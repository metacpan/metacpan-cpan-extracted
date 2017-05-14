# Tau. Twice the Pie.
package Acme::Tau;
use 5.018;
use warnings;
use Acme::Pi;
use utf8;
my $tau = $Acme::Pi::VERSION * 2; $Acme::Tau::VERSION = "$tau";
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Tau - Twice the Pie

=head1 VERSION

Version 6.28318530717958

=head1 SYNOPSIS

    use Acme::Tau;
    my $tau = Acme::Tau->VERSION;

=head1 DESCRIPTION

The τ that is τ is not the true τ. This is only a copy.

=head1 SEE ALSO

L<Acme::Pi>, L<http://tauday.com/>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Jeremy Mates.

This program is distributed under the MIT (X11) License.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
