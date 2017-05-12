package CAE::Nastran::Nasmod::Entity;

use strict;
use warnings;
use vars qw($VERSION $DATE);

$VERSION           = '0.26';
$DATE              = 'Fri Apr 25 13:17:31 2014';

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self={};
    
    $self =
    {
    	"content"   => [],
    	"comment"	=> [],
    };
    
    bless ($self, $class);
    return $self;
}

#---------------------
# adds a line to the comment
#---------------------
sub addComment
{
	my $self = shift;
	my $refa_comment = shift;

	push (@{$self->{'comment'}}, @$refa_comment);
}
#---------------------

#---------------------
# sets the comment to a certain value
# setComment(\@commentlines)
# setComment(\@commentlines, $commentline, \@anotherText, ...)
#---------------------
sub setComment
{
	my $self = shift;

	undef(@{$self->{'comment'}});
	
	foreach (@_)
	{
		if(ref($_) =~ /array/)
		{
			foreach my $line (@$_)
			{
				push (@{$self->{'comment'}}, $line);
			}
		}
		else
		{
			push (@{$self->{'comment'}}, $_);
		}
	}
}
#---------------------

#---------------------
# sets a certain column to a certain value
# setCol(<int>, <string>)
#---------------------
sub setCol
{
	my $self = shift;
	my $col = shift;
	my $string = shift;

	$self->{content}->[$col-1] = $string;
}
#---------------------

#---------------------
# get a col
# getCol(<int>)
# return: <string>
#---------------------
sub getCol
{
	my $self = shift;
	my $col = shift;
	
	if ($self->{content}->[$col-1])
	{
		return $self->{content}->[$col-1];
	}
	else {return""};
}
#---------------------

#---------------------
# get all data
# getRow()
# return: @<string>
#---------------------
sub getRow
{
	my $self = shift;
	return @{$self->{'content'}}
}
#---------------------

#---------------------
# match an entity to a pattern
# es muessen alle filter gefunden werden, sonst undef
# falls es fuer einen row einen ganzen array an moeglichkeiten gibt gilt der filter als bestanden, wenn eine moeglichkeit davon matcht
#---------------------
sub match
{
	my $self = shift;
	my $refa_filter = shift;

#	$self->print();
#	print "FILTER: ".join("|", @$refa_filter)."\n";
#	foreach my $column (1..15)
#	{
#		print "COLUMN $column: ".$self->getCol($column)."\n";
#	}

	my @colFilterResults;
	
	# falls ein filter fuer dem Kommentar gesetzt wurde, wir der vollstaendige kommentar untersucht
	# falls der filter dort greift wird auf "true" gesetzt.
	if ($$refa_filter[0])
	{
		if(!(ref($$refa_filter[0]) =~ m/array/i))
		{
			$colFilterResults[0] = "false";
			foreach my $commentzeile (@{$self->{'comment'}})
			{
#				print "GREIFT COMMENTFILTER $$refa_filter[0] AN ZEILE $commentzeile\n";
				if ( $commentzeile =~ m/$$refa_filter[0]/ )
				{
#					print "JA\n";
					$colFilterResults[0] = "true";
				}
				else
				{
#					print "NEIN\n";
				}
			}
		}
		else
		{
			$colFilterResults[0] = "false";
			foreach my $vergleichsString (@{${$refa_filter}[0]})
			{
				foreach my $commentzeile (@{$self->{'comment'}})
				{
#					print "TEST $vergleichsString on comment '" . $commentzeile ."'\n";
					if ( $commentzeile =~ m/$vergleichsString/ )
					{
#						print "RESULT IS TRUE\n";
						$colFilterResults[0] = "true";
					}
				}
			}
		}
	}

#	print "RESULTAFTERCOMMENT: @colFilterResults\n";

	# falls der kommentarfilter nicht gefunden wurde, kann hier schon undef zurueckgegeben werden
	if(grep { $_ eq "false"} @colFilterResults) {return undef;}

	# die filter fuer die spalten
	for(my $x=0, my $col=1; $x<=(@$refa_filter); $x++, $col++)
	{
		# wenn es fuer die spalte einen filter gibt
		if ( $$refa_filter[$col] )
		{
			# mit 'false' beginnen
			$colFilterResults[$col] = "false";

			# und es sich dabei nicht um ein ARRAY handelt
#			print "IST ES EIN ARRAY? " . $$refa_filter[$row] . "||" .ref($$refa_filter[$row]) ."\n";
			if(!(ref($$refa_filter[$col]) =~ m/array/i))
			{
				# wenn der filter dieses rows greift, dann auf 'true' setzen
#				print "TESTING CONTENT ". $self->{'content'}->[$x] . " on regex /^". $$refa_filter[$col] . "\$/\n";
				if (($self->{'content'}->[$x]) && ($self->{'content'}->[$x] =~ /^$$refa_filter[$col]$/))
				{
#					print "RESULT: GOOD\n";
					$colFilterResults[$col] = "true";
				}
				# ansonsten kann direkt 'undef' zurueckgegeben werden
				else
				{
#					print "RESULT: BAD\n";
					return undef;
				}
			}
			else
			{
				# jeden eintrag im array durchgehen und ueberpruefen ob ein eintrag passt
				foreach my $vergleichsString (@{${$refa_filter}[$col]})
				{
					# wenn eintrag passt
					if(($self->{'content'}->[$x]) && ( $self->{'content'}->[$x] =~ /^$vergleichsString$/))
					{
						$colFilterResults[$col] = "true";
						next;
					}
				}
			}
			
			# wenn der filter zur aktuellen spalte 'false' geliefert hat, kann man sich die ueberpruefung evtl. anderer spalten sparen
			if($colFilterResults[$col] eq "false")
			{
#				print "filter fuer row = 'false'. return undef\n";
				return undef;
			}
		}
		else
		{
			next;
		}
	}
	
	if(grep { if ($_) {$_ eq "false"} } @colFilterResults)
	{
#		print "Mindestens 1 Filter fuer Entity lieferte 'false' => return undef.\n";
#		print "NOMATCH\n";
		return undef;
	}
	else
	{
#		print "Alle Filter fuer Entity lieferten 'true' => return true.\n";
		return "true";
#		print "MATCH\n";
	}
}
#---------------------

