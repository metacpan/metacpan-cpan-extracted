package CSS::LESS::Filter;

use strict;
use warnings;
use Carp;
use Parse::RecDescent;

our $VERSION = '0.04';

sub new {
  my $class = shift;

  my $parser = Parse::RecDescent->new($class->_less_grammar)
    or die "Bad Grammar";

  my $self = bless { parser => $parser, filters => [] }, $class;

  $self->add(@_) if @_;

  $self;
}

sub process {
  my ($self, $less, $opts) = @_;

  my $mode = ($opts || {})->{mode} || 'warn';

  $_->[2] = 0 for @{$self->{filters}}; # clear "used" flag.

  my $res = $self->_apply($self->_parse($less), "");

  for (@{$self->{filters}}) {
    next if $_->[2];
    if ($mode eq 'warn') {
      carp "Filter '$_->[0]' ($_->[1]) is not used at all.";
      next;
    }
    if ($mode eq 'append') {
      my ($id, $filter) = ($_->[0], $_->[1]);
      if (ref $id) {
        carp "Can't append ambiguous '$id' ($filter).";
        next;
      }
      my $type = substr($id, -1);
      my $depth =()= $id =~ /\{/g;
      my $closing_braces = '}' x $depth;
      my $value = !ref $filter ? $filter : $filter->('');
      $res .= "\n" if length $res && substr($res, -1) ne "\n";
      if ($id eq '') {
        $res .= "$value\n";
      }
      elsif ($type eq '{') { # ruleset
        $res .= "$id\n$value";
        $res .= "\n" if substr($res, -1) ne "\n";
        $res .= "$closing_braces\n";
      }
      else { # declaration, at rule
        $closing_braces = " $closing_braces" if $closing_braces;
        $res .= "$id $value;$closing_braces\n";
      }
    }
  }

  $res;
}

sub add {
  my $self = shift;

  croak "Odd number of args" if @_ && @_ % 2;

  while(my ($id, $value) = splice @_, 0, 2) {
    push @{$self->{filters}}, [$id, $value];
  }

  $self;
}

sub _parse {
  my ($self, $less) = @_;

  $self->{parser}->less($less);
}

sub _apply {
  my ($self, $parts, $id) = @_;

  my $str = '';
  for my $part (@$parts) {
    if (!ref $part) {
      $str .= $part;
    }
    elsif (ref $part eq ref {}) {
      if (ref $part->{value} eq ref []) {
        my $new_id = (length $id ? "$id " : "") . "$part->{key} {";
        $new_id =~ s/\s+/ /gs;
        my $ruleset .= $part->{key} . $part->{brace_open};
        my $inside = $self->_apply($part->{value}, $new_id);

        for (@{$self->{filters}}) {
          next if $_->[0] eq '';
          if (
            (!ref $_->[0] and $new_id eq $_->[0]) or
            (ref $_->[0] eq ref qr// and $new_id =~ /$_->[0]/)
          ) {
            if (!ref $_->[1]) {
              $inside = $_->[1];
            }
            elsif (ref $_->[1] eq ref sub {}) {
              $inside = $_->[1]->($inside);
            }
            $_->[2] = 1;
          }
        }
        next unless defined $inside;
        $ruleset .= $inside;
        $ruleset .= $part->{brace_close};
        $str .= $ruleset;
      }
      else {
        (my $sep = $part->{sep}) =~ s/\s+//gs;
        my $cur_id = (length $id ? "$id " : "") . "$part->{key}$sep";
        for (@{$self->{filters}}) {
          next if $_->[0] eq '';
          if (
            (!ref $_->[0] and $cur_id eq $_->[0]) or
            (ref $_->[0] eq ref qr// and $cur_id =~ /$_->[0]/)
          ) {
            if (!ref $_->[1]) {
              $part->{value} = $_->[1];
            }
            elsif (ref $_->[1] eq ref sub {}) {
              $part->{value} = $_->[1]->($part->{value});
            }
            $_->[2] = 1;
          }
        }
        next unless defined $part->{value};
        $str .= join '', @$part{qw/key sep value semicolon/};
      }
    }
    else {
      warn "illegal format: $part";
    }
  }

  $str;
}

sub _less_grammar { return <<'GRAMMAR'
{
  use Data::Dump 'dump';
  *debug = sub {};
  if ($ENV{CSS_LESS_FILTER_DEBUG}) {
    *debug = sub { warn(shift, ': ', dump @_) }
  }
}

less: <skip: ''> (at_rule | ruleset | declaration | mixin | selectors | comments | sp | unknown)(s)
  { $return = $item[2] }

comments: less_comment | css_comment
  { debug($thisline, @item); $return = $item[1] }

less_comment: /\/\/.*$/m
  { debug($thisline, @item); $return = $item[1] }

css_comment: /\/\*[^*]*\*+([^\/*][^*]*\*+)*\//
  { debug($thisline, @item); $return = $item[1] }

ruleset: selectors brace_open (
    comments | ruleset | function | declaration | at_rule |
    selectors | semicolon | sp
  )(s?) brace_close
  { debug($thisline, @item); $return = { key => $item[1], brace_open => $item[2], value => $item[3], brace_close => $item[4] } }

at_rule: at_keyword sp (string | url | ident | parens | sp)(s) semicolon
  { debug($thisline, @item); $return = {key => $item[1], sep => $item[2], value => join('', @{$item[3]}), semicolon => $item[4]} }

selectors: (function|selector) (function | selector | parens | comments | ',' | sp)(s?)
  { debug($thisline, @item); $return = join '', $item[1], @{$item[2]} }

at_keyword: '@' ident
  { debug($thisline, @item); $return = join '', @item[1..2] }

selector: namespace_prefix(?) (
    ident
    | id_selector
    | class_selector
    | at_keyword
    | '&'
    | '%'
    | pseudo_class
    | pseudo_element
    | attribute_selector
    | child_selector
    | adjacent_selector
    | universal_selector
    | parens   # for interpolation
    | interpolated_variable
    | color
    | percent
    | important
  )
  { debug($thisline, @item); $return = join '', @{$item[1]}, $item[2] }

namespace_prefix: (ident | '*')(?) '|'
    { debug($thisline, @item); $return = join '', @{$item[1]}, $item[2] }

id_selector: '#' ident
    { debug($thisline, @item); $return = join '', @item[1..2] }

class_selector: '.' ident
    { debug($thisline, @item); $return = join '', @item[1..2] }

pseudo_class:
  ':' ident (parens)(?)
    { debug($thisline, @item); $return = join '', @item[1..2], @{$item[3]} }
  | ':' ident
    { debug($thisline, @item); $return = join '', @item[1..2] }

pseudo_element: '::' ident
    { debug($thisline, @item); $return = join '', @item[1..2] }

universal_selector: '*'
  { debug($thisline, @item); $return = $item[1] }

child_selector: '>'
  { debug($thisline, @item); $return = $item[1] }

adjacent_selector: '+'
  { debug($thisline, @item); $return = $item[1] }

attribute_selector: /\[.+?\]/
  { debug($thisline, @item); $return = $item[1] }

ident: (word | interpolated_variable | escape)(s)
  { debug($thisline, @item); $return = join '', @{$item[1]} }

interpolated_variable:
  '@{' word '}'
    { debug($thisline, @item); $return = join '', @item[1..3] }
  | '@@' word
    { debug($thisline, @item); $return = join '', @item[1..2] }

mixin: selectors semicolon
    { debug($thisline, @item); $return = join '', @item[1..2] }

brace_open: sp '{' sp
  { debug($thisline, @item); $return = join '', @item[1..3] }

brace_close: sp '}' sp
  { debug($thisline, @item); $return = join '', @item[1..3] }

semicolon: sp ';' sp
  { debug($thisline, @item); $return = join '', @item[1..3] }

colon: sp ':' sp
  { debug($thisline, @item); $return = join '', @item[1..3] }

declaration: (property|variable) colon values (semicolon)(?)
  { debug($thisline, @item); $return = {key => $item[1], sep => $item[2], value => $item[3], semicolon => join '', @{$item[4]}} }

property: /[\*]?/ ident
    { debug($thisline, @item); $return = join'', @item[1..2] }

unicode_range: /U\+[0-9a-fA-F?]{1,6}/
  { debug($thisline, @item); $return = $item[1] }

iefilter: 'progid:DXImageTransform.Microsoft.' ident parens
  { debug($thisline, @item); $return = join'', @item[1..3] }

javascript: /~?`[^`]+?`/s
  { debug($thisline, @item); $return = $item[1] }

values: (value | comments | /[, ]/ )(s)
  { debug($thisline, @item); $return = join '', @{$item[1]} }

value: (
    string | url | variable | color | iefilter | javascript
  | unicode_range | expression | percent
  | px | num | function | ident | important
  | sp | unknown
  )(s)
  { debug($thisline, @item); $return = join'', @{$item[1]} }

variable: at_keyword
  { debug($thisline, @item); $return = $item[1] }

important: sp '!' sp 'important'
  { debug($thisline, @item); $return = join'', @item[1..4] }

url_string: (/[!#$%&*\-\[:\/\.\?=\]~,]|[a-zA-Z0-9_]/ | nonascii | escape)(s)
  { debug($thisline, @item); $return = join'', @{$item[1]} }

url: 'url(' sp (url_string | string) sp ')'
  { debug($thisline, @item); $return = join'', @item[1..5] }

function: selector parens
  { debug($thisline, @item); $return = join '', @item[1..2] }

num: /[0-9\.\-]+[a-z]*/
  { debug($thisline, @item); $return = $item[1] }

op: /\s*[\+\*\/\-,<>=]\s*/
  { debug($thisline, @item); $return = $item[1] }

url: /url\([^)]+?\)/
  { debug($thisline, @item); $return = $item[1] }

paren_open: '('
  { debug($thisline, @item); $return = $item[1] }

paren_close: ')'
  { debug($thisline, @item); $return = $item[1] }

arg: parens | variable | op | color | px | percent | num | function | string | ident | colon | attribute_selector
  { debug($thisline, @item); $return = $item[1] }

parens: paren_open (arg | /[;, ]/ | sp)(s?) paren_close
  { debug($thisline, @item); $return = join '', $item[1], @{$item[2]}, $item[3] }
expression: (variable | percent | px | num | op | parens)(s)
  { debug($thisline, @item); $return = join '', @{$item[1]} }

px: /[0-9]+px/
  { debug($thisline, @item); $return = $item[1] }

percent: /[0-9\.\-]+%/
  { debug($thisline, @item); $return = $item[1] }

color: /#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})/
  { debug($thisline, @item); $return = $item[1] }

string: string1 | string2
  { debug($thisline, @item); $return = $item[1] }

string1: /~?"/ ( /[^\n\r\f\\"]/ | escaped_nl | escape )(s?) /"/
  { debug($thisline, @item); $return = join '', $item[1], @{$item[2]}, $item[3] }

string2: /~?'/ ( /[^\n\r\f\\']/ | escaped_nl | escape )(s?) /'/
  { debug($thisline, @item); $return = join '', $item[1], @{$item[2]}, $item[3] }

unicode: '\\' /[0-9a-fA-F]{1,6}(\r\n|[ \n\r\f\t])?/
  { debug($thisline, @item); $return = join '', @item[1..2] }

word: /[-]?/ nmstart nmchar(s?)
  { debug($thisline, @item); $return = join '', @item[1..2], @{$item[3]} }

nmstart: /[_a-zA-Z]/ | nonascii | escape
  { debug($thisline, @item); $return = $item[1] }

name: nmchar(s)
  { debug($thisline, @item); $return = join '', @{$item[1]} }

nmchar: /[_a-zA-Z0-9\-]/ | nonascii | escape
  { debug($thisline, @item); $return = $item[1] }

nonascii: /[^\0-\237]/
  { debug($thisline, @item); $return = $item[1] }

escape:
  unicode
    { debug($thisline, @item); $return = $item[1] }
  | '\\' /[^\n\r\f0-9a-fA-F]/
    { debug($thisline, @item); $return = join '', @item[1..2] }

escaped_nl: '\\' nl
    { debug($thisline, @item); $return = join '', @item[1..2] }

nl: "\n" | "\r\n" | "\r" | "\f"
  { debug($thisline, @item); $return = $item[1] }

sp: /[ \t\r\n]*/
  { debug($thisline, @item); $return = $item[1] }

unknown: /./s
  { warn dump @item; $return = $item[1] }

GRAMMAR
}

