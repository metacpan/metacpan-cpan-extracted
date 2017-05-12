
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;

use Code::Splice;

{
    my $x = 10;
    my @stuff;
    Code::Splice::inject(
        package => 'foo', method => 'bar', line => 28, 
        code => sub { 
            push @stuff, $x;
            push @stuff, 15;
        }, 
    );
};

package foo;

sub bar {
   my @stuff;
   my $w = 30;
   my $x = 40;
   push @stuff, 1;
   push @stuff, 2;
   push @stuff, 3;
   push @stuff, 4;
   push @stuff, 5;
   push @stuff, 6;
   push @stuff, 7;
   push @stuff, 8;
   push @stuff, 9;
   main::is("@stuff", "1 2 40 15 4 5 6 7 8 9", "variable remapping");
}

bar();


