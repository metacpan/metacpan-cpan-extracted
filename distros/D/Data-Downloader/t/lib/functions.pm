package t::lib::functions;

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader::DB;
use File::Basename;
use File::Path;
use File::Slurp;
use File::Spec::Functions qw(canonpath catfile catdir curdir rel2abs);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::More;

use base 'Exporter';


# Exported functions
our @EXPORT = qw(ok_system ok_not_system
		 scratch_dir set_path t_copy test_cleanup);

# Test system command
sub ok_system {
    my $cmd = shift;
    ok(system($cmd) == 0, $cmd)
	or diag "$cmd failed : $? ${^CHILD_ERROR_NATIVE}";
}

sub ok_not_system {
    my $cmd = shift;
    ok(system($cmd) != 0, $cmd) or diag "$cmd exited with $?";
}

# Create scratch directory for testing
sub scratch_dir {

    my %opts = @_;

    my $scratchdir;
    if (my $tmpdir = $ENV{DATA_DOWNLOADER_TMPDIR}) {
	$scratchdir = tempdir("dado_test_$<_XXXXXX",
			       DIR => $tmpdir, UNLINK => 0, %opts);
    } else {
	$scratchdir = catdir($Bin, 'dado_test');
    }
    unless (-d $scratchdir) {
	mkpath($scratchdir) or BAIL_OUT "Unable to make dir $scratchdir: $!";
    }
    return rel2abs($scratchdir);

}

# Set path for scripts
sub set_path {

    my $perldir = dirname `which perl`;
    $ENV{PATH} = "$Bin/../blib/script:$perldir:/usr/local/bin:/usr/bin:/bin";
    warn "# modifying PERL5OPT for tests ($ENV{PERL5OPT})" if $ENV{PERL5OPT};
    $ENV{PERL5OPT} = "-Mblib=$Bin/../blib";

    return $ENV{PATH};

}

# Copy file to t directory and modify it
sub t_copy {

    my $old_file = shift(@_) or BAIL_OUT "Missing old file in t_copy()";
    my $from     = shift(@_) or BAIL_OUT "Missing 'from' string in t_copy()";
    my $to       = shift(@_) || scratch_dir();

    my $new_file = rel2abs(catfile($Bin, basename($old_file)));

    my $content = read_file($old_file)
	or BAIL_OUT "Unable to read old file $old_file: $!";
    $content =~ s{$from}{$to}g;
    write_file($new_file, $content)
	or BAIL_OUT "Unable to write new file $new_file: $!";;

    return $new_file;

}

# Clean up test directories and database files
sub test_cleanup {
    my ( $dir, $db ) = @_;

    rmtree( $dir, {
            keep_root => ( $ENV{DATA_DOWNLOADER_TMPDIR} ? 0 : 1 ),
            safe => 1
        }
    ) if ( $dir && -d $dir );

    $db ||= Data::Downloader::DB->new();
    my $db_file = $db->database;
    return 1 if $db_file eq ':memory:';
    foreach my $file ( $db_file, $db_file . '.dado_stats_lock' ) {
        unlink($file) if -e $file;
    }

    return 1;
}

1;
