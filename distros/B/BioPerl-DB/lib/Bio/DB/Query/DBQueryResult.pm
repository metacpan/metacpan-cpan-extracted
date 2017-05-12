# $Id$
#
# BioPerl module for Bio::DB::Query::DBQueryResult
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

Bio::DB::Query::DBQueryResult - DESCRIPTION of Object

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


package Bio::DB::Query::DBQueryResult;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::Query::QueryResultI;
use Bio::Root::Root;


@ISA = qw(Bio::Root::Root Bio::DB::Query::QueryResultI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::Query::DBQueryResult->new();
 Function: Builds a new Bio::DB::Query::DBQueryResult object 
 Returns : an instance of Bio::DB::Query::DBQueryResult
 Args    : named parameters

           -sth        the statement handle (this object will not
                       execute it)

           -adaptor    the persistence adaptor (basically needs to 
                       implement instantiate_from_row($row, $factory)

           -factory    optionally, the object factory to pass to the
                       adaptor

	   -num_fks    the number of foreign key object columns in
                       the rows

           -flat_only  whether to retrieve and attach children when
                       building objects (default: false)

           If none of these are given at instantiation, at least sth() and
           persistence_adaptor() must be set prior to calling next_object().


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    
    my ($sth, $adaptor, $fact, $nfks, $flatonly) =
	$self->_rearrange([qw(STH ADAPTOR FACTORY NUM_FKS FLAT_ONLY)], @args);
    
    $self->sth($sth) if $sth;
    $self->persistence_adaptor($adaptor) if $adaptor;
    $self->object_factory($fact) if $fact;
    $self->num_fks($nfks) if defined($nfks);
    $self->flat_retrieval($flatonly);

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
    my $obj;

    my $row = $self->sth()->fetchrow_arrayref();
    if($row) {
	my $adp = $self->persistence_adaptor();
	# build the object
	$obj = $adp->_build_object(-row => $row,
				   -obj_factory => $self->object_factory(),
				   -num_fks => $self->num_fks(),
                                   -flat_only => $self->flat_retrieval());
    }
    return $obj;
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
    my @objs = ();

    while(my $obj = $self->next_object()) {
	if((! $filter) || &$filter($obj)) {
	    push(@objs, $obj);
	}
    }
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
    my $self = shift;
    $self->sth()->finish() if $self->sth();
}

=head2 sth

 Title   : sth
 Usage   : $obj->sth($newval)
 Function: Get/set statement handle from which to fetch the next row.

           This can be changed at any time. If changed, it means the next
           call to next_object() will fetch from the new handle. Also, the
           caller needs to finish() the previous handle if necessary (i.e.,
           if not exhausted).

           Note that this object will not execute the statement handle. The
           caller needs to ensure that has been happened until next_object()
           is called.
 Example : 
 Returns : value of sth (a DBI statement handle)
 Args    : new value (a DBI statement handle, optional)


=cut

sub sth{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'sth'} = $value;
    }
    return $self->{'sth'};
}

=head2 persistence_adaptor

 Title   : persistence_adaptor
 Usage   : $obj->persistence_adaptor($newval)
 Function: Get/set the instantiation adaptor to which to delegate object
           instantiation from an array of row values.

           The adaptor can be any object that implements instantiate_from_row()
           with two arguments, a reference to an array of column values, and
           optionally an object factory.

           This can be changed at any time with no adverse side effect other
           than the kind of object built possibly changing.
 Example : 
 Returns : value of persistence_adaptor (an object)
 Args    : new value (an object, optional)


=cut

sub persistence_adaptor{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'adp'} = $value;
    }
    return $self->{'adp'};
}

=head2 object_factory

 Title   : object_factory
 Usage   : $obj->object_factory($newval)
 Function: Get/set the object factory to pass to the instantiation adaptor.

           Setting this is optional because providing it to the instantiation
           adaptor is optional.
 Example : 
 Returns : value of object_factory (a Bio::Factory::ObjectFactoryI compliant
           instance)
 Args    : new value (a Bio::Factory::ObjectFactoryI compliant
           instance, optional)


=cut

sub object_factory{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'object_factory'} = $value;
    }
    return $self->{'object_factory'};
}

=head2 num_fks

 Title   : num_fks
 Usage   : $obj->num_fks($newval)
 Function: Get/set the number of foreign key columns in a given result row.

           Setting this correctly is only important for query results for which
           the resulting objects must have the foreign key objects attached.
 Example : 
 Returns : value of num_fks (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub num_fks{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'num_fks'} = $value;
    }
    return $self->{'num_fks'};
}

=head2 flat_retrieval

 Title   : flat_retrieval
 Usage   : $obj->flat_retrieval($newval)
 Function: Get/set whether objects should be retrieved and built flat
           or with all their dependent objects fetched and attached.

           The default is to build full objects with all children
           attached which provides for no bad surprises when
           inspecting the results. However, building flat objects by
           disregarding children is potentially a lot faster, so this
           option is useful if, for instance, for a sequence you don't
           need any annotation or features.

 Example : 
 Returns : value of flat_retrieval (a scalar evaluating to true or false)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub flat_retrieval{
    my $self = shift;

    return $self->{'flat_retrieval'} = shift if @_;
    return $self->{'flat_retrieval'};
}

1;
