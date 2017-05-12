C::sparse::stream(sparsestream):
    int            : fd
    int            : constant
    int            : dirty
    int            : next_stream
    int            : once
    int            : issys
    const char *   : name
    const char *   : path
    sparseident    : protect    { new=>1 }
    sparsetok      : ifndef     { new=>1 }
    sparsetok      : top_if     { new=>1 }
    sparseexpand   : e          { new=>1 }

C::sparse::pos(sparsepos):
    int            : type       {}
    int            : stream     { n=>streamid }
    int            : newline    {}
    int            : whitespace {}
    int            : pos        {}
    int            : line       {}
    int            : noexpand   {}

C::sparse::stmt::STMT_NONE(sparsestmt):

C::sparse::tok(sparsetok):
    sparsepos    : pos              { new=>1, deref=>1, n=>position }
    sparsestream : pos.stream       { new=>1, convctx=>stream_get, noset=>1 }
    sparsetok    : next             { new=>1 }
    sparsetok    : copy             { new=>1 }
    sparseexpand : e                { new=>1 }

C::sparse::expand(sparseexpand):
    int   : typ 
    sparsetok :  s                  { new=>1, array=>['next','eof_token','SPARSE_CTX_SET(p->m->ctx)'] }
    sparsetok :  d                  { new=>1, array=>['next','eof_token','SPARSE_CTX_SET(p->m->ctx)'] }

C::sparse::expand::EXPANSION_MACROARG(sparseexpand):
    sparseexpand :  mac             { new=>1 }

C::sparse::expand::EXPANSION_MACRO(sparseexpand):
    sparsesym :  msym               { new=>1 }
    sparsetok :  tok                { new=>1 }

C::sparse::ident(sparseident):
    sparseident : next              { new=>1 }
    sparsesym   : symbols           { new=>1 }
    unsigned char : len
    unsigned char : tainted
    unsigned char : reserved
    unsigned char : keyword


C::sparse::stmt::STMT_DECLARATION(sparsestmt):
    sparsesym    : declaration      { new=>1, arrlist=>1 }

C::sparse::stmt::STMT_CONTEXT(sparsestmt):
    sparseexpr : expression         { new=>1, arrlist=>1 }

C::sparse::stmt::STMT_EXPRESSION(sparsestmt):
    sparseexpr : expression         { new=>1 }
    sparseexpr : context            { new=>1 }

C::sparse::stmt::STMT_COMPOUND(sparsestmt):
    sparsestmt : stmts              { new=>1, arrlist=>1 }
    sparsesym  : ret                { new=>1 }
    sparsesym  : inline_fn          { new=>1 }
    sparsestmt : args               { new=>1 }

C::sparse::stmt::STMT_IF(sparsestmt):
    sparseexpr : if_conditional     { new=>1 }
    sparsestmt : if_true            { new=>1 }
    sparsestmt : if_false           { new=>1 }

C::sparse::stmt::STMT_RETURN(sparsestmt):
    sparseexpr : ret_value          { new=>1 }
    sparsesym  : ret_target         { new=>1 }

C::sparse::stmt::STMT_CASE(sparsestmt):
    sparseexpr : case_expression    { new=>1 }
    sparseexpr : case_to            { new=>1 }
    sparsestmt : case_statement     { new=>1 }
    sparsesym  : case_label         { new=>1 }

C::sparse::stmt::STMT_SWITCH(sparsestmt):
    sparseexpr : switch_expression  { new=>1 }
    sparsestmt : switch_statement   { new=>1 }
    sparsesym  : switch_break       { new=>1 }
    sparsesym  : switch_case        { new=>1 }

C::sparse::stmt::STMT_ITERATOR(sparsestmt):
    sparsesym    : iterator_break          { new=>1 }
    sparsesym    : iterator_continue       { new=>1 }
    sparsesym    : iterator_syms           { new=>1, arrlist=>1 }
    sparsestmt   : iterator_pre_statement  { new=>1 }
    sparseexpr   : iterator_pre_condition  { new=>1 }
    sparsestmt   : iterator_statement      { new=>1 }
    sparsestmt   : iterator_post_statement { new=>1 }
    sparseexpr   : iterator_post_condition { new=>1 }

