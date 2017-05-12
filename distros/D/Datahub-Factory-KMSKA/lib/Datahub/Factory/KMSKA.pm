package Datahub::Factory::KMSKA;

use strict;

our $VERSION = '0.01';

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::KMSKA - Import data from the L<TMS|http://www.gallerysystems.com/products-and-services/tms/> instance of the L<KMSKA|http://kmska.be/nl/>

=head1 SYNOPSIS

    use Datahub::Factory::Importer::KMSKA;
    use Data::Dumper qw(Dumper);

    my $kmska = Datahub::Factory::Importer::KMSKA->new(
        db_host     => 'localhost',
        db_name     => 'kmska',
        db_user     => 'kmska',
        db_password => 'kmska'
    );

    $kmska->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::KMSKA uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from a local instance of L<TMS|http://www.gallerysystems.com/products-and-services/tms/> as it is configured in
the L<KMSKA|http://kmska.be/nl/>. This module does not give you access to the database of the museum, but
allows you to pull and parse data from it if you already have access. For a more generic interface to TMS,
see L<Datahub::Factory::Importer::TMS>. Both modules require however that the TMS database is stored in a MySQL
(or equivalent) system. It will not work with MS SQL (which TMS uses).

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
L<Datahub::Factory::Importer::TMS>
L<Catmandu>

=cut