package Data::Random::Structure::UTF8;

use 5.8.0;
use strict;
use warnings;

our $VERSION='0.06';

use parent 'Data::Random::Structure';

use Scalar::Util qw( looks_like_number );

sub	new {
	my $class = shift;
	my %options = @_;
	my $only_unicode = 0;
	if( exists $options{'only-unicode'} ){
		if( defined $options{'only-unicode'} ){
			$only_unicode = $options{'only-unicode'}
		}
		# do not pass our options to parent it may get confused and croak
		delete $options{'only-unicode'}
	}
	my $self = $class->SUPER::new(%options);
	# at this point our _init() will be called via parent's
	# constructor. Our _init() will call parent's _init()
	$self->only_unicode($only_unicode);
	return $self
}
sub	_reset {
	my $self = shift;
	# we are interfering with the internals of the parent... not good
	$#{$self->{_types}} = -1;
	$#{$self->{_scalar_types}} = -1;
}
sub	_init {
	my $self = shift;
	$self->_reset();
	$self->SUPER::_init(@_);
	push @{$self->{_scalar_types}}, 'string-UTF8'
}
sub	only_unicode {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'_only-unicode'} unless defined $m;
	$self->_init();
	$self->{'_only-unicode'} = $m;
	if( $m == 1 ){
		# delete just the 'string' type
		# we will get various types but the strings will
		# be exclusively unicode
		my @idx = grep { $self->{'_scalar_types'}->[$_] eq 'string' }
			reverse 0 .. $#{$self->{_scalar_types}}
		;
		splice(@{$self->{_scalar_types}}, $_, 1) for @idx;
	} elsif( $m > 1 ){
		# delete ALL the _scalar_types and leave just our unicode string
		# we will get only unicode strings no other scalar type
		$#{$self->{_scalar_types}} = -1;
		push @{$self->{_scalar_types}}, 'string-UTF8'
	}
	return $m
}
sub	random_char_UTF8 {
	# the crucial part borrowed from The Effective Perler:
	# https://www.effectiveperlprogramming.com/2018/08/find-the-new-emojis-in-perls-unicode-support/
#	my $achar;
#	for(my $trials=100;$trials-->0;){
#		$achar = chr(int(rand(0x10FFF+1)));
#		return $achar if $achar =~ /\p{Present_In: 8.0}/;
#	}

	# just greek and coptic no holes
	return chr(0x03B0+int(rand(0x03F0-0x03B0)));

	my $arand = rand();
	if( $arand < 0.2 ){
		return chr(0x03B0+int(rand(0x03F0-0x03B0)))
	} elsif( $arand < 0.4 ){
		return chr(0x0400+int(rand(0x040F-0x0400)))
	} elsif( $arand < 0.6 ){
		return chr(0x13A0+int(rand(0x13EF-0x13A0)))
	} elsif( $arand < 0.8 ){
		return chr(0x1200+int(rand(0x137F-0x1200)))
	}
	return chr(0xA980+int(rand(0xA9DF-0xA980)))
}
sub	random_chars_UTF8 {
	my %options = @_;
	my $minl = defined($options{'min'}) ? $options{'min'} : 6;
	my $maxl = defined($options{'max'}) ? $options{'max'} : 32;
	my $ret = "";
	for(1..($minl+int(rand($maxl-$minl)))){
		$ret .= random_char_UTF8()
	}
	return $ret;
}		
# override's parent's.
# first call parent's namesake and if it fails because it
# is decided to generate UTF8 something, it will default to
# this method which must deal with all the extenstions we introduced
# in our own _init()
# CAVEAT: it relies on parent croaking the message
#   "I don't know how to generate $type\n"
# if that chanegs (in parent) then we will no longer be able to deduce
# $type and have to change this program.
# if that happens please file a bug.
# unfortunately our parent class does not allow for input params...
sub	generate_scalar {
	my $self = shift;
	my $rc = eval { $self->SUPER::generate_scalar(@_) };
	if( $@ || ! defined($rc) ){
		if( $@ !~ /how to generate (.+?)\R/ ){
			warn "something changed in parent class and can not parse this message any more, please file a bug: '$@'";
			return scalar(random_chars_UTF8(min=>2,max=>2));
		}
		my $type = $1;
		if( $type eq 'string-UTF8' ){
			return scalar(random_chars_UTF8(min=>2,max=>2));
		} else {
			warn "child: I don't know how to generate $type, this is a bug, please file a bug and mention this: $@\n";
			# but don't die
			return scalar(random_chars_UTF8(min=>2,max=>2));
		}
	}
	return $rc
}
sub	check_content_recursively {
	my $looking_for = $_[1]; # a hashref of types to look-for, required
	my $bitparams = 0;
	$bitparams |= 1 if exists($looking_for->{'numbers'}) && ($looking_for->{'numbers'}==1);
	$bitparams |= 2 if exists($looking_for->{'strings-unicode'}) && ($looking_for->{'strings-unicode'}==1);
	$bitparams |= 4 if exists($looking_for->{'strings-plain'}) && ($looking_for->{'strings-plain'}==1);
	$bitparams |= (2+4) if exists($looking_for->{'strings'}) && ($looking_for->{'strings'}==1);
	return _check_content_recursively($_[0], $bitparams);
}
# returns 1 if we are looking for it and it was found
# returns 0 if what we were looking for was not found.
# 'looking_for' can be more than one things.
# it is a bit string, 1st bit if set looks for numbers,
# 2nd bit, if set, looks for unicode strings,
# 3rd bit, if set, looks for non-unicode strings (plain)
# if you set 'numbers'=>0, it simply means "do not check for numbers"
# and so it will not check if it has any numbers
# by giving nothing to check, it return 0, nothing was found
sub	_check_content_recursively {
	my $inp = $_[0];
	# NUMBER,UNICODE_STRING,NON_UNICODE_STRING
	my $looking_for = $_[1];
	my $aref = ref($inp);
	my ($r, $v);
	if( ($aref eq '') || ($aref eq 'SCALAR') ){
		if( $aref eq 'SCALAR' ){ $inp = $$inp }
		if( looks_like_number($inp) ){
			return 1 if $looking_for & 1; # a number
			return 0;
		}
		if( _has_utf8($inp) ){
			return 1 if $looking_for & 2; # unicode string
			return 0;
		}
		return 1 if $looking_for & 4; # plain string
		return 0;
	} elsif( $aref eq 'ARRAY' ){
		for my $v (@$inp){
			$r = _check_content_recursively($v, $looking_for);
			return 1 if $r;
		}
	} elsif( $aref eq 'HASH' ){
		for my $k (sort keys %$inp){
			$r = _check_content_recursively($k, $looking_for);
			return 1 if $r;
			$r = _check_content_recursively($inp->{$k}, $looking_for);
			return 1 if $r;
		}
	} else { die "don't know how to deal with this ref '$aref'" }
}
sub	_has_utf8 { return $_[0] =~ /[^\x00-\x7f]/ }
# this does not work for unicode strings
# from https://www.perlmonks.org/?node_id=958679
# and https://www.perlmonks.org/?node_id=791677
#sub isnum ($) {
#    return 0 if $_[0] eq '';
#    $_[0] & ~$_[0] ? 0 : 1
#}
1;

=pod

=encoding utf8

=head1 NAME

Data::Random::Structure::UTF8 - Produce nested data structures with unicode keys, values, elements.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

This module produces random, arbitrarily deep and long,
nested Perl data structures  with unicode content for the
keys, values and/or array elements. Content can be forced
to be exclusively strings and exclusively unicode. Or
the strings can be unicode. Or anything goes, mixed
unicode and non-unicode strings as well as integers, floats, etc.

This is an object-oriented module
which inherits from
L<Data::Random::Structure> and extends its functionality by
providing for unicode keys and values for hashtables and
unicode content for array elements or scalars, randomly mixed with the
usual repertoire of L<Data::Random::Structure>, which is
non-unicode strings,
numerical, boolean values and the assorted entourage to the court
of Emperor Computer, post-Turing.

For example, it produces these:

=over 4

=item * unicode scalars: e.g. C<"αβγ">,

=item * mixed arrays: e.g. C<["αβγ", "123", "xyz"]>

=item * hashtables with some/all keys and/or values as unicode: e.g.
C<{"αβγ" => "123", "xyz" => "αβγ"}>

=item * exclusive unicode arrays or hashtables: e.g. C<["αβγ", "χψζ"]>

=back

This is accomplised by adding an extra
type C<string-UTF8> (invisible to the user) and the
respective generator method. All these are invisible to the user
which will get the old functionality plus some (or maybe none
because this is a random process which does not eliminate non-unicode
strings, at the moment) unicode strings.

    use Data::Random::Structure::UTF8;

    my $randomiser = Data::Random::Structure::UTF8->new(
        'max_depth' => 5,
        'max_elements' => 20,
        # all the strings produced (keys, values, elements)
	# will be unicode strings
	'only-unicode' => 1,
        # all the strings produced (keys, values, elements)
	# will be a mixture of unicode and non-unicode
	# this is the default behaviour
	#'only-unicode' => 0,
        # only unicode strings will be produced for (keys, values, elements),
	# there will be no numbers, no bool, only unicode strings
	#'only-unicode' => 2,
    );
    my $perl_var = $randomiser->generate() or die;
    print pp($perl_var);

    # which prints the usual escape mess of Dump and Dumper
