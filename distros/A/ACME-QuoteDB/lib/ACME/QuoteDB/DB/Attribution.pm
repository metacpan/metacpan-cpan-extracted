#$Id: Attribution.pm,v 1.12 2009/09/30 07:37:09 dinosau2 Exp $
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */

package ACME::QuoteDB::DB::Attribution;
use base 'ACME::QuoteDB::DB::DBI';

use 5.008005;        # require perl 5.8.5, re: DBD::SQLite Unicode
use warnings;
use strict;

#use criticism 'brutal'; # use critic with a ~/.perlcriticrc

use version; our $VERSION = qv('0.1.0');

ACME::QuoteDB::DB::Attribution->table('attribution');
ACME::QuoteDB::DB::Attribution->columns(All    => qw/attr_id name/);
ACME::QuoteDB::DB::Attribution->has_many(quote => 'ACME::QuoteDB::DB::Quote');

1;
__END__

=head1 NAME

ACME::QuoteDB::DB::Attribution - Class::DBI For ACME::QuoteDB

=head1 VERSION

Version 0.1.0


=head1 SYNOPSIS

This module is not meant to be used standalone it is used by C<ACME::QuoteDB>;

see L<ACME::QuoteDB>


=head1 DESCRIPTION

This module is not meant to be used standalone it is used by C<ACME::QuoteDB>;

see L<ACME::QuoteDB>

see L<Class::DBI>

=head1 OVERVIEW

see L<ACME::QuoteDB>

See L<Description|/Description> above

=head1 USAGE

See Synopsis

Also see t/01* included with the distribution.
(available from the CPAN if not included on your system)

=head1 SUBROUTINES/METHODS

see L<ACME::QuoteDB>


=head1 DIAGNOSTICS

None currently known


=head1 CONFIGURATION AND ENVIRONMENT

if you are running perl > 5.8.5 and have access to
install cpan modules, you should have no problem installing this module

=head1 DEPENDENCIES

L<version>(pragma - version numbers)

L<Class::DBI>

L<DBD::SQLite>

=head1 INCOMPATIBILITIES

none known of

=head1 SEE ALSO

L<ACME::QuoteDB>

L<Class::DBI>

=head1 AUTHOR

David Wright, C<< <david_v_wright at yahoo.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-acme-thesimpsonsquotes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ACME-QuoteDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ACME::QuoteDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ACME-QuoteDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ACME-QuoteDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ACME-QuoteDB>

=item * Search CPAN

L<http://search.cpan.org/dist/ACME-QuoteDB/>

=back


=head1 LICENSE AND COPYRIGHT


Copyright 2009 David Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



