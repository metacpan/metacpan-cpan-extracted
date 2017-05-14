use strict;
use warnings;
package Conclave::OTK::Backend::4store;
# ABSTRACT: OTK backend for 4store
use parent qw/Conclave::OTK::Backend/;

use LWP::UserAgent;
use HTTP::Request::Common qw/PUT DELETE/;

sub new {
  my ($class, $base_uri, %opts) = @_;
  my $self = bless({}, $class);

  $self->{base_uri} = $base_uri;
  $self->{query} = $opts{query};
  $self->{update} = $opts{update};
  $self->{restws} = $opts{restws};

  return $self;
}

sub init {
  my ($self, $rdfxml) = @_;
  return unless $rdfxml;

  my $restws = $self->{restws};
  $restws =~ s/\/+$//;
  my $url = $restws.'/'.$self->{base_uri};
  my $ua = LWP::UserAgent->new(timeout => 300);

  my $response = $ua->request(PUT $url, Content => $rdfxml);
  unless ($response->is_success) {
    print STDERR "PUT failed: ", $response->status_line, "\n";
  }
}

sub update {
  my ($self, $sparql) = @_;

  my $params = { 'update' => $sparql };
  my $ua = new LWP::UserAgent(timeout => 300);
  $ua->agent('perlproc/1.0');

  my $response = $ua->post($self->{update}, $params );
  return $response->is_success;
}

sub query {
  my ($self, $sparql) = @_;

  my $params = { 'query' => $sparql, 'soft-limit' => -1 };
  my $ua = new LWP::UserAgent(timeout => 300);
  $ua->agent('perlproc/1.0');
  $ua->default_header('Accept' => 'text/tab-separated-values' );

  my $response = $ua->post($self->{query}, $params );
  my @result;

  unless ($response->is_success) {
    print STDERR "Query failed: ", $response->status_line, "\n";
  }
  else {
    my $tsv = $response->decoded_content;
    # FIXME
    my @lines = split /\n/, $tsv;
    shift @lines;
    foreach my $triple (@lines) {
      $triple =~ s/[<>]//g;
      my @l = split /\t/, $triple;
      if (scalar(@l) == 1) {
        push @result, $l[0];
      }
      else {
        push @result, [@l];
      }
    }
  }
  return @result;
}

sub delete {
  my ($self) = @_;

  my $restws = $self->{restws};
  $restws =~ s/\/+$//;
  my $url = $restws.'/'.$self->{base_uri};
  my $ua = LWP::UserAgent->new(timeout => 300);

  my $response = $ua->request(DELETE $url);
  unless ($response->is_success) {
    print STDERR "DELETE failed: ", $response->status_line, "\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Conclave::OTK::Backend::4store - OTK backend for 4store

=head1 VERSION

version 0.01

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2015 by Nuno Carvalho <smash@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
