use strict;

use Test::More;
use Test::Files;
use File::Spec;

use lib 't';
use Purge; # exports real_purge_dir and strip_copyright;

BEGIN {
    eval {
        require Gantry::Init;

        my $path = Gantry::Init->base_root();

        die "no path to templates\n" unless -d $path;

        eval {
            my $test_ship_dir = File::Spec->catdir( qw( t bigtop ) );
            my $abs_path      = File::Spec->rel2abs( $test_ship_dir );
            die "spaces in path\n" if ( $abs_path =~ /\s/ );

        };
        if ( $@ ) {
            plan skip_all => 'Spaces found in build path';
        }
        else {
            plan tests => 1;
        }
    };
    if ( $@ ) {
        plan skip_all => 'Could not find Gantry templates';
    }
}

$ENV{ BIGTOP_REAL_DEF } = 1;

my $play_dir = File::Spec->catdir( qw( AddressBook ) );
my $ship_dir = File::Spec->catdir( qw( t bigtop playship ) );
my $bigtop   = File::Spec->catdir( qw( scripts bigtop ) );

Purge::real_purge_dir( $play_dir );

my $ascii_art = 'family(name,+street,+city)<-child(name,birth_day:date)';

`$^X $bigtop -n AddressBook '$ascii_art'`;

my $sqlite_db = File::Spec->catfile( qw( AddressBook app.db ) );
my $wrapper   = File::Spec->catfile(
        qw( AddressBook html templates genwrapper.tt )
);
unlink $sqlite_db, $wrapper;

compare_dirs_filter_ok(
    $play_dir, $ship_dir, \&stripper, 'bigtop with art'
);

Purge::real_purge_dir( $play_dir );

sub stripper {
    my $line = shift;
    $line    =~ s/^Copyright.*//; # no copyrights or authors
    $line    =~ s/^0\.01 .*//;    # no version lines
                                  # (the one in Changes has time stamp)
    $line    =~ s/version\s+\d\.\d\d//; # bigtop version in Changes file

    if ( $line =~ /E<lt>/ ) {     # remove author lines (emails won't match)
        return '';
    }

    $line   =~ s/^\s*#!.*//; # remove all shebang lines, even indented ones

    $line   =~ s{\S+docs\W}{};                      # master conf file
    $line   =~ s{dbname=\S+app\.db}{dbname=app.db}; # app.db sqlite database
    $line   =~ s{\S+html\W}{};                      # template dirs

    return $line;
}
