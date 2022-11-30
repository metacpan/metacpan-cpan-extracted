use strict;
use warnings;

use Class::Unload;
use Data::Validate::Sanctions;
use YAML::XS   qw(Dump);
use Path::Tiny qw(tempfile);
use Test::Exception;
use Test::Warnings;
use Test::More;

$ENV{SANCTION_FILE} = "./share/sanctions.yml";

ok Data::Validate::Sanctions::is_sanctioned('NEVEROV', 'Sergei Ivanovich', -253411200), "Sergei Ivanov is_sanctioned for sure";
ok Data::Validate::Sanctions::is_sanctioned('NEVEROV', 'Sergei Ivanovich'),             "Sergei Ivanov is matched even without a birth date";
ok !Data::Validate::Sanctions::is_sanctioned('NEVEROV', 'Sergei Ivanovich', 0),         "Sergei Ivanov with incorrect dob does not match any entry";
ok !Data::Validate::Sanctions::is_sanctioned(qw(chris down)),                           "Chris is a good guy (dummy name)";
ok !Data::Validate::Sanctions::is_sanctioned(qw(Luke Lucky)),                           "Luke is a good boy (dummy name)";

throws_ok { Data::Validate::Sanctions::set_sanction_file() } qr/sanction_file is needed/, "sanction file is required";

my $tempfile = Path::Tiny->tempfile;
$tempfile->spew(
    Dump({
            test1 => {
                updated => time,
                content => [{
                        names       => ['CHRIS DOWN'],
                        'dob_epoch' => []
                    },
                    {
                        names     => ['Lucky Luke', 'Unlucky Luke'],
                        dob_epoch => [],
                        dob_year  => [qw(1996 2000)]
                    },
                ],
            },
        }));
lives_ok { Data::Validate::Sanctions::set_sanction_file("$tempfile"); };
is(Data::Validate::Sanctions::get_sanction_file(), "$tempfile", "get sanction file ok");

ok !Data::Validate::Sanctions::is_sanctioned(qw(sergei ivanov)),                                      "Sergei Ivanov is a good boy now";
ok Data::Validate::Sanctions::is_sanctioned(qw(chris down)),                                          "Chris is a bad boy now";
ok Data::Validate::Sanctions::is_sanctioned(qw(chris down), Date::Utility->new('1974-07-01')->epoch), "Chris is a bad boy even with birthdate";
ok Data::Validate::Sanctions::is_sanctioned(qw(Luke Lucky)),                                          "Luke is a bad boy without date of birth";
ok Data::Validate::Sanctions::is_sanctioned(qw(Luke Lucky), Date::Utility->new('1996-10-10')->epoch), "Luke is a bad boy if year of birth matches";
ok !Data::Validate::Sanctions::is_sanctioned(qw(Luke Lucky), Date::Utility->new('1990-01-10')->epoch),
    "Luke is not sanctioned with mismatching year of birth";

$tempfile->spew(
    Dump({
            test1 => {},
        }));
lives_ok { Data::Validate::Sanctions::set_sanction_file("$tempfile"); };
is(Data::Validate::Sanctions::get_sanction_file(), "$tempfile", "get sanction file ok");

ok !Data::Validate::Sanctions::is_sanctioned(qw(Luke Lucky)), "No sanction match found with empty source";

done_testing;
