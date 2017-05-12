#!/usr/bin/perl -w
# 
# This is an example showing how you can use Config::Natural 
# with HTML::Template. It also shows how to use a handler. 
# 
use strict;
use Config::Natural;
use HTML::Template;

$|=1;

my $source = new Config::Natural;

$source->set_handler('hiragana', sub { my $param = shift; my $value = shift; return "< $value >" });
$source->read_source(\*DATA);

my $html_tmpl = <<HTML;
<TMPL_VAR NAME=title>

<TMPL_LOOP NAME=article>
<TMPL_VAR NAME=nihonji>
  <TMPL_VAR NAME=hiragana>
  <TMPL_LOOP NAME=definitions><TMPL_VAR NAME=definition>; </TMPL_LOOP>
  <TMPL_LOOP NAME=secondary>
    <TMPL_VAR NAME=nihonji> : <TMPL_VAR NAME=definition>
  </TMPL_LOOP>
</TMPL_LOOP>
HTML

my $tmpl = new HTML::Template scalarref => \$html_tmpl, associate => $source;

print $tmpl->output;

__END__
title = Dico de japonais

article {
    nihonji = aoi
    hiragana = a o i
    
    definition = bleu
    definition = 2e def
    definition = 3e def
    
    secondary {
        nihonji = aoi suru
        definition = etre inexperimente
    }
    
    secondary {
        nihonji = aoi blah
        definition = n'importe quoi
    }
}

