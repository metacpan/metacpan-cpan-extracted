package App::Kit::Role::Log;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

# ro-NOOP:
#   my $isa_digit = sub { die "Must be all digits!" unless $_[0] =~ m/\A[0-9]+\z/; };
#   has _log_reload_check_time => ( is => 'rw', lazy => 1, isa => $isa_digit, default => sub { time } );    # not rwp so its easier to test
#   has _log_reload_check_every => ( is => 'rw', lazy => 1, isa => $isa_digit, default => sub { 30 } );     # not rwp so its easier to test

has log => (
    is => ( $INC{'App/Kit/Util/RW.pm'} || $ENV{'App-Kit-Util-RW'} ? 'rw' : 'rwp' ),
    lazy    => 1,
    default => sub {
        require Log::Dispatch;
        require Log::Dispatch::Config;

        # ro-NOOP: my ($app, %new) = @_;
        my ($app) = @_;

        my $path = $app->fs->file_lookup( 'config', 'log.conf' );

        if ($path) {

            # Log::Dispatch::Config->configure( $path ); # $app->log->reload; at will

            # since we only call instance() once this would be a noop *except* the wrapper needs it via needs_reload()
            #   (we could bypass via $app->log->{config}->needs_reload but what if the module changes? poof!)
            Log::Dispatch::Config->configure_and_watch($path);

            my $log = Log::Dispatch::Config->instance;

            # ? TODO: optional 'before' log per config file or $app->conf('reload_log')
            # check mtime instead?
            # before 'log' => sub {
            #      if (!$app->_log_reload_check_time() || time() - $app->_log_reload_check_time() < $app->_log_reload_check_every() ) {
            #          $app->_log_reload_check_time(time());
            #          $app->log->reload if $app->log->needs_reload;
            #      }
            # };

            return $log;
        }

        # ro-NOOP: elsif(keys %new) {
        # ro-NOOP:     return Log::Dispatch->new(%new);
        # ro-NOOP: }

        else {
            return Log::Dispatch->new(
                outputs => [ [ "Screen", min_level => "notice", "newline" => 1 ] ],
                callbacks => sub {    # ? TODO break this out into a thing consumable by Log::Dispatch::Config above ?
                    my %info = @_;

                    my $short = $info{'level'};
                    $short = substr( $info{'level'}, 0, 5 ) eq 'emerg' ? 'M' : uc( substr( $short, 0, 1 ) );
                    $short = " ㏒\xc2\xa0$short";    # Unicode: \x{33D2} utf-8: \xe3\x8f\x92

                    # 0 debug
                    # 1 info
                    # 2 notice
                    # 3 warning (warn)
                    # 4 error (err)
                    # 5 critical (crit)
                    # 6 alert
                    # 7 emergency (emerg)

                    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
                    my $time_stamp = sprintf( "%04d-%02d-%02d\xc2\xa0%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

                    my $tap = $app->detect->is_testing ? '#' : '';    # make it TAP safe

                    # TODO: format via $app->output e.g.:
                    # return $app->output->current_indent() . $app->output->short_indent() . $app->output->class($short, $info{'level'}) . ' ' . $app->output->class($time_stamp, 'dim') . $app->output->short_indent() . $app->output->class($info{message}, 'code');
                    return "$tap  $short $time_stamp  $info{message}";
                },
            );
        }
    },
);

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Role::Log - A Lazy Façade method role for logging

=head1 VERSION

This document describes App::Kit::Role::Log version 0.1

=head1 SYNOPSIS

In your class:

   with 'App::Kit::Role::Log';

Then later in your program:

    $app->log->info(…)

=head1 DESCRIPTION

Add lazy façade logging support to your class.

=head1 INTERFACE

This role adds one lazy façade method:

=head2 log()

Returns a L<Log::Dispatch> object for reuse after lazy loading the module.

By default it goes to “Screen” with a minimum level of “notice” and “newline” set to true. The output will be tap safe when run under testing.

The format (after a # for TAP if applicable) and 2 spaces is space separated string of:

=over 4

=item 1. Unicode SQUARE LOG character (bytes == \xe3\x8f\x92), non-break-space (bytes == \xc2\xa0), followed by a one letter version of the level (emerg is M since error already has dibs on E).

=item 2. datetime stamp (YYYY-MM-DD and HH:MM:SS connected via non-break-space (bytes == \xc2\xa0)).

=item 3. The log message.

=back

You can configure it anyway you like via your app’s config/log.conf (i.e. $app->fs->file_lookup( 'config', 'log.conf' )).

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Moo::Role>, L<Log::Dispatch>, L<Log::Dispatch::Config>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
