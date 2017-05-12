package Bio::Coordinate::MapperI;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Coordinate::MapperI::VERSION = '1.007001';
use utf8;
use strict;
use warnings;
use parent qw(Bio::Root::RootI);

# ABSTRACT: Interface describing coordinate mappers.
# AUTHOR:   Heikki Lehvaslaiho <heikki@bioperl.org>
# OWNER:    Heikki Lehvaslaiho
# LICENSE:  Perl_5



sub in {
   my ($self,$value) = @_;

   $self->throw_not_implemented();

}


sub out {
   my ($self,$value) = @_;

   $self->throw_not_implemented();
}


sub swap {
   my ($self) = @_;

   $self->throw_not_implemented();

}


sub test {
   my ($self) = @_;

   $self->throw_not_implemented();
}


sub map {
   my ($self,$value) = @_;

   $self->throw_not_implemented();

}


sub return_match {
   my ($self,$value) = @_;
   if( defined $value) {
       $value ? ( $self->{'_return_match'} = 1 ) :
                ( $self->{'_return_match'} = 0 );
   }
   return $self->{'_return_match'} || 0 ;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Coordinate::MapperI - Interface describing coordinate mappers.

=head1 VERSION

version 1.007001

=head1 SYNOPSIS

  # not to be used directly

=head1 DESCRIPTION

MapperI defines methods for classes capable for mapping locations
between coordinate systems.

=head1 METHODS

=head2 in

 Title   : in
 Usage   : $obj->in('peptide');
 Function: Set and read the input coordinate system.
 Example :
 Returns : value of input system
 Args    : new value (optional), Bio::LocationI

=head2 out

 Title   : out
 Usage   : $obj->out('peptide');
 Function: Set and read the output coordinate system.
 Example :
 Returns : value of output system
 Args    : new value (optional), Bio::LocationI

=head2 swap

 Title   : swap
 Usage   : $obj->swap;
 Function: Swap the direction of mapping: input <-> output)
 Example :
 Returns : 1
 Args    :

=head2 test

 Title   : test
 Usage   : $obj->test;
 Function: test that both components are of same length
 Example :
 Returns : ( 1 | undef )
 Args    :

=head2 map

 Title   : map
 Usage   : $newpos = $obj->map($loc);
 Function: Map the location from the input coordinate system
           to a new value in the output coordinate system.
 Example :
 Returns : new value in the output coordiante system
 Args    : Bio::LocationI

=head2 return_match

 Title   : return_match
 Usage   : $obj->return_match(1);
 Function: A flag to turn on the simplified mode of
           returning only one joined Match object or undef
 Example :
 Returns : boolean
 Args    : boolean (optional)

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/%%7Bdist%7D

=head1 AUTHOR

Heikki Lehvaslaiho <heikki@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) by Heikki Lehvaslaiho.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
