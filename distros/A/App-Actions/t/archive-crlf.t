use strict;
use warnings;
use Test::Most;
use Config;
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions::Process;

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $script = File::Spec->catfile($root, 't', 'bin', 'check-archive-crlf');

BAIL_OUT("cannot find '$script'; the archive audit is missing from the distribution")
    unless -f $script;

sub write_bytes {
    my ($path, $bytes) = @_;

    my $parent = dirname($path);
    make_path($parent) unless -d $parent;

    open my $handle, '>:raw', $path
        or die "cannot write '$path': $!\n";
    print {$handle} $bytes
        or die "cannot write '$path': $!\n";
    close $handle
        or die "cannot write '$path': $!\n";

    return;
}

sub read_bytes {
    my ($path) = @_;

    open my $handle, '<:raw', $path
        or die "cannot read '$path': $!\n";
    my $bytes = do { local $/; <$handle> };
    close $handle
        or die "cannot read '$path': $!\n";

    return defined $bytes ? $bytes : '';
}

# A minimal archive: enough CRLF source files to pass the completeness guard,
# a CRLF source file at the top level, the generated files make dist writes
# with LF, and a binary file that has a NUL and an LF but no line endings to
# check.  Its MANIFEST names every file the tree holds, because the audit
# compares the two lists.  The named variations replace the source file or add
# the failure the audit exists to catch.
sub make_archive {
    my (%options) = @_;

    my $directory = tempdir(CLEANUP => 1);

    write_bytes(
        File::Spec->catfile($directory, 'src', "file-$_.txt"),
        "source line $_\r\n",
    ) for 1 .. 40;

    write_bytes(
        File::Spec->catfile($directory, 'README.md'),
        $options{normalised} ? "source line\n" : "source line\r\n",
    );

    write_bytes(File::Spec->catfile($directory, 'META.yml'), "meta: yaml\n");
    write_bytes(File::Spec->catfile($directory, 'META.json'), "{\"meta\":1}\n");
    write_bytes(File::Spec->catfile($directory, 'asset.bin'), "binary\0with\n");

    write_bytes(File::Spec->catfile($directory, 'CR.txt'), "bare\r")
        if $options{bare_cr};

    my @listed = (
        'MANIFEST',
        'README.md',
        'asset.bin',
        map { "src/file-$_.txt" } 1 .. 40,
    );
    push @listed, 'CR.txt' if $options{bare_cr};
    push @listed, $options{missing} if defined $options{missing};
    write_bytes(
        File::Spec->catfile($directory, 'MANIFEST'),
        join('', map { "$_\n" } @listed),
    );

    if (defined $options{extra}) {
        write_bytes(
            File::Spec->catfile($directory, split m{/}, $options{extra}),
            "extra line\r\n",
        );
    }

    if (defined $options{missing}) {
        my $path = File::Spec->catfile(
            $directory, split m{/}, $options{missing},
        );
        unlink $path or die "cannot remove '$path': $!\n";
    }

    return $directory;
}

sub audit {
    my ($directory) = @_;

    my ($output, $status) = App::Actions::Process::capture(
        [ $^X, $script, $directory ],
        merge_stderr => 1,
    );

    $output =~ s/\r\n/\n/g;

    return ($output, $status);
}

{
    my ($output, $status) = audit(make_archive());

    is($status, 0,
        'the audit accepts CRLF sources with LF in the generated files');
    like(
        $output,
        qr/^verified 41 source files keep CRLF in the archive$/m,
        'the audit counts the source files and reports them',
    );
}

{
    my ($output, $status) = audit(make_archive(normalised => 1));

    isnt($status, 0, 'the audit refuses a source file normalised to LF');
    like(
        $output,
        qr/^check-archive-crlf: archive line endings were normalised to LF: README\.md$/m,
        'the failure names the file whose line endings changed',
    );
}

{
    my ($output, $status) = audit(make_archive(bare_cr => 1));

    isnt($status, 0, 'the audit refuses a source file without CRLF');
    like(
        $output,
        qr/^check-archive-crlf: archive source files without CRLF: CR\.txt$/m,
        'the failure names the file with no CRLF ending',
    );
}

