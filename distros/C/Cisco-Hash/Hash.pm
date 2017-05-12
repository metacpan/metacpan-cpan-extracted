#!/usr/bin/perl

package Cisco::Hash;

use strict;
use warnings;

require Exporter;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.02 $ =~ m/ (\d+) \. (\d+) /xg;

use vars qw[
						@EXPORT_OK
            @XLAT
            $EXLAT
           ];

BEGIN {
	*import    = \&Exporter::import;
	@EXPORT_OK = qw(decrypt encrypt usage);
}

use Carp;

@XLAT = (
	0x64, 0x73, 0x66, 0x64, 0x3b, 0x6b, 0x66, 0x6f,
	0x41, 0x2c, 0x2e, 0x69, 0x79, 0x65, 0x77, 0x72,
	0x6b, 0x6c, 0x64, 0x4a, 0x4b, 0x44, 0x48, 0x53,
	0x55, 0x42, 0x73, 0x67, 0x76, 0x63, 0x61, 0x36,
	0x39, 0x38, 0x33, 0x34, 0x6e, 0x63, 0x78, 0x76,
	0x39, 0x38, 0x37, 0x33, 0x32, 0x35, 0x34, 0x6b,
	0x3b, 0x66, 0x67, 0x38, 0x37
);

$EXLAT = scalar@XLAT;

sub decrypt {
	my $e = shift;
	
	$e = uc $e;
	
	die "ERROR: The encrypted string has an odd length but must have an even. Call usage for help."
		if length $e & 1;
	
	die "ERROR: Invalid character detected. Ensure you only paste the enrcypted password. Call usage for help."
		if $e !~ /^[\dA-F]+$/i;
	
	my $d;
	my ($eh, $et) = ($e =~ /(..)(.+)/o);
	
	for(my $i = 0; $i < length $et ; $i += 2) {
		$d .= sprintf "%c", hex( substr $et, $i, 2 )^$XLAT[ $eh++ % $EXLAT ];
	}
	return $d;
}

sub encrypt {
	my ($d, $of) = @_;
	
	die "ERROR: Insufficient number of Arguments. Call usage for help."
		if @_ != 2;
	
	die "ERROR: The offset you provided is not supported. Call usage for help."
		if $of < 0 || $of > 52;
		
	my $e .= sprintf "%02d", $of;
	
	for(my $i = 0; $i < length $d; $i++) {
		$e .= sprintf "%02x", unpack( 'C', substr $d, $i, 1 )^$XLAT[ $of++ % $EXLAT ];
	}
	return uc $e;
}

sub usage {
	die <<EOF

decrypt(<encrypted_hash>)
	
	Paste the encrypted hash without any preceeding information
	
	Exmaple:
	use Cisco::Hash qw(decrypt);
	decrypt('1511021F0725'); # Will return 'cisco'

encrypt(<passphrase>, <offset>)
	
	You can define any passphrase you like to encrpyt into a encrypted hash.
	Altough it seems that Cisco devices strip of all characters above the 
	224th position.
	
	The offset describes at which position of the translate mask encryption
	should be startet. Due to the length of the mask (which is 53) allowed
	values are 0 to 52 (decimal).
	
	Example:
	use Cisco::Hash qw(encrypt);
	encrypt('cisco', 15); # will return '1511021F0725'

THIS SOFTWARE IS NEITHER INTENDED FOR MALICIOUS USE NOR FOR THE USE
IN ANY OTHER ILLEGAL PURPOSES.
	
EOF
}

1;

__END__

=head1 NAME

Cisco::Hash - De- and encrypts Cisco type 7 hashes

=head1 SYNOPSIS

use Cisco::Hash qw(decrypt encrypt usage);

print encrypt('cisco', 15);          # will produce 1511021F0725

print decrypt('1511021F0725');       # will produce cisco
print decrypt(encrypt('cisco', 15)); # as will this too

usage; # prints information about the module

=head1 DESCRIPTION

This Module decrypts all kind of Cisco encrypted hashes also referred
to as type 7 passwords. Further you can encrypt any given string into
a encrypted hash that will be accepted by any Cisco device as an
encrypted type 7 password.

=head1 METHODS

=over 4

=item decrypt(encrypted_hash)

Paste the encrypted hash without any preceding information.
	
Exmaple:
C<decrypt('1511021F0725'); # Will return 'cisco'>

=item encrypt(passphrase, offset)

You can define any passphrase you like to encrpyt into a encrypted hash.
Altough it seems that Cisco devices strip of all characters above the 
224th position.

The offset describes at which position of the translate mask encryption
should be startet. Due to the length of the mask (which is 53) allowed
values are 0 to 52 (decimal).

Example:
C<encrypt('cisco', 15); # will return '1511021F0725'>

=item usage

Usage will give hints on how to use the methods provided by this
module.

=back

=head1 AUTHOR

LORD INFERNALE C<infernale@cpan.org>

=head1 COPYRIGHT AND LICENSE

THIS SOFTWARE IS NEITHER INTENDED FOR MALICIOUS USE NOR FOR THE USE
IN ANY OTHER ILLEGAL PURPOSES.

Credits for orginal code and description hobbit@avian.org, 
SPHiXe, .mudge et al. and for John Bashinski <jbash@CISCO.COM> for
Cisco IOS password encryption facts.

Copyright (c) 2008 LORD INFERNALE.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
