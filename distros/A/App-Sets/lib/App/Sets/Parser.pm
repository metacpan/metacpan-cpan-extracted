package App::Sets::Parser;
$App::Sets::Parser::VERSION = '0.976';


use strict;
use warnings;
use Carp;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

# ABSTRACT: parse input expressions of operations on sets


sub parse {
   my ($string) = @_;
   my $retval = first($string, 0);
   my ($expression, $pos) = $retval ? @$retval : (undef, 0);
   return $expression if $pos == length $string;

   my $offending = substr $string, $pos;

   my ($spaces) = $offending =~ s{\A(\s+)}{}mxs;
   $pos += length $spaces;

   my $nchars = 23;
   $offending = substr($offending, 0, $nchars - 3) . '...'
     if length($offending) > $nchars;

   LOGDIE "parse error at char $pos --> $offending\n",;
} ## end sub parse

sub lrx_head {
   my $sequence = _sequence(@_);
   return sub {
      my $retval = $sequence->(@_)
        or return;
      my ($struct, $pos) = @$retval;
      my ($second, $first_tail) = @{$struct}[1, 3];
      if (defined $first_tail->[0]) {
         my ($root, $parent) = @{$first_tail->[0]};
         $parent->[1] = $second->[0];
         $struct = $root;
      }
      else {
         $struct = $second->[0];
      }
      return [$struct, $pos];
     }
} ## end sub lrx_head

sub lrx_tail {
   my $sequence = _sequence('optws', _alternation(_sequence(@_), 'empty'));
   return sub {
      my $retval = $sequence->(@_)
        or return;
      my ($struct, $pos) = @$retval;
      $retval = $struct->[1];
      if (!defined $retval->[0]) {
         $retval = undef;
      }
      else {    # not empty
         my ($op, $second, $tail) = @{$retval->[0]}[0, 2, 4];
         my $node = [$op->[0], undef, $second->[0]];
         if (defined $tail->[0]) {
            my ($root, $parent) = @{$tail->[0]};
            $parent->[1] = $node;    # link leaf to parent node
            $retval = [$root, $node];
         }
         else {
            $retval = [$node, $node];
         }
      } ## end else [ if (!defined $retval->...
      return [$retval, $pos];
     }
} ## end sub lrx_tail

sub first {
   return lrx_head(qw< optws second optws first_tail optws >)->(@_);
}

sub first_tail {
   return lrx_tail(qw< op_subtract optws second optws first_tail optws >)
     ->(@_);
}

sub second {
   return lrx_head(qw< optws third optws second_tail optws >)->(@_);
}

sub second_tail {
   return lrx_tail(qw< op_union optws third optws second_tail optws >)
     ->(@_);
}

sub third {
   return lrx_head(qw< optws fourth optws third_tail optws >)->(@_);
}

sub third_tail {
   return lrx_tail(qw< op_intersect optws fourth optws third_tail optws >)
     ->(@_);
}

sub fourth {
   my $retval = _sequence(
      'optws',
      _alternation(
         _sequence(_string('('), qw< optws first optws >, _string(')')),
         'filename',
      ),
      'optws'
     )->(@_)
     or return;
   my ($struct, $pos) = @$retval;
   my $meat = $struct->[1];
   if (ref($meat->[0])) {
      $retval = $meat->[0][2][0];
   }
   else {
      $retval = $meat->[0];
   }
   return [$retval, $pos];
} ## end sub fourth

sub _op {
   my ($regex, $retval, $string, $pos) = @_;
   pos($string) = $pos;
   return unless $string =~ m{\G($regex)}cgmxs;
   return [$retval, pos($string)];
} ## end sub _op

sub op_intersect {
   return _op(qr{(?:intersect|[iI&^])}, 'intersect', @_);
}

sub op_union {
   return _op(qr{(?:union|[uUvV|+])}, 'union', @_);
}

sub op_subtract {
   return _op(qr{(?:minus|less|[\\-])}, 'minus', @_);
}

sub filename {
   my ($string, $pos) = @_;
   DEBUG "filename() >$string< $pos";
   pos($string) = $pos;
   my $retval;
   if (($retval) = $string =~ m{\G ' ( [^']+ ) '}cgmxs) {
      return [$retval, pos($string)];
   }
   elsif (($retval) = $string =~ m{\G " ( (?: \\. | [^"])+ ) "}cgmxs) {
      $retval =~ s{\\(.)}{$1}gmxs;
      return [$retval, pos($string)];
   }
   elsif (($retval) = $string =~ m{\G ( (?: \\. | [\w.-/])+ )}cgmxs) {
      $retval =~ s{\\(.)}{$1}gmxs;
      return [$retval, pos($string)];
   }
   return;
} ## end sub filename

sub empty {
   my ($string, $pos) = @_;
   return [undef, $pos];
}

sub is_empty {
   my ($struct) = @_;
   return @{$struct->[0]} > 0;
}

sub ws {
   my ($string, $pos) = @_;
   pos($string) = $pos;
   my ($retval) = $string =~ m{\G (\s+)}cgmxs
     or return;
   return [$retval, pos($string)];
} ## end sub ws

sub optws {
   my ($string, $pos) = @_;
   pos($string) = $pos;
   my ($retval) = $string =~ m{\G (\s*)}cgmxs;
   $retval = [$retval || '', pos($string)];
   return $retval;
} ## end sub optws

sub _string {
   my ($target) = @_;
   my $len = length $target;
   return sub {
      my ($string, $pos) = @_;
      return unless substr($string, $pos, $len) eq $target;
      return [$target, $pos + $len];
     }
} ## end sub _string

sub _alternation {
   my @subs = _resolve(@_);
   return sub {
      my ($string, $pos) = @_;
      for my $sub (@subs) {
         my $retval = $sub->($string, $pos) || next;
         return $retval;
      }
      return;
   };
} ## end sub _alternation

sub _sequence {
   my @subs = _resolve(@_);
   return sub {
      my ($string, $pos) = @_;
      my @chunks;
      for my $sub (@subs) {
         my $chunk = $sub->($string, $pos)
           or return;
         push @chunks, $chunk;
         $pos = $chunk->[1];
      } ## end for my $sub (@subs)
      return [\@chunks, $pos];
   };
} ## end sub _sequence

sub _resolve {
   return
     map { ref $_ ? $_ : __PACKAGE__->can($_) || LOGDIE "unknown $_" } @_;
}

1;

__END__

=pod

=head1 NAME

App::Sets::Parser - parse input expressions of operations on sets

=head1 VERSION

version 0.976

=begin grammar

   parse: first
   first:  first  op_difference second | second
   second: second op_union      third  | third
   third:  third  op_intersect  fourth | fourth

   fourth: '(' first ')' | filename

   filename: double_quoted_filename 
           | single_quoted_filename
           | unquoted_filename
   ...

 Left recursion elimination

   first:      second first_tail
   first_tail: <empty> | op_intersect second first_tail

   second:      third second_tail
   second_tail: <empty> | op_union third second_tail

   third:      fourth third_tail
   third_tail: <empty> | op_difference fourth third_tail

=end grammar

=cut
=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Flavio Poletti polettix@cpan.org.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
