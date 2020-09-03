package CTK::Digest::FNV32a; # $Id: FNV32a.pm 294 2020-09-02 06:36:52Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Digest::FNV32a - FNV32a Digest calculation for short strings

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK::Digest::FNV32a;
    my $fnv32a = CTK::Digest::FNV32a->new();
    my $digest = $fnv32a->digest( "123456789" ); # 0xbb86b11c
    my $hexdigest = $fnv32a->digest( "123456789" ); # bb86b11c

=head1 DESCRIPTION

This is Digest backend module that provides calculate FNV32a Digest for short strings

=head1 METHODS

=head2 digest

    my $digest = $fnv32a->digest( "123456789" ); # 0xbb86b11c

Returns FNV32a Digest

=head2 hexdigest

    my $hexdigest = $fnv32a->digest( "123456789" ); # bb86b11c

Returns FNV32a Digest in hex form

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Digest>, L<https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function>,
L<http://isthe.com/chongo/tech/comp/fnv/>, L<Digest::FNV::PurePerl>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2020 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/ $VERSION /;
$VERSION = 1.01;

use parent qw/CTK::Digest/;

sub digest {
    my $self = shift;
    my $string = $self->{data};
    my $hval = 0x811c9dc5;

    if ((1<<32) == 4294967296) {
        foreach my $c (unpack('C*', $string)) {
            $hval ^= $c;
            $hval += ((($hval << 1)) + (($hval << 4)) + (($hval << 7)) + (($hval << 8)) + (($hval << 24)));
            $hval = $hval & 0xffffffff;
        }
    } else {
        use bigint;
        foreach my $c (unpack('C*', $string)) {
            $hval ^= $c;
            $hval += ((($hval << 1)) + (($hval << 4)) + (($hval << 7)) + (($hval << 8)) + (($hval << 24)));
            $hval = $hval & 0xffffffff;
        }
    }
    return $hval;
}
sub hexdigest {
    my $self = shift;
    return sprintf("%x", $self->digest(@_));
}

1;

__END__
