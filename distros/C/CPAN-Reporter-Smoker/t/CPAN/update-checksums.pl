#!/usr/bin/env perl
use strict;
use warnings;
use CPAN::Checksums qw/updatedir/;
use File::Find;

sub wanted { 
    return unless 
        -d $File::Find::name &&
        $File::Find::name =~ m{authors/id/./../.+$};
    print "$File::Find::name\n";    
    updatedir( $File::Find::name );
}

find( { wanted => \&wanted, no_chdir => 1 }, q{.} );
