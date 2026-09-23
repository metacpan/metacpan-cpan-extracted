#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The word list (TEST-LIST). The tests hold the embedded words of
# App::FuguSeed::List and the share file to the pinned digest of the
# source list (TEST-LIST-1). They prove the properties of the list
# (TEST-LIST-2) and the contract of the module (LIST-MODULE-3).

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use Digest::SHA      ();
use Module::CoreList ();
use FindBin          qw($RealBin);
use lib "$RealBin/../../lib";
use App::FuguSeed::List;

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

my $class  = 'App::FuguSeed::List';
my $share  = 'share/fuguseed/english.txt';
my $digest = App::FuguSeed::List::DIGEST();
my @words  = $class->words;

# TEST-LIST-1: the two copies of the list. The pinned digest is the
# one number that holds both to the source list.
like( $digest, qr/\A[0-9a-f]{64}\z/, 'DIGEST is lower-case hex' );

my $embedded = Digest::SHA::sha256_hex( join q{}, map { "$_\n" } @words );
is( $embedded, $digest, 'the embedded words give the pinned digest' );

open my $fh, '<', $share or BAIL_OUT("$share: $!");
binmode $fh;
my $file = Digest::SHA->new(256)->addfile($fh)->hexdigest;
close $fh or BAIL_OUT("close $share: $!");
is( $file, $digest, "$share gives the pinned digest" );

# TEST-LIST-2: LIST-SOURCE-2 and LIST-SOURCE-3 on the embedded words.
is( scalar @words, 2048, 'the embedded list holds 2048 words' );

my @shape = grep { !/\A[a-z]{3,8}\z/ } @words;
is( "@shape", q{}, 'each word holds 3 to 8 lower-case ASCII letters' );

my %word;
my @twice = grep { $word{$_}++ } @words;
is( "@twice", q{}, 'the words are unique' );

is_deeply( \@words, [ sort @words ], 'the words are sorted' );

my %four;
my @clash = grep { $four{ substr $_, 0, 4 }++ } @words;
is( "@clash", q{}, 'the first four letters of each word are unique' );

# LIST-MODULE-3: the contract of the three functions.
is( $class->word(0),          'abandon', 'word(0) is the first word' );
is( $class->word(2047),       'zoo',     'word(2047) is the last word' );
is( $class->index('abandon'), 0,         'index gives 0 for the first word' );
is( $class->index('zoo'),     2047,      'index gives 2047 for the last word' );

my @mismatch = grep { $class->index( $class->word($_) ) != $_ } 0 .. $#words;
is( "@mismatch", q{}, 'word and index agree for each of the 2048 words' );

my $above = $class->word(2048);
is( $above, undef, 'an index above the list gives undef' );

my $below = $class->word(-1);
is( $below, undef, 'an index below the list gives undef' );

my $empty = $class->word(undef);
is( $empty, undef, 'an absent index gives undef' );

my $unknown = $class->index('fugu');
is( $unknown, undef, 'an unknown word gives undef' );

my $none = $class->index(undef);
is( $none, undef, 'an absent word gives undef' );

# The ERRORS section of List.pod: the signature of each method
# requires one argument, so a call without one dies.
eval { $class->word };
like( $@, qr/Too few arguments/, 'word dies on a call with no argument' );

eval { $class->index };
like( $@, qr/Too few arguments/, 'index dies on a call with no argument' );

# LIST-MODULE-2: scripts/pack embeds the module in fuguseed-qr, so
# the module loads no module from outside this repository but the
# core of perl 5.34. Digest::SHA, the one module that this test adds,
# is core as well. The child gets no PERL5LIB and no PERL5OPT of this
# environment. PERL5OPT loads a module through -M, and that module
# writes a false %INC entry. PERL5LIB writes no entry: it adds a
# directory to @INC, so a module can come from outside this checkout.
delete local @ENV{qw(PERL5LIB PERL5OPT)};

open my $ph, '-|', $^X, '-Ilib', "-M$class", '-e',
    'print "$_\n" for sort keys %INC'
    or BAIL_OUT("$^X: $!");
my @loaded = <$ph>;
close $ph or BAIL_OUT("close $^X: status $?");
chomp @loaded;

( my $key = "$class.pm" ) =~ s{::}{/}g;
my @self = grep { $_ eq $key } @loaded;
is( scalar @self, 1, "the child perl loads $key" );

my @outside;
for my $path (@loaded) {
	( my $module = $path ) =~ s/\.pm\z//;
	$module                =~ s{/}{::}g;
	next if $module        =~ /\AApp::FuguSeed::/;
	push @outside, $module
	    unless Module::CoreList::is_core( $module, undef, 5.034 );
}
is( "@outside", q{}, 'the module loads core modules of perl 5.34 only' );

done_testing();
