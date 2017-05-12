# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Try::Tiny;
use Test::Fatal;
use lib 't/lib';
use CSVTester;

my $mod = $CSVTester::mod;

use DBI ();
use DBD::Mock ();

sub mock_st {
  my ($session, $re, %opts) = @_;
  push @$session, {
    statement => sub {
      my ($sql, $state) = @_;
      is_deeply $state->{bound_params}, $opts{bound_params}, 'bound params: ' . join(', ', @{ $opts{bound_params} })
        if $opts{bound_params};
      return like($sql, $re, "sql matches: $sql");
    },
    results   => [[]],
    %opts,
  };
}

sub new_csv_loader {
  my ($file, $opts) = @_;

  my $dbh = DBI->connect('dbi:Mock:', undef, undef, {
    RaiseError => 1,
    PrintError => 0,
  });

  return $mod->new(
    dbh      => $dbh,
    file     => catfile(qw( t data ), $file),
    %$opts,
  );
}

sub test_csv {
  my ($desc, $file, $opts, $rows, $error_re) = @_;
  my ($table) = $file =~ /^(\w+)/;

  subtest $desc => sub {
    my $loader = new_csv_loader($file, $opts);
    isa_ok($loader, $mod);

    my $session = [];
    mock_st($session, qr/BEGIN/);
    mock_st($session, qr/CREATE\s+TABLE\s+"$table"/);

    foreach my $row ( @$rows ){
      mock_st($session, qr/INSERT\s+INTO\s+"$table"/, bound_params => [ @$row ]);
    }

    # expect to see COMMIT unless we're expecting an error first
    # in which case DBIx::TableLoader 1.100 will issue a rollback
    mock_st($session, $error_re ? qr/ROLLBACK/ : qr/COMMIT/);

    $loader->{dbh}->{mock_session} = DBD::Mock::Session->new(csv_error => @$session);

    my $caught;

    try {
      # this will validate dbi actions against the mock session
      $loader->load;
    }
    catch {
      $caught = $_[0];
      if( $error_re ){
        like $caught, $error_re, 'got expected error';
      }
      else {
        ok 0, "got unexpected error: $caught";
      }
    };

    if( !$caught ){
      if( $error_re ){
        ok 0, "no error when expected: $error_re";
      }
      else {
        ok 1, 'no errors';
      }
    }
  };
}

{
  # instantiation failure will return undef but not die (so we must)
  like exception {
    new_csv_loader('example.csv',
      { csv_opts => { un_known_attr_ibute => 1 } },
    );
  }, qr/unknown attribute/i, 'caught csv instantion error';

  isa_ok try {
    new_csv_loader('example.csv',
      { csv_opts => { auto_diag => 2 } },
    );
  }, $mod, 'csv object created successfully';

  isa_ok try {
    new_csv_loader('example.csv',
      { csv => Text::CSV->new, csv_opts => { un_known_attr_ibute => 1 } },
    );
  }, $mod, 'csv object passed in';
}

{
  my $rows = [
    ['salty', "french fries", "sizzle"],
    ['spicy', "red\\", "crackle"],
    ['sweet', "golden brown", 'crumble'],
  ];

  my $file = 'bad_escape.csv';

  test_csv('all good', $file, {}, $rows);

  # CSV_PP ERROR: 4002 - EIQ - Unescaped ESC in quoted field
  # CSV_XS ERROR: 2011 - ECR - Characters after end of quoted field @ pos 15

  test_csv('insert one then error with auto_diag',
    $file,
    { csv_opts => { escape_char => '\\', auto_diag => 2 } },
    [ $rows->[0] ],
    qr/^(# )?CSV\w* ERROR: \d+ - \w+ -/,
  );

  test_csv('insert one then error with our own',
    $file,
    { csv_opts => { escape_char => '\\' } },
    [ $rows->[0] ],
    qr/^CSV parse error: /i,
  );

  test_csv('insert one, discard the error, and finish early',
    $file,
    { csv_opts => { escape_char => '\\' }, ignore_csv_errors => 1 },
    [ $rows->[0] ],
  );
}

{
  # most DBD's will die by themselves, but Mock will not, so set handle => die

  like exception {
    new_csv_loader('alt_sep.txt',
      { handle_invalid_row => 'die', },
    )->load;
  }, qr/Row has 4 fields when 3 are expected/i, 'alternate separator breaks rows';

  test_csv('alternate separator configured properly works',
    'alt_sep.txt',
    { handle_invalid_row => 'die', csv_opts => { sep_char => '|' } },
    [ ['1,2,3', '4,5'], ['5,6', '7,8'] ],
  );
}

done_testing;
