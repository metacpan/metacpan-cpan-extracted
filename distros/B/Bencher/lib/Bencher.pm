package Bencher;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-13'; # DATE
our $DIST = 'Bencher'; # DIST
our $VERSION = '1.056'; # VERSION

1;
# ABSTRACT: A benchmark framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher - A benchmark framework

=head1 VERSION

This document describes version 1.056 of Bencher (from Perl distribution Bencher), released on 2021-08-13.

=head1 SYNOPSIS

See L<bencher> CLI.

=head1 DESCRIPTION

Bencher is a benchmark framework. The main feature of Bencher is permuting list
of Perl codes with list of arguments into benchmark items, and then benchmark
them. You can run only some of the items as well as filter codes and arguments
to use. You can also permute multiple perls and multiple module versions.

=head1 TERMINOLOGY

B<Scenario>. A hash data structure that lists I<participants>, I<datasets>, and
other things. The bencher CLI can accept a scenario from a module (under
C<Bencher::Scenario::*> namespace or C<Acme::CPANModules::*> namespace), a
script, or from command-line option. See L</"SCENARIO">.

B<Participant>. What to run or benchmark. Usually a Perl code or code template,
or a command or command template. See L</"participants">.

B<Dataset>. Arguments or parameters to permute with a participant. See
L</"datasets">.

B<(Benchmark) item>. Participant that has been permuted with dataset into code
ready to run. Usually a scenario does not contain items directly, but only
participants and datasets, and lets Bencher permute these into items.

=head1 SCENARIO

The core data structure that you need to prepare is the B<scenario>. It is a
L<DefHash> (i.e. just a regular Perl hash). The two most important keys of this
hash are: B<participants> and B<datasets>.

An example scenario (from C<Bench::Scenario::Example>):

 package Bencher::Scenario::Example;
 our $scenario = {
     participants => [
         {fcall_template => q[Text::Wrap::wrap('', '', <text>)]},
     ],
     datasets => [
         { name=>"foobar x100",   args => {text=>"foobar " x 100} },
         { name=>"foobar x1000",  args => {text=>"foobar " x 1000} },
         { name=>"foobar x10000", args => {text=>"foobar " x 10000} },
     ],
 };
 1;

=head2 participants

B<participants> (array) lists Perl codes (or external commands) that we want to
benchmark.

=head3 Specifying participant's code

There are several kinds of code you can specify:

=over

=item * module

First, you can just specify C<module> (str, a Perl module name). This is useful
when running scenario in L<module_startup mode/"Running benchmark in module
startup mode">. Also useful to instruct Bencher to load the module. When not in
module startup mode, there is no code in this participant to run. In addition to
C<module> you can also specify C<import_args> which can be a string or an
arrayref.

=item * modules

You can also specify C<modules> (an array of Perl module names) if you want to
benchmark several modules together. Similarly, this is only useful for running
in module startup mode. To specify import arguments for each of these modules,
use C<import_args_array>.

=item * code

You can specify C<code> (a coderef) which contains the code to benchmark.
However, the point of Bencher is to use C<fcall_template> or at least
C<code_template> to be able to easily permute the code with datasets (see
below). So you should only specify C<code> when you cannot specify
C<fcall_template> or C<code_template> or the other way.

B<Caveat:> if you run bencher in multiperl or multi-module-version mode, the
current implementaiton will fill the code templates and dump the scenario into a
temporary script and run that script with separate perl processes. The dumped
coderef will lack 'use' statement or code in BEGIN block. Avoid using that in
your code.

=item * fcall_template

You can specify C<fcall_template>, and this is the recommended way whenever
possible. It is a string containing a function call code, in the form of:

 MODULENAME::FUNCTIONAME(ARG, ...)

or

 CLASSNAME->FUNCTIONAME(ARG, ...)

For example:

 Text::Levenshtein::fastdistance(<word1>, <word2>)

Another example:

 Module::CoreList->is_code(<module>)

It can be used to benchmark a function call or a method call. From this format,
Bencher can easily extract the module name so user can also run in module
startup mode.

