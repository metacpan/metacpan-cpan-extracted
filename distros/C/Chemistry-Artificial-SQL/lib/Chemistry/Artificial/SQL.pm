package Chemistry::Artificial::SQL;
$VERSION = '0.01';
# $Id: Chemistry::Artifical::SQL.pm, v 0.01 2005/05/31 12:14:17 brequesens Exp $

=head1 NAME

ArtificialSQL - Artificial chemistry with database support module

=head1 SYNOPSIS

    use strict;
    use Chemistry::SQL;
    use Chemistry::Artificial::SQL;
    
    # Execution: perl gcha.pl DBNAME CHANAME SIZE_VALUE LEVELS 
    # NUMBER_OF_COMPONENTS_TO_PROCESS
    
    my $dbname = $ARGV[0];
    my $chaname = $ARGV[1];
    my $size = $ARGV[2];
    my $levels = $ARGV[3];
    my $compnumber = $ARGV[4];
    
    if (scalar(@ARGV)!=5)
    { print "Incorrect parameter number  \n";
      print "perl gcha.pl DBNAME CHANAME SIZE_VALUE LEVELS 
      NUMBER_OF_COMPONENTS_TO_PROCESS \n";
      exit;
    }
    
    my $db1 = Chemistry::SQL->new(db_host=>"127.0.0.1",db_user=>"root",db_port=>"3306",db_pwd=>"",
    db_name=>"$dbname",db_driver=>"mysql");
    $db1->connect_db;
    
    my $cha = Chemistry::Artificial::SQL->new(db_name=>$db1);
    $cha->new_ch ("$chaname","TEST DESCRIPTION");
    
    
    #Inserting Reactions 
    #In this example file we're working with the reaction C=CC=C.C=C>>C1=CCCCC1
    my $string_react = $db1->string_react(1);
    my $qr=$cha->create_reaction($string_react,'smiles');
    $cha->art_insert_react($qr,"$chaname");
    my $string_react = $db1->string_react(2);
    my $qr=$cha->create_reaction($string_react,'smiles');
    $cha->art_insert_react($qr,"$chaname");
    
    # Inserting Components
    
    my $list = $db1->recover_comp("","");
    
    my $component;
    my $formula;
    my $smilesform;
    
    for (my $index=0; $index<$compnumber; $index++)
    {	@$list[$index]->print(format => 'smiles', unique => 1);
        $cha->art_insert_comp(@$list[$index],"$chaname");
    }
    print ("GENERATING $chaname IN $dbname DATABASE\n");
    $cha->ch_artificial_table($levels,"$chaname",$size);

=head1 DESCRIPTION

This package provides the necessary functions to work with the generation of 
artificial chemistry. The methods implemented in this package, are all 
oriented to generate artificial chemistry. There is a lot of interaction 
with the package Chemistry::SQL, but Chemistry::Artficial::SQL doesnt 
implement any Chemistry::SQL function.

=cut

=head2 Chemistry::Artificial::SQL Attributes

There is only one attribute necessary to work with this module.

	* db: This attribute describes the SQL object to use in the process.

=cut

use strict;
use Chemistry::Reaction;
use Chemistry::SQL;

=head1 METHODS

Methods of Chemistry::Artificial::SQL object.

=over 4

=item Chemistry::Artificial::SQL->new(SQL_OBJECT)

Creates a new I<Chemistry::Articial::SQL> object with the especified attributes.

Example:

	my $db1 = Chemistry::SQL->new(db_host=>"127.0.0.1",db_user=>"root",
        db_port=>"3306",db_pwd=>"",db_name=>"TESTDB",db_driver=>"mysql");
	$db1->connect_db;
	my $cha = Chemistry::Artificial::SQL->new(db_name => $db1);
	$cha->new_ch ("CHATEST","TEST DESCRIPTION");

=cut

sub new { 	
			
my $class = shift;
my %args = @_;
my $self = 
   bless 
   {    
     db_name=>"",
   }, ref $class || $class;
    foreach my $attribute (keys %args) {
    $self->{$attribute}= $args{$attribute};
  }
  return $self;
}

=back

=head2 Components functions

These are functions writed to make easier working with cha components 

=cut

=over 4

=item $cha->smiles_string($component)

Returns the SMILES format string of the component.

It is often used to get the SMILES string of the components in the function.

	$self->smiles_string($component);

=cut

sub smiles_string{my $self=shift;
		  my ($component)=@_;
		 return $component->print(format => 'smiles', unique => 1);
		 #return $component->sprintf("%S");
		 #return $component->sprintf("%s");
}

=item $cha->art_insert_comp(component, qname)

When a new artificial chemistry is generated, all the components that will 
take part in this generation, are stored in the artifical chemistry table.

