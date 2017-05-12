use strict;
use warnings;
use English;
use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Spelling required to check spelling of POD';
    plan( skip_all => $msg );
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
