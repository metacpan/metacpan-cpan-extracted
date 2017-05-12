# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Apache::Wombat::Logger;

=pod

=head1 NAME

Apache::Wombat::Logger - Apache server logger class

=head1 SYNOPSIS

  use Apache::Log ();
  my $slog = Apache->server()->log();

  my $logger = Apache::Wombat::Logger->new($slog);
  $logger->log("this will show up in the httpd ErrorLog");

=head1 DESCRIPTION

Logger class that writes messages to the Apache ErrorLog.

=cut

use base qw(Wombat::Logger::LoggerBase);
use fields qw(slog);
use strict;
use warnings;

use Apache ();
use Apache::Log ();
use Symbol ();
use Wombat::Exception ();

# map Wombat::Logger log levels to Apache log levels
use constant METHODS => {
                         FATAL => 'emerg',
                         ERROR => 'error',
                         WARN => 'warn',
                         INFO => 'info',
                         DEBUG => 'debug',
                        };

=pod

=head1 CONSTRUCTOR

=over

=item new($slog)

Construct and return a B<Apache::Wombat::Logger> instance using
the specified Apache server log.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{slog} = Apache->server()->log();

    return $self;
}

=pod

=head1 PUBLIC METHODS

=over

=item write($string)

Write the specified string to the Apache server log.

B<Parameters:>

=over

=item $string

the string to write

=back

=cut

sub write {
    my $self = shift;
    my $msg = shift;
    my $method = shift;

    if ($method) {
        $self->{slog}->$method("[$$] $msg");
    } else {
        Apache::log_error("[$$] $msg");
    }

    return 1;
}

# privately override log() to pass in the name of the Apache log
# method corresponding to the passed in Wombat log level

sub log {
    my $self = shift;
    my $msg = shift;
    my $e = shift;
    my $level = shift;

    my $method = METHODS->{$level} if $level;
    $self->write("$msg", $method) if $msg;

    if ($e) {
        $self->write($e, $method);

        if ($e->isa('Servlet::ServletException')) {
            my $root = $e->getRootCause();
            if ($root) {
                $self->write("----- Root Cause -----", $method);
                $self->write($root, $method);
            }
        }
    }

    return 1;
  }

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Logger::LoggerBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
