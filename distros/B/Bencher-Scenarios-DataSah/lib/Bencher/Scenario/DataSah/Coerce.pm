package Bencher::Scenario::DataSah::Coerce;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

require Data::Sah::Coerce;
require DateTime;
require Time::Moment;

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark coercion',
    participants => [
        {
            name => 'gen_coercer',
            code_template => 'state $c = Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>); $c->(<data>)',
        },
    ],
    datasets => [
        {
            name => 'date (coerce to float(epoch))',
            args => {
                type => 'date',
                coerce_to => 'float(epoch)',
                'data@' => [undef, "abc", 123, [], 1463373166, "2016-05-16"],
            },
        },
        # XXX date (coerce to DateTime)
        # XXX date (coerce to Time::Moment)
    ],
};

1;
# ABSTRACT: Benchmark coercion

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::Coerce - Benchmark coercion

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::Coerce (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::Coerce

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_coercer (perl_code)

Code template:

 state $c = Data::Sah::Coerce::gen_coercer(type => <type>, coerce_to => <coerce_to>); $c->(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * date (coerce to float(epoch))

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::Coerce >>):

 #table1#
 [
    200,
    "OK",
    [
       {
          "arg_data" : "2016-05-16",
          "errors" : "6.1e-09",
          "rate" : "72900",
          "samples" : 24,
          "time" : "13.7",
          "vs_slowest" : "1"
       },
       {
          "arg_data" : 1463373166,
          "errors" : "8.5e-10",
          "rate" : "1600000",
          "samples" : 20,
          "time" : "0.61",
          "vs_slowest" : "22"
       },
       {
          "arg_data" : [],
          "errors" : "8.3e-10",
          "rate" : "2200000",
          "samples" : 20,
          "time" : "0.45",
          "vs_slowest" : "31"
       },
       {
          "arg_data" : "abc",
          "errors" : "2.1e-10",
          "rate" : "2540000",
          "samples" : 20,
          "time" : "0.394",
          "vs_slowest" : "34.8"
       },
       {
          "arg_data" : 123,
          "errors" : "6.5e-10",
          "rate" : "2700000",
          "samples" : 20,
          "time" : "0.37",
          "vs_slowest" : "37"
       },
       {
          "arg_data" : null,
          "errors" : "8.1e-11",
          "rate" : "7470000",
          "samples" : 33,
          "time" : "0.134",
          "vs_slowest" : "102"
       }
    ],
    {
       "func.bencher_args" : {
          "action" : "bench",
          "note" : "Run by Pod::Weaver::Plugin::Bencher::Scenario",
          "scenario_module" : "DataSah::Coerce"
       },
       "func.bencher_version" : null,
       "func.cpu_info" : [
          {
             "L2_cache" : {
                "max_cache_size" : "4096 KB"
             },
             "address_width" : "64",
             "architecture" : "AMD-64",
             "bus_speed" : null,
             "data_width" : "64",
             "family" : "6",
             "flags" : [
                "fpu",
                "vme",
                "de",
                "pse",
                "tsc",
                "msr",
                "pae",
                "mce",
                "cx8",
                "apic",
                "sep",
                "mtrr",
                "pge",
                "mca",
                "cmov",
                "pat",
                "pse36",
                "clflush",
                "dts",
                "acpi",
                "mmx",
                "fxsr",
                "sse",
                "sse2",
                "ss",
                "ht",
                "tm",
                "pbe",
                "syscall",
                "nx",
                "pdpe1gb",
                "rdtscp",
                "lm",
                "constant_tsc",
                "arch_perfmon",
                "pebs",
                "bts",
                "rep_good",
                "nopl",
                "xtopology",
                "nonstop_tsc",
                "aperfmperf",
                "eagerfpu",
                "pni",
                "pclmulqdq",
                "dtes64",
                "monitor",
                "ds_cpl",
                "vmx",
                "smx",
                "est",
                "tm2",
                "ssse3",
                "fma",
                "cx16",
                "xtpr",
                "pdcm",
                "pcid",
                "sse4_1",
                "sse4_2",
                "x2apic",
                "movbe",
                "popcnt",
                "tsc_deadline_timer",
                "aes",
                "xsave",
                "avx",
                "f16c",
                "rdrand",
                "lahf_lm",
                "abm",
                "3dnowprefetch",
                "ida",
                "arat",
                "epb",
                "pln",
                "pts",
                "dtherm",
                "tpr_shadow",
                "vnmi",
                "flexpriority",
                "ept",
                "vpid",
                "fsgsbase",
                "tsc_adjust",
                "bmi1",
                "hle",
                "avx2",
                "smep",
                "bmi2",
                "erms",
                "invpcid",
                "rtm",
                "rdseed",
                "adx",
                "smap",
                "xsaveopt"
             ],
             "manufacturer" : "GenuineIntel",
             "model" : "61",
             "name" : "Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz",
             "number_of_cores" : "2",
             "number_of_logical_processors" : 4,
             "processor_id" : "0",
             "speed" : "2599.953",
             "stepping" : "4"
          },
          {
             "L2_cache" : {
                "max_cache_size" : "4096 KB"
             },
             "address_width" : "64",
             "architecture" : "AMD-64",
             "bus_speed" : null,
             "data_width" : "64",
             "family" : "6",
             "flags" : [
                "fpu",
                "vme",
                "de",
                "pse",
                "tsc",
                "msr",
                "pae",
                "mce",
                "cx8",
                "apic",
                "sep",
                "mtrr",
                "pge",
                "mca",
                "cmov",
                "pat",
                "pse36",
                "clflush",
                "dts",
                "acpi",
                "mmx",
                "fxsr",
                "sse",
                "sse2",
                "ss",
                "ht",
                "tm",
                "pbe",
                "syscall",
                "nx",
                "pdpe1gb",
                "rdtscp",
                "lm",
                "constant_tsc",
                "arch_perfmon",
                "pebs",
                "bts",
                "rep_good",
                "nopl",
                "xtopology",
                "nonstop_tsc",
                "aperfmperf",
                "eagerfpu",
                "pni",
                "pclmulqdq",
                "dtes64",
                "monitor",
                "ds_cpl",
                "vmx",
                "smx",
                "est",
                "tm2",
                "ssse3",
                "fma",
                "cx16",
                "xtpr",
                "pdcm",
                "pcid",
                "sse4_1",
                "sse4_2",
                "x2apic",
                "movbe",
                "popcnt",
                "tsc_deadline_timer",
                "aes",
                "xsave",
                "avx",
                "f16c",
                "rdrand",
                "lahf_lm",
                "abm",
                "3dnowprefetch",
                "ida",
                "arat",
                "epb",
                "pln",
                "pts",
                "dtherm",
                "tpr_shadow",
                "vnmi",
                "flexpriority",
                "ept",
                "vpid",
                "fsgsbase",
                "tsc_adjust",
                "bmi1",
                "hle",
                "avx2",
                "smep",
                "bmi2",
                "erms",
                "invpcid",
                "rtm",
                "rdseed",
                "adx",
                "smap",
                "xsaveopt"
             ],
             "manufacturer" : "GenuineIntel",
             "model" : "61",
             "name" : "Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz",
             "number_of_cores" : "2",
             "number_of_logical_processors" : 4,
             "processor_id" : "1",
             "speed" : "2599.953",
             "stepping" : "4"
          },
          {
             "L2_cache" : {
                "max_cache_size" : "4096 KB"
             },
             "address_width" : "64",
             "architecture" : "AMD-64",
             "bus_speed" : null,
             "data_width" : "64",
             "family" : "6",
             "flags" : [
                "fpu",
                "vme",
                "de",
                "pse",
                "tsc",
                "msr",
                "pae",
                "mce",
                "cx8",
                "apic",
                "sep",
                "mtrr",
                "pge",
                "mca",
                "cmov",
                "pat",
                "pse36",
                "clflush",
                "dts",
                "acpi",
                "mmx",
                "fxsr",
                "sse",
                "sse2",
                "ss",
                "ht",
                "tm",
                "pbe",
                "syscall",
                "nx",
                "pdpe1gb",
                "rdtscp",
                "lm",
                "constant_tsc",
                "arch_perfmon",
                "pebs",
                "bts",
                "rep_good",
                "nopl",
                "xtopology",
                "nonstop_tsc",
                "aperfmperf",
                "eagerfpu",
                "pni",
                "pclmulqdq",
                "dtes64",
                "monitor",
                "ds_cpl",
                "vmx",
                "smx",
                "est",
                "tm2",
                "ssse3",
                "fma",
                "cx16",
                "xtpr",
                "pdcm",
                "pcid",
                "sse4_1",
                "sse4_2",
                "x2apic",
                "movbe",
                "popcnt",
                "tsc_deadline_timer",
                "aes",
                "xsave",
                "avx",
                "f16c",
                "rdrand",
                "lahf_lm",
                "abm",
                "3dnowprefetch",
                "ida",
                "arat",
                "epb",
                "pln",
                "pts",
                "dtherm",
                "tpr_shadow",
                "vnmi",
                "flexpriority",
                "ept",
                "vpid",
                "fsgsbase",
                "tsc_adjust",
                "bmi1",
                "hle",
                "avx2",
                "smep",
                "bmi2",
                "erms",
                "invpcid",
                "rtm",
                "rdseed",
                "adx",
                "smap",
                "xsaveopt"
             ],
             "manufacturer" : "GenuineIntel",
             "model" : "61",
             "name" : "Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz",
             "number_of_cores" : "2",
             "number_of_logical_processors" : 4,
             "processor_id" : "2",
             "speed" : "2599.953",
             "stepping" : "4"
          },
          {
             "L2_cache" : {
                "max_cache_size" : "4096 KB"
             },
             "address_width" : "64",
             "architecture" : "AMD-64",
             "bus_speed" : null,
             "data_width" : "64",
             "family" : "6",
             "flags" : [
                "fpu",
                "vme",
                "de",
                "pse",
                "tsc",
                "msr",
                "pae",
                "mce",
                "cx8",
                "apic",
                "sep",
                "mtrr",
                "pge",
                "mca",
                "cmov",
                "pat",
                "pse36",
                "clflush",
                "dts",
                "acpi",
                "mmx",
                "fxsr",
                "sse",
                "sse2",
                "ss",
                "ht",
                "tm",
                "pbe",
                "syscall",
                "nx",
                "pdpe1gb",
                "rdtscp",
                "lm",
                "constant_tsc",
                "arch_perfmon",
                "pebs",
                "bts",
                "rep_good",
                "nopl",
                "xtopology",
                "nonstop_tsc",
                "aperfmperf",
                "eagerfpu",
                "pni",
                "pclmulqdq",
                "dtes64",
                "monitor",
                "ds_cpl",
                "vmx",
                "smx",
                "est",
                "tm2",
                "ssse3",
                "fma",
                "cx16",
                "xtpr",
                "pdcm",
                "pcid",
                "sse4_1",
                "sse4_2",
                "x2apic",
                "movbe",
                "popcnt",
                "tsc_deadline_timer",
                "aes",
                "xsave",
                "avx",
                "f16c",
                "rdrand",
                "lahf_lm",
                "abm",
                "3dnowprefetch",
                "ida",
                "arat",
                "epb",
                "pln",
                "pts",
                "dtherm",
                "tpr_shadow",
                "vnmi",
                "flexpriority",
                "ept",
                "vpid",
                "fsgsbase",
                "tsc_adjust",
                "bmi1",
                "hle",
                "avx2",
                "smep",
                "bmi2",
                "erms",
                "invpcid",
                "rtm",
                "rdseed",
                "adx",
                "smap",
                "xsaveopt"
             ],
             "manufacturer" : "GenuineIntel",
             "model" : "61",
             "name" : "Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz",
             "number_of_cores" : "2",
             "number_of_logical_processors" : 4,
             "processor_id" : "3",
             "speed" : "2599.953",
             "stepping" : "4"
          }
       ],
       "func.elapsed_time" : 0.143622159957886,
       "func.module_startup" : null,
       "func.module_versions" : {
          "Bencher::Scenario::DataSah::Coerce" : null,
          "Benchmark::Dumb" : "0.10",
          "Devel::Platform::Info" : "0.16",
          "Sys::Info" : "0.78",
          "__PACKAGE__" : "1.034",
          "perl" : "v5.24.0"
       },
       "func.note" : "Run by Pod::Weaver::Plugin::Bencher::Scenario",
       "func.permute" : [
          "perl",
          [
             "perl"
          ],
          "participant",
          [
             0
          ],
          "dataset",
          [
             0
          ]
       ],
       "func.platform_info" : {
          "archname" : "x86_64",
          "codename" : "rosa",
          "is32bit" : 0,
          "is64bit" : 1,
          "kernel" : "linux-3.19.0-32-generic",
          "kname" : "Linux",
          "kvers" : "3.19.0-32-generic",
          "osflag" : "linux",
          "oslabel" : "LinuxMint",
          "osname" : "GNU/Linux",
          "osvers" : "17.3",
          "source" : {
             "cat /etc/.issue" : "",
             "cat /etc/issue" : "Linux Mint 17.3 Rosa \\n \\l",
             "lsb_release -a" : "Distributor ID:\tLinuxMint\nDescription:\tLinux Mint 17.3 Rosa\nRelease:\t17.3\nCodename:\trosa",
             "uname -a" : "Linux backpacker 3.19.0-32-generic #37~14.04.1-Ubuntu SMP Thu Oct 22 09:41:40 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux",
             "uname -m" : "x86_64",
             "uname -o" : "GNU/Linux",
             "uname -r" : "3.19.0-32-generic",
             "uname -s" : "Linux"
          }
       },
       "func.precision" : 0,
       "func.scenario_module" : "Bencher::Scenario::DataSah::Coerce",
       "func.scenario_module_md5sum" : "3f81bf39184f72bb9fde60744f642c81",
       "func.scenario_module_mtime" : 1463763168,
       "func.scenario_module_sha1sum" : "1f2acc2c498be7556b36a8817d7345f48b0428a7",
       "func.scenario_module_sha256sum" : "38b8f65763fe5c353d63ba08b36fd6cb9bcf32ee39a974f68f8370d4d097596a",
       "func.time_end" : 1485329055.89202,
       "func.time_factor" : 1000000,
       "func.time_start" : 1485329055.7484,
       "table.field_aligns" : [
          "left",
          "number",
          "number",
          "number",
          "number",
          "number"
       ],
       "table.field_units" : [
          null,
          "/s",
          "μs"
       ],
       "table.fields" : [
          "arg_data",
          "rate",
          "time",
          "vs_slowest",
          "errors",
          "samples"
       ]
    }
 ]


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataSah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
