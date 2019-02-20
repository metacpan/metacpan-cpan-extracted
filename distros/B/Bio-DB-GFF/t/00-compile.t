use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 50 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Bio/DB/GFF.pm',
    'Bio/DB/GFF/Adaptor/berkeleydb.pm',
    'Bio/DB/GFF/Adaptor/berkeleydb/iterator.pm',
    'Bio/DB/GFF/Adaptor/biofetch.pm',
    'Bio/DB/GFF/Adaptor/biofetch_oracle.pm',
    'Bio/DB/GFF/Adaptor/dbi.pm',
    'Bio/DB/GFF/Adaptor/dbi/caching_handle.pm',
    'Bio/DB/GFF/Adaptor/dbi/iterator.pm',
    'Bio/DB/GFF/Adaptor/dbi/mysql.pm',
    'Bio/DB/GFF/Adaptor/dbi/mysqlcmap.pm',
    'Bio/DB/GFF/Adaptor/dbi/mysqlopt.pm',
    'Bio/DB/GFF/Adaptor/dbi/oracle.pm',
    'Bio/DB/GFF/Adaptor/dbi/pg.pm',
    'Bio/DB/GFF/Adaptor/dbi/pg_fts.pm',
    'Bio/DB/GFF/Adaptor/memory.pm',
    'Bio/DB/GFF/Adaptor/memory/feature_serializer.pm',
    'Bio/DB/GFF/Adaptor/memory/iterator.pm',
    'Bio/DB/GFF/Aggregator.pm',
    'Bio/DB/GFF/Aggregator/alignment.pm',
    'Bio/DB/GFF/Aggregator/clone.pm',
    'Bio/DB/GFF/Aggregator/coding.pm',
    'Bio/DB/GFF/Aggregator/gene.pm',
    'Bio/DB/GFF/Aggregator/match.pm',
    'Bio/DB/GFF/Aggregator/none.pm',
    'Bio/DB/GFF/Aggregator/orf.pm',
    'Bio/DB/GFF/Aggregator/processed_transcript.pm',
    'Bio/DB/GFF/Aggregator/so_transcript.pm',
    'Bio/DB/GFF/Aggregator/transcript.pm',
    'Bio/DB/GFF/Aggregator/ucsc_acembly.pm',
    'Bio/DB/GFF/Aggregator/ucsc_ensgene.pm',
    'Bio/DB/GFF/Aggregator/ucsc_genscan.pm',
    'Bio/DB/GFF/Aggregator/ucsc_refgene.pm',
    'Bio/DB/GFF/Aggregator/ucsc_sanger22.pm',
    'Bio/DB/GFF/Aggregator/ucsc_sanger22pseudo.pm',
    'Bio/DB/GFF/Aggregator/ucsc_softberry.pm',
    'Bio/DB/GFF/Aggregator/ucsc_twinscan.pm',
    'Bio/DB/GFF/Aggregator/ucsc_unigene.pm',
    'Bio/DB/GFF/Featname.pm',
    'Bio/DB/GFF/Feature.pm',
    'Bio/DB/GFF/Homol.pm',
    'Bio/DB/GFF/RelSegment.pm',
    'Bio/DB/GFF/Segment.pm',
    'Bio/DB/GFF/Typename.pm'
);

my @scripts = (
    'bin/bp_bulk_load_gff',
    'bin/bp_das_server',
    'bin/bp_fast_load_gff',
    'bin/bp_genbank2gff',
    'bin/bp_generate_histogram',
    'bin/bp_load_gff',
    'bin/bp_meta_gff'
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


