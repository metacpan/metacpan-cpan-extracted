use strict;
use warnings;

package Code::Statistics::Reporter;
{
  $Code::Statistics::Reporter::VERSION = '1.112980';
}

# ABSTRACT: creates reports statistics and outputs them

use 5.004;

use Moose;
use MooseX::HasDefaults::RO;
use Code::Statistics::MooseTypes;
use Code::Statistics::Metric;

use Carp 'confess';
use JSON 'from_json';
use File::Slurp 'read_file';
use List::Util qw( reduce max sum min );
use Data::Section -setup;
use Template;
use List::MoreUtils qw( uniq );
use Clone qw( clone );

has quiet => ( isa => 'Bool' );

has file_ignore => (
    isa    => 'CS::InputList',
    coerce => 1,
    default => sub {[]},
);

has screen_width => ( isa => 'Int', default => 80 );
has min_path_width => ( isa => 'Int', default => 12 );
has table_length => ( isa => 'Int', default => 10 );


sub report {
    my ( $self ) = @_;

    my $stats = from_json read_file('codestat.out');

    $stats->{files} = $self->_strip_ignored_files( @{ $stats->{files} } );
    $stats->{target_types} = $self->_prepare_target_types( $stats->{files} );

    $_->{metrics} = $self->_process_target_type( $_, $stats->{metrics} ) for @{$stats->{target_types}};

    my $output;
    my $tmpl = $self->section_data( 'dos_template' );
    my $tt = Template->new( STRICT => 1 );
    $tt->process(
        $tmpl,
        {
            targets => $stats->{target_types},
            truncate_front => sub {
                my ( $string, $length ) = @_;
                return $string if $length >= length $string;
                return substr $string, 0-$length, $length;
            },
        },
        \$output
    ) or confess $tt->error;

    print $output if !$self->quiet;

    return $output;
}

sub _strip_ignored_files {
    my ( $self, @files ) = @_;

    my @ignore_regexes = grep { $_ } @{ $self->file_ignore };

    for my $re ( @ignore_regexes ) {
        @files = grep { $_->{path} !~ $re } @files;
    }

    return \@files;
}

sub _sort_columns {
    my ( $self, %widths ) = @_;

    # get all columns in the right order
    my @start_columns = qw( path line col );
    my %end_columns = ( 'deviation' => 1 );
    my @columns = uniq grep { !$end_columns{$_} } @start_columns, sort keys %widths;
    push @columns, keys %end_columns;

    @columns = grep { $widths{$_} } @columns;   # remove the ones that have no data

    # expand the rest
    @columns = map $self->_make_col_hash( $_, \%widths ), @columns;

    # calculate the width left over for the first column
    my $used_width = sum( values %widths ) - $columns[0]{width};
    my $first_col_width = $self->screen_width - $used_width;

    # special treatment for the first column
    for ( @columns[0..0] ) {
        $_->{width} = max( $self->min_path_width, $first_col_width );
        $_->{printname} = substr $_->{printname}, 1;
    }

    return \@columns;
}

sub _make_col_hash {
    my ( $self, $col, $widths ) = @_;

    my $short_name = $self->_col_short_name($_);
    my $col_hash = {
        name => $_,
        width => $widths->{$_},
        printname => " $short_name",
    };

    return $col_hash;
}

sub _prepare_target_types {
    my ( $self, $files ) = @_;

    my %target_types;

    for my $file ( @{$files} ) {
        for my $target_type ( keys %{$file->{measurements}} ) {
            for my $target ( @{$file->{measurements}{$target_type}} ) {
                $target->{path} = $file->{path};
                push @{ $target_types{$target_type}->{list} }, $target;
            }
        }
    }

    $target_types{$_}->{type} = $_ for keys %target_types;

    return [ values %target_types ];
}

sub _process_target_type {
    my ( $self, $target_type, $metrics ) = @_;

    my @metric = map $self->_process_metric( $target_type, $_ ), @{$metrics};

    return \@metric;
}

sub _process_metric {
    my ( $self, $target_type, $metric ) = @_;

    return if "Code::Statistics::Metric::$metric"->is_insignificant;
    return if !$target_type->{list} or !@{$target_type->{list}};
    return if !exists $target_type->{list}[0]{$metric};

    my @list = reverse sort { $a->{$metric} <=> $b->{$metric} } @{$target_type->{list}};

    my $metric_data = { type => $metric };

    $metric_data->{avg} = $self->_calc_average( $metric, @list );

    $self->_prepare_metric_tables( $metric_data, @list ) if $metric_data->{avg} and $metric_data->{avg} != 1;

    return $metric_data;
}

