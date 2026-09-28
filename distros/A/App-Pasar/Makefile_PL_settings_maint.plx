use strict;
use warnings;

sub {
    my ($opt) = @_;

    $opt->{README_FROM} = 'script/pasar';

    $opt->{dist}{COMPRESS} = q{sh -c '7z a -tgzip -mx=9 -mfb=258 -mpass=15 -sdel -bso0 -bsp2 -- "$$1.gz" "$$1"' 7z-gzip};
}
