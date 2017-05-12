package Beam::Runner::Command::minion;
our $VERSION = '0.003';
# ABSTRACT: Command for L<beam> to run distributed tasks

#pod =head1 SYNOPSIS
#pod
#pod     exit Beam::Runner::Command::minion->run( $cmd => @args );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the entry point for the L<beam> command to delegate to
#pod the appropriate L<Beam::Minion::Command> subclass.
#pod
#pod =head1 SEE ALSO
#pod
#pod The L<Beam::Minion> commands: L<Beam::Minion::Command::run>,
#pod L<Beam::Minion::Command::worker>
#pod
#pod =cut

use strict;
use warnings;
use Module::Runtime qw( use_module compose_module_name );

sub run {
    my ( $class, $cmd, @args ) = @_;
    my $cmd_class = compose_module_name( 'Beam::Minion::Command', $cmd );
    return use_module( $cmd_class )->run( @args );
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Command::minion - Command for L<beam> to run distributed tasks

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    exit Beam::Runner::Command::minion->run( $cmd => @args );

=head1 DESCRIPTION

This is the entry point for the L<beam> command to delegate to
the appropriate L<Beam::Minion::Command> subclass.

=head1 SEE ALSO

The L<Beam::Minion> commands: L<Beam::Minion::Command::run>,
L<Beam::Minion::Command::worker>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
