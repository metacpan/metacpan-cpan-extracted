# ----------------------------------------------------------------------------
# Crypt::PGPSimple.pm
# Copyright (c) 2000 Jason M. Hinkle. All rights reserved. This module is
# free software; you may redistribute it and/or modify it under the same
# terms as Perl itself.
# For more information see: http://www.verysimple.com/scripts/
#
# LEGAL DISCLAIMER:
# This software is provided as-is.  Use it at your own risk.  The
# author takes no responsibility for any damages or losses directly
# or indirectly caused by this software.
# ----------------------------------------------------------------------------
package Crypt::PGPSimple;
require 5.000;

$Crypt::PGPSimple::VERSION = "0.13";
$Crypt::PGPSimple::ID = "Crypt::PGPSimple.pm";

=head1 NAME

Crypt::PGPSimple - Interface to PGP for Windows and UNIX.  No other mods required.

=head1 DESCRIPTION

Object oriented interface to PGP.  Requires PGP installed on the server.
Allows Perl scripts to encrypt, decrypt and sign messages using PGP
for the encyption.  Tested with PGP 2.6.2 and PGP 6.5.8 on UNIX and 
Windows.

=head1 SYNOPSIS

	use Crypt::PGPSimple;
	my ($objPGP) = new Crypt::PGPSimple;
	
	# tell Crypt::PGPSimple about the PGP executable (these are the defaults, by the way,
	# so if this matches your system, you don't need to set these.  
	# PgpTempDir needs to be writable by the account running the script.
	$objPGP->Version(2.6.2);  # (not currently used, but might be later)
	$objPGP->PgpExePath("C:\\Progra~1\\Networ~1\\Pgp\\PGP.exe");
	$objPGP->PgpKeyPath("C:\\Progra~1\\Networ~1\\Pgp\\PgpKey~1");
	$objPGP->PgpTempDir("C:\\");

	# Example 1: Encrypt
	$objPGP->PublicKey("myfriend\@herhost.com");
	$objPGP->PlainText($plain_text_message);
	$objPGP->Encrypt;
	my ($encrypted_message) = $objPGP->EncryptedText;
	
	# Example 2: Decrypt
	$objPGP->Password("mypassword");
	$objPGP->EncryptedText($encrypted_message);
	$objPGP->Decrypt;
	my ($plain_text_message) = $objPGP->PlainText;
	
	# Example 3: EncryptSign
	$objPGP->PublicKey("myfriend\@herhost.com");
	$objPGP->PrivateKey("me\@myhost.com");
	$objPGP->Password("mypassword");
	$objPGP->PlainText($plain_text_message);
	$objPGP->EncryptSign;
	my ($encrypted_signed_message) = $objPGP->EncryptedText;
	
	# Example 4: Sign
	$objPGP->PrivateKey("me\@myhost.com");
	$objPGP->Password("mypassword");
	$objPGP->PlainText($plain_text_message);
	$objPGP->Sign;
	my ($signed_message) = $objPGP->SignedText;
	
=head1 USAGE

See http://www.verysimple.com/scripts/ for more information.

=head1 PROPERTIES

Calling a property with no arguments will return the current value.
Calling a property with an argument will change the current value to
the value of the argument supplied and return true (1).

	EncryptedText
	ErrDescription
	Password
	PgpExePath
	PgpKeyPath
	PgpTempDir
	PgpTimeZone
	PgpVersion
	PlainText
	PrivateKey
	PublicKey
	Result
	SignedText
	Version

=head1 METHODS

The PGP-related methods (encrypting, decrypting, etc) will return true (1) if
they succeeded or false (0) if not.  The PGP result message is available
in the Result property.  If an error occured, ErrDescription may contain
details.

	Decrypt
	DoPgpCommand($strPgpCommand, $strArguments)
	Encrypt
	EncryptSign
	ErrClear
	Reset
	Sign
	new

=head1 VERSION HISTORY

	0.13 (11/04/00) Updated documentation only.
	0.12 (11/03/01) Fixed bug w/ multiple recieients (Thanks Ken Hoover) 
	0.11 (01/09/00) Original Release

=head1 BUGS & KNOWN ISSUES

This module may not work properly with PGP 5.x.  Version 5 used a slightly
different command-line syntax which was apparently dropped for version 6.  
There are no current plans to test or modify this module for use with PGP 5.

