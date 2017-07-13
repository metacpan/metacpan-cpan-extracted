#!/usr/bin/env perl
use strict;
use warnings;


use AI::PredictionClient::InceptionClient;
# PODNAME: Inception.pl
# ABSTRACT: Example command line Inception client

use Moo;
use MooX::Options;
use 5.010;
use Data::Dumper qw(Dumper);
use Perl6::Form;

my $default_host            = '127.0.0.1';
my $default_port            = '9000';
my $default_model           = 'inception';
my $default_model_signature = 'predict_images';

option image_file => (
  is       => 'ro',
  required => 1,
  format   => 's',
  doc      => '* Required: Path to image to be processed'
);
option host => (
  is       => 'ro',
  required => 0,
  format   => 's',
  default  => $default_host,
  doc      => "IP address of the server [Default: $default_host]"
);
option port => (
  is       => 'ro',
  required => 0,
  format   => 's',
  default  => $default_port,
  doc      => "Port number of the server [Default: $default_port]"
);
option model_name => (
  is       => 'ro',
  required => 0,
  format   => 's',
  default  => $default_model,
  doc      => "Model to process image [Default: $default_model]"
);
option model_signature => (
  is       => 'ro',
  required => 0,
  format   => 's',
  default  => $default_model_signature,
  doc      => "API signature for model [Default: $default_model_signature]"
);
option debug_verbose => (is => 'ro', doc => 'Verbose output');
option debug_loopback_interface => (
  is       => 'ro',
  required => 0,
  doc      => "Test loopback through dummy server"
);
option debug_camel => (
  is       => 'ro',
  required => 0,
  doc      => "Test using camel image"
);

sub run {
  my ($self) = @_;

  my $image_ref = $self->read_image($self->image_file);

  my $client = AI::PredictionClient::InceptionClient->new(
    host => $self->host,
    port => $self->port
  );

  $client->model_name($self->model_name);
  $client->model_signature($self->model_signature);
  $client->debug_verbose($self->debug_verbose);
  $client->loopback($self->debug_loopback_interface);
  $client->camel($self->debug_camel);

  printf("Sending image %s to server at host:%s  port:%s\n",
    $self->image_file, $self->host, $self->port);

  if ($client->call_inception($image_ref)) {

    my $results_ref         = $client->inception_results;
    my $classifications_ref = $results_ref->{'classes'};
    my $scores_ref          = $results_ref->{'scores'};
    my $comments            = 'Clasification Results for ' . $self->image_file;

    my $results_text
      = form
      '.===========================================================================.',
      '| Class                                                     | Score         |',
      '|-----------------------------------------------------------+---------------|',
      '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |{]].[[[[[[[[}  |',
      $classifications_ref, $scores_ref,
      '|===========================================================================|',
      '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}                   |',
      $comments,
      "'==========================================================================='";

    print $results_text;

  } else {
    printf("Failed. Status: %s, Status Code: %s, Status Message: %s \n",
      $client->status, $client->status_code, $client->status_message);
    return 1;
  }
  return 0;
}

sub read_image {
  my $self = shift;

  return \'' if $self->debug_camel;

  my $file_name     = shift;
  my $max_file_size = 16 * 1000 * 1000;  # A large but safe maximum

  open(my $fh, '<:raw', $file_name)
    or die "Could not open file: $file_name";

  read($fh, my $buffer, $max_file_size);

  close $fh;

  return \$buffer;
}

exit main->new_with_options->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

Inception.pl - Example command line Inception client

=head1 VERSION

version 0.01

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
