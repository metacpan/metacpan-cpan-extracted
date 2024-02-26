package Data::Structure::Deserialize::Auto 1.01;
use v5.22;
use warnings;

# ABSTRACT: Deserializes data structures from perl, JSON, YAML, or TOML data, from strings or files

=encoding UTF-8
 
=head1 NAME
 
Data::Structure::Deserialize::Auto - deserializes data structures from perl, JSON, YAML, or TOML data, from strings or files
 
=head1 SYNOPSIS

    use Data::Structure::Deserialize::Auto qw(deserialize);

    my $str = '{"db": {"host": "localhost"}}';
    my $ds = deserialize($str); #autodetects JSON
    say $ds->{db}->{host}; # localhost

    # OR 

    $str = <<'END';
    options:
      autosave: 1
    END
    $ds = deserialize($str); #autodetects YAML
    say $ds->{options}->{autosave}; # 1

    # OR

    use Data::Dumper;
    $Data::Dumper::Terse = 1;
    my $filename = ...;
    open(my $FH, '>', $filename);
    my $data = {
      a => 1,
      b => 2,
      c => 3
    };
    print $FH Dumper($data);
    close($FH);
    $ds = deserialize($filename); #autodetects perl in referenced file
    say $ds->{b}; # 2

=head1 DESCRIPTION

L<Data::Structure::Deserialize::Auto> is a module for converting a string in an
arbitrary format (one of perl/JSON/YAML/TOML) into a perl data structure, without 
needing to worry about what format it was in.

If the string argument given to it is a valid local filename, it is treated as
such, and that file's contents are processed instead.

=head1 FUNCTIONS

=head2 deserialize( $str[, $hint] )

Given a string as its first argument, returns a perl data structure by decoding
the perl (L<Data::Dumper>), JSON, YAML, or TOML string. Or, if the string is a valid
filename, by decoding the contents of that file.

If a hint is given as the second argument, where its value is one of C<yaml>,
C<json>, C<toml> or C<perl>, then this type of deserialization is tried first.
This may be necessary in certain rare edge cases where the input value's format
is ambiguous.

This function can be exported

=cut

use base qw(Exporter);

use File::Basename;
use IO::All;
use JSON qw(decode_json);
use Readonly;
use Syntax::Keyword::Try;
use TOML qw(from_toml);
use YAML::XS;

use experimental qw(signatures);

Readonly::Hash my %FILE_TYPES => (
  yml  => 'yaml',
  yaml => 'yaml',
  toml => 'toml',
  json => 'json',
);
Readonly::Array my @DECODER_PRIORITY => qw(perl yaml json toml);

our @EXPORT_OK = qw(
  deserialize
);

sub _decoders() {
  return (
    yaml => sub($v) {
      Load($v);
    },
    json => sub($v) {
      decode_json($v);
    },
    toml => sub($v) {
      from_toml($v);
    },
    perl => sub($v) {
      no warnings 'syntax';
      eval($v);    ## no critic (ProhibitStringyEval)
    },
  );
}

sub _is_filename($str) {
  return 0 if ($str =~ /\n/);
  return (-f $str);
}

sub deserialize($v, $hint = undef) {
  return $v if (ref($v) eq 'HASH');

  my @decoders = @DECODER_PRIORITY;
  my %decoders = _decoders();
  if (_is_filename($v)) {
    my ($fn, $dirs, $suffix) = fileparse($v, keys(%FILE_TYPES));
    unshift(@decoders, $FILE_TYPES{$suffix}) if (defined($suffix) && defined($FILE_TYPES{$suffix}));
    $v = io->file($v)->slurp;
  }
  unshift(@decoders, $hint) if (defined($hint));
  my $n;
  do {
    $n = shift(@decoders);
    my $decoder = $decoders{$n};
    try {
      my $structure = $decoder->($v);
      if (ref($structure) eq 'HASH' || ref($structure) eq 'ARRAY') {
        # warn("decoded using '$n'");
        return $decoder->($v);
      }
    } catch {
      # ignore any errors and try the next decoder, or die out at the bottom
    };
  } while (@decoders);
  die("Data::Structure::Deserialize::Auto was unable to process the input");
}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
