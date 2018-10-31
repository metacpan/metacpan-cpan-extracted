package Bundler::MultiGem::Command::setup {

  use Bundler::MultiGem -command;
  use YAML::Tiny;
  use Bundler::MultiGem::Model::Directories;
  use Bundler::MultiGem::Model::Gem;

=head1 NAME

Bundler::MultiGem::Command::setup - Create multiple gem versions out of a configuration file (alias: install i s)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module includes the commands to create multiple versions of the same gem out of a config yml file

=head1 SUBROUTINES/METHODS

=head2 command_names

=cut

  sub command_names {
    qw(setup install i s)
  }

=head2 usage_desc

=cut

  sub usage_desc { "bundle-multigem %o <path>" }

=head2 opt_spec

=cut

  sub opt_spec {
    return (
      [ "file|f=s", "provide the yaml configuration file (default: ./.bundle-multigem.yml)" ],
    );
  }
=head2 validate_args

=cut
  sub validate_args {
    my ($self, $opt, $args) = @_;

    $opt->{file} = $opt->{file} // '.bundle-multigem.yml';
    if (!-f $opt->{file}){
      $self->usage_error("You should provide a valid path ($opt->{file} does not exists)");
    }
    $self->usage_error("No args allowed") if @$args;
  }

  sub execute {
    my ($self, $opt, $args) = @_;

    my $yaml = YAML::Tiny->read($opt->{file});

    my $gem = Bundler::MultiGem::Model::Gem->new($yaml->[0]{gem});
    my $dir = Bundler::MultiGem::Model::Directories->new({
      cache => $yaml->[0]{cache},
      directories => $yaml->[0]{directories},
    });

    $dir->validates;
    $dir->apply_cache;

    $gem->apply($dir);

    print "Completed!";
  }
}

1;