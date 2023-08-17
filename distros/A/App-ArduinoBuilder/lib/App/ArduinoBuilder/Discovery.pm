package App::ArduinoBuilder::Discovery;

use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Config;
use App::ArduinoBuilder::JsonTool;
use App::ArduinoBuilder::Logger ':all_logger';
use File::Spec::Functions;


sub _test_command_response {
  my ($res, $cmd) = @_;
  return 0 if $res->{eventType} ne $cmd;
  return 0 if $res->{message} ne 'OK';
  return 1;
}

sub _fail_invalid_response {
  my ($res, $cmd, $tool) = @_;
  return if _test_command_response($res, $cmd);
  fatal "Invalid response for ${tool}:\n%s", $res;
}

# Specification of the discovery protocol.
# https://arduino.github.io/arduino-cli/0.32/pluggable-discovery-specification/
sub _run_one_discovery {
  my ($toolname, $cmd) = @_;

  my $tool = App::ArduinoBuilder::JsonTool->new($cmd);
  # TODO: we could test that the tool accept to speak the protocol version 1.
  # But, as there are no other versions for know, it’s somehow an overkill.
  _fail_invalid_response($tool->send("HELLO 1 ${App::ArduinoBuilder::TOOLS_USER_AGENT}\n"), 'hello', $toolname);
  _fail_invalid_response($tool->send("START\n"), 'start', $toolname);
  my $res = $tool->send("LIST\n");
  _fail_invalid_response($tool->send("QUIT\n"), 'quit', $toolname);

  fatal "Invalid pluggable discovery data (eventType ne 'list') for ${toolname}: %s", $res unless $res->{eventType} eq 'list';
  fatal "Pluggable discovery returned an error for ${toolname}: %s", $res if $res->{error} && $res->{error} eq 'true';
  debug "Pluggable discovery for ${toolname} found:\n%s", $res->{ports};
  return @{$res->{ports}};
}

# See: https://arduino.github.io/arduino-cli/0.32/platform-specification/#properties-from-pluggable-discovery
sub _port_to_config {
  my ($config, $port) = @_;

  my $port_config = App::ArduinoBuilder::Config->new(base => $config);
  $port_config->parse_perl($port, prefix => 'upload.port');
  if ($port_config->exists('upload.port.address')) {
    $port_config->set('serial.port' => $port_config->get('upload.port.address'));
  }
  if ($port_config->get('upload.port.protocol', default => '') eq 'serial') {
    $port_config->set('serial.port.file' => $port_config->get('upload.port.label'));
  }

  # Case folded versions, later used to compare to the content of the --port
  # option.
  $port_config->set('upload.port.lc_label', lc($port_config->get('upload.port.label')));
  $port_config->set('upload.port.lc_address', lc($port_config->get('upload.port.address')));

  return $port_config;
}

# For _some_ documentation, see:
# https://arduino.github.io/arduino-cli/0.32/platform-specification/#pluggable-discovery
sub discover {
  my ($config) = @_;
  my $discovery_config = $config->filter('pluggable_discovery');
  if ($discovery_config->filter('required')->empty()) {
    $discovery_config->set('required.0' => 'builtin:serial-discovery');
    $discovery_config->set('required.1' => 'builtin:mdns-discovery');
  }

  # There is no real documentation of how to use the 'VENDOR_ID:DISCOVERY_NAME'
  # references. For now, we just assume that there is a tool with that discovery
  # name (we ignore the vendor ID) and we expect a binary of the same name in
  # the tool directory (this is the format used by the builtin tools).

  my @discovered_ports;
  for my $k ($discovery_config->keys()) {
    if ($k =~ m/^(.*)\.pattern$/) {
      push @discovered_ports, _run_one_discovery($1, $discovery_config->get($k));
    } elsif ($k =~ m/required(?:\.\d+)?/) {
      if ($discovery_config->get($k) =~ m/^([^:]+):(.*)$/) {
        # Note: for now we’re ignoring the vendor ID part.
        my $tool = $2;
        my $tool_key = "runtime.tools.${tool}.path";
        if (!$config->exists($tool_key)) {
          error "Pluggable discovery references unknown tool: ${tool}";
          next;
        }
        my $tool_dir = $config->get($tool_key);
        my $cmd = catfile($tool_dir, $tool);
        $cmd .= '.exe' if $^O eq 'MSWin32';
        push @discovered_ports, _run_one_discovery($tool, $cmd);
      } else {
        error "Invalid pluggable discovery reference format: %s", $discovery_config->get($k);
      }
    } else {
      error "Invalid pluggable discovery key: %s => %s", $k, $discovery_config->get($k);
    }
  }

  return map { _port_to_config($config, $_) } @discovered_ports;
}

1;
