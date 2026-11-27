use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;
use Role::Tiny::With;

{

  package Local::Slurp;
  use Role::Tiny::With;
  with 'CLI::Simple::Options';

  sub new {
    my ( $class, $metadata ) = @_;
    return bless { _cli_simple_option_metadata => $metadata }, $class;
  }

  sub get_config { return $_[0]->{config}; }
  sub set_config { $_[0]->{config} = $_[1]; return $_[0]->{config}; }
}

sub make_file {
  my ($contents) = @_;
  my ( $fh, $path ) = tempfile( UNLINK => 1 );
  print {$fh} $contents;
  close $fh;
  return ($path);
}

subtest 'slurp replaces pathname with contents' => sub {
  my $path = make_file("hello\nworld\n");
  my ( undef, $metadata ) = Local::Slurp->normalize_option_specs( { 'config=s' => { type => 'file', slurp => 1 }, } );
  my $obj = Local::Slurp->new($metadata);
  $obj->set_config($path);
  $obj->validate_options->finalize_options;
  is( $obj->get_config, "hello\nworld\n", 'contents replace pathname' );
  unlink $path;
};

subtest 'slurp then callback receives self and contents' => sub {
  my $path   = make_file('important');
  my $called = 0;
  my ( undef, $metadata ) = Local::Slurp->normalize_option_specs(
    { 'config=s' => {
        type     => 'file',
        slurp    => 1,
        finalize => sub {
          my ( $self, $value ) = @_;
          is( $self->get_config, $path,       'original pathname remains until completion' );
          is( $value,            'important', 'callback receives file content' );
          $called++;
          return { content => $value };
        },
      },
    }
  );
  my $obj = Local::Slurp->new($metadata);
  $obj->set_config($path);
  $obj->validate_options->finalize_options;
  is( $called, 1, 'callback called once' );
  is_deeply( $obj->get_config, { content => 'important' }, 'final value stored' );
  unlink $path;
};

subtest 'undefined optional option skips slurp' => sub {
  my ( undef, $metadata ) = Local::Slurp->normalize_option_specs( { 'config=s' => { type => 'file', slurp => 1 }, } );
  my $obj = Local::Slurp->new($metadata);
  $obj->validate_options->finalize_options;
  ok( !defined $obj->get_config, 'undefined remains undefined' );
};

subtest 'invalid declarations fail early' => sub {
  for my $entry (
    [ { slurp => 1 },                                        qr/slurp requires type 'file'/ ],
    [ { type => 'file', slurp => 'maybe' },                  qr/slurp must be 0 or 1/ ],
    [ { type => 'file', slurp => 1, collection => 'array' }, qr/slurp does not support collection/ ],
  ) {
    my ( $attrs, $error ) = @{$entry};
    my $ok = eval {
      Local::Slurp->normalize_option_specs( { 'config=s' => $attrs } );
      1;
    };
    ok( !$ok, 'invalid declaration rejected' );
    like( $@, $error, 'clear error' );
  }
};

subtest 'missing file and failed finalizer preserve pathname' => sub {
  my $path = make_file('data');
  my ( undef, $metadata ) = Local::Slurp->normalize_option_specs( { 'config=s' => { type => 'file', slurp => 1 }, } );
  my $obj = Local::Slurp->new($metadata);
  $obj->set_config($path);
  unlink $path;
  my $ok = eval { $obj->validate_options; 1 };
  ok( !$ok, 'missing path rejected in validation' );
  like( $@, qr/existing file/, 'validation error' );
  $ok = eval { $obj->finalize_options; 1 };
  ok( !$ok, 'missing file fails during slurp' );
  like( $@, qr/Slurp failed for option 'config'/, 'error names option' );
  is( $obj->get_config, $path, 'path not replaced on read failure' );
};

subtest 'empty file' => sub {
  my $path = make_file(q{});
  my ( undef, $metadata ) = Local::Slurp->normalize_option_specs( { 'config=s' => { type => 'file', slurp => 1 }, } );
  my $obj = Local::Slurp->new($metadata);
  $obj->set_config($path);
  $obj->validate_options->finalize_options;
  is( $obj->get_config, q{}, 'contents replaces pathname with empty string' );
  unlink $path;
};

done_testing;
1;
