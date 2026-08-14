use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Context/Singleton.pm',
    'lib/Context/Singleton/Exception/Deduced.pm',
    'lib/Context/Singleton/Exception/Invalid.pm',
    'lib/Context/Singleton/Exception/Nondeducible.pm',
    'lib/Context/Singleton/Frame.pm',
    'lib/Context/Singleton/Frame/Builder/Array.pm',
    'lib/Context/Singleton/Frame/Builder/Base.pm',
    'lib/Context/Singleton/Frame/Builder/Hash.pm',
    'lib/Context/Singleton/Frame/Builder/Value.pm',
    'lib/Context/Singleton/Frame/DB.pm',
    'lib/Context/Singleton/Frame/Deducer.pm',
    'lib/Context/Singleton/Frame/Deducer/Notifying.pm',
    'lib/Context/Singleton/Frame/Promise.pm',
    'lib/Context/Singleton/Frame/Promise/Builder.pm',
    'lib/Context/Singleton/Frame/Promise/Rule.pm',
    'lib/Context/Singleton/Singleton.pm',
    'lib/Context/Singleton/Tutorial.pod',
    't/Context-Singleton-Frame-Builder-Array.t',
    't/Context-Singleton-Frame-Builder-Base.t',
    't/Context-Singleton-Frame-Builder-Hash.t',
    't/Context-Singleton-Frame-Builder-Value.t',
    't/Context-Singleton-Frame-Promise.t',
    't/Context-Singleton-Frame.t',
    't/Context-Singleton.t',
    't/builder-array.t',
    't/contrive-class.t',
    't/exporting.t',
    't/frame-call-depth.t',
    't/frame-hierarchy-depth.t',
    't/frame-hierarchy-parent.t',
    't/frame-hierarchy-root.t',
    't/lib/Examples/Context/Singleton.pm',
    't/lib/Examples/Context/Singleton/Frame.pm',
    't/lib/Examples/Context/Singleton/Frame/Builder.pm',
    't/lib/Examples/Context/Singleton/Frame/Promise.pm',
    't/lib/Sample/Context/Singleton.pm',
    't/lib/Sample/Context/Singleton/001/constant.pm',
    't/lib/Sample/Context/Singleton/001/foo.pm',
    't/lib/Sample/Context/Singleton/001/sum.pm',
    't/lib/Sample/Context/Singleton/002/foo.pm',
    't/lib/Sample/Context/Singleton/Contrive/Class.pm',
    't/lib/Sample/Context/Singleton/Frame.pm',
    't/lib/Sample/Context/Singleton/Frame/Builder/Base.pm',
    't/lib/Shared/Example/Context/Singleton.pm',
    't/lib/Test/Spec/Util.pm',
    't/test-helper.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
