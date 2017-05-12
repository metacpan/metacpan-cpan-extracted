package Data::LazyACL;

use strict;
use Math::BigInt;
use Carp;
use vars qw/$VERSION/;

$VERSION = '0.05';

my $ADMIN_NUMBER = -1;

sub new {
    my $class = shift;
    my $s     = {};

    bless $s , $class;
}

sub get_all_access_keys {
    my $s = shift;
    return $s->{all_access_keys};
}

sub set_all_access_keys {
    my $s           = shift;
    my $access_keys = shift;

    $s->{all_access_keys} = $access_keys ;

    my $digit = 1;
    for  my $access_key ( @{ $access_keys }  ) {
    
        if( $access_key eq 'admin' ) {
            croak q{You can not use reserved word 'admin' as access key.};
        }
        
        $s->{access_key}{ $access_key } = $digit;   
        $digit++;
    }
    $s->{access_key}{admin} = $ADMIN_NUMBER;
}

sub has_privilege {
    my $s           = shift;
    my $access_key  = shift;

    return 0 unless defined $s->{token};
    # admin
    return 1 if $s->{token} eq $ADMIN_NUMBER ;

    # required admin
    return 0 if $access_key eq 'admin';

    my $access_digit =  $s->{access_key}{ $access_key } ;
    
    croak 'can not find access key [' . $access_key . ']' unless $access_digit;
    my $acl = Math::BigInt->new( 2 );
    $acl->bpow( $access_digit - 1 );
    return $acl->band( $s->{token} ) ? 1 : 0;
}

sub set_token {
    my $s       = shift;
    my $token   = shift;
    $s->{token} = $token ;
}

sub generate_token {
    my $s           = shift;
    my $access_keys = shift;
    
    my $acl = Math::BigInt->new();

    for my $access_key ( @{ $access_keys } ) {
        return $ADMIN_NUMBER if $access_key eq 'admin';

        my $digit   = $s->{access_key}{ $access_key } ;
        
        croak 'can not find access key [' . $access_key . ']' unless $digit;

        my $i       = Math::BigInt->new( 2 );

        $acl->badd( $i->bpow( $digit -1 ) );
    }
    return $acl->numify();

}

sub retrieve_access_keys_for {
    my $s           = shift;
    my $token       = shift;
    my @access_keys = ();

    return ['admin'] if $token eq $ADMIN_NUMBER;

    foreach my $key ( keys %{ $s->{access_key} } ) {
        next if $key eq 'admin';
        my $mb    = Math::BigInt->new('2');
        my $digit = $s->{access_key}{ $key };

        $mb->bpow( $digit - 1 );    
        
        if( $mb->band( $token ) ) {
            push @access_keys , $key ;
        }

    }

    return \@access_keys;
}

sub retrieve_access_keys_in_hash_for {
    my $s           = shift;
    my $token       = shift;
    my $access_keys = {};

    return {admin => 1} if $token eq $ADMIN_NUMBER;

    foreach my $key ( keys %{ $s->{access_key} } ) {
        next if $key eq 'admin';
        my $mb    = Math::BigInt->new('2');
        my $digit = $s->{access_key}{ $key };

        $mb->bpow( $digit - 1 );    
        
        if( $mb->band( $token ) ) {
            $access_keys->{ $key } = 1;
        }

    }
    return $access_keys;
}
1;

=head1 NAME

Data::LazyACL - Simple and Easy Access Control List

=head1 DESCRIPTION

I am tired of having multiple flags or columns or whatever to implement Access
Control List , so I create this module.

This module is simple and easy to use,  a user only need to have a token
to check having access or not.

=head1 SYNOPSYS

 my $acl = Data::LazyACL->new();
 $acl->set_all_access_keys( [qw/edit insert view/]);

 my ( $edit , insert , view ) = $s->get_all_access_keys();

 # maybe you want to store this token into user record.
 my $token = $acl->generate_token([qw/view insert/]);

 $acl->set_token( $token );

 if ( $acl->has_privilege( 'view' ) ) {
    print "You can view me!!\n";
 }

 if ( $acl->has_privilege( 'edit' ) ) {
    print "Never Dispaly\n";
 }
 
 my $access_keys_ref 
    = $acl->retrieve_access_keys_for( $token );
 
 my $access_keys_hash_ref
    = $acl->retrieve_access_keys_in_hash_for( $token );

=head1 METHODS

=head2 new()

Constractor.

=head2 set_all_access_keys( \@access_keys )

Set all access keys. You can never change this array of order once you
generate token , otherwise you will messup permissins. When you want to add new keys then just append.  

=head2 $token = generate_token( \@user_access_keys )

Generate token. You may want to save this token for per user.

=head2 \@access_keys = get_all_access_keys()

Get access keys which you set with set_all_access_keys() .. means not include
'admin'.

=head2 set_token( $token )

You need to set $token to use has_privilege() method. the has_privilege()
method check privilege based on this token.

If you want to have all access then use reserve keyword 'admin' .

 my $admin_token = $acl->set_token( 'admin' );

=head2 has_privilege( $access_key )

check having privilege or not for the access_key.

=head2 $keys_ref = retrieve_access_keys_for( $token )

Get access keys array ref for a token.

=head2 $keys_hash_ref = retrieve_access_keys_in_hash_for( $token )

Get access keys as hash key. value is 1.

=head1 Token can be big number

Token can be big number when you add a lot of access keys, so I suggest
you treat Token as String not Integer when you want to store it into database.

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi+cpan@gmail.com>

=head1 COPYRIGHT

This program is free software. you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
