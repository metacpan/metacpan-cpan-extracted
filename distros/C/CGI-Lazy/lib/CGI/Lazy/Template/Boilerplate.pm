package CGI::Lazy::Template::Boilerplate;

use strict;

use CGI::Lazy::Globals;

our $datasetMultipleStartBegin = <<END;
<table id="__WIDGETID__Table">
	<caption> <tmpl_var name="CAPTION"> </caption> 
	<tr> <!-- even if you don't use this row, leave it here, or pushRow will break -->
END

our $datasetMultipleHDR = <<END;
		<th> 
			<tmpl_var name='HEADING.ITEM.__FIELDNAME__'> 
		</th> 

END

our $datasetMultipleStartEnd = <<END;
	</tr> 
	<tmpl_loop name='ROW.LOOP'> 
		<tr id="<tmpl_var name="ROW">"> 

END

our $tdPrototypeMultiText = <<END;
				<td> 
					<input 
						type="text"  
						name="<tmpl_var name='NAME.__FIELDNAME__'>" 
						value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
						id="<tmpl_var name='ID.__FIELDNAME__'>" 
						onchange="__WIDGETID__Controller.unflag(this);__WIDGETID__Controller.pushRow(this);" 
					/> 
				</td> 
END

our $tdPrototypeMultiSelect = <<END;
				<td> 
					<select 
						name="<tmpl_var name='NAME.__FIELDNAME__'>" 
						id="<tmpl_var name='ID.__FIELDNAME__'>" 
						onchange="__WIDGETID__Controller.unflag(this);__WIDGETID__Controller.pushRow(this);" 
					/> 
						<tmpl_loop name="LOOP.__FIELDNAME__"> 
							 <option value="<tmpl_var name="ITEM.VALUE">" <tmpl_var name="ITEM.SELECTED">> <tmpl_var name="ITEM.LABEL"> </option> 
						</tmpl_loop> 
					</select> 
				</td> 
END

our $tdPrototypeMultiCheckbox = <<END;
				<td> 
					<input 
						type="checkbox" 
						<tmpl_var name='CHECKED.__FIELDNAME__'> 
						name="<tmpl_var name='NAME.__FIELDNAME__'>" 
						value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
						id="<tmpl_var name='ID.__FIELDNAME__'>" 
						onchange="__WIDGETID__Controller.unflag(this); __WIDGETID__Controller.pushRow(this);" 
					/> 
				</td> 
END

our $tdPrototypeMultiRadio = <<END;
				<td> 
					<tmpl_loop name="LOOP.__FIELDNAME__"> 
						<tmpl_var name='VALUELABEL.__FIELDNAME__'> 
						<input 
							type="radio" 
							<tmpl_var name='CHECKED.__FIELDNAME__'> 
							name="<tmpl_var name='NAME.__FIELDNAME__'>" 
							value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
							id="<tmpl_var name='ID.__FIELDNAME__'>" 
							onchange="__WIDGETID__Controller.unflag(this);__WIDGETID__Controller.pushRow(this);" 
						/> 
					</tmpl_loop> 
				</td>

END

our $tdPrototypeMultiRO = <<END;
				<td> 
					<tmpl_var name='VALUE.__FIELDNAME__'> 
				</td> 
END

our $tdPrototypeSingleMulti = <<END;
				<td> 
					<tmpl_var name='VALUE.__FIELDNAME__'> 
				</td> 
END

our $tdPrototypeSingleText = <<END;
		<td> 
			<input  
				type="text" 
				name="<tmpl_var name='NAME.__FIELDNAME__'>" 
				value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
				id="<tmpl_var name='ID.__FIELDNAME__'>" 
				onchange="__WIDGETID__Controller.unflag(this);"  
			/> 
		</td> 
END

our $tdPrototypeSingleRadio = <<END;
 		<td> 
                        <tmpl_loop name="LOOP.__FIELDNAME__"> 
                                <tmpl_var name='VALUELABEL.__FIELDNAME__'> 
                                <input 
                                        type="radio" 
                                        <tmpl_var name='CHECKED.__FIELDNAME__'> 
                                        name="<tmpl_var name='NAME.__FIELDNAME__'>" 
                                        value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
                                        id="<tmpl_var name='ID.__FIELDNAME__'>" 
                                        onchange="__WIDGETID__Controller.unflag(this);" 
                                /> 
                        </tmpl_loop> 
                </td> 

