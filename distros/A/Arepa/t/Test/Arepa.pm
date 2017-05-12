package Test::Arepa;

use strict;
use warnings;

use Test::Class;
use Test::More;
use Cwd;
use File::Path;
use File::Copy;
use File::Basename;
use File::Spec;
use HTML::TreeBuilder;
use DBI;

use Arepa::Config;

use base qw(Test::Class);

sub config_path {
    my $self = shift;

    if (@_) {
        $self->{config_path} = shift;
        $ENV{AREPA_CONFIG} = $self->{config_path};   # Update for TheSchwartz
    }
    return $self->{config_path};
}

sub config { $_[0]->{config}; }

sub t {
    my $self = shift;
    $self->{t} ||= Test::Mojo->new('Arepa::Web');
    return $self->{t};
}

sub setup : Test(setup) {
    my $self = shift;

    my $config_path = $self->{config_path} ||
                        't/webui/conf/default/config.yml';
    $self->{config} = Arepa::Config->new($config_path);

    # Make the configuration path available to the application
    $ENV{AREPA_CONFIG} = $config_path;
    # Needed so the application finds all the files
    $ENV{MOJO_HOME}    = cwd;

    # ALWAYS recreate the temporary directory
    rmtree('t/webui/tmp');
    mkpath('t/webui/tmp');

    # Prepare the session DB
    my $session_db_path = $self->{config}->get_key('web_ui:session_db');
    unlink $session_db_path;
    my $dbh = DBI->connect("dbi:SQLite:$session_db_path","","");
    my $sth =
        $dbh->prepare("CREATE TABLE session (sid VARCHAR(40) PRIMARY KEY, " .
                                            "data TEXT, " .
                                            "expires INTEGER UNSIGNED " .
                                                               "NOT NULL, " .
                                            "UNIQUE(sid));");
    $sth->execute;

    # Make sure the upload queue exists
    mkpath($self->{config}->get_key('upload_queue:path'));

    # Make sure the repository itself exists. If we had to create it, copy the
    # conf/distributions configuration file
    my $repo_path = $self->{config}->get_key('repository:path');
    my $number_dirs_created = mkpath(File::Spec->catfile($repo_path, "conf"));
    if ($number_dirs_created) {
        my $conf_base_dir = dirname($self->{config_path});
        copy(File::Spec->catfile($conf_base_dir, "distributions"),
             File::Spec->catfile($repo_path,     "conf"));
    }

    # Make sure the build log directory exists
    mkpath($self->{config}->get_key('dir:build_logs'));
}

sub get {
    my ($self, $url) = @_;

    $self->{t}->tx($self->{t}->ua->get($url));
}

sub login_ok {
    my ($self, $username, $password) = @_;

    $self->t->get_ok('/')->
              status_is(200)->
              content_like(qr/arepa_test_logged_out/);
    $self->t->post_form_ok('/' => {username => "testuser",
                                   password => "testuser's password"});
    $self->t->get_ok('/')->
              status_is(200);
    unlike($self->t->tx->res->body, qr/arepa_test_logged_out/,
           "Should NOT find the logged out mark on the page");
}

sub incoming_packages {
    my ($self) = @_;

    $self->get('/');
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_content($self->t->tx->res->body);

    # Get the package names
    my @pkg_names = map {
                         $_->as_text;
                    }
                    $tree->look_down(sub {
                            grep { $_ eq 'incoming-package-name' }
                                 split(' ',
                                       ($_[0]->attr('class') || "")) });

    my @pkg_versions = map {
                            $_->as_text;
                       }
                       $tree->look_down(sub {
                               grep { $_ eq 'incoming-package-version' }
                                    split(' ',
                                          ($_[0]->attr('class') || "")) });

    my @r = ();
    for (my $i = 0; $i <= $#pkg_names; ++$i) {
        push @r, $pkg_names[$i] . "_" . $pkg_versions[$i];
    }
    return @r;
}

sub queue_files {
    my ($self, @files) = @_;

    my $upload_queue_path = $self->config->get_key('upload_queue:path');
    foreach my $file (@files) {
        copy($file, $upload_queue_path);
    }
}

sub save_snapshot {
    my ($self) = @_;

    open F, ">/tmp/mojo-arepa-snapshot.html";
    print F $self->t->tx->res->body;
    close F;
}

sub is_package_in_repo {
    my ($self, $package_spec, $distro, $arch) = @_;

    my ($package_name, $package_revision) = split(/_/, $package_spec);

    my $repo_path = $self->config->get_key('repository:path');
    my $packages_file_path = File::Spec->catfile($repo_path,
                                                 'dists',
                                                 $distro,
                                                 'main',
                                                 'binary-' . $arch,
                                                 'Packages');
    open F, $packages_file_path;
    my ($current_pkg, $found) = ("", 0);
    while (<F>) {
        if (/^Package: (.+)/) {
            $current_pkg = $1;
        } elsif ($current_pkg eq $package_name && /^Version: (.+)/) {
            if ($package_revision eq $1) {
                $found = 1;
            }
        }
    }
    close F;

    is($found, 1, "Package $package_spec should be in the repo");
}

1;
