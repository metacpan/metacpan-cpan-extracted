package CGI::Lazy::DB::RecordSet;

use strict;

use Tie::IxHash;
use Data::Dumper;

#------------------------------------------------------------------
sub basewhere {
	my $self = shift;

	return $self->{_basewhere};
}

#------------------------------------------------------------------------------
sub checkboxes {
	my $self = shift;

	return $self->{_checkboxes};
}

#--------------------------------------------------------------------
sub createSelect {
	my $self = shift;

	my $joinstring = '';
	my $orderbystring = $self->orderby ? ' order by '.$self->orderby : '';

	my $wherestring;
	my @binds;

	if (ref $self->where) {
		my @wherelist = @{$self->where};
		my $where = shift @wherelist;
		@binds = @wherelist;
		
		if ($self->basewhere) {
			$wherestring = $self->where ? ' where '.$self->basewhere. ' and '.$where : ' where '.$self->basewhere;
		} else {
			$wherestring = $self->where ? ' where '.$where : '';
		}

	} else {
		if ($self->basewhere) {
			$wherestring = $self->where ? ' where '.$self->basewhere. ' and '.$self->where : ' where '.$self->basewhere;
		} else {
			$wherestring = $self->where ? ' where '.$self->where : '';
		}
	}

	my @fieldlist;
       	
	foreach my $field (keys %{$self->fieldlist}) {
		unless ($self->displayOnly($field)) {
			if ($self->readfunc($field)) {
				push @fieldlist, $self->readfunc($field);
			} elsif ($self->passwd($field)) {
				next;
			} else {
				push @fieldlist, $field;
			}
		}
	}

	if ($self->joins) {
		foreach (@{$self->joins}) {
			$joinstring .= " " if $joinstring;
			my $type 		= $_->{type};
			my $table 		= $_->{table};
			my $field1		= $_->{field1}; 
			my $field2 		= $_->{field2};
			my $and			= $_->{and};

			$joinstring .= " $type join $table on $field1 = $field2 ";
			$joinstring .= " and $and" if $and;
		}
	}
	
	return "select ". join (', ', @fieldlist)." from ".$self->table.$joinstring.$wherestring.$orderbystring, @binds;
}

#------------------------------------------------------------------
sub data {
	my $self = shift;
	return $self->{_data};
}

#------------------------------------------------------------------
sub db {
	my $self = shift;

	return $self->{_db};
}

#------------------------------------------------------------------------------
sub delete {
	my $self = shift;
	my $data = shift;

	my $table = $self->table;
	my $primarykey = $self->primarykey;

	foreach my $ID (keys %$data) {
		my $query = "delete from $table where $primarykey = ?";
	       
		${$self->primarykeyhandle} = $ID;
#		$self->q->util->debug->edump($query.", $ID");
		$self->db->do($query, $ID);

	}
}
	
#------------------------------------------------------------------------------
sub displayOnly {
	my $self = shift;
	my $field = shift;
	
	if (exists $self->fieldlist->{$field}) {
		if ($self->fieldlist->{$field}->{displayOnly}) {
			return $self->fieldlist->{$field}->{displayOnly};
		} elsif ($self->fieldlist->{$field}->{displayonly}) {
			return $self->fieldlist->{$field}->{displayonly};
		}
	} else {
		return;
	}
}

#------------------------------------------------------------------------------
sub fieldlist {
	my $self = shift;

	return $self->{_fieldlist};
}

#------------------------------------------------------------------
sub handle {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{handle};
	} else {
		return;
	}
}

#------------------------------------------------------------------------------
sub hidden {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{hidden};
	} else {
		return;
	}
}

#-------------------------------------------------------------------------------
sub inputMask {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		if ($self->fieldlist->{$field}->{inputMask}) {
			return $self->fieldlist->{$field}->{inputMask};
		} elsif ($self->fieldlist->{$field}->{inputmask}) {
			return $self->fieldlist->{$field}->{inputmask};
		}
	} else {
		return;
	}
}

