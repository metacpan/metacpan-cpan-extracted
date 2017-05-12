package Catalyst::Plugin::AccessLog;
# ABSTRACT: Request logging from within Catalyst
our $VERSION = '1.10'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

use namespace::autoclean;
use Moose::Role;
use Scalar::Util qw(reftype blessed);
use Catalyst::Utils;

after 'setup_finalize' => sub { # Init ourselves
  my $c = shift;
  my $default_config = {
    formatter => {
      class => 'Catalyst::Plugin::AccessLog::Formatter',
    },
    hostname_lookups => 0,
    enable_stats => 1,
    target => \*STDERR,
  };

  my $config = $c->config->{'Plugin::AccessLog'} = Catalyst::Utils::merge_hashes(
    $default_config,
    $c->config->{'Plugin::AccessLog'}
  );

  if (!ref $config->{target}) {
    open my $output, '>>', $config->{target} or die qq[Error opening "$config->{target}" for log output];
    select((select($output), $|=1)[0]);
    $config->{target} = $output;
  }

  Catalyst::Utils::ensure_class_loaded( $config->{formatter}{class} );

};

override 'use_stats' => sub {
  my ($c) = @_;
  if ($c->config->{'Plugin::AccessLog'}{enable_stats}) {
    return 1;
  } else {
    return super;
  }
};

sub access_log_write {
  my $c = shift;
  my $output = join "", @_;
  $output .= "\n" unless $output =~ /\n\Z/;

  my $target = $c->config->{'Plugin::AccessLog'}{target};
  if (reftype($target) eq 'GLOB' or blessed($target) && $target->isa('IO::Handle')) {
    print $target $output;
  } elsif (reftype($target) eq 'CODE') {
    $target->($output, $c);
  } elsif ($target->can('info')) { # Logger object
    $target->info($output);
  } else {
    warn "Don't know how to log to config->{'Plugin::AccessLog'}{target}";
  }
}

after 'finalize' => sub {
  my $c = shift;
  my $config = $c->config->{'Plugin::AccessLog'};

  my %formatter_opts = %{ $config->{formatter} };
  my $formatter_class = delete $formatter_opts{class};
  my $formatter = $formatter_class->new( %formatter_opts );

  my $line = $formatter->format_line($c);
  $c->access_log_write($line);
};

1;

=head1 DEPRECATION NOTICE

This module doesn't work well on Catalyst 5.9 or above, and no longer
passes its tests. Repairing it isn't possible. Using this module for
anything new isn't recommended; use L<Plack::Middleware::AccessLog> or log
at the proxy layer. It remains online in support of existing users.

=head1 SYNOPSIS

Requires Catalyst 5.8 or above.

    # In lib/MyApp.pm context
    use Catalyst qw(
        ConfigLoader
        -Stats=1
        AccessLog
        ... other plugins here ...
    );

    __PACKAGE__->config(
        'Plugin::AccessLog' => {
            formatter => {
              format => '%[time] %[remote_address] %[path] %[status] %[size]',
              time_format => '%c',
              time_zone => 'America/Chicago',
            },
        }
    );

    __PACKAGE__->setup();

=head1 DESCRIPTION

This plugin isn't for "debug" logging. Instead it enables you to create
"access logs" from within a Catalyst application instead of requiring a
webserver to do it for you. It will work even with Catalyst debug logging
turned off (but see C<enable_stats> below).

=head1 CONFIGURATION

All configuration is optional; by default the plugin will log to STDERR in a
format compatible with the "Common Log Format"
(L<http://en.wikipedia.org/wiki/Common_Log_Format>).

=over 4

=item target

B<Default:> C<\*STDERR>

Where to log to. If C<target> is a filehandle or something that 
C<< isa("IO::Handle") >>, lines of logging information will be C<print>ed to
it. If C<target> is an object with an C<info> method it's assumed to be a
logging object (e.g. L<Log::Dispatch> or L<Log::Log4perl>) and lines will be
passed to the C<info> method. If it's a C<CODE> ref then it will be called
with each line of logging output. If it's an unblessed scalar it will be
interpreted as a filename and the plugin will try to open it for append
and write lines to it.

=item formatter

B<Default:> C<< { class => "Catalyst::Plugin::AccessLog::Formatter" } >>

The formatter to use. Defaults to the Formatter class included in this
distribution. This option must be a hashref. The C<class> option is taken as
the name of the class to use as the formatter; all other keys are passed to
that class's constructor. See L<Catalyst::Plugin::AccessLog::Formatter> for
the keys supported by that module.

=item enable_stats

B<Default:> B<true>

C<Catalyst::Plugin::AccessLog> works without regard to Catalyst's debug
logging option. However, the time-related escapes are only available if the
C<Catalyst::Stats> statistics collection is enabled, and by default stats are
tied to the value of the debug flag. If this option is set, stats will be
enabled for the application regardless of the C<-Stats> or C<-Debug> flags, or
the C<MYAPP_STATS> or C<MYAPP_DEBUG> environment variables.

=back

=head1 NOTES

=head2 Logging to C<< $c->log >>

It is generally not recommended to write the access log to C<< $c->log >>,
especially if static file handling is enabled. However, there might be a
good reason to do it somewhere. If the logging target is a coderef, it will
receive C<$c> as its second argument. You can log to C<< $c->log >> with:

    target => sub { pop->log->info(shift) }

Don't store C<$c> anywhere that persists after the lifetime of the coderef
or bad things will happen to you and everyone you know.

=head1 SOURCE, BUGS, ETC.

L<http://github.com/arodland/Catalyst-Plugin-AccessLog>

=cut
