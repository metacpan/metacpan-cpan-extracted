# t/04-parser.t
#
# This test script is for the optional external parsing of foreign
# configuration files.
#
# vim: syntax=perl

use Test::More tests => 2;
use DateTime;
use Path::Class;

my $ver1 = '6286dd48b488848e6498b82acc081000e3e375bf';

our $gitdb = 't/04-parser.git';
dir($gitdb)->rmtree;

package MyConfig;

use Moose;

extends 'Config::Versioned';

sub parser {
    my $self   = shift;
    my $params = shift;
    $params->{comment} = 'import from my perl hash';

    my $cfg = {
        group1 => {
            subgroup1 => {
                param1 => 'val1',
                param2 => 'val2',
            },
        },
        group2 => {
            subgroup1 => {
                param3 => 'val3',
                param4 => 'val4',
            },
        },
    };

    # pass original params, appended with a comment string for the commit
    $self->commit( $cfg, $params );

}

package main;

my $cfg = MyConfig->new(
    {
        dbpath      => $gitdb,
        commit_time => DateTime->from_epoch( epoch => 1240341682 ),
        author_name => 'Test User',
        author_mail => 'test@example.com',
        autocreate  => 1,
    }
);
ok( $cfg, 'created MyConfig instance with parser' );
is( $cfg->version, $ver1, 'check version of HEAD' );

