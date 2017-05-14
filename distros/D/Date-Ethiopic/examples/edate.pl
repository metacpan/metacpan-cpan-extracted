#!/usr/bin/perl -w

require Date::Ethiopic::ET::am;

my $edate = new Date::Ethiopic::ET::am ( epoch => time, calscale => "gregorian" );

print $edate->full_date, "\n";


__END__

=head1 NAME

edate.pl - Unix like C<date> for Amharic.

=head1 SYNOPSIS

./edate.pl

=head1 DESCRIPTION

A demonstrator script to illustrate L<Date::Ethiopic::ET::am> usage.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
