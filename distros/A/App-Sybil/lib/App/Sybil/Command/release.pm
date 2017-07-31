package App::Sybil::Command::release;

use strict;
use warnings;
use v5.12;

use App::Sybil -command;

use Capture::Tiny ':all';
use File::Slurp;
use Net::GitHub;

sub abstract { 'Release your software' }

sub description { 'Publishes your current version as a github release' }

sub execute {
  my ($self, $opt, $args) = @_;

  my $project = $self->app->project;
  my $version = $self->app->version;

  unless ($self->app->has_build($version)) {
    say STDERR "Incomplete bulid, aborting release";
    return;
  }

  # TODO additional checks

  say STDERR "Publishing $project $version to github.";

  # TODO have setup command to get oauth token
  my $token  = $self->app->github_token();
  unless ($token) {
    say STDERR "No github oauth token available, try `sybil auth`";
    return;
  }
  my $github = Net::GitHub->new(
    version      => 3,
    access_token => $token,
    RaiseError => 1,
  );

  my $url = capture_stdout {
    system 'git', 'remote', 'get-url', 'origin';
  };
  unless ($url =~ m|github\.com[:/](\w+)/(\w+)(?:\.git)?$|) {
    say STDERR 'Remote "origin" is not a github url';
    return;
  }

  my $repos = $github->repos;
  $repos->set_default_user_repo($1, $2);

  my $commit = capture_stdout {
    system 'git', 'rev-parse', 'HEAD';
  };

  foreach my $r ($repos->releases()) {
    if ($r->{name} eq $version) {
      say STDERR "There is already a release named $version";
      say STDERR $r->{html_url};
      return;
    }
  }

  my $desc = capture_stdout {
    system 'git', 'show', '-s', '--format=%B', $version;
  };

  my $release = $repos->create_release({
    tag_name => $version,
    name     => $version,
    body     => $desc,
    draft    => \1,
  });

  say STDERR "Created release $version";

  foreach my $target ($self->app->targets) {
    my $file = $self->app->output_file($version, $target);
    my $type = $file =~ /\.zip$/ ? 'application/zip' : 'application/gzip';
    my $data = read_file($file, { binmode => ':raw' });
    my $size = length $data;
    say STDERR "Uploading $file ($type): $size bytes";
    my $asset = $repos->upload_asset($release->{id}, $file, $type, $data);
  }

  say STDERR "Released $version at $release->{html_url}";
}

1;
