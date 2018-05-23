use strict;
use lib 'lib';
use Test::More;
use Data::Processor;


subtest 'members simple' => sub{

    my $schema = {
        coordinates => {
            members => {
                x => {
                    description => "the x cooridinate",
                },
                y => {
                    description => "the y cooridinate",
                },
            }
        }
    };
    my $p = Data::Processor->new($schema);
    my $data = { coordinates => { x => 1, y => 2} };

    my $res = $p->validate($data);
    ok ( !$res, 'Examples validate themselves') or diag($res);
};

subtest 'members nested' => sub{
    my $schema = {
     house => {
        members => {
            bungalow => {
                members => {
                    rooms => {
                      #...
                    }
                }
            }
        }
     }
  };
    my $p = Data::Processor->new($schema);
    my $data = { house => {'bungalow' => { rooms => 1}}};

    my $res = $p->validate($data);
    ok ( !$res, 'Example vs suitable data validates') or diag($res);

};

subtest 'description' => sub{
     my $schema = {
         x => { description => 'The x coordinate' },
     };
     my $dp = Data::Processor->new($schema);
     ok( !$dp->validate({ x => 1}), 'Simple validate shows schema ok');
 };

subtest 'value' => sub{
    my $schema = {
        x => {
            value => qr{\d+}
        }
    };
    my $dp = Data::Processor->new($schema);

    my $good = { x => 1 };
    my $bad = { x => 'badger' };
    ok( !$dp->validate($good), 'No error for a good value') or diag( $dp->validate($good));
    ok( $dp->validate($bad), 'Error for a bad value');
};

subtest 'optional' => sub{
    my $schema = {
        x => {
            optional => 1,
        },
        y => {
            # required
        },
    };
    my $dp = Data::Processor->new($schema);
    ok( !$dp->validate({ y => 1}), 'can leave out x');
    ok( $dp->validate({ }), 'can\'t leave out y');
};

subtest 'regex' => sub{
    my $schema = {
        'color_.+' => {
            regex => 1
        },
    };
    my $data = { color_red => 'red', color_blue => 'blue'};
    my $ec = Data::Processor->new($schema)->validate($data);
    is( $ec->count, 0, 'No errors');
};


subtest 'validator' => sub{
 my $schema = {
    bob => {
      validator => sub{
         my( $value, $section ) = @_;
         if( $value ne 'bob' ){
            return "Bob must equal bob!";
         }
         return;
      },
    },
 };
 my $p = Data::Processor->new($schema);
 # would validate:
 my $ec1 = $p->validate({ bob => "bob" });
 # would fail:
 my $ec2 = $p->validate({ bob => "harry"});

 is( $ec1->count, 0, 'Ex 1 ok') or diag( $ec1);
 is( $ec2->count, 1, 'Ex 2 errors');
};

subtest 'transformer 1' => sub{

    my $schema = {
        x => {
            transformer => sub{
                my( $value, $section ) = @_;
                $value = $value + 1;
                return $value;
            }
        }
    };
    my $data = { x => 1 };
    my $p = Data::Processor->new($schema);
    my $val = Data::Processor::Validator->new( $schema, data => $data);
    $p->transform_data('x', 'x', $val);
    #say $data->{x};             #will print 2
    is($data->{x}, 2, 'is 2');
};

subtest 'transformer 2' => sub{
    my $schema = {
        x => {
            transformer => sub{
                die { msg => "SOMETHING IS WRONG" };
            }
        },
    };

    my $p = Data::Processor->new($schema);
    my $data = { x => 1 };
    my $val = Data::Processor::Validator->new( $schema, data => $data);
    my $error = $p->transform_data('x', 'x', $val);

    #say $error; # will print: error transforming 'x': SOMETHING IS WRONG
    is( $error, 'error transforming \'x\': SOMETHING IS WRONG', 'error');
};

subtest 'transformer 3' => sub{
    my $schema = {
        x => {
            transformer => sub{
                my( $value, $section ) = @_;
                return $value + 1;
            },
            validator => sub{
                my( $value ) = @_;
                if ( $value < 2 ) {
                    return "too low"
                }
            },
        },
    };
    my $p = Data::Processor->new( $schema );
    my $data = { x => 1 };
    my $errors = $p->validate($data);
    #say $errors->count;         # will print 0
    is( $errors->count, 0, 'errors count');
    #say $data->{x};             # will print 2
    is( $data->{x}, 2, 'data count');

};


my @schemas_with_data = (
    [
        sub{
            my $schema = {
                house => {
                    array => 1,
                }
            };
        },
        { house => [] },
        0,
        'array 1',
    ],
    [
        sub{
            my $schema = {
                house => {
                    array => 1,
                    members => {
                        name => {},
                        window => {
                            array => 1,
                        }
                    },
                },
            };
        },
        {
            house => [
                { name => 'bob',
                  window => []},
                { name => 'harry',
                  window => []},
            ]
        },
        0,
        'array 2',
    ],
 );

for( @schemas_with_data ){
    my( $getschema, $data, $expected_errors, $name ) = @{$_};
    my $schema = $getschema->();
    my $dp = Data::Processor->new( $schema );
    my $errors = $dp->validate( $data);
    ok( $expected_errors ? $errors : ! $errors,
        $name) or diag( $errors);
}




done_testing;
