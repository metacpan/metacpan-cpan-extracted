# -*- perl -*-

# t/002_identify_distros.t

use 5.010;
use CPAN::Mini::Visit::Simple;
use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempfile tempdir );
use IO::CaptureOutput qw( capture );
use Tie::File;

use Test::More;
require CPAN::Mini;
my $config_file = CPAN::Mini->config_file({});
if (! (defined $config_file and -e $config_file) ) {
    plan skip_all => 'No .minicpanrc located';
}
my %config = CPAN::Mini->read_config;
if (! $config{local}) {
    plan skip_all => "No 'local' setting in configuration file '$config_file'";
}
elsif (! (-d $config{local}) ) {
    plan skip_all => 'minicpan directory not located';
}
else {
    plan tests => 31;
}

my ( $self, $rv, @list, $phony_minicpan, $tdir, $id_dir );

$self = CPAN::Mini::Visit::Simple->new({});
isa_ok ($self, 'CPAN::Mini::Visit::Simple');

eval {
    $self->identify_distros_from_derived_list({});
};
like($@, qr/identify_distros_from_derived_list\(\) needs 'list' element/,
    "Got expected error message for absent 'list' element in hashref" );

eval {
    $self->identify_distros_from_derived_list({
        list => {},
    });
};
like($@, qr/Value of 'list' must be array reference/,
    "Got expected error message for bad 'list' value -- must be array ref" );

eval {
    $self->identify_distros_from_derived_list({
        list => [],
    });
};
like($@, qr/Value of 'list' must be non-empty/,
    "Got expected error message for bad 'list' value -- must be non-empty array ref" );

{
    $self = CPAN::Mini::Visit::Simple->new({});
    @list = qw(
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Alpha-Beta-0.01-tar.gz
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Gamma-Delta-0.02-tar.gz
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Epsilon-Zeta-0.03-tar.gz
    );
    eval {
        $self->identify_distros_from_derived_list({
            list => \@list,
            start_dir   => '/foo/bar',
        });
    };
    like($@,
        qr/Bad argument 'start_dir' provided to identify_distros_from_derived_list()/,
        "Got expected error message when calling identify_distros_from_derived_list() with 'start_dir'" );

    eval {
        $self->identify_distros_from_derived_list({
            list => \@list,
            pattern   => qr/foo\/bar/,
        });
    };
    like($@,
        qr/Bad argument 'pattern' provided to identify_distros_from_derived_list()/,
        "Got expected error message when calling identify_distros_from_derived_list() with 'pattern'" );
}

{
    $self = CPAN::Mini::Visit::Simple->new({});
    @list = qw(
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Alpha-Beta-0.01-tar.gz
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Gamma-Delta-0.02-tar.gz
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Epsilon-Zeta-0.03-tar.gz
    );
    eval {
        $self->identify_distros({
            list => \@list,
            start_dir   => '/foo/bar',
        });
    };
    like($@,
        qr/Bad argument 'list' provided to identify_distros()/,
        "Got expected error message when calling identify_distros with 'list'" );
}

{
    $self = CPAN::Mini::Visit::Simple->new({});
    @list = qw(
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Alpha-Beta-0.01-tar.gz
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Gamma-Delta-0.02-tar.gz
        /home/user/minicpan/authors/id/A/AA/AARDVARK/Epsilon-Zeta-0.03-tar.gz
    );
    ok( $self->identify_distros_from_derived_list({ list => \@list, }),
        "identify_distros_from_derived_list() returned true value" );

    my ($stdout, $stderr);
    capture(
        sub { $self->say_list(); },
        \$stdout,
        \$stderr,
    );
    my $seen = 0;
    foreach my $el (@list) {
        $seen++ if $stdout =~ m/$el/;
    }
    is( $seen, scalar(@list), "All distro names seen on STDOUT" );

    my %list_seen = map { $_ => 1 } @list;
    my ($fh, $tfile) = tempfile();
    $self->say_list( { file => $tfile } );
    my @lines;
    my $nonmatch = 0;
    tie @lines, 'Tie::File', $tfile or croak "Unable to tie to $tfile";
    my %lines_seen = map { $_ => 1 } @lines;
    untie @lines or croak "Unable to untie from $tfile";
    foreach my $j (keys %list_seen) {
        foreach my $k (keys %lines_seen) {
            $nonmatch++ unless $lines_seen{$j};
        }
    };
    is( $nonmatch, 0, "All distros printed to file" );

    eval {
        $self->say_list( [] );
    };
    like($@, qr/Argument must be hashref/,
        "Optional 'say_list()' argument must be a hashref" );

    eval {
        $self->say_list( { nofile => 'nothing' } );
    };
    like($@, qr/Need 'file' element in hashref/,
        "'say_list()' requires 'file' element in hashref" );
    unlink $tfile;
}

