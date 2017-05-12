package Cdk::Matrix;

@ISA	= qw (Cdk);

#
# This creates a new Matrix object.
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
   my $rowtitles = Cdk::checkReq ($name, "RowTitles", $params{'RowTitles'});
   my $coltitles = Cdk::checkReq ($name, "ColTitles", $params{'ColTitles'});
   my $colwidths = Cdk::checkReq ($name, "ColWidths", $params{'ColWidths'});
   my $coltypes	= Cdk::checkReq ($name, "ColTypes",  $params{'ColTypes'});
   my $vrows	= Cdk::checkReq ($name, "Vrows", $params{'Vrows'});
   my $vcols	= Cdk::checkReq ($name, "Vcols", $params{'Vcols'});
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $rowSpace	= Cdk::checkDef ($name, "RowSpace", $params{'RowSpace'}, 1);
   my $colSpace	= Cdk::checkDef ($name, "ColSpace", $params{'ColSpace'}, 1);
   my $filler	= Cdk::checkDef ($name, "Filler", $params{'Filler'}, ".");
   my $dominant = Cdk::checkDef ($name, "Dominant", $params{'Dominant'}, "NONE");
   my $box	= Cdk::checkDef ($name, "BoxMatrix", $params{'BoxMatrix'}, "FALSE");
   my $boxCell	= Cdk::checkDef ($name, "BoxCell", $params{'BoxCell'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Matrix::New ($title, 
					$params{'RowTitles'},
					$params{'ColTitles'},
					$params{'ColWidths'},
					$params{'ColTypes'},
					$vrows, $vcols,
					$xpos, $ypos,
					$rowSpace, $colSpace,
					$filler, $dominant,
					$boxCell, $box, $shadow);
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

   # Activate the matrix.
   return (Cdk::Matrix::Activate ($self->{'Me'}));
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

   return (Cdk::Matrix::Inject ($self->{'Me'}, $character));
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
   if (defined $params{'Values'})
   {
      Cdk::Matrix::Set ($self->{'Me'}, $params{'Values'});
   }
   if (defined $params{'Cell'})
   {
      Cdk::Matrix::SetCell ($self->{'Me'}, $params{'Row'}, $params{'Col'}, $params{'Value'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Matrix::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Matrix::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Matrix::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Matrix::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Matrix::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Matrix::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Matrix::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Matrix::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Matrix::SetBox ($self->{'Me'}, $params{'Box'});
   }
}

#
# This allows the user to clean the matrices cell values.
#
sub clean
{
   my $self	= shift;
   my $name	= "$self->{'Type'}::clean";
   Cdk::Matrix::Clean ($self->{'Me'});
}

#
# This allows the user to dump the matrices cell values.
#
sub dump
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::flush";
   my $title	= $params{'Title'}	|| "No Title";

   # Call the function that does this.
   Cdk::Matrix::Dump ($self->{'Me'}, $title);
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
   Cdk::Matrix::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Matrix::Erase ($self->{'Me'});
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Matrix::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Matrix::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Matrix::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Matrix::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Matrix::GetWindow ($self->{'Me'});
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
   Cdk::Matrix::PreProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Matrix::PostProcess ($self->{'Me'}, $params{'Function'});
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

   Cdk::Matrix::Bind ($self->{'Me'}, $params{'Key'}, $params{'Function'});
}
1;
