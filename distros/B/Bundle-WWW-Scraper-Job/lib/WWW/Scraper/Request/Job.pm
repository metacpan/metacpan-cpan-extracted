package WWW::Scraper::Request::Job;

use strict;

use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
use WWW::Scraper::Request;
@ISA = qw(WWW::Scraper::Request);

sub new {
    shift;
    my $self = WWW::Scraper::Request::new(
                'Job',
               ,{   
                   'skills' => ''
                  ,'locations' => ''
                  ,'payrate' => ''
               }
              ,@_
               );
    return $self;

}

sub FieldTitles {
    return { 'skills'        => 'Skills'
            ,'locations'     => 'Locations'
            ,'payrate'       => 'Payrate'
           };
}

1;

__END__

=head1 NAME

WWW::Scraper::Request::Job - Canonical Request - skills, locations, payrate

=head1 SYNOPSIS

    use WWW::Scraper::Request::Job;

    $rqst = new WWW::Scraper::Request::Job;
    $rqst->skills(['Perl', '!Java']);
    $rqst->locations('CA-San Jose');
    $rqst->payrate('100000/A');

=head1 DESCRIPTION

This module provides a canonical taxonomy for specifying requests to search engines (via Scraper modules).
C<Request::Job> is targeted toward job searches.

See L<WWW::Scraper::ScraperPOD> or L<WWW::Scraper::Request> for a description of how this interfaces with Scraper modules.

=head1 FIELDS

=head2 skills

The C<skills> field should be a string, or a reference to an array of strings,
specifying the skills associated with the target job. The semantics here is that
these will be AND-ed by the search engine (i.e., the jobs found will match all the skills).

Use a '+' symbol inside the string to specify "skill A OR skill B".

Use a '!' operator at the beginning of the string to specify that that skill should NOT appear in the job title.
(This is the only place '!' is recognized in this way.)

=head2 locations

The C<locations> field should be a string, or a reference to an array of strings,
specifying the acceptable geographic locations for the job results. The string(s)
should be in the form "SS-Ccccccc", where "SS" is the two letter state name, and 
"Cccccc" is the city name (properly capitalized).

It is the responsibility of the Scraper module to translate these strings into the
appropriate location codes used by their search engines. This may mean an extremely
large lookup table, but there you are! It is also probable that the Scraper module
must postSelect based on this field, since there's seldom a one-to-one match between
our canonical location and a target search engine's location taxonomy.

We've provided an example of how this is done in Brainpower.pm.

(International locations must be handled specially, per Scraper module).

=head2 payrate

This is the desired hourly rate, in dollars (optionally append with '/H').
To specify an annual salary, append the rate with the characters '/A'.
To specify a monthly salary, append the rate with the characters '/M'.
To specify a weekly salary, append the rate with the characters '/W'.

=head1 AUTHOR

C<WWW::Scraper::Request> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



