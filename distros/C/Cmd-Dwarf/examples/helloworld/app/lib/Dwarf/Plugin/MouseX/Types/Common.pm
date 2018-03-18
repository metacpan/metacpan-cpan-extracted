package Dwarf::Plugin::MouseX::Types::Common;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method encode_utf8 decode_utf8/;
use Email::Valid;
use Email::Valid::Loose;
use JSON;
use Mouse;
use Mouse::Util::TypeConstraints;
use Regexp::Common qw/URI/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	subtype URL
		=> as 'Str'
		=> where { $_ =~ /($RE{URI}{HTTP}{-scheme =>'(https|http)'})/o };

	subtype Email
		=> as 'Str'
		=> where { Email::Valid::Loose->address(encode_utf8 $_) };

	subtype ASCII
		=> as 'Str'
		=> where { $_ =~ /^[\x21-\x7E]+$/ };

	subtype Hiragana
		=> as 'Str'
		=> where { _delsp($_) =~ /^\p{InHiragana}+$/ };

	subtype Katakana
		=> as 'Str'
		=> where { _delsp($_) =~ /^\p{InKatakana}+$/ };

	subtype Date
		=> as 'Str'
		=> where { _date(split /-/, $_) };

	subtype Time
		=> as 'Str'
		=> where { _time(split /:/, $_); };

	subtype DateTime
		=> as 'Str'
		=> where { _datetime($_) };

	subtype JTel
		=> as 'Str'
		=> where { $_ =~ /^0\d+\-?\d+\-?\d+$/ };

	subtype JZip
		=> as 'Str'
		=> where { $_ =~ /^\d{3}\-\d{4}$/ };

	subtype CreditcardNumber
		=> as 'Str'
		=> where { $_ =~ /\A[0-9]{14,16}\z/ };

	subtype CreditcardExpire
		=> as 'Str'
		=> where { $_ =~ /^\d{2}\/\d{2}$/ };

	subtype CreditcardSecurity
		=> as 'Str'
		=> where { $_ =~ /\A[0-9]{3,4}\z/ };

	subtype JSON
		=> as 'Str'
		=> where { _json($_) };

	subtype Base64JPEG
		=> as 'Str'
		=> where { _base64_type($_, 'jpeg') };

	subtype Base64PNG
		=> as 'Str'
		=> where { _base64_type($_, 'png') };

	subtype Base64GIF
		=> as 'Str'
		=> where { _base64_type($_, 'gif') };
}

sub _datetime {
	my $str = shift;
	return 0 unless $str =~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/;
	my @a = split / /, $str;
	return _date(split /-/, $a[0]) && _time(split /:/, $a[1]);
}

sub _date {
	my ($y, $m, $d) = @_;

	return 0 if ( !$y or !$m or !$d );

	if ($d > 31 or $d < 1 or $m > 12 or $m < 1 or $y == 0) {
		return 0;
	}
	if ($d > 30 and ($m == 4 or $m == 6 or $m == 9 or $m == 11)) {
		return 0;
	}
	if ($d > 29 and $m == 2) {
		return 0;
	}
	if ($m == 2 and $d > 28 and !($y % 4 == 0 and ($y % 100 != 0 or $y % 400 == 0))){
		return 0;
	}
	return 1;
}

sub _time {
	my ($h, $m, $s) = @_;

	return 0 if (!defined($h) or !defined($m));
	return 0 if ("$h" eq "" or "$m" eq "");
	$s ||= 0; # optional

	if ( $h > 23 or $h < 0 or $m > 59 or $m < 0 or $s > 59 or $s < 0 ) {
		return 0;
	}

	return 1;
}

sub _json {
	my $value = $_;
	return 1 unless defined $value;
	my $data = eval { decode_json encode_utf8 $value };
	if ($@) {
		warn $@;
		warn $value;
		return 0;
	}
	return 1;
}

sub _base64_type {
	my ($value, $expected) = @_;

	my $filetype = '';

	my $decoded = decode_base64($value);
	my $type = image_type(\$decoded);

	if (my $error = $type->{error}) {
		return 0;
	}

	$filetype = lc $type->{file_type};
	return $filetype =~ /^$expected$/i;
};

sub _delsp {
	my $x = $_;
	$x =~ s/\s//g;
	return $x;
}

1;
