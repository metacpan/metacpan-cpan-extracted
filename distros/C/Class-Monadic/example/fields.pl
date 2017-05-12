#!perl -w

use strict;

use Class::Monadic qw(monadic);

{
	package Object;

	sub new{
		bless {}, shift;
	}

	sub clone{
		my($self) = @_;

		bless { %{$self} }, ref $self;
	}
}

my $o = Object->new();

monadic($o)->add_field(
	lang => [qw(perl ruby python)],
);
monadic($o)->add_method(
	hello => sub{ print "Hello, world!\n" },
);

$o->set_lang('perl');


my $another = $o->clone();

#use Data::Dumper;
#print Dumper monadic($another);

print '$another->lang: ', $another->get_lang, "\n";

$another->hello();
