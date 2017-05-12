use Test::More tests => 19;
use strict;

use File::Spec::Functions;
my $dir;
BEGIN { $dir = catdir qw( t lib ); }
use lib $dir;

{ eval "require LWP::UserAgent;"; }
my $has_lwp = !$@;

# test the helper subs
is( Acme::MetaSyntactic::RemoteList::tr_accent('a é ö ì À + ='),
    'a e o i A + =', 'tr_accent' );
is( Acme::MetaSyntactic::RemoteList::tr_nonword('a;Aö"1À +='),
    'a_A__1____', 'tr_nonword' );

# theme without a remote list
use Acme::MetaSyntactic::test_ams_list();
ok( ! Acme::MetaSyntactic::test_ams_list->has_remotelist(),
    "No remote list for tets_ams_list" );
is( Acme::MetaSyntactic::test_ams_list->source(), undef, 'test_ams_list source() empty' );

my $list = Acme::MetaSyntactic::test_ams_list->new();
ok( ! $list->has_remotelist(), 'No remote list for test_ams_list object' );
is( $list->source(), undef, 'test_ams_list object source() empty' );

# try to get the list anyway
SKIP: {
    skip "LWP::UserAgent required to test remote_list()", 1 if !$has_lwp;
    is( $list->remote_list(), undef, 'No remote list for test_ams_list object' );
}

# default version of extract
is( $list->extract( 'zlonk aieee' ), 'zlonk aieee', "Default extract()" );


# theme with a remote list
use Acme::MetaSyntactic::test_ams_remote();
ok( Acme::MetaSyntactic::test_ams_remote->has_remotelist(),
    'test_ams_remote has a remote list' );
is( Acme::MetaSyntactic::test_ams_remote->source(),
    'http://www.perdu.com/',
    'test_ams_remote source()'
);

my $remote = Acme::MetaSyntactic::test_ams_remote->new();
ok( $remote->has_remotelist(), 'test_ams_remote object has a remote list' );
is( $remote->source(), 'http://www.perdu.com/',
    'test_ams_remote source()' );

# these tests must be run after the test module has been loaded
END {
    ok( Acme::MetaSyntactic::dummy->has_remotelist,
        'dummy has a remote list' );

    my $dummy = Acme::MetaSyntactic::dummy->new();
    ok( $dummy->has_remotelist, 'dummy object has a remote list' );

    my $content = << 'EOC';
list
* meu
* zo
* bu
* gä
EOC
    is_deeply( [ Acme::MetaSyntactic::dummy->extract($content) ],
        [qw( meu zo bu ga )], 'extract() class method' );
    # this is now a generated method
    is_deeply( [ $dummy->extract($content) ],
        [qw( meu zo bu ga )], 'extract() object method' );

    SKIP: {
        skip "LWP::UserAgent required to test remote_list()", 3 if !$has_lwp;
        is_deeply(
            [ sort $dummy->name(0) ],
            [ sort $dummy->remote_list() ],
            'Same "remote" list'
        );

        is_deeply(
            [ sort $dummy->name(0) ],
            [ sort Acme::MetaSyntactic::dummy->remote_list() ],
            'Same "remote" list'
        );

        # test failing network
        $Acme::MetaSyntactic::dummy::Remote{source} = 'fail';
        is_deeply( [ $dummy->remote_list() ],
            [], 'Empty list when network fails' );
    }

}

# a test package
package Acme::MetaSyntactic::dummy;
use strict;

use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
use Cwd;

# data regarding the updates
our %Remote = (
    source  => 'file://' . cwd() . '/t/remote',
    extract => sub {
        my $content = shift;
        my @items       =
            map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            $content =~ /^\* (.*?)\s*$/gm;
        return @items;
    },
);

__PACKAGE__->init();
1;

__DATA__
# names
bonk clank_est eee_yow swoosh urkk wham_eth z_zwap
