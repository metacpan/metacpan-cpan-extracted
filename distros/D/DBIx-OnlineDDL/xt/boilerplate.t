#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use File::Find;

my @pm_files;
find(sub { push @pm_files, $File::Find::name if /\.pm$/}, 'lib');

plan tests => 2 + @pm_files;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    # Common checks
    %regex = (
        'fake module names' => qr/Other::CPAN::Modules|Some::Module|Another::Similar::One|Foo::Bar::Module/,
        'FIXME'             => qr/FIXME/,
        %regex,
    );

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for sort keys %violated;
    }
    else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'stub use lines'  => qr/^\#use /m,
        'stub definition' => qr/A thingy|Does this thing/,
        'stub headers'    => qr/head2 (attr|method)/,
    );
}

not_in_file_ok('Makefile.PL');
not_in_file_ok('CHANGES');
module_boilerplate_ok($_) for @pm_files;

done_testing;
