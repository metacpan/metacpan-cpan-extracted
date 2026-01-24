package Data::Text;

use warnings;
use strict;

use Carp;
use Encode;
use Lingua::Conjunction;
use Object::Configure 0.16;
use Params::Get 0.13;
use Scalar::Util;
use String::Util;
use utf8;

=head1 NAME

Data::Text - Class to handle text in an OO way

=head1 VERSION

Version 0.19

=cut

our $VERSION = '0.19';

use overload (
	'==' => \&equal,
	'!=' => \&not_equal,
	'""' => \&as_string,
	# bool => sub { defined $_[0] && defined $_[0]->{'text'} && length $_[0]->{'text'} },
	bool => sub { 1 },
	fallback => 1	# So that boolean tests don't cause as_string to be called
);

=head1 DESCRIPTION

C<Data::Text> provides an object-oriented interface for managing and manipulating text content in Perl.
It wraps string operations in a class-based structure,
enabling clean chaining of methods like appending, trimming, replacing words, and joining text with conjunctions.
It supports flexible input types,
including strings, arrays, and other C<Data::Text> objects,
and overloads common operators to allow intuitive comparisons and stringification.

=head1 SYNOPSIS

    use Data::Text;

    my $d = Data::Text->new("Hello, World!\n");

    print $d->as_string();

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Data::Text object.

The optional parameter contains a string or object to initialise the object with.

=cut

sub new {
	my $class = shift;
	my $self;
	my $params;

	if(scalar(@_) == 1) {
		# Just one parameter - the text to initialize with
		$params = Params::Get::get_params('text', \@_);
	} else {
		$params = Params::Get::get_params(undef, \@_) || {};
	}

	if(!defined($class)) {
		# Using Data::Text->new(), not Data::Text::new()
		# This only works when no arguments are given
		$self = bless { }, __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		$self = bless { }, ref($class);
		return $self->set($class) if(!scalar keys %{$params});
	} else {
		# Create a new object
		$self = bless { }, $class;
	}

	$params = Object::Configure::configure($class, $params);

	# Set additional attributes if arguments are provided
	$self->set($params) if($params->{'text'});

	# Return the blessed object
	return $self;
}

=head2 set

Sets the object to contain the given text.

The argument can be a reference to an array of strings, or an object.
If called with an object, the message as_string() is sent to it for its contents.

    $d->set({ text => "Hello, World!\n" });
    $d->set(text => [ 'Hello, ', 'World!', "\n" ]);

=cut

sub set {
	my $self = shift;
	my $params = Params::Get::get_params('text', @_);

	if(!defined($params->{'text'})) {
		Carp::carp(__PACKAGE__, ': no text given to set()');
		return;
	}

	# @{$self}{'file', 'line'} = (caller(0))[1, 2];
	my @call_details = caller(0);
	$self->{'file'} = $call_details[1];
	$self->{'line'} = $call_details[2];

	if(ref($params->{'text'})) {
		# Allow the text to be a reference to a list of strings
		if(ref($params->{'text'}) eq 'ARRAY') {
			if(scalar(@{$params->{'text'}}) == 0) {
				Carp::carp(__PACKAGE__, ': no text given');
				return $self;
			}
			delete $self->{'text'};
			foreach my $text(@{$params->{'text'}}) {
				$self = $self->append($text);
			}
			return $self;
		} elsif(ref($params->{text}) eq 'HASH') {
			Carp::croak(__PACKAGE__, ': set(): text cannot be a hashref');
		}
		$self->{'text'} = $params->{'text'}->as_string();
	} else {
		$self->{'text'} = $params->{'text'};
	}

	return $self;
}

=head2 append

Adds data given in "text" to the end of the object.
Contains a simple sanity test for consecutive punctuation.
I expect I'll improve that.

Successive calls to append() can be daisy chained.

    $d->set('Hello ')->append("World!\n");

The argument can be a reference to an array of strings, or an object.
If called with an object, the message as_string() is sent to it for its contents.

=cut

