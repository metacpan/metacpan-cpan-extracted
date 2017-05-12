# -*- perl -*-

use Test::More;
BEGIN { plan tests => 205 };
use Class::Iterator;

my $it = Class::Iterator->new(sub { my $i = 0; 
				    return sub { $i < 100 ? $i++ : undef}
				});

# test creation
ok $it;
#diag($it->next);
# test next method
my $v = 0 ;
while (defined(my $n = $it->next)) {
    ok ($v++ == $n);
}


# test the init method
$it->init;
my $v = 0 ;
while (defined(my $n = $it->next)) {
    ok ($v++ == $n);
}

# test the default construct
undef $it;
$it = Class::Iterator->new;
ok (! defined($it->next));

my $it = 
igrep { $_ < 7 } 
igrep {  $_ > 3 }
Class::Iterator->new(sub{ my $n = 0; sub{ $n > 9 ? undef : $n++ }});

                                                             
while(defined( $_ = $it->next )) { ok ( $_ < 7 && $_ > 3 )  }

