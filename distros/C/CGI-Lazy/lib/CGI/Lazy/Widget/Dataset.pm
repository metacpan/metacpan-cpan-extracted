package CGI::Lazy::Widget::Dataset;

use strict;

use JavaScript::Minifier qw(minify);
use JSON;
use CGI::Lazy::Globals;
use Tie::IxHash;

use base qw(CGI::Lazy::Widget);

our $tableCaptionVar     = "CAPTION";
our $headingItemVar      = "HEADING.ITEM.";
our $bodyRowLoopVar      = "ROW.LOOP";
our $bodyRowName         = "ROW";
our $surroundingDivName  = "DIV.MAIN";
our $deleteID		 = "DELETE.ID";
our $deleteFlag		 = "DELETE.FLAG";
our $deletename;

#----------------------------------------------------------------------------------------
sub buildCheckbox {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	if ($webcontrol->{value}) {
		if ($value eq $webcontrol->{value}) {
			return ($webcontrol->{value}, ' checked ');
		} else {
			return ($webcontrol->{value});
		}

	} elsif ($webcontrol->{sql}) {
		my ($query, @binds) = @{$webcontrol->{sql}};
		my $lookupvalue = $self->q->db->get($query, @binds);

		if ($value eq $lookupvalue) {
			return ($lookupvalue, ' checked ');
		} else {
			return ($lookupvalue);
		}
	}
}

#----------------------------------------------------------------------------------------
sub buildHeadings {
	my $self = shift;

	$deletename = $self->vars->{deleteName} || 'Delete';
	my $headings = {};
	my $recset = $self->recordset;

	$headings->{$headingItemVar.$_}  = $recset->label($_) for $recset->visibleFields;
	$headings->{$headingItemVar."DELETE"} = $deletename unless $self->vars->{nodelete};

	return $headings;
}
	
#----------------------------------------------------------------------------------------
sub buildSelect {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	my $list = [];

	my $vals = {};
	tie %$vals, 'Tie::IxHash';

	if ($webcontrol->{values} ) {
		if (ref $webcontrol->{values} eq 'HASH') {
			$vals->{''} = '' unless $webcontrol->{notNull};
			$vals = $webcontrol->{values};
		} elsif (ref $webcontrol->{values} eq 'ARRAY') {
			$vals->{''} = '' unless $webcontrol->{notNull};
			$vals->{$_} = $_ for @{$webcontrol->{values}};
		} else {
			return;
		}


	} elsif ($webcontrol->{sql}) {
		my ($query, @binds) = @{$webcontrol->{sql}};
		$vals->{''} = '' unless $webcontrol->{notNull};
		$vals->{$_->[0]} = $_->[1] for @{$self->q->db->getarray($query, @binds)};

	}

	foreach (keys %$vals) {
		
		if ($vals->{$_} eq $value) {
			push @$list, {'ITEM.LABEL' => $_, 'ITEM.VALUE' => $vals->{$_}, 'ITEM.SELECTED' => ' selected '};

		} else {
			push @$list, {'ITEM.LABEL' => $_, 'ITEM.VALUE' => $vals->{$_}};
		}
	}

	return $list;
}

#----------------------------------------------------------------------------------------
sub buildRadio {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $webname = shift;
	my $webID  = shift;
	my $value = shift;

	my $list = [];
	my $vals = {};
	tie %$vals, 'Tie::IxHash';

	if ($webcontrol->{values} ) {

		if (ref $webcontrol->{values} eq 'HASH') {
			$vals = $webcontrol->{values};
		} elsif (ref $webcontrol->{values} eq 'ARRAY') {
			$vals->{$_} = $_ for @{$webcontrol->{values}};
		} else {
			return;
		}


	} elsif ($webcontrol->{sql} ) {
		my ($query, @binds) = @{$webcontrol->{sql}};

		$vals->{$_->[0]} = $_->[1] for @{$self->q->db->getarray($query, @binds)};

	}

	foreach (keys %$vals) {
		if ($vals->{$_} eq $value) {
			push @$list, {
				"ID.".$fieldname 		=> $webID."-$_", 
				'NAME.'.$fieldname 		=> $webname, 
				'VALUELABEL.'.$fieldname 	=> $_, 
				'VALUE.'.$fieldname 		=> $vals->{$_}, 
				'CHECKED.'.$fieldname 		=> ' checked ',
			};

		} else {
			push @$list, {
				"ID.".$fieldname 		=> $webID."-$_", 
				'NAME.'.$fieldname 		=> $webname, 
				'VALUELABEL.'.$fieldname 	=> $_,
				'VALUE.'.$fieldname 		=> $vals->{$_},
			};

		}
	}

	return $list;

}

