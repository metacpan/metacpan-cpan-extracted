#! /usr/bin/env perl

use Test::More;
use Data::YAML::Reader;

use_ok 'Benchmark::Perl::Formance';

my $out = qx"$^X -Ilib bin/benchmark-perlformance --fastmode --outstyle=yamlish -c -p --plugins=Fib";
my $yr = Data::YAML::Reader->new;
my $outdata =  $yr->read($out);
ok(defined $outdata->{results}, "results");
ok(defined $outdata->{perl_config}, "perl_config");
ok(defined $outdata->{platform_info}, "platform_info");
ok(defined $outdata->{perlformance}, "perlformance meta info");
ok(defined $outdata->{perlformance}{config}, "perlformance config");
ok(defined $outdata->{perlformance}{overall_runtime}, "perlformance runtime");

$out = qx"$^X -Ilib bin/benchmark-perlformance --version -v";
like($out, qr/\(v\d.* Fib$/m,                    "plugin version Fib");
like($out, qr/\(v\d.* FibOO$/m,                  "plugin version FibOO");
like($out, qr/\(v\d.* Mem$/m,                    "plugin version Mem");
like($out, qr/\(v\d.* Rx$/m,                     "plugin version Rx");
like($out, qr/\(v\d.* Shootout::fasta$/m,        "plugin version Shootout::fasta");
like($out, qr/\(v\d.* Shootout::binarytrees$/m,  "plugin version Shootout::binarytrees");
like($out, qr/\(v\d.* Shootout::nbody$/m,        "plugin version Shootout::nbody");
like($out, qr/\(v\d.* Shootout::spectralnorm$/m, "plugin version Shootout::spectralnorm");

done_testing();
