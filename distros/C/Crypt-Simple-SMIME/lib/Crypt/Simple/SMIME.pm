#!/usr/bin/perl
################################################################################
#
#  Script Name : $RCSFile$
#  Version     : 1
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Description: 
#               
#    Program description.
#
#
#  Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.
#
#  $Header: /home/cvs/simple_smime/lib/Crypt/Simple/SMIME.pm,v 0.9 2005/01/29 14:52:13 cvs Exp $
#
#  $Log: SMIME.pm,v $
#  Revision 0.9  2005/01/29 14:52:13  cvs
#  Minor change to version assignement syntax.
#
#  Revision 0.8  2005/01/29 14:47:24  cvs
#  Changed SignedEmailCertificate method to elimiate a warning message when it tries to detect if a filename or certificate was provided to the method.
#
#  Revision 0.7  2005/01/29 14:38:30  cvs
#  Changed tmp file syntax to make more friendly with some ISP temp file access restrictions.  Thanks to for E. v. Pappenheim for providing the patch.
#
#  Revision 0.6  2004/11/01 16:53:38  cvs
#  Fix so email sets the from address properly
#
#  Revision 0.5  2004/10/10 21:11:41  cvs
#  Minor fixes
#
#  Revision 0.4  2004/10/10 19:07:26  cvs
#  Improve error reporting
#
#  Revision 0.1  2004/10/10 00:01:27  cvs
#  Initial checkin
#
#  Revision 1.1  2004/10/09 15:51:27  cvs
#  Version one
#
#
#
################################################################################

=pod

=head1 NAME 

Crypt::Simple::SMIME - Simple SMIME Email Encryptor 

=head1 SYNOPSIS

use Crypt::Simple::SMIME;

my $c = new Crypt::Simple::SMIME( 
	{
		'openssl'		=>	'/opt/openssl/bin/openssl',
		'sendmail'		=>	'/usr/sbin/sendmail'
		'certificate'	=>	'/home/bob/certificate.pem'
	}
);

or:

my $c = new Crypt::Simple::SMIME();

$c->OpenSSLPath('/opt/openssl/bin/openssl');

$c->SendmailPath('/usr/sbin/sendmail');

$c->CertificatePath('/home/bob/certificate.pem')

$c->SendMail($from,$to,$subject,$message);

$c->Close();

or:

my $c = new Crypt::Simple::SMIME();

$c->SignedEmailCertificate($signed_email_text)

$c->SendMail($to,$from,$subject,$message);

$c->Close();

or:

my $c = new Crypt::Simple::SMIME();

$c->SignedEmailCertificate($signed_email_file)

$c->SendMail($to,$from,$subject,$message);

$c->Close();


or:

my $c = new Crypt::Simple::SMIME();

$c->Certificate($certificate_text)

$c->SendMail($to,$from,$subject,$message);

$c->Close();


=head1 DESCRIPTION 

After looking around for a simple way to send encrypted email to Outlook,
Mozilla and Netscape email clients, the modules had requirements that
required installing and/or compiling other software.  This module is a simple
and secure method of sending encrypted email.

No encrypted files are written to the hard drive.  So there's no chance
of others accessing the information.  The only files stored on the hard drive
is public keys/certificates

=head1 REQUIREMENTS 

The only two requirements are the openssl binary be installed on the system and
the system has Sendmail or a binary that emulates Sendmail.  For example Qmail 
provides a binary to emulate Sendmail.

=head1 METHODS

The methods described in this section are available for all 
C<Crypt::Simple::SMIME> objects.

=cut

###############################################################################
#
package Crypt::Simple::SMIME;
use strict;
use File::Temp qw/ :mktemp  /;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 0.9 $' =~ /\$Revision:\s+([^\s]+)/;



###############################################################################

=over

=item new(%hash)

The new method is the constructor.  The input hash can inlude the following:

openssl				/ Path to the openssl binary on your system (optional)
sendmail			/ Path to the sendmail binary on your system (optional)

my $2 = new Crypt::Simple::SMIME( 
									{
										'openssl'		=>	'/opt/openssl/bin/openssl',
										'sendmail'		=>	'/usr/sbin/sendmail'
										'certificate'	=>	'/home/bob/certificate.pem'
									}
								);

or:

my $c = new Crypt::Simple::SMIME();

=cut

sub new {

   my $type  = shift;
   my ($opt) = @_;
   my $self  = {};

   $self->{open_ssl_path} = $opt->{openssl};
   $self->{sendmail_path} = $opt->{sendmail};
   $self->{certificate_path} = $opt->{certificate};
   $self->{encrypt_command}	= undef;

   $self->{error_message} = undef;

   bless $self, $type;

   # If openssl path wasn't provided, try to find it
   #
   if ( ! $opt->{openssl} ) {

		$self->_find_open_ssl();
   }

   if ( ! $opt->{sendmail} ) {

		$self->_find_sendmail();
   }

   return $self;
}
###############################################################################
# EXTERNAL METHODS
#


