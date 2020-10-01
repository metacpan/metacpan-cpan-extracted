package Bundle::DadaMailXXL;

$VERSION = '0.0.7';

1;

__END__

=head1 NAME 

C<Bundle::DadaMailXXL> - CPAN Bundle for required CPAN modules used in Dada Mail

=head1 SYNOPSIS

	perl -MCPAN -e 'install Bundle::DadaMailXXL'

or similar CPAN module installer method

=head1 Description

C<Bundle::DadaMailXXL> is a CPAN Bundle of I<required> CPAN modules used by Dada Mail. It also lists C<Bundle::DadaMail> which is the Bundle that holds optional CPAN modules used by Dada Mail. 

Dada Mail is a self-hosted mailing list manager and the distribution does include the CPAN modules that it requires. This bundle keeps track of those modules, as well as gives you an easy way to install them via CPAN into your Perl environment. 

The copies of the CPAN module that Dada Mail provides may very well be out of date, or contain bugs, so having versions that are up to date is generally a good idea. We treat bugs/problems introduced from using the most up-to-date Perl modules in Dada Mail (rather than something we ship with the app's distro) a bug those should be reported: 

L<https://github.com/justingit/dada-mail/issues>

=head1 See Also

L<http://dadamailproject.com>

L<https://github.com/justingit/Bundle-DadaMailXXL>

=head1 CONTENTS

Bundle::DadaMail

Try::Tiny

CGI

CGI::Application

CGI::Session

CGI::Session::ExpireSessions

Class::Accessor

Class::Accessor::Chained::Fast

Data::Page

Date::Format

Digest 

Digest::MD5

Digest::Perl::MD5

Email::Address

Email::Address::XS

Email::Find

Email::Valid

Exporter::Lite

File::Spec

File::Slurper

Data::Google::Visualization::DataTable

HTML::Entities::Numbered

HTML::Tagset

HTML::Template

HTML::Tiny

HTML::Tree

Data::Pageset

HTML::Template::Expr

HTTP::Date

HTML::TextToHTML

IO::Stringy

Bundle::libnet

Mail::DeliveryStatus::BounceParser 

Mail::Address

Mail::Cap

Mail::Field

Mail::Field::AddrList

Mail::Field::Date

Mail::Filter

Mail::Header

Mail::Internet 

Mail::Mailer

Mail::Mailer::qmail 	  	 

Mail::Mailer::rfc822 	  	 

Mail::Mailer::sendmail 	  	 

Mail::Mailer::smtp 	  	 

Mail::Mailer::testfile 	 

Mail::POP3Client 

Mail::Send

Mail::Util

Mail::Verp

MD5

MIME::EncWords

MIME::Type

MIME::Types

MIME::Tools

Net::SMTP

Net::SMTP_auth

Number::Bytes::Human

Parse::RecDescent

Text::Balanced

PHP::Session

Scalar::Util

List::Util 

Text::CSV

Text::Markdown

Text::Tabs

Text::Wrap

Time::Local

Time::Piece

Try::Tiny

URI

URI::Escape

Crypt::CipherSaber

Net::Domain

DBI

MIME::Base64

Net::DNS

Net::SMTP::SSL

IO::Socket::SSL

Crypt::Rijndael

HTML::Tiny

Authen::SASL

YAML::Tiny

Text::FrontMatter::YAML

HTML::Menu::Select