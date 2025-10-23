# ABSTRACT: Role for application environment name
package Dancer2::Core::Role::HasEnvironment;
$Dancer2::Core::Role::HasEnvironment::VERSION = '2.0.1';
use Moo::Role;
use Dancer2::Core::Types;

my $DEFAULT_ENVIRONMENT = q{development};

has environment => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_environment',
);

sub _build_environment {
    my ($self) = @_;
    return $ENV{DANCER_ENVIRONMENT} || $ENV{PLACK_ENV} || $DEFAULT_ENVIRONMENT;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::Role::HasEnvironment - Role for application environment name

=head1 VERSION

version 2.0.1

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
