package App::AquariumHive::LogRole;
BEGIN {
  $App::AquariumHive::LogRole::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::LogRole::VERSION = '0.003';
use Moo::Role;

with 'MooX::Role::Logger';

sub _build__logger_category {
  my ( $self ) = @_;
  my $class = ref $self;
  return $class;
}

sub trace { shift->_logger->trace(@_) }
sub debug { shift->_logger->debug(@_) }
sub info { shift->_logger->info(@_) }
sub notice { shift->_logger->notice(@_) }
sub warning { shift->_logger->warning(@_) }

1;

__END__

=pod

=head1 NAME

App::AquariumHive::LogRole

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