sub _prepare_metric_tables {
    my ( $self, $metric_data, @list ) = @_;

    $metric_data->{top} = $self->_get_top( @list );
    $metric_data->{bottom} = $self->_get_bottom( @list );
    $self->_calc_deviation( $_, $metric_data ) for ( @{$metric_data->{top}}, @{$metric_data->{bottom}} );
    $metric_data->{widths} = $self->_calc_widths( $metric_data );
    $metric_data->{columns} = $self->_sort_columns( %{ $metric_data->{widths} } );

    return;
}

sub _calc_deviation {
    my ( $self, $line, $metric_data ) = @_;

    my $avg = $metric_data->{avg};
    my $type = $metric_data->{type};

    my $deviation = $line->{$type} / $avg;
    $line->{deviation} = sprintf '%.2f', $deviation;

    return;
}

sub _calc_widths {
    my ( $self, $metric_data ) = @_;

    my @entries = @{$metric_data->{top}};
    @entries = ( @entries, @{$metric_data->{bottom}} );

    my @columns = keys %{$entries[0]};

    my %widths;
    for my $col ( @columns ) {
        my @lengths = map { length $_->{$col} } @entries;
        push @lengths, length $self->_col_short_name($col);
        my $max = max @lengths;
        $widths{$col} = $max;
    }

    $_++ for values %widths;

    return \%widths;
}

sub _calc_average {
    my ( $self, $metric, @list ) = @_;

    my $sum = reduce { $a + $b->{$metric} } 0, @list;
    my $average = $sum / @list;

    return $average;
}

sub _get_top {
    my ( $self, @list ) = @_;

    my $slice_end = min( $#list, $self->table_length - 1 );
    my @top = grep { defined } @list[ 0 .. $slice_end ];

    return clone \@top;
}

sub _get_bottom {
    my ( $self, @list ) = @_;

    return [] if @list < $self->table_length;

    @list = reverse @list;
    my $slice_end = min( $#list, $self->table_length - 1 );
    my @bottom = @list[ 0 .. $slice_end ];

    my $bottom_size = @list - $self->table_length;
    @bottom = splice @bottom, 0, $bottom_size if $bottom_size < $self->table_length;

    return clone \@bottom;
}

sub _col_short_name {
    my ( $self, $col ) = @_;
    return ucfirst "Code::Statistics::Metric::$col"->short_name;
}

1;



=pod

=head1 NAME

Code::Statistics::Reporter - creates reports statistics and outputs them

=head1 VERSION

version 1.112980

=head2 reports
    Creates a report on given code statistics and outputs it in some way.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut


__DATA__
__[ dos_template ]__

================================================================================
============================ Code Statistics Report ============================
================================================================================

[% FOR target IN targets %]
================================================================================

    [%- " " FILTER repeat( ( 80 - target.type.length ) / 2 ) %][% target.type %]
================================================================================


    [%- "averages" %]

    [%- FOR metric IN target.metrics %]
        [%- metric.type %]: [% metric.avg %]

    [%- END %]

    [%- FOR metric IN target.metrics %]
        [%- NEXT IF !metric.defined( 'top' ) and !metric.defined( 'bottom' ) %]

        [%- " " FILTER repeat( ( 80 - metric.type.length ) / 2 ) %][% metric.type %]

        [%- FOR table_mode IN [ 'top', 'bottom' ] %]
            [%- NEXT IF !metric.$table_mode.size -%]
            [%- table_mode %] ten

            [%- FOR column IN metric.columns -%]
                [%- column.printname FILTER format("%-${column.width}s") -%]
            [%- END %]
--------------------------------------------------------------------------------

            [%- FOR line IN metric.$table_mode -%]
                [%- FOR column IN metric.columns -%]
                    [%- IF column.name == 'path' # align to the left and truncate -%]
                        [%- truncate_front( line.${column.name}, column.width ) FILTER format("%-${column.width}s") -%]
                    [%- ELSE # align to the right -%]
                        [%- line.${column.name} FILTER format("%${column.width}s") -%]
                    [%- END -%]
                [%- END %]

            [%- END -%]
--------------------------------------------------------------------------------


        [%- END %]
    [%- END -%]
[%- END -%]
