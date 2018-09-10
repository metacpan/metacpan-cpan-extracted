package Datahub::Factory::Arthub;

use Datahub::Factory::Sane;
use namespace::clean;

our $VERSION = '1.02';

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Arthub - modules for the L<VKC Arthub|>

=head1 DESCRIPTION

This modules contains packages that the L<VKC Arthub|> uses to extract data from project-specific sources.

It contains the following packages:

=over

=item L<Datahub::Factory::Importer::EIZ>

An importer for the Erfgoed Inzicht organisation based on Adlib / OAI.

=item L<Datahub::Factory::Importer::KMSKA>

An importer for the Royal Musuem of Fine Arts Antwerp based on TMS.

=item L<Datahub::Factory::Importer::VKC>

An importer for the Flemish Art Collection based on Collective Access.

=item L<Datahub::Factory::Exporter::>

An exporter for the Arthub Flanders platform absed on LIDO and OAI.

=back

-head1 KMSKA

The KMSKA module is based on the TMS installation operated by 
the Royal Museum of Fine Arts Antwerp. Before using the module in 
a Datahub::Factory pipeline, you need to execute a SQL file against 
the MySQL (MariaDB) database  which contains a replication of 
the TMS MS SQL database.

Run this command:

$ mysql -u <username> -p <databasename> < Resources/TMS/schema.sql

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>
Pieter De Praetere <pieter@packed.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by PACKED, vzw, Vlaamse Kunstcollectie, vzw.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, June 2007.

=head1 SEE ALSO

L<Datahub::Factory>
L<Catmandu>

=cut
