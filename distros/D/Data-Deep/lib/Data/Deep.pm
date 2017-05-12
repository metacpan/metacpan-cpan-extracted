 ######################################################################
#############################################################################
package Data::Deep;
##############################################################################
  # Ultimate tool for Perl data manipulation
  ############################################################################
 ### Deep.pm
  ############################################################################
  # Copyright (c) 2005 Matthieu Damerose. All rights reserved.
  # This program is free software; you can redistribute it and/or
  # modify it under the same terms as Perl itself.
  ############################################################################
###
##
#
#


=head1 NAME

Data::Deep - Complexe Data Structure analysis and manipulation

=head1 SYNOPSIS

use Data::Deep;

$dom1=[ \{'toto' => 12}, 33,  {o=>5,d=>12}, 'titi' ];

$dom2=[ \{'toto' => 12, E=>3},{d=>12,o=>5}, 'titi' ];

my @patch = compare($dom1, $dom2);

use Data::Deep qw(:DEFAULT :convert :config);

o_complex(1);        # deeper analysis results

print join("\n", domPatch2TEXT( @patch ) );

@patch = (
 'add(@0$,@0$%E)=3','remove(@1,)=33','move(@2,@1)=','move(@3,@2)='
);

$dom2 = applyPatch($dom1,@patch);

@list_found = search($dom1, ['@',1])

@list_found = search($dom1, patternText2Dom('@1'))



=head1 DESCRIPTION

Data::Deep provides search, path, compare and applyPatch functions which may operate on complex Perl Data Structure 
for introspection, usage and manipulation 
(ref, hash or array, array of hash, blessed object and siple scalar).
Package, Filehandles and functions are partially supported (type and location is considered).
Loop circular references are also considered as a $t1 variable and partially supported.


=head2 path definition

path expression identify the current element node location in a complex Perl data structure.
pattern used in function search is used to match a part of this path.

Path is composed internally of an array of following elements :

   ('%', '<key>') to match a hash table at <key> value
   ('@', <index>) to match an array at specified index value
   ('*', '<glob name>') to match a global reference
   ('|', '<module name>') to match a blessed module reference

   ('$') to match a reference
   ('&') to match a code reference
   ('$loop') to match a loop reference (circular reference)

   ('=' <value>) to match the leaf node <value>

In text mode a keyname may be defined by entering an hash-ref of keys in o_key()
then '/keyname' will appears in the path text results or could be provided 
to convert function textPatch2dom() and patternText2dom()


Modifier <?> can be placed in the path with types to checks :

EX:

   ?%  : match with hash-table content (any key match)
   ?@  : match with an array content (any index match)
   ?=  : any value
   ?*  : any glob type
   ?$  : any reference
   ?=%@      : any value, hash-table or array
   ?%@*|$&=  : everything

Evaluation function :
   sub{... test with $_ ... } will be executed to match the node
   EX: sub { /\d{2,}/ } match numbers of minimal size of two

Patch is a directional operation to apply difference between two nodes resulting from compare($a, $b)
Patch allow the $a complex perl data structure to be changed to $b using applyPatch($a,@patch)

Each Patch operation is composed of :
   - an action :
        'add' for addition of an element from source to destination
        'remove' is the suppression from source to destination
        'move' if possible the move of a value or Perl Dom
        'change' describe the modification of a value
        'erase' is managed internally for array cleanup when using 'move'
   - a source path on which the value is taken from
   - a destination path on which is applied the change (most of the time same as source)

Three patch formats can be use :
   - dom : interaction with search, path, compare, ApplyPatch
   - text : programmer facilities to use a single scalar for a patch operation
   - ihm : a small readble IHM text aim for output only

Convert function may operation the change between this formats.


   DOM  : dom patch hash-ref sample

        EX: my $patch1 =
                     { action=>'change',
                       path_orig=>['@0','$','%a'],
                       path_dest=>['@0','$','%a'],
                       val_orig=>"toto",
                       val_dest=>"tata"
                     };

   TEXT : text output mode patch could be :

          add(<path source>,<path destination>)=<val dest>
          remove(<path source>,<path destination>)=<val src>
          change(<path source>,<path destination>)=<val src>/=><val dest>
          move(<path source>,<path destination>)


=head2 Important note :

* search() and path() functions use paths in "dom" format :

      DOM (simple array of elements described above)
            EX: ['@',1,'%','r','=',432]

* applyPath() can use TEXT or DOM patch format in input.

* compare() produce "dom" patch format in output.


All function prefer the use of dom (internal format) then no convertion is done.
Output (user point of view) is text or ihm.

format patches dom  can be converted to TEXT : domPatch2TEXT
format patches text can be converted to DOM  : textPatch2DOM
format patches dom  can be converted to IHM  : domPatch2IHM

See conversion function

=cut


##############################################################################
# General version and rules
##############################################################################
use 5.004;
$VERSION = '0.12';
#$| = 1;

##############################################################################
# Module dep
##############################################################################

use Carp;
use strict;
no warnings;
no integer;
no strict 'refs';


use overload; require Exporter; our @ISA = qw(Exporter);


our @DEFAULT =
  qw(
     travel
     visitor_patch
     visitor_dump
     visitor_perl_dump
     search
     compare
     path
     applyPatch
     __d
    );

our @EXPORT = @DEFAULT;


our @CONFIG =
  qw(
     o_debug
     o_follow_ref
     o_complex
     o_key
    );

our @CONVERT =
  qw(
      patternText2Dom
      patternDom2Text
      textPatch2DOM
      domPatch2TEXT
      domPatch2IHM
    );

our @EXPORT_OK = (@DEFAULT,
	      @CONFIG,
	      @CONVERT
	     );


our %EXPORT_TAGS=(
	      convert=>[@CONVERT],
	      config=>[@CONFIG]
	     );
##############################################################################
#/````````````````````````````````````````````````````````````````````````````\


my $CONSOLE_LINE=78;

##############################################################################


=head2 Options Methods

=over 4

=item I<zap>(<array of path>)

configure nodes to skip (in search or compare)
without parameter will return those nodes

=cut


sub zap {
  @_ and $Data::Deep::CFG->{zap}=shift()
    or return $Data::Deep::CFG->{zap};
}


 #############################################################################
### OPTIONS DECLARATION 
##############################################################################
 # Declare option  : _opt_dcl 'o_flg'
 # Read the option :           o_flg()
 # Set the option  :           o_flg(1)
 ############################################################################

our $CFG = {};

my $__opt_dcl = sub { my $name = shift();
		      my $proto = shift() || '$';

		      eval 'sub '.$name."(;$proto) {"
			  .' @_ and $Data::Deep::CFG->{'.$name.'}=shift()
                               or return $Data::Deep::CFG->{'.$name.'} }';
		      $@ and die '__bool_opt_dcl('.$name.') : '.$@;
		  };
 ############################################################################

=item I<o_debug>([<debug mode>])

debug mode :
   1: set debug mode on
   0: set debug mode off
   undef : return debug mode

=cut

$__opt_dcl->('o_debug');

 ############################################################################

=item I<o_follow_ref>([<follow mode>])

