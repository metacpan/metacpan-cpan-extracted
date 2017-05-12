package Crypt::Pwsafe;
# $Id$

=head1 NAME

Crypt::Pwsafe - Perl extension for decrypting and parsing PasswordSafe V3 data files

=cut

use warnings;
use strict;

use FileHandle;
use Term::ReadKey;  # comment me out
#use autouse Term::ReadKey;
my $SHA = "Digest::SHA";
eval "use $SHA";
if ($@) { $SHA .= "::PurePerl"; eval "use $SHA" }

my $CIPHER = "Crypt::Twofish";
eval "use $CIPHER";
if ($@) { $CIPHER .= "_PP"; eval "use $CIPHER" }

=head1 VERSION

Version 1.2

=cut

our $VERSION = '1.2';

our $DEBUG = 0;

=head1 SYNOPSIS

    use Crypt::Pwsafe;
    my $file = 'pwsafe.psafe3';
    my $key = Crypt::Pwsafe::enter_combination();
    my $pwsafe = Crypt::Pwsafe->new($file, $key);

    # The password for 'user' at 'host' computer in 'Test group'
    my $passwd = $pwsafe->{'Test group'}->{'user@host'};

=cut

my %FieldType = (
	0 => "None",
	1 => "UUID",
	2 => "Group",
	3 => "Title",
	4 => "User",
	5 => "Notes",
	6 => "Password",
	7 => "CTime",
	8 => "PWMTime",
	9 => "ATime",
	10 => "LifeTime",
	11 => "Policy",
	12 => "RecordMTime",
	13 => "URL",
	14 => "AutoType",
	15 => "PWHistory",
	255 => "EndofEntry"
);

# pwsafe3 file header format
# V3TAG == "PWS3";
# SALT = 32 bytes random
# NumHashIters = 32 bit integer (little endian)
# Hash = 32 bytes (NumHashIters+1 rounds of SHA256 of Safe combination concatenated with SALT)
# B1B2 = mKey encrypted using ECB Twofish with PTag as key
# B3B4 = hmac SHA256 key encrypted using ECB Twofish with PTag as key
# CBC IV = random 16 bytes

# Notes on records
# 1. All times are 32-bit little-endian integers
# 2. All field values except UUID and times use UTF8
# 3. SHA256 HMAC at the end of file is calculated on field values only

=head1 DESCRIPTION

Crypt::Pwsafe module provide read-only access to database files created by Version 3
of PasswordSafe utility available from SourceForge at L<http://passwordsafe.sf.net>.

Users of this module should take these notes:

1. All passwords will be stored in memory unencrypted (in the form of Perl hashes) once
the password file is loaded.

2. The module will read the entire content of the password file into memory.  This may
be a problem for large data files on systems with small amount of memory.

3. The modules does not support Version 2 Passwordsafe data files.  Please convert
them to Version 3 if needed.

=cut

sub new {
	my ($class, $file, $pw) = @_;
	my $fh = new FileHandle $file;
	die "Failed to open $file\n" unless defined $fh;
	$pw = enter_combination() unless defined $pw;
	my $header;
	my $len = 72;
	unless ($fh->read($header, $len) == $len) {
		die "$file has < $len bytes.\n";
	}
	$header =~ /^PWS3/ or warn "$file is not a version 3 Password Safe data file.\n";
	my $salt = substr($header, 4, 32);
	my $n_iters = unpack('V', substr($header, 36, 4));
	warn "$file uses < 2048 iterations of hash.\n" if $n_iters < 2048;
	warn "$file uses $n_iters iterations of hash?\n" if $n_iters > 20480;
	my $fhash = substr($header, 40, 32);
	my $ptag = _stretch_key($salt, $n_iters, $fhash, $pw);
	die "Bad safe combination.\n" unless $ptag;
	my $crypt = "";
	# Assume that the whole PWsafe file can comfortably fit into the memory
	while ($fh->read(my $buf, 0x400000)) {
		$crypt .= $buf;
	}
	$fh->close;
	my $self = _decrypt($ptag, $crypt);
	return bless($self, $class);
}

sub _decrypt {
	my ($ptag, $crypt) = @_;
	my $len = length($crypt);
	die "Data is too short: $len bytes\n" unless $len > 112;
	die "Data length is not multiple of 16\n" unless $len % 16 == 0;
	my $term_blk = substr($crypt, -48, 16);
	$term_blk eq 'PWS3-EOFPWS3-EOF' or warn "Bad terminal block\n";
	my $hmac_tail = substr($crypt, -32);
	my ($key, $hmac_key) = _ecb_twofish($ptag, $crypt, 64);
	return _cbc_twofish($key, substr($crypt, 64, -48), $hmac_key, $hmac_tail);
}

sub _ecb_twofish {
	my ($ptag, $crypt, $len) = @_;
	my $fish = $CIPHER =~ /Twofish_PP/ ?
		Crypt::Twofish_PP->new($ptag) : Crypt::Twofish->new($ptag);
	my $bs = $fish->blocksize;
	my $head = "";
	for (my $i = 0; $i < $len; $i += $bs) {
		$head .= $fish->decrypt(substr($crypt, $i, $bs));
	}
	return unpack("a32a32", $head);
}

