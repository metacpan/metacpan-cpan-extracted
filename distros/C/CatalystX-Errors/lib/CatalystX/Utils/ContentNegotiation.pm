package CatalystX::Utils::ContentNegotiation;

use HTTP::Headers::ActionPack;

sub content_negotiator { our $cn ||= HTTP::Headers::ActionPack->new->get_content_negotiator }

1;

=head1 NAME

CatalystX::Utils::ContentNegotiation - Global Content Negotiation object

=head1 SYNOPSIS

  use CatalystX::Utils::ContentNegotiation;

=head1 DESCRIPTION

Not really intended for end user use at this point so see source if you want more
info (its a handful lines of code).

I wrote this to avoid creating the content negotiation object over and over.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
