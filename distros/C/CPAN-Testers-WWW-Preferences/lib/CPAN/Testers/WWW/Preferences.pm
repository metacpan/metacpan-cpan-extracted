package CPAN::Testers::WWW::Preferences;

use warnings;
use strict;

our $VERSION = '0.20';

1;

__END__

=head1 NAME

CPAN::Testers::WWW::Preferences - The CPAN Testers Preferences website

=head1 DESCRIPTION

This distribution contains all the code used to run The CPAN Testers 
Preferences website.

=head1 VHOST FILES

The CPAN Testers Preferences website is built on top of the Labyrinth Website
Management System. As such, the code to drive the website is contained within
the Labyrinth and associated plugin prerequisites. In order to define the 
website in terms of functionality, layout and style, the files within the 
'./vhost' directory of this distribution should be installed into your web 
server's virtual host directory.

Included in the distribution is a C<vhost.conf> file, which contains the 
virtual host settings to implement the site using the Apache Web Server.

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

F<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

F<http://iheart.cpantesters.org>

=head1 SEE ALSO

L<Labyrinth>, 

L<https://prefs.cpantesters.org>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
