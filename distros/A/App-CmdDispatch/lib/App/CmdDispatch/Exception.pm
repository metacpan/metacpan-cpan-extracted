package App::CmdDispatch::Exception;

use warnings;
use strict;

our $VERSION = '0.44';

sub new
{
    my ($class, @args) = @_;

    return bless { args => \@args }, $class;
}

sub why
{
    my ($self) = @_;
    return __PACKAGE__;
}

{
    package App::CmdDispatch::Exception::UnknownCommand;
    our @ISA = 'App::CmdDispatch::Exception';
    sub why
    {
        my ($self) = @_;
        return "Unrecognized command '$self->{args}->[0]'";
    }
}

{
    package App::CmdDispatch::Exception::MissingCommand;
    our @ISA = 'App::CmdDispatch::Exception';
    sub why
    {
        my ($self) = @_;
        return "Missing command";
    }
}
1;
__END__

=head1 NAME

App::CmdDispatch::Exception - Define exception objects used by CmdDispatch modules.

=head1 VERSION

This document describes App::CmdDispatch::Exception version 0.44


=head1 SYNOPSIS

    use App::CmdDispatch::Exception;

    die App::CmdDispatch::Exception::MissingCommand->new();

  
=head1 DESCRIPTION

These exception classes simplify exceptional conditions that need a bit more
context to report that the simple fact of the exception. These are used in the
parts of the run code where we want to catch the exception and perform some
recovery.

Other places in the code where we just want to leave the program, I've thrown
simple strings instead.

=head1 INTERFACE 

=head2 new( @args )

Create an exception object. Store the supplied args if necessary to explain
context of exception.

=head2 why()

Method returning a string with a user-readable string explaining the exception.

=head1 CONFIGURATION AND ENVIRONMENT

C<App::CmdDispatch::Exception> requires no configuration files or environment
variables.

=head1 DEPENDENCIES

None.

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

