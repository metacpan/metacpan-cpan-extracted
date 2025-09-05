package ClarID::Tools::Command::validate;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8); # <-- turn on UTF-8 for STDIN/STDOUT/STDERR
use feature 'say';
use File::Spec::Functions qw(catfile);
use Moo;
use MooX::Options
  auto_help => 1,
  usage     => 'pod',
  version   => $ClarID::Tools::VERSION;
use YAML::XS        qw(LoadFile);
use JSON::XS   qw(decode_json);
use Path::Tiny      qw(path);
use ClarID::Tools::Validator;
# Tell App::Cmd this is a command
use App::Cmd::Setup -command;
use namespace::autoclean;

# CLI options
# NB: Invalid parameter values (e.g., --format=foo) trigger App::Cmd usage/help
# This hides the detailed Types::Standard error  
# Fix by overriding usage_error/options_usage  
option codebook => (
  is       => 'ro',
  format   => 's',
  required => 1,
  doc      => 'path to your codebook.yaml',
);

option schema => (
  is       => 'ro',
  format   => 's',
  required => 1,
  default  => sub { catfile( $ClarID::Tools::share_dir, 'clarid-codebook-schema.json' ) },
  doc      => 'path to JSON Schema file',
);

option debug => (
  is       => 'ro',
  is_flag  => 1,
  default  => sub { 0 },
  doc      => 'self-validate the schema before use',
);
sub abstract { "validate a codebook against its JSON schema" }

sub execute {
    my ($self, $opts, @args) = @_;

    my $cb_data    = LoadFile( $self->codebook );
    my $schema_txt = path( $self->schema )->slurp_utf8;
    my $schema     = decode_json( $schema_txt );

    ClarID::Tools::Validator::validate_codebook(
      $cb_data,
      $schema,
      $self->debug,
    );

    say "✅ Codebook is valid";
}

1;
