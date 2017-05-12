use utf8;
package CGI::Carp::StackTrace;
BEGIN {
  $CGI::Carp::StackTrace::AUTHORITY = 'cpan:RKITOVER';
}
{
  $CGI::Carp::StackTrace::VERSION = '0.01';
}

use strict;
use warnings;
use 5.008001;
use CGI::Carp 'fatalsToBrowser';
use Devel::StackTrace::WithLexicals ();
use Devel::StackTrace::AsHTML ();
use HTML::Entities 'decode_entities';

=encoding UTF-8

=head1 NAME

CGI::Carp::StackTrace - install a L<Devel::StackTrace::AsHTML> error screen for your CGI app

=head1 SYNOPSIS

    use Sys::Hostname 'hostname';

    my $IS_PRODUCTION;

    BEGIN {
        $IS_PRODUCTION = hostname() eq 'prod_server';

        require CGI::Carp::StackTrace if not $IS_PRODUCTION;
    }

=head1 DESCRIPTION

Add a modern error screen to your CGI application, like L<Plack::Middleware::StackTrace>.

Uses L<CGI::Carp> in conjunction with L<Devel::StackTrace::WithLexicals> and
L<Devel::StackTrace::AsHTML>.

=cut

BEGIN {
    CGI::Carp::set_message(sub {
        my $stack_trace = Devel::StackTrace::WithLexicals->new(
            message => munge_error(decode_entities(shift), [ caller(3) ]),
            ignore_package => [__PACKAGE__, 'CGI::Carp'],
        );
        print $stack_trace->as_html;
    });
}

# stolen from Plack::Middleware::StackTrace
sub munge_error {
    my($err, $caller) = @_;
    return $err if ref $err;

    # Ugly hack to remove " at ... line ..." automatically appended by perl
    # If there's a proper way to do this, please let me know.
    $err =~ s/ at \Q$caller->[1]\E line $caller->[2]\.\n$//;

    return $err;
}

=head1 SEE ALSO

=over 4

=item * L<Devel::StackTrace>

=item * L<Devel::StackTrace::WithLexicals>

=item * L<Devel::StackTrace::AsHTML>

=item * L<CGI::Carp>

=item * L<Plack::Middleware::StackTrace>

=back

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=head1 ACKNOWLEDGEMENTS

Thanks to Dave Rolsky for L<Devel::StackTrace> and Miyagawa for
L<Devel::StackTrace::AsHTML>.

Some code in this module is stolen from Miyagawa's
L<Plack::Middleware::StackTrace>.

=cut

__PACKAGE__; # End of CGI::Carp::StackTrace