=head1 AUTHOR

Jason M. Hinkle

=head1 COPYRIGHT

Copyright (c) 2001 Jason M. Hinkle.  All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#_____________________________________________________________________________
sub new {
	$|++;
	my $class = shift;
	my $this = {
		strPgpVersion		=> 6.5.8,
		strPgpExePath		=> "C:\\Progra~1\\Networ~1\\Pgp\\PGP.exe",
		strPgpKeyPath		=> "C:\\Progra~1\\Networ~1\\Pgp\\PgpKey~1",
		strPgpTempDir		=> "C:\\",
		strPgpTimeZone		=> "CST6CDT",
		strPublicKey		=> "",
		strPrivateKey		=> "",
		strPassword			=> "",
		strPlainText		=> "",
		strEncryptedText	=> "",
		strSignedText		=> "",
		strResult			=> "",
		strErrDescription	=> "",
	};
	bless $this, $class;

	return $this;
}

# ###########################################################################
# PUBLIC PROPERTIES

#_____________________________________________________________________________
sub Version {
	return $VERSION;
}

#_____________________________________________________________________________
sub PgpVersion {
	return shift->_GetSetProperty("strPgpVersion",shift);
}

#_____________________________________________________________________________
sub PgpExePath {
	return shift->_GetSetProperty("strPgpExePath",shift);
}

#_____________________________________________________________________________
sub PgpKeyPath {
	return shift->_GetSetProperty("strPgpKeyPath",shift);
}

#_____________________________________________________________________________
sub PgpTempDir {
	return shift->_GetSetProperty("strPgpTempDir",shift);
}

#_____________________________________________________________________________
sub PgpTimeZone {
	return shift->_GetSetProperty("strPgpTimeZone",shift);
}

#_____________________________________________________________________________
sub PublicKey {
	return shift->_GetSetProperty("strPublicKey",shift);
}

#_____________________________________________________________________________
sub PrivateKey {
	return shift->_GetSetProperty("strPrivateKey",shift);
}

#_____________________________________________________________________________
sub Password {
	return shift->_GetSetProperty("strPassword",shift);
}

#_____________________________________________________________________________
sub PlainText {
	return shift->_GetSetProperty("strPlainText",shift);
}

#_____________________________________________________________________________
sub EncryptedText {
	return shift->_GetSetProperty("strEncryptedText",shift);
}

#_____________________________________________________________________________
sub SignedText {
	return shift->_GetSetProperty("strSignedText",shift);
}

#_____________________________________________________________________________
sub Result {
	return shift->{'strResult'};
}

#_____________________________________________________________________________
sub ErrDescription {
	return shift->{'strErrDescription'};
}

# ###########################################################################
# PRIVATE PROPERTIES

#_____________________________________________________________________________
sub _GetSetProperty {
	# private fuction that is used by all the properties to get/set values
	# if a parameter is sent in, then the property is set and true is returned.
	# if no parameter is sent, then the current value is returned
	my $this = shift;
	my $fieldName = shift;
	my $newValue = shift;
	if (defined($newValue)) {
		$this->{$fieldName} = $newValue;
	} else {
		return $this->{$fieldName};
	}
	return 1;
}

# ###########################################################################
# PUBLIC METHODS

#_____________________________________________________________________________
sub Encrypt {
	my ($this) = shift;

	my ($return_value) = 0;
	
	# generate the command line
	my ($pgp_command) =  $this->{'strPgpExePath'} 
		. " -feat +batchmode +force " 
		. $this->{'strPublicKey'};
	
	$this->{'strEncryptedText'} = $this->DoPgpCommand($pgp_command,$this->{'strPlainText'});
	
	# if there were results then everything went as planned
	if ($this->{'strEncryptedText'} ne "") {
		$return_value = 1;
	}

	return $return_value;
}

#_____________________________________________________________________________
sub Decrypt {
	my ($this) = shift;

	# assume fail
	my ($return_value) = 0;
	
	# generate the command line
	my ($pgp_command) =  $this->{'strPgpExePath'} 
		. " -f +batchmode +force";
	
	$this->{'strPlainText'} = $this->DoPgpCommand($pgp_command,$this->{'strEncryptedText'});
	
	# if there were results then everything went as planned
	if ($this->{'strPlainText'} ne "") {
		$return_value = 1;
	}

	return $return_value;
}

