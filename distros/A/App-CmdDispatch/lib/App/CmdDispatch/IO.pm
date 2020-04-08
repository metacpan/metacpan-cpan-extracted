package App::CmdDispatch::IO;

use warnings;
use strict;
use Term::ReadLine;

our $VERSION = '0.44';

my $term;
sub new
{
    my ($class) = @_;
    $term ||= Term::ReadLine->new('CmdDispatch Shell');
    $term->ornaments( 0 );
    return bless { term => $term }, $class;
}

sub print
{
    my $self = shift;
    return CORE::print @_;
}

sub readline
{
    my ($self) = @_;
    return $self->{term}->readline( '' );
}

sub prompt
{
    my ($self, @in) = @_;
    return $self->{term}->readline( @in );
}

{
    package App::CmdDispatch::MinimalIO;

    sub new
    {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub print
    {
        my $self = shift;
        return CORE::print @_;
    }

    sub readline
    {
        my ($self) = @_;
        return CORE::readline;
    }

    sub prompt
    {
        my ($self, @in) = @_;
        $self->print( @in );
        return $self->readline();
    }
}
1;
__END__

=head1 NAME

App::CmdDispatch::IO - Abstract out the input and output for C<App::CmdDispatch>


=head1 VERSION

This document describes C<App::CmdDispatch::IO> version 0.44

=head1 SYNOPSIS

    use App::CmdDispatch::IO;

    my $io = App::CmdDispatch::IO->new;

    $io->print( "Message to the user\n" );

    my $name = $io->prompt( "What is your name: " );
  
=head1 DESCRIPTION

This class encapsulates the I/O interface needed by the L<App::CmdDispatch>
module. A user can replace this object to provide a different mechanism for
interacting with the user.

This default version of the class defines the interface and interacts with
the user through the standard in and out streams.

=head1 INTERFACE 

The class supports a relatively small interface.

=head2 new()

Create a new object of type C<App::CmdDispatch::IO>.

=head2 print( @strings )

Display the list of supplied strings to the user.

=head2 readline

Return a single line from the user.

=head2 prompt( @strings )

Display the list of supplied strings and then return a single line from the
user.

=head1 CONFIGURATION AND ENVIRONMENT

C<App::CmdDispatch::IO> requires no configuration files or environment variables.

=head1 DEPENDENCIES

Term::ReadLine

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< wade@anomaly.org >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< wade@anomaly.org >>. All rights reserved.

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
