use strict;
package Apache::Wyrd::Site::MySQLIndexBot;
use base qw(Apache::Wyrd::Site::IndexBot);
our $VERSION = '0.98';

sub purge_missing {
	my ($self, $instance) = @_;
	my @no_skip = ();
	$instance->read_db;
	my $root = $self->{'document_root'};
	my $sh=$instance->db->prepare('select id, name from _wyrd_index');
	$sh->execute;
	while (my $data_ref=$sh->fetchrow_arrayref) {
		my $id = $data_ref->[0];
		my $file = $data_ref->[1];
		if ($file =~ m{^/}) {
			my $exists = -f $root . $file;
			unless ($exists) {
				print $instance->purge_entry($id) . "\n";
			}
		}
	}
	return @no_skip;
}

=pod

=head1 NAME

Apache::Wyrd::Site::MySQLIndexBot - MySQL-backend version of Apache::Wyrd::Site::IndexBot

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

In all ways identical to C<Apache::Wyrd::Site::IndexBot>, save that it works
with the Apache::Wyrd::Services::MySQLIndex and
Apache::Wyrd::Site::MySQLIndex types of indexes.

See that package for further details.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Site::IndexBot

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut


1;