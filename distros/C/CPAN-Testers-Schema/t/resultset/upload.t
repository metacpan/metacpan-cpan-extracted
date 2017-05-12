
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::Upload> module which
queries for L<CPAN::Testers::Schema::Result::Upload> objects.

=head1 SEE ALSO

=over

=item L<DBIx::Class::ResultSet>

=back

=cut

use CPAN::Testers::Schema::Base 'Test';

my %data = (

    Upload => [
        {
            uploadid => 1,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Dist',
            version => '1.001',
            filename => 'My-Dist-1.001.tar.gz',
            released => 1479524600,
        },
        {
            uploadid => 2,
            type => 'cpan',
            author => 'POSTACTION',
            dist => 'My-Dist',
            version => '1.002',
            filename => 'My-Dist-1.002.tar.gz',
            released => 1479524700, # 2016-11-19T03:05:00Z
        },
        {
            uploadid => 3,
            type => 'cpan',
            author => 'PREACTION',
            dist => 'My-Other',
            version => '1.000',
            filename => 'My-Other-1.000.tar.gz',
            released => 1479524800,
        },
    ],

);

my $schema = prepare_temp_schema;
$schema->populate( $_, $data{ $_ } ) for keys %data;

my $rs = $schema->resultset( 'Upload' );
$rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

is_deeply [ $rs->all ], $data{Upload}, 'sanity check that items were inserted'
    or diag explain [ $rs->all ];

subtest 'by_dist' => sub {
    my $rs = $schema->resultset( 'Upload' )->by_dist( 'My-Dist' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Upload}->@[0,1] ], 'get items for My-Dist'
        or diag explain [ $rs->all ];

    subtest 'since' => sub {
        my $rs = $schema->resultset( 'Upload' )->by_dist( 'My-Dist' )
                ->since( '2016-11-19T03:05:00Z' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Upload}[1] ], 'get items for My-Dist'
            or diag explain [ $rs->all ];

    };
};

subtest 'by_author' => sub {
    my $rs = $schema->resultset( 'Upload' )->by_author( 'PREACTION' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Upload}->@[0,2] ], 'get items for PREACTION'
        or diag explain [ $rs->all ];

    subtest 'since' => sub {
        my $rs = $schema->resultset( 'Upload' )->by_author( 'PREACTION' )
                ->since( '2016-11-19T03:05:00Z' );
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        is_deeply [ $rs->all ], [ $data{Upload}[2] ], 'get items for PREACTION'
            or diag explain [ $rs->all ];

    };
};

subtest 'since' => sub {
    my $rs = $schema->resultset( 'Upload' )->since( '2016-11-19T03:05:00Z' );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Upload}->@[1,2] ], 'get items since 2016-11-19'
        or diag explain [ $rs->all ];
};

done_testing;

