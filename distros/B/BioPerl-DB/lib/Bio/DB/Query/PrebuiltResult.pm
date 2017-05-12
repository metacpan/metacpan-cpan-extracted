# $Id$
#
# BioPerl module for Bio::DB::Query::PrebuiltResult
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Query::PrebuiltResult - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

This modules provides an implementation of Bio::DB::Query::QueryResultI for
database queries through DBI.

=head1 FEEDBACK

=head2 Mailing Lists

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

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Query::PrebuiltResult;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::Query::QueryResultI;
use Bio::Root::Root;


@ISA = qw(Bio::Root::Root Bio::DB::Query::QueryResultI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::Query::PrebuiltResult->new();
 Function: Builds a new Bio::DB::Query::PrebuiltResult object 
 Returns : an instance of Bio::DB::Query::PrebuiltResult
 Args    : named parameters
              -objs  a reference to an array of objects that should be
                     returned via next_object()



=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    
    my ($objs, $adaptor, $fact, $nfks) =
	$self->_rearrange([qw(OBJS)], @args);
    
    $self->objs($objs) if $objs;

    return $self;
}


=head2 next_object

 Title   : next_object
 Usage   :
 Function: Obtain the next object from the result stream and return it.
 Example :
 Returns : A Bioperl object (implementing at least Bio::Root::RootI)
 Args    : none


=cut

sub next_object{
    my ($self) = @_;

    return shift(@{$self->objs()});
}

=head2 each_Object

 Title   : each_Object
 Usage   :
 Function: This is primarily a convenience method and in most implementations
           will just loop over next_object() and return an array of all
           objects.
 Example :
 Returns : A reference to an array of objects.
 Args    : Optionally, an anonymous function for filtering objects. If given,
           the function is passed one argument, the object to evaluate.
           The object will be included in the returned array if the function
           returns TRUE, and rejected otherwise.


=cut

sub each_Object{
    my ($self,$filter) = @_;

    my @objs = grep { $filter ? &$filter($_) : 1; } @{$self->objs()};
    $self->objs([]);

    return \@objs;
}

=head2 finish

 Title   : finish
 Usage   :
 Function: Indicate being finished with this result so that possibly used
           system resources can be released.
 Example :
 Returns : none
 Args    : none


=cut

sub finish{
    shift->objs([]);
}

=head2 objs

 Title   : objs
 Usage   : $obj->objs($newval)
 Function: Get/set the objects this result is going to return via next_object()
 Example : 
 Returns : value of objs (a reference to an array)
 Args    : new value (a reference to an array, optional)


=cut

sub objs{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'objs'} = $value;
    }
    return $self->{'objs'} || [];
}

1;
