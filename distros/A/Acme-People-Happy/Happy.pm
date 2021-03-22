package Acme::People::Happy;

use strict;
use warnings;

use Class::Utils qw(set_params);

# Version.
our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Simple question.
sub are_you_happy {
	return "Yes, i'm.";
}

# Everybody can be happy.
sub everybody {
	return 'Everybody can be happy.';
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Acme::People::Happy - Does people happy?

=head1 SYNOPSIS

 use Acme::People::Happy;

 my $obj = Acme::People::Happy->new;
 my $text = $obj->are_you_happy;
 my $text = $obj->everybody;

=head1 METHODS

=head2 C<new>

 my $obj = Acme::People::Happy->new;

Constructor.

Returns instance of object.

=head2 C<are_you_happy>

 my $text = $obj->are_you_happy;

Are you happy question?

Returns answer.

=head2 C<everybody>

 my $text = $obj->everybody;

Everybody?

Returns answer.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Acme::People::Happy;

 # Object.
 my $people = Acme::People::Happy->new;

 # Are you happy?
 print $people->are_you_happy."\n";

 # Output like:
 # Yes, i'm.

=head1 DEPENDENCIES

L<Class::Utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Acme-People-Happy>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 DEDICATION

To Mario for his ideas.

=head1 VERSION

0.05

=cut
