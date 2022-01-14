package Data::Tubes::Util;

# vim: ts=3 sts=3 sw=3 et ai :

use strict;
use warnings;
use English qw< -no_match_vars >;
use Exporter 'import';
our $VERSION = '0.738';

use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

our @EXPORT_OK = qw<
  args_array_with_options
  assert_all_different
  generalized_hashy
  load_module
  load_sub
  metadata
  normalize_args
  normalize_filename
  pump
  read_file
  read_file_maybe
  resolve_module
  shorter_sub_names
  sprintffy
  test_all_equal
  traverse
  trim
  tube
  unzip
>;

sub _load_module {
   my $module = shift;
   (my $packfile = $module . '.pm') =~ s{::}{/}gmxs;
   require $packfile;
   return $module;
} ## end sub _load_module

sub args_array_with_options {
   my %defaults = %{pop @_};
   %defaults = (%defaults, %{pop @_})
     if @_ && (ref($_[-1]) eq 'HASH');
   return ([@_], \%defaults);
} ## end sub args_array_with_options

sub assert_all_different {
   my $keys = (@_ && ref($_[0])) ? $_[0] : \@_;
   my %flag_for;
   for my $key (@$keys) {
      die {message => $key} if $flag_for{$key}++;
   }
   return 1;
} ## end sub assert_all_different

sub _compile_capture {
   my %h = @_;
   use feature 'state';

   state $quoted = qr{(?mxs:
      (?: "(?: [^\\"]+ | \\. )*") # double quotes
      | (?: '[^']*')              # single quotes
   )};

   my ($key, $value, $kvs, $cs) =
     @h{qw< key value key_value_separator chunks_separator>};

   if (!defined($key)) {
      my $admitted = $h{key_admitted};
      $admitted = qr{[\Q$admitted\E]} unless ref $admitted;
      $key = qr{(?mxs: $quoted | (?:(?:$admitted | \\.)+?))};
   }

   if (!defined($value)) {
      my $admitted = $h{value_admitted};
      $admitted = qr{[\Q$admitted\E]} unless ref $admitted;
      $value = qr{(?mxs: $quoted | (?:(?:$admitted | \\.)+?))};
   }

   my $close = qr{(?<close>$h{close})};
   return qr{(?mxs:
      (?: (?<key> $key) $kvs)?  # optional key with kv-separator
      (?<value> $value)         # a value, for sure
      (?: $close | $cs $close?) # close or chunk separator next
   )};
} ## end sub _compile_capture

