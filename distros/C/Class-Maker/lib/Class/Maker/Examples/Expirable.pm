
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Expirable;

our $VERSION = '0.02';

require 5.005_62; use strict; use warnings;

Class::Maker::class
{
	public =>
	{
		string => [qw/creation expiration/],
	}
};

# Preloaded methods go here.

sub _preinit
{
	my $this = shift;

		$this->creation( time() );
}

sub dump_object : method
{
	my $this = shift;

	print "\n";

	printf '%20s %s'."\n", 'Created:',$this->creationToString;

	printf '%20s %s'."\n", 'Expires:',$this->expirationToString;
}

sub expiration_status : method
{
	my $this = shift;

	if( not defined $this->expiration )
	{
		return 1;
	}

return $this->expiration() <= time();
}

sub expiration_add : method
{
	my $this = shift;

	my $seconds = shift;

return $this->expiration( $this->expiration + $seconds );
}

sub expiration_remove : method
{
	my $this = shift;

	my $seconds = shift;

return $this->expiration( $this->expiration - $seconds );
}

sub expiration_to_string : method
{
	my $this = shift;

	if( not defined $this->expiration )
	{
		return 'Never';
	}

return scalar gmtime( $this->expiration );
}

sub creation_to_string : method
{
	my $this = shift;

return scalar gmtime( $this->creation );
}

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Object::Expirable - class for exirable objects

=head1 SYNOPSIS

  use CATS::Article;

=head1 DESCRIPTION

Stub documentation for CATS::Article, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub unedited.

Embedded SQL-Objects

=head2 Methods

id created expiration status replyto user subject body board attachment

=head2 EXPORT

None by default.


=head1 AUTHOR

muenalan@cpan.org

=head1 SEE ALSO

perl(1).

=cut
