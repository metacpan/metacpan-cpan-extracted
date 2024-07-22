package App::ArduinoBuilder::JsonTool;

# Package that implement bi-directionnal communication with a tool talking
# JSON (like the Arduino pluggable discovery and monitor tools).

use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::System 'split_cmd';
use JSON::PP;
use IPC::Run  qw(start pump finish timeout);
use Log::Any::Simple ':default';

# TODO: look into what should be done with UTF-8 encoding when communicating
# with the tool.

my $timeout_exn;

sub new {
  my ($class, $cmd) = @_;

  my $this = bless {
    out => '',  # Out from the JsonTool class point of view, this will be the tool STDIN
    in => '',  # This will be the tool STDOUT.
    cmd => $cmd,
  }, $class;

  $this->{tool} = start [split_cmd($cmd)], \$this->{out}, \$this->{in}, ($this->{timer} = timeout('inf'));
  $this->{timer}->exception(\$timeout_exn);
  trace "Creating tool for command: ${cmd}";

  return $this;
}

sub DESTROY {
  my ($this) = @_;
  local($., $@, $!, $^E, $?);
  return unless $this->{tool};
  $this->{timer}->start(5);
  trace "Waiting for tool to stop";
  eval {
    $this->{tool}->finish();
  };
  if ($@) {
    $this->{tool}->kill_kill(grace => 5);
  }
  return;
}

# Read our input pipe for one full json object.
# $json can be omitted or it can be a single already read character.
sub _read_and_parse_json {
  my ($this) = @_;

  my $json = '';
  my $braces = 0;
  my $primed = 0;

  $this->{timer}->start(5);

  while (1) {
    eval { pump $this->{tool} };
    if (my $err = $@) {
      $this->{tool}->kill_kill(grace => 5);
      debug 'Received: %s%s', $json, $this->{in};
      if ($err == \$timeout_exn) {
        fatal "External tool is not responding: %s", $this->{cmd};
      } else {
        chomp($err);
        fatal "Error while reading output of external tool: %s (%s)", $err, $this->{cmd};
      }
    }
    $json .= $this->{in};
    1 while $this->{in} =~ m/\{ (?{$braces++; $primed++}) | \} (?{$braces--})/gx;
    $this->{in} = '';
    if ($primed && $braces == 0) {
      my $data = eval { decode_json ${json} };
      trace "Received following JSON:\n%s", $json;
      fatal "Could not parse JSON from tool output: $@" if $@;
      $this->{timer}->reset();
      return $data;
    }
  }
}

sub send {
  my ($this, $msg) = @_;

  trace "Sending message to tool: ${msg}";
  $this->{out} .= $msg;

  return $this->_read_and_parse_json();
}

1;
