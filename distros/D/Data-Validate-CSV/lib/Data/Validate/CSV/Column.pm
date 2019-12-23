use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::Column;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use Data::Validate::CSV::Types -types;
use Types::Common::String qw( NonEmptyStr );
use Types::TypeTiny qw( TypeTiny );
use namespace::autoclean;

has name  => (
	is        => 'rwp',
	isa       => Str,
	predicate => 1,
);

sub maybe_set_name {
	my $self = shift;
	$self->_set_name(@_) unless $self->has_name;
	$self;
}

has titles => (
	is        => 'ro',
	isa       => Str | ArrayRef[Str] | HashRef[Str|ArrayRef[Str]],
	coerce    => 1,
);

has datatype => (
	is        => 'lazy',
	isa       => HashRef->plus_coercions( Str, '{base=>$_}' ),
	coerce    => 1,
	builder   => sub { { base => 'string' } },
);

has default  => (
	is        => 'ro',
	isa       => Any,
	predicate => 1,
);

has null  => (
	is        => 'ro',
	isa       => ArrayRef->of(Str)->plus_coercions(Str, '[$_]'),
	coerce    => 1,
	predicate => 1,
);

has separator  => (
	is        => 'ro',
	isa       => NonEmptyStr,
	predicate => 1,
);

has ordered => (
	is        => 'ro',
	isa       => Bool,
	default   => 1,
);

has required => (
	is        => 'ro',
	isa       => Bool,
	default   => 0,
	coerce    => 1,
);

has type_constraint => (
	is        => 'lazy',
	isa       => TypeTiny,
	handles   => ['assert_valid', 'assert_coerce', 'coerce', 'check', 'get_message', 'has_coercion'],
);

has base_type_constraint => (
	is        => 'lazy',
	isa       => TypeTiny,
);

my %mapping = map { $_ => $_ } qw(
	length maxLength minLength
	minExclusive maxExclusive
	minInclusive maxInclusive
	fractionDigits totalDigits
	explicitTimezone
);
# these silly aliases are why we need a mapping
$mapping{maximum} = 'maxInclusive';
$mapping{minimum} = 'minInclusive';

my %is_numeric = map { $_ => 1 } qw(
	float double decimal integer nonpositiveinteger
	negativeinteger long int short byte nonnegativeinteger
	positiveinteger unsignedlong unsignedint unsignedbyte
);

my %is_dt = map { $_ => 1 } qw(
	datetime datetimestamp time date gyearmonth gyear
	gmonthday gday gmonth
);

sub canonicalize_value {
	shift->_canon(0, @_);
}

sub inflate_value {
	shift->_canon(1, @_);
}

sub _canon {
	my $self = shift;
	my ($obj, $errs, @values) = @_;
	my $base = lc $self->datatype->{base};
	
	require JSON::PP;
	require Types::XSD;
	
	if ($self->has_separator) {
		@values = map {
			($_ eq '' || !defined) ? () : split quotemeta($self->separator)
		} @values;
	}

	unless ($base =~ /^(string|json|xml|html|anyatomictype)^/) {
		s/[\t\r\n]/ /g for @values;
	}
	
	unless ($base =~ /^(string|json|xml|html|anyatomictype|normalizedstring)^/) {
		s/\s+/ /g for @values;
		s/^\s+//g for @values;
		s/\s+$//g for @values;
	}

	my %is_null = map { $_ => 1 } $self->has_null ? @{$self->null} : ();
	
	my @coerced = map {
		my $v = $_;
		if ($self->has_default and $v eq '' || !defined $v) {
			$v = $self->default;
		}
		my $c = $self->has_coercion ? $self->coerce($v) : $v;
		if ($is_null{$c}) {
			undef;
		}
		elsif ($self->check($c)) {
			if ($obj and $base eq 'boolean') {
				($c eq 'true'  || $c eq '1') ? JSON::PP::true() :
				($c eq 'false' || $c eq '0') ? JSON::PP::false() :
				do { push @$errs, sprintf('Value %s is not a valid boolean', B::perlstring($c)); $c };
			}
			elsif ($obj and $base =~ /duration/) {
				Types::XSD::dur_parse($c);
			}
			elsif ($obj and $base =~ /datetime/) {
				Types::XSD::dt_parse($c)->to_datetime;
			}
			elsif ($obj and $is_dt{$base}) {
				Types::XSD::dt_parse($self->base_type_constraint, $c);
			}
			elsif ($is_numeric{$base}) {
				0+$c;
			}
			else {
				$c;
			}
		}
		else {
			if ($self->base_type_constraint->check($c)) {
				push @$errs, sprintf('Value %s is a valid %s, but fails additional constraints', B::perlstring($c), $base);
			}
			else {
				push @$errs, sprintf('Value %s is a not valid %s', B::perlstring($c), $base);
			}
			$c;
		}
	} @values;
	
	$self->has_separator || @_ > 3 ? \@coerced : $coerced[0];
}

sub _build_base_type_constraint {
	my $self = shift;
	my $base = lc( $self->datatype->{base} || 'string' );
	my ($xsd_type) =
		map  Types::XSD->get_type($_),
		grep $base eq lc($_),
		Types::XSD->type_names;
	$xsd_type;
}

