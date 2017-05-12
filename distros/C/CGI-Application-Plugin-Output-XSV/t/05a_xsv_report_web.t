#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
#use Test::Differences;

use lib './t';
use XSVTest;

$ENV{CGI_APP_RETURN_ONLY}= 1;

my $app= XSVTest->new;

ok( my $report= $app->run, 'app runs OK' );

my $expected= qr{(?i)Content-disposition(?-i): attachment; filename=download.csv\s+
Content-Type: application/x-csv(?:;\s+charset=\S+)?\s+
\s+
fOO,bAR,bAZ
1,2,3
};

#eq_or_diff $report, $expected;
like( $report, $expected, "report output (hash input) matches" );

$app= XSVTest->new( PARAMS => { filename => 'myfilename.csv' } );

ok( $report= $app->run, 'app runs OK' );

$expected= qr{(?i)Content-disposition(?-i): attachment; filename=myfilename.csv\s+
Content-Type: application/x-csv(?:;\s+charset=\S+)?\s+
\s+
fOO,bAR,bAZ
1,2,3
};

#eq_or_diff $report, $expected;
like( $report, $expected, "report output matches (user-specified filename)" );

$report= $app->xsv_report_web({
  values          => [
    { first_name => 'Jack',  last_name => 'Tors',  phone => '555-1212' },
    { first_name => 'Frank', last_name => 'Rizzo', phone => '555-1515' },
  ],
  headers         => [ "First Name", "Last Name", "Phone" ],
  fields          => [ qw(first_name last_name phone) ],
  include_headers => 1,
  line_ending     => "\n",
  csv_opts        => { sep_char => "\t" },
});

$expected= q{"First Name"	"Last Name"	Phone
Jack	Tors	555-1212
Frank	Rizzo	555-1515
};

#eq_or_diff $report, $expected;
is( $report, $expected, "report output (hash input) matches" );

# should be same as above
$report= $app->xsv_report_web({
  values          => [
    { first_name => 'Jack',  last_name => 'Tors',  phone => '555-1212' },
    { first_name => 'Frank', last_name => 'Rizzo', phone => '555-1515' },
  ],
  headers         => [ "First Name", "Last Name", "Phone" ],
  fields          => [ qw(first_name last_name phone) ],
});

$expected= q{"First Name","Last Name",Phone
Jack,Tors,555-1212
Frank,Rizzo,555-1515
};

is( $report, $expected, "report output (hash input) matches" );

$report= $app->xsv_report_web({
  values          => [
    { first_name => 'Jack',  last_name => 'Tors',  phone => '555-1212' },
    { first_name => 'Frank', last_name => 'Rizzo', phone => '555-1515' },
  ],
  fields          => [ qw(first_name last_name phone) ],
});

$expected= q{"First Name","Last Name",Phone
Jack,Tors,555-1212
Frank,Rizzo,555-1515
};

is( $report, $expected, "report output (hash input) matches" );

$report= $app->xsv_report_web({
  values          => [
    { first_name => 'Jack',  last_name => 'Tors',  phone => '555-1212' },
    { first_name => 'Frank', last_name => 'Rizzo', phone => '555-1515' },
  ],
  fields          => [ qw(first_name last_name phone) ],
  headers_cb      => sub {
    my @h= @{ +shift };
    s/_name$// foreach @h;
    return \@h;
  },
});

$expected= q{first,last,phone
Jack,Tors,555-1212
Frank,Rizzo,555-1515
};

is( $report, $expected, "report output (hash input) matches" );

$report= $app->xsv_report_web({
  values          => [
    { first_name => 'Jack',  last_name => 'Tors',  phone => '555-1212' },
    { first_name => 'Frank', last_name => 'Rizzo', phone => '555-1515' },
  ],
});

$expected= q{Phone,"Last Name","First Name"
555-1212,Tors,Jack
555-1515,Rizzo,Frank
};

my @rows= split /\n/ => $expected;

foreach my $h ( "Phone","Last Name","First Name" ) {
  ok( index($rows[0], $h) > -1 ,
      "report output includes header field [$h]" );
}

foreach my $f ( "555-1212","Tors","Jack" ) {
  ok( index($rows[1], $f) > -1 ,
      "report output, first row includes field [$f]" );
}

foreach my $f ( "555-1515","Rizzo","Frank" ) {
  ok( index($rows[2], $f) > -1 ,
      "report output, first row includes field [$f]" );
}
