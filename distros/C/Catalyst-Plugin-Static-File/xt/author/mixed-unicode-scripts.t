use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = ( 'ASCII' );

my @files = (
    'lib/Catalyst/Plugin/Static/File.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-catalyst.t',
    't/20-psgi-mime.t',
    't/21-psgi-xsendfile.t',
    't/22-psgi-etag.t',
    't/23-psgi-conditional-get.t',
    't/lib/App.pm',
    't/lib/App/Controller/Root.pm',
    't/static/hello.txt'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