#_____________________________________________________________________________
sub EncryptSign {
	my ($this) = shift;

	my ($return_value) = 0;
	
	# generate the command line
	my ($pgp_command) =  $this->{'strPgpExePath'} 
		. " -feast +batchmode +force "
		. $this->{'strPublicKey'} 
		. " -u " . $this->{'strPrivateKey'};
	
	$this->{'strEncryptedText'} = $this->DoPgpCommand($pgp_command,$this->{'strPlainText'});
	
	# if there were results then everything went as planned
	if ($this->{'strEncryptedText'} ne "") {
		$return_value = 1;
	}

	return $return_value;
}

#_____________________________________________________________________________
sub Sign {
	my ($this) = shift;

	my ($return_value) = 0;
	
	# generate the command line
	my ($pgp_command) =  $this->{'strPgpExePath'} 
		. " -fts +batchmode +force -u "
		. $this->{'strPrivateKey'};
	
	$this->{'strSignedText'} = $this->DoPgpCommand($pgp_command,$this->{'strPlainText'});
	
	# if there were results then everything went as planned
	if ($this->{'strSignedText'} ne "") {
		$return_value = 1;
	}

	return $return_value;
}

#_____________________________________________________________________________
sub ErrClear {
	$strErrDescription = "";
	return 1;
}

#_____________________________________________________________________________
sub Reset {
	my ($this) = shift;
	my ($clear_key_info) = shift || "";

	$this->{'strPlainText'} = "";
	$this->{'strEncryptedText'} = "";
	$this->{'strSignedText'} = "";
	$this->{'strResult'} = "";
	$this->{'strErrDescription'} = "";
	
	if ($clear_key_info) {
		$this->{'strPublicKey'} = "";
		$this->{'strPrivateKey'} = "";
		$this->{'strPassword'} = "";
	}
	return 1;
}


#_____________________________________________________________________________
sub DoPgpCommand {
	my ($this) = shift;
	my ($pgp_command) = shift || "";
	my ($pgp_args) = shift || "";
	
	my ($return_value) = "";

	# get the filepath settings and set our temp file paths
	my ($encrypted_file_path) = $this->{'strPgpTempDir'} . $$ . ".pgp";
	my ($stdout_path) = $this->{'strPgpTempDir'} . $$ . ".txt";
	
	$pgp_command .= " > " . $encrypted_file_path;
	
	# UNCOMMENT TO DEBUG
	# print $encrypted_file_path . "\n";
	# print $stdout_path . "\n";
	# print $pgp_command . "\n";
	# print $pgp_args . "\n";
	
	# set the environmental variables
	$ENV{"TZ"} = $this->{'strPgpTimeZone'};
	$ENV{"PGPPATH"} = $this->{'strPgpKeyPath'};
	$ENV{"PGPPASS"} = $this->{'strPassword'};
	
	# do our redirection magic.  pgp insists on sending text to STDERR and STDOUT
	# even if you tell it to be quite.  this way we can catch them all.
	open (OLDOUT, ">&STDOUT");
	open (OLDERR, ">&STDERR");
	open (STDOUT, ">$stdout_path");
	open (STDERR, ">>&STDOUT");

	# execute PGP command
	open (PGPCOMMAND, "|$pgp_command");
	print PGPCOMMAND $pgp_args;
	close (PGPCOMMAND);

	# undo our redirection magic
	close (STDOUT);
	close (STDERR);
	open (STDOUT, ">&OLDOUT");
	open (STDERR, ">&OLDERR");

	# close these just to avoid Perl warnings
	close (OLDOUT);
	close (OLDERR);

	# open the encrypted file
	open (ENCRYPTED, "$encrypted_file_path");
	$return_value = join('',<ENCRYPTED>);
	close (ENCRYPTED);

	# open the redirect file to see what pgp sent to STDOUT & STDERR
	open (PGPERROR, "$stdout_path");
	$this->{'strResult'} = join('',<PGPERROR>);
	close (PGPERROR);

	# delete the temporary files (COMMENT TO DEBUG)
	unlink($encrypted_file_path);
	unlink($stdout_path);
	
	# if there is no encrypted text, then something went wrong
	if ($return_value eq "") {
		$this->{'strErrDescription'} = "PGP Command Failed.  Check Result Property For Details.";
	}
	
	$ENV{"PGPPASS"} = "";
	return $return_value;
}
1;