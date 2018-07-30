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
                                      '/f "delims=" %%a IN (c:\\tmp\\file)',
                                    'Statement' => {
                                        'Command' => {
                                            'SpecialCommand' => {
                                                'Set' => {
                                                    'Value'    => '%%a',
                                                    'Variable' => 'FILECONTENT'
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
            ]
          }

    };
    my $cmd_file = $PROGRAM_NAME;
    $cmd_file =~ s/\.t/\.cmd/;
    my $cmd_contents = path($cmd_file)->slurp;
    my $parser       = App::BatParser->new;
    my $ast          = $parser->parse($cmd_contents);

    is_deeply( $ast, $ast_expected, 'Simple cmd' );
}

