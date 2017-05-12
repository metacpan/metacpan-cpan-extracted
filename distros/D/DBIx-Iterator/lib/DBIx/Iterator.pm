use strict;
use warnings;
package DBIx::Iterator;
{
  $DBIx::Iterator::VERSION = '0.0.2';
}

# ABSTRACT: Query your database using iterators and save memory

use Carp qw(confess);
use DBIx::Iterator::Statement;


sub new {
    my ($class, $dbh) = @_;
    confess("Please specify a database handle") unless defined $dbh;
    return bless {
        'dbh' => $dbh,
    }, $class;
}


sub dbh {
    my ($self) = @_;
    return $self->{'dbh'};
}


sub prepare {
    my ($self, $query) = @_;
    confess("Please specify a database query") unless defined $query;
    return DBIx::Iterator::Statement->new($query, $self);
}


sub query {
    my ($self, $query, @placeholder_values) = @_;
    confess("Please specify a query") unless defined $query;
    return $self->prepare($query)->execute(@placeholder_values);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

DBIx::Iterator - Query your database using iterators and save memory

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    # Create an iterator for a simple DBI query
    my $db = DBIx::Iterator->new( DBI->connect('...') );
    my $it = $db->query("SELECT id, name FROM person");
    while ( my $row = $it->() ) {
        say $row->{'id'} . ": " . $row->{'name'};
        # Do something with $row...
    }

    # We have a basic class here that knows nothing about iterators
    package Person;
    use Moose;

    has 'id'   => ( is => 'ro', isa => 'Int' );
    has 'name' => ( is => 'ro', isa => 'Str' );

    sub label {
        my ($self) = @_;
        return $self->id . ": " . $self->name;
    }

    # Then we have a role that knows how to create instances
    # from iterators
    package FromIterator;
    use Moose::Role;

    sub new_from_iterator {
        my ($self, $it) = @_;
        return sub {
            my $row = $it->();
            return unless defined $row;
            return $self->new($row);
        }
    }

    # Then we apply the role to the Person class and use
    # our plain database iterator that produces hashes to
    # now create Person instances instead.

    package main;
    use Moose::util qw(apply_all_roles);
    my $p = apply_all_roles('Person', 'FromIterator');
    my $it = $p->new_from_iterator(
        $db->query("SELECT * FROM person")
    );
    while ( my $person = $it->() ) {
        say $person->label;
        # Do something with $person...
    }

=head1 DESCRIPTION

Iterators are a nice way to perform operations on large datasets without
having to keep all of the data you're working on in memory at the same time.
Most people have experience with iterators already from working with
filehandles.  They are basically iterators hidden behind a somewhat odd
syntax.  This module gives you the same way of executing database queries.

The trivial example at the start of the synopsis is not very different from
using L<DBI/fetchrow_hashref> directly to retrieve your database rows.  But
when we look at the second example we can start to see how it allows much
cleaner separation of concerns without having to modify the core class
(Person) to support iterators or database interaction at all.

For more information about iterators and how they can work for you, have a
look at chapter 4 in the book Higher-Order Perl mentioned below.  It is free
to download and highly recommended.

=head1 METHODS

=head2 new($dbh)

Creates a new iterator factory connected to the specified database handle.

=head2 dbh

Returns the database handle provided to new().

=head2 prepare($query)

Asks the database engine to parse the query and return a statement object
that can be used to execute the query with optional parameters.

=head2 query($query, @placeholder_values)

Executes the query with the optional placeholder values.  Returns a code
reference you can execute until it is exhausted.  If called in list context,
it will also return a reference to the statement object itself.  The
iterator returns exactly what L<DBI/fetchrow_hashref> returns.  When the
iterator is exhausted it will return undef.

=head1 SEE ALSO

=over 4

=item *

L<Higher-Order Perl by Mark Jason Dominus, page 163-173|http://hop.perl.plover.com/>

=item *

L<Iterator>

=back

=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc DBIx::Iterator

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/DBIx-Iterator>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/DBIx-Iterator>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Iterator>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/DBIx-Iterator>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/DBIx-Iterator>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/DBIx-Iterator>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/DBIx-Iterator>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/DBIx-Iterator>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=DBIx-Iterator>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=DBIx::Iterator>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dbix-iterator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Iterator>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/robinsmidsrod/DBIx-Iterator>

  git clone git://github.com/robinsmidsrod/DBIx-Iterator.git

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