C::sparse::stmt::STMT_LABEL(sparsestmt):
    sparsesym    : label_identifier { new=>1 }
    sparsestmt   : label_statement  { new=>1 }

C::sparse::stmt::STMT_GOTO(sparsestmt):
    sparsesym    : goto_label       { new=>1 }
    sparseexpr   : goto_expression  { new=>1 }
    sparsesym    : target_list      { new=>1, arrlist=>1 }

C::sparse::stmt::STMT_ASM(sparsestmt):
    sparseexpr   : asm_string       { new=>1 }
    sparseexpr   : asm_outputs      { new=>1, arrlist=>1 }
    sparseexpr   : asm_inputs       { new=>1, arrlist=>1 }
    sparseexpr   : asm_clobbers     { new=>1, arrlist=>1 }
    sparsesym    : asm_labels       { new=>1, arrlist=>1 }

C::sparse::stmt::STMT_RANGE(sparsestmt):
    sparseexpr : range_expression   { new=>1 }
    sparseexpr : range_low          { new=>1 }
    sparseexpr : range_high         { new=>1 }






C::sparse::expr::EXPR_VALUE(sparseexpr):
    unsigned long long : value
    unsigned           : taint

C::sparse::expr::EXPR_FVALUE(sparseexpr):
    long double : fvalue

C::sparse::expr::EXPR_STRING
    int :  wide
    sparsestring : string

C::sparse::expr::EXPR_UNOP(sparseexpr):
    sparseexpr : unop                 { new=>1 }
    unsigned long : op_value
C::sparse::expr::EXPR_PREOP(sparseexpr):
    sparseexpr : unop                 { new=>1 }
    unsigned long : op_value
C::sparse::expr::EXPR_POSTOP(sparseexpr):
    sparseexpr : unop                 { new=>1 }
    unsigned long : op_value

C::sparse::expr::EXPR_SYMBOL(sparseexpr):
    sparsesym   : symbol              { new=>1 }
    sparseident : symbol_name         { new=>1 }
C::sparse::expr::EXPR_TYPE(sparseexpr):
    sparsesym   : symbol              { new=>1 }
    sparseident : symbol_name         { new=>1 }

C::sparse::expr::EXPR_STATEMENT(sparseexpr):
    sparsestmt : statement            { new=>1 }

C::sparse::expr::EXPR_BINOP(sparseexpr):
    sparseexpr : left                 { new=>1 }
    sparseexpr : right                { new=>1 }
C::sparse::expr::EXPR_COMMA(sparseexpr):
    sparseexpr : left                 { new=>1 }
    sparseexpr : right                { new=>1 }
C::sparse::expr::EXPR_COMPARE(sparseexpr):
    sparseexpr : left                 { new=>1 }
    sparseexpr : right                { new=>1 }
C::sparse::expr::EXPR_LOGICAL(sparseexpr):
    sparseexpr : left                 { new=>1 }
    sparseexpr : right                { new=>1 }
C::sparse::expr::EXPR_ASSIGNMENT(sparseexpr):
    sparseexpr : left                 { new=>1 }
    sparseexpr : right                { new=>1 }

C::sparse::expr::EXPR_DEREF(sparseexpr):
    sparseexpr  : deref               { new=>1 }
    sparseident : member              { new=>1 }

C::sparse::expr::EXPR_SLICE(sparseexpr):
    sparseexpr : base;                { new=>1 }
    unsigned   : r_bitpos
    unsigned   : r_nrbits

C::sparse::expr::EXPR_CAST(sparseexpr):
    sparsesym  : cast_type            { new=>1 }
    sparseexpr : cast_expression      { new=>1 }
C::sparse::expr::EXPR_SIZEOF(sparseexpr):
    sparsesym  : cast_type            { new=>1 }
    sparseexpr : cast_expression      { new=>1 }

