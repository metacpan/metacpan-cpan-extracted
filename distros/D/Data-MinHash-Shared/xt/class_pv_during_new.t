#!/usr/bin/perl
# Regression: the constructors declared the invocant as `const char *class`,
# so xsubpp captured its PV in the XS INPUT section -- BEFORE any magic on the
# later arguments ran (SvUV on k/mode in new/new_memfd, SvGETMAGIC+SvPV on
# path/name, SvIV on fd in new_from_fd). Called as $class->new(...), ST(0)
# aliases the caller's variable, so that later magic could realloc/free the
# class PV; MAKE_OBJ then passed the dangling pointer to gv_stashpv and the
# new object was blessed into whatever the freed buffer now held.
#
# The fix re-reads the class PV from ST(0) at the point of use, after all
# argument magic has run, so the object is blessed into the class variable's
# CURRENT value. The test drives this with an overloaded later argument whose
# numeric conversion (a) frees the old class PV chunk and (b) sets the class
# variable to a different valid package name; the constructor must bless into
# the NEW name. Without the fix it blesses into the stale (old) name -- or
# crashes, which the child-process harness reports instead of dying.
use strict;
use warnings;
use Test::More;
use Config;
use Data::MinHash::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

@Data::MinHash::Shared::Hijacked::ISA = ('Data::MinHash::Shared');

# Overloaded numeric argument: converting it frees the class variable's PV
# chunk (the 100k string forces the buffer to move, not realloc in place) and
# then installs a different package name as the variable's current value.
# [0] = ref to the caller's class variable, [1] = number to return.
{ package EvilNum;
  use overload
      '0+' => sub {
          my ($clsref, $num) = @{ $_[0] };
          $$clsref = 'x' x 100_000;                        # free the old PV chunk
          $$clsref = 'Data::MinHash::Shared::Hijacked';    # value at point of use
          $num;
      },
      fallback => 1; }

for my $ctor (qw(new new_memfd new_from_fd)) {
    my $pid = open(my $out, '-|');
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {    # child: the hostile call, possibly crashing without the fix
        my $cls = 'Data::MinHash::Shared';
        my $obj = eval {
            if ($ctor eq 'new') {
                my $evil = bless [ \$cls, 0660 ], 'EvilNum';
                $cls->new(undef, 64, $evil);        # mode arg magic mutates $cls
            }
            elsif ($ctor eq 'new_memfd') {
                my $evil = bless [ \$cls, 64 ], 'EvilNum';
                $cls->new_memfd(undef, $evil);      # k arg magic mutates $cls
            }
            else {
                my $real = Data::MinHash::Shared->new_memfd(undef, 16);
                my $evil = bless [ \$cls, $real->memfd ], 'EvilNum';
                $cls->new_from_fd($evil);           # fd arg magic mutates $cls
            }
        };
        if ($obj) {
            print ref($obj), "\n";
            print $obj->add('probe'), "\n";         # handle + stash must work
        } else {
            print "undef\nundef\n";
        }
        exit 0;
    }
    chomp(my $ref  = <$out> // 'undef');
    chomp(my $add  = <$out> // 'undef');
    close $out;
    my $st = $?;
    ok !($st & 127), "$ctor: no crash when argument magic replaces the class PV"
        or diag sprintf('died with signal %d', $st & 127);
    is $ref, 'Data::MinHash::Shared::Hijacked',
       "$ctor: blessed into the class variable's current value, not a stale PV";
    is $add, 1, "$ctor: resulting object is fully functional";
}

# Control: an overloaded argument that does NOT touch the class variable must
# leave the normal bless target alone.
{
    my $cls = 'Data::MinHash::Shared';
    my $calm = bless [ \$cls, 0660 ], 'EvilCalm';
    { package EvilCalm;
      use overload '0+' => sub { $_[0][1] }, fallback => 1; }
    my $obj = $cls->new(undef, 64, $calm);
    is ref($obj), 'Data::MinHash::Shared', 'new: unchanged class variable blesses normally';
    isa_ok $obj, 'Data::MinHash::Shared';
}

done_testing;
