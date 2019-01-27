use strict;
use Test::More;
use Test::Exception;
use Acme::AtIncPolice;

lives_ok(sub {push @INC, "lib"}, "Acme::AtINCPolice no says");

throws_ok(sub {
    push @INC, sub {
        my ($coderef, $filename) = @_;
        my $modfile = "lib/$filename";
        if (-f $modfile) {
            open my $fh, '<', $modfile;
            return $fh;
        }
    };
}, qr/^Acme::AtIncPolice does not allow contamination of \@INC/);

done_testing;