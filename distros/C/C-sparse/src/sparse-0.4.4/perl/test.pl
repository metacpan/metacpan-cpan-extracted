use POSIX;
use C::sparse qw(:all);
#use Devel::Peek;

%SYM_typ = (
	C::sparse::SYM_UNINITIALIZED=>"SYM_UNINITIALIZED" ,
	C::sparse::SYM_PREPROCESSOR =>"SYM_PREPROCESSOR"  ,
	C::sparse::SYM_BASETYPE     =>"SYM_BASETYPE"      ,
	C::sparse::SYM_NODE         =>"SYM_NODE"          ,
	C::sparse::SYM_PTR          =>"SYM_PTR"           ,
	C::sparse::SYM_FN           =>"SYM_FN"            ,
	C::sparse::SYM_ARRAY        =>"SYM_ARRAY"         ,
	C::sparse::SYM_STRUCT       =>"SYM_STRUCT"        ,
	C::sparse::SYM_UNION        =>"SYM_UNION"         ,
	C::sparse::SYM_ENUM         =>"SYM_ENUM"          ,
	C::sparse::SYM_TYPEDEF      =>"SYM_TYPEDEF"       ,
	C::sparse::SYM_TYPEOF       =>"SYM_TYPEOF"        ,
	C::sparse::SYM_MEMBER       =>"SYM_MEMBER"        ,
	C::sparse::SYM_BITFIELD     =>"SYM_BITFIELD"      ,
	C::sparse::SYM_LABEL        =>"SYM_LABEL"         ,
	C::sparse::SYM_RESTRICT     =>"SYM_RESTRICT"      ,
	C::sparse::SYM_FOULED       =>"SYM_FOULED"        ,
	C::sparse::SYM_KEYWORD      =>"SYM_KEYWORD"       ,
	C::sparse::SYM_BAD          =>"SYM_BAD"           
);

$s0 = C::sparse::sparse("t/test.c");
$s1 = C::sparse::sparse("t/test.c");
$s2 = C::sparse::sparse("t/test.c");

print("Files0:\n");
map { print " ".$_->name."\n" } (@files0 = $s0->streams);
my @f = grep { $_->name eq 't/test.c'} @files0;
$e = $f[0]->e;
@s = $e->s;
@d = $e->d;
print ("Source: ".scalar(@s)."\n");
print ("Dest  : ".scalar(@d)."\n");
print ("Source: ".join("",(map { 
  my $pre = "";
  if ((my $e = $_->e)) {
    $pre = ":" if ($e->typ == C::sparse::EXPANSION_MACRO) ;
  }
  $pre."[$_]" 
} (@s)))."\n");
print ("Dest  : ".join("",(map { "[$_]" } (@d)))."\n");




#while(1) {}
#foreach my $a (@a) {
#  if ($a->namespace != sparse::NS_PREPROCESSOR) {
#    my $cnt = $a->arguments;
#    my $symbt = $a->ctype->base_type;
#    
#    print "name         : ".$a->name."=".$a->ctype->typename."\n";
#    print "bttype       : ".$SYM_typ{$symbt->type}.":".sprintf("0x%x",$a->ctype->modifiers)."\n";
#  }
#}

#$p = 
#print($p->pos);

