# t/08-sha.t
#
# This test script is for the optional external parsing of
# configuration files using Config::Merge.
#
# It specifically tries to address a problem I was having with the SHA1
# hash working correctly on my Mac but not on Ubuntu
#
# vim: syntax=perl

BEGIN {
    use vars qw( $req_cm_err );
    eval 'require Config::Merge;';
    $req_cm_err = $@;
}

use Test::More tests => 6;
use DateTime;
use Path::Class;
use Data::Dumper;
use Carp qw(confess);

my $ver1 = '777fd3790995c010b20a9d7af47ec4d72d472b3e';

my $gitdb1   = 't/08-sha-1.git';
my $cfgdata1 = 't/08-sha-1.conf';
my $gitdb2   = 't/08-sha-2.git';
my $cfgdir2   = 't/08-sha-2.d';

dir($gitdb1)->rmtree;
dir($gitdb2)->rmtree;

package MyConfig2;

use Moose;

extends 'Config::Versioned';

use Data::Dumper;

sub parser {
    my $self     = shift;
    my $params   = shift;
    my $filename = '';

    my $cm    = Config::Merge->new($cfgdir2);
    my $cmref = $cm->();

    my $tree = $self->cm2tree($cmref);

    $params->{comment} = 'import from  using Config::Merge';

    if ( not $self->commit( $tree, $params ) ) {
        die "Error committing import from $filename: $@";
    }
}

sub cm2tree {
    my $self = shift;
    my $cm   = shift;

    if ( ref($cm) eq 'HASH' ) {
        my $ret = {};
        foreach my $key ( keys %{$cm} ) {
            $ret->{$key} = $self->cm2tree( $cm->{$key} );
        }
        return $ret;
    }
    elsif ( ref($cm) eq 'ARRAY' ) {
        my $ret = {};
        my $i   = 0;
        foreach my $entry ( @{$cm} ) {
            $ret->{ $i++ } = $self->cm2tree($entry);
        }
        return $ret;
    }
    else {
        return $cm;
    }
}

package main;

my $cfg1 = Config::Versioned->new(
    {   dbpath      => $gitdb1,
        autocreate  => 1,
        filename    => $cfgdata1,
#        path        => [qw( t )],
        commit_time => DateTime->from_epoch( epoch => 1240341682 ),
        author_name => 'Test User',
        author_mail => 'test@example.com',
    comment => 'import from  using Config::Merge',  # use this string to match other one we're debugging
    }
);
ok( $cfg1, 'cfg1 - created instance' );
is( $cfg1->version,           $ver1, 'cfg1 - check version of HEAD' );
is( $cfg1->get('port.host1'), '123', 'cfg1 - check param port.host1' );

SKIP: {
    skip "Config::Merge not installed", 3 if $req_cm_err;
    my $cfg2 = MyConfig2->new(
        {   dbpath      => $gitdb2,
            commit_time => DateTime->from_epoch( epoch => 1240341682 ),
            author_name => 'Test User',
            author_mail => 'test@example.com',
            autocreate  => 1,
        }
    );

    ok( $cfg2, 'cfg2 - created instance' );
    is( $cfg2->version, $ver1, 'cfg2 - check version of HEAD' );

    is( $cfg2->get('port.host1'), '123', 'cfg2 - check param port.host1' );
}
