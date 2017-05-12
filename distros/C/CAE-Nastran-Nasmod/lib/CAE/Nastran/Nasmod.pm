package CAE::Nastran::Nasmod;

use strict;
use warnings;
use CAE::Nastran::Nasmod::Entity;
use vars qw($VERSION $ABSTRACT $DATE);

$VERSION           = '0.26';
$DATE              = 'Fri Apr 25 13:17:31 2014';
$ABSTRACT          = 'basic access to nastran models';

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self={};

    $self =
    {
		"bulk" => [],
		"tmp" => [],
    };

    bless ($self, $class);
    return $self;
}

#---------------------
# prints the whole model to STDOUT or a file
# print()
# return: 0 | 1
#---------------------
sub print
{
    my $self = shift;

	my $outfile = undef;
	if (@_)
	{
		$outfile = shift(@_);
		if (stat $outfile)
		{
			print("error: file does already exist. " . $outfile . "\n");
			return 0;
		}
	}

	# if an outfile has been defined, redirect STDOUT to this file
	if($outfile)
	{
		open (SAVE, ">&STDOUT") or die "can't save STDOUT $!\n";
		open (STDOUT, '>', $outfile) or die "can't redirect STDOUT to " . $outfile . ": $!";
	}

#	print "WOOOOOPP\n";
#	print "anzahl der entities: " . scalar(@{$self->{'bulk'}}) . "\n";

	# print each entity
	foreach my $entity (@{$self->{'bulk'}})
	{
		$entity->print();
	}
	
	# remove redirection of STDOUT
	if($outfile)
	{
		close STDOUT;
		open (STDOUT, ">&SAVE") or die "can't restore STDOUT $!\n";
		close SAVE;
	}
	
	return 1;
}
#---------------------

#---------------------
# imports data from a nastran file
# optional filtering possible
#---------------------
sub importBulk
{
	my $self = shift;
	my $path = shift;
	my $refh_options;

	if(@_)
	{
		$refh_options = shift;
	}

	if (!open (MODEL, "<$path")) {die "cannot read $path"}

	my @model = <MODEL>;
	chomp @model;
	close MODEL;

	$self->{'tmp'} = \@model;

	if ($refh_options)
    {
    	$self->parse($refh_options);
    }
    else
    {
    	$self->parse();
    }
}

#---------------------
# parse bulkdata and store entity-objects in show
#---------------------
sub parse
{
    my $self = shift;

    my $maxoccur;
    my $occur = 0;

    my $cards;
    my $refa_filter;

    if (@_)
    {
	    my $refh_options = shift;
	    my %OPTIONS = %$refh_options;
	    if (defined $OPTIONS{'cards'})
	    {
	    	$cards = join("|", @{$OPTIONS{'cards'}});
	    }
	    if (defined $OPTIONS{'filter'})
	    {
	    	$refa_filter = $OPTIONS{'filter'};
	    }
	    if (defined $OPTIONS{'maxoccur'})
	    {
	    	$maxoccur = $OPTIONS{'maxoccur'};
	    }
    }

   	my $entity;
	my @comment;

	my $just_skipped = 0;

	my $folgezeile = 0;

    # each line of bulk
	foreach my $line (@{$self->{tmp}})
    {
    	# if its a comment
    	if ($line =~ m/^\$/)
    	{
    		push @comment, $line;
#	    	print "-----\n";
# 	    	print "COMMENT: $line\n";
    	}
    	
    	# if its an entity
    	else
    	{

			# sofort ueberpruefen ob die karte ueberhaupt eingelesen werden soll
			if (($cards) && ($line =~ m/^\w+/) && ($line !~ m/^$cards/))
			{
				$just_skipped = 1;
				undef @comment;
				next;
			}
			
			# zeile zerteilen
    		my @line = &split8($line);
			
			# handelt es sich um die erste Zeile einer Karte?
    		if ($line =~ m/^\w+/)
			{
				$just_skipped = 0;
				$folgezeile = 0;
				
    			# first store previous entity-object if available and if matches the filter
    			if ($entity)
    			{
   					# greift der filter? dann ablegen | ist $maxoccur erreicht? dann abbrechen
   					if($entity->match($refa_filter))
   					{
#   						print "FILTER GREIFT fuer Zeile: $line\n";
   						$self->addEntity($entity);
   						$occur++;
	   					if( ($maxoccur) && ($maxoccur <= $occur) )
	   					{
	   						return;
	   					}
   					}
    			}
    			
    			# ein neues entity anlegen
    			$entity = CAE::Nastran::Nasmod::Entity->new();
    			$entity->setComment(@comment);
    			undef(@comment);
    			
    			# die zerhackte zeile durchgehen und in einem entity ablegen
    			for(my $x=0, my $col=1; $x<@line; $x++, $col++)
    			{
    				$entity->setCol($col, $line[$x]);
    			}
			}
			
			# wenn kein kommentar und keine schluesselzeile, dann handelt es sich um eine folgezeile.
			# diese soll nur dann beruecksichtigt werden, wenn die schluesselzeile nicht aussortiert wurde
			elsif (!($just_skipped))
			{
				$folgezeile++;
  
    			# die zerhackte zeile durchgehen und in einem entity ablegen
    			for(my $x=0, my $col=(1+($folgezeile * 10)); $x<@line; $x++, $col++)
    			{
    				$entity->setCol($col, $line[$x]);
    			}
			}
    	}
    }

	# zum schluss die letzte entity ablegen
    if ($entity)
    {
    	if ($entity->match($refa_filter))
    	{
    		$self->addEntity($entity);
    	}
    }
    			
}
#---------------------

