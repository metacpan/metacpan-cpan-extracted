package CPAN::Maker::Bootstrapper::ConfigReader;

use strict;
use warnings;

use Config::Tiny;
use File::HomeDir;

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(config));

########################################################################
sub new {
########################################################################
  my ( $class, $file ) = @_;

  ($file) = grep {defined} ( $file, $ENV{CPAN_MAKER_CONFIG}, File::HomeDir->my_home . '/.gitconfig' );

  die "ERROR: no configuration file\n"
    if !$file || !-e $file;

  my $config = Config::Tiny->read($file)
    or die "ERROR: Could not read $file: " . Config::Tiny->errstr . "\n";

  return $class->SUPER::new( { config => $config } );
}

########################################################################
sub get_value {
########################################################################
  my ( $self, $section, $parameter ) = @_;

  return $self->get_config->{$section}->{$parameter};
}

########################################################################
sub user_name {
########################################################################
  my ($self) = @_;
  return $self->get_value( 'user', 'name' );
}

########################################################################
sub user_github {
########################################################################
  my ($self) = @_;
  return $self->get_value( 'user', 'github' );
}

########################################################################
sub user_email {
########################################################################
  my ($self) = @_;
  return $self->get_value( 'user', 'email' );
}

########################################################################
sub cpan_maker_basedir {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'basedir' );
}

########################################################################
sub cpan_maker_max_tokens {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'max-tokens' );
}

########################################################################
sub cpan_maker_resources {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'resources' );
}

########################################################################
sub cpan_maker_perltidyrc {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'perltidyrc' );
}

########################################################################
sub cpan_maker_perlcriticrc {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'perlcriticrc' );
}

########################################################################
sub cpan_maker_syntax_checking {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'syntax-checking' );
}

########################################################################
sub cpan_maker_llm_api_key_helper {
########################################################################
  my ($self) = @_;

  return $self->get_value( 'cpan-maker', 'llm-api-key-helper' );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CPAN::Maker::ConfigReader - Read CPAN::Maker configuration from an INI file

=head1 SYNOPSIS

  use CPAN::Maker::ConfigReader;

  # uses ~/.gitconfig by default
  my $reader = CPAN::Maker::ConfigReader->new;

  # or specify a file explicitly
  my $reader = CPAN::Maker::ConfigReader->new('/path/to/.cpan-makerrc');

  # or set CPAN_MAKER_CONFIG in the environment
  # CPAN_MAKER_CONFIG=~/.cpan-makerrc
  my $reader = CPAN::Maker::ConfigReader->new;

  print $reader->user_name;
  print $reader->cpan_maker_basedir;

=head1 DESCRIPTION

C<CPAN::Maker::ConfigReader> reads configuration for the
C<CPAN::Maker> build system from an INI-format file. By default it
reads from the user's global F<~/.gitconfig> file, which means no
additional configuration is required for most developers who already
have git set up.

For users who prefer a dedicated configuration file or who do not use
git, any properly formatted INI file can be used instead. See
L</CONFIGURATION FILE> for the expected format.

=head1 CONFIGURATION FILE

The configuration file uses standard INI format as read by
L<Config::Tiny>. The following sections and keys are recognized:

=head2 [user]

  [user]
      name   = First Last
      email  = you@example.com
      github = your-github-username

=over 4

=item C<name>

Your full name. Used to populate the author field in generated module
stubs and F<buildspec.yml>.

=item C<email>

Your email address. Used in generated module stubs, F<buildspec.yml>,
and the bugtracker C<mailto> field when C<--resources github> is
specified.

=item C<github>

Your GitHub username. Used to construct repository, homepage, and
bugtracker URLs when C<--resources github> is specified.

=back

=head2 [cpan-maker]

  [cpan-maker]
      basedir            = /home/you/git
      resources          = github
      syntax-checking    = on
      perltidyrc         = /home/you/.perltidyrc
      perlcriticrc       = /home/you/.perlcriticrc
      llm-api-key-helper = cat ~/.ssh/anthropic-api-key
      max-tokens         = 4096

=over 4

=item C<basedir>

The directory in which new projects are created. Equivalent to passing
C<--basedir> on the command line.

=item C<resources>

Controls generation of the F<resources> file. Currently only C<github>
is supported. Equivalent to passing C<--resources github> on the
command line.

=item C<syntax-checking>

Set to C<on> to enable Perl syntax checking during the build via
C<perl -wc> in the C<%.pm> and C<%.pl> pattern rules. See
L<CPAN::Maker::Bootstrapper/EXTENDING THE BUILD SYSTEM> for details.

=item C<perltidyrc>

Path to a F<.perltidyrc> configuration file. When set, enables
C<perltidy> checking in the build system pattern rules.

=item C<perlcriticrc>

Path to a F<.perlcriticrc> configuration file. When set, enables
C<perlcritic> checking in the build system pattern rules.

=item C<llm-api-key-helper>

A shell command whose output is used as the LLM API key. Executed when
no key is passed directly and C<LLM_API_KEY> is not set in the environment.
The command should print the key and nothing else. The file it reads should
be chmod 600.

Example: cat ~/.ssh/anthropic-api-key

=back

=head1 METHODS

=head2 new

  my $reader = CPAN::Maker::ConfigReader->new;
  my $reader = CPAN::Maker::ConfigReader->new($file);

Creates a new C<ConfigReader> instance. The configuration file is
resolved in the following order:

=over 4

=item 1. The C<$file> argument if provided

=item 2. The C<CPAN_MAKER_CONFIG> environment variable

=item 3. F<~/.gitconfig>

=back

Dies if the resolved file does not exist or cannot be read.

=head2 get_value

  my $val = $reader->get_value($section, $key);

Low-level accessor for any section and key in the config file. Useful
for reading project-specific keys beyond those C<ConfigReader> knows
about.

=head2 user_name

Returns C<name> from the C<[user]> section.

=head2 user_email

Returns C<email> from the C<[user]> section.

=head2 user_github

Returns C<github> from the C<[user]> section.

=head2 cpan_maker_basedir

Returns C<basedir> from the C<[cpan-maker]> section.

=head2 cpan_llm_api_key_helper

Bash snippet or the name of an executable script that provides the LLM
API key.

=head2 max-tokens

The maxium number of tokens output tokens.

=head2 cpan_maker_perltidyrc

Returns C<perltidyrc> from the C<[cpan-maker]> section.

=head2 cpan_maker_perlcriticrc

Returns C<perlcriticrc> from the C<[cpan-maker]> section.

=head2 cpan_maker_resources

Returns C<resources> from the C<[cpan-maker]> section.

=head2 cpan_maker_syntax_checking

Returns C<syntax-checking> from the C<[cpan-maker]> section.


=head1 ENVIRONMENT

=over 4

=item C<CPAN_MAKER_CONFIG>

Path to the configuration file. Used when no file is passed to
C<new>. Allows the config file location to be set once in your shell
profile:

 export CPAN_MAKER_CONFIG=~/.cpan-makerrc

=back

=head1 SEE ALSO

L<CPAN::Maker::Bootstrapper> - the scaffolding tool that uses this module

L<Config::Tiny> - the INI file parser underlying this module

=head1 AUTHOR

Rob Lauer - E<lt>rlauer@treasurersbriefcase.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
