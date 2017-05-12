#
# BioPerl module for Bio::Network::IO::psi::intact
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::IO::psi::intact - module to handle variations
in PSI MI format from the IntAct database

=head1 SYNOPSIS

Do not use this module directly, use Bio::Network::IO. For example:

  my $io = Bio::Network::IO->new(-format => 'psi',
                                 -source => 'intact',
                                 -file   => 'data.xml');

  my $network = $io->next_network;

=head1 DESCRIPTION

There are slight differences between PSI MI files offered by various public 
databases. The Bio::Network::IO::psi* modules have methods for handling
these variations. To load a module like this use the optional "-source" 
argument when creating a new Bio::Network::IO object.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists. Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHORS

Brian Osborne bosborne at alum.mit.edu

=cut

package Bio::Network::IO::psi::intact;
use strict;
use vars qw(@ISA $FAC @EXPORT);
use Bio::Network::IO;
use Bio::Annotation::DBLink;
use Bio::Annotation::Collection;

@EXPORT = qw(&);

#=head2
#
# Name      :
# Purpose   : 
# Arguments : 
# Returns   : 
# Usage     :
#
#=cut

1;

__END__
