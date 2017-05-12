package Chemistry::SQL;
$VERSION = '0.01';
# $Id: Chemistry::SQL.pm, v 0.01 2005/05/31 11:03:17 brequesens Exp $

=head1 NAME

SQL - Access Database Functions Module

=head1 SYNOPSIS

	use strict;
	use Chemistry::SQL;
	use Chemistry::Artificial::SQL;
	
	my $db_name = $ARGV[0];
	my $file = $ARGV[1];
	
	my $db1 = Chemistry::SQL::new(db_host=>"127.0.0.1",db_user=>"root",db_port=>"3306",db_pwd=>"",
                                    db_name=>$db_name,db_driver=>"mysql");
	if ($db1->db_exist) 
	{	$db1->connect_db;
		$db1->del_tables;
		$db1->create_tables_mysql;
		$db1->inscomp_from_file("$file");
	}
	else
	{
		$db1->create_db;
		$db1->connect_db;
		$db1->create_tables_mysql;
		$db1->inscomp_from_file("$file");
	}
	# Reaction Insertion
	
	my $qart = Chemistry::Artificial::SQL::new($db1);
	my $qr =$qart->q_reaccion('C=CC=C.C=C>>C1=CCCCC1','smiles');
	$db1->reactionsert($qr,"","0");

=head1 DESCRIPTION

This package provides the necessary functions to interact with the database.
The methods implemented in this module are oriented to give users control of 
the database without knowing how to use SQL queries.

=cut

=head2 SQL Attributes

There are some attributes in the Chemistry::SQL object: 

	* host: IP Address where the database is located.
	* user: User given to connect_db the database.
	* port: Mysql Port (Default 3306).
	* pwd: User's password to access to the database
	* db_name: Database name that will be used during the application.
	* driver: Driver used while trying to connect_db to database 

=cut

use Chemistry::File::SMILES;
use DBI;
use strict;

=head1 METHODS

The methods of SQL Object are:

=over 4

=item SQL->new(name => ...)

Creates a new SQL object with the specified attributes. Example: 

    my $db1 = Chemistry::SQL::new(db_host=>"127.0.0.1",db_user=>"root",db_port=>"3306",db_pwd=>"",
    db_name=>$db_name,db_driver=>"mysql");

=cut

sub new 
{
   my $class=shift;
   my %args = @_;
    my $self = bless {
	db_host => "127.0.0.1",
	db_user => "root",
	db_port => "3306",
	db_pwd => "",
	db_name => undef,
	db_driver => "mysql",
	dbh => undef ,
	sth => undef,
	sql => undef ,
  },ref ($class) || $class;
 #  $self->$_($args{$_}) for (keys %args);
foreach my $attribute (keys %args) {
    $self->{$attribute}= $args{$attribute};    #$self->$attribute($args{$attribute});
  }
  $self->{dbh}= DBI->connect( "DBI:".$self->{db_driver}.":", $self->{db_user}, $self->{db_pwd});
  return $self;
}

=back

=head2 Database functions

The functions used to acces to the database are:

=cut

=over 4

=item $db->db_exist()

This function decides if the I<self::{db_name}> exists in the database server. 
The function returns 1 when the database name exists, else return 0.

=cut

sub db_exist
{	my $self=shift;
	my $sql = "show databases";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute;
	while (my $row = $sth->fetchrow)
	{	if ($row eq  $self->{db_name}) {return 1;}
	}
	return 0;
}

=item $db->create_db()

Creates a database with I<$self->{db_name}> name. It firts tests if the database
exists; returning 1 when database is been created successfully, else return 0

=cut

sub create_db
{	my $self=shift;
	if (!($self->db_exist))
	{$self->{dbh}->do("create database $self->{db_name}");
	 return 1;}
	 else{return 0;}
}

=item $db->connect_db()

connect_dbs to the database with I<$self->{db_name}> name.

=cut


sub connect_db
{	my $self=shift;
	$self->{dbh}= DBI->connect( "DBI:".$self->{db_driver}.":".$self->{db_name},
	$self->{db_user}, $self->{db_pwd});
}

=item $db->delete_db()

Delete Database with I<$self->{db_name}> name.

=cut


sub delete_db
{	my $self=shift;
	$self->{dbh}->do("drop database $self->{db_name}");
}

=item $db->create_tables_mysql()

Creates all tables necessary to work with the other modules (see
I<Chemistry::Artificial::SQL> and I<Chemistry::Graphics>).

	$db->create_tables_mysql;

I<* Example of a connect_dbion and creation of a database structure:>

	import Chemistry::SQL;
	use strict;
	my $db = Chemistry::SQL::new("127.0.0.1","root","3306","","MOL",
	"mysql");
	if (!($db1->db_exist)) 
	{	$db1->connect_db;
		$db1->del_tables;
		$db1->create_tables_mysql;
	}

Before execution of the function:

	+----------+
	| Database |
	+----------+
	| mysql    |
	| test     |
	+----------+

After execution of the function:

	+----------+
	| Database |
	+----------+
	| MOL      |
	| mysql    |
	| test     |
	+----------+

