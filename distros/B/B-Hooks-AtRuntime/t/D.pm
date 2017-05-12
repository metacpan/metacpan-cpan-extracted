package t::D;

use B::Hooks::AtRuntime qw/at_runtime after_runtime/;
#use Scalar::Util "weaken";
#use Devel::FindRef;
#use Devel::Peek;
#use Devel::Cycle;

#my @All;
#warn "\@All: " . \@All;
#warn "\@::D: " . \@::D;

sub new { bless [$_[1]], $_[0] }
sub DESTROY { push @::D, @{$_[0] } }
sub import {
    my $d = t::D->new($_[1]);
#    push @All, \$d;
#    weaken $All[-1];
    $_[2] ? after_runtime { $d } : at_runtime { $d };
}

#sub dump_all { 
#    for (@All) {
#        ref or next;
#        #Dump $$_;
#        warn Devel::FindRef::track $$_;
#        find_cycle $$_;
#    }
#}

1;