C::sparse::expr::EXPR_CONDITIONAL(sparseexpr):
    sparseexpr : conditional          { new=>1 }
    sparseexpr : cond_true            { new=>1 }
    sparseexpr : cond_false           { new=>1 }
C::sparse::expr::EXPR_SELECT(sparseexpr): 
    sparseexpr : conditional          { new=>1 }
    sparseexpr : cond_true            { new=>1 }
    sparseexpr : cond_false           { new=>1 }

C::sparse::expr::EXPR_CALL(sparseexpr):
    sparseexpr : fn;                  { new=>1 }
    sparseexpr : args                 { new=>1, arrlist=>1 }

C::sparse::expr::EXPR_LABEL(sparseexpr):
    sparsesym  : label_symbol         { new=>1 }

C::sparse::expr::EXPR_INITIALIZER(sparseexpr):
    sparseexpr : expr_list            { new=>1, arrlist=>1 }

C::sparse::expr::EXPR_IDENTIFIER(sparseexpr):
    sparseident : expr_ident          { new=>1 }
    sparsesym   : field               { new=>1 }
    sparseexpr  : ident_expression    { new=>1 }

C::sparse::expr::EXPR_INDEX(sparseexpr):
    unsigned int : idx_from
    unsigned int : idx_to
    sparseexpr : idx_expression       { new=>1 }

C::sparse::expr::EXPR_POS(sparseexpr):
    unsigned int : init_offset
    unsigned int : init_nr
    sparseexpr   : init_expr          { new=>1 }

C::sparse::expr::EXPR_OFFSETOF(sparseexpr):
    sparsesym   : in                  { new=>1 }
    sparseexpr  : down                { new=>1 }
    sparseident : ident               { new=>1 }
    sparseexpr  : index               { new=>1 }

C::sparse::scope(sparsescope):
    sparsetok   : token               { new=>1 }
    sparsesym   : symbols             { new=>1, arrlist=>1 }
    sparsescope : next                { new=>1 }

C::sparse::sym(sparsesym):
    unsigned int : type
    unsigned int : namespace
    unsigned char : used
    unsigned char : attr
    unsigned char : enum_member
    unsigned char : bound
    sparsetok   : tok                 { new=>1 }
    sparsetok   : pos                 { new=>1, n=>position }
    sparsetok   : endpos              { new=>1 }
    sparseident : ident               { new=>1 }
    sparsesym   : next_id             { new=>1 }		
    sparsesym   : replace             { new=>1 }
    sparsescope : scope               { new=>1 }
    sparsesym   : same_symbol         { new=>1 }
    sparsesym   : next_subobject      { new=>1 }


C::sparse::sym::NS_SYMBOL(sparsesym):
    unsigned long : offset
    int		  : bit_size
    unsigned int  : bit_offset
    unsigned int  : arg_count
    unsigned int  : variadic
    unsigned int  : initialized
    unsigned int  : examined
    unsigned int  : expanding
    unsigned int  : evaluated
    unsigned int  : string
    unsigned int  : designated_init
    unsigned int  : forced_arg
    sparseexpr    : array_size         { new=>1 }
    sparsectype   : ctype              { new=>1, deref=>1 }
    sparsesym     : arguments          { new=>1, arrlist=>1 }
    sparsestmt    : stmt               { new=>1 }
    sparsesym     : symbol_list        { new=>1, arrlist=>1 }
    sparsestmt    : inline_stmt        { new=>1 }
    sparsesym     : inline_symbol_list { new=>1, arrlist=>1 }
    sparseexpr    : initializer        { new=>1 }
    struct entrypoint *ep
    long long     : value		
    sparsesym     : definition         { new=>1 }

C::sparse::ctype(sparsectype):
    unsigned long : modifiers
    unsigned long : alignment
    sparsesymctx  : contexts           { new=>1, arrlist=>1 }
    unsigned int  : as
    sparsesym     : base_type          { new=>1 }

C::sparse::symctx(sparsesymctx):
    sparseexpr   : context             { new=>1 }
    unsigned int : in
    unsigned int : out
