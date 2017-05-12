package Bundle::CertHost;

$VERSION = "0.02";

1;

__END__

=head1 NAME

Bundle::CertHost - A bundle to install PerlCertifiedHosting.com module requirements

=head1 SYNOPSIS

Linux:-
 perl -MCPAN -e 'install Bundle::CertHost'

Windows:-
 ppm install Bundle-CertHost

=head1 CONTENTS

Bundle::DBI - Start DB section

DBD::mysql

DBD::ODBC

DBD::Pg

DBD::SQLite

Bundle::LWP       

CGI - Start CGI section

CGI::Simple

FCGI

CGI::Fast

Task::CGI::Application

Task::Catalyst

Digest::MD5 - Start Digest section

Digest::SHA1

XML::Stream - Start XML section

XML::Parser

XML::Simple

MIME::Parser - Start MIME section

MIME::Base64

MIME::Lite

HTML::Parser - Start HTML section

HTML::TreeBuilder

DateTime - Start misc section

Date::Calc

GD

Image::Size

Storable

Net::DNS

=head1 DESCRIPTION

This bundle provides the CPAN module requirements for PerlCertifiedHosting.com.

=head1 AUTHOR

Lyle Hopkins E<lt>webmaster@cosmicperl.com>

=cut 
