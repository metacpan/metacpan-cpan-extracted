package Amazon::SQS::Config;

use strict;
use warnings;

use Config::IniFiles;
use Scalar::Util qw(openhandle);

use Data::Dumper;

our $VERSION = '2.0.6';

use Readonly;

Readonly::Array our @REQUIRED_ACCESSORS => qw(
  aws_access_key_id
  aws_secret_access_key
  error_delete
  error_exit
  handler_class
  handler_pidfile
  log_file
  log_level
  queue_create_queue
  queue_name
  queue_url
  queue_interval
  queue_max_messages
  queue_max_wait
  queue_visibility_timeout
  queue_wait_time
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(config file queue_list service));

use parent qw(Class::Accessor::Fast);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  my $self = $class->SUPER::new($options);

  my $file = $self->get_file;

  die "file is a required argument\n"
    if !$file;

  die sprintf "no such file: [%s]\n", $file
    if !openhandle($file) && !-e $file;

  my $config = Config::IniFiles->new(
    -file     => $self->get_file,
    -fallback => 'main'
  );

  $self->set_config($config);

  $self->create_config_accessors();

  my @required_accessors = grep { !$self->can($_) } @REQUIRED_ACCESSORS;

  $self->mk_accessors(@required_accessors);

  return $self;
}

########################################################################
sub create_config_accessors {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my @sections = $config->Sections;

  foreach my $section (@sections) {

    my %section_config;

    foreach ( $config->Parameters($section) ) {
      $section_config{$_} = $self->get_config->val( $section, $_ );
    }

    my @extra_vars = keys %section_config;

    if (@extra_vars) {
      no strict 'refs';  ## no critic (ProhibitNoStrict)
      my @ok_vars;

      for (@extra_vars) {

        my $name = $section eq 'main' ? $_ : "${section}_$_";

        next
          if defined *{ ref($self) . q{::} . "get_$name" }{CODE};

        push @ok_vars, $_;
      }

      $self->mk_accessors( map { $section eq 'main' ? $_ : "${section}_$_" } @ok_vars );

      for (@extra_vars) {
        my $name = $section eq 'main' ? $_ : "${section}_$_";
        $self->set( "$name", $section_config{$_} );
      }
    }
  }

  return $self;
}

1;

__END__

=pod

=head1 NAME

Amazon::SQS::Config - configuration file class for Amazon::SQS::QueueHandler

=head1 SYNOPSIS

 my $config = Amazon::SQS::Config->new( file => 'amazon-sqs.ini' );

 my $config = Amazon::SQS::Config->new( file => \*DATA );

I<NOTE: you won't typically create your own configuration objects as
this is done as part of the F<QueueDaemon.pl> startup procedure.>

=head1 DESCRIPTION

L<Config::IniFiles> based class to retrieve configuration information for
AWS SQS services from a F<.ini> style file.

=head1 SECTIONS

The configuration file should contain multiple sections describe below.

=head2 handler

The handler section describes your queue handler and other attributes
that control how messages are processed.

  [handler]
  class = MyHandler
  message_type = application/json
  max_children = 1

=over 5

=item class

Name of the class that implements your handler.  If you do not provide
a class the default class L<Amazon::SQS::QueueHandler> is used.  That
class will dump and delete each message it reads.

=item message_type

The message mime type. Can be one of 'text/plain', 'application/json',
or 'application/x-www-form-urlencoded'.

If the message type is 'application/json' it will be decoded using the
L<JSON> class. If the message type is
'application/x-www-form-urlencoded' the message will be decode using
L<CGI::Simple> and returned as a hash reference.

default: text/plain

I<NOTE: The message sent to your handler is the decoded message. The
raw message is available using the C<get_raw_message> method. The
decoded messsage is also available using the getter C<get_message>.>

=item max_children

The maximum number of children that can be instantiated by the
F<QueuDaemon.pl> script.  Currently the maximum is 1.  Future versions
may support forking.

=item pidfile

Path of the pid file.

default: /var/run/QueueDaemon.pl.pid

=back

=head2 error

The exit section describes what to do with messages when they are
handled successfully or when an error occurs.  Your handler should
return a true value indicating it successfully handled the message and
a false value otherwise. Options here then describe what actions to
take based on the result of calling your handler.

There are three outcomes possible when processing the message:

=over 5

=item 1. Your handler returned a true value

=item 2. Your handler returned a false value

=item 3. Your handler or decoding the message resulted in an exception

=back

Two configuration values (C<exit>, C<delete>) control what to do next.

  [error]
  exit = error
  delete = true

