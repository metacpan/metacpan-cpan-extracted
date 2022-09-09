package CTK::Timeout;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Timeout - Provides execute the code reference wrapped with timeout

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK::Timeout;

    # Create the timeout object
    my $to = CTK::Timeout->new();

    # Execute
    unless ($to->timeout_call(sub { sleep 2 } => 1)) {
        die $to->error if $to->error;
    }

=head1 DESCRIPTION

This class provides execute the code reference wrapped with timeout

=head2 new

Creates the timeout object

    my $to = CTK::Timeout->new();

Creates the timeout object without the POSIX "sigaction" supporting (forced off)

    my $to = CTK::Timeout->new(0);

=head2 error

    die $to->error if $to->error;

Returns error string

=head2 timeout_call

Given a code reference (with optional arguments @args) will execute
as eval-wrapped with a timeout value (in seconds). This method returns
the return-value of the specified code in scalar context

    my $retval = $to->timeout_call(sub { sleep 2 } => 1, "foo", "bar");

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<POSIX>, L<Config>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<DBI/Timeout>, L<Sys::SigAction>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;

$VERSION = "1.00";

use Carp;
use POSIX ':signal_h';
use Config;

# Check POSIX sigaction support
my $USE_POSIX_SIGACTION = 1;
$USE_POSIX_SIGACTION = 0 if $^O =~ /mswin/i or $^O =~ /cygwin/i;
$USE_POSIX_SIGACTION = 0 unless $Config{'useposix'} && $Config{'d_sigaction'};
$USE_POSIX_SIGACTION = 0 if $Config{'archname'} && $Config{'archname'} =~ /^arm/;

sub new {
    my $class = shift;
    my $force = shift;
    my $self = bless {
            error => "",
            use_sigaction => $USE_POSIX_SIGACTION ? $force // 1 : 0,
            use_sigaction_origin => $USE_POSIX_SIGACTION,
        }, $class;
    return $self;
}
sub timeout_call {
    my $self = shift;
    my $code = shift // sub {1};
    my $timeout = shift || 0;
    my @args = @_;
    croak("The code reference incorrect") unless ref($code) eq 'CODE';
    $self->{error} = "";

    my $failed;
    my $retval; # scalar context only!

    # Without timeout
    if (!$timeout) {
        eval {
            $retval = &$code(@args);
            1;
        } or do {
            $self->{error} = $@ if $@;
        };
        return $retval;
    }

    # With timeout
    eval { # outer eval
        my ($mask, $action, $oldaction);
        my $use_sa = $self->{'use_sigaction'};
        my $h = sub { die "Call timed out\n" }; # N.B. \n required
        local $SIG{ALRM} = $h unless $use_sa; # the handler code ref
        if ($use_sa) {
            $mask = POSIX::SigSet->new(SIGALRM); # list of signals to mask in the handler
            $action = POSIX::SigAction->new($h, $mask);
            $oldaction = POSIX::SigAction->new();
            sigaction(SIGALRM, $action, $oldaction);
        }
        eval { # inner eval
            alarm($timeout);
            $retval = &$code(@args);
            alarm(0);
            1;
        } or $failed = 1;
        alarm(0); # cancel alarm (if code ran fast)
        sigaction(SIGALRM, $oldaction) if $use_sa; # restore original signal handler
        die $@ if $failed && $@; # call died
        1;
    } or $failed = 1;
    if ($failed) {
        $self->{error} = $@ if $@;
    }
    return $retval;
}
sub error {
    my $self = shift;
    return $self->{error} // "";
}

1;
