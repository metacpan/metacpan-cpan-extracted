#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Role::RunningCommand;
# ABSTRACT: sthg that can run an external command
$App::Magpie::Role::RunningCommand::VERSION = '2.010';
use Moose::Role;
use MooseX::Has::Sugar;

with 'App::Magpie::Role::Logging';


# -- public methods


sub run_command {
    my ($self, $cmd) = @_;
    my $logger = $self->logger;
    $self->log_debug( "running: $cmd" );

    my $stderr = $logger->log_level >= 2 ? "" : "2>/dev/null";

    # run the command
    system("$cmd $stderr >&2") == 0
        or $self->log_fatal( "command [$cmd] exited with value " . ($?>>8) );
}


 
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Role::RunningCommand - sthg that can run an external command

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    with 'App::Magpie::Role::RunningCommand';
    $self->run_command( "sleep 10" );

=head1 DESCRIPTION

This role is meant to provide easy way of running a command for classes
consuming it. Standard output & standard errors are redirected depending
on the log level.

=head1 METHODS

=head2 run_command

    $obj->run_command( $cmd );

Run a command, spicing some debug comments here and there. Die if the
command encountered a problem.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
