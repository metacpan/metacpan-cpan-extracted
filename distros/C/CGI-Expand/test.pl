#!/usr/bin/perl -w

use strict;
use Test::More tests => 59;
use Test::Exception;

BEGIN { use_ok( 'CGI::Expand' ); }

my $query = 'a.0=3&a.2=4&b.c.0=x&c.0=2&c.1=3&d=';
my $flat = {
	'a.0' => 3, 'a.2' => 4, 'b.c.0' => "x", 'c.0' => 2, 'c.1' => 3, d => '',
};
my $deep = {
	a => [3,undef,4],
	b => { c => ['x'] },
	c => ['2','3'],
	d => '',
};
my $pipe_flat = {
    'a|0' => 3, 'a|2' => 4, 'b|c|0' => "x", 'c|0' => 2, 'c|1' => 3, d => '',
};
my $deep_hash_only = {
    a => { 0 => 3, 2 => 4 },
    b => { c => { 0 => 'x' } },
    c => { 0 => '2', 1 => '3'},
    d => '',
};

#use Data::Dumper;
#diag Dumper(CGI::Expand->collapse_hash($deep));
#diag Dumper($flat);

sub Fake::param {
	shift;
	return keys %$flat unless @_;
	return $flat->{$_[0]};
}

# only uses param interface
is_deeply( expand_cgi(bless []=>'Fake'), $deep, 'param interface');

CGI::Expand->import('expand_hash','collapse_hash');
is_deeply( expand_hash($flat), $deep, 'expand_hash');
is_deeply( collapse_hash($deep), $flat, 'collapse_hash');

isa_ok(expand_hash({1,2}), 'HASH');
is_deeply(expand_hash({'1.0',2}), {1=>[2]}, 'top level always hash (digits)');
is_deeply(expand_hash(), {}, 'top level always hash (empty)');

my @array_99;
$array_99[99] = 1;

is_deeply(expand_hash({'a.99',1}), {a=>\@array_99}, ' < 100 array' );
throws_ok { expand_hash({'a.100',1}) } qr/^CGI param array limit exceeded/;
is_deeply(expand_hash({'a.\\100',1}), {a=>{100=>1}}, ' \100 hash' );

{
	# Limit adjustable
	local $CGI::Expand::Max_Array = 200;
	local $CGI::Expand::BackCompat = 1;
	my @array_199;
	$array_199[199] = 1;

	is_deeply(expand_hash({'a.199',1}), {a=>\@array_199}, ' < 200 array' );
	throws_ok { expand_hash({'a.200',1}) } qr/^CGI param array limit exceeded/;
	is_deeply(expand_hash({'a.\200',1}), {a=>{200=>1}}, ' \200 hash' );
}

throws_ok { expand_hash($_) } qr/^CGI param clash/
	for (   {'a.1',1,'a.b',1},
			{'a.1',1,'a',1},
			{'a.b',1,'a',1},
		);

# escaping and weird cases
my $ds = "\\\\";
is_deeply(expand_hash({'a.\0'=>1}), {a=>{0=>1}}, '\digit' );
is_deeply(expand_hash({'a.\0\\'=>1}), {a=>{'0\\'=>1}}, '\ at end' );
is_deeply(expand_hash({'a\.0'=>1}), {'a.0'=>1}, '\dot' );
is_deeply(expand_hash({'\a.0'=>1}), {'a'=>[1]}, '\ first alpha' );
is_deeply(expand_hash({'a\a.0'=>1}), {'aa'=>[1]}, '\ other alpha' );
is_deeply(expand_hash({"$ds.0"=>1}), {'\\'=>[1]}, '\ only first' );
is_deeply(expand_hash({"a.$ds.0"=>1}), {a=>{'\\'=>[1]}}, '\ only other' );
is_deeply(expand_hash({"${ds}a"=>1}), {'\\a'=>1}, 'double \ to one' );
is_deeply(expand_hash({"a$ds.0"=>1}), {'a\\'=>[1]}, 'double \ dot to one' );
is_deeply(expand_hash({'.a.'=>1}), {''=>{a=>{''=>1}}}, 'dot start end' );
is_deeply(expand_hash({'a..0'=>1}), {a=>{''=>[1]}}, 'dot dot middle' );
is_deeply(expand_hash({'a..'=>1}), {a=>{''=>{''=>1}}}, 'dot dot end' );
is_deeply(expand_hash({'.'=>1}), {''=>{''=>1}}, 'dot only' );
is_deeply(expand_hash({''=>1}), {''=>1}, 'empty key' );


