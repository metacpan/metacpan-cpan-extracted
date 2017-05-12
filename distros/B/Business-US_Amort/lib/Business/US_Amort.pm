
# Time-stamp: "2004-12-29 19:56:54 AST"  -*-perl-*-

require 5;
package Business::US_Amort; # This is a class
use strict;
use vars qw($VERSION $Debug %Proto);
use Carp;

$Debug = 0 unless defined $Debug;
$VERSION = "0.09";

###########################################################################

=head1 NAME

Business::US_Amort - class encapsulating US-style amortization

=head1 SYNOPSIS

  use Business::US_Amort;
  my $loan = Business::US_Amort->new;
  $loan->principal(123654);
  $loan->interest_rate(9.25);
  $loan->term(20);
  
  my $add_before_50_amt = 700;
  sub add_before_50 {
    my $this = $_[0];
    if($this->{'_month_count'} == 50) {
      $this->{'_monthly_payment'} += $add_before_50_amt;
    }
  }
  $loan->callback_before_monthly_calc(\&add_before_50);
  $loan->start_date_be_now;
  
  $loan->run;
  $loan->dump_table;
  
  print "Total paid toward interest: ", $loan->total_paid_interest, "\n";

=head1 DESCRIPTION

This class encapsulates amortization calculations figured according to
what I've been led to believe is the usual algorithm for loans in the USA.

I used to think amortization was simple, just the output of an algorithm
that'd take just principle, term, and interest rate, and return the
monthly payment and maybe something like total paid toward interest.
However, I discovered that there's a need for loan calculations where,
say, between the 49th and 50th month, your interest rate drops, or where
you decide to add $100 to your monthly payment in the 32nd month.

So I wrote this class, so that I could amortize simply in simple cases
while still allowing any kind of strangeness in complex cases.

=cut

#===========================================================================

=head1 FUNCTIONS

This module provides one function, which is a simple amortizer.
This is just to save you the bother of method calls when you
really don't need any frills.

=over

=item Business::US_Amort::simple $principal, $interest_rate, $term

Amortizes based on these parameters.  In a scalar context,
returns the initial monthly payment.

In an array context, returns a three-item list consisting of:
the initial monthly payment, the total paid toward interest,
and the loan object, in case you want to do things with it.

=back

Example usages:

  $monthly_payment = Business::US_Amort::simple(123654, 9.25, 20);
  
  ($monthly_payment, $total_toward_interest, $o)
    = Business::US_Amort::simple(123654, 9.25, 20);

Of course, if you find yourself doing much of anything with the
loan object, you probably should be using the OOP interface instead
of the functional one.

=cut

sub simple ($$$) {
  my($p, $i, $t) = @_[0,1,2];
  my $o = Business::US_Amort->new;
  $o->principal($p);
  $o->interest_rate($i);
  $o->term($t);

  $o->run || croak("Error while amortizing: " . $o->error . "\n");
  
  return
    wantarray ?
      ($o->initial_monthly_payment, $o->total_paid_interest, $o)
    : $o->initial_monthly_payment
  ;
}

#===========================================================================

=head1 OBJECT ATTRIBUTES

All attributes for this class are scalar attributes.  They can be read via:

  $thing = $loan->principal     OR    $thing = $loan->{'principal'}

or set via:

  $loan->principal(VALUE)       OR    $loan->{'principal'} = VALUE


=head2 MAIN ATTRIBUTES

These attributes are used as parameters to the C<run> method.

=over

=item principal

The principal amount of the loan.

=item interest_rate

The annual rate, expressed like 8.3, not like .083.

Note that if you're defining callbacks, you can change this attribute
at any time in your callbacks, to change the rate of interest from
then on.

=item term

The term of the loan, in years, not months.

=item callback_before_monthly_calc

If set, this should be a coderef to a routine to call at the B<beginning>
of each month, B<before any> calculations are done.
The one parameter passed to this routine, in $_[0], is the object.
See the SYNOPSIS, above, for an example.

=item callback_after_monthly_calc

If set, this should be a coderef to a routine to call at the B<end>
of each month, B<after all> monthly calculations are done.
The one parameter passed to this routine, in $_[0], is the object.

=item block_table

If set to true, this inhibits C<run> from adding to C<table>.  (This
is false by default.) If you're not going to access C<table>, set this
to true before calling C<run> -- it'll speed things up and use less
memory.