By using a template, Bencher can generate actual codes from this template by
combining it with datasets. The words enclosed in C<< <...> >> will be replaced
with actual arguments specified in L</"datasets">. The arguments are
automatically encoded as Perl value, so it's safe to use arrayref or complex
structures as argument values (however, you can use C<< <...:raw> >> to avoid
this automatic encoding).

=item * code_template

Aside from C<fcall_template>, you can also use C<code_template> (a string
containing arbitrary code), in the cases where the code you want to benchmark
cannot be expressed as a simple function/method call, for example (taken from
L<Bencher::Scenario::ComparisonOps>):

 participants => [
     {name=>'1k-numeq'      , code_template=>'my $val =     1; for (1..1000) { if ($val ==     1) {} if ($val ==     2) {} }'},
     {name=>'1k-streq-len1' , code_template=>'my $val = "a"  ; for (1..1000) { if ($val eq "a"  ) {} if ($val eq "b"  ) {} }'},
     {name=>'1k-streq-len3' , code_template=>'my $val = "foo"; for (1..1000) { if ($val eq "foo") {} if ($val eq "bar") {} }'},
     {name=>'1k-streq-len10', code_template=>'my $val = "abcdefghij"; for (1..1000) { if ($val eq "abcdefghij") {} if ($val eq "klmnopqrst") {} }'},
 ],

Like in C<fcall_template>, words enclosed in C<< <...> >> will be replaced with
actual data. When generating actual code, Bencher will enclose the code template
with C<sub { .. }>.

B<Caveat:> if you run bencher in multiperl or multi-module-version mode, the
current implementaiton will fill the code templates and dump the scenario into a
temporary script and run that script with separate perl processes. The dumped
coderef will lack 'use' statement or code in BEGIN block. Avoid using that in
your code.

=item * cmdline, cmdline_template, perl_cmdline, perl_cmdline_templates

Or, if you are benchmarking external commands, you specify C<cmdline> (array or
strings, or strings) or C<cmdline_template> (array/str) or C<perl_cmdline> or
C<perl_cmdline_template> instead. An array cmdline will not use shell, while the
string version will use shell. C<perl_cmdline*> are the same as C<cmdline*>
except the first implicit argument/prefix is perl. When the cmdline template is
filled with the arguments, the values will automatically be shell-escaped
(unless you use the C<< <...:raw> >> syntax).

When using code template, code will be generated and eval-ed in the C<main>
package.

=back

=head3 Specifying participant's name

By default, Bencher will attempt to figure out the name for a participant (a
sequence number starting from 1, a module name or module name followed by
function name, etc). You can also specify name for a participant explicitly so
you can refer to it more easily later, e.g.:

 participants => [
     {name=>'pp', fcall_template=>'List::MoreUtils::PP::uniq(@{<array>})'},
     {name=>'xs', fcall_template=>'List::MoreUtils::XS::uniq(@{<array>})'},
 ],

=head3 List of properties for a participant

This is a reference section.

=over

=item * name (str)

From DefHash.

=item * summary (str)

From DefHash.

=item * description (str)

From DefHash.

=item * tags (array of str)

From DefHash. Define tag(s) for this participant. Can be used to include/exclude
groups of participants having the same tags.

=item * module (str)

=item * modules (array of str)

These are modules that are to be benchmarked. When running the benchmark
scenario, these modules will be require'd first, so you don't have to require
them again manually in your code/code template.

=item * helper_modules (array of str)

These are helper modules that are required when running the participant code,
but are not the main subject to be benchmarked. They will also be require'd when
running the benchmark scenario so you don't have to require them manually in
your code/code template.

The difference with the C<modules> property is: the modules specified in
C<modules> should be specified as phase=x_benchmarks, rel=x_benchmarks
prerequisites while modules specified in C<helper_modules> should not. But all
modules can be specified as phase=x_benchmarks, rel=requires prerequisites.

=item * function (str)

=item * fcall_template (str)

=item * code_template (str)

=item * code (code)

=item * cmdline (str|array of str)

=item * cmdline_template (str|array of str)

=item * perl_cmdline (str|array of str)

=item * perl_cmdline_template (str|array of str)

=item * result_is_list (bool, default 0)

This is useful when dumping item's codes, so Bencher will use a list context
when receiving result.

