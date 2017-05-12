# t/04-parser.t
#
# This test script is for the optional external parsing of
# configuration files using Config::Merge.
#
# If you're supporting Config::Merge in your app, be sure to look at the
# semantics here. This implementation creates symlinks for keys that end
# with an '@' symbol.
#
# vim: syntax=perl

BEGIN {
    use vars qw( $req_cm_err );
    eval 'require Config::Merge;';
    $req_cm_err = $@;
}

use Test::More tests => 8;
use DateTime;
use Path::Class;
use Data::Dumper;
use Carp qw(confess);

my $ver1 = 'dbfc699b2bfaf60b0c62191d82a31bb57f75d282';

my $gitdb = 't/05-config-merge.git';

dir($gitdb)->rmtree;

package MyConfig;

use Moose;
extends 'Config::Versioned';

use Data::Dumper;

sub parser {
    my $self     = shift;
    my $params   = shift;
    my $filename = '';

    my $cm    = Config::Merge->new('t/05-config-merge.d');
    my $cmref = $cm->();

    my $tree = $self->cm2tree($cmref);

    $params->{comment} = 'import from ' . $filename . ' using Config::Merge';

    if ( not $self->commit( $tree, $params ) ) {
        die "Error committing import from $filename: $@";
    }
}

sub cm2tree {
    my $self = shift;
    my $cm   = shift;
    my $tree = {};
    if ( ref($cm) eq 'HASH' ) {
        my $ret = {};
        foreach my $key ( keys %{$cm} ) {

            # If the key is appended with an '@' character, treat it
            # as a symbolic link.
            if ( $key =~ m/(.+)[@]$/ ) {
                my $newkey = $1;
                my $temp   = $self->cm2tree( $cm->{$key} );
                $ret->{$newkey} = \$temp;
            }
            else {
                $ret->{$key} = $self->cm2tree( $cm->{$key} );
            }
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

SKIP: {
    skip "Config::Merge not installed", 8 if $req_cm_err;
    my $cfg = MyConfig->new(
        {
            dbpath      => $gitdb,
            commit_time => DateTime->from_epoch( epoch => 1240341682 ),
            author_name => 'Test User',
            author_mail => 'test@example.com',
            autocreate  => 1,
        }
    );

    ok( $cfg, 'created MyConfig instance' );
    is( $cfg->version, $ver1, 'check version of HEAD' );

    is( $cfg->get('db.hosts.1'),    'host2', 'Check param db.hosts.1' );
    is( $cfg->get('db.port.host2'), '789',   'Check param db.hosts.1' );

    my @attrlist = sort( $cfg->listattr('db.port') );
    is_deeply(
        \@attrlist,
        [ sort(qw( host1 host2 )) ],
        'Check attr list at db.port'
    );

    my @getlist = $cfg->get('db.hosts');
    is_deeply( \@getlist, [qw( 0 1 )], 'Check that get() returns array' );
    my $sym = $cfg->get('db.symgroup.sym1');
    is( ref($sym), 'SCALAR', 'check value of symlink is anon ref to scalar' );
    is( ${$sym}, 'conn1:new.location', 'check target of symlink' );
}
