package IsamObjects;

use strict;
use CIsam;
use vars qw(@ISA);
@ISA = qw(CIsam);


# function new
sub new
{
	my $class = shift;
	my $open_mode;

	if ( @_ != 0)
	{
		$open_mode = shift;
	}
	else
	{
		$open_mode = undef;
	}

	my $object = {} ;
	bless ($object, $class);
	
	#figuring out if the db files need to be build
	if ($open_mode == &BUILD)
	{
		$object->_initialize_build();
		$object->_initialize_common();
	}
	elsif( defined ($open_mode))
	{
		$object->_initialize_common($open_mode);
	}
	else
	{
		$object->_initialize_common();
	}
	return $object;
}

#destructor for the object
sub DESTROY
{
	my $this = shift;
	$this->{ISAM_OBJ}->isclose();
}

#common initialization for the db object
sub _initialize_common
{
	my $object = shift;
	my $open_mode;

	if ( @_ != 0)
	{
		$open_mode = shift;
	}
	else
	{
		$open_mode = undef;
	}

	my $object_name = sprintf("%s",ref($object));
	my $dataset_name = "\L$object_name";


	if (defined ($open_mode))
	{
		$object->{ISAM_OBJ} = CIsam->isopen($dataset_name, $open_mode);
	}
	else
	{
		$object->{ISAM_OBJ} = CIsam->isopen($dataset_name, &ISINOUT + &ISMANULOCK);
	}
	
	#raw buffer
	my $BUFFER = ' ' x $object->LENGTH;
	$object->{BUFFER} = \$BUFFER;


	#initializing the fields
	$object->clear();

}

#building initialization for the db object
sub _initialize_build
{
	my $object = shift;
	my $object_name = sprintf("%s",ref($object));
	my $dataset_name = "\L$object_name";
	my @index_list = keys ( %{ $object->INDEXMAP } );
	my $key = shift ( @index_list );
	


	$object->{ISAM_OBJ} = CIsam->isbuild($dataset_name,$object->LENGTH,$object->INDEXMAP->{$key}, &ISINOUT+&ISEXCLLOCK) or die "error " . CIsam->iserrno . " isbuild($dataset_name)\n";

	while ( defined( $key = shift ( @index_list )))
	{
		$object->{ISAM_OBJ}->isaddindex($object->INDEXMAP->{$key}) or die "error isaddindex -> $key\n";

		#The following two lines are needed by the C-Isam v4.0
		$object->{ISAM_OBJ}->isclose();
		$object->{ISAM_OBJ}->isopen($dataset_name, &ISINOUT+&ISEXCLLOCK);
	}
	$object->{ISAM_OBJ}->isclose();


}

#clears the data entries in the object
sub clear
{
	my $this = shift;
	${$this->{BUFFER}} = ' ' x $this->LENGTH;
	my @keylist = keys ( %{ $this->FIELDMAP } );
	foreach my $key (@keylist)
	{
		my $type = $this->FIELDMAP->{$key}[0];
		if ( $type eq 'CHARTYPE')
		{
			$this->{$key} = ' ';
		}
		elsif ( ($type eq 'DOUBLETYPE') ||
				($type eq 'MONEYTYPE') ||
				($type eq 'FLOATTYPE'))
		{
			$this->{$key} = '0.00';
		}
		else
		{
			$this->{$key} = 0;
		}
	}
	return;
}

#This function stuffs the raw buffer with the values in the structure
sub _stuff_buffer
{
	my $this = shift;
	my @keylist = keys ( %{ $this->FIELDMAP } );
	my @byte_array;
	my $temp_hex;

	#BUG!
	#on some systems (AIX 3) buffer gets garbage collected while it still exists
	#this is a temporary work-around for the problem
	if (length(${$this->{BUFFER}}) != $this->LENGTH)
	{
		${$this->{BUFFER}} = ' ' x $this->LENGTH;
	}

	foreach my $key (@keylist)
	{
		my $type = $this->FIELDMAP->{$key}[0];
		my $offset = $this->FIELDMAP->{$key}[1];
		my $length = $this->FIELDMAP->{$key}[2];

		if ( $type eq 'CHARTYPE')
		{
			my $format = "%-${length}s";
			substr(${$this->{BUFFER}}, $offset, $length) = sprintf($format, $this->{$key});
		}
		elsif ( ($type eq 'DOUBLETYPE') ||
				($type eq 'MONEYTYPE'))
		{
			@byte_array = $this->{ISAM_OBJ}->stdbl($this->{$key}, $length);
			for (my $i = 0; $i < $length; $i++)
			{
				$temp_hex = ord(sprintf("%-1s", $byte_array[$i]));	
				substr(${$this->{BUFFER}}, $offset+$i,1) = chr($temp_hex);
			}
		}
		elsif ( ($type eq 'INTTYPE') ||
		        ($type eq 'PERIODTYPE'))
		{
			@byte_array = $this->{ISAM_OBJ}->stint($this->{$key}, $length);
			for (my $i = 0; $i < $length; $i++)
			{
				$temp_hex = ord(sprintf("%-1s", $byte_array[$i]));	
				substr(${$this->{BUFFER}}, $offset+$i,1) = chr($temp_hex);
			}
		}
		elsif ($type eq 'FLOATTYPE')
		{
			@byte_array = $this->{ISAM_OBJ}->stfloat($this->{$key}, $length);
			for (my $i = 0; $i < $length; $i++)
			{
				$temp_hex = ord(sprintf("%-1s", $byte_array[$i]));	
				substr(${$this->{BUFFER}}, $offset+$i,1) = chr($temp_hex);
			}
		}
		else 		#defaults to LONGTYPE
		{
			@byte_array = $this->{ISAM_OBJ}->stlong($this->{$key}, $length);
			for (my $i = 0; $i < $length; $i++)
			{
				$temp_hex = ord(sprintf("%-1s", $byte_array[$i]));	
				substr(${$this->{BUFFER}}, $offset+$i,1) = chr($temp_hex);
			}
		}
	}
	
}

