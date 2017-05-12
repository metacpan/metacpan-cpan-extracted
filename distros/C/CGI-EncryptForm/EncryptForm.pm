#
# Copyright 1999, Peter Marelas.  All rights reserved.
#
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# Bug reports and comments to maral@phase-one.com.au.
#

package CGI::EncryptForm;

use Crypt::HCE_SHA;
use Storable qw(freeze thaw);
use Digest::SHA1 qw(sha1);

use strict;
use vars qw($VERSION $CHARSET);

$VERSION = 1.02;

# Default character set we use for encoding/decoding encrypted string
#
$CHARSET = [qw/AA Aa BA Ba CA Ca DA Da EA Ea AB Ab BB Bb CB Cb DB Db EB Eb AC Ac BC Bc CC Cc DC Dc EC Ec AD Ad BD Bd CD Cd DD Dd ED Ed AE Ae BE Be CE Ce DE De EE Ee AF Af BF Bf CF Cf DF Df EF Ef AG Ag BG Bg CG Cg DG Dg EG Eg AH Ah BH Bh CH Ch DH Dh EH Eh AI Ai BI Bi CI Ci DI Di EI Ei AJ Aj BJ Bj CJ Cj DJ Dj EJ Ej AK Ak BK Bk CK Ck DK Dk EK Ek AL Al BL Bl CL Cl DL Dl EL El AM Am BM Bm CM Cm DM Dm EM Em AN An BN Bn CN Cn DN Dn EN En AO Ao BO Bo CO Co DO Do EO Eo AP Ap BP Bp CP Cp DP Dp EP Ep AQ Aq BQ Bq CQ Cq DQ Dq EQ Eq AR Ar BR Br CR Cr DR Dr ER Er AS As BS Bs CS Cs DS Ds ES Es AT At BT Bt CT Ct DT Dt ET Et AU Au BU Bu CU Cu DU Du EU Eu AV Av BV Bv CV Cv DV Dv EV Ev AW Aw BW Bw CW Cw DW Dw EW Ew AX Ax BX Bx CX Cx DX Dx EX Ex AY Ay BY By CY Cy DY Dy EY Ey yY wW vV uU zU zZ/];

sub new {
	my($this) = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->_initialize(@_);
	return($self);
}

sub DESTROY {
}

# Public Method:
#
# encrypt()
#
# Purpose:
#
# Encrypt the hash reference
#
# Constructs:
#
#   encrypt()
#   Return last encrypted string
#
#   encrypt({a => b})
#   Encrypt hash reference and return encrypted string
#
sub encrypt {
	my($self, $decrypted_hashref) = @_;

	my $secret_key = $self->secret_key() || return undef;

	if (!defined($decrypted_hashref) && !defined($self->{_encrypted_string})) {
		$self->error('encrypt() This is the first time encrypt() has been called and therefore requires an arguement.');
		return undef;
	}
	elsif (!defined($decrypted_hashref)) {
		return($self->{_encrypted_string});
	}

	if (ref($decrypted_hashref) ne 'HASH') {
		$self->error('encrypt() This method accepts a single hash reference only.');
		return undef;
	}

	my $random_key = $self->_random_key();

	my $str = freeze($decrypted_hashref);
	$str = sha1($str) . $str;

	my $cipher = Crypt::HCE_SHA->new($secret_key, $random_key);
	$self->{_encrypted_string} = $self->usecharset() ?
		$self->_encode($random_key . $cipher->hce_block_encrypt($str)) : $random_key . $cipher->hce_block_encrypt($str);
	$self->error('');
	return($self->{_encrypted_string});
}


