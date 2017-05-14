
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Collection::Perl6::Interface;

our @ISA = qw(Data::Type::Object::Interface);

sub prefix : method { 'Perl6::' }

package Data::Type::Collection::Perl6;

our @ISA = qw(Data::Type::Collection::Perl6::Interface);

1;

__END__

=head1 Perl6 Synopsis 6

=head2 Types

These are the standard type names in Perl 6 (at least this week):

    bit         single native bit
    int         native integer
    str         native string
    num         native floating point
    ref         native pointer 
    bool        native boolean
    Bit         Perl single bit (allows traits, aliasing, etc.)
    Int         Perl integer (allows traits, aliasing, etc.)
    Str         Perl string
    Num         Perl number
    Ref         Perl reference
    Bool        Perl boolean
    Array       Perl array
    Hash        Perl hash
    IO          Perl filehandle
    Code        Base class for all executable objects
    Routine     Base class for all nameable executable objects
    Sub         Perl subroutine
    Method      Perl method
    Submethod   Perl subroutine acting like a method
    Macro       Perl compile-time subroutine
    Rule        Perl pattern
    Block       Base class for all unnameable executable objects
    Bare        Basic Perl block
    Parametric  Basic Perl block with placeholder parameters
    Package     Perl 5 compatible namespace
    Module      Perl 6 standard namespace
    Class       Perl 6 standard class namespace
    Object      Perl 6 object
    Grammar     Perl 6 pattern matching namespace
    List        Perl list
    Lazy        Lazily evaluated Perl list
    Eager       Non-lazily evaluated Perl list


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

