use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use English qw( -no_match_vars );
use App::BatParser;
use Path::Tiny;

{
    my $ast_expected = {
        'File' => {
            'Lines' => [
                {
                    'Statement' => {
                        'Command' => {
                            'SpecialCommand' => {
                                'For' => {
                                    'Token' =>
'/F "delims=" %%K in (\'echo i like doritos\')',
                                    'Statement' => {
                                        'Command' => {
                                            'SpecialCommand' => {
                                                'Set' => {
                                                    'Variable' => 'RESPONSE',
                                                    'Value'    => '%%K'
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                {
                    'Statement' => {
                        'Command' => {
                            'SpecialCommand' => {
                                'Echo' => {
                                    'Message' => '%RESPONSE%'
                                }
                            }
                        }
                    }
                }
            ]
        }
    };
    my $cmd_file = $PROGRAM_NAME;
    $cmd_file =~ s/\.t/\.cmd/;
    my $cmd_contents = path($cmd_file)->slurp;
    my $parser       = App::BatParser->new;
    my $ast          = $parser->parse($cmd_contents);

    is_deeply( $ast, $ast_expected, 'Parsing a cmd with a DO command' );
}