I<* Example of the components table estructure:>

	+-------------+--------------+------+-----+---------+----------------+
	| Field       | Type         | Null | Key | Default | Extra          |
	+-------------+--------------+------+-----+---------+----------------+
	| formula     | varchar(250) |      | MUL |         |                |
	| id          | int(11)      |      | PRI | NULL    | auto_increment |
	| smilesform  | blob         |      |     |         |                |
	| description | blob         |      |     |         |                |
	+-------------+--------------+------+-----+---------+----------------+

=cut

sub create_tables_mysql
{	my $self=shift;
	$self->{sql}="CREATE TABLE `listafter` (
	`id` int(11) NOT NULL auto_increment,
	`smilesform` blob NOT NULL,
	PRIMARY KEY(`id`)
	)  ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	$self->{sql}="CREATE TABLE `listbefore` (
	`id` int(11) NOT NULL auto_increment,
	`smilesform` blob NOT NULL,
	PRIMARY KEY(`id`)
	)  ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	# Creating components Table
	$self->{sql}="CREATE TABLE `components` (
	`formula` varchar(250) NOT NULL default '',
	`id` int(11) NOT NULL auto_increment,
	`smilesform` blob NOT NULL,
	`description` blob NOT NULL,
	PRIMARY KEY  (`id`),
	KEY `formula` (`formula`)
	)  ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	# Creating Reactions Table	
	$self->{sql}="CREATE TABLE `reactions` (
 	`formula` varchar(255) NOT NULL default '',
	`smilesbefore` blob NOT NULL,
	`smilesafter` blob NOT NULL,
	`atommap_forward` blob NOT NULL,
	`atommap_reverse` blob NOT NULL,
	`id` int(11) NOT NULL auto_increment,
	`direction` tinyint(1) NOT NULL default '0',
	`description` blob NOT NULL,
	PRIMARY KEY  (`id`),
	KEY `formula` (`formula`)
	) ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
	$self->{sth}->execute ;

	# Creating Results Table	
	$self->{sql}="CREATE TABLE `results` (
	`id` int(11) NOT NULL auto_increment,
	`q_name` varchar(255) NOT NULL default '',
	`formula` varchar(255) NOT NULL default '',
	`smilesbefore` blob NOT NULL,
	`smilesafter` blob NOT NULL,
	`atommap` blob NOT NULL,
	`idreact` int(11) NOT NULL default '0',
	`direction` tinyint(1) NOT NULL default '0',
	`is_root` tinyint(1) NOT NULL default '0',
	`level` int(11) NOT NULL default '0',
	PRIMARY KEY  (`id`),
	KEY `busquedakey` (`formula`,`idreact`),
	KEY `qnamekey` (`q_name`),
	KEY `levelkey` (`level`)
	)  ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
	$self->{sth}->execute;	

	# Creating Solution Graph	
	$self->{sql}="CREATE TABLE `sgraph` (
	`id` int(11) NOT NULL auto_increment,
	`q_name` varchar(255) NOT NULL default '',
	`formula` varchar(255) NOT NULL default '',
	`smilesbefore` blob NOT NULL,
	`smilesafter` blob NOT NULL,
	`atommap` blob NOT NULL,
	`idreact` int(11) NOT NULL default '0',
	`direction` tinyint(1) NOT NULL default '0',
	`is_root` tinyint(1) NOT NULL default '0',
	`reaction_smiles` blob NOT NULL default '',
	`painted` tinyint(1) NOT NULL default '0',
	PRIMARY KEY  (`id`),
	KEY `busqueda` (`formula`,`idreact`),
	KEY `q_name` (`q_name`)
	)  ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
	$self->{sth}->execute;	
	
	# Creating  quimics	
	$self->{sql}="CREATE TABLE `quimics` (
	`q_name` varchar(250) NOT NULL default '',
	`descripcio` blob NOT NULL,
	PRIMARY KEY  (`q_name`)
	)  ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
	$self->{sth}->execute;	

	
	
	return 1;
}

=item $db->clean_tables(table_name)

Cleans the selected table.

=cut

sub clean_tables	
{	my $self=shift;
	my ($table) = @_;
	$self->{sql}="delete  from $table;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
	$self->{sth}->execute;
	return 1;
}

=item $db->del_tables()

Erases all tables in the database I<$self->{db_name}>. This function is used 
to clean a complete database.

* I<Example of cleaning a database:>

	use Chemistry::SQL;
	my $db1 = Chemistry::SQL::new("127.0.0.1","root","3306","",
	"mole2","mysql");
	if ($db1->db_exist) 
	{	$db1->connect_db;
		$db1->del_tables;
		$db1->create_tables_mysql;
	}

=cut

sub del_tables 
{	my $self=shift;
	$self->{sql}="drop table components;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	$self->{sql}="drop table listafter;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	$self->{sql}="drop table listbefore;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	$self->{sql}="drop table sgraph;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	$self->{sql}="drop table reactions;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	$self->{sql}="drop table results;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;
	
	# Deleting Quimics Tables 
	$self->{sql}="select q_name from quimics";
	$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
	$self->{sth}->execute;	
	while (my $row = $self->{sth}->fetchrow)
	{	my $sql = "drop table $row";
		my $sth = $self->{dbh}->prepare($sql);
		$sth->execute;
		$sth->finish;
	}
	
	$self->{sql}="drop table quimics;";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute ;

	return 1;
}

