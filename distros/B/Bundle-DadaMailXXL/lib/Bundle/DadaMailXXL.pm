package Bundle::DadaMailXXL;

$VERSION = '0.0.9';

1;

__END__

=head1 NAME 

C<Bundle::DadaMailXXL> - CPAN Bundle of ALL CPAN modules used in Dada Mail

=head1 SYNOPSIS

	perl -MCPAN -e 'install Bundle::DadaMailXXL'

or similar CPAN module installer method

=head1 Description

C<Bundle::DadaMailXXL> is a CPAN Bundle of ALL CPAN modules used by Dada Mail. 

C<Bundle::DadaMailXXL> will pull modules listed in C<Bundle::DadaMail::IncludedInDistribution> (CPAN modules usually bundled within the distro) and C<Bundle::DadaMail> (modules required, but not bundled within the distribution).

=head1 See Also

L<https://dadamailproject.com>

L<https://github.com/justingit/Bundle-DadaMailXXL>


=head1 CONTENTS

AWS::Signature4 - used for Amazon SES 

CSS::Inliner - Used in inlining CSS in HTML email messages. Important for making sure HTML messages look correctly in most all readers.

CSS::Packer - minifies CSS used in HTML email messages

DateTime::Event::Recurrence - used for scheduled mass mailings

DateTime - used for scheduled mass mailings, amazingly, not required

Digest::HMAC - 

Digest::SHA - for Amazon SES, should be in core

Digest::SHA1

Google::reCAPTCHA

Gravatar::URL

HTML::Element - used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTML::FormatText::WithLinks - Plaintext to HTML

HTML::Packer - minifies HTML used in HTML email messages

HTML::Scrubber - removes Javascript in messages - think discussion lists

HTML::Tree - used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTML::TreeBuilder -  used for Dada Mail's "Magic" templates, as well as manipulating HTML documents

HTTP::BrowserDetect - Makes reporting of user agents prettier

IO::Socket::SSL

Net::Domain

Net::DNS

Net::IMAP::Simple - use for IMAP access

Net::IP - used for anonymizing IPV6

Time::Piece - used in templates for https://dadamailproject.com/d/features-email_template_syntax.pod.html#Flexible-Date-and-Time-formats, should be in core

WWW::StopForumSpam

XML::FeedPP - for sending out RSS feeds as mass mailings

XML::LibXML - for Amazon SES

XMLRPC::Lite

YAML - is it used? 

Image::Resize - used for resizing images

Image::Scale - used for resizing images

Image::Magick - used for resizing images

LWP::Protocol::https

LWP::Protocol::Net::Curl

Bundle::DadaMail::IncludedInDistribution

Bundle::DadaMail