#------------------------------------------------------------------------------
sub insert {
	my $self = shift;
	my $data = shift;
	my $vars = shift;

	my $table = $self->table;
	my $primarykey = $self->primarykey;
	my $defaults = $self->insertdefaults;
	my $additional = $self->insertadditional;

	foreach my $row (keys %$data) {
		my @fieldlist;
		my @binds;
		my @bindvalues;
		
		if (%$vars) {
			foreach (keys %$vars) {
				if ($vars->{$_}->{value}) {
					$data->{$row}->{$_} = ref $vars->{$_}->{value} ? ${$vars->{$_}->{value}} : $vars->{$_}->{value};
#					$self->q->util->debug->edump("var: ".$vars->{$_}->{value}." -- ".${$vars->{$_}->{value}});
				}
			}
		}

		if ($defaults) {
			foreach my $field (keys %$defaults) {
				if ($defaults->{$field}->{value}) { #static quanities
					$data->{$row}->{$field} = $defaults->{$field}->{value};
					if ($vars->{$field}->{handle}) {
						${$vars->{$field}->{handle}} = $defaults->{$field}->{value};
					}
				} else { #values pulled from queries and such
					my $result = $self->db->getarray(@{$defaults->{$field}->{sql}});

					if (defined $result->[1] || defined $result->[0]->[1]) { #we got more than a single value, better warn
						$self->q->errorHandler->dbReturnedMoreThanSingleValue;
					}

					my $value = $result->[0]->[0];
					$data->{$row}->{$field} = $value;

					if ($vars->{$field}->{handle}) {
						${$vars->{$field}->{handle}} = $value;
					}

					if ($vars->{$field}->{primarykey}) {
						${$self->primarykeyhandle} = $value;
					}
				}
			}
		}

		foreach (keys %{$data->{$row}}) {
			my $field = $self->verify($_);
			if ($field) {
				unless ($self->displayOnly($field) || $self->readOnly($field)) {
					push @fieldlist, $field;

					my $value;


					if ($self->inputMask($field)) {
						$value = sprintf $self->inputMask($field), $data->{$row}->{$field};
					} elsif ($self->passwd($field)){
						if ($self->q->authn) {
							$value = $self->q->authn->passwdhash($data->{$row}->{$self->passwd($field)->{userField}}, $data->{$row}->{$field});
						}
					} else {
						$value = $data->{$row}->{$field};
					}

					if ($vars->{$field}->{handle}) {
						${$vars->{$field}->{handle}} = $value;
					}

					if ($field eq $self->primarykey) {
						${$self->primarykeyhandle} = $value;

					}

					push @bindvalues, $value;

					if ($self->writefunc($field) ) {
						push @binds,  $self->fieldlist->{$field}->{writefunc};
					} else {
						push @binds, "?";
					}

				}
			}
		}

		my $insertclause = join ', ', @fieldlist;
		my $binds = join ', ', @binds;
		my $query = "insert into $table ($insertclause) values ($binds)";
#		$self->q->util->debug->edump($query."\n".join ',', @bindvalues);

		$self->db->do($query, @bindvalues);

		if ($self->mysqlAuto) {
			my $query = 'select LAST_INSERT_ID()';
			${$self->primarykeyhandle} = $self->db->get($query);
		}


		if ($additional) { #addional queries run on insert
			foreach my $field (keys %$additional) {
				my $result = $self->db->getarray($additional->{$field}->{sql});

				if (defined $result->[1] || defined $result->[0]->[1]) { #we got more than a single value, better warn
					$self->q->errorHandler->dbReturnedMoreThanSingleValue;
				}

				my $value = $result->[0]->[0];

				if ($additional->{$field}->{handle}) {
					${$additional->{$field}->{handle}} = $value ;
				}
			}
		}
	}
}

#----------------------------------------------------------------------
sub insertadditional {
	my $self = shift;

	return $self->{_insertadditional};
}

#----------------------------------------------------------------------
sub insertdefaults {
	my $self = shift;

	return $self->{_insertdefaults};
}

#--------------------------------------------------------------------
sub joins {
	my $self = shift;

	return wantarray ? @{$self->{_joins}} : $self->{_joins};
}

#--------------------------------------------------------------------
sub label {
	my $self = shift;
	my $field = shift;

	return $self->fieldlist->{$field}->{label} ? $self->fieldlist->{$field}->{label} : $self->fieldlist->{$field}->{name};
}

