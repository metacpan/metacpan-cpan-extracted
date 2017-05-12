package Authen::Quiz;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Quiz.pm 361 2008-08-18 18:29:46Z lushe $
#
use strict;
use warnings;
use File::Spec;
use Digest::SHA1 qw/ sha1_hex /;
use Carp qw/ croak /;
use base qw/ Class::Accessor::Fast /;

eval { require YAML::Syck; };  ## no critic.
if (my $error= $@) {
	$error=~m{Can\'t\s+locate\s+YAML.+?Syck}i || die $error;
	require YAML;
	*load_quiz= sub { YAML::LoadFile( $_[0]->quiz_yaml ) };
} else {
	*load_quiz= sub { YAML::Syck::LoadFile( $_[0]->quiz_yaml ) };
}

our $VERSION = '0.05';

__PACKAGE__->mk_accessors(qw/ data_folder expire session_id session_file /);

our $QuizYaml   = 'authen_quiz.yaml';
our $QuizSession= 'authen_quiz_session.txt';

sub quiz_yaml { File::Spec->catfile( $_[0]->data_folder, $QuizYaml ) }

sub new {
	my $class = shift;
	my $option= $_[1] ? {@_}: ($_[0] || croak __PACKAGE__. ' - I want option.');
	$option->{expire}      ||= 30;  ## minute.
	$option->{data_folder} || die __PACKAGE__. " - 'data_folder' is empty.";
	$option->{data_folder}=~s{[\\\/\:]+$} [];
	$option->{session_file}=
	   File::Spec->catfile($option->{data_folder}, $QuizSession);
	-e $option->{session_file}
	   || die __PACKAGE__. " - Session file is not found. : $option->{session_file}";
	-w $option->{session_file}
	   || die __PACKAGE__. " - I want write permission to session file.";
	bless $option, $class;
}
sub question {
	my($self)= @_;
	my $quiz= $self->load_quiz;
	my $keynow= do { my @list= keys %$quiz; $list[ int( rand(@list) ) ] };
	my $data= $quiz->{$keynow}
	              || croak __PACKAGE__. " - Quiz data is empty. [$keynow]";
	   $data->[0] || croak __PACKAGE__. " - question data is empty. [$keynow]";
	   $data->[1] || croak __PACKAGE__. " - answer data is empty. [$keynow]";
	my $limit= $self->_limit_time;
	my $sha1now= $self->session_id( sha1_hex(
	   ($ENV{REMOTE_ADDR} || '127.0.0.1'). time. $$. rand(1000). $data->[0]
	   ) );
	$self->_save(sub {
		my($fh)= @_;
		my $new_session;
		for (<$fh>) {
			my($T, $sha1, $key)= $self->_parse($_);
			next if (! $T or $T< $limit);
			$new_session.= $self->_session_line($T, $sha1, $key);
		}
		truncate $fh, 0;
		seek $fh, 0, 0;
		print $fh ($new_session || '')
		        . $self->_session_line(time, $sha1now, $keynow);
	  });
	$data->[0];
}
sub check_answer {
	my $self   = shift;
	my $sid    = shift || croak __PACKAGE__. ' - I want session id.';
	my $answer = shift || croak __PACKAGE__. ' - I want answer.';
	my($quiz, $limit)= ($self->load_quiz, $self->_limit_time);
	my $result;
	$self->_save(sub {
		my($fh)= @_;
		my $new_session;
		for (<$fh>) {
			my($T, $sha1, $key)= $self->_parse($_);
			next if (! $T or $T< $limit);
			if ($sid eq $sha1) {
				if (my $data= $quiz->{$key}) {
					$result= 1 if ($data->[1] and $answer eq $data->[1]);
				}
			} else {
				$new_session.= $self->_session_line($T, $sha1, ${key});
			}
		}
		truncate $fh, 0;
		seek $fh, 0, 0;
		print $fh ($new_session || "");
	  });
	$result || 0;
}
sub remove_session {
	my $self  = shift;
	if (my $sid= shift) {
		my $limit= $self->_limit_time;
		$self->_save(sub {
			my($fh)= @_;
			my @data= <$fh>;
			truncate $fh, 0;
			seek $fh, 0, 0;
			for (@data) {
				my($T, $sha1, $key)= $self->_parse($_);
				next if (! $T or $T< $limit or $sid eq $sha1);
				print $fh $self->_session_line($T, $sha1, $key);
			}
		  });
	} else {
		$self->_save(sub { truncate $_[0], 0 });
	}
	$self;
}
sub _parse        { $_[1] ? $_[1]=~m{^(.+?)\t(.+?)\t([^\n]+)}: '' }
sub _session_line { "$_[1]\t$_[2]\t$_[3]\n" }
sub _limit_time   { time- ($_[0]->expire* 60) }
sub _save {
	my($self, $code)= @_;
	open QUIZ, "+<@{[ $self->session_file ]}"  ## no critic.
	     || die __PACKAGE__. " - File open error: @{[ $self->session_file ]}";
	flock QUIZ, 2; # write lock.
	$code->(*QUIZ);
	close QUIZ;
	$self;
}

1;

__END__

=head1 NAME

Authen::Quiz - The person's input is confirmed by setting the quiz.

=head1 SYNOPSIS

  use Authen::Quiz;
  
  my $q= Authen::Quiz->new(
    data_folder => '/path/to/authen_quiz',  ## Passing that arranges data file.
    expire      => 30,                      ## Expiration date of setting questions(amount).
    );
  
  ## Setting of quiz.
  my $question= $q->question;
  
  ## When 'question' method is called, 'session_id' is set.
  ## This value is buried under the form, and it passes it to 'check_answer' method later.
  my $session_id= $q->session_id;
  
  #
  ## Check on input answer.
  my $session_id = $cgi->param('quiz_session') || return valid_error( ..... );
  my $answer     = $cgi->param('quiz_answer')  || return valid_error( ..... );
  if ($q->check_answer($session_id, $answer)) {
    # ... is success.
  } else {
  	return valid_error( ..... );
  }

=head1 DESCRIPTION

This module sets the quiz to the input of the form, and confirms whether it is artificially done.

Recently, to take the place of it because there seemed to be a thing that the capture attestation
is broken by improving the image analysis technology, it produced it.

Moreover, I think that it can limit the user who can use the input form if the difficulty of the
quiz is adjusted.

=head2 Method of checking artificial input.

=head3 1. Setting of problem.

The problem of receiving it by the question method is displayed on the screen.

ID received by the session_id method is set in the hidden field of the input form.

=head3 2. Confirmation of input answer.

The answer input to the check_answer method as session_id of 1. is passed, and whether
it agrees is confirmed.

=head2 Preparation for quiz data of YAML form.

First of all, it is necessary to make use the quiz data of the following YAML formats.

  ---
  F01:
    - What color is the color of the apple ?
    - red
  F02:
    - What color is the color of the lemon ?
    - yellow
  F03:
    - The color of the orange and the cherry ties by '+' and is answered.
    - orange+red

'F01' etc. It is an identification name of the quiz data. Any name is not and is not 
cared about by the rule if it is a unique name.

And, the first element in ARRAY becomes the value under the control of the identification name 
and "Problem" and the second element are made to become to "Answer".

The file of the name 'authen_quiz.yaml' is made under the control of 'data_folder' 
when completing it.

=head2 Preparation for session data.

Permission that can make the empty file of the name 'authen_quiz_session.txt', and write it
from CGI script is set.

The preparation is completed by this.

Please produce the part of the WEB input form and the input confirmation according 
to this now.


=head1 METHODS

=head2 new ([OPTION_HASH])

Constructor.

HASH including the following items is passed as an option.

=over 4

=item * data_folder

Passing of place where data file was arranged.

There is no default. Please specify it.

=item * expire

The expiration date of setting questions is set in each amount.

Default is 30 minutes.

=back

  my $q= Authen::Quiz->new(
    data_folder => '/path/to/temp',
    expire      => 60,
    );

=head2 quiz_yaml

Passing the quiz data is returned.

* It is a value that returns in which $QuizYaml ties to 'data_folder'.

To change the file name, the value is set in $QuizYaml.

  $Authen::Quiz::QuizYaml = 'orign_quiz.yaml';

=head2 session_file

Passing the session data is returned.

* It is a value that returns in which $QuizSession ties to 'data_folder'.

To change the file name, the value is set in $QuizSession.

  $Authen::Quiz::QuizSession = 'orign_quiz_session.txt';

=head2 load_quiz

The quiz data of the YAML form is loaded.

  my $quiz_data= $q->load_quiz;

=head2 question

The question displayed in the input form is set.

This method sets a unique HEX value in session_id at the same time.

  my $question= $q->question;

=head2 session_id

It is made to succeed by setting the value received by this method in the hidden field of
the input form.

When the check_answer method is called, this value is needed.

  my $question   = $q->question;
  my $session_id = $q->session_id;

=head2 check_answer ([SESSION_ID], [ANSWER_STRING])

It checks whether the answer input to the form is correct.

The value received by the session_id method is passed to SESSION_ID.

The input data is passed to ANSWER_STRING as it is.

* It is a caution needed because it doesn't do Validation.

  my $session_id = validate($cgi->param('quiz_session')) || return valid_error( ..... );
  my $answer     = validate($cgi->param('quiz_answer'))  || return valid_error( ..... );
  if ($q->check_answer($session_id, $answer)) {
  	# success.
  } else {
  	return valid_error( ..... );
  }

=head2 remove_session ([SESSION_ID])

The data of the quiz session is deleted.

When SESSION_ID is omitted, all data is deleted.

  $q->session_remove( $session_id );


=head1 OTHERS

There might be a problem in the response because it reads the quiz data every time.
If the Wrapper module is made and cash is used, this can be solved.

  package MyAPP::AuthQuizWrapper;
  use strict;
  use warnings;
  use Cache::Memcached;
  use base qw/ Authen::Quiz /;
  
  sub load_quiz {
     my $cache= Cache::Memcached->new;
     $cache->get('authen_quiz_data') || do {
         my $data= $_[0]->SUPER::load_quiz;
         $cache->set('authen_quiz_data'=> $data, 600);
         data;
       };
  }
  
  1;

Or, please use L<Authen::Quiz::Plugin::Memcached>.

=head1 SEE ALSO

L<Carp>,
L<Class::Accessor::First>,
L<Digest::SHA1>,
L<File::Spec>,
L<YAML::Syck>,
L<YAML>,

L<http://egg.bomcity.com/wiki?Authen%3a%3aQuiz>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

