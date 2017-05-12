use Data::Dumper;
use Getopt::Long;
use Getopt::Long;
use Carp;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Cwd;
use Cwd 'abs_path';

$idre = $id = qr'(?:[a-zA-Z_][a-zA-Z_0-9:\.]*)';
$RE_balanced_squarebrackets =    qr'(?:[\[]((?:(?>[^\[\]]+)|(??{$RE_balanced_squarebrackets}))*)[\]])';
$RE_balanced_smothbrackets =     qr'(?:[\(]((?:(?>[^\(\)]+)|(??{$RE_balanced_smothbrackets}))*)[\)])';
$RE_balanced_brackets      =     qr'(?:[\{]((?:(?>[^\{\}]+)|(??{$RE_balanced_brackets}))*)[\}])';
$RE_comment_Cpp =                q{(?:\/\*(?:(?!\*\/)[\s\S])*\*\/|\/\/[^\n]*\n)};

Getopt::Long::Configure(qw(bundling));
GetOptions(\%OPT,qw{
d+
quite|q+
verbose|v+
outfile|o=s
}, @g_more) or usave(\*STDERR);

sub readfile {
    my ($in) = @_;
    usage(\*STDOUT) if (length($in) == 0) ;
    open IN, "$in" or die "Reading \"$in\":".$!;
    local $/ = undef;
    $m = <IN>;
    close IN;
    return $m;
}

$m = readfile ($ARGV[0]);

sub delspace { my ($m) = @_; $m =~ s/^\s+//s; $m; }
sub rmspace  { my ($m) = @_; $m =~ s/^\s+//s; $m =~ s/\s+$//s; $m; }
sub nrmspace { my ($m) = @_; $m =~ s/\s+/ /s; rmspace($m); }
sub unspace  { my ($m) = @_; $m =~ s/\s+/_/s; $m; }
sub dbgstr   { my ($m,$l) = @_; $m =~ s/\n/\\n/g; return substr($m, 0, $l).(length($m)>$l?"...":""); }
sub ident    { my ($ctx) = @_; my $r = ""; for (my $i = 0; $i < $$ctx{'i'}; $i++) { $r .= "|"; }; return $r; }

while ($m =~ /($idre)$RE_balanced_smothbrackets:\s*\n/m) {
  my ($id, $typ) = ($1,$2);
  $m = $';
  #  print (STDERR "$id,$typ\n"); 
  my @m = ();
  while (($m =~ /^((?:[ \t]+[^\n]*\n))/s)) {
    $m = $'; my $l = $1;
    #print ".".$l.":";
    if ($l =~ /(.+)\s+:\s+($idre)(.*)/) {
      my ($t,$n,$r) = ($1,$2,$3); $t = nrmspace($t);
      my $p = $n,;
      $p =~ s/\./_/g;
      my $a = {};
      if ($r =~ /$RE_balanced_brackets/) {
	eval ("\$a = { $1 };");
      }
      push(@m,{'n'=>nrmspace($n),'t'=>nrmspace($t),'a'=>$a});
      my $newpre = "";my $newpost = "";      
      my $gnewpre = "";my $gnewpost = "";      
      my $derefget = ""; my $derefset = ""; 
      if (defined($$a{'new'})) {
	  $newpre = "new_${t}(";
	  $newpost = ")";
	  $gnewpre = "->m";
	  $gnewpost = "";
      }
      if (defined($$a{'convctx'})) {
	$newpre .= $$a{'convctx'}."(p->m->ctx, ";
        $newpost .= ')';
      }
      if (defined($$a{'deref'})) {
	  $derefget = "&"; 
	  $derefset = "*";
      }
      my $vpost = $$a{'vpost'};
      my $name = $$a{'n'} ? $$a{'n'} : $p;

      my $ne;
      if (($ne = $$a{'array'})) {
	my $nn = $$ne[0];
	my $nt = $$ne[1];
	my $ni = $$ne[2];

	  

my $g = "
MODULE = C::sparse   PACKAGE = ${id}
PROTOTYPES: ENABLE

void
${name}(p,...)
        $typ p
    PREINIT:
        void *ptr; int i = 0;
        ${t}_t l; SPARSE_CTX_GEN(0);
    PPCODE:
        /*printf(\"e:%p x:%p %p\\n\",p->m, p->m->$n, p->m->$n->next);*/
        $ni; l = (${t}_t)(p->m->$n);
 	if (GIMME_V == G_ARRAY) {
	    while(l && !$nt(l)) {
	        EXTEND(SP, 1);
	        PUSHs(bless_${t}((${t}_t)l));
                l = l->$nn;
            }
        } else {
            EXTEND(SP, 1);
	    while(l && !$nt(l)) { i++; l = l->$nn; };
            PUSHs(sv_2mortal(newSViv(i)));
        }

";
      print $g;

      } elsif ($$a{'arrlist'}) {

my $g = "
MODULE = C::sparse   PACKAGE = ${id}
PROTOTYPES: ENABLE

void
${name}(p,...)
        $typ p
    PREINIT:
        struct ptr_list *l; void *ptr; int i = 0;
    PPCODE:
        l = (struct ptr_list *)(p->m->$n);
 	if (GIMME_V == G_ARRAY) {
	    FOR_EACH_PTR(l, ptr) {
	        EXTEND(SP, 1);
	        PUSHs(bless_${t}((${t}_t)ptr));
            } END_FOR_EACH_PTR(ptr);
        } else {
            EXTEND(SP, 1);
	    FOR_EACH_PTR(l, ptr) { i++; } END_FOR_EACH_PTR(ptr);
            PUSHs(sv_2mortal(newSViv(i)));
        }

";
      print $g;

      } else {
      
my $g = "
MODULE = C::sparse   PACKAGE = ${id}
PROTOTYPES: ENABLE

".nrmspace($t)." $vpost
${name}(p)
        $typ p
    PREINIT:
    CODE:
        RETVAL = ${newpre}${derefget}p->m->$n${newpost};
    OUTPUT:
	RETVAL
";
      print $g;

      my $cast = $$a{'cast'};

my $s = "
void
set_${name}(p,v)
        $typ p
        ".nrmspace($t)." ${vpost}v
    PREINIT:
    CODE:
        p->m->$n = ${derefset}$cast v${gnewpre};
";
      print $s if (!$$a{'noset'});


      }
    }
  }
  
}