sub append
{
	my $self = shift;
	my $params = Params::Get::get_params('text', @_);
	my $text = $params->{'text'};

	# Check if text is provided
	unless(defined $text) {
		Carp::carp(__PACKAGE__, ': no text given to append()');
		return;
	}

	# Capture caller information for debugging
	my $file = $self->{'file'};
	my $line = $self->{'line'};
	# my @call_details = caller(0);
	# $self->{'file'} = $call_details[1];
	# $self->{'line'} = $call_details[2];
	@{$self}{'file', 'line'} = (caller(0))[1, 2];

	# Process if text is a reference
	if(ref($text)) {
		if(ref($text) eq 'ARRAY') {
			unless(@{$text}) {
				Carp::carp(__PACKAGE__, ': no text given');
				return
			}
			$self->append($_) for @{$text};
			return $self;
		}
		$text = $text->as_string();
	}

	# Check for consecutive punctuation
	# FIXME: handle ending with an abbreviation
	if($self->{'text'} && ($self->{'text'} =~ /\s*[\.,;]\s*$/) && ($text =~ /^\s*[\.,;]/)) {
		if(my $logger = $self->{'logger'}) {
			$logger->warn(": attempt to add consecutive punctuation\n\tCurrent = '" . $self->{'text'} .
			"' at $line of $file\n\tAppend = '", $text, "'");
		}
		Carp::carp(__PACKAGE__,
			": attempt to add consecutive punctuation\n\tCurrent = '", $self->{'text'},
			"' at $line of $file\n\tAppend = '", $text, "'");
	} else {
		# Append text
		$self->{'text'} .= $text;
	}

	return $self;
}

=head2 uppercase

Converts the text to uppercase.

    $d->uppercase();

=cut

sub uppercase {
	my $self = shift;

	Encode::_utf8_on($self->{'text'});	# Ensure characters like é are converted to É
	$self->{'text'} = uc($self->{'text'}) if(defined($self->{'text'}));
	Encode::_utf8_off($self->{'text'});

	return $self;
}

=head2 lowercase

Converts the text to lowercase.

    $d->lowercase();

=cut

sub lowercase {
	my $self = $_[0];

	Encode::_utf8_on($self->{'text'});	# Ensure characters like é are converted to É
	$self->{'text'} = lc($self->{'text'}) if(defined($self->{'text'}));
	Encode::_utf8_off($self->{'text'});

	return $self;
}

=head2 clear

Clears the text and resets the internal state.

    $d->clear();

=cut

sub clear {
	my $self = shift;

	delete @$self{qw(text file line)};

	return $self;
}

=head2	equal($self, $other)

Are two texts the same?

    my $t1 = Data::Text->new('word');
    my $t2 = Data::Text->new('word');
    print ($t1 == $t2), "\n";	# Prints 1

=cut

sub equal {
	my $self = shift;
	my $other = shift;

	return $self->as_string() eq $other->as_string();
}

=head2	not_equal($self, $other)

Are two texts different?

    my $t1 = Data::Text->new('xyzzy');
    my $t2 = Data::Text->new('plugh');
    print ($t1 != $t2), "\n";	# Prints 1

=cut

sub not_equal {
	my $self = shift;
	my $other = shift;

	return $self->as_string() ne $other->as_string();
}

=head2 as_string

Returns the text as a string.

=cut

sub as_string {
	my $self = shift;

	return $self->{'text'};
}

=head2	length

Returns the length of the text as an integer.

This is actually the number of characters, not the number of bytes.

=cut

sub length {
	my $self = shift;

	if(!defined($self->{'text'})) {
		return 0;
	}

	my $copy = $self->{'text'};

	Encode::_utf8_on($copy);

	return length($copy);
}

=head2	trim

Removes leading and trailing spaces from the text.

=cut

sub trim {
	my $self = shift;

	$self->{'text'} = String::Util::trim($self->{'text'});

	return $self;
}

=head2	rtrim

Removes trailing spaces from the text.

=cut

sub rtrim {
	my $self = shift;

	$self->{'text'} = String::Util::rtrim($self->{'text'});

	return $self;
}

=head2 replace($self, $replacements)

Replaces multiple words in the text.

    $d->append('Hello World');
    $d->replace({ 'Hello' => 'Goodbye', 'World' => 'Universe' });
    print $d->as_string(), "\n";	# Outputs "Goodbye Universe"

=cut

sub replace {
	my ($self, $replacements) = @_;

	if($self->{'text'} && (ref($replacements) eq 'HASH')) {
		foreach my $search (keys %{$replacements}) {
			my $replace = $replacements->{$search};
			$self->{'text'} =~ s/\b\Q$search\E\b/$replace/g;
		}
	}

	return $self;
}

=head2	appendconjunction

Add a list as a conjunction.  See L<Lingua::Conjunction>
Because of the way Data::Text works with quoting,
this code works

    my $d1 = Data::Text->new();
    my $d2 = Data::Text->new('a');
    my $d3 = Data::Text->new('b');

    # Prints "a and b\n"
    print $d1->appendconjunction($d2, $d3)->append("\n");

=cut

sub appendconjunction
{
	my $self = shift;

	return $self->append(Lingua::Conjunction::conjunction(@_));
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

There is limited Unicode or UTF-8 support.

=head1 SEE ALSO

=over 4

=item * <Test Coverage Report|https://nigelhorne.github.io/Data-Text/coverage/>

=item * L<String::Util>, L<Lingua::String>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Data::Text

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Data-Text>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Text>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Data-Text>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Data::Text>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
