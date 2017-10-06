package CPAN::Recent::Uploads::Retriever;
$CPAN::Recent::Uploads::Retriever::VERSION = '0.14';
#ABSTRACT: Retrieves recentfiles from a CPAN mirror

use strict;
use warnings;
use Carp;
use URI;
use HTTP::Tiny;
use File::Spec::Unix;

my @times = qw(1h 6h 1d 1W 1M 1Q 1Y);

sub retrieve {
  my $class = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $self = bless \%opts, $class;
  $self->{uri} = URI->new( $self->{mirror} || 'http://www.cpan.org/' );
  croak "Unknown scheme\n"
      unless $self->{uri} and $self->{uri}->scheme and
             $self->{uri}->scheme =~ /^(http|ftp)$/i;
  $self->{time} = '6h'
      unless $self->{time}
         and grep { $_ eq $self->{time} } @times;
  $self->{uri}->path( File::Spec::Unix->catfile( $self->{uri}->path, 'authors', 'RECENT-' . $self->{time} . '.yaml' ) );
  return $self->_fetch();
}

sub _fetch {
  my $self = shift;
  open my $fooh, '>', \$self->{foo} or die "$!\n";
  my $ua = HTTP::Tiny->new();
  my $resp = $ua->get( $self->{uri}->as_string, { 'data_callback' => sub { my $data = shift; print {$fooh} $data; } } );
  close $fooh;
  return $self->{foo} if $resp->{success};
}

q[Woof];

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Recent::Uploads::Retriever - Retrieves recentfiles from a CPAN mirror

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use CPAN::Recent::Uploads::Retriever;

  my $yamldata = CPAN::Recent::Uploads::Retriever->retrieve();

=head1 DESCRIPTION

CPAN::Recent::Uploads::Retriever is a helper module for L<CPAN::Recent::Uploads> that retrieves
individual C<RECENT-xx.yaml> files from a CPAN mirror.

=head1 CONSTRUCTOR

=over

=item C<retrieve>

Takes two optional arguments. The first argument is an identifier for the C<RECENT> file to retrieve and
can be either, C<1h>, C<6h>, C<1d>, C<1W>, C<1M>, C<1Q> or C<1Y>. The default is C<6h>.
The second argument is a CPAN mirror URL to retrieve said files from.

Returns a scalar of YAML data on success, C<undef> otherwise.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