follow mode :
   1: follow every reference (default)
   0: do not enter into any reference
   undef: return if reference are followed

=cut

$__opt_dcl->('o_follow_ref');

o_follow_ref(1);


 ############################################################################

=item I<o_complex>([<complex mode>])

complex mode is used for intelligency complex (EX: elements move in an array)
   1: complex mode used in search() & compare()
   0: simple analysis (no complex search)
   undef: return if reference are followed

=cut

$__opt_dcl->('o_complex');


##############################################################################
sub debug {
##############################################################################
  o_debug() or return;

  # B.S./WIN : no output using STDERR 
  sub out__ { (($^O=~/win/i)?print @_:print SDTERR @_) }

  my $l;
  foreach $l(@_) {
    (ref $l)
      and out__ "\n".__d($l)
	or do {
	  out__$l;
	  if (length($l)>$CONSOLE_LINE) { out__ "\n" }
	  else { out__ ' ' }
	}
      }
  out__ "\n"
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub  __d {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $res = join('', travel(shift(), \&visitor_perl_dump));
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  $res =~ s/
	     ([\000-\037]|[\177-\377])
	   /sprintf("\\%o", ord ($1))/egx;

  return $res;
}

##############################################################################
###############################################################################
###############################################################################
# PRIVATE FX
###############################################################################
###############################################################################


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $matchPath = sub {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my @pattern=@{shift()};  # to match
  my @where=@_;    # current path
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  # warn 'matchPath('.join(' ',@where).' , '.join(' ',@pattern).')';


  my $ok;
  # warn 'matchPath:LongAlgo( '.join(' ',@pattern).', '.join(' ',@where).' )';
  my $i = 0;
 PATH:while ($i<=$#where) {

    my $j = 0;
    my $sav_i = $i;

  PATTERN: while ($i<=$#where) {

      ### CURRENT PATH
      my $t_where = $where[$i++]; # TYPE

      ## PATTERN
      my $t_patt = $pattern[$j++]; # TYPE

      if ($t_patt eq '/') {
        die 'internal matchPath('.join('',@pattern).') : key usage is only in textual format (use Text and convertion patternText2Dom)';
      }

      #print "$t_where =~ $t_patt : ";

      (index($t_patt,$t_where)==-1) and last PATTERN; # type where should be found in the pattern

      if ($t_where eq '&') { }
      elsif ($t_where eq '$') { }
      elsif ($t_where eq '=' or
	     $t_where eq '%' or
	     $t_where eq '@' or
	     $t_where eq '*' or
	     $t_where eq '|'
	    ) {

	my $v_where = $where[$i++];

	unless (substr($t_patt,0,1) eq '?') {
#print 'v';

	  my $v_patt = $pattern[$j++];

	  if (ref($v_patt) eq 'CODE') { # regexp or complexe val
            local ($_) = ($v_where);
	    $v_patt->($_) or last PATTERN
	  }
	  elsif (ref($v_patt) and (__d($v_patt) ne __d($v_where))) {
	    last PATTERN;
	  }
	  elsif (!defined($v_where) and defined($v_patt)) {
	    # print '!';
	    last PATTERN;
	  }
	  elsif (defined($v_where) and !defined($v_patt)) {
	    # print '!';
	    last PATTERN;
	  }
	  elsif (defined($v_where) and defined($v_patt) and $v_patt ne $v_where) {
	    # print '!';
	    last PATTERN;
	  }
	}
      }
      else {
#print '#';
	($i-1==$#where)
	  or
	    die 'Error in matched expression "'.join('',@where).'" not supported char type "'.$t_where.'".';
      }
#print '.';
      if ($j-1==$#pattern and $i-1==$#where) {
	# warn "#found($i,$j)";
	return $sav_i;
      }

    }# PATTERN:

    # next time
    ($j>1) and $i = $sav_i+1;

  }# WHERE:

  #print "\n";
  return undef;
};

##############################################################################
# KEY DCL :

sub o_key {
  @_ and $CFG->{o_key}=shift()
    or return $CFG->{o_key};
}

=item I<o_key>(<hash of key path>)

key is a search pattern for simplifying search or compare.
or a group of pattern for best identification of nodes.

hash of key path:


EX:
         key(
		CRC => {regexp=>['%','crc32'],
			eval=>'{crc32}',
			priority=>1
		       },
		SZ  => {regexp=>['%','sz'),
			eval=>'{sz}',
			priority=>2
		       }
             )


regexp   : path to search in the dom
eval     : is the perl way to match the node
priority : on the same node two ambigues keys are prioritized
depth    : how many upper node to return from the current match node

=back

=cut




##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $patchDOM = sub($$$;$$) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my $action = shift;
  my $p1= shift();
  my $p2= shift();
  my $v1 = shift();
  my $v2 = shift();
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my $dom = {};
  $dom->{action} = $action;
  $dom->{path_orig} = $p1;
  $dom->{path_dest} = $p2;
  $dom->{val_orig}  = $v1;
  $dom->{val_dest}  = $v2;

  return $dom;
};


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $path2eval__ = sub {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $first_eval = shift();
  my $deepness = shift();  # [ 0.. N ] return N from root
                           # [-N..-1]  return N stage from leaves
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  my $evaled = $first_eval;

  my $dbg_head = __PACKAGE__."::path2eval__(".join(',',@_).") : ";
  debug $dbg_head;
  my $max=$#_;

  @_ or return $evaled;

  if (defined $deepness and $deepness<=0) { # start from the end
    while ($deepness++<0 and $max>=0) {
      $_[$max-1] =~ /^[\@%\*\|\/=]$/ and $max-=2
	or
      $_[$max] =~ /^[\$\&]$/    and $max--;
    }
    ($max==0) and return $evaled; # upper as root

    debug "\n negative depth $deepness: -> remaining path(".join(',',@_[0..$max]).")\n";
    $deepness=undef;
  }
  my $deref='->';

  my $i=0;
  while($i<=$max) {
    $_ = $_[$i++];

    if ($_ eq '$') {
      $evaled = '${'.$evaled.'}';
      $deref = '->';
    }
    elsif ($_ eq '%') {
      $evaled .= $deref."{'".$_[$i++]."'}";
      $deref='';
    }
    elsif ($_ eq '@') {
      $evaled .= $deref.'['.$_[$i++].']';
      $deref='';
    }
    elsif ($_ eq '|') {
      $i++;
    }
    elsif ($_ eq '*') {
      $i++;
      my $suiv = $_[$i] or next;
      if ($suiv eq '%') {
	$evaled = '*{'.$evaled.'}{HASH}';
	$deref = '->';
      }
      elsif ($suiv eq '@'){
	$evaled = '*{'.$evaled.'}{ARRAY}';
	$deref = '->';
      }
      elsif ($suiv eq '$' or $suiv eq '='){
	$evaled = '*{'.$evaled.'}{SCALAR}';
	$deref = '->';
      }
    }
    elsif ($_ eq '/') { # KEY->{eval}
      my $keyname = $_[$i++];
      my $THEKEY  = $CFG->{o_key}{$keyname};
      my $ev = $THEKEY->{eval} or die $dbg_head.'bad eval code for '.$keyname;
      $evaled .= $deref.$ev;
      $deref='';
    }
    elsif ($_ eq '&') {
      $evaled = $evaled.'->()';
    }
    elsif ($_ eq '=') {
      ($i==$#_) or die $dbg_head.'bad path format : value waited in path after "="';

      if ($_[$i]=~/^\d+$/) {	
	$evaled = 'int('.$evaled.'=='.$_[$i++].')'
      }
      else {
	$evaled = 'int('.$evaled.' eq \''.$_[$i++].'\')'
      }

      $deref='';
    }
    else {
      die $dbg_head.'bad path format : Type '.$_.' not supported.'
    }

    if (defined($deepness)) {  # >0 start from root
      #print "\n positive depth $deepness:";
      last if (--$deepness==0);
    }
  }
  debug "-> $evaled #\n";
  return $evaled;
};

my %loop_ref=();
##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub loop_det($;@) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  my $r = shift();
  ref($r) or return 0;

  $r = $r.' ';

  if (exists($loop_ref{$r})) {
    debug "loop_det => LOOP".join('',@_) ;

    return 1;
  }

  $loop_ref{$r}=1;
  return 0;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PUBLIC FX
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




=head2 Operation Methods

=over 4

=cut


#############################################################
sub visitor_patch {
#                  Visitor which create patch for dom creation
#############################################################
    my $node = shift();
    my $depth = shift;
    my $open = shift;
    my @cur_path = @_;

    my $path = join('',@cur_path);

# warn $depth.($open==1?' > ':(defined($open)?' < ':'   ')).join('',@cur_path).' : '.ref($node);

    my $ref = ref($node);
    if ($ref) {
      if (!defined $open ) {
	($_[-1] eq '$loop') and return 'loop('.$path.','.$path.')=';
	($ref eq 'CODE') and return 'add('.$path.','.$path.')=sub{}';
	#($ref eq 'REF') and return 'add('.$path.','.$path.')={}';
	($ref eq 'GLOB') and return 'new '.$_[-1].'()';
      }
      elsif ($open ==1 ) {
	($ref eq 'ARRAY') and return 'add('.$path.','.$path.')=[]';
	($ref eq 'HASH') and return 'add('.$path.','.$path.')={}';
	return ;
      }
      elsif ($open ==0 ) {
	#($ref eq 'ARRAY') and return ']';
	#($ref eq 'HASH') and return '}';
	return;
      }

    }

    defined($node) and $node = "'$node'" or $node = 'undef';


    pop(@cur_path);
    pop(@cur_path);
    $path = join('',@cur_path);
    pop(@cur_path);
    pop(@cur_path);

    ($_[-2] eq '=') and return 'add('.join('',@cur_path).','.$path.')='.$node;


    return;

    # get the source code => How ?
#   (ref($node) eq 'CODE') and return $dump.'CODE';#(&$node());
 #   return $dump.ref($node);

}


#############################################################
sub visitor_perl_dump {
#                  Visitor to dump Perl structure
#############################################################
    my $node = shift();
    my $depth = shift;
    my $open = shift;
    my @cur_path = @_;

    my $path = @cur_path;

    my $ref = ref($node);

    my ($realpack, $realtype, $id) =
      (overload::StrVal($node) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    # warn $depth.($open==1?' > ':(defined($open)?' < ':'   ')).join('',@cur_path).' : '.ref($node)." ($realpack/$realtype/$id)";


    if ($ref) {
      if (!defined $open ) {
	($realpack and $realtype and $id) and $ref = $realtype;

	($ref eq 'REF' or $ref eq 'SCALAR') and return '\\';

	($ref eq 'CODE') and return 'sub { "DUMMY" }';

	if ($_[-1] eq '$loop') {
	  return '$t1';
	}

	if ($ref eq 'HASH' and $_[-2] eq '%') {
	  my @keys = sort {$a cmp $b} keys(%$node);
	  my $is_first = ($_[-1] eq $keys[0]);

	  $is_first 
	    and 
	      return '\''.$_[-1].'\'=>';

	  return ',\''.$_[-1].'\'=>';
	}
	($ref eq 'ARRAY' and $_[-2] eq '@' and $_[-1] != 0) and return ',';
	return;
      }
      elsif ($open ==1 ) {
	($ref eq 'ARRAY') and return '[';
	($ref eq 'HASH') and return '{';

	($realtype eq 'ARRAY') and return 'bless([';
	($realtype eq 'HASH') and return 'bless({';
      }
      elsif ($open ==0 ) {
	($ref eq 'ARRAY') and return ']';
	($ref eq 'HASH') and return '}';

	($realtype eq 'ARRAY') and return "] , '$ref')";
	($realtype eq 'HASH') and return "} , '$ref')";

      }
    }

    (defined($node)) or return 'undef';

    if ($_[-2] eq '=') {
      $node=~s/\'/\\\'/g;
      ($node=~/^\d+$/) and return $node;
      return '\''.$node.'\'';
    }

    return;

  }


#############################################################
sub visitor_dump {
#                  Visitor to dump Perl structure
#############################################################
    my $node = shift();
    my $depth = shift;
    my $open = shift;
    my @cur_path = @_;

    my $path = join('',@cur_path);

    my ($realpack, $realtype, $id) =
      (overload::StrVal($node) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    return $depth.($open==1?' > ':(defined($open)?' < ':'   ')).join('',@cur_path).' : '.ref($node); #." ( $realpack/$realtype/$id)";
  }


#############################################################
# IDEA : sub visitor_search { 
# IDEA : searching visitor to replace search
#############################################################
#    my $node = shift();
#    my $depth = shift;
#    my $open = shift;
#    my @cur_path = @_;

#    if (defined $matchPath->($pattern, @cur_path)) {
#	    defined($nb_occ) and (--$nb_occ<1) and die 'STOP';

#            return $node;
#    }
#}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub travel($;@) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  my $where=shift();
  my $visitor = shift() || \&visitor_patch;
  my $depth = shift()||0;
  my @path = @_;


=over 4

=item I<travel>(<dom> [,<visitor function>])

travel make the visitor function to travel through each node of the <dom>

   <dom>    complexe perl data structure to travel into
   <visitor_fx>()

Return a list path where the <pattern> argument match with the
   corresponding node in the <dom> tree data type

I<EX:>

   travel( {ky=>['l','r','t',124],r=>2}

   returns ( [ '%', 'ky', '@' , 3 , '=' , 124 ] )

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  if (@path) {
    debug "travel( dom=",@path, ' is ',ref($where),")";
    #debug "return ".($arr && ' ARRAY ' || 'SCALAR');
  }
  else {
    %loop_ref=();
  }

  #

  sub __appendVisitorResult {
    my $is_array = shift();
    my @list;

    foreach (@_) {
      if (defined $_) {
	$is_array or return $_;
	push(@list, $_);
      }
    }
    return @list;
  }

  my ($k,$res);
  my @res;

  #}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my $ref_type = ref $where;


  ######################################## !!!!! Modules type resolution
#  if (index($ref_type,'::')!=-1) {
  my ($realpack, $realtype, $id) =
    (overload::StrVal(scalar($where)) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

  if ($realpack and $realtype and $id) {
    push @path,'|',$ref_type;

    my $y = undef;
    if ($realtype eq 'SCALAR') {
      $y=$$where;
    }
    elsif ($realtype eq 'HASH') {
      $y=\%$where
    }
    elsif ($realtype eq 'ARRAY') {
      $y=\@$where
    }
    else {
      #die $realtype.' : '.$where;
    }

    #debug ref($y)." = $realpack -> real $realtype, $id";

    $where=$y;
    $ref_type = $realtype;
  }


  ######################################## !!!!! Loop detection
  my @p;

  if (loop_det($where)) {

    return __appendVisitorResult(wantarray(), @res,
				 &$visitor($where, $depth, undef , (@path, '$loop')));

  }
  else {
    ######################################## !!!!! SCALAR TRAVEL
    if (!$ref_type) {

      return __appendVisitorResult(wantarray(),
				   @res, 
				   &$visitor($where, $depth , undef, (@path, '=', $where)));

    }
    ######################################## !!!!! HASH TRAVEL
    elsif ($ref_type eq 'HASH')
      {

	@res = __appendVisitorResult(wantarray(),
				     @res, 
				     &$visitor($where, $depth, 1, @path));

	my $k;
	foreach $k (sort {$a cmp $b} keys(%{ $where })) {
	  @p = (@path, '%', $k);

	  @res = __appendVisitorResult(wantarray(),
				       @res,
				       &$visitor($where, $depth, undef, @p)
				      );

	  @res = __appendVisitorResult(
				       wantarray(),
				       @res,
				       travel($where->{$k},$visitor,$depth+1, @p)
				      );
	}

	return __appendVisitorResult( wantarray(),
				      @res,
				      &$visitor($where, $depth, 0, @path)
				    );

      }
    ######################################## !!!!! ARRAY TRAVEL
    elsif ($ref_type eq 'ARRAY')
      {
        $res = &$visitor($where, $depth, 1, @path);

	@res = __appendVisitorResult( wantarray(), @res, $res );

	for my $i (0..$#{ $where }) {
	  #print "\narray  $i (".$where->[$i].','.join('.',@p).")\n" if (join('_',@p)=~ /\@_1_\%_g_/);
	  @p = (@path, '@', $i);

	  @res = __appendVisitorResult(wantarray(),
				       @res,
				       &$visitor($where, $depth, undef, @p)
				      );

	  @res = __appendVisitorResult(
				       wantarray(),
				       @res,
				       travel($where->[$i],$visitor,$depth+1, @p)
				      );

	}

	return __appendVisitorResult( wantarray(),
				      @res,
				      &$visitor($where, $depth, 0, @path)
				    );

      }
    ######################################## !!!!! REFERENCE TRAVEL
    elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR')
      {
	@p = (@path, "\$");

	@res = __appendVisitorResult( wantarray(),
				      @res,
				      &$visitor($where, $depth, undef,  @p )
				    );

	return __appendVisitorResult( wantarray(),
				      @res,
				      travel( ${ $where }, $visitor, $depth+1, @p )
				    );
      }
    else { # others types
      ######################################## !!!!! CODE TRAVEL
      if ($ref_type eq 'CODE') {
	@p = (@path, '&');
      }
      ######################################## !!!!! GLOB TRAVEL
      elsif ($ref_type eq 'GLOB') {
	my $name=$$where;
	$name=~s/b^\*//;
	@p = (@path, '*', $name);
      }
      ######################################## !!!!! MODULE TRAVEL
      else {
	#die $ref_type;
      }

      ######################################## !!!!! GLOB TRAVEL
      # cf IO::Handle or Symbol::gensym()

      if ($p[-2] eq '*') { # GLOB
	for $k (qw(SCALAR ARRAY HASH)) {
	  my $gval = *$where{$k};
	  defined($gval) or next;
	  next if ($k eq "SCALAR" && ! defined $$gval);  # always there

	  return __appendVisitorResult( wantarray(),
					@res,
					travel($gval, $visitor, $depth+1, undef, @p)
				      );
	}
      }

      return __appendVisitorResult(
				   wantarray(),
				   @res,
				   &$visitor($where, $depth, undef, @p )
				  );
    }
  }

  return ();
}



my %circular_ref;
##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub search($$;$@) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $where = shift();
  my $pattern = shift();
  my $nb_occ = shift();
  my @path=@_;

#  warn "search for #$nb_occ (",join('',@{$pattern}),")";


=item I<search>(<tree>, <pattern> [,<max occurrences>])

search the <pattern> into <tree>

   <tree>      is a complexe perl data structure to search into
   <pattern>   is an array of type description to match
   <max occ.>  optional argument to limit the number of results
                  if undef all results are returned
		  if 1 first one is returned

Return a list path where the <pattern> argument match with the
    corresponding node in the <dom> tree data type

EX:
    search( {ky=>['l','r','t',124],r=>2}
            ['?@','=',124])

      Returns ( [ '%', 'ky', '@' , 3 , '=' , 124 ] )


    search( [5,2,3,{r=>3,h=>5},4,\{r=>4},{r=>5}],
            ['%','r'], 2 )

      Returns (['@',3,'%','r'],['@',5,'$','%','r'])


    search( [5,2,3,{r=>3},4,\3],
            ['?$@%','=',sub {$_ == 3 }],
            2;

      Returns (['@',2,'=',3], ['@',3,'%','r','=',3])

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  # warn "search($where / ref=".ref($where).','.$nb_occ.' ,'.join('',@path).")";

  @path or %loop_ref=();

  (defined($nb_occ) and ($nb_occ<1)) and return ();

  my $ref_type = ref $where;

  my @found;
  my $next = undef;
  my @p;

  ######################################## !!!!! Modules type resolution
  if ($ref_type) {

    #if (index($where,'::')!=-1) {  ## !!!!! MODULE SEARCH

    my ($realpack, $realtype, $id) =
      (overload::StrVal($where) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    if ($realpack and $realtype and $id) {
      push @path, ('|', $ref_type);

      $ref_type = $realtype;

      #warn "$ref_type -> ($realpack, $realtype, $id )";
    }


    ######################################## !!!!! Loop detection

    if (loop_det($where)) {
      @p = (@path, '$loop');
    }
    ######################################## HASH Search
    elsif ($ref_type eq 'HASH') {
      my $k;
      foreach $k (sort {$a cmp $b} keys(%{ $where })) {
	@p = (@path, '%', $k);

	if (defined $matchPath->($pattern, @p)) {
	  push @found,[@p];
	  defined($nb_occ) and (--$nb_occ<1) and last;
	}
	else {
	  my @res = search($where->{$k}, $pattern, $nb_occ, @p);
	  @res and push @found,@res;
	}
      }
      return @found;
    }
    ######################################## HASH Search
    elsif ($ref_type eq 'ARRAY')
      {
	for my $i (0..$#{ $where }) {
	  @p = (@path, '@', $i);

	  if (defined $matchPath->($pattern, @p)) {
	    push @found,[@p];
	    defined($nb_occ) and (--$nb_occ<1) and last;
	  }
	  else {
	    my @res = search($where->[$i], $pattern, $nb_occ, @p);
	    @res and push @found,@res;
	  }
	}
	return @found;
      }
    ######################################## REF Search
    elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR') {
      @p = (@path, '$');
      $next = ${ $where };
    }
    ######################################## CODE Search
    elsif ($ref_type eq 'CODE') {
      @p = (@path, '&');
    }
    ######################################## GLOB Search
    elsif ($ref_type eq 'GLOB') {
      my $name = $$where;
      $name=~s/^\*//;
      @p = (@path, '*',$name);
      if (defined *$where{SCALAR} and defined(${*$where{SCALAR}})) {
	$next = *$where{SCALAR};
      }
      elsif (defined *$where{ARRAY}) {
	$next = *$where{ARRAY};
      }
      elsif (defined *$where{HASH}) {
	$next = *$where{HASH};
      }
    }
  }
  ######################################
  else { ## !!!!! SCALAR Search
    @p = (@path, '=', $where);
  }
  ######################################

  if (defined $matchPath->($pattern, @p)) {
    push @found,[@p];
    defined($nb_occ) and --$nb_occ;
  }

  if ((defined($next))) {
    my @res = search($next, $pattern, $nb_occ, @p);

    @res and push @found,@res;
  }

  return @found;
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub path($$;$) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $dom = shift();
  my @paths = @{shift()};
  my $father_nb = shift() or 0;


=item I<path>(<tree>, <paths> [,<depth>])

gives a list of nodes pointed by <paths>
   <tree> is the complex perl data structure
   <paths> is the array reference of paths
   <depth> is the depth level to return from tree
      <nb> start counting from the top
      -<nb> start counting from the leaf
      0 return the leaf or check the leaf with '=' or '&' types):
             * if code give the return of execution
             * scalar will check the value

Return a list of nodes reference to the <dom>

EX:

    $eq_3 = path([5,{a=>3,b=>sub {return 'test'}}],
                  ['@1%a'])

    $eq_3 = path([5,{a=>3,b=>sub {return 'test'}}],
                  '@1%a','@1%b')


    @nodes = path([5,{a=>3,b=>sub {return 'test'}}],
                   ['@1%b&'], # or [['@',1,'%','b','&']]

                   0  # return ('test')
                      # -1 or 2 return ( sub { "DUMMY" } )
		      # -2 or 1 get the hash table
		      # -3 get the root tree
                   )]);

    @nodes = path([5,{a=>3,b=>sub {return 'test'}}],
                   ['@1%a'], # or [['@',1,'%','b','&']]

                   0  # return 3
                      # -1 or 2 get the hash table
		      # -2 or 1 get the root tree
                   )]);


=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}


  debug "path( \$dom, $#paths patch, $father_nb)";

  my @nodes;

  foreach my $node (@paths) {
    (ref($node) eq 'ARRAY') or die 'path() : pattern "'.$node.'" should be a Dom pattern ("Dom" internal array, perhaps use patternText2dom)';

    my @path = @{$node};

    # perl evaluation of the dom path
    my $e = $path2eval__->('$dom', $father_nb, @path);

    my $r = eval $e;
    debug $dom;
    debug $e.' evaluated to '.__d($r);
    die __FILE__.' : path() '.$e.' : '.$@ if ($@);
    push @nodes,$r
  }
  return shift @nodes unless (wantarray());
  return @nodes;
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub compare {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  # ############ ret : 0 if equal / 1 else
  my $d1 = shift();
  my $d2 = shift();

  my (@p1,@p2,$do_resolv_patch);
  if (@_) {
    @p1 = @{$_[0]};
    @p2 = @{$_[1]};
  }
  else {
    %loop_ref=();
    # equiv TEST on each function call: if ($CFG->{o_complex} and ($#a1==-1 and $#a2==-1)) {
    $CFG->{o_complex} and $do_resolv_patch=1;
  }

=item I<compare>(<node origine>, <node destination>)

compare nodes from origine to destination
nodes are complex perl data structure

Return a list of <patch in dom format> (empty if node structures are equals)

EX:

   compare(
           [{r=>new Data::Dumper([5],ui=>54},4],
           [{r=>new Data::Dumper([5,2],ui=>52},4]
          )

    return ({ action=>'add',
              ...
            },
            { action=>'change',
              ...
            },
             ...
          )

=cut


#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}



  ###############################################################################
  sub searchSuffix__{
    my @a1=@{shift()};
    my @a2=@{shift()};
    my @patch=@{shift()};

    my @common;
    while (@a1 and @a2) {
      $_= pop(@a1);
      ($_ eq pop(@a2)) and unshift @common,$_ or return @common
    }
    return @common
  }
  ###############################################################################

  sub resolve_patch {
    my @patch = @_;
    my ($p1,$p2);

    foreach $p1 (@patch) {
      foreach $p2 (@patch) {

	if ($p1->{action} eq 'remove' and
	    $p2->{action} eq 'add' and
	    (__d($p1->{val_orig}) eq __d($p2->{val_dest}))) {

	  #my @com = searchSuffix__($p1->{path_orig}, $p2->{path_dest}, \@patch);
	  #@com or next;
	  #grep({$_ eq '&'}  @com) or next;
	  push @patch,
	    compare($p1->{val_orig},
		    $p2->{val_dest},
		    [@{$p1->{path_orig}}],
		    [@{$p2->{path_dest}}]
		   );

	  $p1->{action}='move';
	  $p1->{val_orig}= $p1->{val_dest}= undef;
	  $p1->{path_dest}= $p2->{path_dest};
	  $p2->{action}='erase';
	}
      }
    }

    my $o = 0;
    while ($o<=$#patch) {
      ($patch[$o]->{action} eq 'erase') and splice(@patch,$o,1) and next;
      $o++
    }

    return @patch
  }

  ###############################################################################
  #warn "\nComparing ORIG(".join(@p1,'=',ref($d1)||$d1).") <> DEST(".join('.',@p2,'=',ref($d2)||$d2).")\n";

  # ############ ret : 0 if equal / 1 else
  my @msg=();

  ######################################## !!!!! Type resolution
  my $ref_type = ref $d1;

  if ($ref_type) {

    ($ref_type ne ref($d2))
      and 
	return ( $patchDOM->('change', \@p1,\@p2, $d1,$d2) );

    #if (index($ref_type,'::')!=-1) {

    my ($realpack, $realtype, $id) =
      (overload::StrVal($d1) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    if ($realpack and $realtype and $id) {
      my ($realpack2, $realtype2, $id2) =
	(overload::StrVal($d2) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

      ($realtype ne $realtype2)
	and
	  push @msg, $patchDOM->('change', \@p1 ,\@p2 , $realtype ,$realtype2);

      push @p1, '|',$ref_type;
      push @p2, '|',$ref_type;
	
      debug "$ref_type -> ($realpack, $realtype, $id : $ref_type)";

      $ref_type = $realtype;
    }
  }

  ######################################## !!!!! SCALAR COMPARE
  if (!$ref_type)
    {
      (defined($d1) and $d1 ne $d2) and return ($patchDOM->('change', \@p1,\@p2, $d1,$d2) );
      (!defined($d1) and defined($d2)) and return ($patchDOM->('change', \@p1,\@p2, $d1,$d2) );
      return ();
    }
  ######################################## !!!!! HASH COMPARE
  elsif ($ref_type eq 'HASH')
    {
      my (%seen,$k);

      foreach $k (sort {$a cmp $b}
		  keys(%{ $d1 }))
	{
	  $seen{$k}=1;

	  if (exists $d2->{$k}) {

	    loop_det($d1->{$k},@p1) and next;

	    push @msg,
	      compare( $d1->{$k},
		       $d2->{$k},
		       [ @p1, '%',$k ],
		       [ @p2, '%',$k ],
		     );
	  } else {
	    push @msg,$patchDOM->('remove', [ @p1, '%', $k ] ,\@p2 , $d1->{$k} ,undef)
	  }

	}#foreach($d1)

      foreach $k (sort {$a cmp $b} keys(%{ $d2 })) {
	next if exists $seen{$k};

	my $v = $d2->{$k};
	push @msg,$patchDOM->('add', \@p1, [ @p2, '%', $k ], undef, $v)
      }

      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);
    }
  elsif ($ref_type eq 'ARRAY')
    {
      ######################################## !!!!! ARRAY COMPARE (not complex mode)

      unless ($CFG->{o_complex}) {

	my $min = $#{$d1};
	$min = $#{$d2} if ($#{$d2}<$min); # min ($#{$d1},$#{$d2})

	my $i;
	foreach $i (0..$min) {

	  loop_det($d1->[$i], @p1)
	    and
	      next;

	  push @msg,
	    compare( $d1->[$i], $d2->[$i], [@p1, '@',$i], [@p2, '@',$i]);
	}

	foreach $i ($min+1..$#{$d1}) { # $d1 is bigger
	  # silent just for complexe search mode
	  push @msg,$patchDOM->('remove', [ @p1, '@', $i ], \@p2 ,$d1->[$i], undef)
	}
	foreach $i ($#{$d1}+1..$#{$d2}) { # d2 is bigger
	  push @msg,$patchDOM->('add', \@p1, [ @p2, '@', $i ], undef, $d2->[$i])
	}
	return @msg;
      }

      ######################################## !!!!! ARRAY COMPARE (in complex mode)
      my @seen_src;
      my @seen_dst;
      my @res_Eq;
      # perhaps not on the same index (search in the dest @)
      my $i; 
    ARRAY_CPLX:
      foreach $i (0..$#{$d1}) {
	my $val1 = $d1->[$i];
	
	#print "\n SAR($i) {";
	#if ($i<$#{$d2}) {
	if (exists $d2->[$i]) {
	  my @res;

	  loop_det($val1, @p1)
	    or
	      @res = compare($val1,
			     $d2->[$i],
			     [ @p1, '@',$i ],
			     [ @p2, '@',$i ]);

	  if (@res) {	$res_Eq[$i] = [@res]	    }   # (*)
	  else
	    {
	      $seen_src[$i]=$i;
	      $seen_dst[$i]=$i;
	      next ARRAY_CPLX;
	    }
	}
	my $j;
	foreach $j (0..$#{$d2}) {  #print " -> $j ";
	  next if ($i==$j);
	  next if (defined($seen_dst[$j]));

	  unless (compare( $val1,
			   $d2->[$j],
			   [ @p1, '@',$i ],
			   [ @p2, '@',$j ]))
	    {  #print " (found) ";

	      $seen_dst[$j] = 1;
	      $seen_src[$i] = $patchDOM->('move',
					  [ @p1, '@', $i ],
					  [ @p2, '@', $j ]);
	      next ARRAY_CPLX;
	    }
	}
	(defined  $seen_src[$i])
	  or
	    $seen_src[$i] = $patchDOM->('remove', 
					[ @p1, '@', $i ],
					\@p2,
					$val1,
					undef
				       );

	#print " }SAR($i)";
      } # for $d1 (0..$min)

      ### destination table $d2 is bigger
      ##
      foreach $i (0..$#{$d2}) {
	defined($seen_dst[$i]) and next;

	$seen_dst[$i] = $patchDOM->('add',
				    \@p1,
				    [ @p2, '@', $i ],
				    undef, 
				    $d2->[$i]
				   )
      }

      my $max = $#seen_dst;

      ($#seen_src>$max) and $max = $#seen_src;

      foreach (0..$max) {
	my $src = $seen_src[$_];
	my $dst = $seen_dst[$_];

	if (ref($res_Eq[$_]) and # differences on the same index (*)
	    ref($src) and ref($dst)) {

	  #print "\n src/dst : ".domPatch2TEXT($src)."/ ".domPatch2TEXT($dst)."\n";

	  # remove(@2,)=<val1> add(,@2)=<val2 => <patch val1 val2>
	  ($src->{action} eq 'remove') and
	    ($dst->{action} eq 'add') and
	      (push @msg, @{ $res_Eq[$_] })
		and next;
	}
	(ref $src) and push @msg,$src;
	(ref $dst) and push @msg,$dst;
      }

      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);
    }
  ######################################## !!!!! REF COMPARE
  elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR')
    {
      if (loop_det($$d1, @p1)) {
      }
      else {
	@msg = ( compare($$d1, $$d2,
			 [ @p1, '$' ],
			 [ @p2, '$' ])
	       );
      }
      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);
    }
  ######################################## !!!!! GLOBAL REF COMPARE
  elsif ($ref_type eq 'GLOB')
    {
      my $name1=$$d1;
      $name1=~s/^\*//;
      my $name2=$$d2;
      $name2=~s/^\*//;

      push @p1,'*', $name1;
      push @p2,'*', $name2;

      push @msg, $patchDOM->('change', \@p1 ,\@p2);

      my ($k,$g_d1,$g_d2)=(undef,undef,undef);

      if (defined *$d1{SCALAR} and defined(${*$d1{SCALAR}})) {
	$g_d1 = *$d1{SCALAR};
      }
      elsif (defined *$d1{ARRAY}) {
	$g_d1 = *$d1{ARRAY};
      }
      elsif (defined*$d1{HASH}) {
	$g_d1 = *$d1{HASH};
      }
      elsif (defined*$d1{GLOB}) {
	$g_d1 = *$d1{GLOB};
	loop_det($g_d1, @p1) and return ();
      }
      else {
	die $name1;
      }

      if (defined *$d2{SCALAR} and defined(${*$d2{SCALAR}})) {
	$g_d2 = *$d2{SCALAR};
      }
      elsif (defined *$d2{ARRAY}) {
	$g_d2 = *$d2{ARRAY};
      }
      elsif (defined*$d2{HASH}) {
	$g_d2 = *$d2{HASH};
      }
      elsif (defined*$d2{GLOB}) {
	$g_d2 = *$d2{GLOB};
      }
      else {
	die $name2;
      }

      my @msg = ( compare($g_d1, $g_d2, \@p1, \@p2));

      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);

    }
  ######################################## !!!!! CODE REF COMPARE
  elsif ($ref_type eq 'CODE') {      # cannot compare this type

    #push @msg,$patchDOM->('change', \@p1, [@p2, '@', $i ], undef, $d2->[$i])
    return ();
  }
  ######################################## !!!!! What's that ?
  else {
    die 'unknown type /'.$ref_type.'/ '.join('',@p1);
  }
  return ();
}



##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub applyPatch($@) { # modify a dom source with a patch
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $dom = shift();


=item I<applyPatch>(<tree>, <patch 1> [, <patch N>] )

applies the patches to the <tree> (perl data structure)
<patch1> [,<patch N> ] is the list of your patches to apply
supported patch format should be text or dom types,
the patch should a clear description of a modification
no '?' modifier or ambiguities)

