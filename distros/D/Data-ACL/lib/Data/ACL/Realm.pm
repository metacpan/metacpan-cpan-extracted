package Data::ACL::Realm;

use Carp;

use strict;
use vars qw/ $VERSION /;

$VERSION = $Data::ACL::VERSION;


sub AddPolicy {
    my ( $self, $right, @args ) = @_;
    $right = uc $right;
    unless( $right eq 'ALLOW' or $right eq 'DENY' ) {
        croak( __PACKAGE__, "->AddPolicy : Policy should be either 'ALLOW' or 'DENY'" );
    }
    push @{ $self->{'policies'} }, [ $right, @args ];
}


sub Allow {
    my ( $self, @args ) = @_;
    push @{ $self->{'policies'} }, [ 'ALLOW', @args ];
}


sub Deny {
    my ( $self, @args ) = @_;
    push @{ $self->{'policies'} }, [ 'DENY', @args ];
}


sub Is {
    my ( $self, $user, $group ) = @_;
    my $set = $self->{'set'};
    return 1 if $group =~ /^all$/i;
    return ( $group eq $user ) if $group =~ s/^\.//;
    return undef unless $set->member( $user );
    return $set->member( $user, $group );
}


sub IsAuthorized {
    my ( $self, $user ) = @_;
    my $result = 0;
    foreach my $policy ( @{ $self->{'policies'} } ) {
        my ( $right, $group, $exception ) = @{ $policy };
        if ( ( $self->Is( $user, $group ) ) and ( !( $exception and $self->Is( $user, $exception ) ) ) ) {
            $result = ( $right eq 'ALLOW' );
        }
    }
    return $result;
}


sub new {
    my ( $class, $set ) = @_;
    my $self = bless {
        'policies'  =>  [],
        'set'       =>  $set
    }, $class;
    return $self;
}


1;


__END__
