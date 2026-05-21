#!/usr/bin/env perl

use strict;
use warnings;

use App::MARC::Validator::Utils qw(obj_to_json);
use Data::MARC::Validator::Report;
use Data::MARC::Validator::Report::Error;
use Data::MARC::Validator::Report::Plugin;
use Data::MARC::Validator::Report::Plugin::Errors;
use DateTime;

# Create data object for validator report.
my $report = Data::MARC::Validator::Report->new(
        'datetime' => DateTime->now,
        'plugins' => [
                Data::MARC::Validator::Report::Plugin->new(
                       'module_name' => 'MARC::Validator::Plugin::Foo',
                       'name' => 'foo',
                       'plugin_errors' => [
                               Data::MARC::Validator::Report::Plugin::Errors->new(
                                       'errors' => [
                                               Data::MARC::Validator::Report::Error->new(
                                                       'error' => 'Error #1',
                                                       'params' => {
                                                               'key' => 'value',
                                                       },
                                               ),
                                               Data::MARC::Validator::Report::Error->new(
                                                       'error' => 'Error #2',
                                                       'params' => {
                                                               'key' => 'value',
                                                       },
                                               ),
                                       ],
                                       'filters' => ['filter1', 'filter2'],
                                       'record_id' => 'id1',
                               ),
                       ],
                       'version' => '0.01',
                ),
        ],
);

my $self = {
        '_opts' => {
                'p' => 1,
        },
};
my $json = obj_to_json($self, $report);

print $json;

# Output:
# {
#    "foo" : {
#       "checks" : {
#          "not_valid" : {
#             "id1" : [
#                {
#                   "error" : "Error #1",
#                   "params" : {
#                      "key" : "value"
#                   }
#                },
#                {
#                   "error" : "Error #2",
#                   "params" : {
#                      "key" : "value"
#                   }
#                }
#             ]
#          }
#       },
#       "datetime" : "2026-05-21T11:20:09",
#       "module_name" : "MARC::Validator::Plugin::Foo",
#       "module_version" : "0.01",
#       "name" : "foo"
#    }
# }