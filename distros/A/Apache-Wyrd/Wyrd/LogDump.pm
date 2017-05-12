#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::LogDump;
our $VERSION = '0.98';
use base qw (Apache::Wyrd::Interfaces::Setter Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::LogDump - Debug Wyrd tool

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

Internal Wyrd used by the Debug Wyrd for dumping the debugging log to a
popup window.

It has no usefully configurable options.

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup method.

=cut

sub _setup{
	my ($self) = @_;
	my @log = ();
	my $dumpfile = ($self->dbl->globals->{logfile} || '/tmp/' . $self->dbl->req->hostname . '.debuglog');
	open (INLOG, $dumpfile);
	my $tally = undef;
	while (<INLOG>) {
		if (/^\(/) {
			push @log, $tally;
			$tally = undef;
		}
		$tally .= $_;
	}
	push @log, $tally;
	close (INLOG);
	my $log = join('', reverse(@log));
	if ($self->_data =~ /\$:dump/m) {
		$self->_set({dump => $log});
	} else {
		$self->_data($log);
	}
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

