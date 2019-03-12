package Beam::Runner::ExecCommand;
our $VERSION = '0.016';
# ABSTRACT: Run an external command

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This runnable module runs an external command using L<perlfunc/system>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runnable>
#pod
#pod =cut

use Moo;
use warnings;
with 'Beam::Runnable';
use Types::Standard qw( Str ArrayRef );

#pod =attr command
#pod
#pod The command to run. If a string, will execute the command in a subshell.
#pod If an arrayref, will execute the command directly without a subshell.
#pod
#pod =cut

has command => (
    is => 'ro',
    isa => ArrayRef[Str]|Str,
    required => 1,
);

sub run {
    my ( $self, @args ) = @_;
    my $cmd = $self->command;
    my $exit;
    if ( ref $cmd eq 'ARRAY' ) {
        $exit = system @$cmd;
    }
    else {
        $exit = system $cmd;
    }
    if ( $exit == -1 ) {
        my $name = ref $cmd eq 'ARRAY' ? $cmd->[0] : $cmd;
        die "Error starting command %s: $!\n", $name;
    }
    elsif ( $exit & 127 ) {
        die sprintf "Command died with signal %d\n", ( $exit & 127 );
    }
    return $exit;
}

1;

__END__

=pod

=head1 NAME

Beam::Runner::ExecCommand - Run an external command

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    beam run <container> <service>

=head1 DESCRIPTION

This runnable module runs an external command using L<perlfunc/system>.

=head1 ATTRIBUTES

=head2 command

The command to run. If a string, will execute the command in a subshell.
If an arrayref, will execute the command directly without a subshell.

=head1 SEE ALSO

L<beam>, L<Beam::Runnable>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