Return the modified dom, die if patch are badly formated

EX:
    applyPatch([1,2,3],'add(,@4)=4')
    return [1,2,3,4]

=back

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  debug 'applyPatch('.__d($dom).') :';
  my (@remove,@add,@change,@move);

  my $p;
  foreach $p (@_) { # ordering the patch operations
    defined($p) or next;
    my $dom_patch = $p;

    (ref($p) eq 'HASH')
      or ($dom_patch) = textPatch2DOM($p);

    debug(domPatch2TEXT($dom_patch));

    eval 'push @'.$dom_patch->{action}.', $dom_patch;';
    $@ and die 'applyPatch() : '.$@;
  }

  my ($d,$t);

  my ($d1,$d2,$d3,$d4,$d5);
  my ($t1,$t2,$t3,$t4,$t5);

  my $patch_eval='$d='.__d($dom).";\n";

  $patch_eval .= '$t='.__d($dom).";\n";

  my $post_eval;

  my $r;
  foreach $r (@remove) {
    my @porig = @{$r->{path_orig}};

    my $key =  pop @porig;
    my $type = pop @porig;

    if ($type eq '@') {
      $patch_eval .= 'splice @{'.$path2eval__->('$d',undef,@porig) ."},$key,1;\n";
    }
    else {
      $patch_eval .= 'delete '.$path2eval__->('$d',undef,@porig,$type,$key) .";\n";
    }
  }

  my $m;
  my @remove_patch = sort
		 {
		   # the array indexes order from smallest to biggest
		   if (${$a->{path_orig}}[-2] eq '@') {
		     return (${$a->{path_orig}}[-1] >
			     ${$b->{path_orig}}[-1])
		   }
		   # smallest path after bigger ones
		   return $#{$a->{path_orig}} < $#{$b->{path_orig}};
		 } @move;

  foreach $m (@remove_patch) {
    my @porig = @{$m->{path_orig}};

    my $key =  pop @porig;
    my $type = pop @porig;

    if ($type eq '@') {
      $patch_eval .= 'splice @{'.$path2eval__->('$d',undef,@porig)."},$key,1;\n";
    }
    else {
      $patch_eval .= 'delete '.$path2eval__->('$d',undef,@porig,$type,$key) .";\n";
    }
  }

  foreach $m (@remove_patch) {
    my @porig = @{$m->{path_orig}};
    $patch_eval .= $path2eval__->('$d',undef,@{$m->{path_dest}}).
      ' = '.$path2eval__->('$t',undef,@porig).";\n";
  }


  my $a;
  foreach $a (@add) {
    $patch_eval .=
      $path2eval__->('$d',undef,@{$a->{path_dest}}).
	' = '.__d($a->{val_dest}) .";\n";
  }
  my $c;
  foreach $c (@change) {
    $patch_eval .=
      $path2eval__->('$d',undef,@{$c->{path_dest}}).
	' = '.__d($c->{val_dest}).";\n";
  }

  $patch_eval = $patch_eval.'$d;';

  my $res = eval($patch_eval);

  debug "\nEval=>> $patch_eval >>=".__d($res).".\n";

  $@
    and
      die 'applyPatch() : '.$patch_eval.$@;

  return $res
}