=item * include_by_default (bool, default 1)

Can be set to false if you want to exclude participant by default when running
benchmark, unless the participant is explicitly included e.g. using
C<--include-participant> command-line option.

=back

=head2 datasets

B<datasets> (array) lists the function inputs (or command-line arguments). You
can C<name> each dataset too, to be able to refer to it more easily.

Other properties you can add to a dataset: C<include_by_default> (bool, default
true, can be set to false if you want to exclude dataset by default when running
benchmark, unless the dataset is explicitly included).

=over

=item * name (str)

From DefHash.

=item * summary (str)

From DefHash.

=item * description (str)

From DefHash.

=item * tags (array of str)

From DefHash. Define tag(s) for this dataset. Can be used to include/exclude
groups of datasets having the same tags.

=item * args (hash)

Example:

 {filename=>"ujang.txt", size=>10}

You can supply multiple argument values by adding C<@> suffix to the argument
name. You then supply an array for the values, example:

 {filename=>"ujang.txt", 'size@'=>[10, 100, 1000]}

This means, for each participant mentioning C<size>, three benchmark items will
be generated, one for each value of C<size>.

Aside from array, you can also use hash for the multiple values. This has a nice
effect of showing nicer names (in the hash keys) for the argument value, e.g.:

 {filename=>"ujang.txt", 'size@'=>{"1M"=>1024*2, "1G"=>1024**3, "1T"=>1024**4}}

=item * argv (array)

=item * include_by_default (bool, default 1)

=item * include_participant_tags (array of str)

Only include participants having one of these tags. For example:

 ['a', 'b']

will include all participants having either C<a> or C<b> in their tags. To only
include participants which have all of C<a> and C<b> in their tags, use:

 ['a & b']

=item * exclude_participant_tags (array of str)

Exclude participants having any of these tags. For example:

 ['a', 'b']

will exclude all participants having either C<a> or C<b> in their tags. To only
exclude participants which have all of C<a> and C<b> in their tags, use:

 ['a & b']

=item * result (any)

Specify result that any participant must return. This can be used to verify that
participant code is correct (returns the desired result) before benchmarking.
If a participant fails to return this result, benchmarking will be aborted.

=back

=head2 Other properties

Other known scenario properties (keys):

=over

=item * name

From DefHash, scenario name (usually short and one word).

=item * summary

From DefHash, a one-line plaintext summary.

=item * description (str)

From DefHash, longer description in Markdown.

=item * test (bool, default 1)

By default, participant code is run once first for testing (e.g. whether it dies
or return the correct result) before benchmarking. If your code runs for many
seconds, you might want to skip this test and set this to 0.

=item * module_startup (bool)

=item * code_startup (bool)

=item * precision (float)

Precision to pass to Benchmark::Dumb. Default is 0. Can be overriden via
C<--precision> (CLI). takes precedence over C<default_precision>.

=item * default_precision (float)

(DEPRECATED)

Precision to pass to Benchmark::Dumb. Default is 0. Can be overriden via
C<--precision> (CLI).

=item * module_startup_precision (float)

Precision to pass to Benchmark::Dumb, when running benchmark in module_startup
mode. Default is from C<precision> or C<default_precision>. Can be overriden
with C<--precision> (CLI).

=item * result (any)

Like per-dataset C<result> property, which you normally should use instead of
this. But this property can be used when a scenario does not have any dataset.

=item * with_args_size (bool)

Show the size of the item code's arguments. Size is measured using
L<Devel::Size>. The measurement is done once per item when it is testing the
code. See also: C<with_result_size>.

=item * with_result_size (bool)

Show the size of the item code's return value. Size is measured using
L<Devel::Size>. The measurement is done once per item when it is testing the
code. See also: C<with_args_size>.

=item * with_process_size (bool)

