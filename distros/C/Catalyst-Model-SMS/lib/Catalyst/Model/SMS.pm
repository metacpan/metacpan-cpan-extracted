package Catalyst::Model::SMS;
use Moose;
use SMS::Send;
extends 'Catalyst::Model::Adaptor';

# ABSTRACT: Easy SMS sending from Catalyst Apps.

our $VERSION = '0.4';

__PACKAGE__->config( class => 'SMS::Send' );

has driver => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Test',
);

sub mangle_arguments {
    my ( $self, $args ) = @_;

    my $driver = delete $args->{driver} || $self->driver;
    return $driver, %$args;
}

__PACKAGE__->meta->make_immutable;
1;


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Catalyst::Model::SMS - Easy SMS sending from Catalyst Apps.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

    # on the shell
    $ script/myapp_create.pl model SMS

    # in myapp.conf
    <Model::SMS>
        driver Test
        <args>
            _login admin
            _password pa55w0rD
        </args>
    </Model::SMS>

=head1 DESCRIPTION

L<Catalyst::Model::SMS> is a thin proxy around SMS::Send. It can
be initialized using the Catalyst configuration file or method.

=head1 NAME

Catalyst::Model::SMS - Catalyst Model for SMS::Send

=head1 OPTIONS

=head2 driver

L<SMS::Send> driver name. You may specify 'Test' if you need a testing driver.
This module will default to 'Test' if this is not specified. See L<SMS::Send>
for more information.

=head2 args

L<SMS::Send> arguments specific to the selected driver. These options are
passed directly to the appropriate L<SMS::Send> driver.

=head1 METHODS

=head2 mangle_arguments

overridden method imported from Catalyst::Model::Adaptor. This method is
passed the arguments, and returns them in a way suitable for SMS::Send->new

=head1 AUTHOR

Martin Atukunda, <matlads@cpan.org>

=head1 COPYRIGHT

Copyright 2013 the above author(s).

=head1 LICENSE

This sofware is free software, and is licensed under the same terms as perl itself.

=head1 AUTHOR

Martin Atukunda <matlads@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Atukunda.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
