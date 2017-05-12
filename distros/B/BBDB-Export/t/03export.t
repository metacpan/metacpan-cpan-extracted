# -*- mode: perl; -*-

use Test::More tests => 28;

use BBDB;
use BBDB::Export;
use BBDB::Export::LDIF;
use BBDB::Export::MailAliases;
use BBDB::Export::vCard;
use Data::Dumper;

for my $case ( qw( aka company net notes phone simple title ) )
{
    my $test_bbdb = "t/testcases/$case.bbdb";

    #
    # check record hash
    #

    # create instance of exporter
    my $exporter = BBDB::Export->new(
                                   {
                                    bbdb_file => $test_bbdb,
                                   }
                                    );

    # get the first record from the test file
    my $record = ( @{BBDB::simple( "$test_bbdb" )} )[0];

    # set default value for got_data in case reading of file fails
    $got_data = "failed to read test case data: t/testcases/$case.data";

    # data in $case.data is in Data::Dumper format
    do "t/testcases/$case.data";

    is_deeply(
              $exporter->get_record_hash( $record ),
              $got_data,
              "$case - creating record hash"
              );

    #
    # check mail aliases
    #
    my $mailaliases = BBDB::Export::new(
                                        "BBDB::Export::MailAliases",
                                      {
                                       bbdb_file => $test_bbdb,
                                      }
                                       );

    my ( $aliases_got ) = $mailaliases->export();
    is_deeply(
              [ split /\n/, $aliases_got                             ],
              [ split /\n/, read_file( "t/testcases/$case.mailaliases" ) ],
              "$case - mail_aliases export"
              );

    #
    # check LDIF exporter
    #
    my $ldif = BBDB::Export::LDIF->new(
                                     {
                                      bbdb_file   => $test_bbdb,
                                      dc          => "dc=geekfarm, dc=org",
                                      quiet       => 1,
                                     }
                                      );


    my ( $ldif_got ) = $ldif->export();
    is_deeply(
              [ split /\n/, $ldif_got                         ],
              [ split /\n/, read_file( "t/testcases/$case.ldif" ) ],
              "$case - ldif export"
               );

    #
    # check vCard exporter
    #
    my $vcard = BBDB::Export::vCard->new(
                                       {
                                        bbdb_file   => $test_bbdb,
                                       }
                                        );

    my ( $vcard_got ) = $vcard->export();
    is_deeply(
              [ split /\n/, $vcard_got                         ],
              [ split /\n/, read_file( "t/testcases/$case.vcf" ) ],
              "$case - vcard export"
               );

}

sub read_file
{
    my $file = shift;

    local $/=undef;
    open( IN, "<$file") or return undef;
    my $content = <IN>;
    close IN;

    return $content;
}
