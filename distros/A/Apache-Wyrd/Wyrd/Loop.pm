package Apache::Wyrd::Loop;
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw (Apache::Wyrd::Interfaces::Setter Apache::Wyrd::Interfaces::Stealth Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(:db);

our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Loop - Loop through SQL query results

=head1 SYNOPSIS

    <BASENAME::Loop query="select name from contact">
      <P>$:name</P>
    </BASENAME::Loop>

    <BASENAME::Loop
     query="select name from contact where name is like 'S%'">
      <b>$:name</b>
    </BASENAME::Loop>

=head1 DESCRIPTION

Loop performs a given query and iterates through the result of the query,
C<set>-ting the enclosed text for each query item and concatinating the
results together.  Unlike normal Wyrds, however, the enclosed text is NOT
interpreted prior to this treatment, allowing Wyrds to be included in this
template.

=head2 HTML ATTRIBUTES

=over

=item query

The query to pass to the SQL engine.  Use Apache::Wyrd::Attribute if this
query has unsafe characters (quote, <, etc.).

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup and _format_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'_template'} = $self->_data;
	$self->{'_data'} = '';
	return;
}

sub _format_output {
	my ($self) = @_;
	my $out = '';
	my $query = $self->{'query'};
	my $sh = $self->cgi_query($query);
	while (my $values = $sh->fetchrow_hashref) {
		$out .= $self->_set($values, $self->_template);
	}
	$self->_data($out);
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

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut


1;