# Public Method:
#
# decrypt()
#
# Purpose:
#
# Decryption routine
#
# Constructs:
#
#   decrypt()
#   Return last decrypted reference to hash
#
#   decrypt("encrypted string")
#   Decrypt encrypted string and return reference to hash
#
sub decrypt {
	my($self, $encrypted_string) = @_;

	my $secret_key = $self->secret_key() || return undef;
	my $random_key;

	if (!defined($encrypted_string) && !defined($self->{_decrypted_hashref})) {
		$self->error('decrypt() This is the first time decrypt() has been called and therefore requires an arguement.');
		return undef;
	}
	elsif (!defined($encrypted_string)) {
		return($self->{_decrypted_hashref});
	}

	# if using char set ensure string is even number
	if ($self->usecharset() && (length($encrypted_string) % 2) != 0) {
		$self->error('decrypt() Character set is inconsistent.');
		return undef;
	}

	# decode the encrypted string
	my $str = $self->usecharset() ? $self->_decode($encrypted_string) :
																	$encrypted_string;

	# extract the random key (first 4 bytes)
	$random_key = substr($str, 0, 4);
	if (length($random_key) != 4) {
		$self->error('decrypt() Random key is inconsistent.');
		return undef;
	}
	$str = substr($str, 4);

  # decrypt
  my $cipher = Crypt::HCE_SHA->new($secret_key, $random_key);
	my $plaintxt = $cipher->hce_block_decrypt($str);

	# extract sha1 digest from decrypted string which is always
	# 20 bytes long
	my $digest = substr($plaintxt, 0, 20);
	if (length($digest) != 20) {
		$self->error('decrypt() Digest is inconsistent.');
		return undef;
	}
	$plaintxt = substr($plaintxt, 20);

	# check stored decrypted digest against digest of decrypted string
	if ($digest ne sha1($plaintxt)) {
		$self->error('decrypt() Encrypted string is inconsistent.');
		return undef;
	}	

	$self->error('');
	return(thaw($plaintxt));
}

# Public Method:
#
# secret_key()
#
# Purpose:
#
# Set/Return secret key
#
# Constructs:
#
#   secret_key()
#   Return current secret_key
#
#   secret_key("secret key")
#   Set secret key
#
sub secret_key {
	my($self, $secret_key) = @_;

	if (defined($secret_key)) {
		$self->{_secret_key} = $secret_key;
	}
	elsif (!defined($self->{_secret_key})) {
		$self->error('secret_key() No secret key has been defined.');
		return undef;
	}

	$self->error('');
	return($self->{_secret_key});
}

# Public Method
#
# charset()
#
# Purpose:
#
# Set character set
#
# Constructors:
#
#		charset([array of 2 character length elements from 0 to 255])
#		Set character set
#
sub charset {
	my($self, $charset) = @_;

	if ((defined($charset) && ref($charset) ne 'ARRAY') || !defined($charset)) {
		$self->error('charset() This methods accepts a single array reference.');
		return undef;
	}
	elsif (defined($charset) && $#$charset != 255) {
		$self->error('charset() The character set is invalid.');
		return undef;
	}

	$self->{'_charset'} = $charset;
	$self->{'_charset_hash'} = {
		map { $self->{'_charset'}->[$_] => $_; } 0..$#{$self->{'_charset'}}
	};

	$self->error('');
}

# Public Method:
#
# usecharset()
#
# Purpose:
#
# Enable/Return character set encoding/decoding of encrypted/decrypted string 
# suitable for storage in form fields, cookies or URL's
#
# Constructs:
#
#   usecharset()
#   Return current usecharset value
#
#   usecharset(0 or 1)
#   Set charset encoding/decoding
#
sub usecharset {
	my($self, $usecharset) = @_;

	$self->error('');
	$self->{_usecharset} = $usecharset if defined($usecharset);

	return($self->{_usecharset} ? 1 : 0);
}

# Public/Private Method:
#
# error()
#
# Purpose:
#
# Set/Clear/Get error message for last operation on object
#
# Public Constructors:
#
#		error()
#   Return error from last operation
#
sub error {
	my($self, $errormsg) = @_;

	if ($errormsg) {
		$self->{_errormsg} = "Error: $errormsg\n";
	}
	else {
		return($self->{_errormsg});
	}
}

#
# Private methods - dont call these from your object
#
sub _initialize {
	my($self, %opts) = @_;

	$self->{'_usecharset'} = 1;
	$self->{'_encrypted_string'} = undef;
	$self->{'_decrypted_hashref'} = undef;
	$self->{'_secret_key'} = undef;
	$self->{'_random_key'} = undef;
	$self->{'_errormsg'} = '';
	$self->{'_charset'} = undef;
	$self->{'_charset_hash'} = undef;

	# Set default charset
	$self->charset($CHARSET);

	foreach (keys(%opts)) {
		if (! $self->can($_)) {
			$self->error("_initialize() $_ is not a valid option.");
			return undef;
		}
		$self->$_($opts{$_});
	}
}

