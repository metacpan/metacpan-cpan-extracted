package Blessed::Merge;

use 5.006;

our $VERSION = '1.01';
use strict;
use warnings;
use Scalar::Util qw/reftype/;
use Carp qw/croak/;
use Combine::Keys qw/combine_keys/;
use Tie::IxHash;

sub new {
	my ($pkg, $args) = (shift, reftype $_[0] || "" eq 'HASH' ? $_[0] : {@_});
	my $self = bless $args, $pkg;
	$self->{$_} = $self->{$_} // 1 foreach (qw/same blessed/);
	$self->{$_} = $self->{$_} // 0 foreach(qw/unique_array unique_hash/);
	$self->{itterator} = 1;
	return $self;
}

sub merge {
	my ($self, $base_bless, $new) = (shift, ref $_[0], shift);
	tie my %isa, 'Tie::IxHash';
	$isa{$base_bless} = $new;
	map {
		if ( $self->{same} ) {
			croak 'Attempting to merge two different *packages*' unless $base_bless eq ref $_;
		} else {
			my $r = ref $_;
			$isa{$r} = $_ unless $r =~ m/HASH|ARRAY|SCALAR/;
		}
		$new = $self->_merge($new, $_);
	} @_;
	for my $f (keys %isa) {
		my $check = $isa{$f} or next;
		for (keys %isa) {
			$_ eq $f and next;
			delete $isa{$_} if $check->isa($_); 
		}
	}
	return $self->{blessed} ? scalar keys %isa == 1 ? bless $new, $base_bless : do { 
		my $class = sprintf "Blessed::Merge::__ANON__::%s", $self->{itterator}++;
		eval sprintf('package %s; our @ISA = qw/%s/; 1;', $class, join ' ', keys %isa);
		return bless $new, $class;
	} : $new;
}

sub _merge {
	my ($self, $new, $merger) = @_;
	return $new unless defined $merger;
	my $new_ref = reftype($new) || '';
	my $merger_ref = reftype($merger) || 'SCALAR';
	$merger_ref eq 'HASH' ? do {
		$new = {} if ( $new_ref ne 'HASH' );
		return { 
			$self->{unique_hash} 
				? $self->_unique_merge($merger_ref, $new, $merger) 
				: map +( $_ => $self->_merge( $new->{$_}, $merger->{$_} ) ), combine_keys($new, $merger) 
		};
	} : $merger_ref eq 'ARRAY' ? do {
		$new_ref eq 'ARRAY' ? do {
			my $length = sub {$_[0] < $_[1] ? $_[1] : $_[0]}->(scalar @{$new}, scalar @{$merger});
			[ $self->{unique_array} 
				? $self->_unique_merge($merger_ref, $new, $merger, $length)
				: map { $self->_merge($new->[$_], $merger->[$_]) } 0 .. $length - 1 
			];
		} : [ map { $self->_merge('', $_ ) } @{ $merger } ]; # destroy da references
	} : $merger;
}

sub _unique_merge {
	my ($s, $r, $n, $m, $l) = @_;
	($r eq 'ARRAY') && do {
		my (@z, %u, $x1, $x2);
		for (my $i = 0; $i < $l; $i++) {
			my $c = grep {
				my ($x) = reftype(\$_);
				$x eq 'SCALAR' ? !$_ || exists $u{$_} ? 1 : do { $u{$_} = 1; push @z, $_; } : 0; 
			} ($n->[$i], $m->[$i]);
			do { ($x1, $x2) = (reftype($n->[$i]), reftype($m->[$i])); $c == 0 } 
				? $x1 eq $x2 
					? push @z, $s->_merge($n->[$i], $m->[$i]) 
					: push @z, $n->[$i], $m->[$i] 
				: $x1 
					? push @z, $n->[$i] 
					: push @z, $m->[$i] if $c != 2;
		}
		return @z;
	};
	my %z = %{ $n };
	map {
		my $x = reftype($m->{$_}) || 'SCALAR';
		exists $z{$_} ? $x ne 'SCALAR' && $x eq reftype($z{$_}) 
			? do { $z{$_} = $s->_merge($z{$_}, $m->{$_}) } : '*\o/*' : do { $z{$_} = $m->{$_} }
	} keys %{ $m };
	return %z;
}

1;

__END__

=head1 NAME

Blessed::Merge - Merge Blessed Refs.

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

	use Blessed::Merge;

	my $blessed = Blessed::Merge->new({ same => 0, unique_hash => 1, unique_array => 1 });

	my $world = $blessed->merge($obj1, $obj2, $obj3, $obj4, $obj5);

=head1 Description

Deeply merge x number of blessed references.

=head2 new

Instantiate a new Blessed::Merge object.

	my $blessed = Blessed::Merge->new(%options);

=head3 options

=head4 unique_hash

Setting unique_hash will only set undefined key/values in the hash.

	use JSONP;
	use overload::x qw/n/;

	my $blessed = Blessed::Merge->new({ unique_hash => 1 });
	
	my ($one, $two) = JSONP->new() x n(2);
	
	$one->css = {
		'@media only screen (min-width: 33.75em)' => {
			'.container' => {
				'width' => '80%'
			}
		}
	};

	$two->css = {
		'@media only screen (min-width: 33.75em)' => {
			'.container' => {
				'width' => '100%',
			}
		}
	};
	
	my $new = $blessed->merge($one, $two);
	
	$new->serialize;  # '{"css":{"@media only screen (min-width: 33.75em)":{".container":{"width":"80%"}}}}'

=head4 unique_array

Setting unique_array will merge arrays based on order and unique value.

	my $blessed = Blessed::Merge->new({ unique_array => 1 });

	my $one = JSONP->new();
	
	$one->graft('one', '{"b":["a", "c", "e"]}');
	$one->graft('two', '{"b":["b", "d", "f"]}');
	$one->graft('three', '{"b":["a", "b", "c", "d"]}');
	
	my $new = $blessed->merge($one->one, $one->two, $one->three);
	
	$new->serialize;  #'{"b":["a","b","c","d","e","f"]}'

=head4 blessed

Disable to return the non blessed ref.

	use JSONP;
	use overload::x qw/n/;

	my $blessed = Blessed::Merge->new({ blessed => 1 });

	my ($one, $two) = JSONP->new() x n(2);
	
	$one->graft('level', '{"b":["a", "c", "e"]}');
	$two->graft('level', '{"b":["b", "d", "f"]}');
	
	my $new = $blessed->merge($one, $two);
	
	$new->level->b->serialize;  # ["b","d","f"]

=head4 same

Disable to prevent the same ref check.
	
	my $blessed = Blessed::Merge->new({ same => 0 });

	my $foo = Foo->new;
	my $bar = Bar->new;

	my $new = $blessed->merge($foo, $bar);

	$new->method_from_foo();
	$new->method_from_bar();

=head2 merge

	$blessed->merge($foo x n(100000));

=head1 AUTHOR

Robert Acock, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-blessed-merge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Blessed-Merge>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Blessed::Merge

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Blessed-Merge>

=item * Search CPAN

L<http://search.cpan.org/dist/Blessed-Merge/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017->2025 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Blessed::Merge
