package Class::PseudoHash;
$Class::PseudoHash::VERSION = '1.10';

use 5.005;
use strict;
use vars qw/$FixedKeys $Obj $Proxy/;
use constant NO_SUCH_FIELD => 'No such pseudohash field "%s"';
use constant NO_SUCH_INDEX => 'Bad index while coercing array into hash';
use overload (
    '%{}'  => sub { $$Obj = $_[0]; return $Proxy },
    '""'   => sub { overload::AddrRef($_[0]) },
    '0+'   => sub { 
	my $str = overload::AddrRef($_[0]);
	hex(substr($str, index($str, '(') + 1, -1));
    },
    'bool' => sub { 1 },
    'cmp'  => sub { "$_[0]" cmp "$_[1]" },
    '<=>'  => sub { "$_[0]" cmp "$_[1]" }, # for completeness' sake
    'fallback' => 1,
);

$FixedKeys = 1;

sub import {
    no strict 'refs';

    my $class = shift;
    tie %{$Proxy}, $class;

    *{'fields::phash'} = sub {
	$class->new(@_);
    } unless defined $_[0];
}

sub new {
    my $class = shift;
    my @array = undef;

    if (UNIVERSAL::isa($_[0], 'ARRAY')) {
	foreach my $k (@{$_[0]}) {
	    $array[$array[0]{$k} = @array] = $_[1][$#array];
	}
    }
    else {
	while (my ($k, $v) = splice(@_, 0, 2)) {
	    $array[$array[0]{$k} = @array] = $v;
	}
    }

    bless(\@array, $class);
}

sub FETCH {
    my ($self, $key) = @_;

    $self = $$$self;

    return $self->[
	$self->[0]{$key} >= 1
	    ? $self->[0]{$key} :
	defined($self->[0]{$key})
	    ? _croak(NO_SUCH_INDEX) :
	$FixedKeys
	    ? _croak(NO_SUCH_FIELD, $key) :
	@$self
    ];
}

sub STORE {
    my ($self, $key, $value) = @_;

    $self = $$$self;

    return $self->[
	$self->[0]{$key} >= 1
	    ? $self->[0]{$key} :
	defined($self->[0]{$key})
	    ? _croak(NO_SUCH_INDEX) :
	$FixedKeys
	    ? _croak(NO_SUCH_FIELD, $key) :
	@$self
    ] = $value;
}

sub _croak {
    require Carp;
    Carp::croak(sprintf(shift, @_));
}

sub TIEHASH {
    bless \$Obj => shift;
}

sub FIRSTKEY {
    scalar keys %{$${$_[0]}->[0]};
    each %{$${$_[0]}->[0]};
}

sub NEXTKEY {
    each %{$${$_[0]}->[0]};
}

sub EXISTS {
    exists $${$_[0]}->[0]{$_[1]};
}

sub DELETE {
    delete $${$_[0]}->[0]{$_[1]};
}

sub CLEAR {
    @{$${$_[0]}} = ();
}

1;

__END__

=head1 NAME

Class::PseudoHash - Emulates Pseudo-Hash behaviour via overload

=head1 VERSION

This document describes version 1.10 of Class::PseudoHash, released
October 14, 2007.

=head1 SYNOPSIS

    use Class::PseudoHash;

    my @args = ([qw/key1 key2 key3 key4/], [1..10]);
    my $ref1 = fields::phash(@args);		# phash() override
    my $ref2 = Class::PseudoHash->new(@args);	# constructor syntax

=head1 DESCRIPTION

Due to its impact on overall performance of ordinary hashes, pseudo-hashes
are deprecated in Perl 5.8.

As of Perl 5.10, pseudo-hashes have been removed from Perl, replaced by
restricted hashes provided by L<Hash::Util>.  Additionally, Perl 5.10 no
longer supports the C<fields::phash()> API.

Although L<perlref/Pseudo-hashes: Using an array as a hash> recommends
against depending on the underlying implementation (i.e. using the first
array element as hash indice), there are undoubtly many legacy codebase
still depending on pseudohashes; elimination of pseudo-hashes would
therefore require a massive rewrite of their programs.

Back in 2002, as one of the primary victims, I tried to devise a drop-in
solution that could emulate exactly the same semantic of pseudo-hashes, thus
keeping all my legacy code intact.  So C<Class::PseudoHash> was born.

Hence, if your code use the preferred C<fields::phash()> function, just write:

    use fields;
    use Class::PseudoHash;

then everything will work like before.  If you are creating pseudo-hashes 
by hand (C<[{}]> anyone?), just write this instead:

    $ref = Class::PseudoHash->new;

and use the returned object in whatever way you like.

=head1 NOTES

If you set C<$Class::PseudoHash::FixedKeys> to a false value and tries
to access a non-existent hash key, then a new pseudo-hash entry will be
created silently.  This is most useful if you're already using untyped
pseudo-hashes, and don't want the compile-time checking feature.

Compile-time validating of keys is not possible with this module, for
obvious reasons.  Also, the performance will not be as fast as typed
pseudo-hashes (but generally faster than untyped ones).

=head1 SEE ALSO

L<fields>, L<perlref/Pseudo-hashes: Using an array as a hash>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2002, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
