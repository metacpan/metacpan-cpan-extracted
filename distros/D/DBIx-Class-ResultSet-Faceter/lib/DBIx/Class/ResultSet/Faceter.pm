package DBIx::Class::ResultSet::Faceter;
use Moose;

use Class::MOP;
use DBIx::Class::ResultSet::Faceter::Result;
use Try::Tiny;

=head1 NAME

DBIx::Class::ResultSet::Faceter - Faceting for DBIx::Class ResultSets

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  my $faceter = DBIx::Class::ResultSet::Faceter->new;

  # Add a Column facet for the name_last column
  $faceter->add_facet('Column', {
	name => 'Last Name', column => 'name_last'
  });
  # Add more, if you like
  $faceter->add_facet('CodeRef', {
    name => 'Avg Test Score', code => sub { # something fancy }
  });

  # Even for HashRefInflator stuff
  $faceter->add_facet('HashRef', {
    name => 'DoB', key => 'date_of_birth'
  });

  # Pass in a resultset and get a results object
  my $results = $faceter->facet($resultset);


=head1 DESCRIPTION

Faceter is a mechanism for "faceting" a resultset, or counting the occurrences
of certain data.  Faceting is a common search pattern, represented by
the sidebars that tell how how many of your search results fall in a certain
price range or are members of a certain category.

This module allows you to perform these types of operations on the results
of a database query via a L<DBIx::Class::ResultSet>.

=head2 What about GROUP BY?

Using an SQL C<GROUP BY> can do the same things that this module does.  The
reason I've created this module is to allow for more complex situations and
to avoid generating more SQL queries.  Large facet implementations that cover
dozens of dimensions can quickly cause an SQL query to become unweildy.  This
module provides an alternate approach for people who may've run afoul of the
aforementioned problems.

=head1 ATTRIBUTES

=head2 facets

List of facets, keyed by name.

=cut

has 'facets' => (
    traits => [ qw(Hash) ],
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        get_facet => 'get'
    }
);

=head1 METHODS

=head2 add_facet

Add a facet to this faceter.

=cut

sub add_facet {
    my $self = shift;

    my $facet;
    if(scalar(@_) == 1) {
        # If we only have one argument, it has to be something that does facet
        try {
            $_[0]->does('DBIx::Class::ResultSet::Faceter::Facet');
        } catch {
            die 'Single arguments to add_facet must implement the DBIx::Class::Faceter::Facet role';
        }
        $facet = shift;
    } else {
        # If we have anything else we'll assume the first argument is the name
        # of the class and next are arguments to said class.
        my $class = shift;
        my $args = shift;
        die "First argument to add_facet should be a string class name if it isn't an instance" unless defined($class) && !ref($class);

        # Attempt to load the class.  If it has a + on the front, we'll treat
        # it like a fully qualified class name.
        if($class =~ /^\+/) {
            # Strip off the unary plus and load that
            $class =~ s/^\+//g;
        } else {
            $class = "DBIx::Class::ResultSet::Faceter::Facet::$class";
        }

        try {
            Class::MOP::load_class($class);
            # Instantiate the damned thing with the leftover arguments, but do
            # it in this try so if it blows up we can report the failure.
            $facet = $class->new($args);
        } catch {
            die "Tried to load the class '$class' as a Facet and failed: $_";
        }
    }

    die "Facet name '".$facet->name."' is not unique." if exists($self->facets->{$facet->name});

    $self->facets->{$facet->name} = $facet;
}

=head2 facet

Performs the faceting, returning a L<DBIx::Class::ResultSet::Faceter::Result> object.

=cut

sub facet {
    my ($self, $rs) = @_;

    my %res = ();

    while(my $row = $rs->next) {
        foreach my $name (keys %{ $self->facets }) {
            my $facet = $self->get_facet($name);
            $res{$name}->{$facet->process($row)} += 1;
        }
    }

    my $result = DBIx::Class::ResultSet::Faceter::Result->new;

    foreach my $name (keys %{ $self->facets }) {
        my $data = $res{$name};
        if(scalar(keys %{ $data })) {
            my $facet = $self->get_facet($name);
            # Call prepare on the facet, give it the data and store the
            # retval in the result!
            $result->set($name, $facet->_prepare($data));
        } else {
            $result->set($name, []);
        }
    }

    return $result;
}

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Jay Shirley

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;
