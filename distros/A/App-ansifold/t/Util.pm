use v5.14;
use warnings;

use Data::Dumper;
use lib '.';
use t::Runner;

$ENV{PERL5LIB} = join ':', @INC;

sub ansifold {
    my @opts = @_;
    Runner->new(
	sub {
	    use App::ansifold;
	    App::ansifold->new->run(@opts);
	});
}

sub test {
    my %arg = @_;
    (my $runner = ansifold shellwords($arg{option}))
	->setstdin($arg{stdin})->run;
    is($runner->{stdout}, $arg{expect}, "option: $arg{option}");
}

1;
