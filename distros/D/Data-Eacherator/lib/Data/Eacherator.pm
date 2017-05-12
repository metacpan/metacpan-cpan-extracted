package Data::Eacherator;

use strict;
use warnings;

use base qw(Exporter);
use vars qw(@EXPORT_OK $VERSION);

use Carp;

$VERSION = "0.01";
@EXPORT_OK = qw(eacherator);

=head1 NAME

Data::Eacherator - simple each-like iterator generator for hashes and arrays

=head1 SYNOPSIS

  my $iter = eacherator($hash_or_array);

  while (my ($k, $v) = $iter->()) {
      # ...
  }

=head1 DESCRIPTION

This module is designed as a simple drop-in replacement for "each" on
those occasions when you need to iterate over a hash I<or> an array.

That is, if C<$data> is a hash, and you're happily doing something
like:

  while (my ($k, $v) = each %$data) {
      # ...
  }

but then decide that you also want to loop over C<$data> in the event
that it's an array, you can do:

  my $iter = eacherator($data);

  while (my ($k, $v) = $iter->()) {
      # ...
  }

(You may wish to use this package if, for example, you have a module
that happily iterates over a hash, but then discover that you also
need to iterate over an "ordered" hash--in this case you can just
switch curly brackets to square brackets and use C<eacherator()> to
generate a drop-in replacement for each.)

=head1 FUNCTIONS

=over 4

=item $iter_fn = eacherator($hash_or_array_ref)

Returns a function (closure) that behaves like "each".

=back

=head1 PERFORMANCE

Not tested; it's probably quite a bit slower than regular "each" on
hashes, though.

=head1 SEE ALSO

If you need something more sophisticated, or something with
similar--but different--behaviour, try C<Data::Iter>,
C<Data::Iterator>, C<Array::Each> or C<Object::Iterate>.  (All of
these generate iterators (some with more each-like semantics than
others), but none are indifferent as to whether they receive a hash
or array.)

Depending on what you're trying to do, C<Maptastic> may also be
useful.

=head1 AUTHOR

Michael Stillwell <mjs@beebo.org>

=cut

sub eacherator {
    my ($data) = @_;
    
    if (ref($data) eq "HASH") {
	return sub { 
	    each %$data 
	};
    }

    elsif (ref($data) eq "ARRAY") {
	my $i = 0;
	return sub {
	    if (@$data >= $i+2) {
		$i += 2;
		return ($data->[$i-2], $data->[$i-1])
	    } 
	    else {
		$i = 0;
		return ();
	    }
	};
    }
    
    else { croak "error: can't iterate over something that's not a HASH or ARRAY" }
}

1;
