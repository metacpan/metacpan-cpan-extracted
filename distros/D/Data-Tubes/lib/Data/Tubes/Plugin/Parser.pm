package Data::Tubes::Plugin::Parser;
use strict;
use warnings;
use English qw< -no_match_vars >;
use Data::Dumper;
our $VERSION = '0.738';

use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

use Data::Tubes::Util qw<
  assert_all_different
  generalized_hashy
  metadata
  normalize_args
  shorter_sub_names
  test_all_equal
  trim
  unzip
>;
use Data::Tubes::Plugin::Util qw< identify >;
my %global_defaults = (
   input  => 'raw',
   output => 'structured',
);

sub parse_by_format {
   my %args = normalize_args(@_,
      [{%global_defaults, name => 'parse by format'}, 'format']);
   identify(\%args);

   my $format = $args{format};
   LOGDIE "parser of type 'format' needs a definition"
     unless defined $format;

   my @items = split m{(\W+)}, $format;
   return parse_single(key => $items[0]) if @items == 1;

   my ($keys, $separators) = unzip(\@items);

   # all keys MUST be different, otherwise some fields are just trumping
   # on each other
   eval { assert_all_different($keys); }
     or LOGDIE "'format' parser [$format] "
     . "has duplicate key $EVAL_ERROR->{message}";

   my $value = $args{value} //= ['whatever'];
   $value = [$value] unless ref $value;
   my $multiple =
        (ref($value) ne 'ARRAY')
     || (scalar(@$value) > 1)
     || ($value->[0] ne 'whatever');

   return parse_by_separators(
      %args,
      keys       => $keys,
      separators => $separators
   ) if $multiple || !test_all_equal(@$separators);

   # a simple split will do if all separators are the same
   return parse_by_split(
      %args,
      keys      => $keys,
      separator => $separators->[0]
   );
} ## end sub parse_by_format

sub parse_by_regex {
   my %args =
     normalize_args(@_,
      [{%global_defaults, name => 'parse by regex'}, 'regex']);
   identify(\%args);

   my $name  = $args{name};
   my $regex = $args{regex};
   LOGDIE "parse_by_regex needs a regex"
     unless defined $regex;

   $regex = qr{$regex};
   my $input  = $args{input};
   my $output = $args{output};
   return sub {
      my $record = shift;
      $record->{$input} =~ m{$regex}
        or die {
         message => "'$name': invalid record, regex is $regex",
         input   => $input,
         record  => $record,
        };
      my $retval = {%+};
      $record->{$output} = $retval;
      return $record;
   };
} ## end sub parse_by_regex

sub _resolve_separator {
   my ($separator, $args) = @_;
   return unless defined $separator;
   $separator = $separator->($args) if ref($separator) eq 'CODE';
   my $ref = ref $separator;
   return $separator if $ref eq 'Regexp';
   LOGCROAK "$args->{name}: unknown separator type $ref" if $ref;
   $separator = quotemeta $separator;
   return qr{(?-i:$separator)};
} ## end sub _resolve_separator

