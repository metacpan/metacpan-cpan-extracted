use strict;
use warnings;

package Ambrosia::error::Exceptions;
our $VERSION = 0.010;
1;

######################################################################
package Ambrosia::error::Exception;
use base qw/Ambrosia::error::Exception::Error/;
our $VERSION = 0.010;

sub CODE() {'E0000'}

sub throw
{
    return shift->SUPER::throw(CODE, @_);
}

######################################################################
package Ambrosia::error::Exception::BadUsage;
use base qw/Ambrosia::error::Exception::Error/;
our $VERSION = 0.010;

sub CODE() {'E0001'}

sub throw
{
    return shift->SUPER::throw(CODE, @_);
}

######################################################################
package Ambrosia::error::Exception::BadParams;
use base qw/Ambrosia::error::Exception::Error/;
our $VERSION = 0.010;

sub CODE() {'E0002'}

sub throw
{
    return shift->SUPER::throw(CODE, @_);
}

######################################################################
package Ambrosia::error::Exception::AccessDenied;
use base qw/Ambrosia::error::Exception::Error/;
our $VERSION = 0.010;

sub CODE() {'E0003'}

sub throw
{
    return shift->SUPER::throw(CODE, @_);
}

1;

__END__

=head1 NAME

Ambrosia::error::Exception - an unspecified exception.
Ambrosia::error::Exception::BadUsage - this exception will occur if you use something incorrect.
Ambrosia::error::Exception::BadParams - this exception will occur if you use incorrect parameters.
Ambrosia::error::Exception::AccessDenied - this exception will occur if you try run closed method.

=head1 SYNOPSIS

    use Ambrosia::error::Exceptions;

    sub test
    {
        unless ( @_ )
        {
            throw Ambrosia::error::Exception::BadParams("Must call test with arguments.");
        }
    }

    eval
    {
        test();
    };
    if ( $@ )
    {
        if ( ref $@ && $@->isa('Ambrosia::error::Exception::Error') )
        {
            print "ERROR: " . $@->message . "\n";
            print "STACK:\n" . $@->stack . "\n";
            print "CODE: " . $@->code . "\n";

            #printed:
            #ERROR: Must call test with arguments.
            #ERROR: Must call test with arguments.
            #STACK:
            #    Ambrosia::error::Exception::BadParams::throw( Ambrosia::error::Exception::BadParams, Must call test with arguments. ) at main line ...
            #    main::test(  ) at main line ...
            #    (eval) at main line ...
            #CODE: E0002

            #ERROR: Must call test with arguments.
            #STACK:
            #    Ambrosia::error::Exception::BadParams::throw( Ambrosia::error::Exception::BadParams, Must call test with arguments. ) at main line ...
            #    main::test(  ) at main line ...
            #    (eval) at main line ...
        }
        #or you can do so:
        print "ERROR: $@";

        #printed:
        #ERROR: Must call test with arguments.
        #    Ambrosia::error::Exception::BadParams::throw( Ambrosia::error::Exception::BadParams, Must call test with arguments. ) at main line ...
        #    main::test(  ) at main line ...
        #    (eval) at main line ...
    }

=cut

=head1 DESCRIPTION

List of different types of exceptions.
Ambrosia::error::Exception - an unspecified exception.
Ambrosia::error::Exception::BadUsage - this exception will occur if you use something incorrect.
Ambrosia::error::Exception::BadParams - this exception will occur if you use incorrect parameters.
Ambrosia::error::Exception::AccessDenied - this exception will occur if you try run closed method.

=cut

=head2 Ambrosia::error::Exception

System exception of undefined type.

=cut

=head2 Ambrosia::error::Exception::BadUsage

Incorrect use of the method of the class.

=cut

=head2 Ambrosia::error::Exception::BadParams

Bad parameters.

=cut

=head2 Ambrosia::error::Exception::AccessDenied

Trying to use a private field or method.

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
