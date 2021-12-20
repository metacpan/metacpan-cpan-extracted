package App::perlimports::Role::Logger;

use Moo::Role;

our $VERSION = '0.000028';

use Types::Standard qw( InstanceOf );

has logger => (
    is        => 'ro',
    isa       => InstanceOf ['Log::Dispatch'],
    predicate => '_has_logger',
    writer    => 'set_logger',
);

1;

# ABSTRACT: Provide a logger attribute to App::perlimports objects

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlimports::Role::Logger - Provide a logger attribute to App::perlimports objects

=head1 VERSION

version 0.000028

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
