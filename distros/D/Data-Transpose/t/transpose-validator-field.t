use strict;
use warnings;
use Test::More;
use Data::Transpose::Validator;

my $dtv = Data::Transpose::Validator->new;

my $field = $dtv->field('month' => {validator => 'NumericRange',
                                    options => {
                                        min => 1,
                                        max => 12,
                                        integer => 1
                                    },
                                    });

my @input = ({value => 11, valid => 1},
             {value => 12, valid => 1},
             {value => 13, valid => 0},
             {value => 1.1, valid => 0},
             );

plan tests => scalar(@input);

for my $spec (@input) {
    my $ret = $dtv->transpose({month => $spec->{value}});

    if ($spec->{valid}) {
        ok($ret, "Test whether $spec->{value} is numeric month.")
            || diag "Result: " . $dtv->packed_errors;
    }
    else {
        ok(! $ret, "Test whether $spec->{value} is numeric month.");
    }
}


