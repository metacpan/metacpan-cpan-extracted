use strict;

package Blatte::HTML::Element;

sub new {
  my $class = shift;
  bless [@_], $class;
}

sub name { $_[0]->[0] }

sub attrs { $_[0]->[1] }

sub content {
  my $self = shift;
  @$self[2..$#$self];
}

package Blatte::HTML;

BEGIN {
  @Blatte::HTML::builtins = qw($html_bool_yes $html_bool_no
                               $html_p_yes $html_p_no
                               $html_ent_yes $html_ent_no
                               $a $abbr $acronym $address $applet $area $b
                               $base $basefont $bdo $big $blockquote $body $br
                               $button $caption $center $cite $code $col
                               $colgroup $dd $del $dfn $dir $div $dl $dt $em
                               $fieldset $font $form $frame $frameset $h1 $h2
                               $h3 $h4 $h5 $h6 $head $hr $html $i $iframe $img
                               $input $ins $isindex $kbd $label $legend $li
                               $link $map $menu $meta $noframes $noscript
                               $object $ol $optgroup $option $p $param $pre $q
                               $s $samp $script $select $small $span $strike
                               $strong $style $sub $sup $table $tbody $td
                               $textarea $tfoot $th $thead $title $tr $tt $u
                               $ul $var);
}

use vars (qw(@ISA @EXPORT @EXPORT_OK $VERSION), @Blatte::HTML::builtins);

use Exporter;

@ISA = qw(Exporter);

@EXPORT = @Blatte::HTML::builtins;
@EXPORT_OK = qw(make_start_tag render);

$VERSION = '0.9';

use Blatte;
use HTML::Entities;
use HTML::Tagset;
use Symbol;

my $_html_bool_yes = gensym();
my $_html_bool_no  = gensym();

$html_bool_yes = sub { $_html_bool_yes };
$html_bool_no  = sub { $_html_bool_no };

$html_p_yes   = sub { new Blatte::HTML::Element('_p', 1, @_[1 .. $#_]) };
$html_p_no    = sub { new Blatte::HTML::Element('_p', 0, @_[1 .. $#_]) };
$html_ent_yes = sub { new Blatte::HTML::Element('_ent', 1, @_[1 .. $#_]) };
$html_ent_no  = sub { new Blatte::HTML::Element('_ent', 0, @_[1 .. $#_]) };

$a          = sub { new Blatte::HTML::Element('a',          @_) };
$abbr       = sub { new Blatte::HTML::Element('abbr',       @_) };
$acronym    = sub { new Blatte::HTML::Element('acronym',    @_) };
$address    = sub { new Blatte::HTML::Element('address',    @_) };
$applet     = sub { new Blatte::HTML::Element('applet',     @_) };
$area       = sub { new Blatte::HTML::Element('area',       @_) };
$b          = sub { new Blatte::HTML::Element('b',          @_) };
$base       = sub { new Blatte::HTML::Element('base',       @_) };
$basefont   = sub { new Blatte::HTML::Element('basefont',   @_) };
$bdo        = sub { new Blatte::HTML::Element('bdo',        @_) };
$big        = sub { new Blatte::HTML::Element('big',        @_) };
$blockquote = sub { new Blatte::HTML::Element('blockquote', @_) };
$body       = sub { new Blatte::HTML::Element('body',       @_) };
$br         = sub { new Blatte::HTML::Element('br',         @_) };
$button     = sub { new Blatte::HTML::Element('button',     @_) };
$caption    = sub { new Blatte::HTML::Element('caption',    @_) };
$center     = sub { new Blatte::HTML::Element('center',     @_) };
$cite       = sub { new Blatte::HTML::Element('cite',       @_) };
$code       = sub { new Blatte::HTML::Element('code',       @_) };
$col        = sub { new Blatte::HTML::Element('col',        @_) };
$colgroup   = sub { new Blatte::HTML::Element('colgroup',   @_) };
$dd         = sub { new Blatte::HTML::Element('dd',         @_) };
$del        = sub { new Blatte::HTML::Element('del',        @_) };
$dfn        = sub { new Blatte::HTML::Element('dfn',        @_) };
$dir        = sub { new Blatte::HTML::Element('dir',        @_) };
$div        = sub { new Blatte::HTML::Element('div',        @_) };
$dl         = sub { new Blatte::HTML::Element('dl',         @_) };
$dt         = sub { new Blatte::HTML::Element('dt',         @_) };
$em         = sub { new Blatte::HTML::Element('em',         @_) };
$fieldset   = sub { new Blatte::HTML::Element('fieldset',   @_) };
$font       = sub { new Blatte::HTML::Element('font',       @_) };
$form       = sub { new Blatte::HTML::Element('form',       @_) };
$frame      = sub { new Blatte::HTML::Element('frame',      @_) };
$frameset   = sub { new Blatte::HTML::Element('frameset',   @_) };
$h1         = sub { new Blatte::HTML::Element('h1',         @_) };
$h2         = sub { new Blatte::HTML::Element('h2',         @_) };
$h3         = sub { new Blatte::HTML::Element('h3',         @_) };
$h4         = sub { new Blatte::HTML::Element('h4',         @_) };
$h5         = sub { new Blatte::HTML::Element('h5',         @_) };
$h6         = sub { new Blatte::HTML::Element('h6',         @_) };
$head       = sub { new Blatte::HTML::Element('head',       @_) };
$hr         = sub { new Blatte::HTML::Element('hr',         @_) };
$html       = sub { new Blatte::HTML::Element('html',       @_) };
$i          = sub { new Blatte::HTML::Element('i',          @_) };
$iframe     = sub { new Blatte::HTML::Element('iframe',     @_) };
$img        = sub { new Blatte::HTML::Element('img',        @_) };
$input      = sub { new Blatte::HTML::Element('input',      @_) };
$ins        = sub { new Blatte::HTML::Element('ins',        @_) };
$isindex    = sub { new Blatte::HTML::Element('isindex',    @_) };
$kbd        = sub { new Blatte::HTML::Element('kbd',        @_) };
$label      = sub { new Blatte::HTML::Element('label',      @_) };
$legend     = sub { new Blatte::HTML::Element('legend',     @_) };
$li         = sub { new Blatte::HTML::Element('li',         @_) };
$link       = sub { new Blatte::HTML::Element('link',       @_) };
$map        = sub { new Blatte::HTML::Element('map',        @_) };
$menu       = sub { new Blatte::HTML::Element('menu',       @_) };
$meta       = sub { new Blatte::HTML::Element('meta',       @_) };
$noframes   = sub { new Blatte::HTML::Element('noframes',   @_) };
$noscript   = sub { new Blatte::HTML::Element('noscript',   @_) };
$object     = sub { new Blatte::HTML::Element('object',     @_) };
$ol         = sub { new Blatte::HTML::Element('ol',         @_) };
$optgroup   = sub { new Blatte::HTML::Element('optgroup',   @_) };
$option     = sub { new Blatte::HTML::Element('option',     @_) };
$p          = sub { new Blatte::HTML::Element('p',          @_) };
$param      = sub { new Blatte::HTML::Element('param',      @_) };
$pre        = sub { new Blatte::HTML::Element('pre',        @_) };
$q          = sub { new Blatte::HTML::Element('q',          @_) };
$s          = sub { new Blatte::HTML::Element('s',          @_) };
$samp       = sub { new Blatte::HTML::Element('samp',       @_) };
$script     = sub { new Blatte::HTML::Element('script',     @_) };
$select     = sub { new Blatte::HTML::Element('select',     @_) };
$small      = sub { new Blatte::HTML::Element('small',      @_) };
$span       = sub { new Blatte::HTML::Element('span',       @_) };
$strike     = sub { new Blatte::HTML::Element('strike',     @_) };
$strong     = sub { new Blatte::HTML::Element('strong',     @_) };
$style      = sub { new Blatte::HTML::Element('style',      @_) };
$sub        = sub { new Blatte::HTML::Element('sub',        @_) };
$sup        = sub { new Blatte::HTML::Element('sup',        @_) };
$table      = sub { new Blatte::HTML::Element('table',      @_) };
$tbody      = sub { new Blatte::HTML::Element('tbody',      @_) };
$td         = sub { new Blatte::HTML::Element('td',         @_) };
$textarea   = sub { new Blatte::HTML::Element('textarea',   @_) };
$tfoot      = sub { new Blatte::HTML::Element('tfoot',      @_) };
$th         = sub { new Blatte::HTML::Element('th',         @_) };
$thead      = sub { new Blatte::HTML::Element('thead',      @_) };
$title      = sub { new Blatte::HTML::Element('title',      @_) };
$tr         = sub { new Blatte::HTML::Element('tr',         @_) };
$tt         = sub { new Blatte::HTML::Element('tt',         @_) };
$u          = sub { new Blatte::HTML::Element('u',          @_) };
$ul         = sub { new Blatte::HTML::Element('ul',         @_) };
$var        = sub { new Blatte::HTML::Element('var',        @_) };

# Hmm, why did HTML::Tagset neglect to do this?
my %p_closure_barriers = map { ($_ => 1) } @HTML::Tagset::p_closure_barriers;

sub make_start_tag {
  my $obj = shift;
  my $result = $obj->name();
  my $attrs = $obj->attrs();
  foreach my $attr (keys %$attrs) {
    my $val = $attrs->{$attr};
    if ($val ne $_html_bool_no) {
      if ($val eq $_html_bool_yes) {
        $result .= " $attr";
      } else {
        $result .= sprintf(' %s="%s"',
                           $attr,
                           &encode_entities(&Blatte::flatten($val, '')));
      }
    }
  }
  "<$result>";
}

sub render {
  my($val, $render_cb) = @_;
  my $do_p = 1;
  my $do_entities = 1;
  my @stack;
  my $traverse_cb;
  $traverse_cb = sub {
    my($ws, $obj) = @_;

    my $old_do_p        = $do_p;
    my $old_do_entities = $do_entities;

    my $obj_is_html_elt = &UNIVERSAL::isa($obj, 'Blatte::HTML::Element');

    my $obj_is__p   = ($obj_is_html_elt && ($obj->name() eq '_p'));
    my $obj_is__ent = ($obj_is_html_elt && ($obj->name() eq '_ent'));
    my $obj_is_control = ($obj_is__p || $obj_is__ent);

    if ($obj_is__p) {
      $do_p = $obj->attrs();
    } elsif ($obj_is__ent) {
      $do_entities = $obj->attrs();
    }

    my $obj_is_p        = ($obj_is_html_elt && ($obj->name() eq 'p'));
    my $newpar          = ($do_p &&
                           ($obj_is_p || (defined($ws) && ($ws =~ /\n.*\n/))));

    my $close_needed;

    if ($newpar) {
      for (my $i = $#stack; $i >= 0; --$i) {
        my $elt = $stack[$i];
        my $name = $elt->[0];
        last if ($p_closure_barriers{$name});
        if ($name eq 'p') {
          $close_needed = $i;
          last;
        }
      }

      if (defined($close_needed)) {
        for (my $i = $#stack; $i >= $close_needed; --$i) {
          my $elt = $stack[$i];
          my $name = $elt->[0];
          &$render_cb("</$name>");
        }

        splice(@stack, $close_needed, 1) if $obj_is_p;
      }
    }

    &$render_cb($ws) if defined($ws);

    if ($newpar) {
      if (defined($close_needed)) {
        for (my $i = $close_needed; $i <= $#stack; ++$i) {
          my $elt = $stack[$i];
          my($name, $tag) = @$elt;
          &$render_cb($tag);
        }
      } elsif (!$obj_is_p) {
        my $tag = '<p>';
        &$render_cb($tag);
        push(@stack, ['p', $tag]);
      }
    }

    if ($obj_is_html_elt) {
      my $tag;
      my $name;

      unless ($obj_is_control) {
        $tag = &make_start_tag($obj);
        &$render_cb($tag);
        $name = $obj->name();
      }

      if ($obj_is_control || !$HTML::Tagset::emptyElement{$name}) {
        my $pair;

        unless ($obj_is_control) {
          $pair = [$name, $tag];
          push(@stack, $pair);
        }

        &Blatte::traverse([$obj->content()], $traverse_cb);

        unless ($obj_is_control) {
          for (my $i = $#stack; $i >= 0; --$i) {
            my $elt = $stack[$i];
            if ($elt eq $pair) {
              for (my $j = $#stack; $j >= $i; --$j) {
                my $elt2 = $stack[$j];
                my $name2 = $elt2->[0];
                &$render_cb("</$name2>");
              }
              splice(@stack, $i);
              last;
            }
          }
        }
      }
    } else {
      &$render_cb($do_entities ? &encode_entities($obj) : $obj);
    }

    $do_p = $old_do_p;
    $do_entities = $old_do_entities;
  };
  &Blatte::traverse($val, $traverse_cb);
}

1;

__END__

=head1 NAME

Blatte::HTML - tools for generating HTML with Blatte

=head1 SYNOPSIS

  use Blatte;
  use Blatte::Builtins;
  use Blatte::HTML;

  $perl = &Blatte::Parse(...string of Blatte code...);
  $val = eval $perl;
  &Blatte::HTML::render($val, \&emit);

  sub emit {
    print shift;
  }

=head1 DESCRIPTION

This module defines Blatte functions corresponding to HTML tags,
making it possible to write Blatte that looks like this:

  Here is a {\a \href=http://www.blatte.org/ link}

and can be translated to this:

  Here is a <a href="http://www.blatte.org/">link</a>

The beauty is that you can use Blatte functions to encapsulate
repeated constructs.  For instance, this definition:

  {\define {\mypagestyle \=name \&content}
   {\html {\head {\title \name}}
          {\body {\h1 \name} \content}}}

allows you to write

  {\mypagestyle \name={A page I wrote} This is my page.}

which saves you from having to write:

  <html><head><title>A page I wrote</title></head>
  <body><h1>A page I wrote</h1>This is my page.</body></html>

End-tags are supplied automatically.  The module HTML::Tagset, by
Gisle Aas and Sean M. Burke, is used to identify HTML elements that
require no end-tag.

Paragraph tags (<p>) are also supplied automatically wherever a blank
line appears in the text.  For instance, this:

  Here is some text.

  Here is some more.

becomes this:

  Here is some text.

  <p>Here is some more.

This module tries hard to keep HTML element nesting correct.  For
instance, this:

  Paragraph 1.

  Paragraph 2 {\b with some bold text

  continuing to paragraph 3}.

becomes this:

  Paragraph 1.

  <p>Paragraph 2 <b>with some bold text</b></p>

  <p><b>continuing to paragraph 3</b>.

Entity-encoding is automatic too.  So this:

  Five & dime

becomes this:

  Five &amp; dime

It's possible to suppress automatic <p>-tag generation and entity-encoding by
writing:

  {\html_p_no ...content...}

and

  {\html_ent_no ...content...}

Inside an {\html_p_no ...} it's possible to reenable <p>-tag generation with
{\html_p_yes ...}, and inside {\html_ent_no ...} it's possible to reenable
entity encoding with {\html_ent_yes ...}.

=head1 FUNCTIONS

=over 4

=item make_start_tag(ELEMENT)

Given a Blatte::HTML::Element object, returns a string representing
that element's HTML start tag.

(Blatte::HTML::Element is the type of object returned by the Blatte
functions representing HTML tags.)

=item render(OBJECT, CALLBACK)

Renders OBJECT as HTML, converting it to a series of strings that are
passed one at a time to repeated calls to CALLBACK.  OBJECT can be a
string, a Blatte::HTML::Element object, or a Blatte list (Perl ARRAY
ref) containing any combination of strings, Blatte::HTML::Elements,
and Blatte lists.

=back

=head1 BLATTE FUNCTIONS

This module defines a Blatte function for every HTML element defined
in the HTML 4.01 specification (http://www.w3.org/TR/html401):

    a abbr acronym address applet area b base basefont bdo big
    blockquote body br button caption center cite code col colgroup dd
    del dfn dir div dl dt em fieldset font form frame frameset h1 h2
    h3 h4 h5 h6 head hr html i iframe img input ins isindex kbd label
    legend li link map menu meta noframes noscript object ol optgroup
    option p param pre q s samp script select small span strike strong
    style sub sup table tbody td textarea tfoot th thead title tr tt u
    ul var

Tag names are case-sensitive.

HTML attributes are specified using Blatte named parameters, like so:

  {\td \colspan=2 ...}

Boolean attributes, such as the C<ismap> in

  <img src="..." ismap>

are specified using {\html_bool_yes} and {\html_bool_no}.  For instance, this:

  {\img \src=... \ismap={\html_bool_yes}}

yields this:

  <img src="..." ismap>

while this:

  {\img \src=... \ismap={\html_bool_no}}

yields this:

  <img src="...">

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.  (It's written
using Blatte::HTML!)

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte::HTML is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the
Blatte::HTML distribution.

=head1 SEE ALSO

L<blatte-html(1)>, L<Blatte(3)>, L<Blatte::Builtins(3)>.
