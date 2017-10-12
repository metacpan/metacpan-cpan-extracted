package Datahub::Factory::Importer::TMS;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use Moo;
use Catmandu;
use DBI;
use Log::Log4perl;
use Config::Simple;
use namespace::clean;

use Datahub::Factory::Importer::TMS::Index;

with 'Datahub::Factory::Importer';

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);

sub _build_importer {
    my $self = shift;
    my $dsn = sprintf('dbi:mysql:%s', $self->db_name);
    my $query = 'select * from vgsrpObjTombstoneD_RO;';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query, encoding => ':iso-8859-1');
    # Add indices
    $self->logger->info('Creating indices on TMS tables.');
    Datahub::Factory::Importer::TMS::Index->new(
        db_host => $self->db_host,
        db_name => $self->db_name,
        db_user => $self->db_user,
        db_password => $self->db_password
    );
    return $importer;
}

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::TMS - Import data from a L<TMS|http://www.gallerysystems.com/products-and-services/tms/> instance

=head1 SYNOPSIS

    use Datahub::Factory;
    use Data::Dumper qw(Dumper);

    my $tms = Datahub::Factory->importer('TMS')->new(
        db_host     => 'localhost',
        db_name     => 'tms',
        db_user     => 'tms',
        db_password => 'tms'
    );

    $tms->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::TMS uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from a local instance of L<TMS|http://www.gallerysystems.com/products-and-services/tms/>The module requires
that the TMS database is stored in a MySQL (or equivalent) system. It will not work with MS SQL (which TMS uses).

=head1 PARAMETERS

=over

=item C<db_host>

Host (IP or FQDN) of the MySQL database.

=item C<db_name>

Name of the MySQL database.

=item C<db_user>

Username to connect to the database.

=item C<db_password>

Password for the user.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Catmandu>

=cut