#
# Autogenerate the current object's random key every time. i.e. Not Persistent!
#
sub _random_key {
	my($self) = @_;

	$self->{_random_key} = pack("CCCC", rand(255), rand(255), rand(255),
																			rand(255));

	$self->error('');
	return($self->{_random_key});
}

# Decode encrypted string using character set
# 
sub _decode {
	my($self, $decode) = @_;

	$decode =~ s/(.{2})/chr($self->{'_charset_hash'}->{$1})/sge;
  return($decode);
}

# Encode encrypted string using character set
#
sub _encode {
		my($self, $encode) = @_;

  	$encode =~ s/(.)/$self->{'_charset'}->[ord($1)]/sge;
    return($encode);
}

1;
__END__


=head1 NAME

CGI::EncryptForm - Implement trusted stateful CGI Form Data using cryptography.

=head1 SYNOPSIS

  use CGI::EncryptForm;
  
  my $cfo = new CGI::EncryptForm(secret_key => 'my secret');
  
  my $hashref = { username => 'joe', password => 'test' };

  my $encrypted_string = $cfo->encrypt($hashref);
  if (!defined($encrypted_string)) {
    print $cfo->error();
    return;
  }

  my $newhashref = $cfo->decrypt($encrypted_string);
  if (!defined($newhashref)) {
    print $cfo->error();
    return;
  }

  print $newhashref->{'username'};

=head1 PREREQUISITES

This modules requires the following perl modules:

Digest::SHA1, Crypt::HCE_SHA and Storable

=head1 ABSTRACT

Many CGI programmers take for granted the validity of stateful CGI form data.

Im talking about the common scenario where you present a form to the browser,
the user fills in the form, you verify the form values, store them in the next
form as hidden fields, the user fills in another form, the script appends these
results to the next form in hidden fields and so on.

Using hidden form fields is one mechanism where by CGI scripts can maintain
state in the process of collecting information from the user.

Unfortunately, it is also one of the weakest to implement because
the CGI script must trust the hidden form fields and there values, provided
by the users browser. At some point in time the CGI program does something
with this stateful information. To be completely sure the hidden fields
haven't been altered along the way and thus rendered initial verification
checks useless, the programmer must continually verify all new form fields
and previous state (encapsulated in hidden form fields) to be sure the
desired constraints are met. This process of verification becomes tedious to
program especially if there are many forms required to produce a final
result.

To tackle this problem I created CGI::EncryptForm, where by instead of
including state in hidden form fields verbatim, we use SHA1 encryption
algorithm to provide a satisfactory level of trust between the users browser
and the CGI script.

=head1 DESCRIPTION

An object is created with a secret key defined by the CGI script. The
objects encrypt() method is called with a perl data structure, which in the
context of CGI scripts would normally contain key/value pairs.
The encrypt() method returns an encrypted string. The encrypted string is
stored in a hidden form field. The user fills in the form. The
CGI script processes the form, extracts the encrypted string from the
hidden form field, decrypts the string and returns the original data
structure. Further results from the form are added to the data structure,
then it is encrypted again and stored in the next form as a hidden field.
This process continues until the CGI script has all the desired
information and is ready to process it. To process the results, the CGI script
decrypts the encrypted string from the last hidden form field, which contains
the B<collective state> of all previous form input.

Along the way, the users input was verified only once. The fact that
state was encrypted and therefore trusted, renders the process of continually
verifying all state for each form processed, unnecessary.

=head1 METHODS

=over 4

=item B<new CGI::EncryptForm>([secret_key => $s [, usecharset => $a]])

Create a new CGI::EncryptForm object. All of the paramaters are optional.
$s specifies the secret key to use during encryption/decryption. $a
specifies whether to enable (1) or disable (0) the character set
encoding/decoding of the encrypted/decrypted result. By default this is enabled.

=item B<encrypt>($hashref)

Encrypt the data structure and return an encrypted string. $hashref must be
a reference to an associative array supported by the Storable module.
If called with no arguement, returns the previous encrypted string.

Upon error, the method returns undef and sets error().

=item B<decrypt>($encrypted_string)

Decrypt the encrypted string and return a reference to an associative array.
$encrypted_string must be a scalar previously generated by encrypt().
If called with no arguement, returns the previous reference.

Upon error, the method returns undef and sets error(). If the encrypted
string is tampered with the decryption routine should fail with undef, but
this is ultimately dependant on the strength of SHA1 digests.

