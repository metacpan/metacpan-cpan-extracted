=head1 NAME

Bio::Polloc::Locus::generic - An unknown feature

=head1 DESCRIPTION

A feature loaded by some external source, but not directly created by
some L<Bio::Polloc::RuleI> object.

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::LocusI>.

=back

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::generic;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Bio::Polloc::Locus::repeat> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   # my($self,@args) = @_;
   # Do nothing ;-), just to avoid the unimplemented error.
}

1;