SKIP: {
	skip "No CGI module", 10 unless eval 'use CGI; 1';

	is_deeply( expand_cgi(CGI->new($query)), $deep, 'expand_cgi');
	is_deeply( expand_cgi(CGI->new("$query&c.x=20&c.y=30")), $deep, 
										'expand_cgi ignores .x .y');

	ok(eq_set( ( expand_cgi(CGI->new('a=1&a=2')) )->{a}, [2, 1]), 
													'cgi multivals');

	throws_ok { expand_cgi(CGI->new($_)) } qr/^CGI param clash/
		for (  
			'a.0=3&a.c=4',
			'a.c=3&a.0=4',
			'a.0=3&a=b',
			'a.a=3&a=b',
			'a=3&a.0=b',
			'a=3&a.a=b',
			'a=3&a=4&a.b=1',
		);
}

{
    # Disable Array, treat everything as a hash
    local $CGI::Expand::Max_Array = 0;
	local $CGI::Expand::BackCompat = 1;
    # $flat from above

    is_deeply( expand_hash($flat), $deep_hash_only, 'expand hash only');
    is_deeply( collapse_hash($deep_hash_only), $flat, 'collapse hash only');
    is_deeply( expand_hash(collapse_hash($deep_hash_only)), $deep_hash_only, 
        'round trip hash only');
}
{
    local $CGI::Expand::Separator = '|'; # Another regex metacharacter
	local $CGI::Expand::BackCompat = 1;

    is_deeply( CGI::Expand->expand_hash($pipe_flat), $deep, 
                                        'expand sep | with class method');
    is_deeply( CGI::Expand->collapse_hash($deep), $pipe_flat, 
                                        'collapse sep | with class method');
}

{ 
    package Subclass::Empty;
    our @ISA = qw(CGI::Expand);

    package Subclass::Empty::main;
    use Test::More;

    Subclass::Empty->import();
    is_deeply( expand_cgi(bless []=>'Fake'), $deep, 'subclass param interface');

    Subclass::Empty->import('expand_hash', 'collapse_hash');
    is_deeply( expand_hash($flat), $deep, 'subclass expand_hash');
    is_deeply( collapse_hash($deep), $flat, 'subclass collapse_hash');
}

{ 
    package Subclass::Pipe;
    our @ISA = qw(CGI::Expand);
    sub separator { '.|' }

    package Subclass::Pipe::main;
    use Test::More;

    Subclass::Pipe->import();
    is_deeply( expand_cgi(bless []=>'Fake'), $deep, 'subclass param interface');

    Subclass::Pipe->import('expand_hash', 'collapse_hash');
    is_deeply( expand_hash($flat), $deep, 'pipe subclass expand_hash');
    is_deeply( expand_hash($pipe_flat), $deep,'pipe subclass hash pipe :)');
    is_deeply( collapse_hash($deep), $flat, 'pipe subclass collapse_hash');
}

{ 
    package Subclass::NoArray;
    our @ISA = qw(CGI::Expand);
    sub max_array { 0 }

    package Subclass::NoArray::main;
    use Test::More;

    Subclass::NoArray->import();
    is_deeply( expand_cgi(bless []=>'Fake'), $deep_hash_only, 
                                            'subclass param hash only');

    Subclass::NoArray->import('expand_hash', 'collapse_hash');
    is_deeply( expand_hash($flat), $deep_hash_only,'subclass expand hash only');
    is_deeply( collapse_hash($deep_hash_only), $flat, 
        'subclass collapse hash only');
    is_deeply( expand_hash(collapse_hash($deep_hash_only)), $deep_hash_only, 
        'subclass round trip hash only');
}

{ 
    package Subclass::Rails;
    our @ISA = qw(CGI::Expand);
    sub max_array  { 0 }
    sub separator  { '.[]' }
    sub split_name {
        my $class = shift;
        my $name = shift;
        $name =~ /^ ([^\[\]\.]+) /xg;
        my @segs = $1;
        push @segs, ($name =~ / \G (?: \[ ([^\[\]\.]+) \] ) /xg);
        return @segs;
    }
    sub join_name  {
        my $class = shift;
        my ($first, @segs) = @_;
        return $first unless @segs;
        return "$first\[".join('][',@segs)."]";
    }

    package Subclass::Rails::main;
    use Test::More;

    Subclass::Rails->import('expand_hash', 'collapse_hash');

    my $rails_flat = { 'a' => 1, 'b[c]' => 2, 'b[d][e]' => undef, 'b[2]' => 3 };
    my $rails_deep = {
        a => '1', b => { c => 2, d => { e => undef }, '2' => 3 }
    };
    is_deeply( expand_hash($rails_flat), $rails_deep, 
                                            '[] convention expands');
    is_deeply( collapse_hash($rails_deep), $rails_flat, 
                                            '[] convention collapses');
    is_deeply( expand_hash(collapse_hash($rails_deep)), $rails_deep, 
        '[] convention round trips');
}

#my $mix_flat = { 'a' => 1, 'b[c]' => 2, 'b.d.e' => undef };
#my $mix_deep = {
#        a => '1', b => { c => 2, d => { e => undef } }
#    };
#is_deeply( expand_hash($mix_flat), $mix_deep, '[] convention expands');
#is_deeply( collapse_hash($mix_deep), $mix_flat, '[] convention collapses');
