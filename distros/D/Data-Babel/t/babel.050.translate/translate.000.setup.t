########################################
# setup database
# many kinds of tree structures
#   arity      - fanout, eg, 2 for binary
#   link_type  - starlike   idtypes connect all nodes at each level
#                chainlike  each idtype connects parent to one child
#   db_type    - staggered or binary data pattern
#   skip_pairs - don't do all pairs
########################################
use t::lib;
use t::utilBabel;
use translate;
use Test::More;
use List::Util qw(min);
use Graph::Directed;
use Hash::AutoHash qw(autohash_get);
use Class::AutoDB;
use Data::Babel;
use strict;

init('setup');
my($num_maptables,$arity,$db_type,$link_type)=
  autohash_get($OPTIONS,qw(num_maptables arity db_type link_type));
my $last_maptable=$num_maptables-1;

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
my $extra_idtypes=$OPTIONS->extra_idtypes;
if ($extra_idtypes) {
  my($rate,$num)=@$extra_idtypes;
  # make leaf IdTypes
  for my $i (0..$last_maptable) {	 
    next if $i%$rate;
    my $idtype_basename='leaf_'.sprintf('%03d',$i);
    my @idtype_names=
      $num==1? $idtype_basename: map {join('_',$idtype_basename,sprintf('%03d',$_))} 0..$num-1;
    push(@idtypes,map {new Data::Babel::IdType(name=>$_,sql_type=>$sql_type)} @idtype_names);
  }
}
for my $i (@nodes) {	  # make link IdTypes
  my @kids=$graph->successors($i);
  next unless @kids;
  my $idtype_name='link_'.sprintf('%03d',$i);
  if ($link_type eq 'starlike') { # 1 link per level connecting parent to all kids
    push(@idtypes,new Data::Babel::IdType(name=>$idtype_name,sql_type=>$sql_type));
  } else {			  # each link connects parent to one child
    for my $k (@kids) {
      push(@idtypes,new Data::Babel::IdType(name=>$idtype_name.'_'.sprintf('%03d',$k),
					    sql_type=>$sql_type));
    }}}
# make explicit masters if required
if (my $explicit=$OPTIONS->explicit) {
  my $history=$OPTIONS->history;
  for my $idtype (@idtypes) {
    my $name=$idtype->name;
    my($i)=$name=~/_(\d+)$/;
    next if $i%$explicit;
    push(@masters,
	 new Data::Babel::Master(name=>"${name}_master",history=>$history && $i%$history==0));
  }}

for my $i (@nodes) {	  # make MapTables
  my $maptable_num=sprintf('%03d',$i);
  my $maptable_name="maptable_$maptable_num";
  my ($parent)=$graph->predecessors($i);
  my @kids=$graph->successors($i);
  my @idtypes;
  if ($link_type eq 'starlike') { # 1 link per level connecting parent to all kids
    push(@idtypes,'link_'.sprintf('%03d',$parent)) if defined $parent;
    push(@idtypes,"link_$maptable_num") if @kids;
  } else {			  # each link connects parent to one child
    push(@idtypes,join('_','link',sprintf('%03d',$parent),$maptable_num)) if defined $parent;
    push(@idtypes,map {join('_','link',$maptable_num,sprintf('%03d',$_))} @kids);
  }
  if ($extra_idtypes) {
    my($rate,$num)=@$extra_idtypes;
    if ($i%$rate==0) {
      my $idtype_basename='leaf_'.sprintf('%03d',$i);
      push(@idtypes,
	   $num==1? 
	   $idtype_basename: map {join('_',$idtype_basename,sprintf('%03d',$_))} 0..$num-1);
    }}
  @idtypes=sort @idtypes;
  push(@maptables,new Data::Babel::MapTable(name=>$maptable_name,idtypes=>\@idtypes));
}

$babel=new Data::Babel
  (name=>'test',idtypes=>\@idtypes,masters=>\@masters,maptables=>\@maptables);
isa_ok($babel,'Data::Babel','sanity test - $babel');
my @errstrs=$babel->check_schema;
ok(!@errstrs,'sanity test - check_schema');
diag(join("\n",@errstrs)) if @errstrs;

# load the database. maptables first
for my $maptable (@{$babel->maptables}) {
  load_maptable($maptable);
}
# implicit masters next
$babel->load_implicit_masters;
# explicit masters next
for my $master (@{$babel->masters}) {
  next if $master->implicit;
  my $master_name=$master->name;
  # my $data=($master->explicit)? master_data($master): undef;
  load_master($master);
}
load_ur($babel,'ur');
my $ok=check_database_sanity($babel,'sanity test - database',$num_maptables);
report_pass($ok,'sanity test - database looks okay');

# create MapTable distance matrix for future tests that consider output span
my $paths=$graph->undirected_copy->all_pairs_shortest_paths;
my %distance;
for (my $i=0;$i<$num_maptables-1;$i++) {
  my $maptable_i='maptable_'.sprintf('%03d',$i);
  for (my $j=$i+1; $j<$num_maptables; $j++) {
    my $maptable_j='maptable_'.sprintf('%03d',$j);
    $distance{"$maptable_i $maptable_j"}=$paths->path_length($i,$j);
  }}
# save matrix in AutoDB
put t::stash autodb=>$autodb,id=>'translate_distances',data=>\%distance;

done_testing();

