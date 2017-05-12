#------------------------------------------------------------------------------
# DBO::Visitor::RenderHTML - render record as HTML
#
# DESCRIPTION
#   A visitor class that renders a record as HTML.
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id$
#------------------------------------------------------------------------------

use strict;
package DBO::Visitor::RenderHTML;
use base qw(DBO::Visitor);
use Class::Multimethods;
use HTML::FromText 'text2html';

multimethod visit_table =>
  qw(DBO::Visitor::RenderHTML DBO::Table DBO::Handle) =>
sub {
  my ($vis, $table, $handle) = @_;
  my @html = ("<BLOCKQUOTE><TABLE BORDER=0 CELLSPACING=0>\n");
  $vis->{html} = \@html;
  # visit_table(superclass($vis), $table, $handle);
  call_next_method();
  push @html, "</TABLE></BLOCKQUOTE>\n";
  join '', @html;
};

multimethod visit_column =>
  qw(DBO::Visitor::RenderHTML DBO::Column::String DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  my $name = defined $col->{print_name} ? $col->{print_name} : $col->{name};
  my $value = $vis->{record}{$col->{name}};
  push @{$vis->{html}},
    ("<TR VALIGN=\"TOP\"><TD ALIGN=\"RIGHT\">",
     text2html($name), "</TD>\n<TD ALIGN=\"LEFT\">",
     text2html($value), "</TD></TR>\n") if defined $value;
};

multimethod visit_column =>
  qw(DBO::Visitor::RenderHTML DBO::Column::Number DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  my $name = defined $col->{print_name} ? $col->{print_name} : $col->{name};
  my $value = $vis->{record}{$col->{name}};
  push @{$vis->{html}},
    ("<TR VALIGN=\"TOP\"><TD ALIGN=\"RIGHT\">",
     text2html($name), "</TD>\n<TD ALIGN=\"LEFT\">",
     $vis->{record}{$col->{name}}, "</TD></TR>\n") if defined $value;
};

1;
