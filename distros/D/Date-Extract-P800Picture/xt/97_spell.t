# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.014;
use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

our $VERSION = v1.1.7;
if ( !eval { require Test::Spelling; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{Test::Spelling required to check spelling of POD};
}
Test::Spelling::add_stopwords(<DATA>);
Test::Spelling::all_pod_files_spelling_ok();

__DATA__
DateTime
EXIF
Ipenburg
JFIF
JPG
Noncommercial
RT
Readonly
Sony
Unported
YMDH
cpan
exif
org
rt
