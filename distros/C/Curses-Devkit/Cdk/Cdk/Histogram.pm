package Cdk::Histogram;

@ISA	= qw (Cdk);

#
# This creates a new Histogram object.
#
sub new
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";

   # Retain the type of the object.
   $self->{'Type'}	= $type;
   
   # Set up the parameters passed in.
   my $height	= Cdk::checkReq ($name, "Height", $params{'Height'});
   my $width	= Cdk::checkReq ($name, "Width", $params{'Width'});
   my $orient	= Cdk::checkReq ($name, "Orient", $params{'Orient'});
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Histogram::New ($title, $height, $width, $orient,
					$xpos, $ypos, $box, $shadow);
   bless $self;
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
   if (defined $params{'Value'})
   {
      Cdk::Histogram::SetValue ($self->{'Me'}, $params{'Low'}, $params{'High'}, $params{'Value'});
   }
   if (defined $params{'DisplayType'})
   {
      Cdk::Histogram::SetDisplayType ($self->{'Me'}, $params{'DisplayType'});
   }
   if (defined $params{'FillerChar'})
   {
      Cdk::Histogram::SetFillerChar ($self->{'Me'}, $params{'FillerChar'});
   }
   if (defined $params{'StatsPos'})
   {
      Cdk::Histogram::SetStatsPos ($self->{'Me'}, $params{'StatsPos'});
   }
   if (defined $params{'StatsAttr'})
   {
      Cdk::Histogram::SetStatsAttr ($self->{'Me'}, $params{'StatsAttr'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Histogram::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Histogram::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Histogram::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Histogram::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Histogram::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Histogram::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Histogram::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Histogram::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Histogram::SetBox ($self->{'Me'}, $params{'Box'});
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
   Cdk::Histogram::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Histogram::Erase ($self->{'Me'});
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Histogram::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Histogram::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Histogram::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Histogram::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Histogram::GetWindow ($self->{'Me'});
}

1;