END

our $tdPrototypeSingleCheckbox = <<END;
		<td> 
			<input 
				type="checkbox" 
				<tmpl_var name="CHECKED.__FIELDNAME__"> 
				name="<tmpl_var name='NAME.__FIELDNAME__'>"  
				value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
				id="<tmpl_var name='ID.__FIELDNAME__'>" 
				onchange="__WIDGETID__Controller.unflag(this);" 
			/> 
		</td> 
END

our $tdPrototypeSingleSelect = <<END;
		<td> 
			<select 
				name="<tmpl_var name='NAME.__FIELDNAME__'>" 
				id="<tmpl_var name='ID.__FIELDNAME__'>" 
				onchange="__WIDGETID__Controller.unflag(this);" 
			> 
				<tmpl_loop name="LOOP.__FIELDNAME__"> 
					<option value="<tmpl_var name="ITEM.VALUE">" <tmpl_var name="ITEM.SELECTED"> > <tmpl_var name="ITEM.LABEL"> </option> 
				</tmpl_loop> 

			</select> 
		</td> 
END

our $tdPrototypeSingleRO = <<END;
		<td> 
			<tmpl_var name='VALUE.__FIELDNAME__'> 
		</td> 
END

our $datasetDeleteTd = <<END;
				<tmpl_if name="DELETE.FLAG"> 
				<td> 
					<input  
						type = 'checkbox'  
						tabindex=-1  
						id = "<tmpl_var name = 'DELETE.ID'>"  
						onclick="__WIDGETID__Controller.deleteRow(this);" 
					> 
				</td> 
				</tmpl_if> 
END

our $datasetMultipleEnd = <<END;
		</tr> 
	</tmpl_loop> 
</table> 
END

our $cssClean = <<END;
div#__WIDGETID__ {

}

END

our $datasetSingleStart = <<END;
<table id="__WIDGETID__.table">
END

our $datasetSingleRowStart = <<END;
	<tr> 
END

our $datasetSingleLableTd = <<END;
		<td 
			id="__FIELDNAME__Label"> 
			<tmpl_var name="LABEL.__FIELDNAME__"> 
		</td> 
END

our $datasetSingleRowEnd = <<END;
	</tr> 

END

our $datasetSingleEnd = <<END;
		
</table> 

END

our $datasetMultipleHeaderStart = <<END;
<div id="__WIDGETID__HDR"> 
	<table> 
		<caption> <tmpl_var name="CAPTION"> </caption> 
		<tr> 

END

our $datasetMultipleHeaderDeleteTd = <<END;
			<th>  
				<tmpl_var name="HEADING.ITEM.DELETE">  
			</th> 

END

our $datasetMultipleHeaderEnd = <<END;
		</tr> 


	</table> 
</div> 


END

our $controllerStart = <<END;
<table>
	<tr>

END

our $controllerEnd = <<END;
	</tr>
</table>

END

our $tdPrototypeControllerSelect = <<END;
				<td> 
					<select 
						name="<tmpl_var name='NAME.__FIELDNAME__'>" 
						id="<tmpl_var name='ID.__FIELDNAME__'>" 
						onchange="__WIDGETID__Controller.select();" 
					/> 
						<tmpl_loop name="LOOP.__FIELDNAME__"> 
							 <option value="<tmpl_var name="ITEM.VALUE">" <tmpl_var name="ITEM.SELECTED">> <tmpl_var name="ITEM.LABEL"> </option> 
						</tmpl_loop> 
					</select> 
				</td> 
END

our $tdPrototypeControllerCheckbox = <<END;
				<td> 
					<input 
						type="checkbox" 
						<tmpl_var name='CHECKED.__FIELDNAME__'> 
						name="<tmpl_var name='NAME.__FIELDNAME__'>" 
						value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
						id="<tmpl_var name='ID.__FIELDNAME__'>" 
						onchange="__WIDGETID__Controller.select();" 
					/> 
				</td> 
END

our $tdPrototypeControllerRadio = <<END;
				<td> 
					<tmpl_loop name="LOOP.__FIELDNAME__"> 
						<tmpl_var name='VALUELABEL.__FIELDNAME__'> 
						<input 
							type="radio" 
							<tmpl_var name='CHECKED.__FIELDNAME__'> 
							name="<tmpl_var name='NAME.__FIELDNAME__'>" 
							value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
							id="<tmpl_var name='ID.__FIELDNAME__'>" 
							onchange="__WIDGETID__Controller.select();" 
						/> 
					</tmpl_loop> 
				</td>