#----------------------------------------------------------------------
sub new {
	my $class = shift;
	my $db = shift;
	my $args = shift;

	my $var = undef;	

	my $self = {
		_data 			=> [],
		_db			=> $db,
		_table			=> $args->{table},
		_basewhere		=> $args->{basewhere},
		_primarykey		=> $args->{primarykey},
		_orderby		=> $args->{orderby},
		_joins			=> $args->{joins},
		_insertdefaults		=> $args->{insertdefaults},
		_insertadditional	=> $args->{insertadditional},
		_updatedefaults		=> $args->{updatedefaults},
		_updateadditional	=> $args->{updateadditional},
		_where			=> '',
		_mysqlAuto		=> $args->{mysqlAuto},
		_primarykeyhandle		=> \$var,
		_checkboxes		=> [],

	};
	
	$self->{_fieldlist} = {};
	tie (%{$self->{_fieldlist}}, 'Tie::IxHash');

	foreach (@{$args->{fieldlist}}) {
		$self->{_fieldlist}{$_->{name}} = $_;
		if ($_->{webcontrol} && ($_->{webcontrol}->{type} eq 'checkbox')) {
			push @{$self->{_checkboxes}}, $_->{name};
		}
	}

	return bless $self, $class;
}

#------------------------------------------------------------------------------
sub noLabel {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{noLabel};
	} else {
		return;
	}
}

#--------------------------------------------------------------------
sub orderby {
	my $self = shift;
	my $value = shift;

	if ($value) {
		return $self->{_orderby} = $value;
	} else {
		return $self->{_orderby};
	}
}

#-------------------------------------------------------------------------------
sub outputMask {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		if ($self->fieldlist->{$field}->{outputMask}) {
			return $self->fieldlist->{$field}->{outputMask};
		} elsif ($self->fieldlist->{$field}->{outputmask}) {
			return $self->fieldlist->{$field}->{outputmask};
		}
	} else {
		return;
	}
}

#------------------------------------------------------------------------------
sub multipleField {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{multi};
	} else {
		return;
	}
}

#----------------------------------------------------------------------------------------
sub multipleFieldList {
	my $self = shift;

	my @multipleFieldList;
	foreach my $field (keys %{$self->{_fieldlist}}) {
		if ($self->multipleField($field)) {
			push @multipleFieldList, $self->fieldlist->{$field}->{name};
		}
	}

	return wantarray ? @multipleFieldList : \@multipleFieldList;

}

#-----------------------------------------------------------------------------
sub multipleFieldLabels {
	my $self = shift;

	my @multipleFieldLabels;
	foreach my $field (keys %{$self->{_fieldlist}}) {
		if ($self->fieldlist->{$field}->{multi}) {
			push @multipleFieldLabels, $self->fieldlist->{$field}->{label} ? $self->fieldlist->{$field}->{label} : $self->fieldlist->{$field}->{name};
		}
	}

	return wantarray ? @multipleFieldLabels : \@multipleFieldLabels;

}

#------------------------------------------------------------------------------
sub mysqlAuto {
	my $self = shift;

	return $self->{_mysqlAuto};

}

#------------------------------------------------------------------------------
sub passwd {
	my $self = shift;
	my $field = shift;
	
	if (exists $self->fieldlist->{$field}) {
		if ($self->fieldlist->{$field}->{passwd}) {
			return $self->fieldlist->{$field}->{passwd};
		} else {
			return;
		}
	} else {
		return;
	}
}

#------------------------------------------------------------------------------
sub primarykey {
	my $self = shift;
	my $value = shift;

	if ($value) {
		return $self->{_primarykey} = $value;
	} else {
		return $self->{_primarykey};
	}
}

#------------------------------------------------------------------------------
sub primarykeyhandle {
	my $self = shift;

	return $self->{_primarykeyhandle};
}

#------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->db->q;
}

#-----------------------------------------------------------------------------
sub readfunc {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{readfunc};
	} else {
		return;
	}
}

#------------------------------------------------------------------------------
sub readOnly {
	my $self = shift;
	my $field = shift;
	
	if (exists $self->fieldlist->{$field}) {
		if ($self->fieldlist->{$field}->{readOnly}) {
			return $self->fieldlist->{$field}->{readOnly};
		} elsif ($self->fieldlist->{$field}->{readonly}) {
			return $self->fieldlist->{$field}->{readonly};
		}
	} else {
		return;
	}
}

