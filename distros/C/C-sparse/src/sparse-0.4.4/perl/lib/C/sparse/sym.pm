package C::sparse::sym;
our @ISA = qw (C::sparse); 

our %typ_n = (
 	C::sparse::SYM_PREPROCESSOR =>"SYM_PREPROCESSOR",     
 	C::sparse::SYM_BASETYPE	    =>"SYM_BASETYPE",	     
 	C::sparse::SYM_NODE	    =>"SYM_NODE",	     
 	C::sparse::SYM_PTR	    =>"SYM_PTR",		     
 	C::sparse::SYM_FN	    =>"SYM_FN",		     
 	C::sparse::SYM_ARRAY	    =>"SYM_ARRAY",	     
 	C::sparse::SYM_STRUCT	    =>"SYM_STRUCT",	     
 	C::sparse::SYM_UNION	    =>"SYM_UNION",	     
 	C::sparse::SYM_ENUM	    =>"SYM_ENUM",	     
 	C::sparse::SYM_TYPEDEF	    =>"SYM_TYPEDEF",	     
 	C::sparse::SYM_TYPEOF	    =>"SYM_TYPEOF",	     
 	C::sparse::SYM_MEMBER	    =>"SYM_MEMBER",	     
 	C::sparse::SYM_BITFIELD	    =>"SYM_BITFIELD",	     
 	C::sparse::SYM_LABEL	    =>"SYM_LABEL",	     
 	C::sparse::SYM_RESTRICT	    =>"SYM_RESTRICT",	     
 	C::sparse::SYM_FOULED	    =>"SYM_FOULED",	     
 	C::sparse::SYM_KEYWORD	    =>"SYM_KEYWORD",	     
 	C::sparse::SYM_BAD             =>"SYM_BAD"
);           

sub totype { my $s = shift; C::sparse::type::totype($s->ctype->base_type,$s->ident,@_); }

package C::sparse::sym::SYM_UNINITIALIZED;
our @ISA = qw (C::sparse::sym);
package C::sparse::sym::SYM_PREPROCESSOR;
our @ISA = qw (C::sparse::sym);
package C::sparse::sym::SYM_BASETYPE;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_NODE;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
sub totype { my $s = shift; return C::sparse::type::totype($s->ctype->base_type,$s->ident,@_); }
package C::sparse::sym::SYM_PTR;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_FN;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);



package C::sparse::sym::SYM_ARRAY;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_STRUCT;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
sub totype { my $s = shift; return C::sparse::type::totype($s,$s->ident,@_); }


package C::sparse::sym::SYM_UNION;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
sub totype { my $s = shift; return C::sparse::type::totype($s,$s->ident,@_); }


package C::sparse::sym::SYM_ENUM;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_TYPEDEF;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_TYPEOF;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_MEMBER;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_BITFIELD;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_LABEL;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_RESTRICT;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_FOULED;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_KEYWORD;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);
package C::sparse::sym::SYM_BAD;
our @ISA = qw (C::sparse::sym C::sparse::sym::NS_SYMBOL);

1;