END

our $tdPrototypeControllerText = <<END;
				<td> 
					<input 
						type="text"  
						name="<tmpl_var name='NAME.__FIELDNAME__'>" 
						value="<tmpl_var name='VALUE.__FIELDNAME__'>" 
						id="<tmpl_var name='ID.__FIELDNAME__'>" 
						onchange="__WIDGETID__Controller.select();" 
					/> 
				</td> 
END

#--------------------------------------------------------------------------------------------
sub buildTmplController {
	my $self = shift;

	my $tmpl = $controllerStart;

	foreach my $control (@{$self->controls}) {
		my $type = $control->{type};

		if ($type eq 'select') { 
			$tmpl .= $self->parse4FieldAndID($control->{name}, $tdPrototypeControllerSelect);
		} elsif ($type eq 'checkbox') {
			$tmpl .= $self->parse4FieldAndID($control->{name}, $tdPrototypeControllerCheckbox);
		} elsif ($type eq 'radio') {
			$tmpl .= $self->parse4FieldAndID($control->{name}, $tdPrototypeControllerRadio);
		} else {
			$tmpl .= $self->parse4FieldAndID($control->{name}, $tdPrototypeControllerText);
		}
	}
	
	$tmpl .= $controllerEnd;

	return $self->outputTmpl($tmpl, 'Controller');
}

#--------------------------------------------------------------------------------------------
sub buildTmplDatasetMultiple {
	my $self = shift;

	my $tmpl = $self->parse4ID($datasetMultipleStartBegin);
	$tmpl .= $self->parse4Field($_, $datasetMultipleHDR) for $self->widget->recordset->visibleFields;
	$tmpl .= $datasetMultipleStartEnd;
	
	foreach my $fieldname (@{$self->fieldlist}) {
		if ($self->widget->recordset->webcontrol($fieldname)) {
			my $webcontrol = $self->widget->recordset->webcontrol($fieldname);
			my $type = $webcontrol->{type};

			if ($type eq 'select') { 
				$tmpl .= $self->parse4FieldAndID($fieldname, $tdPrototypeMultiSelect);
			} elsif ($type eq 'checkbox') {
				$tmpl .= $self->parse4FieldAndID($fieldname, $tdPrototypeMultiCheckbox);
			} elsif ($type eq 'radio') {
				$tmpl .= $self->parse4FieldAndID($fieldname, $tdPrototypeMultiRadio);
			} else {
				$tmpl .= $self->parse4FieldAndID($fieldname, $tdPrototypeMultiText);
			}
		} else {
			$tmpl .= $self->parse4FieldAndID($fieldname, $tdPrototypeMultiText);
		}
	}

	$tmpl .= $self->parse4ID($datasetDeleteTd);
	$tmpl .= $self->parse4ID($datasetMultipleEnd);

	$self->outputTmpl($tmpl);
}

#--------------------------------------------------------------------------------------------
sub buildTmplDatasetMultipleHeadings {
	my $self = shift;

	my $tmpl = $self->parse4ID($datasetMultipleHeaderStart);
	$tmpl .= $self->parse4Field($_, $datasetMultipleHDR) for @{$self->fieldlist};
	$tmpl .= $self->parse4ID($datasetMultipleHeaderDeleteTd);
	$tmpl .= $self->parse4ID($datasetMultipleHeaderEnd);

	$self->outputTmpl($tmpl, 'HDR');
}

#--------------------------------------------------------------------------------------------
sub buildTmplDatasetMultipleRO {
	my $self = shift;

	my $tmpl = $self->parse4ID($datasetMultipleStartBegin);
	$tmpl .= $self->parse4Field($_, $datasetMultipleHDR) for $self->widget->recordset->visibleFields;
	$tmpl .= $datasetMultipleStartEnd;
	$tmpl .= $self->parse4FieldAndID($_, $tdPrototypeMultiRO) for @{$self->fieldlist};
	$tmpl .= $self->parse4ID($datasetMultipleEnd);

	$self->outputTmpl($tmpl, 'RO');
}

