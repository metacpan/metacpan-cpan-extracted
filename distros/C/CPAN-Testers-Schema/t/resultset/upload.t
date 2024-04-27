
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::Upload> module which
queries for L<CPAN::Testers::Schema::Result::Upload> objects.

=head1 SEE ALSO

=over

=item L<DBIx::Class::ResultSet>

=back

=cut

use CPAN::Testers::Schema::Base 'Test';

my %common = (
  Stats => {
    type => 2,
    postdate => '202401',
    fulldate => '202401010000',
    tester => 'Doug Bell <doug@preaction.me>',
    platform => 'x86_64-linux-thread-multi',
    perl => '5.28.0',
    osname => 'Linux',
    osvers => '2.21.4',
  },
);

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

$data{Stats} = [
  {
      uploadid => 1,
      state => 'pass',
      guid => 'df7fd789-4ECE-4923-8623-935DC4306330',
      $common{Stats}->%*,
      $data{Upload}[0]->%{qw(dist version)},
  },
  {
      uploadid => 2,
      state => 'pass',
      guid => '78de1ed2-d47d-4ef5-b7d0-67e95b6a5fe9',
      $common{Stats}->%*,
      $data{Upload}[1]->%{qw(dist version)},
  },
  {
      uploadid => 2,
      state => 'fail',
      guid => 'eab00b13-ac66-458e-b0b2-eb69709a49e5',
      $common{Stats}->%*,
      $data{Upload}[1]->%{qw(dist version)},
  },
  {
      uploadid => 3,
      state => 'pass',
      guid => '2b06a21a-f4c9-4f80-af86-860f33399fc2',
      $common{Stats}->%*,
      $data{Upload}[2]->%{qw(dist version)},
  },
  {
      uploadid => 3,
      state => 'pass',
      guid => 'f0e4962a-b300-4fe2-9a07-d449e81daa47',
      $common{Stats}->%*,
      $data{Upload}[2]->%{qw(dist version)},
  },
];

my $schema = prepare_temp_schema;
my $version_row = $schema->resultset( 'PerlVersion' )->create({ version => $common{Stats}{perl} });
$schema->populate( $_, $data{ $_ } ) for qw( Upload Stats );

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

subtest 'recent' => sub {
    my $rs = $schema->resultset( 'Upload' )->recent(1);
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Upload}->@[2] ], 'get most recent item'
        or diag explain [ $rs->all ];
    $rs = $schema->resultset( 'Upload' )->recent;
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ $rs->all ], [ $data{Upload}->@[2,1,0] ],
        'get up to 20 most recent items sorted newest to oldest'
        or diag explain [ $rs->all ];
};

subtest 'latest_by_dist' => sub {
  if ( !eval { require Test::mysqld; 1 } ) {
      plan skip_all => 'Requires Test::mysqld';
      return;
  }

  no warnings 'once';
  my $mysqld = Test::mysqld->new(
      my_cnf => {
          'skip-networking' => '', # no TCP socket
      },
  );
  if ( !$mysqld ) {
      plan skip_all => "Failed to start up server: $Test::mysqld::errstr";
      return;
  }

  my ( undef, $version ) = DBI->connect( $mysqld->dsn(dbname => 'test') )->selectrow_array( q{SHOW VARIABLES LIKE 'version'} );
  my ( $mversion ) = $version =~ /^(\d+[.]\d+)/;
  diag "MySQL version: $version; Major version: $mversion";
  if ( $mversion < 5.7 ) {
      plan skip_all => "Need MySQL version 5.7 or higher. This is $version";
      return;
  }

  my $schema = CPAN::Testers::Schema->connect(
      $mysqld->dsn(dbname => 'test'), undef, undef, { ignore_version => 1 },
  );
  $schema->deploy;

  my $version_row = $schema->resultset( 'PerlVersion' )->create({ version => $common{Stats}{perl} });
  $schema->populate( $_, $data{ $_ } ) for qw( Upload Stats );

  my $rs = $schema->resultset( 'Upload' )->latest_by_dist;
  $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
  is_deeply [ $rs->all ], [ map +{ $_->%{qw( dist version )} }, $data{Upload}->@[1,2] ], 'get most recent version for all dists'
      or diag explain [ $rs->all ];

  $rs = $schema->resultset( 'Upload' )->latest_by_dist->by_author('PREACTION');
  $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
  is_deeply [ $rs->all ], [ map +{ $_->%{qw( dist version )} }, $data{Upload}->@[0,2] ], 'get most recent version for all dists by PREACTION'
      or diag explain [ $rs->all ];

  subtest 'join report_stats' => sub {
    my $rs = $schema->resultset( 'Upload' )->latest_by_dist->search_related('report_stats');
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ map +{ $_->%{keys $data{Stats}[0]->%*} }, $rs->all ], [ $data{Stats}->@[1,2,3,4] ]
        or diag explain [ $rs->all ];

    $rs = $schema->resultset( 'Upload' )->by_author('PREACTION')->latest_by_dist->search_related('report_stats');
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    is_deeply [ map +{ $_->%{keys $data{Stats}[0]->%*} }, $rs->all ], [ $data{Stats}->@[0,3,4] ]
        or diag explain [ $rs->all ];
  };
};

done_testing;