#---------------------
# sprint entity
#---------------------
sub sprint
{
	my $self = shift;

	my $return;
	
	# print comment if available
	foreach (@{$self->{comment}})
	{
		unless ($_ =~ m/^\$/) {$_ = "\$".$_;}		# falls noch kein Kommentarzeichen vorhanden, eines hinzufuegen
		$return .= $_."\n";
#		print $_."\n";
	}
	
	
	# print content
#	print "JUPP: ".(1+int((scalar(@{$self->{'content'}}))/10))."\n";
	for (my $zeile=0; $zeile<(1+int((scalar(@{$self->{'content'}}))/10)); $zeile++)
	{
		# 10er pack befuellen
		my $formatstring;
		my @ausgabe;
		for(my $x=(0+$zeile*10); ( ($x<@{$self->{content}}) && ($x<(10+$zeile*10)) ); $x++)
		{
			if(defined ${$self->{content}}[$x])
			{
				push(@ausgabe, ${$self->{content}}[$x]);
				$formatstring .= "%-8.8s";
			}
		}
		$return .= sprintf $formatstring."\n", @ausgabe;
	}
	return $return;
}
#---------------------

#---------------------
# print entity
#---------------------
sub print
{
	my $self = shift;
	my $ausgabe = $self->sprint();
	print $ausgabe;
}

1;

__END__

=head1 NAME

CAE::Nastran::Nasmod::Entity - an entity of a nastran model

=head1 SYNOPSIS

    use CAE::Nastran::Nasmod::Entity;

    # create new Entity (an empty nastran card)
    my $entity = CAE::Nastran::Nasmod::Entity->new();

	# define its content
    $entity->setComment("just a test"); # comment
    $entity->setCol(1, "GRID");         # column 1: cardname
    $entity->setCol(2, 1000);           # column 2: id
    $entity->setCol(4, 17);             # column 4: x
    $entity->setCol(5, 120);            # column 5: y
    $entity->setCol(6, 88);             # column 6: z

    # print entity to STDOUT
    $entity->print();
    
=head1 DESCRIPTION

create new entities, set data fields, extract data, match against filters and print data

=head1 API

=head2 new()

creates and returns a new Entity

    # create a new Entity
    my $entity = CAE::Nastran::Nasmod::Entity->new();

=head2 setComment()

sets the comment of the entity (and deletes existent comment)

    # set a new comment
    $entity->setComment("hi there");
    
    # set a new comment
    $entity->setComment("im the first line", "and i'm the second one");
    
    # set a new comment
    my @comment = ("i'm the first line", "and i'm the second one");
    $entity->setComment(\@comment);
    
=head2 addComment()

adds a line of comment to an entity without deleting existent comment

    # add a line
    $entity->addComment("hi there");
    
    # add a second line
    $entity->addComment("i'm the second line");

=head2 setCol()

sets the value for a certain column

    # set column 1 to value 'hello'
    $entity->setCol(1, 'hello');

=head2 getCol()

gets the value of a certain column

    # get column 1
    my $value = $entity->getCol(1);

=head2 getRow()

returns all data columns as an array.

    my @row = $entity->getRow();

=head2 match()

match all data against a filter. returns true if filter matches otherwise returns undef

    # filter for GRID (NID=1000)
    my @filter = (
        "",                   # pos 0 filters comment:  entities pass which match // in the comment. (comment => no anchors in the regex)
        "GRID",               # pos 1 filters column 1: only entities pass which match /^GRID$/ in column 1. (note the anchors in the regex)
        "1000"                # pos 2 filters column 2: entities pass which match /^1000$/ in column 2. (note the anchors in the regex)
        ""                    # pos 3 filters column 3: entities pass which match // in column 3. (empty => no anchors in the regex)
    )

    my $result = $entity->match(\@filter);

=head2 print()

prints the entity in nastran format to STDOUT

    $entity->print();              # prints to STDOUT

=head1 TAGS

CA, CAE, FEA, FEM, Nastran, perl, Finite Elements, CAE Automation, CAE Automatisierung

=head1 AUTHOR

Alexander Vogel <avoge@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2014, Alexander Vogel, All Rights Reserved.
You may redistribute this under the same terms as Perl itself.
