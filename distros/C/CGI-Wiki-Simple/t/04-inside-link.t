#!/usr/bin/perl -w
use strict;
use vars qw( @good_tests @error_tests );

BEGIN {

  @good_tests = (
    [[ title => 'foo', target => 'foo', mode => 'display' ], "<a href='/wiki/display/foo'>foo</a>", 'Fully specified' ],
    [[ title => 'foo', node => 'foo', mode => 'display' ], "<a href='/wiki/display/foo'>foo</a>", 'target <-> node' ],
    [[ title => 'foo', target => 'bar', mode => 'display' ], "<a href='/wiki/display/bar'>foo</a>", 'Different target' ],
    [[ title => 'foo', node => 'bar', mode => 'display' ], "<a href='/wiki/display/bar'>foo</a>", 'Different node' ],
    [[ target => 'bar', mode => 'display' ], "<a href='/wiki/display/bar'>bar</a>", 'Default title via node' ],
    [[ node => 'bar', mode => 'display' ], "<a href='/wiki/display/bar'>bar</a>", 'Default title via target' ],
    [[ target => 'bar' ], "<a href='/wiki/display/bar'>bar</a>", 'Default title,mode via node' ],
    [[ node => 'bar' ], "<a href='/wiki/display/bar'>bar</a>", 'Default title,mode via target' ],
    [[ target => 'bar', mode => 'test' ], "<a href='/wiki/test/bar'>bar</a>", 'Different mode' ],
    [[ target => 'bar', title => '<>', mode => 'test' ], "<a href='/wiki/test/bar'>&lt;&gt;</a>", 'HTML encoding' ],
    [[ target => 'foo::bar', title => '<>', mode => 'test' ], "<a href='/wiki/test/foo%3A%3Abar'>&lt;&gt;</a>", 'URL/HTML encoding' ],
    [[ target => 'foo::bar', title => 'foo::bar', mode => 'test' ], "<a href='/wiki/test/foo%3A%3Abar'>foo::bar</a>", 'URL encoding' ],
  );

  @error_tests = ();
};

use Test::More tests => 2+scalar @good_tests*2 + scalar @error_tests*2;

BEGIN{ use_ok('CGI::Wiki::Simple') };

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ };};

my $wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {}, script_name => '/wiki' } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "The created wiki");

for (@good_tests) {
  my ($args,$result,$name) = @$_;
  is( $wiki->inside_link(@$args),$result,$name );
  is_deeply(\@warnings,[],"No warnings raised");
  @warnings = ();
};

for (@error_tests) {
  is_deeply(\@warnings,[],"No warnings raised");
  @warnings = ();
};
