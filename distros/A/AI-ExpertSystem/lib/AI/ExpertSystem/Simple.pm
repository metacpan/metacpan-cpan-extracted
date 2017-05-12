package AI::ExpertSystem::Simple;

use strict;
use warnings;

use XML::Twig;

use AI::ExpertSystem::Simple::Rule;
use AI::ExpertSystem::Simple::Knowledge;
use AI::ExpertSystem::Simple::Goal;

our $VERSION = '1.2';

sub new {
	my ($class) = @_;

	die "Simple->new() takes no arguments" if scalar(@_) != 1;

	my $self = {};

	$self->{_rules} = ();
	$self->{_knowledge} = ();
	$self->{_goal} = undef;
	$self->{_filename} = undef;

	$self->{_ask_about} = undef;
	$self->{_told_about} = undef;

	$self->{_log} = ();

	$self->{_number_of_rules} = 0;
	$self->{_number_of_attributes} = 0;
	$self->{_number_of_questions} = 0;

	return bless $self, $class;
}

sub reset {
	my ($self) = @_;

	die "Simple->reset() takes no arguments" if scalar(@_) != 1;

	foreach my $name (keys %{$self->{_rules}}) {
		$self->{_rules}->{$name}->reset();
	}

	foreach my $name (keys %{$self->{_knowledge}}) {
		$self->{_knowledge}->{$name}->reset();
	}

	$self->{_ask_about} = undef;
	$self->{_told_about} = undef;
	$self->{_log} = ();
}

sub load {
	my ($self, $filename) = @_;

	die "Simple->load() takes 1 argument" if scalar(@_) != 2;
	die "Simple->load() argument 1 (FILENAME) is undefined" if !defined($filename);

	if(-f $filename and -r $filename) {
		my $twig = XML::Twig->new(
			twig_handlers => { goal => sub { $self->_goal(@_) },
					   rule => sub { $self->_rule(@_) },
					   question => sub { $self->_question(@_) } }
		);

		$twig->safe_parsefile($filename);

		die "Simple->load() XML parse failed: $@" if $@;

		$self->{_filename} = $filename;

		$self->_add_to_log( "Read in $filename" );
		$self->_add_to_log( "There are " . $self->{_number_of_rules} . " rules" );
		$self->_add_to_log( "There are " . $self->{_number_of_attributes} . " attributes" );
		$self->_add_to_log( "There are " . $self->{_number_of_questions} . " questions" );
		$self->_add_to_log( "The goal attibutes is " . $self->{_goal}->name() );
		return 1;
	} else {
		die "Simple->load() unable to use file";
	}
}

sub _goal {
	my ($self, $t, $node) = @_;

	my $attribute = undef;
	my $text = undef;

	my $x = ($node->children('attribute'))[0];
	$attribute = $x->text();

	$x = ($node->children('text'))[0];
	$text = $x->text();

	$self->{_goal} = AI::ExpertSystem::Simple::Goal->new($attribute, $text);

	eval { $t->purge(); }
}

sub _rule {
	my ($self, $t, $node) = @_;

	my $name = undef;

	my $x = ($node->children('name'))[0];
	$name = $x->text();

	if(!defined($self->{_rules}->{$name})) {
		$self->{_rules}->{$name} = AI::ExpertSystem::Simple::Rule->new($name);
		$self->{_number_of_rules}++;
	}

	foreach $x ($node->get_xpath('//condition')) {
		my $attribute = undef;
		my $value = undef;

		my $y = ($x->children('attribute'))[0];
		$attribute = $y->text();

		$y = ($x->children('value'))[0];
		$value = $y->text();

		$self->{_rules}->{$name}->add_condition($attribute, $value);

		if(!defined($self->{_knowledge}->{$attribute})) {
			$self->{_number_of_attributes}++;
			$self->{_knowledge}->{$attribute} = AI::ExpertSystem::Simple::Knowledge->new($attribute);
		}
	}

	foreach $x ($node->get_xpath('//action')) {
		my $attribute = undef;
		my $value = undef;

		my $y = ($x->children('attribute'))[0];
		$attribute = $y->text();

		$y = ($x->children('value'))[0];
		$value = $y->text();

		$self->{_rules}->{$name}->add_action($attribute, $value);

		if(!defined($self->{_knowledge}->{$attribute})) {
			$self->{_number_of_attributes}++;
			$self->{_knowledge}->{$attribute} = AI::ExpertSystem::Simple::Knowledge->new($attribute);
		}
	}

	eval { $t->purge(); }
}

sub _question {
	my ($self, $t, $node) = @_;

	my $attribute = undef;
	my $text = undef;
	my @responses = ();

	$self->{_number_of_questions}++;

	my $x = ($node->children('attribute'))[0];
	$attribute = $x->text();

	$x = ($node->children('text'))[0];
	$text = $x->text();

	foreach $x ($node->children('response')) {
		push(@responses, $x->text());
	}

	if(!defined($self->{_knowledge}->{$attribute})) {
		$self->{_number_of_attributes}++;
		$self->{_knowledge}->{$attribute} = AI::ExpertSystem::Simple::Knowledge->new($attribute);
	}
	$self->{_knowledge}->{$attribute}->set_question($text, @responses);

	eval { $t->purge(); }
}

