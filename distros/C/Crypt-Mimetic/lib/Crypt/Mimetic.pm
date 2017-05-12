=pod

=head1 NAME

Crypt::Mimetic - Crypt a file and mask it behind another file


=head1 SYNOPSIS

 use Crypt::Mimetic;
	
 Crypt::Mimetic::Mask($original_file, $mask_file, $destination_file, $algorithm);
 Crypt::Mimetic::Unmask($mimetic_file);

 Crypt::Mimetic::Main($original_file, $mask_file, $destination_file, [$algorithm]);
 Crypt::Mimetic::Main($mimetic_file);
	

=head1 DESCRIPTION

This module allows you to hide a file by encrypting in and then attaching
it to another file of your choice.
This mimetic file then looks and behaves like a normal file,
and can be stored, used or emailed without attracting attention.


=head1 EXAMPLES

=head2 Here your first running example

 use Crypt::Mimetic;
 use Error;
 $Error::Debug = 1;

 &Crypt::Mimetic::Main(@ARGV);

You should already have it in your bin/ files: write I<mimetic> and follow instructions.

=head2 How to make a test of all encryption algorithms

 use Crypt::Mimetic;

 use Error qw(:try);
 $Error::Debug = 1;

 print "\nPerforming tests for Crypt::Mimetic\n";
 print "Looking for available encryption algorithms, please wait... ";
 select((select(STDOUT), $| = 1)[0]); #flush stdout

 @algo = Crypt::Mimetic::GetEncryptionAlgorithms();
 print @algo ." algorithms found.\n\n";

 $str = "This is a test string";
 $failed = 0;
 $warn = 0;

 foreach my $algo (@algo) {

    try {

       print ''. Crypt::Mimetic::ShortDescr($algo) ."\n";
       print " Encrypting string '$str' with $algo...";
       select((select(STDOUT), $| = 1)[0]); #flush stdout

       ($enc,@info) = Crypt::Mimetic::EncryptString($str,$algo,"my stupid password");
       print " done.\n";

       print " Decrypting encrypted string with $algo...";
       select((select(STDOUT), $| = 1)[0]);

       $dec = Crypt::Mimetic::DecryptString($enc,$algo,"my stupid password",@info);
       print " '$dec'.\n";

       if ($dec eq $str) {
          print "Algorithm $algo: ok.\n\n";
       } else {
          print "Algorithm $algo: failed. Decrypted string '$dec' not equals to original string '$str'\n\n";
          $failed++;
       }#if-else

    } catch Error::Mimetic with {
       my $x = shift;

       if ($x->type() eq "error") {
          print "Algorithm $algo: error. ". $x->stringify() ."\n";
          $failed++;
       } elsif ($x->type() eq "warning") {
          print "Algorithm $algo: warning. ". $x->stringify() ."\n";
          $warn++;
       }#if-else

    }#try-catch

 }#foreach

 print @algo ." tests performed: ". (@algo - $failed) ." passed, $failed failed ($warn warnings).\n\n";
 exit $failed;

Script I<test.pl> used by I<make test> in this distribution
do exactly the same thing.

=cut

package Crypt::Mimetic;
use strict;
use vars qw($VERSION);

use Error qw(:try);
use Error::Mimetic;
use Term::ReadKey;
use File::Copy;
use File::Find ();

$VERSION = '0.02';

=pod

=head1 PROCEDURAL INTERFACE

=over 4

=item @array I<GetEncryptionAlgorithm> ()

Return an array with names of encryption algorithms. Each algorithm is
implemented in module Crypt::Mimetic::<algorithm>

=cut

