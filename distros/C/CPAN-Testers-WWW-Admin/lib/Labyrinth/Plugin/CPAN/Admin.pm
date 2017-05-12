package Labyrinth::Plugin::CPAN::Admin;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.15';

=head1 NAME

Labyrinth::Plugin::CPAN::Admin - Content Plugin for CPAN Testers Admin website.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::DTUtils;
use Labyrinth::Variables;

#----------------------------------------------------------------------------
# Variables

#----------------------------------------------------------------------------
# Public Interface Functions

#----------------------------------------------------------
# Content Management Subroutines

=head1 CONTENT MANAGEMENT FUNCTIONS

=over 4

=item GetVersion

Store the current application version in a template variable.

=item ServerTime

Retrieve the current date and time on the server.

=back

=cut

sub GetVersion  { $tvars{'version'} = $main::VERSION; $tvars{'labversion'} = $Labyrinth::VERSION; }
sub ServerTime  { $tvars{'server'}{'date'} = formatDate(3); $tvars{'server'}{'time'} = formatDate(17); }

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
