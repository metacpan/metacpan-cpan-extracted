package CGI::Application::Tutorial::Namegame;
use base 'CGI::Application';
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Feedback ':all';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Forward;
use strict;
use warnings;
use Carp;

sub setup {
   my $self = shift;
   $self->start_mode('choose_name');
}

sub choose_name : Runmode {
   my $self = shift;
   $self->_detect_name_change_request;

   my $q = $self->query;
   my $html = 
        $q->start_html
      . $self->_nav
      . $q->h1('Choose Name')
      . $q->start_form
      . $q->textfield('name')
      . $q->submit('save')
      . $q->end_form
      . $q->end_html;

   return $html;  
}


sub show_verse : Runmode {
   my $self = shift;   
   $self->_detect_name_change_request;

   my $name = $self->_get_name_chosen
      or return $self->forward('choose_name');   


   require Lingua::EN::Namegame;

   my $verse = Lingua::EN::Namegame::name2verse($name)
      or $self->feedback("Sorry, cannot generate verse for [$name]")
      and $self->session->clear('name')
      and return $self->forward('choose_name');
      
   my $q = $self->query;   
   my $html = 
        $q->start_html
      . $self->_nav
      . $q->h1('Your Verse:')
      . $q->pre($verse)
      . $q->end_html;

   return $html;   
}



sub _detect_name_change_request {
   my $self = shift;
     
   my $name = $self->query->param('name');
   defined $name or return 0;   

   $name=~/^\w+$/
      or $self->feedback('Your "name" input sucks.')
      and $self->feedback('Try again.')
      and return 0;

   $self->session->param( name => $name );
   $self->session->flush;
   $self->feedback("Ok, name choice saved for [$name].");
   return 1;
}



sub _get_name_chosen {
   my $self = shift;
   my $name = $self->session->param('name');
   defined $name
      or $self->feedback('no name chosen yet')
      and return;
      
   return $name;
}



sub _nav {
   my $self = shift;
   
   my $navetc = 
        $self->query->p(q{<a href="?rm=choose_name">Choose Name</a>})
      . $self->query->p(q{<a href="?rm=show_verse">Show Verse</a>})
      . $self->get_feedback_html;

   return $navetc;   
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Tutorial::Namegame - example of how to use plugins with cgiapps

=head1 DESCRIPTION

This is example code meant to illustrate more advanced usage of CGI::Application

=head1 SEE ALSO

CGI::Application::Plugin::AutoRunmode
CGI::Application::Plugin::Session
CGI::Application::Plugin::Feedback
CGI::Application::Plugin::Forward
CGI::Application
Lingua::EN::Namegame

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