sub process {
	my ($self) = @_;

	die "Simple->process() takes no arguments" if scalar(@_) != 1;

	my $n = $self->{_goal}->name();

	if($self->{_knowledge}->{$n}->is_value_set()) {
		return 'finished';
	}

	if($self->{_ask_about}) {
		my %answers = ();

		$answers{$self->{_ask_about}}->{value} = $self->{_told_about};
		$answers{$self->{_ask_about}}->{setter} = '';

		$self->{_ask_about} = undef;
		$self->{_told_about} = undef;

		while(%answers) {
			my %old_answers = %answers;
			%answers = ();

			foreach my $answer (keys(%old_answers)) {
				my $n = $answer;
				my $v = $old_answers{$answer}->{value};
				my $s = $old_answers{$answer}->{setter};

				$self->_add_to_log( "Setting '$n' to '$v'" );

				$self->{_knowledge}->{$n}->set_value($v,$s);

				foreach my $key (keys(%{$self->{_rules}})) {
					if($self->{_rules}->{$key}->state() eq 'active') {
						my $state = $self->{_rules}->{$key}->given($n, $v);
						if($state eq 'completed') {
							$self->_add_to_log( "Rule '$key' has completed" );
							my %y = $self->{_rules}->{$key}->actions();
							foreach my $k (keys(%y)) {
								$self->_add_to_log( "Rule '$key' is setting '$k' to '$y{$k}'" );
								$answers{$k}->{value} = $y{$k};
								$answers{$k}->{setter} = $key;
							}
						} elsif($state eq 'invalid') {
							$self->_add_to_log( "Rule '$key' is now inactive" );
						}
					}
				}
			}
		}

		return 'continue';
	} else {
		my %scoreboard = ();

		foreach my $rule (keys(%{$self->{_rules}})) {
			if($self->{_rules}->{$rule}->state() eq 'active') {
				my @listofquestions = $self->{_rules}->{$rule}->unresolved();
				my $ok = 1;
				my @questionstoask = ();
				foreach my $name (@listofquestions) {
					if($self->{_knowledge}->{$name}->has_question()) {
						push(@questionstoask, $name);
					} else {
						$ok = 0;
					}
				}

				if($ok == 1) {
					foreach my $name (@questionstoask) {
						$scoreboard{$name}++;
					}
				}
			}
		}

		my $max_value = 0;

		foreach my $name (keys(%scoreboard)) {
			if($scoreboard{$name} > $max_value) {
				$max_value = $scoreboard{$name};
				$self->{_ask_about} = $name;
			}
		}

		return $self->{_ask_about} ? 'question' : 'failed';
	}
}

sub get_question {
	my ($self) = @_;

	die "Simple->get_question() takes no arguments" if scalar(@_) != 1;

	return $self->{_knowledge}->{$self->{_ask_about}}->get_question();
}

sub answer {
	my ($self, $value) = @_;

	die "Simple->answer() takes 1 argument" if scalar(@_) != 2;
	die "Simple->answer() argument 1 (VALUE) is undefined" if ! defined($value);

	$self->{_told_about} = $value;
}

sub get_answer {
	my ($self) = @_;

	die "Simple->get_answer() takes no arguments" if scalar(@_) != 1;

	my $n = $self->{_goal}->name();

	return $self->{_goal}->answer($self->{_knowledge}->{$n}->get_value());
}

sub log {
	my ($self) = @_;

	die "Simple->log() takes no arguments" if scalar(@_) != 1;

	my @return = ();
	@return = @{$self->{_log}} if defined @{$self->{_log}};

	$self->{_log} = ();

	return @return;
}

sub _add_to_log {
	my ($self, $message) = @_;

	push( @{$self->{_log}}, $message );
}

sub explain {
	my ($self) = @_;

	die "Simple->explain() takes no arguments" if scalar(@_) != 1;

	my $name  = $self->{_goal}->name();
	my $rule  = $self->{_knowledge}->{$name}->get_setter();
	my $value = $self->{_knowledge}->{$name}->get_value();

	my $x = "The goal '$name' was set to '$value' by " . ($rule ? "rule '$rule'" : 'asking a question' );
	$self->_add_to_log( $x );

	my @processed_rules;
	push( @processed_rules, $rule ) if $rule;

	$self->_explain_this( $rule, '', @processed_rules );
}

