use 5.008000;
use strict;
use warnings;

use Test::More tests => 10;
use Config::Processor;

my $CONFIG_PROCESSOR = Config::Processor->new(
  dirs => [ qw( t/etc ) ],
);

can_ok( $CONFIG_PROCESSOR, 'load' );

t_merging_yaml($CONFIG_PROCESSOR);
t_merging_json($CONFIG_PROCESSOR);
t_merging_mixed($CONFIG_PROCESSOR);
t_variable_interpolation_on($CONFIG_PROCESSOR);
t_variable_interpolation_off();
t_directive_processing_on($CONFIG_PROCESSOR);
t_directive_processing_off();
t_complete_processing($CONFIG_PROCESSOR);
t_env_exporting($CONFIG_PROCESSOR);

sub t_merging_yaml {
  my $config_processor = shift;

  my $t_config = $config_processor->load( qw( foo_A.yaml foo_B.yml ) );

  my $e_config = {
    foo => {
      param1 => 'foo_B:val1',
      param2 => 'foo_A:val2',

      param3 => {
        param3_1 => 'foo_B:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
      },

      param4 => [
        'foo_B:val4_1',
        'foo_B:val4_2',
      ],

      param5 => [
        'foo_B:val5_1',
        { param5_2_1 => 'foo_B:val5_2_1',
          param5_2_2 => 'foo_B:val5_2_2',
        },
      ],

      param6 => {
        param6_1 => 'foo_B:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'foo_B:val6_4',
      },
    },
  };

  is_deeply( $t_config, $e_config, 'merging; YAML' );
}

sub t_merging_json {
  my $config_processor = shift;

  my $t_config = $config_processor->load( qw( bar_A.json bar_B.jsn ) );

  my $e_config = {
    bar => {
      param1 => 'bar_B:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'bar_B:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'bar_B:val3_3',
      },

      param4 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param5 => [
        'bar_B:val5_1',
        { param5_2_1 => 'bar_B:val5_2_1',
          param5_2_2 => 'bar_B:val5_2_2',
        },
      ],

      param6 => {
        param6_1 => 'bar_B:val6_1',
        param6_2 => [
          'bar_B:val6_2_1',
          'bar_B:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_4 => 'bar_B:val6_4',
      },
    },
  };

  is_deeply( $t_config, $e_config, 'merging; JSON' );

  return;
}

sub t_merging_mixed {
  my $config_processor = shift;

  my $t_config = $config_processor->load( qw( foo_A.yaml bar_A.json zoo.yml ),
    { foo => {
        param1 => 'hard:val1',

        param3 => {
          param3_3 => "hard:val3_3",
          param3_5 => "hard:val3_5",
        },
      },

      bar => {
        param1 => 'hard:val1',

        param3 => {
          param3_3 => "hard:val3_3",
          param3_5 => "hard:val3_5",
        },
      },
    }
  );

  my $e_config = {
    foo => {
      param1 => 'hard:val1',
      param2 => 'foo_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'hard:val3_3',
        param3_4 => 'zoo:val3_4',
        param3_5 => 'hard:val3_5',
      },

      param4 => [
        'foo_A:val4_1',
        'foo_A:val4_2',
      ],

      param5 => [
        'foo_A:val5_1',
        { param5_2_1 => 'foo_A:val5_2_1',
          param5_2_2 => 'foo_A:val5_2_2',
        },
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'foo_A:val6_2_1',
          'foo_A:val6_2_2'
        ],
        param6_3 => 'foo_A:val6_3',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2'
        ],
      },
    },

    bar => {
      param1 => 'hard:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'hard:val3_3',
        param3_4 => 'zoo:val3_4',
        param3_5 => 'hard:val3_5',
      },

      param4 => [
        'bar_A:val4_1',
        'bar_A:val4_2',
      ],

      param5 => [
        'bar_A:val5_1',
        { param5_2_1 => 'bar_A:val5_2_1',
          param5_2_2 => 'bar_A:val5_2_2',
        },
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'bar_A:val6_2_1',
          'bar_A:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ]
      },
    },
  };

  is_deeply( $t_config, $e_config, 'merging; mixed' );

  return;
}

