package App::mojopaste::Backend::Mongo;

use strict;
use 5.008_005;
our $VERSION = '0.03';

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Promise;

my $ID = 0;

sub register {
  my ($self, $app, $config) = @_;

  my $mongo_uri = $ENV{MONGO_URI} || 'mongodb://mongo:27017/paste';
  $app->plugin( 'Mango', {
    mango      => $mongo_uri,
    helper     => 'db',
    default_db => 'mojopaste',
  });

  $app->helper('paste.load_p' => sub { _load_p(@_) });
  $app->helper('paste.save_p' => sub { _save_p(@_) });
}

sub _load_p {
  my ($c, $id) = @_;

  eval {

    my $promise = Mojo::Promise->new;
    $c->collection('docs')->find_one({id => $id}, { _id => 0 } => sub {
      my ($collection, $err, $doc) = @_;

      return $err ? $promise->reject($err) : $promise->resolve($doc->{body});
    });

    return $promise;
  } or do {
    return Mojo::Promise->new->reject($@ || 'Paste not found');
  };
}

sub _save_p {
  my ($c, $text) = @_;
  my $id = substr Mojo::Util::md5_sum($$ . time . $ID++), 0, 12;

  eval {
    my $promise = Mojo::Promise->new;
    $c->collection('docs')->insert({ id => $id, body => $text } => sub {
      my ($collection, $err, $oid) = @_;

      return $err ? $promise->reject( $err ) : $promise->resolve( $id );
    });

    return $promise;
  } or do {
    return Mojo::Promise->new->reject($@ || 'Unknown error');
  };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::mojopaste::Backend::Mongo - backen for App::mojopaste

=head1 SYNOPSIS

  use App::mojopaste::Backend::Mongo;

=head1 DESCRIPTION

App::mojopaste::Backend::Mongo is backend for https://github.com/jhthorsen/app-mojopaste

How to use

  * install docker and docker-compose
  * git clone https://github.com/sklukin/App-mojopaste-Backend-Mongo
  * cd App-mojopaste-Backend-Mongo
  * docker-compose up

=head1 AUTHOR

sklukin E<lt>sklukin@yandex.ruE<gt>

=head1 COPYRIGHT

Copyright 2020- sklukin

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
