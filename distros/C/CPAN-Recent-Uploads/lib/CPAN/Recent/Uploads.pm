package CPAN::Recent::Uploads;
$CPAN::Recent::Uploads::VERSION = '0.10';
#ABSTRACT: Find the distributions recently uploaded to CPAN

use strict;
use warnings;
use Carp;
use YAML::Syck;
use File::Spec;
use CPAN::Recent::Uploads::Retriever;

my $MIRROR = 'http://www.cpan.org/';
my @times = qw(1h 6h 1d 1W 1M 1Q 1Y);
my %periods  = (
  '1h' => (60*60),
  '6h' => (60*60*6),
  '1d' => (60*60*24),
  '1W' => (60*60*24*7),
  '1M' => (60*60*24*30),
  '1Q' => (60*60*24*90),
  '1Y' => (60*60*24*365.25),
);

sub recent {
  my $epoch = shift;
  $epoch = shift if $epoch and eval { $epoch->isa(__PACKAGE__) };
  $epoch = ( time() - ( 7 * 24 * 60 * 60 ) )
    unless $epoch and $epoch =~ /^\d+$/ and
      $epoch <= time() and $epoch >= ( time() - $periods{'1Y'} );
  my $period = _period_from_epoch( $epoch );
  my $mirror = shift || $MIRROR;
  my %data;
  OUTER: foreach my $foo ( @times ) {
    my $yaml = CPAN::Recent::Uploads::Retriever->retrieve( time => $foo, mirror => $mirror );
    my @yaml;
    eval { @yaml = YAML::Syck::Load( $yaml ); };
    croak "Unable to process YAML\n" unless @yaml;
    my $record = shift @yaml;
    die unless $record;
    RECENT: foreach my $recent ( reverse @{ $record->{recent} } ) {
      next RECENT unless $recent->{path} =~ /\.(tar\.gz|tgz|tar\.bz2|zip)$/;
      if ( $recent->{type} eq 'new' ) {
        ( my $bar = $recent->{path} ) =~ s#^id/##;
        next RECENT if $recent->{epoch} < $epoch;
        {
          my @parts = split m!/!, $bar;
          next RECENT if $parts[3] =~ m!Perl6!i;
        }
        $data{ $bar } = $recent->{epoch};
      }
      else {
        ( my $bar = $recent->{path} ) =~ s#^id/##;
        delete $data{ $bar } if exists $data{ $foo };
      }
    }
    last if $foo eq $period;
  }
  return \%data unless wantarray;
  return sort { $data{$a} <=> $data{$b} } keys %data;
}

sub _period_from_epoch {
  my $epoch = shift || return;
  foreach my $period ( @times ) {
    return $period if ( time() - $periods{$period} ) < $epoch;
  }
  return;
}

q[Whats uploaded, Doc?];

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Recent::Uploads - Find the distributions recently uploaded to CPAN

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use CPAN::Recent::Uploads;

  my $weekago = time() - ( 7 * 24 * 60 * 60 );

  my @uploads = CPAN::Recent::Uploads->recent( $weekago );

  # as a one liner (seeing the weeks worth of uploads).

  perl -MCPAN::Recent::Uploads -le 'print for CPAN::Recent::Uploads->recent;'

=head1 DESCRIPTION

CPAN::Recent::Uploads provides a mechanism for obtaining a list of the
RECENT uploads to C<CPAN> as determined from the files produced by
L<File::Rsync::Mirror::Recentfile> that exist in the C<authors/> directory
on C<CPAN>.

=head1 FUNCTIONS

=over

=item C<recent>

Takes two optional arguments. The first argument is an C<epoch> time you wish to
find the uploads since. If it is not supplied the default is the current time minus
one week. The second argument is the URL of a C<CPAN> mirror you wish to query. If it
is not supplied then C<http://www.cpan.org/> is used.

In a list context it returns a list of uploaded distributions ordered by the time they were
uploaded (ie. oldest first, increasing in recentness ).

In a scalar context it returns a hash reference keyed on distribution with the values being the
C<epoch> time that that distribution entered C<CPAN>.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
