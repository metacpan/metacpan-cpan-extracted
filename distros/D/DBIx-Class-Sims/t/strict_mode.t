# vi:sw=2
use strictures 2;

use Test2::V0 qw(
  done_testing subtest E match is ok
  array hash field item end
);

use lib 't/lib';

use File::Path qw( remove_tree );
use Try::Tiny;
use YAML::Any qw( LoadFile );

BEGIN {
  use loader qw(build_schema);
  build_schema([
    Artist => {
      columns => {
        id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
        },
      },
      primary_keys => [ 'id' ],
    },
  ]);
}

use common qw(sims_test Schema);

sims_test "Table doesn't exist (strict off)" => {
  spec => [
    { NotThere => 1 },
    { ignore_unknown_tables => 1 },
  ],
  expect => {
  },
};

sims_test "Table doesn't exist (strict mode)" => {
  spec => { NotThere => 1 },
  dies => qr/DBIx::Class::Sims::Runner::.*\(\): The following names are in the spec, but not the schema:.NotThere./s,
};

sims_test "Tables don't exist (strict mode) - shows sorting" => {
  spec => { NotThere => 1, AlsoNotThere => 1 },
  dies => qr/DBIx::Class::Sims::Runner::.*\(\): The following names are in the spec, but not the schema:.AlsoNotThere,NotThere./s,
};

sims_test "Column doesn't exist (strict off)" => {
  spec => [
    { Artist => { whatever => 1 } },
    { ignore_unknown_columns => 1 },
  ],
  expect => {
    Artist => { id => 1 },
  },
};

sims_test "Column doesn't exist (strict mode)" => {
  spec => [
    { Artist => { whatever => 1 } },
  ],
  dies => qr/DBIx::Class::Sims::Runner::.*\(\): The following names are in the spec, but not the table Artist.whatever./s,
};

sims_test "Columns don't exist (strict mode) - shows sorting" => {
  spec => [
    { Artist => { whatever => 1, other_whatever => 1 } },
  ],
  dies => qr/DBIx::Class::Sims::Runner::.*\(\): The following names are in the spec, but not the table Artist.other_whatever,whatever./s,
};

sims_test "Columns don't exist (strict mode) - shows sorting" => {
  load_sims => sub {
    my ($schema) = @_;

    my $trace_file = '/tmp/trace';

    remove_tree( $trace_file );

    try {
      $schema->load_sims(
        {
          Artist => [
            {},
            { whatever => 1, other_whatever => 1 },
          ],
        },
        { object_trace => $trace_file },
      );
    } catch {
      # Verify the trace was written out
      my $trace = LoadFile( $trace_file );
      my $check = hash {
        field objects => array {
          item hash {
            field parent => 0;
            field seen => 1;
            field table => 'Artist';
            field spec => hash {
              end;
            };
            field made => 1;
            field create_params => hash {
              end;
            };
            field row => hash {
              field id => 1;
              end;
            };
            end;
          };
          item hash {
            field parent => 0;
            field seen => 2;
            field table => 'Artist';
            field spec => hash {
              field whatever => 1;
              field other_whatever => 1;
              end;
            };
            end;
          };
          end;
        };
        end;
      };
      is( $trace, $check, 'Toposort trace is as expected' );

      remove_tree( $trace_file );

      die $_;
    }
  },
  dies => qr/DBIx::Class::Sims::Runner::.*\(\): The following names are in the spec, but not the table Artist.other_whatever,whatever./s,
};

done_testing;
