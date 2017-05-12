use Test::More;
our $no_run = 1;
do "../bin/bootstrap-perl";

is caller_line(), 5;

sub func {
        my $line = shift;
        is caller_line(), $line;
}
func(11);

sub func2 {
        func(@_);
}
func2(16);

eval <<'CODE';
        is caller_line(), 1;
        func(2);
CODE

done_testing();
