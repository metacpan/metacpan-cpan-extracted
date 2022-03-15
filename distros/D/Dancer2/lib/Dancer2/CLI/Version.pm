package Dancer2::CLI::Version;
# ABSTRACT: Display Dancer2 version
$Dancer2::CLI::Version::VERSION = '0.400000';
use Moo;
use CLI::Osprey
    desc => 'Display version of Dancer2';

sub run {
    my $self = shift;
    print "Dancer2 " . $self->parent_command->_dancer2_version, "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::CLI::Version - Display Dancer2 version

=head1 VERSION

version 0.400000

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
