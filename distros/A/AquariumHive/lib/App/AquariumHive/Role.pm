package App::AquariumHive::Role;
BEGIN {
  $App::AquariumHive::Role::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::Role::VERSION = '0.003';
use Moo::Role;
with 'App::AquariumHive::LogRole';

has app => (
  is => 'ro',
  required => 1,
  handles => [qw(
    add_tile
    web_mount
    on_data
    on_socketio
    send
    run_cmd
    sensor_rows
    no_pwm
    no_power
  )],
);

1;

__END__

=pod

=head1 NAME

App::AquariumHive::Role

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
