package DateTime::Format::EMIUCP;

=head1 NAME

DateTime::Format::EMIUCP - Parse time formats for EMI-UCP protocol

=head1 SYNOPSIS

  use DateTime::Format::EMIUCP;

  my $scts = DateTime::Format::EMIUCP->parse_datetime('030212065530');
  print $scts->ymd; # 2012-02-03
  print $scts->hms; # 06:55:30

  my $vp = DateTime::Format::EMIUCP->parse_datetime('0302120655');
  print $vp->ymd; # 2012-02-03
  print $vp->hms; # 06:55:00

=head1 DESCRIPTION

These formats are part of EMI-UCP protocol message. EMI-UCP protocol is
primarily used to connect to short message service centers (SMSCs) for mobile
telephones.

SCTS is a string of 12 numeric characters which represents Service Center
time-stamp in ddMMyyHHmmss format.

DSCTS is a string of 12 numeric characters which represents Delivery
time-stamp in ddMMyyHHmmss format.

DDT is a string of 10 numeric characters which represents deferred delivery
time in ddMMyyHHmm format.

VP is a string of 10 numeric characters which represents validity period time
in ddMMyyHHmm format.

See EMI-UCP Interface 5.2 Specification for further explanations.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0300';

=head1 METHODS

=over

=item DateTime I<$dt> = $fmt->parse_datetime(Str I<$scts>)

Given a string in the pattern specified in the constructor, this method will
return a new DateTime object.

Year number below 70 means the date before year 2000.

If given a string that doesn't match the pattern, the formatter will croak.

=back

=cut

use DateTime::Format::Builder (
    parsers => {
        parse_datetime => [
            {
                params => [qw( day month year hour minute second )],
                regex  => qr/^(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
                postprocess => \&_fix_year,
            },
            {
                params => [qw( day month year hour minute )],
                regex  => qr/^(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
                postprocess => \&_fix_year,
            },
        ]
    }
);


sub _fix_year {
    my %args = @_;
    my ($date, $p) = @args{qw( input parsed )};
    $p->{year} += $p->{year} > 69 ? 1900 : 2000;
    return 1;
};


1;

__END__

=for readme continue

=head1 PREREQUISITES

=over 2

=item *

L<DateTime::Format::Builder>

=back

=head1 SEE ALSO

L<DateTime::Format::EMIUCP::DDT>,
L<DateTime::Format::EMIUCP::DSCTS>,
L<DateTime::Format::EMIUCP::SCTS>,
L<DateTime::Format::EMIUCP::VP>,
L<DateTime>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-EMIUCP>

The code repository is available at
L<http://github.com/dex4er/perl-DateTime-Format-EMIUCP>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
