package DBIx::Class::SaltedPasswords;

use base qw(DBIx::Class);
use strict;
use warnings;
use Digest::MD5 qw( md5_hex );

our $VERSION = '0.03001';

__PACKAGE__->mk_classdata( 'salted_enabled'     => 1 );
__PACKAGE__->mk_classdata( 'salted_column'      => "" );
__PACKAGE__->mk_classdata( 'salted_salt_length' => 6 );
__PACKAGE__->mk_classdata( 'salted_salt_column' => 'salt' );

sub saltedpasswords {
	my $self = shift;
	my %args = @_;
	$self->salted_column( $args{column} );
	$self->salted_enabled( $args{enabled} ) if exists $args{enabled};
	$self->salted_salt_length( $args{salt_length} )
	  if exists $args{salt_length};
	$self->salted_salt_column( $args{salt_column} )
	  if exists $args{salt_column};

}

sub insert {
	my $self = shift;
	if ( $self->salted_enabled ) {
		my $salt;
		$salt .= ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 )[ int( rand() * 62 ) ]
		  for ( 1 .. $self->salted_salt_length );
		if ( defined $self->get_column( $self->salted_column ) ) {
			$self->set_column( $self->salted_column,
				md5_hex( $self->get_column( $self->salted_column ) . $salt ) );
			$self->set_column( $self->salted_salt_column, $salt );

		}
	}
	return $self->next::method(@_);
}
## copy of insert
sub update {
	my $self = shift;
	if (   $self->salted_enabled
		&& $self->is_column_changed( $self->salted_column ) )
	{
		my $salt;
		$salt .= ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 )[ int( rand() * 62 ) ]
		  for ( 1 .. $self->salted_salt_length );
		if ( defined $self->get_column( $self->salted_column ) ) {
			$self->set_column( $self->salted_column,
				md5_hex( $self->get_column( $self->salted_column ) . $salt ) );
			$self->set_column( $self->salted_salt_column, $salt );

		}
	}
	return $self->next::method(@_);
}

sub verify_password {
	my $self = shift;
	return 0 unless ( $_[0] );
	die "There is no salt element"
	  unless ( defined $self->get_column( $self->salted_salt_column ) );
	die "There is no password element"
	  unless ( defined $self->get_column( $self->salted_column ) );
	return md5_hex( $_[0] . $self->get_column( $self->salted_salt_column ) ) eq
	  $self->get_column( $self->salted_column ) ? 1 : 0;

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DBIx::Class::SaltedPasswords - Salts password columns

=head1 SYNOPSIS

  __PACKAGE__->load_components(qw/SaltedPasswords ... Core /);
  __PACKAGE__->saltedpasswords( 
     column      => "password", # no defaul value
     salt_lenght => 6,          # default: 6
     enabled     => 1,          # default: 1
     salt_column =>'salt'       # default: 'salt'
  );

=head1 DESCRIPTION

This module generates for every insert or update of a specified column a random salt, adds it to the value and hashes the complete string with MD5.
The salt is stored in the salt_column column.
To verify a password against the table use the verify_password method.

=head1 EXAMPLE

In your table scheme (e.g. User):

  __PACKAGE__->load_components(qw/SaltedPasswords ... Core /);
  __PACKAGE__->saltedpasswords( 
     column      => "password"
  );
  
In your application:

  sub register {
  	$db->resultset('User')->create(
		{
			name         => 'Paul',
			password     => 'secret'
		}
	)->update;
  }

This registers a new user with a crypted password ($password is plaintext, the encryption is done by this module). Make sure the salt column exists.

  my $rs = $db->resultset('User')->search({name => 'Paul'})->first; # Or use find() and your primary key
  $rs->verify_password('secret');                                   # returns 1 if the password is right

This validates the password

=head1 NEW METHODS

The following methods are new:-

=over 4

=item verify_password

returns 1 if the password is right, 0 else.

=head1 EXTENDED METHODS

The following L<DBIx::Class::Row> methods are extended by this module:-

=over 4

=item insert

=item update


=head1 SEE ALSO

L<DBIx::Class>
L<DBIx::Class::DigestColumns>

=head1 AUTHOR

Moritz Onken (perler)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by perler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