1;

__END__

=head1 NAME

CSS::LESS::Filter - tweak CSS/LESS files such as of Twitter Bootstrap

=head1 SYNOPSIS

  use CSS::LESS::Filter;
  use Path::Extended;
  
  my $filter = CSS::LESS::Filter->new;
  
  # simply set a new property value
  $filter->add('.highlight { color:' => '#ff6600');
  
  # tweak a property value more liberally
  $filter->add('.highlight { background-image:' => sub {
    my $value = shift;
    $value =~ s/#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/#$3$1$2/;
    $value;
  });
  
  # Want to tweak the whole ruleset?
  $filter->add('.dropdown {' => sub {
    my $inside = shift;
    return "// this is added by CSS::LESS::Filter\n$inside";
  });
  
  # remove every ruleset that matches .ie class
  # (returning undef removes the declaration/ruleset entirely)
  $filter->add(qr/\.ie \{/ => undef);
  
  # You can also tweak an "@" rule, but take care: the same "@" rule
  # may (and often) be seen several times in the same context.
  # You most probably need to check its value in a callback.
  $filter->add('@import' => sub {
    my $value = shift;
    return if $value eq q{"foo.less"}; # not to @import "foo.less";
    $value; # preserve the rest
  });
  
  # parse LESS, apply filters, and return the modified LESS
  my $file = file('less/docs.less');
  my $less = $file->slurp;
  $file->save($filter->process($less, {mode => 'append'}));

=head1 DESCRIPTION

Twitter Bootstrap is nice and handy. You can also customize its
various aspects fairly easily. However, its LESS files still have
fixed values which you probably need to tweak by hand every time
you update.

L<CSS::LESS::Filter> makes this tweak easier.

=head1 METHODS

=head2 new

Creates an object. May take filter settings (see below).

=head2 add

Adds a filter. See SYNOPSIS for basic usage. Selectors are
concatenated with a ' { ' (space, brace, space), and declaration
property has a trailing ':' (colon). @ rules have no trailing colon.
You can use regular expressions to match multiple selectors, though
with some speed penalty. (Note that you may eventually need to
escape '{' to suppress future warnings.)

If you just want to append something at the end of a less file,
pass an empty string as a selector.

  # this comment will be appended at the end.
  $filter->add('' => "// whatever you want to add\n");

=head2 process

takes LESS content, parses it to apply filters, and returns
the result. Optionally, you can pass a hash reference to change
filter's behavior. As of version 0.03, only available option is
C<mode>:

=over 4

=item mode => 'warn'

L<CSS::LESS::Filter> warns if any of the filters are not used.
Those unmatched filters will be ignored.

=item mode => 'append'

Under this mode, unmatched filters are used to append things at the
end of the processed LESS. L<CSS::LESS::Filter> still warns if
any filter that uses a regular expression fails.

=back

=head1 NOTE

L<CSS::LESS::Filter> only supports LESS to LESS (or CSS to CSS)
filtering. You still need to use "less.js" or its variants to
convert LESS into CSS.

=head1 SEE ALSO

L<http://lesscss.org/>

L<http://www.w3.org/TR/CSS/>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
