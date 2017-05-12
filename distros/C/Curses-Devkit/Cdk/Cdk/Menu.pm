package Cdk::Menu;

@ISA	= qw (Cdk);

#
# This creates a new Menu object.
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
   my $menuList		= Cdk::checkReq ($name, "Menulist", $params{'Menulist'});
   my $menuLoc		= Cdk::checkReq ($name, "Menuloc", $params{'Menuloc'});
   my $menuPos		= Cdk::checkDef ($name, "Menupos", $params{'Menupos'}, "TOP");
   my $titleAttr	= Cdk::checkDef ($name, "Tattrib", $params{'Tattrib'}, "A_REVERSE");
   my $subTitleAttr	= Cdk::checkDef ($name, "SubTattrib", $params{'SubTattrib'}, "A_REVERSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Menu::New ($params{'Menulist'},
					$params{'Menuloc'},
					$titleAttr, $subTitleAttr, $menuPos);
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
   my $itemPicked;

   # Activatate the menu
   if (defined $params{'Input'})
   {
      $itemPicked = Cdk::Menu::Activate ($self->{'Me'}, $params{'Input'});
   }
   else
   {
      $itemPicked = Cdk::Menu::Activate ($self->{'Me'});
   }

   return if !defined $itemPicked;

   $self->{'Info'}	= $itemPicked;

   # Create the menu and submenu item values and return them.
   my $menuItem		= int($itemPicked / 100);
   my $submenuItem	= ($itemPicked % 100) + 1;
   
   # Return the two values.
   return (($menuItem, $submenuItem, $itemPicked));
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

   return (Cdk::Menu::Inject ($self->{'Me'}, $character));
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
   if (defined $params{'CurrentItem'})
   {
      Cdk::Menu::SetCurrentItem ($self->{'Me'}, $params{'CurrentItem'});
   }
   if (defined $params{'TitleHighlight'})
   {
      Cdk::Menu::SetTitleHighlight ($self->{'Me'}, $params{'TitleHighlight'});
   }
   if (defined $params{'SubTitleHighlight'})
   {
      Cdk::Menu::SetSubTitleHighlight ($self->{'Me'}, $params{'SubTitleHighlight'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Menu::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
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

   # Draw the object.
   Cdk::Menu::Draw ($self->{'Me'});
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Menu::Erase ($self->{'Me'});
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
   Cdk::Menu::Bind ($self->{'Me'}, $params{'Key'}, $params{'Function'});
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
   Cdk::Menu::PreProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Menu::PostProcess ($self->{'Me'}, $params{'Function'});
}

1;