=back

=head2 Conversion Methods

=over 4

=cut


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub patternDom2Text($) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my @path=@{shift()};
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

=item I<patternDom2Text>(<pattern>)

convert the pattern DOM (array of element used by search(), path()) to text scalar string.


   <pattern>   is an array list of splited element of the pattern

Return equivalent text

EX:
    patternDom2Text( ['?@'] );

             Return '?@'

    patternDom2Text( ['%', 'r'] );

             Return '%r'

    patternDom2Text( ['@',3,'%','r'] );

             Return '@3%r'

    patternDom2Text( ['@',2,'=','3'] );

             Return '@2=3'

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  # patternDom2Text is a singlé join without key defined

  (defined $CFG->{o_key}) or   return join('',@path);

  (%{$CFG->{o_key}}) or join('',@path);


  # matching Keys

  my $sz_path = scalar(@path);

  # debug "\n###".join('.',@{$path}).' '.join('|',keys %{$CFG->{o_key}});    <>;

  my %keys=%{$CFG->{o_key}};

# TODO : key priority sould be managed by a small getPrioritizedKey() function (warning)

  my @sorted_keys = 
#    sort {      ( $keys{$a}->{priority} > $keys{$b}->{priority} ) }
    keys %keys;

  my $k;

  my $i = 0;
  while ($i<scalar(@path)) {

    foreach $k (@sorted_keys)
      {
	my $match = $keys{$k}{regexp};

	#warn "\n=$k on ".join('',@path[0..$i]);

	my $min_index = $matchPath->($match, @path[0..$i]);

	if (defined $min_index) {
	  # debug 
	  #warn " -> key($k -> ".join(' ',@{$match}).")  = $min_index\n";

	  # replace the (matched key expression) by ('/' , <key name>)

	  splice @path, $min_index, scalar(@$match), '/',$k;

	  $i = $i + 2 - scalar(@$match);

	  #warn "-> path  -> ".join('.',@path)." \$i=$i\n";
      }
    }
    $i++;
  }
  return join('',@path);

};



