=head1 NAME

MyCDs - Testng and example clases for DBIx::DBO2

=head1 SYNOPSIS

  use MyCDs;
  MyCDs->connect_datasource( $dsn, $user, $pass );

  my $discs = MyCDs::Disc->fetch_all;
  foreach my $disc ( $discs->records ) {
    print $disc->name, $disc->year;
  }

=head1

This is an example use of the DBIx::DBO2 framework used for testing purposes.

=cut

package MyCDs;

use strict;
use DBIx::DBO2;
use DBIx::DBO2::Schema;

########################################################################

use Class::MakeMethods (
  'Standard::Global:object' => [
      { name=>'tableset', class=>'DBIx::DBO2::Schema'},
  ],
  'Standard::Universal:delegate'=>[ 
    [qw(datasource connect_datasource declare_tables create_tables drop_tables)]
	=> { target=>'tableset'} 
  ],
);

sub init {
  # warn "Init MyCD tableset";
  MyCDs->tableset( DBIx::DBO2::Schema->new(
    packages => { 
      'MyCDs::Disc' => 'disc',
      'MyCDs::Track' => 'track',
      'MyCDs::Artist' => 'artist',
      'MyCDs::Genre' => 'genre',
    }, 
    require_packages => 1,
  ) );
}

########################################################################

1;
