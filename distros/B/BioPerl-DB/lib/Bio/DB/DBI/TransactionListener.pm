# $Id$
#
# BioPerl module for Bio::DB::DBI::TransactionListener
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
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

Bio::DB::DBI::TransactionListener - a simple transaction listener 

=head1 SYNOPSIS

    # see method section

=head1 DESCRIPTION

This object is the contract and at the same time a simple (neutral)
implementation of a transaction listener.

Transaction listeners are notified before and after commit and
rollback on transactions as represented by a
Bio::DB::DBI::Transaction objects.

Note that this is a very loose contract in the sense that it is not
enforced. Therefore it serves more as a guideline of what you *can*
do rather than what you have to do. 

You may currently choose between 3 different options on how to listen
to transactions:

    - write your own transaction listener that inherits from this
      class and overrides methods as suitable, then use your class to
      add listeners to Transactions

    - let your adaptor or persistent object module inherit from this
      class and thereby make it a listener-compliant object that you
      can then use to register with Transactions

    - register any object with Transaction that implements at least
      one of the methods defined here (if it implements none then
      what's the point?). Transaction will only call the methods
      defined here if the listener actually implements them.

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


package Bio::DB::DBI::TransactionListener;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;


@ISA = qw(Bio::Root::Root );

my $counter = 1;

=head2 new

 Title   : new
 Usage   : my $obj = Bio::DB::DBI::TransactionListener->new();
 Function: Builds a new Bio::DB::DBI::TransactionListener object 
 Returns : an instance of Bio::DB::DBI::TransactionListener
 Args    :


=cut

sub new {
    my($class,@args) = @_;
    
    my $self = $class->SUPER::new(@args);
    return $self;
}

=head2 register_sub

 Title   : register_sub
 Usage   :
 Function: Register an anonymous code block for being executed in
           one of the listener methods.

           This method is probably mostly useful for testing purposes,
           but who knows.

           You may call this as a class method or an object method.

 Example :
 Returns : an instance of this class with the supplied anonymous
           function overriding the specified listener method
 Args    : the code reference to register

           the name(s) of the interface method(s) to register it for
           (optional, if not specified the code block will be
           registered for all 4 methods)


=cut

sub register_sub{
   my ($class,$code,@meths) = @_;

   @meths = ("before_commit","after_commit",
	     "before_rollback","after_rollback") unless @meths;
   $class = ref($class) || $class;
   $class .= ++$counter;
   my $obj = bless {}, $class;
   foreach my $meth (@meths) {
       *{"$class::$meth"} = $code;
   }
   return $obj;
}

=head1 TransactionListener interface methods

The following methods define the interface for TransactionListeners.

=cut

=head2 before_commit

 Title   : before_commit
 Usage   :
 Function: Called before a commit is issued. 

           Any listener may veto a pending commit by returning
           false. The default implementation returns true.

 Example :
 Returns : TRUE if the transaction is good to be committed, and
           FALSE if it is vetoed.
 Args    : none


=cut

sub before_commit{
    return 1;
}

=head2 after_commit

 Title   : after_commit
 Usage   :
 Function: Called after a commit was issued. 

           The default implementation here does nothing.

 Example :
 Returns : ignored
 Args    : none


=cut

sub after_commit{
    return 1;
}


=head2 before_rollback

 Title   : before_rollback
 Usage   :
 Function: Called before a rollback is issued. 

           A listener cannot veto a pending rollback. The return value
           and even thrown exceptions will be ignored by Transaction.

 Example :
 Returns : ignored
 Args    : none


=cut

sub before_rollback{
    return 1;
}


=head2 after_rollback

 Title   : after_rollback
 Usage   :
 Function: Called after a rollback is issued. 

 Example :
 Returns : ignored
 Args    : none


=cut

sub after_rollback{
    return 1;
}

1;