#--------------------------------------------------------------------
sub select { 
	my $self = shift;
	my @bindvars = @_;

	my ($query, @wherebinds)  = $self->createSelect;

	if (@wherebinds) {
		unshift @bindvars, $_ for @wherebinds;
	}

	my @data;
	my $sth;
	
	my ($pkg, $file, $line) = caller;

	eval {
		$sth = $self->db->dbh->prepare($query);
		$sth->execute(@bindvars);
#		$self->q->util->debug->edump($query, @bindvars);
	};

	if ($@) {
		$self->q->errorHandler->dbError($pkg, $file, $line, $query);
	} else {

		while (my @record = $sth->fetchrow_array) {
			my @fieldlist = keys %{$self->fieldlist};
		
			my $record = {};
			tie (%$record, 'Tie::IxHash');

			for (0..$#fieldlist) {
				next if	$self->passwd($fieldlist[$_]);
				$record->{$fieldlist[$_]} = $record[$_];
			}

			push @data, $record;
		}
	}

	$self->{_data} = \@data; 

	#$self->q->util->debug->edump(\@data);
	return $self->{_data};
}

#-------------------------------------------------------------------------------
sub table {
	my $self = shift;
	my $value = shift;

	if ($value) {
		return $self->{_table} = $value;
	} else {
		return $self->{_table};
	}
}

#-------------------------------------------------------------------------------
sub update {
	my $self = shift;
	my $data = shift;
	my $vars = shift;

	my $table = $self->table;
	my $primarykey = $self->primarykey;
	my $defaults = $self->updatedefaults;
	my $additional = $self->updateadditional;

	foreach my $ID (keys %$data) {
		my @updates;
		my @binds;

		if (%$vars) {
			foreach (keys %$vars) {
				if ($vars->{$_}->{value}) {
					$data->{$ID}->{$_} = ref $vars->{$_}->{value} ? ${$vars->{$_}->{value}} : $vars->{$_}->{value};
#					$self->q->util->debug->edump("var: ".$vars->{$_}->{value}." -- ".${$vars->{$_}->{value}});
				}
			}
		}

		if ($defaults) {
			foreach my $field (keys %$defaults) {
				if ($defaults->{$field}->{value}) { #static quanities
					$data->{$ID}->{$field} = $defaults->{$field}->{value};
					if ($vars->{$field}->{handle}) {
						${$vars->{$field}->{handle}} = $defaults->{$field}->{value};
					}
				} else { #values pulled from queries and such
					my $result = $self->db->getarray(@{$defaults->{$field}->{sql}});

					if (defined $result->[1] || defined $result->[0]->[1]) { #we got more than a single value, better warn
						$self->q->errorHandler->dbReturnedMoreThanSingleValue;
					}

					my $value = $result->[0]->[0];
					$data->{$ID}->{$field} = $value;

					if ($vars->{$field}->{handle}) {
						${$vars->{$field}->{handle}} = $value;
					}
				}
			}
		}


		foreach (keys %{$data->{$ID}}) {
			my $field = $self->verify($_);

			if ($field) {
				unless ($self->displayOnly($field) || $self->readOnly($field)) {
					if ($vars->{$field}->{handle}) {
						${$vars->{$field}->{handle}} = $data->{$ID}->{$field};

					}

					if ($field eq $self->primarykey) {
						${$self->primarykeyhandle} = $data->{$ID}->{$field};

					}

					if ($self->inputMask($field)) {
						push @binds, sprintf $self->inputMask($field), $data->{$ID}->{$field};
					} elsif ($self->passwd($field)){
						if ($data->{$ID}->{$field}) {
							if ($self->q->authn) {
								push @binds, $self->q->authn->passwdhash($data->{$ID}->{$self->passwd($field)->{userField}}, $data->{$ID}->{$field});
							}
						}
					} else {
						push @binds, $data->{$ID}->{$field};
					}

					if ($self->writefunc($field) ) {
						push @updates,  "$field = ".$self->fieldlist->{$field}->{writefunc};

					} elsif ($self->passwd($field)) {
						if ($self->q->authn) {
							if ($data->{$ID}->{$field}) {
								push @updates,  "$field = ?";
							}
						}
					} else {
						push @updates,  "$field = ?";
					}
				}
			}
		}

		if (@{$self->checkboxes}) {
			foreach (@{$self->checkboxes}) {
				next if exists $data->{$ID}->{$_};

				if ($vars->{$_}->{handle}) {
					${$vars->{$_}->{handle}} = '';
				}

				push @updates,  "$_ = ?";
				push @binds, '';

			}
		}

		my $updateclause = join ',', @updates;

		my $query = "update $table set $updateclause where $primarykey = ?";

#		$self->q->util->debug->edump($query, join ',', @binds. " key: $ID");
	       
		$self->db->do($query, @binds, $ID);

		${$self->primarykeyhandle} = $ID;

		if ($additional) { #addional queries run on insert
			foreach my $field (keys %$additional) {
				my $result = $self->db->getarray($additional->{$field}->{sql});

				if (defined $result->[1] || defined $result->[0]->[1]) { #we got more than a single value, better warn
					$self->q->errorHandler->dbReturnedMoreThanSingleValue;
				}

				my $value = $result->[0]->[0];

				if ($additional->{$field}->{handle}) {
					${$additional->{$field}->{handle}} = $value ;
				}
			}
		}
	}


}

