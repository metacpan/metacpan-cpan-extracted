package C::sparse::expr;
our @ISA = qw (C::sparse);
use Carp;

our %typ_n = (

	C::sparse::EXPR_VALUE=>          "EXPR_VALUE",	 
	C::sparse::EXPR_STRING=>	 "EXPR_STRING",	 
	C::sparse::EXPR_SYMBOL=>	 "EXPR_SYMBOL",	 
	C::sparse::EXPR_TYPE=>	         "EXPR_TYPE",	 
	C::sparse::EXPR_BINOP=>	         "EXPR_BINOP",	 
	C::sparse::EXPR_ASSIGNMENT=>     "EXPR_ASSIGNMENT", 
	C::sparse::EXPR_LOGICAL=>	 "EXPR_LOGICAL",	 
	C::sparse::EXPR_DEREF=>	         "EXPR_DEREF",	 
	C::sparse::EXPR_PREOP=>	         "EXPR_PREOP",	 
	C::sparse::EXPR_POSTOP=>	 "EXPR_POSTOP",	 
	C::sparse::EXPR_CAST=>	         "EXPR_CAST",	 
	C::sparse::EXPR_FORCE_CAST=>     "EXPR_FORCE_CAST", 
	C::sparse::EXPR_IMPLIED_CAST=>   "EXPR_IMPLIED_CAST",
	C::sparse::EXPR_SIZEOF=>	 "EXPR_SIZEOF",	 
	C::sparse::EXPR_ALIGNOF=>	 "EXPR_ALIGNOF",	 
	C::sparse::EXPR_PTRSIZEOF=>	 "EXPR_PTRSIZEOF",	 
	C::sparse::EXPR_CONDITIONAL=>    "EXPR_CONDITIONAL",
	C::sparse::EXPR_SELECT=>	 "EXPR_SELECT",	 	
	C::sparse::EXPR_STATEMENT=>	 "EXPR_STATEMENT",	 
	C::sparse::EXPR_CALL=>	         "EXPR_CALL",	 
	C::sparse::EXPR_COMMA=>	         "EXPR_COMMA",	 
	C::sparse::EXPR_COMPARE=>	 "EXPR_COMPARE",	 
	C::sparse::EXPR_LABEL=>	         "EXPR_LABEL",	 
	C::sparse::EXPR_INITIALIZER=>    "EXPR_INITIALIZER",	
	C::sparse::EXPR_IDENTIFIER=>     "EXPR_IDENTIFIER", 	
	C::sparse::EXPR_INDEX=>	         "EXPR_INDEX",	 	
	C::sparse::EXPR_POS=>	         "EXPR_POS",	 	
	C::sparse::EXPR_FVALUE=>	 "EXPR_FVALUE",	 
	C::sparse::EXPR_SLICE=>	         "EXPR_SLICE",	 
	C::sparse::EXPR_OFFSETOF=>       "EXPR_OFFSETOF"   
);

