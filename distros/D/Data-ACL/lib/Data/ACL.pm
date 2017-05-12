package Data::ACL;

use Carp;
use Data::ACL::Realm;

use strict;
use vars qw/ $VERSION /;

$VERSION = '0.02';


sub AddPolicy {
    my ( $self, $realm, @args ) = @_;
    my $obj = $self->Realm( $realm );
    return $obj->AddPolicy( @args );
}


sub IsAuthorized {
    my ( $self, $user, $realm ) = @_;
    my $obj = $self->{'realms'}->{$realm};
    unless ( UNIVERSAL::isa( $obj, 'Data::ACL::Realm' ) ) {
        croak( __PACKAGE__, "->IsAuthorized : Undefined realm or unknown realm object - ", $realm );
    }
    my $default = $self->{'realms'}->{'all'};
    if ( UNIVERSAL::isa( $default, 'Data::ACL::Realm' ) ) {
        return undef unless $default->IsAuthorized( $user );
    }
    $obj->IsAuthorized( $user );
}


sub Realm {
    my ( $self, $realm ) = @_;
    $self->{'realms'}->{$realm} ||= Data::ACL::Realm->new( $self->{'set'} );
    return $self->{'realms'}->{$realm};
}


sub RemovePolicy {
    my ( $self, $realm, @args ) = @_;
}


sub new {
    my ( $class, $set ) = @_;
    my $self = bless {
        'realms'    =>  {},
        'set'       =>  $set
    }, $class;
    return $self;
}


1;


__END__

=pod

=head1 NAME

Data::ACL - Perl extension for simple ACL lists

=head1 SYNOPSIS

 use Data::ACL;
 use Set::NestedGroups;  #   See Set::NestedGroups documentation

 my $groups = Set::NestedGroups->new;
 $groups->add( 'root', 'wheel' );
 $groups->add( 'wheel', 'staff' );
 $groups->add( 'webmaster', 'staff' );

 my $acl = Data::ACL->new( $groups );
 my $web = $acl->Realm( 'web' );
 $web->Deny( 'all' );
 $web->Allow( 'staff' );

 &DenyAccess unless $acl->IsAuthorized( $user, 'web' );

=head1 DESCRIPTION

This module implements a series of allowed and denied access control lists 
for permissive controls.  The Set::NestedGroups module is used to define 
users and nested permissive groups.

=head1 METHODS

The following methods are available through this module for use in the 
creation and manipulation of access control lists.  No methods of this 
module may be exported into the calling namespace.

=over 4

=item B<new>

 my $acl = Data::ACL->new( $groups );

The method creates a new access control list module and requires the 
Set::NestedGroups object of defined users and nested permissive groups to 
be passed to this object constructor.

=item B<Realm>

 my $realm = $acl->Realm( $name );

This method creates a new authentication realm to which users and groups 
can be assigned access rights via the Allow and Deny methods.

=item B<Allow>

 $realm->Allow( $group );

This method grants access rights to the user or group passed as an 
argument to this method within the authentication realm object defined 
previously by the $acl->Realm method.

=item B<Deny>

 $realm->Deny( $group );

This method denies access rights to the user or group passed as an 
argument to this method within the authentication realm object defined 
previously by the $acl->Realm method.

=item B<IsAuthorized>

 if ( $acl->IsAuthorized( $user, $name ) ) { ... }

This method is used to test the access rights of a user or group to 
the authentication realm defined by $name.

=back

=head1 SEE ALSO

L<Set::NestedGroups>

=head1 VERSION

0.02

=head1 AUTHOR

Ariel Brosh, L<schop@cpan.org> (Inactive); Rob Casey, L<robau@cpan.org>

=cut

