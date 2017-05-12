
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;

use Code::Splice;

{
    my $x = 10;
    Code::Splice::inject(
        # debug => 1,
        package => 'main', method => 'test',
        code => sub { 
            "blurgh";
        }, 
        preconditions => [
            sub { 
                my $op = shift;
                $op->name eq 'const' and $op->sv->sv =~ m/four/; 
            },
        ],
    );
};

sub test {
   my $w = int rand 100;
   my $x = 50; # int rand 100;
   my $str = '';
   $str .="one";
   $str .="two";
   $str .="three";
   $str .="four";
   $str .="five";
   $str .="six";
   $str .="seven";
   is($str, 'onetwothreeblurghfivesixseven', "preconditions against ops");
}

test();
