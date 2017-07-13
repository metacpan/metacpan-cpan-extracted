package Data::Format::Pretty::Console;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.38'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use Scalar::Util qw(blessed);
use Text::ANSITable;
use YAML::Any;
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new->allow_nonref;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

sub content_type { "text/plain" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};
    __PACKAGE__->new($opts)->_format($data);
}

# OO interface is nto documented, we use it just to subclass
# Data::Format::Pretty::HTML
sub new {
    my ($class, $opts) = @_;
    $opts //= {};
    $opts->{interactive} //= $ENV{INTERACTIVE} // (-t STDOUT);
    $opts->{table_column_orders} //= $json->decode(
        $ENV{FORMAT_PRETTY_TABLE_COLUMN_ORDERS})
        if defined($ENV{FORMAT_PRETTY_TABLE_COLUMN_ORDERS});
    $opts->{table_column_formats} //= $json->decode(
        $ENV{FORMAT_PRETTY_TABLE_COLUMN_FORMATS})
        if defined($ENV{FORMAT_PRETTY_TABLE_COLUMN_FORMATS});
    $opts->{table_column_types} //= $json->decode(
        $ENV{FORMAT_PRETTY_TABLE_COLUMN_TYPES})
        if defined($ENV{FORMAT_PRETTY_TABLE_COLUMN_TYPES});
    $opts->{list_max_columns} //= $ENV{FORMAT_PRETTY_LIST_MAX_COLUMNS};
    bless {opts=>$opts}, $class;
}

sub _is_cell_or_format_cell {
    my ($self, $data, $is_format) = @_;

    # XXX currently hardcoded limits
    my $maxlen = 1000;

    if (!ref($data) || blessed($data)) {
        if (!defined($data)) {
            return "" if $is_format;
            return 1;
        }
        if (length($data) > $maxlen) {
            return;
        }
        return "$data" if $is_format;
        return 1;
    } elsif (ref($data) eq 'ARRAY') {
        if (grep {ref($_) && !blessed($_)} @$data) {
            return;
        }
        my $s = join(", ", map {defined($_) ? "$_":""} @$data);
        if (length($s) > $maxlen) {
            return;
        }
        return $s if $is_format;
        return 1;
    } else {
        return;
    }
}

# return a string when data can be represented as a cell, otherwise undef. what
# can be put in a table cell? a string (or stringified object) or array of
# strings (stringified objects) that is quite "short".
sub _format_cell { _is_cell_or_format_cell(@_, 1) }

sub _is_cell     { _is_cell_or_format_cell(@_, 0) }

sub _detect_struct {
    my ($self, $data) = @_;
    my $struct;
    my $struct_meta = {};

    # XXX perhaps, use Data::Schema later?
  CHECK_FORMAT:
    {
      CHECK_SCALAR:
        {
            if (!ref($data) || blessed($data)) {
                $struct = "scalar";
                last CHECK_FORMAT;
            }
        }

      CHECK_AOA:
        {
            if (ref($data) eq 'ARRAY') {
                my $numcols;
                for my $row (@$data) {
                    last CHECK_AOA unless ref($row) eq 'ARRAY';
                    last CHECK_AOA if defined($numcols) && $numcols != @$row;
                    last CHECK_AOA if grep { !$self->_is_cell($_) } @$row;
                    $numcols = @$row;
                }
                $struct = "aoa";
                last CHECK_FORMAT;
            }
        }

      CHECK_AOH:
        {
            if (ref($data) eq 'ARRAY') {
                $struct_meta->{columns} = {};
                for my $row (@$data) {
                    last CHECK_AOH unless ref($row) eq 'HASH';
                    for my $k (keys %$row) {
                        last CHECK_AOH if !$self->_is_cell($row->{$k});
                        $struct_meta->{columns}{$k} = 1;
                    }
                }
                $struct = "aoh";
                last CHECK_FORMAT;
            }
        }

        # list of scalars/cells
      CHECK_LIST:
        {
            if (ref($data) eq 'ARRAY') {
                for (@$data) {
                    last CHECK_LIST unless $self->_is_cell($_);
                }
                $struct = "list";
                last CHECK_FORMAT;
            }
        }

        # hash which contains at least one "table" (list/aoa/aoh)
      CHECK_HOT:
        {
            last CHECK_HOT if $self->{opts}{skip_hot};
            last CHECK_HOT unless ref($data) eq 'HASH';
            my $has_t;
            while (my ($k, $v) = each %$data) {
                my ($s2, $sm2) = $self->_detect_struct($v, {skip_hot=>1});
                last CHECK_HOT unless $s2;
                $has_t = 1 if $s2 =~ /^(?:list|aoa|aoh|hash)$/;
            }
            last CHECK_HOT unless $has_t;
            $struct = "hot";
            last CHECK_FORMAT;
        }

        # hash of scalars/cells
      CHECK_HASH:
        {
            if (ref($data) eq 'HASH') {
                for (values %$data) {
                    last CHECK_HASH unless $self->_is_cell($_);
                }
                $struct = "hash";
                last CHECK_FORMAT;
            }
        }

    }

    ($struct, $struct_meta);
}