sub _resolve_value {
   my ($value, $args) = @_;
   $value //= 'whatever';
   $value = $value->($args) if ref($value) eq 'CODE';
   my $ref = ref $value;
   ($value, $ref) = ([$value], 'ARRAY') if (!$ref) || ($ref eq 'Regexp');
   LOGCROAK "$args->{name}: unknown value type $ref" if $ref ne 'ARRAY';

   my (%flag_for, @regexps);
   for my $part (@$value) {
      my $ref = ref $part;
      if ($ref eq 'Regexp') {
         push @regexps, $part;
      }
      elsif (
         $part =~ m{\A(?:
              (?:single|double)[-_]quoted 
            | escaped
            | whatever
            )\z}mxs
        )
      {
         $part =~ s{-}{_}mxs;
         $flag_for{$part} = 1;
      } ## end elsif ($part =~ m{\A(?: )})
      elsif ($part eq 'quoted') {
         $flag_for{single_quoted} = 1;
         $flag_for{double_quoted} = 1;
      }
      elsif ($part eq 'specials') {
         $flag_for{single_quoted} = 1;
         $flag_for{double_quoted} = 1;
         $flag_for{escaped}       = 1;
      }
      elsif ($ref) {
         LOGCROAK "$args->{name}: unknown part of type $ref";
      }
      else {
         LOGCROAK "$args->{name}: unknown part $part";
      }
   } ## end for my $part (@$value)

   my @escape;
   if ($flag_for{single_quoted}) {
      push @escape, q{'};
      unshift @regexps, q{(?mxs: '[^']*' )};
   }
   if ($flag_for{double_quoted}) {
      push @escape, q{"};
      unshift @regexps, q{(?mxs: "(?: [^\\"] | \\\\.)*" )};
   }
   if ($flag_for{escaped}) {
      push @escape, '\\';
      my $escape = quotemeta join '', @escape;
      push @regexps, qq{(?mxs-i: (?: [^$escape] | \\\\.)*?)};
   }
   if ($flag_for{whatever}) {
      push @regexps, qq{(?mxs:.*?)};
   }

   my $regex = '(' . join('|', @regexps) . ')';
   return ($regex, \%flag_for);
} ## end sub _resolve_value

sub _resolve_decode {
   my $args    = shift;
   my $name    = $args->{name};
   my $escape  = $args->{escaped};
   my $squote  = $args->{single_quoted};
   my $dquote  = $args->{double_quoted};
   my $vdecode = $args->{decode};
   my $decode  = $args->{decode_values};
   if ($vdecode) {
      $decode ||= sub {
         my $values = shift;
         for my $value (@$values) {
            $value = $vdecode->($value);
         }
         return $values;
        }
   } ## end if ($vdecode)
   elsif ($escape || $squote || $dquote) {
      $decode ||= sub {
         my $values = shift;
         for my $i (0 .. $#$values) {
            my $value = $values->[$i];
            my $len   = length $value or next;
            my $first = substr $value, 0, 1;
            if ($dquote && $first eq q{"}) {
               die {message => "'$name': invalid record, "
                    . "unterminated double quote at field $i (0-based)"
                 }
                 unless $len > 1 && substr($value, -1, 1) eq q{"};
               $values->[$i] = substr $value, 1, $len - 2;    # unquote
               $values->[$i] =~ s{\\(.)}{$1}gmxs;             # unescape
            } ## end if ($dquote && $first ...)
            elsif ($squote && $first eq q{'}) {
               die {message => "'$name': invalid record, "
                    . "unterminated single quote at field $i (0-based)",
                 }
                 unless $len > 1 && substr($value, -1, 1) eq q{'};
               $values->[$i] = substr $value, 1, $len - 2;    # unquote
            } ## end elsif ($squote && $first ...)
            elsif ($escape) {
               $values->[$i] =~ s{\\(.)}{$1}gmxs;             # unescape
            }
         } ## end for my $i (0 .. $#$values)
         return $values;
        }
   } ## end elsif ($escape || $squote...)
   return $decode;
} ## end sub _resolve_decode

sub parse_by_separators {
   my %args = normalize_args(@_,
      [{%global_defaults, name => 'parse by separators'}, 'separators']);
   identify(\%args);
   my $name = $args{name};

   my $separators = $args{separators};
   LOGDIE "parse_by_separators needs separators"
     unless defined $separators;
   $separators = [map { _resolve_separator($_, \%args) } @$separators];

   my $keys = $args{keys};
   my ($delta, $n_keys);
   if (defined $keys) {
      $n_keys = scalar @$keys;
      $delta  = $n_keys - scalar(@$separators);
      LOGDIE "parse_by_separators 0 <= #keys - #separators <= 1"
        if ($delta < 0) || ($delta > 1);
   } ## end if (defined $keys)
   else {
      $keys   = [0 .. scalar(@$separators)];
      $n_keys = 0;                             # don't bother
      $delta  = 1;
   }

   my ($value_regex, $flag_for) = _resolve_value($args{value}, \%args);

   my @items;
   for my $i (0 .. $#$keys) {
      push @items, $value_regex;
      push @items, $separators->[$i] if $i <= $#$separators;
   }

   # if not a separator, the last item becomes a catchall
   $items[-1] = '(.*)' if $delta > 0;

   # ready to generate the regexp. We bind the end to \z anyway because
   # the last element might be a separator
   my $format = join '', '(?:\\A', @items, '\\z)';
   my $regex = qr{$format};
   DEBUG "$name: regex will be: $regex";

   # this sub will use the regexp above, do checking and return captured
   # values in a hash with @keys
   my $input  = $args{input};
   my $output = $args{output};
   my $trim   = $args{trim};
   my $decode = _resolve_decode({%args, %$flag_for});
   return sub {
      my $record = shift;
      my @values = $record->{$input} =~ m{$regex}
        or die {
         message => 'invalid record',
         record  => $record,
         regex   => $regex
        };
      trim(@values) if $trim;
      if ($decode) {
         eval { @values = @{$decode->(\@values)}; 1 } or do {
            my $e = $@;
            $e = {message => $e} unless ref $e;
            $e = {%$e, record => $record} if ref($e) eq 'HASH';
            die $e;
         };
      } ## end if ($decode)

      if ($n_keys) {
         my $n_values = scalar @values;
         die {
            message => "'$name': invalid record, expected $n_keys, "
              . "got $n_values only",
            values => \@values,
            record => $record
           }
           if $n_values < $n_keys;

         $record->{$output} = \my %retval;
         @retval{@$keys} = @values;
      } ## end if ($n_keys)
      else {
         $record->{$output} = \@values;
      }
      return $record;
   };
} ## end sub parse_by_separators

sub parse_by_split {
   my %args =
     normalize_args(@_,
      [{%global_defaults, name => 'parse by split'}, 'separator']);
   identify(\%args);

   my $separator = _resolve_separator($args{separator}, \%args);

   my $name          = $args{name};
   my $keys          = $args{keys};
   my $n_keys        = defined($keys) ? scalar(@$keys) : 0;
   my $input         = $args{input};
   my $output        = $args{output};
   my $allow_missing = $args{allow_missing} || 0;
   my $trim          = $args{trim};

   return sub {
      my $record = shift;

      my @values = split(/$separator/, $record->{$input}, $n_keys);
      trim(@values) if $trim;

      my $n_values = @values;
      die {
         message => "'$name': invalid record, expected $n_keys items, "
           . "got $n_values",
         input  => $input,
         record => $record,
        }
        if $n_values + $allow_missing < $n_keys;

      $record->{$output} = \my %retval;
      @retval{@$keys} = @values;
      return $record;
     }
     if $n_keys;

   return sub {
      my $record = shift;
      my @retval = split /$separator/, $record->{$input};
      trim(@retval) if $trim;
      $record->{$output} = \@retval;
      return $record;
   };

} ## end sub parse_by_split

sub parse_by_value_separator {
   my %args = normalize_args(
      @_,
      [
         {%global_defaults, name => 'parse by value and separator'},
         'separator'
      ]
   );
   identify(\%args);
   my $name = $args{name};

   my $separator = _resolve_separator($args{separator}, \%args);
   LOGCROAK "$name: argument separator is mandatory"
     unless defined $separator;

   my ($value, $flag_for) = _resolve_value($args{value}, \%args);
   my $decode = _resolve_decode({%args, %$flag_for});

   my $keys          = $args{keys};
   my $n_keys        = defined($keys) ? scalar(@$keys) : 0;
   my $input         = $args{input};
   my $output        = $args{output};
   my $allow_missing = $args{allow_missing} || 0;
   my $allow_surplus = $args{allow_surplus} || 0;
   my $trim          = $args{trim};
   my $go_global     = $^V lt v5.18.0;

   return sub {
      my $record = shift;

      my @values;
      if ($go_global) {
         local our @global_values = ();
         my $collector = qr/(?{push @global_values, $^N})/;
         $record->{$input} =~ m/
            \A (?: $value $separator $collector )*
               $value \z $collector
            /gmxs
           or die {
            message   => 'invalid record',
            separator => $separator,
            value     => $value,
            record    => $record,
           };
         @values = @global_values;
      }
      else {
         $record->{$input} =~ m/
            \A (?: $value $separator (?{push @values, $^N}) )*
               $value \z (?{push @values, $^N})
            /gmxs
           or die {
            message   => 'invalid record',
            separator => $separator,
            value     => $value,
            record    => $record,
           };
      }
      trim(@values) if $trim;
      if ($decode) {
         eval { @values = @{$decode->(\@values)}; 1 } or do {
            my $e = $EVAL_ERROR;
            $e = {message => $e} unless ref $e;
            $e = {%$e, record => $record} if ref($e) eq 'HASH';
            die $e;
         };
      } ## end if ($decode)

      if ($n_keys) {
         my $n_values = @values;
         die {
            message => "'$name': invalid record, expected $n_keys items, "
              . "got $n_values",
            input  => $input,
            record => $record,
           }
           if ($n_values + $allow_missing < $n_keys)
           || ($n_values - $allow_surplus > $n_keys);
         $record->{$output} = \my %retval;
         @retval{@$keys} = @values;
      } ## end if ($n_keys)
      else {
         $record->{$output} = \@values;
      }
      return $record;
   };
} ## end sub parse_by_value_separator

sub parse_ghashy {
   my %args = normalize_args(@_,
      {%global_defaults, default_key => '', name => 'parse ghashy'});
   identify(\%args);

   my %defaults = %{$args{defaults} || {}};
   my $input    = $args{input};
   my $output   = $args{output};

   # pre-compile capture thing from generalized_hashy
   $args{capture} = generalized_hashy(%args, text => undef)->{capture};

   return sub {
      my $record = shift;
      my $outcome = generalized_hashy(%args, text => $record->{$input});
      die {
         input   => $input,
         message => $outcome->{failure},
         outcome => $outcome,
         record  => $record,
        }
        unless exists $outcome->{hash};
      $record->{$output} = {%defaults, %{$outcome->{hash}}};
      return $record;
   };
} ## end sub parse_ghashy

sub parse_hashy {
   my %args = normalize_args(
      @_,
      {
         %global_defaults,
         chunks_separator    => ' ',
         default_key         => '',
         key_value_separator => '=',
         name                => 'parse hashy',
      }
   );
   identify(\%args);
   my %defaults = %{$args{defaults} || {}};
   my $input    = $args{input};
   my $output   = $args{output};
   return sub {
      my $record = shift;
      my $parsed = metadata($record->{$input}, %args);
      $record->{$output} = {%defaults, %$parsed};
      return $record;
   };
} ## end sub parse_hashy

sub parse_single {
   my %args = normalize_args(
      @_,
      {
         key => 'key',
         %global_defaults,
      }
   );
   identify(\%args);
   my $key     = $args{key};
   my $has_key = defined($key) && length($key);
   my $input   = $args{input};
   my $output  = $args{output};
   return sub {
      my $record = shift;
      $record->{$output} =
        $has_key ? {$key => $record->{$input}} : $record->{$input};
      return $record;
     }
} ## end sub parse_single

shorter_sub_names(__PACKAGE__, 'parse_');

1;
