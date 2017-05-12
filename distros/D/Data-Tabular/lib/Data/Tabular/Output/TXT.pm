# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;

package Data::Tabular::Output::TXT;

use base qw(Data::Tabular::Output);

use Carp qw (croak);

use overload '""' => \&_render;

sub new
{
    my $class = shift;
    my $args = { @_ };

    my $self = bless {}, $class;

    die 'No table' unless $args->{table};
    $self->{table} = $args->{table};

    $self->{output} = $args->{output} || croak "Need output";

    $self;
}

sub _render
{
    my $self = shift;
    $self->text;
}

sub text
{
    my $self = shift;
    my $ret = "\n";

    my $output = $self->output;

    my @table;

    my @col_length;

    for my $row ($self->rows(output => $self->output)) {
	for my $cell ($row->cells($output->headers)) {
            my $cell_data = $cell->data;

            my $width = 20; # $cell->width;
	    $cell_data =~ s/^\s*(.*)\s*$/$1/;
	    if ((my $length = length($cell_data)) >= ($col_length[$cell->col_id] || 0)) {
		$col_length[$cell->col_id] = $length;
	    }
	}
    }

    my $right = 0;
    for my $row ($self->rows(output => $self->output)) {
	for my $cell ($row->cells()) {
	    push(@table, " ") if $cell->col_id;
            my $cell_data = $cell->html_string;
            my $width = $col_length[$cell->col_id];
	    $cell_data =~ s/^\s*(.*)\s*$/$1/;
	    my $length = $width - length($cell_data);
	    if ($right) {
		push(@table, " " x $length);
	    }
            push(@table, $cell_data);
	    if (!$right) {
		push(@table, " " x $length);
	    }
	}
	push(@table, "\n");
    }
    $ret .= join('', @table);

    $ret;
}

1;
__END__

=head1 NAME

Data::Tabular::Output::TXT

=head1 SYNOPSIS

This object is used by Data::Tabular to render a table in text format.

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over 4

=item new

Normally this object is constructed by the Data::Tabular::html method.

It requires two arguments: a table and and an output object.

=back

=head1 METHODS

=over 4

=item text

return a string that represents the table.

=cut
1;

