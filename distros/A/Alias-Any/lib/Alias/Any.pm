package Alias::Any;

use 5.012;
use warnings;

our $VERSION = '0.000007';

use Keyword::Simple;

# Make 'keyword' and 'unkeyword' no-ops, unless Keyword::Declare is later loaded...
BEGIN {
    sub _delete_source { my $ref = shift; $$ref =~ s{ \A .*? [#]END_OF_ALIAS }{}xms; }
    Keyword::Simple::define(   keyword => \&_delete_source );
    Keyword::Simple::define( unkeyword => \&_delete_source );
}

sub import {
    # Below 5.22, alias keyword just injects Data::Alias...
    if ($^V <  5.022) {
        Keyword::Simple::define(
            alias => sub {
                my $ref = shift;
                $$ref = q{use Data::Alias; Data::Alias::alias} . $$ref;
            }
        );
    }

    # Above 5.22, alias keyword replaced with built-in syntax...
    use if $^V >= 5.022, 'Keyword::Declare';

    keyword alias (Variable|VariableDeclaration $variable, '=', Expr $expr) {{{
        use feature 'refaliasing';
        no warnings 'experimental::refaliasing';
        \<{$variable}> = \<{$expr}>
    }}} #END_OF_ALIAS
}

sub unimport {
    # Below 5.22, alias keyword is undefined by Keyword::Simple...
    if ($^V < 5.022) {
        Keyword::Simple::undefine('alias');
        if ($Keyword::Simple::VERSION < 0.04) {
            $^H{'Keyword::Simple/keywords'} =~ s{ alias:(?:\d+|-\d*)}{}g;
        }
    }

    # Above 5.22, alias keyword is unkeyworded by Keyword::Declare...
    use if $^V >= 5.022, 'Keyword::Declare';
    unkeyword alias; #END_OF_ALIAS
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Alias::Any - Create lexical aliases under different versions of Perl


=head1 VERSION

This document describes Alias::Any version 0.000007


=head1 SYNOPSIS

    use v5.12;
    use Alias::Any;

    alias my $scalar_alias = $scalar_var;

    alias my @array_alias = @array_var;

    alias my %hash_alias = %hash_var;


    no Alias::Any;

    alias my $var = $ref;    # Syntax error


=head1 DESCRIPTION

This module is simply a convenient wrapper around the various mechanisms
by which aliases can be defined under different versions of Perl.

Under Perl 5.12 to 5.18, the module uses the 'alias' function
from the Data::Alias module to create the requested alias.

But previous releases of Data::Alias didn't work under Perl 5.24 or
later, and from Perl 5.22 there is a more robust built-in aliasing
mechanism available anyway. So under Perl 5.22 or later, this module
uses the built-in mechanism in preference to Data::Alias.

This means you can define simple aliases using a consistent syntax,
without needing to worry which version of Perl (or Data::Alias)
your code will vebe running under.


=head1 INTERFACE

The module exports a single keyword (C<alias>) that constructs the
requested alias. The syntax of the keyword is:

    alias <new_alias> = <existing_thing>;

The new alias must be a variable (or a variable declaration). The
"existing thing" must either be an expression yielding a variable
of the same type as the alias (i.e. scalar, array, or hash):

    alias $value = $another_value;
    alias @list  = @another_list;
    alias @data  = @{ get_data_as_array_ref() };

If the alias is a scalar variable the expression can also be a
scalar constant:

    alias $PI = 3.1415926;

In the latter case, of course, the alias will be immutabe too.

To remove the C<alias> keyword for the rest of the current lexical
scope, use:

    no Alias::Any;

Note that this only removes the C<alias> keyword; it will have no effect
on any aliases already defined at that point.


=head1 DIAGNOSTICS

=over

=item C<< 'alias' keyword requires Data::Alias module under Perl %d >>

Under Perl 5.12 to 5.18, the module uses Data::Alias to implement
its magic. You used the module, but it couldn't load Data::Alias.

=item C<< syntax error at %s, near "alias" >>

You attempted to declare an alias at a point in the code where the
C<alias> keyword was not installed. Did you forget to put a
S<C<use Alias::Any;>> earlier in that lexical scope?

Or did you insert a S<C<no Alias::Any;>> somewhere above the alias?

=back

The module may also produce any diagnostic that Data::Alias or
Perl's built-in refaliasing does. For example:

    use 5.24;
    alias my @foo = %bar;
    # Dies with: Assigned value is not an ARRAY reference...



=head1 CONFIGURATION AND ENVIRONMENT

Alias::Any requires no configuration files or environment variables.


=head1 DEPENDENCIES

Keyword::Declare (under Perl 5.22 or later)
Data::Alias      (under Perl 5.20 or earlier)


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

The module defines a new C<alias> keyword, so it only works under Perl
5.12 or later.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-alias-any@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
