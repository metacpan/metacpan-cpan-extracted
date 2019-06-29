package App::TeleGramma::Store;
$App::TeleGramma::Store::VERSION = '0.14';
# ABSTRACT: Persistent datastore for TeleGramma and plugins


use Mojo::Base -base;
use Storable qw/store retrieve/;
use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;

has 'path';
has 'dbs' => sub { {} };


sub hash {
  my $self = shift;
  my $db   = shift || die "no db?";

  $self->check_db_name($db);

  if (! $self->dbs->{$db} ) {
    my $hash = $self->read_db_into_hash($db);
    $self->dbs->{$db} = $hash;
  }
  return $self->dbs->{$db};
}

sub check_db_name {
  my $self = shift;
  my $db   = shift;

  if ($db !~ /^[\w\-]+$/) {
    croak "invalid db name '$db'\n";
  }

}

sub read_db_into_hash {
  my $self = shift;
  my $db   = shift;

  if (! -d $self->path) {
    croak "no path '" . $self->path . "'?";
  }

  my $db_file = catfile($self->path, $db);
  if (! -e $db_file) {
    my $hash = {};
    store($hash, $db_file);
    return $hash;
  }
  return retrieve($db_file);
}


sub save {
  my $self = shift;
  my $db   = shift || die "no db?";

  my $db_file = catfile($self->path, $db);
  store($self->hash($db), $db_file);
}


sub save_all {
  my $self = shift;
  my @dbs = keys %{ $self->dbs };
  $self->save($_) foreach @dbs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::Store - Persistent datastore for TeleGramma and plugins

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  my $store = App::TeleGramma::Store->new(path => "/some/dir");
  my $hashref1 = $store->hash('mydata-1');
  $hashref1->{foo} = 'bar';
  $hashref1->{bar} = 'baz';
  $store->save('mydata-1');  # persisted

  my $hashref2 = $store->hash('mydata-2'); # new data structure
  $hashref2->{users} = [ qw/ a b c / ];

  $store->save_all;  # persist data in both the 'mydata1' hash and the 'mydata2' hash

=head1 METHODS

=head2 hash

Return the hash reference for a named entry in your data store. Note that
the names become disk filenames, and thus must consist of alphanumeric characters
or '-' only.

=head2 save

Save a named hash to the data store.

References are saved using L<Storable> and the limitations in terms of data
stored can be found in that documenation.

In general, if you stick with simple hashrefs, arrayrefs and scalars you will
be fine.

=head2 save_all

Persist all named hashrefs to the store at once.

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
