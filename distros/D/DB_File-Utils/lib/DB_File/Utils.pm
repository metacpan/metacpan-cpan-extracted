# ABSTRACT: Creates db_util command line for DB_File management
package DB_File::Utils;
$DB_File::Utils::VERSION = '0.006';
use warnings;
use strict;
use DB_File;
use Fcntl;

use App::Cmd::Setup -app;

sub global_opt_spec {
  return (
     ['u|utf8' => "Force UTF8 encoding/decoding on values."],
     ['btree' => "Use BTree indexing method (default)"],
     ['hash'  => "Use Hash indexing method"],
     ['recno' => "Use RecNo indexing method"],
  );
}

sub do_tie {
	my ($self, $file, $ops) = @_;

    my $mode   = $ops->{_create_} ? (O_CREAT | O_RDWR) : O_RDWR;
	if ($ops->{recno}) {
		my @array;
		my $method = $DB_RECNO;

		tie @array, 'DB_File', $file, $mode, '0666', $method;

		return \@array;
	}
	else {
		my %hash;
		my $method = $ops->{hash} ? $DB_HASH : $DB_BTREE;

		tie %hash, 'DB_File', $file, $mode, '0666', $method;

		return \%hash;
	}
}


1;

=encoding UTF-8

=head1 NAME

DB_File::Utils - main module for db_util command line tool

=head1 DESCRIPTION

Please refer to C<perldoc db_util> for detail on module usage.

=head1 SEE ALSO

db_util (3)

=head1 AUTHOR

Alberto Simões C<< <ambs@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alberto Simões.

This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut