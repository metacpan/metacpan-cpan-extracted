package App::AquariumHive::DB;
BEGIN {
  $App::AquariumHive::DB::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::DB::VERSION = '0.003';
use Moo;
use namespace::clean;

extends 'DBIx::Class::Schema';

$ENV{DBIC_NULLABLE_KEY_NOWARN} = 1;

with 'App::AquariumHive::LogRole';

__PACKAGE__->load_namespaces(
  default_resultset_class => 'ResultSet',
);

has _app => (
  is => 'rw',
);
sub app { shift->_app }

sub connect {
  my ( $self, $app ) = @_;
  $app = $self->app if ref $self;
  my $schema = $self->next::method("dbi:SQLite::memory:","","",{
    sqlite_unicode => 1,
    quote_char => '"',
    name_sep => '.',
  });
  $schema->_app($app);
  return $schema;
}

sub format_datetime { shift->storage->datetime_parser->format_datetime(shift) }

1;

__END__

=pod

=head1 NAME

App::AquariumHive::DB

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