#--------------------------------------------------------------------------------------------
sub buildTmplDatasetSingle {
	my $self = shift;

	my $widgetID 	= $self->widgetID;
	my $fieldlist 	= $self->fieldlist;
	my $fields 	= scalar @$fieldlist;
	my $rows 	= ($fields / 5 == int $fields) ? $fields / 5 : int $fields / 5 + 1;

	my $tmpl = $self->parse4ID($datasetSingleStart);

	my $field = 0;
	for (my $i = 0; $i < $rows; $i++) {
		my $column = 0;
		$tmpl .= $datasetSingleRowStart;
		while ($column < 6) {
			if ($fieldlist->[$field]) {
				$tmpl .= $self->parse4Field($fieldlist->[$field], $datasetSingleLableTd);

				if ($self->widget->recordset->webcontrol($fieldlist->[$field])) {
					my $webcontrol = $self->widget->recordset->webcontrol($fieldlist->[$field]);
					my $type = $webcontrol->{type};

					if ($type eq 'select') { 
						$tmpl .= $self->parse4Field($fieldlist->[$field], $self->parse4ID($tdPrototypeSingleSelect));
					} elsif ($type eq 'checkbox') {
						$tmpl .= $self->parse4Field($fieldlist->[$field], $self->parse4ID($tdPrototypeSingleCheckbox));
					} elsif ($type eq 'radio') {
						$tmpl .= $self->parse4Field($fieldlist->[$field], $self->parse4ID($tdPrototypeSingleRadio));
					} else {
						$tmpl .= $self->parse4Field($fieldlist->[$field], $self->parse4ID($tdPrototypeSingleText));
					}
				} else {
					$tmpl .= $self->parse4Field($fieldlist->[$field], $self->parse4ID($tdPrototypeSingleText));
				}
			}
			$column++;
			$field++;
		}

		$tmpl .= $datasetSingleRowEnd;

	}

	$tmpl .= $self->parse4ID($datasetSingleEnd);

	$self->outputTmpl($tmpl);
}

#--------------------------------------------------------------------------------------------
sub buildTmplDatasetSingleRO {
	my $self = shift;

	my $widgetID 	= $self->widgetID;
	my $fieldlist 	= $self->fieldlist;
	my $fields 	= scalar @$fieldlist;
	my $rows 	= ($fields / 5 == int $fields) ? $fields / 5 : int $fields / 5 + 1;

	my $tmpl = $self->parse4ID($datasetSingleStart);

	my $field = 0;
	for (my $i = 0; $i < $rows; $i++) {
		my $column = 0;
		$tmpl .= $datasetSingleRowStart;
		while ($column < 6) {
			if ($fieldlist->[$field]) {
				$tmpl .= $self->parse4Field($fieldlist->[$field], $datasetSingleLableTd);
				$tmpl .= $self->parse4Field($fieldlist->[$field], $self->parse4ID($tdPrototypeSingleRO));
			}
			$column++;
			$field++;
		}

		$tmpl .= $datasetSingleRowEnd;

	}

	$tmpl .= $self->parse4ID($datasetSingleEnd);

	$self->outputTmpl($tmpl, 'RO');
}

#--------------------------------------------------------------------------------------------
sub buildTmplDatasetSingleMulti {
	my $self = shift;

	my $tmpl = $self->parse4ID($datasetMultipleStartBegin);
	$tmpl .= $self->parse4Field($_, $datasetMultipleHDR) for $self->widget->recordset->multipleFieldList;
	$tmpl .= $datasetMultipleStartEnd;
	$tmpl .= $self->parse4Field($_, $tdPrototypeSingleMulti) for @{$self->fieldlist};
	$tmpl .= $self->parse4ID($datasetMultipleEnd);

	$self->outputTmpl($tmpl, 'Multi');
}
#--------------------------------------------------------------------------------------------
sub buildTemplates {
	my $self = shift;
	
	if ($self->{_composite} ) {
		$_->buildTemplates foreach (@{$self->{_members}});
		return;
	}

	if ($self->type eq 'Dataset-single') {
		$self->buildTmplDatasetSingle;
		$self->buildTmplDatasetSingleMulti;
		$self->buildTmplDatasetSingleRO;

	} elsif ($self->type eq 'Dataset-multi') {
		$self->buildTmplDatasetMultiple;
		$self->buildTmplDatasetMultipleRO;
		$self->buildTmplDatasetMultipleHeadings;

	} elsif ($self->type eq 'Controller') {
		$self->buildTmplController;

	}

	return;
}