our %m = (
    'C::sparse::expr::EXPR_NONE'        => { 'n' => 'C::sparse::expr::none',      'c' => [] },
    'C::sparse::expr::EXPR_VALUE'       => { 'n' => 'C::sparse::expr::value',     'c' => [] },
    'C::sparse::expr::EXPR_STRING'      => { 'n' => 'C::sparse::expr::string',    'c' => [] },
    'C::sparse::expr::EXPR_SYMBOL'      => { 'n' => 'C::sparse::expr::symbol',    'c' => [] },
    'C::sparse::expr::EXPR_TYPE'        => { 'n' => 'C::sparse::expr::type',      'c' => [] },
    'C::sparse::expr::EXPR_UNOP'        => { 'n' => 'C::sparse::expr::unop',      'c' => ['unop'] },
    'C::sparse::expr::EXPR_BINOP'       => { 'n' => 'C::sparse::expr::binop',     'c' => ['left','right'] },
    'C::sparse::expr::EXPR_ASSIGNMENT'  => { 'n' => 'C::sparse::expr::assign',    'c' => ['left','right'] },
    'C::sparse::expr::EXPR_LOGICAL'     => { 'n' => 'C::sparse::expr::logical',   'c' => ['left','right'] },
    'C::sparse::expr::EXPR_DEREF'       => { 'n' => 'C::sparse::expr::deref',     'c' => ['deref'] },
    'C::sparse::expr::EXPR_PREOP'       => { 'n' => 'C::sparse::expr::preop',     'c' => ['unop'] },
    'C::sparse::expr::EXPR_POSTOP'      => { 'n' => 'C::sparse::expr::postop',    'c' => ['unop'] },
    'C::sparse::expr::EXPR_CAST'        => { 'n' => 'C::sparse::expr::cast',      'c' => ['cast_expression'] },
    'C::sparse::expr::EXPR_FORCE_CAST'  => { 'n' => 'C::sparse::expr::cast',      'c' => [] },
    'C::sparse::expr::EXPR_IMPLIED_CAST'=> { 'n' => 'C::sparse::expr::cast',      'c' => [] },
    'C::sparse::expr::EXPR_SIZEOF'      => { 'n' => 'C::sparse::expr::sizeof',    'c' => ['cast_expression'] },
    'C::sparse::expr::EXPR_ALIGNOF'     => { 'n' => 'C::sparse::expr::alignof',   'c' => [] },
    'C::sparse::expr::EXPR_OFFSETOF'    => { 'n' => 'C::sparse::expr::offsetof',  'c' => ['down','index'] }, 
    'C::sparse::expr::EXPR_PTRSIZEOF'   => { 'n' => 'C::sparse::expr::ptrsizeof', 'c' => [] },
    'C::sparse::expr::EXPR_CONDITIONAL' => { 'n' => 'C::sparse::expr::cond',      'c' => ['conditional','cond_true','cond_false'] },
    'C::sparse::expr::EXPR_SELECT'      => { 'n' => 'C::sparse::expr::sel',       'c' => ['conditional','cond_true','cond_false'] },
    'C::sparse::expr::EXPR_STATEMENT'   => { 'n' => 'C::sparse::expr::stmt',      'c' => ['statement'] },
    'C::sparse::expr::EXPR_CALL'        => { 'n' => 'C::sparse::expr::call',      'c' => ['fn','args'] },
    'C::sparse::expr::EXPR_COMMA'       => { 'n' => 'C::sparse::expr::comma',     'c' => ['left','right'] },
    'C::sparse::expr::EXPR_COMPARE'     => { 'n' => 'C::sparse::expr::compare',   'c' => ['left','right'] },
    'C::sparse::expr::EXPR_LABEL'       => { 'n' => 'C::sparse::expr::label',     'c' => [] },
    'C::sparse::expr::EXPR_INITIALIZER' => { 'n' => 'C::sparse::expr::init',      'c' => ['expr_list'] },
    'C::sparse::expr::EXPR_IDENTIFIER'  => { 'n' => 'C::sparse::expr::ident',     'c' => [] },
    'C::sparse::expr::EXPR_INDEX'       => { 'n' => 'C::sparse::expr::idx',       'c' => ['idx_expression'] },
    'C::sparse::expr::EXPR_POS'         => { 'n' => 'C::sparse::expr::position',  'c' => ['init_expr'] },
    'C::sparse::expr::EXPR_FVALUE'      => { 'n' => 'C::sparse::expr::fvalue',    'c' => [] },
    'C::sparse::expr::EXPR_SLICE'       => { 'n' => 'C::sparse::expr::slice',     'c' => ['base'] },
	  
);

sub l { my ($s,$p) = @_;
	confess("Cannot map ".ref($s)) if (!defined($::C::sparse::expr::m{ref($s)}{'n'}));
	my @c = @{$::C::sparse::expr::m{ref($s)}{'c'}};
	my $_p = bless ({'_o'=>$s, '_p'=>$p},$::C::sparse::expr::m{ref($s)}{'n'}); 
	my @_c = map { $_->l($_p) } grep { defined($_) } map { $s->$_ } @c; 
	return ($_p, @_c);
      }

package C::sparse::expr::EXPR_NONE;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_VALUE;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_STRING;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_SYMBOL;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_TYPE;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_BINOP;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_ASSIGNMENT;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_LOGICAL;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_DEREF;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_PREOP;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_POSTOP;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_CAST;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_FORCE_CAST;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_IMPLIED_CAST;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_SIZEOF;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_ALIGNOF;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_PTRSIZEOF;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_CONDITIONAL;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_SELECT;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_STATEMENT;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_CALL;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_COMMA;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_COMPARE;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_LABEL;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_INITIALIZER;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_IDENTIFIER;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_INDEX;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_POS;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_FVALUE;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_SLICE;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::EXPR_OFFSETOF;
our @ISA = qw (C::sparse::expr);


package C::sparse::expr::none;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::value;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::string;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::symbol;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::type;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::binop;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::assign;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::logical;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::deref;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::preop;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::postop;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::cast;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::cast;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::cast;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::sizeof;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::alignof;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::offsetof;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::ptrsizeof;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::cond;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::sel;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::stmt;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::call;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::comma;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::compare;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::label;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::init;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::ident;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::idx;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::position; 
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::fvalue;
our @ISA = qw (C::sparse::expr);
package C::sparse::expr::slice;
our @ISA = qw (C::sparse::expr);














1;

