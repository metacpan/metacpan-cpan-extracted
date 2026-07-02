use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SpatialHash::Shared;

# new_from_fd must reject a non-map fd gracefully (croak, never crash/UB).

sub rejects { my $fd = shift; !eval { Data::SpatialHash::Shared->new_from_fd($fd); 1 } }

{ pipe(my $r, my $w) or die; ok rejects(fileno $r), 'new_from_fd(pipe) croaks'; }

{ my $f = "/tmp/sph-notmap-$$";
  open my $wf, '>', $f or die; print $wf "x" x 600; close $wf;
  open my $rf, '<', $f or die;
  ok rejects(fileno $rf), 'new_from_fd(regular non-map file) croaks';
  unlink $f; }

{ open my $dn, '<', '/dev/null' or die; ok rejects(fileno $dn), 'new_from_fd(/dev/null) croaks'; }

ok rejects(99999), 'new_from_fd(bogus fd number) croaks';

# a real map fd still works (sanity: the rejections above are not blanket failures)
my $m = Data::SpatialHash::Shared->new_memfd('ok', 50, 0, 1.0);
ok eval { Data::SpatialHash::Shared->new_from_fd($m->memfd); 1 }, 'new_from_fd(valid memfd) succeeds';

done_testing;
