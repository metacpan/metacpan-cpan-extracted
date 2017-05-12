# --*-Perl-*--
# $Id: ACM.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::BibItemStyle::ACM;
use strict;
#use English;

=head1 package PBib::BibItemStyle::ACM;

% Base for all ACM bibliography styles (CHI, UIST, CSCW, ...)

=cut

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::BibItemStyle::ACM;
our @ISA = qw(PBib::BibItemStyle);

# used modules
#use ZZZZ;

# module variables
#use vars qw(mmmm);

#
#
# format methods for entries
#
#

sub format_names { my ($self, $names) = @_;
  return () unless( defined($names) );
  return $self->format_names_last_initials($names);
}

1;

=head1 HISTORY

$Log: ACM.pm,v $
Revision 1.2  2004/03/29 13:11:14  tandler
names are formatted as Last, First, Initials

Revision 1.1  2003/04/14 09:48:10  ptandler
new style: ACM


=cut
