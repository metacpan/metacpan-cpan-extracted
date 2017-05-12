package t::lib::Explain;
use strict;
use warnings;

use Test::Deep;

our @cases = (
	{
		code => '$_ = $_[2]',
		expected_ppidump => [
			re(q((?x)PPI::Document)),
			re(q((?x)  PPI::Statement)),
			re(q((?x)    PPI::Token::Magic          \s*   '\$_'        )),
			re(q((?x)    PPI::Token::Whitespace     \s*   '\ '         )),
			re(q((?x)    PPI::Token::Operator       \s*   '='          )),
			re(q((?x)    PPI::Token::Whitespace     \s*   '\ '         )),
			re(q((?x)    PPI::Token::Magic          \s*   '\$_'        )),
			re(q((?x)    PPI::Structure::Subscript  \s*   \[\ ...\ \]  )),
			re(q((?x)    PPI::Statement::Expression                    )),
			re(q((?x)        PPI::Token::Number     \s*   '2'          )),
		],
		expected_ppiexplain => [
			re(q((?x)\$_   \s* Default\ variable)),
			re(q((?x)        Not\ found)),
			re(q((?x)= \s*   Not\ found)),
			re(q((?x)        Not\ found)),
			re(q((?x)\$_   \s* Default\ variable)),
			re(q((?x)\[ \s*       Not\ found)),
			re(q((?x)2  \s* A\ number)),
			re(q((?x)\] \s*       Not\ found)),
		],
	},
);

1;
