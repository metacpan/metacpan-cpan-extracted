#!perl -T

use Test::More tests => 70;
use Data::Dumper;

BEGIN {
	use_ok( 'Acme::TextLayout' );
}

diag( "Testing Acme::TextLayout $Acme::TextLayout::VERSION, Perl $], $^X" );

my $tl = Acme::TextLayout->new;
my $pattern = <<'EOF';
JJJhhhhhhhhrr
AAAAAAAAAAAAA
BBBCCCCCCCCCC
DDEEEEEEEEEFF
DDEEEEEEEEEFF
EOF
my @Characters = qw(J h r A B C D E F);
ok($tl->instantiate(text => $pattern));

# test fetching a particular line in pattern
ok(check([qw(J h r)], $tl->order(0)));
# test possible direction methods for right answers
ok(check([qw(h)], $tl->right('J')));
ok(check([qw(r)], $tl->right('h')));
ok(check([], $tl->right('A')));
ok(check([qw(C)], $tl->right('B')));
ok(check([], $tl->right('C')));
ok(check([qw(E)], $tl->right('D')));
ok(check([qw(F)], $tl->right('E')));
ok(check([], $tl->right('F')));

ok(check([], $tl->left('J')));
ok(check([], $tl->left('A')));
ok(check([], $tl->left('D')));
ok(check([qw(D)], $tl->left('E')));
ok(check([qw(E)], $tl->left('F')));
ok(check([qw(B)], $tl->left('C')));
ok(check([qw(h)], $tl->left('r')));
ok(check([qw(J)], $tl->left('h')));

ok(check([qw(B C)], $tl->above('E')));
ok(check([qw(C)], $tl->above('F')));
ok(check([qw(B)], $tl->above('D')));
ok(check([qw(A)], $tl->above('B')));
ok(check([qw(A)], $tl->above('C')));
ok(check([], $tl->above('J')));
ok(check([], $tl->above('h')));
ok(check([], $tl->above('r')));
ok(check([qw(A)], $tl->below('J')));
ok(check([qw(A)], $tl->below('h')));
ok(check([qw(A)], $tl->below('r')));
ok(check([qw(B C)], $tl->below('A')));
ok(check([qw(E D)], $tl->below('B')));
ok(check([qw(F E)], $tl->below('C')));
ok(check([], $tl->below('D')));
ok(check([], $tl->below('E')));
ok(check([], $tl->below('F')));

# be sure we get right answers from characters method
my @chars = $tl->characters();
@chars = sort(@chars);
@Characters = sort(@Characters);
ok(check(\@Characters, @chars));
#print STDERR Dumper(\@chars);

$tl = Acme::TextLayout->new;
$pattern = <<'EOF';
JJJhhhhhhhhrr
AAAAAAAAAAArr
BBBCCCCCCCCCC
DDEEEEEEEEEFF
DDEEEEEEEEEFF
EOF
$tl->instantiate(text => $pattern);
ok(check([qw(A h)], $tl->left('r')));

# request a line too big for our pattern
print STDERR "This should report error:\n";
eval q($tl->order(5));
print STDERR $@;
ok($@ ne '');

# test of a non-rectangular pattern
$pattern = <<'EOF';
aaaaaa
bb
EOF
$tl = Acme::TextLayout->new;
ok (!($tl->instantiate(text => $pattern)));

# single char pattern test
$pattern = <<'EOF';
A
EOF
$tl = Acme::TextLayout->new;
ok($tl->instantiate(text => $pattern));
ok($tl->width()==1 && $tl->height()==1);

# bad pattern tests
$pattern = <<'EOF';
ABBA
EOF
ok(!$tl->instantiate(text => $pattern));

$tl = Acme::TextLayout->new;
$pattern = <<'EOF';
BBBA
ABBB
EOF
eval q($tl->instantiate(text => $pattern));
ok($@);

$tl = Acme::TextLayout->new;
$pattern = <<'EOF';
BBBAAA
BBBAAA
CCCCCC
BBBAAA
EOF
ok(!$tl->instantiate(text => $pattern));

# be sure leading whitespace handled
$tl = Acme::TextLayout->new;
$pattern = <<'EOF';
            ABBBB
            ABBBB
            CCCCC
EOF
ok($tl->instantiate(text => $pattern));
ok(!$tl->only_one());

# single character pattern and test only_one method
$tl = Acme::TextLayout->new;
$pattern = <<'EOF';
    A
EOF
ok($tl->instantiate(text => $pattern));
ok($tl->only_one() == 1);

$tl = Acme::TextLayout->new;
$pattern = <<'EOF';
    AAAABBBBBB
    AAAABBBBBB
EOF
ok($tl->instantiate(text => $pattern));
ok(check([qw(0.4 1)], $tl->range_as_percent('A')));
ok(check([qw(0.6 1)], $tl->range_as_percent('B')));
ok(check([qw(0 0 39 99)], $tl->map_range(100, 100, 'A')));
ok(check([qw(40 0 99 99)], $tl->map_range(100, 100, 'B')));

$pattern = <<'EOF';
    AAAABBBBBB
    AAAABBBBBB
    CCCCDDDDDD
    CCCCDDDDDD
EOF
ok($tl->instantiate(text => $pattern));
ok(check([qw(0.4 0.5)], $tl->range_as_percent('A')));
ok(check([qw(0.4 0.5)], $tl->range_as_percent('C')));
ok(check([qw(0.6 0.5)], $tl->range_as_percent('B')));
ok(check([qw(0.6 0.5)], $tl->range_as_percent('D')));
ok(check([qw(0 0 39 49)], $tl->map_range(100, 100, 'A')));
ok(check([qw(0 50 39 99)], $tl->map_range(100, 100, 'C')));
ok(check([qw(40 0 99 49)], $tl->map_range(100, 100, 'B')));
ok(check([qw(40 50 99 99)], $tl->map_range(100, 100, 'D')));
ok($tl->height()==4 && $tl->width()==10);
ok(check([qw(0 1 0 3)], $tl->range('A')));
ok(check([qw(2 3 0 3)], $tl->range('C')));
ok(check([qw(0 1 4 9)], $tl->range('B')));
ok(check([qw(2 3 4 9)], $tl->range('D')));

ok($tl->instantiate(file => 'data/foobar.dat'));
ok($tl->width()==5 && $tl->height()==3);

sub check {
    my ($ref, @x) = @_;
    my $status = 1;
    if (@$ref != @x) {
        print STDERR Dumper(\@x);
        return 0;
    }
    map {
        $status = 0 unless $ref->[$_] eq $x[$_];
    } 0..$#x;
    print STDERR Dumper(\@x) unless $status;
    return $status;
}