=item start_date

If set to a date in the format "YYYY-MM", C<_date> will be defined
appropriately for each month.  You can set C<start_date> to the current
month by just saying $loan->start_date_be_now.

=item cent_rounding

If set to true, figures are rounded to the nearest cent at appropriate
moments, so as to avoid having to suppose that the debtor is to make a
monthly payment of $1025.229348723948 on a remaining principal of
$196239.12082309123408, or the like.

=back

These attributes are set by the C<run> method:

=over

=item initial_monthly_payment

The monthly payment that follows from the basic amortization parameters
given.  Compare with C<_monthly_payment>.

=item total_paid_interest

The total amount paid toward interest during the term of this loan.

=item total_month_count

The total number of months the loan took to pay off.
E.g., "12" for a loan that took 12 months to pay off.

=item table

This will be a reference to a list of copies made of the object
("snapshots") each month.  You can then use this if you want to
generate a dump of particular values of the object's state in
each month.

Note that snapshots have their C<am_snapshot> attribute set to true,
and have their C<table> attribute set to undef.  (Otherwise this'd be
a circular data structure, which would be a hassle for you and me.)

=item error

A string explaining any error that might have occurred, which would/should
accompany C<run> returning 0.  Use like:

  $loan->run or die("Run failed: " . $loan->error);

=back

Other attributes:

=over

=item am_snapshot

This attribute is set to true in snapshots, as stored in C<table>.

=item _month_count_limit

This is a variable such that if the month count ever exceeds this
amount, the main loop will abort.  This is intended to keep the
iterator from entering any infinite loops, even in pathological cases.
Currently the C<run> method sets this to twelve plus twice the number
of months that it's expected this loan will take.
Increase as necessary.

=back

=head2 ITERATION ATTRIBUTES

These are attributes of little or no interest once C<run> is done, but
may be of interest to callbacks while C<run> is running, or may
be of interest in examining snapshots in C<table>.

=over

=item _month_count

This is how many months we are into the loan.  The first month is 1.

=item _abort

If you want callbacks to be able to halt the iteration for some
reason, you can have them set C<_abort> to true.  You may also choose
to set C<error> to something helpful.

=item _monthly_payment

The amount to be paid to toward the principal each month. At the start
of the loan, this is set to whatever C<initial_monthly_payment> is
figured to be, but you can manipulate C<_monthly_payment> with
callbacks to change how much actually gets paid when.

=item _remainder

The balance on the loan.

=item _date

The given month's date, if known, in the format "YYYY-MM".  Unless you'd
set the C<start_date> to something, this will be undef.

=item _h

The interest to be paid this month.

=item _old_amount

What the remainder was before we made this month's payment.

=item _c

The current monthly payment, minus the monthly interest, possibly
tweaked in the last month to avoid paying off more than is actually left
on the loan.

=back

=cut

###########################################################################

%Proto =  # public attributes and their values
(
  principal => 0,
  interest_rate => 8, # annual, percent
  term => 30, # years (target term)
  error => '',
  cent_rounding => 1,
  start_date => undef,

  initial_monthly_payment => undef,
  total_paid_interest => undef,
  total_month_count => undef,

  am_snapshot => 0, # flag for objects that are snapshots
  block_table => 0, # set to 1 to block table generation

  table => undef,
  callback_before_monthly_calc => undef,
  callback_after_monthly_calc => undef,

  _month_count_limit => undef,
  _abort => undef,
  _remainder => undef,
  _date => undef,
  _h => undef,
  _old_amount => undef,
  _monthly_payment => undef,
);

#===========================================================================
 # make accessors -- just simple scalar accessors
foreach my $k (keys %Proto) { # attribute method maker
   no strict 'refs';
   *{$k} = sub {
     my $it = shift @_;
     return ($it->{$k} = $_[0]) if @_;
     return $it->{$k};
   }
   unless defined &{$k}
}

#--------------------------------------------------------------------------
# the usual doofy service methods

=head1 METHODS

=over

=item $loan = Business::US_Amort->new

Creates a new loan object.

=cut

sub new { # constructor
  my $class = shift @_;
  $class = ref($class) || $class;
  return bless { %Proto, @_ }, $class;
}

=item $loan->copy

Copies a loan object or snapshot object.  Also performs a somewhat
deep copy of its table, if applicable.

