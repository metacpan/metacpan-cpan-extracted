package Data::Text;

use warnings;
use strict;
use Carp;
use String::Util;

=head1 NAME

Data::Text - Class to handle text in an OO way

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Handle text in an OO way.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Data::Text object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Use Data::Text->new(), not Data::Text::new()
	if(!defined($class)) {
		Carp::carp(__PACKAGE__, ': use ->new() not ::new() to instantiate');
		return;
	}

	return bless { }, $class;
}

=head2 append

Adds data to the end of the object.
Contains a simple sanity test for consecutive punctuation.
I expect I'll improve that.

Successful calls to append() can be daisy chained.

The argument can be a reference to an array of strings, or an object.
If called with an object, the message as_string() is sent to it for its contents.

=cut

sub append {
	my $self = shift;

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(scalar(@_) % 2 == 0) {
		%params = @_;
	} else {
		$params{'text'} = shift;
	}

	if(ref($params{'text'})) {
		# Allow the text to be a reference to a list of strings
		if(ref($params{'text'}) eq 'ARRAY') {
			foreach my $text(@{$params{'text'}}) {
				$self = $self->append($text);
			}
			return $self;
		}
		$params{'text'} = $params{'text'}->as_string();
	}

	# FIXME: handle ending with an abbreviation

	if($self->{'text'} && ($self->{'text'} =~ /[\.\,;]\s*$/)) {
		if($params{'text'} =~ /^\s*[\.\,;]/) {
			Carp::carp(__PACKAGE__, ': attempt to add consecutive punctuation');
			return;
		}
	}
	$self->{'text'} .= $params{'text'};

	return $self;
}

=head2 as_string

Returns the text as a string.

=cut

sub as_string {
	my $self = shift;

	return $self->{'text'};
}

=head2	length

Returns the length of the text.

=cut

sub length {
	my $self = shift;

	return length($self->{'text'});
}

=head2	trim

Removes leading and trailing spaces from the string.

=cut

sub trim {
	my $self = shift;

	$self->{'text'} = String::Util::trim($self->{'text'});

	return $self;
}

=head2	rtrim

Removes trailing spaces from the string.

=cut

sub rtrim {
	my $self = shift;

	$self->{'text'} = String::Util::rtrim($self->{'text'});

	return $self;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=head1 SEE ALSO

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Text

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Data-Text>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Text>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Data-Text>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Data-Text>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Text>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Data::Text>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
