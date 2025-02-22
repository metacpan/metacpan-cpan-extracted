#!perl

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Data::Record::Serialize;

use File::Slurper         qw[ read_text ];
use File::Spec::Functions qw[ catfile ];

sub test_it {
    my ( $args, $combine ) = @_;

    my $s;
    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'csv',
                fields => [qw[ a b c ]],
                %{$args},
              ),
              ;
        },
        'constructor'
    ) or diag $@;

    $s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
    $s->send( { a => 1, b => 2 } );
    $s->send( { a => 1, b => 2, c => q{} } );

    my $buf = $combine->();

    is(
        $buf,
        read_text( catfile(qw[ t data encoders data.csv ]) ),
        'properly formatted'
    );

}

subtest array => sub {

    my @buf;
    my %args    = ( sink => 'array', output => \@buf );
    my $combine = sub { join( "\n", @buf ) . "\n" };

    test_it( \%args, $combine );
};

subtest 'string stream' => sub {

    my $buf;
    my %args    = ( output => \$buf );
    my $combine = sub { $buf };

    test_it( \%args, $combine );
};

done_testing;
