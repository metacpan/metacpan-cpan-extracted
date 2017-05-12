package Crypt::SSSS;

use strict;
use warnings;

our $VERSION = 0.3;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(ssss_distribute ssss_reconstruct);

use POSIX qw(ceil pow);
use Crypt::SSSS::Message;

require Carp;

sub ssss_distribute(%) {
    my (%data) = @_;

    my $message = $data{message} or Carp::croak 'Missed "message" argument';

    my $k = $data{k} or Carp::croak 'Missed "k" argument';
    my $n = $data{n} || $k;

    my $p = $data{p} || 257;

    my $shares = {};

    for my $x (1 .. $n) {
        $shares->{$x} = Crypt::SSSS::Message->new(p => $p);
    }

    my $chunks;
    if (my $ref = ref $message) {
        Carp::croak qw/"message" has unsupported type "$ref"/
          unless $ref eq 'Crypt::SSSS::Message';

        $chunks = $message->get_data;
    }
    else {
        $chunks = [unpack (($data{pack_size} || 'C') . '*', $message)];
    }
    while (@$chunks) {
        my @a = splice @$chunks, 0, $k;

        for my $x (1 .. $n) {

            my $res = 0;
            for my $pow (0 .. $k - 1) {
                $res += ($a[$pow] || 0) * pow($x, $pow);

            }

            # print "$x → ", $res % $p, "\n";
            $shares->{$x}->push_data($res % $p);
        }
    }

    $shares;
}

sub ssss_reconstruct(%) {
    my (%data) = @_;

    my $shares = $data{shares};
    my $p = $data{p} || '257';

    my @xs = keys %$shares;
    my $k = @xs;

    my %mdata;
    foreach my $x (@xs) {
        $mdata{$x} =
          Crypt::SSSS::Message->build_from_binary($p, $shares->{$x})
          ->get_data;
    }

    my $size = $data{size} || @{(values %mdata)[0]};

    my $message = '';

    my $pack_size = $data{pack_size} || 'C';

    for (my $l = 0; $l < $size; $l++) {
        my @fx = ();
        for my $i (@xs) {

            # Plynom
            my @pl = (1);

            # Divider
            my $d = 1;
            for my $j (@xs) {
                if ($j != $i) {

                    # Multiply polinoms
                    my @opl = @pl;
                    unshift @pl, 0;
                    for (my $i = 0; $i < @opl; $i++) {
                        $pl[$i] += -$j * $opl[$i];
                    }
                    $d *= $i - $j;
                }
            }
            $d += $p if $d < 0;

            my ($m) = extended_gcb($d, $p);
            $m += $p if $m < 0;

            while (@fx < @pl) {
                push @fx, 0;
            }

            # Add our polynom (multiplied by constant)
            for (my $j = 0; $j < @pl; $j++) {
                $fx[$j] += $m * $mdata{$i}->[$l] * $pl[$j];
            }
        }

        for (@fx) {
            $_ %= $p;
            $_ += $p if $_ < 0;
        }

        for (my $i = 0; $i < $k; $i++) {
            $message .= pack $pack_size, $fx[$i];
        }
    }

    $message;
}

sub extended_gcb {
    my ($a, $b) = @_;

    return (1, 0) if $b == 0;

    my $q = int($a / $b);
    my $r = $a % $b;
    my ($s, $t) = extended_gcb($b, $r);

    return ($t, $s - $q * $t);
}

1;
__END__

=head1 NAME

Crypt::SSSS - implementation of Shamir's Secret Sharing System.

=head1 SYNOPSIS

    use Crypt::SSSS;

    # use (3, 3) scheme
    my $shares = ssss_distribute(
        message => "\x06\x1c\x08",
        k       => 3,
    );

    # Save shares
    for my $share (1 .. 3) {
        open my $fh, '>', "share${share}.dat";
        print $fh $shares->{$share}->binary;
        close $fh;
    }

    # Reconstruct message
    my $ishares = {};
    for my $share (1 .. 3) {
        open my $fh, '<', "share${share}.dat";
        $ishares->{$share} = do {
            local $/;    # slurp!
            <$fh>;
        };
        close $fh;
    }

    print "Original message: ", sprintf '"\x%02x\x%02x\x%02x"',
      unpack('C*', ssss_reconstruct(p => 257, shares => $ishares));

=head1 DESCRIPTION

Implementation of Shamir's Secret Sharing Scheme.

=head1 ATTRIBUTES

Crypt::SSSS implements the following attributes.

=head2 C<ssss_distribute>

    my $shares = ssss_distribute(
        message => $message,
        k       => $k,
        p       => $p,         # 257 by default
        n       => $n,         # By default equals to k
    );

Distribute C<$message> to C<$n> shares, so that any C<$k> shares would be
enough to reconstruct the secret. C<$p> is a prime number.

Returns hashref of Crypt::SSSS::Message.

=head2 C<ssss_reconstruct>

    my $secret = ssss_reconstruct(
        shares => $shares,
        p      => $p,        # 257 by default
    );

Reconstruct message from given C<$shares>. C<$p> is a prime number used to
distribute message.

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 CREDITS

=over 2

=item Mohammad S Anwar (MANWAR)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2016, Sergey Zasenko.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
