package CGI::Application::Plugin::Feedback;
use strict; 
require Exporter;
require CGI::Application;
require CGI::Application::Plugin::Session;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/; 
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;

# export ...
@ISA = qw(Exporter);
@EXPORT_OK = qw(feedback get_feedback_prepped feedback_exists get_feedback_html get_feedback_text);
%EXPORT_TAGS = (
 all =>  \@EXPORT_OK ,
);

sub import {   
   __PACKAGE__->export_to_level(1,@_,@EXPORT_OK);
}





sub feedback {
	my $self = shift;
	my $add = shift; 

   
	my $feedback = $self->session->param('feedback');   

	if ($add){
		push @{$feedback}, $add;
		$self->session->param(feedback=> $feedback);		
		return 1;
	}

	$feedback or return [];

	# clear it
	$self->session->param(feedback=> []);
	
	return $feedback;	
}


sub feedback_exists {
	my $self = shift;		
	if ( defined $self->session->param('feedback') 
      and scalar @{$self->session->param('feedback')} 
   ){
		return 1;
	}
	return 0;
}

sub get_feedback_html {
	my $self = shift;
   $self->feedback_exists or return '';

	my $html;
	for( @{$self->feedback} ){
		$html.= "<p>$_</p>";
	}
	return $html;
}

sub get_feedback_text {
	my $self = shift;
   $self->feedback_exists or return '';

	my $text = join("\n\n", @{$self->feedback} );
	return $text;
}

sub get_feedback_prepped {
	my $self = shift;
	my @prepped;
	for (@{$self->feedback}){ 
		push @prepped, { FEEDBACK => $_ };
	}
	return \@prepped;
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::Feedback - simple end user feedback method

=head1 SYNOPSIS

	use CGI::Application::Plugin::Feedback;		
		
	$self->feedback('hello.'); # now stored in session

	$self->feedback('Yawn.'); # appended as new entry

# later, whenever you want.. 4 minutes later.. in another runmode..

	$tmpl->param( FEEDBACK_LOOP => get_feedback_prepped ); # appropriate for HTML::Template loop
   # or as text
   my $feedback = $self->get_feedback_txt;

   $tmpl->param( FEEDBACK_VAR => $feedback );
   

# later still..

	$tmpl->param( FEEDBACK_LOOP => get_feedback_prepped ); # nothing.


=head1 DESCRIPTION
	
Imagine a user calls runmode rm_make_pie, which itself just makes a pie.
You want to tell the end user if it worked, if it did not, and why. And you
want to do this just about as simply as you would tell yourself when you are debugging.

This simple trinket has saved me a lot of coding time, and maintained my apps looking good,
and providing useful information to an end user.

Another example. Maybe you don't know exactly what your program will do, maybe feedback may be set
from a variety of places, you can have feedback be set by whatever, and it only shows to the user
when you call the template object output.

This plugin has helped me cut down on my runmodes tremendously.

=head1 METHODS

Methods are exported to level 1, your cgi app.

=head2 feedback()

Argument is feedback to show. If no argument is provided, feedback array ref is returned
and feedback is cleared from session.

	$self->feedback('that worked, congrats!');

If no argument, and no feedback exists, returns empty array ref [].
Each feedback entry, argument, is a string.

=head2 feedback_exists()

takes no argument. returns boolean, true or false.
unlike calling feedback() alone, it does not empty out the contents.


=head1 RETRIEVAL METHODS

Note: Calling any of these methods will automatically clear the feedback in session.

=head2 feedback()

returns array ref, will clear the feedback queue just like the following methods

=head2 get_feedback_html()

If you don't want to use a template, this subroutine will return your feedback as already formatted html.
Each entry is in a paragraph block.
If no feedback was present, returns an empty string ''

=head2 get_feedback_text()

If you don't want to use a template, or html,  this subroutine will return your feedback as simple text,
each entry is separated by two newlines.
If no feedback was present, returns an empty string ''

=head2 get_feedback_prepped()

get feedback in a loop already prepped for HTML::Template

If your remplate has:

	<TMPL_LOOP FEEDBACK>
		<p>Notice: <TMPL_VAR FEEDBACK></p>
	</TMPL_LOOP>

Then:

	my $feedback = $self->get_feedback_prepped;
	$tmpl->param('FEEDBACK'=>$feedback);

If your HTML template object is set to do not fail on missing params, then this is safe to do 
even if no feedback is present?

If no feedback is present, returns an array ref with no elements []

=head1 Example

	use CGI::Application::Plugin::Feedback ':all';	
	
	sub rm_one {
		my $self = shift;
		
		my $nextmode = (int rand 2) ? 'two' : 'three';
	
		$self->feedback('Hi there, as you call the feedback method with an string argument, ');

		$self->feedback('it gets appended, stored in the session object.');
		$self->feedback('When you ask feedback to be injected into a HTML Template, ');
		$self->feedback(' the feedback is shown and emptied from the session.');

		$self->header_type('redirect');
		$self->header_props(-url=>"?rm=$nextmode");
		return 'Redirecting..';
	}

	sub rm_two {
		my $self = shift;
		
		my $tmpl = $self->load_tmpl(undef, die_on_bad_params => 0 );		
		$tmpl->param( FEEDBACK => $self->get_feedback_prepped );
		
		return $tmpl->output;
	}


	# or how i like to code my runmodes...
	sub rm_three {
		my $self = shift;
		$self->feedback('This is runmode three, hello there.' );
		return $self->tmpl->output;		
	}

	sub tmpl {
		my $self = shift;

		unless ( defined $self->{tmpl}){
			$self->{tmpl} = $self->load_tmpl(undef, die_on_bad_params => 0 );
			$self->{tmpl}->param( FEEDBACK =>  $self->get_feedback_prepped );
		}
		return $self->{tmpl};	
	}
	

In two.html

	<TMPL_INCLUDE NAME="_feedback.html">
	
In three.html

	<TMPL_INCLUDE NAME="_feedback.html">

In _feedback.html

	<TMPL_IF FEEDBACK>
	<h2>You have feedback!</h2>
	<TMPL_LOOP FEEDBACK>
		<p>Notice: <TMPL_VAR FEEDBACK></p>
	</TMPL_LOOP>
	</TMPL_IF>


=head1 REQUIREMENTS

CGI::Application::Plugin::Session

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut

