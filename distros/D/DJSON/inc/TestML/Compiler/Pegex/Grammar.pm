package TestML::Compiler::Pegex::Grammar;

use TestML::Base;
extends 'Pegex::Grammar';

use constant file => '../testml-pgx/testml.pgx';

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.43)
  {
    '+grammar' => 'testml',
    '+include' => 'atom',
    '+toprule' => 'testml_document',
    '+version' => '0.0.1',
    '__' => {
      '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)+/
    },
    'assertion_call' => {
      '.any' => [
        {
          '-wrap' => 1,
          '.ref' => 'assertion_eq'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_ok'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_has'
        }
      ]
    },
    'assertion_call_test' => {
      '.rgx' => qr/\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(?:EQ|OK|HAS)/
    },
    'assertion_eq' => {
      '.any' => [
        {
          '-wrap' => 1,
          '.ref' => 'assertion_operator_eq'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_function_eq'
        }
      ]
    },
    'assertion_function_eq' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)EQ\(/
        },
        {
          '.ref' => 'code_expression'
        },
        {
          '.rgx' => qr/\G\)/
        }
      ]
    },
    'assertion_function_has' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)HAS\(/
        },
        {
          '.ref' => 'code_expression'
        },
        {
          '.rgx' => qr/\G\)/
        }
      ]
    },
    'assertion_function_ok' => {
      '.rgx' => qr/\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)(OK)(?:\((?:[\ \t]|\r?\n|\#.*\r?\n)*\))?/
    },
    'assertion_has' => {
      '.any' => [
        {
          '-wrap' => 1,
          '.ref' => 'assertion_operator_has'
        },
        {
          '-wrap' => 1,
          '.ref' => 'assertion_function_has'
        }
      ]
    },
    'assertion_ok' => {
      '.ref' => 'assertion_function_ok'
    },
    'assertion_operator_eq' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)+==(?:[\ \t]|\r?\n|\#.*\r?\n)+/
        },
        {
          '.ref' => 'code_expression'
        }
      ]
    },
    'assertion_operator_has' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)+\~\~(?:[\ \t]|\r?\n|\#.*\r?\n)+/
        },
        {
          '.ref' => 'code_expression'
        }
      ]
    },
    'assignment_statement' => {
      '.all' => [
        {
          '.ref' => 'variable_name'
        },
        {
          '.rgx' => qr/\G\s+=\s+/
        },
        {
          '.ref' => 'code_expression'
        },
        {
          '.ref' => 'ending'
        }
      ]
    },
    'blank_line' => {
      '.rgx' => qr/\G[\ \t]*\r?\n/
    },
    'blanks' => {
      '.rgx' => qr/\G[\ \t]+/
    },
    'block_header' => {
      '.all' => [
        {
          '.ref' => 'block_marker'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'blanks'
            },
            {
              '.ref' => 'block_label'
            }
          ]
        },
        {
          '.ref' => 'blank_line'
        }
      ]
    },
    'block_label' => {
      '.ref' => 'unquoted_string'
    },
    'block_marker' => {
      '.rgx' => qr/\G===/
    },
    'block_point' => {
      '.any' => [
        {
          '.ref' => 'lines_point'
        },
        {
          '.ref' => 'phrase_point'
        }
      ]
    },
    'call_argument' => {
      '.ref' => 'code_expression'
    },
    'call_argument_list' => {
      '.all' => [
        {
          '.rgx' => qr/\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*/
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'call_argument'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*/
                },
                {
                  '.ref' => 'call_argument'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\)/
        }
      ]
    },
    'call_call' => {
      '.all' => [
        {
          '+asr' => -1,
          '.ref' => 'assertion_call_test'
        },
        {
          '.ref' => 'call_indicator'
        },
        {
          '.ref' => 'code_object'
        }
      ]
    },
    'call_indicator' => {
      '.rgx' => qr/\G(?:\.(?:[\ \t]|\r?\n|\#.*\r?\n)*|(?:[\ \t]|\r?\n|\#.*\r?\n)*\.)/
    },
    'call_name' => {
      '.any' => [
        {
          '.ref' => 'user_call'
        },
        {
          '.ref' => 'core_call'
        }
      ]
    },
    'call_object' => {
      '.all' => [
        {
          '.ref' => 'call_name'
        },
        {
          '+max' => 1,
          '.ref' => 'call_argument_list'
        }
      ]
    },
    'code_expression' => {
      '.all' => [
        {
          '.ref' => 'code_object'
        },
        {
          '+min' => 0,
          '.ref' => 'call_call'
        }
      ]
    },
    'code_object' => {
      '.any' => [
        {
          '.ref' => 'function_object'
        },
        {
          '.ref' => 'point_object'
        },
        {
          '.ref' => 'string_object'
        },
        {
          '.ref' => 'number_object'
        },
        {
          '.ref' => 'call_object'
        }
      ]
    },
    'code_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'assignment_statement'
        },
        {
          '.ref' => 'code_statement'
        }
      ]
    },
    'code_statement' => {
      '.all' => [
        {
          '.ref' => 'code_expression'
        },
        {
          '+max' => 1,
          '.ref' => 'assertion_call'
        },
        {
          '.ref' => 'ending'
        }
      ]
    },
    'comment' => {
      '.rgx' => qr/\G\#.*\r?\n/
    },
    'core_call' => {
      '.rgx' => qr/\G([A-Z]\w*)/
    },
    'data_block' => {
      '.all' => [
        {
          '.ref' => 'block_header'
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.any' => [
            {
              '.ref' => 'blank_line'
            },
            {
              '.ref' => 'comment'
            }
          ]
        },
        {
          '+min' => 0,
          '.ref' => 'block_point'
        }
      ]
    },
    'data_section' => {
      '+min' => 0,
      '.ref' => 'data_block'
    },
    'double_quoted_string' => {
      '.rgx' => qr/\G(?:"((?:[^\n\\"]|\\"|\\\\|\\[0nt])*?)")/
    },
    'ending' => {
      '.any' => [
        {
          '.rgx' => qr/\G(?:;|\r?\n)/
        },
        {
          '+asr' => 1,
          '.ref' => 'ending2'
        }
      ]
    },
    'ending2' => {
      '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\}/
    },
    'function_object' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'function_signature'
        },
        {
          '.ref' => 'function_start'
        },
        {
          '+min' => 0,
          '.any' => [
            {
              '.ref' => '__'
            },
            {
              '.ref' => 'assignment_statement'
            },
            {
              '.ref' => 'code_statement'
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\}/
        }
      ]
    },
    'function_signature' => {
      '.all' => [
        {
          '.rgx' => qr/\G\((?:[\ \t]|\r?\n|\#.*\r?\n)*/
        },
        {
          '+max' => 1,
          '.ref' => 'function_variables'
        },
        {
          '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*\)/
        }
      ]
    },
    'function_start' => {
      '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*(\{)(?:[\ \t]|\r?\n|\#.*\r?\n)*/
    },
    'function_variable' => {
      '.rgx' => qr/\G([a-zA-Z]\w*)/
    },
    'function_variables' => {
      '.all' => [
        {
          '.ref' => 'function_variable'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.rgx' => qr/\G(?:[\ \t]|\r?\n|\#.*\r?\n)*,(?:[\ \t]|\r?\n|\#.*\r?\n)*/
            },
            {
              '.ref' => 'function_variable'
            }
          ]
        }
      ]
    },
    'lines_point' => {
      '.all' => [
        {
          '.ref' => 'point_marker'
        },
        {
          '.ref' => 'blanks'
        },
        {
          '.ref' => 'point_name'
        },
        {
          '.ref' => 'blank_line'
        },
        {
          '.ref' => 'point_lines'
        }
      ]
    },
    'number' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'number_object' => {
      '.ref' => 'number'
    },
    'phrase_point' => {
      '.all' => [
        {
          '.ref' => 'point_marker'
        },
        {
          '.ref' => 'blanks'
        },
        {
          '.ref' => 'point_name'
        },
        {
          '.rgx' => qr/\G:[\ \t]/
        },
        {
          '.ref' => 'point_phrase'
        },
        {
          '.rgx' => qr/\G\r?\n/
        },
        {
          '.rgx' => qr/\G(?:\#.*\r?\n|[\ \t]*\r?\n)*/
        }
      ]
    },
    'point_lines' => {
      '.rgx' => qr/\G((?:(?!(?:===|\-\-\-)\ \w).*\r?\n)*)/
    },
    'point_marker' => {
      '.rgx' => qr/\G\-\-\-/
    },
    'point_name' => {
      '.rgx' => qr/\G([a-z]\w*|[A-Z]\w*)/
    },
    'point_object' => {
      '.rgx' => qr/\G(\*[a-z]\w*)/
    },
    'point_phrase' => {
      '.ref' => 'unquoted_string'
    },
    'quoted_string' => {
      '.any' => [
        {
          '.ref' => 'single_quoted_string'
        },
        {
          '.ref' => 'double_quoted_string'
        }
      ]
    },
    'single_quoted_string' => {
      '.rgx' => qr/\G(?:'((?:[^\n\\']|\\'|\\\\)*?)')/
    },
    'string_object' => {
      '.ref' => 'quoted_string'
    },
    'testml_document' => {
      '.all' => [
        {
          '.ref' => 'code_section'
        },
        {
          '+max' => 1,
          '.ref' => 'data_section'
        }
      ]
    },
    'unquoted_string' => {
      '.rgx' => qr/\G([^\ \t\n\#](?:[^\n\#]*[^\ \t\n\#])?)/
    },
    'user_call' => {
      '.rgx' => qr/\G([a-z]\w*)/
    },
    'variable_name' => {
      '.rgx' => qr/\G([a-zA-Z]\w*)/
    }
  }
}

1;
