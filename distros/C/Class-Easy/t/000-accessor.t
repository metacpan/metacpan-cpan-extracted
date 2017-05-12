#!/usr/bin/perl

use Class::Easy::Import;
use Test::More qw(no_plan);
use Data::Dumper;

use Errno qw(:POSIX);

use_ok ('Class::Easy');

logger ('debug')->appender (*STDERR);

ok try_to_use_quiet ('My', 'Circle');

my $use_result = try_to_use_quiet ('My', 'Circle', 'QEWRQWERTQWETQWERQWERWER');

ok ! defined $use_result;

ok $!{ENOENT}; # no such file or directory

make_accessor ('My::Circle::QEWRQWERTQWETQWERQWERWER', 'aaa', default => sub {return 1;});

# symbolic table now have one or more records for this package, ok
ok try_to_use_quiet ('My', 'Circle', 'QEWRQWERTQWETQWERQWERWER');

# but package not exists within %INC
ok ! try_to_use_inc_quiet ('My', 'Circle', 'QEWRQWERTQWETQWERQWERWER');

no warnings qw(redefine);

my $circle = My::Circle->new;

ok $circle->new_default eq 'new_default';

$circle->dim_x (2);
$circle->dim_y (3);

#diag Dumper $circle;

ok $circle->dim_x == 2;
ok $circle->dim_y == 3;

ok $circle->id == 2345;

$circle->global_hash->{1} = 1;
ok $circle->global_hash->{1} == 1;

ok ! defined $circle->global_hash_rw;

$circle->global_hash_rw ({'aaa' => 'aaa'});
ok $circle->global_hash_rw->{'aaa'} eq 'aaa';

$circle->global_hash_rw_default ({'aaa' => 'aaa'});
ok $circle->global_hash_rw_default->{'aaa'} eq 'aaa';


eval {$circle->id (1);};
ok $@ =~ /^too many parameters/, "ERROR: $@";

# warn Dumper \%My::Circle::__accessors;

my $ellipse = My::Ellipse->new;

#warn Dumper $ellipse->global_hash_rw;
#die 'jopa' if ref $ellipse->global_hash_rw eq 'HASH';

#ok ! defined $ellipse->global_hash_rw;

$ellipse->global_hash_rw ({});

ok ! scalar keys %{$ellipse->global_hash_rw};

ok scalar keys %{$circle->global_hash_rw};

# die;

# diag Dumper $circle->global_hash_rw;

my $sphere = My::Sphere->new;
$sphere->dim_x (2);
$sphere->dim_y (3);

ok $sphere->dim_x == 2;
ok $sphere->dim_y == 3;

$sphere->dim_z (4);
ok $sphere->dim_z == 4;

$sphere->global_one ('test');

$sphere->global_one_defined ('la-la-la');

ok $sphere->can ('global_hash_rw');

eval {$sphere->global_ro (1);};
ok $@ =~ /^too many parameters/, "ERROR: $@";

ok $sphere->sub_z eq $sphere->dim_z;

make_accessor ('My::Sphere', 'accessor', default => sub {
	my $self = shift;
	
	return $self->global_one;
});

ok $sphere->accessor eq $sphere->global_one;

# warn join ', ', Class::Easy::list_subs ('My::Sphere');

my $subs = Class::Easy::list_all_subs_for ($circle);

ok keys %{$subs->{inherited}} == 1, 'now we use Class::Easy::Base as base class';

# warn Dumper $subs;

$subs = Class::Easy::list_all_subs_for ($sphere);

ok keys %{$subs->{inherited}} == 2;
ok grep {$_ eq 'global_hash_rw_default'} @{$subs->{inherited}->{'My::Circle'}};

# warn Dumper $subs;

1;

package My::Circle;

use Class::Easy::Base;

# begin is needed because we can't actually use these packages
BEGIN {
	has 'id';
	has 'dim_x', is => 'rw';
	has 'dim_y', is => 'rw';
	has 'global_hash', default => {};
	has 'global_hash_rw', is => 'rw', global => 1;
	has 'global_hash_rw_default', is => 'rw', global => 1, default => {ccc => 'ddd'};
	has new_default => 'new_default';
};

sub new {
	my $class = shift;
	my $self  = {id => 2345};
	
	bless $self, $class;
}

1;

package My::Sphere;

use Class::Easy::Base;

use base 'My::Circle';

BEGIN {
	has 'dim_z', is => 'rw';
	has 'global_one', is => 'rw', global => 1;
	has 'global_one_defined', is => 'rw', global => 1, default => 'defined';
	has 'global_ro', default => 'ro';
	has 'sub_z', default => sub {
		my $self = shift;
		
		return $self->dim_z;
	};
};

1;

package My::Ellipse;

use Class::Easy::Base;

use base 'My::Circle';

1;