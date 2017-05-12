use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Lattice;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(token_parse);
use Apache::Wyrd::Services::Tree;
use Apache::Wyrd::Query;

=pod

=head1 NAME

Apache::Wyrd::Lattice - Generate HTML Tables from Tabular Data

=head1 SYNOPSIS

  <BASENAME::Lattice>
    <BASENAME::Query>
      <BASENAME::CGISetter style="sql">
        select name, email from contact_database
        where name=$:name
      </BASENAME::CGISetter>
    </BASENAME::Query>
    <BASENAME::Lattice::Header>
      <table class="ctable">
      <tr><th>Name</th><th>E-Mail</th></tr>
    </BASENAME::Lattice::Header>
    <BASENAME::Lattice::Grid>
      <tr bgcolor="#CCCCCC">
        <td class="namecol">$:name</td>
        <td class="emailcol"><a href="mailto:$:email">$:email</a></td>
      </tr></BASENAME::Lattice::Grid>
    <BASENAME::Lattice::Footer></table></BASENAME::Lattice::Footer>
  </BASENAME::Lattice>

=head1 DESCRIPTION

The Lattice Wyrd represents the result of an C<Apache::Wyrd::Query> Wyrd in
HTML.  Three supporting Wyrds, C<Apache::Wyrd::Lattice::Header>,
C<Apache::Wyrd::Lattice::Grid>, C<Apache::Wyrd::Lattice::Footer> give the HTML a
beginning, a repeated middle, and an end.

Unless provided within the Lattice Wyrd, as in the SYNOPSIS, the Lattice
Wyrd defaults to a simple HTML table.  The B<cols> attribute is parsed
(whitespace/comma) to determine these columns.  If no cols attribute is
given, the Grid Wyrd is scanned for placemarkers in the
C<Apache::Wyrd::Interfaces::Setter> style. Lastly, if no Grid Wyrd is given,
Lattice will attempt to create a Grid based on the columns returned by the
Query.  The data will appear in this grid, one column per table column.

=head2 HTML ATTRIBUTES

=over

=item cols

Which columns of the query to display.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<_format_table> (scalar)

=item (scalar) C<_format_tr> (scalar)

=item (scalar) C<_format_th> (scalar)

=item (scalar) C<_format_td> (scalar)

When the Lattice Wyrd is used in default mode, it is very simple to define a
default "house style" by implementing the C<_format_xxx> methods for tables,
rows, headers, and cells.

=cut


sub register_header {
	my ($self, $value) = @_;
	$self->header($value);
	return;
}

sub register_footer {
	my ($self, $value) = @_;
	$self->footer($value);
	return;
}

sub register_grid {
	my ($self, $value) = @_;
	$self->grid($value);
	return;
}

sub register_query {
	my ($self, $value) = @_;
	$self->_raise_exception("argument to register_query must define the sh method.") unless ($value->can('sh'));
	$self->query($value);
	return;
}

sub _auto_encapsulate {
	my ($self) = @_;
	return undef unless ($self->_flags->auto);
	$self->_data($self->_format_table($self->_data));
}

sub _auto_header {
	my ($self) = @_;
	my $out = '';
	my @cols = @{$self->cols};
	foreach my $i (@cols) {
		$out .= $self->_format_th($i);
	}
	$self->_flags->auto('1');
	$self->header($self->_format_tr($out));
	$self->_debug("header is " . $self->header);
}

sub _auto_grid {
	my ($self) = @_;
	my $out = '';
	foreach my $i (@{$self->cols}) {
		#warn("adding column $i to grid");
		$out .= $self->_format_td('$:' . $i);
	}
	$self->_flags->auto('1');
	$self->grid($self->_format_tr($out));
	$self->_debug("grid is " . $self->grid);
}

sub _auto_footer {
	my ($self) = @_;
	$self->_flags->auto('1');
	return '';
}

sub _cols_from_grid {
	my ($self, $value) = @_;
	my @cols = ();
	my $grid = ($value || $self->grid || $self->_raise_exception("Attempt to get cols from grid failed: no grid"));
	while ($grid =~ /(\$:[a-zA-Z0-9_]+)/g) {
		push @cols, $1;
	}
	$self->_debug("Attempt to get cols from grid failed: no settables found in grid.")
		unless scalar(@cols);
	$self->cols(\@cols);
}


=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup and _generate_output methods.  Also reserves the
register_header, register_grid, register_footer, and register_query methods
for the respective sub-Wyrds.  "Automatic" formatting is provided by the
private methods _auto_encapsulate, _auto_header, _auto_grid, _aouto_footer,
and _cols_from_grid.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'cols'} = [token_parse($self->{'cols'})];
	$self->{'header'} ||= '';
	$self->{'footer'} ||= '';
	$self->{'grid'} ||= '';
	$self->{'query'} ||= '';
}

sub _generate_output {
	my ($self) = @_;
	my ($row, $build_row) = ();
	$self->_raise_exception($self->_base_class . ' cannot be used without defining a query')
		unless ($self->query);
	$self->query->activate;
	unless (scalar(@{$self->cols})) {
		$self->_warn("No number of cols defined.");
	#Don't know what columns to use, try extracting them from the query
		if ($self->query->cols) {
			$self->cols($self->query->cols);
		} else {
			#failing that, get them from the grid
			$self->cols($self->_cols_from_grid);
		}
		$self->_raise_exception("Not enough information to derive column values.")
			unless (scalar(@{$self->cols}));
	}
	$self->_auto_header unless ($self->header);
	$self->_auto_footer unless ($self->footer);
	$self->_auto_grid unless ($self->grid);
	my $out = $self->header;
	while (my $row = $self->query->sh->fetchrow_hashref) {
		$out .= $self->_set($row, $self->grid);
	};
	$out .= $self->footer;
	$self->_auto_encapsulate;
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

package Apache::Wyrd::Lattice::Header;
use base qw(Apache::Wyrd);

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception($self->base_class . " may only be used within a Apache::Wyrd::Lattice context")
		unless ($self->_parent->can('register_header'));
	$self->{'_parent'}->register_header($self->_data);
	$self->_data(undef);
	return;
}

package Apache::Wyrd::Lattice::Footer;
use base qw(Apache::Wyrd);

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception($self->base_class . " may only be used within a Apache::Wyrd::Lattice context")
		unless ($self->_parent->can('register_footer'));
	$self->_parent->register_footer($self->_data);
	$self->_data('');
	return;
}

package Apache::Wyrd::Lattice::Grid;
use base qw(Apache::Wyrd);

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception($self->base_class . " may only be used within a Apache::Wyrd::Lattice context")
		unless ($self->_parent->can('register_grid'));
	$self->_parent->register_grid($self->_data);
	$self->_data('');
	return;
}

1;