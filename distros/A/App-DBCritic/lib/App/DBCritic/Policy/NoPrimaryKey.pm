package App::DBCritic::Policy::NoPrimaryKey;

use strict;
use utf8;
use Modern::Perl;

our $VERSION = '0.020';    # VERSION
use Moo;
use Sub::Quote;
use namespace::autoclean -also => qr{\A _}xms;

has description => ( is => 'ro', default => quote_sub q{'No primary key'} );
has explanation => (
    is      => 'ro',
    default => quote_sub
        q{'Tables should have one or more columns defined as a primary key.'},
);

sub violates {
    my $source = shift->element;
    return $source->name . ' has no primary key' if !$source->primary_columns;
    return;
}

with 'App::DBCritic::PolicyType::ResultSource';
1;

# ABSTRACT: Check for DBIx::Class::Schema::ResultSources without primary keys

__END__

=pod

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders

=encoding utf8

=head1 NAME

App::DBCritic::Policy::NoPrimaryKey - Check for DBIx::Class::Schema::ResultSources without primary keys

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use App::DBCritic;

    my $critic = App::DBCritic->new(
        dsn => 'dbi:Oracle:HR', username => 'scott', password => 'tiger');
    $critic->critique();

=head1 DESCRIPTION

This policy returns a violation if a
L<DBIx::Class::ResultSource|DBIx::Class::ResultSource> has zero primary columns.

=head1 ATTRIBUTES

=head2 description

"No primary key"

=head2 explanation

"Tables should have one or more columns defined as a primary key."

=head2 applies_to

This policy applies to L<ResultSource|DBIx::Class::ResultSource>s.

=head1 METHODS

=head2 violates

Returns details if the
L<"current element"|App::DBCritic::Policy>'s C<primary_columns>
method returns nothing.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc bin::dbcritic

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-DBCritic>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/App-DBCritic>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-DBCritic>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/App-DBCritic>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-DBCritic>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=App-DBCritic>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=bin::dbcritic>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/dbcritic/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/dbcritic>

  git clone git://github.com/mjgardner/dbcritic.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
