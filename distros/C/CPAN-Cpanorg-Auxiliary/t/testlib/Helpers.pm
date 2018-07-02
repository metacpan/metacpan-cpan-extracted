package Helpers;
use 5.14.0;
use warnings;
use parent 'Exporter';
our @EXPORT_OK = qw(basic_test_setup);
use Carp;
use File::Copy::Recursive::Reduced qw(dircopy);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

# Performs 8 tests
sub basic_test_setup {
    my $cwd = shift;
    my $tdir = tempdir(CLEANUP => 1);
    my $from_mockdir = File::Spec->catdir($cwd, 't', 'mockserver');
    my @created = dircopy($from_mockdir, $tdir);
    ok(@created, "Copied directories and files for testing");

    my %dirs_required = (
        CPANdir     => [ $tdir, qw| CPAN | ],
        srcdir      => [ $tdir, qw| CPAN src | ],
        fivedir     => [ $tdir, qw| CPAN src 5.0 | ],
        authorsdir  => [ $tdir, qw| CPAN authors | ],
        iddir       => [ $tdir, qw| CPAN authors id | ],
        contentdir  => [ $tdir, qw| content | ],
        datadir     => [ $tdir, qw| data | ],
    );
    for my $el (keys %dirs_required) {
        my $dir = File::Spec->catdir(@{$dirs_required{$el}});
        ok(-d $dir, "Created directory '$dir' for testing");
    }
    return $tdir;
}

1;

