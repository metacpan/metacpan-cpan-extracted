# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::Dochazka::Common::Model;

use 5.012;
use strict;
use warnings;

use Params::Validate qw( :all );
use Test::Deep::NoTest;



=head1 NAME

App::Dochazka::Common::Model - functions shared by several modules within
the data model




=head1 SYNOPSIS

Shared data model functions. All three functions are designed to be
used together as follows:

    package My::Package;

    use Params::Validate qw( :all );

    BEGIN {
        no strict 'refs';
        *{"spawn"} = App::Dochazka::Common::Model::make_spawn;
        *{"reset"} = App::Dochazka::Common::Model::make_reset(
            'attr1', 'attr2',
        );
        *{"attr1"} = App::Dochazka::Common::Model::make_accessor( 'attr1' );
        *{"attr2"} = App::Dochazka::Common::Model::make_accessor( 'attr2', { type => HASHREF } );
    }

What this does: 

=over

=item * create a C<spawn> class method in your class

=item * create a C<reset> instance method in your class

=item * create a C<attr1> accessor method in your class (type defaults to SCALAR)

=item * create a C<attr2> accessor method in your class (type HASHREF)

=back


=head1 PACKAGE VARIABLES

Dispatch table used in 'boilerplate'.

=cut

my %make = (
    spawn => \&make_spawn,
    filter => \&make_filter,
    reset => \&make_reset,
    TO_JSON => \&make_TO_JSON,
    compare => \&make_compare,
    compare_disabled => \&make_compare_disabled,
    clone => \&make_clone,
    accessor => \&make_accessor,
    attrs => \&make_attrs,
    get => \&make_get,
    set => \&make_set,
);


=head1 FUNCTIONS


=head2 boilerplate

Run all the necessary commands to "install" the methods inside your
module. Call like this:

    use App::Dochazka::Common::Model;
    use constant ATTRS => qw( ... );

    BEGIN {
        App::Dochazka::Common::Model::boilerplate( __PACKAGE__, ATTRS );
    }

where the constant ATTRS contains the list of object properties.

This routine requires some explanation. It's purpose is to generate
"boilerplate" code for the modules under C<App::Dochazka::Common::Model>.
That includes the following methods:

=over 

=item * C<spawn> 

=item * C<filter> 

=item * C<reset> 

=item * C<TO_JSON> 

=item * C<compare>

=item * C<compare_disabled>

=item * C<clone>

=item * C<attrs>

=item * C<get>

=item * C<set>

=back

as well as basic accessors for that model/class. 

The C<boilerplate> routine takes a module name and a list of attributes (object
property names), and returns nothing. 

=cut

sub boilerplate {
    no strict 'refs';
    my ( $module, @attrs ) = @_;
    my $fn;

    # generate 'spawn' method
    $fn = $module . "::spawn";
    *{ $fn } = $make{"spawn"}->();

    # generate filter, reset, TO_JSON, compare, compare_disabled, clone, attrs, get and set
    map {
        $fn = $module . '::' . $_;
        *{ $fn } = $make{$_}->( @attrs );
    } qw( filter reset TO_JSON compare compare_disabled clone attrs get set );

    # generate accessors (one for each property)
    map {
        $fn = $module . '::' . $_;
        *{ $fn } = $make{"accessor"}->( $_ );
    } @attrs;

    return;
}



=head2 make_spawn

Returns a ready-made 'spawn' method for your class/package/module.

=cut

sub make_spawn {

    return sub {
        my $self = bless {}, shift;
        $self->reset( @_ );
        return $self;
    }

}


=head2 make_filter

Given a list of attributes, returns a ready-made 'filter' routine
which takes a PROPLIST and returns a new PROPLIST from which all bogus
properties have been removed.

=cut

sub make_filter {

    # take a list consisting of the names of attributes that the 'filter'
    # routine will retain -- these must all be scalars
    my ( @attr ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        if ( @_ % 2 ) {
            die "Odd number of parameters given to filter routine!";
        }
        my %ARGS = @_;
        my %PROPLIST;
        map { $PROPLIST{$_} = $ARGS{$_}; } @attr;
        return %PROPLIST;
    }
}


=head2 make_reset

Given a list of attributes, returns a ready-made 'reset' method. 

