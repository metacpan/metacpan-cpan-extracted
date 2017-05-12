use strict;
package Apache::Wyrd::Interfaces::Columnize;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Interfaces::Columnize - Add limited table auto-formatting

=head1 SYNOPSIS

	use base qw(Apache::Wyrd::Intefaces::Columnize Apache::Wyrd);

	sub _format_output {
		my ($self) = @_;
		my @items = $self->_get_items;
		my $data = $self->_columnize(@items);
		$self->_data($data);
	}

=head1 DESCRIPTION

Arranges a given array of items into a table based on the number found
in the Wyrd's C<columns> attribute.

Currently, the interface also will interpret the C<style> attribute of
the Wyrd to be included as the named style of the table data (TD) tags
it uses to build the table.  It also looks to the C<cellpadding> and
C<cellspacing> attributes to pass to the enclosing table.  These
criteria are under review may change in the future.

=head1 HTML ATTRIBUTES

=item columns

The number of columns the table will consist of.  The table will be
line- broken based on this number of columns.

=item direction

When set to "down", will arrange the items left-column first, moving
right.  Otherwise, they are arranged left to right across the columns.

=head1 METHOD

=item _columnize

Takes an array of items, assumed to be HTML text and arranges them in
columns (by default, across-first) of an HTML Table, and returns the
text of that table.

=cut

sub _columnize {
	my($self, @items) = @_;

	my $cols = ($self->{'columns'} || 1);
	my $class = ($self->{'class'});
	$class = qq( class="$class") if $class;
	my $cellpadding = ($self->{'cellpadding'} || '0');
	my $cellspacing = ($self->{'cellspacing'} || '0');

	my $out = undef;
	my $rows = scalar(@items) ? int(1 + (@items/$cols)) : 1;
	if ($self->{'direction'} eq 'down') {#only re-map the array to the down-first direction if specified
		my (@newitems, $counter, $rowcounter) = ();
		my $count = $#items;
		while (@items) {#map a new array by iterating across the old array horizontal-wise
			my $cursor = $counter;
			while ($cursor <= $count) {
				my $item = shift @items;
				$newitems[$cursor] = $item;
				$cursor += $cols;
			}
			$counter++;
		}
		while (@newitems < ($cols * $rows)) {#fill in additional items;
			push @newitems, '&nbsp';
		}
		@items = @newitems;
	}
	while (@items) {
		$out .= join (
			'',
			'<tr>',
			(
				map {qq(<td$class>$_</td>)}
				map {$_ || '&nbsp;'}
				splice(@items, 0, $cols)
			),
			'</tr>'
		);
	}
	$out =  qq(<table border="0" cellpadding="$cellpadding" cellspacing="$cellspacing">$out</table>);
	return $out;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;