# t (table) is a structure like this: {cols=>["colName1", "colName2", ...]},
# rows=>[ [row1.1, row1.2, ...], [row2.1, row2.2, ...], ... ], at_opts=>{...},
# col_widths=>{colName1=>5, ...}}. the job of this routine is to render it
# (currently uses Text::ANSITable).
sub _render_table {
    my ($self, $t) = @_;

    my $colfmts;
    my $tcff = $self->{opts}{table_column_formats};
    if ($tcff) {
        for my $tcf (@$tcff) {
            my $match = 1;
            my @tcols = @{ $t->{cols} };
            for my $scol (keys %$tcf) {
                do { $match = 0; last } unless $scol ~~ @tcols;
            }
            if ($match) {
                $colfmts = $tcf;
                last;
            }
        }
    }

    my $coltypes;
    my $tctt = $self->{opts}{table_column_types};
    if ($tctt) {
        for my $tct (@$tctt) {
            my $match = 1;
            my @tcols = @{ $t->{cols} };
            for my $scol (keys %$tct) {
                do { $match = 0; last } unless $scol ~~ @tcols;
            }
            if ($match) {
                $coltypes = $tct;
                last;
            }
        }
    }

    # render using Text::ANSITable
    my $at = Text::ANSITable->new;
    $at->columns($t->{cols});
    $at->rows($t->{rows});
    if ($t->{at_opts}) {
        $at->{$_} = $t->{at_opts}{$_} for keys %{ $t->{at_opts} };
    }
    if ($colfmts) {
        $at->set_column_style($_ => formats => $colfmts->{$_})
            for keys %$colfmts;
    }
    if ($coltypes) {
        $at->set_column_style($_ => type => $coltypes->{$_})
            for keys %$coltypes;
    }
    if ($t->{col_widths}) {
        $at->set_column_style($_ => width => $t->{col_widths}{$_})
            for keys %{ $t->{col_widths} };
    }
    $at->draw;
}

# format unknown structure, the default is to dump YAML structure
sub _format_unknown {
    my ($self, $data) = @_;
    Dump($data);
}

sub _format_scalar {
    my ($self, $data) = @_;

    my $sdata = defined($data) ? "$data" : "";
    return "" if !length($sdata);
    return $sdata =~ /\n\z/s ? $sdata : "$sdata\n";
}

