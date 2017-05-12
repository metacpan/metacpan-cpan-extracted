package DBIx::Changeset::App::Command::version;

use warnings;
use strict;

use base qw/DBIx::Changeset::App::BaseCommand/;

use DBIx::Changeset;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App::Command::version - display version information

=head1 SYNOPSIS

=head1 METHODS

=head2 run

=cut
sub run {
	my ($self, $opt, $args) = @_;
	
	printf ("Using DBIx::ChangeSet %s\n\n", $DBIx::Changeset::VERSION);

	return;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
