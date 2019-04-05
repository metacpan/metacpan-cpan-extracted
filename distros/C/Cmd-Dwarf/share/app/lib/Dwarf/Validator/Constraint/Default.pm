package Dwarf::Validator::Constraint::Default;
use Dwarf::Validator::Constraint;
use Dwarf::Validator::NullValue;
use Email::Valid;
use Email::Valid::Loose;
use Dwarf::Util qw/encode_utf8 decode_utf8/;
use Image::Info qw/image_type/;
use JSON;
use MIME::Base64 qw(decode_base64 decoded_base64_length);
use Scalar::Util qw/looks_like_number/;
use UNIVERSAL::require;


rule NOT_NULL => sub {
	return 0 if not defined($_);
	return 0 if ref $_ eq 'ARRAY' && @$_ == 0;
	return 1;
};
alias NOT_NULL => 'REQUIRED';

rule NOT_BLANK => sub {
	return 0 if not defined($_);
	return 0 if ref $_ eq 'ARRAY' && @$_ == 0;
	$_ ne "";
};

rule INT  => sub {
	return 0 unless $_ =~ /\A[+\-]?[0-9]+\z/;
	return 0 unless $_ < 2_147_483_647;
	return 0 unless $_ > -2_147_483_648;
	return 1;
};

rule UINT => sub {
	return 0 unless $_ =~ /\A[0-9]+\z/;
	return 0 unless $_ < 2_147_483_647;
	return 1;
};

rule BIGINT => sub {
	return 0 unless $_ =~ /\A[+\-]?[0-9]+\z/;
	return 1 if $_ =~ /\A[+\-]?[0-9]{1,18}\z/;
	return 0 if $_ =~ /\A[+]?[0-9]{20,}\z/;
	return 0 if $_ =~ /\A[\-]?[0-9]{20,}\z/;
	Math::BigInt->use or die;
	my $MIN = Math::BigInt->new("-9223372036854775808");
	my $MAX = Math::BigInt->new("9223372036854775807");
	my $val = Math::BigInt->new($_);
	return 0 if $MIN->bcmp($val) > 0;
	return 0 if $val->bcmp($MAX) > 0;
	return 1;
};

rule BIGUINT => sub {
	return 0 unless $_ =~ /\A[0-9]+\z/;
	return 1 if $_ =~ /\A[0-9]{1,18}\z/;
	return 0 if $_ =~ /\A[0-9]{20,}\z/;
	Math::BigInt->use or die;
	my $MAX = Math::BigInt->new("9223372036854775807");
	my $val = Math::BigInt->new($_);
	return 0 if $val->bcmp($MAX) > 0;
	return 1;
};

rule NUMBER => sub {
	my $value = $_;
	return 1 unless defined $value;
	return looks_like_number $value;
};

rule EQUAL => sub {
	Carp::croak("missing \$argument") if @_ == 0;
	$_ eq $_[0]
};

rule BETWEEN => sub {
	$_[0] <= $_ && $_ <= $_[1];
};

rule LESS_THAN => sub {
	$_ < $_[0];
};

rule LESS_EQUAL => sub {
	$_ <= $_[0];
};

rule MORE_THAN => sub {
	$_[0] < $_;
};

rule MORE_EQUAL => sub {
	$_[0] <= $_;
};

rule ASCII => sub {
	$_ =~ /^[\x21-\x7E]+$/
};

# 'name' => [qw/LENGTH 5 20/],
rule LENGTH => sub {
	my $length = length($_);
	my $min    = shift;
	my $max    = shift || $min;
	Carp::croak("missing \$min") unless defined($min);

	( $min <= $length and $length <= $max )
};

rule DATE => sub {
	if (ref $_) {
		# query: y=2009&m=09&d=02
		# rule:  {date => [qw/y m d/]} => ['DATE']
		return 0 unless scalar(@{$_}) == 3;
		_date(@{$_});
	} else {
		# query: date=2009-09-02
		# rule:  date => ['DATE']
		_date(split /-/, $_);
	}
};

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

rule TIME => sub {
	if (ref $_) {
		# query: h=12&m=00&d=60
		# rule:  {time => [qw/h m s/]} => ['TIME']
		_time(@{$_});
	} else {
		# query: time=12:00:30
		# rule:  time => ['time']
		_time(split /:/, $_);
	}
};

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

# this regexp is taken from http://www.din.or.jp/~ohzaki/perl.htm#httpURL
# thanks to ohzaki++
rule HTTP_URL => sub {
	$_ =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/
};

rule EMAIL       => sub { Email::Valid->address(encode_utf8 $_) };
rule EMAIL_LOOSE => sub { Email::Valid::Loose->address(encode_utf8 $_) };

rule HIRAGANA => sub { delsp($_) =~ /^\p{InHiragana}+$/  };
rule KATAKANA => sub { delsp($_) =~ /^\p{InKatakana}+$/  };
rule JTEL     => sub { $_ =~ /^0\d+\-?\d+\-?\d+$/        };
rule JZIP     => sub { $_ =~ /^\d{3}\-\d{4}$/            };

