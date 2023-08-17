package App::ArduinoBuilder::JsonTool;

# Package that implement bi-directionnal communication with a tool talking
# JSON (like the Arduino pluggable discovery and monitor tools).

use strict;
use warnings;
no warnings 'experimental::defer';
use utf8;
use feature 'defer';

use App::ArduinoBuilder::CommandRunner;
use App::ArduinoBuilder::Logger ':all_logger';
use IO::Pipe;
use JSON::PP;

# TODO: look into what should be done with UTF-8 encoding when communicating
# with the tool.

sub new {
  my ($class, $cmd, %options) = @_;
  # The only option that we expect to use is the SIG one, to ignore a SIGINT.

  my $mosi = IO::Pipe->new();  # from parent to child
  my $miso = IO::Pipe->new();  # from child to parent

  # Custom re-implementation of open2 (but using our CommandRunner so that we
  # don’t have to mess again with $SIG{CHLD}).
  my $task = default_runner()->execute(sub {
    log_cmd $cmd;
    $mosi->reader();
    $miso->writer;
    close STDIN;
    close STDOUT;
    open STDIN, '<&', $mosi or fatal "Can’t reopen STDIN";
    open STDOUT, '>&', $miso or fatal "Can’t reopen STDOUT";
    $mosi->close();
    $miso->close();
    # Maybe we could call system instead of exec, so that we can do some cleanup
    # task at the end (and be notified here if the tool terminate abruptly while
    # we are still trying to communicate with it).
    exec $cmd;
  }, %options);

  $mosi->writer();
  $miso->reader();
  # Make our out-channel be unbuffered (binmode($fh, ':unix') with a real filehandle)
  $mosi->autoflush(1);

  my $this = bless {
    task => $task,
    out => $mosi,
    in => $miso,
  }, $class;

  return $this;
}

sub DESTROY {
  local($., $@, $!, $^E, $?);
  my ($this) = @_;
  $this->{out}->close();
  $this->{in}->close();
  full_debug "Waiting for tool to stop";
  $this->{task}->wait();
  return;
}

# Read our input pipe for one full json object.
# $json can be omitted or it can be a single already read character.
sub _read_and_parse_json {
  my ($this, $json) = @_;

  $json //= '';
  my $braces = $json eq '{' ? 1 : 0;

  my $b = $this->{in}->blocking(1);
  defer { $this->{in}->blocking($b) }

  while (1) {
    my $count = $this->{in}->read(my $char, 1);
    # full_debug "Read from tool: ${content}";
    fatal "An error occured while reading tool output: $!" unless defined $count;
    fatal "Unexpected end of file stream while reading tool output" if $count == 0;
    $json .= $char;
    if ($char eq '{') {
      $braces++;
    } elsif ($char eq '}') {
      $braces--;
      if ($braces == 0) {
        # Here, we could use sysread to check that there is no more any
        # meaningful content in the pipe. But let’s assume that we are talking
        # to correct tools for now.
        my $data = eval { decode_json ${json} };
        full_debug "Received following JSON:\n%s", $json;
        fatal "Could not parse JSON from tool output: $@" if $@;
        return $data;
      }
    }
  }
}

sub send {
  my ($this, $msg) = @_;

  full_debug "Sending message to tool: ${msg}";
  $this->{out}->print($msg);

  return $this->_read_and_parse_json();
}

sub check_for_message {
  my ($this) = @_;
  
  my $b = $this->{in}->blocking(0);
  defer { $this->{in}->blocking($b) }

  #error "Starting to check for message";

  while(1) {
    my $count = $this->{in}->read(my $char, 1);
    #error "Read: %s", [$count, $char];
    # We can’t easily distinguish an error case from an empty pipe, so we don’t try
    # to do so.
    return unless defined $count;
    if ($char !~ m/[[:space:]]/s) {
      #error "Saw -->$char<-- starting full parse";
      return $this->_read_and_parse_json($char);
    }
  }
}

1;
