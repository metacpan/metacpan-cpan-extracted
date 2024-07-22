package App::ArduinoBuilder::Discovery;

use 5.026;
use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Config;
use App::ArduinoBuilder::JsonTool;
use File::Spec::Functions;
use List::Util 'all', 'max';
use Log::Any::Simple ':default';
use Time::HiRes 'usleep';


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
  # A small delay here, otherwise the LIST command returns empty results :(
  usleep(50000);
  my $res = $tool->send("LIST\n");
  if (!@{$res->{ports}}) {
    # mitigation: if the list was empty initially, let’s try again, maybe the tool has initialized now.
    trace "Retrying due to empty list";
    $res = $tool->send("LIST\n");
  }
  _fail_invalid_response($tool->send("QUIT\n"), 'quit', $toolname);

  fatal "Invalid pluggable discovery data (eventType ne 'list') for ${toolname}: %s", $res unless $res->{eventType} eq 'list';
  fatal "Pluggable discovery returned an error for ${toolname}: %s", $res if $res->{error} && $res->{error} eq 'true';
  debug "Pluggable discovery for ${toolname} found: %s", $res->{ports};
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
  # In general, that syntax could be used to automaticaly download the required
  # tools if they are not already present.

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

  return () unless @discovered_ports;

  # Something that we don’t implement is that the discovery could be used to
  # automatically detect the board being used, as well as some of its "menu"
  # properties.
  # However, the whole thing is very buggy. For example the Feather 2040 board
  # will have a match on the vid property but not the pid property, so we accept
  # partial match (theoretically we should accept full matches).

  # Some boards have the upload ports properties defined without the
  # upload_ports prefix (in addition to also having them with the prefix), we
  # are ignoring that.
  my $defined_ports = $config->filter('upload_port');
  my @property_sets_keys = $defined_ports->top_level_keys();
  my @property_sets;
  if (all { m/^\d+$/ } @property_sets_keys) {
    @property_sets = map { { $defined_ports->filter($_)->get_hash() } } @property_sets_keys;
  } else {
    @property_sets = { $defined_ports->get_hash() };
  }
  
  # We compute a "match strength" for all discovered ports, corresponding to how
  # many properties (from a single defined set) the port matches.
  my $all_max_match = 0;
  for my $p (@discovered_ports) {
    my $max_match = 0;
    for my $s (@property_sets) {
      my $match = 0;
      while (my ($k, $v) = each %{$s}) {
        if (fc($p->{properties}{$k} // '') eq fc($v)) {
          $match++;
        }
      }
      $max_match = max($max_match, $match);
    }
    $all_max_match = max($all_max_match, $max_match);
    $p->{upload_port_match_strength} = $max_match;
    trace "Port %s: match strength == %d", $p->{label}, $max_match;
  }

  # Now, we keep all the found ports that have the highest 
  @discovered_ports = grep { $_->{upload_port_match_strength} == $all_max_match } @discovered_ports;

  return map { _port_to_config($config, $_) } @discovered_ports;
}

1;
