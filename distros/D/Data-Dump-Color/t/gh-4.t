#!perl

use 5.010001;
use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 0+1;

use Data::Dump::Color qw(dump);

my $var = dump(
{
          'interface' => 'N91-2-5-22',
          'software_version' => 'H74.00.0004.G2',
          'ont_status' => 'up',
          'ethernet_ports' => {
                                'eth1' => {
                                            'raw_speed_string' => 'Unknown',
                                            'port_name' => 'eth1',
                                            'admin' => 'enabled',
                                            'physical' => 'down',
                                            'speed' => '',
                                            'duplex' => ''
                                          },
                                'eth2' => {
                                            'physical' => 'up',
                                            'speed' => '1000',
                                            'duplex' => 'full',
                                            'port_name' => 'eth2',
                                            'admin' => 'enabled'
                                          },
                                'eth3' => {
                                            'physical' => 'down',
                                            'speed' => '',
                                            'duplex' => '',
                                            'raw_speed_string' => 'Unknown',
                                            'port_name' => 'eth3',
                                            'admin' => 'enabled'
                                          },
                                'eth4' => {
                                            'raw_speed_string' => 'Unknown',
                                            'admin' => 'enabled',
                                            'port_name' => 'eth4',
                                            'speed' => '',
                                            'duplex' => '',
                                            'physical' => 'down'
                                          }
                              },
          'optic' => {
                       'tx_level' => '-5.5',
                       'rx_level' => '-6.9',
                       'distance' => '10 km',
                       'wavelength' => '1490',
                       'light_levels' => '-6.9 / -5.5'
                     },
          'model_number_raw' => '1287704G1',
          'hardware_vendor' => 'Adtran',
          'light_levels' => '-6.9 / -5.5 dBm',
          'product_name' => 'TA354E 2ND GEN OUTDOOR SFU 2P+4AE',
          'pots' => {
                      'interface' => {
                                       '1' => {
                                                'hook_status' => 'off',
                                                'admin_status' => 'is',
                                                'error_info' => 'none',
                                                'operational_status' => 'up'
                                              },
                                       '2' => {
                                                'hook_status' => 'on',
                                                'admin_status' => 'is',
                                                'operational_status' => 'up',
                                                'error_info' => 'none'
                                              }
                                     },
                      'query_time' => '0.31'
                    },
          'serial_number' => 'ADTN14290317',
          'query_time' => '2.316',
          'uptime' => '36 days, 04 hours, 11 minutes, 47 seconds',
          'model_number' => '1287704G1 (TA354E 2ND GEN OUTDOOR SFU 2P+4AE)',
          'admin_status' => 'is'
});
