package Bundle::BricolagePlus;

our $VERSION = '1.11.0';

1;
__END__

=head1 NAME

Bundle::BricolagePlus - Optional and Required modules for the Bricolage content management system.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::BricolagePlus'>

=head1 DESCRIPTION

The bundle provides an easy way to install all of the required and optional
modules used by Bricolage. Bricolage is a 100% pure Perl content-management
and publishing system which features intuitive and highly-configurable
administration, workflow, permissions, templating, server-neutral output,
distribution, and document management.

=head1 CONTENTS

Bundle::Bricolage 1.11.0 - Modules required to run Bricolage content management system.

DBD::mysql - MySQL driver for the Perl5 Database Interface

mod_perl2 2.000004 - Embed a Perl interpreter in the Apache/2.x HTTP server

Apache2::Request 2.08 - Methods for dealing with client request data

HTML::Template - Perl module to use HTML Templates from CGI scripts

HTML::Template::Expr - HTML::Template extension adding expression support

Template 2.14 - Front-end module to the Template Toolkit

PHP::Interpreter - An embedded PHP5 interpreter

Encode - Character encodings

Pod::Simple - Framework for parsing Pod

Test::Pod 0.95 - Check for POD Errors in Files

Apache::SizeLimit - Because size does matter

Apache2::SizeLimit - Because size does matter

Net::FTPServer - A secure, extensible and configurable Perl FTP server

Net::SSH2 0.18 - Support for the SSH 2 protocol via libssh2

HTTP::DAV - Perl WebDAV Client Library

Crypt::SSLeay - OpenSSL glue that provides LWP https support

Imager - Perl extension for Generating 24 bit Images

Text::Aspell - Perl interface to the GNU Aspell library

XML::DOM - Module for building DOM Level 1 compliant document structures

CGI - Simple Common Gateway Interface Class

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

The Bricolage home page, at L<http://bricolage.cc/>.

See L<Bundle::Bricolage|Bundle::Bricolage> for just the required modules for
Bricolage.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