# {mails => [qw/mail1 mail2/]} => ['DUPLICATION']
rule DUPLICATION => sub {
	defined($_->[0]) && defined($_->[1]) && $_->[0] eq $_->[1]
};
alias DUPLICATION => 'DUP';

rule REGEX => sub {
	my $regex = shift;
	Carp::croak("missing args at REGEX rule") unless defined $regex;
	$_ =~ /$regex/
};
alias REGEX => 'REGEXP';

rule CHOICE => sub {
	Carp::croak("missing \$choices") if @_ == 0;

	my @choices = @_==1 && ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

	for my $c (@choices) {
		if ($c eq $_) {
			return 1;
		}
	}
	return 0;
};
alias CHOICE => 'IN';

rule NOT_IN => sub {
	my @choices = @_==1 && ref$_[0]eq'ARRAY' ? @{$_[0]} : @_;

	for my $c (@choices) {
		if ($c eq $_) {
			return 0;
		}
	}
	return 1;
};

rule MATCH => sub {
	my $callback = shift;
	Carp::croak("missing \$callback") if ref $callback ne 'CODE';

	$callback->($_);
};

rule JSON => sub {
	my $value = $_;
	return 1 unless defined $value;
	my $data = eval { decode_json encode_utf8 $value };
	if ($@) {
		warn $@;
		warn $value;
		return 0;
	}
	return 1;
};

rule CREDITCARD_NUMBER   => sub { $_ =~ /\A[0-9]{14,16}\z/ };
rule CREDITCARD_EXPIRE   => sub { $_ =~ /^\d{2}\/\d{2}$/ };
rule CREDITCARD_SECURITY => sub { $_ =~ /\A[0-9]{3,4}\z/ };

rule BASE64_TYPE => sub {
	Carp::croak('missing args. usage: ["BASE64_TYPE", "(jpeg|png|gif)"]') unless @_;
	my $expected = $_[0];
	my $filetype = '';

	my $decoded = decode_base64($_);
	my $type = image_type(\$decoded);

	if (my $error = $type->{error}) {
		return 0;
	}
	$filetype = lc $type->{file_type};
	return $filetype =~ /^$expected$/i;
};

rule BASE64_SIZE => sub {
	Carp::croak('missing args. usage: ["BASE64_SIZE", "10000"]') unless @_;
	my $expected = $_[0];
	my $length = decoded_base64_length($_);
	return $length < $expected;
};


file_rule FILE_NOT_NULL => sub {
	return 0 if not defined($_);
	return 0 if $_ eq "";
	return 0 if ref($_) eq 'ARRAY' && @$_ == 0;
	return 1;
};

file_rule FILE_MIME => sub {
	Carp::croak('missing args. usage: ["FILE_MIME", "text/plain"]') unless @_;
	my $expected = $_[0];
	return $_->type =~ /^$expected$/;
};

file_rule FILE_EXT => sub {
	Carp::croak('missing args. usage: ["FILE_MIME", "text/plain"]') unless @_;
	my $expected = $_[0];
	my $ext = '';
	if ($_->filename =~ /\.([^\.]+)$/) {
		$ext = lc $1;
	}
	return $ext =~ /^$expected$/;
};

# 予約
rule ARRAY => sub { 1 };

rule FILTER => sub {
	my ($filter, @args) = @_;
	Carp::croak("missing \$filter") unless $filter;

	my $opts = {
		override_param => 1,
	};
	
	if (not ref $filter) {
		$filter = $Dwarf::Validator::Filters->{uc $filter}
			or Carp::croak("$filter is not defined.");
	}
	
	Carp::croak("\$filter must be coderef.") if ref $filter ne 'CODE';

	$_ = $filter->($_, \@args, $opts);

	# パラメータを上書きしない場合は null を返す
	unless ($opts->{override_param}) {
		return Dwarf::Validator::NullValue->new;
	}

	$_;
};

filter TRIM => sub {
	my ($value, $args, $opts) = @_;
	return $value unless $value;
	$value =~ s/^\s+|\s+$//g;
	$value;
};

# remove control character other than LF or CR
filter RCC => sub {
	my ($value, $args, $opts) = @_;
	return $value unless $value;
	$value =~ s/[\x00-\x09\x0b\x0c\x0e-\x1f]//g;
	$value;
};

filter DEFAULT => sub {
	my ($value, $args, $opts) = @_;
	unless (defined $value) {
		$value = $args->[0];
	}
	$value;
};

filter BLANK_TO_NULL => sub {
	my ($value, $args, $opts) = @_;
	return undef unless defined $value;
	return undef if $value eq '';
	return $value;
};

filter DECODE_UTF8 => sub {
	my ($value, $args, $opts) = @_;
	return $value unless $value;
	$value = decode_utf8($value);
	$value;
};

filter ENCODE_UTF8 => sub {
	my ($value, $args, $opts) = @_;
	return $value unless $value;
	$value = encode_utf8($value);
	$value;
};

# normalize_line_endings
filter NLE => sub {
	my ($value, $opts, @args) = @_;
	return $value unless $value;
	$value =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$value;
};

1;
