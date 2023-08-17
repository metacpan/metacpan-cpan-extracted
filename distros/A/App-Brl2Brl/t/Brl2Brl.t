#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use App::Brl2Brl;

my $brl_obj = App::Brl2Brl->new( {
  from_table_file => "unicode.dis",
  to_table_file => "en-us-brf.dis",
  warn => 1,
} ) or die "Couldn't initialize the braille object.";

ok( defined $brl_obj, ' The new() returned something' );
ok( $brl_obj->isa( 'App::Brl2Brl' ), " It's class is App::Brl2Brl" );
my $in = "⠁⠃⠉⠂";
my $out = $brl_obj->switch_brl_char_map( $in );
ok( $out =~ /ABC1/, ' The switch_brl_char_map works.' );

# now test that LOUIS_TABLEPATH works. We set a bogus path
# in it so expect an exception containing the bogus path.
$ENV{LOUIS_TABLEPATH} = '/i/like/eating/weevils';
throws_ok
    {
        my $brl_obj = App::Brl2Brl->new( {
          from_table_file => "unicode.dis",
          to_table_file => "en-us-brf.dis",
          warn => 1,
        } )
    }
    qr{Error opening file /i/like/eating/weevils/unicode.dis},
    "pays attention to LOUIS_TABLEPATH";

# leave the env var still set, but pass in a path argument. The
# argument should take precedence.
throws_ok
    {
        my $brl_obj = App::Brl2Brl->new( {
          path            => '/i/like/eating/slugs',
          from_table_file => "unicode.dis",
          to_table_file => "en-us-brf.dis",
          warn => 1,
        } )
    }
    qr{Error opening file /i/like/eating/slugs/unicode.dis},
    "pays attention to a 'path' argument";

done_testing;
