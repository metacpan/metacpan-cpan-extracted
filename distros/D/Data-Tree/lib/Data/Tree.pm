package Data::Tree;
{
  $Data::Tree::VERSION = '0.16';
}
BEGIN {
  $Data::Tree::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a hash-based tree-like data structure

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
# has ...
has 'data' => (
    'is'      => 'rw',
    'isa'     => 'HashRef',
    'lazy'    => 1,
    'builder' => '_init_data',
);

has 'debug' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'lazy'    => 1,
    'builder' => '_init_debug',
);
# with ...
# initializers ...
sub _init_data {
    return {};
}

sub _init_debug {
    my $self = shift;

    if($ENV{'DATA_TREE_DEBUG'}) {
        return 1;
    }

    return 0;
}

# your code here ...
############################################
# Usage      : $C->set('Path::To::Key','Value');
# Purpose    : Set a value to the given key.
# Returns    :
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
## no critic (ProhibitAmbiguousNames)
sub set {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    my $force = shift || 0;

    my ( $ref, $last_key ) = $self->_find_leaf($key);
    if ( ref( $ref->{$last_key} ) eq 'HASH' && !$force ) {
        return;
    }
    $ref->{$last_key} = $value;
    return $value;
}
## use critic

sub increment {
    my $self      = shift;
    my $key       = shift;
    my $increment = shift // 1;

    my $value = $self->get($key) || 0;

    # bail out if value != numeric
    if($value !~ m/^\d+$/) {
        return $value;
    }

    $value += $increment;
    $self->set( $key, $value );

    return $value;
}

sub decrement {
    my $self      = shift;
    my $key       = shift;
    my $decrement = shift || 1;

    my $value = $self->get($key) || 0;

    # bail out if value != numeric
    if($value !~ m/^\d+$/) {
        return $value;
    }

    $value -= $decrement;
    $self->set( $key, $value );

    return $value;
}

############################################
# THIS METHOD IS NOT PART OF OUR PUBLIC API!
# Usage      :
# Purpose    :
# Returns    :
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# THIS METHOD IS NOT PART OF OUR PUBLIC API!
sub _find_leaf {
    my $self = shift;
    my $key  = shift;

    my @path = ();
    if ( ref($key) eq 'ARRAY' ) {
        @path = map { lc($_); } @{$key};
    }
    else {
        $key = lc($key);
        @path = split /::/, $key;
    }

    my $ref       = $self->data();
    my $last_step = undef;
    while ( my $step = shift @path ) {
        $last_step = $step;
        if ( @path < 1 ) {
            last;
        }
        elsif ( ref( $ref->{$step} ) eq 'HASH' ) {
            $ref = $ref->{$step};
        }
        elsif ( @path >= 1 ) {
            $ref->{$step} = {};
            $ref = $ref->{$step};
        }
        else {
            warn "Unhandled condition in _find_leaf w/ key $key in step $step in Data::Tree::_find_leaf().\n" if $self->debug();
        }
    }

    # ref contains the hash ref one step above the wanted entry,
    # last_step is the key in this hash to access the wanted
    # entry.
    # this is necessary or
    return ( $ref, $last_step );
}

############################################
# Usage      : my $value = $C->get('Path::To::Key');
# Purpose    : Retrieve a value from the config.
# Returns    : The value.
# Parameters : The name of the key.
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub get {
    my $self = shift;
    my $key  = shift;
    my $opts = shift || {};

    my ( $ref, $last_key ) = $self->_find_leaf($key);

    if ( exists( $ref->{$last_key} ) ) {
        return $ref->{$last_key};
    }
    else {
        if ( exists( $opts->{'Default'} ) ) {
            return $opts->{'Default'};
        }
        else {
            return;
        }
    }
}

# return a single value out of an array
sub get_scalar {
    my $self = shift;
    my $key  = shift;

    my $value = $self->get($key);

    if ( $value && ref($value) && ref($value) eq 'ARRAY' ) {
        return $value->[0];
    }
    elsif ( $value && ref($value) && ref($value) eq 'HASH' ) {
        return ( keys %{$value} )[0];
    }
    else {
        return $value;
    }
}

############################################
# Usage      : my @values = $C->get_array('Path::To::Key');
# Purpose    : Retrieve an array of values from config.
# Returns    : The values as an array.
# Parameters : The name of the key.
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub get_array {
    my $self = shift;
    my $key  = shift;
    my $opts = shift || {};

    my $ref = $self->get($key);

    if ( $ref && ref($ref) eq 'HASH' ) {
        warn "Returning only the keys of a hashref in Data::Tree::get_array($key).\n" if $self->debug();
        return ( keys %{$ref} );
    }
    elsif ( $ref && ref($ref) eq 'ARRAY' ) {
        return @{$ref};
    }
    elsif ($ref) {
        return ($ref);
    }
    elsif ( defined( $opts->{'Default'} ) && ref($opts->{'Default'}) eq 'ARRAY' ) {
        return @{$opts->{'Default'}};
    }
    else {
        ## no critic (ProhibitMagicNumbers)
        my $caller = ( caller(1) )[3] || 'n/a';
        ## use critic
        warn "Returning empty array in Data::Tree::get_array($key) to $caller.\n" if $self->debug();
        return ();
    }
}
## no critic (ProhibitBuiltinHomonyms)
sub delete {
## use critic
    my $self = shift;
    my $key  = shift;

    my ( $ref, $last_key ) = $self->_find_leaf($key);

    if ( ref($ref) eq 'HASH' ) {
        delete $ref->{$last_key};
        return 1;
    }
    else {

        # don't know how to handle non hash refs
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Data::Tree - a hash-based tree-like data structure

=head1 SYNOPSIS

    use Data::Tree;
    my $DT = Data::Tree::->new();

    $DT->set('First::Key',[qw(a b c]);
    $DT->get('First::Key'); # should return [a b c]
    $DT->get_scalar('First::Key'); # should return a
    $DT->get_array('First::Key'); # should return (a, b, c)

=head1 DESCRIPTION

A simple hash-based nested tree.

=head1 METHODS

=head2 decrement

Decrement the numeric value of the given key by one.

=head2 delete

Remove the given key and all subordinate keys.

=head2 get

Return the value associated with the given key. May be an SCALAR, HASH or ARRAY.

=head2 get_array

Return the values associated with the given key as a list.

=head2 get_scalar

Return the value associated with the given key as an SCALAR.

=head2 increment

Increment the numeric value of the given key by one.

=head2 set

Set the value of the given key to the given value.

=head1 NAME

Data::Tree - A simple hash-based tree.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1; # End of Data::Pwgen
