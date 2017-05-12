

package App::Guiio;

$|++ ;

use strict;
use warnings;

#-----------------------------------------------------------------------------

sub transform_elements_to_ascii_buffer
{
my ($self, @elements)  = @_ ;

return(join("\n", $self->transform_elements_to_ascii_array(@elements)) . "\n") ;
}

#-----------------------------------------------------------------------------
#GUIIO Function which will read an ASCII Art representation in its entirety and then attempt
# to reconstruct the elements of the GUIIO form
#sub build_identified_guiio_components{
#	my ($self,$ref_Identified) = @_;
#
# sub isComponent_Identified{
	# my ($self,$StartY,$StartY,$findX,$findY) = @_;
# }

# This function will tell you if a control which contains vertical components (completely scanned in or otherwise) has been 
#detected by our system, given the current x and y co-ordinates of the system
# It returns a non-negative value if found, or -1 if not found
sub is_control_exists{
	my $X = shift;
	my $Y = shift;
	my $CurState = shift;
	my $StartX = shift;
	my $StartY = shift;
	my $EndX = shift;
	my $EndY = shift;
	my $ControlType = shift;
	my $FindIndex = -1;
	if (!defined $X) { $X = 0;}
	if (!defined $Y) { $Y = 0;}
	
	if (!defined $ControlType)
	{
		die 'Did not pass in reference arrays!';
	}
	elsif (!defined $CurState)
	{
		die 'Did not cur co-ordinate or cur state!';	
	}

	my $i;
		
		END:for($i = 0 ; $i < @$StartX;$i++)
		{
			if (($X == @$StartX[$i] or $X == @$EndX[$i]) and ($Y-1) == @$EndY[$i] and @$ControlType[$i] eq $CurState)
			{
				$FindIndex = $i;
				last END;
			}
		}
	return $FindIndex;
}

