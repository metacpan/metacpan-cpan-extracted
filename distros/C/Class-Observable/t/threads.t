use strict; use warnings;

use Config;
use Test::More;

BEGIN {
	plan skip_all => 'perl 5.8.1 required for thread tests'
		unless "$]" >= 5.008001;

	plan skip_all => 'perl interpreter is not compiled with ithreads'
		unless $Config{'useithreads'};

	plan skip_all => 'threads are unreliable on perl 5.10.0'
		if "$]" >= 5.009 and "$]" < 5.010001;

	plan skip_all => "threads pragma failed to load: $@"
		unless eval { require threads };

	plan tests => 4;
}

use Class::Observable;
our @ISA = 'Class::Observable';
sub DESTROY {} # prevent Class::Observable::DESTROY from being called

my $warning;
$SIG{'__WARN__'} = sub { $warning = "@_" };

my @obs = qw( Foo Bar Baz );

my $self = bless {};
$self->add_observer( @obs );

is_deeply( [ $self->get_observers ], \@obs,
	'got expected observers' );

is_deeply( threads->create( sub { [ $self->get_observers ] } )->join, \@obs,
	'got expected observers in cloned interpreter' );

$self->delete_all_observers; # clean up manually
undef $self;
is( threads->create( sub { $warning } )->join, undef,
	'manual cleanup prevents lost instances' );

$self = bless {};
$self->add_observer( @obs );
undef $self; # no cleanup, rely on DESTROY (which is blocked), causing littering
is( threads->create( sub { $warning } )->join,
	"*** Inconsistent state ***\nObserved instances have gone away without invoking Class::Observable::DESTROY\n",
	'detected lost instances' );
