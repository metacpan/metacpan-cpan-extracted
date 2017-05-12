use strict;
use warnings;
use Scalar::Util qw(reftype);

sub make_check_closure
{
    my $check = shift;
    my $name  = shift;

    my $func;
    $func = sub {
        my $h = shift;
        my $ref = reftype($h);

        if (! $ref) {
            ok($check->($h), "Assert value is $name");
        } elsif ($ref eq 'HASH') {
            # Hash
            while (my($key, $value) = each %$h) {
                ok($check->($key), "Assert key is $name");
                if (ref($value)) {
                    $func->($value);
                } else {
                    ok($check->($value), "Assert value is $name");
                }
            }
        } elsif ($ref eq 'ARRAY') {
            # Array
            foreach (@$h) {
                if (ref($_)) {
                    $func->($_);
                } else {
                    ok($check->($_), "Assert value is $name");
                }
            }
        } elsif ($ref eq 'SCALAR') {
            ok($check->($$h), "Assert value is $name");
        }
    };
    return $func;
}

1;