sub set_detected_components
{
	my $colCount = shift;
	my $lineCount = shift;
	my $RecognizedCharacters = shift;
	my $lastState = shift;
	my $StartX = shift;
	my $EndX = shift;
	my $StartY = shift;
	my $EndY = shift;
	my $ControlType = shift;
	my $Properties = shift;

	# We should only be scanning for detected components if we are to commit a control/state to the recognized components array that is non-empty
	if (length($ControlType) > 0)
	{
	if ($lastState eq 'Label') # were we a label before this?
	{
		push(@$StartX,$colCount-length($RecognizedCharacters));
		push(@$StartY,$lineCount);
		push(@$EndX, $colCount-1);
		push(@$EndY, $lineCount);
		push(@$ControlType,'Label');
		# That character between the quotes isn't a white space but rather character 255 in the extended ASCII character set which we know won't be used with our application
		push(@$Properties,'Text ' .  $RecognizedCharacters . ' ');
	}
	elsif ($lastState eq 'Checkbox' or $lastState eq 'Optionbox')
	{
		my $controlIndex = is_control_exists(($colCount-length($RecognizedCharacters)-2),$lineCount,$lastState,\@$StartX,\@$EndX,\@$StartY,\@$EndY,\@$ControlType,\@$Properties);
		@$Properties[$controlIndex] = AddProperty(@$Properties[$controlIndex],'Text',$RecognizedCharacters);
		@$EndX[$controlIndex] = $colCount;
	}
	}
}
sub transform_ascii_string_to_elements
{
	my ($self, $input) = @_;
	my @StartY; # Start Y ordinate for identified component
	my @StartX; # Start X ordinate for identified component
	my @EndX; # End X ordinate for identified component
	my @EndY; # End Y ordinate for identified component
	my @ControlType; # Type of control identified
	my @Properties; # An array of of properties assigned to each control
	my $Property; # A string holding the key/value pairs of properties associated with the control
	
	my $lineCount = 0;
	my $colCount = 0;
	my $i  = 0; #index of the character we are currently processing
	my $RecognizedCharacters = '';
	my $lastState = '';
	my $char = '';
	my $StartX = 0;
	my @chars = split //,$input;
	
	# Iterate through the ASCII text (i.e. the $input parameter), attempting to identify components in the ASCII art, and adding/updating the identified components accordingly
	for($i=0; $i < @chars; $i++)
	{
		if ( index($input, '[ ]',$i) eq $i or index($input, '[X]',$i) eq $i or index($input, '( )',$i) eq $i or index($input, '(O)',$i) eq $i ) #handles check/option box
		{

			set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);
			$Property = '';
			push(@StartX,$colCount);
			push(@StartY,$lineCount);
			push(@EndX,$colCount);
			push(@EndY,$lineCount);
			if (index($input,'[X]',$i) eq $i){

				push(@ControlType,'Checkbox');
				push(@Properties,AddProperty($Property,'Checked',TRUE));
				$lastState = 'Checkbox';
				}
			elsif (index($input,'[ ]',$i) eq $i){
				push(@ControlType,'Checkbox');
				push(@Properties,AddProperty($Property,'Checked',FALSE));
				$lastState = 'Checkbox';
				}
			elsif (index($input,'(O)',$i) eq $i){
				push(@ControlType,'Optionbox');
				push(@Properties,AddProperty($Property,'Selected',TRUE));
				$lastState = 'Optionbox';
				}
			else{
				push(@ControlType,'Optionbox');
				push(@Properties,AddProperty($Property,'Selected',FALSE));
				$lastState = 'Optionbox';
				}
		$i +=2;
		$colCount +=2;
	
		}
		
		# elsif ( substr($input,$i) =~ m/^\*\*\*+[V|\*][A|\*][X|\*].*/s) # either top or bottom of window...
		# {
			# set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);		
			# $Property = '';

			# if (substr($input,$i) =~ m/^\*\*\*+V[A|\*][X|\*].*/s) # minimize button present - clearly top of window
			# {
				# $Property = AddProperty($Property,'Minimize',TRUE);
			# }
			# if (substr($input,$i) =~ m/^\*\*\*+[V|\*]A[X|\*].*/s) # if maximize button is present
			# {
				# $Property = AddProperty($Property,'Maximize',TRUE);
			# }
			# if (substr($input,$i) =~ m/^\*\*\*+[V|\*][A|\*]X.*/s)
			# {
				# $Property = AddProperty($Property,'Close',TRUE);
			# }
			# my $offSet = 0;
			
			# while(substr($input,$i+$offSet,1) eq '*')
			# {
				# $offSet++;
			# }
			# if (substr($input,$i+$offSet) =~ m/^[V|\*][A|\*][X|\*].*/s)
			# {
				# $offSet += 2;
			# }
			# else
			# {
				# $offSet--;
			# }
			# my $controlBegin = is_control_exists($colCount,$lineCount,'WindowBody',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
			# my $controlEnd = is_control_exists($colCount+$offSet,$lineCount,'WindowBody',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
			# my $controlHeaderBegin = is_control_exists($colCount,$lineCount,'WindowTitle',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
			# $controlHeaderEnd = is_control_exists($colCount+$offSet,$lineCount,'WindowTitle',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
			
			# if ( $controlBegin == $controlEnd and $controlBegin >= 0) #clearly this is the header of the window
				# {
					# $EndY[$controlBegin] = $lineCount;
					# $EndX[$controlBegin] = $colCount + $offSet;
					# $ControlType[$controlBegin] = 'Window';
				# }
			
			# elsif ($controlHeaderBegin == $controlHeaderEnd and $controlHeaderBegin >= 0)
			# {
				# $EndY[$controlBegin] = $lineCount;
				# $ControlType[$controlBegin] = 'WindowHeader';
			# }
			# else
			# {
				# push(@StartX,$colCount);
				# push(@StartY,$lineCount);
				# push(@EndX, $colCount+$offSet);
				# push(@EndY,$lineCount);
				# push(@ControlType, 'WindowTop');
				# push(@Properties, $Property);
				# $Property = '';
			# }
			
			# $i += $offSet;
			# $colCount += $offSet;
		# }
#		elsif (substr($input,$i) =~ m/^\*[^*]+\*.*/s and is_control_exists($colCount,$lineCount,'WindowTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) >= 0 and
#				is_control_exists(($colCount+index(substr($input,($i+1)),'*')+1),$lineCount,'WindowTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) >= 0)
#				{
#					my $controlIndex = is_control_exists($colCount,$lineCount,'WindowTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
#					
#					my $WindowTitle = substr($input,($i+1),index(substr($input,($i+1)),'*'));
#					
#					$Properties[$controlIndex] = AddProperty($Properties[$controlIndex],'Title',$WindowTitle);
#					$EndY[$controlIndex] = $lineCount;
#					$ControlType[$controlIndex] = 'WindowTitle';
#					
#					$colCount += index(substr($input,($i+1)),'*');
#				}
		elsif (substr($input,$i) eq '*') # could be either the title section of the dialog or the body separator of the dialog
		{
		}
		elsif (substr($input,$i) =~ m/^---+.*/s)
		{
			my $offSet = 0;
			set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);

			while(substr($input,$i+$offSet,1) eq '-')
			{
				$offSet++;
			}
			$offSet--;
			my $controlStartIndex = is_control_exists($colCount,$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
			my $controlEndIndex = is_control_exists($colCount+$offSet,$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType); 
			if ($controlStartIndex == $controlEndIndex and $controlStartIndex >= 0) # if header/end of button
			{
				$EndX[$controlStartIndex] = $colCount+$offSet;
				$EndY[$controlStartIndex] = $lineCount;
				$ControlType[$controlStartIndex] = 'Button';
			}
			else
			{
				push(@StartX,$colCount);
				push(@StartY,$lineCount);
				push(@EndX,$colCount+$offSet);
				push(@EndY,$lineCount);
				push(@Properties,'');
				push(@ControlType,'ButtTop');
			}
			$colCount += $offSet;
			$i += $offSet;
		}
		elsif (substr($input,$i) =~ m/^\|[^|]+\|.*/s and ((is_control_exists($colCount,$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) ==
				is_control_exists($colCount+(index(substr($input,$i+1),'|')+1),$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) and 
				is_control_exists($colCount,$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) >= 0 ) or (
				is_control_exists($colCount,$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) ==
				is_control_exists($colCount+(index(substr($input,$i+1),'|')+1),$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) and 
				is_control_exists($colCount,$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) >= 0))) 
				{
					set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);
					my $startIndex = is_control_exists($colCount,$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
					my $endIndex = is_control_exists($colCount+(index(substr($input,$i+1),'|')+1),$lineCount,'ButtTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
					
					if ($startIndex == $endIndex and $startIndex >= 0) # this is clearly the text part of the button
					{
						$EndY[$startIndex] = $lineCount;
						$Properties[$startIndex] = AddProperty($Properties[$startIndex],'Text',substr($input,($i+1),index(substr($input,$i+1),'|')));
					}
					$startIndex = is_control_exists($colCount,$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
					$endIndex = is_control_exists($colCount+index(substr($input,$i+1),'|')+1,$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
					
					if ($startIndex == $endIndex and $startIndex >= 0)
					{
						$EndY[$startIndex] = $lineCount;
						$Properties[$startIndex] = AddProperty($Properties[$startIndex],'Items',substr($input,($i+1),index(substr($input,$i+1),'|')));
					}
					$i += index(substr($input,$i+1),'|')+1;
					$colCount += index(substr($input,$i+1),'|')+1;
				}
		elsif (substr($input,$i) =~ m/^_+.*/s)
		{
				set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);
				$lastState = '';
				$RecognizedCharacters = '';
				$Property = '';
				push(@StartX,$colCount); # we  set StartX to be our current position minus one, as the control begins one before this character on the following line
				push(@StartY,$lineCount);
				push(@EndY, $lineCount);
				push(@Properties,$Property);
				push(@ControlType,'ComboHeader');
				while(substr($input,$i,1) eq '_')
				{
					$i++;
					$colCount++;
				}
				$i--;
				$colCount--;
				push(@EndX,$colCount); # we offset the last occurance of _ in that portion of the substring by 3 as the combobox infact ends after 3 characters on the following line
				$colCount--;
		}
		elsif (substr($input,$i) =~ m/^\[Combo *\|V\].*/s and is_control_exists($colCount,$lineCount,'ComboHeader',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) >= 0 and 
				is_control_exists($colCount+index(substr($input,$i),']'),$lineCount,'ComboHeader',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) >= 0 and 
				is_control_exists($colCount+index(substr($input,$i),']'),$lineCount,'ComboHeader',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType) ==
								is_control_exists($colCount,$lineCount,'ComboHeader',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType)) # found the content part of the combobox
		{
				my $controlIndex = is_control_exists($colCount,$lineCount,'ComboHeader',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
				$ControlType[$controlIndex] = 'Combobox';
				$EndY[$controlIndex] = $lineCount;
				
				$i += index(substr($input,$i),']');
				$colCount += index(substr($input,$i),']');
		}
		elsif (substr($input,$i) =~ m/^<-+>.*/s or substr($input,$i) =~ m/^\[=+\].*/s or substr($input,$i) =~ m/^=+\[\]=+.*/s or substr($input,$i) =~ m/^\[_+\].*/s) # picks up horizontal scroll bar, horizontal slider, progress bar, or textbox patterns
		{
				set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);
				$Property = '';
				push(@StartX,$colCount);
				push(@StartY,$lineCount);
				push(@EndY, $lineCount);
				push(@Properties,$Property);
				
			if (substr($input,$i) =~ m/^<-+>.*/s)
			{
				push(@EndX, $colCount+(index($input,'>',$i)-$i));
				$colCount += (index($input,'>',$i))-$i;
				$i += (index($input,'>',$i))-$i;
				push(@ControlType,'Horizontal Scroll');
			}
			elsif (substr($input,$i) =~ m/^\[=+\].*/s)
			{
				push (@EndX, $colCount+(index($input,']',$i)-$i));
				$colCount+= (index($input,']',$i))-$i;
				$i += (index($input,']',$i))-$i;
				
				push(@ControlType,'Progress Bar');
			}
			elsif (substr($input,$i) =~ m/^\[_+\].*/s) # Define textbox
			{
				push (@EndX, $colCount+(index($input,']',$i))-$i);
				$colCount+= (index($input,']',$i))-$i;
				$i += (index($input,']',$i))-$i;
				push (@ControlType, 'Textbox');
			}
			else{ # Horizontal Slider Control
				my $substr = substr($input,$i);
				$i += index ($substr,']')+1;
				$colCount += index ($substr,']')+1;
				$substr = substr($substr,index($substr,']')+1);

				# I apologize for the following section of code looking unpleasent
				# I tried using Perl's regular expression system with the pos function and after several hours
				# of research and attempts, never got it to work quite like I wanted it to (it returned the length of the string, as opposed to
				# the first character in the string where the pattern no longer matches)
				my $curSliderChar;
				my $SliderCount = 0;
				while(substr($substr,$SliderCount,1) eq '=')
				{
							$i++;
							$colCount++;
							$SliderCount++;
				}
				push (@EndX, $colCount);
				push(@ControlType,'Horizontal Slider');
			}
			$lastState = '';
			$RecognizedCharacters = '';
		}
		elsif (substr($input,$i) =~ m/^===+.*/s)
		{
			my $offSet = 0;
			
			while(substr($input,$i+$offSet,1) eq '=')
			{
				$offSet++;
			}
			$offSet--;
			my $controlStartIndex = is_control_exists($colCount,$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType);
			my $controlEndIndex = is_control_exists($colCount+$offSet,$lineCount,'ListTop',\@StartX,\@StartY,\@EndX,\@EndY,\@ControlType); 
			if ($controlStartIndex == $controlEndIndex and $controlStartIndex >= 0) # if header/end of listbox
			{
				$EndX[$controlStartIndex] = $colCount+$offSet;
				$EndY[$controlStartIndex] = $lineCount;
				$ControlType[$controlStartIndex] = 'Listbox';
				print "Listbox\n";
			}
			else
			{
				push(@StartX,$colCount);
				push(@StartY,$lineCount);
				push(@EndX,$colCount+$offSet);
				push(@EndY,$lineCount);
				push(@Properties,'');
				push(@ControlType,'ListTop');
				print "ListTop\n";
			}
			$colCount += $offSet;
			$i += $offSet;
		}
		elsif ($chars[$i] eq "\n") # If it's a new line character, then commit detected components to array, update linecount and reset state tracker
		{
			set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);			
			$RecognizedCharacters = '';
			$lastState = '';
			$colCount = -1;
			$lineCount++;
		}
		else # Some other non-recognizable character
		{
			if (length($lastState) <1){
				$lastState = 'Label';
			}
				$RecognizedCharacters = $RecognizedCharacters . $chars[$i];	
		}
		
	$colCount++;
	}
	# Capture any components that were detected before the loop terminated...
	set_detected_components($colCount,$lineCount,$RecognizedCharacters,$lastState,\@StartX,\@EndX,\@StartY,\@EndY,\@ControlType,\@Properties);
				
		#Now that we've identified the components in question, update the GUIIO surface with the identified components.  We begin
		#by finding the windows identified and adding them to the surface first, so that the window is sunk to the bottom of the form, then
		#we iterate through the identified components (minus the windows), adding the components as they should fit on the form
		for($i = 0 ; $i < @ControlType ; $i++)
		{
			if ($ControlType[$i] eq 'Window')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Window', $StartX[$i],$StartY[$i]);
				my $IsMinimize = FindProperty($Properties[$i],'Minimize');
				my $IsMaximize = FindProperty($Properties[$i],'Maximize');
				my $IsClose = FindProperty($Properties[$i],'Close');
				my $windowTitle = FindProperty($Properties[$i],'Title');
				$CurControl->setup($windowTitle,$CurControl->{TITLE},$CurControl->{BOX_TYPE},$EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{RESIZABLE},
				$CurControl->{EDITABLE},$CurControl->{AUTO_SHRINK});
			}
		}
		for($i = 0 ; $i < @ControlType ; $i++)
		{ 
			if ($ControlType[$i] ne 'Window'){
			if ($ControlType[$i] eq 'Horizontal Scroll')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Scroll Bar', $StartX[$i],$StartY[$i]);
				$CurControl->setup($CurControl->{ARROW_TYPE}, $EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{EDITABLE}) ;
			}
			elsif ($ControlType[$i] eq 'Horizontal Slider')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Slider', $StartX[$i],$StartY[$i]);
				$CurControl->setup($CurControl->{ARROW_TYPE}, $EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{EDITABLE}) ;
			
			}
			elsif ($ControlType[$i] eq 'Progress Bar')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Progress Bar', $StartX[$i], $StartY[$i]);
				$CurControl->setup($CurControl->{ARROW_TYPE}, $EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{EDITABLE});
			}
			elsif ($ControlType[$i] eq 'Label')
			{
				my $LabelText = FindPropertyValue('Text',$Properties[$i]);			
				my $textIndex = length($LabelText)-1;
				while( $textIndex >= 0 and substr($LabelText,$textIndex,1) eq ' ' and length($LabelText) > 0)
				{
					if ($textIndex >0){$LabelText = substr($LabelText,0,$textIndex-1);}
					else{$LabelText = '';}
					$textIndex--;
				}
				if (length($LabelText) > 0)
				{
					my $CurControl = $self->add_new_element_named('stencils/guiio/Label',$StartX[$i],$StartY[$i]);
					$CurControl->set_text($LabelText,'');
				}
			}
			elsif ($ControlType[$i] eq 'Combobox')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Combobox', $StartX[$i], $StartY[$i]);
				$CurControl->setup($CurControl->{TEXT_ONLY}, $CurControl->{TITLE},$CurControl->{BOX_TYPE},$EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{RESIZABLE},$CurControl->{EDITABLE},$CurControl->{AUTO_SHRINK});
			}
			elsif ($ControlType	[$i] eq 'Textbox')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Progress Bar', $StartX[$i], $StartY[$i]);
				$CurControl->setup($CurControl->{ARROW_TYPE}, $EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{EDITABLE});
			}
			elsif ($ControlType[$i] eq 'Button')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Button', $StartX[$i],$StartY[$i]);
				$CurControl->setup(FindPropertyValue('Text',$Properties[$i]),$CurControl->{TITLE},$CurControl->{BOX_TYPE},$EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{RESIZABLE},$CurControl->{EDITABLE},$CurControl->{AUTO_SHRINK});
			}
			elsif ($ControlType[$i] eq 'Listbox')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Listbox', $StartX[$i],$StartY[$i]);
				$CurControl->setup(FindPropertyValue('Items',$Properties[$i]),$CurControl->{TITLE},$CurControl->{BOX_TYPE},$EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{RESIZABLE},$CurControl->{EDITABLE},$CurControl->{AUTO_SHRINK});
			}
			elsif ($ControlType[$i] eq 'Optionbox')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Radio Button', $StartX[$i],$StartY[$i]);
				$CurControl->setup(FindPropertyValue('Text',$Properties[$i]),$CurControl->{TITLE},$CurControl->{BOX_TYPE},$EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{RESIZABLE},$CurControl->{EDITABLE},$CurControl->{AUTO_SHRINK});
				$CurControl->SetChecked(FindPropertyValue('Selected',$Properties[$i]));
			}
			elsif ($ControlType[$i] eq 'Checkbox')
			{
				my $CurControl = $self->add_new_element_named('stencils/guiio/Checkbox', $StartX[$i],$StartY[$i]);
				$CurControl->setup(FindPropertyValue('Text',$Properties[$i]),$CurControl->{TITLE},$CurControl->{BOX_TYPE},$EndX[$i]-$StartX[$i], $EndY[$i]-$StartY[$i], $CurControl->{RESIZABLE},$CurControl->{EDITABLE},$CurControl->{AUTO_SHRINK});
				$CurControl->SetChecked(FindPropertyValue('Checked',$Properties[$i]));
			}
		}
		print "\n" . $ControlType[$i] . "\n"
		}
		$self->update_display();
}
sub AddProperty{
	my($PropertyString,$PropertyName,$PropertyValue) = @_;
	$PropertyName = $PropertyName . ' ';
	
	
	#if the property already exists, append it:
	if (index($PropertyString,$PropertyName) >= 0) 
	{
		my $startIndex = index($PropertyString,$PropertyName)+length($PropertyName);
		my $length = index(substr($PropertyString,$startIndex),' ');
		my $existingValue = substr($PropertyString,$startIndex,$length);
		
		$existingValue 	=~ s/ //;
		$PropertyValue = $existingValue . "\n" . $PropertyValue . ' ';
		$PropertyString = substr($PropertyString,0,$startIndex) . $PropertyValue . substr($PropertyString,$startIndex+$length);
	}
	else
	{
		$PropertyString = $PropertyString . $PropertyName . $PropertyValue . ' ';
	}
return $PropertyString;
}
sub FindPropertyValue{
	my ($PropertyName,$PropertyString) = @_;
	$PropertyName = $PropertyName . ' ';

	my $PropertyValue = '';
	my $KeyBegin = index($PropertyString,$PropertyName)+length($PropertyName);
	my $KeyEnd = index(substr($PropertyString,$KeyBegin),' ');
	$PropertyValue = substr($PropertyString,$KeyBegin,$KeyEnd);
	return $PropertyValue;
}
sub transform_elements_to_ascii_array
{
my ($self, @elements)  = @_ ;

@elements = @{$self->{ELEMENTS}} unless @elements ;

my @lines ;

for my $element (@elements)
	{
	for my $strip ($element->get_mask_and_element_stripes())
		{
		my $line_index = 0 ;
		for my $sub_strip (split("\n", $strip->{TEXT}))
			{
			my $character_index = 0 ;
			
			for my $character (split '', $sub_strip)
				{
				my $x =  $element->{X} + $strip->{X_OFFSET} + $character_index ;
				my $y =  $element->{Y} + $strip->{Y_OFFSET} + $line_index ;
				
				$lines[$y][$x] = $character if ($x >= 0 && $y >= 0) ;
				
				$character_index ++ ;
				}
				
			$line_index++ ;
			}
		}
	}

my @ascii;

for my $line (@lines)
	{
	my $ascii_line = join('', map {defined $_ ? $_ : ' '} @{$line})  ;
	push @ascii,  $ascii_line;
	}

return(@ascii) ;
}			

#-----------------------------------------------------------------------------

1 ;