#!/usr/bin/perl -w

use Test::More tests => 3;

use IO::String;
use BibTeX::Parser;

{
    my $string = q|@article{lin1973,
       author = "Shen Lin and Brian W. Kernighan",
       title = "An Effective Heuristic Algorithm for the Travelling-Salesman Problem",
       journal = "Operations Research",
       volume = 21,
       year = 1973,
       pages = "498--516"
    }|;
    my $fh = IO::String->new($string);

    my $parser = BibTeX::Parser->new( $fh );

#my @result = BibTeX::Parser->_parse($fh);

    my $entry = $parser->next;

    is_deeply($entry, {_type => 'ARTICLE', _key => 'lin1973', author => "Shen Lin and Brian W. Kernighan",
       title => "An Effective Heuristic Algorithm for the Travelling-Salesman Problem",
       journal => "Operations Research",
       volume => 21,
       year => 1973,
       pages => "498--516", _parse_ok => 1,
       _fieldnums =>   {'author' => 0, 'title' => 1,
                        'journal' => 2, 'volume' => 3,
			    'year' => 4, 'pages' => 5},
       _pre => '',		       
       _raw => $string}, "parse \@ARTICLE");

}
{
    my $string1 = q|@article{lin1973,
       author = "Shen Lin and Brian W. Kernighan",
       title = "An Effective Heuristic Algorithm for the Travelling-Salesman Problem",
       journal = "Operations Research",
       volume = 21,
       year = 1973,
       pages = "498--516"
    }|;
    my $string = "some
text
$string1";
    my $fh = IO::String->new($string);

    my $parser = BibTeX::Parser->new( $fh );

#my @result = BibTeX::Parser->_parse($fh);

    my $entry = $parser->next;

    is_deeply($entry, {_type => 'ARTICLE', _key => 'lin1973', author => "Shen Lin and Brian W. Kernighan",
       title => "An Effective Heuristic Algorithm for the Travelling-Salesman Problem",
       journal => "Operations Research",
       volume => 21,
       year => 1973,
       pages => "498--516", _parse_ok => 1,
       _fieldnums =>   {'author' => 0, 'title' => 1,
                        'journal' => 2, 'volume' => 3,
			    'year' => 4, 'pages' => 5},
       _pre => "some\ntext",		       
       _raw => $string1}, "parse \@ARTICLE");

}
{
    my $string = q|@InProceedings{Herper:2001:MVS,
  author = 	 {Henry Herper},
  title = 	 {{M}odellierung von {S}ystemen: ein
		  {A}pplikationsgebiet im {I}nformatikunterricht},
  booktitle = 	 {Informatikunterricht und Medienbildung, INFOS 2001
		  (9. Fachtagung Informatik und Schule, Paderborn
		  17.-20- September 2001) -- Tagungsband},
  editor =	 {Reinhard Keil-Slavik and Johannes Magenheim},
  year =	 {2001},
}|;
    my $fh = IO::String->new($string);

    my $parser = BibTeX::Parser->new( $fh );

    my $entry = $parser->next;

    is_deeply($entry, {
        _type => 'INPROCEEDINGS',
        _key => 'Herper:2001:MVS',
       _fieldnums =>   {'author' => 0, 'title' => 1,
                        'booktitle' => 2, 'editor' => 3,
                        'year' => 4},
        author => "Henry Herper",
        title => "{M}odellierung von {S}ystemen: ein {A}pplikationsgebiet im {I}nformatikunterricht",
        booktitle => "Informatikunterricht und Medienbildung, INFOS 2001 (9. Fachtagung Informatik und Schule, Paderborn 17.-20- September 2001) -- Tagungsband",
        editor => "Reinhard Keil-Slavik and Johannes Magenheim",
        year => 2001,
        _parse_ok => 1,
        _pre => '',
        _raw => $string}, "parse \@ARTICLE");
}