=item $c->SendMail($from,$to,$subject,$message)

Given the from address, to address, subject and the message, encrypts and sends
the message to the given address.

=cut


sub SendMail(){

	my $self = shift;
	my ($from,$to,$subject,$message) = @_;
	my $rtn = 1;

	if ( ! $from ) {

		$self->Error("From address missing in method SendMail");
		$rtn = 0;
	}
	elsif ( ! $to ) {

		$self->Error("To address missing in method SendMail");
		$rtn = 0;
	}
	elsif ( ! $subject ) {

		$self->Error("Subject missing in method SendMail");
		$rtn = 0;
	}
	elsif ( ! $message ) {

		$self->Error("Message missing in method SendMail");
		$rtn = 0;
	}
	elsif ( ! -f $self->{open_ssl_path} ) {

		$self->Error("Can't find openssl binary");
		$rtn = 0;
	}

	elsif ( ! -f $self->{sendmail_path} ) {

		$self->Error("Can't find sendmail binary");
		$rtn = 0;
	}

	elsif ( ! -f $self->{certificate_path} ) {

		$self->Error("Can't find certificate file");
		$rtn = 0;
	}
	else {

		my $openssl		= $self->{open_ssl_path};
		my $pub_cert	= $self->{certificate_path};
		my $sendmail	= $self->{sendmail_path};

		my $openssl_err = mktemp('/tmp/smimeXXXXXXX');
		my $sendmail_out = mktemp('/tmp/smimeXXXXXXX');
		my $sendmail_err = mktemp('/tmp/smimeXXXXXXX');

		$subject =~ s/'/\\'/g;

	    my $result;

	    $self->{encrypt_command} = "echo '\n" . $self->_str_replace('"', '\\"', $message ) . "'  | $openssl smime -to '$to' -subject '$subject' -from '$from' -encrypt  $pub_cert 2> $openssl_err | $sendmail -f$from -t  > $sendmail_out 2> $sendmail_err";

        $result = system($self->{encrypt_command});

		if ( $result ) {

			my $message = "Unknown error sending encrypted mail\n";

			$message .= "openssl  STDERR: " . $self->_read_file($openssl_err) . "\n\n";
			$message .= "sendmail STDOUT: " . $self->_read_file($sendmail_out) . "\n\n";
			$message .= "sendmail STDOUT: " . $self->_read_file($sendmail_err) . "\n\n";

			$self->Error($message);
			$rtn = 0;
		}
		if ( -f $openssl_err )  { unlink($openssl_err);	}
		if ( -f $sendmail_out ) { unlink($sendmail_out);	}
		if ( -f $sendmail_err ) { unlink($sendmail_err);	}

	}
	return $rtn;
}

=item $c->Close()

Cleans up after the module by deleting temporary files.

=cut


sub Close(){

	my $self = shift;

	if ( -f $self->{tmp_cert_file} ) {

		unlink( $self->{tmp_cert_file} );
	}

	if ( -f $self->{tmp_msg_file} ) {

		unlink( $self->{tmp_msg_file} );
	}

	if ( -f $self->{tmp_signed_cert_path} ) {

		unlink( $self->{tmp_signed_cert_path} );
	}
}


###############################################################################
# INTERNAL METHODS
#

sub _str_replace {
   my $self  = shift;
   my ($search,$replace,$text) = @_;

   $text =~ s/$search/$replace/g;

   return $text;
}
# Looks for openssl binary at common locations
#
sub _find_open_ssl {

   my $self  = shift;
   my ($var) = @_;

   if ( -f '/usr/bin/openssl' ) {

	   $self->{open_ssl_path} = '/usr/bin/openssl';
   }
   elsif ( -f '/usr/local/bin/openssl' ) {

	   $self->{open_ssl_path} = '/usr/local/bin/openssl';
   }
}
# Looks for sendmail binary at common locations
#
sub _find_sendmail {

   my $self  = shift;
   my ($var) = @_;

   if ( -f '/usr/bin/sendmail' ) {

	   $self->{sendmail_path} = '/usr/bin/sendmail';
   }
   elsif ( -f '/usr/local/bin/sendmail' ) {

	   $self->{sendmail_path} = '/usr/local/bin/sendmail';
   }
   elsif ( -f '/usr/lib/sendmail' ) {

	   $self->{sendmail_path} = '/usr/lib/sendmail';
   }
}

sub _assessor_util(){

	my $self = shift;
	my ($value,$key) = @_;

	if ($value) {

		$self->{$key} = $value;
	}
	return $self->{$key};
}

