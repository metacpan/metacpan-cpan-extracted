package Configd::Language::opendmarc;
$Configd::Language::opendmarc::VERSION = '0.005';
#ABSTRACT: opendmarc.conf, which has never had a conf.d.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use parent qw{Configd::Syntax::Spaced};


sub files {
    return ( { path => '/etc/opendmarc.conf', mode => 0o600, owner => 'opendmarc:opendmarc' } );
}

sub units {
    return ('opendmarc.service');
}


sub accumulates {
    my ( $self, $key ) = @_;
    return $key eq 'TrustedAuthservIDs';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Language::opendmarc - opendmarc.conf, which has never had a conf.d.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Configd();

    Configd->adopt('opendmarc');
    Configd->build('opendmarc');

=head1 DESCRIPTION

The same file, the same problem, and the same shape as opendkim's: a
directive, some whitespace, and the rest of the line.

=head1 NAME

Configd::Language::opendmarc - opendmarc.conf, which has never had a conf.d.

=head1 METHODS

=head2 files()

F</etc/opendmarc.conf>, 0600 opendmarc:opendmarc if it has to be created.

=head2 units()

C<opendmarc.service>.

=head2 accumulates($key)

True for C<TrustedAuthservIDs>, a comma-separated list.  One opendmarc
serves every domain on the host, and each domain can name the ids that it
trusts, so a later fragment adds to the list.  C<AuthservID> is one name, the
one that opendmarc writes its own verdicts under, so the later fragment wins.
The comma of the base class is the separator.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Language>, L<Configd::Syntax::Spaced>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
