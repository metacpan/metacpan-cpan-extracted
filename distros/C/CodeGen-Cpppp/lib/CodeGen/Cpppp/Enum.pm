package CodeGen::Cpppp::Enum;

our $VERSION = '0.004'; # VERSION
# ABSTRACT: Helper for enumerations and generating related utility functions

use v5.20;
use warnings;
use Carp;
use experimental 'signatures', 'lexical_subs', 'postderef';
use Scalar::Util 'looks_like_number';
use List::Util 'any', 'min', 'max', 'uniqstr';
use CodeGen::Cpppp::CParser;


sub new($class, %attrs) {
   my $self= bless {}, $class;
   # apply num_format first because it affects set_values
   $self->num_format(delete $attrs{num_format})
      if exists $attrs{num_format};
   $self->$_($attrs{$_}) for keys %attrs;
   return $self;
}


sub prefix($self, @val) {
   if (@val) { $self->{prefix}= $val[0]; return $self }
   $self->{prefix} // ''
}

sub macro_prefix($self, @val) {
   if (@val) { $self->{macro_prefix}= $val[0]; return $self }
   $self->{macro_prefix} // uc($self->prefix);
}

sub symbol_prefix($self, @val) {
   if (@val) { $self->{symbol_prefix}= $val[0]; return $self }
   $self->{symbol_prefix} // lc($self->prefix);
}

sub type($self, @val) {
   if (@val) { $self->{type}= $val[0]; return $self; }
   $self->{type} // 'int';
}

