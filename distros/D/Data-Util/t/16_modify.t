#!perl -w

use strict;
use Test::More tests => 55;
use Test::Exception;

use constant HAS_SCOPE_GUARD => eval{ require Scope::Guard };

use Data::Util qw(:all);

sub foo{ @_ }

my @tags;
sub before{ push @tags, 'before'; }
sub around{ push @tags, 'around'; my $next = shift; $next->(@_) }
sub after { push @tags, 'after'; }

ok is_code_ref(modify_subroutine(\&foo)), 'modify_subroutine()';

my $w = modify_subroutine \&foo,
	before => [\&before],
	around => [\&around],
	after => [\&after];

lives_ok{
	ok  subroutine_modifier($w);
	ok !subroutine_modifier(\&foo);
};

is_deeply [subroutine_modifier $w, 'before'], [\&before], 'getter:before';
is_deeply [subroutine_modifier $w, 'around'], [\&around], 'getter:around';
is_deeply [subroutine_modifier $w, 'after'],  [\&after],  'getter:after';

is_deeply [scalar $w->(1 .. 10)], [10], 'call with scalar context';
is_deeply \@tags, [qw(before around after)];

@tags = ();
is_deeply [$w->(1 .. 10)], [1 .. 10],   'call with list context';
is_deeply \@tags, [qw(before around after)];

$w = modify_subroutine \&foo;
subroutine_modifier $w, before => \&before;
@tags = ();
is_deeply [$w->(1 .. 10)], [1 .. 10];
is_deeply \@tags, [qw(before)], 'add :before modifiers';

$w = modify_subroutine \&foo;
subroutine_modifier $w, around => \&around;
@tags = ();
is_deeply [$w->(1 .. 10)], [1 .. 10];
is_deeply \@tags, [qw(around)], 'add :around modifiers';

$w = modify_subroutine \&foo;
subroutine_modifier $w, after  => \&after;
@tags = ();
is_deeply [$w->(1 .. 10)], [1 .. 10];
is_deeply \@tags, [qw(after)], 'add :after modifiers';

$w = modify_subroutine \&foo, before => [(\&before) x 10], around => [(\&around) x 10], after => [(\&after) x 10];

@tags = ();
is_deeply [$w->(42)], [42];

is_deeply \@tags, [('before') x 10, ('around') x 10, ('after') x 10], 'with multiple modifiers';

subroutine_modifier $w, before => \&before, \&before;
subroutine_modifier $w, around => \&around, \&around;
subroutine_modifier $w, after  => \&after,  \&after;

@tags = ();
is_deeply [$w->(1 .. 10)], [1 .. 10];
is_deeply \@tags, [('before') x 12, ('around') x 12, ('after') x 12], 'add modifiers';

# calling order and copying

sub f1{
	push @tags, 'f1';
	my $next = shift;
	$next->(@_);
}
sub f2{
	push @tags, 'f2';
	my $next = shift;
	$next->(@_);
}
sub f3{
	push @tags, 'f3';
	my $next = shift;
	$next->(@_);
}


sub before2{ push @tags, 'before2' }
sub before3{ push @tags, 'before3' }

sub after2 { push @tags, 'after2'  }
sub after3 { push @tags, 'after3'  }

# the order of around modifier
$w = modify_subroutine \&foo, around => [ \&f1, \&f2, \&f3 ];
@tags = ();
$w->();
is_deeply \@tags, [qw(f1 f2 f3)], ":around order (modify_subroutine)(@tags)";

$w = modify_subroutine \&foo;
subroutine_modifier $w, around => \&f3, \&f2, \&f1;
@tags = ();
$w->();
is_deeply \@tags, [qw(f3 f2 f1)], ":around order (subroutine_modifier) (@tags)";

$w = modify_subroutine \&foo;
subroutine_modifier $w, around => $_ for \&f1, \&f2, \&f3;
@tags = ();
$w->();
is_deeply \@tags, [qw(f3 f2 f1)], ":around order (subroutine_modifier) (@tags)";

# the order of before modifier
$w = modify_subroutine \&foo, before => [\&before, \&before2, \&before3];
@tags = ();
$w->();
is_deeply \@tags, [qw(before before2 before3)], ':before order (modify_subroutine)';

$w = modify_subroutine \&foo;
subroutine_modifier $w, before => \&before, \&before2, \&before3;
@tags = ();
$w->();
is_deeply \@tags, [qw(before3 before2 before)], ':before order (subroutine_modifier)';

$w = modify_subroutine \&foo;
subroutine_modifier $w, before => $_ for \&before, \&before2, \&before3;
@tags = ();
$w->();
is_deeply \@tags, [qw(before3 before2 before)], ":before order (subroutine_modifier) (@tags)";


# the order of after modifier
$w = modify_subroutine \&foo, after => [\&after, \&after2, \&after3];
@tags = ();
$w->();
is_deeply \@tags, [qw(after after2 after3)], ':after order (modify_subroutine)';

