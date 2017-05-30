
use strict;
use warnings;

use Test::More;
use Path::Tiny;
use App::EvalServerAdvanced::Protocol;

my $saved = path(__FILE__)->parent->child("test.packet");
my $data = $saved->slurp_raw;
my $alldata = $saved->slurp_raw;

my ($res, $message);
my @msgs;

my $count = 0;
do {
  ($res, $message, $data) = decode_message($data);
  push @msgs, $message if $res;
} while($res);

is_deeply(\@msgs, [
          bless( {
                   'files' => [
                                bless( {
                                         'filename' => '__code',
                                         'contents' => 'print \'hello world\''
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 126,
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'language' => 'perl'
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'sequence' => 163,
                   'files' => [
                                bless( {
                                         'contents' => 'print \'hello world\'',
                                         'filename' => '__code'
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'language' => 'perl'
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'files' => [
                                bless( {
                                         'filename' => '__code',
                                         'contents' => 'print \'hello world\''
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 71,
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'language' => 'perl'
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'language' => 'perl',
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'files' => [
                                bless( {
                                         'contents' => 'print \'hello world\'',
                                         'filename' => '__code'
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 71
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'language' => 'perl',
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'files' => [
                                bless( {
                                         'filename' => '__code',
                                         'contents' => 'print \'hello world\''
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 72
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'language' => 'perl',
                   'files' => [
                                bless( {
                                         'filename' => '__code',
                                         'contents' => 'print \'hello world\''
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 194
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'language' => 'perl',
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'sequence' => 130,
                   'files' => [
                                bless( {
                                         'filename' => '__code',
                                         'contents' => 'print \'hello world\''
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ]
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'language' => 'perl',
                   'sequence' => 116,
                   'files' => [
                                bless( {
                                         'contents' => 'print \'hello world\'',
                                         'filename' => '__code'
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ]
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'files' => [
                                bless( {
                                         'filename' => '__code',
                                         'contents' => 'print \'hello world\''
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 32,
                   'language' => 'perl',
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' )
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
          bless( {
                   'files' => [
                                bless( {
                                         'contents' => 'print \'hello world\'',
                                         'filename' => '__code'
                                       }, 'App::EvalServerAdvanced::Protocol::Eval::File' )
                              ],
                   'sequence' => 52,
                   'prio' => bless( {
                                      'pr_realtime' => bless( {}, 'App::EvalServerAdvanced::Protocol::Priority::Priority_Realtime' )
                                    }, 'App::EvalServerAdvanced::Protocol::Priority' ),
                   'language' => 'perl'
                 }, 'App::EvalServerAdvanced::Protocol::Eval' ),
], "All packets decoded properly");

my $re_data = join '', map {encode_message("eval" => $_)} @msgs;

is($re_data, $alldata, "Re-encoded message matches original");

done_testing;
