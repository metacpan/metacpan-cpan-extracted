use strict; use warnings; use Test::More; use Config; use POSIX (); use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

# Adversarial re-entrancy coverage for the identity guards in Shared.xs:
# SEXTRACT/SREEXTRACT (Set: has/each_key) and BEXTRACT/BREEXTRACT
# (Builder: add/add_many). Arbitrary Perl can run mid-XSUB via overload
# magic (SvIV/SvPVbyte on a key) or via a callback (each_key). If that
# Perl destroys or replaces the invocant, the *REEXTRACT re-check after
# the conversion/callback must croak instead of touching a freed/foreign
# pointer. Every case below is isolated in its own forked child: a signal
# death (SIGSEGV/SIGBUS) is a crash the guard failed to prevent, an
# unexpected non-death means the guard didn't fire at all, and a croak
# with the wrong message means the wrong guard (or none) fired.
plan skip_all=>'fork required' unless $Config{d_fork};

our ($victim,$path,$vbuilder);

{ package Evil::Destroy; use overload '0+'=>sub{$_[0][0]->DESTROY;1},'""'=>sub{$_[0][0]->DESTROY;'1'},fallback=>1; }
{ package Evil::ReplaceObj; use overload
    '0+'=>sub{ $main::victim = Data::PerfectHash::Shared->load($main::path); 1 },
    '""'=>sub{ $main::victim = Data::PerfectHash::Shared->load($main::path); '1' }, fallback=>1; }
{ package Evil::DestroyB; use overload '0+'=>sub{$_[0][0]->DESTROY;1},'""'=>sub{$_[0][0]->DESTROY;'1'},fallback=>1; }
{ package Evil::ReplaceBuilder; use overload
    '0+'=>sub{ $main::vbuilder = Data::PerfectHash::Shared->new_builder(type=>'int'); 1 },
    '""'=>sub{ $main::vbuilder = Data::PerfectHash::Shared->new_builder(type=>'int'); '1' }, fallback=>1; }

my $dir=tempdir(CLEANUP=>1); $path="$dir/h.phs";
Data::PerfectHash::Shared->build_int($path,[1..100]);

# Per-case setup, run in the forked child before $call. Kept OUT of $call
# so the has() cases' call bodies stay verbatim against the brief.
my $load_victim    = sub { $victim   = Data::PerfectHash::Shared->load($path) };
my $fresh_builder  = sub { $vbuilder = Data::PerfectHash::Shared->new_builder(type=>'int') };
my $seeded_builder = sub { $vbuilder = Data::PerfectHash::Shared->new_builder(type=>'int'); $vbuilder->add($_) for 1..5 };

my @cases = (
  ['has: key magic destroys the set', qr/destroyed during the call/,
     $load_victim,
     sub { my $e=bless [$victim],'Evil::Destroy'; $victim->has($e) }],
  ['has: key magic replaces with a different set', qr/replaced or destroyed during the call/,
     $load_victim,
     sub { my $e=bless [$victim],'Evil::ReplaceObj'; $victim->has($e) }],
  ['each_key: callback destroys the set on the 3rd key', qr/destroyed during the call/,
     $load_victim,
     sub { my $n=0; $victim->each_key(sub { if (++$n==3) { $victim->DESTROY } }) }],
  ['each_key: callback replaces the set on the 3rd key', qr/destroyed during the call/,
     $load_victim,
     sub { my $n=0; $victim->each_key(sub { if (++$n==3) { $main::victim = Data::PerfectHash::Shared->load($main::path) } }) }],
  ['add: key magic destroys the builder', qr/destroyed during the call/,
     $seeded_builder,
     sub { my $e=bless [$vbuilder],'Evil::DestroyB'; $vbuilder->add($e) }],
  ['add: key magic replaces the builder', qr/destroyed during the call/,
     $seeded_builder,
     sub { my $e=bless [$vbuilder],'Evil::ReplaceBuilder'; $vbuilder->add($e) }],
  ['add_many: element magic destroys the builder mid-loop', qr/destroyed during the call/,
     $fresh_builder,
     sub { my $e=bless [$vbuilder],'Evil::DestroyB'; $vbuilder->add_many([1,2,$e,4]) }],
  ['build: mode value magic destroys the builder', qr/destroyed during the call/,
     $seeded_builder,
     sub { my $e=bless [$vbuilder],'Evil::DestroyB'; $vbuilder->build("$dir/mode_uaf.phs", mode => $e) }],
);

for my $c (@cases){ my($name,$want,$setup,$call)=@$c;
  my $pid=fork; unless(defined $pid){plan skip_all=>"fork: $!"}
  unless($pid){ $setup->();
    my $ok=eval{$call->();1}; my $err=$@//'';
    POSIX::_exit($ok?7:($err=~$want?0:8)); }
  waitpid $pid,0; my $st=$?;
  ok !($st&127), "no crash: $name"; is $st>>8,0, "clean croak: $name";
}
done_testing;
