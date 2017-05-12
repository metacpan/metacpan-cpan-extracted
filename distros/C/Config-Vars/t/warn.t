#!/perl -I..

use strict;
use lib 't';
use Test::More tests => 4;

my @warnings;
BEGIN {$SIG{__WARN__} = sub {push @warnings,  join '', @_} }

use cvWarn;
SKIP: {
    skip 'Readonly installed', 4  if $Config::Vars::RO_ok;

    is scalar @warnings, 3     => 'Correct number of warnings';
    like $warnings[0], qr/^Readonly not available, making \$cat read\/write at/        => 'warning 1';
    like $warnings[1], qr/^Readonly not available, making \@dogs read\/write at/       => 'warning 2';
    like $warnings[2], qr/^Readonly not available, making \%hamsters read\/write at/   => 'warning 3';
}
