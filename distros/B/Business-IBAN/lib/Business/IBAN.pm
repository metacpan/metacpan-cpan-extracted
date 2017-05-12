package Business::IBAN;

require 5.005_62;
use Math::BigInt;
use strict;
use vars qw($VERSION @errors);

$VERSION = '0.06';

# error codes
use constant IBAN_CTR => 0;
use constant IBAN_BBAN => 1;
use constant IBAN_ISO => 2;
use constant IBAN_FORMAT => 3;
use constant IBAN_FORMAT2 => 4;
use constant IBAN_INVALID => 5;

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
} ## end sub new
# --------------------------------------
sub getIBAN {
    my ($self, $args) = @_;
	my $iso = uc $args->{ISO};
	my $bban = $args->{BBAN};
	my $bic = $args->{BIC};
	my $ac = $args->{AC};
	delete $self->{ERRORS};
	push @{$self->{ERRORS}}, IBAN_CTR unless $iso ;
	push @{$self->{ERRORS}}, IBAN_BBAN unless $bban || ($bic && $ac);
	return if $self->{ERRORS};
	$iso =~ tr/A-Za-z//cd if $iso;
	$bban =~ tr/A-Za-z09//cd if $bban;
	$ac =~ tr/A-Za-z09//cd if $ac;

	return unless $iso;
	$iso = uc $iso;
	$args->{CV} = $iso;
	$args->{CV} =~ s/([A-Z])/(ord $1)-55/eg;
	my $no;
	$args->{ISO} = $iso;
	for ($iso) {
		m/^DE$/ and $no = $self->iban_de($args), last;
		$no = $self->iban_unspec($args);
	}
	return $no;
}
# --------------------------------------
sub iban_de {
	my $self = shift;
	my $args = shift;
	$args->{BBAN} ||= sprintf "%08s%010s", $args->{BIC},$args->{AC};
	my $no = sprintf "%018s%4s00", $args->{BBAN}, $args->{CV};
	my $tmp = $no % 97;
	my $bigint = Math::BigInt->new($no);
	my $mod = sprintf "%2d", 98 - ($bigint % 97);
	substr($no,-6,6) = "";
	$no = 'IBAN '.$args->{ISO}.$mod.$no;
	return $no;
}
# --------------------------------------
sub iban_unspec {
	my $self = shift;
	my $args = shift;
	push @{$self->{ERRORS}}, IBAN_BBAN unless $args->{BBAN};
	return if $self->{ERRORS};
	my $no = sprintf "%s%4s00", $args->{BBAN}, $args->{CV};
	my $bigint = Math::BigInt->new($no);
	my $mod = 98 - ($bigint % 97);
	substr($no,-6,6) = "";
	$no = 'IBAN '.$args->{ISO}.$mod.$no;
	return $no;
}
# --------------------------------------
sub getError {
	return unless $_[0]->{ERRORS};
	return @{$_[0]->{ERRORS}};
}
# --------------------------------------
sub printError {
	return unless $_[0]->{ERRORS};
	print "$errors[$_]\n" for @{$_[0]->{ERRORS}};
}
# --------------------------------------
sub country {
	return $_[0]->{COUNTRY};
}
# --------------------------------------
sub valid {
    my ($self, $ib) = @_;
	delete $self->{ERRORS};
	# remove spaces
	$ib =~ tr/ //d;
	# invalid characters
	#(push @{$self->{ERRORS}}, IBAN_FORMAT2), return if $ib =~ tr/A-Za-z0-9//c;
	$ib =~ s/^IBAN//i;
	push @{$self->{ERRORS}}, IBAN_FORMAT unless $ib =~ m/^[A-Z][A-Z]/i;
	return if $self->{ERRORS};
	my $iso = substr $ib, 0, 2, "";
	$iso =~ s/([A-Z])/(ord $1)-55/eg;
	my $check = substr $ib, 0, 2, "";
	# convert alpha characters to their ascii code
	$ib =~ s/([A-Z])/(ord $1)-55/eg;
	# iban still contains characters which are not numbers!
	(push @{$self->{ERRORS}}, IBAN_FORMAT2), return if $ib =~ tr/0-9//c;
	$ib .= "$iso$check";
	$ib = Math::BigInt->new($ib);
	push @{$self->{ERRORS}}, IBAN_INVALID and return unless ($ib % 97)==1;
	return 1;
}
# --------------------------------------

@errors = (
	"No Country or Iso-Code supplied",
	"No BBAN (Bank-Number) or Bank Identifier and Accountnumber supplied",
	"Could not find country",
	"IBAN must contain two-letter ISO-Code at the beginning",
	"IBAN must only contain only alphanumerics after the ISO-code",
	"IBAN is invalid",
);

1;
__END__

=head1 NAME

Business::IBAN - Validate and generate IBANs

=head1 SYNOPSIS

  use Business::IBAN;
  use Locale::Country;
  my $cc = country2code('Germany');
  my $iban = Business::IBAN->new();

  # ---------- generate
  my $ib = $iban->getIBAN(
  {
    ISO => $cc, # or "DE", etc.
    BIC => 12345678, # Bank Identifier Code, meaning the BLZ
                     # in Germany
    AC => "1234567890",
  });
  # or
  my $ib = $iban->getIBAN(
  {
    ISO => "DE",
    BBAN => 123456781234567890,
  });
  if ($ib) {
    print "IBAN is $ib\n";
  }
  else {
    $iban->printError();
    # or
    my @errors = $iban->getError();
    # print your own error messages (for description of error-
    # codes see section ERROR-CODES
  }

  # ------------ validate
  if ($iban->valid($ib)) {
    # note: this also accepts IBANs in paper format with spaces added
    print "$ib is valid\n";
  }
  else {
    $iban->printError();
  }

=head1 DESCRIPTION

With this module you can validate IBANs (International Bank
Account Number) like "IBAN DE97123456781234567890" (ISO 13616).
(Note: spaces between numbers are allowed.)
Note that this dos not (and cannot) assure that the bank
account exists or that the bank account number for the
bank itself is valid.
You can also create an IBAN if you supply

=over 4

=item

- your BBAN (Basic Bank Account Number),
  (or for germany your BLZ and account
  number are sufficient),

=item

- and either your country code (ISO3166)
  or the english name for your country.

But note that only your bank is supposed to create your official IBAN.

=back

=head2 REQUIRES

To get your country code the module Locale::Country is required, which
you can get from www.cpan.org. It's a standard module since perl-version
5.7.2. If you know your country code, you don't need the module.

=head2 EXPORT

None by default. All methods are accessed over the object.


=head2 ERROR-CODES

You can print your own error-messages. The array you get from
  my @errors = $iban->getError();
are numbers which stand for the following errors:

	0: No Country or Iso-Code supplied
	1: No BBAN (Bank-Number) or Bank Identifier and Accountnumber supplied
	2: Could not find country
	3: IBAN must contain two-letter ISO-Code at the beginning
	4: IBAN must only contain only alphanumerics after the ISO-code
	5: IBAN is invalid

=head2 CAVEATS

Please note that this program is intended to validate IBANs and generate
them for you if you have your BBAN. It's not for generating valid
numbers for illegal purposes. The algorithm is simple and publicly
available for everyone. You can find informations about the IBAN at

=over 4

=item http://www.ecbs.org

=item http://www.iban.ch

=back

=head1 VERSION

Business::IBAN Version 0.06

=head1 AUTHOR

Tina Mueller. tinita(at)cpan.org

=cut
