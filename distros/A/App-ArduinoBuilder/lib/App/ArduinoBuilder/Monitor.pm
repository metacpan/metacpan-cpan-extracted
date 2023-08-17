package App::ArduinoBuilder::Monitor;

use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Logger ':default', 'is_logged';
use App::ArduinoBuilder::JsonTool;
use File::Spec::Functions 'catfile';
use IO::Select;
use IO::Socket::INET;

sub monitor {
  my ($config, $port) = @_;

  my $protocol = $port->get('upload.port.protocol');
  my $board_port = $port->get('upload.port.address');

  # Some documentation for these properties is at:
  # https://arduino.github.io/arduino-cli/0.32/platform-specification/#pluggable-monitor
  my $cmd;
  if ($config->exists("pluggable_monitor.required.${protocol}")) {
    my $tooldef = $config->get("pluggable_monitor.required.${protocol}");
    if ($tooldef =~ m/^([^:]+):(.*)$/) {
      # Note: for now we’re ignoring the vendor ID part.
      my $tool = $2;
      my $tool_key = "runtime.tools.${tool}.path";
      if (!$config->exists($tool_key)) {
        fatal "Pluggable monitor references unknown tool: ${tool}";
      }
      my $tool_dir = $config->get($tool_key);
      $cmd = catfile($tool_dir, $tool);
      $cmd .= '.exe' if $^O eq 'MSWin32';
    } else {
      error "Invalid pluggable discovery reference format: $tooldef";
    }
  } elsif ($config->exists("pluggable_monitor.pattern.${protocol}")) {
    $cmd = $config->get("pluggable_monitor.pattern.${protocol}");
  } elsif ($protocol eq 'serial') {
    my $tool_key = "runtime.tools.serial-monitor.path";
    if (!$config->exists($tool_key)) {
      fatal "Built-in serial-monitor is not found, you may need to install the Arduino GUI and/or to set the builder.arduino.install_dir value in the project configuration";
    }
    my $tool_dir = $config->get($tool_key);
    $cmd = catfile($tool_dir, 'serial-monitor');
    $cmd .= '.exe' if $^O eq 'MSWin32';
  } else {
    fatal "No pluggable monitor for protocol '$protocol'";
  }

  # The protocol is described at:
  # https://arduino.github.io/arduino-cli/0.32/pluggable-monitor-specification

  my $tool = App::ArduinoBuilder::JsonTool->new(
    $cmd, catch_error => 1);
  $tool->send("HELLO 1 ${App::ArduinoBuilder::TOOLS_USER_AGENT}\n");

  if (is_logged('DEBUG')) {
    my $params = $tool->send("DESCRIBE\n")->{port_description}{configuration_parameters};
    my %set_params = map { $_->{label} => $_->{selected} } values %{$params};
    debug "Monitor port configuration: %s", \%set_params;
    full_debug "Monitor port available options: %s", $params;
  }
  
  my $serv = IO::Socket::INET->new(Listen => 1, Timeout => 5);
  my $serv_addr = sprintf "%s:%s", $serv->sockhost, $serv->sockport();
  debug "Listening for the monitor on '${serv_addr}'";
  
  # TODO: check OK response (here and in other commands too).
  $tool->send("OPEN ${serv_addr} ${board_port}\n");

  my $client = $serv->accept();
  $serv->close();

  my $select = IO::Select->new();
  $select->add($client);
  $select->add(\*STDIN);

  # For the RP2040 core, setting the baudrate reset the board, also asserting
  # the DTR and RTS line at the same time make it enter its bootloader.
  # TODO: test the behavior of other core and boards.
  # TODO: make all this be configurable (and happen only with the serial
  # monitor).
  $tool->send("CONFIGURE baudrate 1200\n");
  #$tool->send("CONFIGURE rts off\n");
  #$tool->send("CONFIGURE dtr off\n");
  #$tool->send("CONFIGURE rts on\n");
  #$tool->send("CONFIGURE dtr on\n");
  $tool->send("CONFIGURE baudrate 9600\n");
  
  # TODO: look into what to do about UTF-D when communicating over the socket.
  {
    my $interrupted = 0;
    local $SIG{INT} = sub { $interrupted = 1; };
    while (!$interrupted && (my @ready = $select->can_read())) {
      for my $s (@ready) {
        if ($s == \*STDIN) {
          my $data = readline STDIN;
          $client->send($data);
        } elsif ($s == $client) {
          my $ret = $client->recv(my $data, 255);
          die "Can’t read tool data in monitor: $!" unless defined $ret;
          print STDOUT $data;
        }
      }
    }
  }

  # The tool process was already killed by the SIGINT that we have received,
  # there is no easy and portable way to detach the tool process from our
  # control group (or from the terminal on Windows).
  #$tool->send("CLOSE\n");
  $client->close();
  #$tool->send("QUIT\n");

  return;
}

1;
