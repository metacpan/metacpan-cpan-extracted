use 5.008000;
use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;
use Config::Processor;

my $CONFIG_PROCESSOR = Config::Processor->new(
  dirs => [ qw( t/etc ) ],
);

t_missing_extension($CONFIG_PROCESSOR);
t_unknown_extension($CONFIG_PROCESSOR);
t_cant_locate_file();
t_cant_parse_file($CONFIG_PROCESSOR);
t_invalid_array_element_index($CONFIG_PROCESSOR);


sub t_missing_extension {
  my $config_processor = shift;

  like(
    exception { $config_processor->load( qw( foo ) ) },
    qr/^File extension not specified\./, 'missing extension'
  );

  return;
}

sub t_unknown_extension {
  my $config_processor = shift;

  like(
    exception { $config_processor->load( qw( foo.xml ) ) },
    qr/^Unknown file extension "\.xml" encountered\./, 'unknown extension'
  );

  return;
}

sub t_cant_locate_file {
  my $config_processor = Config::Processor->new(
    dirs => [ qw( t/etc my/etc ) ],
  );

  like(
    exception { $config_processor->load( 'foo.json bar.yml' ) },
    qr/^Can't locate/, 'unknown extension'
  );

  return;
}

sub t_cant_parse_file {
  my $config_processor = shift;

  like(
    exception { my $c = $config_processor->load( qw( invalid.yml ) ) },
    qr/^Can't parse/, "can't parse file; YAML"
  );

  like(
    exception { my $c = $config_processor->load( qw( invalid.json ) ) },
    qr/^Can't parse/, "can't parse file; JSON"
  );

  return;
}

sub t_invalid_array_element_index {
  my $config_processor = shift;

  like(
    exception {
      $config_processor->load( qw( foo_A.yaml ),
        { foo => {
            param_G => { var => 'foo.param4.param4_1' },
          },
        }
      );
    },
    qr/^Can't resolve variable "foo\.param4\.param4_1";/,
    'invalid array element index'
  );

  return;
}
