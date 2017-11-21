# -*- perl -*-

# t/008_visit.t

use 5.010;
use CPAN::Mini::Visit::Simple;
use Carp;
use Cwd;
use File::Basename;
use File::Copy;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use IO::CaptureOutput qw( capture );

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
    plan tests => 25;
}

my ( $self, $rv );
my ( $real_id_dir, $start_dir, $cwd );
my ( $id_dir );

$cwd = cwd();

$self = CPAN::Mini::Visit::Simple->new();
isa_ok ($self, 'CPAN::Mini::Visit::Simple');
$real_id_dir = $self->get_id_dir();
$start_dir = File::Spec->catdir( $real_id_dir, qw( J JK JKEENAN ) );
ok( ( -d $start_dir ), "'start_dir' exists: $start_dir" );

note("Case 1:  Failure:  visit() called prematurely");
eval {
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            my $makefiles;
            my $buildfiles;
            if ( -f 'Makefile.PL' ) {
                $makefiles++;
            }
            if ( -f 'Build.PL' ) {
                $buildfiles++;
            }
        },
        action_args => [],
    } );
};
like($@,
    qr/Must have a list of distributions on which to take action/,
    "Got expected error message:  visit() called before identify_distros()" );

note("Case 2:  Success:  identify_distros() called with 'start_dir'");
$rv = $self->identify_distros( {
    start_dir   => $start_dir,
} );

{
    my ($stdout, $stderr);
    capture(
        sub {
            $rv = $self->visit( {
                action  => sub {
                    my $distro = shift @_;
                    if ( -f 'Makefile.PL' ) {
                        say "$distro has Makefile.PL";
                    }
                    if ( -f 'Build.PL' ) {
                        say "$distro has Build.PL";
                    }
                },
            } );
        },
        \$stdout,
        \$stderr,
    );
    ok( $rv, "'visit()' returned true value" );
    like($stdout,
        qr/List-Compare-.*?\.tar\.gz has Makefile\.PL/s,
        "Got expected STDOUT"
    );
}

note("Case 3:  Success:  'quiet' option");
{
    my ($stdout, $stderr);
    capture(
        sub {
            $rv = $self->visit( {
                action  => sub {
                    my $distro = shift @_;
                    if ( -f 'Makefile.PL' ) {
                        say "$distro has Makefile.PL";
                    }
                    if ( -f 'Build.PL' ) {
                        say "$distro has Build.PL";
                    }
                },
                quiet => 1,
            } );
        },
        \$stdout,
        \$stderr,
    );
    ok( $rv, "'visit()' returned true value" );
    like($stdout,
        qr/List-Compare-.*?\.tar\.gz has Makefile\.PL/s,
        "Got expected STDOUT"
    );
}
my $pattern = qr/'visit\(\)' method requires 'action' subroutine reference/;

note("Case 4:  Failure:  visit() called without 'action' argument");
eval {
    $rv = $self->visit( { quiet => 1 } );
};
like( $@, qr/$pattern/,
    "Got expected error output:  No 'action' argument" );

note("Case 5:  Failure:  visit() called with bad 'action' argument");
eval {
    $rv = $self->visit( { action => 'not a reference' } );
};
like( $@, qr/$pattern/,
    "Got expected error output:  'action' argument not a reference" );

note("Case 6:  Failure:  visit() called with bad 'action' argument");
eval {
    $rv = $self->visit( { action => {} } );
};
like( $@, qr/$pattern/,
    "Got expected error output:  'action' argument not a code reference" );

note("Case 7:  Success:  visit() called with 'action_args'");
{
    my ($stdout, $stderr);
    capture(
        sub {
            $rv = $self->visit( {
                action  => sub {
                    my $distro = shift @_;
                    if ( -f 'Makefile.PL' ) {
                        say "$distro has Makefile.PL";
                    }
                    if ( -f 'Build.PL' ) {
                        say "$distro has Build.PL";
                    }
                },
                action_args => [ 1 .. 3 ],
            } );
        },
        \$stdout,
        \$stderr,
    );
    ok( $rv, "'visit()' returned true value" );
    like($stdout,
        qr/List-Compare-.*?\.tar\.gz has Makefile\.PL/s,
        "Got expected STDOUT"
    );
}

