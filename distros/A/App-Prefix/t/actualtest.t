#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);
use IPC::Run qw(run timeout);


#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "Author tests not required for installation" );
#}

my $perl = $^X;
# use catfile for win32 safety
my $prefix         = catfile("bin", "prefix" );
my $one_word_file  = catfile("t", "one_word.dat");
my $two_word_file  = catfile("t", "two_words.dat");
my $sample_file    = catfile("t", "sample.dat");

my @out = like_btick( $perl, $prefix, "-host", $sample_file );
cmp_ok( scalar(@out), '==', 5, "prefix: read t/sample.dat" );
cmp_ok( $out[0], '=~', '.* OK: System operational', "line from test file looks as expected" );

# set up command line stuff specifically for IPC::Run
my @tests = (

    [ [$perl, $prefix,                        $one_word_file], 'sanguine$'],   # no option, no change
    [ [$perl, $prefix, "-host",               $one_word_file], '.* sanguine$' ], # test -host
    [ [$perl, $prefix, "-host", "-suffix",    $one_word_file], 'sanguine .*' ],  # test -suffix

    [ [$perl, $prefix, "-version"                           ], 'prefix [0-9.]+$' ],   # test -version

    [ [$perl, $prefix, "-text=A",             $one_word_file], 'A sanguine$' ],
    [ [$perl, $prefix, "-text=A", "-suffix",  $one_word_file], 'sanguine A$' ],   # test -text=A
    [ [$perl, $prefix, "-text=A", "-no-space",$one_word_file], 'Asanguine$' ],   # test -no-space
    [ [$perl, $prefix, "-text=A", "-quote",   $one_word_file], 'A \'sanguine\'$' ],   # test -quote

    [ [$perl, $prefix, "-timestamp",          $one_word_file], '[-:0-9 ]+ sanguine$'],   # 2013-10-16 23:23:35 sanguine
    [ [$perl, $prefix, "-utimestamp",         $one_word_file], '[-:0-9. ]+ sanguine$'],   # 2013-10-16 23:23:35.12345 sanguine

    [ [$perl, $prefix, "-utimestamp",         $one_word_file], '[-:0-9. ]+ sanguine$'],   # 2013-10-16 23:23:35 sanguine
    [ [$perl, $prefix, "-elapsed",            $one_word_file], '[0-9.]+ \S+ elapsed sanguine$'],   

    [ [$perl, $prefix,                        $two_word_file], 'cat--dog' ],      # basic test, no changes
    [ [$perl, $prefix, "-elapsed",            $two_word_file], '([0-9.]+ \S+ elapsed (cat|dog)(--)?){2}'],   
    [ [$perl, $prefix, "-elapsed", "-raw",    $two_word_file], '([0-9.]+ secs elapsed (cat|dog)(--)?){2}'],   
    [ [$perl, $prefix, "-diffstamp",          $two_word_file], '([0-9.]+ \S+ diff (cat|dog)(--)?){2}'],   
    [ [$perl, $prefix, "-diffstamp", "-raw",  $two_word_file], '([0-9.]+ secs diff (cat|dog)(--)?){2}'],   
);

for my $t (@tests) {
    my ($cmd_ref, $regex) = @$t;
    my @cmd = @$cmd_ref;
    my @lines = like_btick( @cmd );
    my $line = join( "--", @lines );  

    my $showcmd = join(" ", @cmd);
    $showcmd =~ s/\s+/ /g;
    ok( $line =~ /^$regex$/, "output of $showcmd =~ '$regex' ($line)" ); 
}
done_testing();
sub like_btick {
    my @cmd = @_;
    my ($in, $out, $err) = ("", "", "");
    run( \@cmd, \$in, \$out, \$err, timeout(2)) || ($err .= " (timeout)");
    diag( $err ) if $err;
    return split(/\n/, $out); # no newlines, just lines
}

