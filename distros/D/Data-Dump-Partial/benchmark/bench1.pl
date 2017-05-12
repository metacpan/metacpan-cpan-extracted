#!/usr/bin/perl -w

use Benchmark;
use Data::Dumper;
use Data::Dump qw/dump/;
use Data::Dump::Filtered qw/dump_filtered/;
use Data::Dump::Partial qw/dump_partial/;

$data = [1, {q=>1, w=>1, e=>1, r=>1, t=>1, y=>1}, ("a"x100)."2", 4, 5, 0];

# we assign to $_ cause otherwise Data::Dump-based dumper will print
# to STDERR.

timethese(2000, {
    'Data::Dumper' => sub { $_ = Dumper($data) },
    'Data::Dump' => sub { $_ = dump($data) },
    'Data::Dump::Filtered' => sub { $_ = dump_filtered($data, sub {}) },
    'Data::Dump::Partial' => sub { $_ = dump_partial($data) },
});

__END__

=head1 RESULT (2010-06-27, my EEE S101 [Atom N270] netbook)

Data::Dump is slow (about 6 times slower than Data::Dumper), while
Data::Dump::Partial is around 2x slower than plain Data::Dump. right
now i don't see much point in speeding it up as long as we still base
on Data::Dump.

 Data::Dump:  3 wallclock secs ( 2.77 usr +  0.00 sys =  2.77 CPU) @ 722.02/s (n=2000)
 Data::Dump::Filtered:  3 wallclock secs ( 3.54 usr +  0.00 sys =  3.54 CPU) @ 564.97/s (n=2000)
 Data::Dump::Partial:  5 wallclock secs ( 5.05 usr +  0.00 sys =  5.05 CPU) @ 396.04/s (n=2000)
 Data::Dumper:  1 wallclock secs ( 0.47 usr +  0.00 sys =  0.47 CPU) @ 4255.32/s (n=2000)

=cut
