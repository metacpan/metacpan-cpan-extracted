package Cdk::Calendar;

#
# This creates a new Calendar object
#
sub new
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";

   # Retain the type of the object.
   $self->{'Type'}	= $type;
   
   # Get today's date.
   my ($today, $thisMonth, $thisYear) = (localtime(time))[3,4,5];
   $thisMonth++;
   $thisYear += 1900;

   # Set up the parameters passed in.
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $day	= Cdk::checkDef ($name, "Day", $params{'Day'}, $today);
   my $month	= Cdk::checkDef ($name, "Month", $params{'Month'}, $thisMonth);
   my $year	= Cdk::checkDef ($name, "Year", $params{'Year'}, $thisYear);
   my $dAttrib	= Cdk::checkDef ($name, "Dattrib", $params{'Dattrib'}, "A_NORMAL");
   my $mAttrib	= Cdk::checkDef ($name, "Mattrib", $params{'Mattrib'}, "A_NORMAL");
   my $yAttrib	= Cdk::checkDef ($name, "Yattrib", $params{'Yattrib'}, "A_NORMAL");
   my $hlight	= Cdk::checkDef ($name, "Highlight", $params{'Highlight'}, "A_REVERSE");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Calendar::New ($title, $day, $month, $year,
					$dAttrib, $mAttrib, $yAttrib,
					$hlight, $xpos, $ypos, $box, $shadow);
   bless $self;
}

#
# This activates the object.
#
sub activate
{
   my $self             = shift;
   my %params           = @_;
   my $name             = "$self->{'Type'}::activate";

   # Activate the object...
   if (defined $params{'Input'})
   {
      $self->{'Info'} = Cdk::Calendar::Activate ($self->{'Me'}, $params{'Input'});
   }
   else
   {
      $self->{'Info'} = Cdk::Calendar::Activate ($self->{'Me'});
   }
   return ($self->{'Info'});
}

#
# This injects a character into the widget.
#
sub inject
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::inject";

   # Set the values.
   my $character = Cdk::checkReq ($name, "Input", $params{'Input'});

   return (Cdk::Calendar::Inject ($self->{'Me'}, $character));
}

#
# This allows us to bind a key to an action.
#
sub bind
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::bind";
 
   # Set the values.
   my $key = Cdk::checkReq ($name, "Key", $params{'Key'});
   my $function	= Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Calendar::Bind ($self->{'Me'}, $key, $params{'Function'});
}

#
# This allows us to set a pre-process function.
#
sub preProcess
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::preProcess";
 
   # Set the values.
   my $function = Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Calendar::PreProcess ($self->{'Me'}, $params{'Function'});
}

#
# This allows us to set a post-process function.
#
sub postProcess
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::postProcess";
 
   # Set the values.
   my $function = Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Calendar::PostProcess ($self->{'Me'}, $params{'Function'});
}

#
# This draws the object.
#
sub draw
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::draw";

   # Set up the parameters passed in.
   my $box = Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   
   # Draw the object.
   Cdk::Calendar::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Calendar::Erase ($self->{'Me'});
}

#
# This sets the object...
#
sub set
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::set";

   # Get today's date.
   my ($today, $thisMonth, $thisYear) = (localtime(time))[3,4,5];
   $thisMonth ++;
   $thisYear += 1900;

   # Set up the parameters passed in.
   my $day = Cdk::checkDef ($name, "Day", $params{'Day'}, $today);
   my $month = Cdk::checkDef ($name, "Month", $params{'Month'}, $thisMonth);
   my $year = Cdk::checkDef ($name, "Year", $params{'Year'}, $thisYear);
   my $dAttrib = Cdk::checkDef ($name, "Dattrib", $params{'Dattrib'}, "</16/B>");
   my $mAttrib = Cdk::checkDef ($name, "Mattrib", $params{'Mattrib'}, "</24/B>");
   my $yAttrib = Cdk::checkDef ($name, "Yattrib", $params{'Yattrib'}, "</32/B>");
   my $highlight = Cdk::checkDef ($name, "Highlight", $params{'Highlight'}, "</40/B>");
   my $box = Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");

   Cdk::Calendar::Set ($self->{'Me'}, $day, $month, $year, 
			$dAttrib, $mAttrib, $yAttrib, $box);
}

#
# This sets the calendar to a given date.
#
sub setDate
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::setDate";

   # Set up the parameters passed in.
   my $day = Cdk::checkDef ($name, "Day", $params{'Day'}, -1);
   my $month = Cdk::checkDef ($name, "Month", $params{'Month'}, -1);
   my $year = Cdk::checkDef ($name, "Year", $params{'Year'}, -1);

   Cdk::Calendar::SetDate ($self->{'Me'}, $day, $month, $year);
}

#
# This gets the current date on the given calendar.
#
sub getDate
{
   my $self = shift;
   return (Cdk::Calendar::GetDate ($self->{'Me'}));
}

#
# This sets a marker in the calendar widget.
#
sub setMarker
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::setMarker";

   # Set up the parameters passed in.
   my $day = Cdk::checkReq ($name, "Day", $params{'Day'});
   my $month = Cdk::checkReq ($name, "Month", $params{'Month'});
   my $year = Cdk::checkReq ($name, "Year", $params{'Year'});
   my $marker = Cdk::checkDef ($name, "Marker", $params{'Marker'}, "A_REVERSE");

   Cdk::Calendar::SetMarker ($self->{'Me'}, $day, $month, $year, $marker);
}

#
# This removes a marker from the calendar widget.
#
sub removeMarker
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::removeMarker";

   # Set up the parameters passed in.
   my $day = Cdk::checkReq ($name, "Day", $params{'Day'});
   my $month = Cdk::checkReq ($name, "Month", $params{'Month'});
   my $year = Cdk::checkReq ($name, "Year", $params{'Year'});

   Cdk::Calendar::RemoveMarker ($self->{'Me'}, $day, $month, $year);
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Calendar::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Calendar::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Calendar::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Calendar::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Calendar::GetWindow ($self->{'Me'});
}

1;
