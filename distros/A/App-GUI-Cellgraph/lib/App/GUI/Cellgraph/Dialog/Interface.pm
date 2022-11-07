use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Dialog::Interface;
use base qw/Wx::Dialog/;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'Which Knob does what?' );

    my @lblb_pro = ( [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL );
    my $layout  = Wx::StaticText->new( $self, -1, 'The general layout of the program has three parts, which flow from the position of the drawing board.');
    my $layout1 = Wx::StaticText->new( $self, -1, '1. In the left upper corner is the drawing board - showing the result of the Harmonograph.');
    my $layout2 = Wx::StaticText->new( $self, -1, '2. The right half of the window contains the settings, which guide the drawing operation.');
    my $layout3 = Wx::StaticText->new( $self, -1, '3. The lower left side has buttons, which are mostly for storage into series of files.' );
    my $layout4 = Wx::StaticText->new( $self, -1, 'Please mind the tool tips - short help texts which appear if the mouse stands still over a button or slider.' );
    my $layout5 = Wx::StaticText->new( $self, -1, 'Also helpful are messages in the status bar at the bottom: on left regarding images and right about settings.' );
    my $layout6 = Wx::StaticText->new( $self, -1, 'When holding the Alt key you can see which Alt + letter combinations trigger which button.' );
    my $layout7 = Wx::StaticText->new( $self, -1, 'Key combinations and help in status bar can also be oserved when sliding through the menus.' );

    my $settings  = Wx::StaticText->new( $self, -1, 'The first tab of settings define the properties of the 4 pendula (X, Y, Z and R), which create the shapes.');
    my $settings1 = Wx::StaticText->new( $self, -1, 'X moves the pen left - right (on the x axis), Y moves up - down, Z does a circling movement, R = rotation.');
    my $settings2 = Wx::StaticText->new( $self, -1, 'Each pendulum has three rows of controls - first come: the on/off switch, amplitude and (amp.) damping.');
    my $settings3 = Wx::StaticText->new( $self, -1, 'Amplitudes define the size of the drawing and damping just means the drawings will get smaller with time.');
    my $settings4 = Wx::StaticText->new( $self, -1, 'The second row lets you dial in the speed (frequency) - add there decimals for more complex drawings.');
    my $settings5 = Wx::StaticText->new( $self, -1, 'The third row has switches to invert (1/x) frequency or direction and can also change the starting position.');
    my $settings6 = Wx::StaticText->new( $self, -1, '2 = 180 degree offset, 4 = 90 degree (both can be combined). The last slider adds even more offset.');
    
    my $settings7 = Wx::StaticText->new( $self, -1, 'Controls in the second tab set the properties of the pen: First how many rotations will be drawn.');
    my $settings8 = Wx::StaticText->new( $self, -1, 'Secondly the distance between dots and thirdly the dot size may also be changed for artistic purposes.');
    my $settings9 = Wx::StaticText->new( $self, -1, 'Below that are the options for colorization and has in itself three parts:');
    my $settings10 = Wx::StaticText->new( $self,-1, 'Topmost are the settings for the color change, which is set on default to "no"');
    my $settings11 = Wx::StaticText->new( $self,-1, 'In that case only the start (upper) color will be used, and not the lower end (target) color.');
    my $settings12 = Wx::StaticText->new( $self,-1, 'Both allows instant change of red, green and blue value or hue, saturation and lightness.');
    my $settings13 = Wx::StaticText->new( $self,-1, 'A one time or alternating gradient between both colors with different dynamics can be employed too.');
    my $settings14 = Wx::StaticText->new( $self,-1, 'Circular gradients travel around the rainbow through complement with saturation and lightness of the target.');
    my $settings15 = Wx::StaticText->new( $self,-1, 'Steps size refers always to how maby circles are draw before the color changes .');
    my $settings16 = Wx::StaticText->new( $self,-1, 'Rows at the bottom exchange colors between the color store (in config file) and the start and end color.');

    my $commands  = Wx::StaticText->new( $self, -1, 'Most commands, like saving and loading (especially recently used) settings are only to be found in the menu.');
    my $commands1 = Wx::StaticText->new( $self, -1, 'Image > "Save" stores the image in an arbitrary PNG, JPG or SVG file (the typed in file ending decides).');
    my $commands2 = Wx::StaticText->new( $self, -1, '"Draw" (in menu or button below image) creates the picture in full length. This might take some seconds,');
    my $commands3 = Wx::StaticText->new( $self, -1, 'if line length and dot density are high. The second button on leftis for storing series of files.');
    my $commands4 = Wx::StaticText->new( $self, -1, 'Push "Dir" to select the directory and type in directly the file base name - the index is found automatically.');
    my $commands5 = Wx::StaticText->new( $self, -1, 'Push "Save" to save the image under the path: dir + base name + index + ending (set in config) - index will ++.');
    my $commands6 = Wx::StaticText->new( $self, -1, 'Push "INI" to also save the settings of the current state under same file name with ending .ini.');
    
    $self->{'close'} = Wx::Button->new( $self, -1, '&Close', [10,10], [-1, -1] );
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->EndModal(1) });

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    my $t_attrs = &Wx::wxGROW | &Wx::wxLEFT | &Wx::wxALIGN_LEFT;
    $sizer->AddSpacer( 10 );
    $sizer->Add( $layout,          0, $t_attrs, 20 );
    $sizer->Add( $layout1,         0, $t_attrs, 40 );
    $sizer->Add( $layout2,         0, $t_attrs, 40 );
    $sizer->Add( $layout3,         0, $t_attrs, 40 );
    $sizer->Add( $layout4,         0, $t_attrs, 20 );
    $sizer->Add( $layout5,         0, $t_attrs, 20 );
    $sizer->Add( $layout6,         0, $t_attrs, 20 );
    $sizer->Add( $layout7,         0, $t_attrs, 20 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $settings,        0, $t_attrs, 20 );
    $sizer->Add( $settings1,       0, $t_attrs, 20 );
    $sizer->Add( $settings2,       0, $t_attrs, 20 );
    $sizer->Add( $settings3,       0, $t_attrs, 20 );
    $sizer->Add( $settings4,       0, $t_attrs, 20 );
    $sizer->Add( $settings5,       0, $t_attrs, 20 );
    $sizer->Add( $settings6,       0, $t_attrs, 20 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $settings7,       0, $t_attrs, 20 );
    $sizer->Add( $settings8,       0, $t_attrs, 20 );
    $sizer->Add( $settings9,       0, $t_attrs, 20 );
    $sizer->Add( $settings10,      0, $t_attrs, 20 );
    $sizer->Add( $settings11,      0, $t_attrs, 20 );
    $sizer->Add( $settings12,      0, $t_attrs, 20 );
    $sizer->Add( $settings13,      0, $t_attrs, 20 );
    $sizer->Add( $settings14,      0, $t_attrs, 20 );
    $sizer->Add( $settings15,      0, $t_attrs, 20 );
    $sizer->Add( $settings16,      0, $t_attrs, 20 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $commands,        0, $t_attrs, 20 );
    $sizer->Add( $commands1,       0, $t_attrs, 20 );
    $sizer->Add( $commands2,       0, $t_attrs, 20 );
    $sizer->Add( $commands3,       0, $t_attrs, 20 );
    $sizer->Add( $commands4,       0, $t_attrs, 20 );
    $sizer->Add( $commands5,       0, $t_attrs, 20 );
    $sizer->Add( $commands6,       0, $t_attrs, 20 );
    $sizer->Add( 0,                1, &Wx::wxEXPAND | &Wx::wxGROW);
    $sizer->Add( $self->{'close'}, 0, &Wx::wxGROW | &Wx::wxALL, 25 );
    $self->SetSizer( $sizer );
    $self->SetAutoLayout( 1 );
    $self->SetSize( 700, 700 );
    return $self;
}

1;
