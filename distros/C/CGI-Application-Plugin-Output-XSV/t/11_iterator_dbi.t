#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use DBD::Sponge";
  plan skip_all => "DBD::Sponge required to test DBI iterator" if $@;
}

# first populate the database with some sample data
my $dbh = eval {
  use DBI;
  DBI->connect( "dbi:Sponge:", "", "", { RaiseError => 1 } )
};
plan skip_all => "Couldn't connect using DBD::Sponge: $@" if $@;

plan tests => 4;

use_ok( 'CGI::Application::Plugin::Output::XSV', qw(xsv_report) );

# adapted from DBD::Sponge pod
{
  my @rows = (
    [ 1, 'Tors, Inc.'  ],
    [ 2, 'Rizzo, Inc.' ],
  );

  my $sth = $dbh->prepare( "first two entries",
    {
      rows => \@rows,
      NAME => [ qw(dealer_id company_name) ],
    }
  );
  $sth->execute;

  my $report= xsv_report({
    include_headers => 0,
    iterator        => sub { $sth->fetchrow_arrayref },
  });

  is( $report, qq{1,"Tors, Inc."\n2,"Rizzo, Inc."\n},
      "report output (iterator) matches" );
}

{
  my @rows = (
    [ 1, 'Tors, Inc.'         ],
    [ 2, 'Rizzo, Inc.'        ],
    [ 3, 'Testing, Ltd.'      ],
    [ 4, 'Another Test, LLC.' ],
  );

  my $sth = $dbh->prepare( "all entries",
    {
      rows => \@rows,
      NAME => [ qw(dealer_id company_name) ],
    }
  );
  $sth->execute;

  my $report= xsv_report({
    include_headers => 0,
    iterator        => sub { $sth->fetchrow_arrayref },
  });

  is( $report,
      qq{1,"Tors, Inc."\n2,"Rizzo, Inc."\n3,"Testing, Ltd."\n4,"Another Test, LLC."\n},
      "report output (iterator) matches" );
}

{
  my @rows = (
    [ 1, 'Tors, Inc.'         ],
    [ 2, 'Rizzo, Inc.'        ],
    [ 3, 'Testing, Ltd.'      ],
    [ 4, 'Another Test, LLC.' ],
  );

  my $sth = $dbh->prepare( "all entries",
    {
      rows => \@rows,
      NAME => [ qw(id name) ],
    }
  );
  $sth->execute;

  sub get_vals_from_hashref {
    my $fields_ref = shift;

    while ( my $dealer_href = $sth->fetchrow_hashref ) {
      return [ @{$dealer_href}{@{$fields_ref}} ];
    }
  }

  my $report= xsv_report({
    include_headers => 0,
    fields          => [ qw(id name) ],
    iterator        => \&get_vals_from_hashref,
  });

  is( $report,
      qq{1,"Tors, Inc."\n2,"Rizzo, Inc."\n3,"Testing, Ltd."\n4,"Another Test, LLC."\n},
      "report output (iterator) matches" );
}
