
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------

my ($slides, $current_slide) ;

#----------------------------------------------------------------------------------------------

sub load_slides
{
my ($self) = @_ ;

# get file name for slides definitions
my  $file_name = $self->get_file_name('open') ;

# load slides
$slides = do $file_name or die $@ ;
$current_slide = 0 ;

# run first slide
$slides->[$current_slide]->($self) ;
$self->update_display() ;

}

#----------------------------------------------------------------------------------------------

sub first_slide
{
my ($self) = @_ ;

if($slides)
	{
	$current_slide = 0 ;
	$slides->[$current_slide]->($self) ;
	$self->update_display() ;
	}
}

#----------------------------------------------------------------------------------------------

sub next_slide
{
my ($self) = @_ ;

if($slides && $current_slide != $#$slides)
	{
	$current_slide++ ;
	$slides->[$current_slide]->($self) ;
	$self->update_display() ;
	}
}

#----------------------------------------------------------------------------------------------

sub previous_slide
{
my ($self) = @_ ;

if($slides && $current_slide != 0)
	{
	$current_slide-- ;
	$slides->[$current_slide]->($self) ;
	$self->update_display() ;
	}
}

#----------------------------------------------------------------------------------------------

