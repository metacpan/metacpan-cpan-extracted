#!/usr/bin/perl -w -s
use Biblio::Thesaurus;
use CGI qw(:all);
use Data::Dumper;

my $the = shift || "secondorder.the";
my $t = thesaurusLoadM($the);

print Dumper ($t);

print $t->baselang(), join("=",$t->order());
print $t->downtr(
 {-default  => sub { dt($t->describe($rel))."\n".
                     join("\n", (map {dd(a({href=>"#$_"},$_))} sort @terms))},
  -eachTerm => sub { dt(a({name=>"$term"},$term))."\n".dd(dl($_))."\n"},
  -end      => sub { h1("Thesaurus - all in one page").dl($_)."\n"},
  -order    => (defined $t->{order} ? [$t->order()] : ["EN","FR","BT"]),
  URL       => sub { dt($t->describe($rel))."\n".
                     join("\n", (map {dd(a({href=>"$_"},$_))} @terms))}, 
 });

=head1 NAME

ex4.pl - exemplo usando metadata

=SYNOPIS
