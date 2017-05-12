# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use lib 't/lib';
use App::rlibperl::Tester;
use Test::More;

my @tests = (
  ['local::lib' => [ [qw(lib perl5), $ARCHNAME], [qw(lib perl5)] ] ],
  [ same   => [ ['lib'] ] ],
  [ parent => [ ['lib'] ] ],
);

plan tests => scalar @tests;

foreach my $test ( @tests ) {
  my ($structure, $dirs) = @$test;
  my $tree = named_tree( $structure );

  my @def = get_inc();

  my @ext = $^O eq 'MSWin32'
    ? map { $_ = catdir(Win32::GetShortPathName($tree->{root}), @$_); s-\\-/-g; $_ } @$dirs
    : map { catdir($tree->{root}, @$_) } @$dirs;

  my @got = get_inc($tree->{rlibperl});

  is_deeply(
    \@got,
    [@ext, @def],
    "rlibperl added expected dirs to inc for '$structure'"
  )
    or diag explain {
      def => \@def,
      ext => \@ext,
      got => \@got,
    };
}