#---------------------
# split a string in chunks of 8 characters
#---------------------
sub split8
{
	my $string = shift;
	my @strings;
	for (my $x=0; ($x*8) < length($string); $x++)
	{
		my $substring = substr $string, ($x*8), 8;
		$substring =~ s/^\s+//;
		$substring =~ s/\s+$//;
		push @strings, $substring;
	}
	return @strings;
}
#---------------------

#---------------------
# adds an entity to show
# addEntity(@entities)
# return: -
#---------------------
sub addEntity
{
	my $self = shift;
	push @{$self->{bulk}}, @_;
}
#---------------------

#---------------------
# gets the entities that match the filter. if no filter is given, returns all entities
# getEntity(\@filter)
# return: @allEntitiesThatMatch
#---------------------
sub getEntity
{
	my $self = shift;

	# if a filter is given
	if(@_)
	{
		my $refh_filter = shift;
		my $newModel = $self->filter($refh_filter);
		return $newModel->getEntity();
	}
	
	# if no filter is given
	else
	{
		return @{$self->{bulk}};
	}

}
#---------------------

#---------------------
# filter model
# return a model
# filter array:
# $[0]: pattern for matching the comment
# $[1]: pattern for matching the row1 of entity
# $[2]: pattern for matching the row2 of entity
# an entity matches when every pattern of the given filter is found in entity at the given place.
#---------------------
sub filter
{
	my $self = shift;
	my $refa_filter = shift;
	my $refh_param;
	
	if (@_)
	{
		$refh_param = shift;
	}

	# ein neues objekt erzeugen
	my $filtered_model = CAE::Nastran::Nasmod->new();

# alle entities durchgehen
	foreach my $entity (@{$self->{'bulk'}})
	{
		if ($entity->match($refa_filter))
		{
			$filtered_model->addEntity($entity);
			if ($refh_param->{'firstonly'})
			{
				return $filtered_model;
			}
		}
	}
	return $filtered_model;
}
#---------------------

#---------------------
# getrow
sub getCol
{
	my $self = shift;
	my $row = shift;
	my @return;
	foreach my $entity (@{$self->{'bulk'}})
	{
		push @return, $entity->getrow($row);
	}
	return @return;
}
#---------------------

#---------------------
# merges models to this model
# merge(Nasmod, Nasmod, ...)
# return: -
#---------------------
sub merge
{
	my $self = shift;
	foreach my $model (@_)
	{
		push @{$self->{'bulk'}}, @{$model->{'bulk'}};
	}
}
#---------------------

#---------------------
# count_entities
# count()
# return: int
#---------------------
sub count
{
	my $self = shift;

	return scalar(@{$self->{'bulk'}});
}
#---------------------
1;

__END__

=head1 NAME

CAE::Nastran::Nasmod - basic access to nastran models

=head1 SYNOPSIS

    use CAE::Nastran::Nasmod;

    # create object of a nastran model
    my $model = CAE::Nastran::Nasmod->new();

    # import content from a nastran file
    $model->importBulk("file.inc");

    # filter for GRIDs
    my $model2 = $model->filter("", "GRID");

    # print to a file
    $model2->print("file.nas");

=head1 DESCRIPTION

import a nastran model from files, filter content, extract data, overwrite data, write content to file.

=head1 API

=head2 new()

creates and returns a new Nasmod

    # create a new Nasmod
    my $model = CAE::Nastran::Nasmod->new();

=head2 import()

imports a Nastran model from file. it only imports nastran bulk data. no sanity checks will be performed - duplicate ids or the like are possible.

    # define options and filter
    my %OPTIONS = (
        cards => ["GRID", "CTRIA"],         # fastest way to reduce data while importing. only mentioned cardnames will be imported. the values in 'cards' match
                                            # always without a trailing anchor => "CTRIA" matches "CTRIA3" and "CTRIA6"
        filter => ["", "", 10],             # only the content passing this filter will be imported. same dataformat as in filter().
        maxoccur => 5                       # stops the import if this amount of entities has been imported.
    )

    # create object of a nastran model
    my $model = new Nastranmodel();
    
    # adds all bulk data of a file
    $model->import("file.inc");
    
    # adds only the bulk data of the file, that passes the filter
    $model->import("file2.inc", \%OPTIONS);

