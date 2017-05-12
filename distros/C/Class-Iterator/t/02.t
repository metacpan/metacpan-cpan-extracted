# -*- perl -*-

use Test::More;
BEGIN { plan tests => 102 };
use Class::Iterator qw(imap igrep);

my $it = Class::Iterator->new(sub { my $i = 0; 
				    return sub { $i < 100 ? $i++ : undef}
				});

# test creation
ok $it;

# test the imap routine
my $it2 = imap { $_ + 99 } $it;
my $v = 99 ;
while (defined(my $n = $it2->next)) {
    ok ($v++ == $n);
}

# test the imap routine
my $it3 = igrep { $_ >= 99 } $it;
ok ($it3->next == 99);
my $s = sub { $_ >= 99 };
