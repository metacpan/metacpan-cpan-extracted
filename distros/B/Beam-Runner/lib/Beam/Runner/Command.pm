package Beam::Runner::Command;
our $VERSION = '0.016';
# ABSTRACT: Main command handler delegating to individual commands

#pod =head1 SYNOPSIS
#pod
#pod     exit Beam::Runner::Command->run( $cmd => @args );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the entry point for the L<beam> command which loads and
#pod runs the specific C<Beam::Runner::Command> class.
#pod
#pod =head1 SEE ALSO
#pod
#pod The L<Beam::Runner> commands: L<Beam::Runner::Command::run>,
#pod L<Beam::Runner::Command::list>, L<Beam::Runner::Command::help>
#pod
#pod =cut

use strict;
use warnings;
use Module::Runtime qw( use_module compose_module_name );

sub run {
    my ( $class, $cmd, @args ) = @_;
    my $cmd_class = compose_module_name( 'Beam::Runner::Command', $cmd );
    return use_module( $cmd_class )->run( @args );
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::Command - Main command handler delegating to individual commands

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    exit Beam::Runner::Command->run( $cmd => @args );

=head1 DESCRIPTION

This is the entry point for the L<beam> command which loads and
runs the specific C<Beam::Runner::Command> class.

=head1 SEE ALSO

The L<Beam::Runner> commands: L<Beam::Runner::Command::run>,
L<Beam::Runner::Command::list>, L<Beam::Runner::Command::help>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
