package Authen::Simple::Log;

use strict;
use warnings;

use IO::Handle;

our $SINGLETON = bless( {}, __PACKAGE__ );

sub new   { $SINGLETON }
sub debug { }
sub error { shift->_log( 'error', @_ ) }
sub info  { }
sub warn  { shift->_log( 'warn',  @_ ) if $^W }

sub _caller {
    my $self  = shift;
    my $frame = 0;

    $frame++ until ( caller($frame) ne __PACKAGE__ );

    return scalar caller($frame);
}

sub _format {
    my ( $self, $level, @message ) = @_;
    return sprintf( "[%s] [%s] [%s] %s\n", scalar localtime(), $level, $self->_caller, "@message" );
}

sub _output {
    my $self = shift;
    STDERR->print(@_);
    STDERR->flush;
}

sub _log {
    my $self    = shift;
    my $message = $self->_format(@_);
    $self->_output($message);
}

1;

__END__

=head1 NAME

Authen::Simple::Log - Simple log class

=head1 SYNOPSIS

    $log = Authen::Simple::Log->new;
    $log->error($message);
    $log->warn($message);

=head1 DESCRIPTION

Default log class for Authen::Simple

=head1 METHODS

=over 4

=item * new

Constructor, takes no parameters.

=item * debug (@)

Does nothing.

=item * error (@)

Logs a error message to C<STDERR>.

=item * info (@)

Does nothing.

=item * warn (@)

Logs a warning message to C<STDERR> if C<$^W> is true.

=back

=head1 SEE ALSO

L<Authen::Simple>

L<Authen::Simple::Adapter>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

