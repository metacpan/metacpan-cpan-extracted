package Dancer2::CLI;
# ABSTRACT: Dancer2 CLI application
$Dancer2::CLI::VERSION = '2.0.1';
use Moo;
use CLI::Osprey;
use Path::Tiny;
use File::Share 'dist_dir';
use Module::Runtime 'use_module';

subcommand gen => 'Dancer2::CLI::Gen';
subcommand 'gen-app' => 'Dancer2::CLI::Gen';

# Could have done this one inline, but wanted to remain consistent
# across subcommands.
subcommand version => 'Dancer2::CLI::Version';

# Thinking ahead, these might be useful in future subcommands
has _dancer2_version => (
    is      => 'lazy',
    builder => sub { use_module( 'Dancer2' )->VERSION },
);

has _dist_dir => (
    is      => 'lazy',
    builder => sub{ dist_dir('Dancer2') },
);

sub run {
    my $self = shift;
    return $self->osprey_usage;
}

sub _get_app_path {
    my ( $self, $path, $appname ) = @_;
    return path( $path, $self->_get_dashed_name( $appname ));
}

sub _get_app_file {
    my ( $self, $appname ) = @_;
    $appname =~ s{::}{/}g;
    return path( 'lib', "$appname.pm" );
}

sub _get_perl_interpreter {
    return -r '/usr/bin/env' ? '#!/usr/bin/env perl' : "#!$^X";
}

sub _get_dashed_name {
    my ( $self, $name ) = @_;
    $name =~ s{::}{-}g;
    return $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::CLI - Dancer2 CLI application

=head1 VERSION

version 2.0.1

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