#----------------------------------------------------------------------------------------
sub buildvalidator {
	my $self = shift;

	my $validator = {};

	foreach ( @{$self->recordset->visibleFields}) {
		if ($self->recordset->validator($_)) {
			my $rules = $self->recordset->validator($_);
			$rules->{label} = $self->recordset->label($_);
			if ($self->type eq "multi") {
				$validator->{$self->widgetID."-".$_."--".1} = $rules;
			} elsif ($self->type eq "single") {
				$validator->{$self->widgetID."-".$_} = $rules;
			}
		}
	}
	
	$self->{_validator} = $validator;
}

#----------------------------------------------------------------------------------------
sub contents {
	my $self = shift;
	my %args = @_;

        my $widgetID		= $self->widgetID;
	my $vars 		= $self->vars;
	my $template;

	if ($args{mode} eq 'readonly') {
        	$template            = $vars->{readOnlyTemplate}; #some form of template is required
	} else {
        	$template            = $vars->{template};
	}

	my $type 		= $vars->{type};
	my $multiType	 	= $vars->{multiType};
	my $containerID 	= $vars->{containerId} || $widgetID;
        my $tableCaptionValue   = $vars->{tableCaption}; 	#can be blank
        my $recset              = $vars->{recordset}; 		#required
        my $lookups             = $vars->{lookups}; 		#if this isn't set, then new records will only contain what's on the screen
        my $standalone          = $vars->{standalone};		#if set, widget will include its own open and close tags
	my $defaults 		= $vars->{defaultvalues}; 	#if this isn't set, then new records will only contain what's on the screen
	my $nodelete		= $vars->{nodelete};
	my $flagcolor		= $vars->{flagColor};
	my $headings		= $vars->{headings};

        my $formOpenTag 	= '';
        my $formCloseTag 	= '';
	my $validator 		= {};
	my $tmplvars 		= {};

	$type = 'multi' unless $type;

	if ($type eq 'single') {
		$multiType = 'list' unless $multiType;
	}

        if ($standalone) {
                $formOpenTag = $vars->{formOpenTag} || $self->q->start_form({-method => 'post', -action => $self->q->url});
                $formCloseTag = $self->q->end_form;
        }


	$recset->select(@{$args{binds}}) unless $args{mode} eq 'blank';
#	$self->q->util->debug->edump($recset->data);

	$self->{_multi} = 0;
	$self->{_empty} = scalar @{$recset->data} ? 0 : 1;;

	my $headingsdiv;

	if ($type eq 'multi') {
		if ($headings && $headings eq 'none') {

		} elsif ($headings) {
			$headingsdiv .= $self->q->template($headings)->process($self->headings);

		} else {
			$tmplvars->{$headingItemVar.$_} = $recset->label($_) for $recset->visibleFields;
			$tmplvars->{$headingItemVar."DELETE"} = $deletename unless $nodelete;
		}

		my $bodyRowLoop = [];

		my $newrecordindex = 0;

		for (my $i = 0; $i < @{$recset->data}; $i++) {
			my $row = {}; 
			my $rownum = $i + 1; 
			my $ID = $recset->data->[$i]->{$recset->primarykey};

			$row->{$bodyRowName} = $widgetID."Row".$rownum;
			$row->{$deleteID} = "$widgetID-$rownum" unless $nodelete;
			$row->{$deleteFlag} = 1 unless $nodelete;
			$row->{PRIMARYKEY} = $ID;

			foreach my $fieldname (keys %{$recset->data->[$i]}) {
				if ($recset->handle($fieldname)) { #if we've been given a handle for this field, set it
					${$recset->handle($fieldname)} = $recset->data->[$i]->{$fieldname};			
				}

				unless ($recset->hidden($fieldname)) { #don't add hidden fields
					my $webname = "$widgetID-:UPDATE:".$fieldname."-:-".$ID."::".$rownum;
					my $webID = "$widgetID-".$fieldname."--".$rownum;

					$row->{"NAME.".$fieldname} = $webname; 
					$row->{"ID.".$fieldname} = $webID;
					$row->{'LABEL.'.$fieldname} = $recset->label($fieldname) unless $recset->noLabel($fieldname);

					my $value;

					if ($recset->outputMask($fieldname)) {
						$value = sprintf $recset->outputMask($fieldname), $recset->data->[$i]->{$fieldname}; 
					} else {
						$value= $recset->data->[$i]->{$fieldname}; 
					}

					if ($recset->webcontrol($fieldname)) {
						my $webcontrol = $recset->webcontrol($fieldname);
						my $type = $webcontrol->{type};

						if ($type eq 'select') { #build variables for web controls
							$row->{"LOOP.".$fieldname} = $self->buildSelect($fieldname, $webcontrol, $value);
						} elsif ($type eq 'checkbox') {
							($row->{"VALUE.".$fieldname}, $row->{"CHECKED.".$fieldname}) = $self->buildCheckbox($fieldname, $webcontrol, $value);
						} elsif ($type eq 'radio') {
							$row->{"LOOP.".$fieldname} = $self->buildRadio($fieldname, $webcontrol, $webname, $webID, $value );
						} else {
							$row->{"VALUE.".$fieldname} = $value;
						}

					} else {
						$row->{"VALUE.".$fieldname} = $value;

					}

					if ($recset->validator($fieldname)) {
						my $rule = $recset->validator($fieldname);
						$rule->{label} = $recset->label($fieldname);
						$validator->{"$widgetID-".$fieldname."--".$rownum} =  $rule;
					}
				}
			}

			$newrecordindex = $rownum;
			push @$bodyRowLoop, $row; 
		}

		#blank record for inserts
		
		my $defaultstring = join ",", sort keys %$defaults;
		my $blankrow = {};
		$newrecordindex++;
		$blankrow->{$bodyRowName} = $widgetID."Row".$newrecordindex;
		$blankrow->{$deleteID} = "$widgetID-$newrecordindex" unless $nodelete;
		$blankrow->{$deleteFlag} = 1 unless $nodelete;
		foreach my $field ( @{$recset->visibleFields}) {
			my $webname = "$widgetID-".$field."--".$newrecordindex;
			my $webID = "$widgetID-".$field."--".$newrecordindex;

			$blankrow->{"NAME.".$field} = $webname;
			$blankrow->{"ID.".$field} = $webID;
			$blankrow->{'LABEL.'.$field} = $recset->label($field) unless $recset->noLabel($field);

			if ($recset->webcontrol($field)) {
				my $webcontrol = $recset->webcontrol($field);
				my $type = $webcontrol->{type};

				if ($type eq 'select') { #build variables for web dropdowns
					$blankrow->{"LOOP.".$field} = $self->buildSelect($field, $webcontrol);

				} elsif ($type eq 'checkbox') {
					($blankrow->{"VALUE.".$field}, $blankrow->{"CHECKED.".$field}) = $self->buildCheckbox($field, $webcontrol);

				} elsif ($type eq 'radio') {
					$blankrow->{"LOOP.".$field} = $self->buildRadio($field, $webcontrol, $webname, $webID);

				} else {
					$blankrow->{"VALUE.".$field} = '';

				}

			} else {
				$blankrow->{"VALUE.".$field} = '';
			}

			if ($recset->validator($field)) {
				my $rule = $recset->validator($field);
				$rule->{label} = $recset->label($field);
				$validator->{"$widgetID-".$field."--".$newrecordindex} = $rule;
			}
		}

		push @$bodyRowLoop, $blankrow;

		$self->{_validator} = $validator;

		$tmplvars->{$tableCaptionVar}	= $tableCaptionValue;
		$tmplvars->{$bodyRowLoopVar}	= $bodyRowLoop;
			
	} elsif ($type eq 'single')  {
		if (scalar @{$recset->data} > 1) {
			unless ($vars->{multiType} eq 'sequential') { #there are configurations where we don't want to display multi
				$self->{_multi} = 1;
				return $self->displaySingleList(%args);
			}
		} elsif (scalar @{$recset->data} == 0) {
			$self->{_empty} = 1;
		}

		my $recordnum = 0; #which record of a multiple return to display, if we're not doing displaySingleList
		
		foreach my $field (keys %{$args{vars}}) {
			if ($field eq '-recordnum') {
				$recordnum = $args{vars}->{$field};
			} elsif ($args{vars}->{$field}->{handle}) {
				my $ref = $args{vars}->{$field}->{handle};
				$$ref = $recset->data->[$recordnum]->{$field};
			}
		}

		my $ID = $recset->data->[$recordnum]->{$recset->primarykey} || '';

		if ($args{mode} eq 'blank') {
			foreach my $fieldname (keys %{$recset->fieldlist}) {
				unless ($recset->hidden($fieldname)) {
					my $webname = "$widgetID-:INSERT:".$fieldname."--";
					my $webID = "$widgetID-".$fieldname;

					$tmplvars->{'LABEL.'.$fieldname} = $recset->label($fieldname) unless $recset->noLabel($fieldname);
					$tmplvars->{'NAME.'.$fieldname} = $webname;
					$tmplvars->{"ID.".$fieldname} = $webID;

					if ($recset->webcontrol($fieldname)) {
						my $webcontrol = $recset->webcontrol($fieldname);
						my $type = $webcontrol->{type};

						if ($type eq 'select') { #build variables for web dropdowns
							$tmplvars->{"LOOP.".$fieldname} = $self->buildSelect($fieldname, $webcontrol);
						} elsif ($type eq 'checkbox') {
							($tmplvars->{"VALUE.".$fieldname}, $tmplvars->{"CHECKED.".$fieldname}) = $self->buildCheckbox($fieldname, $webcontrol);
						} elsif ($type eq 'radio') {
							$tmplvars->{"LOOP.".$fieldname} = $self->buildRadio($fieldname, $webcontrol, $webname, $webID);
						} else {

						}
					}
				}
			}
		} else {
			foreach my $fieldname (keys %{$recset->fieldlist}) {
				my $value;

				if ($recset->outputMask($fieldname)) {
					$value = sprintf $recset->outputMask($fieldname), $recset->data->[$recordnum]->{$fieldname}; 
				} else {
					$value = $recset->data->[$recordnum]->{$fieldname};
				}

				if ($recset->handle($fieldname)) { #if we've been given a handle for this field, set it
					${$recset->handle($fieldname)} = $recset->data->[$recordnum]->{$fieldname};			
				}

				unless ($recset->hidden($fieldname)) {
					my $webname = "$widgetID-:UPDATE:".$fieldname."-:-".$ID;
					my $webID = "$widgetID-".$fieldname;

					$tmplvars->{'LABEL.'.$fieldname} = $recset->label($fieldname) unless $recset->noLabel($fieldname);
					$tmplvars->{'NAME.'.$fieldname} = $webname;
					$tmplvars->{"ID.".$fieldname} = $webID;
					$tmplvars->{PRIMARYKEY} = $ID;

					if ($recset->webcontrol($fieldname)) {
						my $webcontrol = $recset->webcontrol($fieldname);
						my $type = $webcontrol->{type};

						if ($type eq 'select') { #build variables for web dropdowns
							$tmplvars->{"LOOP.".$fieldname} = $self->buildSelect($fieldname, $webcontrol, $value);
						} elsif ($type eq 'checkbox') {
							($tmplvars->{"VALUE.".$fieldname}, $tmplvars->{"CHECKED.".$fieldname}) = $self->buildCheckbox($fieldname, $webcontrol, $value);
						} elsif ($type eq 'radio') {
							$tmplvars->{"LOOP.".$fieldname} = $self->buildRadio($fieldname, $webcontrol, $webname, $webID, $value );
						} else {
							$tmplvars->{"VALUE.".$fieldname} = $value; 

						}
					} else {
						$tmplvars->{"VALUE.".$fieldname} = $value; 
					}
				}
			}
		}
	}

	foreach my $extra (keys %{$self->vars->{extravars}} ) {
		my $type = $self->vars->{extravars}->{$extra}->{type};
		if (ref $self->vars->{extravars}->{$extra}->{value} ) {
			$tmplvars->{"NAME.$extra"} = "$widgetID-$extra";
			$tmplvars->{"ID.$extra"} = "$widgetID-$extra";
			$tmplvars->{"VALUE.$extra"} = ${$self->vars->{extravars}->{$extra}->{value}};
		} else {
			$tmplvars->{"NAME.$extra"} = "$widgetID-$extra";
			$tmplvars->{"ID.$extra"} = "$widgetID-$extra";
			$tmplvars->{"VALUE.$extra"} = $self->vars->{extravars}->{$extra}->{value};
		}
	}

	my $divopen = $args{nodiv} ? '' : "<div id='$widgetID'>";
	my $divclose = $args{nodiv} ? '' : "</div>";
	$validator = $self->q->jswrap("var ".$self->widgetID ."Validator = ".to_json($self->validator).";");
	my $primarykey = $self->recordset->primarykey;

	my $searchObjectName = $self->widgetID.'SearchObject';

	my $searchObject = to_json([map {$widgetID."-".$_} @{$recset->visibleFields}]);

	my $jsvalidatorname = $widgetID."Validator";
	my $jscontrollername = $widgetID."Controller";
	my $jsmultisearchname = $widgetID."MultiSearchPrimaryKey";

	my $javascript = <<END;
		var $jscontrollername = new datasetController('$widgetID', $jsvalidatorname, '$containerID', $searchObject, '$flagcolor');
		var $jsmultisearchname = '$primarykey';
END

	if ($javascript) {
		$javascript = minify(input => $javascript) unless $self->q->config->noMinify;
	}

	my $js = $self->q->jswrap($javascript);

	return $headingsdiv.
		$divopen.
		$validator.
		$js.
		$formOpenTag.
		$self->q->template($template)->process($tmplvars).
		$formCloseTag.
		$divclose;
}

