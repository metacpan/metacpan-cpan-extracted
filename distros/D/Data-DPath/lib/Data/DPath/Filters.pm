package Data::DPath::Filters;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Magic functions available inside filter conditions
$Data::DPath::Filters::VERSION = '0.58';
use strict;
use warnings;

use Data::Dumper;
use Scalar::Util;
use constant {
              HASH   => 'HASH',
              ARRAY  => 'ARRAY',
              SCALAR => 'SCALAR',
      };

our $idx;
our $p;   # current point

sub affe {
        return $_ eq 'affe' ? 1 : 0;
}

sub idx { $idx }

sub size()
{
        no warnings 'uninitialized';

        return -1 unless defined $_;
        # speed optimization: first try faster ref, then reftype
        # ref
        return scalar @$_      if ref $_  eq ARRAY;
        return scalar keys %$_ if ref $_  eq HASH;
        return  1              if ref \$_ eq SCALAR;
        # reftype
        return scalar @$_      if Scalar::Util::reftype $_  eq ARRAY;
        return scalar keys %$_ if Scalar::Util::reftype $_  eq HASH;
        return  1              if Scalar::Util::reftype \$_ eq SCALAR;
        # else
        return -1;
}

sub key()
{
        no warnings 'uninitialized';
        my $attrs = defined $p->attrs ? $p->attrs : {};
        return $attrs->{key};
}

sub value()
{
        no warnings 'uninitialized';
        return $_;
}

sub isa($) {
        my ($classname) = @_;

        no warnings 'uninitialized';
        #print STDERR "*** value ", Dumper($_ ? $_ : "UNDEF");
        return $_->isa($classname) if Scalar::Util::blessed $_;
        return undef;
}

sub reftype() {
        return Scalar::Util::reftype($_);
}

sub is_reftype($) {
        no warnings 'uninitialized';
        return (Scalar::Util::reftype($_) eq shift);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Data::DPath::Filters - Magic functions available inside filter conditions

=head1 API METHODS

=head2 affe

Mysterious test function. Will vanish. Soon. Or will it really? No,
probably not. I like it. :-)

Returns true if the value eq "affe".

=head2 idx

Returns the current index inside array elements.

Please note that the current matching elements might not be in a
defined order if resulting from anything else than arrays.

=head2 size

Returns the size of the current element. If it is an array ref it
returns the number of elements, if it is a hash ref it returns number of keys,
if it is a scalar it returns 1, everything else returns -1.

=head2 key

If it is a hashref returns the key under which the current element is
associated as value. Else it returns undef.

This gives the key() function kind of a "look back" behaviour because
the associated point is already after that key.

=head2 value

Returns the value of the current element.

=head2 isa

Frontend to UNIVERSAL::isa. True if the current element is_a given
class.

=head2 reftype

Frontend to Scalar::Util::reftype.

Returns Scalar::Util::reftype of current element $_. With this you can
do comparison by yourself with C<eq>, C<=~>, C<~~> or whatever in
filter expressions.

=head2 is_reftype($EXPECTED_TYPE)

Frontend to Scalar::Util::reftype.

Checks whether Scalar::Util::reftype of current element $_ equals the
provided argument $EXPECTED_TYPE and returns true/false.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# sub parent, Eltern-Knoten liefern
# nextchild, von parent und mir selbst
# previous child
# "." als aktueller Knoten, kind of "no-op", daran aber Filter verknÃ¼pfbar, lÃ¶st //.[filter] und /.[filter]

# IDEA: functions that return always true, but track stack of values, eg. last taken index
#
#    //AAA/*[ _push_idx ]/CCC[ condition ]/../../*[ idx == pop_idx + 1]/
#
# This would take a way down to a filtered CCC, then back again and take the next neighbor.

