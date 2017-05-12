package C::sparse::stmt;
our @ISA = qw (C::sparse);

our %typ_n = (
	C::sparse::STMT_NONE        => "STMT_NONE",	      
	C::sparse::STMT_DECLARATION => "STMT_DECLARATION",  
	C::sparse::STMT_EXPRESSION  => "STMT_EXPRESSION",   
	C::sparse::STMT_COMPOUND    => "STMT_COMPOUND",     
	C::sparse::STMT_IF	    => "STMT_IF",	      
	C::sparse::STMT_RETURN	    => "STMT_RETURN",	      
	C::sparse::STMT_CASE	    => "STMT_CASE",	      
	C::sparse::STMT_SWITCH	    => "STMT_SWITCH",	      
	C::sparse::STMT_ITERATOR    => "STMT_ITERATOR",     
	C::sparse::STMT_LABEL	    => "STMT_LABEL",	      
	C::sparse::STMT_GOTO	    => "STMT_GOTO",	      
	C::sparse::STMT_ASM	    => "STMT_ASM",	      
	C::sparse::STMT_CONTEXT     => "STMT_CONTEXT",      
	C::sparse::STMT_RANGE       => "STMT_RANGE"          
);

our %m = (
    'C::sparse::stmt::STMT_NONE'        => 'C::sparse::stmt::none',
    'C::sparse::stmt::STMT_DECLARATION' => 'C::sparse::stmt::decl',
    'C::sparse::stmt::STMT_EXPRESSION'  => 'C::sparse::stmt::expr',
    'C::sparse::stmt::STMT_COMPOUND'    => 'C::sparse::stmt::comp',
    'C::sparse::stmt::STMT_IF'          => 'C::sparse::stmt::ifstmt',
    'C::sparse::stmt::STMT_RETURN'      => 'C::sparse::stmt::ret',
    'C::sparse::stmt::STMT_CASE'        => 'C::sparse::stmt::case',
    'C::sparse::stmt::STMT_SWITCH'      => 'C::sparse::stmt::switch',
    'C::sparse::stmt::STMT_ITERATOR'    => 'C::sparse::stmt::iter',
    'C::sparse::stmt::STMT_LABEL'       => 'C::sparse::stmt::label',
    'C::sparse::stmt::STMT_ASM'         => 'C::sparse::stmt::asm',
    'C::sparse::stmt::STMT_CONTEXT'     => 'C::sparse::stmt::ctx',
    'C::sparse::stmt::STMT_RANGE'       => 'C::sparse::stmt::range',
    'C::sparse::stmt::STMT_GOTO'        => 'C::sparse::stmt::gotostmt'
);

sub l { my ($s,$p) = @_; return bless ({'_o'=>$s, '_p'=>$p},$::C::sparse::stmt::m{ref($s)}); }

package C::sparse::stmt::STMT_NONE;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_DECLARATION;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_EXPRESSION;
our @ISA = qw (C::sparse::stmt);
sub l { my ($s,$p) = @_; my $_p = $s->C::sparse::stmt::l($p); return ($_p, (map { $_->l($_p) } grep { defined($_) } ($s->expression))); }

package C::sparse::stmt::STMT_COMPOUND;
our @ISA = qw (C::sparse::stmt);
sub l { my ($s,$p) = @_; my @a = $s->stmts; return () if (!scalar(@a)); my $_p = $s->C::sparse::stmt::l($p); return ((map { $_->l($_p) } @a)); }
sub c { my @s; return (@s = $_[0]->{'_o'}->stmts); }

package C::sparse::stmt::STMT_IF;
our @ISA = qw (C::sparse::stmt);
sub l { my ($s,$p) = @_; my $_p = $s->C::sparse::stmt::l($p); return ($_p, (map { $_->l($_p) } grep { defined($_) } ($s->if_true, $s->if_false))); }

package C::sparse::stmt::STMT_RETURN;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_CASE;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_SWITCH;
our @ISA = qw (C::sparse::stmt);
sub l { my ($s,$p) = @_; my $_p = $s->C::sparse::stmt::l($p); return ($_p, (map { $_->l($_p) } grep { defined($_) } ($s->switch_statement))); } 

package C::sparse::stmt::STMT_ITERATOR;
our @ISA = qw (C::sparse::stmt);
sub l { my ($s,$p) = @_; my $_p = $s->C::sparse::stmt::l($p); return ($_p, (map { $_->l($_p) } grep { defined($_) } ($s->iterator_pre_statement, $s->iterator_statement, $s->iterator_post_statement))); }


package C::sparse::stmt::STMT_LABEL;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_GOTO;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_ASM;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_CONTEXT;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::STMT_RANGE;
our @ISA = qw (C::sparse::stmt);



package C::sparse::stmt::none;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::decl;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::expr;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::comp;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::ifstmt;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::ret;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::case;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::switch;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::iter;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::label;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::asm;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::ctx;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::range;
our @ISA = qw (C::sparse::stmt);
package C::sparse::stmt::gotostmt;
our @ISA = qw (C::sparse::stmt);



1;
