#!/usr/bin/perl
# Regression: argument magic that explicitly calls $obj->DESTROY must not leave
# the running method dereferencing a freed handle.
#
# EXTRACT pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))), but that
# only blocks REFCOUNT-driven destruction. An explicit ->DESTROY runs the
# destructor regardless, freeing the handle and zeroing the IV -- so a method
# that captured `h` before running argument magic held a dangling pointer and
# segfaulted on the next lock. Methods where magic can intervene now re-read
# the handle (REEXTRACT) and croak instead.
#
# Two magic vectors are exercised:
#   add / add_many  -- SvPVbyte on the item argument runs a "" overload
#   similarity / merge -- the 'other' argument must be a MinHash object, so the
#                         overload trick cannot reach it; instead 'other' is a
#                         TIED scalar whose stored value is the object (so
#                         sv_isobject passes) and whose FETCH destroys $mh,
#                         triggered by the get-magic inside sv_derived_from.
#
# The hostile call runs in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use Data::MinHash::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

{ package Evil;
  use overload
      '""' => sub { $_[0][0]->DESTROY; 'k' },
      '0+' => sub { $_[0][0]->DESTROY; 0 },
      fallback => 1; }

# Tied scalar holding a MinHash object as its current value (so SvROK is true
# before magic); FETCH destroys the victim handle, then returns the object.
{ package TieDestroy;
  sub TIESCALAR { my ($class, $target) = @_; bless { target => $target }, $class }
  sub STORE { $_[0]{val} = $_[1] }
  sub FETCH { my $s = shift; $s->{target}->DESTROY; $s->{val} } }

for my $method (qw(add add_many similarity merge)) {
    my $pid = fork();
    unless ($pid) {
        my $k  = 64;
        my $mh = Data::MinHash::Shared->new(undef, $k);
        my $ok = eval {
            if ($method eq 'add') {
                my $evil = bless [$mh], 'Evil';
                $mh->add($evil);
            }
            elsif ($method eq 'add_many') {
                my $evil = bless [$mh], 'Evil';
                $mh->add_many([$evil]);
            }
            else {
                my $other = Data::MinHash::Shared->new(undef, $k);
                tie my $x, 'TieDestroy', $mh;
                $x = $other;    # STORE: current value is the object (sv_isobject passes)
                if ($method eq 'similarity') { $mh->similarity($x) }
                else                         { $mh->merge($x) }
            }
            1;
        };
        exit($ok ? 7 : 0);        # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