#----------------------------------------------------------------------------------------
sub display {
	my $self = shift;
	my %args = @_;

 	my $preloadLookup = $self->preloadLookup;
	
	return $preloadLookup.
		$self->contents(%args);
}

#----------------------------------------------------------------------------------------
sub displaySingleList {
	my $self = shift;
	my %args = @_;

        my $standalone 		= $self->vars->{standalone};
	my $formOpenTag 	= '';
	my $formCloseTag 	= '';
        my $widgetID		= $self->vars->{id};
	my $recset 		= $self->recordset;
	my @fieldlist 		= $recset->multipleFieldList;
	my @labels 		= $recset->multipleFieldLabels;

        my $surroundingDivName	= "DIV.MAIN";
        my $tableCaptionVar   	= "CAPTION";
        my $headingItemVar   	= "HEADING.ITEM.";
        my $bodyRowLoopVar    	= "ROW.LOOP";
        my $bodyRowName       	= "ROW";
	
	if ($standalone) {
		$formOpenTag = $self->vars->{formOpenTag} || $self->q->start_form({-method => 'post', -action => $self->q->url});
		$formCloseTag = $self->q->end_form;
	}

	my $bodyRowLoop = [];

	my $primarykey = $recset->primarykey;

	foreach my $record (@{$recset->data}) {
		my $row = {};
		my $ID = $record->{$primarykey} || '';

		foreach my $field (keys %{$record}) {
			if ($recset->multipleField($field)) {
				$row->{PRIMARYKEY} = $ID;

				if ($recset->webcontrol($field)) {
					my $webcontrol = $recset->webcontrol($field);
					my $type = $webcontrol->{type};

					if ($type eq 'select') { #build variables for web dropdowns
						$row->{"VALUE.".$field} = "<a href= \"javascript:$widgetID"."Controller.multiSearch('$ID');\">".
							$self->singleListSelect($field, $webcontrol, $record->{$field}).
							"</a>";
						
					} elsif ($type eq 'checkbox') {
						$row->{"VALUE.".$field} = "<a href= \"javascript:$widgetID"."Controller.multiSearch('$ID');\">".
							$self->singleListCheckbox($field, $webcontrol, $record->{$field}).
							"</a>";
					} elsif ($type eq 'radio') {
						$row->{"VALUE.".$field} = "<a href= \"javascript:$widgetID"."Controller.multiSearch('$ID');\">".
						$self->singleListRadio($field, $webcontrol, $record->{$field}).
							"</a>";
					} else {
						$row->{"VALUE.".$field} = "<a href= \"javascript:$widgetID"."Controller.multiSearch('$ID');\">".$record->{$field}."</a>";
					}

				} else {
					$row->{"VALUE.".$field} = "<a href= \"javascript:$widgetID"."Controller.multiSearch('$ID');\">".$record->{$field}."</a>";

				}
			}
		}

		push @$bodyRowLoop, $row;
	}

	my $tmplvars = {
		$bodyRowLoopVar	=> $bodyRowLoop,

	};

	$tmplvars->{$headingItemVar.$_} = $recset->label($_) for $recset->multipleFieldList;

	my $divopen = $args{nodiv} ? '' : "<div id='$widgetID"."Multi'>";
	my $divclose = $args{nodiv} ? '' : "</div>";

	return $divopen.
		$formOpenTag.
		$self->q->template($self->vars->{multipleTemplate})->process($tmplvars).
		$formCloseTag.
		$divclose;
}