sub GetEncryptionAlgorithms {
	# Set the variable $File::Find::dont_use_nlink if you're using AFS,
	# since AFS cheats.

	# for the convenience of &wanted calls, including -eval statements:
	use vars qw/*name *dir *prune/;
	*name   = *File::Find::name;
	*dir    = *File::Find::dir;
	*prune  = *File::Find::prune;

	my (@dirs, %algo);
	my $wanted = sub {
		my ($dev,$ino,$mode,$nlink,$uid,$gid);

		/^Mimetic\z/os &&
		(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
		-d _ &&
		push(@dirs,"$name");
	};

	# Traverse desired filesystems
	File::Find::find({wanted => $wanted}, @INC);

	$wanted = sub {
		my ($dev,$ino,$mode,$nlink,$uid,$gid);

		/^.*\.pm\z/os &&
		(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
		-f _ || return;
		s/^(.+)\.pm$/$1/o;
		$algo{$_} = $_;
	};

	File::Find::find({wanted => $wanted}, @dirs);
	return ( keys %algo );
}

=pod

=item string I<GetPasswd> ($prompt)

Ask for a password with a given prompt (default "Password: ")
and return it.

=cut

sub GetPasswd {
	my ($prompt) = @_;
	$prompt = "Password: " unless $prompt;
	print STDERR $prompt;
	ReadMode('noecho');
	my $key = ReadLine(0);
	ReadMode('restore');
	print "\n";
	$key =~ s/[\r\n]*$//o;
	return $key;
}

=pod

=item string I<GetConfirmedPasswd> ()

Ask for a password twice and return it only if it's correct.

Throws an I<Error::Mimetic> if passwords don't match

=cut

sub GetConfirmedPasswd {
	my $passwd = GetPasswd();
	return "" if ($passwd eq "");
	my $confirm = GetPasswd("Again: ");
	return $passwd if ($passwd eq $confirm);
	throw Error::Mimetic "Passwords don't match at ". __FILE__ ." line ". __LINE__;
}

#
# @array ExternalCall($algoritm,$func)
#
sub ExternalCall {
	my ($algorithm,$func,@args) = @_;
	eval('use Crypt::Mimetic::' . $algorithm);
	throw Error::Mimetic ("Error using algorithm '$algorithm' at ". __FILE__ ." line ". __LINE__, $@) if $@;
	no strict 'refs';
	return &{ 'Crypt::Mimetic::' . $algorithm . '::' . $func }(@args);
}

=pod

=item string I<ShortDescr> ($algorithm)

Return a short description of $algorithm

=cut

sub ShortDescr {
	my ($algorithm) = @_;
	try {
		return ExternalCall($algorithm,'ShortDescr');
	} catch Error::Mimetic with {
		my $x = shift;
		$x->{'-type'} = "warning";
		throw $x;
	}
}

=pod

=item boolean I<PasswdNeeded> ($algorithm)

Return true if password is needed by this $algorithm, false otherwise.

=cut

sub PasswdNeeded {
	my ($algorithm) = @_;
	return ExternalCall($algorithm,'PasswdNeeded');
}

=pod

=item ($len,$blocklen,$padlen,[string]) I<EncryptFile> ($filename,$output,$algorithm,$key,@info)

Call specific routine to encrypt $filename according to $algorithm. Return 3 int:
 $len      - is the total output length
 $blocklen - length of an encrypted block (if needed)
 $padlen   - length of last encrypted block (if needed)

If $output is null then the output is returned as string.
Ask for a password if key not given.

Throws an I<Error::Mimetic> if cannot open files or if password is not correctly given.

=cut

sub EncryptFile {
	my ($filename,$output,$algorithm,$key,@info) = @_;
	return ExternalCall($algorithm,'EncryptFile',$filename,$output,$algorithm,$key,@info);
}

=pod

=item string I<EncryptString> ($string,$algorithm,$key,@info)

Call specific routine to encrypt $string according to $algorithm and return an encrypted string.
Ask for a password if key not given.

Throws an I<Error::Mimetic> if password is not correctly given.

=cut

sub EncryptString {
	my ($string,$algorithm,$key,@info) = @_;
	return ExternalCall($algorithm,'EncryptString',$string,$algorithm,$key,@info);
}

=pod

=item [string] I<DecryptFile> ($filename,$output,$offset,$len,$algorithm,$key,@info)

Call specific routine to decrypt $filename according to $algorithm. Return decrypted file as string if $output is not given, void otherwise.
Ask for a password if key not given.

Throws an I<Error::Mimetic> if cannot open files or if password is not given

=cut

sub DecryptFile {
	my ($filename,$output,$offset,$len,$algorithm,$key,@info) = @_;
	return ExternalCall($algorithm,'DecryptFile',$filename,$output,$offset,$len,$algorithm,$key,@info);
}

=pod

=item string I<DecryptString> ($string,$algorithm,$key,@info)

Call specific routine to decrypt $string according to $algorithm and return a decrypted string.
Ask for a password if key not given.

Throws an I<Error::Mimetic> if password is not correctly given.

=cut

sub DecryptString {
	my ($string,$algorithm,$key,@info) = @_;
	return ExternalCall($algorithm,'DecryptString',$string,$algorithm,$key,@info);
}

=pod

=item string I<Sign> ($original_file,$mask_file,$dlen,$algorithm,$key,@info)

Create following sign (all on the same line):
 Mimetic\0
 version\0
 mask_file_name\0
 mask_file_length\0
 original_file_name\0
 encrypted_file_length\0
 @info

than encrypt it and calculate length of encrypted sign.
Return a string composed by concatenation of encrypted sign, algorithm (32 bytes null padding string) and its length (8 bytes hex number).

=cut

sub Sign {
	my ($original_file,$mask_file,$dlen,$algorithm,$key,@info) = @_;
	my $mlen = (stat($mask_file))[7];
	my $sign = join "\0", "Mimetic", $VERSION, $mask_file, $mlen, $original_file, $dlen, @info;
	$sign = EncryptString($sign,$algorithm,$key,@info);
	my $slen = pack "a8", sprintf "%x", length($sign);
	my $algo = pack "A32", $algorithm;
	return join '', $sign, ~$algo, ~$slen;
}

=pod

=item (string,int) I<GetSignInfo> ($mimetic_file)

Return the algorithm and the length of the sing read from last 40 bytes of $mimetic_file.

Throws an I<Error::Mimetic> if cannot open file

=cut

sub GetSignInfo {
	my ($mimetic_file) = @_;
	my $len = (stat($mimetic_file))[7];
	my $offset = $len - 40;
	open (FH, "$mimetic_file") or throw Error::Mimetic "Cannot open $mimetic_file: $!";
	my ($algo,$slen) = ("","");
	seek FH, $offset, 0;
	read FH, $algo, 32;
	read FH, $slen, 8;
	close(FH);
	return (unpack ("A32", ~$algo) , hex(~$slen));
}

=pod

=item ($Mimetic,$version,$mask_file,$mlen,$original_file,$olen,@pinfo) = I<ParseSign> ($mimetic_file,$slen,$algorithm,$key,@info);

Extract information from sign of $mimetic_file.
You can obtain $slen and $algorithm from I<GetSignInfo>($mimetic_file) and key from I<GetPasswd>(void)
This sub returns an array:
 $Mimetic        - constant string "Mimetic"
 $version        - version of the module
 $mask_file      - mask file's name
 $mlen           - mask file's length
 $original_file  - original file's name
 $olen           - original file's length
 @pinfo          - specific encryption algorithm information

Throws an I<Error::Mimetic> if cannot open file

=cut

sub ParseSign {
	my ($mimetic_file,$slen,$algorithm,$key,@info) = @_;
	my $len = (stat($mimetic_file))[7];
	my $offset = $len - 40 - $slen;
	open (FH, "$mimetic_file") or throw Error::Mimetic "Cannot open $mimetic_file: $!";
	my $sign = "";
	seek FH, $offset, 0;
	read FH, $sign, $slen;
	close(FH);
	$sign = DecryptString($sign,$algorithm,$key,@info);
	return split "\0", $sign;
}

=pod

=item void I<WriteMaskFile> ($mimetic_file,$len,$mask_file)

Extract the mask file from $mimetic_file and save it in $mask_file.

Throws an I<Error::Mimetic> if cannot open files

=cut

sub WriteMaskFile {
	my ($mimetic_file,$len,$mask_file) = @_;
	my ($buf,$blocks,$padlen) = ("",int($len/32768),($len%32768));
	open (IN, "$mimetic_file") or throw Error::Mimetic "Cannot open $mimetic_file: $!";
	open (OUT, ">$mask_file") or throw Error::Mimetic "Cannot open $mask_file: $!";
	for (my $i = 0; $i < $blocks; $i++ ) {
		read(IN,$buf,32768);
		print OUT $buf;
	}
	read(IN,$buf,$padlen);
	print OUT $buf;
	close(OUT);
	close(IN);
}

=pod

=item void I<Mask> ($original_file,$mask_file,$destination_file,$algorithm,$key,@info)

Mask the $original_file with a $mask_file and put everything in $destination_file, according $algorithm and @info instruction. Return true on success, false otherwise.

Throws an I<Error::Mimetic> if cannot open files or password not correctly given

=cut

sub Mask {
	my ($original_file,$mask_file,$destination_file,$algorithm,$key,@info) = @_;

	#test if destination file is ok
	open (OF,">$destination_file") or throw Error::Mimetic "Cannot open $destination_file: $!";
	close(OF);

	my $passwd_needed = ExternalCall($algorithm,'PasswdNeeded');

	copy ($mask_file,$destination_file) or throw Error::Mimetic "Cannot copy $mask_file to $destination_file: $!";

	$key = GetConfirmedPasswd() or throw Error::Mimetic "Password is needed at ". __FILE__ ." line ". __LINE__ unless ($key || !$passwd_needed);
	my ($len,@einfo) = EncryptFile($original_file,$destination_file,$algorithm,$key,@info);
	my $sign = Sign($original_file,$mask_file,$len,$algorithm,$key,@einfo);

	open (OF,">>$destination_file") or throw Error::Mimetic "Cannot open $destination_file: $!";
	print OF $sign;
	close(OF);
}

=pod

=item boolean I<Unmask> ($mimetic_file,$algorithm,$key,@info)

Unmask a $mimetic file splitting it in 2 files:
 1. mask file
 2. original file

Throws an I<Error::Mimetic> if cannot open files or password not given

=cut

sub Unmask {
	my ($mimetic_file,$algorithm,$key,@info) = @_;
	my ($algo,$slen) = GetSignInfo($mimetic_file);

	$algorithm = $algo unless $algorithm;
	my $passwd_needed = ExternalCall($algorithm,'PasswdNeeded');

	$key = GetPasswd() or throw Error::Mimetic "Password is needed at ". __FILE__ ." line ". __LINE__ unless ($key || !$passwd_needed);
	my ($Mimetic,$version,$mask_file,$mlen,$original_file,$olen,@pinfo) = ParseSign($mimetic_file,$slen,$algorithm,$key,@info);

	throw Error::Mimetic "Cannot do anything on this file: signature not recognized at ". __FILE__ ." line ". __LINE__ if ($Mimetic ne "Mimetic");

	WriteMaskFile($mimetic_file,$mlen,$mask_file);
	DecryptFile($mimetic_file,$original_file,$mlen,$olen,$algorithm,$key,@pinfo);
}

=pod

=item void I<Main> (@arguments)

A demo main to use this module
 Usage:
  to camouflage a file with a mask
    Main($original_file, $mask_file, $destination_file, [$algorithm]);
  to split camouflaged file in original file and mask
    Main($mimetic_file);

=cut

sub Main {
	my @argv = @_;
	my $argc = $#argv + 1;
	if ($argc == 1) {
		return Unmask($argv[0]);
	} elsif ($argc == 3) {
		return Mask($argv[0],$argv[1],$argv[2],"None");
	} elsif ($argc == 4) {
		return Mask($argv[0],$argv[1],$argv[2],$argv[3]);
	} else {
		print <<"END";

Usage (see also Perl documentation about Crypt::Mimetic):

 to camouflage a file with a mask:
   $0 original-file mask-file destination-file [algorithm]

 to split camouflaged file in original file and mask:
   $0 mimetic-file

 (Looking for available encryption algorithms, please wait...)
END
		my @algo = GetEncryptionAlgorithms();
		print " Encryption algorithms found:\n";
		my $err = $Error::Debug;
		$Error::Debug = 1 if $err < 1;
		foreach my $algo (@algo) {
			try {
				print '   * '. ShortDescr($algo) ."\n";
			} catch Error::Mimetic with {
				my $x = shift;
				print "   * $algo - ". $x->stringify();
			}
		}
		$Error::Debug = $err;
		print " See Perl documentation about Crypt::Mimetic::<algorithm> for details.\n\n";
		exit;
	}
}

1;
__END__


=pod

=head2 About errors

Some subroutines in this module throw errors. You can learn more about
this reading documentation about Error::Mimetic(3).


=head1 ENCRYPTION ALGORITHMS
  

=head2 Implementing new algorithm

To implement a new encryption algorithm, let's say Foo,
you should write a module with name Crypt::Mimetic::Foo
that has following subroutines:

=item string I<ShortDescr> ()

Return a short description of algorithm

=item boolean I<PasswdNeeded> ()

Return true if password is needed by this algorithm, false otherwise.

=item ($len,$blocklen,$padlen,[string]) I<EncryptFile> ($filename,$output,$algorithm,$key,@info)

Encrypt a file with Foo algorithm. See I<Crypt::Mimetic::EncryptFile>.

=item string I<EncryptString> ($string,$algorithm,$key,@info)

Encrypt a string with Foo algorithm. See I<Crypt::Mimetic::EncryptString>.

=item [string] I<DecryptFile> ($filename,$output,$offset,$len,$algorithm,$key,@info)

Decrypt a file with Foo algorithm. See I<Crypt::Mimetic::DecryptFile>.

=item string I<DecryptString> ($string,$algorithm,$key,@info)

Decrypt a string with Foo algorithm. See I<Crypt::Mimetic::DecryptString>.

=head2 Installing new algorithms

To install a new mimetic encryption algorithm that you wrote
(or downloaded) you should only install it as a normal Perl module;
Crypt::Mimetic module will be able to find it (and use it) automagically
if it's in one of the directories listed in @INC.

Obviously if you send me your algorithm I'll include it in the new release
of Crypt::Mimetic


=head1 NEEDED MODULES

This module needs:
   Error
   Error::Mimetic
   Term::ReadKey
   File::Copy
   File::Find


=head1 SEE ALSO

Crypt::Mimetic::None(3), Crypt::Mimetic::TEA(3), Crypt::Mimetic::CipherSaber(3)


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself (Artistic/GPL2).


=head1 AUTHOR

Erich Roncarolo <erich-roncarolo@users.sourceforge.net>

=cut
