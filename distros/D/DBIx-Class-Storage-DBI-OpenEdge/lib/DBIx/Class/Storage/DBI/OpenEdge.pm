package DBIx::Class::Storage::DBI::OpenEdge;

our $VERSION = '0.02';

use strict;
use warnings;
use base 'DBIx::Class::Storage::DBI';

__PACKAGE__->sql_limit_dialect('GenericSubQ');

sub sqlt_type { 'OPENEDGE' }

1;

__END__

=head1 NAME

DBIx::Class::Storage::DBI::OpenEdge - Support for OpenEdge Advance Server

=head1 DESCRIPTION

This is the base class for Progress Sofware's OpenEdge Advance Server database
product. It requires the OpenEdge Client package to be installed to be usable. 

=head1 SUPPORTED VERSIONS

This module should be compatiable with the client libraries for OpenEdge
Advance Server 10.2b and later.

=head1 AUTHOR

Kevin L. Esteb, C<< <kesteb at wsipc.org> >>

=head1 BUGS

Certainly many, since this is a cut and paste job and only tested under Windows.
It's primmary mission is to remove annoying warnings from DBIx::Class.
But please report any bugs or feature requests to C<bug-dbix-class-storage-dbi-openedge at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Storage-DBI-OpenEdge>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Storage::DBI::OpenEdge

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Storage-DBI-OpenEdge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Storage-DBI-OpenEdge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Storage-DBI-OpenEdge>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Storage-DBI-OpenEdge/>

=back

=head1 ACKNOWLEDGEMENTS

Modeled after the DBIx::Class::Storage::DBI::ACCESS module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Kevin L. Esteb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