{
    my ($output, $status) = audit(
        make_archive(missing => 'src/file-40.txt'),
    );

    isnt($status, 0, 'the audit refuses an archive missing a file MANIFEST lists');
    like(
        $output,
        qr/^check-archive-crlf: MANIFEST lists files missing from the archive: src\/file-40\.txt$/m,
        'the failure names the file the archive is missing',
    );
}

{
    my ($output, $status) = audit(make_archive(extra => 'notes.txt'));

    isnt($status, 0, 'the audit refuses a file MANIFEST does not list');
    like(
        $output,
        qr/^check-archive-crlf: the archive has files MANIFEST does not list: notes\.txt$/m,
        'the failure names the file the archive added',
    );
}

{
    my ($output, $status) = audit(tempdir(CLEANUP => 1));

    isnt($status, 0, 'the audit refuses an archive with no source files');
    like(
        $output,
        qr/^check-archive-crlf: the archive has no source files to check$/m,
        'the failure says why an empty archive cannot pass',
    );
}

# The synthetic archives above test the audit's rules cheaply.  The release
# archive is made by "make dist", which walks MANIFEST, copies the distribution
# directory, tars it and gzips the tar.  Building that archive from a CRLF
# checkout unpacks the same bytes a release publishes, so a tar or gzip step
# that normalises line endings - or a MANIFEST entry the archive does not
# survive - fails here rather than only in the CRLF CI job.
sub find_program {
    my ($name) = @_;

    return unless defined $name && length $name;

    my @names = ($name);
    if ($^O eq 'MSWin32') {
        my $extensions = $ENV{PATHEXT} || '.COM;.EXE;.BAT;.CMD';
        push @names, map { $name . $_ } split /;/, $extensions;
    }

    for my $candidate (@names) {
        if (File::Spec->file_name_is_absolute($candidate)) {
            return $candidate if -x $candidate;
            next;
        }

        for my $directory (File::Spec->path) {
            my $path = File::Spec->catfile($directory, $candidate);
            return $path if -x $path;
        }
    }

    return;
}

# Copy exactly what MANIFEST ships, so the distribution is built from the same
# list as the release and not from whatever happens to be in the checkout.
sub copy_manifest_tree {
    my ($from, $to) = @_;

    my $manifest = File::Spec->catfile($from, 'MANIFEST');
    open my $listing, '<', $manifest
        or die "cannot read '$manifest': $!\n";

    my @files;
    while (my $line = <$listing>) {
        next if $line =~ /\A#/;

        my ($file) = split /\s+/, $line;
        next unless defined $file && length $file;

        my $source = File::Spec->catfile($from, split m{/}, $file);
        my $target = File::Spec->catfile($to, split m{/}, $file);
        die "MANIFEST lists '$file', which is not in the tree\n"
            unless -f $source;

        make_path(dirname($target));
        copy($source, $target)
            or die "cannot copy '$source' to '$target': $!\n";
        chmod((stat $source)[2] & 07777, $target)
            or die "cannot set the mode of '$target': $!\n";

        push @files, $file;
    }
    close $listing;

    return \@files;
}

sub convert_text_files_to_crlf {
    my ($directory, $files) = @_;

    my $converted = 0;
    for my $relative (@$files) {
        my $path = File::Spec->catfile($directory, split m{/}, $relative);
        my $bytes = read_bytes($path);
        next if index($bytes, "\0") >= 0;

        (my $crlf = $bytes) =~ s/\r?\n/\r\n/g;
        next if $crlf eq $bytes;

        write_bytes($path, $crlf);
        $converted++;
    }

    return $converted;
}

sub files_with_bare_lf {
    my ($directory, $files) = @_;

    my @bare;
    for my $relative (@$files) {
        my $path = File::Spec->catfile($directory, split m{/}, $relative);
        my $bytes = read_bytes($path);
        next if index($bytes, "\0") >= 0;

        push @bare, $relative if $bytes =~ /(?<!\r)\n/;
    }

    return @bare;
}