sub _read_file {
	my $self = shift;
	my ($filename) = @_;
	my $contents;

	open(IN, "< $filename");

	while ( my $line = <IN> ) {

		$contents .= $line;
	}
	return $contents;
}
# Called if using a Netscape certificate is being used
#
sub _convert_signed_certificate {

	my $self = shift;
	my $rtn = 1;

	$self->_write_signed_email_to_temp_file();


	my $pemfile = mktemp('/tmp/smimeXXXXXXX') . ".pem";

	$self->CertificatePath($pemfile);
	$self->{tmp_cert_file} = $pemfile;

	my $signedemailfile = $self->{signed_cert_path};

	my $msgfile = mktemp('/tmp/smimeXXXXXXX');
	$self->{tmp_msg_file} = $pemfile;

	my $openssl = $self->OpenSSLPath();

	my $cmd = "$openssl smime -verify -in $signedemailfile -signer $pemfile -out $msgfile 2>/dev/null > /dev/null";

    my $result = system($cmd);

	if (! $result ) {

			$self->Error("Unknown error extracting certificate from signed email");
			$rtn = 0;
	}
	return $rtn;
}

sub _write_signed_email_to_temp_file {

	my $self = shift;

	$self->{signed_cert_path} = mktemp('/tmp/smimeXXXXXXX') . ".p12";
	my $filename = $self->{signed_cert_path};

	$self->{tmp_signed_cert_path} = $filename;

	open( CRT, "> $filename");
	print CRT $self->SignedEmailCertificate();
	close(CRT);
}


=head1 DATA ACCESSORS

The methods described in this section allow setting and reading data.

=cut


###############################################################################
# ACCESSORS
#
=item $c->OpenSSLPath($openssl_path)

If a the open sll binary path is passed, this accessor will set the value.  
It will always return the value stored.

=cut

sub OpenSSLPath(){

	my $self = shift;
	my ($var) = @_;

	return $self->_assessor_util($var,'open_ssl_path');
}

=item $c->SendmailPath($sendmail_path)

If a the sendmail binary path is passed, this accessor will set the value.  
It will always return the value stored.

=cut

sub SendmailPath(){

	my $self = shift;
	my ($var) = @_;

	return $self->_assessor_util($var,'sendmail_path');
}

=item $c->CertificatePath($certificate_path)

If a the sendmail binary path is passed, this accessor will set the value.  
It will always return the value stored.

=cut


sub CertificatePath(){

	my $self = shift;
	my ($var) = @_;

	return $self->_assessor_util($var,'certificate_path');
}

=item $c->SignedEmailCertificate($certificate)

Accepts the text of a signed email or the path to a file that contains the
email.  It returns the text of a signed email.  

To get a certificate from asigned email, save the message to a file and and 
pass the contents this routine.

=cut


sub SignedEmailCertificate(){

	my $self = shift;
	my ($var) = @_;

	if ($var) {

		if ( ! $var =~ /\n/ && -f $var ) {

			open(FILE,"< $var");
			$var = '';
			while( my $line = <FILE> ) {

				$var .= $line;
			}
			close(FILE);
		}

		$self->{signed_certificate} = $var;
		$self->_convert_signed_certificate();
	}
	return $self->{signed_certificate};
}
=item $c->Certificate($certificate)

Accepts the certificate contents from a variable to use to encrypt the message.

=cut


sub Certificate(){

	my $self = shift;
	my ($var) = @_;

	if ($var) {

		$self->{certificate} = $var;

		my $pemfile = mktemp('/tmp/smimeXXXXXXX') . ".pem";

		$self->CertificatePath($pemfile);
		$self->{tmp_cert_file} = $pemfile;

		open(FILE,"> $pemfile");
		print FILE $var;
		close(FILE);

	}
	return $self->{certificate};
}

=item $c->Error()

Returns true if the module encountered an error.

=cut


sub Error(){

	my $self = shift;
	my ($var) = @_;

	return $self->_assessor_util($var,'error_message');
}

=item $c->ErrorMessage()

Returns the error message module encountered an error.

=cut


sub ErrorMessage(){

	my $self = shift;
	my ($var) = @_;

	return $self->_assessor_util($var,'error_message');
}
=item $c->EncryptCommand()

Returns the command used to encrypt the email.

=cut


sub EncryptCommand(){

	my $self = shift;
	my ($var) = @_;

	return $self->_assessor_util($var,'encrypt_command');
}



#########################################################################################33
# End of class

1;
__END__


=back

=head1 ERRORS/BUGS

=over 4

=item Any erros		

This will occur if your LWP does not support SSL (i.e. https).  I suggest
installing the L<Crypt::SSLeay> module.

=back

=head1 IDEAS/TODO

Build methods for each type of transaction so you don't need to
know UTIs and other FedEx codes. FedEx Express Ship-A-Package UTI 2016 
would be called via $object->FDXE_ship();

=head1 AUTHOR

Duane Hinkley, <F<duane@dhwd.com>>

L<http://www.dhwd.com>


If you have any questions, comments or suggestions please feel free 
to contact me.

=head1 COPYRIGHT

Copyright 1995-2004, Down Home Web Design, Inc.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this module is likely to be available from CPAN
as well as:

http://www.dhwd.com/

=head1 SEE ALSO

L<Crypt::SSLeay>, L<LWP::UserAgent>, L<Business::FedEx::Constants>


1;