To insert a component in this table is necessary that the component exists in
the components table. When a reaction is inserted in the artificial chemistry
component, then the I<id> of the component is stored in the table, but not 
all the information.

=cut

sub art_insert_comp	
{my $self = shift;
 my ($component,$qname) = @_;
 my $index = $self->{db_name}->component_exist($component);
 if (($index)>0)
 { $self->{db_name}->insert_art_comp($index,$qname);
   return 1;
 }
 else
 {print "This component doesn't exist. \n";
  return 0;
 }
}

=back

=head2 Reaction functions

These are functions writed to make easier working with reactions in the cha

=cut

=over 4

=item $cha->create_reaction(reaction_string, type)

This function implements the creation of a new reaction from SMILES string.

There are some considerations about this function

- The reaction is created in a unique SMILES form.

- The function uses the I<Chemistry::Reaction> module to create the final 
  reaction.

Example:

	my $qr=$cha->create_reaction($string_react,'smiles');

string_react is a SMILESBEFORE >> SMILESAFTER format string.

=cut

sub create_reaction{ my $self = shift;
		my ($string,$type)=@_;
		my $s;
		my $p;
		my %m=();
		my $react;
		my @parts=();
		if ($type eq 'smiles')
		{@parts = split(/>>/,$string);
		 $s =  Chemistry::Pattern->parse($parts[0], format => 'smiles');
		 $p =  Chemistry::Pattern->parse($parts[1], format => 'smiles');
		 %m;
		 for (my $i = 1; $i le $s->atoms; $i++) {
				$m{$s->atoms($i)} = $p->atoms($i);
			}
		$react = Chemistry::Reaction->new($s,$p,\%m);
		}
		else
		{  return 0;
		}
		return $react;
	}

=item $cha->art_insert_react(reaction, qname)

When a new artificial chemistry is generated, all the components that will 
take part in this generation, are stored in the artifical chemistry table.

To insert a reaction in this table, it is necessary that the reaction exists in
the reaction table. When a reaction is inserted in the artificial chemistry
reaction, then the id of the reaction is stored in the table, but not all the 
information.

=cut

sub art_insert_react	
{my $self=shift;
 my ($react,$qname)=@_;
 my $s = $react->substrate;
 my $p = $react->product;
 my $index=$self->{db_name}->reaction_exist(($s->sprintf("%s"),
		$p->sprintf("%s"), $s->sprintf("%f")));
 if (($index)>0)
 { $self->{db_name}->insert_art_react($index,$qname);
  return 1;
 }
 else
 { print "This reaction doesn't exist in database \n";
  return 0;
 }
}

=back

=head2 Artificial Chemistry especific functions

These functions give control to create and generate artificial chemistry

=cut

=over 4

=item $cha->new_ch(qname, description)

When a new ArtificialChemistry is created, the Chemistry::SQL module creates a new table 
with the qname name. This function is used to create a new artificial table.

Example:

	$cha->new_ch ("CHATEST","TEST DESCRIPTION");

=cut

sub new_ch	{	my $self = shift;
			my ($qname,$description)=@_;
			$self->{db_name}->new_ch($qname,$description);
}

=item cha->ch_next_level(Ref_array, qname, memsize, level)

Generates all the possible components in the next level. The components are in
the database and Ref_array has all the reactions that we apply on one component.

How does it work:

- For each component all the reactions in the Ref_array are applied. If the 
  interaction generates new components, then they are stored in the 
  result table in the database.

- This function also is called from this module, is not recomended to call 
  this function from external program. There is another function avaible that
  uses this one to generate the artifical chemistry.

- This function has direction support in the reaction application

=cut

