# t/001-print-file.t
use strict;
use warnings;
use CPAN::Cpanorg::Auxiliary qw(print_file);
use Carp;
use Cwd;
use File::Spec;
use File::Path 2.15 qw(make_path);
use File::Temp qw(tempdir);
use LWP::Simple qw(get);
use Test::More;

my $perl_dist_url = "http://search.cpan.org/api/dist/perl";
my $cpan_json = get($perl_dist_url);
my $filename = 'perl_version_all.json';
my $cwd = cwd();

{
    my $tdir = tempdir(CLEANUP => 1);
    my $datadir = File::Spec->catdir($tdir, 'data');
    my $file_expected = File::Spec->catfile($datadir, $filename);
    my @created = make_path($datadir, { mode => 0711 });
    ok(@created, "Able to create $datadir for testing");
    chdir $tdir or croak "Unable to change to $tdir for testing";
    my $rv = print_file( $filename, $cpan_json );
    ok($rv, "print_file() returned true value");
    ok(-f $file_expected, "$file_expected was created");
    chdir $cwd or croak "Unable to change back to $cwd";
}

{
    my $tdir = tempdir(CLEANUP => 1);
    chdir $tdir or croak "Unable to change to $tdir for testing";
    local $@;
    eval { my $rv = print_file( $filename, $cpan_json ); };
    like($@, qr/data\/$filename/s,
        "Got expected exception: absence of 'data/' subdirectory");
}

done_testing;
