package Cdk::Buttonbox;
require "flush.pl";

@ISA	= qw (Cdk);

#
# This creates a new Buttonbox object.
#
sub new
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";

   # Retain the type of the object.
   $self->{'Type'} = $type;
   
   # Set up the parameters passed in.
   my $buttons	= Cdk::checkReq ($name, "Buttons", $params{'Buttons'});
   my $rows	= Cdk::checkReq ($name, "Rows", $params{'Rows'});
   my $cols	= Cdk::checkReq ($name, "Cols", $params{'Cols'});
   my $height	= Cdk::checkReq ($name, "Height", $params{'Height'});
   my $width	= Cdk::checkReq ($name, "Width", $params{'Width'});
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $hlight	= Cdk::checkDef ($name, "Highlight", $params{'Highlight'}, "A_REVERSE");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Buttonbox::New ($title, $params{'Buttons'},
					$rows, $cols,
					$height, $width,
					$xpos, $ypos,
					$hlight, $box, $shadow);
   bless $self;
}

#
# This activates the object
#
sub activate
{
   my $self		= shift;
   my %params		= @_;
   my $name		= "$self->{'Type'}::activate";

   # Activate the object...
   if (defined $params{'Input'})
   {
      $self->{'Info'} = Cdk::Buttonbox::Activate ($self->{'Me'}, $params{'Input'});
   }
   else
   {
      $self->{'Info'} = Cdk::Buttonbox::Activate ($self->{'Me'});
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

   return (Cdk::Buttonbox::Inject ($self->{'Me'}, $character));
}

#
# This sets several parameters of the widget.
#
sub set
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::set";

   #
   # Check the parameters sent in.
   #
   if (defined $params{'Highlight'})
   {
      Cdk::Buttonbox::SetHighlight ($self->{'Me'}, $params{'Highlight'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Buttonbox::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Buttonbox::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Buttonbox::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Buttonbox::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Buttonbox::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Buttonbox::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Buttonbox::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Buttonbox::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Buttonbox::SetBox ($self->{'Me'}, $params{'Box'});
   }
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
   Cdk::Buttonbox::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Buttonbox::Erase ($self->{'Me'});
}

#
# This allows us to bind a key to an action.
#
sub bind
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::bind";

   # Set up the parameters passed in.
   my $key = Cdk::checkReq ($name, "Key", $params{'Key'});
   my $function = Cdk::checkReq ($name, "Function", $params{'Function'});
   
   # Bind the key to the function
   Cdk::Buttonbox::Bind ($self->{'Me'}, $key, $function);
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
   Cdk::Buttonbox::PreProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Buttonbox::PostProcess ($self->{'Me'}, $params{'Function'});
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Buttonbox::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Buttonbox::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Buttonbox::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Buttonbox::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Buttonbox::GetWindow ($self->{'Me'});
}

1;
