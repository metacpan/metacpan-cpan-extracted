#! perl

use Test2::V0;

use App::mkpkgconfig::PkgConfig::Entry;
use constant Keyword  => 'App::mkpkgconfig::PkgConfig::Entry::Keyword';
use constant Variable => 'App::mkpkgconfig::PkgConfig::Entry::Variable';

subtest constant => sub {
    my $kwd = Keyword->new( 'Version', '1' );
    is( $kwd->name,  'Version', 'name' );
    is( $kwd->value, '1',       'value' );
    is( [ $kwd->depends ], [], 'depends' );
};

subtest 'one dependency' => sub {
    my $kwd = Keyword->new( 'Version', '${version}' );
    is( $kwd->name,  'Version', 'name' );
    is( $kwd->value, '${version}',       'value' );
    is(
        [ $kwd->depends ],
        bag {
            item 'version';
            end;
        },
        'depends'
    );
};

subtest 'two dependencies' => sub {
    my $kwd = Keyword->new( 'Version', '${version}-${subversion}' );
    is( $kwd->name,  'Version', 'name' );
    is( $kwd->value, '${version}-${subversion}',       'value' );
    is(
        [ $kwd->depends ],
        bag {
            item 'version';
            item 'subversion';
            end;
        },
        'depends'
    );
};

done_testing;