#----------------------------------------------------------------------
sub updateadditional {
	my $self = shift;

	return $self->{_updateadditional};
}

#----------------------------------------------------------------------
sub updatedefaults {
	my $self = shift;

	return $self->{_updatedefaults};
}

#-----------------------------------------------------------------------------
sub validator {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{validator};
	} else {
		return;
	}

}

#----------------------------------------------------------------------------------------
sub verify {
	my $self = shift;
	my $value = shift;

	$value =~ /^([\w\d\-\.]+)$/; #letters, numbers, underscores, dots, and dashes only please.
	my $field = $1;

	if (exists $self->fieldlist->{$field}) { #fieldname has to be in recordset
		if ($field =~ /\./) {		 #if there's a . in the fieldname
			my $table = $self->table;
			if ($field =~ /^$table/) { #the first part has to be the recordset's table
				return $field;
			} else {		# its a joined field, no modification allowed
				return;
			}
		}
		return $field;
	}

	return;
}

#-----------------------------------------------------------------------------
sub visibleFieldLabels {
	my $self = shift;

	my @visibleFieldLabels;
	foreach my $field (keys %{$self->{_fieldlist}}) {
		unless ($self->fieldlist->{$field}->{hidden}) {
			push @visibleFieldLabels, $self->fieldlist->{$field}->{label} ? $self->fieldlist->{$field}->{label} : $self->fieldlist->{$field}->{name};
		}
	}

	return wantarray ? @visibleFieldLabels : \@visibleFieldLabels;

}

#-----------------------------------------------------------------------------
sub visibleFields {
	my $self = shift;

	my @visibleFieldList;
	foreach my $field (keys %{$self->{_fieldlist}}) {
		unless ($self->fieldlist->{$field}->{hidden}) {
			push @visibleFieldList, $self->fieldlist->{$field}->{name};
		}
	}

	return wantarray ? @visibleFieldList : \@visibleFieldList;
}

#------------------------------------------------------------------------------
sub webcontrol {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{webcontrol};
	} else {
		return;
	}
}

#-----------------------------------------------------------------------------
sub where {
	my $self = shift;
	my @values = @_;
	
	if (@values) {
		if (scalar @values > 1) {
			return $self->{_where} = \@values; #theres a list, store an arrayref

		} else {
			return $self->{_where} = $values[0]; #where is a single string, store a scalar
		}
	} else {
		return $self->{_where};
	}
}

#-----------------------------------------------------------------------------
sub writefunc {
	my $self = shift;
	my $field = shift;

	if (exists $self->fieldlist->{$field}) {
		return $self->fieldlist->{$field}->{writefunc};
	} else {
		return;
	}
}

1;

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::RecordSet