sub ch_next_level
{	
my $self = shift;
my ($ref_arrayid,$qname,$size,$level) = @_;
my $list_before;
my @list_after;
my $reaction_id;
my $subst;
my $product;
my $presenttestmol;
my $smilesform;
my $reactID;
my $direction;
my $new_mol;
my @m;
my @map;
my $is_root;
my $counter=0;
my $presentuniqsmilesform;
my $newuniqsmilesform;
my $atom_string;
my $r;
# Recover last level.
$list_before=$self->{db_name}->list_before_out($size);
print "Working on Level $level\n";
 while (scalar(@$list_before)!=0)
 {	# for each component we must try to get all the possibles
	# results in K reactions
 foreach $smilesform(@$list_before)	
 { $presenttestmol = Chemistry::Mol->parse($smilesform,format => 'smiles');
#print "Working on Level $level with Component : $smilesform\n";
# Test if smilesbefore exist in the result table
   if (!($self->{db_name}->result_before_exists($presenttestmol->sprintf("%f"),
       $self->smiles_string($presenttestmol),$qname)))
   {foreach $reaction_id(@$ref_arrayid)
    {my $r= $self->create_reaction($self->{db_name}->string_react($reaction_id),'smiles');   
     $direction = $self->{db_name}->react_dir($reaction_id);
     my $subst = $r->substrate;
     if (($direction==0)||($direction==2))
     {
      while ($subst->match($presenttestmol))  
      {my $new_mol = $presenttestmol->clone; 
       my @map = $subst->atom_map;
       my @m = map { $new_mol->by_id($_->id) } @map;
       $r->forward($new_mol, @m);
       $newuniqsmilesform = $self->smiles_string($new_mol);
       $presentuniqsmilesform = $self->smiles_string($presenttestmol);
       push @list_after,$newuniqsmilesform;
       if (scalar(@list_after)>=$size)
       {$self->{db_name}->list_after_in(\@list_after);
        @list_after=();
       }
       if ($level==0)
       { $is_root=1;}
       else
       {$is_root=0;}
       @map =$subst->atom_map;
       $atom_string=split(//,@map);
       $counter=$counter+$self->{db_name}->result_insert($presenttestmol->
       sprintf("%f"),$presentuniqsmilesform,$newuniqsmilesform,$reaction_id,
       $direction,$atom_string,$qname,$is_root,$level);
      }
     }
    if (($direction==1)||($direction==2))
    {  # Reverse Direction
     my $product = $r->product;
     while ($product->match($presenttestmol))  
     {my $new_mol = $presenttestmol->clone; 
      my @map = $product->atom_map;
      my @m = map { $new_mol->by_id($_->id) } @map;
      $r->reverse($new_mol, @m);	
      $newuniqsmilesform = $self->smiles_string($new_mol);
      $presentuniqsmilesform = $self->smiles_string($presenttestmol);
      push @list_after,$newuniqsmilesform;
      if (scalar(@list_after)>=$size)
      {$self->{db_name}->list_after_in(\@list_after);
       @list_after=();
      }
      if ($level==0)
      { $is_root=1;}
      else
      {$is_root=0;}
      @map =$product->atom_map;
      $atom_string=split(//,@map);
      $counter=$counter+$self->{db_name}->result_insert($presenttestmol->
      sprintf("%f"),$presentuniqsmilesform,$newuniqsmilesform,$reaction_id,
      $direction,$atom_string,$qname,$is_root,$level);
     } 
    }
   }
  }
 }
 $list_before=$self->{db_name}->list_before_out($size);
 }
 # Copy the las Results
 print "New $counter Results in level $level \n";
 $self->{db_name}->list_after_in(\@list_after);
 @list_after=();
}

=item $artificial->ch_artificial_table(levels, cha_name)

This function gets all the components and reactions into the artificial table
and simulates an artificial chemistry. 
if I<levels> is greater than 0, then the artificial simulation only 
generates the number of levels that are especified with this variable.
If I<levels> is minor than 0, the artificial simulation generates 
all levels of the artificial.

This method takes components of the level 0 (the components that exist in the
artificial table) and make one level with all reactions in artificial table,
and then take the next level and repeat the process I<levels> level or while 
no results are discovered.

=cut

sub ch_artificial_table  
{	
my $self = shift;
my ($levels,$qname,$sizevalue) = @_;
# Clean Tables:
$self->{db_name}->clean_tables("listbefore");
$self->{db_name}->clean_tables("listafter");
my $level=0;
my $idreact = $self->{db_name}->id_artificial("R",$qname);
my @react_string=();
my $idcomp = $self->{db_name}->id_artificial("C",$qname);
my $component;
my $idreaction;
my @components;
my $size=$sizevalue;
foreach $component(@$idcomp)
{	push @components, $self->{db_name}->string_comp($component);
	if (scalar(@components)>=$size)
	{	$self->{db_name}->list_before_in(\@components);
		@components=();
	}
}
# Copy the last components
$self->{db_name}->list_before_in(\@components);
# Level Generation
if ($levels >=0 )
{	print "$levels Levels Generation \n";
	for ($level=0; $level<$levels;$level++)
	{	$self->ch_next_level($idreact,$qname,$size,$level);
		$self->{db_name}->lista_to_listb;
	}
}
else
{	print "No limit Levels Generation \n";
	# NO Level Generation
	while (!($self->{db_name}->list_before_empty))
	{	$self->ch_next_level($idreact,$qname,$size,$level);
		$level++;
		$self->{db_name}->lista_to_listb;
	}
}
}

1;

=back

=head1 VERSION

0.01

=head1 SEE ALSO

L<Chemistry::SQL>,L<Chemistry::Artificial::Graphics>

The PerlMol website L<http://www.perlmol.org/>

=head1 AUTHOR

Bernat Requesens E<lt>brequesens@gmail.comE<gt>.

=head1 COPYRIGHT

This program is free software; so it can be redistributed and/or modified 
under the same terms as Perl itself.

=cut

