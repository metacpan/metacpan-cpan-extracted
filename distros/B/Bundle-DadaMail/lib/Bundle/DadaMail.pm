package Bundle::DadaMail;

$VERSION = '0.0.14';

1;

__END__

=head1 NAME 

C<Bundle::DadaMail> - CPAN Bundle for optional CPAN modules used in Dada Mail

=head1 SYNOPSIS

	perl -MCPAN -e 'install Bundle::DadaMail'

or similar CPAN module installer method

=head1 Description

C<Bundle::DadaMail> is a CPAN Bundle of I<optional> CPAN modules used by Dada Mail. 
Dada Mail is a self-hosted mailing list manager and the distribution does include the
CPAN modules that it requires.

The modules listed here are not included for a variety of reasons, 
but mostly because their own dependency chain is very long, or that they
or some dependency that they require needs compilation, or even an outside library. 

=head1 See Also

L<http://dadamailproject.com>

=head1 CONTENTS

parent

LWP - So many things. Makes the Send a Webpage work, for starters.  actually a required module, but we assume the environment Dada Mail is installed on has this already (I know, never assume!)

Authen::SASL

AWS::Signature4 - For sending via Amazon SES

Captcha::reCAPTCHA::Mailhide

CSS::Inliner - Used in inlining CSS in HTML email messages. Important for making sure HTML messages look correctly in most all readers.

CSS::Packer - minifies CSS used in HTML email messages

Cwd - for Amazon SES

Crypt::SSLeay - for Amazon SES

DateTime::Event::Recurrence - used for scheduled mass mailings

DateTime - same

DBI - actually a required module, but we assume the environment Dada Mail is installed on has this already (I know, never assume!)

Digest::HMAC

Digest::SHA - for Amazon SES

File::Copy::Recursive - used in the installer 

File::Find::Rule - used for the Perl connector in KCFInder

HTML::Element - used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTML::Packer - minifies HTML used in HTML email messages

HTML::Scrubber - removes Javascript in messages - think discussion lists

HTML::Tree - used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTML::TreeBuilder -  used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTTP::BrowserDetect - Makes reporting of user agents prettier

Google::reCAPTCHA

Google::reCAPTCHA::v3

Gravatar::URL

HTML::FormatText::WithLinks - Plaintext to HTML

IO::Socket::SSL

Image::Resize - used for resizing images

Image::Scale - used for resizing images

Image::Magick - used for resizing images

JSON - actually required for Dada Mail - Pure Perl version included, but you probably want to use a faster version

MIME::Base64 - for Amazon SES

Net::Domain

Net::DNS

Net::IMAP::Simple - use for IMAP access

Net::IP

Net::POP3 - used for POP3 access, for example: Bounce Handler and Bridge

Net::SMTP - used for sending via SMTP

Text::CSV - actually required for Dada Mail - Pure Perl version included, but you probably want to use a faster version

Time::Piece - used in templates for http://dadamailproject.com/d/features-email_template_syntax.pod.html#Flexible-Date-and-Time-formats

Time::Piece::MySQL

URI::Escape - for Amazon SES

URI::GoogleChart - used for the fancy charts Dada Mail's Tracker plugin uses. 

WWW::StopForumSpam

XML::FeedPP - for sending out RSS feeds as mass mailings

XML::LibXML - for Amazon SES

XMLRPC::Lite

YAML