$self = CPAN::Mini::Visit::Simple->new({});
$phony_minicpan = '/foo/bar';
eval {
    $self->identify_distros({
        start_dir => $phony_minicpan,
    });
};
like($@, qr/\QDirectory $phony_minicpan not found\E/,
    "Got expected error message for bad 'start_dir' value" );

{
    $tdir = tempdir( CLEANUP => 1 );
    ok( -d $tdir, "tempdir directory created for testing" );
    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    my $phony_start_dir = File::Spec->catdir($tdir, qw( foo bar ));
    make_path($phony_start_dir, { mode => 0711 });
    ok( -d $phony_start_dir, "'start_dir' directory created for testing" );
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan  => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
    eval {
        $self->identify_distros({
            start_dir => $phony_start_dir,
        });
    };
    like($@, qr/\QDirectory $phony_start_dir must be subdirectory of $id_dir\E/,
        "Got expected error message for 'start_dir' that is not subdir of authors/id/" );
}

{
    $tdir = tempdir( CLEANUP => 1 );
    ok( -d $tdir, "tempdir directory created for testing" );
    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    my $start_dir = File::Spec->catdir($id_dir, qw( foo bar ));
    make_path($start_dir, { mode => 0711 });
    ok( -d $start_dir, "'start_dir' directory created for testing" );
    $self = CPAN::Mini::Visit::Simple->new({
        minicpan  => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
    $self->identify_distros({
        start_dir => $start_dir,
    });
    is( $self->{'start_dir'}, $start_dir,
        "'start_dir' assigned as expected" );
}

$self = CPAN::Mini::Visit::Simple->new({});
say STDERR "\nScanning your actual minicpan repository; this may take a minute";
$self->identify_distros();
ok( defined $self->{'start_dir'}, "'start_dir' assigned: $self->{'start_dir'}" );
ok( defined $self->{'list'}, "'list' assigned" );
my @distros_found = $self->get_list();
my @unwanted_tarballs = ();
my $modules_dir = $self->get_minicpan() . 'modules';
for my $k (@distros_found) {
    push @unwanted_tarballs, $k if $k =~ m{\Q$modules_dir\E};
}
is(scalar(@unwanted_tarballs), 0, "Excluded tarballs in minicpan/modules");

$self = CPAN::Mini::Visit::Simple->new({});
eval {
    $self->identify_distros( { pattern => [] } );
};
like($@, qr/'pattern' is a regex, which means it must be a REGEXP ref/,
    "Got expected error message when wrong type of value supplied to 'pattern'" );

{
    $self = CPAN::Mini::Visit::Simple->new({});
    my $start_dir = File::Spec->catdir($self->{id_dir}, qw( J JK JKEENAN ));
    ok(
        $self->identify_distros( { start_dir => $start_dir, } ),
        "'identify_distros() returned true value"
    );

    my ($stdout, $stderr);
    capture(
        sub { $self->say_list(); },
        \$stdout,
        \$stderr,
    );
    my @expected = qw(
        ExtUtils-ModuleMaker-PBP
        ExtUtils-ModuleMaker
        List-Compare
    );
    my $seen = 0;
    foreach my $el (@expected) {
        $seen++ if $stdout =~ m/$el/;
    }
    is( $seen, scalar(@expected), "All distro names seen on STDOUT" );
}

{
    $self = CPAN::Mini::Visit::Simple->new({});
    my $start_dir = File::Spec->catdir($self->{id_dir}, qw( J JK JKEENAN ));
    my $pattern = qr/ExtUtils-ModuleMaker/;
    my %distro_args = (
        start_dir => $start_dir,
        pattern   => $pattern,
    );
    ok( $self->identify_distros( \%distro_args ),
        "'identify_distros() returned true value" );
    my ($stdout, $stderr);
    capture(
        sub { $self->say_list(); },
        \$stdout,
        \$stderr,
    );
    my @expected = qw(
        ExtUtils-ModuleMaker-PBP
        ExtUtils-ModuleMaker
    );
    my $seen = 0;
    foreach my $el (@expected) {
        $seen++ if $stdout =~ m/$el/;
    }
    is( $seen, scalar(@expected), "All distro names seen on STDOUT" );
}
