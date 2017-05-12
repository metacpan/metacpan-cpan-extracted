# -*- perl -*-

package Bundle::Egrail;

$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::Egrail - A bundle to install 'eGrail Open-Source' perl prerequisites

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Egrail'>

=head1 CONTENTS

Image::Size

Digest::MD5

Net::FTP

File::NCopy

Mail::Sendmail

Array::RefElem

XML::Parser

XML::RSS

Data::DumpXML

MIME::Base64

URI

LWP::UserAgent

Date::Calc

DBI

=head1 DESCRIPTION

This bundle includes the perl prerequisites you need to run 'eGrail Open-Source'. The full-working
installation would also require:

 1. mysql-3.22.32.tar.gz
 2. apache_1.3.12.tar.gz
 3. php-4.0.1pl2.tar.gz
 4. gd1.3.tar.gz
 5. freetype-1.3.1.tar.gz
 6. t1lib-1.0.tar.gz

=cut

=head1 INFO

Visit the project-website to download the source and complete installation instructions:

http://sourceforge.net/projects/egrail-source/

=head1 AUTHOR

Murat Uenalan (murat.uenalan@gmx.de), who only created this bundle-file.

=cut
