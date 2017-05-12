package DBIx::Class::InflateColumn::JSON2Object;

# ABSTRACT: convert JSON columns to Perl objects

our $VERSION = '0.900';

use strict;
use warnings;
use JSON::MaybeXS qw(encode_json decode_json );
use Encode qw(encode_utf8 decode_utf8);
use Module::Runtime 'use_module';
use Scalar::Util qw(blessed);

sub class_in_column {
    my ($class,@args) = @_;
    my $caller = caller(0);

    foreach my $def (@args) {

        my $class_column    = $def->{class_column};
        my $data_column     = $def->{data_column};
        my $namespace       = $def->{namespace};
        my $result_source   = $def->{result_source} || $caller;

        use_module($namespace);

        $result_source->inflate_column(
            $data_column,
            {
                inflate => sub {
                    my ($data,$self) = @_;
                    my $package = $namespace->package($self->$class_column);
                    return $package->thaw($data);
                },
                deflate => sub {
                    my ($data,$self) = @_;
                    if (blessed $data) {
                        if ($data->isa($namespace)) {
                            $self->$class_column($data->moniker);
                        } else {
                            die('Supplied args object is not a '.$namespace);
                        }
                    } else {
                        my $package = $namespace->package($self->$class_column);
                        $data = $package->thaw($data);
                    }
                    return $data->freeze;
                },
            }
        );
    }
}

sub fixed_class {
    my ($class,@args) = @_;
    my $caller = caller(0);

    foreach my $def (@args) {

        my $data_column   = $def->{column};
        my $package       = $def->{class};
        my $result_source = $def->{result_source} || $caller;

        use_module($package);

        $result_source->inflate_column(
            $data_column,
            {
                inflate => sub {
                    my ($data,$self) = @_;
                    return $package->thaw($data);
            },
                deflate => sub {
                    my ($data,$self) = @_;
                    if (blessed $data) {
                        if (!$data->isa($package)) {
                            die('Supplied args object is not a '.$package);
                        }
                    } else {
                        $data = $package->thaw($data);
                    }
                    return $data->freeze;
                },
            }
        );
    }
}

sub no_class {
    my ($class,@args) = @_;
    my $caller = caller(0);

    foreach my $def (@args) {

        my $data_column     = $def->{column};
        my $result_source   = $def->{result_source} || $caller;

        $result_source->inflate_column(
            $data_column,
            {
                inflate => sub {
                    my ($data,$self) = @_;
                    return {}
                        if !defined $data
                            || $data =~ m/^\s*$/;
                    return decode_json( encode_utf8($data) );
                },
                deflate => sub {
                    my ($data,$self) = @_;
                    if ( ref($data) =~ m/^(HASH|ARRAY)$/ ) {
                        return decode_utf8( encode_json($data) );
                    }
                    return $data;
                },
            }
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::JSON2Object - convert JSON columns to Perl objects

=head1 VERSION

version 0.900

=head1 SYNOPSIS

  # In a DBIx::Class Result
  package MyApp::Schema::Result::SomeTable;
  ... lots of DBIx::Class code...

  use DBIx::Class::InflateColumn::JSON2Object;
  DBIx::Class::InflateColumn::JSON2Object->fixed_class({
      column=>'data',      # a column storing JSON
      class=>'MyApp::SomeClass',
  });

  # later, in some code far, far away...
  my $row = $schema->resultset('SomeTable')->find(42);
  my $obj = $row->data;
  $obj->foo; # $obj ISA MyApp::SomeClass

  # store a hash as JSON after "validating" it through MyApp::SomeClass
  $schema->resultset('SomeTable')->create({
      data => {
          foo=>'bar',
      };
  })

  # you can also use it to just deflate/inflate JSON to a Perl hash
  DBIx::Class::InflateColumn::JSON2Object->no_class({
      column=>'args',
  });

  # or have a complex set of objects
  DBIx::Class::InflateColumn::JSON2Object->class_in_column({
      data_column  => 'object',        # some JSON
      class_column => 'type',          # here we store the name of the object
      namespace    => 'MyApp::Object', # the namespace of the objects
  });

=head1 DESCRIPTION

TODO: short overview

=head2 Booleans, JSON, oh my...

TODO: describe problem and the (hacky/crappy?) solution

=head2 METHODS

Please note that you can pass more than one HASHREF per method to
install several inflator/deflators at once.

=head3 no_class

Install a JSON inflator/deflator for each column.

  DBIx::Class::InflateColumn::JSON2Object->no_class({
      column=>'args'
  });

You can pass a Perl datastructure to the row and it will be stored as JSON:

  $resultset->create( {
      id   => 123,
      args => {
        some => 'data',
        more => [1,1,2,3,5,8]
      }
  });
  # will be stored as '{"some":"data","more":[1,1,2,3,5,8]}'

You can also access the data directly as a Perl hash:

  my $row = $resultset->find(123);
  $row->args->{some};     # 'data'
  $row->args->{more}[5];  # 8

=head3 fixed_class

If plain JSON is to wobbly for you, you can define Moose objects and
have them serialized to JSON. Not only can you now add some custom
methods to the objects, but you can (ab)use the object initalisation
and all features Moose provides to define your objects.

 TODO ->fixed_class(..)

Just pass an object to the row and it will be stored as JSON:

  TODO

And you get back the initated object:

  TODO

=head3 class_in_column

Sometimes you have a set of similar objects you want to store. TODO: explain oe1.article.paragraph

  TODO ->class_in_column(..)

You can pass an object to the row and the infered type will be stored together with the JSON-payload:

  TODO

To get back the object:

  TODO

=head1 THANKS

=over

=item *

Parts of this code were orginally developed for L<validad.com|https://www.validad.com/> and released as Open Source.

=item * L<Maroš Kollár|https://metacpan.org/author/MAROS> wrote the prototype of C<class_in_column>, orginally developed for L<http://oe1.orf.at>.

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
