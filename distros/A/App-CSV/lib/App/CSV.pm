package App::CSV;

use Moose;
use IO::Handle;
use Text::CSV;

our $VERSION = '0.08';

BEGIN {
  # One day, MooseX::Getopt will allow us to pass pass_through to Getopt::Long.
  # Until then, do the following ugly thing unconditionally.
  # (We don't need a BEGIN block here yet. But we will once we start fussing
  # around with version numbers.)
  use Getopt::Long qw(:config pass_through);
}

with 'MooseX::Getopt';

# Create "hasrw" and "hasro" sugar for less cumbersome attribute declarations.
# Why isn't this in Moose?
BEGIN {
  my $mk_has = sub {
    my($access) = @_;
    return sub {
      my($attr, @args) = @_;
      has $attr => (
        is => $access,
        metaclass => 'Getopt',  # For cmd_aliases
        @args,
      );
    };
  };
  no strict 'refs';
  *hasrw = $mk_has->('rw');
  *hasro = $mk_has->('ro');
}

# Input and output filenames. Significant when we want to DWIM with TSV files.
hasrw input  => (isa => 'Str', cmd_aliases => 'i');
hasrw output => (isa => 'Str', cmd_aliases => 'o');

# isa => 'FileHandle' (or IO::String...)
hasrw _input_fh => ();
hasrw _output_fh => ();

# TODO: command line aliases?
hasro from_tsv =>
    (isa => 'Bool', cmd_aliases => 'from-tsv', predicate => 'has_from_tsv');
hasro to_tsv   =>
    (isa => 'Bool', cmd_aliases => 'to-tsv',   predicate => 'has_to_tsv');

hasrw _init => (isa => 'Bool');

# Normalized column indexes.
hasrw columns => (isa => 'ArrayRef[Int]', cmd_aliases => 'c');

# Named fields.
hasrw fields => (isa => 'ArrayRef[Str]', cmd_aliases => 'f');

# The input and output CSV processors.
hasrw _input_csv  => ();
hasrw _output_csv => ();

# Text::CSV options, straight from the manpage.
# We override Text::CSV's default here... because it's WRONG.
our %TextCSVOptions = (
    # name              => [type, default, alias, @extra_opts]
    quote_char          => ['Str', '"',   'q'],
    escape_char         => ['Str', '"',   'e'],
    sep_char            => ['Str', ',',   's', is => 'rw'],
    eol                 => ['Any', ''],
    always_quote        => ['Int', 0],
    binary              => ['Int', 1,     'b'],
    keep_meta_info      => ['Int', 0,     'k'],
    allow_loose_quotes  => ['Int', 0],
    allow_loose_escapes => ['Int', 0],
    allow_whitespace    => ['Int', 0,     'w'],
    verbatim            => ['Int', 0],
);

# output CSV processor options default to whatever the input option is.
# But you can override it just for output by saying --output_foo instead
# of --foo.   (Thanks, gphat and t0m.)
while (my($attr, $opts) = each %TextCSVOptions) {
  my($type, $default, $short, @extra_opts) = @$opts;
  hasro $attr => (
    isa => $type,
    default => $default,
    __aliases($attr, $short),
    @extra_opts
  );
  hasro "output_$attr" => (
    isa => $type,
    lazy => 1,
    default => sub { $_[0]->$attr },
    __output_aliases($attr),
    @extra_opts,
  );
}

sub __aliases {
  my($attr, $short) = @_;
  my @aliases;
  (my $dashes = $attr) =~ s/_/-/g;
  push @aliases, $dashes if $attr ne $dashes;
  push @aliases, $short if $short;
  return @aliases ? (cmd_aliases => \@aliases) : ();
}

sub __output_aliases {
  return __aliases("output_" . shift);
}

sub __normalize_column {
  my($in) = @_;
  return ($in <= 0) ? $in : $in - 1;
}

sub _get_header_map {
  my ($self) = @_;

  my $header_line = $self->_peek_line;
  my %header_map;
  my $field_number = 0;
  for my $field (@$header_line) {
    $header_map{$field} = ++$field_number;
  }

  return \%header_map;
}

sub _fields_to_columns {
  my ($self, $fields) = @_;

  my @all_fields = map { /^(\d+)-(\d+)$/ ? $1 .. $2 : $_ } map { split "," } @$fields;
  my @named_fields = grep { /\D/ } @all_fields;

  my @normalized_fields;
  # If there is at least one named field, we need to read the header line from input and translate
  # into column number.
  if (@named_fields) {
    my $header_map = $self->_get_header_map;
    if (my @missing_fields = grep { not defined $header_map->{$_} } @named_fields) {
        die "The following named fields aren't in the input header: ",
            join(", ", @missing_fields), "\n";
    }
    @normalized_fields = map { __normalize_column(/^\d+/ ? $_ : $header_map->{$_} ) } @all_fields;
  }
  else {
    @normalized_fields = map { __normalize_column($_) } @all_fields;
  }

  return \@normalized_fields;
}