sub t_variable_interpolation_on {
  my $config_processor = shift;

  my $t_config = $config_processor->load(
      qw( foo_A.yaml foo_B.yml bar_A.json bar_B.jsn zoo.yml jar.json ) );

  my $e_config = {
    foo => {
      param1 => 'foo_B:val1',
      param2 => 'foo_A:val2',

      param4 => [
        'foo_B:val4_1',
        'foo_B:val4_2',
      ],

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param5 => [
        'foo_B:val5_1',
        { param5_2_1 => 'foo_B:val5_2_1',
          param5_2_2 => 'foo_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'foo_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    bar => {
      param1 => 'bar_B:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'bar_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param4 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param5 => [
        'bar_B:val5_1',
        { param5_2_1 => 'bar_B:val5_2_1',
          param5_2_2 => 'bar_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'bar_B:val6_2_1',
          'bar_B:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_4 => 'bar_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    jar => {
      param1 => 'jar:foo_B:val1',
      param2 => 'jar:foo_A:val2; jar:bar_A:val2',

      param3 => {
        param3_1 => 'jar:zoo:val3_1; jar:bar_B:val3_3',
        param3_2 => 'jar:foo_B:val3_3; jar:zoo:val3_1',
      },

      param4 => [
        'jar:foo_B:val4_1; jar:bar_B:val4_2',
        'jar:bar_B:val4_2; jar:foo_B:val4_1',
        'jar:foo_B:val6_2_1; jar:bar_B:val6_2_2',
        'jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',
        'jar:zoo:val6_5_1; jar:zoo:val6_5_2',
      ],

      param5 => [
        'jar:jar:foo_B:val1; jar:jar:foo_A:val2; jar:bar_A:val2',
        { param5_2_2 => 'jar:jar:foo_B:val4_1; jar:bar_B:val4_2;'
              . ' jar:jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',
          param5_2_1 => 'jar:jar:zoo:val3_1; jar:bar_B:val3_3;'
              . ' jar:jar:foo_B:val3_3; jar:zoo:val3_1',
        },
        'jar:jar:bar_B:val4_2; jar:foo_B:val4_1; jar:jar:zoo:val6_5_1;'
            . ' jar:zoo:val6_5_2',
      ],

      param6 => {
        param6_1 =>
            'jar:jar:jar:foo_B:val1; jar:jar:foo_A:val2; jar:bar_A:val2;'
                .' jar:jar:jar:zoo:val3_1; jar:bar_B:val3_3;'
                .' jar:jar:foo_B:val3_3; jar:zoo:val3_1',
        param6_2 => [
          'jar:jar:jar:foo_B:val4_1; jar:bar_B:val4_2; jar:jar:bar_B:val6_2_2;'
              . ' jar:foo_B:val6_2_1',
          'jar:jar:jar:bar_B:val4_2; jar:foo_B:val4_1; jar:jar:zoo:val6_5_1;'
              . ' jar:zoo:val6_5_2',
        ],
        param6_3 => 'jar:jar:jar:jar:foo_B:val4_1; jar:bar_B:val4_2;'
            . ' jar:jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',

        param6_4 => 'jar:${foo.param1}',

        param6_5 => 'jar:',
        param6_6 => 'jar:',
        param6_7 => 'jar:',
        param6_8 => 'jar:',
      },

      param7 => {
        param7_1 => 'jar:val7_1',
        param7_2 => 'jar:val7_2',
        param7_3 => 'jar:jar:val7_1; jar:jar:val7_2',
        param7_4 => 'jar:jar:jar:val7_1; jar:jar:val7_2',
        param7_5 => 'jar:jar:zoo:val3_1; jar:bar_B:val3_3'
            . ' jar:jar:bar_B:val4_2; jar:foo_B:val4_1',
      },
    },
  };

  is_deeply( $t_config, $e_config, 'variable interpolation: on' );

  return;
}

sub t_variable_interpolation_off {
  my $config_processor = Config::Processor->new(
    dirs                  => [ qw( t/etc ) ],
    interpolate_variables => 0,
  );

  my $t_config = $config_processor->load(
      qw( foo_A.yaml foo_B.yml bar_A.json bar_B.jsn zoo.yml jar.json ) );

  my $e_config = {
    foo => {
      param1 => 'foo_B:val1',
      param2 => 'foo_A:val2',

      param4 => [
        'foo_B:val4_1',
        'foo_B:val4_2',
      ],

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param5 => [
        'foo_B:val5_1',
        { param5_2_1 => 'foo_B:val5_2_1',
          param5_2_2 => 'foo_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'foo_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    bar => {
      param1 => 'bar_B:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'bar_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param4 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param5 => [
        'bar_B:val5_1',
        { param5_2_1 => 'bar_B:val5_2_1',
          param5_2_2 => 'bar_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'bar_B:val6_2_1',
          'bar_B:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_4 => 'bar_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    jar => {
      param1 => 'jar:${foo.param1}',
      param2 => 'jar:${foo.param2}; jar:${ bar.param2 }',

      param3 => {
        param3_1 => 'jar:${foo.param3.param3_1};'
            . ' jar:${bar.param3.param3_3}',
        param3_2 => 'jar:${ foo.param3 . param3_3 };'
            . ' jar:${bar.param3.param3_1}',
      },

      param4 => [
        'jar:${foo.param4.0}; jar:${bar.param4.1}',
        'jar:${bar.param4.1}; jar:${foo.param4.0}',
        'jar:${foo.param6.param6_2.0}; jar:${bar.param6.param6_2.1}',
        'jar:${bar.param6.param6_2.1}; jar:${foo.param6.param6_2.0}',
        'jar:${foo.param6.param6_5.0}; jar:${bar.param6.param6_5.1}',
      ],

      param5 => [
        'jar:${jar.param1}; jar:${jar.param2}',
        { param5_2_1 => 'jar:${jar.param3.param3_1};'
            . ' jar:${jar.param3.param3_2}',
          param5_2_2 => 'jar:${jar.param4.0}; jar:${jar.param4.3}',
        },
        'jar:${jar.param4.1}; jar:${jar.param4.4}',
      ],

      param6 => {
        param6_1 => 'jar:${jar.param5.0}; jar:${jar.param5.1.param5_2_1}',
        param6_2 => [
          'jar:${jar.param5.1.param5_2_2}',
          'jar:${jar.param5.2}',
        ],
        param6_3 => 'jar:${jar.param6.param6_2.0}',

        param6_4 => 'jar:$${foo.param1}',

        param6_5 => 'jar:${foox.param3.param3_1}',
        param6_6 => 'jar:${foo.param3X.param3_1}',
        param6_7 => 'jar:${foo.param3.param3X}',
        param6_8 => 'jar:${jar.param5.3}',
      },

      param7 => {
        param7_1 => 'jar:val7_1',
        param7_2 => 'jar:val7_2',
        param7_3 => 'jar:${.param7_1}; jar:${.param7_2}',
        param7_4 => 'jar:${.param7_3}',
        param7_5 => 'jar:${..param3.param3_1} jar:${..param4.1}',
      }
    }
  };

  is_deeply( $t_config, $e_config, 'variable interpolation: off' );

  return;
}

sub t_directive_processing_on {
  my $config_processor = shift;

  my $t_config = $config_processor->load(
      qw( foo_A.yaml foo_B.yml bar_A.json bar_B.jsn zoo.yml moo.yml ) );

  my $e_config = {
    foo => {
      param1 => 'foo_B:val1',
      param2 => 'foo_A:val2',

      param4 => [
        'foo_B:val4_1',
        'foo_B:val4_2',
      ],

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param5 => [
        'foo_B:val5_1',
        { param5_2_1 => 'foo_B:val5_2_1',
          param5_2_2 => 'foo_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'foo_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    bar => {
      param1 => 'bar_B:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'bar_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param4 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param5 => [
        'bar_B:val5_1',
        { param5_2_1 => 'bar_B:val5_2_1',
          param5_2_2 => 'bar_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'bar_B:val6_2_1',
          'bar_B:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_4 => 'bar_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    moo => {
      param1 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param2 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param3 => [
        { param3_1 => 'zoo:val3_1',
          param3_2 => 'foo_A:val3_2',
          param3_3 => 'foo_B:val3_3',
          param3_4 => 'zoo:val3_4',
        },
        [ 'bar_B:val4_1',
          'bar_B:val4_2',
        ],
      ],

      param4 => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_A => {
        param4_1 => 'moo:val4_A_1',
        param4_2 => 'moo:val4_A_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_A_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_B => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_B_3',
        param4_4 => 'moo:val4_B_4',
        param4_5 => 'moo:val4_B_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_C => {
        param4_1 => 'moo:val4_C_1',
        param4_2 => 'moo:val4_A_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_A_5',
        param4_6 => 'moo:val4_C_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_D => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_D_3',
        param4_4 => 'moo:val4_B_4',
        param4_5 => 'moo:val4_B_5',
        param4_6 => 'moo:val4_D_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_E => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_E_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_F => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_F_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_G => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_E_5',
        param4_6 => 'moo:val4_G_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_H => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_F_5',
        param4_6 => 'moo:val4_H_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param5 => {
        param5_1 => {
          param5_1_2 => 'moo_A:val5_1_2',
          param5_1_1 => 'moo_A:val5_1_1'
        },

        param5_2 => {
          param5_2_1 => 'moo_B:val5_2_1',
          param5_2_2 => 'moo_B:val5_2_2'
        },

        param5_3 => {
          param5_1_1 => 'moo_A:val5_1_1',
          param5_1_2 => 'moo_A:val5_1_2',
          param5_2_1 => 'moo_B:val5_2_1',
          param5_2_2 => 'moo_B:val5_2_2',
          param6_6   => 'moo_C:val6_6',
          param6_7   => 'moo_C:val6_7',
        },
      },

      param6_A => {
        param6_1 => 'moo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'moo:val6_4',
        param6_5 => 'moo:val6_5',
        param6_6 => 'moo:val6_6',
        param6_7 => 'moo_C:val6_7',
      },

      param6_B => {
        param6_1 => 'moo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2'
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'moo:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
        param6_6 => 'moo_C:val6_6',
        param6_7 => 'moo_C:val6_7',
      },

      param6_C => {
        param6_1 => 'moo:val6_C_1',
        param6_2 => 'moo:val6_C_2',
      },

      param6_D => 'moo:val6_D_2',

      param6_E => {
        param6_1 => 'moo:val6_E_1',
        param6_2 => 'moo:val6_E_2',
      },

      param6_F => 'moo:val6_F_3',
    },
  };

  is_deeply( $t_config, $e_config, 'directive processing: on' );

  return;
}

sub t_directive_processing_off {
  my $config_processor = Config::Processor->new(
    dirs               => [ qw( t/etc ) ],
    process_directives => 0,
  );

  my $t_config = $config_processor->load(
      qw( foo_A.yaml foo_B.yml bar_A.json bar_B.jsn zoo.yml moo.yml ) );

  my $e_config = {
    foo => {
      param1 => 'foo_B:val1',
      param2 => 'foo_A:val2',

      param4 => [
        'foo_B:val4_1',
        'foo_B:val4_2',
      ],

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param5 => [
        'foo_B:val5_1',
        { param5_2_1 => 'foo_B:val5_2_1',
          param5_2_2 => 'foo_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'foo_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    bar => {
      param1 => 'bar_B:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'bar_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param4 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param5 => [
        'bar_B:val5_1',
        { param5_2_1 => 'bar_B:val5_2_1',
          param5_2_2 => 'bar_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'bar_B:val6_2_1',
          'bar_B:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_4 => 'bar_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    moo => {
      param1 => { var => 'foo.param3' },
      param2 => { var => 'bar.param4' },

      param3 => [
        { var => 'foo.param3' },
        { var => 'bar.param4' },
      ],

      param4 => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_A => {
        underlay => { var => 'moo.param4' },
        param4_1 => 'moo:val4_A_1',
        param4_2 => 'moo:val4_A_2',
        param4_5 => 'moo:val4_A_5',
      },

      param4_B => {
        underlay => { var => 'moo.param4' },
        param4_3 => 'moo:val4_B_3',
        param4_4 => 'moo:val4_B_4',
        param4_5 => 'moo:val4_B_5',
      },

      param4_C => {
        underlay => { var => 'moo.param4_A' },
        param4_1 => 'moo:val4_C_1',
        param4_6 => 'moo:val4_C_6',
      },

      param4_D => {
        underlay => { var => 'moo.param4_B' },
        param4_3 => 'moo:val4_D_3',
        param4_6 => 'moo:val4_D_6',
      },

      param4_E => {
        param4_1 => 'moo:val4_E_1',
        param4_2 => 'moo:val4_E_2',
        param4_5 => 'moo:val4_E_5',
        overlay  => { var => 'moo.param4' },
      },

      param4_F => {
        param4_3 => 'moo:val4_F_3',
        param4_4 => 'moo:val4_F_4',
        param4_5 => 'moo:val4_F_5',
        overlay  => { var => 'moo.param4' },
      },

      param4_G => {
        param4_1 => 'moo:val4_G_1',
        param4_6 => 'moo:val4_G_6',
        overlay  => { var => 'moo.param4_E' },
      },

      param4_H => {
        param4_3 => 'moo:val4_H_3',
        param4_6 => 'moo:val4_H_6',
        overlay   => { var => 'moo.param4_F' },
      },

      param5 => {
        param5_1 => { include => 'includes/moo_A.yml' },
        param5_2 => { include => 'includes/moo_B.json' },
        param5_3 => { include => 'includes/*' },
      },

      param6_A => {
        underlay => [
          { var     => 'foo.param6' },
          { include => 'includes/moo_C.yml' },
          { param6_1 => 'moo:val6_1',
            param6_4 => 'moo:val6_4',
          },
        ],
        param6_5 => 'moo:val6_5',
        param6_6 => 'moo:val6_6',
      },

      param6_B => {
        param6_5 => 'moo:val6_5',
        param6_6 => 'moo:val6_6',
        overlay => [
          { var     => 'foo.param6' },
          { include => 'includes/moo_C.yml' },
          { param6_1 => 'moo:val6_1',
            param6_4 => 'moo:val6_4',
          }
        ],
      },

      param6_C => {
        underlay => [
          'moo:val6_C_1',
          'moo:val6_C_2',
        ],
        param6_2 => 'moo:val6_C_2',
        param6_1 => 'moo:val6_C_1',
      },

       param6_D => {
        param6_1 => 'moo:val6_D_1',
        param6_2 => 'moo:val6_D_2',
        overlay  => [
          'moo:val6_D_1',
          'moo:val6_D_2',
        ],
      },

      param6_E => {
        underlay => 'moo:val6_E_3',
        param6_1 => 'moo:val6_E_1',
        param6_2 => 'moo:val6_E_2',
      },

      param6_F => {
        param6_1 => 'moo:val6_F_1',
        param6_2 => 'moo:val6_F_2',
        overlay  => 'moo:val6_F_3',
      },
    },
  };

  is_deeply( $t_config, $e_config, 'directive processing: off' );

  return;
}

sub t_complete_processing {
  my $config_processor = shift;

  my $t_config = $config_processor->load(
      qw( foo_A.yaml foo_B.yml bar_A.json bar_B.jsn zoo.yml jar.json moo.yml
      yar.yml ) );

  my $e_config = {
    foo => {
      param1 => 'foo_B:val1',
      param2 => 'foo_A:val2',

      param4 => [
        'foo_B:val4_1',
        'foo_B:val4_2',
      ],

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param5 => [
        'foo_B:val5_1',
        { param5_2_1 => 'foo_B:val5_2_1',
          param5_2_2 => 'foo_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'foo_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    bar => {
      param1 => 'bar_B:val1',
      param2 => 'bar_A:val2',

      param3 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'bar_A:val3_2',
        param3_3 => 'bar_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param4 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param5 => [
        'bar_B:val5_1',
        { param5_2_1 => 'bar_B:val5_2_1',
          param5_2_2 => 'bar_B:val5_2_2',
        }
      ],

      param6 => {
        param6_1 => 'zoo:val6_1',
        param6_2 => [
          'bar_B:val6_2_1',
          'bar_B:val6_2_2',
        ],
        param6_3 => 'bar_A:val6_3',
        param6_4 => 'bar_B:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
      },
    },

    jar => {
      param1 => 'jar:foo_B:val1',
      param2 => 'jar:foo_A:val2; jar:bar_A:val2',

      param3 => {
        param3_1 => 'jar:zoo:val3_1; jar:bar_B:val3_3',
        param3_2 => 'jar:foo_B:val3_3; jar:zoo:val3_1',
      },

      param4 => [
        'jar:foo_B:val4_1; jar:bar_B:val4_2',
        'jar:bar_B:val4_2; jar:foo_B:val4_1',
        'jar:foo_B:val6_2_1; jar:bar_B:val6_2_2',
        'jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',
        'jar:zoo:val6_5_1; jar:zoo:val6_5_2',
      ],

      param5 => [
        'jar:jar:foo_B:val1; jar:jar:foo_A:val2; jar:bar_A:val2',
        { param5_2_2 => 'jar:jar:foo_B:val4_1; jar:bar_B:val4_2;'
              . ' jar:jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',
          param5_2_1 => 'jar:jar:zoo:val3_1; jar:bar_B:val3_3;'
              . ' jar:jar:foo_B:val3_3; jar:zoo:val3_1',
        },
        'jar:jar:bar_B:val4_2; jar:foo_B:val4_1; jar:jar:zoo:val6_5_1;'
            . ' jar:zoo:val6_5_2',
      ],

      param6 => {
        param6_1 =>
            'jar:jar:jar:foo_B:val1; jar:jar:foo_A:val2; jar:bar_A:val2;'
                .' jar:jar:jar:zoo:val3_1; jar:bar_B:val3_3;'
                .' jar:jar:foo_B:val3_3; jar:zoo:val3_1',
        param6_2 => [
          'jar:jar:jar:foo_B:val4_1; jar:bar_B:val4_2;'
              . ' jar:jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',
          'jar:jar:jar:bar_B:val4_2; jar:foo_B:val4_1;'
              . ' jar:jar:zoo:val6_5_1; jar:zoo:val6_5_2',
        ],
        param6_3 => 'jar:jar:jar:jar:foo_B:val4_1; jar:bar_B:val4_2;'
            . ' jar:jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',

        param6_4 => 'jar:${foo.param1}',

        param6_5 => 'jar:',
        param6_6 => 'jar:',
        param6_7 => 'jar:',
        param6_8 => 'jar:',
      },

      param7 => {
        param7_1 => 'jar:val7_1',
        param7_2 => 'jar:val7_2',
        param7_3 => 'jar:jar:val7_1; jar:jar:val7_2',
        param7_4 => 'jar:jar:jar:val7_1; jar:jar:val7_2',
        param7_5 => 'jar:jar:zoo:val3_1; jar:bar_B:val3_3'
            . ' jar:jar:bar_B:val4_2; jar:foo_B:val4_1',
      },
    },

    moo => {
      param1 => {
        param3_1 => 'zoo:val3_1',
        param3_2 => 'foo_A:val3_2',
        param3_3 => 'foo_B:val3_3',
        param3_4 => 'zoo:val3_4',
      },

      param2 => [
        'bar_B:val4_1',
        'bar_B:val4_2',
      ],

      param3 => [
        { param3_1 => 'zoo:val3_1',
          param3_2 => 'foo_A:val3_2',
          param3_3 => 'foo_B:val3_3',
          param3_4 => 'zoo:val3_4',
        },
        [ 'bar_B:val4_1',
          'bar_B:val4_2',
        ],
      ],

      param4 => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_A => {
        param4_1 => 'moo:val4_A_1',
        param4_2 => 'moo:val4_A_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_A_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_B => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_B_3',
        param4_4 => 'moo:val4_B_4',
        param4_5 => 'moo:val4_B_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_C => {
        param4_1 => 'moo:val4_C_1',
        param4_2 => 'moo:val4_A_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_A_5',
        param4_6 => 'moo:val4_C_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_D => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_D_3',
        param4_4 => 'moo:val4_B_4',
        param4_5 => 'moo:val4_B_5',
        param4_6 => 'moo:val4_D_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_E => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_E_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_F => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_F_5',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_G => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_E_5',
        param4_6 => 'moo:val4_G_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param4_H => {
        param4_1 => 'moo:val4_1',
        param4_2 => 'moo:val4_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_F_5',
        param4_6 => 'moo:val4_H_6',
        param4_7 => 1,
        param4_8 => '',
      },

      param5 => {
        param5_1 => {
          param5_1_2 => 'moo_A:val5_1_2',
          param5_1_1 => 'moo_A:val5_1_1'
        },

        param5_2 => {
          param5_2_1 => 'moo_B:val5_2_1',
          param5_2_2 => 'moo_B:val5_2_2'
        },

        param5_3 => {
          param5_1_1 => 'moo_A:val5_1_1',
          param5_1_2 => 'moo_A:val5_1_2',
          param5_2_1 => 'moo_B:val5_2_1',
          param5_2_2 => 'moo_B:val5_2_2',
          param6_6   => 'moo_C:val6_6',
          param6_7   => 'moo_C:val6_7',
        },
      },

      param6_A => {
        param6_1 => 'moo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'moo:val6_4',
        param6_5 => 'moo:val6_5',
        param6_6 => 'moo:val6_6',
        param6_7 => 'moo_C:val6_7',
      },

      param6_B => {
        param6_1 => 'moo:val6_1',
        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2'
        ],
        param6_3 => 'foo_A:val6_3',
        param6_4 => 'moo:val6_4',
        param6_5 => [
          'zoo:val6_5_1',
          'zoo:val6_5_2',
        ],
        param6_6 => 'moo_C:val6_6',
        param6_7 => 'moo_C:val6_7',
      },

      param6_C => {
        param6_1 => 'moo:val6_C_1',
        param6_2 => 'moo:val6_C_2',
      },

      param6_D => 'moo:val6_D_2',

      param6_E => {
        param6_1 => 'moo:val6_E_1',
        param6_2 => 'moo:val6_E_2',
      },

      param6_F => 'moo:val6_F_3',
    },

    yar => {
      param1 => {
        param1_1 => 'yar_A:jar:jar:zoo:val3_1; jar:bar_B:val3_3;'
            . ' jar:jar:foo_B:val3_3; jar:zoo:val3_1',

        param1_2 => [
          { param3_1 => 'zoo:val3_1',
            param3_2 => 'foo_A:val3_2',
            param3_3 => 'foo_B:val3_3',
            param3_4 => 'zoo:val3_4',
          },
          [ 'bar_B:val4_1',
            'bar_B:val4_2',
          ]
        ],

        param1_3 => {
          param5_1_2 => 'moo_A:val5_1_2',
          param5_1_1 => 'moo_A:val5_1_1'
        },

        param1_4 => 'yar:jar:jar:jar:foo_B:val4_1; jar:bar_B:val4_2;'
            . ' jar:jar:bar_B:val6_2_2; jar:foo_B:val6_2_1',

        param1_5 => 'yar:val1_5',
        param1_6 => 'yar:jar:foo_B:val1',
        param1_7 => 'yar:val1_7',
        param1_8 => 'yar:jar:foo_A:val2; jar:bar_A:val2',
        param1_9 => 'yar:val1_9',

        param4_1 => 'moo:val4_A_1',
        param4_2 => 'moo:val4_A_2',
        param4_3 => 'moo:val4_3',
        param4_4 => 'moo:val4_4',
        param4_5 => 'moo:val4_A_5',
        param4_7 => 1,
        param4_8 => '',

        param5_1 => {
          param5_1_1 => 'moo_A:val5_1_1',
          param5_1_2 => 'moo_A:val5_1_2',
        },

        param5_2 => {
          param5_2_1 => 'moo_B:val5_2_1',
          param5_2_2 => 'moo_B:val5_2_2',
        },

        param5_3 => {
          param5_1_1 => 'moo_A:val5_1_1',
          param5_1_2 => 'moo_A:val5_1_2',
          param5_2_2 => 'moo_B:val5_2_2',
          param5_2_1 => 'moo_B:val5_2_1',
          param6_6   => 'moo_C:val6_6',
          param6_7   => 'moo_C:val6_7',
        },

        param6_1 => 'moo:val6_1',

        param6_2 => [
          'foo_B:val6_2_1',
          'foo_B:val6_2_2',
        ],

        param6_3 => 'foo_A:val6_3',
        param6_4 => 'moo:val6_4',
        param6_5 => 'moo:val6_5',
        param6_6 => 'moo:val6_6',
        param6_7 => 'moo_C:val6_7',
      },

      param2 => {
        param2_1 => {
          param2_1_2 => 'yar_B:val2_1_2',
          param2_1_1 => 'yar_B:val2_1_1'
        },

        param2_2 => {
          param2_2_1 => 'yar_B:val2_2_1',
          param2_2_2 => 'yar_B:val2_2_2'
        },

        param2_3 => {
          param2_3_3 => 'yar:val2_3_3',
          param2_1_2 => 'yar_B:val2_1_2',
          param2_3_4 => 'yar:val2_3_4',
          param2_1_1 => 'yar_B:val2_1_1'
        },

        param2_4 => {
          param2_4_3 => 'yar:val2_4_3',
          param2_4_4 => 'yar:val2_4_4',
          param2_2_1 => 'yar_B:val2_2_1',
          param2_2_2 => 'yar_B:val2_2_2'
        },
      },
    },
  };

  is_deeply( $t_config, $e_config, 'complete processing' );

  return;
}

sub t_env_exporting {
  my $config_processor = shift;

  $config_processor->export_env(1);
  my $t_config = $config_processor->load( qw( foo_A.yaml foo_B.yml ) );

  ok( ref( $t_config->{ENV} ) eq 'HASH' , 'environment variables exporting' );

  return;
}