#----------------------------------------------------------------------------------------
sub empty {
	my $self = shift;

	return $self->{_empty};
}

#----------------------------------------------------------------------------------------
sub headings {
	my $self = shift;

	return $self->{_headings};
}

#----------------------------------------------------------------------------------------
sub multi {
	my $self = shift;

	return $self->{_multi};
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;
	my $vars = shift;
	
	unless (ref $vars->{recordset} eq 'CGI::Lazy::DB::RecordSet') {
		$vars->{recordset} = $q->db->recordset($vars->{recordset});
	}

	my $self = {
			_q 		=> $q,
			_vars 		=> $vars, 
			_recordset	=> $vars->{recordset},
			_type 		=> $vars->{type}, 
			_multiType 	=> $vars->{multiType}, 
			_widgetID 	=> $vars->{id},
	};

	bless $self, $class;

#	$q->util->debug->edump($self->recordset);

	$self->{_headings} = $self->buildHeadings;

	$self->buildvalidator;
	
	return $self;
}

#----------------------------------------------------------------------------------------
sub searchResults {
	my $self = shift;
	my %args = @_;

	my $html = $self->rawContents(%args);

	my $outgoing = '{"validator" : '.$self->validator.', "html" : "'.$html.'"}';    

	return $outgoing;
}