# TODO: You know, I end up with something like this on a lot of projects.
# Why isn't this easier? Having to remember to "use IO::Handle" is sad, too.
sub _setup_fh {
  my($self, $name) = @_;
  my $fh_name = "_${name}_fh";
  return if $self->$fh_name;  # someone had already injected a fh.

  # ARGH. You can't open $fh, ">-", but you can't open $fh, "", "-" !?
  my $dir2 = $name eq 'input' ? '' : '>';
  my $dir3 = $name eq 'input' ? '<' : '>';

  my $fh;
  $self->$name('-') if not defined $self->$name;
  if ($self->$name eq '-') {  # use stdio
    open $fh, "$dir2-" or die "open: stdio: $!";
  } else {
    open $fh, $dir3, $self->$name or die "open: $self->$name: $!";
  }
  $self->$fh_name($fh);
}

sub init {
  my($self) = @_;
  return if $self->_init;
  $self->_init(1);

  # TODO: zero-based field numbers as an option? nah?
  my @columns = (($self->columns ? @{$self->columns} : ()), @{$self->extra_argv});
  $self->columns([map { __normalize_column($_) } @columns]) if @columns;

  $self->_setup_fh($_) for qw(input output);

  # DWIMmy TSV
  if ($self->from_tsv ||
      (!$self->has_from_tsv && $self->input && $self->input =~ /\.tsv$/)) {
    $self->sep_char("\t");
  }
  if ($self->to_tsv ||
      (!$self->has_to_tsv && $self->output && $self->output =~ /\.tsv$/)) {
    $self->output_sep_char("\t");
  }

  $self->_input_csv(Text::CSV->new({
      map { $_ => $self->$_ } keys %TextCSVOptions }));
  $self->_output_csv(Text::CSV->new({
      map { my $o = "output_$_"; $_ => $self->$o } keys %TextCSVOptions }));

  # If columns aren't specified, look for the --fields option. It allows
  # use of named fields, list of comma-separated fields list, field
  # ranges and so on.

  if (@columns) {
    warn "--fields (-f) option is ignored since columns are also specified." if $self->fields;
  } else {
    my @fields = $self->fields ? @{$self->fields} : ();
    if (@fields) {
      my $columns = $self->_fields_to_columns(\@fields);
      $self->columns($columns);
    }
  }
}

{
  my $line_read;

  # Read a line from input, but push it back for later reading.
  sub _peek_line {
    my ($self) = @_;

    $line_read = $self->_input_csv->getline($self->_input_fh);
  }

  # If there is a line already read, return it; otherwise, read from input.
  sub _get_line {
    my ($self) = @_;

    my $line;
    if ($line_read) {
      $line = $line_read;
      undef $line_read;
      return $line;
    } else {
      return $self->_input_csv->getline($self->_input_fh);
    }
  }
}

sub run {
  my($self) = @_;
  $self->init;

  # L<perlsyn/"modifiers don't take loop labels">
  INPUT: { do {
    my $data;
    while (defined($data = $self->_get_line)) {
      if ($self->columns) {
        @$data = @$data[@{ $self->columns }];
      }
      
      if (!$self->_output_csv->print($self->_output_fh, $data)) {
        warn $self->format_error("Warning - Output error", diag => [$self->_input_csv->error_diag]), "\n";
        next INPUT;
      }
      $self->_output_fh->print("\n");
    }

    # Keeps us going on input errors.
    # TODO: strict errors, according to command line, blah
    if (not defined $data) {
      last INPUT if $self->_input_csv->eof;
      warn $self->format_error("Warning - Input error", line => $., diag => [$self->_input_csv->error_diag]), "\n";
    }
  } }
}

sub format_error {
    my $self = shift;
    my $msg  = shift;
    my %args = @_;

    $msg .= ", line $args{line}"
        if defined $args{line};

    if ($args{diag}) {
        my ($code, $err, $pos, $record) = @{ $args{diag} || [] };
        $msg .= ": " . join " - ",
            $code, $err, "position $pos",
            (defined $record ? "record $record" : ());
    }
    return $msg;
}

1;

__END__
=head1 NAME

App::CSV - process CSV files

=head1 REDIRECTION

Please see L<csv>.

=head1 COPYRIGHT (The "MIT" License)

Copyright 2013 Gaal Yahas.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
