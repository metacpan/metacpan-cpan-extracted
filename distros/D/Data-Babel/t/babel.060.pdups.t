########################################
# 060.pdups - partial duplicate removal
########################################
use t::lib;
use t::utilBabel;
use Carp;
use Getopt::Long;
use Graph::Directed;
use List::MoreUtils qw(uniq any);
use List::Util qw(min max);
use Math::BaseCalc;
use Text::Abbrev;
use Class::AutoDB;
use Data::Babel;
# use Benchmark qw(:hireswallclock);
use Test::More;
use strict;

my @OPTIONS=qw(bundle=s graph_type=s arity=i link_type=s num_maptables=i num_groups=i
	       keep_pdups
	       pdups_group_cutoffs=s pdups_prefixmatcher_cutoffs=s pdups_prefixmatcher_classes=s);
# defaults make a binary tree of depth 3 with reasonable sized db
#   and test default PrefixMatcher (Trie)
# set --pdups_prefixmatcher_classes='all' to test all choices
my %DEFAULTS=(bundle=>'install',
	      graph_type=>'tree',arity=>2,link_type=>'star',num_maptables=>7,num_groups=>1);

my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
my $dbh=$autodb->dbh;
my $OPTIONS=get_options();
my $babel=make_babel();
load_database($OPTIONS->num_groups);