##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub domPatch2TEXT(@) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

=over 4

=item I<domPatch2TEXT>(<patch 1>, <patch 2> [,<patch N>])

convert a list of perl usable patches into a readable text format.
Also convert to key patterns which are matching the regexp key definnition
Mainly used to convert the compare result (format dom)

ARGS:
   a list of <patch in dom format>

Return a list of patches in TEXT mode

EX:


   domPatch2TEXT($patch1)

        returns 'change(@0$%magic_key,@0$%magic_key)="toto"/=>"tata"'


   # one key defined
   o_key({ key_1 => {regexp=>['%','magic_key'], eval=>'{magic_key}' }	} );

   # same but with the related matched key in path

   domPatch2TEXT($patch1)

        returns 'change(@0$/key_1,@0$/key_1)="toto"/=>"tata"'


=cut

  my @res;
  my $patch;
  foreach $patch (@_) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

    (ref($patch) eq 'HASH') and do {

      (exists $patch->{action})
	or die 'domPatch2TEXT(): bad internal dom structure '.__d($patch);


      my $action = $patch->{action};
      my $v1 = $patch->{val_orig};
      my $v2 = $patch->{val_dest};

      my $txt = $action
	.'('
	  .patternDom2Text($patch->{path_orig})
	    .','
	      .patternDom2Text($patch->{path_dest})
		.')=';

      if (($action eq 'remove') or ($action eq 'change')) {
	$v1 = __d($v1);
	$v1 =~ s|/=>|\/\\054\>|g;
	$v1 =~ s/\s=>\s/=>/sg;
	$txt .= $v1;
      }

      ($action eq 'change') and $txt .= '/=>';

      if (($action eq 'add') or ($action eq 'change')) {
	$v2 = __d($v2);
	$v2 =~ s|/=>|\/\\054\>|g;
	$v2 =~ s/\s=>\s/=>/sg;
	$txt .= $v2;
      }

      push @res, $txt;
      next
    } or
    (ref($_) eq 'ARRAY') and do {
      push @res,join '', @{$_};
      next
    };
  }

  # 
  (wantarray()) and return @res;
  return join("\n",@res);
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub domPatch2IHM(@) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

