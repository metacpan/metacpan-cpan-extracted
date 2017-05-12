package Data::Babel::HAH_MultiValued;
#################################################################################
#
# Author:  Nat Goodman
# Created: 12-09-21
# $Id: 
#
# Specialized Hash::AutoHash::MultiValued that allows undef values
#
#################################################################################
use strict;
use Carp;
use base qw(Hash::AutoHash::MultiValued);

our @NORMAL_EXPORT_OK=@Hash::AutoHash::MultiValued::EXPORT_OK;
my $helper_class=__PACKAGE__.'::helper';
our @EXPORT_OK=$helper_class->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=$helper_class->SUBCLASS_EXPORT_OK;

#################################################################################
# helper package exists to avoid polluting main package namespace with
#   subs that would mask accessor/mutator AUTOLOADs
# functions herein (except _new) are exportable by Hash::AutoHash::Args
#################################################################################
package Data::Babel::HAH_MultiValued::helper;
use strict;
use Carp;
BEGIN {
  our @ISA=qw(Hash::AutoHash::MultiValued::helper);
}
use Hash::AutoHash::MultiValued qw(autohash_tie);

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Data::Babel::HAH_MultiValued::tie,@args;
  bless $self,$class;
}

#################################################################################
# Tied hash which implements Data::Babel::HAH_MultiValued
#################################################################################
package Data::Babel::HAH_MultiValued::tie;
use strict;
our @ISA=qw(Hash::AutoHash::MultiValued::tie);
use constant STORAGE=>0;
use constant UNIQUE=>1;
use constant FILTER=>2;

sub FETCH {
  my($self,$key)=@_;
  my $storage=$self->[STORAGE];
  if (defined $storage->{$key}) {
    my $values=$storage->{$key};
    return wantarray? @$values: $values;
  } 
  return wantarray? (): undef;
}
sub STORE {
  my($self,$key,@new_values)=@_;
  my $storage=$self->[STORAGE];
  if (@new_values==1 && !defined $new_values[0] && !exists $storage->{$key}) { 
    # special case - store undef
    $storage->{$key}=undef;
    return wantarray? (): undef;
  }
  if (exists $storage->{$key} && !defined $storage->{$key}) {
    # special case - existing value is undef
    unshift(@new_values,undef);
  }
  # regular MultiValued STORE
  $self->SUPER::STORE($key,@new_values);
}

1;