$pattern = qr/'action_args' must be array reference/;

note("Case 8:  Failure:  bad 'action_args'");
eval {
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            my $makefiles;
            my $buildfiles;
            if ( -f 'Makefile.PL' ) {
                $makefiles++;
            }
            if ( -f 'Build.PL' ) {
                $buildfiles++;
            }
        },
        action_args => 'not a reference',
    } );
};
like($@, qr/$pattern/,
    "Got expected error message:  'action_args' must be reference" );

note("Case 9:  Failure:  bad 'action_args'");
eval {
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            my $makefiles;
            my $buildfiles;
            if ( -f 'Makefile.PL' ) {
                $makefiles++;
            }
            if ( -f 'Build.PL' ) {
                $buildfiles++;
            }
        },
        action_args => {},
    } );
};
like($@, qr/$pattern/,
    "Got expected error message:  'action_args' must be an array reference" );

{
note("Case 10: Badly formatted archive");
    my $archive = File::Spec->catfile( $cwd, qw( t data mydistro.tar.gz ));
    ok( -f $archive, "Able to locate archive prior to testing" );
    my $tdir = tempdir(CLEANUP => 1);
    chdir $tdir or croak "Unable to change to tempdir";

    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );

    my $thisauthor_dir = File::Spec->catdir($id_dir, qw( Z ));
    make_path($thisauthor_dir, { mode => 0711 });
    ok( -d $thisauthor_dir, "directory created for testing" );
    my $copy_archive = File::Spec->catfile($thisauthor_dir, basename($archive));
    copy $archive => $copy_archive or croak "Unable to copy archive";

    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
    $rv = $self->identify_distros( {
        start_dir   => $thisauthor_dir,
    } );
    ok( $rv, "'identify_distros() returned true value" );
    {
        my ($stdout, $stderr);
        capture(
            sub {
                $rv = $self->visit( {
                    action  => sub {
                        my $distro = shift @_;
                        if ( -f 'Makefile.PL' ) {
                            say "$distro has Makefile.PL";
                        }
                        if ( -f 'Build.PL' ) {
                            say "$distro has Build.PL";
                        }
                    },
                } );
            },
            \$stdout,
            \$stderr,
        );
        ok( $rv, "'visit()' returned true value" );
        like($stdout,
            qr/\.tar\.gz has Makefile\.PL/s,
            "Got expected STDOUT"
        );
    }
    chdir $cwd or croak "Unable to change back to '$cwd'";
}

{
    note("Case 11:  Success:  identify_distros() called with 'start_dir'; different approach to testing");
    $self = CPAN::Mini::Visit::Simple->new();
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
    $real_id_dir = $self->get_id_dir();
    $start_dir = File::Spec->catdir( $real_id_dir, qw( J JK JKEENAN ) );
    ok( ( -d $start_dir ), "'start_dir' exists: $start_dir" );

    $rv = $self->identify_distros( {
        start_dir   => $start_dir,
    } );
    my @output_list = $self->get_list();
    my %build_generators = ();
    $rv = $self->visit( {
        action  => sub {
            my $distro = shift @_;
            if ( -f 'Makefile.PL' ) {
                $build_generators{Makefile}{$distro}++;
            }
            elsif ( -f 'Build.PL' ) {
                $build_generators{Build}{$distro}++;
            }
            else {
                $build_generators{unidentified}++;
            }
        },
    } );
    ok( $rv, "'visit()' returned true value" );
    #is($build_generators{Makefile} + $build_generators{Build}, $output_count,
    is(scalar(keys %{$build_generators{Makefile}}) +
       scalar(keys %{$build_generators{Build}}),
       scalar(@output_list),
       "Each distro has a Makefile.PL or, if not that, a Build.PL");
}

