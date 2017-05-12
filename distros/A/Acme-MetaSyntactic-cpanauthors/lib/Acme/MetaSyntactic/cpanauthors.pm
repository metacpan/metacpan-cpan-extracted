package Acme::MetaSyntactic::cpanauthors;
$Acme::MetaSyntactic::cpanauthors::VERSION = '1.001';
use strict;
use Acme::MetaSyntactic::MultiList;
use Acme::CPANAuthors;
our @ISA = qw( Acme::MetaSyntactic::MultiList );

my %names = (
    map {
        lc $_ => map { tr/-/_/; $_ } join ' ', Acme::CPANAuthors->new($_)->id
        } Acme::CPANAuthors->_list_categories()
);

# protect against empty categories (Acme::CPANAuthors::Dutch)
delete $names{$_} for grep !$names{$_}, keys %names;

__PACKAGE__->init( { default => ':all', names => \%names } );

1;

__END__

=head1 NAME

Acme::MetaSyntactic::cpanauthors - We are CPAN authors, and metasyntactic!

=head1 DESCRIPTION

CPAN authors come in all shapes and sizes. The L<Acme::CPANAuthors>
series of modules aims at grouping them by various criteria. These lists
are then used to provide statistics on L<http://acme.cpanauthors.org/>.

This theme has a category per I<installed> L<Acme::CPANAuthors> category,
with the name spelt in lowercase (i.e. if L<Acme::CPANAuthors::French> is
installed, then Acme::MetaSyntactic::cpanauthors will have a C<french>
category).

=head1 CONTRIBUTOR

Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2014-06-03 - v1.001

Fixed the categories to be all lowercase, and the names to be in uppercase
(as in PAUSE). Published one day late because of a disk crash.

=item *

2014-05-26 - v1.000

First release. And if all goes well, the last.

=item *

2013-04-30

Publicly mentioned on irc.perl.org #perlfr as module I could release any time.

=back

=head1 SEE ALSO

L<Acme::CPANAuthors>, L<Task::CPANAuthors>,
L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut
