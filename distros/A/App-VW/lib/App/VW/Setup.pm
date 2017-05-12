package App::VW::Setup;
use strict;
use warnings;
use App::VW;
use Cwd;
use base 'App::VW::Command';
use File::ShareDir 'module_dir';
use YAML 'DumpFile';

my $config = App::VW->config;

sub options {
  my ($class) = @_;
  (
    $class->SUPER::options,
    'port|p=i'     => 'port',
    'size|s=s'     => 'size',
    'modules|m=s@' => 'modules',
  );
}

sub run {
  my ($self, $app) = @_;

  die("Please specify an App to start.\n")
    if (not defined $app);

  my $cwd = getcwd;
  my $cluster_description = {
    app          => $app,
    dir          => $cwd,
    port         => $self->{port} || 4000,
    cluster_size => $self->{size} || 1,
  };

  if ($self->{modules}) {
    $cluster_description->{modules} =
      join(" ", @{ $self->{modules} });
  }

  my $app_name = lc $cluster_description->{app};
  $app_name =~ s/::/_/g;
  my $yaml_file = "$config->{etc}/$app_name.yml";
  print "Creating $yaml_file.\n" if ($self->{verbose});
  DumpFile($yaml_file, $cluster_description) || die($!);

  my $src = module_dir('App::VW') . "/etc/vw_harness.tmpl";
  my $harness_file = "$cwd/vw_harness.pl";
  print "Creating $harness_file.\n" if ($self->{verbose});

  open(IN, "<", $src) || die ($!);
  my $tmpl = join('', <IN>);
  close(IN);

  $tmpl =~ s/\[%\s*(\w+)\s*%\]/$cluster_description->{$1}/eg;

  open(OUT, ">", $harness_file) || die($!);
  print OUT $tmpl;
  close(OUT);
}

1;

=head1 NAME

App::VW::Setup - setup a Squatting app for deployment via Continuity

=head1 SYNOPSIS

Usage:

  vw setup <App> [OPTION]...

Example:  How to setup a Squatting app called 'Bavl'

  # Go to the directory your squatting app is in.
  cd /www/towr.of.bavl.org

  # Run the setup command
  sudo vw setup Bavl --port 6000

  # You should have 2 new files in your system, now:
  /etc/vw/bavl.yml
  /www/towr.of.bavl.org/vw_harness.pl

=head1 DESCRIPTION

The C<setup> command installs 2 files into your system so that vw will be able
to start your app as a daemonized server at boot time.  See L<App::VW> for
details.

=head1 OPTIONS

=over 4

=item -p, --port=PORT

This is the port that the first process in the cluster will listen to.  Its
default value is C<4000>, but you should really specify one yourself.

=item -s, --size=SIZE

This is the number of processes in the cluster.  Its default value is C<1>.

=item -m, --modules=PLUGIN

This option is used to specify which plugins you want your Squatting app to
load before starting.  You can use this option multiple times.

B<Example>:

  sudo vw setup ChatterBox -m With::AccessTrace -m With::Log --port 9000

=back

=cut