#----------------------------------------------------------------------------------------
sub singleListCheckbox {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	if ($webcontrol->{value}) {
		if ($value eq $webcontrol->{value}) {
			return 'yes';
		} else {
			return 'no';
		}

	} elsif ($webcontrol->{sql}) {
		my ($query, @binds) = @{$webcontrol->{sql}};
		my $lookupvalue = $self->q->db->get($query, @binds);

		if ($value eq $lookupvalue) {
			return 'yes';
		} else {
			return 'no';
		}
	}
}

#----------------------------------------------------------------------------------------
sub singleListRadio {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	my $list = [];
	my $vals = {};
	tie %$vals, 'Tie::IxHash';

	if ($webcontrol->{values} ) {

		if (ref $webcontrol->{values} eq 'HASH') {
			$vals = $webcontrol->{values};
		} elsif (ref $webcontrol->{values} eq 'ARRAY') {
			$vals->{$_} = $_ for @{$webcontrol->{values}};
		} else {
			return;
		}


	} elsif ($webcontrol->{sql} ) {
		my ($query, @binds) = @{$webcontrol->{sql}};

		$vals->{$_->[0]} = $_->[1] for @{$self->q->db->getarray($query, @binds)};

	}

	foreach (sort keys %$vals) {
		if ($vals->{$_} eq $value) {
			return  $_;

		}
	}

}

