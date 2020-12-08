package App::optex::tc;

use v5.14;
use warnings;

use App::optex::textconv;

for my $sub (qw(initialize finalize load)) {
    no strict 'refs';
    *{$sub} = \&{"App::optex::textconv::$sub"};
}

1;