sub _explain_this {
	my ($self, $rule, $depth, @processed_rules) = @_;

	$self->_add_to_log( "${depth}Explaining rule '$rule'" );

	my %dont_do_these = map{ $_ => 1 } @processed_rules;

	my @check_these_rules = ();

	my %conditions = $self->{_rules}->{$rule}->conditions();
	foreach my $name (sort keys %conditions) {
		my $value = $conditions{$name};
		my $setter = $self->{_knowledge}->{$name}->get_setter();

		my $x = "$depth Condition '$name' was set to '$value' by " . ($setter ? "rule '$setter'" : 'asking a question' );
		$self->_add_to_log( $x );

		if($setter) {
			unless($dont_do_these{$setter}) {
				$dont_do_these{$setter} = 1;
				push( @check_these_rules, $setter );
			}
		}
	}

	my %actions = $self->{_rules}->{$rule}->actions();
	foreach my $name (sort keys %actions) {
		my $value = $actions{$name};

		my $x = "$depth Action set '$name' to '$value'";
		$self->_add_to_log( $x );
	}

	@processed_rules = keys %dont_do_these;

	foreach my $x ( @check_these_rules ) {
		push( @processed_rules, $self->_explain_this( $x, "$depth ", keys %dont_do_these ) );
	}

	return @processed_rules;
}

1;

=head1 NAME

AI::ExpertSystem::Simple - A simple expert system shell

=head1 VERSION

This document refers to verion 1.2 of AI::ExpertSystem::Simple, released June 10, 2003

=head1 SYNOPSIS

This class implements a simple expert system shell that reads the rules from an XML 
knowledge base and questions the user as it attempts to arrive at a conclusion.

=head1 DESCRIPTION

=head2 Overview

This class is where all the work is being done and the other three classes are only 
there for support. At present there is little you can do with it other than run it. Future 
version will make subclassing of this class feasable and features like logging will be introduced.

To see how to use this class there is a simple shell in the bin directory which allows you 
to consult the example knowledge bases and more extensive documemtation in the docs directory.

There is a Ruby version that reads the same XML knowledge bases, if you are interested.

=head2 Constructors and initialisation

=over 4

=item new( )

The constructor takes no arguments and just initialises a few basic variables.

=back

=head2 Public methods

=over 4

=item reset( )

Resets the system back to its initial state so that a new consoltation can be run

=item load( FILENAME )

This method takes the FILENAME of an XML knowledgebase and attempts to parse it to set up the data structures 
required for a consoltation.

=item process( )

Once the knowledgebase is loaded the consultation is run by repeatedly calling this method.

It returns four results:

=over 4

=item "question"

The system has a question to ask of the user.

The question and list of valid responses is available from the get_question( ) method and the users response should be returned via the answer( ) method. 

Then simply call the process( ) method again.

=item "continue"

The system has calculated some data but has nothing to ask the user but has still not finished.

This response will be removed in future versions.

Simply call the process( ) method again.

=item "finished"

The consoltation has finished and the system has an answer for the user which is available from the answer( ) method.

=item "failed"

The consoltation has finished and the system has failed to find an answer for the user. It happens.

=back

=item get_question( )

If the process( ) method has returned "question" then this method will return the question to ask the user 
and a list of valid responses.

=item answer( VALUE )

The user has been presented with the question from the get_question( ) method along with a set of 
valid responses and the users selection is returned by this method.

=item get_answer( )

If the process( ) method has returned "finished" then the answer to the users query will be 
returned by this method.

=item log( )

Returns a list of the actions undertaken so far and clears the log.

=item explain( )

Explain how the given answer was arrived at. The explanation is added to the log.

=back

=head2 Private methods

=over 4

=item _goal

A private method to get the goal data from the knowledgebase.

=item _rule

A private method to get the rule data from the knowledgebase.

=item _question

A private method to get the question data from the knowledgebase.

=item _add_to_log

A private method to add a message to the log.

=item _explain_this

A private method to explain how a single attribute was set.

=back

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Simple->new() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if 
some arguments were supplied.

=item Simple->reset() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=item Simple->load() takes 1 argument

When the method is called it requires one argument. This message is given if more or 
less arguments were supplied.

=item Simple->load() argument 1 (FILENAME) is undefined

The corrct number of arguments were supplied with the method call, however the first 
argument, FILENAME, was undefined.

=item Simple->load() XML parse failed

XML Twig encountered some errors when trying to parse the XML knowledgebase.

=item Simple->load() unable to use file

The file supplied to the load( ) method could not be used as it was either not a file 
or not readable.

=item Simple->process() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=item Simple->get_question() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=item Simple->answer() takes 1 argument

When the method is called it requires one argument. This message is given if more or 
less arguments were supplied.

=item Simple->answer() argument 1 (VALUE) is undefined

The corrct number of arguments were supplied with the method call, however the first 
argument, VALUE, was undefined.

=item Simple->get_answer() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=item Simple->log() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=item Simple->explain() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=back

=head1 BUGS

None

=head1 FILES

See the Simple.t file in the test directory and simpleshell in the bin directory.

=head1 SEE ALSO

AI::ExpertSystem::Simple::Goal - A utility class

AI::ExpertSystem::Simple::Knowledge - A utility class

AI::ExpertSystem::Simple::Rule - A utility class

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