#----------------------------------------------------------------------------------------
sub singleListSelect {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	my $list = [];

	my $vals = {};
	tie %$vals, 'Tie::IxHash';

	if ($webcontrol->{values} ) {
		if (ref $webcontrol->{values} eq 'HASH') {
			$vals->{''} = '' unless $webcontrol->{notNull};
			$vals = $webcontrol->{values};
		} elsif (ref $webcontrol->{values} eq 'ARRAY') {
			$vals->{''} = '' unless $webcontrol->{notNull};
			$vals->{$_} = $_ for @{$webcontrol->{values}};
		} else {
			return;
		}


	} elsif ($webcontrol->{sql}) {
		my ($query, @binds) = @{$webcontrol->{sql}};
		$vals->{''} = '' unless $webcontrol->{notNull};
		$vals->{$_->[0]} = $_->[1] for @{$self->q->db->getarray($query, @binds)};

	}

	foreach (keys %$vals) {
		if ($vals->{$_} eq $value) {
#			return $vals->{$_};
			return $_;
		} 
	}
}

#----------------------------------------------------------------------------------------
sub type {
	my $self = shift;

	return $self->{_type};
}

#----------------------------------------------------------------------------------------
sub vars {
	my $self = shift;

	return $self->{_vars};

}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Widget::Dataset

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



	my $widget = $q->widget->dataset({

				id		=> 'detailBlock',

				type		=> 'multi',

				template	=> "lazydemoDetailBlock.tmpl",

				headings 	=> {
							template 	=> 'pathwidgetheader.tmpl',

							id		=> 'pathwidgetheader',
						},

	#					nodelete	=> 1,

				lookups		=> {

						prodcodeLookup  => {

							sql 		=> 'select ID, description from prodCodeLookup', 

							preload 	=> 1,

							orderby		=> ['ID'],

							output		=> 'hash',

							primarykey	=> 'ID',

						},

							

				},

				recordset	=> $q->db->recordset({

							table		=> 'detail', 

							fieldlist	=> [

										{name => 'detail.ID', 

											hidden => 1},

										{name => 'invoiceid', 

											hidden => 1},

										{name => 'prodCode', 

											label => 'Product Code', 

											validator => {rules => ['/\d+/'], msg => 'number only, and is required'}},

										{	name 		=> 'quantity', 

											label 		=> 'Quantity', 

											validator 	=> {rules => ['/\d+/'], msg => 'number only, and is required'},

											outputMask	=> "%.1f",

										},

										{name => 'unitPrice', 

											label 		=> 'Unit Price' , 

											validator 	=> {rules => ['/\d+/'], msg => 'number only, and is required'},

											inputMask	=> "%.1f",

											},

										{name => 'productGross', 

											label => 'Product Gross' , 

											validator => {rules => ['/\d+/'], msg => 'number only, and is required'}},

										{name => 'prodCodeLookup.description', 

											label => 'Product Description', 

											readOnly => 1 },

										], 

							where 		=> '', 

							joins		=> [

										{type => 'inner', table	=> 'prodCodeLookup', field1 => 'prodCode', field2 => 'prodCodeLookup.ID',},

							],

							orderby		=> 'detail.ID', 

							primarykey	=> 'detail.ID',

				}),
		});

	$q->template->boilerplate($widget)->buildTemplates();		#use a boilerplate object to create template stubs in the buildDir.

