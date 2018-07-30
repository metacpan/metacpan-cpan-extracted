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
                    'Comment' => {
                        'Text' =>
                          'There is a whitespace at the end of the next line'
                    }
                },
                {
                    'Statement' => {
                        'Command' => {
                            'SpecialCommand' => {
                                'Set' => {
                                    'Value' =>
                                      'TheValueOfTheVariableWhithoutSpaces',
                                    'Variable' => 'VARIABLE'
                                }
                            }
                        }
                    }
                },
                {
                    'Statement' => {
                        'Command' => {
                            'SpecialCommand' => {
                                'Set' => {
                                    'Value'    => 'TheValueOfTheVariable',
                                    'Variable' => 'VARIABLE'
                                }
                            }
                        }
                    }
                },
            ]
        },
    };
    my $cmd_file = $PROGRAM_NAME;
    $cmd_file =~ s/\.t/\.cmd/;
    my $cmd_contents = path($cmd_file)->slurp;
    my $parser       = App::BatParser->new;
    my $ast          = $parser->parse($cmd_contents);
    use Data::Dumper;
    print Dumper $ast;

    is_deeply( $ast, $ast_expected,
        'Parsing a cmd with whitespaces in the end of lines' );
}

