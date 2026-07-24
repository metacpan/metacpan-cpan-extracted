#!/usr/bin/perl
# Regression: constructor argument magic must not leave MAKE_OBJ blessing
# through a stale class PV.
#
# xsubpp converts the `const char *class` invocant with SvPV_nolen(ST(0)) in
# the INPUT section, BEFORE the CODE block. Any get-magic on a later argument
# (the file mode in new(), capacity in new_memfd(), fd in new_from_fd()) runs
# after that capture and can realloc/free the class SV's PV buffer. gv_stashpv
# then read the freed chunk, blessing the new object into whatever bytes
# happened to be there.
#
# The tied argument below exploits exactly that: its FETCH grows the class
# variable so its PV buffer moves, parks a same-length decoy package name in
# the freed chunk, and restores the class to its proper value. With the bug,
# ref($obj) is the decoy ('Data::BitSet::ShareQ', one character off so it is
# the same string length and lands in the same malloc size class). With the
# fix, the constructor re-reads ST(0) after all magic and blesses into
# Data::BitSet::Shared.
#
# The assertion is on the specific symptom: the returned object must be
# blessed into Data::BitSet::Shared AND be callable, not merely "no crash".
use strict;
use warnings;
use Test::More;
use Data::BitSet::Shared;

my $CLASS = 'Data::BitSet::Shared';
# Decoy: 'Data::BitSet::ShareQ' - one character off $CLASS so it is the same
# string length and lands in the same malloc size class.

{ package ReallocClass;
  # A scalar whose FETCH relocates the PV buffer of the class variable it was
  # given a reference to, writes a decoy package name into the freed chunk,
  # then restores the class variable, so a corrected re-read sees the right
  # string while the stale pointer sees the decoy.
  sub TIESCALAR { my ($pkg, $classref, $retval) = @_; bless { cr => $classref, rv => $retval }, $pkg }
  sub FETCH {
      my $s = shift;
      ${ $s->{cr} } = 'P' x 100_000;   # grow: PV buffer moves, old chunk freed
      $s->{decoy} = join '', 'Data::BitSet', '::ShareQ';  # private PV: reuses the freed chunk
      ${ $s->{cr} } = $CLASS;          # restore: shorter, reuses big buffer
      $s->{rv};
  }
}

# Keep the class chunk away from the top of the heap so the grow above cannot
# extend in place.
my @pad = map { "padding-string-$_" } 1 .. 64;

# A non-COW, privately-owned class string: a plain copy of a literal is IsCOW
# and shares the hek buffer, which un-COW would copy out of without ever
# freeing the captured pointer, masking the bug. join '' gives a private PV.
sub fresh_class { join '', 'Data::BitSet', '::Shared' }

sub check_obj {
    my ($obj, $what) = @_;
    is ref($obj), $CLASS, "$what: blessed into $CLASS (not the decoy)"
        or diag "ref was: ", ref($obj);
    my $ok = eval { $obj->set(5); $obj->test(5) };
    ok $ok, "$what: object is callable";
}

# new(): magic on the optional file-mode argument runs after class capture.
{
    my $class = fresh_class();
    tie my $mode, 'ReallocClass', \$class, 0600;
    my $obj = $class->new(undef, 128, $mode);
    check_obj($obj, 'new (mode magic)');
}

# new_memfd(): magic on capacity runs in INPUT, after class capture.
{
    my $class = fresh_class();
    tie my $cap, 'ReallocClass', \$class, 128;
    my $obj = $class->new_memfd('magic', $cap);
    check_obj($obj, 'new_memfd (capacity magic)');
}

# new_from_fd(): magic on fd runs in INPUT, after class capture.
{
    my $donor = $CLASS->new_memfd('donor', 128);
    my $fd = $donor->memfd;
    ok $fd >= 0, 'donor exposes a backing fd';
    my $class = fresh_class();
    tie my $fdt, 'ReallocClass', \$class, $fd;
    my $obj = $class->new_from_fd($fdt);
    check_obj($obj, 'new_from_fd (fd magic)');
}

done_testing;
