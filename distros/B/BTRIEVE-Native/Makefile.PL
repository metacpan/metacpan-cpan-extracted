use ExtUtils::MakeMaker;

use Config;

my %o =
(
  NAME          => 'BTRIEVE::Native'
, VERSION_FROM  => 'Native.pm'
, ABSTRACT_FROM => 'Native.pm'
, AUTHOR        => 'Steffen Goeldner'
);
$Config{cc} eq 'bcc32'
? ( $o{IMPORTS} = { BTRCALL => 'wbtrv32.BTRCALL'} )
: ( $o{LIBS}    =              'wbtrv32'          )
;
WriteMakefile( %o );