=head1 DESCRIPTION

CGI::Lazy::Widget::Dataset is, at present, the crown jewel of the CGI::Lazy framework, and the chief reason why the framework was written.  Lazy was written because the author has been asked to write front ends to simple databases so often that he started to realize he was writing the same damn code over and over again, and finally got sick of it.

When we're talking about web-based access to a database, there really aren't many operations that we are talking about performing.  It all comes down to Select, Insert, Update, and Delete (and Ignore- but more on that later).  From the standpoint of the database, it doesn't matter what the data is pertaining to, it could be cardiac patients, or tootsie rolls- the data is still stored in tables, rows and fields, and no matter what you need to read it, modify it, extend it, or destroy it.

The Dataset is designed to, given a set of records, defined by a CGI::Lazy::DB::Recordset object, display that recordset to the screen in whatever manner you like (determined by template and css)  and then keep track of the data.  It's smart enough to know if a record was retrieved from the db, and therefore should be updated or deleted, or if it came from the web, it must be inserted (or ignored, if it was created clientside, and then subsequently deleted clientside- these records will show on the screen, but will be ignored on submit).

Furthermore, as much of the work as possible is done clientside to cut down on issues caused by network traffic.  It's using AJAX and JSON, but there's no eval-ing.  All data is passed into the browser as JSON, and washed though a JSON parser. 