sub _build_type_constraint {
	my $self = shift;
	require Types::XSD;
	my %dt   = %{ $self->datatype };
	my $base = lc delete $dt{base};
	my $xsd_type = $self->base_type_constraint;
	die "huh? $base" unless $xsd_type;
	
	my %facets;
	for my $key (sort keys %mapping) {
		next unless exists $dt{$key};
		$facets{$mapping{$key}} = delete $dt{$key};
	}
	
	my ($coerce_boolean, $coerce_numeric, $coerce_dt);
	if (exists $dt{format}) {
		if ($base eq 'boolean') {
			$coerce_boolean = delete $dt{format};
		}
		elsif ($is_numeric{$base}) {
			$coerce_numeric = delete $dt{format};
		}
		elsif ($is_dt{$base}) {
			$coerce_dt = delete $dt{format};
		}
		else {
			my $fmt = delete $dt{format};
			$facets{pattern} = qr/^$fmt$/;
		}
	}
	
	my $parameterized = $xsd_type->of(%facets);
	if ($dt{'dc:title'}) {
		$parameterized = $parameterized->create_child_type(
			name => delete $dt{'dc:title'},
		);
	}
	
	delete $dt{$_} for grep /:/, keys %dt;
	die "unrecognized keys: ".join(', ', sort keys %dt)
		if keys %dt;
	
	if (defined $coerce_boolean) {
		my ($t,$f) = split /\|/, $coerce_boolean;
		$parameterized = $parameterized->plus_coercions(
			Enum[$t,$f], sprintf('0+!!($_ eq %s)', B::perlstring($t)),
		);
	}

	if (defined $coerce_numeric) {
		my %fmt = ref($coerce_numeric) ? %$coerce_numeric : (pattern => $coerce_numeric);
		$parameterized = $parameterized->plus_coercions(
			~Ref, sprintf(
				'%s->_coerce_numeric($_, %s, %s, %s)',
				map defined($_) ? B::perlstring($_) : 'undef',
					ref($self),
					@fmt{qw(pattern decimalChar groupChar)},
			),
		);
	}

	if (defined $coerce_dt) {
		$parameterized = $parameterized->plus_coercions(
			~Ref, sprintf(
				'%s->_coerce_dt($_, %s, %s)',
				map defined($_) ? B::perlstring($_) : 'undef',
					ref($self),
					$coerce_dt,
					lc($base),
			),
		);
	}
	
	return $parameterized;
}

sub _coerce_numeric {
	shift;
	my ($value, $pattern, $decimal_char, $group_char) = @_;
	$decimal_char //= '.';
	$group_char   //= ',';
	$pattern =~ s/;+$//;
	
	return  'NaN' if lc($value) eq  'nan';
	return  'INF' if lc($value) eq  'inf';
	return '-INF' if lc($value) eq '-inf';
	
	my $regexp;
	if (defined $pattern) {
		my %numeric_pattern_char = (
			'0'   => '[0-9]+',
			'#'   => '[0-9]+',
			'-'   => quotemeta('-'),
			'E'   => '[Ee]',
			'e'   => '[Ee]',
			'%'   => quotemeta('%'),
			'‰'   => quotemeta('‰'),
			$decimal_char  => quotemeta($decimal_char),
			$group_char    => quotemeta($group_char),
		);
		my @regexp;
		for my $part (split /;/, $pattern) {
			push @regexp, '';
			while (length $part) {
				my $next = substr($part, 0, 1, '');
				$regexp[-1] .= ($numeric_pattern_char{$next}
					or die "unrecognized numeric pattern char: $next");
			}
		}
		if (@regexp == 1) {
			$regexp[0] = '-?' . $regexp[0];
		}
		$regexp = join '|', map "(?:$_)", @regexp;
		$regexp = qr/^($regexp)$/;
	}
	
	if (!defined $pattern or $value =~ $regexp) {
		my $dummy = quotemeta($group_char);
		$value =~ s/$dummy//g;
		unless ($decimal_char eq '.') {
			my $dec   = quotemeta($decimal_char);
			$value =~ s/$dec/\./g;
		}
		if ($value =~ /^(.+)\%$/) {
			$value = $1 / 100;
		}
		elsif ($value =~ /^(.+)‰$/) {
			$value = $1 / 1000;
		}
	}
	
	return $value;
}

my %target_patterns = (
	datetime          => '%FT%T',
	datetimestamp     => '%FT%T%z',
	time              => '%T',
	date              => '%F',
	gyearmonth        => '%Y-%m',
	gyear             => '%Y',
	gmonthday         => '--%m-%d',
	gday              => '---%d',
	gmonth            => '--%m',
);
sub _coerce_dt {
	shift;
	require DateTime::Format::CLDR;
	my ($value, $pattern, $target_type) = @_;
	my $parser = DateTime::Format::CLDR->new(
		locale    => 'en-GB',  # allow override???
		pattern   => $pattern,
	);
	my $dt = $parser->parse_datetime($value);
	return $value unless ref $dt;
	$dt->strftime($target_patterns{$target_type} || $target_patterns{datetimestamp});
}

1;