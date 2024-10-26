package App::mqtt2job;

use strict;
use warnings;

use Template;
use File::Temp;
use Exporter qw/import/;

# ABSTRACT: Helper module for mqtt2job

our @EXPORT_OK = qw/ helper_v1 ha_helper_cfg /;

sub helper_v1 {
    my ($obj) = @_;

    my $unlink = $obj->{rm} ? 1 : 0;

    # helper scripts need to be saved, so set up & prepare a filehandle
    my $fh = File::Temp->new( SUFFIX => "." . ($obj->{suffix} || "pl"), UNLINK => $unlink );
    $obj->{wrapper_location} = $fh->filename;
    
    my $tt = Template->new();
    my $ttout = undef;
    
    $tt->process( _helper_v1(), $obj, \$ttout );

    return _save($fh, $ttout, $obj->{rm});
}

sub ha_helper_cfg {
    my ($obj) = @_;

    my $tt = Template->new();
    my $ttout = undef;
    
    $tt->process( _ha_helper_cfg(), $obj, \$ttout );

    return $ttout;
}

sub _save {
    my ($fh, $output) = @_;
    print $fh $output;
    return $fh;
}

sub _helper_v1 {
    my $tpl = undef;
    $tpl = <<'_RUNNER_TPL';
#![% shebang %]

use strict;
use warnings;

use Net::MQTT::Simple;
use DateTime;
use JSON; 
use Capture::Tiny ':all';

my $dt_start = DateTime->now();
my $mqtt = Net::MQTT::Simple->new("[% mqtt_server %]:[% mqtt_port %]");

$mqtt->retain("[% base_topic %]/status/" . "[% task || "unknown" %]", encode_json({ status => "initiated", dt => "$dt_start", msg => "[% cmd %]" }) );
my $real_cmd = "[% job_dir %]/[% cmd %]";
my $real_args = "[% args %]";

print STDERR "$dt_start: [MQTT TASK] $real_cmd $real_args\n";

my ($output, $exit) = tee_merged {
    my @args = split(" ", $real_args);
    system($real_cmd, @args);
};

my $msg = ($exit == 0) ? "ok" : "failed";

my $dt_end = DateTime->now();
my $dt_elapsed_obj = $dt_end - $dt_start;
my $dt_elapsed = $dt_elapsed_obj->in_units("seconds");

my @split_output = split("\n", $output);
my $last_line = $split_output[$#split_output];

$output =~ s/\n//g;

$mqtt->retain("[% base_topic %]/status/" . "[% task || "unknown" %]", encode_json({ status => "completed", dt => "$dt_end", last_line => "$last_line", output => "$output", elapsed => "$dt_elapsed", msg => "$msg" }) );
print STDERR "$dt_end: [MQTT TASK] $real_cmd $real_args (${dt_elapsed}s) Exit: $exit\n";

$mqtt->disconnect;
[% UNLESS no_unlink %]unlink "[% wrapper_location %]";[% END %]
_RUNNER_TPL
    return \$tpl;
}

sub _ha_helper_cfg {
    my $tpl = undef;
$tpl = <<'_HA_CFG_TPL';
=====================================================================
TRIGGER: (automation)
=====================================================================
alias: mqtt2job [% task %]
description: ""
triggers:
  - seconds: "0"
    trigger: time_pattern
    enabled: true
conditions: []
actions:
  - action: mqtt.publish
    metadata: {}
    data:
      topic: [% base_topic %]
      payload: |-
        { 
          "cmd": "[% cmd %]",
          "args": "[% args %]", 
          "dt": "{{ now().strftime("%Y-%m-%d %H:%M:%S") }}",
          "task": "[% task %]",
          "status": "queue"
        }
mode: single

=====================================================================
SENSORS: (configuration.yaml)
=====================================================================
  sensor:
    - name: "[% task %] status"
      state_topic: "[% base_topic %]/status/[% task || "unknown" %]"
      value_template: "{{ value_json.status }}"
    - name: "[% task %] datetime"
      state_topic: "[% base_topic %]/status/[% task || "unknown" %]"
      value_template: "{{ value_json.dt }}"
    - name: "[% task %] message"
      state_topic: "[% base_topic %]/status/[% task || "unknown" %]"
      value_template: "{{ value_json.msg }}"
    - name: "[% task %] elapsed"
      state_topic: "[% base_topic %]/status/[% task || "unknown" %]"
      value_template: "{{ value_json.elapsed }}"
    - name: "[% task %] output"
      state_topic: "[% base_topic %]/status/[% task || "unknown" %]"
      value_template: "{{ value_json.last_line }}"

=====================================================================
CARD: (dashboard, uses button-card from HACS)
=====================================================================
type: custom:button-card
show_state: false
custom_fields:
  [% task %]_status:
    card:
      type: custom:button-card
      entity: sensor.[% task %]_message
      name: [% task %]
      show_icon: true
      icon: mdi:circle
      state:
        - value: ok
          color: green
          icon: mdi:check-circle
        - value: failed
          color: red
          icon: mdi:alert-circle
        - operator: default
          color: blue
          icon: mdi:progress-clock
      tap_action:
        action: navigate
        navigation_path: [% task %] 
styles:
  custom_fields:
    [% task %]_status:
      - padding: 5px
      - font-size: 12px
  grid:
    - grid-template-areas: "\"[% task %]_status\""
    - grid-template-columns: 1fr 1fr
    - grid-template-rows: auto
  card:
    - padding: 10px
    - width: auto
    - height: auto

=====================================================================
WIDGET: (hidden dashboard)
=====================================================================
title: [% task %]
path: [% task %]
icon: mdi:widgets
type: panel
cards:
  - type: entities
    entities:
      - entity: sensor.[% task %]_datetime
      - entity: sensor.[% task %]_elapsed
      - entity: sensor.[% task %]_message
      - entity: sensor.[% task %]_status
      - entity: sensor.[% task %]_output
subview: true

_HA_CFG_TPL
	return \$tpl;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::mqtt2job - Helper module for mqtt2job

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  mqtt2job --mqtt_server mqtt.example.com --base_topic my/topic --job_dir /apps

=head1 DESCRIPTION

Subscribes to the my/topic/job mqtt topic and upon receiving a 
correctly formatted json message will fork and run the requested 
job in a wrapper script providing it is present and executable in 
the job_dir directory. 

This wrapper will generate two child mqtt messages under the base 
topic, at my/topic/status. Message one is sent when the job is 
initiated. The second is sent when the job has completed (or timed 
out). This second message will also include any output from the job 
amongst various other metadata (e.g. execution datetime, duration, 
timeout condition, etc.)

=head1 NAME

App::mqtt2job - Subscribe to an MQTT topic and trigger job execution

=head1 FOR THE LOVE OF ALL THAT IS SACRED, WHY?

This is part one of my "Cursed Solutions" series, URL to be added
later when I've uploaded it.

=head1 COPYRIGHT

Copyright 2024 -- Chris Carline

=head1 LICENSE

This software is licensed under the same terms as Perl.

=head1 NO WARRANTY

This software is provided "as is" without any express or implied
warranty. Using it for any reason whatsoever is probably an 
extremely bad idea and it should only ever be considered if you 
understand the potential consequences. In no event shall the 
author be held liable for any damages arising from the use of 
this software. It is provided for demonstration purposes only.

=head1 AUTHOR

Chris Carline <chris@carline.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Chris Carline.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
