package Catmandu::XLS;

our $VERSION = '0.08';

=head1 NAME

Catmandu::XLS - modules for working with Excel .xls and .xlsx files

=begin markdown

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-XLS.png)](https://travis-ci.org/LibreCat/Catmandu-XLS)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-XLS/badge.png?branch=dev&service=github)](https://coveralls.io/github/LibreCat/Catmandu-XLS?branch=dev)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-XLS.png)](http://cpants.cpanauthors.org/dist/Catmandu-XLS)
[![CPAN version](https://badge.fury.io/pl/Catmandu-XLS.png)](http://badge.fury.io/pl/Catmandu-XLS)

=end markdown

=head1 SYNPOSIS

    # Convert Excel to CSV
    $ catmandu convert XLS to CSV < ./t/test.xls > test.csv
    $ catmandu convert XLSX to CSV < ./t/test.xlsx > test.csv

    # Convert Excel to JSON
    $ catmandu convert XLS to JSON
    $ catmandu convert XLS 

    # Convert Excel to JSON providing own field names
    $ catmandu convert XLS --field title,name,isbn

    # Convert Excel to JSON using the column coordinates as field names
    $ catmandu convert XLS --columns 1

    # Convert CSV to Excel
    $ catmandu convert CSV to XLS < test.csv
    $ catmandu convert CSV to XLSX  < test.csv

=head1 MODULES

=over

=item * L<Catmandu::Importer::XLS>

=item * L<Catmandu::Importer::XLSX>

=item * L<Catmandu::Exporter::XLS>

=item * L<Catmandu::Exporter::XLSX>

=back

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTOR

Vitali Peil, C<< <vitali.peil at uni-bielefeld.de> >>

Johann Rolschewski, C<< <jorol at cpan.org> >>

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=cut

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nicolas Steenlant.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