#this function unstuffs the raw buffer and puts it into the structure
sub _unstuff_buffer
{
	my $this = shift;
	my @keylist = keys ( %{ $this->FIELDMAP } );
	foreach my $key (@keylist)
	{
		my $type = $this->FIELDMAP->{$key}[0];
		my $offset = $this->FIELDMAP->{$key}[1];
		my $length = $this->FIELDMAP->{$key}[2];
		my $raw_value = substr( ${$this->{BUFFER}}, $offset, $length);

		if ( $type eq 'CHARTYPE')
		{
			$this->{$key} = substr(${$this->{BUFFER}}, $offset, $length);
		}
		elsif ( ($type eq 'DOUBLETYPE') ||
				($type eq 'MONEYTYPE'))
		{
			$this->{$key} = $this->{ISAM_OBJ}->lddbl($raw_value);
		}
		elsif ( ($type eq 'INTTYPE') ||
		        ($type eq 'PERIODTYPE'))
		{
			$this->{$key} = $this->{ISAM_OBJ}->ldint($raw_value);
		}
		elsif ($type eq 'FLOATTYPE')
		{
			$this->{$key} = $this->{ISAM_OBJ}->ldfloat($raw_value);
		}
		else 		#defaults to LONGTYPE
		{
			$this->{$key} = $this->{ISAM_OBJ}->ldlong($raw_value);
		}
	}
}

sub add
{
	my $this = shift;
	$this->_stuff_buffer();
	$this->{ISAM_OBJ}->iswrite($this->{BUFFER});
}

#this function gets the record from the database
#the object needs to be seeded with the search parameters
#and the mode of access of the db needs to be passed to get
sub get
{
	my $this = shift;
	my $mode = shift;

	$this->_stuff_buffer();

	if ( ( defined($this->{_HIDDEN_OPTIONS}->{PENDING_PATH})) ||
	     ( ($this->{_HIDDEN_OPTIONS}->{CURRENT_MODE} != $mode) &&
	       ( ($mode == &ISFIRST) ||
	         ($mode == &ISLAST)  ||
	         ($mode == &ISEQUAL) ||
	         ($mode == &ISGREAT) ||
	         ($mode == &ISGTEQ)
               )
	     )
	   )
	{
		$this->{_HIDDEN_OPTIONS}->{CURRENT_MODE} = $mode;
		if (defined($this->{_HIDDEN_OPTIONS}->{PENDING_PATH}))
		{
			$this->{_HIDDEN_OPTIONS}->{ISAM_PATH} = $this->{_HIDDEN_OPTIONS}->{PENDING_PATH};
		}
		$this->{_HIDDEN_OPTIONS}->{PENDING_PATH} = undef;
		$this->{ISAM_OBJ}->isstart($this->INDEXMAP->{$this->{_HIDDEN_OPTIONS}->{ISAM_PATH}}, 0, $this->{BUFFER}, $mode);
	}
		
		
	my $status = $this->{ISAM_OBJ}->isread($this->{BUFFER}, $mode);
	$this->_unstuff_buffer();
	return ($status);
}

#this function sets the path throught the database
sub path
{
	my $this = shift;
	my $path = shift;
	if ($this->{_HIDDEN_OPTIONS}->{ISAM_PATH} ne $path)
	{
		$this->{_HIDDEN_OPTIONS}->{PENDING_PATH} = $path
	}
	#$this->{ISAM_OBJ}->isstart($this->INDEXMAP->{$path}, 0, $this->{BUFFER}, $mode);
}

#this function updates the record that already exists
sub update
{
	my $this = shift;
	$this->_stuff_buffer();
	$this->{ISAM_OBJ}->isrewrite($this->{BUFFER});
}

#this function deletes the current record
sub delete
{
	my $this = shift;
	$this->{ISAM_OBJ}->isdelcurr();
}

#this function is just a define for a building mode
sub BUILD
{
	0x45678;
}

1;
__END__;
