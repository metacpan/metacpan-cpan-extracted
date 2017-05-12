package DNS::Bananafonana;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $bananafonana_strings);

use Carp;
use Exporter;
use Math::BigInt qw(:constant);

$VERSION = '0.1';

@ISA = qw(Math::BigInt);
@EXPORT = qw();
@EXPORT_OK = qw(from_bananafonana to_bananafonana bananafonana);

=head1 NAME

DNS::Bananafonana - Perl extension for Bananafonana encoding / decoding

=head1 SYNOPSIS

  use DNS::Bananafonana;

  $bigint = from_bananafonana($number);
  $bafostr = to_bananafonana($bigint);
  $hostname = bananafonana($ptr, $domain, $prefix);
  $ip = bananafonana($hostname, $domain, $prefix);

=head1 DESCRIPTION

RFC 1924 describes a compact, fixed-size representation of IPv6
addresses which uses a base 85 number system. The base 85 numbers
(from 0 to 84) are as follows:

    0..9 A..Z a..z ! # $ % & ( ) * + - ; < = > ? @ ^ _ ` { | } ~

In order to let human beings pronounce the resulting string more easily and
to be able to use base 85 encoding in DNS naming schemes, an alternative
encoding scheme is used, based on 85 consonant-vowel pairs, as suggested by
DGolden on Slashdot
(http://tech.slashdot.org/comments.pl?sid=649579&cid=24654733).

This module has a variable called C<$DNS::Bananafonana::bananafonana_strings>,
which is a string containing the 85 two-character strings that make up
the bananafonana "alphabet" from lowest to highest , in that order.

Additionally, the following three functions are defined for general
use.  (They will be exported upon request.)

=cut

$DNS::Bananafonana::bananafonana_strings = 
    "babebibobudadedidodufafefifofugagegigogu" .
    "hahehihohujajejijojukakekikokulalelilolu" .
    "mamemimomunaneninonupapepipopusasesisosu" .
    "tatetitotuvavevivovuxaxexixoxuwawewiwowu" .
    "zazezizozu";


# Maybe we can make this a little more general...

use constant BAFO_BASE => 85;
use constant BAFO_BLOCKSIZE => 5;
use constant BAFO_MARKUP => '-';

=pod

=head1 from_bananafonana

=head2 Parameters

A string composed of valid bananafonana strings.

=head2 Returns

A C<DNS::BigInt> object representing the number.

=cut

sub from_bananafonana
{
    my $num = shift;
    # Remove markup characters
    $num =~ s/[-_\.]//g;
    my $answer = new Math::BigInt "0";
    my $n;
    my $d;
    while (length($d = substr($num,0,2)) > 0) {
    if (length($d) == 1) {
	    croak __PACKAGE__ . "::from_bananafonana -- invalid bananafonana string $d";
    }
    $num = substr($num,2);
	$answer = $answer * BAFO_BASE;
	$n = index($bananafonana_strings, $d)/2.0;
	if ($n < 0.0) {
	    croak __PACKAGE__ . "::from_bananafonana -- invalid bananafonana string $d";
	}
	$answer = $answer + $n;
    }
    return $answer;
}

=pod

=head1 to_bananafonana

=head2 Parameters

A C<DNS::BigInt> object.

Optionally:

A markup character to split the string in more readable parts.
Can be C<->, C<_> or C<.>. Defaults to C<->.

A blocksize that determines the number of consonant-vowel combinations
between each markup character. Defaults to 5.

=head2 Returns

A string of bananafonana strings representing the number.

=cut

sub to_bananafonana
{
    my $num = shift;
    my $markup = shift || BAFO_MARKUP;
    my $blocksize = (shift || BAFO_BLOCKSIZE) + 1;
    my @digits;
    my $q;
    my $r;
    my $d;

    if (! $markup =~ /[-_\.]/) {
	    croak __PACKAGE__ . "::to_bananafonana -- invalid markup character ($markup)";
    }
    if ($blocksize < 0) {
	    croak __PACKAGE__ . "::to_bananafonana -- invalid blocksize ($blocksize)";
    }
	if ($num eq "NaN" ) {
	    croak __PACKAGE__ . "::to_bananafonana -- invalid number ($num)";
	}
    while ($num > 0) {
	$q = $num / BAFO_BASE;
	$r = $num % BAFO_BASE;
	$d = substr($bananafonana_strings, $r*2, 2);
    if ($blocksize > 0 && (($#digits + 1) % $blocksize ==  0)) {
        unshift @digits, $markup;
    }
	unshift @digits, $d;
	$num = $q;
    }
    pop @digits;
    unshift @digits, 'ba' unless (@digits);
    return join('', @digits);
}

=pod

=head1 bananafonana

=head2 Parameters

A string 

A string containing the domain name of the record. It will be appended to the
result when a pointer record is asked and removed from the input for hostname
lookups.

Optionally:

A string containing a prefix that needs to be added before the bananafonana
representation of the ip address. Defaults to empty.

A markup character to split the string in more readable parts.
Can be C<->, C<_> or C<.>. Defaults to C<->.

A blocksize that determines the number of consonant-vowel combinations
between each markup character. Defaults to 5.

=head2 Returns

A string containing either the bananafonana representation of the ip address
(presented in 1.2.3.4.in-addr.arpa or a.b...e.f.ip6.arpa notation)
or a string representing the ip address determined from the bonananfonana
encoded hostname (for all domains not ending in in-addr|ip6.arpa).

=cut

sub bananafonana
{
    my $name = shift;
    my $domain = shift || "";
    my $prefix = shift || "";
    my $markup = shift || BAFO_MARKUP;
    my $blocksize = (shift || BAFO_BLOCKSIZE) + 1;
    my $ip;

# Input validation
    if (! $markup =~ /[-_\.]/) {
	    croak __PACKAGE__ .
            "::bananafonana -- invalid markup character($markup)";
    }
    if ($blocksize < 0) {
	    croak __PACKAGE__ .
            "::bananafonana -- invalid blocksize ($blocksize)";
    }
	if ($domain eq "" ) {
	    croak __PACKAGE__ . "::bananafonana -- empty domain is not allowed";
	}
# Strip leading and trailing dots from domain
    $domain =~ s/^\.|\.$//g;

# IPv4 PTR record
    if ($name =~ /^(.*)\.in-addr\.arpa[.]{0,1}$/) {
        $ip = eval { $prefix.to_bananafonana(
                new Math::BigInt("0x".sprintf("%02x%02x%02x%02x",
                    reverse split(/\./, $1)))
            ).".".$domain; };
        if (not defined($ip)) {
            croak __PACKAGE__ . "::bananafonana -- cannot encode $1";
        }
        return($ip);

# IPv6 PTR record
    } elsif ($name =~ /^(.*)\.ip6\.arpa[.]{0,1}$/) {
        $ip = eval { $prefix.to_bananafonana(
                new Math::BigInt("0x".join('', reverse split(/\./, $1)))
            ).".".$domain; };
        if (not defined($ip)) {
            croak __PACKAGE__ . "::bananafonana -- cannot encode $1";
        }
        return($ip);

    } elsif ($name =~ /^$prefix(.*)\.$domain[.]{0,1}$/) {

# A or AAAA record
        $name = $1;
        $name =~ s/[-_\.]//g;
        if (length($name) == 10) {

# A record (Note: this also incorrectly matches ::abcd IPv6 addresses!)
            $ip = eval { sprintf("%08x",from_bananafonana($name)); };
            if (not defined($ip)) {
                croak __PACKAGE__ . "::bananafonana -- cannot decode $name";
            }
            return(sprintf("%d.%d.%d.%d",
                hex(substr($ip,0,2)), hex(substr($ip,2,2)),
                hex(substr($ip,4,2)), hex(substr($ip,6,2))));
        } else {

# AAAA record
            $ip = eval { from_bananafonana($name)->as_hex(); };
            if (not defined($ip)) {
                croak __PACKAGE__ . "::bananafonana -- cannot decode $name";
            }
            if (length($ip) < 34) {
                $ip = "0x".substr('00000000000000000000000000000000',0,
                    34-length($ip)).substr($ip,2);
            }
            $name = sprintf("%x:%x:%x:%x:%x:%x:%x:%x",
                hex(substr($ip,2,4)), hex(substr($ip,6,4)),
                hex(substr($ip,10,4)), hex(substr($ip,14,4)),
                hex(substr($ip,18,4)), hex(substr($ip,22,4)),
                hex(substr($ip,26,4)), hex(substr($ip,30,4)));
            $name =~ s/^(0:)+|(:0)+$|(:0)+:/::/;
            return($name);
        }

    } else {

#Invalid question
        croak __PACKAGE__ . "::bananafonana -- invalid input ($name)";

    }
}

=head1 BUGS

The bananafonana function is currently decoding all hostnames with 10
character bonanafonana encoded addresses as IPv4 addresses. This prevends the
correct encoding and decoding for IPv6 addresses in the range ::/96, which
should not be a big limitation in practice.

=head1 AUTHOR

Michiel Fokke <michiel@fokke.org>
Based upon work from Tony Monroe <tmonroe+perl@nog.net>

=head1 SEE ALSO

perl(1).

=cut

1;
__END__
