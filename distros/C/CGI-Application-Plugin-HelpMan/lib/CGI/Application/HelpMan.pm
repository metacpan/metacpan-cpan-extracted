package CGI::Application::HelpMan;
use base 'CGI::Application';
use CGI::Application::Plugin::TmplInnerOuter;
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Feedback ':all';
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::HelpMan ':all';
#$CGI::Application::Plugin::TmplInnerOuter::DEBUG = 1;

sub setup {
   my $self = shift;
   $self->start_mode('help_search');
}

sub help : Runmode {
   my $self = shift;
   
   $self->_set_tmpl_default(q{
      <h1><TMPL_VAR HELP_TITLE></h1>      
      <div>
      <TMPL_VAR HELP_BODY>
      </div>
   });

    $self->_set_vars(
      HELP_TITLE => $self->hm_help_title,
      HELP_BODY  => $self->hm_help_body,
   );

   return $self->tmpl_output;  
}

sub help_view : Runmode {
   my $self = shift;

   unless( $self->hm_found_term_query ){
      $self->feedback("What do you want to search for?");
      return $self->forward('help_search');
   }

   $self->feedback(sprintf "You searched for [%s]", $self->hm_term_get );

   my $abs;

   unless( $self->hm_found_term_abs ){
      $self->feedback( sprintf "Sorry, I can't find [%s]", $self->hm_term_get );
      return $self->forward('help_search');
   }

   unless( $self->hm_found_term_doc ) {
      $self->feedback( sprintf "Sorry, no doccumentation in [%s]", $self->hm_term_get );
      return $self->forward('help_search');
   }

   unless( $self->hm_doc_body ) {
      $self->feedback( sprintf "Sorry, cant get out the doccumentation for [%s]", $self->hm_term_get );
      return $self->forward('help_search');
   }


   $self->_set_tmpl_default(q{
      <h1><TMPL_VAR HELP_TITLE></h1>      
      <div>
      <TMPL_VAR HELP_BODY>
      </div>
   });


   $self->_set_vars(
      HELP_TITLE => $self->hm_doc_title,
      HELP_BODY  => $self->hm_doc_body,
   );

   return $self->tmpl_output;  
}


sub help_search : Runmode {
   my $self = shift;
   
   $self->_set_tmpl_default(q{
   <h1>Search Help</h1>
   <form>
   <input type="text" name="query">
   <input type="hidden" name="rm" value="help_view">
   <input type="submit" value="search">
   </form>
   });   

   return $self->tmpl_output;
}


sub tmpl_output {
   my $self = shift;

   $self->_set_tmpl_default(q{
   <html>
   <head><title><TMPL_VAR PAGE_TITLE></title></html></head>   
   <body>
   
   <div><a href="?rm=help_search">new search</a> : <a href="?rm=help">help</a></div>
   
   <div>
   <TMPL_LOOP FEEDBACK>
      <p><TMPL_VAR FEEDBACK></p>
   </TMPL_LOOP>
   </div>
   
   <div><TMPL_VAR BODY></div>
   </body>
   </html>},'main.html');
   
   $self->_set_vars( FEEDBACK => $self->get_feedback_prepped );

   $self->_feed_vars_all;
   $self->_feed_merge;
   return $self->_tmpl_outer->output;
}



1;



=pod

=head1 NAME

CGI::Application::HelpMan - look up system perl pod docs

=head1 DESCRIPTION

The application lets you look up documentation on this system.

For developer API, please see L<CGI::Application::Plugin::HelpMan>.

=head1 SCREENS

=head2 NEW SEARCH 

Here you can enter a query to look up.
Enter the text in the box and click on search.
At any moment you can click on 'new search' to search something else.

=head2 HELP

Shows this screen.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

L<CGI::Application::Plugin::HelpMan>
L<CGI::Application::Plugin::Feedback>
L<CGI::Application::Plugin::Session>
L<CGI::Application::Plugin::AutoRunmode>
L<CGI::Application::Plugin::Forward>
L<CGI::Application::Plugin::TmplInnerOuter>
L<CGI::Application>

=cut


