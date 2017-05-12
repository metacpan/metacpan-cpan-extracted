use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 28;

my @module_files = (
    'Bio/MLST/Blast/BlastN.pm',
    'Bio/MLST/Blast/Database.pm',
    'Bio/MLST/CDC/Convert.pm',
    'Bio/MLST/Check.pm',
    'Bio/MLST/CheckMultipleSpecies.pm',
    'Bio/MLST/CompareAlleles.pm',
    'Bio/MLST/DatabaseSettings.pm',
    'Bio/MLST/Databases.pm',
    'Bio/MLST/Download/Database.pm',
    'Bio/MLST/Download/Databases.pm',
    'Bio/MLST/Download/Downloadable.pm',
    'Bio/MLST/FilterAlleles.pm',
    'Bio/MLST/NormaliseFasta.pm',
    'Bio/MLST/OutputFasta.pm',
    'Bio/MLST/ProcessFasta.pm',
    'Bio/MLST/SearchForFiles.pm',
    'Bio/MLST/SequenceType.pm',
    'Bio/MLST/Spreadsheet/File.pm',
    'Bio/MLST/Spreadsheet/Row.pm',
    'Bio/MLST/Types.pm',
    'Bio/MLST/Validate/Executable.pm',
    'Bio/MLST/Validate/File.pm',
    'Bio/MLST/Validate/Resource.pm'
);

my @scripts = (
    'bin/download_fasta_database',
    'bin/download_mlst_databases',
    'bin/get_emm_sequence_type',
    'bin/get_sequence_type'
);

# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

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
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


