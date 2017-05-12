package PTest;
use base 'CGI::Application';
use CGI::Application::Plugin::Thumbnail ':all';



sub setup {
   my $self = shift;
   $self->run_modes(
      thumbnail => 'rm_thumbnail',   
   );

   $self->start_mode('thumbnail');
   
}



sub rm_thumbnail {
  my $self = shift;

   $self->thumbnail_header_add;
   
   $self->_img or warn('none via get_abs_image') and return;
      
   
   $self->abs_thumbnail or warn('no abs thumbnail returned') and return 0;
  
   
         
   return 1;
   

}




sub rm_thumbnail_via_query {
  my $self = shift;

   $self->thumbnail_header_add;
   # was an original image requested, and did it exist on disk?
   $self->get_abs_image('rel_path') or warn('none via get_abs_image') and return;
      
   # get the corresponding abs pathto the thumbnail, create if not exists
   $self->abs_thumbnail or warn('none via abs thumbnail') and return;
   
   $self->abs_thumbnail or warn('no abs thumbnail returned') and return 0;
  
   
         
   return 1;
   

}





1;


