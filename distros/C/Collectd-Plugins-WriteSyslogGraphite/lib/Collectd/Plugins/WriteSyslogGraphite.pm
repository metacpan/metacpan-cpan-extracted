package Collectd::Plugins::WriteSyslogGraphite;

use strict;
use warnings;
use Collectd qw( :all );
use threads::shared;
use Sys::Syslog qw(:standard :macros);

# ABSTRACT: collectd plugin for sending collectd metrics to syslog
our $VERSION = '1.002'; # VERSION


my $level = 'info';
my $facility = 'local0';
my $ident = 'metric';

sub write_syslog_graphite_config {
    my ($ci) = @_;
    foreach my $item (@{$ci->{'children'}}) {
        my $key = lc($item->{'key'});
        my $val = $item->{'values'}->[0];

        if ($key eq 'level' ) {
            $level = $val;
        } elsif ($key eq 'facility' ) {
            $facility = $val;
        } elsif ($key eq 'ident') {
            $ident = $val;
        }
    }

    return 1;
}

sub write_syslog_graphite_init {
    openlog( $ident, 'ndelay,pid', $facility );

    return 1;
}

sub write_syslog_graphite_write {
    my ($type, $ds, $vl) = @_;

    my $plugin_str = $vl->{'plugin'};
    my $type_str   = $vl->{'type'};   
    if ( defined $vl->{'plugin_instance'} ) {
        $plugin_str .=  "-" . $vl->{'plugin_instance'};
    }
    if ( defined $vl->{'type_instance'} ) {
        $type_str .= "-" . $vl->{'type_instance'};
    }

    for (my $i = 0; $i < scalar (@$ds); ++$i) {
        my $graphite_path = sprintf "%s.%s.%s",
            $plugin_str,
            $type_str,
            $ds->[$i]->{'name'};
            
        $graphite_path =~ s/\s+/_/g;
        my $log = sprintf  "%s %s %d\n",
            $graphite_path,
            $vl->{'values'}->[$i],
            $vl->{'time'};
        syslog( $level, $log );
    }

    return 1;
}

plugin_register (TYPE_CONFIG, "WriteSyslogGraphite", "write_syslog_graphite_config");
plugin_register (TYPE_WRITE, "WriteSyslogGraphite", "write_syslog_graphite_write");
plugin_register (TYPE_INIT, "WriteSyslogGraphite", "write_syslog_graphite_init");

1;

__END__
=pod

=head1 NAME

Collectd::Plugins::WriteSyslogGraphite - collectd plugin for sending collectd metrics to syslog

=head1 VERSION

version 1.002

=head1 SYNOPSIS

This is a collectd plugin for sending collectd metrics to syslog.

In your collectd config:

    <LoadPlugin "perl">
    	Globals true
    </LoadPlugin>

    <Plugin "perl">
      BaseName "Collectd::Plugins"
      LoadPlugin "WriteSyslogGraphite"

    	<Plugin "WriteSyslogGraphite">
    	  level "info"
    	  facility "local0"
    	  ident   "metric"
    	</Plugin>
    </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