sub generalized_hashy {
   use feature 'state';
   state $admitted_default = qr{[^\\'":=\s,;\|/]};
   state $kvdecoder        = sub {
      my $kv = shift;
      my $first = substr $kv, 0, 1;
      $kv = substr $kv, 1, length($kv) - 2
        if ($first eq q{'}) || ($first eq q{"});
      $kv =~ s{\\(.)}{$1}gmxs unless $first eq q{'};
      return $kv;
   };
   state $default_handler_for = {
      open                => qr{(?mxs: \s* )},
      key_value_separator => qr{(?mxs: \s* [:=] \s*)},
      chunks_separator    => qr{(?mxs: \s* [\s,;\|/] \s*)},
      close               => qr{(?mxs: \s*\z)},
      key_admitted        => $admitted_default,
      value_admitted      => $admitted_default,
      key_decoder         => $kvdecoder,
      value_decoder       => $kvdecoder,
      key_duplicate       => sub {
         my ($h, $k, $v) = @_;
         $h->{$k} = [$h->{$k}] unless ref $h->{$k};
         push @{$h->{$k}}, $v;
      },
   };
   my $args = normalize_args(@_, [$default_handler_for, 'text']);
   $args->{key_default} = delete $args->{default_key}
     if exists $args->{default_key};
   my $text = $args->{text};

   my %h = (%$default_handler_for, %$args);
   my $capture = $h{capture} ||= _compile_capture(%h);
   my %retval = (capture => $capture);
   return {%retval, failure => 'undefined input'} unless defined $text;

   my $len = length $text;
   pos($text) = my $startpos = $args->{pos} || 0;
   %retval = (%retval, pos => $startpos, res => ($len - $startpos));

   # let's check open first, no need to define anything otherwise
   $text =~ m{\G$h{open}}gmxs or return {%retval, failure => 'no opening'};

   my ($dkey, $dupkey, $kdec, $vdec) =
     @h{qw< key_default key_duplicate key_decoder value_decoder >};
   my ($closed, %hash);
   while (!$closed && pos($text) < length($text)) {
      my $pos = pos($text);
      $text =~ m{\G$capture}gcmxs
        or return {
         %retval,
         failure => "failed match at $pos",
         failpos => $pos
        };

      my $key =
          exists($+{key}) ? ($kdec      ? $kdec->($+{key}) : $+{key})
        : defined($dkey)  ? (ref($dkey) ? $dkey->()        : $dkey)
        :                   undef;
      return {
         %retval,
         failure => 'stand-alone value, no default key set',
         failpos => $pos
        }
        unless defined $key;

      my $value = $vdec ? $vdec->($+{value}) : $+{value};

      if (!exists $hash{$key}) {
         $hash{$key} = $value;
      }
      elsif ($dupkey) {
         $dupkey->(\%hash, $key, $value);
      }
      else {
         return {
            %retval,
            failure => "duplicate key $key",
            failpos => $pos
         };
      } ## end else [ if (!exists $hash{$key...})]

      $closed = exists $+{close};
   } ## end while (!$closed && pos($text...))

   return {%retval, failure => 'no closure found'} unless $closed;

   my $pos = pos $text;
   return {
      %retval,
      pos  => $pos,
      res  => ($len - $pos),
      hash => \%hash,
   };
} ## end sub generalized_hashy

sub load_module {
   return _load_module(resolve_module(@_));
} ## end sub load_module

sub load_sub {
   my ($locator, $prefix) = @_;
   my ($module, $sub) =
     ref($locator) ? @$locator : $locator =~ m{\A(.*)::(\w+)\z}mxs;
   $module = resolve_module($module, $prefix);

   # optimistic first
   return $module->can($sub) // _load_module($module)->can($sub);
} ## end sub load_sub

sub metadata {
   my $input = shift;
   my %args  = normalize_args(
      @_,
      {
         chunks_separator    => ' ',
         key_value_separator => '=',
         default_key         => '',
      }
   );

   # split data into chunks, un-escape on the fly
   my $separator = $args{chunks_separator};
   my $qs        = quotemeta($separator);
   my $regexp    = qr/((?:\\.|[^\\$qs])+)(?:$qs+)?/;
   my @chunks    = map { s{\\(.)}{$1}g; $_ } $input =~ m{$regexp}gc;

   # ensure we consumed the whole $input
   die {message =>
        "invalid metadata (separator: '$separator', input: [$input])\n"
     }
     if pos($input) < length($input);

   $separator = $args{key_value_separator};
   return {
      map {
         my ($k, $v) = _split_pair($_, $separator);
         defined($v) ? ($k, $v) : ($args{default_key} => $k);
      } @chunks
   };
} ## end sub metadata

sub normalize_args {
   my $defaults = pop(@_);

   my %retval;
   if (ref($defaults) eq 'ARRAY') {
      ($defaults, my $key) = @$defaults;
      $retval{$key} = shift(@_)
        if (scalar(@_) % 2) && (ref($_[0]) ne 'HASH');
   }
   %retval = (
      %$defaults,    # defaults go first
      %retval,       # anything already present goes next
      ((@_ && ref($_[0]) eq 'HASH') ? %{$_[0]} : @_),    # then... the rest
   );

   return %retval if wantarray();
   return \%retval;
} ## end sub normalize_args

sub normalize_filename {
   my ($filename, $default_handle) = @_;
   return unless defined $filename;
   return $filename       if ref($filename) eq 'GLOB';
   return $filename       if ref($filename) eq 'SCALAR';
   return $default_handle if $filename eq '-';
   return $filename       if $filename =~ s{\Afile:}{}mxs;
   if (my ($handlename) = $filename =~ m{\Ahandle:(?:std)?(.*)\z}imxs) {
      $handlename = lc $handlename;
      return \*STDOUT if $handlename eq 'out';
      return \*STDIN  if $handlename eq 'err';
      return \*STDERR if $handlename eq 'in';
      LOGDIE "normalize_filename: invalid filename '$filename', "
        . "use 'file:$filename' if name is correct";
   } ## end if (my ($handlename) =...)
   return $filename;
} ## end sub normalize_filename

sub pump {
   my ($iterator, $sink) = @_;
   if ($sink) {
      while (my @items = $iterator->()) {
         $sink->(@items);
      }
      return;
   }
   my $wa = wantarray();
   if (! defined $wa) {
      while (my @items = $iterator->()) {}
      return;
   }
   my @records;
   while (my @items = $iterator->()) {
      push @records, @items;
   }
   return $wa ? @records : \@records;
}

sub read_file {
   my %args = normalize_args(
      @_,
      [
         {binmode => ':encoding(UTF-8)'},
         'filename',    # default key for "straight" unnamed parameter
      ]
   );
   defined(my $filename = normalize_filename($args{filename}, \*STDIN))
     or LOGDIE 'read_file(): undefined filename';

   my $fh;
   if (ref($filename) eq 'GLOB') {
      $fh = $filename;
   }
   else {
      open $fh, '<', $filename
        or LOGDIE "read_file() for <$args{filename}>: open(): $OS_ERROR";
   }

   if (defined $args{binmode}) {
      binmode $fh, $args{binmode}
        or LOGDIE "read_file(): binmode()"
        . " for $args{filename} failed: $OS_ERROR";
   }

   local $INPUT_RECORD_SEPARATOR;
   return <$fh>;
} ## end sub read_file

sub read_file_maybe {
   my $x = shift;
   return read_file(@$x) if ref($x) eq 'ARRAY';
   return $x;
}

sub resolve_module {
   my ($module, $prefix) = @_;

   # Force a first character transforming from new interface if after 0.734
   if ($Data::Tubes::API_VERSION gt '0.734') {
      $module = '+' . $module unless $module =~ s{^[+^]}{!}mxs;
   }

   my ($first) = substr $module, 0, 1;
   return substr $module, 1 if $first eq '!';

   $prefix //= 'Data::Tubes::Plugin';
   if ($first eq '+') {
      $module = substr $module, 1;
   }
   elsif ($module =~ m{::}mxs) {
      $prefix = undef;
   }
   return $module unless defined $prefix;
   return $prefix . '::' . $module;
}

sub shorter_sub_names {
   my $stash = shift(@_) . '::';

   no strict 'refs';

   # isolate all subs
   my %sub_for =
     map { *{$stash . $_}{CODE} ? ($_ => *{$stash . $_}{CODE}) : (); }
     keys %$stash;

   # iterate through inputs, work only on isolated subs and don't
   # consider shortened ones
   for my $prefix (@_) {
      while (my ($name, $sub) = each %sub_for) {
         next if index($name, $prefix) < 0;
         my $shortname = substr $name, length($prefix);
         *{$stash . $shortname} = $sub;
      }
   } ## end for my $prefix (@_)

   return;
} ## end sub shorter_sub_names

sub _split_pair {
   my ($input, $separator) = @_;
   my $qs     = quotemeta($separator);
   my $regexp = qr{(?mxs:\A((?:\\.|[^\\$qs])+)$qs(.*)\z)};
   my ($first, $second) = $input =~ m{$regexp};
   ($first, $second) = ($input, undef) unless defined($first);
   $first =~ s{\\(.)}{$1}gmxs;    # unescape metadata
   return ($first, $second);
} ## end sub _split_pair

sub sprintffy {
   my ($template, $substitutions) = @_;
   my $len = length $template;
   pos($template) = 0;            # initialize
   my @chunks;
 QUEST:
   while (pos($template) < $len) {
      $template =~ m{\G (.*?) (% | \z)}mxscg;
      my ($plain, $term) = ($1, $2);
      my $pos = pos($template);
      push @chunks, $plain;
      last unless $term;          # got a percent, have to continue
    CANDIDATE:
      for my $candidate ([qr{%} => '%'], @$substitutions) {
         my ($regex, $value) = @$candidate;
         $template =~ m{\G$regex}cg or next CANDIDATE;
         $value = $value->() if ref($value) eq 'CODE';
         push @chunks, $value;
         next QUEST;
      } ## end CANDIDATE: for my $candidate ([qr{%}...])

      # didn't find a matchin thing... time to complain
      die {message => "invalid sprintffy template '$template'"};
   } ## end QUEST: while (pos($template) < $len)
   return join '', @chunks;
} ## end sub sprintffy

sub test_all_equal {
   my $reference = shift;
   for my $candidate (@_) {
      return if $candidate ne $reference;
   }
   return 1;
} ## end sub test_all_equal

sub traverse {
   my ($data, @keys) = @_;
   for my $key (@keys) {
      if (ref($data) eq 'HASH') {
         $data = $data->{$key};
      }
      elsif (ref($data) eq 'ARRAY') {
         $data = $data->[$key];
      }
      else {
         return undef;
      }
      return undef unless defined $data;
   } ## end for my $key (@keys)
   return $data;
} ## end sub traverse

sub trim {
   s{\A\s+|\s+\z}{}gmxs for @_;
}

sub tube {
   my $opts = {};
   $opts = shift(@_) if (@_ && ref($_[0]) eq 'HASH');
   my @prefix = exists($opts->{prefix}) ? ($opts->{prefix}) : ();
   my $locator = shift;
   return load_sub($locator, @prefix)->(@_);
}

sub unzip {
   my $items = (@_ && ref($_[0])) ? $_[0] : \@_;
   my $n_items = scalar @$items;
   my (@evens, @odds);
   my $i = 0;
   while ($i < $n_items) {
      push @evens, $items->[$i++];
      push @odds, $items->[$i++] if $i < $n_items;
   }
   return (\@evens, \@odds);
} ## end sub unzip

1;
