#!/usr/bin/perl -w -s
use Biblio::Thesaurus;
use CGI qw(:all);

my $the = shift || "secondorder.the";
my $t = thesaurusLoad($the);
my @ts=();
my @r=qw(_baselang_ _external_ _top_ _language_ _relation_ _order_);
my %r; @r{@r}=@r;

if(@ts=$t->terms("_order_","NT"))   { $t->order(@ts);       @r{@ts}=@ts }
if(@ts=$t->terms("_external_","NT")){ $t->setExternal(@ts); @r{@ts}=@ts }
if(@ts=$t->terms("_top_","NT"))     { $t->top_name($ts[0]);             }
if(@ts=$t->terms("_baselang_","NT")){ $t->baselang($ts[0]); @r{@ts}=@ts }
if(@ts=$t->terms("_language_","NT")){ $t->languages(@ts);   @r{@ts}=@ts }

# for each new relation describe it, add Invers and remove it as Term
if(@ts=$t->terms("_relation_","NT")){
  $t->downtr(
    { SN        => sub{ $t->describe($term,$terms[0]) },
      INV       => sub{ $t->addInverse($term,$terms[0])},
      -order    => ["SN","INV"],
      -eachTerm => sub{ $r{$term}=$term },  
    }, @ts);
}
for (keys %r){$t->deleteTerm($_)}

##Show this as HTML

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
