package App::AquariumHive::DB::ResultSet;
BEGIN {
  $App::AquariumHive::DB::ResultSet::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::DB::ResultSet::VERSION = '0.003';
use Moo;
use namespace::clean;

extends 'DBIx::Class::ResultSet';

$ENV{DBIC_NULLABLE_KEY_NOWARN} = 1;

with 'App::AquariumHive::LogRole';

1;

__END__

=pod

=head1 NAME

App::AquariumHive::DB::ResultSet

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