=cut

sub make_reset {

    # take a list consisting of the names of attributes that the 'reset'
    # method will accept -- these must all be scalars
    my ( @attr ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    # construct the validation specification for the 'reset' routine:
    # 1. 'reset' will take named parameters _only_
    # 2. only the values from @attr will be accepted as parameters
    # 3. all parameters are optional (indicated by 0 value in $val_spec)
    my $val_spec;
    map { $val_spec->{$_} = 0; } @attr;
    
    return sub {
        # process arguments
        my $self = shift;
        #confess "Not an instance method call" unless ref $self;
        my %ARGS;
        %ARGS = validate( @_, $val_spec ) if @_ and defined $_[0];

        # Set attributes to run-time values sent in argument list.
	# Attributes that are not in the argument list will get set to undef.
        map { $self->{$_} = $ARGS{$_}; } @attr;

        # run the populate function, if any
        $self->populate() if $self->can( 'populate' );

        # return an appropriate throw-away value
        return;
    }
}


=head2 make_accessor

Returns a ready-made accessor.

=cut

sub make_accessor {
    my ( $subname, $type ) = @_;
    $type = $type || { type => SCALAR | UNDEF, optional => 1 };
    sub {
        my $self = shift;
        validate_pos( @_, $type );
        $self->{$subname} = shift if @_;
        $self->{$subname} = undef unless exists $self->{$subname};
        return $self->{$subname};
    };
}


=head2 make_TO_JSON

Returns a ready-made TO_JSON

=cut

sub make_TO_JSON {

    my ( @attr ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my $self = shift;
        my $unblessed_copy;

        map { $unblessed_copy->{$_} = $self->{$_}; } @attr;

        return $unblessed_copy;
    }
}


=head2 make_compare

Returns a ready-made 'compare' method that can be used to determine if two objects are the same.

=cut

sub make_compare {

    my ( @attr ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my ( $self, $other ) = validate_pos( @_, 1, 1 );
        return if ref( $other ) ne ref( $self );
        
        return eq_deeply( $self, $other );
    }
}


=head2 make_compare_disabled

Returns a ready-made 'compare' method that can be used to determine if two objects are the same.
For use with objects containing a 'disabled' property where 'undef' and 'false' are treatd
as functionally the same.

=cut

sub make_compare_disabled {

    my ( @attr ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my ( $self, $other ) = validate_pos( @_, 1, 1 );
        return $self->compare( $other) unless grep { $_ eq 'disabled' } @attr;
        return if ref( $other ) ne ref( $self );
        my $self_disabled = $self->{'disabled'};
        delete $self->{'disabled'};
        my $other_disabled = $other->{'disabled'};
        delete $other->{'disabled'};
        return 0 unless eq_deeply( $self, $other );
        return 0 unless ( ! $self_disabled and ! $other_disabled ) or ( $self_disabled and $other_disabled );
        return 1;
    }
}


=head2 make_clone

Returns a ready-made 'clone' method.

=cut

sub make_clone {

    my ( @attr ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my ( $self ) = @_;

        my ( %h, $clone );
        map { $h{$_} = $self->{$_}; } @attr;
        {
            no strict 'refs';
            $clone = ( ref $self )->spawn( %h );
        }

        return $clone;
    }
}


=head2 make_attrs

Returns a ready-made 'attrs' method.

=cut

sub make_attrs {

    my ( @attrs ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my ( $self ) = @_;

        return \@attrs;
    }
}


=head2 make_get

Returns a ready-made 'get' method.

=cut

sub make_get {

    my ( @attrs ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my ( $self, $attr ) = @_;

        if ( grep { $_ eq $attr } @attrs ) {
            return $self->{$attr};
        }
        # unknown attribute
        return;
    }
}


=head2 make_set

Returns a ready-made 'set' method, which takes the name of an attribute and a
value to set that attribute to. Returns true value on success, false on failure.

=cut

sub make_set {

    my ( @attrs ) = validate_pos( @_, map { { type => SCALAR }; } @_ );

    return sub {
        my ( $self, $attr, $value ) = @_;

        if ( grep { $_ eq $attr } @attrs ) {
            $self->{$attr} = $value;
            return 1;
        }
        # unknown attribute
        return 0;
    }
}

=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

