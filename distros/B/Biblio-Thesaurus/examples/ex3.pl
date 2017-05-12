#!/usr/bin/perl -w -s
use Biblio::Thesaurus;
use CGI qw(:all);

my $the = shift || "animal.the";
$thesaurus = thesaurusLoad($the);

print $thesaurus->downtr(
 {-default  => sub { dt($thesaurus->describe($rel))."\n".
                     join("\n", (map {dd(a({href=>"#$_"},$_))} sort @terms))},
  -eachTerm => sub { dt(a({name=>"$term"},$term))."\n".dd(dl($_))."\n"},
  -end      => sub { h1("Thesaurus - all in one page").dl($_)."n"},
  -order    => ["EN","FR","BT"],
  URL       => sub { dt($thesaurus->describe($rel))."\n".
                     join("\n", (map {dd(a({href=>"$_"},$_))} @terms))}, 
 });

= converte to HTML
