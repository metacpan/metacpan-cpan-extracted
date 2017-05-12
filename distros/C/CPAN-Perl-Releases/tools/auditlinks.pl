use strict;
use warnings;
use Test::More qw[no_plan];
use CPAN::Perl::Releases qw[perl_tarballs perl_versions];
use HTTP::Tiny;

my $baseurl = 'http://cpan.mirror.local/CPAN/authors/id/';

foreach my $vers ( perl_versions() ) {
  my $balls = perl_tarballs( $vers );
  foreach my $tarball ( keys %$balls ) {
    my $url = $baseurl . $balls->{$tarball};
    my $resp = HTTP::Tiny->new( )->get( $url );
    unless ( $resp->{success} ) {
      fail( "$vers -> $tarball -> $url" );
    }
    else {
      pass( "$vers -> $tarball -> $url" );
    }
  }
}
