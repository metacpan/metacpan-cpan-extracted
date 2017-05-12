use Test::More;
use File::Find;
use strict;

@ARGV = ();
find( sub { push @ARGV, $File::Find::name if /^[a-z].*\.p(m|od)$/ }, 'blib' );

plan tests => scalar @ARGV;

# check that no file contains a FIXME / XXX
my $fixme = 0;
while (<>) {
    $fixme++ if /\bFIXME\b/;
    next if $ARGV =~ /currency|roman/; # currency and romain contain XXX
    $fixme++ if /\bXXX\b/;
}
continue {
    if (eof) {
        is( $fixme, 0, "No FIXME/XXX found in $ARGV" );
        $fixme = 0;
    }
}

