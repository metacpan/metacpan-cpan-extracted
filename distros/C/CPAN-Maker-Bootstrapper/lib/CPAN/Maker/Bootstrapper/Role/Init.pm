package CPAN::Maker::Bootstrapper::Role::Init;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use Cwd qw(abs_path getcwd);
use Data::Dumper;
use English qw(-no_match_vars);
use File::ShareDir qw(dist_dir);

use Role::Tiny;

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my ($dist) = split /[.]/xsm, 'CPAN::Maker::Bootstrapper';
  $dist =~ s/::/-/xmsg;

  $self->set_dist_dir( dist_dir($dist) );

  $self->_init_config;

  my $basedir = $self->get_basedir;

  die sprintf "ERROR: basedir [%s] is not a directory\n", $basedir
    if $basedir && !-d $basedir;

  $basedir //= abs_path(getcwd);
  $self->set_basedir( abs_path($basedir) );

  if ( $self->get_import ) {
    $self->_import_file_listing;
    $self->get_logger->debug( Dumper( [ listing => $self->get_import_file_listing ] ) );
  }

  $self->set_max_diff_files( $self->get_max_diff_files // $MAX_DIFF_FILES );

  if ( $self->get_color ) {
    eval {
      require Term::ANSIColor;
      Term::ANSIColor->import('colored');
      $self->set_color($TRUE);
    };

  }

  return;
}

########################################################################
sub _init_config {
########################################################################
  my ($self) = @_;

  require CPAN::Maker::Bootstrapper::ConfigReader;

  # Example usage:
  my $reader = eval { CPAN::Maker::Bootstrapper::ConfigReader->new( $self->get_config ); };

  if ($EVAL_ERROR) {
    warn "WARNING: could not load config file: $EVAL_ERROR Using defaults.\n";
  }

  {  # the one legit and allowable use of postfix if!
    ## no critic (ProhibitPostfixControls)
    $self->set_username( $reader ? $reader->user_name : q{} )
      if !$self->get_username;

    $self->set_email( $reader ? $reader->user_email : q{} )
      if !$self->get_email;

    $self->set_github_user( $reader ? $reader->user_github : q{} )
      if !$self->get_github_user;

    $self->set_resources( $reader ? $reader->cpan_maker_resources : undef )
      if !$self->get_resources;

    $self->set_basedir( $reader ? $reader->cpan_maker_basedir : undef )
      if !$self->get_basedir;

    $self->set_llm_api_key_helper( $reader ? $reader->cpan_maker_llm_api_key_helper : undef )
      if !$self->get_llm_api_key_helper;

    $self->set_max_tokens( $reader ? $reader->cpan_maker_max_tokens : undef )
      if !$self->get_max_tokens;
  }

  return;
}

1;

__END__
