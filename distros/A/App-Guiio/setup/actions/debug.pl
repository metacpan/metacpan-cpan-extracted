
use List::Util qw(min max sum) ;

#----------------------------------------------------------------------------------------------

register_action_handlers
	(
	'Dump self' => ['CA0-d', \&dump_self],
	'Dump all elements' => ['C00-d', \&dump_all_elements],
	'Dump selected elements'=> ['C0S-D' , \&dump_selected_elements],
	'Test' => ['0A0-t',  \&test],
	) ;


#----------------------------------------------------------------------------------------------

sub dump_self
{
my ($self) = @_ ;

my $size = sum(map { length } @{$self->{DO_STACK}}) || 0 ;

local $self->{DO_STACK} = scalar(@{$self->{DO_STACK}})  . " [$size]";
	
#~ print Data::TreeDumper::DumpTree $self ;
$self->show_dump_window($self, 'guiio') ;
}

#----------------------------------------------------------------------------------------------

sub dump_selected_elements
{
my ($self) = @_ ;

#~ print Data::TreeDumper::DumpTree [$self->get_selected_elements(1)] ;
$self->show_dump_window([$self->get_selected_elements(1)], 'guiio selected elements') ;
}

#----------------------------------------------------------------------------------------------

sub dump_all_elements
{
my ($self) = @_ ;

#~ print Data::TreeDumper::DumpTree $self->{ELEMENTS} ;
$self->show_dump_window($self->{ELEMENTS}, 'guiio elements') ;
}

#----------------------------------------------------------------------------------------------

sub test
{
my ($self) = @_ ;

$self->create_undo_snapshot() ;

#~ use Text::FIGlet ;
#~ my $font = Text::FIGlet->new(-f=>'doh');
#~ my $font = Text::FIGlet->new(-d=>'/usr/share/figlet/');
#~ my $output = $font->figify(-A=>"Test");

#~ use App::Guiio::stripes::editable_box2 ;
#~ my $new_element = new App::Guiio::stripes::editable_box2
				#~ ({
				#~ TEXT_ONLY => $output,
				#~ TITLE => '',
				#~ EDITABLE => 1,
				#~ RESIZABLE => 1,
				#~ }) ;

#~ $self->add_element_at($new_element, $self->{MOUSE_X}, $self->{MOUSE_Y}) ;


use App::Guiio::stripes::section_wirl_arrow ;
my $new_element = new App::Guiio::stripes::section_wirl_arrow
					({
					POINTS => [[5, 5, 'downright']],
					DIRECTION => '',
					ALLOW_DIAGONAL_LINES => 0,
					EDITABLE => 1,
					RESIZABLE => 1,
					NOT_CONNECTABLE_START => 1,
					NOT_CONNECTABLE_END => 1,
					}) ;
					
$self->add_element_at($new_element, $self->{MOUSE_X}, $self->{MOUSE_Y}) ;

$self->update_display() ;
}