sub values($self, @val) {
   return $self->set_values(@val) if @val;
   @{ $self->{values} // [] }
}

sub set_values($self, @spec) {
   my @values;
   for (@spec == 1 && ref $spec[0]? @{$spec[0]} : @spec) {
      if ('ARRAY' eq ref) {
         push @values, [ @$_ ];
      } elsif (/^\w+$/) {
         push @values, [ $_ ];
      } else {
         defined $values[-1] or croak "Got an enum value '$_' before a name";
         defined $values[-1][1] and croak "'$_' is not a valid enum name";
         $values[-1][1]= $_;
      }
   }
   # Fill in missing values with next sequential integer
   my $prev= $values[0][1] //= 0;
   for (@values[1..$#values]) {
      if (!defined $_->[1]) {
         my ($base, $ofs, $fmt)= $self->_parse_value_expr($prev);
         $_->[1]= sprintf $fmt, $ofs+1;
      }
      $prev= $_->[1];
   }
   $self->{values}= \@values;
   $self->{_analysis}= undef;
   $self;
}

sub value_table_var($self, @val) {
   if (@val) {
      $self->{value_table_var}= $val[0];
      return $self;
   }
   $self->{value_table_var} // $self->symbol_prefix . 'value_table';
}

sub indent($self, @val) {
   if (@val) {
      $self->{indent}= $val[0];
      return $self;
   }
   $self->{indent} // '   ';
}

sub _current_indent {
   $CodeGen::Cpppp::INDENT // shift->indent;
}

sub num_format($self, @val) {
   if (@val) {
      $self->{num_format}= $val[0];
      $self->{_analysis}= undef;
      return $self;
   }
   $self->{num_format} // '%d';
}

sub max_waste_factor($self, @val) {
   if (@val) {
      $self->{max_waste_factor}= $val[0];
      $self->{_analysis}= undef;
      return $self;
   }
   $self->{max_waste_factor} // 2;
}


our %_algorithm= map +( $_ => 1 ), qw( bsearch hashtable switch );
sub algorithm($self, @val) {
   if (@val) {
      !defined $val[0] or $_algorithm{$val[0]}
         or croak "Unknown parse_design '$val[0]', expected one of ".join(', ', keys %_algorithm);
      $self->{algorithm}= $val[0];
      return $self;
   }
   $self->{algorithm}
}

sub _parse_value_expr($self, $val) {
   # Make the common case fast
   return '', +$val, '%d'
      if $val =~ /^[-+]?(?:0|[1-9][0-9]*)\Z/;
   # else need to parse the expression
   my @tokens= CodeGen::Cpppp::CParser->tokenize($val);
   my $type_pattern= join '', map $_->type, @tokens;
   # Recognize patterns where a +N occurs at the end of the expression
   # Else, the whole value is the expression and will get '+N' appended.
   return $val, 0, "($val+".($self->{num_format}//'%d').")"
      unless $type_pattern =~ /(^|[-+])integer\W*$/;
   my $context= $1;
   # walk backward to last 'integer' token
   my $i= $#tokens;
   $i-- while $tokens[$i]->type ne 'integer';
   # could be start of string, -N, +N, EXPR-N, EXPR+N, or EXPR OP -N
   my $fmt_str= $val;
   my ($pos, $pos2)= ($tokens[$i]->src_pos, $tokens[$i]->src_pos+$tokens[$i]->src_len);
   my $n= $tokens[$i]->value;
   # If start of string or preceeded by '+', nothing to do.
   # If preceeded by '-', need to convert that to '+' in format string
   if ($context eq '-') {
      $n= -$n;
      $pos= $tokens[$i-1]->src_pos + 1;
      substr($fmt_str, $tokens[$i-1]->src_pos, 1, '+');
   }
   my $num_str= substr($val, $tokens[$i]->src_pos, $tokens[$i]->src_len);
   my $notation= $self->{num_format}
      // $num_str =~ /^-?0x[0-9A-F]+$/? 'X'
       : $num_str =~ /^-?0x[0-9a-f]+$/? 'x'
       : $num_str =~ /^-?0[0-9]+/? 'o'
       : 'd';
   substr($fmt_str, $pos, $pos2-$pos, '%'.($pos2-$pos).$notation);
   # The "base" is everying to the left of the number minus the number of "("
   #  to match the number of ")" to the right of the number
   my $rparen= grep $_->type eq ')', @tokens[$i..$#tokens];
   shift @tokens while $tokens[0]->type eq '(' && $rparen--;
   my $base= substr($val, $tokens[0]->src_pos, $pos-$tokens[0]->src_pos);
   return ($base, $n, $fmt_str);
}


sub is_symbolic($self) {
   $self->_analysis->{base_expr} ne '';
}

sub is_sequential($self) {
   $self->_analysis->{is_seq}
}

sub is_nearly_sequential($self) {
   $self->_analysis->{is_nearly_seq}
}

sub _analysis($self) {
   $self->{_analysis} //= do {
      my @vals= map +[ $_->[0], $self->_parse_value_expr($_->[1]) ], $self->values;
      my $base_expr= $vals[0][1];
      my %seen_ofs= ( $vals[0][2] => 1 );
      for (@vals[1..$#vals]) {
         # Can't be sequential unless they share a symbolic base expression
         $base_expr= undef, last
            unless $_->[1] eq $base_expr;
         $seen_ofs{$_->[2]}++;
      }
      my %info= (
         vals => \@vals
      );
      if (defined $base_expr) {
         # Find the min/max
         my ($min, $max)= (min(keys %seen_ofs), max(keys %seen_ofs));
         # Is it sequential?
         my ($is_seq, $is_nearly_seq, $gap);
         # don't iterate unless the range is reasonable
         if (($max - $min - @vals) <= $self->max_waste_factor * @vals) {
            $gap= 0;
            for ($min .. $max) {
               $gap++ unless $seen_ofs{$_};
            }
            $is_seq= $gap == 0;
            $is_nearly_seq= $gap <= $self->max_waste_factor * ($max-$min+1-$gap);
         }
         $info{is_seq}= $is_seq;
         $info{is_nearly_seq}= $is_nearly_seq;
         $info{gap}= $gap;
         $info{min}= $min;
         $info{max}= $max;
         $info{base_expr}= $base_expr;
      }
      \%info
   };
}


sub generate_declaration($self, %options) {
   return join "\n", $self->_generate_declaration_macros(\%options);
}

sub _generate_declaration_macros($self, $options) {
   my @vals= $self->values;
   my $name_width= max map length($_->[0]), @vals;
   my $prefix= $self->macro_prefix;
   my $fmt= "#define $prefix%-${name_width}s %s";
   return map sprintf($fmt, $_->[0], $_->[1]), @vals;
}


sub generate_static_tables($self, %options) {
   return join "\n", _generate_enum_table($self, \%options);
}

sub _generate_enum_table($self, $options) {
   my $prefix= $self->prefix;
   my @names= map $prefix . $_->[0], $self->values;
   my $name_width= max map length, @names;
   my $indent= $self->_current_indent;
   my $fmt= $indent.$indent.'{ "%s",%*s %s },';
   my @code= (
      "const struct { const char *name; const ".$self->type." value; }",
      $indent . $self->value_table_var . "[] = {",
      (map sprintf($fmt, $_, $name_width-length, '', $_), @names),
      $indent . '};'
   );
   substr($code[-2], -1, 1, ''); # remove trailing comma
   return @code;
}


sub generate_lookup_by_value($self, %options) {
   return join "\n", $self->_generate_lookup_by_value_switch(\%options);
}

sub _generate_lookup_by_value_switch($self, $options) {
   my @vals= $self->values;
   my $name_width= max map length($_->[0]), @vals;
   my $info= $self->_analysis;
   my $val_variable= 'value';
   my $prefix= $self->macro_prefix;
   my $enum_table= $self->value_table_var;
   # Generate a switch() table to look them up
   my @code= "switch ($val_variable) {";
   my $fmt=  "case $prefix%s:%*s return ${enum_table}[%d].name;";
   for (0..$#vals) {
      push @code, sprintf($fmt, $vals[$_][0], $name_width - length($vals[$_][0]), '', $_);
   }
   push @code, 'default: return NULL;', '}';
   return @code;
}


sub generate_lookup_by_name($self, %options) {
   return join "\n", $self->_generate_lookup_by_name_switch(\%options);
}

sub _generate_lookup_by_name_switch($self, $options) {
   my @vals= $self->values;
   my $info= $self->_analysis;
   my $caseless= $options->{caseless};
   my $prefixless= $options->{prefixless};
   my $prefixlen= length($self->macro_prefix);
   my $indent= $self->_current_indent;
   my $len_var= $options->{len_var} // 'len';
   my $str_ptr= $options->{str_ptr} // 'str';
   my $enum_table= $self->value_table_var;
   my $strcmp= $caseless? "strcasecmp" : "strcmp";
   my $idx_type= @vals <= 0x7F? 'int8_t'
      : @vals <= 0x7FFF? 'int16_t'
      : @vals <= 0x7FFFFFFF? 'int32_t'
      : 'int64_t';
   my @search_set;
   for (0..$#vals) {
      push @search_set, [ $self->macro_prefix . $vals[$_][0], $_ ];
      push @search_set, [ $vals[$_][0], -$_ ] if $prefixless;
   }
   my %by_len;
   for (@search_set) {
      push @{ $by_len{length $_->[0]} }, $_;
   }
   my $longest= max(keys %by_len);
   my @code= (
      "$idx_type test_el= 0;",
      ("char str_buf[$longest+1];")x!!$caseless,
      "switch ($len_var) {",
   );
   # Generate one binary decision tree for each string length
   for (sort { $a <=> $b } keys %by_len) {
      my %pivot_pos;
      my @split_expr= $self->_binary_split($by_len{$_}, $caseless, $caseless? 'str_buf' : $str_ptr, \%pivot_pos);
      push @code,
         "case $_:",
         ($caseless? (
            map "${indent}str_buf[$_]= tolower(${str_ptr}[$_]);",
               sort { $a <=> $b } keys %pivot_pos
         ) : ()),
         (map "$indent$_", @split_expr),
         "${indent}break;",
   }
   push @code,
      "default:",
      "${indent}return false;",
      "}";
   # If allowing prefixless match, some test_el will be negative, meaning to
   # test str+prefixlen
   if ($prefixless) {
      push @code,
         "if (test_el < 0) {",
         "${indent}if ($strcmp($str_ptr, ${enum_table}[-test_el].name + $prefixlen) == 0) {",
         "${indent}${indent}if (value_out) *value_out= ${enum_table}[-test_el].value;",
         "${indent}${indent}return true;",
         "${indent}}",
         "${indent}return false;",
         "}";
   }
   push @code,
      "if ($strcmp($str_ptr, ${enum_table}[test_el].name) == 0) {",
      "${indent}if (value_out) *value_out= ${enum_table}[test_el].value;",
      "${indent}return true;",
      "}",
      "return false;";
   return @code;
}

sub _binary_split($self, $vals, $caseless, $str_var, $pivot_pos) {
   # Stop at length 1
   return qq{test_el= $vals->[0][1];}
      if @$vals == 1;
   # Find a character comparison that splits the list roughly in half.
   my $goal= .5 * scalar @$vals;
   # Test every possible character and keep track of the best.
   my ($best_i, $best_ch, $best_less);
   for (my $i= 0; $i < length $vals->[0][0]; ++$i) {
      if (!$caseless) {
         for my $ch (uniqstr map substr($_->[0], $i, 1), @$vals) {
            my @less= grep substr($_->[0], $i, 1) lt $ch, @$vals;
            ($best_i, $best_ch, $best_less)= ($i, $ch, \@less)
               if !defined $best_i || abs($goal - @less) < abs($goal - @$best_less);
         }
      } else {
         for my $ch (uniqstr map lc substr($_->[0], $i, 1), @$vals) {
            my @less= grep +(lc(substr($_->[0], $i, 1)) lt $ch), @$vals;
            ($best_i, $best_ch, $best_less)= ($i, $ch, \@less)
               if !defined $best_i || abs($goal - @less) < abs($goal - @$best_less);
         }
      }
   }
   $pivot_pos->{$best_i}++; # inform caller of which chars were used
   # Binary split the things less than the pivot character
   my @less_src= $self->_binary_split($best_less, $caseless, $str_var, $pivot_pos);
   # Binary split the things greater-or-equal to the pivot character
   my %less= map +($_->[0] => 1), @$best_less;
   my @ge_src= $self->_binary_split([ grep !$less{$_->[0]}, @$vals ], $caseless, $str_var, $pivot_pos);
   my $indent= $self->_current_indent;
   return (
      "if (${str_var}[$best_i] < '$best_ch') {",
      (map $indent.$_, @less_src),
      (@ge_src > 1
         # combine "else { if"
         ? ( '} else '.$ge_src[0], @ge_src[1..$#ge_src] )
         # else { statement }
         : ( '} else {', (map $indent.$_, @ge_src), '}' )
      )
   );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Cpppp::Enum - Helper for enumerations and generating related utility functions

=head1 SYNOPSIS

  ## my $enum= CodeGen::Cpppp::Enum->new(
  ##   prefix => 'MYENUM_', type => 'int', values => q(
  ##     VAL_1      1
  ##     VAL_2
  ##     ALT_VAL
  ##     SOME_VAL
  ##     OTHER_VAL  1<<10
  ##     NONE       -1
  ## ));
  ## section PUBLIC;
  
  ${{ $enum->generate_declaration }}
  
  extern const char * myenum_name(int value);
  extern bool myenum_parse(const char *str, size_t len, int *value_out);
  
  ## section PRIVATE;

  ${{ $enum->generate_static_tables }}

  const char * myenum_name(int value) {
    ${{ $enum->generate_lookup_by_value }}
  }
  
  bool myenum_parse(const char *str, size_t len, int *value_out) {
    ${{ $enum->generate_lookup_by_name }}
  }

=head1 DESCRIPTION

This utility module helps you generate C code for enumerations.

First, you create an instance of this object and load it with a list of enum
values.  These can come from a supplied list, or you can parse a header to find
them.  This module supports multiple names with the same value, but not
multiple values with the same name.

Next, you can generate the definition of the enum as either C<#define> macros or
a C++ C<< enum { ... } >> syntax.

This also can generate code that looks up the name by the value, or parses a
name to get the value.  The header would generally look like:

  #define EXAMPLE_1 1
  #define EXAMPLE_2 2
  
  // Returns true if found a match
  extern bool example_parse(const char *ch, int len, int *value_out);
  extern const char *example_name(int enum_val);

There are several implementations to choose from, and a sensible one will be
chosen by default based on the patterns in your enum values.

=head1 CONSTRUCTOR

=head2 new

Standard constructor.  Pass values for any of the non-readonly attributes below.

=head1 ATTRIBUTES

=head2 prefix

String to be prefixed onto each name of the enum.  You may then optionally
allow name lookups that match strings without the prefix as well as ones that
include it.

=head2 type

Defaults to 'int'.

=head2 values

Returns a list of C<< [ $name, $value ] >>.  You can initialize it with a list
or arrayref containing C<$name> or C<< [ $name, $value ] >>.  Any element
without a value will get the next sequential value from the previous entry,
starting from 0.

=head2 value_table_var

C Variable name of the constant which holds the official list of enum values.

=head2 indent

Set to a literal string to use for each level of indent in generated code.

=head2 num_format

Controls formatting of integers, as decimal or hex.  Can be any single
placeholder known to sprintf, like '%d', '%x', or '%X'.

=head2 max_waste_ratio

Permissible ratio of empty lookup table elements vs. populated elements.
If there would be more empty cells than that, a different algorithm will be
chosen.  The default is 2, meaning that the table must be at least 1/3
populated.

=head2 algorithm

One of 'bsearch', 'hashtable', 'switch'.

For each, the enum is stored in an array of string/value pairs (unless the
values match the array index, then they get omitted).  If this happens to be
the sorted order of the names or sorted order of the values, those
optimizations are taken into account.  Otherwise, the algorithm operates as
follows:

=over

=item bsearch

Secondary arrays of integers are built that refer back to the enum array.
These arrays are searched during name or value lookups using the C library
C<bsearch> function.  This results in the least space usage.

=item hashtable

Hash tables will be built that refer back to the enum array.  Hash function
constants will be chosen to provide the fewest number of collisions possible.
This results in good performance without much added code.

=item switch

The lookup functions will be built using a combination of C 'switch' statements
and binary character-comparison 'if' statements.  This results in the absolute
fastest performance, but may generate a fair amount of parsing code.

=back

=head2 is_symbolic

True if one if your values is an expression instead of a constant integer.
In this case, only the switch algorithm can be used for lookups.

=head2 is_sequential

Read-only, calculated by whether all the values have adjacent numeric values.

=head2 is_sequentialish

Read-only, calculated by whether all the values can be stored in an array at
the offset of their numeric value without wasting more than C<max_waste_factor>
elements.

=head2 generate_declaration

  @code_lines= $enum->generate_declaration(%options);

Return either a list of C<< #define NAME ... >> or the lines of a C++ 
C<< enum Foo { ... } >>.

=head2 generate_static_tables

  @code_lines= $enum->generate_static_tables(%options);

Return lines of code that declare the tables needed for the lookups.  This
always includes a table in the same order as the declaration of the enum values,
but may also include additional hash tables or lookup tables to represent the
values in alphabetical order.

=head2 generate_lookup_by_value

  @code_lines= $enum->generate_lookup_by_value(%options);

Return lines of code that return a C<< const char * >> of the name associated 
with a value.  The variable holding the value is named 'value' by default, and
the implementation returns NULL if this value does not have a name.

=head2 generate_lookup_by_name

  @code_lines= $enum->generate_lookup_by_name(%options);

Return lines of code that take a name in a variable C<str>, C<len> bytes long,
and store the enum value for that name into a variable C<value_out> and then
return true (if found) or false if not found.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.004

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
