package Arepa::Web::Incoming;

use strict;
use warnings;

use base 'Arepa::Web::Base';

use File::Basename;
use Parse::Debian::PackageDesc;
use Arepa::Repository;
use Arepa::BuilderFarm;

sub _approve_package {
    my ($self, $changes_file_path, %opts) = @_;

    # Only get the file basename, and search for it in the incoming directory
    my $path = $self->config->get_key('upload_queue:path') . "/" .
                    basename($changes_file_path);
    my $changes_file = Parse::Debian::PackageDesc->new($path);
    my $distribution = $changes_file->distribution;

    # Add the source package to the repo
    my ($source_file_path) = grep /\.dsc$/, $changes_file->files;
    my $repository = Arepa::Repository->new($self->config_path);
    my $farm       = Arepa::BuilderFarm->new($self->config_path);

    my ($arch) = grep { $_ ne 'source' } $changes_file->architecture;
    my $canonical_distro;
    eval {
        $canonical_distro = $farm->canonical_distribution($arch,
                                                          $distribution);
    };
    if ($@) {
        $self->_add_error($@);
        return 0;
    }

    my $source_pkg_id;
    if ($canonical_distro) {
        $source_pkg_id = $repository->insert_source_package(
                             $self->config->get_key('upload_queue:path').
                                         "/".$source_file_path,
                             $distribution,
                             canonical_distro => $canonical_distro,
                             %opts);

        if ($source_pkg_id) {
            if (! $self->config->key_exists('repository:signature:id') ||
                    $self->config->get_key('repository:signature:id') ne
                        'unsigned') {
                my $sign_cmd = "sudo -H -u arepa-master arepa sign >/dev/null";
                if (system($sign_cmd) != 0) {
                    $self->_add_error("Couldn't sign repositories, check " .
                                      "your 'sudo' configuration and " .
                                      "the README file");
                }
            }
        }
        else {
            $self->_add_error("Couldn't approve source package " .
                                "'$source_file_path'.",
                                $repository->last_cmd_output);
        }
    }
    else {
        $self->_add_error("Can't find any builder for $source_file_path " .
                            "($distribution/$arch)");
    }

    if ($self->_error_list) {
        return 0;
    }
    else {
        # If everything went fine, add the source package to the compilation
        # queue
        $farm->request_package_compilation($source_pkg_id);

        $self->_remove_uploaded_package($path);

        if ($self->_error_list) {
            return 0;
        }
    }

    return 1;
}

sub _remove_uploaded_package {
    my ($self, $changes_file_path) = @_;

    my $changes_file = Parse::Debian::PackageDesc->new($changes_file_path);
    # Remove all files from the pending queue
    # Files referenced by the changes file
    foreach my $file ($changes_file->files) {
        my $file_path = $self->config->get_key('upload_queue:path')."/".$file;
        if (-e $file_path && ! unlink($file_path)) {
            $self->add_error("Can't delete '$file_path'.");
        }
    }
    # Changes file itself
    if (! unlink($changes_file_path)) {
        $self->add_error("Can't delete '$changes_file_path'.");
    }
}

sub process {
    my ($self) = @_;

    $self->_only_if_admin(sub {
        my @field_ids = map { /^package-(\d+)$/; $1 }
                            grep /^package-\d+$/,
                                 keys %{$self->tx->req->params->to_hash};
        foreach my $field_id (@field_ids) {
            if ($self->param("approve_all") ||
                        $self->param("approve-$field_id")) {
                $self->_approve_package(
                    $self->param("package-$field_id"),
                    priority => $self->param("priority-$field_id"),
                    section  => $self->param("section-$field_id"),
                    comments => $self->param("comments-$field_id"));
            }
            elsif ($self->param("reject-$field_id")) {
                my $changes_file_path = $self->param("package-$field_id");
                my $path = $self->config->get_key('upload_queue:path')."/".
                                basename($changes_file_path);
                $self->_remove_uploaded_package($path);
            }
        }
        if ($self->_error_list) {
            $self->vars(errors => [$self->_error_list]);
            $self->render('error');
        }
        else {
            $self->redirect_to('home');
        }
    });
}

1;