=item I<domPatch2IHM>(<patch 1>, <patch 2> [,<patch N>])

convert a list of patches in DOM format (internal Data;;Deep format)
into a IHM format.
Mainly used to convert the compare result (format dom)

ARGS:
   a list of <patch in dom format>

Return a list of patches in IHM mode
   IHM format is not convertible

EX:
   C<domPatch2IHM>($patch1)
   returns
       '"toto" changed in "tata" from @0$%a
                       into @0$%a
=cut


  my ($msg,$patch);

  foreach $patch (@_) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
    $_ = $patch->{action};

    /^add$/ and ($msg .= __d($patch->{val_orig}).' added')
      or
	/^remove$/ and ($msg .= __d($patch->{val_orig}).' removed')
	  or 
	    /^move$/ and ($msg .= 'Moved ')
	      or 
		/^change$/ and ($msg .= __d($patch->{val_orig})
				.' changed in '
				.__d($patch->{val_dest}));
    my $l = length($msg);
    my $MAX_COLS=40;
    if ($l>$MAX_COLS) {
      $msg .= "\n   from ".join('',@{$patch->{path_orig}});
      $msg .= "\n   into ".join('',@{$patch->{path_dest}});
    }
    else {
      $l-=($msg=~ s/\n//g);
      $msg .= ' from '.join('',@{$patch->{path_orig}});
      $msg .= "\n".(' 'x $l).' into '.join('',@{$patch->{path_dest}});
    }
    $msg .= "\n";
  }
  return $msg;
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub patternText2Dom($) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my $pathTxt = shift();

  (ref($pathTxt)) and die 'patternText2Dom() : bad call with a reference instead of scalar containing pattern text ';

