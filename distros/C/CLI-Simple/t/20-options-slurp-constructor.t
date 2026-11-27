use strict;
use warnings;

use CLI::Simple;
use File::Temp qw(tempfile);
use Test::More;

{
  package Local::SlurpConstructor;
  use parent qw(CLI::Simple);

  sub cmd_run { return 0; }

  sub init {
    my ($self) = @_;
    $self->{value_at_init} = $self->get_config;
    return $self;
  }
}

subtest 'slurp and callback run before init' => sub {
  my ( $fh, $path ) = tempfile(UNLINK => 1);
  print {$fh} "hello\n";
  close $fh;
  local @ARGV = ( '--config', $path, 'run' );
  my $app = Local::SlurpConstructor->new(
    options => {
      'config|c=s' => {
        type => 'file', slurp => 1, required => 1,
        finalize => sub {
          my ( $self, $value ) = @_;
          isa_ok( $self, 'Local::SlurpConstructor' );
          return uc $value;
        },
      },
    },
    commands => { run => \&Local::SlurpConstructor::cmd_run },
  );
  is( $app->{value_at_init}, "HELLO\n", 'init sees transformed file contents' );
};

done_testing;
1;
