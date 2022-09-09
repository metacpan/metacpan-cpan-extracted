package CTK::Digest::M11R;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Digest::M11R - interface for modulus 11 (recursive) check digit calculation

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK::Digest::M11R;
    my $m11r = CTK::Digest::M11R->new();
    my $digest = $m11r->digest( "123456789" ); # 5

=head1 DESCRIPTION

This is Digest backend module that provides calculate the modulus 11 (recursive) check digit

=head1 METHODS

=head2 digest

    my $digest = $m11r->digest( "123456789" ); # 5

Returns M11R checkdigit by specified digits-string

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Digest>, L<Algorithm::CheckDigits::M11_015>, B<check_okpo()>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/ $VERSION /;
$VERSION = 1.01;

use Carp;

use parent qw/CTK::Digest/;

sub digest {
    # See also: Algorithm::CheckDigits::M11_015 and check_okpo()
    my $self = shift;
    my $data = shift;
    $self->{data} = $data if defined $data;
    my $test = $self->{data};
    croak "Incorrect input digit-string" if !$test || $test =~ m/[^0-9]/g;
    my $len = length($test);
    my $iters = ($len + (($len & 1) ? 1 : 0)) / 2;
    my @digits = split(//, $test); # Get all digits from input string of chars
    #printf "Test=%s; len=%d; iters=%d\n", $test, $len, $iters;

    my $w_lim = 10; # Maximum for round-robin(10) weight list: 1,2,3,4,5,6,7,8,9,10,1,2,3,4,5...
    my $step = 2; # Step for weight list offset calculation for next iteration

    # Calculation sum for one weight list by ofset
    my $calc = sub {
        my $off = shift || 0;
        my $s = 0;
        for (my $i = 0; $i < $len; $i++) {
            my $w = (($i + $off) % $w_lim) + 1;
            $s += ($w * $digits[$i]);
            #printf " > i=%d; d=%d; w=%d; sum=%d\n", $i, $digits[$i], $w, $s;
        }
        return $s % 11;
    };

    # Main cycle
    my $sum = 0;
    for (my $j = 0; $j < $iters; $j++) {
        my $offset = $j*$step;
        $sum = $calc->($offset);
        #printf " >> j=%d; offset=%d; sum=%d\n", $j, $offset, $sum;
        last if $sum < 10;
    }
    $sum = 0 if $sum >= 10; # 0 if incorrect again
    #printf " >>> sum=%d\n", $sum;

    return $sum;
}

1;

__END__
