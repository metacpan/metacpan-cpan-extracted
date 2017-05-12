package Bencher::Scenario::DataSah::Validate;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

require Data::Sah;
require DateTime;
require Time::Moment;

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark validation',
    modules => {
        'Data::Sah' => {version=>'0.84'},
    },
    participants => [
        {
            name => 'gen_validator',
            code_template => 'state $v = Data::Sah::gen_validator(<schema>, {return_type => <return_type>}); $v->(<data>)',
        },
    ],
    datasets => [
        {
            name => 'int',
            args => {
                schema => 'int',
                'data@' => [undef, 1, "a"],
                'return_type@' => $return_types,
            },
        },
        {
            name => 'str+2clause',
            args => {
                schema => ['str', min_len=>1, max_len=>5],
                'data@' => [undef, "abc", ""],
                'return_type@' => $return_types,
            },
        },
        {
            name => 'date (coerce to float(epoch))',
            args => {
                schema => ['date'],
                'data@' => [undef, "abc", 1463371843, "2016-05-16", DateTime->now,
                            #Time::Moment->now, # disabled for now, error
                        ],
                'return_type@' => $return_types,
            },
        },
        # XXX: date (coerce to DateTime)
        # XXX: date (coerce to Time::Moment)
    ],
};

1;
# ABSTRACT: Benchmark validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::Validate - Benchmark validation

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::Validate (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::Validate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.87

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_validator (perl_code)

Code template:

 state $v = Data::Sah::gen_validator(<schema>, {return_type => <return_type>}); $v->(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * str+2clause

=item * date (coerce to float(epoch))

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::Validate >>):

 #table1#
 [
    200,
    "OK",
    [
       {
          "arg_data" : 1485329055,
          "arg_return_type" : "full",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "5.2e-08",
          "rate" : "28000",
          "samples" : 21,
          "time" : "35",
          "vs_slowest" : "1"
       },
       {
          "arg_data" : "CIRCULAR",
          "arg_return_type" : "bool",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1.2e-07",
          "rate" : "29000",
          "samples" : 20,
          "time" : "35",
          "vs_slowest" : "1"
       },
       {
          "arg_data" : "CIRCULAR",
          "arg_return_type" : "str",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "5.1e-08",
          "rate" : "30000",
          "samples" : 22,
          "time" : "33",
          "vs_slowest" : "1.1"
       },
       {
          "arg_data" : "2016-05-16",
          "arg_return_type" : "full",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "4.7e-08",
          "rate" : "63000",
          "samples" : 20,
          "time" : "16",
          "vs_slowest" : "2.2"
       },
       {
          "arg_data" : "2016-05-16",
          "arg_return_type" : "str",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "2.3e-08",
          "rate" : "66000",
          "samples" : 28,
          "time" : "15",
          "vs_slowest" : "2.3"
       },
       {
          "arg_data" : "2016-05-16",
          "arg_return_type" : "bool",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "2.7e-08",
          "rate" : "68000",
          "samples" : 20,
          "time" : "15",
          "vs_slowest" : "2.4"
       },
       {
          "arg_data" : "abc",
          "arg_return_type" : "full",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1.2e-07",
          "rate" : "400000",
          "samples" : 23,
          "time" : "2",
          "vs_slowest" : "10"
       },
       {
          "arg_data" : 1463371843,
          "arg_return_type" : "full",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1.7e-09",
          "rate" : "750000",
          "samples" : 20,
          "time" : "1.3",
          "vs_slowest" : "26"
       },
       {
          "arg_data" : "a",
          "arg_return_type" : "full",
          "dataset" : "int",
          "errors" : "4.2e-10",
          "rate" : "813000",
          "samples" : 21,
          "time" : "1.23",
          "vs_slowest" : "28.8"
       },
       {
          "arg_data" : "",
          "arg_return_type" : "full",
          "dataset" : "str+2clause",
          "errors" : "1.1e-11",
          "rate" : "847640",
          "samples" : 20,
          "time" : "1.1798",
          "vs_slowest" : "30.005"
       },
       {
          "arg_data" : 1463371843,
          "arg_return_type" : "str",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1.7e-09",
          "rate" : "920000",
          "samples" : 20,
          "time" : "1.1",
          "vs_slowest" : "32"
       },
       {
          "arg_data" : 1463371843,
          "arg_return_type" : "bool",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1.7e-09",
          "rate" : "1100000",
          "samples" : 20,
          "time" : "0.88",
          "vs_slowest" : "40"
       },
       {
          "arg_data" : 1,
          "arg_return_type" : "full",
          "dataset" : "int",
          "errors" : "4.3e-10",
          "rate" : "1280000",
          "samples" : 20,
          "time" : "0.782",
          "vs_slowest" : "45.3"
       },
       {
          "arg_data" : "abc",
          "arg_return_type" : "full",
          "dataset" : "str+2clause",
          "errors" : "3.9e-10",
          "rate" : "1300000",
          "samples" : 23,
          "time" : "0.772",
          "vs_slowest" : "45.9"
       },
       {
          "arg_data" : "abc",
          "arg_return_type" : "str",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "0",
          "rate" : "1397030",
          "samples" : 20,
          "time" : "0.715803",
          "vs_slowest" : "49.4527"
       },
       {
          "arg_data" : "abc",
          "arg_return_type" : "bool",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "8.3e-10",
          "rate" : "1700000",
          "samples" : 20,
          "time" : "0.6",
          "vs_slowest" : "59"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "full",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1e-09",
          "rate" : "1700000",
          "samples" : 20,
          "time" : "0.59",
          "vs_slowest" : "60"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "full",
          "dataset" : "str+2clause",
          "errors" : "4.4e-10",
          "rate" : "1710000",
          "samples" : 20,
          "time" : "0.583",
          "vs_slowest" : "60.7"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "full",
          "dataset" : "int",
          "errors" : "8.4e-10",
          "rate" : "1700000",
          "samples" : 20,
          "time" : "0.58",
          "vs_slowest" : "61"
       },
       {
          "arg_data" : "a",
          "arg_return_type" : "str",
          "dataset" : "int",
          "errors" : "2.1e-10",
          "rate" : "2590000",
          "samples" : 20,
          "time" : "0.386",
          "vs_slowest" : "91.6"
       },
       {
          "arg_data" : "abc",
          "arg_return_type" : "str",
          "dataset" : "str+2clause",
          "errors" : "1.9e-09",
          "rate" : "2600000",
          "samples" : 20,
          "time" : "0.38",
          "vs_slowest" : "93"
       },
       {
          "arg_data" : 1,
          "arg_return_type" : "str",
          "dataset" : "int",
          "errors" : "6.2e-10",
          "rate" : "2700000",
          "samples" : 20,
          "time" : "0.37",
          "vs_slowest" : "95"
       },
       {
          "arg_data" : "",
          "arg_return_type" : "str",
          "dataset" : "str+2clause",
          "errors" : "2.1e-10",
          "rate" : "2830000",
          "samples" : 20,
          "time" : "0.354",
          "vs_slowest" : "100"
       },
       {
          "arg_data" : 1,
          "arg_return_type" : "bool",
          "dataset" : "int",
          "errors" : "4.2e-10",
          "rate" : "3300000",
          "samples" : 20,
          "time" : "0.3",
          "vs_slowest" : "120"
       },
       {
          "arg_data" : "a",
          "arg_return_type" : "bool",
          "dataset" : "int",
          "errors" : "4.2e-10",
          "rate" : "3400000",
          "samples" : 20,
          "time" : "0.3",
          "vs_slowest" : "120"
       },
       {
          "arg_data" : "abc",
          "arg_return_type" : "bool",
          "dataset" : "str+2clause",
          "errors" : "3.1e-10",
          "rate" : "3500000",
          "samples" : 20,
          "time" : "0.29",
          "vs_slowest" : "120"
       },
       {
          "arg_data" : "",
          "arg_return_type" : "bool",
          "dataset" : "str+2clause",
          "errors" : "4.2e-10",
          "rate" : "3700000",
          "samples" : 20,
          "time" : "0.27",
          "vs_slowest" : "130"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "str",
          "dataset" : "str+2clause",
          "errors" : "4.3e-10",
          "rate" : "3900000",
          "samples" : 20,
          "time" : "0.25",
          "vs_slowest" : "140"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "str",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "1e-10",
          "rate" : "3950000",
          "samples" : 20,
          "time" : "0.253",
          "vs_slowest" : "140"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "str",
          "dataset" : "int",
          "errors" : "4.2e-10",
          "rate" : "4000000",
          "samples" : 20,
          "time" : "0.25",
          "vs_slowest" : "140"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "bool",
          "dataset" : "int",
          "errors" : "4.2e-10",
          "rate" : "5500000",
          "samples" : 20,
          "time" : "0.18",
          "vs_slowest" : "190"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "bool",
          "dataset" : "str+2clause",
          "errors" : "4.7e-10",
          "rate" : "5500000",
          "samples" : 30,
          "time" : "0.18",
          "vs_slowest" : "200"
       },
       {
          "arg_data" : null,
          "arg_return_type" : "bool",
          "dataset" : "date (coerce to float(epoch))",
          "errors" : "3.7e-11",
          "rate" : "5620000",
          "samples" : 20,
          "time" : "0.178",
          "vs_slowest" : "199"
       }
    ],
    {
       "func.bencher_args" : {
          "action" : "bench",
          "note" : "Run by Pod::Weaver::Plugin::Bencher::Scenario",
          "scenario_module" : "DataSah::Validate"
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
             "speed" : "2602.304",
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
             "speed" : "2605.531",
             "stepping" : "4"
          }
       ],
       "func.elapsed_time" : 0.92997407913208,
       "func.module_startup" : null,
       "func.module_versions" : {
          "Bencher::Scenario::DataSah::Validate" : null,
          "Benchmark::Dumb" : "0.10",
          "Data::Sah" : "0.87",
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
             0,
             1,
             2
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
       "func.scenario_module" : "Bencher::Scenario::DataSah::Validate",
       "func.scenario_module_md5sum" : "6fca70892c1607daef019a9d21879a7d",
       "func.scenario_module_mtime" : 1485328729,
       "func.scenario_module_sha1sum" : "bbadb0f5cb6b719bc8a9d7bb1dccea69ab586b03",
       "func.scenario_module_sha256sum" : "c1a41062fe5f8d0e84c5f8782417f70abb4e2eece98a07c58d69a116bb04977d",
       "func.time_end" : 1485329064.2527,
       "func.time_factor" : 1000000,
       "func.time_start" : 1485329063.32273,
       "table.field_aligns" : [
          "left",
          "left",
          "left",
          "number",
          "number",
          "number",
          "number",
          "number"
       ],
       "table.field_units" : [
          null,
          null,
          null,
          "/s",
          "μs"
       ],
       "table.fields" : [
          "dataset",
          "arg_data",
          "arg_return_type",
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