#--------------------------------------------------------------------------------------------
sub controls {
	my $self = shift;

	return $self->{_controls};
}

#--------------------------------------------------------------------------------------------
sub fieldlist {
	my $self = shift;

	return $self->{_fieldlist};
}

#--------------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $template = shift;
	my $widget = shift;


	die "Boilerplate called with no widget!" unless $widget;


	my $self = {
		_template		=> $template,
		_widget			=> $widget,
	};

	if (ref $widget eq 'CGI::Lazy::Widget::Dataset') {
		$self->{_widgetID}	= $widget->widgetID;
		$self->{_fieldlist}	= $widget->recordset->visibleFields;
		$self->{_type}		= 'Dataset-'.$widget->type;
		$self->{_style}		= $widget->vars->{style};

	} elsif (ref $widget eq 'CGI::Lazy::Widget::Controller') {
		$self->{_widgetID}	= $widget->widgetID;
		$self->{_type}		= 'Controller';
		$self->{_controls}	= $widget->controls;
	
	} elsif (ref $widget eq 'CGI::Lazy::Widget::Composite') {
		$self->{_widgetID}	= $widget->widgetID;
		$self->{_composite} 	= 1;

		foreach (@{$widget->memberarray}) {
			push @{$self->{_members}}, $template->boilerplate($_);
		}
	}


	return bless $self, $class;
}

#--------------------------------------------------------------------------------------------
sub output {
	my $self = shift;
	my $text = shift;
	my $type = shift;
	my $extra = shift;

	my $filename = $self->widgetID;
	$filename .= $extra if $extra;
	$filename .=".$type";

	my $file = $self->q->config->buildDir."/".$filename;

	open OF, "+> $file" or die "Couldn't open $file for writing: $!";
	print OF $text;
	close OF;
}

#--------------------------------------------------------------------------------------------
sub outputTmpl {
	my $self = shift;
	my $text = shift;
	my $type = shift;

	$self->output($text, "tmpl", $type);
}

#--------------------------------------------------------------------------------------------
sub parse4ID {
	my $self = shift;
	my $text = shift;
	
	my $widgetID = $self->widgetID;

	$text =~ s/__WIDGETID__/$widgetID/gs;

	return $text;
}

#--------------------------------------------------------------------------------------------
sub parse4Field {
	my $self 	= shift;
	my $fieldname	= shift;
	my $text 	= shift;

	$text =~ s/__FIELDNAME__/$fieldname/gs;

	return $text;
}

#--------------------------------------------------------------------------------------------
sub parse4FieldAndID {
	my $self 	= shift;
	my $fieldname	= shift;
	my $text 	= shift;

	$text = $self->parse4Field($fieldname, $text);
	$text = $self->parse4ID($text);

	return $text;
}

#--------------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->template->q;
}

#--------------------------------------------------------------------------------------------
sub style {
	my $self = shift;

	return $self->{_style};
}

#--------------------------------------------------------------------------------------------
sub template {
	my $self = shift;

	return $self->{_template};
}

#--------------------------------------------------------------------------------------------
sub type {
	my $self = shift;

	return $self->{_type};
}

#--------------------------------------------------------------------------------------------
sub widget {
	my $self = shift;

	return $self->{_widget};
}

#--------------------------------------------------------------------------------------------
sub widgetID {
	my $self = shift;

	return $self->{_widgetID};
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

CGI::Lazy::Template::BoilerPlate

=head1 SYNOPSIS
	
	use CGI::Lazy;

	my $q = CGI::Lazy->new({...});
	
	my $widget = $q->ajax->dataset({...});

	my $b = $q->template->boilerplate($widget);

	$b->buildTemplates;


=head1 DESCRIPTION

CGI::Lazy::Template::Boilerplate is a module to generate boilerplate template examples for Lazy widgets.  The templates generated can then be customized to do whatever you want, and look like whatever you want.  Some pieces of template syntax might be confusing to users of Lazy, so this will generate a nice starting point for you.

The template directory must be writeable by whatever user Apache is configured to run as, at least for as long as you're generating boilerplate templates.

=head1 METHODS

=head2 buildTemplates ()

Builds a set of templates appropriate for widget given.

=cut

