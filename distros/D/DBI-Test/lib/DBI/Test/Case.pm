package DBI::Test::Case;

use strict;
use warnings;

use DBI::Mock ();

sub requires_extended { 0 }

sub is_test_for_mocked
{
    my ( $self, $test_confs ) = @_;

    # allow DBD::NullP for DBI::Mock
    return ( $INC{'DBI.pm'} eq "mocked" and !scalar(@$test_confs) )
      || scalar grep { $_->{cat_abbrev} eq "m" } @$test_confs;
}

sub is_test_for_dbi
{
    my ( $self, $test_confs ) = @_;

    return ( -f $INC{'DBI.pm'} and !scalar(@$test_confs) )
      || scalar grep { $_->{cat_abbrev} eq "z" } @$test_confs;
}

sub filter_drivers
{
    my ( $self, $options, @test_dbds ) = @_;
    if ( $options->{CONTAINED_DBDS} )
    {
        my @contained_dbds =
          "ARRAY" eq ref( $options->{CONTAINED_DBDS} )
          ? @{ $options->{CONTAINED_DBDS} }
          : ( $options->{CONTAINED_DBDS} );
        my @supported_dbds;

        foreach my $test_dbd (@test_dbds)
        {
            @supported_dbds = ( @supported_dbds, grep { $test_dbd eq $_ } @contained_dbds );
        }

        return @supported_dbds;
    }

    return @test_dbds;
}

sub supported_variant
{
    my ( $self, $test_case, $cfg_pfx, $test_confs, $dsn_pfx, $dsn_cred, $options ) = @_;

    # allow only DBD::NullP for DBI::Mock
    if ( $self->is_test_for_mocked($test_confs) )
    {
        $dsn_cred or return 1;
        $dsn_cred->[0] eq 'dbi:NullP:' and return 1;
        return;
    }

    return 1;
}

1;
