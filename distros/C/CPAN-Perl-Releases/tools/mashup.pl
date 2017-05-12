use strict;
use warnings;
use Perl::Version;
use Module::CoreList;
use CPAN::Perl::Releases;

foreach my $ver ( keys %{ $CPAN::Perl::Releases::data } ) {
  next if $ver =~ /(RC|TRIAL)/;
  my $pv = Perl::Version->new( $ver );
  my $num = $pv->numify;
  $num =~ s/_//g;
  if ( exists $Module::CoreList::released{ 0+$num } ) {
    print "$ver: ", $Module::CoreList::released{ 0+$num }, "\n";
  }
  else {
    warn "SHIT NOTHING FOR '$ver', '$num'\n";
  }
}
