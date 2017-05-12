package Arepa::Web::Repository;

use strict;
use warnings;

use base 'Arepa::Web::Base';

use Parse::Debian::PackageDesc;
use Arepa::Config;
use Arepa::Repository;
use Arepa::BuilderFarm;

sub index {
    my ($self) = @_;

    my $repository = Arepa::Repository->new($self->config_path);
    my $pdb = Arepa::PackageDb->new($self->config->get_key('package_db'));

    my %packages = $repository->get_package_list;
    my %comments = ();
    foreach my $pkg (keys %packages) {
        foreach my $comp (keys %{$packages{$pkg}}) {
            foreach my $version (keys %{$packages{$pkg}->{$comp}}) {
                if (grep { $_ eq 'source' }
                         @{$packages{$pkg}->{$comp}->{$version}}) {
                    my $id = $pdb->get_source_package_id($pkg, $version);
                    my %source_pkg = $pdb->get_source_package_by_id($id);
                    $comments{$pkg}->{$version} = $source_pkg{comments};
                }
            }
        }
    }

    $self->show_view({ packages => \%packages,
                       comments => \%comments });
}

sub view {
    my ($self) = @_;

    if ($self->config->key_exists('repository:url')) {
        my $repo_url = $self->config->get_key('repository:url');
        my @url_parts = @{$self->tx->req->url->path->parts};
        my $package_name = $url_parts[$#url_parts];
        my $package_dir = ($package_name =~ /^lib/) ?
          substr($package_name, 0, 4) :
          substr($package_name, 0, 1);
        my $package_in_repo_url = $repo_url . "/pool/main/" . $package_dir .
                                              "/" . $package_name;
        $self->redirect_to($package_in_repo_url);
    }
    else {
        $self->_add_error("No 'repository:url' configuration key found. Please make it point to your repository URL to use this feature");
        $self->vars(errors => [$self->_error_list]);
        $self->render('error');
    }
}

sub sync {
    my ($self) = @_;

    $self->_only_if_admin(sub {
        if ($self->config->key_exists('repository:remote_path')) {
            my $cmd = "sudo -H -u arepa-master arepa sync";
            if (system("$cmd >/dev/null") != 0) {
                $self->_add_error("Couldn't synchronize the repository with the command '$cmd'");
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
