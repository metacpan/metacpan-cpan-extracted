#===============================================================================
#
#      PODNAME:  CLI::Gwrapper.pm
#     ABSTRACT:  specifies requirements for the Gwrapper role for CLI::Gwrap
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/07/2013 05:05:41 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

package CLI::Gwrapper;
use Types::Standard qw( Str Int Bool ArrayRef CodeRef InstanceOf );

our $VERSION = '0.030'; # VERSION

use Moo::Role;
use IPC::Run;

requires qw(
    title
    run
);

has 'command'       => (is => 'ro', isa => ArrayRef);
has 'main_opt'      => (is => 'ro', isa => InstanceOf['CLI::Gwrap::Opt']);
has 'description'   => (is => 'ro', isa => Str);
has 'verbatim'      => (is => 'ro', isa => Bool);
has 'help'          => (is => 'ro', isa => Str);
has 'persist'       => (is => 'ro', isa => Bool);
has 'columns'       => (is => 'rw', isa => Int, default => 3);
has 'opts'          => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['CLI::Gwrap::Opt']],
    default => sub { return []},
);
has 'advanced'      => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['CLI::Gwrap::Opt']],
    default => sub { return []},
);
has 'timeout'       => (is => 'rw', isa => Int, default => 10);
has 'exec_callback' => (is => 'rw', isa => CodeRef, default => sub { return \&default_exec_callback; }, );

sub default_exec_callback {
    my ($self, $cmd_ref) = @_;

    # $out accumulates cmd's stdout
    # $err accumulates cmd's stderr
    my ($out, $err);
    IPC::Run::run(
        $cmd_ref,       # command line (in array format)
        \undef,         # close STDIN
        \$out,          # STDOUT to $out
        \$err,          # STDERR to $err
        IPC::Run::timeout( $self->timeout ),
    );

    return ($?, $out, $err);

}

sub execute_callback {
    my ($self, $cmd_ref) = @_;

    return $self->exec_callback->($self, $cmd_ref);
}


1;



=pod

=head1 NAME

CLI::Gwrapper.pm - specifies requirements for the Gwrapper role for CLI::Gwrap

=head1 VERSION

version 0.030

=head1 SYNOPSIS

 package CLI::Gwrapper::My_Gwrapper;

 use Moo with CLI::Gwrapper;     # make your wrapper satisfy the Gwrapper role

    ...

=head1 DESCRIPTION

CLI::Gwrapper provides attributes, methods and requirements of the
CLI::Gwrapper role, thus allowing My_Gwrapper to be used as a plugin for
CLI::Gwrap.

=head1 SEE ALSO

CLI::Gwrap

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

