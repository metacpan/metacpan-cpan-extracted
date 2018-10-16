package Data::Context::Log;

use Moose;
use version;
use Carp qw/longmess/;
use Data::Dumper qw/Dumper/;

our $VERSION = version->new('0.3');

my $last;

has level => ( is => 'rw', isa => 'Int', default => 3 );
has fh    => ( is => 'ro', default => sub {\*STDERR}  );
sub BUILD {
    my ($self) = @_;
    $last = $self;
    return;
};
sub debug {
    my ($self, @message) = @_;
    $self = $last if !ref $self;
    $self->_log( 'DEBUG', @message ) if $self->level <= 1;
    return;
}
sub info  {
    my ($self, @message) = @_;
    $self = $last if !ref $self;
    $self->_log( 'INFO ' , @message ) if $self->level <= 2;
    return;
}
sub warn  {   ## no critic
    my ($self, @message) = @_;
    $self = $last if !ref $self;
    $self->_log( 'WARN ' , @message, longmess ) if $self->level <= 3;
    return;
}
sub error {
    my ($self, @message) = @_;
    $self = $last if !ref $self;
    $self->_log( 'ERROR', @message, longmess ) if $self->level <= 4;
    return;
}
sub fatal {
    my ($self, @message) = @_;
    $self = $last if !ref $self;
    $self->_log( 'FATAL', @message, longmess ) if $self->level <= 5;
    return;
}

sub _log {
    my ($self, $level, @message) = @_;
    $self = $last if !ref $self;
    $message[0] = Dumper $message[0] if @message == 1 && ( ref $message[0] || !defined $message[0] );
    chomp $message[-1];
    print {$self->fh} localtime() . " [$level] ", join ' ', @message, "\n";
    return;
}

1;

__END__

=head1 NAME

Data::Context::Log - Simple Log object helper

=head1 VERSION

This documentation refers to Data::Context::Log version 0.3

=head1 SYNOPSIS

   use Data::Context::Log;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Very simple log object it only really exists as a place holder for more
sophisticated log objects (eg L<Log::Log4perl>).

=head1 SUBROUTINES/METHODS

=head2 new

Has one optional parameter C<level> (default is 3) which sets the cut off
level for showing log messages. Setting level to 1 shows all messages, setting
level to 5 will show only fatal error messages.

=head2 BUILD

Construction activities

=over 4

=item debug

Requires level 1 to be displayed

=item info

Requires level 2 to be displayed

=item warn

Requires level 3 to be displayed

=item error

Requires level 4 to be displayed

=item fatal

Requires level 5 to be displayed

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
