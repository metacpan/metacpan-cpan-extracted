use strict;
use warnings;
use File::Temp ();
use Test::More;

plan tests => 30;

my ($config);
my %data = ( global => { profile => 'profile.json' } );

#--------------------------------------------------------------------------#

require_ok( 'CPAN::Testers::Config' );

my $temp_home = File::Temp->newdir;
ok( local $ENV{HOME} = $temp_home,
  "setting \$ENV{HOME} to temp directory for testing"
);
is( CPAN::Testers::Config->config_dir,
    File::Spec->catdir( $ENV{HOME}, '.cpantesters' ),
    "config_dir() gives expected directory"
);

#--------------------------------------------------------------------------#

SKIP: {
  eval { CPAN::Testers::Config->new(%data)->write };
  is( $@, '', "wrote config file without error" )
    or skip "no config to read", 3;
  $config = eval { CPAN::Testers::Config->read };
  is( $@, '', "read config file without error" );
  isa_ok( $config, 'CPAN::Testers::Config' );
  is( $config->{global}{profile}, 'profile.json', "found 'profile' in [global]" );

}

#--------------------------------------------------------------------------#

{
  ok( local $ENV{CPAN_TESTERS_CONFIG} = File::Spec->rel2abs('bogusfile'),
    "setting CPAN_TESTERS_CONFIG to non-existant file"
  );
  is( CPAN::Testers::Config->config_file,
      $ENV{CPAN_TESTERS_CONFIG},
      "config_file() gives expected file (though it doesn't exist)"
  );
  $config = eval { CPAN::Testers::Config->read };
  like( $@, qr/Error reading '$ENV{CPAN_TESTERS_CONFIG}': No such file or directory/,
    "bogus file in CPAN_TESTERS_CONFIG gives error"
  );
}

#--------------------------------------------------------------------------#

SKIP: {
  ok( local $ENV{CPAN_TESTERS_DIR} = File::Temp->newdir,
    "setting CPAN_TESTERS_DIR to new temp config directory"
  );
  is( CPAN::Testers::Config->config_dir, $ENV{CPAN_TESTERS_DIR},
      "config_dir() gives expected directory"
  );

  eval { CPAN::Testers::Config->new(%data)->write };
  is( $@, '', "wrote config file without error" )
    or skip "no config to read", 3;
  $config = eval { CPAN::Testers::Config->read };
  is( $@, '', "read config file" );
  isa_ok( $config, 'CPAN::Testers::Config' );
  is( $config->{global}{profile}, 'profile.json', "found 'profile' in [global]" );
}

#--------------------------------------------------------------------------#

SKIP: {
  ok( local $ENV{CPAN_TESTERS_DIR} = File::Temp->newdir,
    "setting CPAN_TESTERS_DIR to new temp config directory"
  );
  is( CPAN::Testers::Config->config_dir, $ENV{CPAN_TESTERS_DIR},
      "config_dir() gives expected directory"
  );
  ok( local $ENV{CPAN_TESTERS_CONFIG} = 'custom.pl',
    "setting CPAN_TESTERS_CONFIG to relative filename"
  );
  is( CPAN::Testers::Config->config_file,
      File::Spec->catdir( $ENV{CPAN_TESTERS_DIR}, 'custom.pl' ),
      "config_file() gives expected file in CPAN_TESTERS_DIR"
  );

  eval { CPAN::Testers::Config->new(%data)->write };
  is( $@, '', "wrote config file without error" )
    or skip "no config to read", 3;
  $config = eval { CPAN::Testers::Config->read };
  is( $@, '', "read config file" );
  isa_ok( $config, 'CPAN::Testers::Config' );
  is( $config->{global}{profile}, 'profile.json', "found 'profile' in [global]" );
}

#--------------------------------------------------------------------------#

SKIP: {
  my $filename = File::Spec->catfile( $ENV{HOME}, 'custom.pl' );
  eval { CPAN::Testers::Config->new(%data)->write($filename) };
  is( $@, '', "wrote config file without error" )
    or skip "no config to read", 5;
  $config = eval { CPAN::Testers::Config->read($filename)};
  is( $@, '', "read config file without error" );
  isa_ok( $config, 'CPAN::Testers::Config' );
  is( $config->{global}{profile}, 'profile.json', "found 'profile' in [global]" );
  $config->{global}{profile} = 'other.json';
  eval { $config->read($filename)};
  is( $@, '', "re-read config file without error" );
  is( $config->{global}{profile}, 'profile.json', "found 'profile' in [global]" );
}

