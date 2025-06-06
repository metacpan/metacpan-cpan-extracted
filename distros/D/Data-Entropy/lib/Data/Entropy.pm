=head1 NAME

Data::Entropy - entropy (randomness) management

=head1 SYNOPSIS

	use Data::Entropy qw(entropy_source);

	$i = entropy_source->get_int(12345);

	use Data::Entropy qw(with_entropy_source);

	with_entropy_source $source, sub {
		@a = shuffle(@a);
	};

=head1 STATUS

This module is deprecated.

For most purposes (including cryptography and security), modules like
L<Crypt::URandom>, L<Crypt::SysRandom> or L<Crypt::PRNG> are more than
adequate.

Modern operating systems provide good sources of random bytes, and
the above mentioned modules work on many kinds of systems, including Windows.

There is no need to choose an entropy source, and some users of this
module have omitted that step, and prior to version 0.008 they may
have been relying on Perl's builtin C<rand> function.

Please see CPAN Author's Guide to Random Data for Security
L<https://security.metacpan.org/docs/guides/random-data-for-security.html>.

=head1 DESCRIPTION

This module maintains a concept of a current selection of
entropy source.  Algorithms that require entropy, such as those in
L<Data::Entropy::Algorithms>, can use the source nominated by this
module, avoiding the need for entropy source objects to be explicitly
passed around.  This is convenient because usually one entropy source
will be used for an entire program run and so an explicit entropy source
parameter would rarely vary.  There is also a default entropy source,
avoiding the need to explicitly configure a source at all.

If nothing is done to set a source then it defaults to the use of Rijndael
(AES) in counter mode (see L<Data::Entropy::RawSource::CryptCounter>
and L<Crypt::Rijndael>), keyed using L<Crypt::URandom>.

=cut

package Data::Entropy;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Params::Classify 0.000 qw(is_ref);

our $VERSION = "0.008";

use parent "Exporter";
our @EXPORT_OK = qw(entropy_source with_entropy_source);

our $entropy_source;

=head1 FUNCTIONS

=over

=item entropy_source

Returns the current entropy source, a C<Data::Entropy::Source>
object.  This will be the source passed to the innermost call to
C<with_entropy_source>, if any, or otherwise the default entropy source.

=cut

my $default_entropy_source;

sub entropy_source() {
	if(is_ref($entropy_source, "CODE")) {
		my $source = $entropy_source->();
		croak "entropy source thunk returned another thunk"
			if is_ref($source, "CODE");
		$entropy_source = $source;
	}
	unless(defined $entropy_source) {
		unless(defined $default_entropy_source) {
			require Crypt::URandom;
			my $key = Crypt::URandom::urandom(32);
			require Crypt::Rijndael;
			require Data::Entropy::RawSource::CryptCounter;
			require Data::Entropy::Source;
			$default_entropy_source =
				Data::Entropy::Source->new(
					Data::Entropy::RawSource::CryptCounter
						->new(Crypt::Rijndael
							->new($key)),
					"getc");
		}
		$entropy_source = $default_entropy_source;
	}
	return $entropy_source;
}

=item with_entropy_source SOURCE, CLOSURE

The SOURCE is selected, so that it will be returned by C<entropy_source>,
and CLOSURE is called (with no arguments).  The SOURCE is selected only
during the dynamic scope of the call; after CLOSURE finishes, by whatever
means, the previously selected entropy source is restored.

SOURCE is normally a C<Data::Entropy::Source> object.  Alternatively,
it may be C<undef> to cause use of the default entropy source.  It may
also be a reference to a function of no arguments, which will be called to
generate the actual source only if required.  This avoids unnecessarily
initialising the source object if it is uncertain whether any entropy
will be required.  The source-generating closure may return a normal
source or C<undef>, but not another function reference.

=cut

sub with_entropy_source($&) {
	my($source, $closure) = @_;
	local $entropy_source = $source;
	$closure->();
}

=back

=head1 SEE ALSO

L<Data::Entropy::Algorithms>,
L<Data::Entropy::Source>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

Maintained by Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2011, 2025
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
