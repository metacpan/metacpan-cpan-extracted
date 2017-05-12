package Purge;
use strict; use warnings;

use base 'Exporter';
use File::Find;

our @EXPORT = qw( purge_dir strip_copyright strip_shebang strip_build_dir );

sub purge_dir {
}

sub real_purge_dir {
    my $doomed_dir = shift;

    return unless -d $doomed_dir;

    my $purger = sub {
        my $name = $_;

        if    ( -f $name ) { unlink $name; }
        elsif ( -d $name ) { rmdir $name;  }
    };

    finddepth( $purger, $doomed_dir );
    rmdir $doomed_dir;
}

sub strip_copyright {
    my $line = shift;
    $line    =~ s/\(C\)\s+\d+//;
    return $line;
}

sub strip_shebang {
    my $line = shift;
    $line    =~ s/^\s*#!.*//;
    return $line;
}

sub strip_build_dir {
    my $line = shift;

    $line    =~ s{`\S+(docs\W)}{`$1};                # master Gantry::Conf file
    $line    =~ s{dbname=\S+app\.db}{dbname=app.db}; # app.db sqlite database

    return $line;
}

