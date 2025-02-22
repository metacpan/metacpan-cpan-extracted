package Rose::DB::Object::Metadata::Util;

use strict;

use Carp();

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = 
  qw(perl_hashref perl_arrayref perl_quote_key perl_quote_value
     hash_key_padding);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $DEFAULT_PERL_INDENT = 4;
our $DEFAULT_PERL_BRACES = 'k&r';

our $VERSION = '0.817';

sub perl_hashref
{
  my(%args) = (@_ == 1 ? (hash => $_[0]) : @_);

  my $inline = defined $args{'inline'} ? $args{'inline'} : ($args{'inline'} = 1);
  my $indent = defined $args{'indent'} ? $args{'indent'} : ($args{'indent'} = $DEFAULT_PERL_INDENT);
  my $braces = defined $args{'braces'} ? $args{'braces'} : ($args{'braces'} = $DEFAULT_PERL_BRACES);
  my $level  = defined $args{'level'}  ? $args{'level'}  : ($args{'level'}  = 0);
  my $no_curlies   = delete $args{'no_curlies'};
  my $key_padding  = $args{'key_padding'} || 0;
  my $inline_limit = $args{'inline_limit'};

  my $sort_keys = $args{'sort_keys'} || sub { lc $_[0] cmp lc $_[1] };

  my $hash = delete $args{'hash'};

  my $indent_txt = ' ' x ($indent * ($level + 1));
  my $sub_indent = ' ' x ($indent * $level);

  my @pairs;

  foreach my $key (sort { $sort_keys->($a, $b) } keys %$hash)
  {
    push(@pairs, sprintf('%-*s => ', $key_padding, perl_quote_key($key)) .
                 perl_value(value => $hash->{$key}, %args));
  }

  my($inline_perl, $perl);

  $inline_perl = ($no_curlies ? '' : '{ ') . join(', ', @pairs) . ($no_curlies ? '' : ' }');

  if($braces eq 'bsd')
  {
    $perl = "\n${sub_indent}" . ($no_curlies ? '' : "{\n");
  }
  elsif($braces eq 'k&r')
  {
    $perl = "{\n"  unless($no_curlies);
  }
  else
  {
    Carp::croak 'Invalid ', (defined $args{'braces'} ? '' : 'default '),
                "brace style: '$braces'";
  }

  $perl .= join(",\n", map { "$indent_txt$_" } @pairs) . ',' . 
           ($no_curlies ? '' : "\n$sub_indent}");

  if(defined $inline_limit && length($inline_perl) > $inline_limit)
  {
    return $perl;
  }

  return $inline ? $inline_perl : $perl;
}

sub perl_arrayref
{
  my(%args) = (@_ == 1 ? (array => $_[0]) : @_);

  my $inline = defined $args{'inline'} ? $args{'inline'} : ($args{'inline'} = 1);
  my $indent = defined $args{'indent'} ? $args{'indent'} : ($args{'indent'} = $DEFAULT_PERL_INDENT);
  my $braces = defined $args{'braces'} ? $args{'braces'} : ($args{'braces'} = $DEFAULT_PERL_BRACES);
  my $level  = defined $args{'level'}  ? $args{'level'}  : ($args{'level'}  = 0);
  my $key_padding = $args{'key_padding'} || 0;
  my $inline_limit = $args{'inline_limit'};

  my $sort_keys = $args{'sort_keys'} || sub { lc $_[0] cmp lc $_[1] };

  my $array = delete $args{'array'};

  my $indent_txt = ' ' x ($indent * ($level + 1));
  my $sub_indent = ' ' x ($indent * $level);

  my @items;

  foreach my $item (@$array)
  {
    push(@items, perl_value(value => $item, %args));
  }

  my($inline_perl, $perl);

  $inline_perl = '[ ' . join(', ', @items) . ' ]';

  if($braces eq 'bsd')
  {
    $perl = "\n${sub_indent}\[\n";
  }
  elsif($braces eq 'k&r')
  {
    $perl = "[\n";
  }
  else
  {
    Carp::croak 'Invalid ', (defined $args{'braces'} ? '' : 'default '),
                "brace style: '$braces'";
  }

  $perl .= join(",\n", map { "$indent_txt$_" } @items) . ",\n$sub_indent]";

  if(defined $inline_limit && length($inline_perl) > $inline_limit)
  {
    return $perl;
  }

  return $inline ? $inline_perl : $perl;
}

sub perl_value
{
  my(%args) = (@_ == 1 ? (value => $_[0]) : @_);

  my $value = delete $args{'value'};

  $args{'level'}++;

  if(my $ref = ref $value)
  {
    if($ref eq 'ARRAY')
    {
      return perl_arrayref(array => $value, %args);
    }
    elsif($ref eq 'HASH')
    {
      $args{'key_padding'} = hash_key_padding($value);
      delete $args{'inline'};
      return perl_hashref(hash => $value, %args);
    }
    else
    {
      return $value;
    }
  }

  return perl_quote_value($value)
}

sub hash_key_padding
{
  my($hash) = shift;

  my $max_len = 0;
  my $min_len = -1;

  foreach my $name (keys %$hash)
  {
    $max_len = length($name)  if(length $name > $max_len);
    $min_len = length($name)  if(length $name < $min_len || $min_len < 0);
  }

  return $max_len;
}

sub perl_quote_key
{
  my($key) = shift;

  return $key  if($key =~ /^\d+$/);

  for($key)
  {
    s/'/\\'/g    if(/'/);    
    $_ = "'$_'"  if(/\W/);
  }

  return $key;
}

sub perl_quote_value
{
  my($val) = shift;

  for($val)
  {
    s/'/\\'/g    if(/'/);
    $_ = "'$_'"  unless(/^(?:[1-9]\d*\.?\d*|\.\d+)$/);
  }

  return $val;
}

1;
