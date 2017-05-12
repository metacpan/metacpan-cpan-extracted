use Contextual::Return;
use Carp;
use Test::More tests => 3;

sub f { Carp::confess("Forgive me..."); };
ok !defined eval { f() }            => 'eval fails';
my $exception = $@;
  like $exception, qr{line\s${\(__LINE__-3)}\.?\n.*line\s${\(__LINE__-2)}}xms
         => 'error message';
unlike $exception, qr{\*\* Incomplete caller override detected; \@DB::args were not set \*\*}
        => 'Complete override';