=head2 filter()

returns a new Nastranmodel with only the entities that pass the whole filter. A filter is an array of regexes. $filter[0] is the regex for the comment, $filter[1] is the regex for column 1 of the nastran cards, $filter[2] is the regex for column 2 ... A nastran card passes a filter if every filter-entry matches the correspondent column or comment. Everything passes an empty filter-entry. The filter-entry for the comment matches without anchors. filter-entries for data columns will always match with anchors (^$). A filter-entry for a column may be an array with alternatives - in this case only one alternative has to match.

    # filter for GRID (NID=1000)
    my @filter = (
        "",                   # pos 0 filters comment:  entities pass which match // in the comment. (comment => no anchors in the regex)
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1. (note the anchors in the regex)
        "1000"                # pos 2 filters column 2: entities pass which match /^1000$/ in column 2. (note the anchors in the regex)
        ""                    # pos 3 filters column 3: entities pass which match // in column 3. (empty => no anchors in the regex)
    )

    my $filteredModel = $model->filter(\@filter);

    # filter for GRIDs (999 < NID < 2000)
    my @filter2 = (
        "lulu",               # pos 0 filters comment:  only entities pass which match /lulu/ somewhere in the comment (comment = no anchors in the regex)
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1.
        "1\d\d\d"             # pos 2 filters column 2: entities pass which match /^1\d\d\d$/ in column 2.
    )

    my $filteredModel2 = $model->filter(\@filter2);

    # filter for GRIDs ( (999 < NID < 2000) and (49999 < NID < 60000) and (69999 < NID < 80000))
    my @filter3 = (
        "",                   # pos 0 filters comment:  all entities match empty filter
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1.
        [
            "1\d\d\d",        # pos 2 filters column 2: entities pass which match /^1\d\d\d$/ in column 2.
            "5\d\d\d\d",      # pos 2 filters column 2: or which match /^5\d\d\d\d$/ in column 2.
            "7\d\d\d\d"       # pos 2 filters column 2: or which match /^7\d\d\d\d$/ in column 2.
        ]
    )

    my $filteredModel3 = $model->filter(\@filter3);

=head2 getEntity()

returns all entities or only entities that pass a filter.

    my @allEntities = $model->getEntitiy();

    my @certainEntities = $model->getEntity(\@filter);

=head2 addEntity()

adds entities to a model.

    # create new Entities
    my $entity = CAE::Nastran::Nasmod::Entity->new();

    $entity->setComment("just a test"); # comment
    $entity->setCol(1, "GRID");         # column 1: cardname
    $entity->setCol(2, 1000);           # column 2: id
    $entity->setCol(4, 17);             # column 4: x
    $entity->setCol(5, 120);            # column 5: y
    $entity->setCol(6, 88);             # column 6: z

    my $entity2 = CAE::Nastran::Nasmod::Entity->new(); 
    $entity2->setComment("another test", "this is the second line of the comment");
    $entity2->setCol(1, "GRID");
    $entity2->setCol(2, 1001);
    $entity2->setCol(4, 203);
    $entity2->setCol(5, 77);
    $entity2->setCol(6, 87);

    # adds the entities to the model
    $model->addEntity($entity, $entity2);

=head2 merge()

merges two models.

    $model1->merge($model2);    # $model2 is beeing merged into model1

=head2 getCol()

returns the desired column of every entity in the model as an array.

    my $model2 = $model->filter(["", "GRID"]);     # returns a Nastranmodel $model2 that contains only the GRIDs of $model
    my @col2   = $model2->getCol(2);               # returns an array with all GRID-IDs (column 2) of $model2

=head2 count()

returns the amount of all entities stored in the model

    $model1->count();

=head2 print()

prints the whole model in nastran format to STDOUT or to a file.

    $model->print();              # prints to STDOUT
    $model->print("file.nas");    # prints to file.nas

=head1 LIMITATIONS

only bulk data is supported. only 8-field nastran format is supported. the larger the model, the slowlier is filtering.

=head1 TODO

indexing to accelerate filtering

=head1 TAGS

CA, CAE, FEA, FEM, Nastran, perl, Finite Elements, CAE Automation, CAE Automatisierung

=head1 AUTHOR

Alexander Vogel <avoge@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2014, Alexander Vogel, All Rights Reserved.
You may redistribute this under the same terms as Perl itself.
