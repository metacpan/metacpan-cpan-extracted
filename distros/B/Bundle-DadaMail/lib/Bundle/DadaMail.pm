package Bundle::DadaMail;

$VERSION = '0.0.6';

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

IO::Socket::SSL

JSON

YAML

CSS::Inliner - Used in inlining CSS in HTML email messages. Important for making sure HTML messages look correctly in most all readers.

HTML::Packer - minifies HTML used in HTML email messages

CSS::Packer - minifies CSS used in HTML email messages

HTML::Scrubber - removes Javascript in messages - think discussion lists

DateTime::Event::Recurrence - used for scheduled mass mailings

DateTime - same

File::Find::Rule - used for the Perl connector in KCFInder

HTML::Tree - used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTML::Element - same

HTML::TreeBuilder - same

Google::reCAPTCHA

Gravatar::URL

Net::Domain

JSON - actually required for Dada Mail - Pure Perl version included, but you probably want to use a faster version

MIME::Base64

Text::CSV - actually required for Dada Mail - Pure Perl version included, but you probably want to use a faster version

URI::GoogleChart - used for the fancy charts Dada Mail's Tracker plugin uses. 

HTML::FormatText::WithLinks - Plaintext to HTML

Captcha::reCAPTCHA::Mailhide

DBI - actually a required module, but we assume the environment Dada Mail is installed on has this already (I know, never assume!)

XML::FeedPP - for sending out RSS feeds as mass mailings

Time::Piece - used in templates for http://dadamailproject.com/d/features-email_template_syntax.pod.html#Flexible-Date-and-Time-formats

XMLRPC::Lite

Cwd - for Amazon SES

Digest::SHA - for Amazon SES

URI::Escape - for Amazon SES

MIME::Base64 - for Amazon SES

Crypt::SSLeay - for Amazon SES

XML::LibXML - for Amazon SES

Net::DNS

Image::Resize - used for resizing images when using Drag and Drop in CKEditor