=over 5

=item exit

=over 10

=item * error

Exit whenever an exception occurs.

=item * never

Never exit.

=item * always

Exit after processing any message, regardless of state.

=item * false

Exit if your handler returns a false value.

=back

=item delete

=over 10

=item * always

Always delete messages (when an error occurs or regardless of your handler's return value).

=item * true

Only delete messages if your handler returns a true value. This is the
default value if the F<QueueDaemon.pl> script is not provided a
setting for the C<delete> option.

=item * false

Only delete messages if your handler returns a false value.

=item * error

Delete messages only when an error occurs.

=back

=back

=head2 queue

This section decribes the queue.

  [queue]
  interval = 2 
  max_wait = 20 
  max_messages = 1
  visibility_timeout = 60
  max_error_retry = 3
  name = <your-queue-name>
  url = https://sqs.us-east-1.amazonaws.com/<your-account-number>/<your-queue-name>

=over 5

=item create_queue

Set to 'yes' if you want the F<QueueDaemon.pl> script to create the
queue if it does not exist. Set the C<name> option to just the name of
the queue (not the URL).

=item interval

Number of seconds to wait after no message is received. The script
will sleep for this amount of time before attempting to receive
another message. If after waking there are still no messages, the
sleep time is incremented by this amount up to the C<max_wait> value.

=item max_error_retry

Number of retries for invoking any AWS API.

default: 3

=item max_messages

Maximum number of messages to return from the receive message
API. Current maximum value is 1. This may change in future versions.

=item max_wait

The maxium amount of time in seconds to sleep.

default: 60s

=item name

The name (not the URL) of the queue.

=item url

The queue URL.

=item visibility_timeout

From the AWS documentation:

I<You can provide the VisibilityTimeout parameter in your request. The
parameter is applied to the messages that Amazon SQS returns in the
response. If you don't include the parameter, the overall visibility
timeout for the queue is used for the returned messages. The default
visibility timeout for a queue is 30 seconds.>

default: 30

=item wait_time

The number of seconds to wait for a message (long polling).  The
maximum value is 20 seconds.

The advantage of using long polling is that your messages will be
received almost as soon as they are available on the queue.  The
disadvantage is that you may incur more costs if you are making a lot
of calls to receive messages on a queue that is infrequently used.  In
that case you may want to consider short polling with an C<interval>
value. This will result in far fewer calls to receive messages but may
delay receipt of messages up to the max wait time.

I<NOTE: Using long polling instead of short polling will result in your daemon
blocking until the ReceiveMessage API returns. Signals received during
this period not be may not be immediately acting upon.>

=back

=head2 aws

This section describes the SQS endpoint and your API credentials. By
default, the F<QueueDaemon.pl> script will use the
L<Amazon::Credentials> class to find your credentials so you do not
need to configure them here.

  [aws]
  access_key_id = <Your Access Key ID>
  secret_access_key = <Your Secret Access Key>
  endpoint_url = https://sqs.amazonaws.com

=over 5

=item access_key_id

Your AWS Access key value.

=item secrete_access_key

Your AWS Secret Access key value.

=item endpoint_url

The AWS SQS endpoint. 

default: https://queue.amazonaws.com

=back 

=head2 log

The log section describe how the F<QueueDaemon.pl> script will log
messages. The script instantiates a L<Log::Log4perl> logger
automatically for you that will log to the parent's STDERR. See note
below regarding how the daemonization process closes STDOUT, STDERR.

  [log]
  level = debug
  file = /tmp/amazon_sqs.log

When you daemonize the script, if either C<stdout> or C<stderr> is set
the parent's STDOUT or STDERR will be closed and then reopened using
those settings. If these are not set, then they will not be
closed. The closing STDERR will stop the C<Log::Log4perl> logger.

=over 5

=item level

C<Log::Log4perl> logging level ('trace', 'debug', 'info', 'warn', 'error').

=item file

Name of a log file for C<Log::Log4perl> messages. You can also use the
values of 'stdout' or 'stderr' to log to STDOUT and STDERR.

=back

I<WARNING: You should probably make sure that the F<.ini> file is properly
protected with restrictive permissions if you place credentials in
this file.>

=head1 METHODS AND SUBROUTINES

=head2 new

 new( file => filename | handle )

You can pass either the name of a file or a file handle to the new
method. See L<Config::IniFiles>.

=over

=item file

The name of a F<.ini> style file that contains the AWS SQS configuration information or 
handle to an open F<.ini> style file.

=back

=head1 SEE ALSO

L<Config::IniFiles>

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut

1;
