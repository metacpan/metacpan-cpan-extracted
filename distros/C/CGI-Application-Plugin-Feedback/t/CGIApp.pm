package CGIApp;
use CGI::Application::Plugin::Feedback;
use CGI::Application::Plugin::Session;
use lib './lib';
use base 'CGI::Application';

sub setup {
   my $self = shift;
   $self->start_mode('insert_feedback');
   $self->run_modes(
      show_feedback => \&show_feedback,
		insert_feedback => \&insert_feedback,
   );
   
}

sub show_feedback {
   my $self = shift;

   my $dat = rand(91000) .time();
   $self->feedback(" generated last : $dat");
   print STDERR " # generated now: $dat\n";
   return $self->get_feedback_text;
}

sub insert_feedback {
	my $self = shift;
	$self->feedback('I am inserting feedback');
	return 'Done inserting feedback..';
}


1;

