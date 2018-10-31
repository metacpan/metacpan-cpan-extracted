package Bundler::MultiGem::Command::initialize {

  use Bundler::MultiGem -command;
  use Cwd qw(realpath);
  use Bundler::MultiGem::Utl::InitConfig qw(merge_configuration);
  use File::Spec::Functions qw(catfile);
  use YAML::Tiny;
=head1 NAME

Bundler::MultiGem::Command::initialize - Generate a configuration file (alias: init bootstrap b)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module includes the commands to initialize a yml configuration file for installing multiple versions of the same gem

=head1 SUBROUTINES/METHODS

=head2 command_names

=cut

  sub command_names {
    qw(initialize init bootstrap b)
  }

=head2 execute

=cut

  sub execute {
    my ($self, $opt, $args) = @_;

    foreach my $k (keys %{$opt}) {
      my ($k1, $k2) = split(/_/, $k, 2);
      my $new_key = opt_prefix($k1);
      next unless $new_key;
      $app->{config}->{$new_key}->{$k2} = $opt->{$k};
    }

    $app->{config} = merge_configuration($app->{config});

    my $output_file = $opt->{conf-file} || ".bundle-multigem.yml";
    my $yaml = YAML::Tiny->new( $app->{config} );

    if (! -f $output_file ) {
      $output_file = catfile($app->{config}->{directories}->{root}, ".bundle-multigem.yml")
    }

    $yaml->write($output_file);

    print "Configuration generated at: ${output_file}\n";
  }

=head2 usage_desc

=cut

  sub usage_desc { "bundle-multigem %o <path>" }

=head2 opt_spec

=cut

  sub opt_spec {
    return (
      [ "gem-main-module|gm=s", "provide the gem main module (default: constantize --gem-name)" ],
      [ "gem-name|gn=s", "provide the gem name" ],
      [ "gem-source|gs=s", "provide the gem source (default: https://rubygems.org)" ],
      [ "gem-versions|gv=s@", "provide the gem versions to install (e.g: --gem-versions 0.0.1 --gem-versions 0.0.2)" ],
      [ "dir-pkg|dp=s", "directory for downloaded gem pkg (default: pkg)" ],
      [ "dir-target|dt=s", "directory for extracted versions (default: versions)" ],
      [ "cache-pkg|cp=s", "keep cache of pkg directory (default: 1)" ],
      [ "cache-target|ct=s", "keep cache of target directory (default: 0)" ],
      [ "conf-file|f=s", "choose config file name (default: .bundle-multigem.yml)" ],
    );
  }

=head2 validate_args

=cut
  sub validate_args {
    my ($self, $opt, $args) = @_;

    if (scalar @$args != 1) {
      $self->usage_error("You should provide exactly one argument (<path>)");
    }

    my $root_path = realpath($args->[0]);

    if (! -e $root_path) {
      $self->usage_error("You should provide a valid path ($root_path does not exists)");
    }

    $app->{config}->{directories} = {
      'root' => $root_path
    };
  }

=head2 config

=cut

  sub config {
    my $app = shift;
    $app->{config} ||= {};
  }
=head2 config

=cut

  our $OPT_PREFIX = {
    'gem' => 'gem',
    'dir' => 'directories',
    'cache' => 'cache'
  };

  sub opt_prefix {
    my $k = shift;
    $OPT_PREFIX->{$k};
  }
};
1;
