package Business::TPGPost;

use strict;
use Business::TNTPost::NL;

our $VERSION     = '0.05';
our $ERROR       = $Business::TNTPost::NL::ERROR;

sub new {
  shift; unshift @_, 'Business::TNTPost::NL';
  goto &Business::TNTPost::NL::new;
}
#################### main pod documentation begin ###################

=head1 NAME

Business::TPGPost - [OBSOLETE] See Business::TNTPost::NL

=head1 SYNOPSIS

  use Business::TPGPost;

  my $tpg = Business::TPGPost->new();
  my $costs = $tpg->calculate(
                  country    =>'DE', 
                  weight     => 534, 
                  large      => 1, 
                  tracktrace => 1,
                  register   => 1,
                  receipt    => 1
              ) or die $Business::TPGPost::ERROR;

=head1 DESCRIPTION

On 14 september 2005, TPG Post announced their new name TNT Post. Unfortunately
the author of this module missed this name change and went for 
Business::TPGPost. On 16 october 2006, it was official, the name TPG Post
was not used anymore and thus this module was doomed.

This module now is a very simple wrapper around the new 
L<Business::TNTPost::NL>. Please don't accept this to work very well. 
Please update your scripts to use the new L<Business::TNTPost::NL>. 
This module will C<not> get updated anymore. All updates will be 
in L<Business::TNTPost::NL>.

=head1 AUTHOR

M. Blom, 
E<lt>blom@cpan.orgE<gt>, 
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Business::TNTPost::NL>, 
L<http://www.tntpost.nl/overtntpost/nieuwspers/persberichten/2006/10/naamswijziging.aspx>

=cut

#################### main pod documentation end ###################

1;
