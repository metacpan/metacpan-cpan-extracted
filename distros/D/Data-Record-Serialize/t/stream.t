#!perl

use Test2::V0;
use Data::Record::Serialize;
use Test::TempDir::Tiny;
use File::Slurper;
use Capture::Tiny 'capture';
use FileHandle;

use constant EXPECTED => qq/{foo => 'bar'},\n/;

sub read_text {
    File::Slurper::read_text ( shift, undef, 'auto' );
}

sub config {
    {
        Sortkeys  => 1,
        Indent    => 0,
        Quotekeys => 0,
    }
}

sub serialize {

    my ( $label, $output, $get_output ) = @_;

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
                    );
                },
                "create serializer"
            ) or do { bail_out( $@ ) };

            my ( $stdout, $stderr, $exit ) = eval {
                capture { $s->send( { foo => 'bar' } );
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
    'FileHandle' => sub { FileHandle->new( 'ddump.pl', '>' ) },
    sub { $_[0]->close; read_text( 'ddump.pl' ) } );

# this works with a direct run of this script, or with prove, but not
# yath or dzil test

# serialize(
#     'IO::Handle' => IO::Handle->new->fdopen(fileno(STDOUT), '>' ),
#     sub { $_[1] } );

serialize(
    'IO::File' => sub { IO::File->new( 'ddump.pl', '>' ) },
          sub { $_[0]->close; read_text( 'ddump.pl' ) },
         );

serialize(
    filename => 'ddump.pl',
    sub { read_text( $_[0] ) } );

serialize(
    'filehandle glob' => *STDOUT,
    sub { $_[1] } );

serialize(
    'reference filehandle glob' => \*STDOUT,
    sub { $_[1] } );



done_testing;