=cut

sub copy { # duplicator
  my $this = shift @_;
  return $this->new unless ref($this);

  my $new = bless { %$this }, ref($this);
  
  if(ref($new->{'table'})) {
    $new->{'table'} =
      [ # copy listref
        map( bless({ %$_ }, ref($_)), # copy hashref
             @{ $new->{'table'} }
           )
      ]
    ;
  } # copy the list of hashrefs
  
  return $new;
}

=item $loan->destroy

Destroys a loan object.  Probably never necessary, given Perl's garbage
collection techniques.

=cut

sub destroy { # destructor
  my $this = @_;
  return unless ref($this);
  %$this = ();
  bless $this, 'DEAD';
  return;
}
sub DEAD::destroy { return }


#===========================================================================

=item $loan->start_date_be_now

This sets C<start_date> to the current date, based on C<$^T>.

=cut

sub start_date_be_now {
  my $this = $_[0];
  $this->{'start_date'} = &__date_now;
}

#===========================================================================

sub maybe_round {
  my $this = $_[0];
  return $this->{'cent_rounding'} ? (0 + sprintf("%.02f", $_[1])) : $_[1];
}

#===========================================================================

=item $loan->run

This performs the actual amortization calculations.
Returns 1 on success; otherwise returns 0, in which case you should
check the C<error> attribute.

=cut

sub run {
  my $this = $_[0];
  croak "Can't call loan->run() on a snapshot" if $this->{'am_snapshot'};
  $this->{'error'} = '';
  
  # not a whole lot of sanity checking here

  unless($this->{'principal'} > 0) {
    $this->{'error'} = 'principal must be positive and nonzero';
    return 0;
  }

  $this->{'_remainder'} = $this->maybe_round( $this->{'principal'} ); # AKA "p"

  unless($this->{'interest_rate'} >= 0) {
    $this->{'error'} = 'interest rate must be nonnegative';
    return 0;
  }

  $this->{'term'} = abs($this->{'term'} + 0);
  unless($this->{'term'}) {
    $this->{'error'} = 'term must be positive and nonzero';
    return 0;
  }

  # The only real voodoo is here:
  my $j = # monthly interest rate in decimal -- in percent, not like .0875
    $this->{'interest_rate'} / 1200;
  my $n = # number of months the loan is amortized over
    int($this->{'term'} * 12);

  #print "j: $j\n";
  if($j) {
    #print "Nonzero interest\n";
    $this->{'initial_monthly_payment'} =
      $this->maybe_round(
        $this->{'_remainder'} * $j / ( 1 - (1 + $j) ** (-$n) )
      );
  } else {
    # interest-free loan -- much simpler calculation
    $this->{'initial_monthly_payment'} =
      $this->maybe_round(
        $this->{'_remainder'} / $n
      );
  }
  # ...the rest is just iteration

  # init...
  $this->{'table'} = []; # clear
  $this->{'total_paid_interest'} = 0;
  $this->{'_monthly_payment'} = $this->{'initial_monthly_payment'};
    # this can vary if the user starts tweaking it
  $this->{'_month_count'} = 0;
  $this->{'_date'} = $this->{'start_date'} || undef;
  $this->{'_month_count_limit'} = $n * 2 + 12
    unless defined $this->{'_month_count_limit'};
   # throw an error if our _month_count ever hits this

  my $last_month_date;
  while($this->{'_remainder'} >= 0.01) { # while there's more than a cent left
    ++$this->{'_month_count'};
    $this->{'_old_amount'} = $this->{'_remainder'};

    # maybe call the 'before' callback
    if($this->{'callback_before_monthly_calc'}) {
       my @list = ($this);
       &{$this->{'callback_before_monthly_calc'}}(@list);
    }
    if($this->{'_abort'}) { $this->{'error'} ||= "Abort flag set."; return 0 }

    # and now all the calcs for this month
    $this->{'_h'} = $this->maybe_round( $this->{'_remainder'}
                                        * $this->{'interest_rate'} / 1200
                                      );
    $this->{'total_paid_interest'} += $this->{'_h'};

    $this->{'_c'} = $this->{'_monthly_payment'} - $this->{'_h'};

    if($this->{'_remainder'} > $this->{'_c'}) { # normal case
      $this->{'_remainder'} = $this->maybe_round($this->{'_remainder'}
                              - $this->{'_c'});
    } else { # exceptional end case
      $this->{'_c'} = $this->{'_remainder'};
      $this->{'_remainder'} = 0;
    }

    # maybe take a snapshot
    unless($this->{'block_table'}) {
      my $snapshot = bless {%$this}, ref($this); # lame-o copy
      # Entries in the table are just snapshots of the object, minus 'table',
      #  and plus a few other things:
      $snapshot->{'table'} = undef;
      $snapshot->{'am_snapshot'} = 1;
      push @{$this->{'table'}}, $snapshot;
    }

    # maybe call the 'after' callback.
    if($this->{'callback_after_monthly_calc'}) {
       my @list = ($this);
       &{$this->{'callback_after_monthly_calc'}}(@list);
    }
    if($this->{'_abort'}) { $this->{'error'} ||= "Abort flag set."; return 0; }

    if($this->{'_month_count'} > $this->{'_month_count_limit'}) {
      $this->{'error'} = "_month_count_limit exceeded!";
      return 0;
    }
    $last_month_date = $this->{'_date'};
    $this->{'_date'} = &__inc_date($this->{'_date'})
     if defined($this->{'_date'});
  }
  $this->{'_date'} = $last_month_date; # a hack
  
  $this->{'total_month_count'} = $this->{'_month_count'};

  # 'total_paid_interest' and 'total_month_count' hold useful values
  # now

  return 1;
}