sub run_in {
    my ($directory, @command) = @_;

    my $original = File::Spec->rel2abs(File::Spec->curdir);
    chdir $directory or die "cannot change to '$directory': $!\n";

    my ($output, $status, $error);
    my $ran = eval {
        ($output, $status) = App::Actions::Process::capture(
            \@command, merge_stderr => 1,
        );
        1;
    };
    $error = $@ unless $ran;

    chdir $original or die "cannot return to '$original': $!\n";
    die $error if defined $error;

    return ($output, $status);
}

sub only_directory {
    my ($parent) = @_;

    opendir my $handle, $parent
        or die "cannot read '$parent': $!\n";
    my @directories = sort grep {
        $_ ne '.' && $_ ne '..'
            && -d File::Spec->catdir($parent, $_)
    } readdir $handle;
    closedir $handle;

    return @directories == 1
        ? File::Spec->catdir($parent, $directories[0])
        : undef;
}

# Makefile.PL uses gtar on darwin, so the archive is only built where the
# tar it names is available; extracting with the same command keeps the test
# honest about the step that produced the archive.
my $tar_name = $^O eq 'darwin' ? 'gtar' : 'tar';
my $make     = find_program($Config{make});
my $tar      = find_program($tar_name);
my $gzip     = find_program('gzip');

