package CSS::Inliner::TreeBuilder;
use strict;
use warnings;

use Storable qw(dclone);

BEGIN {
#  $HTML::TreeBuilder::DEBUG = 1;
}

use base qw(HTML::TreeBuilder);

=pod

=head1 NAME

CSS::Inliner::TreeBuilder - Parser that builds a HTML syntax tree

=head1 SYNOPSIS

 use CSS::Inliner::TreeBuilder;

 foreach my $file_name (@ARGV) {
   my $tree = CSS::Inliner::TreeBuilder->new();
   $tree->parse_file($file_name);

   print "Hey, here's a dump of the parse tree of $file_name:\n";
   $tree->dump(); # a method we inherit from HTML::Element
   print "And here it is, bizarrely rerendered as HTML:\n", $tree->as_HTML, "\n";

   $tree = $tree->delete();
 }

=head1 DESCRIPTION

Class to handling parsing of generic HTML

This sub-module is derived from HTML::TreeBuilder. The aforementioned module is almost completely incapable
of handling non-standard HTML4 documents commonly seen in the wild, let alone HTML5 documents. This module
basically performs some minor adjustments to the way parsing and printing occur such that an acceptable result
can be reached when handling real world documents.

=cut

sub as_HTML {
  my $self = shift;

  my $html;
  if ($self->implicit_tags() == 0) {
    $html = $self->SUPER::as_HTML(@_);

    #strip trailing and leading whitespace which our relaxed mode may have
    #inadvertently adds
    $html =~ s/^\s+|\s+$//g;

    # our indentation is messed up by 1 space, try to clean it up
    my @lines = split /\n/, $html;
    for (my $count = 0; $count < scalar @lines; $count++) {
      $lines[$count] =~ s/^ //;
    }

    # put html back together after whitespace processing, probably still indentation
    # problems, but this is the best we can do without some sort of indentation library
    $html = join("\n",@lines);
  }
  else {
    $html = $self->SUPER::as_HTML(@_);
  }

  return $html;
}

sub parse_content {
  my $self = shift;

  if ($self->implicit_tags() == 0) {
    # protect doctype declarations... parser is too strict here
    $_[0] =~ s/\<!(doctype) ([^>]+)\>/\<decl ~pi="1" \>$1 $2<\/decl\>/gi;

    $self->SUPER::parse_content(@_);

    $self->{_tag} = '~literal';
    $self->{text} = '';

    my @decls = $self->look_down('_tag','decl','~pi','1');
    foreach my $decl (@decls) {
      my $text = '<!' . $decl->as_text() . '>';
      my $literal = HTML::Element->new('~literal', 'text' => $text );

      $decl->replace_with($literal);
    }
  }
  else {
    $self->SUPER::parse_content(@_);
  }

  return();
}

1;
