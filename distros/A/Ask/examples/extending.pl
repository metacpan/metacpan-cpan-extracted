use 5.010;
use strict;
use warnings;
use Ask;

{
	package AskX::Method::Password;
	use Moo::Role;
	sub password {
		my ($self, %o) = @_;
		$o{hide_text} //= 1;
		$o{text}      //= "please enter your password";
		$self->entry(%o);
	}
}

my $ask = Ask->detect(traits => ['AskX::Method::Password']);
say "GOT: ", $ask->password;
