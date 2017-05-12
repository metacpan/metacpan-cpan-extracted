package Bundle::Catalog;

$VERSION = "1.02"

1;

__END__

=head1 NAME

Bundle::Catalog - A bundle to install all Catalog related modules

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::Catalog'

=head1 CONTENTS

DBI 1.13             - Database independent interface for Perl

DBD::mysql 2.0410    - mysql drivers for the Perl Database Interface (DBI)

MD5 1.7		     - Perl interface to the MD5 Message-Digest Algorithm

CGI 2.56	     - Simple Common Gateway Interface Class

XML::Parser 2.27     - parsing XML documents

XML::DOM 1.25	     - building DOM Level 1 compliant document structures

MIME::Base64 2.11    - Encoding and decoding of base64 strings

Unicode::String 2.05 - String of Unicode characters

Unicode::Map8 0.09   - Mapping table between 8-bit chars and Unicode

Text::Query 0.07     - Query parsing and resolver framework

Text::Query::BuildSQL 0.05 - Query implementation for SQL databases

Catalog              - for to get to know thyself

=head1 DESCRIPTION

This bundle includes all the modules used by the Perl Catalog
module.

A I<Bundle> is a module that simply defines a collection of other
modules.  It is used by the L<CPAN> module to automate the fetching,
building and installing of modules from the CPAN ftp archive sites.

=head1 AUTHOR

Loic Dachary <loic@senga.org>

=cut
