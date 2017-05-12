# -*- perl -*-

use Test::More qw(no_plan);
use Data::Eacherator qw(eacherator);

# NOTE: These tests could be "stronger" if not for Perl's randomised
# hash feature.  Not knowing what a hash will look like makes some
# things difficult...

sub empty {
    my $data = [ ];
    
    my $iter = eacherator($data);
    
    my ($k, $v);
    
    ($k, $v) = $iter->();
    
    is($k, undef);
    is($v, undef);

    ($k, $v) = $iter->();
    
    is($k, undef);
    is($v, undef);
}

empty({});
empty([]);

sub simple {
    my ($expected, $count, $data) = @_;
    
    my $iter = eacherator($data);
    
    my $i;
    
    $i = 0;

    while (my ($k, $v) = $iter->()) {
	is($v, $expected->{$k});
	$i++;
    }
    
    is($count, $i);
    
    $i = 0;

    while (my ($k, $v) = $iter->()) {
	is($v, $expected->{$k});
	$i++;
    }
    
    is($count, $i);

}

my ($k1, $k2, $k3) = qw(aa bb cc);
my ($v1, $v2, $v3) = qw(xx yy zz);

my $expected = { $k1 => $v1, $k2 => $v2, $k3 => $v3 };

my $hash = { $k1 => $v1, $k2 => $v2, $k3 => $v3 };

simple($expected, 3, $hash);

my $list1 = [ $k1 => $v1, $k2 => $v2, $k3 => $v3 ];

simple($expected, 3, $list1);

my $list2 = [ $k1 => $v1, $k2 => $v2, $k3 => $v3, "jjj" ];

simple($expected, 3, $list2);

simple({}, 0, {});

simple({}, 0, []);
