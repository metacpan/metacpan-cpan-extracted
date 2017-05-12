#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
plan 'no_plan';

use Config::Identity;
use Config::Identity::GitHub;
use Config::Identity::PAUSE;

my $h0 = File::Spec->catdir(qw/ t assets h0 /);
my $h1 = File::Spec->catdir(qw/ t assets h1 /);

is( Config::Identity->best( 'test' => $h0 ), File::Spec->catfile( $h0, '.test-identity' ) );
is( Config::Identity->best( 'test' => $h1 ), File::Spec->catfile( $h1, '.test' ) );

my ( %cfg );

%cfg = Config::Identity->parse( <<'_END_' );
    # Xyzzy
apple a1
banana b2

    

_END_

cmp_deeply( \%cfg, {qw/ apple a1 banana b2 /} );

{
    local $ENV{CI_PAUSE_STUB} = 'pause-alternate';
    local $Config::Identity::home = File::Spec->catfile(qw/ t assets pause /);
    my %identity = Config::Identity::PAUSE->load_check;
    cmp_deeply( \%identity, {qw/ username alternate user alternate password xyzzy /} );
}

{
    local $Config::Identity::home = File::Spec->catfile(qw/ t assets pause /);
    my $expected = {qw/ username alternate password xyzzy /};
    my %got;

    %got = Config::Identity->load_check('pause-alternate',[qw/username password/]);
    cmp_deeply( \%got, $expected, "load_check with arrayref" );

    my %identity = Config::Identity->load_check('pause-alternate',sub {});
    cmp_deeply( \%identity, $expected, "load_check with coderef" );

    eval { Config::Identity->load_check('pause-alternate', "notfound1") };
    like( $@, qr/^Argument to check keys must be an arrayref or coderef/, "load_check croaks on bad argument" );

    eval { Config::Identity->load_check('pause-alternate',[qw/notfound1 password/]) };
    like( $@, qr/^Missing required field: notfound1/, "load_check detected missing field" );

    eval { Config::Identity->load_check('pause-alternate',[qw/notfound1 notfound2 password/]) };
    like( $@, qr/^Missing required fields: notfound1 notfound2/, "load_check detected missing fields" );

    my $checker = sub {
        is( "$_", "$_[0]", "checker sub has same \$_ and \$[0]" );
        cmp_deeply( $_, $expected, "checker sub has expected fields in \$_" );
        return "notfound1"; # fake error
    };

    eval { Config::Identity->load_check('pause-alternate', $checker) };
    like( $@, qr/^Missing required field: notfound1/, "load_check detected missing field (from checker sub)" );

}

SKIP: {
    skip 'GnuPG not available' unless my $gpg = Config::Identity->GPG;

    my $homedir = File::Spec->catfile(qw/ t assets gpg /);

    # Per https://rt.cpan.org/Public/Bug/Display.html?id=112569 gpg 2.1.x
    # needs a key format migration run on test data before tests
    {
        my $gpg_v = qx/$gpg --version/;
        my ($first,$second) = $gpg_v =~ /^gpg \s+ \([^)]+\) \s+ (\d+) \. (\d+)/mx;
        if ( $first && $second && ($first > 2 || ($first == 2 && $second > 0))) {
            qx/$gpg --homedir $homedir --list-secret-keys/;
        }
    }

    $ENV{CI_GPG_ARGUMENTS} =
        '--no-secmem-warning ' .
        '--no-permission-warning ' .
        '--homedir ' . $homedir
    ;

    is( Config::Identity->read( File::Spec->catfile(qw/ t assets test.asc /) ), <<_END_ );
1234567890xyzzy

# 123
_END_

    if ($ENV{RELEASE_TESTING}) {
        is( Config::Identity->read( File::Spec->catfile(qw/ t assets test.gpg /) ), <<_END_ );
ABCDEFGHIJKLMNOPQRSTUVWXYZ

1 2 3 4 5 6 7 8 9 0

.
_END_
    }

    use Config::Identity::GitHub;
    {
        local $Config::Identity::home = File::Spec->catfile(qw/ t assets github /);
        my %identity = Config::Identity::GitHub->load_check;
        cmp_deeply( \%identity, {qw/ login alice token hunter2 /} );
    }

    use Config::Identity::PAUSE;
    {
        local $Config::Identity::home = File::Spec->catfile(qw/ t assets pause /);
        my %identity = Config::Identity::PAUSE->load_check;
        cmp_deeply( \%identity, {qw/ username alice user alice password hunter2 /} );
    }
    {
        local $Config::Identity::home = File::Spec->catfile(qw/ t assets pause-username /);
        my %identity = Config::Identity::PAUSE->load_check;
        cmp_deeply( \%identity, {qw/ username alice user alice password hunter3 /} );
    }
}

1;