my @idtype_names=map {$_->name} @{$babel->idtypes};
my %idtypes=group {my($group)=/^(.+?)_/; $group} @idtype_names;
my @leafs=sort @{$idtypes{leaf}};
my @links=sort @{$idtypes{link}};
my $input=$leafs[$#leafs];	# 'extreme' leaf - bottom right in tree

my($group_cutoffs,$matcher_cutoffs,$matcher_classes)=
  @$OPTIONS{qw(pdups_group_cutoffs pdups_prefixmatcher_cutoffs pdups_prefixmatcher_classes)};
for my $group_cutoff (@$group_cutoffs) {
  for my $matcher_cutoff (@$matcher_cutoffs) {
    for my $matcher_class (@$matcher_classes) {
      doit_all($group_cutoff,$matcher_cutoff,$matcher_class);
      doit_all($group_cutoff,$matcher_cutoff,$matcher_class,'keep_pdups') if $OPTIONS->keep_pdups;
    }}}
done_testing();

sub doit_all {
  my($group_cutoff,$matcher_cutoff,$matcher_class,$keep_pdups)=@_;
  $babel->pdups_group_cutoff($group_cutoff) if defined $group_cutoff;
  $babel->pdups_prefixmatcher_cutoff($matcher_cutoff) if defined $matcher_cutoff;
  $babel->pdups_prefixmatcher_class($matcher_class) if defined $matcher_class;
  my $label_all=label($group_cutoff,$matcher_cutoff,$matcher_class,$keep_pdups);

  # case 1: short paths
  my $label="case 1. short paths $label_all";
  my $ok=1;
  my @outputs;
  for my $leaf (@leafs) {
    push(@outputs,$leaf);
    $ok&&=doit($input,\@outputs,$keep_pdups,$label) or last;
  }
  report_pass($ok,$label);

  # case 2: long paths
  my $label="case 2. long paths $label_all";
  my $ok=1;
  my @outputs=@leafs;
  for my $link (@links) {
    push(@outputs,$link);
    $ok&&=doit($input,\@outputs,$keep_pdups,$label) or last;
  }
  report_pass($ok,$label);

  # case 3: mixed paths
  my $label="case 3. mixed paths $label_all";
  my $ok=1;
  for my $link (@links) {
    my @outputs=@leafs;
    push(@outputs,$link);
    $ok&&=doit($input,\@outputs,$keep_pdups,$label) or last;
  }
  report_pass($ok,$label);
}

# args are idtype names
sub doit {
  my($input_name,$output_names,$keep_pdups,$label)=@_;
  my @args=(input_idtype=>$input_name,output_idtypes=>$output_names);
  push(@args,keep_pdups=>$keep_pdups) if defined $keep_pdups;
  # my $t0=new Benchmark;
  my $actual=$babel->translate(@args);
  # diag 'translate: ',timestr(timediff(new Benchmark, $t0));
  # my $t0=new Benchmark;
  my $correct=select_ur(babel=>$babel,@args);
  # diag 'select_ur: ',timestr(timediff(new Benchmark, $t0));
  cmp_table_quietly($actual,$correct,"$label input=$input_name, outputs=@$output_names");
}
sub label {
  my($group_cutoff,$matcher_cutoff,$matcher_class,$keep_pdups)=@_;
  my $label;
  if (any {defined $_} ($group_cutoff,$matcher_cutoff,$matcher_class)) {
    $group_cutoff=!defined $group_cutoff? 'default': 
      ($group_cutoff==0? 'always': ($group_cutoff>=1e6? 'never': $group_cutoff));
    $matcher_cutoff=!defined $matcher_cutoff? 'default': 
      ($matcher_cutoff==0? 'always': ($matcher_cutoff>=1e6? 'never': $matcher_cutoff));
    $matcher_class=!defined $matcher_class? 'default': $matcher_class;
    $label=
      "group_cutoff=$group_cutoff, matcher_cutoff=$matcher_cutoff, matcher_class=$matcher_class";
  }
  if (defined $keep_pdups) {
    $label.=', ' if $label;
    $label.="keep_pdups=".($keep_pdups? 1: 0);
  }
  $label;
} 

sub get_options {
  # initialize to defaults then overwrite with ones explicitly set
  my %OPTIONS=%DEFAULTS;
  GetOptions(\%OPTIONS,@OPTIONS);
  # expand abbreviations
  my %bundle=abbrev qw(install full);
  my %graph_type=abbrev qw(star chain tree);
  my %link_type=abbrev qw(starlike chainlike);
  for my $option (qw(bundle graph_type link_type)) {
    next unless defined $OPTIONS{$option};
    my %abbrev=eval "\%$option";
    $OPTIONS{$option}=$abbrev{$OPTIONS{$option}} or confess "illegal value for option $option";
  }
  my $full=$OPTIONS{bundle} eq 'full';
  # deal with list options
  for my $option 
    (qw(pdups_group_cutoffs pdups_prefixmatcher_cutoffs pdups_prefixmatcher_classes)) {
    next unless defined $OPTIONS{$option};
    my $string=$OPTIONS{$option};
    my @list=split(/\W+/,$string);
    $OPTIONS{$option}=\@list;
  }
  $OPTIONS{keep_pdups}=1 if $full && !defined $OPTIONS{keep_pdups};

  # for install, cutoffs default to default
  # for full, cutoffs default to default, always, never

  my $cutoffs=$OPTIONS{pdups_group_cutoffs};
  $cutoffs=$full? [0,1e6]: [] unless defined $cutoffs;
  $OPTIONS{pdups_group_cutoffs}=[undef,@$cutoffs];

  my $cutoffs=$OPTIONS{pdups_prefixmatcher_cutoffs};
  $cutoffs=$full? [0,1e6]: [] unless defined $cutoffs;
  $OPTIONS{pdups_prefixmatcher_cutoffs}=[undef,@$cutoffs];

  my $classes=$OPTIONS{pdups_prefixmatcher_classes};
  # NG 13-09-18: set --pdups_prefixmatcher_classes='all' to test all choices
  my $all=[undef,qw(Trie BinarySearchTree BinarySearchList PrefixHash)];
  if (!defined $classes) {
    $classes=$full? $all: [undef];
  } else {
    $classes=$all if grep /^all$/i,@$classes;
  }
  $OPTIONS{pdups_prefixmatcher_classes}=$classes;

  new Hash::AutoHash %OPTIONS;
}

sub make_babel {
  my($num_maptables,$arity,$link_type)=@$OPTIONS{qw(num_maptables arity link_type)};
  # make graph to guide schema construction. each node will generate a maptable
  my $graph=new Graph::Directed;
  my $root=0;			# root is node 0
  $graph->add_vertex($root);
  my $more=$num_maptables-1;	# number of nodes remaining
  my @roots=$root;		# queue of nodes to root subtrees

  while ($more) {
    my $root=shift @roots;
    for (1..min($arity,$more)) {
      my $kid=$num_maptables-$more--;
      $graph->add_edge($root,$kid);
      push(@roots,$kid);
    }}
  my @nodes=$graph->vertices;

  # make component objects and Babel
  # 'link' IdTypes connect MapTables.
  # 'leaf' IdTypes are private to each MapTable

  my $sql_type='VARCHAR(255)';
  my(@idtypes,@masters,@maptables);

  # make leaf IdTypes
  for my $i (@nodes) {
    my $idtype_name='leaf_'.sprintf('%03d',$i);
    push(@idtypes,new Data::Babel::IdType(name=>$idtype_name,sql_type=>$sql_type));
  }
  # make link IdTypes
  for my $i (@nodes) {
    my @kids=$graph->successors($i);
    next unless @kids;
    my $idtype_name='link_'.sprintf('%03d',$i);
    if ($link_type eq 'starlike') { 
      # 1 link per level connecting parent to all kids
      push(@idtypes,new Data::Babel::IdType(name=>$idtype_name,sql_type=>$sql_type));
    } else {			  
      # each link connects parent to one child
      for my $k (@kids) {
	push(@idtypes,new Data::Babel::IdType(name=>$idtype_name.'_'.sprintf('%03d',$k),
					    sql_type=>$sql_type));
      }}}
  # make MapTables
  for my $i (@nodes) {	 
    my $maptable_num=sprintf('%03d',$i);
    my $maptable_name="maptable_$maptable_num";
    my ($parent)=$graph->predecessors($i);
    my @kids=$graph->successors($i);
    my @idtypes="leaf_$maptable_num";
    if ($link_type eq 'starlike') { 
      # 1 link per level connecting parent to all kids
      push(@idtypes,'link_'.sprintf('%03d',$parent)) if defined $parent;
      push(@idtypes,"link_$maptable_num") if @kids;
    } else {
      # each link connects parent to one child
      push(@idtypes,join('_','link',sprintf('%03d',$parent),$maptable_num)) if defined $parent;
      push(@idtypes,map {join('_','link',$maptable_num,sprintf('%03d',$_))} @kids);
    }
    @idtypes=sort @idtypes;
    push(@maptables,new Data::Babel::MapTable(name=>$maptable_name,idtypes=>\@idtypes));
  }
  # make Babel
  my $babel=new Data::Babel
    (name=>'test',autodb=>$autodb,idtypes=>\@idtypes,masters=>\@masters,maptables=>\@maptables);
  isa_ok($babel,'Data::Babel','sanity test - $babel');
  my @errstrs=$babel->check_schema;
  ok(!@errstrs,'sanity test - check_schema');
  diag(join("\n",@errstrs)) if @errstrs;

  $babel;
}

sub load_database {
  my($num_groups)=@_;
  map {load_maptable($_,$num_groups)} @{$babel->maptables};
  $babel->load_implicit_masters;
  load_ur($babel,'ur');
  my $ok=check_database_sanity($babel,'sanity test - database',$OPTIONS->num_maptables);
  report_pass($ok,'sanity test - database looks okay');
}
# arg is maptable number
sub load_maptable {
  my($maptable,$num_groups)=@_;
  $num_groups=1 unless defined $num_groups;
  my $maptable_name=$maptable->name;
  my($num)=$maptable_name=~/_(\d+)$/;
  my $leaf_type="leaf_$num";
  my @link_types=grep /^link/,map {$_->name} @{$maptable->idtypes};
  my @data;
  for (my $i=1; $i<=$num_groups; $i++) {
    my $num=sprintf('%04i',$i);
    my $leaf_vals=[undef,"$leaf_type/aaa_$num"];
    my @link_vals=map {[undef,"$_/aaa_$num","$_/multi","$_/nomatch_$maptable_name"]} @link_types;
    my @rows=cross_product($leaf_vals,@link_vals);
    @rows=uniq_rows(\@rows);
    @rows=grep {any {defined $_} @$_} @rows;
    push(@data,@rows);
  }
  t::utilBabel::load_maptable($babel,$maptable,@data);
}

