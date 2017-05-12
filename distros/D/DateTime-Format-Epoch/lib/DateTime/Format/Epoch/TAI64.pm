package DateTime::Format::Epoch::TAI64;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.13';

use DateTime;
use DateTime::Format::Epoch;

use Params::Validate qw/validate/;
use Math::BigInt ('lib' => $^O eq 'MSWin32' ? 'Pari,FastCalc' : 'GMP,Pari,FastCalc');

@ISA = qw/DateTime::Format::Epoch/;

# Epoch is 1970-01-01 00:00:00 TAI, is 1969-12-31T23:59:50 'utc'
my $epoch = DateTime->new( year => 1969, month => 12, day => 31,
                           hour => 23, minute => 59, second => 50 );

my $start = Math::BigInt->new(1) << 62;

sub new {
	my $class = shift;
    my %p = validate( @_,
                      { format => { regex => qr/^string|number$/,
                                    default => 'number' },
                      });

    my $self = $class->SUPER::new( epoch => $epoch,
                                   unit  => 'seconds',
                                   type  => 'bigint',
                                   skip_leap_seconds => 0,
                                   start_at => $start );
    $self->{is_string} = ($p{format} eq 'string');

    return $self;
}

sub format_datetime {
    my ($self, $dt) = @_;

    my $n = $self->SUPER::format_datetime($dt);

    if ($self->{is_string}) {
        my $str = $n->as_hex;
        my ($hex) = $str =~ /^0x(\w+)$/
                        or die "Unknown BigInt format '$str'\n";
        my $retval = pack "H*", $hex;
        $n = "0" x (8 - length$retval) . $retval;
    }

    return $n;
}

sub parse_datetime {
    my ($self, $n) = @_;

    if ($self->{is_string}) {
        my $hexstr = '0x' . unpack 'H*', $n;
        $n = Math::BigInt->new($hexstr);
    }

    return $self->SUPER::parse_datetime($n);
}

1;
__END__

=head1 NAME

DateTime::Format::Epoch::TAI64 - Convert DateTimes to/from TAI64 values

=head1 SYNOPSIS

  use DateTime::Format::Epoch::TAI64;

  my $dt = DateTime::Format::Epoch::TAI64
                ->parse_datetime( '4611686019483526367' );
   # 2003-06-20T19:49:59

  DateTime::Format::Epoch::TAI64->format_datetime($dt);
   # 4611686019483526367

  my $formatter = DateTime::Format::Epoch::TAI64->new();

  $dt = $formatter->parse_datetime( '4611686019483526367' );
   # 2003-06-20T19:49:59

  $formatter->format_datetime($dt);
   # 4611686019483526367

  my $str_frmt = DateTime::Format::Epoch::TAI64->new(
                                                format => 'string' );

  $dt = $str_frmt->parse_datetime( "\x40\0\0\0\x3e\xf3\x69\x6a" );
   # 2003-06-20T19:49:59

  $str_frmt->format_datetime($dt);
   # "\x40\0\0\0\x3e\xf3\x69\x6a"

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to a TAI64 value. The TAI64 timescale
covers the entire expected lifespan of the universe (at least, if you
expect the universe to be closed).

=head1 METHODS

Most of the methods are the same as those in L<DateTime::Format::Epoch>.
The only difference is the constructor.

=over 4

=item * new( [format => 'string'] )

Constructor of the formatter/parser object. If the optional format
parameter is set to 'string', TAI64 values will be expected to be 8
byte strings.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 COPYRIGHT

Copyright (c) 2003, 2004 Eugene van der Pijll.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

http://cr.yp.to/time.html

=cut
