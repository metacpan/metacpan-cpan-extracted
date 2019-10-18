package Acme::September::Eternal;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(eternalseptemberize);
our $VERSION = '1.0';

use Date::Manip;
use Lingua::EN::Numbers::Ordinate;

sub eternalseptemberize {
    # Change date&time string to "Eternal september" date string
    my ($indate) = @_;

    my $sepdate = '1993-09-01 00:00:00';

    my $inmangler = Date::Manip::Date->new();
    my $sepmangler = Date::Manip::Date->new();

    my ($inparseerr) = $inmangler->parse($indate);

    if(defined($inparseerr) && $inparseerr) {
        return '';
    }

    my ($sepparseerr) = $sepmangler->parse($sepdate);

    if(defined($sepparseerr) && $sepparseerr) {
        return '';
    }

    my $delta = $inmangler->calc($sepmangler, 1);
    my @deltafields = $delta->value();
    my $days = ordinate(int($deltafields[4] / 24) + 1);
    my $result = $inmangler->printf("%a, $days et. Sept. 1993 %H:%M:%S");

    return $result;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::September::Eternal - Calculate the "eternal september" date string

=head1 SYNOPSIS

  use Acme::September::Eternal;

  print eternalseptemberize('2019-10-18 10:28:00'), "\n";

=head1 DESCRIPTION

This module calculates a nicely formatted string for the "eternal september" date for any given date.

=head2 eternalSeptemberize()

This function takes a date string (anything that L<Date::Manip> can parse should be OK) and returns it formatted
as something like "Fri, 9544th et. Sept. 1993 10:28:23"

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Eternal_September>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