=item I<patternText2Dom>(<text pattern>)

convert pattern scalar string to the array of element to be used by search(), path()


   <pattern>   is an array of type description to match
   <max occ.>  optional argument to limit the number of results
                  if undef all results are returned
		  if 1 first one is returned

Return an array  list of splited element of the <pattern> for usage

EX:
    patternText2Dom( '?@' );

             Return ['?@']

    patternText2Dom( '%r' );

             Return ['%', 'r']

    patternText2Dom( '@3%r' );

             Return ['@',3,'%','r']

    patternText2Dom( '@2=3' );

             Return ['@',2,'=','3']

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my @path;

  #debug "patternText2Dom($pathTxt)";;

  my %keys=();

   (ref($CFG->{o_key})) and %keys = %{$CFG->{o_key}};

  my @pathTxt = split('',$pathTxt);

  while (@pathTxt) {

    $_ = shift @pathTxt;

    if (defined($path[-1]) and $path[-1] =~ /^\?/ and m/^[\=\%\$\@\%\*]/) {
      $path[-1].= $_;
    }
    elsif ($_ eq '$') {
      push(@path,'$');
    }
    elsif ($_ eq '?') {
      push(@path,'?');
    }
    elsif ($_ eq '&') {
      push(@path,'&');
    }
    elsif (/([%\@\=\|\*\/])/) {
      push(@path,$1,'');
    }
    else {
      if ($path[-2] eq '/' and exists($keys{$path[-1]})) {
           # cf test "Search Complex key 3..5"
             push(@path,'');
      }
      $path[-1].= $_;
    }
  }

  # post - convertion § array & key convertion

  my $i;
  for $i (0..$#path) {

    if ($path[$i] eq '@') {
      $path[$i+1] = int($path[$i+1]);
    }
    elsif ($path[$i] eq '/') {
      my $keyname = $path[$i+1];
      (exists($keys{$keyname})) or die 'patternText2Dom() ! no key '.$keyname;

      splice @path, $i, 2, @{ $keys{$keyname}{regexp} };

    }
  }