Include some memory statistics in each item's result. This currently only works
on Linux because the measurement is done by reading C</proc/PID/smaps>. Also,
since this is a per-process information, to get this information each item's
code will be run by dumping the code (using L<B::Deparse>) into a temporary
file, then running the file (once per item, after the item's code is completed)
using a new perl interpreter process. This is done to get a measurement on a
clean process that does not load Bencher itself or the other items. This also
means that not all code will work: all the caveats in L</"MULTIPLE PERLS AND
MULTIPLE MODULE VERSIONS"> apply. In short, all outside data will not be
available for the code.

Also, this information normally does not make sense for external command
participants, because what is measured is the memory statistics of the perl
process itself, not the external command's processes.

=item * capture_stdout (bool)

Useful for silencing command/code that outputs stuffs to stdout. Note that
output capturing might affect timings if your benchmark code outputs a lot of
stuffs. See also: C<capture_stderr>.

=item * capture_stderr (bool)

Useful for silencing command/code that outputs stuffs to stderr. Note that
output capturing might affect timings if your benchmark code outputs a lot of
stuffs. See also: C<capture_stdout>.

=item * extra_modules (array of str)

You can specify extra modules to load here before benchmarking. The modules and
their versions will be listed in the result metadata under
C<func.module_versions>, for extra information. An example to put here are
modules that contain/produce datasets that get benchmarked, because the data
might differ from version to version.

=item * env_hashes (array of hash)

With this property, you can permute multiple sets of environment variables.
Suppose you want to benchmark each participant when running under environment
variables FOO=0, FOO=1, and FOO=2. You can specify:

 env_hashes => [
     {FOO=>0},
     {FOO=>1},
     {FOO=>2},
 ]

=item * runner (str)

Set which runner to run the benchmark with. Either C<Benchmark::Dumb> (the
default), C<Benchmark> (C<Benchmark.pm>, to get Benchmark.pm-style output), or
C<Benchmark::Dumb::SimpleTime> (to be able to run a code with only 1 or 2
iterations without warning, suitable if your code that runs for at least a few
seconds and you don't want to wait for too long).

=item * on_failure (str, "skip"|"die")

For a command participant, failure means non-zero exit code. For a Perl-code
participant, failure means Perl code dies or (if expected result is specified)
the result is not equal to the expected result.

The default is "die". When set to "skip", will first run the code of each item
before benchmarking and trap command failure/Perl exception and if that happens,
will "skip" the item.

Can be overriden in the CLI with C<--on-failure> option.

=item * on_result_failure (str, "skip"|"die"|"warn")

This is like C<on_failure> except that it specifically refer to the failure of
item's result not being equal to expected result.

The default is the value of C<on_failure>.

There is an extra choice of `warn` for this type of failure, which is to print a
warning to STDERR and continue.

Can be overriden in the CLI with C<--on-result-failure> option.

=item * before_parse_scenario (code)

If specified, then this code will be called before parsing scenario. Code will
be given hash argument with the following keys: C<hook_name> (str, set to
C<before_gen_items>), C<scenario> (hash, unparsed scenario), C<stash> (hash,
which you can use to pass data between hooks).

=item * before_parse_participants (code)

If specified, then this code will be called before parsing/normalizing
participants from scenario. Code will be given hash argument with the following
keys: C<hook_name>, C<scenario>, C<stash>.

You can use this hook to, e.g.: generate participants dynamically.

=item * before_parse_datasets (code)

If specified, then this code will be called before parsing/normalizing datasets
from scenario. Code will be given hash argument with the following keys:
C<hook_name>, C<scenario>, C<stash>.

You can use this hook to, e.g.: generate datasets dynamically.

=item * after_parse_scenario (code)

If specified, then this code will be called after parsing scenario. Code will be
given hash argument with the following keys: C<hook_name>, C<scenario> (hash,
parsed scenario), C<stash>.

=item * before_gen_items (code)

If specified, then this code will be called before generating items. Code will
be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>.

You can use this hook to, e.g.: modify datasets/participants before being
permuted into items.

=item * before_bench (code)

If specified, then this code will be called before starting the benchmark. Code
will be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>.

=item * before_test_item (code)

If specified, then this code will be called before testing each item's code.
Code will be given hash argument with the following keys: C<hook_name>,
C<scenario>, C<stash>, C<item> (itself a hash containing the following keys:
C<_name>, C<seq>, C<permute>).

=item * after_test_item (code)

If specified, then this code will be called after testing each item's code. Code
will be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>, C<item> (itself a hash containing the following keys: C<_name>,
C<seq>, C<permute>, C<_result>).

Item's code result can be accessed in C<_result> in C<item> hash.

The hook is expected to return false (0 or '') or a string which will be
interpreted as error message. Thus, this hook can be used to force error during
an item's test. The hook can be used to check that the item's code has executed
correctly by checking other side effects aside from the return in C<_result>.

=item * after_bench (code)

If specified, then this code will be called after completing benchmark. Code
will be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>, C<result> (array, enveloped result).

You can use this hook to, e.g.: do some custom formatting/modification to the
result.

=item * before_return (code)

If specified, then this code will be called before displaying/returning the
result. Code will be given hash argument with the following keys: C<hook_name>,
C<scenario>, C<stash>, C<result>.

You can use this hook to, e.g.: modify the result in some way.

=back

=head1 USING THE BENCHER COMMAND-LINE TOOL

=head2 Running benchmark

=head2 Running benchmark in code startup mode

Code startup mode can be activated either by specifying C<--code-startup> option
from the command-line, or by setting C<code_startup> property to true in the
scenario.

In this mode, instead of running participant's perl code, it runs a perl
command:

 perl -e 'YOUR_PERL_CODE'

or if there are modules to be loaded:

 perl -MModule1 -MModule2 ... -e 'YOUR_PERL_CODE'

and then comparing the time with the baseline:

 perl -e1

and measure the startup overhead of each code.

See also C<module_startup> mode.

=head2 Running benchmark in module startup mode

Module startup mode can be activated either by specifying C<--module-startup>
option from the command-line, or by setting C<module_startup> property to true
in the scenario.

In this mode, instead of running each participant's code, module name will be
extracted from each participant and this will be benchmarked instead:

 perl -MModule1 -e1
 perl -MModule2 -e1
 ...
 perl -e1 ;# the baseline, for comparison

Basically, this mode tries to measure the startup overhead of each module in
isolation.

Module name can be extracted from a participant if a participant specifies
C<module> or C<fcall_template> or C<modules>. When a participant does not
contain any module name, it will be skipped.

=head1 MULTIPLE PERLS AND MULTIPLE MODULE VERSIONS

Bencher can be instructed to run benchmark items against multiple perl
installations, as well as multiple versions of a module.

Bencher uses L<perlbrew> to get the list of available perl installations, so you
need to install perlbrew and brew some perls first.

To run against multiple versions of a module, specify the module name in
C<--multimodver> then add one or more library include paths using C<-I>. The
include paths need to contain different versions of the module.

B<Caveats.> Here is how benchmarking against multiple perls and module versions
currently works. Bencher first prepares a new scenario based on the input
scenario. But the new scenario contains benchmark items that has been permuted
and where the code template has been converted into actual Perl code (a
coderef). The new scenario along with the Perl codes in it will be dumped using
L<Data::Dmp> (which can deparse code) into a temporary file. A new Bencher
process is then started using the appropriate perl interpreter, runs the
scenario, and returns the result as JSON. The original Bencher process then
collects and combines the per-interpreter results into the final result.

Due to the above way of working, there are some caveats. First, code that
contains closures won't work properly because the original variables that the
code can see are no longer available in the new process. Also, some scenarios
prepare data in a hook like in the C<before_bench> or C<before_gen_items> hook.
This also won't work because the new scenario that gets dumped into temporary
file currently has all the hooks stripped first.

So in principle, to enable a benchmark item to be run against multiple perls or
module versions, make the code self-sufficient. Do not depend on an outside
variable. Instead, only depend on the variables in the dataset.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<bencher>

C<Bencher::Manual::*>

B<BenchmarkAnything>. There are lot of overlaps of goals between Bencher and
this project. I hope to reuse or interoperate parts of BenchmarkAnything, e.g.
storing Bencher results in a BenchmarkAnything storage backend, sending Bencher
results to a BenchmarkAnything HTTP server, and so on.

L<Benchmark>, L<Benchmark::Dumb> (L<Dumbbench>)

C<Bencher::Scenario::*> for examples of scenarios.

An article about Bencher written in 2016, L<https://perladvent.org/2016/2016-12-03.html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