=back

=head2 Components functions

These functions are used to work with the components and the database; and
they are:

=cut


=over 4

=item $mol->smiles_string(component)

Returns SMILES string of the component.

It is often used to get the SMILES string of the components in the function.

	$self->smiles_string($component);

=cut

sub smiles_string	
{	my $self=shift;
	my ($component)=@_;
	return $component->print(format => 'smiles', unique => 1);
	#return $component->sprintf("%S");
        #return $component->sprintf("%s");
}

=item $db->string_comp(id)

Returns SMILES format string of the component.

=cut

sub string_comp
{	my $self = shift;
	my ($id) = @_;
	$self->{sql} = "Select smilesform from components where id='$id'"; 
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	my $str;
	if ($self->{results} = $self->{sth}->fetchrow)
	{ 	$str = $self->{results};
	}
	return $str;
}

=item $db->component_exist(component)

Checks if the component already exist in the database.

This function is used in the insertion of components before to inserting them, 
because it checks if them already exist.

=cut

sub component_exist 	
{	my $self = shift;
	my ($component) = @_;
	my $result = 0;
	my $formula = $component->sprintf("%f");
	my $smilesform = $self->smiles_string($component);
	$self->{sql} = "SELECT smilesform,id FROM components where formula =
			'$formula'";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while ((my @row = $self->{sth}->fetchrow_array)&&($result==0))
	{	if ($row[0] eq $smilesform) {$result=$row[1];}
	}
	$self->{sth}->finish;
	return $result;
}

=item $db->insert_component(component, description)

Inserts component in the components table.

=cut

sub insert_component 	
{	my $self=shift;
	my ($component,$description) = @_;
	my $formula = $component->sprintf("%f");
	my $smilesform = $self->smiles_string($component);
	if (($self->component_exist($component))==0)
	{	
		$self->{sql} = "INSERT INTO components
		(formula,smilesform,description)
		VALUES('$formula','$smilesform','$description')";
		$self->{sth}= $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
	}
	$self->{sth}->finish;
}

=item $db->inscomp_from_file(file)

Imports components from I<smilesformat> file.

This function imports a I<data.smi> file into the components table. It is often
used in the initialitzation of the database.

=cut

sub inscomp_from_file
{	my $self=shift;
	my($file)=@_;
	my @mols = Chemistry::Mol->read($file, format => 'smiles');
	my $smilesform="";
	my $formula = "";
	my $repeat=0;
	my $ending_value = scalar(@mols) ;
	for(my $counter=0 ; $counter < $ending_value ; $counter++)
	{	$self->insert_component($mols[$counter],"");
	}		
	return 1;
}

=item $db->recover_comp(formula, smilesform)

This function returns the components.

Options of recover_comp function:

	-------------------------------
	|formula      |   smilesform  | Result
	-------------------------------
	|  blank      |   ------      | All components returned 
	-------------------------------
	|  value set  |   blank       | All components with formula parameter
	-------------------------------
	| value set   |   value set   | smilesform component is returned 
	-------------------------------

* I<Examples:>

Returning all components in database:

	$db1->recover_comp("","") 

=cut

