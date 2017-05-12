package CGI::Application::Plugin::LogDispatch;

use strict;
use vars qw($VERSION @EXPORT);

use Log::Dispatch;
use Log::Dispatch::Screen;
use Scalar::Util ();
use CGI::Application ();
use File::Spec ();
require UNIVERSAL::require;

$VERSION = '1.02';

@EXPORT = qw(
  log
  log_config
);

sub import { 
    my $pkg = shift;
    my $callpkg = caller;
    no strict 'refs';
    foreach my $sym (@EXPORT) {
        *{"${callpkg}::$sym"} = \&{$sym};
    }
    $callpkg->log_config(@_) if @_;
}

sub log {
    my $self = shift;

    my ($log, $options, $frompkg) = _get_object_or_options($self);

    if (!$log) {
        # define the config hash if it doesn't exist to save some checks later
        $options = {} unless $options;

        # create Log::Dispatch object
        if ($options->{LOG_DISPATCH_OPTIONS}) {
            # use the parameters the user supplied
            $log = Log::Dispatch->new( %{ $options->{LOG_DISPATCH_OPTIONS} } );
        } else {
            $log = Log::Dispatch->new( );
        }

        if ($options->{LOG_DISPATCH_MODULES}) {
            foreach my $logger (@{ $options->{LOG_DISPATCH_MODULES} }) {
                if (!$logger->{module}) {
                    # no logger module provided
                    #  not fatal... just skip this logger
                    warn "No 'module' name provided -- skipping this logger";
                } elsif (!$logger->{module}->require) {
                    # Couldn't load the logger module
                    #  not fatal... just skip this logger
                    warn $UNIVERSAL::require::ERROR;
                } else {
                    my $module = delete $logger->{module};
                    # setup a callback to append a newline if requested
                    if ($logger->{append_newline} || $options->{APPEND_NEWLINE}) {
                        delete $logger->{append_newline} if exists $logger->{append_newline};
                        $logger->{callbacks} = [ $logger->{callbacks} ]
                            if $logger->{callbacks} &&  ref $logger->{callbacks} ne 'ARRAY';
                        push @{ $logger->{callbacks} }, \&_append_newline;
                    }
                    # add the logger to the dispatcher
                    $log->add( $module->new( %$logger ) );
                }
            }
        } else {
            # create a simple STDERR logger
            my %options = (
                                name => 'screen',
                              stderr => 1,
                           min_level => 'debug',
            );
            $options{callbacks} = \&_append_newline if $options->{APPEND_NEWLINE};
            $log->add( Log::Dispatch::Screen->new( %options ) );
        }
        _set_object($frompkg||$self, $log);

        # CAP::DevPopup support
        if (UNIVERSAL::can($self, 'devpopup')) {
            # Register our report with DevPopup
            $self->add_callback( 'devpopup_report', \&_devpopup_report );

            # Create logger to capture all log entries
            my %options = (
                'name'      => 'DevPopup',
                'min_level' => 'debug',
                'filename'  => File::Spec->devnull(),
                'callbacks' => sub {
                    my %args = @_;
                    push( @{$self->{LOG_DISPATCH_DEVPOPUP_HISTORY}}, [$args{level}, $args{message}] );
                    },
                );
            $log->add( Log::Dispatch::File->new(%options) );
        }
    }

    return $log;
}

sub log_config {
    my $self = shift;
    my $class = ref $self ? ref $self : $self;

    my $log_config;
    if (ref $self) {
        die "Calling log_config after the log object has already been created" if @_ && defined $self->{__LOG_OBJECT};
        $log_config = $self->{__LOG_CONFIG} ||= {};
    } else {
        no strict 'refs';
        die "Calling log_config after the log object has already been created" if @_ && defined ${$class.'::__LOG_OBJECT'};
        ${$class.'::__LOG_CONFIG'} ||= {};
        $log_config = ${$class.'::__LOG_CONFIG'};
    }

    if (@_) {
        my $props;
        if (ref($_[0]) eq 'HASH') {
            my $rthash = %{$_[0]};
            $props = CGI::Application->_cap_hash($_[0]);
        } else {
            $props = CGI::Application->_cap_hash({ @_ });
        }
        my %options;
        # Check for LOG_OPTIONS
        if ($props->{LOG_DISPATCH_OPTIONS}) {
            die "log_config error:  parameter LOG_DISPATCH_OPTIONS is not a hash reference"
                if ref $props->{LOG_DISPATCH_OPTIONS} ne 'HASH';
            $log_config->{LOG_DISPATCH_OPTIONS} = delete $props->{LOG_DISPATCH_OPTIONS};
        }

        # Check for LOG_DISPATCH_MODULES
        if ($props->{LOG_DISPATCH_MODULES}) {
            die "log_config error:  parameter LOG_DISPATCH_MODULES is not an array reference"
                if ref $props->{LOG_DISPATCH_MODULES} ne 'ARRAY';
            $log_config->{LOG_DISPATCH_MODULES} = delete $props->{LOG_DISPATCH_MODULES};
        }

        # Check for APPEND_NEWLINE
        if ($props->{APPEND_NEWLINE}) {
            $log_config->{APPEND_NEWLINE} = 1;
            delete $props->{APPEND_NEWLINE};
        }

        # Check for LOG_METHOD_EXECUTION
        if ($props->{LOG_METHOD_EXECUTION}) {
            die "log_config error:  parameter LOG_METHOD_EXECUTION is not an array reference"
                if ref $props->{LOG_METHOD_EXECUTION} ne 'ARRAY';
            _log_subroutine_calls($self->log, @{$props->{LOG_METHOD_EXECUTION}});
            delete $props->{LOG_METHOD_EXECUTION};
        }

        # If there are still entries left in $props then they are invalid
        die "Invalid option(s) (".join(', ', keys %$props).") passed to log_config" if %$props;
    }

    $log_config;
}