=item B<secret_key>($secret)

Sets the secret key for use during encryption/decryption. This method is
analogues to the secret_key paramater when creating a CGI::EncryptForm object.
If called with no $secret it returns the current secret key or undef if
undefined.

Upon error, the method returns undef and sets error().

=item B<usecharset>(1)

Enables or disables the character set encoding/decoding of encrypted/decrypted
strings. This method is analogues to the usecharset paramater when creating a
CGI::EncryptForm object. By default usecharset is enabled (1) and should be
ignored unless you use this module in non CGI programs. The encode/decode
routine applies the default or user defined (B<see charset()>) character set to
encode/decode the encrypted string, before returning to the caller.

=item B<charset>($arrayref)

Sets the character set which will be used to encode/decode the
encrypted/decrypted string. This method accepts a single array reference that
must contain a character set from 0 to 255, where by each element must be 2
characters and UNIQUE. e.g.

  charset(qw[/aA aB aC aD ... /])

If this method is not called with your own character set, a default
character set will be used which produces suitable output to store the
result of the encrypt() method in form fields, URL's and cookies.

Upon error, the method returns undef and sets error().

=item B<error>()

Returns the last error as a scalar. You would normally read this if any
method returns undef. error() is always cleared for each method that
executes successfully.

=back

=head1 EXAMPLE

This example illustrates the use of CGI::EncryptForm in combination with
CGI.pm to maintain stateful information in a multi-form CGI script.

  #!/usr/local/bin/perl

  use CGI::EncryptForm;
  use CGI;
  use vars qw($cgi $cfo);

  $cgi = new CGI();
  $cfo = new CGI::EncryptForm(secret_key => 'blah');

  print $cgi->header(), $cgi->start_html(), $cgi->start_form();

  if (defined $cgi->param('enc')) {
      form3();
  }
  elsif (defined $cgi->param('something')) {
      form2();
  }
  else {
      form1();
  }

  print $cgi->end_html(), $cgi->end_form();

  sub form1 {

    print "<h1>form1</h1>",
          "Type something and we will remember it: ",
          $cgi->textfield('something'), $cgi->submit();
  }

  sub form2 {

    print "<h1>form2</h1>",
          $cgi->hidden(-name=>'enc', value=>$cfo->encrypt({ $cgi->Vars })),
          "Now click here and I will tell you what you typed based on ",
          "the encrypted hidden form field, which you would normally ",
          "only see if you view the HTML source. For the sake of this ",
          "demonstration the encrypted field is included below.<p>",
          $cfo->encrypt(), "<p>",
          "Before proceeding with this form I suggest you take note of ",
          "what the encrypted field looks like, then click the back ",
          "button and resubmit the previous form with the same value ",
          "again. What you will notice is the encrypted field will ",
          "change. This is because the SHA encryption algorithm is ",
          "based on a secret key and a random key. In the module we ",
          "take care of generating a unique random key for each ",
          "invocation of the encryption routine, which is why a ",
          "distinct encrypted string is produced each time.",
          "<p>", $cgi->submit();
  }

  sub form3 {

    my $hashref = $cfo->decrypt($cgi->param('enc'));
    if (!defined($hashref)) {
      print $cfo->error();
      return;
    }
    print "<h1>form3</h1>",
          "Previously in the first form you typed:<p>", $hashref->{something},
          "<p>We reproduced this data by decrypting the hidden form ",
          "field called 'enc', which was passed to us from the previous ",
          "form. You may like to try and tamper with the hidden form ",
          "field in form2, to see if you can alter the result of the ",
          "data as it originally flows from form 1 to form 3. Good luck";
  }

=head1 NOTES

CGI::EncryptForm is not limited to form fields. The encrypted result can be
stored in cookies and URL's as well. Personally though, I discourage this
because your more likely to exceed size limitations with various web browsers
and servers.

=head1 BUGS

None that I know of.

=head1 TODO

None.

=head1 AUTHOR

Copyright 1999, Peter Marelas.  All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Bug reports and comments to maral@phase-one.com.au.

Thanks to the authors of these fine perl modules Storable, Digest::SHA1
and Crypt::HCE_SHA.

=head1 SEE ALSO

Storable, Digest::SHA1, Digest::HCE_SHA1

=cut
