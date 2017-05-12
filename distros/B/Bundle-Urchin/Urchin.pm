package Bundle::Urchin;

$VERSION = '0.1';

1;

__END__

=head1 NAME 

Bundle::Urchin - Urchin RSS Aggregator Perl Dependencies 

=head1 SYNOPSIS

C<cpan install Bundle::Urchin>

=head1 DESCRIPTION

These are Perl dependencies for the Urchin RSS aggregator software.
L<http://urchin.sourceforge.net/>

After installing you may get a report that there were some problems 
installing certain modules. Before reporting them make sure that they 
haven't installed by:

    perl -MHTML::LinkExtractor -e 1

This will test to make sure the HTML::LinkExtractor package is available. 
Substitute the name of any modules that were reported failed.

=head1 CONTENTS

Apache::compat

Apache::Const

Apache::Emulator

Apache2

DBI 

Encode

HTML::Entities

HTML::LinkExtractor

HTML::Sanitizer

HTML::Template

HTTP::Request

HTTP::Response

HTTP::Status

LWP::RobotUA

LWP::UserAgent

POSIX

Parse::RecDescent

RDF::Core

Set::Array

Sys::Hostname::Long

Text::CSV

Time::ParseDate

Time::Stopwatch

URI

XML::DOM

XML::RSS

XML::RSS::Tools

XML::XPath

XML::XSLT

=head1 TODO

=over 4

=item * Include version dependencies?

=back

=head1 AUTHOR

=over 4 

=item * Clay Redding e<lt>clay@monarchos.come<gt>

=item * Ed Summers e<lt>ehs@pobox.come<gt>

=back