#warn "patternText2Dom(".join('',@pathTxt).')=> '.join(' ',@path)."  .";

  #debug '=>'.join('.',@path);
  return [@path];
};


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub textPatch2DOM(@) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

=item I<textPatch2DOM>(<text patch 1>, <text patch 2> [,<text patch N>])

convert a list of patches formatted in text (readable text format format)
to a perl DOM format (man  perldsc).
Mainly used to convert the compare result (format dom)

ARGS:
   a list of <patch in text format>

Return a list of patches in dom mode

EX:
   C<textPatch2DOM>( 'change(@0$%a,@0$%a)="toto"/=>"tata"',
                        'move(... '
                      )

returns (
   { action=>'change',
     path_orig=>['@0','$','%a'],
     path_dest=>['@0','$','%a'],
     val_orig=>"toto",
     val_dest=>"tata"
   },
   { action=>'move',
     ...
   });

=cut

  my @res;
  while (@_) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
    my $patch=pop;

    defined($patch) or next;

    debug "textPatch2DOM in ".$patch;

    my ($p1,$p2,$v1,$v2);
    $patch =~ s/^(\w+)\(// or die 'Data::Deep::textPatch2DOM / bad patch format :'.$patch.'  !!!';

    my $action = $1; # or die 'action ???';

    ( $patch =~ s/^([^,]*?),//
    ) and $p1 = patternText2Dom($1);

    ( $patch =~ s/^([^\(]*?)\)=//
    ) and $p2 = patternText2Dom($1);

    if ($action ne 'move') {
      my $i = index($patch, '/=>');
      if ($i ==-1 ) {
	($action eq 'add') && ($v2 = $patch) or ($v1 = $patch);
      }
      else {
	$v1 = substr($patch, 0, $i);
	$v2 = substr($patch, $i+3);
      }
    }
    my $a = eval($v1);
    ($@) and die "textPatch2DOM() error in eval($v1) : ".$@;

    my $b = eval($v2);
    ($@) and die "textPatch2DOM() error in eval($v2) : ".$@;

    push @res,$patchDOM->($action, $p1, $p2, $a, $b);
  }

  #
  (wantarray()) and return @res;
   return [@res];
}


=begin end

=head1 AUTHOR


Data::Deep was written by Matthieu Damerose I<E<lt>damo@cpan.orgE<gt>> in 2005.

=cut


   ###########################################################################
1;#############################################################################
__END__ Deep::Manip.pm
###########################################################################


