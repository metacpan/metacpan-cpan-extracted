#!perl

use v5.12;
use Test2::V0;
use Data::Record::Serialize;
use Test::TempDir::Tiny;
use File::Slurper;
use Capture::Tiny 'capture';
use FileHandle;

use constant EXPECTED => qq/{foo => 'bar'},\n/;

sub read_text {
    File::Slurper::read_text( shift, undef, 'auto' );
}

sub config {
    {
        Sortkeys  => 1,
        Indent    => 0,
        Quotekeys => 0,
    };
}

sub serialize {

    my %pars       = @_;
    my $output     = delete $pars{output};
    my $label      = delete $pars{label};
    my $get_output = delete $pars{get_output};
    my $config     = delete( $pars{config} ) // {};

    die 'extra pars' if %pars;

    in_tempdir $label => sub {
        subtest $label => sub {
            my $ctx = context();
            my $s;

            # may need to run some code in the tempdir to get the
            # output thing.
            $output = $output->() if 'CODE' eq ref $output;

            ok(
                lives {
                    $s = Data::Record::Serialize->new(
                        encode    => 'ddump',
                        output    => $output,
                        dd_config => config(),
                        %{$config},
                    );
                },
                "create serializer",
            ) or do { bail_out( $@ ) };

            my ( $stdout, $stderr, $exit ) = eval {
                capture {
                    $s->send( { foo => 'bar' } );
                    $s->close;
                }
            };

            bail_out( $@ ) if $@ ne '';

            is( $get_output->( $output, $stdout, $stderr, $exit ), EXPECTED, 'correct output' );
            $ctx->release;
        };
    };
}

serialize(
    label      => 'FileHandle',
    output     => sub { FileHandle->new( 'ddump.pl', '>' ) },
    get_output => sub { $_[0]->close; read_text( 'ddump.pl' ) },
);

# this works with a direct run of this script, or with prove, but not
# yath or dzil test

# serialize(
#     'IO::Handle' => IO::Handle->new->fdopen(fileno(STDOUT), '>' ),
#     sub { $_[1] } );

serialize(
    label      => 'IO::File',
    output     => sub { IO::File->new( 'ddump.pl', '>' ) },
    get_output => sub { $_[0]->close; read_text( 'ddump.pl' ) },
);

serialize(
    label      => 'filename',
    output     => 'ddump.pl',
    get_output => sub { read_text( $_[0] ) },
);

serialize(
    label      => 'filehandle glob',
    output     => *STDOUT,
    get_output => sub { $_[1] },
);

serialize(
    label      => 'reference filehandle glob',
    output     => \*STDOUT,
    get_output => sub { $_[1] },
);

serialize(
    label      => 'create output dir',
    output     => 'foo/bar/fff.pl',
    get_output => sub { read_text( $_[0] ) },
    config     => { create_output_dir => 1 },
);



done_testing;
