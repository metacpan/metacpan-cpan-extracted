print "1..1\n";

eval {
    require Acme::Tao;
};

package Bar;

@ISA = qw(Acme::Tao);

@messages = @messages = (qq(BARBARBAR));

package main;

use constant Tao;

my $count = 0;
while($count < 1000) {
    eval {
        Bar -> import();
    };

    if($@) {
        if($@ =~ m{BARBARBAR}) {
            print "ok 1\n";
        }
        else {
            print "not ok 1\n";
        }
        last;
    }
    $count ++;
}

print "not ok 1\n" if $count > 999;

exit 0;
