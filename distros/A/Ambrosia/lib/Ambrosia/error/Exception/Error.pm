package Ambrosia::error::Exception::Error;
use strict;
use warnings;

use overload '""' => \&as_string, fallback => 1;

our $VERSION = 0.010;

sub PREF() { '    ' };

sub throw
{
    my $class = shift;
    my $error_code = shift;
    my @msg = @_;

    unless ( $error_code =~ /^E\d+/ )
    {
        unshift @msg, $error_code;
        $error_code = 'E0000';
    }

    my $frames = undef;
    foreach ( @msg )
    {
        if ( ref $_ && eval{$_->can('frames')} )
        {
            $frames = $_;
            last;
        }
    }

    my $self = bless
        {
            _error_code => $error_code,
            _message    => (join ' - ', grep { !ref $_ } @msg),
            _frames     => $frames || [],
        }, $class;

    $self->_addFrames() unless defined $frames;

    die $self;
}

# Формирует стек вызова
sub _addFrames
{
    my $self = shift;
    my $p = __PACKAGE__;
    my $x = 0;
    my ($package, $line, $subroutine);
    
    while ( do { package DB; ($package, $line, $subroutine) = (caller($x++))[0, 2, 3] } )
    {# Do the quickest ones first.
        next if $package eq __PACKAGE__ or substr($subroutine, 0, 33) eq __PACKAGE__;
        my @arg = $subroutine !~ /^$p\:\:/ ? @DB::args : ('...');
        push @{ $self->{_frames} }, { 'callers' => [$line, $subroutine, $package], 'argums' => \@arg };
    }
}

sub frames
{
    my $self = shift;

    local $@;
    return $self->{_frames}->frames if ref $self->{_frames} && ref $self->{_frames} ne 'ARRAY' && eval {$self->{_frames}->can('frames')};

    my @frms;
    foreach my $f ( @{$self->{_frames}} )
    {
        if ( ref $f )
        {
            my $subrutine = $f->{callers}->[1];
            unshift @frms, &PREF . $subrutine
                        . ( $subrutine ne '(eval)'
                                ? ( '( ' . (join ', ', map { defined $_ ? $_ : 'undef' } @{$f->{argums}}) . ' )')
                                : ''
                          )
                        . ' at ' . $f->{callers}->[2]
                        . ' line ' . $f->{callers}->[0];
        }
        else
        {
            unshift @frms, $f;
        }
    }
    return \@frms;
}

sub message
{
    my $self = shift;
    my $indent = shift || 0;
    local $@;

    my $pref = (&PREF x $indent);
    my $msg = $pref . $self->{_message};
    if ( ref $self->{_frames} && ref $self->{_frames} ne 'ARRAY' && eval {$self->{_frames}->can('message')} )
    {
        $msg .= " [\n" . $self->{_frames}->message($indent+1) . "\n$pref]";
    }
    return $msg;
}

sub stack
{
    return join("\n", reverse @{$_[0]->frames()}) . "\n";
}

sub as_string
{
#warn caller(0);
    my $self = shift;
    return $self->message() . "\n" . $self->stack();
}

sub code
{
    return $_[0]->{_error_code};
}

1;

__END__

=head1 NAME

Ambrosia::error::Exception::Error - a base class for Exceptions.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

   Ambrosia::error::Exception::Error is a base class for Exceptions. See L<Ambrosia::error::Exceptions>.

=cut

=head1 CONSTRUCTOR

=head2 throw ($message1, $message2, ...)

The constructor that generate exception.

=cut

=head1 METHODS

=head2 message

Returns message about an exception.

=cut

=head2 stack

Return a stack of calls.

=cut

=head2 as_string

Returns this exception as string.

=cut

=head2 frames

Returns pointer to list of calls.

=cut

=head2 code

Returns an error code.

=cut

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
