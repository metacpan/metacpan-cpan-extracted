# -*- Perl -*-
#
# Data::Xtab - cross-tabulate a table of data.
#
# Copyright (c) 1997, Brian C. Jepson
#
# You may distribute this under the same terms as Perl
# itself.
#

$Data::Xtab::VERSION = '1.01';

=head1 NAME

Data::Xtab - Pivot (cross-tabulate) a table of data.

=head1 DESCRIPTION

This module allows you to feed it tables of data to be
pivoted in such a way that they can be easily used in a
report or graph. Here is an example of input data:

  'A', 'JUN', 7
  'A', 'JAN', 4
  'B', 'JAN', 3
  'B', 'FEB', 39
  'C', 'MAY', 8
  'A', 'JUN', 100

The output would be rendered as:

          JAN     FEB     MAR     APR     MAY     JUN
  A       4       0       0       0       0       107
  B       3       39      0       0       0       0
  C       0       0       0       0       8       0

The first column in the table ends up becoming the data
series. The second column becomes the headers, under which
the third column is summed. If more than one data records 
for the same data series and header column appear in the
input data, the values are totalled for that intersection.

This module was designed to be used in conjunction with the
GIFGraph module, but no doubt has other uses.

=head1 SYNOPSIS

  #!/usr/local/bin/perl

  use Data::Xtab;
  use GIFgraph::lines;
  use CGI;
  $query = new CGI;
  print $query->header("image/gif");

  my @data = ( ['A', 'FEB', 31],
               ['A', 'FEB', 12],
               ['A', 'MAR', 18],
               ['A', 'MAR', 29],
               ['A', 'APR', 142],
               ['B', 'FEB', 217],
               ['B', 'FEB', 14],
               ['B', 'MAR', 121],
               ['B', 'APR', 37],
               ['C', 'MAR', 39],
               ['C', 'MAR', 8],
               ['C', 'APR', 100] );

  # The outputcols parameter is used to enumerate the
  # columns that should be used in the output table, and
  # more importantly, the order in which they should appear.
  #
  my @outputcols = ('JAN', 'FEB', 'MAR', 'APR');

  my $xtab = new Data::Xtab(\@data, \@outputcols);
 
  my @graph_data = $xtab->graph_data;

  $my_graph = new GIFgraph::lines();

  $my_graph->set( 'x_label' => 'Month',
                  'y_label' => 'Sales',
                  'title' => 'Monthly Sales',
                  'y_max_value' => 450,
                  'y_tick_number' => 5,
                  'y_label_skip' => 2 );
  print $my_graph->plot( \@graph_data );

=head1 AUTHOR

Copyright (c) 1997, Brian Jepson
You may distribute this kit under the same terms as Perl itself.

=cut

package Data::Xtab;
use strict;

sub new {

  my $class = shift;

  my $self = {};
  bless($self,$class);

  $self->{data} = shift;
  $self->{cols} = shift;

  $self->pivot;

  return $self;

}

# Pivot the data.
#
sub pivot {

  my $self = shift;

  my %rows;

  # This is the input data.
  #
  my @data = @{ $self->{data} };

  my @cols;
  foreach (@data) {

    # Each row in the input data is a reference to an array
    # of the row_label, column_label, and data value. The 
    # row_label is the value that describes each data series. 
    # The column_label is the value that is used as headers 
    # for each columns, and the data value is the information 
    # that appears cross-referenced between the row_label and
    # column_label values.
    #
    # In the SYNOPSIS section of the documentation, the
    # 'A', 'B' and 'C' values are the row_label values, and 
    # the months (FEB-APR) are the column_label values.
    #
    my $row_label = $$_[0];
    my $column_label = $$_[1];

    # By incrementing the row_label attribute, we ensure
    # that each row_label gets listed in an easy-to-fetch 
    # lookup hash.
    #
    $self->{row_label}->{$row_label}++;

    # By incrementing the column_label attribute, we ensure
    # that each pivoted column gets listed in an 
    # easy-to-fetch lookup hash.
    #
    $self->{column_label}->{$column_label}++;

    # The values are stored in a hash of hashes - keyed
    # first by the row_label, and then by the column_label 
    # value. Note that the values can be cumulative, as you 
    # can have more than one data element that goes into a 
    # given row_label/column_label value "bucket."
    #
    $rows{$row_label}{$column_label} += $$_[2];
  
  }

  # If, for some reason, the user didn't pass in a list of
  # column titles, then we'll sort the keys we have in the
  # column_label attribute, and use that. This is a bad
  # idea, particularly with character month names and data
  # sets that may have gaps. It's best to always explicitly
  # supply the columns.
  #
  @cols = sort keys %{ $self->{column_label} };
  $self->{cols} ||= \@cols;

  return (%{$self->{'rows'}}  = %rows);

}

sub row_labels {
  my ($self) = shift;
  keys %{$self->{row_label}};
}

# massage the cross-tab into something that GIFgraph.pm can
# handle.
#
sub graph_data {
    my $self = shift;

    my %rows = %{$self->{rows}};
    my @graph_data;
    my @header;
    foreach my $col ( @{$self->{cols}}) {
        push @header, $col;
    }
    push @graph_data, \@header;
    my @total;
    foreach my $row ($self->row_labels) {
        my @data;
        my $i;
        foreach my $col (@{$self->{cols}}) {

            my $val = 0;
            if (defined $rows{$row}{$col}) {
                $val = $rows{$row}{$col} * 1;
            }
            push @data, $val;
            $total[$i++] += $val;
        }
        push @graph_data, \@data;
    }
    push @graph_data, \@total;
    @graph_data;
}

1;
