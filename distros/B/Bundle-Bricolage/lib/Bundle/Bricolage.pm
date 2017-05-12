package Bundle::Bricolage;

our $VERSION = '1.11.0';

1;
__END__

=head1 NAME

Bundle::Bricolage - Modules required to run Bricolage content management system.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Bricolage'>

=head1 DESCRIPTION

The bundle provides an easy way to install all of the modules required by
Bricolage. Bricolage is a 100% pure Perl content-management and publishing
system which features intuitive and highly-configurable administration,
workflow, permissions, templating, server-neutral output, distribution, and
document management.

B<Note:> This bundle does not contain the modules that are optional in
Bricolage. To get those mosules, install
L<Bundle::BricolagePlus|Bundle::BricolagePlus>.

=head1 CONTENTS

Storable - Persistency for perl data structures

Time::HiRes - High resolution ualarm, usleep, and gettimeofday

Unix::Syslog - Perl interface to the UNIX syslog(3) calls

Net::Cmd - Network Command class (as used by FTP, SMTP etc)

Devel::Symdump - Dump symbol names or the symbol table

DBI 1.18 - Database independent interface for Perl

Error - Error/exception handling in an OO-ish way

Cache::Cache - The Cache interface

Cache::Mmap - Shared data cache using memory mapped files

Digest::MD5 - Perl interface to the MD5 Algorithm

Digest::SHA1 2.01 - Perl interface to the SHA-1 Algorithm

URI - Uniform Resource Identifiers (absolute and relative)

HTML::Tagset - Data tables useful in parsing HTML

HTML::Parser - HTML parser class

MIME::Base64 - Encoding and decoding of base64 strings

MIME::Tools - modules for parsing (and creating!) MIME entities

Mail::Address - Parse mail addresses

XML::Writer - Perl extension for writing XML documents

LWP - Library for WWW access in Perl

Image::Info - Extract meta information from image files

MLDBM - Store multi-level hash structure in single level tied hash

Params::Validate 0.57 - Validate method/function parameters

Exception::Class 1.12 - Perl Exceptions Base Class

Class::Container 0.09 - Glues object frameworks together transparently

mod_perl 1.30 - Embed a Perl interpreter in the Apache HTTP server

Apache::Request 1.0 - Generate compiler and linker flags for libapreq

HTML::Mason 1.23 - High-Performance, Dynamic Web Site Authoring System

DBD::Pg 1.22 - PostgreSQL database driver for the DBI module

DB_File - Perl5 access to Berkeley DB version 1.x

Apache::Session 1.54 - A persistence framework for session data

Test::Harness 2.03 - Run perl standard test scripts with statistics

Test::Simple - Basic utilities for writing tests

Test::MockModule 0.04 - Override subroutines in a module for unit testing

Test::File::Contents 0.02 - Test routines for examining the contents of files

Text::Balanced - Extract delimited text sequences from strings

XML::Parser 2.34 - A Perl module for parsing XML documents

XML::Simple - Easy API to read/write XML (esp config files)

IO::Stringy - I/O on in-core objects like strings and arrays

SOAP::Lite 0.55 - Client and server side SOAP implementation

File::Temp - Return Name and Handle of a Temporary File Safely

Text::LevenshteinXS - XS implementation of the Levenshtein edit distance

Locale::Maketext - Framework for Localization in Perl

Test::Class 0.04 - xUnit/JUnit style Test Suite System

Params::CallbackRequest 1.16 - Functional and object-oriented callback architecture

MasonX::Interp::WithCallbacks 1.10 - Mason callback support via Params::CallbackRequest

Safe 2.09 - Compile and execute code in restricted compartments

DateTime 0.21 - Date and time objects

DateTime::TimeZone 0.2601 - Time zone object base class and factory

Term::ReadPassword - Prompt for passwords without echoing to the terminal

Data::UUID - Generate globally/universally unique identifiers (GUIDs/UUIDs)

List::Util - A selection of general-utility list subroutines

List::MoreUtils - Provides the stuff missing in List::Util

Text::Diff - Perform diffs on files and record sets

Text::Diff::HTML 0.02 - XHTML format for Text::Diff::Unified

Text::WordDiff - Track changes between documents

URI::Escape - Escape and unescape unsafe URI characters

Scalar::Util - A selection of general−utility scalar subroutines

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

The Bricolage home page, at L<http://bricolage.cc/>.

See L<Bundle::BricolagePlus|Bundle::BricolagePlus> for modules that are
optional in Bricolage.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
