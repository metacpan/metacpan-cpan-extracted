package App::Antigen;

use Moo;
use MooX::Options;
use YAML::Tiny;
use Path::Tiny;
use IPC::System::Simple qw/ system /;

our $VERSION = '0.001';

=head1 NAME

App::Antigen - Plugin Manager for Zsh

=head1 SYNOPSIS

  use App::Antigen;

  my $app = App::Antigen->new_with_options( plugins => \@plugins );
  $app->run;

=head1 DESCRIPTION

App::Antigen is the underlying code for the antigen-perl tool, which is used
for managing Zsh plugins. This module is still under development, and so the
interface is subject to change as new features are added, and bugs are found.

=head2 Todo

There are many things which are still to do in this, including supporting
upgrades to the plugins as hosted on github, as well as adding support for
other targets such as normal git repos, tarball downloads, and local files and
folders. As said before, this module is still under development, and may change
entirely without warning.

=head2 Attributes

These are the attributes provided (using MooX::Options). These can also be put
in the configuration file - see L<antigen-perl>

=head3 output

This it the output folder into which all the plugin repositories and code will
be put. Defaults to $HOME/.antigen-perl

=cut

option 'output' => (
  is => 'lazy',
  format => 's',
  short => 'o',
  default => sub { File::Spec->catfile( $ENV{HOME}, '.antigen-perl' ) },
  doc => 'Directory for all Antigen-Perl output files',
);

=head3 repo

This is the folder where all the repositories will be stored. Defaults to
$HOME/.antigen-perl/repos

=cut

option 'repo' => (
  is => 'lazy',
  format => 's',
  short => 'r',
  builder => sub { File::Spec->catfile( $_[0]->output, 'repos' ) },
  doc => 'Directory for Antigen-Perl repos',
);

=head3 output_file

This is the file which will contain all the calls to the various plugins for
zsh to load. Defaults to $HOME/.antigen-perl/antigen-perl.zsh

=cut

option 'output_file' => (
  is => 'lazy',
  format => 's',
  short => 'f',
  builder => sub { File::Spec->catfile( $_[0]->output, 'antigen-perl.zsh' ) },
  doc => 'Final output file for sourcing',
);

=head3 plugins

This contains an array of hashrefs of the plugins, with the keys as the method/place to
get the plugins from. Currently only accepts one method for getting the
plugins, github. An example plugin config:

  my $plugins = [
    github => "TBSliver/zsh-theme-steeef",
    github => "TBSliver/zsh-plugin-extract"
  ];

=cut

has 'plugins' => (
  is => 'ro',
  required => 1,
);

=head2 Methods

These are the various methods which are provided, either for internal use or
for basic usage.

=head3 run

This is the main method of App::Antigen, and when called will actually build
the entire plugin structure, according to the plugin options specified.

=cut

sub run {
  my $self = shift;

  my @plugin_dirs;

  for my $plugin ( @{ $self->plugins } ) {
    if ( exists $plugin->{ github } ) {
      push @plugin_dirs, $self->github_cmd( $plugin->{ github } );
    }
  }

  my @plugin_files;

  for my $plugin_dir ( @plugin_dirs ) {
    push @plugin_files, $self->find_plugin( $plugin_dir );
  }

  $self->write_output_file( \@plugin_files, \@plugin_dirs );

  print "To actually use the plugins, make sure you have the following line at the bottom of your ~/.zshrc:\n\n";
  print "    source " . $self->output_file . "\n\n\n";
}

=head3 gen_github_url

This function generates the github repository URL as required for getting the
plugins.

=cut

sub gen_github_url {
  my ( $self, $repo ) = @_;

  return sprintf( "https://github.com/%s.git", $repo );
}

=head3 gen_plugin_target

This function performs a regex on the github url, replacing all colons (:) with
'-COLON-', and all slashes (/) with '-SLASH-'. This is then used as the folder
name for the github target.

=cut

sub gen_plugin_target {
  my ( $self, $repo ) = @_;

  $repo =~ s/:/-COLON-/g;
  $repo =~ s/\//-SLASH-/g;

  return File::Spec->catfile( $self->repo, $repo );
}

=head3 github_cmd

This function pulls together the github url and target folder, and actually
performs the git command using a call out to system.

=cut

sub github_cmd {
  my ( $self, $repo ) = @_;

  my $url = $self->gen_github_url( $repo );
  my $output_file = $self->gen_plugin_target( $url );

  if ( -d $output_file ) {
    print "skipping existing plugin $repo\n";
  } else {
    system ( 'git', 'clone', '--recursive', '--', $url, $output_file );
  }

  return $output_file;
}

=head3 find_plugin

This finds all the plugins inside the repo directory with a file extension of
*.plugin.zsh and addes them to the plugin list. This will find every occurance
of a file with that plugin extension.

=cut

sub find_plugin {
  my ( $self, $dir ) = @_;

  my @plugins;

  my $iter = path( $dir )->iterator;
  while (my $path = $iter->() ) {
    push ( @plugins, $path->stringify ) if $path =~ /\.plugin\.zsh$/;
  }

  return @plugins;
}

=head3 write_output_file

This takes all the plugins found with the correct extension, and puts them in a
single file ready to be added to your .zshrc

=cut

sub write_output_file {
  my ( $self, $plugins, $directories ) = @_;

  my $file = path( $self->output_file );

  my @lines = (
    "# Generated by Script antigen-perl\n"
  );

  push @lines, map { "source " . $_ . "\n" } @$plugins;
  push @lines, map { "fpath+=" . $_ . "\n" } @$directories;

  $file->spew( join "", @lines );
}

=head1 AUTHOR

Tom Bloor E<lt>tom.bloor@googlemail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Tom Bloor

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<antigen-perl>, L<MooX::Options>

=cut

1;
