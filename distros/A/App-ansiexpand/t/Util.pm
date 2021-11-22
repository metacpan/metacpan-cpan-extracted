use v5.14;
use warnings;

use Data::Dumper;
use lib '.';
use t::Runner;

use Text::ParseWords qw(shellwords);

$ENV{PERL5LIB} = join ':', @INC;

sub ansiexpand {
    my @opts = @_;
    Runner->new(
	sub {
	    use App::ansiexpand;
	    App::ansiexpand->new->run(@opts);
	});
}

sub test {
    my %arg = @_;
    (my $runner = ansiexpand shellwords($arg{option}))
	->setstdin($arg{stdin})->run;
    is($runner->{stdout}, $arg{expect}, "option: $arg{option}");
}

1;
