use strict;
use Test;
BEGIN { plan tests => 14 }
use Config::Natural;
Config::Natural->options(-quiet => 1);

my $obj = new Config::Natural { 
        affectation_symbol => ':',  comment_line_symbol => '//', 
        list_begin_symbol => '(', list_end_symbol => ')', 
        multiline_begin_symbol => '<<', multiline_end_symbol => '---'
    }, \*DATA;

ok( $obj->affectation_symbol,  ':'  );  #01
ok( $obj->comment_line_symbol, '//' );  #02
ok( $obj->list_begin_symbol,   '('  );  #03
ok( $obj->list_end_symbol,     ')'  );  #04

ok( $obj->all_parameters, 3 );  #05

ok( $obj->param('version'), '3.2.3' );  #06
my $copyright = $obj->param('copyright');
chomp($copyright);
ok( $copyright, "Copyright (C)1994-2003 Sebastien Aperghis-Tramoni <sebastien\@aperghis.net>" );  #07

my $articles = $obj->param('article');
ok( ref $articles, 'ARRAY' );  #08
ok( $articles->[0]{name},       'rei_01' );  #09
ok( $articles->[0]{romanji},    'rei'    );  #10
ok( $articles->[0]{definition}, 'zero'   );  #11
ok( $articles->[1]{name},       'rei_02' );  #12
ok( $articles->[1]{romanji},    'rei'    );  #13
ok( $articles->[1]{definition}, 'soul, spirit' );  #14


__END__
// extracted and translated from my Japanese to French mini Dictionary
version: 3.2.3
copyright:<<
Copyright (C)1994-2003 Sebastien Aperghis-Tramoni <sebastien@aperghis.net>
---

article (
    name: rei_01
    romanji: rei
    definition: zero
)

article (
    name: rei_02
    romanji: rei
    definition: soul, spirit
)

