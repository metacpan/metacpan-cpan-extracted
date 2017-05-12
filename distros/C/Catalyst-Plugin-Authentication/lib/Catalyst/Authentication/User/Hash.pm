package Catalyst::Authentication::User::Hash;

use strict;
use warnings;

use base qw/Catalyst::Authentication::User/;

sub new {
    my $class = shift;

    bless { ( @_ > 1 ) ? @_ : %{ $_[0] } }, $class;
}

sub AUTOLOAD {
    my $self = shift;
    ( my $key ) = ( our $AUTOLOAD =~ m/([^:]*)$/ );

    $self->_accessor( $key, @_ );
}

# this class effectively handles any method calls
sub can { 1 }

sub id {
    my $self = shift;
    $self->_accessor( "id", @_ );
}

## deprecated. Let the base class handle this.
#    sub store {
#        my $self = shift;
#        $self->_accessor( "store", @_ ) || ref $self;
#    }

sub _accessor {
    my $self = shift;
    my $key  = shift;

    if (@_) {
        my $arr = $self->{__hash_obj_key_is_array}{$key} = @_ > 1;
        $self->{$key} = $arr ? [@_] : shift;
    }

    my $data = $self->{$key};
    ( $self->{__hash_obj_key_is_array}{$key} || $key =~ /roles/ )
      ? @{ $data || [] }
      : $data;
}

## password portion of this is no longer necessary, but here for backwards compatibility.
my %features = (
    password => {
        clear      => ["password"],
        crypted    => ["crypted_password"],
        hashed     => [qw/hashed_password hash_algorithm/],
        self_check => undef,
    },
    roles   => ["roles"],
    session => 1,
);

sub supports {
    my ( $self, @spec ) = @_;

    my $cursor = \%features;

    return 1 if @spec == 1 and exists $self->{ $spec[0] };

    # traverse the feature list,
    for (@spec) {
        return if ref($cursor) ne "HASH";
        $cursor = $cursor->{$_};
    }

    if ( ref $cursor ) {
        die "bad feature spec: @spec" unless ref $cursor eq "ARRAY";

        # check that all the keys required for a feature are in here
        foreach my $key (@$cursor) {
            return undef unless exists $self->{$key};
        }

        return 1;
    }
    else {
        return $cursor;
    }
}

sub for_session {
    my $self = shift;
    
    return $self; # we serialize the whole user
}

sub from_session {
    my ( $self, $c, $user ) = @_;
    $user;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Authentication::User::Hash - An easy authentication user
object based on hashes.

=head1 SYNOPSIS

    use Catalyst::Authentication::User::Hash;
    
    Catalyst::Authentication::User::Hash->new(
        password => "s3cr3t",
    );

=head1 DESCRIPTION

This implementation of authentication user handles is supposed to go hand in
hand with L<Catalyst::Authentication::Store::Minimal>.

=head1 METHODS

=head2 new( @pairs )

Create a new object with the key-value-pairs listed in the arg list.

=head2 supports( )

Checks for existence of keys that correspond with features.

=head2 for_session( )

Just returns $self, expecting it to be serializable.

=head2 from_session( )

Just passes returns the unserialized object, hoping it's intact.

=head2 AUTOLOAD( )

Accessor for the key whose name is the method.

=head2 store( )

Accessors that override superclass's dying virtual methods.

=head2 id( )

=head2 can( )

=head1 SEE ALSO

L<Hash::AsObject>

=cut