$w = modify_subroutine \&foo;
subroutine_modifier $w, after => \&after, \&after2, \&after3;
@tags = ();
$w->();
is_deeply \@tags, [qw(after after2 after3)], ':after order (subroutine_modifier)';

$w = modify_subroutine \&foo;
subroutine_modifier $w, after => $_ for \&after, \&after2, \&after3;
@tags = ();
$w->();
is_deeply \@tags, [qw(after after2 after3)], ":after order (subroutine_modifier) (@tags)";


# Moose compatibility
$w = modify_subroutine \&foo;
subroutine_modifier $w, before => $_ for \&before1, \&before2, \&before3;
subroutine_modifier $w, around => $_ for \&around1, \&around2, \&around3;
subroutine_modifier $w, after  => $_ for \&after1,  \&after2,  \&after3;

is_deeply [subroutine_modifier $w, 'before'], [\&before3, \&before2, \&before1], 'get before modifiers';
is_deeply [subroutine_modifier $w, 'around'], [\&around3, \&around2, \&around1], 'get around modifiers';
is_deeply [subroutine_modifier $w, 'after' ], [\&after1,  \&after2,  \&after3 ], 'get after  modifiers';

# Copying possilbility
$w = modify_subroutine \&foo,
	before => [subroutine_modifier $w, 'before'],
	around => [subroutine_modifier $w, 'around'],
	after  => [subroutine_modifier $w, 'after' ];
is_deeply [subroutine_modifier $w, 'before'], [\&before3, \&before2, \&before1], 'copy before modifiers';
is_deeply [subroutine_modifier $w, 'around'], [\&around3, \&around2, \&around1], 'copy around modifiers';
is_deeply [subroutine_modifier $w, 'after' ], [\&after1,  \&after2,  \&after3 ], 'copy after  modifiers';

# Contexts


sub get_context{
	push @tags,  wantarray    ? 'list'
	: defined(wantarray) ? 'scalar'
	:                      'void';
}

$w = modify_subroutine(\&foo, around => [\&get_context]);

@tags = ();
() = $w->();
is_deeply \@tags, [qw(list)], 'list context in around';

@tags = ();
scalar $w->();
is_deeply \@tags, [qw(scalar)], 'scalar context in around';

@tags = ();
$w->();
is_deeply \@tags, [qw(void)], 'void context in around';

# Modifier's args

sub mutator{
	$_[0]++;
}

$w = modify_subroutine(\&foo, before => [\&mutator]);
my $n = 42;
is_deeply [ $w->($n) ], [43]; # $n++
is $n, 43;


# GC

SKIP:{
	skip 'requires Scope::Gurard for testing GC',    3 unless HAS_SCOPE_GUARD;

	@tags = ();
	for(1 .. 10){
		my $gbefore = Scope::Guard->new(sub{ push @tags, 'before' });
		my $garound = Scope::Guard->new(sub{ push @tags, 'around' });
		my $gafter  = Scope::Guard->new(sub{ push @tags, 'after'  });

		my $w = modify_subroutine \&foo,
			before => [sub{ $gbefore }], # encloses guard objects
			around => [sub{ $gafter }],
			after  => [sub{ $gafter }];
	}
	is_deeply [sort @tags], [sort((qw(after around before)) x 10)], 'closed values are released';

	@tags = ();
	my $i = 0;
	for(1 .. 10){
		my $gbefore = Scope::Guard->new(sub{ push @tags, 'before' });
		my $garound = Scope::Guard->new(sub{ push @tags, 'around' });
		my $gafter  = Scope::Guard->new(sub{ push @tags, 'after'  });

		my $w = modify_subroutine \&foo,
			before => [sub{ $gbefore }], # encloses guard objects
			around => [sub{ $gafter }],
			after  => [sub{ $gafter }];

		$w->(Scope::Guard->new( sub{ $i++ } ));
	}
	is_deeply [sort @tags], [sort((qw(after around before)) x 10)], '... called and released';
	is $i, 10, '... and the argument is also released';
}

# FATAL

dies_ok{
	modify_subroutine(undef);
};
dies_ok{
	modify_subroutine(\&foo, []);
};

dies_ok{
	modify_subroutine(\&foo, before => [1]);
};
dies_ok{
	modify_subroutine(\&foo, around => [1]);
};
dies_ok{
	modify_subroutine(\&foo, after => [1]);
};

$w = modify_subroutine(\&foo);

throws_ok{
	subroutine_modifier($w, 'foo');
} qr/Validation failed:.* a modifier property/;
throws_ok{
	subroutine_modifier($w, undef);
} qr/Validation failed:.* a modifier property/;

throws_ok{
	subroutine_modifier($w, before => 'foo');
} qr/Validation failed:.* a CODE reference/;


throws_ok{
	subroutine_modifier($w, foo => sub{});
} qr/Validation failed:.* a modifier property/;


throws_ok{
	subroutine_modifier(\&foo, 'before');
} qr/Validation failed:.* a modified subroutine/;
throws_ok{
	subroutine_modifier(\&foo, before => sub{});
} qr/Validation failed:.* a modified subroutine/;
