package Data::Collector::Engine::Local;
{
  $Data::Collector::Engine::Local::VERSION = '0.15';
}
# ABSTRACT: An engine for Data::Collector that runs local commands

use Moose;
use IPC::System::Simple 'capture';
use namespace::autoclean;

extends 'Data::Collector::Engine';

has '+name'  => ( default => 'Local' );

sub run {
    my ( $self, $cmd ) = @_;

    return capture($cmd);
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::Engine::Local - An engine for Data::Collector that runs local commands

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Data::Collector;

    my $collector = Data::Collector->new(
        engine => 'Local',
    );

This engine helps debugging Data::Collector better by running commands locally.

=head2 run

This functions runs the given command locally using IPC::System::Simple.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

