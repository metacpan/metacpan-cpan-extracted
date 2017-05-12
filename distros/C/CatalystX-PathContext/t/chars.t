#!perl

use strict;
use warnings;

use File::Find;
use FindBin;
use Test::More;

if ( ! $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

my $base_path = "$FindBin::Bin/../";
my %file_of;
find(
    sub {
        if ( $File::Find::name =~ m{ \. t | p[l|m] \z}xms ) {
            $file_of{$File::Find::name} = ();
        }
    },
    $base_path,
);

plan( tests => 4 * keys %file_of );

for my $file (sort { $a cmp $b } keys %file_of) {
    open( my $fh, '<', $file) or die "cannnot open file >$file<";
    local $/;
    my $text = <$fh>;
    close $fh;

    ok( $text !~ m{[\x0D]}xmsg, ">$file< has no DOS line ending (CR)");
    ok( $text !~ m{[\x09]}xmsg, ">$file< uses no TABs");
    ok(
        $text !~ m{[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]}xmsg,
        ">$file< is free of shit",
    );
    ok( $text !~ m{[ ][\x0D\x0A]}xmsg , ">$file< has no trailing space");
}
