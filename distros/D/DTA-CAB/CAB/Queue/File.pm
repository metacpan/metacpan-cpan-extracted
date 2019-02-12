## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Queue::File.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: file-based queue

package DTA::CAB::Queue::File;
use DTA::CAB::Utils ':temp';
use File::Queue;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Logger File::Queue);

##==============================================================================
## Constructors etc.
##==============================================================================

## $q = DTA::CAB::Queue::File->new(%args)
##  + %$q, %args:
##    (
##     file => $filename,   ##-- basename of queue file (will have .dat,.idx suffixes); default=tmpfsfile('qXXXXXXX')
##     mode => $mode,       ##-- creation mode (default=0660)
##     seperator => $str,   ##-- item separator string (default=$/) [typo in name is (sic): bummer]
##    )
sub new {
  my ($that,%args) = @_;
  if (exists($args{separator})) {
    ##-- annoying typo in File::Queue
    $args{seperator} = $args{separator};
    CORE::delete($args{separator});
  }
  $args{file} = tmpfsfile('qXXXXXXX') if (!defined($args{file}));
  my $q = $that->SUPER::new(seperator=>$/,mode=>0600,%args);
  @$q{keys %args} = values %args; ##-- save args
  return $q;
}

## $q = $q->reopen()
##  + re-open the queue (e.g. in a sub-process)
##  + hack just calls new()
BEGIN {
  *refresh = \&reopen;
}
sub reopen {
  my $q = shift;
  %$q = %{ref($q)->new(file=>$q->{file},mode=>$q->{mode},seperator=>$q->{seperator})};
  return $q;
}

## undef = $q->enq($item)
##  + enqueue a simple item

## $item_or_undef = $q->deq()
##  + de-queue a single item; undef means end-of-queue

## @items = $q->peek($count)
##  + peek at the top of the queue

## undef = $q->reset()
##  + clear the queue
sub clear { $_[0]->reset(); }

## undef = $q->close()
##  + close the queue filehandles

## undef = $q->delete()
##  + delete queue file(s)
sub unlink { $_[0]->delete(); }

1;

##==============================================================================
## Package DTA::CAB::Queue::File::Locked
package DTA::CAB::Queue::File::Locked;
use Fcntl qw(:flock);
our @ISA = qw(DTA::CAB::Queue::File);

sub _locked {
  my $subname = shift;
  my $supersub = DTA::CAB::Queue::File->can($subname);
  die(__PACKAGE__, "::_locked(): no superclass subroutine for '$subname'") if (!$supersub);
  return sub {
    my (@rc);
    flock($_[0]{queue},LOCK_EX) if ($_[0]{queue});
    if (wantarray) {
      @rc = $supersub->(@_);
    } else {
      $rc[0] = $supersub->(@_);
    }
    flock($_[0]{queue},LOCK_UN) if ($_[0]{queue});
    return wantarray ? @rc : $rc[0];
  };
}

*enq = _locked('enq');
*deq = _locked('deq');
*peek = _locked('peek');
*reset = _locked('reset');
#*close = _locked('close');

1; ##-- be happy

__END__