SKIP: {
    skip 'make, tar and gzip are needed to build and unpack a distribution', 1
        unless defined $make && defined $tar && defined $gzip;

    subtest 'a distribution built from a CRLF checkout' => sub {
        my $work = tempdir(
            'app-actions archive XXXX', TMPDIR => 1, CLEANUP => 1,
        );
        my $checkout = File::Spec->catdir($work, 'checkout');
        make_path($checkout);

        my $shipped = copy_manifest_tree($root, $checkout);
        cmp_ok(scalar @$shipped, '>', 40,
            'the checkout copy holds the files the distribution ships');

        my $converted = convert_text_files_to_crlf($checkout, $shipped);
        diag $converted
            ? "converted $converted text files to CRLF"
            : 'the checkout copy was already CRLF';
        is_deeply(
            [ files_with_bare_lf($checkout, $shipped) ],
            [],
            'every text file in the checkout copy is CRLF',
        );

        my ($configure_output, $configure_status) = run_in(
            $checkout, $^X, 'Makefile.PL',
        );
        is($configure_status, 0, 'the CRLF checkout generates a Makefile')
            or diag $configure_output;
        BAIL_OUT('the CRLF checkout could not generate a Makefile')
            if $configure_status;

        my ($dist_output, $dist_status) = run_in($checkout, $make, 'dist');
        is($dist_status, 0, 'make dist builds a distribution from the CRLF checkout')
            or diag $dist_output;
        BAIL_OUT('make dist failed in the CRLF checkout')
            if $dist_status;

        opendir my $directory, $checkout
            or die "cannot read '$checkout': $!\n";
        my @archives = sort grep {
            /\AApp-Actions-.*\.tar\.gz\z/
                && -f File::Spec->catfile($checkout, $_)
        } readdir $directory;
        closedir $directory;

        is(scalar @archives, 1, 'make dist writes one gzipped tarball');
        BAIL_OUT('make dist did not write exactly one tarball')
            unless @archives == 1;

        my $archive = File::Spec->catfile($checkout, $archives[0]);

        # make dist runs tar and then gzip.  Checking the compressed archive
        # with gzip and extracting it with tar's gzip support exercises both
        # steps on the bytes the release publishes; comparing every shipped
        # file with the CRLF checkout then proves neither step rewrote them.
        my $gzip_errors = File::Spec->catfile($work, 'gzip.stderr');
        my $gzip_status = App::Actions::Process::run(
            [ $gzip, '-t', $archive ],
            stdout => File::Spec->devnull,
            stderr => $gzip_errors,
        );
        is($gzip_status, 0, 'gzip accepts the archive make dist wrote')
            or diag(-s $gzip_errors ? read_bytes($gzip_errors) : '');
        BAIL_OUT('the distribution tarball is not valid gzip')
            if $gzip_status;

        my $unpacked = tempdir(
            'unpacked XXXX', DIR => $work, CLEANUP => 1,
        );
        my ($untar_output, $untar_status) = run_in(
            $work, $tar, '-xzf', $archive, '-C', $unpacked,
        );
        is($untar_status, 0, 'tar extracts the gzipped distribution')
            or diag $untar_output;
        BAIL_OUT('the distribution tarball could not be unpacked')
            if $untar_status;

        my $distribution = only_directory($unpacked);
        ok(defined $distribution,
            'the archive unpacks to one distribution directory');
        BAIL_OUT('the archive did not unpack to one distribution directory')
            unless defined $distribution;

        my ($audit_output, $audit_status) = audit($distribution);
        is($audit_status, 0,
            'the unpacked archive keeps CRLF in every source file');
        like(
            $audit_output,
            qr/^verified \d+ source files keep CRLF in the archive$/m,
            'the audit reports the source files it found in the real archive',
        );

        my @different;
        for my $relative (@$shipped) {
            next if $relative =~ m{\A(?:MANIFEST|META\.(?:yml|json))\z};

            my $source = File::Spec->catfile(
                $checkout, split m{/}, $relative,
            );
            my $archived = File::Spec->catfile(
                $distribution, split m{/}, $relative,
            );

            if (!-f $archived) {
                push @different, "$relative (missing)";
                next;
            }

            push @different, $relative
                if read_bytes($source) ne read_bytes($archived);
        }

        is_deeply(
            \@different,
            [],
            'tar and gzip preserve every shipped source file byte for byte',
        );

        # The audit passing above only proves something if it fails on the
        # archive this test is meant to catch.  Normalise one source file to
        # LF, rebuild the same real distribution, and check that the audit
        # rejects it and names the file the tar or gzip step changed.
        my $normalised = File::Spec->catfile(
            $checkout, qw(lib App Actions Cache.pm),
        );
        my $source = read_bytes($normalised);
        (my $lf = $source) =~ s/\r\n/\n/g;
        isnt($lf, $source,
            'the negative control has a CRLF source file to normalise');
        write_bytes($normalised, $lf);

        unlink $archive
            or die "cannot remove '$archive' before rebuilding it: $!\n";
        my ($broken_dist_output, $broken_dist_status) = run_in(
            $checkout, $make, 'dist',
        );
        is($broken_dist_status, 0,
            'make dist rebuilds the archive after the source changes')
            or diag $broken_dist_output;
        BAIL_OUT('the distribution could not be rebuilt with a normalised source')
            if $broken_dist_status;

        my $broken_unpacked = tempdir(
            'unpacked normalised XXXX', DIR => $work, CLEANUP => 1,
        );
        my ($broken_untar_output, $broken_untar_status) = run_in(
            $work, $tar, '-xzf', $archive, '-C', $broken_unpacked,
        );
        is($broken_untar_status, 0,
            'tar extracts the distribution with the normalised source')
            or diag $broken_untar_output;
        BAIL_OUT('the archive with a normalised source could not be unpacked')
            if $broken_untar_status;

        my $broken_distribution = only_directory($broken_unpacked);
        ok(defined $broken_distribution,
            'the archive with the normalised source unpacks to one directory');
        BAIL_OUT('the normalised archive did not unpack to one directory')
            unless defined $broken_distribution;

        my ($broken_audit_output, $broken_audit_status)
            = audit($broken_distribution);
        isnt($broken_audit_status, 0,
            'the audit refuses a real archive whose source was normalised to LF');
        like(
            $broken_audit_output,
            qr/^check-archive-crlf: archive line endings were normalised to LF: .*?\blib\/App\/Actions\/Cache\.pm\b/m,
            'the audit names the source file the archive normalised',
        );
    };
}

done_testing;
