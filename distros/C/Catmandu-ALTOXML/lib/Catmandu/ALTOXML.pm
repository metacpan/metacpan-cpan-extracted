package Catmandu::ALTOXML;
use Catmandu::Sane;

our $VERSION = "0.01";

=encoding utf8

=head1 NAME

Catmandu::ALTOXML - tools to work with ALTOXML documents

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-ALTOXML.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-ALTOXML)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Importer-ALTOXML/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-ALTOXML)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-ALTOXML.png)](http://cpants.cpanauthors.org/dist/Catmandu-ALTOXML)

=end markdown

=head1 SYNOPSIS

    #From the command line

    #Extract OCR data, treating each line as a record

    $ catmandu convert ALTOXML --file input.xml to YAML

    #In a script

    use Catmandu::Sane;

    use Catmandu::Importer::ALTOXML;

    my $importer = Catmandu::Importer::ALTOXML->new( file => "/tmp/input.xml" );

    $importer->each(sub{

        my $record = $_[0];
        #..

    });

=head1 EXAMPLE OUTPUT IN YAML

    ---
    block: 5
    block_h: 63
    block_w: 114
    block_x: 2294
    block_y: 2713
    h: 38
    page: 1
    page_h: 3316
    page_w: 2904
    page_x: ~
    page_y: ~
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

L<Catmandu::Importer::ALTOXML>, L<XML::LibXML::Reader>, L<Catmandu>, L<Catmandu::Importer>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
