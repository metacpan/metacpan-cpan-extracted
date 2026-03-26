#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
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
                       'errors' => [
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
                       'module_name' => 'MARC::Validator::Plugin::Foo',
                       'name' => 'foo',
                       'version' => '0.01',
                ),
        ],
);

# Dump out.
p $report;

# Output:
# Data::MARC::Validator::Report  {
#     parents: Mo::Object
#     public methods (4):
#         BUILD
#         Mo::utils:
#             check_isa, check_required
#         Mo::utils::Array:
#             check_array_object
#     private methods (0)
#     internals: {
#         datetime   2026-02-22T11:16:24 (DateTime),
#         plugins    [
#             [0] Data::MARC::Validator::Report::Plugin
#         ]
#     }
# }