use Test2::Bundle::Extended;
use AnyEvent::ProcessPool::Pipeline;

bail_out 'OS unsupported' if $^O eq 'MSWin32';

my %recv;
my @tasks  = 1 .. 10;
my %expect = map{ $_ => 1 } @tasks;
my $count  = pipeline
  in  { return unless @tasks; return (sub{ shift }, shift @tasks); },
  out { $recv{ $_[0]->recv } = 1 };

is $count, 10, 'all tasks seen by pipe';
is \%recv, \%expect, 'all tasks processed';

done_testing;
