#!/usr/bin/perl -w

use strict;
use warnings;


###################################################################
##
## This script will pass a xml map file to the MapIt module
## and spit out the resulting datastructure returned by MapIt
## using Data::Dumper;
##
###################################################################


my $map="./maps/map1.xml";
use DBIx::XML::DataLoader::MapIt;
use Data::Dumper;
my  @classmap=DBIx::XML::DataLoader::MapIt->mapclasses($map);
print Dumper(@classmap);



__END__


#############################################################
###  The output from this script would look like this
############################################################

$VAR1 = undef;
$VAR2 = {
          'test_data' => {
                           'dbpass' => 'na',
                           'dbsource' => 'dbi:CSV:f_dir=./data',
                           'dbuser' => 'na'
                         }
        };
$VAR3 = 'PeopleDoc';
$VAR4 = {
          'Addresses' => [
                           {
                             'date' => undef,
                             'col' => 'UID',
                             'xpath' => '../../@uid',
                             'default' => undef
                           },
                           {
                             'date' => undef,
                             'col' => 'type',
                             'xpath' => './@type',
                             'default' => undef
                           },
                           {
                             'date' => undef,
                             'col' => 'Street',
                             'xpath' => './Street',
                             'default' => undef
                           },
                           {
                             'date' => undef,
                             'col' => 'City',
                             'xpath' => './City',
                             'default' => undef
                           },
                           {
                             'date' => undef,
                             'col' => 'State',
                             'xpath' => './State',
                             'default' => undef
                           },
                           {
                             'date' => undef,
                             'col' => 'Zip',
                             'xpath' => './Zip',
                             'default' => undef
                           },
                           {
                             'parent' => undef,
                             'xpath' => './Person/Addresses/Address',
                             'keys' => [
                                         {
                                           '2' => 'type'
                                         },
                                         {
                                           '1' => 'UID'
                                         },
                                         {
                                           '3' => 'Zip'
                                         },
                                         {
                                           '4' => 'City'
                                         }
                                       ],
                             'columns' => [
                                            'UID',
                                            'type',
                                            'Street',
                                            'City',
                                            'State',
                                            'Zip'
                                          ],
                             'child' => undef,
                             'handlers' => undef,
                             'dbname' => 'test_data'
                           }
                         ],
          'People_info' => [
                             {
                               'date' => undef,
                               'col' => 'UID',
                               'xpath' => './@uid',
                               'default' => undef
                             },
                             {
                               'date' => undef,
                               'col' => 'First_Name',
                               'xpath' => './@first',
                               'default' => undef
                             },
                             {
                               'date' => undef,
                               'col' => 'Last_Name',
                               'xpath' => './@last',
                               'default' => undef
                             },
                             {
                               'date' => undef,
                               'col' => 'Mothers_Maiden',
                               'xpath' => './@mothers_maiden',
                               'default' => undef
                             },
                             {
                               'date' => undef,
                               'col' => 'Age',
                               'xpath' => './@age',
                               'default' => undef
                             },
                             {
                               'parent' => undef,
                               'xpath' => './Person',
                               'keys' => [
                                           {
                                             '2' => 'Last_Name'
                                           },
                                           {
                                             '1' => 'UID'
                                           },
                                           {
                                             '3' => 'Mothers_Maiden'
                                           }
                                         ],
                               'columns' => [
                                              'UID',
                                              'First_Name',
                                              'Last_Name',
                                              'Mothers_Maiden',
                                              'Age'
                                            ],
                               'child' => undef,
                               'handlers' => {
                                               'Last_Name' => {
                                                                '1' => {
                                                                         'args' => undef,
                                                                         'handler' => 'sub{$_[0]=~s/.*/\\u\\L$&/; return $_[0];}'
                                                                       }
                                                              },
                                               'First_Name' => {
                                                                 '1' => {
                                                                          'args' => undef,
                                                                          'handler' => 'sub{$_[0]=~s/.*/\\u\\L$&/; return $_[0];}'
                                                                        }
                                                               }
                                             },
                               'dbname' => 'test_data'
                             }
                           ]
        };
$VAR5 = [
          'People_info',
          'Addresses'
        ];
$VAR6 = 'UID';