=head1 SYNOPSIS

	use CGI::Lazy;

	our $q = CGI::Lazy->new({

					tmplDir 	=> "/templates",

					jsDir		=>  "/js",

					plugins 	=> {

						mod_perl => {

							PerlHandler 	=> "ModPerl::Registry",

							saveOnCleanup	=> 1,

						},

						ajax	=>  1,

						dbh 	=> {

							dbDatasource 	=> "dbi:mysql:somedatabase:localhost",

							dbUser 		=> "dbuser",

							dbPasswd 	=> "letmein",

							dbArgs 		=> {"RaiseError" => 1},

						},

						session	=> {

							sessionTable	=> 'SessionData',

							sessionCookie	=> 'frobnostication',

							saveOnDestroy	=> 1,

							expires		=> '+15m',

						},

					},

				});

	my $recordset = $q->db->recordset({

			table		=> 'detail',  #table where records are coming from

			mysqlAuto	=> 1,

			fieldlist	=> [

						{name => 'detail.ID', #name of field

							hidden => 1}, #do not display to screen.  Recordset cant do any operations on fields that are not a part of itself, however all fields need not be displayed

						{name => 'invoiceid', 

							hidden => 1},

						{name => 'prodCode', 

							label => 'Product Code', 

							validator => {rules => ['/\d+/'], msg => 'number only, and is required'}}, #validator for filed.  msg is not implemented at present.

						{name 		=> 'quantity', 

							label 		=> 'Quantity', 

							validator 	=> {rules => ['/\d+/'], msg => 'number only, and is required'},

							outputMask	=> "%.1f", #formatting to data applied on output to browser

						},

						{name => 'unitPrice', 

							label 		=> 'Unit Price' , 

							validator 	=> {rules => ['/\d+/'], msg => 'number only, and is required'},

							inputMask	=> "%.1f", #formatting to data applied on input to database

							},

						{name => 'productGross', 

							label => 'Product Gross' , 

							validator => {rules => ['/\d+/'], msg => 'number only, and is required'}},

						{name => 'prodCodeLookup.description', 

							label => 'Product Description', 

							readOnly => 1 }, #readOnly values display to the screen, but never get written to the db

						], 

			basewhere 	=> '',  #baseline where clause for the select query.  this is used in all selects, even if 'where is set later.

			joins		=> [ #table joins

						{type => 'inner', table	=> 'prodCodeLookup', field1 => 'prodCode', field2 => 'prodCodeLookup.ID',},

			],

			orderby		=> 'detail.ID',  #order by clause for select wuery

			primarykey	=> 'detail.ID', #primary key for recordset.  This value is looked for for all updates and deletes

			insertdefaults  => {

				unitprice        => {

					value => 'lots',

					handle	=> $ref,

				},

				invoiceid         => {

					sql     => 'select something.nextval from dual',
					
					primarykey	=> 1,

				},

			},

	});


	my $thing = $q->ajax->dataset({

			id		=> 'detailBlock',

			type		=> 'multi',

			template	=> "UsbInternalPOCDetailBlock.tmpl",

			lookups		=> {

					prodcodeLookup  => {

						sql 		=> 'select ID, description from prodCodeLookup', 

						preload 	=> 1,

						orderby		=> ['ID'],

						output		=> 'hash',

						primarykey	=> 'ID',

					},

						

			},

			recordset	=> $recordset,

			});
			

=head1 DESCRIPTION

CGI::Lazy::DB::Recordset is a container object for handling a set of records pulled out of a database.  The big difference between using the Recordset object and just using a standard query is the Recordset, with its defined internal structure allows for automated transformations to the data.  The object builds the queries on the fly, and remembers where it got all the data in question, so it can edit it and put it back.  Much of this functionality is seen in the CGI::Lazy::Widget::Dataset object, for which the Recordset object was originally written.

=head1 METHODS

=head2 basewhere ()

Returns the basewhere string for the recordset.  

=head2 createSelect ()

Creates the Select statement out of the structure of the Recordset.

=head2 data ()

Returns data reference from Recordset.  Will always be present, but will be empty until select() is called.

=head2 delete ( data )

Deletes records with primary keys in data.

=head3 data

Hashref who's keys are the primary keys of the records to be deleted.

=head2 displayOnly ( field )

Returns true if field has displayOnly key set to a true value.

=head3 field

name of field to test

=head2 db ()

Returns reference to CGI::Lazy::DB object


=head2 fieldlist ()

Returns array ref of field list with which recordset was built.

=head2 handle ( field )

Returns reference used as handle to value of field.

=head3 field

Name of field who's handle to retrieve

=head2 hidden ( field )

