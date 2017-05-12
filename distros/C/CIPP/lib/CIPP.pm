# $Id: CIPP.pm,v 1.46 2006/05/29 11:25:09 joern Exp $

package CIPP;

$VERSION = "3.0.8";

__END__

=head1 NAME

CIPP - Powerful preprocessor for embedding Perl and SQL in HTML

=head1 SYNOPSIS

You never use the CIPP module directly, it works behind the scenes of several possible execution environments, which are described in the next chapter.

=head1 DESCRIPTION

B<CIPP = CgI Perl Preprocessor>

CIPP is a perl module for translating CIPP sources to pure perl programs. CIPP defines a HTML embedding language called CIPP which has powerful features for CGI and database developers. Many standard CGI- and database operations (and much more) are covered by CIPP, so the developer has no need to code them again and again.

CIPP is useful in two ways. One aproach is to let CIPP generate standalone CGI scripts, which only need a little environment to run (some configuration files). If you want to use CIPP in this way: there is a complete development environment called new.spirit which supports you in many ways, to develop such CGI programms with CIPP. new.spirit can be downloaded from CPAN.

(The next chapter is a typical case of "already documented, but not implemented yet" - if you need Apache::CIPP or CGI::CIPP, use the previous generation of CIPP, version 2.xx.)

The second approach is to use the Apache::CIPP or CGI::CIPP modules. Apache::CIPP defines an Apache request handler for CIPP sources, so they will be executed in an Apache environment on the fly, with a two-level cache and great performance. CGI::CIPP doesn't depend on Apache and executes CIPP code using a small CGI wrapper programm. Combining this with CGI::SpeedyCGI to increase performance is possible and suggested.

=head1 DOCUMENTATION

Several manpages cover the configuration and usage of CIPP:

=over 4

=item B<CIPP language reference>

The Perl module CIPP::Manual contains a complete reference of the CIPP language. You can view it using perldoc:

  perldoc CIPP::Manual

or by creating a PDF document from it. Simply execute

  doc/create_pdf.sh

in the CIPP installation directory. You need pod2html and ps2pdf for this to work.

=item B<CIPP::Request>

This is the description of the CIPP runtime API, which is accessable through the class CIPP::request.

  perldoc CIPP::Request

=item B<Apache::CIPP>

(currently not available for CIPP versions 2.99 or above)

The manpage of Apache::CIPP describes the configuration and usage of CIPP using Apache and mod_perl.

  perldoc Apache::CIPP

=item B<CGI::CIPP>

(currently not available for CIPP versions 2.99 or above)

The manpage of CGI::CIPP describes the configuration and usage of CIPP using a CGI wrapper, which can be used in conjuction with many webservers.

  perldoc CGI::CIPP

=back 

=head1 AUTHOR

Jörn Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright 1997-2002 Jörn Reder, All Rights Reserved
Copyright 1997-2002 dimedis GmbH, All Rights Reserved

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), CIPP::Manual (3pm), CIPP::Request (3pm) Apache::CIPP (3pm), CGI::CIPP (3pm)