sub _format_list {
    my ($self, $data) = @_;
    if ($self->{opts}{interactive}) {

        require List::Util;
        require POSIX;

        # format list as as columns (a la 'ls' output)

        my @rows = map { $self->_format_cell($_) } @$data;

        my $maxwidth = List::Util::max(map { length } @rows) // 0;
        my ($termcols, $termrows);
        if ($ENV{COLUMNS}) {
            $termcols = $ENV{COLUMNS};
        } elsif (eval { require Term::Size; 1 }) {
            ($termcols, $termrows) = Term::Size::chars();
        } else {
            # sane default, on windows we need to offset by 1 because printing
            # at the rightmost column will cause cursor to move down one line.
            $termcols = $^O =~ /Win/ ? 79 : 80;
        }
        my $numcols = 1;
        if ($maxwidth) {
            # | some-text-some | some-text-some... |
            # 2/\__maxwidth__/\3/\__maxwidth__/...\2
            #
            # table width = (2+maxwidth) + (3+maxwidth)*(numcols-1) + 2
            #
            # so with a bit of algrebra, solve for numcols:
            $numcols = int( (($termcols-1)-$maxwidth-6)/(3+$maxwidth) + 1 );
            $numcols = @rows if $numcols > @rows;
            $numcols = 1 if $numcols < 1;
        }
        $numcols = $self->{opts}{list_max_columns}
            if defined($self->{opts}{list_max_columns}) &&
                $numcols > $self->{opts}{list_max_columns};
        my $numrows = POSIX::ceil(@rows/$numcols);
        if ($numrows) {
            # reduce number of columns to avoid empty columns
            $numcols = POSIX::ceil(@rows/$numrows);
        }
        #say "D: $numcols x $numrows";

        my $t = {rows=>[], at_opts=>{show_header=>0}};
        $t->{cols} = [map { "c$_" } 1..$numcols];
        if ($numcols > 1) {
            $t->{col_widths}{"c$_"} = $maxwidth for 1..$numcols;
        }
        for my $r (1..$numrows) {
            my @trow;
            for my $c (1..$numcols) {
                my $idx = ($c-1)*$numrows + ($r-1);
                push @trow, $idx < @rows ? $rows[$idx] : '';
            }
            push @{$t->{rows}}, \@trow;
        }

        return $self->_render_table($t);

    } else {
        my @rows;
        for my $row (@$data) {
            push @rows, ($row // "") . "\n";
        }
        return join("", @rows);
    }
}

sub _format_hash {
    my ($self, $data) = @_;
    # format hash as two-column table
    if ($self->{opts}{interactive}) {
        my $t = {cols=>[qw/key value/], rows=>[],
                 at_opts=>{}};
        for my $k (sort keys %$data) {
            push @{ $t->{rows} }, [$k, $self->_format_cell($data->{$k})];
        }
        return $self->_render_table($t);
    } else {
        my @t;
        for my $k (sort keys %$data) {
            push @t, $k, "\t", ($data->{$k} // ""), "\n";
        }
        return join("", @t);
    }
}

sub _format_aoa {
    my ($self, $data) = @_;
    # show aoa as table
    if ($self->{opts}{interactive}) {
        if (@$data) {
            my $t = {rows=>[], at_opts=>{}};
            $t->{cols} = [map { "column$_" } 0..@{ $data->[0] }-1];
            for my $i (0..@$data-1) {
                push @{ $t->{rows} },
                    [map {$self->_format_cell($_)} @{ $data->[$i] }];
            }
            return $self->_render_table($t);
        } else {
            return "";
        }
    } else {
        # tab-separated
        my @t;
        for my $row (@$data) {
            push @t, join("\t", map { $self->_format_cell($_) } @$row) .
                "\n";
        }
        return join("", @t);
    }
}

sub _format_aoh {
    my ($self, $data, $struct_meta) = @_;
    # show aoh as table
    my @cols = @{ $self->_order_table_columns(
        [keys %{$struct_meta->{columns}}]) };
    if ($self->{opts}{interactive}) {
        my $t = {cols=>\@cols, rows=>[]};
        for my $i (0..@$data-1) {
            my $row = $data->[$i];
            push @{ $t->{rows} }, [map {$self->_format_cell($row->{$_})} @cols];
        }
        return $self->_render_table($t);
    } else {
        # tab-separated
        my @t;
        for my $row (@$data) {
            my @row = map {$self->_format_cell($row->{$_})} @cols;
            push @t, join("\t", @row) . "\n";
        }
        return join("", @t);
    }
}

sub _format_hot {
    my ($self, $data) = @_;
    # show hot as paragraphs:
    #
    # key:
    # value (table)
    #
    # key2:
    # value ...
    my @t;
    for my $k (sort keys %$data) {
        push @t, "$k:\n", $self->_format($data->{$k}), "\n";
    }
    return join("", @t);
}

sub _format {
    my ($self, $data) = @_;

    my ($struct, $struct_meta) = $self->_detect_struct($data);

    if (!$struct) {
        return $self->_format_unknown($data, $struct_meta);
    } elsif ($struct eq 'scalar') {
        return $self->_format_scalar($data, $struct_meta);
    } elsif ($struct eq 'list') {
        return $self->_format_list($data, $struct_meta);
    } elsif ($struct eq 'hash') {
        return $self->_format_hash($data, $struct_meta);
    } elsif ($struct eq 'aoa') {
        return $self->_format_aoa($data, $struct_meta);
    } elsif ($struct eq 'aoh') {
        return $self->_format_aoh($data, $struct_meta);
    } elsif ($struct eq 'hot') {
        return $self->_format_hot($data, $struct_meta);
    } else {
        die "BUG: Unknown format `$struct`";
    }
}

sub _order_table_columns {
    #$log->tracef('=> _order_table_columns(%s)', \@_);
    my ($self, $cols) = @_;

    my $found; # whether we found an ordering in table_column_orders
    my $tco = $self->{opts}{table_column_orders};
    my %orders; # colname => idx
    if ($tco) {
        die "table_column_orders should be an arrayref"
            unless ref($tco) eq 'ARRAY';
      CO:
        for my $co (@$tco) {
            die "table_column_orders elements must all be arrayrefs"
                unless ref($co) eq 'ARRAY';
            for (@$co) {
                next CO unless $_ ~~ @$cols;
            }

            $found++;
            for (my $i=0; $i<@$co; $i++) {
                $orders{$co->[$i]} = $i;
            }
            $found++;
            last CO;
        }
    }

    my @ocols;
    if ($found) {
        @ocols = sort {
            (defined($orders{$a}) && defined($orders{$b}) ?
                 $orders{$a} <=> $orders{$b} : 0)
                || $a cmp $b
        } (sort @$cols);
    } else {
        @ocols = sort @$cols;
    }

    \@ocols;
}

1;
# ABSTRACT: Pretty-print data structure for console output

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::Console - Pretty-print data structure for console output

=head1 VERSION

This document describes version 0.38 of Data::Format::Pretty::Console (from Perl distribution Data-Format-Pretty-Console), released on 2017-07-10.

=head1 SYNOPSIS

In your program:

 use Data::Format::Pretty::Console qw(format_pretty);
 ...
 print format_pretty($result);

Some example output:

Scalar, format_pretty("foo"):

 foo

List, format_pretty([1..21]):

 .------------------------------------------------------.
 |  1 |  3 |  5 |  7 |  9 | 11 | 13 | 15 | 17 | 19 | 21 |
 |  2 |  4 |  6 |  8 | 10 | 12 | 14 | 16 | 18 | 20 |    |
 '----+----+----+----+----+----+----+----+----+----+----'

The same list, when program output is being piped (that is, (-t STDOUT) is
false):

 1
 2
 3
 4
 5
 6
 7
 8
 9
 10
 11
 12
 14
 15
 16
 17
 18
 19
 20
 21

Hash, format_pretty({foo=>"data",bar=>"format",baz=>"pretty",qux=>"console"}):

 +-----+---------+
 | bar | format  |
 | baz | pretty  |
 | foo | data    |
 | qux | console |
 '-----+---------'

2-dimensional array, format_pretty([ [1, 2, ""], [28, "bar", 3], ["foo", 3,
undef] ]):

 +---------+---------+---------+
 |       1 |       2 |         |
 |      28 | bar     |       3 |
 | foo     |       3 |         |
 '---------+---------+---------'

An array of hashrefs, such as commonly found if you use DBI's fetchrow_hashref()
and friends, format_pretty([ {a=>1, b=>2}, {b=>2, c=>3}, {c=>4} ]):

 .-----------.
 | a | b | c |
 +---+---+---+
 | 1 | 2 |   |
 |   | 2 | 3 |
 |   |   | 4 |
 '---+---+---'

Some more complex data, format_pretty({summary => "Blah...", users =>
[{name=>"budi", domains=>["foo.com", "bar.com"], quota=>"1000"}, {name=>"arif",
domains=>["baz.com"], quota=>"2000"}], verified => 0}):

 summary:
 Blah...

 users:
 .---------------------------------.
 | domains          | name | quota |
 +------------------+------+-------+
 | foo.com, bar.com | budi |  1000 |
 | baz.com          | arif |  2000 |
 '------------------+------+-------'

 verified:
 0

Structures which can't be handled yet will simply be output as YAML,
format_pretty({a {b=>1}}):

 ---
 a:
   b: 1

=head1 DESCRIPTION

This module is meant to output data structure in a "pretty" or "nice" format,
suitable for console programs. The idea of this module is that for you to just
merrily dump data structure to the console, and this module will figure out how
to best display your data to the end-user.

Currently this module tries to display the data mostly as a nice text table (or
a series of text tables), and failing that, display it as YAML.

This module takes piping into consideration, and will output a simpler, more
suitable format when your user pipes your program's output into some other
program.

Most of the time, you don't have to configure anything, but some options are
provided to tweak the output.

=for Pod::Coverage ^(content_type)$

=head1 FUNCTIONS

=for Pod::Coverage new

=head2 format_pretty($data, \%opts)

Return formatted data structure. Options:

=over

=item * interactive => BOOL (optional, default undef)

If set, will override interactive terminal detection (-t STDOUT). Simpler
formatting will be done if terminal is non-interactive (e.g. when output is
piped). Using this option will force simpler/full formatting.

=item * list_max_columns => INT

When displaying list as columns, specify maximum number of columns. This can be
used to force fewer columns (for example, single column) instead of using the
whole available terminal width.

=item * table_column_orders => [[COLNAME1, COLNAME2], ...]

Specify column orders when drawing a table. If a table has all the columns, then
the column names will be ordered according to the specification. For example,
when table_column_orders is [[qw/foo bar baz/]], this table's columns will not
be reordered because it doesn't have all the mentioned columns:

 |foo|quux|

But this table will:

 |apple|bar|baz|foo|quux|

into:

 |apple|foo|bar|baz|quux|

=item * table_column_formats => [{COLNAME=>FMT, ...}, ...]

Specify formats for columns. Each table format specification is a hashref
{COLNAME=>FMT, COLNAME2=>FMT2, ...}. It will be applied to a table if the table
has all the columns. FMT is a format specification according to
L<Data::Unixish::Apply>, it's basically either a name of a dux function (e.g.
C<"date">) or an array of function name + arguments (e.g. C<< [['date', [align
=> {align=>'middle'}]] >>). This will be fed to L<Text::ANSITable>'s C<formats>
column style.

=item * table_column_types => [{COLNAME=>TYPE, ...}, ...]

Specify types for columns. Each table format specification is a hashref
{COLNAME=>TYPE, COLNAME2=>TYPE2, ...}. It will be applied to a table if the
table has all the columns. TYPE is type name according to L<Sah> schema. This
will be fed to L<Text::ANSITable>'s C<type> column style to give hints on how to
format the column. Sometimes this is the simpler alternative to
C<table_column_formats>.

=back

=head1 ENVIRONMENT

=over

=item * INTERACTIVE => BOOL

To set default for C<interactive> option (overrides automatic detection).

=item * FORMAT_PRETTY_LIST_MAX_COLUMNS => INT

To set C<list_max_columns> option.

=item * FORMAT_PRETTY_TABLE_COLUMN_FORMATS => ARRAY (JSON)

To set C<table_column_formats> option, interpreted as JSON.

=item * FORMAT_PRETTY_TABLE_COLUMN_TYPES => ARRAY (JSON)

To set C<table_column_types> option, interpreted as JSON.

=item * FORMAT_PRETTY_TABLE_COLUMN_ORDERS => ARRAY (JSON)

To set C<table_column_orders> option, interpreted as JSON.

=item * COLUMNS => INT

To override terminal width detection.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-Console>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Format-Pretty-Console>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-Console>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Modules used for formatting: L<Text::ANSITable>, L<YAML>.

L<Data::Format::Pretty>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