Returns true if field in question has been set to hidden

=head3 field

name of field to test

=head2 inputMask ( field )

Returns inputMask for field of given name, if one has been set.

=head3 field

Name of field to test.

=head2 insert ( data, vars )

Inserts data modified by vars into table accessed by Recordset.

=head3 data

Hashref of data to be inserted.  Each key corresponds to a row of data

=head3 vars

modifiers for data to be inserted

=head2 insertadditonal

Returns reference of additional information to be inserted with each new record

=head2 insertdefaults

Returns reference of default values to be inserted with each new record

=head2 joins

Returns either list or arrayref of joins for Recordset

=head2 label ( field )

Returns label set for field, or name of field if no label has been specified

=head3 field

field name to test.

=head2 new ( vars )

Constructor

=head3 vars

Hashref with construction properties.  

Options:

	{

		table		=> $table, 

		mysqlAuto	=> 1,

		basewhere 	=> $where,

		orderby 	=> $order by, 

		primarykey 	=> $keyfield, 

		fieldlist 	=> [

			{

				name 		=> 'field1', 

				label 		=> 'some field',

				validator 	=> { rules => ['/\d+/'},

				outputMask	=> "%1.f",

				inputMask	=> "%1.f",

			},

			{

				name 		=> 'field2', 

				label 		=> 'some other field',

				outputMask	=> "%1.f",

				readOnly	=> 1,

			},

 			{

                        	name            => 'post_date',

				label           => 'Post Date',

				readfunc        => "to_char(post_date, 'YYYY-MM-DD')",

				writefunc       => "to_date(?, 'YYYY-MM-DD')",

			},

			{

				name		=> 'username',

				label		=> 'Username',

			},

			{	

				name		=> 'passwd',
				
				label		=> 'Password',

				passwd		=> {

							userField	=> 'username',

				},

			},
				

		],

		insertdefaults	=> {

			field1 => {

				value	=> 'some value',

			},

			field2 => {

				sql	=> ['select foo from bar where ?', $bind1],
			},

			field3	=> {

				sql	=> ['select foo.nextvar from dual'],
				handle	=> $ref,
			}

		updatedefaults 	=> {

			field1 => {

				value	=> 'some value',

			},

			field2 => {

				sql	=> ['select foo from bar where ?', $bind1],
			},

			field3	=> {

				sql	=> ['select foo.nextvar from dual'],
				handle	=> $ref,
			}

		}


	}


=head3 table

string.  name of table

=head3 mysqlAuto

set flag if primary key for this recordset is created by mysql auto_increment column.  If set, composite widgets will automatically make this value available to member widgets on insert.

=head3 basewhere

Sql string. This forms the base where clause for all selects.  This string should not contain any variables from the outside world, as it is NOT bound, and could be used in sql injection attacks were cgi parameters used here.  If you want to use cgi params, see the 'where' method which is intended to be dynamic, and can take binds.

=head3 orderby

string. orderby clause

=head3 primarykey

field name of primary key for table

=head3 fieldlist

array ref. list of fields with their attributes

=head4 Fieldlist Options

	name		=> name of field

	hidden		=> if true, field is never displayed, but is selected

	readOnly	=> if true, field is displayed, but never written

	label		=> displayed label of field.  if blank label defaults to fieldname

	noLabel		=> if true, no label is displayed for field.

	oututMask	=> sprintf string that transforms data on the way out of db to screen

	inputMask	=> sprintf string that transforms data on the way into db

	validator	=> rules for field validation

			rules	=>  arrayref of tests to check.  if all return true, field is valid. Currently only supports regexes. 

			message	=> canned error message to display onerror.  (not currently used by anything, but you can grab this in your own code and display it)

	readfunc	=> database function to perform on read

	writefunc	=> db function to perform on write	

	insertdefaults 	=> default values inserted on insert
		
		value	=> value to insert

		sql	=> array ref.  first value is sql to generate value to insert, rest is binds

		handle	=> reference whose referrent will contain whatever value is set into db.  Useful for later use in cgi.

	updatedefaults	=> default values updated on update
		
		value	=> value to insert

		sql	=> array ref. first value is sql to generate value to insert, rest is binds

		handle	=> reference whose referrent will contain whatever value is set into db.  Useful for later use in cgi.

	webcontrol	=> type of input displayed to browser.  Defaults to text input field.
		
		type	=> select, checkbox, text.  Text is the default.

		value	=> for a checkbox, only a single value can be specified

		values	=> arrayref, or hashref.  If arrayref, both displayed value and value will be the same.  If hashref, key will be label, value will be value.  

		sql	=> [$query, @binds]	You can specify a query that will build the values, but it expected to return 2 values per row, the first being the label, the second being the value.

		notNull	=> 1   Set this for selects if you don't want the first item of the select to be blank

	passwd		=> This field is password field used with the authn plugin

		userField	=> name of field in recordset that will contain the username


=head3 updatedefaults 

means for setting default values on any update

=head3 insertdefaults

means for setting default values on any insert

=head2 noLabel ( field )

Returns true if field in question has been set with the noLabel option

=head3 field

Name of field to test.
=head2 orderby ( sql )

returns or sets the order by clause

=head3 sql

sql string

=head2 outMask ( field )

Returns outputMask set for field.

=head3 field

Name of field to test.

=head2 multipleFiled ( field )

Returns true if field in question has multipleField option set (i.e. it's supposed to turn up on the mulitple record screen)

=head3 field

Name of field to test.

=head2 multipleFieldList

Returns arrayref or array of fields flagged to show up on multiple records page

=head2 multipleFieldLabels

Returns arrayref or array of labels for fields chosen to appear on multiple record pages.

=head2 mysqlAuto ()

Returns true if recordset was created with mysqlAuto => 1 .

=head2 passwd ( field ) 

Returns passwd hashref from fieldlist config.  

=head3 fieldname

name of the field in question

=head2 primarykey ( fieldname )

returns or sets the primary key for the object

=head3 fieldname

The name of the field in the database

=head2 primarykeyhandle ()

Returns scalar ref to primary key of record being processed.  Used by Composite widget to get primary key of parent.  Only really useful for datasets in single mode.  Use with multiple row datasets at your own risk.

=head2 q ()

returns reference to CGI::Lazy object.

=head2 readfunc ( field )

Returns readfunction set for field in question, if any.

=head3 field

field to be tested.

=head2 readOnly ( field )

Returns true if field in question has been set to readOnly.

=head3 field

field to be tested

=head2 select ()
	
Runs select query based on $self->createSelect, fills $self->{_data}, and returns same.

If where clause is set up with bind placeholders, and select is called with bind variables as arguments, it will bind them and be safe from injection.  if called with straight up variables from the net, it will be vulnerable.  As you will.

=head2 table( tablename )
	
gets or sets the table queried
	
=head3 table
	
string.

=head2 update ( data, vars )

Updates fields in data, modified by vars

=head3 data

Hashref of data.  Each key is the primary key off a record, and the value is a hash whose keys are fieldnames and values are field contents.

=head3 vars

modifiers to data

=head2 updateadditional ()

Returns updateadditional information for recordset.

=head2 updatedefaults ()

Returns updatedefaults information for recordset

=head2 validator ( field )

Returns validator hashref for field.

=head3 field

Name of field to be tested.

=head2 verify ( value ) 

Untaints and returns true only if the given string is a field included in the database

Due to the dynamic nature of the Widget objects, it's not possible to bind all variables coming in from the web.  This is not ideal.  However, we can guard from sql injection attacks by refusing to include strings that contain characters beyond A-Za-z0-9_-, and verify that the field in question is part of your recordset.  If your database structure has special characters in its table names, go out back and hit yourself with a brick.  Shame on you.

=head2 visibleFieldLabels ()

Returns array or arrayref of labels for non-hidden fields.

=head2 visibleFields

Returns array or arrayref of field names that are not hidden

=head2 webcontrol (field)

Returns webcontrol hashref for field.

=head3 field

Name of field.

=head2 where($sql, binds)
	
Gets or sets the where clause.  If called with a single argument, argument is assumed to be sql string for the where clause.  If called with multiple args, first element is sql string, everything else is bind values.  When called without arguments, it returns whatever's been set.  This could be a single string, or an array ref, depending on how it was last called.
	
=head3 sql
	
string.

=head3 binds

list of bind vars

=head2 writefunc ( field )

Returns writefunc set for field.

=head3 field

field to be tested

=cut

