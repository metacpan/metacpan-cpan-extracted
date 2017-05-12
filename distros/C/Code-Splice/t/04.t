
use Test::More tests => 1;
use Code::Splice;


{
    my @stuff;
    Code::Splice::inject(
        # debug => 1,
        package => 'main', method => 'test',
        code => sub { 
            push @stuff, "fred";
        }, 
        precondition => sub {
            my $op = shift;
            my $stringrep = shift;
            $stringrep =~ m/four/ and $stringrep =~ m/push/;
        },
    );
};

sub test {
   my $w = 20 + int rand 100;
   my $x = 20 + int rand 100;
   my @stuff;
   push @stuff,  "one";
   push @stuff,  "two";
   push @stuff,  "three";
   push @stuff,  "four";
   push @stuff,  "five";
   push @stuff,  "six";
   push @stuff,  "seven";
   print "@stuff\n";
   is("@stuff", 'one two three fred five six seven', "precondition against deparsed line");
}

test();
