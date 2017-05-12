package Astro::ADS;

=head1 NAME

Astro::ADS - An object orientated interface to NASA's ADS database

=head1 DESCRIPTION

This module does nothing, and is here as a placeholder in case of need. The
user interface to the goodness wrapped in the ADS package can be found in
the L<Astro::ADS::Query> module.

=head1 REVISION

B<NOTE:> The API for the ADS is changing and the current interface will disappear.
This will be the final revision of this version of Astro::ADS.  The new API
(described at L<https://github.com/adsabs/adsabs-dev-api> ) will be implemented
as version 2.0 sometime in 2015.

$Id: ADS.pm,v 1.26 2014/06/15 bjd Exp $
$Id: ADS.pm,v 1.25 2013/08/06 bjd Exp $
$Id: ADS.pm,v 1.3 2004/01/28 09:04:42 aa Exp $

=head1 METHODS

The Astro::ADS module itself has no methods, and is just a placeholder
module, see L<Astro::ADS::Query> for the actual interface.

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=head1 BUGS

=over

=item Followup queries using default URL

When an B<Astro::ADS::Query> object has set the url to a non-default server, 
the B<Astro::ADS::Result::Paper> objects it returns use the default URL in the
B<references>, B<citations>, B<alsoread> and B<tableofcontents> methods.  This
is likely not what you want if you are doing a lot of followup queries.

You can re-use the original query with the followup method or use v1.21.0 or
above which turns the URL from an object variable to a class variable.

=back

=head1 TODO

=over

=item Document issues with ADS mirrors, proxy() and $ENV{HTTP_PROXY}

Explain the preference to set the class variable using the ads_mirror() method
in Astro::ADS::Query at the top of the script so that followup queries go to
the expected place.
*NB*
Also note that the proxy() method is only affects one query object and 
the user agent looks at the environment variables HTTP_PROXY and NO_PROXY to
the exclusion of almost all else.  Once again, set $ENV{HTTP_PROXY} at the
top of your script for least confusion.

=item Fix followup queries on B<alsoread> and B<tableofcontents>

Followups are new query objects, so there are issues with alsoread and tableofcontents.
No one has noticed yet and I don't have time to fix it.

=item Tweak make to prompt for default ADS mirror

This is a "good" idea, but fiddly to implement.  Prompt the user for one of the
ADS mirrors during the installation and write it into Astro::ADS::Query to save
setting it at the beginning of each script

=item Error 500: handle network failures gracefully.  

Return undef instead of die()ing.

=back

=cut

use strict;
use warnings;
use vars qw/ $VERSION /;
$VERSION = '1.26';

1;                                                                  
