use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 79 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/CSVUtils.pm',
    'App/CSVUtils/csv2td.pm',
    'App/CSVUtils/csv2vcf.pm',
    'App/CSVUtils/csv_add_fields.pm',
    'App/CSVUtils/csv_avg.pm',
    'App/CSVUtils/csv_concat.pm',
    'App/CSVUtils/csv_convert_to_hash.pm',
    'App/CSVUtils/csv_csv.pm',
    'App/CSVUtils/csv_delete_fields.pm',
    'App/CSVUtils/csv_dump.pm',
    'App/CSVUtils/csv_each_row.pm',
    'App/CSVUtils/csv_fill_template.pm',
    'App/CSVUtils/csv_freqtable.pm',
    'App/CSVUtils/csv_gen.pm',
    'App/CSVUtils/csv_get_cells.pm',
    'App/CSVUtils/csv_grep.pm',
    'App/CSVUtils/csv_info.pm',
    'App/CSVUtils/csv_intrange.pm',
    'App/CSVUtils/csv_list_field_names.pm',
    'App/CSVUtils/csv_lookup_fields.pm',
    'App/CSVUtils/csv_map.pm',
    'App/CSVUtils/csv_munge_field.pm',
    'App/CSVUtils/csv_munge_row.pm',
    'App/CSVUtils/csv_pick_fields.pm',
    'App/CSVUtils/csv_pick_rows.pm',
    'App/CSVUtils/csv_replace_newline.pm',
    'App/CSVUtils/csv_select_fields.pm',
    'App/CSVUtils/csv_select_rows.pm',
    'App/CSVUtils/csv_setop.pm',
    'App/CSVUtils/csv_shuf_fields.pm',
    'App/CSVUtils/csv_shuf_rows.pm',
    'App/CSVUtils/csv_sort_fields.pm',
    'App/CSVUtils/csv_sort_rows.pm',
    'App/CSVUtils/csv_split.pm',
    'App/CSVUtils/csv_sum.pm',
    'App/CSVUtils/csv_transpose.pm',
    'App/CSVUtils/csv_uniq.pm'
);

my @scripts = (
    'script/csv-add-fields',
    'script/csv-avg',
    'script/csv-concat',
    'script/csv-convert-to-hash',
    'script/csv-csv',
    'script/csv-delete-fields',
    'script/csv-dump',
    'script/csv-each-row',
    'script/csv-fill-template',
    'script/csv-freqtable',
    'script/csv-gen',
    'script/csv-get-cells',
    'script/csv-grep',
    'script/csv-info',
    'script/csv-intrange',
    'script/csv-list-field-names',
    'script/csv-lookup-fields',
    'script/csv-map',
    'script/csv-munge-field',
    'script/csv-munge-row',
    'script/csv-pick',
    'script/csv-pick-fields',
    'script/csv-pick-rows',
    'script/csv-replace-newline',
    'script/csv-select-fields',
    'script/csv-select-rows',
    'script/csv-setop',
    'script/csv-shuf',
    'script/csv-shuf-fields',
    'script/csv-shuf-rows',
    'script/csv-sort',
    'script/csv-sort-fields',
    'script/csv-sort-rows',
    'script/csv-split',
    'script/csv-sum',
    'script/csv-transpose',
    'script/csv-uniq',
    'script/csv2ltsv',
    'script/csv2td',
    'script/csv2tsv',
    'script/csv2vcf',
    'script/tsv2csv'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


