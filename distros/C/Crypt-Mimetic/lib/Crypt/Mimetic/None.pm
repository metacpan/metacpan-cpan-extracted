=pod

=head1 NAME

Crypt::Mimetic::None - No Encryption

	
=head1 DESCRIPTION

This module is a part of I<Crypt::Mimetic>.

This modules does not encrypt anything: it only do a bitwise negation. I<DecryptFile> needs @info containing generic-blocks-length and last-block-length (padlen). I<EncryptString> and I<DecryptString> return the bitwise negated string.

=cut

package Crypt::Mimetic::None;
use strict;
use Error::Mimetic;
use vars qw($VERSION);
$VERSION = '0.01';

=pod

=head1 PROCEDURAL INTERFACE

=item string I<ShortDescr> ()

Return a short description of algorithm

=cut

sub ShortDescr {
	return "None - Special algorithm to not encrypt; very fast.";
}

=pod

=item boolean I<PasswdNeeded> ()

Return true if password is needed by this algorithm, false otherwise.
('None' return always false)

=cut

sub PasswdNeeded {
	return 0;
}

=pod

=item ($len,$blocklen,$padlen,[string]) I<EncryptFile> ($filename,$output,$algorithm,$key,@info)

Do a bitwise negation of $filename. See I<Crypt::Mimetic::EncryptFile>.

=cut

sub EncryptFile {
	my ($filename,$output,$algorithm,$key,@info) = @_;
	my ($buf, $text, $txt) = ("","","");
	my ($len,$blocklen,$padlen) = (0,0,0);
	if ($output) {
		open(OUT,">>$output") or throw Error::Mimetic "Cannot open $output: $!";
	}
	open(IN,"$filename") or throw Error::Mimetic "Cannot open $filename: $!";
	while ( read(IN,$buf,32768) ) {
		$blocklen = $padlen;
		$text = ~$buf;
		$padlen = length($text);
		$len += $padlen;
		if ($output) {
			print OUT $text;
		} else {
			$txt .= $text;
		}
	}
	close(IN);
	if ($output) {
		close(OUT);
		return ($len,$blocklen,$padlen);
	}
	return ($len,$blocklen,$padlen,$txt);
}

=pod

=item string I<EncryptString> ($string,$algorithm,$key,@info)

Do a bitwise negation of $string. See I<Crypt::Mimetic::EncryptString>.

=cut

sub EncryptString {
	my ($string,$algorithm,$key,@info) = @_;
	return ~$string;
}

=pod

=item [string] I<DecryptFile> ($filename,$output,$offset,$len,$algorithm,$key,@info)

Do a bitwise negation of $filename. See I<Crypt::Mimetic::DecryptFile>.

=cut

sub DecryptFile {
	my ($filename,$output,$offset,$len,$algorithm,$key,@info) = @_;
	my ($blocklen,$padlen) = @info;
	my ($buf, $text, $i, $txt) = ("","",0,"");
	$blocklen = 32768 unless $blocklen;
	my $blocks = 0;
	$blocks = int($len/$blocklen) if $blocklen;
	if ($output) {
		open(OUT,">$output") or throw Error::Mimetic "Cannot open $output: $!";
	}
	open(IN,"$filename") or throw Error::Mimetic "Cannot open $filename: $!";
	seek IN, $offset, 0;
	for ($i = 0; $i < $blocks; $i++ ) {
		read(IN,$buf,$blocklen);
		$text = ~$buf;
		if ($output) {
			print OUT $text;
		} else {
			$txt .= $text;
		}
	}
	read(IN,$buf,$padlen);
	$text = ~$buf;
	if ($output) {
		print OUT $text;
	} else {
		$txt .= $text;
	}
	close(IN);
	if ($output) {
		close(OUT);
	} else {
		return $txt;
	}
}

=pod

=item string I<DecryptString> ($string,$algorithm,$key,@info)

Do a bitwise negation of $string. See I<Crypt::Mimetic::DecryptString>.

=cut

sub DecryptString {
	my ($string,$algorithm,$key,@info) = @_;
	return ~$string;
}

1;
__END__

=pod

=head1 NEEDED MODULES

This module needs:
   Crypt::Mimetic
   Error::Mimetic


=head1 SEE ALSO

Crypt::Mimetic


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself (Artistic/GPL2).


=head1 AUTHOR

Erich Roncarolo <erich-roncarolo@users.sourceforge.net>

=cut
