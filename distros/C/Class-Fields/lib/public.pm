package public;

use strict;

use vars qw($VERSION);

$VERSION = 0.04;

use Class::Fields::Fuxor;
use Class::Fields::Attribs;

sub import {
    #Dump the class.
    shift;
    
    my $pack = caller;
    foreach my $field (@_) {
        if( $field =~ /^_/ ) {
            require Carp;
            Carp::carp("Use of leading underscores to name public data ",
                       "fields is considered unwise.") if $^W;
        }
    }
    add_fields($pack, PUBLIC, @_);
}


return <<TIP
Displaying one's member publicly will often get one arrested for
indecent exposure.
TIP

__END__
=pod

=head1 NAME

  public - Add public data members to Perl classes


=head1 SYNOPSIS

  package GI::Joe;

  use public qw( Name Rank Serial_Number );

  # see the protected man page for an example of use


=head1 DESCRIPTION

=over 4

=item I<Public member.> 

Externally visible data or functionality.  An attribute or method that
is directly accessable from scopes outside the class.  In Perl, most
members are, by their standard semantics, public.  By convention,
attributes of Perl classes are regarded as private, as are methods
whose names begin with an underscore.

From B<"Object Oriented Perl"> by Damian Conway

=back

public.pm adds a list of keys as public data members to the current
class.  This is useful when using pseudo-hashes as objects, or for
simply imposing a bit more structure on your Perl objects than is
normally expected.  It allows you to use the methods provided in
Class::Fields.

Public data members are those pieces of data which are expected to be
regularly accessed by methods, functions and programs outside the
class which owns them.  They are also inherited by any subclasses.

public.pm serves a subset of the functionality of fields.pm.

  use public qw(Foo);

is almost exactly the same as:

  use fields qw(Foo);

with the exception that you can (if you REALLY want to) do something
like this:

  use public qw(_Foo);

Whereas one cannot do this with fields.pm. (Note: This is considered
unwise and public.pm will scream about it if you have Perl's warnings
on.)

Additionally, public.pm is a bit clearer in its intent and is not
necessarily implying use of pseudo-hashes.


=head1 EXAMPLE

See L<protected/SYNOPSIS> for an example of use.

=head1 MUSINGS

I fully expect public.pm to eventually mutate into a real pragma
someday when a better formalized OO data system for Perl supplants the
current fledgling pseudo-hashes.


=head1 AUTHOR

Michae G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<private>, L<protected>, L<fields>, L<base>, L<Class::Fields>

=cut
