use 5.010;
use MooseX::Declare;

class Test {
    has a_var => ( is => 'rw', isa => 'Str' );
    has b_var => ( is => 'rw', isa => 'Str' );

    method some_method {
        my $x_var = 1;

        say "Do stuff with ${x_var}";
        $x_var += 2;

        my %hash;
        for my $i (1..5) {
            $hash{$i} = $x_var;
        }
    }
}