sub recover_comp
{	my $self=shift;
	my ($formula,$smilesform)=@_;
	my @list=();
	if ($formula eq "")
	{$self->{sql} = "SELECT smilesform FROM components";}
	else
	{$self->{sql} = "SELECT smilesform FROM components where formula=
			'$formula'";}
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if ($smilesform eq "")
	{while (my $row = $self->{sth}->fetchrow)
	 {	push @list, Chemistry::Mol->parse($row, format => 'smiles');
	 }
	}
	else
	{while (my $row = $self->{sth}->fetchrow)
	 {	if ($row eq $smilesform)
	 	{push @list, Chemistry::Mol->parse($row, format => 'smiles');}
	 }
	}
	$self->{sth}->finish;
	return \@list;
}

=back

=head2 Reactions functions

Functions to work with the reactions and the database, and they are:

=cut

=over 4

=item $db->reaction_exist(smilesbefore, smilesafter, formula)

It tests if the reaction described is in the database selecting the formula
reaction, and test if smilesbefore and smilesafter are the same that the
parameters describe.

=cut


sub reaction_exist 	
{	my $self=shift;
	my ($smilesbefore,$smilesafter,$formula) = @_;
	my $result = 0;
	$self->{sql} = "SELECT smilesbefore,smilesafter,id FROM reactions 
	where formula = '$formula' ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while (my @row = $self->{sth}->fetchrow_array)
	{	if (($row[0] eq $smilesbefore) && ($row[1] eq $smilesafter)) 
		{$result=$row[2];}
	}
	return $result;
}

=item $db->react_id(reaction)

Gets the reaction id of the reaction.

	my $reactionID = $db1->react_id($r);

=cut


sub react_id	
{	my $self=shift;
	my ($reaction) = @_;
	my $id;
	my $substrate = $reaction->substrate;
	my $product = $reaction->product;
	my $formula = $substrate->sprintf("%f");
	my $smilesbefore = $substrate->sprintf("%s");
	my $smilesafter = $product->sprintf("%s");
	$self->{sql} = "SELECT id,smilesbefore,smilesafter FROM reactions 
			where formula = '$formula'";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while (my @row = $self->{sth}->fetchrow_array)
	{	if (($row[1] eq $smilesbefore) && ($row[2] eq $smilesafter))
		 {$id = $row[0];}
	}
	$self->{sth}->finish;
	return $id;
}

=item $db->react_dir(react_id)

Returns the reaction direction. This function is used during the cha generation
to know reaction's direction and how to apply the reaction.

	my $reactionID = $db1->react_id($r);
	my $reactiondir= $db->reacDIR($reactionID);

=cut

sub react_dir		
{	my $self=shift;
	my ($react_id)=@_;
	my $direct;
	$self->{sql} = "SELECT direction FROM reactions where id=$react_id";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	$direct= $self->{sth}->fetchrow;
	$self->{sth}->finish;
        return $direct;
}

=item $db->rection_insert(reaction, description, direction)

Inserts a reaction in the database. 
 
Before inserting the reaction it is tested if the reaction already exists.

The direction is a number between 0 and 2 

0=> Forward Reaction.

1=> Reverse Reaction.

2=> Bidirectional Reaction.

* Example of forward reaction insertion :

	$db1->rection_insert($r,"Description of my Reaction",0)

=cut

sub reaction_insert 	
{	my $self=shift;
	my ($reaction,$description,$direction) = @_;
	my $substrate = $reaction->substrate;
	my $formula = $substrate->sprintf("%f");
	my $product = $reaction->product;
	my $smilesbefore = $substrate->sprintf("%s");
	my $smilesafter = $product->sprintf("%s");
	my $atommapf;
	my $atommapr;
	my @map = $substrate->atom_map;
	$atommapf=split(//,@map);
	my @map = $product->atom_map;
	$atommapr=split(//,@map);
	if (($self->reaction_exist($smilesbefore,$smilesafter,$formula))==0)
	{	 $self->{sql} = "INSERT INTO reactions
		(formula,smilesbefore,smilesafter,atommap_forward,
		atommap_reverse,description,direction)
		VALUES('$formula','$smilesbefore','$smilesafter','$atommapf'
		,'$atommapr','$description','$direction')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;	
	}
}

=item $db->string_react(id)

Returns the string of the reaction with a SMILES format.

=cut

sub string_react
{	my $self = shift;
	my ($id) = @_;
	$self->{sql} = "Select smilesbefore, smilesafter from reactions
	 		where id='$id'"; 
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	my $str;
	if (my @row = $self->{sth}->fetchrow_array)
	{ 	$str = $row[0].">>".$row[1];
	}
	return $str;
}

=item $db->recover_reaction()

Recovers all the reactions from the reactions table.
This function returns an reference array.

=cut

sub recover_reaction
{	my $self=shift;
	my @list=();
	$self->{sql} = "SELECT distinct smilesbefore,smilesafter,direction FROM
			reactions group by(id)";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while (my @row = $self->{sth}->fetchrow_array)
	{	push @list, $row[0].">>".$row[1];
	}
	$self->{sth}->finish;
	return \@list;
}

=back

=head2 CHA functions

This functions are used to work with artificial chemistry and database.
They are:

=cut

=over 4

=item $db->ch_exist(qname)

Querys the database if the I<cha> name exist in the database. This function 
is used in the module to test if qname exist before inserting a new cha.

	if (!($self->ch_exist($qname)))
	{ 
		INSERT
	}

=cut

sub ch_exist 	
{	my $self = shift;
	my ($qname) = @_;
	my $resultado = 0;
	$self->{sql} = "SELECT q_name FROM quimics where q_name = '$qname' ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if ($self->{sth}->fetchrow_array)
	{return 1;}
	else 
	{return 0;}
}

=item $db->new_ch(qname, description)

Inserts I<cha> name and description in the database. When a I<cha> is created, 
a new table is created in the database.

	$db1->new_ch("cha_name","Description of the cha");

=cut

sub new_ch
{	my $self = shift;
	my ($qname, $description) = @_;
	if (!($self->ch_exist($qname)))
	{ 
		$self->{sql} = "INSERT INTO quimics
		(q_name,descripcio)
		VALUES('$qname','$description')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		$self->{sql}="CREATE TABLE `$qname` (
		`Type` enum('C','R') NOT NULL default 'C',
		`id` int(11) NOT NULL default '0',
		PRIMARY KEY  (`Type`,`id`)
		)  ";
		$self->{sth} = $self->{dbh}->prepare($self->{sql}) ;
		$self->{sth}->execute;	
		return 1;
	}
	else
	{	return 0;
	}
}

=item $db->id_artificial(type, qname)

When a i<cha> is created, a new table with <cha> name is created too. 
In this table  are stored components and reactions that will be used in the 
CHA generation.

This function returns the I<id>'s of the selected type.

Type must be 'R' for reactions and 'C' for components.

qname is the name of I<cha>.

I<* Example to get all the component id from the TESTCHA.>

	my $idcomp = $db1->id_artificial("C","TESTCHA");
	foreach $component(@$idcomp)
	{ print $db->string_comp($component);}

=cut

sub id_artificial 
{	my $self=shift;
	my ($type,$qname) = @_;
	$self->{sql} = "Select id from $qname where Type='$type'"; 
	$self->{sth}= $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	my @ids;
	while ($self->{results} = $self->{sth}->fetchrow)
	{	push @ids, $self->{results};
	}
	$self->{sth}->finish;
	return \@ids;
}

=item $db->exist_artificial(type,id,q_name)

When a new component or reaction is inserted in a I<cha> table, it is checked 
before being inserted.

=cut

sub exist_artificial	
{	my $self=shift;
	my ($type,$id,$qname) = @_;
	$self->{sql} = "Select Type, id from $qname where Type='$type' 
	and id = '$id'"; 
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;	
	if ($self->{sth}->fetchrow)
	{	$self->{sth}->finish;
		return 1; 
	}
	else
	{	$self->{sth}->finish;
		return 0;
	}
}

=item $db->insert_art_react(index, qname)

Inserts reactions in the I<cha> table.

=cut

sub insert_art_react	
{	my $self=shift;
	my ($index,$qname) = @_;
	if (!($self->exist_artificial("R",$index,$qname)))
	{ 
		$self->{sql} = "INSERT INTO $qname
		(Type,id)
		VALUES('R','$index')";
		$self->{sth}= $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;	
		$self->{sth}->finish;
	}
}

=item $db->insert_art_comp(index,qname)

Inserts components in the I<cha> table.

=cut

sub insert_art_comp	
{	my $self=shift;
	my ($index,$qname) = @_;
	if (!($self->exist_artificial("C",$index,$qname)))
	{ 
		$self->{sql} = "INSERT INTO $qname
		(Type,id)
		VALUES('C','$index')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;	
		$self->{sth}->finish;
	}
}

=item $db->recover_cha_names()

Returns all the I<cha>s in the database.

This function is used during the clenaning of the database, because it lists
a detail of all the tables that will be dropped.

=cut

sub recover_cha_names
{	my $self=shift;
	my @list=();
	$self->{sql} = "SELECT distinct q_name FROM quimics";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while (my $row = $self->{sth}->fetchrow)
	{	push @list, $row;
	}
	$self->{sth}->finish;
	return \@list;
}

=item $db->list_after_in(entries)

Next level component is inserted in the I<lista_after_in>. It is used because
some I<cha> generations can be bigger than the memory, and then the next 
level is stored in a table and recovered to be processed when is necesary.

=cut

sub list_after_in 	
{	my $self=shift;
	#@_ is a smilesstring
	my ($entries)=@_;
	my $entry;
	foreach $entry(@$entries)
	{
		$self->{sql} = "INSERT INTO listafter
		(smilesform)
		VALUES('$entry')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		$self->{sth}->finish;
	}
}

=item $db->list_after_out(size)

Recovers the next level components in a I<cha> generation.

The variable size defines how many elements can be in the memory.
When it recovers the elements of the next level, it returns the number
of elements especified in the size variable.

=cut


sub list_after_out 
{	my $self=shift;
	my ($size) = @_;
	#my $smilesform = $component->print(format => 'smiles');
	my @result=();
	$self->{sql} = "Select MIN(id) from listafter";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if (my $id = $self->{sth}->fetchrow)
	{	$size= $size+$id;
		$self->{sql} = "Select smilesform from listafter where 
		id >= $id AND <= $size";
		$self->{sth}= $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		if ($self->{results}= $self->{sth}->fetchrow)
	{		
		my $sql="delete  from listafter where id = $id";
		my $sth = $self->{dbh}->prepare($sql);
		$sth->execute;
		$sth->finish;
		$id = $id+1;
		push @result,$self->{results};
	}
}
	$self->{sth}->finish;
	return \@result;
}

=item $db->list_before_in(entries)

This function inserts components in I<list_before> table.

=cut


sub list_before_in
{	my $self=shift;
	my ($entries)=@_;
	my $entry;
	foreach $entry(@$entries)
	{	$self->{sql} = "INSERT INTO listbefore
		(smilesform)
		VALUES('$entry')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		$self->{sth}->finish;
	}
}

=item $db->list_before_out(size)

Recovers the actual level components in a I<cha> generation.

The size variable defines how much elements can be in memory,
when it recovers, the elements of the level, the function 
returns the number of elements defined in size variable.

=cut


sub list_before_out
{	my $self=shift;
	my ($size)=@_;
	my @result;
	$self->{sql}= "Select MIN(id) from listbefore";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if (my $id = $self->{sth}->fetchrow)
	{	$size = $id+$size;
		$self->{sql} = "Select smilesform from listbefore where 
		id >= $id AND id <= $size";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		while ($self->{results}= $self->{sth}->fetchrow)
		{		
			my $sql="delete  from listbefore where id = $id";
			my $sth = $self->{dbh}->prepare($sql);
			$sth->execute;
			$id = $id+1;
			push @result,$self->{results};	
		}
	}
	$self->{sth}->finish;
	return \@result;
}	

=item $db->list_before_empty()

Checks if the I<list_before> is empty, returning 1 if it is empty.

=cut


sub list_before_empty
{	my $self=shift;
	$self->{sql}= "Select MIN(id) from listbefore";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if ($self->{sth}->fetchrow)
	{	$self->{sth}->finish;
		return 0;	
	}
	else
	{	$self->{sth}->finish;
		return 1;
	}
}		

=item $db->lista_to_listb()

Moves all I<after_table> data to I<before_table>  data setting up 
the next level to explore

=cut

sub lista_to_listb
{	my $self = shift;
	my $min=0;my $max=0;
	# Select the MIN ID from Next Level
	$self->{sql}= "Select MIN(id) from listafter";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if (my $id = $self->{sth}->fetchrow)
	{ $min = $id;}
	else
	{return}
	# Select the MAX ID from Next Level
	$self->{sql}= "Select MAX(id) from listafter";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if (my $id = $self->{sth}->fetchrow)
	{ $max = $id;}
	else
	{return}
	# From the Min ID to the MAX ID, we copy all the rows into the 
	#listbefore table levels.
	for (my $item = $min; $item<$max; $item++)
	{	$self->{sql} = "Select smilesform from listafter 
				where id = $item";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		if (my $smilesform = $self->{sth}->fetchrow)
		{	my $sql = "INSERT INTO listbefore
			(smilesform)
			VALUES('$smilesform')";
			my $sth = $self->{dbh}->prepare($sql);
			$sth->execute;
			$sth->finish;
		}
	}
	$self->{sql}= "delete from listafter";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	$self->{sth}->finish;
}

=item $db->result_before_exists(formula, smilesform, qname)

Test for one component in I<cha> if the result already has been calculated.

=cut

sub result_before_exists
{	my $self=shift;
	my ($formula,$smilesform,$qname)=@_;
	my $result = 0;
	$self->{sql} = "SELECT smilesbefore FROM results where formula = 
			'$formula' AND q_name='$qname'";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while (my $rows=$self->{sth}->fetchrow)
	{	if ($rows eq $smilesform)
		{$result=1;}	
	}
	return $result;
}

=back

=head2 Graphic generation functions

These functions are used to work with the I<sgraph> table, and they are:

=cut

=over 4

=item $db->gsg_fsc(startcomp)

Generates solution graph from start components.

This function inserts the data into the solution graph table to plot with
the graphic module a graphic solution.

I<startcomp> is an array reference with all the components to process.

=cut

sub gsg_fsc
{	my $self=shift;
	my ($startcomp)=@_;
	my $smilesform;
	my $component;
	my @child;my $rcomponent;
	foreach $component(@$startcomp)
	{	my $formula=$component->sprintf("%f");
		$smilesform=$self->smiles_string($component);
		my $sql = "SELECT smilesbefore,smilesafter,idreact,direction,
			atommap FROM results where formula = '$formula'";
		my $sth = $self->{dbh}->prepare($sql);
		$sth->execute;
		# Create the root Graph Nodes
		my $counter=0;
		while (my @row = $sth->fetchrow_array)
		{	# creem el component
			 if ($row[0] eq $smilesform)
			 {	
			 	push @child,$row[1];
				$self->sgraph_insert($formula,$row[0],$row[1],
					$row[2],$row[3],$row[4],"","1");
			 }
		}
		# Get all the others
		# Firts Get the Child Components, 
		# when detect a new child it is added in the list
		foreach $rcomponent(@child)
		{	my $component = Chemistry::Mol->parse($rcomponent, 
					format => 'smiles');
			my $formula=$component->sprintf("%f");
			my $smilestring=$self->smiles_string($component);
			my $sql  = "select smilesbefore,smilesafter,idreact,
				   direction,atommap from results where 
				   formula = '$formula' ";
			my $sth = $self->{dbh}->prepare($sql);
			$sth->execute;
			while (my @row = $sth->fetchrow_array)
			{	if ($row[0] eq $smilestring)
				{	if (!($self->sgraph_exist($formula,
						$row[0],$row[1],$row[2])))	
					{	push @child,$row[1];
						$self->sgraph_insert($formula,
						$row[0],$row[1],$row[2],
						$row[3],$row[4],"","0");
					}
				}
			}
		}
	}
}

=item $db->gsg_fec(endcomp)

Generate solution Graph from end components

This function inserts the data into the solution graph table to plot with the 
graphic module a graphic solution.

I<endcomp> is an array reference with all the components to process.

=cut

sub gsg_fec
{	my $self=shift;
	my ($endcomp)=@_;
	my $smilesform;
	my $component;
	my @fathers;my $rcomponent;
	my $invdir;#inverted direction
	foreach $component(@$endcomp)
	{	my $formula=$component->sprintf("%f");
		$smilesform=$self->smiles_string($component);
		my $sql = "SELECT smilesbefore,smilesafter,idreact,direction,
			atommap FROM results where formula = '$formula'";
		my $sth = $self->{dbh}->prepare($sql);
		$sth->execute;
		# Create the root Graph Nodes
		my $counter=0;
		while (my @row = $sth->fetchrow_array)
		{
			 if ($row[1] eq $smilesform)
			 {	
			        if ($row[3]==1) 
			 	{$invdir=0;}
				else
				{ if ($row[3]==0)
				  {$invdir=1;}
				}
			 	push @fathers,$row[0];
				$self->sgraph_insert($formula,$row[1],$row[0],
				$row[2],$invdir,$row[4],"","1");
			 }
		}
		
		# Get all the others
		foreach $rcomponent(@fathers)
		{	my $component = Chemistry::Mol->parse($rcomponent, 
					format => 'smiles');
			my $formula=$component->sprintf("%f");
			my $smilestring=$self->smiles_string($component);
			my $sql  = "select smilesbefore,smilesafter,idreact,
					direction,atommap from results where 
					formula = '$formula' ";
			my $sth = $self->{dbh}->prepare($sql);
			$sth->execute;
			while (my @row = $sth->fetchrow_array)
			{	if ($row[1] eq $smilestring)
				{	 if ($row[3]==1) 
			 		 {$invdir=0;}
					 else
					 { if ($row[3]==0)
				  	   {$invdir=1;}
					 }
					if (!($self->sgraph_exist($formula,
						$row[1],$row[0],$row[2])))
					{	push @fathers,$row[0];
						$self->sgraph_insert($formula,
						$row[1],$row[0],$row[2],
						$invdir,$row[4],"","0");
					}
				}
			}
		}
	}
}

=item $db->gsg_levels(qname, initlevel, endlevel)

Generate solution graph levels

Insert the necessary data into graph solution table.

I<qname>: Cha to draw

I<initlevel>: First level 

I<endlevel>: Last level to draw

=cut


sub gsg_levels
{	my $self=shift;
	my ($qname,$initlevel,$endlevel)=@_;
	my $sql = "SELECT level,formula,smilesbefore,smilesafter,idreact,
		direction,atommap FROM results where q_name='$qname' 
		AND level >= '$initlevel' AND level<='$endlevel'";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute;
	while (my @row = $sth->fetchrow_array)
	{	if($row[0]==$initlevel)
		{$self->sgraph_insert($row[1],$row[2],$row[3],$row[4],$row[5],
					$row[6],$qname,"1");	
		}
		else
		{$self->sgraph_insert($row[1],$row[2],$row[3],$row[4],$row[5],
					$row[6],$qname,"0");}
	}
}

=item $db->gsg_complete(qname)

Generate solution graph complete.

Generates a complete I<cha> solution graph, inserting data into solution graph 
table.

=cut


sub gsg_complete
{	my $self=shift;
	my ($qname)=@_;
	my $sql = "SELECT formula,smilesbefore,smilesafter,idreact,
	direction,atommap,is_root FROM results where q_name='$qname'";
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute;
	while (my @row = $sth->fetchrow_array)
	{	$self->sgraph_insert($row[0],$row[1],$row[2],$row[3],$row[4],
					$row[5],$qname,$row[6]);	}
	$self->{sth}->finish;
}

=item $db->sgraph_exist(formula, smilesbefore, smilesafter, idreact)

Checks if a result is in the solution graph table

=cut


sub sgraph_exist
{	my $self=shift;
	my ($formula,$smilesbefore,$smilesafter,$idreact) = @_;
	my $result=0;
	$self->{sql} = "SELECT smilesbefore, smilesafter FROM sgraph where 
			formula = '$formula'  AND idreact = '$idreact' ";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	#Finding for a equal smilesbefore and smilesafter strings
	while (my @row = $self->{sth}->fetchrow_array)
	{	if (($row[0] eq $smilesbefore) && ($row[1] eq $smilesafter)) 
		{$result=1;}
	}
	# 0 if not exist
	$self->{sth}->finish;
	return $result;
}

=item $db->sgraph_insert(formula,smilesbefore,smilesafter,idreact,direction,
atommap,q_name,is_root)

Solution graph insertion.

=cut


sub sgraph_insert
{	my $self=shift;
	my ($formula,$smilesbefore,$smilesafter,$idreact,$direction,$atommap,
	$qname,$is_root) = @_;
	if (!($self->sgraph_exist($formula,$smilesbefore,$smilesafter,$idreact)))
	{	# Get the Reaction Properties and Insert into the 
		# Result Graph Table
		my $sql = "Select smilesbefore,smilesafter from reactions  
				where id = $idreact";
		my $sth =  $self->{dbh}->prepare($sql);
		$sth->execute;
		my $smilesreaction;
		if (my @row=$sth->fetchrow_array)
		{	$smilesreaction = $row[0].">>".$row[1];
		}
		$sth->finish;
		$self->{sql} = "INSERT INTO sgraph
		(formula,smilesbefore,smilesafter,idreact,direction,atommap,
		q_name,is_root,reaction_smiles)
		VALUES('$formula','$smilesbefore','$smilesafter','$idreact',
		'$direction','$atommap','$qname','$is_root','$smilesreaction')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		$self->{sth}->finish;
		return 1;
	}
	else 
	{return 0;}
}

=back

=head2 Result functions

These functions are used to work with the results generated, and they are:

=cut

=over 4

=item $db->resultinsert(formula, smilesbefore, smilesafter, idreact, direction,
atommap, qname, is_root, level)

Inserts a result in the database.

=cut

sub result_insert
{	my $self=shift;
	my ($formula,$smilesbefore,$smilesafter,$idreact,$direction,$atommap,
	$qname,$is_root,$level) = @_;
	if ($smilesbefore eq $smilesafter) {return 0;}
	
	if (!($self->results_exist($formula,$smilesbefore,$smilesafter,
	$idreact,$qname)))
	{	$self->{sql} = "INSERT INTO results
		(formula,smilesbefore,smilesafter,idreact,direction,atommap,
		q_name,is_root,level)
		VALUES('$formula','$smilesbefore','$smilesafter','$idreact',
		'$direction','$atommap','$qname','$is_root','$level')";
		$self->{sth} = $self->{dbh}->prepare($self->{sql});
		$self->{sth}->execute;
		$self->{sth}->finish;
		return 1;
	}
	else 
	{return 0;}
}

=item $db->resultexist(formula, smilesbefore, smilesafter, idreact, qname)

Checks if the result already exists in the database.

=cut

sub results_exist
{	my $self=shift;
	my ($formula,$smilesbefore,$smilesafter,$idreact,$qname) = @_;
	my $resultado=0;
	$self->{sql} = "SELECT smilesbefore, smilesafter FROM results where
			formula = '$formula'  AND idreact = '$idreact' 
			AND q_name='$qname'";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	while (my @row = $self->{sth}->fetchrow_array)
	{	if ((@row[0] eq $smilesbefore) && (@row[1] eq $smilesafter)) 
		{$resultado=1;}
	}
	$self->{sth}->finish;
	return $resultado;
}

=item $db->graphic_information(id,component)

Returns information about the components to plot the graph.

=cut


sub graphic_information	
{	my $self = shift;
	# @_ is the quimics name
	my ($id,$component) = @_;
	my @info;
	my $smilesform = $self->smiles_string($component);
	my $formula = $component->sprintf("%f");
	$self->{sql} = "select smilesbefore,direction,atommap,reaction_smiles 
			from sgraph where id='$id'";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	if (my @row = $self->{sth}->fetchrow_array)
	{		push @info, $smilesform;
			push @info, $formula;
			push @info, $row[0];
			push @info, $row[1];
			push @info, $row[2];
			push @info, $row[3];	
	}
	return \@info;
}

=item $db->rec_root()

Recovers the root components.

=cut

sub rec_root 
{	my $self = shift;
	$self->{sql} = "select smilesbefore,id from sgraph where is_root=1 
			group by (smilesbefore)";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	my @result;
	while (my @row = $self->{sth}->fetchrow_array)
	{	
		 push @result, Chemistry::Mol->parse($row[0], 
		 		format => 'smiles');
		 push @result,$row[1];
	}
	$self->{sth}->finish;
	return \@result;
}

=item $db->rec_child(component)

Returns all the child components from one component.

=cut

sub rec_child 
{	my $self = shift;
	my ($component)=@_;
	my $formula = $component->sprintf("%f");
	my $smilesform = $self->smiles_string($component);
	$self->{sql} = "select id,smilesbefore,smilesafter from sgraph 
			where formula = '$formula' and painted=0";
	$self->{sth} = $self->{dbh}->prepare($self->{sql});
	$self->{sth}->execute;
	my @result;my @ids;
	while (my @row = $self->{sth}->fetchrow_array)
	{	# creem el component
		 if ($row[1] eq $smilesform)
		 {push @result, Chemistry::Mol->parse($row[2], 
		 		format => 'smiles');
		  push @ids,$row[0];
		  push @result,$row[0]; }
	}
	$self->{sth}->finish;
	
	#Matk painted Nodes
	my $child;
	foreach $child(@ids)
	{$self->{sql} = "UPDATE sgraph SET painted=1 WHERE id=$child";
	 $self->{sth} = $self->{dbh}->prepare($self->{sql});
	 $self->{sth}->execute;
	}
	$self->{sth}->finish;
	
	return \@result;
}
1;

=back

=head1 VERSION

0.01

=head1 SEE ALSO

L<Chemistry::Artificial::SQL>,L<Chemistry::Artificial::Graphics>

The PerlMol website L<http://www.perlmol.org/>

=head1 AUTHOR

Bernat Requesens E<lt>brequesens@gmail.comE<gt>.

=head1 COPYRIGHT

This program is free software; so it can be redistributed and/or modified under
the same terms as Perl itself.

=cut
