use 5.008;
use strict;
use warnings;
use utf8;

package Crypt::XkcdPassword;

BEGIN {
	$Crypt::XkcdPassword::AUTHORITY = "cpan:TOBYINK";
	$Crypt::XkcdPassword::VERSION   = "0.009";
}

use match::simple            qw( match );
use Carp                     qw( carp croak );
use Module::Runtime          qw( require_module );
use Types::Standard 1.000000 qw( CodeRef Str ConsumerOf ArrayRef );

use Moo 1.006000;

has rng => (
	is      => "rw",
	isa     => CodeRef,
	default => sub { sub { int(rand($_[0])) } },
);

my $wordrole = 'Crypt::XkcdPassword::Words';

has words => (
	is      => "rw",
	isa     => ConsumerOf->of($wordrole)->plus_coercions(
		Str,      sub { require_module("$wordrole\::$_")->new },
		ArrayRef, sub { my ($c, @a) = @$_; require_module("$wordrole\::$c")->new(@a) },
	),
	coerce  => 1,
	default => sub { "EN" },
	handles => { _word_list => 'words' },
);

*chars = *provider = sub {};

sub make_password
{
	my $self = shift;
	my ($length, $filter) = @_;
	
	$self = $self->new unless ref $self;
	
	$length = 4 unless defined $length;
	$length = 4 unless $length > 0;
	
	my $rng        = $self->rng;
	my $words      = $self->_word_list;
	my $word_count = @$words;

	my @password;
	while (@password < $length)
	{
		local $_ = my $maybe = $words->[ $rng->($word_count) ];
		push @password, $maybe
			if (!defined $filter or match($maybe, $filter));
	}

	join q{ }, @password;	
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::XkcdPassword - see http://xkcd.com/936/

=head1 SYNOPSIS

 use 5.010;
 use Crypt::XkcdPassword;
 
 say Crypt::XkcdPassword->make_password;

=head1 DESCRIPTION

Yet another password generator module inspired by L<http://xkcd.com/936/>.

=head2 Constructor

=over

=item * C<< new(%attr) >>

Creates a new generator. A single generator can be used to generate as
many passwords as you like.

=back

=head2 Attributes

This is a Moo-based class.

=over

=item * C<< words >>

An object consuming the L<Crypt::XkcdPassword::Words> role.

Can be coerced from a short string. This will be prepended with
C<< Crypt::XkcdPassword::Words:: >> to form a class name, and the
C<< new >> constructor will be called.

Can also coerce from an arrayref where the first item in the array is a
short string used as above, and the other items in the array are passed
to the constructor.

The default is "EN", which means the class used as a source for words
is C<< Crypt::XkcdPassword::Words::EN >>.

=item * C<< rng >>

A coderef for generating a random number. The coderef is called and passed
a single numeric argument. The coderef is expected to generate a random,
positive integer, smaller than the argument. The default is:

 sub { int(rand($_[0])) }

Perl's default random number generator is often though insufficient for
practical cryptography, so you may wish to use another random number
generator.

=back

=head2 Methods

=over

=item * C<< make_password($size, $filter) >>

Returns the password as a string.

$size is the length of the password in words. It defaults to 4. For the
English dictionary that provides over 47 bits of entropy; for the Italian
dictionary (which has twice as many words), about 56 bits of entropy.

$filter is a test against which each word is checked. It can be a sub
returning true if the word is OK, or a regular expression matching OK
words. Words which are not OK will be excluded from passwords. The default
is to allow any words found in the provided dictionary.

For reference, 47 bits of entropy is roughly equivalent to an eight digit
random case-sensitive alphanumeric password (i.e. 62^8).

This can be called as an object method, or (if you have no desire to
change the defaults for the C<rng> and C<words> attributes) as a class
method. That is, the first line of the example below is a shortcut for
the second line:

 say Crypt::XkcdPassword->make_password($size);
 say Crypt::XkcdPassword->new->make_password($size);

Note that the passphrases returned may not be ASCII-safe, and may
sometimes be inappropriate for uttering in polite company. See
L<Crypt::XkcdPassword::Examples> for ways of using $filter to resolve
this situation.

=item * C<< chars >>

No-op, provided for compatibility with Data::SimplePassword.

=item * C<< provider >>

No-op, provided for compatibility with Data::SimplePassword.

=back

=head2 Bundled Word Lists

C<< Crypt::XkcdPassword::Words::EN >> is a list of 10,000 common
English words.

C<< Crypt::XkcdPassword::Words::EN::Roget >> is a list of about 8500
words. The words are less questionable, but as there are fewer of them,
pass phrases will be chosen from a smaller pool, thus slightly more
guessable.

C<< Crypt::XkcdPassword::Words::IT >> is a list of 20,000 common
Italian words.

C<< Crypt::XkcdPassword::Words::sys >> uses your system's word list
(C<< /usr/share/dict/words >> by default). The constructor can be
passed an alternative filename.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Crypt-XkcdPassword>.

=head1 SEE ALSO

L<Crypt::XkcdPassword::Examples> - how to do stuff with this module.

L<Data::SimplePassword> - I borrowed this module's interface, so it
should mostly be possible to s/Data::SimplePassword/Crypt::XkcdPassword/.

L<Crypt::PW44> - similar to this one, but with a smaller list of words.

L<http://xkcd.com/936/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
