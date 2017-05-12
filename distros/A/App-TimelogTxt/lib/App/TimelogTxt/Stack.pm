package App::TimelogTxt::Stack;

use warnings;
use strict;
use autodie;

our $VERSION = '0.22';

sub new
{
    my ($class, $file) = @_;
    die "No file specified.\n" unless $file;
    return bless { file => $file }, $class;
}

sub clear
{
    my ($self) = @_;
    unlink $self->{file};
    return;
}

sub push
{
    my ($self, $task) = @_;
    open my $fh, '>>', $self->{file};
    print {$fh} $task, "\n";
    return;
}

sub pop
{
    my ($self) = @_;
    return unless -f $self->{file};
    return $self->_pop();
}

sub _pop
{
    my ($self) = @_;
    open my $fh, '+<', $self->{file};
    my ($line, $pos) = _find_last_line( $fh );
    return unless defined $line;

    seek( $fh, $pos, 0 );
    truncate( $fh, $pos );
    return $line;
}

sub drop
{
    my ($self, $arg) = @_;
    return unless -f $self->{file};
    if( !defined $arg )
    {
        $self->_pop();
    }
    elsif( lc $arg eq 'all' )
    {
        $self->clear()
    }
    elsif( $arg =~ /^[0-9]+$/ )
    {
        $self->_pop() foreach 1 .. $arg;
    }
    return;
}

sub _find_last_line
{
    my ($fh) = @_;
    my ( $lastpos, $lastline );
    while( my ( $line, $pos ) = _readline_pos( $fh ) )
    {
        ( $lastpos, $lastline ) = ( $pos, $line );
    }
    return unless defined $lastline;

    chomp $lastline;
    return ($lastline, $lastpos);
}

sub _readline_pos
{
    my $fh   = shift;
    my $pos  = tell $fh;
    my $line = <$fh>;
    return ( $line, $pos ) if defined $line;
    return;
}

sub list
{
    my ($self, $ofh) = @_;
    $ofh ||= \*STDOUT;
    return unless -f $self->{file};

    open my $fh, '<', $self->{file};
    print {$ofh} reverse <$fh>;
    return;
}

1;

__END__

=head1 NAME

App::TimelogTxt::Stack - Interface to the stack file for the timelog application.

=head1 VERSION

This document describes App::TimelogTxt::Stack version 0.22

=head1 SYNOPSIS

    use App::TimelogTxt::Stack;

    my $stack = App::TimelogTxt::Stack->new( 'timelog/stack.txt' );

    $stack->push( '+Project @Task More detail' );
    my $event = $stack->pop();

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=head2 new( $filename )

Create an C<App::TimelogTxt::Stack> object wrapping the supplied file.

=head2 $s->clear()

Truncate the stack file, removing all items from the stack.

=head2 $s->push( $event )

Add a new event to the stack file.

=head2 $event = $s->pop()

Remove the most recent event from the stack file and return the event string.

=head2 $s->drop( $arg )

Remove one or more events from the stack file. If C<$arg> is not supplied,
remove one item. If C<$arg> is a positive number, remove that many items
from the stack. If C<$arg> is the string C<'all'>, clear the stack.

=head2 $s->list( $fh )

Print the stack to the supplied filehandle. If no filehandle is supplied, use
C<STDOUT>. The stack will be printed such that the most recent item is listed
first.

=head1 CONFIGURATION AND ENVIRONMENT

App::TimelogTxt::Stack requires no configuration files or environment variables.

=head1 DEPENDENCIES

autodie.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

