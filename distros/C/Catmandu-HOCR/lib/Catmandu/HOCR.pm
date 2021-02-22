package Catmandu::HOCR;
use Catmandu::Sane;

our $VERSION = "0.02";

=encoding utf8

=head1 NAME

Catmandu::HOCR - tools to work with HOCR documents

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-HOCR.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-HOCR)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Importer-HOCR/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-HOCR)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-HOCR.png)](http://cpants.cpanauthors.org/dist/Catmandu-HOCR)

=end markdown

=head1 SYNOPSIS

    #From the command line

    #Extract OCR data

    $ catmandu convert HOCR --file input.xml to YAML

    #In a script

    use Catmandu::Sane;

    use Catmandu::Importer::HOCR;

    my $importer = Catmandu::Importer::HOCR->new( file => "/tmp/input.html" );

    $importer->each(sub{

        my $record = $_[0];
        #..

    });

=head1 EXAMPLE OUTPUT IN YAML

    ---
    h: 38
    page: 1
    page_h: 3316
    page_w: 2904
    page_x: 0
    page_y: 0
    text: '1'
    w: 17
    x: 2349
    y: 2717
    ...

=head1 INSTALLATION

In order to install this package you need the following system packages installed

=over

=item Centos

* perl-devel

* make

* gcc

* gcc-c++

* libyaml-devel

* libxml2 version 2.6.21 or higher. Reason: the module XML::LibXML::Reader uses the libxml2 pull parser to read xml documents incrementally.

=back

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Importer::HOCR>, L<XML::LibXML::Reader>, L<Catmandu>, L<Catmandu::Importer>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