#===========================================================================

=item $loan->dump_table

This method dumps a few fields selected from snapshots in the C<table>
of the given object.  It's here more as example code than as anything
particularly useful.  See the source.  You should be able to use this
as a basis for making code of your own that dumps relevant fields from
the contents of snapshots of loan objects.

=cut

sub dump_table {
  my $this = $_[0];
  return unless ref $this->{'table'}; # no table!
  foreach my $line (@{$this->{'table'}}) {
     # iterate over snapshots
    printf
      "%s (#% 4d) | % 12.2f || % 10.2f | % 10.2f || % 12.2f\n",
      map($line->{$_},
          '_date',
          '_month_count',
          '_old_amount',
          '_h',
          '_c',
          '_remainder'
         )
    ;
  }
  return;
}
#===========================================================================

=back

=head1 REMEMBER

When in panic or in doubt, run in circles, scream and shout.

Or read the source.  I really suggest the latter, actually.

=head1 WARNINGS

* There's little or no sanity checking in this class.  If you want
to amortize a loan for $2 at 1% interest over ten million years,
this class won't stop you.

* Perl is liable to produce tiny math errors, like just about any
other language that does its math in binary but has to convert to and
from decimal for purposes of human interaction.  I've seen this
surface as tiny discrepancies in loan calculations -- "tiny" as in
less than $1 for even multi-million-dollar loans amortized over
decades.

* Moreover, oddities may creep in because of round-off errors. This
seems to result from the fact that the formula that takes term,
interest rate, and principal, and returns the monthly payment, doesn't
know that a real-world monthly payment of "$1020.309" is impossible --
and so that ninth of a cent difference can add up across the months.
At worst, this may cause a 30-year-loan loan coming to term in 30
years and 1 month, with the last payment being needed to pay off a
balance of two dollars, or the like.

These errors have never been a problem for any purpose I've
put this class to, but be on the look out.

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful,
but B<without any warranty>; without even the implied warranty of
B<merchantability> or B<fitness for a particular purpose>.

But let me know if it gives you any problems, OK?

=head1 COPYRIGHT

Copyright 1999-2002, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut


#  stuff...

sub __date_now {
  my $now;
  $now = @ARGV ? $_[0] : $^T;
  my($m, $y) = (localtime($now))[4,5];
  return sprintf("%04d-%02d", $y + 1900, $m + 1);
}

#===========================================================================

sub __inc_date {
  my $in_date = $_[0];
  my($year, $month);
  return "2000-01" unless $in_date =~ /^(\d\d\d\d)-(\d\d)/s;
  ($year, $month) = ($1, $2);

  if(++$month > 12) {
    $month = 1;
    $year++;
  }
  return sprintf("%04d-%02d", $year, $month);
}

#===========================================================================
1;

__END__


%seen = ();
while(<DATA>) {
  while(/->\{['"]([^'"]+)['"]\}/g) {
    print "$1 # $.\n" unless $seen{$1}++
  }
}

