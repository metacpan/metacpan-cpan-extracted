package Acme::Be::Modern;

use Modern::Perl;

use Filter::Util::Call;

=encoding utf-8

=head1 NAME

Acme::Be::Modern - enables your script to "be modern"

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This is a thin (and stupid) wrapper (actually a source filter) around
L<Modern::Perl>. It makes it possible to write 'be modern' instead of
'use Modern::Perl' - like this:

    use Acme::Be::Modern;

    be modern; # all lowercase is actually postmodern :-/
    ...

=cut

=head1 WARNING

The source filter (defined in the L<Acme::Be::Modern::filter> sub is
simply a naive search-and-replace. Don't use this in any real code.

=head1 IMPLEMENTATION

The implementation is a slight variation of the example in
L<perlfilter>. It's implemented using two functions:

=head2 import

This will be called after L<Acme::Be::Modern> has been loaded. Simply
calls filter_add() with a blessed reference. Now the filter is
activated.

=cut

sub import {
    my ($type) = @_;
    my ($ref) = [];
    filter_add(bless $ref);
}


=head2 filter

The actual filter. Will receive source lines by calling
filter_read(). Any occurrence (and I mean any) of 'be modern' will be
replace with 'use Modern::Perl'.

=cut

sub filter {
    my ($self) = @_;
    my ($status);
    s/be modern/use Modern::Perl/g if ($status = filter_read()) > 0;
    $status;
}

=head1 AUTHOR

Søren Lund, C<< <slu at cpan.org> >>

=head1 BUGS

Yes! This is buggy. It's a source filter, and it's really stupid. Any
text in your source matching 'be modern' will be replaced with 'use
Modern::Perl'.

Please report any bugs or feature requests to C<bug-acme-be-modern at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Be-Modern>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Be::Modern


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Be-Modern>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Be-Modern>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Be-Modern>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Be-Modern/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Søren Lund.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1; # End of Acme::Be::Modern