sub _log_subroutine_calls {
  my $log = shift;
  eval {
    Sub::WrapPackages->require;
    Sub::WrapPackages->import(
                            packages => [@_],
                            pre      => sub {
                              $log->debug("calling $_[0](".join(', ', @_[1..$#_]).")");
                            },
                            post     => sub {
                              no warnings qw(uninitialized);
                              $log->debug("returning from $_[0] (".join(', ', @_[1..$#_]).")");
                            }
    );
    1;
  } or do {
    $log->error("Failed to load and configure Sub::WrapPackages:  $@");
  };
}

sub _append_newline {
  my %hash = @_;
  chomp $hash{message};
  return $hash{message}.$/;
}


##
## Private methods
##
sub _set_object {
    my $self = shift;
    my $log  = shift;
    my $class = ref $self ? ref $self : $self;

    if (ref $self) {
        $self->{__LOG_OBJECT} = $log;
    } else {
        no strict 'refs';
        ${$class.'::__LOG_OBJECT'} = $log;
    }
}

sub _get_object_or_options {
    my $self = shift;
    my $class = ref $self ? ref $self : $self;

    # Handle the simple case by looking in the object first
    if (ref $self) {
        return ($self->{__LOG_OBJECT}, undef) if $self->{__LOG_OBJECT};
        return (undef, $self->{__LOG_CONFIG}) if $self->{__LOG_CONFIG};
    }

    # See if we can find them in the class hierarchy
    #  We look at each of the modules in the @ISA tree, and
    #  their parents as well until we find either a log
    #  object or a set of configuration parameters
    require Class::ISA;
    foreach my $super ($class, Class::ISA::super_path($class)) {
        no strict 'refs';
        return (${$super.'::__LOG_OBJECT'}, undef) if ${$super.'::__LOG_OBJECT'};
        return (undef, ${$super.'::__LOG_CONFIG'}, $super) if ${$super.'::__LOG_CONFIG'};
    }
    return;
}

sub _devpopup_report {
    my $self = shift;
    my $r=0;
    my $history = join $/, map {
                    $r=1-$r;
                    qq(<tr class="@{[$r?'odd':'even']}"><td valign="top">$_->[0]</td><td>$_->[1]</td></tr>)
                    }
                    @{$self->{LOG_DISPATCH_DEVPOPUP_HISTORY}};
    $self->devpopup->add_report(
        title   => 'Log Entries',
        summary => 'All entries logged via Log::Dispatch',
        report  => qq(
            <style type="text/css">
              tr.even{background-color:#eee}
            </style>
            <div style="font-size: 80%">
              <table>
                <thead><tr><th>Level</th><th>Message</th></tr></thead>
                <tbody>$history</tbody>
              </table>
            </div>
            ),
        );
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::LogDispatch - Add Log::Dispatch support to CGI::Application


=head1 SYNOPSIS

 package My::App;

 use CGI::Application::Plugin::LogDispatch;

 sub cgiapp_init {
   my $self = shift;

   # calling log_config is optional as
   # some simple defaults will be used
   $self->log_config(
     LOG_DISPATCH_MODULES => [ 
       {    module => 'Log::Dispatch::File',
              name => 'debug',
          filename => '/tmp/debug.log',
         min_level => 'debug',
       },
     ]
   );
 }

 sub myrunmode {
   my $self = shift;

   $self->log->info('Information message');
   $self->log->debug('Debug message');
 }

 - or as a class based singleton -

 package My::App;

 use CGI::Application::Plugin::LogDispatch (
   LOG_DISPATCH_MODULES => [ 
     {    module => 'Log::Dispatch::File',
            name => 'debug',
        filename => '/tmp/debug.log',
       min_level => 'debug',
     },
   ]
 );

 My::App->log->info('Information message');

 sub myrunmode {
   my $self = shift;

   $self->log->info('This also works');
 }


=head1 DESCRIPTION

CGI::Application::Plugin::LogDispatch adds logging support to your L<CGI::Application>
modules by providing a L<Log::Dispatch> dispatcher object that is accessible from
anywhere in the application.

If you have L<CGI::Application::Plugin::DevPopup> installed, a "Log Entries"
report is added to the popup window, containing all of the entries that were
logged during the execution of the runmode.  

=head1 METHODS

=head2 log

This method will return the current L<Log::Dispatch> dispatcher object.  The L<Log::Dispatch>
object is created on the first call to this method, and any subsequent calls will return the
same object.  This effectively creates a singleton log dispatcher for the duration of the request.
If C<log_config> has not been called before the first call to C<log>, then it will choose some
sane defaults to create the dispatcher object (the exact default values are defined below).

  # retrieve the log object
  my $log = $self->log;
  $log->warning("something's not right!");
  $log->emergency("It's all gone pear shaped!");
 
  - or -
 
  # use the log object directly
  $self->log->debug(Data::Dumper::Dumper(\%hash));

  - or - 

  # if you configured it as a singleton
  My::App->log->debug('This works too');


=head2 log_config

This method can be used to customize the functionality of the CGI::Application::Plugin::LogDispatch module.
Calling this method does not mean that a new L<Log::Dispatch> object will be immediately created.
The log object will not be created until the first call to $self->log.

The recommended place to call C<log_config> is in the C<cgiapp_init>
stage of L<CGI::Application>.  If this method is called after the log object
has already been accessed, then it will die with an error message.

If this method is not called at all then a reasonable set of defaults
will be used (the exact default values are defined below).

The following parameters are accepted:

=over 4

=item LOG_DISPATCH_OPTIONS

This allows you to customize how the L<Log::Dispatch> object is created by providing a hash of
options that will be passed to the L<Log::Dispatch> constructor.  Please see the documentation
for L<Log::Dispatch> for the exact syntax of the parameters.  Surprisingly enough you will usually
not need to use this option, instead look at the LOG_DISPATCH_MODULES option.

 LOG_DISPATCH_OPTIONS => {
      callbacks => sub { my %h = @_; return time().': '.$h{message}; },
 }

=item LOG_DISPATCH_MODULES

This option allows you to specify the Log::Dispatch::* modules that you wish to use to
log messages.  You can list multiple dispatch modules, each with their own set of options.  Format
the options in an array of hashes, where each hash contains the options for the Log::Dispatch::
module you are configuring and also include a 'module' parameter containing the name of the
dispatch module.  See below for an example.  You can also add an 'append_newline' option to
automatically append a newline to each log entry for this dispatch module (this option is
not needed if you already specified the APPEND_NEWLINE option listed below which will add
a newline for all dispatch modules).

 LOG_DISPATCH_MODULES => [ 
   {         module => 'Log::Dispatch::File',
               name => 'messages',
           filename => '/tmp/messages.log',
          min_level => 'info',
     append_newline => 1
   },
   {         module => 'Log::Dispatch::Email::MailSend',
               name => 'email',
                 to => [ qw(foo@bar.com bar@baz.org ) ],
             subject => 'Oh No!!!!!!!!!!',
          min_level => 'emerg'
   }
 ]

=item APPEND_NEWLINE

By default Log::Dispatch does not append a newline to the end of the log messages.  By setting
this option to a true value, a newline character will automatically be added to the end
of the log message.

 APPEND_NEWLINE => 1

=item LOG_METHOD_EXECUTION (EXPERIMENTAL)

This option will allow you to log the execution path of your program.  Set LOG_METHOD_EXECUTION to
a list of all the modules you want to be logged.  This will automatically send a debug message at
the start and end of each method/function that is called in the modules you listed.
The parameters passed, and the return value will also be logged.  This can be useful by tracing the
program flow in the logfile without having to resort to the debugger.

 LOG_METHOD_EXECUTION => [qw(__PACKAGE__ CGI::Application CGI)],

WARNING:  This hasn't been heavily tested, although it seems to work fine for me.  Also, a closure
is created around the log object, so some care may need to be taken when using this in a
persistent environment like mod_perl.  This feature depends on the L<Sub::WrapPackages> module.

=back

=head2 DEFAULT OPTIONS

The following example shows what options are set by default (ie this is what you
would get if you do not call log_config).  A single Log::Dispatch::Screen module that writes
error messages to STDERR with a minimum log level of debug.

 $self->log_config(
   LOG_DISPATCH_MODULES => [ 
     {        module => 'Log::Dispatch::Screen',
                name => 'screen',
              stderr => 1,
           min_level => 'debug',
      append_newline => 1
     }
   ],
 );

Here is a more customized example that uses two file appenders, and an email gateway.
Here all debug messages are sent to /tmp/debug.log, and all messages above are sent
to /tmp/messages.log.  Also, any emergency messages are emailed to foo@bar.com and 
bar@baz.org.

 $self->log_config(
   LOG_DISPATCH_MODULES => [ 
     {    module => 'Log::Dispatch::File',
            name => 'debug',
        filename => '/tmp/debug.log',
       min_level => 'debug',
       max_level => 'debug'
     },
     {    module => 'Log::Dispatch::File',
            name => 'messages',
        filename => '/tmp/messages.log',
       min_level => 'info'
     },
     {    module => 'Log::Dispatch::Email::MailSend',
            name => 'email',
              to => [ qw(foo@bar.com bar@baz.org ) ],
          subject => 'Oh No!!!!!!!!!!',
       min_level => 'emerg'
     }
   ],
   APPEND_NEWLINE => 1,
 );
 

=head1 EXAMPLE

In a CGI::Application module:

  
  # configure the log modules once during the init stage
  sub cgiapp_init {
    my $self = shift;
 
    # Configure the session
    $self->log_config(
      LOG_DISPATCH_MODULES => [ 
        {    module => 'Log::Dispatch::File',
               name => 'messages',
           filename => '/tmp/messages.log',
          min_level => 'error'
        },
        {    module => 'Log::Dispatch::Email::MailSend',
               name => 'email',
                 to => [ qw(foo@bar.com bar@baz.org ) ],
             subject => 'Oh No!!!!!!!!!!',
          min_level => 'emerg'
        }
      ],
      APPEND_NEWLINE => 1,
    );
 
  }
 
  sub cgiapp_prerun {
    my $self = shift;
 
    $self->log->debug("Current runmode:  ".$self->get_current_runmode);
  }
 
  sub my_runmode {
    my $self = shift;
    my $log  = $self->log;

    if ($ENV{'REMOTE_USER'}) {
      $log->info("user ".$ENV{'REMOTE_USER'});
    }

    # etc...
  }

=head1 SINGLETON SUPPORT

This module can be used as a singleton object.  This means that when the object
is created, it will remain accessable for the duration of the process.  This can
be useful in persistent environments like mod_perl and PersistentPerl, since the
object only has to be created one time, and will remain in memory across multiple
requests.  It can also be useful if you want to setup a DIE handler, or WARN handler,
since you will not have access to the $self object.

To use this module as a singleton you need to provide all configuration parameters
as options to the use statement.  The use statement will accept all the same parameters
that the log_config method accepts, so see the documentation above for more details.

When creating the singleton, the log object will be saved in the namespace of the
module that created it.  The singleton will also be inherited by any subclasses of
this module.

NOTE:  Singleton support requires the Class::ISA module which is not installed
automatically by this module.

=head1 SINGLETON EXAMPLE

  package My::App;
  
  use base qw(CGI::Application);
  use CGI::Application::Plugin::LogDispatch(
      LOG_DISPATCH_MODULES => [ 
        {    module => 'Log::Dispatch::File',
               name => 'messages',
           filename => '/tmp/messages.log',
          min_level => 'error'
        },
      ],
      APPEND_NEWLINE => 1,
    );
 
  }
 
  sub cgiapp_prerun {
    my $self = shift;
 
    $self->log->debug("Current runmode:  ".$self->get_current_runmode);
  }
 
  sub my_runmode {
    my $self = shift;
    my $log  = $self->log;

    if ($ENV{'REMOTE_USER'}) {
      $log->info("user ".$ENV{'REMOTE_USER'});
    }

    # etc...
  }

  package My::App::Subclass;

  use base qw(My::App);

  # Setup a die handler that uses the logger
  $SIG{__DIE__} = sub { My::App::Subclass->log->emerg(@_); CORE::die(@_); };

  sub my_other_runmode {
    my $self = shift;

    $self->log->info("This will log to the logger configured in My::App");
  }


=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-logdispatch@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

L<CGI::Application>, L<Log::Dispatch>, L<Log::Dispatch::Screen>, L<Sub::WrapPackages>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENSE

Copyright (C) 2004 Cees Hek <ceeshek@gmail.com>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

