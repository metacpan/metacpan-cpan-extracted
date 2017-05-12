package Data::Validate::Email;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
use AutoLoader 'AUTOLOAD';

use Email::Address;
use Data::Validate::Domain;

@ISA = qw(Exporter);



# no functions are exported by default.  See EXPORT_OK
@EXPORT = qw();

@EXPORT_OK = qw(
		is_email
		is_email_rfc822
		is_domain
		is_username
);

%EXPORT_TAGS = ();

$VERSION = '0.05';


# No preloads

1;
__END__

=head1 NAME

Data::Validate::Email - common email validation methods

=head1 SYNOPSIS

  use Data::Validate::Email qw(is_email is_email_rfc822);
  
  if(is_email($suspect)){
  	print "Looks like an email address\n";
  } elsif(is_email_rfc822($suspect)){
  	print "Doesn't much look like an email address, but passes rfc822\n";
  } else {
  	print "Not an email address\n";
  }

  # or as an object
  my $v = Data::Validate::Email->new();
  
  die "not an email" unless ($v->is_email('foo'));

=head1 DESCRIPTION

This module collects common email validation routines to make input validation,
and untainting easier and more readable. 

All functions return an untainted value if the test passes, and undef if
it fails.  This means that you should always check for a defined status explicitly.
Don't assume the return will be true. (e.g. is_username('0'))

The value to test is always the first (and often only) argument.

=head1 FUNCTIONS

=over 4

=cut

# -------------------------------------------------------------------------------

=pod

=item B<new> - constructor for OO usage

  new([\%opts]);

=over 4

=item I<Description>

Returns a Data::Validator::Email object.  This lets you access all the validator function
calls as methods without importing them into your namespace or using the clumsy
Data::Validate::Email::function_name() format.

=item I<Arguments>

An optional hash reference is retained and passed on to other function calls in the
Data::Validate module series.  This module does not utilize the extra data,
but some child calls do.  See Data::Validate::Domain for an example.

=item I<Returns>

Returns a Data::Validate::Email object

=back

=cut

sub new{
	my $class = shift;
	my %self = @_;
	
	return bless \%self, ref($class) || $class;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_email> - is the value a well-formed email address?

  is_email($value);

=over 4

=item I<Description>

Returns the untainted address if the test value appears to be a well-formed
email address.  This method tries to match real-world addresses, rather than
trying to support everything that rfc822 allows.  (see is_email_rfc822 if you want the
more permissive behavior.)

In short, it pretty much looks for something@something.tld.  It does not understand
real names ("bob smith" <bsmith@test.com>), or other comments.  It will not accept
partially-qualified addresses ('bob', or 'bob@machine')

=item I<Arguments>

=over 4

=item $value

The potential address to test.

=back

=item I<Returns>

Returns the untainted address on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This function does not make any attempt to check whether an address is 
genuinely deliverable. It only looks to see that the format is email-like.

The function accepts an optional hash reference as a second argument to 
change the validation behavior.  It is passed on unchanged to Neil Neely's
Data::Validate::Domain::is_domain() function.  See that module's documentation
for legal values.

=back

=cut

sub is_email{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined($value);
	
	my $opt = (defined $self) ? $self : (shift);
	
	my @parts = split(/\@/, $value);
	return unless scalar(@parts) == 2;
	
	my($user) = is_username($parts[0], $opt);
	return unless defined($user);
	return unless $user eq $parts[0];
	
	my $domain = is_domain($parts[1], $opt);
	return unless defined($domain);
	return unless $domain eq $parts[1];

	return $user . '@' . $domain;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_email_rfc822> - does the value look like an RFC 822 address?

  is_email_rfc822($value);

=over 4

=item I<Description>

Returns the untainted address if the test value appears to be a well-formed
email address according to RFC822. Note that the standard allows for a wide
variety of address formats, including ones with real names and comments.

In most cases you probably want to use is_email() instead.  This one will
accept things that you probably aren't expecting ('foo@bar', for example.)  

=item I<Arguments>

=over 4

=item $value

The potential address to test.

=back

=item I<Returns>

Returns the untainted address on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

This check uses Casey West's Email::Address module to do its validation.

The function does not make any attempt to check whether an address is 
genuinely deliverable. It only looks to see that the format is email-like.

=back

=cut

sub is_email_rfc822{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined($value);
	
	#warn $Email::Address::mailbox;
	
	my $address;
	if($value =~ /^$Email::Address::mailbox$/){
		#warn $&;
		$address = $&;
	}
	
	return $address;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_domain> - does the value look like a domain name?

  is_domain($value);

=over 4

=item I<Description>

Returns the untainted domain if the test value appears to be a well-formed
domain name.  This test uses the same logic as is_email(), rather than the
somewhat more permissive pattern specified by RFC822. 

=item I<Arguments>

=over 4

=item $value

The potential domain to test.

=back

=item I<Returns>

Returns the untainted domain on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether a domain is 
actually exists. It only looks to see that the format is appropriate.

As of version 0.03, this is a direct pass-through to Neil Neely's
Data::Validate::Domain::is_domain() function.

The function accepts an optional hash reference as a second argument to 
change the validation behavior.  It is passed on unchanged to Neil Neely's
Data::Validate::Domain::is_domain() function.  See that module's documentation
for legal values.

=back

=cut

sub is_domain{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined($value);
	
	my $opt = (defined $self) ? $self : (shift);
	
	return Data::Validate::Domain::is_domain($value, $opt);
}


# -------------------------------------------------------------------------------

=pod

=item B<is_username> - does the value look like a username?

  is_username($value);

=over 4

=item I<Description>

Returns the untainted username if the test value appears to be a well-formed
username.  More specifically, it tests to see if the value is legal as the
username component of an email address as defined by is_email().  Note that
this definition is more restrictive than the one in RFC822.

=item I<Arguments>

=over 4

=item $value

The potential username to test.

=back

=item I<Returns>

Returns the untainted username on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether a username
actually exists on your system. It only looks to see that the format is
appropriate.

=back

=cut

sub is_username{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined($value);
	
	my($username) = $value =~ /^([a-z0-9_\-\.\+]+)$/i;
	
	return $username;
}


=pod

=back

=head1 AUTHOR

Richard Sonnen <F<sonnen@richardsonnen.com>>.

=head1 COPYRIGHT

Copyright (c) 2004 Richard Sonnen. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
