package DBIx::TextIndex::DBD::mysql;

use strict;
use warnings;

our $VERSION = '0.26';

use base qw(DBIx::TextIndex::DBD);

sub insert_doc_key {
    my $self = shift;
    my $doc_key = shift;

    my $sql = <<END;
INSERT INTO $self->{DOC_KEY_TABLE} (doc_key) VALUES (?)
END

    $self->{INDEX_DBH}->do($sql, undef, $doc_key);
    my $doc_id = $self->{INDEX_DBH}->{mysql_insertid};
    return $doc_id;
}

1;
__END__

=head1 NAME

DBIx::TextIndex::DBD::mysql - Driver for MySQL

=head1 SYNOPSIS

 require DBIx::TextIndex::DBD::mysql;

=head1 DESCRIPTION

Contains MySQL-specific overrides for methods of L<DBIx::TextIndex::DBD>.

Used internally by L<DBIx::TextIndex>.


=head1 INTERFACE

=head2 Restricted Methods

=over

=item C<insert_doc_key>

=back


=head1 AUTHOR

Daniel Koch, dkoch@cpan.org.


=head1 COPYRIGHT

Copyright 1997-2007 by Daniel Koch.
All rights reserved.


=head1 LICENSE

This package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, i.e., under the terms of the "Artistic
License" or the "GNU General Public License".


=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut
