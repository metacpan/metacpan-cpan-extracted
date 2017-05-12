package CSS::DOM::Rule::Style;

$VERSION = '0.16';

use warnings;
use strict;

use CSS::DOM::Exception qw/ SYNTAX_ERR /;
 use        CSS::DOM::Rule;

our @ISA = 'CSS::DOM::Rule';

use constant 1.03 our $_const = {
# Don't let this conflict with the superclass.
	styl => 2,
	selc => 3,
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }

# overrides:
sub type { CSS::DOM::Rule::STYLE_RULE }
sub cssText {
	my $self = shift;
	my $old;
	if(defined wantarray) {
		my $sel = $self->selectorText;
		length $sel and $sel .= ' ';
		$old = "$sel\{ "
			. $self->[styl]->cssText ." }\n";
	}
	if (@_) {
		my $new_rule  =  $self->_parse(shift);
		@$self[styl,selc] = @$new_rule[styl,selc];
	}
	$old;
};


# CSSStyleRule interface:

# The selector ($self->[selc]) can be stored several ways, depending on how
# deeply we’ve parsed it:
#
# - a string
# - an array of two elements: [ token types, \@tokens ]
# - an array of three elements: [ token types, \@tokens, \@tree ]
#
# Tree format:
#   * E > F:link + G[foo], E[foo="warning"] DIV.ette E#myid h1[lang|='en']
# becomes
# [
#   [ '*' ],
#   '',
#   [ 'E' ],
#   '>',
#   [ 'F', ':', 'link', undef ],
#   '+',
#   [ 'G', 'a', 'foo', undef ], # ‘a’ stands for attr
# ],
# [
#   [ 'E', '=', 'foo', 'warning' ],
#   ''
#   [ 'DIV', '~', 'class', 'ette' ],
#   ''
#   [ 'E', '#', 'myid', undef ],
#   ''
#   [ 'h1', '|', 'lang', 'en' ],
# ],
#
# We pad the items above with undef because :foo.bar#baz becomes
# [[ undef,
#    ':', 'foo', undef,   # (sets of three)
#    '~', 'class', 'bar',
#    '#', 'baz', undef,
# ]]
sub selectorText { # ~~~ syntax_err
	my $old = (my $self = shift)->[selc];
#	warn "@{$$old[1]}";# if ref $old eq 'ARRAY' and wantarray;
	$old = join '', @{$$old[1]}
		if ref $old eq 'ARRAY' and defined wantarray;
	$self->[selc] = "".shift if @_;
	$old;
}

sub _set_selector_tokens {
	shift->[selc] = \@_;
}

sub _selector_matches { # ~~~ Does this work with initial space in the selector?
 my $self = shift;
 my $elem = shift; # This is assumed to be an HTML::DOM::Element.
 my $pseudo = shift; # pseudo-element

 # tokenise if necessary
 unless(ref $self->[selc]) {
  require CSS'DOM'Parser;
  $self->[selc] = [ CSS'DOM'tokenise($self->[selc]) ];
 }

 # parse selector tokens if necessary
 my $tree;
 unless($tree = $self->[selc][2]) {
  require CSS::DOM::Util;
  my ($types,@tokens) = ($self->[selc][0], @{ $self->[selc][1] });

  # ~~~ remove initial whitespace here?

  $self->[selc][2] = $tree = [];

  # for each sub-selector within the selector (comma-delimited)
  comma: while($types) {
   my @pieces;

   while($types) {
    push @pieces, \my @subsel;

    # element:
    if($types =~ s/^i//) {
     @subsel = lc shift @tokens;
    }
    elsif($tokens[0] eq '*') {
     shift @tokens;
     $types =~ s/^.//;
     @subsel = '*';
    }
    else { @subsel = undef }

    # suffixes:
    while($types) {

     # ids:
     if($types =~ s/^#//) {
      push @subsel, '#', CSS'DOM'Util'unescape( substr shift @tokens, 1 ),
       undef;
     }

     # classes
     elsif($types =~ /^di/ && $tokens[0] eq '.') {
      $types =~ s/^..//; shift @tokens;
      push @subsel, '~', 'class',
       CSS'DOM'Util'unescape( shift @tokens );
     }

     # pseudo-elems and classes
     elsif($types =~ s/^(::?)i//) {
      push @subsel, $1,lc CSS'DOM'Util'unescape($tokens[length $1]), undef;
      splice @tokens, 0, $+[0];
     }

     # :lang() and similar functions
     elsif($types =~ s/^:fi\)//) {
      push @subsel,
       ':',
       lc CSS'DOM'Util'unescape(substr $tokens[1], 0, -1),
       lc CSS'DOM'Util'unescape($tokens[2]);
      splice @tokens, 0, 4;
     }

     # [attr]
     elsif($types =~ s/^\[i]//) {
      push @subsel, '=', lc CSS'DOM'Util'unescape($tokens[1]), undef;
      splice @tokens, 0, 3;
     }

     # [attr='value']
     elsif($types =~ /^\[id']/ && $tokens[2] eq '=') {
      $types =~ s/^.{5}//;
      push @subsel, '=',
       lc CSS'DOM'Util'unescape($tokens[1]),
       CSS'DOM'Util'unescape_str($tokens[3]);
      splice @tokens, 0, 5;
     }

     # [attr~='value'], [attr|='value']
     elsif($types =~ s/^\[i[~|]']//) {
      push @subsel, $tokens[2],
       lc CSS'DOM'Util'unescape($tokens[1]),
       CSS'DOM'Util'unescape_str($tokens[3]);
      splice @tokens, 0, 5;
     }

     else { last } # last suffix
    }

    # If we reach this point and \@subsel is [ undef ], skip this selector
    # and move to the next comma
    if (@subsel == 1 and !defined $subsel[0]) {
     no warnings 'regexp';
     $types =~ s/^$CSS::DOM::Parser::any_re*,?//o;
     splice @tokens, 0, $+[0];
     next comma;
    }
 
    # check for hierarchy indicator (space > +)
    if($types =~ /^(s?)d/ and $tokens[$+[1]] =~ /([>+])/) {
     push @pieces, $1;
     $types =~ s/^s?d//;
     splice @tokens, $+[0];
    }
    else { push @pieces, '' }

    # trailing space
    $types =~ s/^s// and shift @tokens;

    # check for comma or end
    if($types =~ s/^(?:,s?|\z)//) {
     splice @tokens, 0, $+[0];
     push @$tree, \@pieces;
     pop @pieces; # remove redundant ''
     next comma;
    }
   }
  }
 }

#use DDS; Dump $tree if local our $warn = join "", @{$self->[selc][1]}, eq 'ul li span.a';

 my $specificity = '';
 
 comma: for(@$tree) {
  my $spec = _elem_matches_sel( $elem, $pseudo, $_ ) or next comma;

  no warnings 'uninitialized';
  $spec = join '', map chr, @$spec;
  $spec gt $specificity and $specificity = $spec;
 }

#warn join("", @{$self->[selc][1]}), " ", join ',', map ord, split//,$specificity;
 return $specificity || ();
}

sub _elem_matches_sel {
 my ($elem, $pseudo, $subsels) = @_;

#warn $elem if our $warn;
 my $spec = _elem_matches_subsel( $elem, $pseudo, $$subsels[-1] )or return;
  
 subsel: for(my $i = $#$subsels-1; $i>=0; $i-=2) {
   my $combinator = $$subsels[$i];
   my $next_sel = $$subsels[$i-1];

   # space between subselectors (ancestor)
   if(!$combinator) {
    my $e = $elem;
    while($e = $e->parentNode) {
     last if !$e->can('tagName'); # document
     # ~~~ this might be more efficient if we use parentElement, but
     # but HTML::DOM doesn’t have that yet.

     # We have to call _match recursively here with a copy of the selector
     # to account for cases like A > B C, where B might first match an
     # ancestor that is not a child of A.
     my $s = _elem_matches_sel( $e, undef, [ @$subsels[0..$i-1] ] );
     if($s) {
      for(0..2) {
       no warnings 'uninitialized';
       $$spec[$_] += $$s[$_];
      }
      last subsel; # recursion makes the rest of this loop unnecessary
     }
    }
    # If we get here, we’ve run out of ancestors.
    return
   }

   # parent/sibling
   else {
    my $meth = ('previousSibling','parentNode')[$combinator eq '>'];
    $elem = $elem->$meth;
    last unless $elem->can('tagName'); # ~~~ The note above about effici-
                                       #     ency applies here, too.
    my $s = _elem_matches_subsel( $elem, undef, $next_sel ) or return;
    for(0..2) {
       $$spec[$_] += $$s[$_];
    }
   }
  }

  return $spec;
}

sub _elem_matches_subsel {
 my ($elem, $pseudo, $subsel) = @_;
 my @subsel = @$subsel;

 my($ids,$attrs,$tags);

 # tag
 my $tag = shift @subsel;
 if(defined $tag and $tag ne '*') {
    $tag eq lc $elem->tagName or return;
    ++$tags
 }

 # suffixes
 while(@subsel) {
    my($type,$id,$arg) = splice @subsel, 0, 3;

    if($type eq '#') {
     $id eq $elem->id or return;
     ++$ids;
    }
    elsif($type eq '~') {
     my $attr = $elem->getAttribute($id);
     !defined $attr || !length $attr and return;
     $attr =~ /(?:^|[ \t\r\n\f])\Q$arg\E(?:\z|[ \t\r\n\f])/ or return;
     ++$attrs;
    }
    # A single colon is either a CSS 2.1 pseudo-element or a pseudo-class.
    # Since CSS 3 ps-elems have two colons, we can simply filter out those
    # pseudo-elems listed in CSS 2.1. The rest are classes.
    elsif($type eq ':'
      and $id !~ /^(?:first-l(?:ine|etter)|before|after)\z/) { # class
     # ~~~
     return
    }
    elsif($type =~ /:/) { # pseudo-element
     return unless $pseudo and lc $id eq lc $pseudo;
    }
    elsif($type eq '=') {
     my $attr = $elem->getAttribute($id);
     if(defined $arg) {
      no warnings;
      $attr eq $arg or return;
     }
     else { defined $attr || length $attr or return }
     ++$attrs;
    }
    elsif($type eq '|') {
     my $attr = $elem->getAttribute($id);
     !defined $attr || !length $attr and return;
     $attr =~ /^\Q$arg\E(?:-|\z)/ or return;
     ++$attrs;
    }
 }
#warn Dump [$tag,$ids,$attrs,$tags] if our $warn;
 return[$ids,$attrs,$tags];
}

sub style {
	$_[0]->[styl] ||= do {
		require CSS::DOM::Style;
		new CSS::DOM::Style shift
	};
}

                              !()__END__()!

=head1 NAME

CSS::DOM::Rule::Style - CSS style rule class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM;
  my $ruleset = CSS::DOM->parse(
      'p:firstline, h3 { font-weight: bold }'
  )->cssRules->[0];

  $ruleset->selectorText;      # 'p:firstline, h3'
  $ruleset->style;             # a CSS::DOM::Style object
  $ruleset->style->fontWeight; # 'bold'

=head1 DESCRIPTION

This module implements CSS style rules for L<CSS::DOM>. It inherits 
from
L<CSS::DOM::Rule> and implements
the CSSStyleRule DOM interface.

=head1 METHODS

=over 4

=item selectorText

Returns a string representing the selector(s). Pass an argument to set it.

=item style

Returns the CSS::DOM::Style object representing the declaration block
of this rule.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Style>

L<CSS::DOM::Rule>
