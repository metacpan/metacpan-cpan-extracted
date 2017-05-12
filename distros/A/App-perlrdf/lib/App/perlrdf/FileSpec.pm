package App::perlrdf::FileSpec;

use 5.010;
use autodie;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::FileSpec::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::FileSpec::VERSION   = '0.006';
}

use Moose;
use Moose::Util::TypeConstraints;
use JSON;
use PerlX::Maybe;
use RDF::Trine;
use URI;
use URI::file;
use namespace::clean;

class_type PathClassFile => { class => 'Path::Class::File' };
class_type AbsoluteUri   => { class => 'URI' };

coerce 'AbsoluteUri',
	from Str => via {
		if    (/^std(in|out):$/i) { URI->new(lc $_) }
		elsif (/^\w\w+:/i)        { URI->new($_) }
		else                      { URI::file->new_abs($_) }
	};

coerce 'AbsoluteUri',
	from PathClassFile => via {
		URI::file->new_abs("$_")
	};

has uri => (
	is         => 'ro',
	isa        => 'AbsoluteUri',
	required   => 1,
	coerce     => 1,
);

has base => (
	is         => 'ro',
	isa        => 'AbsoluteUri',
	lazy_build => 1,
	coerce     => 1,
);

has 'format' => (
	is         => 'ro',
	isa        => 'Str',
	lazy_build => 1,
);

sub DEFAULT_STREAM
{
	warn "DEFAULT_STREAM is 'stdout:'\n";
	return "stdout:";
}

sub _jsonish
{
	my ($self, $str) = @_;
	$str =~ s/(^\{)|(\}$)//g; # strip curlies
	
	my $opts = {};
	while ($str =~ m{ \s* (\w+|"[^"]+"|'[^']+') \s* [:] (\w+|"[^"]+"|'[^']+') \s* ([;,]|$) }xg)
	{
		my $key = $1;
		my $val = $2;
		$val = $1 if $val =~ /^["'](.+).$/;
		$opts->{$key} = $val;
	}
	
	return $opts;
}

sub new_from_filespec
{
	my ($class, $spec, $default_format, $default_base) = @_;
	
	my ($optstr, $name) = ($spec =~ m<^ (\{ .*? \}) (.+) $>x)
		? ($1, $2)
		: ('{}', $spec);
	my $opts = $class->_jsonish($optstr);

	$class->new(
		'uri'          => ($name eq '-' ? $class->DEFAULT_STREAM : $name),
		maybe('format' => ($opts->{format} // $default_format)),
		maybe('base'   => ($opts->{base}   // $default_base)),
	);
}

sub _build_base
{
	shift->uri;
}

sub _build_format
{
	return $1 if shift->uri =~ /\.(\w+)$/;
	return '';
}

sub TO_JSON
{
	my ($self, $stringify) = @_;
	my $r = +{
		base    => $self->base->as_string,
		format  => $self->format,
		uri     => $self->uri->as_string,
	};
	return $stringify
		? to_json($r => +{ pretty => 1, canonical => 1 })
		: $r;
}

sub AUTHORITY
{
	my $class = ref($_[0]) || $_[0];
	no strict qw(refs);
	${"$class\::AUTHORITY"};
}

1;