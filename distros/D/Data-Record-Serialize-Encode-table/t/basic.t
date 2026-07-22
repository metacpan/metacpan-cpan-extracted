use strict;
use warnings;

use Test2::V0;

use Data::Record::Serialize;

subtest 'encodes records to a table sink' => sub {
    my $output     = q{};
    my $serializer = Data::Record::Serialize->new(
        encode => 'table',
        output => \$output,
        fields => [qw( name count )],
    );

    ok $serializer->does( 'Data::Record::Serialize::Role::Encode' ), 'provides an encoder';
    ok $serializer->does( 'Data::Record::Serialize::Role::Sink' ),   'provides a sink';

    $serializer->send( { count => 2,  name => 'alpha' } );
    $serializer->send( { count => 10, name => 'beta' } );

    is $output, q{}, 'buffers records until the sink is closed';

    $serializer->close;

    is $output, <<'TABLE', 'renders headers and records in field order';
+-------+-------+
| name  | count |
+-------+-------+
| alpha | 2     |
| beta  | 10    |
+-------+-------+
TABLE

    my $rendered = $output;
    $serializer->close;
    is $output, $rendered, 'closing the sink again does not render twice';
};

subtest 'passes table options to Term::Table' => sub {
    my $output     = q{};
    my $serializer = Data::Record::Serialize->new(
        encode      => 'table',
        output      => \$output,
        fields      => [qw( name note )],
        show_header => 0,
        no_collapse => ['note'],
    );

    $serializer->send( { name => 'alpha', note => q{} } );
    $serializer->close;

    is $output, <<'TABLE', 'honors header and empty-column options';
+-------+--+
| alpha |  |
+-------+--+
TABLE
};

done_testing;