To do its magic, the Dataset relies heavily on javascript that *should* work for Firefox and IE6.  At the time of publication, all functions and methods work flawlessly with FF2, FF3, and IE6.  The author has tried to write for W3C standards, and provide as much IE support as his corporate sponsors required.  YMMV.  Bug reports are always welcome, however we will not support IE to the detrement of W3C standards.  Get on board M$.


The API for Lazy, Recordset, and Dataset allows for hooking simple widgets together to generate not-so-simple results, such as pages with Parent/Child 1 to Many relationships between the Datasets.  CGI::Lazy::Composite is a wrapper designed to connect Widgets, especially Datasets, together.  The Javascript and the Widget templates are highly dependent on each other, and are rather complex.  In order to prevent any user (including the author) from having to write them by hand, the CGI::Lazy::Template::Boilerplate object will create a basic, boring, no nonsense template to start from.  It won't be the most fancy piece of web automation on the planet, but it will be functional, and can be tweaked to your heart's content.


=head1 METHODS


=head2 contents (args)

Generates widget contents based on args.

=head3 args

Hash of arguments.  Common args are mode => 'blank', for displaying a blank data entry form, and nodiv => 1, for sending the contents back without the surrounding div tags (javascript replaces the contents of the div, and we don't want to add another div of the same name inside the div).


=head2 display (args)

Displays the widget.  Calls $self->contents, and adds preload lookups and instance specific javascript that will not be updated on subsequent ajax calls.  Print the return value of this method to STDOUT within a cgi or mod_perl handler.

=head3 args

Hash of arguments

=head2 displaySingleList (args)

Handler for displaying data when a search returns multiple records.  Displays multipleTemplate rather than template.

=head3 args

Hash of arguments.


=head2 empty ()

Returns the empty property.  Property gets set when a search returns nothing.


=head2 multi ()

Returns multi property.  Multi gets set when a search returns more than one record.


=head2 new (q, vars)

Constructor.

=head3 q

CGI::Lazy object.

=head3 vars

Hashref of object configs.

	class			=> widget class name (lowercase, just as if you were calling $q->widget->$classname)  (only necessary if creating widgets automatically, such as members of a Composite widget)

	id			=> widget id 			(mandatory)
	
	type			=> widget type			(mandatory)  'single' or 'multi'

	template		=> standard template		(mandatory)

	multipleTemplate 	=> multiple template		(mandatory if your searches could ever return multiple results)

	headings		=> 'none'			No headings displayed on a multi dataset.  If it's anyting other than 'none' its assumed to be the name of a template

	headings		=> 'template name'		template to use for headings.  Integral div tags assumed.  

	recordset		=> CGI::Lazy::RecordSet		(mandatory)  Can pre-make recordset and pass object reference, or just pass hashref with recordset's particulars, and it'll get created on the fly.

	flagColor		=> color to flag fields that fail validation (defaults to red)   (optional)

	lookups			=> 				(optional)

		countryLookup =>	name of lookup 

			sql 		=> sql

			preload 	=> 1 (0 means no preload, will have to be run via ajax)

			orderby		=> order by clause

			output		=> type of output (see CGI::Lazy::DB)

			primarykey	=> primary key

	extravars		=>  Extra variables to be output to template	(optional)  		

				name	=> name of variable

					value => variable, string, or reference

=cut

