# $Id$
#
# BioPerl module for Bio::DB::DBI::Transaction
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

Bio::DB::DBI::Transaction - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

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


package Bio::DB::DBI::Transaction;
use vars qw(@ISA);
use strict;
use Carp qw(confess);

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;

@ISA = qw(Bio::Root::Root );

my %transactions = ();

=head2 new

 Title   : new
 Usage   : 
 Function: This method throws an exception. Use get_Transaction() 
           to get a Transaction object.
 Returns : 
 Args    :


=cut

sub new {
    my($class,@args) = @_;
    
    confess "You cannot instantiate this class from outside. ".
	"Use get_Transaction() to get an object.";
}

=head2 _new

 Title   : _new
 Usage   : my $obj = Bio::DB::DBI::Transaction->_new();
 Function: Builds a new Bio::DB::DBI::Transaction object 

           This is a private method. If you call this method from
           outside you are on your own. Call get_Transaction() to
           obtain an instance of this class.

 Returns : an instance of Bio::DB::DBI::Transaction
 Args    :


=cut

sub _new {
    my($class,@args) = @_;

    # silly trick but maybe catches some silly people who don't believe
    my $bummer = pop(@args);
    return $class->new($bummer, @args) unless $bummer && ($bummer eq "Bummer");

    my $self = $class->SUPER::new(@args);
    return $self;
}

=head2 dbh

 Title   : dbh
 Usage   :
 Function: Get/set the database connection handle for this transaction.
           Transactions are connection-specific.

           You should not need to call this method from outside. If
           you do, call yourself bold, but you're on your own ...

 Example :
 Returns : A DBI database connection handle 
 Args    : on set, the new DBI database connection handle


=cut

sub dbh{
    my $self = shift;

    return $self->{'dbh'} = shift if @_;
    return $self->{'dbh'};
}

=head2 commit

 Title   : commit
 Usage   :
 Function: Commit this transaction.

           Read the DBI perldoc for $dbh->commit about possible
           return values and behaviour.

           Committing the transaction will also notify all listeners
           before and after the actual commit. Listeners have the
           opportunity to veto a transaction commit by returning
           false from their before_commit() method.

 Example :
 Returns : The return value from $dbh->commit()
 Args    : none


=cut

sub commit{
    my $self = shift;

    foreach my $listener ($self->get_TransactionListeners()) {
	if($listener->can("before_commit")) {
	    $listener->before_commit() || return;
	}
    }
    my $rv = $self->dbh->commit();
    foreach my $listener ($self->get_TransactionListeners()) {
	$listener->after_commit() if $listener->can("after_commit");
    }
    return $rv;
}

=head2 rollback

 Title   : rollback
 Usage   :
 Function: Rollback this transaction.

           Read the DBI perldoc for $dbh->rollback about possible
           return values and behaviour.

           Rolling back the transaction will also notify all listeners
           before and after the actual rollback. Listeners cannot veto
           a transaction rollback.

 Example :
 Returns : The return value from $dbh->rollback()
 Args    : none


=cut

sub rollback{
    my $self = shift;

    foreach my $listener ($self->get_TransactionListeners()) {
	eval {
	    $listener->before_rollback() if $listener->can("before_rollback");
	};
	if($@) {
	    $self->warn(ref($listener).
			"::before_rollback threw an exception, but rollback ".
			"cannot be vetoed (message was: ".$@.")");
	}
    }
    my $rv = $self->dbh->rollback();
    foreach my $listener ($self->get_TransactionListeners()) {
	$listener->after_rollback() if $listener->can("after_rollback");
    }
    return $rv;
}

=head2 get_TransactionListeners

 Title   : get_TransactionListeners
 Usage   : @arr = get_TransactionListeners()
 Function: Get the list of TransactionListener(s) for this object.

           We currently do not enforce the listener objects to
           literally be Bio::DB::DBI::TransactionListener implementing
           objects. This object can handle this; use $obj->can() for
           every listener-specific call you invoke yourself on the
           returned objects.

 Example :
 Returns : An array of Bio::DB::DBI::TransactionListener objects
 Args    :


=cut

sub get_TransactionListeners{
    my $self = shift;

    return @{$self->{'_listeners'}} if exists($self->{'_listeners'});
    return ();
}

=head2 add_TransactionListener

 Title   : add_TransactionListener
 Usage   :
 Function: Add one or more TransactionListener(s) to this object.

           We currently do not enforce the listener objects to
           literally be Bio::DB::DBI::TransactionListener implementing
           objects.

 Example :
 Returns : 
 Args    : One or more Bio::DB::DBI::TransactionListener objects.


=cut

sub add_TransactionListener{
    my $self = shift;

    $self->{'_listeners'} = [] unless exists($self->{'_listeners'});
    push(@{$self->{'_listeners'}}, @_);
}

=head2 remove_TransactionListeners

 Title   : remove_TransactionListeners
 Usage   :
 Function: Remove all TransactionListeners for this class.

           We currently do not enforce the listener objects to
           literally be Bio::DB::DBI::TransactionListener implementing
           objects. This object can handle this; use $obj->can() for
           every listener-specific call you invoke yourself on the
           returned objects.

 Example :
 Returns : The list of previous TransactionListeners as an array of
           Bio::DB::DBI::TransactionListener objects.
 Args    :


=cut

sub remove_TransactionListeners{
    my $self = shift;

    my @arr = $self->get_TransactionListeners();
    $self->{'_listeners'} = [];
    return @arr;
}

=head2 remove_TransactionListener

 Title   : remove_TransactionListener
 Usage   :
 Function: Remove one TransactionListener for this class.

           We currently do not enforce the listener objects to
           literally be Bio::DB::DBI::TransactionListener implementing
           objects. This object can handle this; use $obj->can() for
           every listener-specific call you invoke yourself on the
           returned objects.

 Example :
 Returns : void
 Args    : A Bio::DB::DBI::TransactionListener object


=cut

sub remove_TransactionListener{
    my $self = shift;
    my $obj = shift;

    my @arr = grep { $_ != $obj } $self->remove_TransactionListeners();
    $self->{'_listeners'} = [@arr];
}

=head2 get_Transaction

 Title   : get_Transaction
 Usage   :
 Function: Get the Transaction for a particular connection.

           This is a class method. 
 Example :
 Returns : an instance of this class
 Args    : a DBI database connection handle for which to obtain
           the transaction

           All other arguments are passed on to new() if a new
           Transaction needs to be created.


=cut

sub get_Transaction{
    my $class = shift;
    my $dbh = shift;
    my $tx;

    if(exists($transactions{$dbh})) {
	$tx = $transactions{$dbh};
    } else {
	$tx = $class->_new("Bummer",@_);
	$tx->dbh($dbh);
	$transactions{$dbh} = $tx;
    }
    return $tx;
}

1;
