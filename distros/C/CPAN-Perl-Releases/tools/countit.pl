use strict;
use warnings;
use CPAN::Perl::Releases;

foreach my $ver ( sort keys %{ $CPAN::Perl::Releases::data } ) {
  print "$ver: ", join (' ', scalar keys %{ $CPAN::Perl::Releases::data->{ $ver } }, keys %{ $CPAN::Perl::Releases::data->{ $ver } } ), "\n";
}
