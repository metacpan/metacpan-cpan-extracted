use Test::More tests => 7;
use strict;
use Cwd;

{eval "require LWP::UserAgent;";}
my $has_lwp = !$@;

# these tests must be run after the test module has been loaded
END {
    # test for multiple remote lists
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
        $Acme::MetaSyntactic::dummy::Remote{source}
            = [ 'fail', 'file://' . cwd() . '/t/remote2' ];
        is_deeply( [ $dummy->remote_list() ],
            [], 'Empty list when network fails' );
    }

}

# a test package (with 2 lists)
package Acme::MetaSyntactic::dummy;
use strict;

use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
use Cwd;

# data regarding the updates
our %Remote = (
    source =>
        [ 'file://' . cwd() . '/t/remote1', 'file://' . cwd() . '/t/remote2' ],
    extract => sub {
        my $content = shift;
        my @items   =
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
