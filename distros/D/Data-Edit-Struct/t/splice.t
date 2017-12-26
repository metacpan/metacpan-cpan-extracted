#! perl

use Test2::Bundle::Extended;
use Test2::API qw[ context ];

use Ref::Util qw[ is_arrayref ];
use Data::Edit::Struct qw[ edit ];

subtest 'container' => sub {

    my %defaults = (
        dtype => 'container',
        stype => 'container',
    );

    subtest 'no replacement (e.g. deletion)' => sub {

        cmp_splice( %defaults, %$_ )
          for ( {
                input => [ 10, 20, 30, 40 ],
            },

            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
            },
            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                length => 2,
            },
          );

    };

    subtest 'replacement' => sub {

        cmp_splice( %defaults, %$_ )
          for ( {
                input => [ 10, 20, 30, 40 ],
                src   => [ 50, 60 ],
            },

            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                src => [ 50, 60 ],
            },
            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                length => 2,
                src => [ 50, 60 ],
            },
            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                length => 2,
                src   => [ 50, 60 ],
                stype => 'element',
            },
            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                length => 2,
                src    => 'foo',
                stype  => 'element',
            },
          );

    };

    subtest errors => sub {

        my %defaults = %defaults;
        delete $defaults{idx};

        isa_ok(
            dies {
                edit(
                    splice => {
                        %defaults,
                        dest  => { foo => 1 },
                        dpath => '/'
                    } )
            },
            ['Data::Edit::Struct::failure::input::dest'],
            'illegal destination: hash',
        );

        isa_ok(
            dies {
                edit(
                    splice => {
                        %defaults,
                        dest  => { foo => 1 },
                        dpath => '/foo'
                    } )
            },
            ['Data::Edit::Struct::failure::input::dest'],
            'illegal destination: hash element',
        );

        isa_ok(
            dies {
                edit(
                    splice => {
                        %defaults,
                        dest  => [ 1, 2 ],
                        dpath => '/*[0]'
                    } )
            },
            ['Data::Edit::Struct::failure::input::dest'],
            'illegal destination: array element',
        );
    };

};


subtest 'element' => sub {

    my %defaults = (
        dtype => 'element',
        dpath => '/*[%d]',
        idx   => 1,
    );

    subtest 'no replacement (e.g. deletion)' => sub {

        cmp_splice( %defaults, %$_ )
          for ( {
                input => [ 10, 20, 30, 40 ],
            },

            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
            },
            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                length => 2,
            },
          );

    };

    subtest 'replacement' => sub {

        cmp_splice( %defaults, %$_ )
          for ( {
                input => [ 10, 20, 30, 40 ],
                src   => [ 50, 60 ],
            },

            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                src => [ 50, 60 ],
            },
            {
                input  => [ 10, 20, 30, 40 ],
                offset => 1,
                length => 2,
                src => [ 50, 60 ],
            },
          );

    };

    subtest errors => sub {

        my %defaults = %defaults;
        delete $defaults{idx};

        isa_ok(
            dies {
                edit(
                    splice => { %defaults, dest => { foo => 1 }, dpath => '/' }
                  )
            },
            ['Data::Edit::Struct::failure::input::dest'],
            'illegal destination: root',
        );

        isa_ok(
            dies {
                edit( splice =>
                      { %defaults, dest => { foo => 1 }, dpath => '/foo' } )
            },
            ['Data::Edit::Struct::failure::input::dest'],
            'illegal destination: hash element',
        );

    };

};

subtest 'auto' => sub {

    my %defaults = ( dtype => 'auto' );

    subtest 'element' => sub {

        my %defaults = (
            %defaults,
            dpath => '/*[%d]',
            idx   => 1,
        );

        subtest 'no replacement (e.g. deletion)' => sub {

            cmp_splice( %defaults, %$_ )
              for ( {
                    input  => [ 10, 20, 30, 40 ],
                    offset => 1,
                    length => 2,
                },
              );

        };

        subtest 'replacement' => sub {

            cmp_splice( %defaults, %$_ )
              for ( {
                    input  => [ 10, 20, 30, 40 ],
                    offset => 1,
                    length => 2,
                    src => [ 50, 60 ],
                },
              );

        };

    };

    subtest "container" => sub {

        subtest 'no replacement (e.g. deletion)' => sub {

            cmp_splice( %defaults, %$_ )
              for ( {
                    input  => [ 10, 20, 30, 40 ],
                    offset => 1,
                    length => 2,
                },
              );

        };

        subtest 'replacement' => sub {

            cmp_splice( %defaults, %$_ )

              for ( {
                    input  => [ 10, 20, 30, 40 ],
                    offset => 1,
                    length => 2,
                    src => [ 50, 60 ],
                },
              );
        };
    };

    isa_ok(
        dies {
            edit(
                splice => {
                    %defaults,
                    dest  => { foo => 1 },
                    dpath => '/'
                },
              )
        },
        ['Data::Edit::Struct::failure::input::dest'],
        'illegal destination: root',
    );

};


sub cmp_splice {

    my ( %arg ) = @_;

    my $ctx = context();

    if ( defined $arg{dpath} && $arg{dpath} =~ /%/ ) {
        $arg{dpath}
          = sprintf( $arg{dpath}, ( defined $arg{idx} ? $arg{idx} : () ) );
    }


    my $label
      = Data::Dumper->new( [ \%arg ], ['Args'] )->Indent( 0 )->Quotekeys( 0 )
      ->Sortkeys( 1 )->Dump;

    $label =~ s/\$Args\s*=\s*\{//;
    $label =~ s/};//;

    my $input = delete $arg{input};
    my $idx   = delete $arg{idx};


    my @input = @{ $input };
    splice(
        @input,
        ( $idx || 0 ) + ( $arg{offset} || 0 ),
        $arg{length} || 1,
        defined $arg{src}
        ? is_arrayref( $arg{src} )
          && ( ( defined $arg{stype} ? $arg{stype} :  'container' ) eq 'container' )
              ? @{ $arg{src} }
              : $arg{src}
        : (),
    );

    my $dest = [ @{ $input } ];
    edit(
        splice => {
            %arg, dest => $dest,
        },
    );

    my $ok = is( $dest, \@input, "$label" );
    $ctx->release;
    return $ok;
}

done_testing;
