package Arepa::Job::CompilePackage;

use strict;
use warnings;

use base qw( TheSchwartz::Worker );

use TheSchwartz::Job;
use File::Path;
use File::Temp;

use Arepa::BuilderFarm;
use Arepa::Repository;

our $PrintMessages = 0;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my $config_file = $ENV{AREPA_CONFIG} || '/etc/arepa/config.yml';
    my $farm = Arepa::BuilderFarm->new($config_file);

    my $id = $job->arg->{compilation_queue_id};
    eval {
        $farm->package_db->mark_compilation_started($id);
        $class->_work($config_file, $id);
    };
    if ($@) {
        my $error = $@;

        $farm->package_db->mark_compilation_failed($id);
        $job->permanent_failure($error);
        $class->print("ERROR: " . $error);
        exit 1;
    }
    else {
        $job->completed;
    }
}

sub _work {
    my ($class, $config_file, $id) = @_;

    my $farm = Arepa::BuilderFarm->new($config_file);
    my $repo = Arepa::Repository->new($config_file);
    my %req;

    eval {
        %req = $farm->package_db->get_compilation_request_by_id($id);
    };
    if (! %req) {
        die "Can't find a compilation request with id '$id'";
    }

    my ($builder) = $farm->get_matching_builders($req{architecture},
                                                 $req{distribution});
    if (!defined $builder) {
        die "There aren't any builders for $req{distribution}/" .
                         "$req{architecture}?\n";
    }

    # Actual package compilation
    my $source_pkg_id = $req{source_package_id};
    my %source_attrs  = $farm->package_db->
                               get_source_package_by_id($source_pkg_id);
    $class->print("Compiling request id $req{id}\n");
    $class->print("$source_attrs{name} $source_attrs{full_version} ");
    $class->print("(arch: $req{architecture}, ");
    $class->print("distro: $req{distribution}) ");
    $class->print("with builder $builder...\n");
    my $temp_dir = File::Temp::tempdir();
    if ($farm->compile_package_from_queue($builder,
                                          $req{id},
                                          output_dir => $temp_dir)) {
        $class->print("*** SUCCESS ***\n");
        foreach my $deb_package (glob("$temp_dir/*.deb")) {
            $class->print("Adding $deb_package to the repository\n");
            if ($repo->insert_binary_package($deb_package,
                                             $req{distribution})) {
                unlink $deb_package;
            }
        }
        $repo->sign_distribution($req{distribution});
    } else {
        $class->print("*** FAILED ***\n\n");
        $class->print("You can see the build log at ");
        my $build_log_dir = $repo->get_config_key('dir:build_logs');
        $class->print(File::Spec->catfile($build_log_dir, $id), "\n");
    }
    rmtree($temp_dir);
}

sub print {
    my ($class, @args) = @_;

    if ($PrintMessages) {
        print @args;
    }
}

1;
