#!perl

=head1 NAME

pod-source.t - Tests that the POD in the I<source files> is clean
enough to display on CPAN

Just delete this test if you don't plan on publishing your module on
the CPAN.

=cut

## Note that there is a lot of code here that is just duplicated from
## pod.t. Oh well.

use strict;
use Test::More;
use File::Spec::Functions;
use File::Find;

plan(skip_all => "Test::Pod 1.14 required for testing POD"), exit unless
    eval "use Test::Pod 1.14; 1";
plan(skip_all => "Pod::Checker required for testing POD"), exit unless
    eval "use Pod::Checker; 1";
plan(skip_all => "Pod::Text required for testing POD"), exit unless
    eval "use Pod::Text; 1";

my @files = Test::Pod::all_pod_files(glob("*.pm"), "lib");
plan(skip_all => "no POD (yet?)"), exit if ! @files;

plan( tests => 3 * scalar (@files) );

my $out = catfile(qw(t pod-out.tmp));

sub podcheck_ok {
    my ($file, @testcomment) = @_;
    my $checker = new My::Pod::Checker;
    $checker->parse_from_file($file, \*STDERR);
    if ((my $errors = $checker->num_errors) > 0) {
        diag("$errors errors in podchecker");
        &fail(@testcomment);
    } else {
        &pod_file_ok($file, @testcomment);
    }
    return;

    { package My::Pod::Checker; use base "Pod::Checker"; }

    sub My::Pod::Checker::poderror {
        my $self = shift;
        my %opts = %{$_[0]};
        diag(sprintf("%s: %s (file %s, line %d)",
                     @opts{qw(-severity -msg -file -line)}))
            unless ($opts{-msg} =~ m/empty section/);
        local $self->{-quiet} = 1;
        return $self->Pod::Checker::poderror(@_);
    }
}

foreach my $file ( @files ) {
    podcheck_ok($file, "$file");

=pod

We also check that the internal and test suite documentations are
B<not> visible in the POD (coz this just looks funny on CPAN)

=cut

    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($file, $out);
    my $result = read_file($out);
    unlike($result, qr/^TEST SUITE/m,
           "Test suite documentation is podded out");
    unlike($result, qr/^INTERNAL/,
           "Internal documentation is podded out");
}

unlink($out);

=head2 read_file

Same foo as L<File::Slurp/read_file>, sans the dependency on same.

=cut

sub read_file {
    my ($path) = @_;
    local *FILE;
    open FILE, $path or die $!;
    return wantarray ? <FILE> : join("", <FILE>);
}
