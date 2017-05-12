package App::derived::Plugin;

use strict;
use warnings;
use Class::Accessor::Lite (
    new => 1,
    ro => [qw/_services _proclet/]
);
use JSON qw//;

my $_JSON = JSON->new()
    ->utf8(1)
    ->shrink(1)
    ->space_before(0)
    ->space_after(0)
    ->indent(0);

sub json {
    $_JSON;
}

sub exists_service {
    my $self = shift;
    my $key = shift;
    exists $self->_services->{$key};
}

sub service_stats {
    my $self = shift;
    my $key = shift;
    return if ! exists $self->_services->{$key};
    my $service = $self->_services->{$key};
    open my $fh, '<', $service->{file} or return;
    my $val = do { local $/; <$fh> };
    $self->json->decode($val);
}

sub service_keys {
    my $self = shift;
    keys %{$self->_services};
}

my %worker_tag;
sub add_worker {
    my $self = shift;
    my ($tag, $code, $workers) = @_;
    $workers ||= 1;
    $worker_tag{$tag} = 0 unless exists $worker_tag{$tag};
    $worker_tag{$tag}++;
    $self->_proclet->service(
        code => $code,
        tag => $tag . '_' . $worker_tag{$tag},
        worker => $workers
    );
}

sub init {
    die 'abstract method';
}


1;

__END__

=encoding utf8

=head1 NAME

App::derived::Plugin - base class of App::derived::Plugin

=head1 SYNOPSIS

  package App::derived::Plugin::Dumper;
  
  use strict;
  use warnings;
  use parent qw/App::derived::Plugin/;
  use Data::Dumper;
  use Class::Accessor::Lite (
      ro => [qw/interval/]
  );
  
  sub int {
      my $self = shift;
      $self->interval(10) unless $self->interval;

      $self->add_worker(
          'dumper',
          sub {
              while (1) {
                  sleep $self->interval;
                  my @keys = $self->service_keys();
                  for my $key ( @keys ) {
                      my $ref = $self->service_stats->{$key}
                      print Dumper([$key,$ref]);
                  }
              }
          }  
      );
  }


=head1 DESCRIPTION

This module is base class to make App::derived Plugin.

=head1 METHODS

=over 4

=item new

=item json(): Object

Utility method. returns JSON.pm object

=item service_stats($key): HashRef

Retrieve service status

=item exists_service($key): Bool

Checking existence of service named $key

=item service_keys(): Array

get all registered service keys

=item add_worker($tag:String, $code:SubRef)

Registering a worker

=item init

Required to implementing this method in your Plugin

=back

=head1 SEE ALSO

<App::derived::Plugin::Memcached>

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


