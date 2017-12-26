#! perl

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::API qw[ context ];

use Data::Edit::Struct qw[ edit ];

isa_ok(
    dies {
        edit( insert => { dest => [] } )
    },
    ['Data::Edit::Struct::failure::input::src'],
    "source must be specified",
);


subtest 'container' => sub {

    my %defaults = (
        dtype => 'container',
        stype => 'auto',
        dest  => [ 0, 10, 20, 30, 40 ],
    );

    my $maxidx = $#{ $defaults{dest} };

    subtest 'dest => array' => sub {

        my %defaults = ( %defaults, exclude => [qw[ dtype stype dest src]] );

        subtest "insert => 'before'" => sub {

            my %defaults = (
                %defaults,
                exclude => [ @{ $defaults{exclude} }, 'dpath', 'insert' ],
                dpath   => '/',
                insert  => 'before',
            );


            subtest "anchor => 'first'" => sub {

                test_insert(
                    %defaults,
                    anchor  => 'first',
                    exclude => [ @{ $defaults{exclude} }, 'anchor' ],
                    dest    => [ @{ $defaults{dest} } ],
                    %$_
                  )
                  for ( {
                        src      => [ -20, -10 ],
                        expected => [ -20, -10, 0, 10, 20, 30, 40 ],
                        msg => 'anchor + offset == 0 (default)',
                    },
                    {
                        src    => [ 11, 12 ],
                        offset => 2,
                        expected => [ 0, 10, 11, 12, 20, 30, 40 ],
                        msg => '0 < anchor + offset < maxidx',
                    },
                    {
                        src    => [ -30, -20 ],
                        offset => -1,
                        expected => [ -30, -20, undef, 0, 10, 20, 30, 40 ],
                        msg => 'anchor + offset < 0',
                    },
                    {
                        src    => [ 31, 32 ],
                        offset => $maxidx,
                        expected => [ 0, 10, 20, 30, 31, 32, 40 ],
                        msg => 'anchor + offset == maxidx',
                    },
                    {
                        src    => [ 50, 60 ],
                        offset => $maxidx + 1,
                        expected => [ 0, 10, 20, 30, 40, 50, 60 ],
                        msg => 'anchor + offset == maxidx + 1',
                    },
                    {
                        src    => [ 60, 70 ],
                        offset => $maxidx + 2,
                        expected => [ 0, 10, 20, 30, 40, undef, 60, 70 ],
                        msg => 'offset == maxidx + 2',
                    },
                  );
            };

            subtest "anchor => 'last'" => sub {

                test_insert(
                    %defaults,
                    anchor  => 'last',
                    exclude => [ @{ $defaults{exclude} }, 'anchor' ],
                    dest    => [ @{ $defaults{dest} } ],
                    %$_
                  )
                  for ( {
                        src      => [ 31, 32 ],
                        expected => [ 0,  10, 20, 30, 31, 32, 40 ],
                        msg => 'anchor + offset == maxidx (default )',
                    },
                    {
                        src      => [60],
                        offset   => 2,
                        expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                        msg      => 'anchor + offset > maxidx',
                    },
                    {
                        src      => [21],
                        offset   => -1,
                        expected => [ 0, 10, 20, 21, 30, 40 ],
                        msg      => '0 < anchor + offset < maxidx',
                    },
                    {
                        src      => [-10],
                        offset   => -$maxidx,
                        expected => [ -10, 0, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset == 0',
                    },
                    {
                        src      => [-20],
                        offset   => -$maxidx - 1,
                        expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset < 0',
                    },

                  );
            };

        };

        subtest "insert => 'after'" => sub {

            my %defaults = (
                %defaults,
                exclude => [ @{ $defaults{exclude} }, 'dpath', 'insert' ],
                dpath   => '/',
                insert  => 'after',
            );


            subtest "anchor => 'first'" => sub {

                test_insert(
                    %defaults,
                    anchor  => 'first',
                    exclude => [ @{ $defaults{exclude} }, 'anchor' ],
                    dest    => [ @{ $defaults{dest} } ],
                    %$_
                  )
                  for ( {
                        src      => [1],
                        expected => [ 0, 1, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset == 0 (default)',
                    },
                    {
                        src    => [ 21, 22 ],
                        offset => 2,
                        expected => [ 0, 10, 20, 21, 22, 30, 40 ],
                        msg => '0 < offset < maxidx',
                    },
                    {
                        src      => [-10],
                        offset   => -1,
                        expected => [ -10, 0, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset == -1',
                    },
                    {
                        src      => [-20],
                        offset   => -2,
                        expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset < -1',
                    },
                    {
                        src    => [ 41, 42 ],
                        offset => $maxidx,
                        expected => [ 0, 10, 20, 30, 40, 41, 42 ],
                        msg => 'anchor + offset == maxidx',
                    },
                    {
                        src      => [60],
                        offset   => $maxidx + 1,
                        expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                        msg      => 'anchor + offset > maxidx',
                    },
                  );
            };

            subtest "anchor => 'last'" => sub {

                test_insert(
                    %defaults,
                    anchor  => 'last',
                    exclude => [ @{ $defaults{exclude} }, 'anchor' ],
                    dest    => [ @{ $defaults{dest} } ],
                    %$_
                  )
                  for ( {
                        src      => [ 41, 42 ],
                        expected => [ 0,  10, 20, 30, 40, 41, 42 ],
                        msg => 'anchor + offset == maxidx (default )',
                    },
                    {
                        src      => [60],
                        offset   => 2,
                        expected => [ 0, 10, 20, 30, 40, undef, undef, 60 ],
                        msg      => 'anchor + offset > maxidx',
                    },
                    {
                        src      => [31],
                        offset   => -1,
                        expected => [ 0, 10, 20, 30, 31, 40 ],
                        msg      => '0 < anchor + offset < maxidx',
                    },
                    {
                        src      => [1],
                        offset   => -$maxidx,
                        expected => [ 0, 1, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset == 0',
                    },
                    {
                        src      => [-10],
                        offset   => -$maxidx - 1,
                        expected => [ -10, 0, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset == -1',
                    },

                    {
                        src      => [-20],
                        offset   => -$maxidx - 2,
                        expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                        msg      => 'anchor + offset == -2',
                    },

                  );
            };

        };

    };

    subtest 'dest => hash' => sub {

        test_insert( %defaults, %$_ )
          for ( {
                dest  => { foo => 1, bar => 2 },
                dpath => '/',
                src      => [ baz => 3 ],
                expected => { foo => 1, bar => 2, baz => 3 },
            },
            {
                dest  => { foo => 1, bar => 2 },
                dpath => '/',
                src      => { baz => 3 },
                expected => { foo => 1, bar => 2, baz => 3 },
            },
          );

        isa_ok(
            dies {
                edit(
                    insert => {
                        %defaults,
                        dest  => { foo => 1 },
                        dpath => '/',
                        src   => { bar => 11 },
                        spath => '/',
                        stype => 'element'
                    } )
            },
            ['Data::Edit::Struct::failure::input::src'],
            'source must have an even number of elements to insert into a hash',
        );
    };

    subtest 'errors' => sub {

        isa_ok(
            dies {
                edit(
                    insert => {
                        %defaults,
                        dest  => { foo => 1 },
                        dpath => '/foo',
                        src => [ 0, 1 ],
                    } )
            },
            ['Data::Edit::Struct::failure::input::dest'],
            'destination must be an array or hash',
        );

    };
};

subtest 'element' => sub {

    my %defaults = (
        dtype => 'element',
        dest  => [ 0, 10, 20, 30, 40 ],
        exclude => [ 'dest', 'dtype', 'src' ],
    );

    my $maxidx = $#{ $defaults{dest} };

    subtest 'dest => array' => sub {

        subtest "insert => 'before'" => sub {

            test_insert(
                %defaults,
                exclude => [ @{ $defaults{exclude} }, 'insert' ],
                insert  => 'before',
                dest    => [ @{ $defaults{dest} } ],
                %$_
              )

              for ( {
                    dpath    => '/*[0]',
                    src      => [ -20, -10 ],
                    expected => [ -20, -10, 0, 10, 20, 30, 40 ],
                    msg      => 'offset == 0 (default)',
                },
                {
                    dpath    => '/*[0]',
                    offset   => -1,
                    src      => [-20],
                    expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset < 0',
                },
                {
                    dpath    => '/*[0]',
                    offset   => 1,
                    src      => [1],
                    expected => [ 0, 1, 10, 20, 30, 40 ],
                    msg      => '0 < idx + offset < maxidx',
                },
                {
                    dpath    => '/*[0]',
                    offset   => $maxidx,
                    src      => [31],
                    expected => [ 0, 10, 20, 30, 31, 40 ],
                    msg      => '0 < idx + offset == maxidx',
                },
                {
                    dpath    => '/*[0]',
                    offset   => $maxidx + 1,
                    src      => [50],
                    expected => [ 0, 10, 20, 30, 40, 50 ],
                    msg      => '0 < idx + offset == maxidx + 1',
                },
                {
                    dpath    => '/*[0]',
                    offset   => $maxidx + 2,
                    src      => [60],
                    expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                    msg      => '0 < idx + offset == maxidx + 2',
                },


                {
                    dpath    => '/*[1]',
                    src      => [ 1, 2 ],
                    expected => [ 0, 1, 2, 10, 20, 30, 40 ],
                    msg      => 'offset == 0 (default)',
                },
                {
                    dpath    => '/*[1]',
                    offset   => -1,
                    src      => [-10],
                    expected => [ -10, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset < 0',
                },
                {
                    dpath    => '/*[1]',
                    offset   => 1,
                    src      => [11],
                    expected => [ 0, 10, 11, 20, 30, 40 ],
                    msg      => '0 < idx + offset < maxidx',
                },
                {
                    dpath    => '/*[1]',
                    offset   => $maxidx - 1,
                    src      => [31],
                    expected => [ 0, 10, 20, 30, 31, 40 ],
                    msg      => '0 < idx + offset == maxidx - 1',
                },
                {
                    dpath    => '/*[1]',
                    offset   => $maxidx,
                    src      => [50],
                    expected => [ 0, 10, 20, 30, 40, 50 ],
                    msg      => '0 < idx + offset == maxidx',
                },
                {
                    dpath    => '/*[1]',
                    offset   => $maxidx + 1,
                    src      => [60],
                    expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                    msg      => '0 < idx + offset == maxidx + 1',
                },


                {
                    dpath    => "/*[$maxidx]",
                    src      => [ 31, 32 ],
                    expected => [ 0, 10, 20, 30, 31, 32, 40 ],
                    msg      => 'idx + offset == maxidx (default)',
                },
                {
                    dpath    => "/*[$maxidx]",
                    offset   => 1,
                    src      => [50],
                    expected => [ 0, 10, 20, 30, 40, 50 ],
                    msg      => 'idx + offset == maxidx + 1',
                },
                {
                    dpath    => "/*[$maxidx]",
                    offset   => 2,
                    src      => [60],
                    expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                    msg      => 'idx + offset > maxidx + 1',
                },

                {
                    dpath    => "/*[$maxidx]",
                    offset   => -1,
                    src      => [21],
                    expected => [ 0, 10, 20, 21, 30, 40 ],
                    msg      => '0 < idx + offset < maxidx',
                },
                {
                    dpath    => "/*[$maxidx]",
                    offset   => -$maxidx,
                    src      => [-10],
                    expected => [ -10, 0, 10, 20, 30, 40 ],
                    msg      => '0 == idx + offset',
                },

                {
                    dpath    => "/*[$maxidx]",
                    offset   => -$maxidx - 1,
                    src      => [-20],
                    expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset < 0 ',
                },

              );
        };

        subtest "insert => 'after'" => sub {

            test_insert(
                %defaults,
                exclude => [ @{ $defaults{exclude} }, 'insert' ],
                insert  => 'after',
                dest    => [ @{ $defaults{dest} } ],
                %$_
              )

            for ( {
                    dpath    => '/*[0]',
                    src      => [1],
                    expected => [ 0, 1, 10, 20, 30, 40 ],
                    msg      => 'idx + offset == 0 (default)',
                },
                {
                    dpath    => '/*[0]',
                    offset   => -1,
                    src      => [-10],
                    expected => [ -10, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset == -1',
                },
                {
                    dpath    => '/*[0]',
                    offset   => -2,
                    src      => [-20],
                    expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset < -1',
                },
                {
                    dpath    => '/*[0]',
                    offset   => 1,
                    src      => [11],
                    expected => [ 0, 10, 11, 20, 30, 40 ],
                    msg      => '0 < idx + offset < maxidx',
                },
                {
                    dpath    => '/*[0]',
                    offset   => $maxidx,
                    src      => [50],
                    expected => [ 0, 10, 20, 30, 40, 50 ],
                    msg      => '0 < idx + offset == maxidx',
                },
                {
                    dpath    => '/*[0]',
                    offset   => $maxidx + 1,
                    src      => [60],
                    expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                    msg      => '0 < idx + offset == maxidx + 1',
                },

                {
                    dpath    => '/*[1]',
                    src      => [11],
                    expected => [ 0, 10, 11, 20, 30, 40 ],
                    msg      => 'offset == 0 (default)',
                },
                {
                    dpath    => '/*[1]',
                    offset   => -1,
                    src      => [1],
                    expected => [ 0, 1, 10, 20, 30, 40 ],
                    msg      => 'idx + offset == 0',
                },
                {
                    dpath    => '/*[1]',
                    offset   => -2,
                    src      => [-10],
                    expected => [ -10, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset == -1',
                },
                {
                    dpath    => '/*[1]',
                    offset   => -3,
                    src      => [-20],
                    expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset < -1',
                },

                {
                    dpath    => '/*[1]',
                    offset   => 1,
                    src      => [21],
                    expected => [ 0, 10, 20, 21, 30, 40 ],
                    msg      => '0 < idx + offset < maxidx',
                },
                {
                    dpath    => '/*[1]',
                    offset   => $maxidx - 2,
                    src      => [31],
                    expected => [ 0, 10, 20, 30, 31, 40 ],
                    msg      => '0 < idx + offset == maxidx - 1',
                },
                {
                    dpath    => '/*[1]',
                    offset   => $maxidx - 1,
                    src      => [50],
                    expected => [ 0, 10, 20, 30, 40, 50 ],
                    msg      => '0 < idx + offset == maxidx',
                },
                {
                    dpath    => '/*[1]',
                    offset   => $maxidx,
                    src      => [60],
                    expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                    msg      => '0 < idx + offset == maxidx + 1',
                },


                {
                    dpath    => "/*[$maxidx]",
                    src      => [50],
                    expected => [ 0, 10, 20, 30, 40, 50 ],
                    msg      => 'idx + offset == maxidx (default)',
                },
                {
                    dpath    => "/*[$maxidx]",
                    offset   => 1,
                    src      => [60],
                    expected => [ 0, 10, 20, 30, 40, undef, 60 ],
                    msg      => 'idx + offset > maxidx',
                },

                {
                    dpath    => "/*[$maxidx]",
                    offset   => -1,
                    src      => [31],
                    expected => [ 0, 10, 20, 30, 31, 40 ],
                    msg      => '0 < idx + offset < maxidx',
                },
                {
                    dpath    => "/*[$maxidx]",
                    offset   => -$maxidx,
                    src      => [1],
                    expected => [ 0, 1, 10, 20, 30, 40 ],
                    msg      => '0 == idx + offset',
                },

                {
                    dpath    => "/*[$maxidx]",
                    offset   => -$maxidx - 1,
                    src      => [-10],
                    expected => [ -10, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset == -1',
                },

                {
                    dpath    => "/*[$maxidx]",
                    offset   => -$maxidx - 2,
                    src      => [-20],
                    expected => [ -20, undef, 0, 10, 20, 30, 40 ],
                    msg      => 'idx + offset < -1',
                },

            );

        };

    };


    subtest 'errors' => sub {

        my @params = ( {
                dest  => { foo => 1 },
                dpath => '/foo',
                src => [ 0, 1 ],
            },
            {
                dest  => [ 10, 20 ],
                dpath => '/',
                src   => [ 0,  1 ],
            } );

        for ( @params ) {

            my %arg = ( %defaults, %$_ );

	    delete $arg{exclude};

            isa_ok(
                dies { edit( insert => \%arg ) },
                ['Data::Edit::Struct::failure::input::dest'],
                _make_label( \%arg ) . ':destination must be an array or hash'
            );
        }
    };
};

subtest auto => sub {

    my %defaults = ( dtype => 'auto' );

    subtest 'container' => sub {

        test_insert( %defaults, %$_ )
          for ( {
              dest  => [ 10, 20, 30, 40 ],
              dpath => '/',
              src    => [ 1, 2 ],
              offset => 0,
              expected => [ 1, 2, 10, 20, 30, 40 ],
          } );
    };

    subtest 'element' => sub {

        test_insert( %defaults, %$_ )
          for ( {
                dest  => [ 10, 20, 30, 40 ],
                dpath => '/*[0]',
                src    => [ 1, 2 ],
                offset => 0,
                expected => [ 1, 2, 10, 20, 30, 40 ],
            },
          );
    };

};

sub test_insert {

    my ( %arg ) = @_;

    my $ctx = context();

    my $expected = delete $arg{expected};

    my @msg = ( delete $arg{msg} || () );

    my $exclude = delete $arg{exclude} || [];

    my $label = join( ': ', @msg, _make_label( \%arg, $exclude ) );

    edit( insert => \%arg );

    my $ok = is( $arg{dest}, $expected, "$label" )
      or diag explain $arg{dest};
    $ctx->release;
    return $ok;
}

sub _make_label {

    my ( $arg, $exclude ) = @_;

    $exclude = [] if ! defined $exclude;

    my %args = %$arg;

    delete @args{@$exclude};

    my $label
      = Data::Dumper->new( [ \%args ], ['Args'] )->Indent( 0 )->Quotekeys( 0 )
      ->Sortkeys( 1 )->Dump;

    $label =~ s/\$Args\s*=\s*\{//;
    $label =~ s/};//;

    return $label ne '' ? $label : ();
}

done_testing;