sub _cbc_twofish {
	my ($key, $crypt, $hmac_key, $hmac_tail) = @_;
	my $fish = $CIPHER =~ /Twofish_PP/ ?
		Crypt::Twofish_PP->new($key) : Crypt::Twofish->new($key);
	my $bs = $fish->blocksize;
	my $prev_crypt = substr($crypt, 0, $bs);
	my $ptr = $bs;
	my $chain_blocks = sub {
		my $curr_crypt = substr($crypt, $ptr, $bs);
		$ptr += $bs;
		my $curr_plain = $fish->decrypt($curr_crypt) ^ $prev_crypt;
		$prev_crypt = $curr_crypt;
		return $curr_plain;
	};
	my $plain = "";
	my $pwsafe = {};
	my $crypt_len = length($crypt);
	my ($group, $title, $user);
	my $entry = {};
	while($ptr < $crypt_len) {
		my $curr_plain = $chain_blocks->();
		# Passwordsafe uses little-endian
		my ($len, $type) = unpack("VC", $curr_plain);
		#printf "len=%2d type=%3d ", $len, $type;
		die "Read negative length from CBC\n" if $len < 0;
		my $buf_len = $len > 11 ? 11 : $len;
		my $buf = substr($curr_plain, 5, $buf_len);
		$len -= $buf_len;
		while($len > 0) {
			my $curr_plain = $chain_blocks->();
			if ($len >= $bs) {
				$buf .= $curr_plain;
				$len -= $bs;
			} else {
				$buf .= substr($curr_plain, 0, $len);
				$len = 0;
			}
		}
		$plain .= $buf;
		#print unpack("H*", $buf), "\n";
		if ($type == 1) { # UUID
			$entry->{UUID} = unpack("H*", $buf);
			print "\tUUID=$entry->{UUID}\n" if $DEBUG;
		} elsif ($type == 2) {    # Group
			$group = pack("U0C*", unpack("C*", $buf));
			print "Group=$group\n" if $DEBUG;
		} elsif ($type == 3) {    # Title
			$title = pack("U0C*", unpack("C*", $buf));
			print "  Title=$title\n" if $DEBUG;
		} elsif ($type == 4) {    # Username
			$user  = pack("U0C*", unpack("C*", $buf));
			print "    User=$user\n" if $DEBUG;
		} elsif ($type == 0xff) { # End of Entry
			if (defined($title) and defined($user)) {
				if (exists $pwsafe->{$group}) {
					$pwsafe->{$group}->{"$user\@$title"} = $entry;
				} else {
					$pwsafe->{$group} = {"$user\@$title" => $entry};
				}
			} else {
				$pwsafe->{$group} = { dummy => $entry};
			}
			($group, $title, $user) = (undef, undef, undef);
			$entry = {};
		} else {
			my $descr = $FieldType{$type};
			$descr = "Type$type" unless defined $descr;
			my $value;
			if ($descr=~/Time/) {
				$value = unpack("V", $buf);
			} else {
				$value = pack("U0C*", unpack("C*", $buf));
			}
			$entry->{$descr} = $value;
			print "\t$descr=$value\n" if $DEBUG;
		}
	}
	my $hmac = Digest::SHA::hmac_sha256($plain, $hmac_key);
	die "SHA256 HMAC error: data integrity has been compromised.\n" unless $hmac eq $hmac_tail;
	return $pwsafe;
}

sub _stretch_key {
	my ($salt, $n_iters, $fhash, $pw) = @_;
	my $sha = eval("new $SHA(256)");
	$sha->add("$pw$salt");
	my $key = $sha->digest;
	for(my $i = 0; $i < $n_iters; $i++) {
		$sha->add($key);
		$key = $sha->digest;
	}
	$sha->add($key);
	return $key if $sha->digest eq $fhash;
}

sub enter_combination {
	print "Enter password safe combination: ";
	local $SIG{__DIE__} = { ReadMode 0 };
	ReadMode 2;
	my $pass = <STDIN>;
	ReadMode 0;
	chomp($pass);
	print "\n";
	return $pass;
}

sub get_password {
	my ($self, $group, $user_title) = @_;
	return unless exists $self->{$group};
	my $gh = $self->{$group};
	return unless exists $gh->{$user_title};
	my $uh = $gh->{$user_title};
	return unless exists $uh->{Password};
	$uh->{Password};
}

=head1 AUTHOR

Shufeng Tan, C<< <shufengtan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-crypt-pwsafe at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Pwsafe>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Pwsafe

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Pwsafe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Pwsafe>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Pwsafe>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Pwsafe>

=back

=head1 ACKNOWLEDGEMENTS

PasswordSafe is a password database utility, originally developed by Counterpane Labs.
PasswordSafe project is currently administered by Rony Shapiro.  The project homepage is
located at:

L<http://passwordsafe.sourceforge.net>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shufeng Tan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1
