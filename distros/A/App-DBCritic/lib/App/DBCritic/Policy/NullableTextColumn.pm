package App::DBCritic::Policy::NullableTextColumn;

# ABSTRACT: Check for ResultSources with nullable text columns

#pod =head1 SYNOPSIS
#pod
#pod     use App::DBCritic;
#pod
#pod     my $critic = App::DBCritic->new(
#pod         dsn => 'dbi:Oracle:HR', username => 'scott', password => 'tiger');
#pod     $critic->critique();
#pod
#pod =head1 DESCRIPTION
#pod
#pod This policy returns a violation if a
#pod L<DBIx::Class::ResultSource|DBIx::Class::ResultSource> has nullable text
#pod columns.
#pod
#pod =cut

use strict;
use utf8;
use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.023';     # VERSION
use DBI ':sql_types';
use English '-no_match_vars';
use List::Util 1.33 'any';
use Moo;
use Sub::Quote;
use namespace::autoclean -also => qr{\A _}xms;

has description => (
    is      => 'ro',
    default => quote_sub q{'Nullable text column'},
);

#pod =attr description
#pod
#pod "Nullable text column"
#pod
#pod =cut

has explanation => (
    is      => 'ro',
    default => quote_sub
        q{'Text columns should not be nullable. Default to empty string instead.'},
);

#pod =attr explanation
#pod
#pod "Text columns should not be nullable. Default to empty string instead."
#pod
#pod =cut

sub violates {
    my $source = shift->element;

    ## no critic (ProhibitAccessOfPrivateData,ProhibitCallsToUndeclaredSubs)
    my @text_types = (
        qw(TEXT NTEXT CLOB NCLOB CHARACTER CHAR NCHAR VARCHAR VARCHAR2 NVARCHAR2),
        'CHARACTER VARYING',
        map     { uc $_->{TYPE_NAME} }
            map { $source->storage->dbh->type_info($_) } (
            SQL_CHAR,        SQL_CLOB,
            SQL_VARCHAR,     SQL_WVARCHAR,
            SQL_LONGVARCHAR, SQL_WLONGVARCHAR,
            ),
    );

    my %column = %{ $source->columns_info };
    return join "\n", map {"$_ is a nullable text column."} grep {
        my $col = $_;
        any { uc( $column{$col}{data_type} // q{} ) eq $_ } @text_types
            and $column{$col}{is_nullable};
    } keys %column;
}

#pod =method violates
#pod
#pod Returns details of each column from the
#pod L<"current element"|App::DBCritic::Policy> that maps to
#pod following data types and
#pod L<"is nullable"|DBIx::Class::ResultSource/is_nullable>:
#pod
#pod =over
#pod
#pod =item C<TEXT>
#pod
#pod =item C<NTEXT>
#pod
#pod =item C<CLOB>
#pod
#pod =item C<NCLOB>
#pod
#pod =item C<CHARACTER>
#pod
#pod =item C<CHAR>
#pod
#pod =item C<NCHAR>
#pod
#pod =item C<VARCHAR>
#pod
#pod =item C<VARCHAR2>
#pod
#pod =item C<NVARCHAR2>
#pod
#pod =item C<CHARACTER VARYING>
#pod
#pod =item C<SQL_CHAR>
#pod
#pod =item C<SQL_CLOB>
#pod
#pod =item C<SQL_VARCHAR>
#pod
#pod =item C<SQL_WVARCHAR>
#pod
#pod =item C<SQL_LONGVARCHAR>
#pod
#pod =item C<SQL_WLONGVARCHAR>
#pod
#pod =back
#pod
#pod =cut

with 'App::DBCritic::PolicyType::ResultSource';

#pod =attr applies_to
#pod
#pod This policy applies to L<ResultSource|DBIx::Class::ResultSource>s.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

App::DBCritic::Policy::NullableTextColumn - Check for ResultSources with nullable text columns

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use App::DBCritic;

    my $critic = App::DBCritic->new(
        dsn => 'dbi:Oracle:HR', username => 'scott', password => 'tiger');
    $critic->critique();

=head1 DESCRIPTION

This policy returns a violation if a
L<DBIx::Class::ResultSource|DBIx::Class::ResultSource> has nullable text
columns.

=head1 ATTRIBUTES

=head2 description

"Nullable text column"

=head2 explanation

"Text columns should not be nullable. Default to empty string instead."

=head2 applies_to

This policy applies to L<ResultSource|DBIx::Class::ResultSource>s.

=head1 METHODS

=head2 violates

Returns details of each column from the
L<"current element"|App::DBCritic::Policy> that maps to
following data types and
L<"is nullable"|DBIx::Class::ResultSource/is_nullable>:

=over

=item C<TEXT>

=item C<NTEXT>

=item C<CLOB>

=item C<NCLOB>

=item C<CHARACTER>

=item C<CHAR>

=item C<NCHAR>

=item C<VARCHAR>

=item C<VARCHAR2>

=item C<NVARCHAR2>

=item C<CHARACTER VARYING>

=item C<SQL_CHAR>

=item C<SQL_CLOB>

=item C<SQL_VARCHAR>

=item C<SQL_WVARCHAR>

=item C<SQL_LONGVARCHAR>

=item C<SQL_WLONGVARCHAR>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::DBCritic::Policy::NullableTextColumn

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-DBCritic>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-DBCritic>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-DBCritic>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-DBCritic>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

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

This software is copyright (c) 2019 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