[
  "\x{7D5A}\x{4EC1}",
  "\x{E6E2}\x{75A4}",
  329076,
  0.255759160148987,
  [
    "TEb97qJt",
    1,
    "_ow|J\@~=6%*N;52?W3Y\$S1",
    {
      "x{75A4}x{75A4}" => 123,
      "123" => "\x{7D5A}\x{4EC1}",
      "xyz" => [1, 2, "\x{7D5A}\x{4EC1}"],
    },
  ],

    # can control the scalar type (for keys, values, items) on the fly
    # this produces unicode strings in addition to
    # Data::Random::Structure's usual repertoire:
    # non-unicode-string, numbers, bool, integer, float, etc.
    # (see there for the list)
    $randomiser->only_unicode(0); # the default: anything plus unicode strings
    print $randomiser->only_unicode();

    # this produces unicode strings in addition to
    # Data::Random::Structure's usual repertoire:
    # numbers, bool, integer, float, etc.
    # (see there for the list)
    # EXCEPT non-unicode-strings, (all strings will be unicode)
    $randomiser->only_unicode(1);
    print $randomiser->only_unicode();

    # this produces unicode strings ONLY
    # Data::Random::Structure's usual repertoire does not apply
    # there will be no numbers, no bool, no integer, no float, no nothing
    $randomiser->only_unicode(2);
    print $randomiser->only_unicode();

=head1 METHODS

This is an object oriented module which has exactly the same API as
L<Data::Random::Structure>.

=head2 C<new>

Constructor. In addition to L<Data::Random::Structure> C<<new()>>
API, it takes parameter C<< 'only-unicode' >> with
a valid value of 0, 1 or 2. Default is 0.

=over 4

=item * 0 : keys, values, elements of the produced data structure will be
a mixture of unicode strings, plus L<Data::Random::Structure>'s full
repertoire which includes non-unicode strings, integers, floats etc.

=item * 1 : keys, values, elements of the produced data structure will be
a mixture of unicode strings, plus L<Data::Random::Structure>'s full
repertoire except non-unicode strings. That is, all strings will be
unicode. But there will possibly be integers etc.

=item * 2 : keys, values, elements of the produced data structure will be
only unicode strings. Nothing of L<Data::Random::Structure>'s
repertoire applies. Only unicode strings, no integers, no nothing.

=back

Controlling the scalar data types can also be done on the fly, after
the object has been created using
L<Data::Random::Structure::UTF8> C<<only_unicode()>>
method.

Additionally, L<Data::Random::Structure> C<<new()>>'s API reports that
the constructor takes 2 optional arguments, C<max_depth> and C<max_elements>.
See L<Data::Random::Structure> C<<new()>> for up-to-date, official information.

=head2 C<only_unicode>

Controls what scalar types to be included in the nested
data structures generated. With no parameters it returns back
the current setting. Otherwise, valid input parameters and their
meanings are listed in L<Data::Random::Structure::UTF8> C<<new()>>

=head2 C<generate>

Generate a nested data structure according to the specification
set in the constructor. See L<Data::Random::Structure> C<<generate()>> for
all options. This method is not overriden by this module.

It returns the Perl data structure as a reference.

=head2 C<generate_scalar>

Generate a scalar which may contain unicode content.
See L<Data::Random::Structure::generate_scalar> for
all options. This method is overriden by this module but
calls the parent's too.

It returns a Perl string.

=head2 C<generate_array>

Generate an array with random, possibly unicode, content.
See L<Data::Random::Structure::generate_array> for
all options. This method is not overriden by this module.

It returns the Perl array as a reference.

=head2 C<generate_hash>

Generate an array with random, possibly unicode, content.
See L<Data::Random::Structure::generate_array> for
all options. This method is not overriden by this module.

It returns the Perl array as a reference.

=head2 C<random_char_UTF8>

Return a random unicode character, guaranteed to be valid.
This is a very simple method which selects characters
from some pre-set code pages (Greek, Cyrillic, Cherokee,
Ethiopic, Javanese) with equal probability.
These pages and ranges were selected so that there are
no "holes" between them which would produce an invalid
character. Therefore, not all characters from the
particular code page will be produced.

Returns a random unicode character guaranteed to be valid.

=head2 C<random_chars_UTF8>

  my $ret = random_chars_UTF8($optional_paramshash)

Arguments:

=over 4

=item * C<$optional_paramshash> : can contain

=over 4

=item * C<'min'> sets the minimum length of the random sequence to be returned, default is 6

=item * C<'max'> sets the maximum length of the random sequence to be returned, default is 32

=back

=back

Return a random unicode-only string optionally specifying
minimum and maximum length. See
L<Data::Random::Structure::UTF8> C<<random_chars_UTF8()>>
for the range of characters it returns. The returned string
is unicode and is guaranteed all its characters are valid.

=head1 SUBROUTINES

=head2 C<check_content_recursively>

  my $ret = check_content_recursively($perl_var, $paramshashref)

Arguments:

=over 4

=item * C<$perl_var> : a Perl variable containing an arbitrarily nested data structure

=item * C<$paramshashref> : can contain one or more of the following keys:

=over 4

=item * C<'numbers'> set it to 1 to look for numbers (possibly among other things).
If set to 1 and a number C<123> or C<"123"> is found, this sub returns 1.
Set it to 0 to not look for numbers at all (and not report if
there are no numbers) - I<don't bother checking for numbers>, that's what
setting this to zero means.

=item * C<'strings-unicode'> set it to 1 to look for unicode strings (possibly among other things).
The definition of "unicode string" is that at least one its characters is unicode.
If set to 1 and a "unicode string" is found, this sub returns 1.

=item * C<'strings-plain'> set it to 1 to look for plain strings (possibly among other things).
The definition of "plain string" is that none of its characters is unicode.
If set to 1 and a "plain string" is found, this sub returns 1.

=item * C<'strings'> set it to 1 to look for plain or unicode strings (possibly among other things).
If set to 1 and a "plain string" or "unicode string" is found, this sub returns 1. Basically,
it returns 1 when a string is found (as opposed to a "number").

=back

=back

In general, by setting C<<'strings-unicode'=>1>> you are checking whether
the input Perl variable contains a unicode string in a key, a value,
an array element, or a scalar reference.

But, setting C<<'strings-unicode'=>0>>, it simply means do not look for
this. It does not mean I<report if they are NO unicode strings>.

Return value: 1 or 0 depending whether what
was looking for, was found.

This is not an object-oriented method. It is called thously:

    # check if ANY scalar (hash key, value, array element or scalar ref)
    # contains ONLY single number (integer, float)
    # the decicion is made by Scalar::Util:looks_like_number()
    if( Data::Random::Structure::UTF8::check_content_recursively(
	{'abc'=>123, 'xyz'=>[1,2,3]},
	{
		# look for numbers, are there any?
		'numbers' => 1,
	}
    ) ){ print "data structure contains numbers\n" }

    # check if it contains no numbers but it does unicode strings
    if( Data::Random::Structure::UTF8::check_content_recursively(
	{'abc'=>123, 'xyz'=>[1,2,3]},
	{
		# don't look for numbers
		'numbers' => 0,
		# look for unicode strings, are there any?
		'strings-unicode' => 1,
	}
    ) ){ print "data structure contains numbers\n" }

CAVEAT: as its name suggests, this is a recursive function. Beware
of extremely deep data structures. Deep, not long. If you do get
C<<"Deep recursion..." warnings>>, and you do insist to go ahead,
this will remove the warnings (but are you sure?):

    {
        no warnings 'recursion';
        if( Data::Random::Structure::UTF8::check_content_recursively(
	    {'abc'=>123, 'xyz'=>[1,2,3]},
	    {
		'numbers' => 1,
	    }
        ) ){ print "data structure contains numbers\n" }
    }

=head1 SEE ALSO

=over 4

=item * The parent class L<Data::Random::Structure>.

=item * L<Data::Roundtrip> for stringifying possibly-unicode Perl data structures.

=back

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako ta cpan.org / andreashad2 ta gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-random-structure-utf8 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Random-Structure-UTF8>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 CAVEATS

There are two issues users should know about.

The first issue is that the unicode produced can make
L<Data::Dump> to complain with

   Operation "lc" returns its argument for UTF-16 surrogate U+DA4B at /usr/local/share/perl5/Data/Dump.pm line 302.

This, I have found, can be fixed with the following workaround (from L<github user iafan|https://github.com/evernote/serge/commit/865402bbde42101345a5bee4cd0a855b9b76bdd7>, thank you):

    # Suppress `Operation "lc" returns its argument for UTF-16 surrogate 0xNNNN` warning
    # for the `lc()` call below; use 'utf8' instead of a more appropriate 'surrogate' pragma
    # since the latter is not available in until Perl 5.14
    no warnings 'utf8';

The second issue is that this class inherits from L<Data::Random::Structure>
and relies on it complaining about not being able to handle certain types
which are our own extensions (the C<string-UTF8> extension). We have
no way to know that except from catching its C<croak>'ing and parsing it
with the following code

   my $rc = eval { $self->SUPER::generate_scalar(@_) };
   if( $@ || ! defined($rc) ){
     # parent doesn't know what to do, can we handle this?
     if( $@ !~ /how to generate (.+?)\R/ ){ ...  ... }
     else { print "type is $1" }
     ...

in order to extract the C<type> which can not be handled
and handle it ourselves. So whenever the parent class (L<Data::Random::Structure>)
changes its C<croak> song, we will have to adopt this code
accordingly (in L<Data::Random::Structure::UTF8> C<<generate_scalar()>>).
For the moment, I have placed a catch-all, fall-back condition
to handle this but it will be called for all kind of types
and not only the types we have added.

So, this issue is not going to make the module die but may make it
to skew the random results in favour of unicode strings (which
is the fallback, default action when can't parse the type).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Random::Structure::UTF8


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Random-Structure-UTF8>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Random-Structure-UTF8>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Data-Random-Structure-UTF8>

=item * Search CPAN

L<https://metacpan.org/release/Data-Random-Structure-UTF8>

=back

=head1 SEE ALSO

=over 4

=item * L<Data::Random::Structure> 

=back

=head1 ACKNOWLEDGEMENTS

Mark Allen who created L<Data::Random::Structure> which is our parent class.

=head1 DEDICATIONS AND HUGS

!Almaz!

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
