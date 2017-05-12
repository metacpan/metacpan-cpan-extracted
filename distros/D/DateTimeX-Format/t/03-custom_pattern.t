package DateTimeX::Format::RequiresPattern;
use Moose;
with 'DateTimeX::Format::CustomPattern';

sub parse_datetime {
	my $self = shift;
	my ( $time, $env, @args ) = @_;
	die 'no time_zone' unless delete $env->{'time_zone'};
	die 'no locale'    unless delete $env->{'locale'};
	die [ @_ ];
}

sub format_datetime { }


package main;
use Test::More tests => 3;

my $dt = DateTimeX::Format::RequiresPattern->new({
	time_zone    => 'floating'
	, locale     => 'en_US'
	, pattern    => '%H:%M:%S'
	, debug      => 1
	, defaults   => 1
});


eval { $dt->parse_datetime('time', {env=>1}, qw/ foo bar baz/ ); };
is_deeply ( $@ , [
		'time',
		{
			'pattern' => '%H:%M:%S',
			'override' => {
				'env' => 1
			}
		},
		'foo',
		'bar',
		'baz'
	]
	, "Stuff RequirsePattern does is predicatable"
);

eval { $dt->parse_datetime('time', {pattern=>"foobar"}, qw/ foo bar baz/ ); };
is_deeply ( $@ , [
		'time',
		{
			'pattern' => 'foobar',
			'override' => {
				'pattern' => 'foobar'
			}
		},
		'foo',
		'bar',
		'baz'
	]
	, "Changing pattern in override results in the change to function and the recorded entry in the override hash"
);

eval { $dt->parse_datetime(); };
like (
	$@
	, qr/time.*required argument/
	, "time is a required argument for things that consume CustomPattern Role"
);
