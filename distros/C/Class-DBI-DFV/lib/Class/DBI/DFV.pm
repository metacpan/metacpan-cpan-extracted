# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Class::DBI::DFV;
use base 'Class::DBI';

use Data::FormValidator;
use Data::Dumper;

our $VERSION = '0.02';

=head1 NAME

Class::DBI::DFV - check that your data is valid using DFV

=head1 SYNOPSIS

    package My::DBI;
    use base 'Class::DBI::DFV';

    __PACKAGE__->connection(...);
    __PACKAGE__->table(...);
    __PACKAGE__->columns( All => qw( id val_unique val_optional ) );

    sub dfv_profile {
        my $class = shift;

        return {
            filters            => 'trim',
            required           => [qw/val_unique/],
            constraint_methods => { val_unique => qr/^\d+$/ },
        };
    }

=head1 INTRODUCTION

NOTE: this module is still under development - please see the bottom
of the pod for how you can help.

C<Class::DBI::DFV> combines the database abstraction of L<Class::DBI>
with the data validation of L<Data::FormValidator>. It allows you to
specify a DFV profile that the data must match. This profile is
applied when you do an C<insert> or a C<set>. If the profile does not
match then the normal C<Class::DBI-E<gt>_croak> method is called.

=head1 METHODS

=cut

my $DEBUG = 0;
warn "DEBUG is true" if $DEBUG;

=head2 validate_column_values

Class::DBI::DFV overides the C<validate_column_values> method to do
the actual validating. Once it has validated the data it then calls
the parent class' C<validate_column_values> method. There is no need
to call this in your code - it is called by Class::DBI. Be warned
though if you decide to override it as well.

=cut

sub validate_column_values {
    my ( $self, $class ) = _self_class(shift);
    my $data = shift || {};

    warn "Raw: ", Dumper $data if $DEBUG;

    if ($self) {

        # Fill in any blanks that there are.
        #warn "Filling in the blanks.";
        for my $field ( map { $_->name } $class->columns('All') ) {
            $$data{$field} = $self->get($field)
              unless exists $$data{$field};
        }
    }

    warn "Input: ", Dumper $data if $DEBUG;

    my $dfv_profile = $class->_get_dfv_profile;

    # Check that the data is good
    my $results = Data::FormValidator->check( $data, $dfv_profile );

    $class->dfv_results($results);

    if ( $results->has_invalid || $results->has_missing ) {

        Class::DBI::_croak( "validation failed in '$class': "
              . Dumper( $results->msgs, $data ) );
        return;
    }
    else {
        %$data = %{ $results->valid };

        # If we are already in the database and the Primary has not
        # changed then don't save it.
        my $primary_column = $class->columns('Primary');

        if ($self) {

            Class::DBI->_croak(
"Attempting to change primary key detected - Class::DBI does NOT support this"
              )
              if $self->id ne $$data{$primary_column};

            delete $$data{$primary_column};
        }

        warn "Valid: ", Dumper $data if $DEBUG;

        my $whatever = $self || $class;
        return $whatever->SUPER::validate_column_values($data);
    }
}

=head2 dfv_results

    eval { My::DBI->create( \%data ) }
      || warn "ERROR: ", Dumper( My::DBI->dfv_results->msgs );

The C<dfv_results> method gives you access to the last results
produced by Data::FormValidator.

=cut

our $_RESULTS = undef;

sub dfv_results {
    my $class = shift;
    return $_RESULTS unless @_;
    return $_RESULTS = shift;
}

=head2 dfv_base_profile

    sub dfv_base_profile {
        return {
            filters => 'trim',
            msgs    => {
                format      => 'validation error: %s',
                constraints => { unique_constraint => 'duplicate' },
            },
        };
    }

You will find that there are many things that you will want to put in
all your profiles. If in your parent class you create
C<dfv_base_profile> then the values in this will be combined with the
C<dfv_profile> that you create. As a general rule anything that is
specified in the profile will override the values in the base profile.

=cut

sub dfv_base_profile { return {}; }

# Combine the dfv_profile and the base_dfv_profile.

our %_CACHED_PROFILES = ();

=head2 _get_dfv_profile

This is a private method but as it changes your profile it is
documented here. The first thing it does is to combine the
C<dfv_base_profile> and the C<dfv_profile>.

Having done that it then looks at what columns you have in the
database and puts all the ones that are not in the profile's
C<required> list in the C<optional> list.

Finally it caches the profile to make execution faster. Make sure that
you use sub refs if you want something to be executed each time the
profile is parsed, eg:

    defaults => {
        wrong => rand(1000),
        right => sub { rand(1000) },
    },

The 'wrong' one will always return the same value - as the value is
created when the profile is created. The 'right' one will be executed
each time that the profile is applied and so will be different each
time.

=cut

sub _get_dfv_profile {
    my $class = shift;
    return $_CACHED_PROFILES{$class} if $_CACHED_PROFILES{$class};

    my $base    = $class->dfv_base_profile;
    my $profile = $class->dfv_profile;

    # Add the stuff in base to the profile if it is missing.
    $$profile{$_} ||= $$base{$_} for keys %$base;

    # Do obvious stuff
    unless ( $$profile{optional} ) {
        my %required = map { $_ => 1 } @{ $$profile{required} };
        my @optional =
          grep { !$required{$_} } map { $_->name } $class->columns('All');
        $$profile{optional} = \@optional;
    }

    # warn Dumper $profile;
    return $_CACHED_PROFILES{$class} = $profile;
}

sub _self_class {
    my $self  = ref( $_[0] ) ? $_[0]      : undef;
    my $class = $self        ? ref($self) : $_[0];
    return ( $self, $class );
}

############################################################################

=head2 unique_constraint

EXPERIMENTAL - this is a constraint that lets you check that the
database does not contain duplicate values. Please see the module
C<Local::Test> in the test suite for usage. The way that this
constraint is used may well change.

=cut

sub unique_constraint {
    my $class = shift;
    my $table = $class->table;

    my @columns = @_;

    return sub {
        my $dfvr       = shift;
        my $main_field = $dfvr->get_current_constraint_field;
        my @fields     = @columns;
        @fields = ($main_field) unless scalar @fields;

        #warn Dumper $dfvr;
        #warn "Fields to check: ", join ', ', @fields;

        # Set things up.
        $dfvr->name_this('unique_constraint');

        # Create the args to search for.
        my %args = map { $_ => $dfvr->{__INPUT_DATA}{$_} } @fields;

        #warn "args: ", Dumper \%args;

        # See if the value is stored in the database.
        my $existing = $class->retrieve(%args);

        # If nothing found then it cannot be a duplicate.
        return 1 unless $existing;

        # If it was found it might be ourselves.
        my $new_id = $dfvr->{__INPUT_DATA}{ $class->columns('Primary') };
        my $old_id = $existing->id;

        if ( $new_id && $new_id eq $old_id ) {
            return 1;
        }

        # It exists and is not us - duplicate.
        $dfvr->msgs->{$main_field} = 'duplicate';
        return 0;
    };
}

=head1 SEE ALSO

L<Class::DBI> - Simple Database Abstraction

L<Data::FormValidator> - Validates user input (usually from an HTML
form) based on input profile.

=head1 AUTHOR

Edmund von der Burg - C<evdb@ecclestoad.co.uk>

=head1 CONTRIBUTE

If you want to change something is Class::DBI::DFV I would be
delighted to help. You can get the latest from
L<http://svn.ecclestoad.co.uk/svn/class-dbi-dfv/trunk/>. Anonymous
access is read-only but if you have an idea please contact me and I'll
create an account for you so you can commit too.

=cut

1;

