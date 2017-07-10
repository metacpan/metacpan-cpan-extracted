package Alias::Any;

use 5.012;
use warnings;

our $VERSION = '0.000004';

use Keyword::Declare;

sub import {
    keyword alias (Variable|VariableDeclaration $variable, '=', Expr $expr) {
        if ($^V >= 5.022) {
            qq{use feature 'refaliasing';}
          . qq{no warnings 'experimental::refaliasing';}
          . qq{\\$variable = \\$expr}
        }
        else {
            eval { require Data::Alias; 1 }
                // die "'alias' keyword requires Data::Alias module under Perl $^V\nat "
                 . join(' line ', (caller 2)[1,2]) . "\n";
            qq{Data::Alias::alias $variable = $expr}
        }
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Alias::Any - Create lexical aliases under different versions of Perl


=head1 VERSION

This document describes Alias::Any version 0.000004


=head1 SYNOPSIS

    use v5.12;
    use Alias::Any;

    alias my $scalar_alias = $scalar_var;

    alias my @array_alias = @array_var;

    alias my %hash_alias = %hash_var;


=head1 DESCRIPTION

This module is simply a convenient wrapper around the various mechanisms
by which aliases can be defined under different versions of Perl.

Under Perl 5.12 to 5.18, the module uses the 'alias' function
from the Data::Alias module to create the requested alias.

But Data::Alias doesn't work under Perl 5.24 or later, so under Perl
5.22 or later, the module uses the built-in refaliasing mechanism.

(Unfortunately, the module does not work at all under Perl 5.20, because
of a long-standing problem with compilation of large recursive regexes
in that release.)

This means you can define simple aliases using a consistent syntax,
without needing to worry which version of Perl your code will run under.


=head1 INTERFACE

The module exports a single keyword (C<alias>) that constructs the
requested alias. The syntax of the keyword is:

    alias <new_alias> = <existing_thing>;

The new alias must be a variable (or variable declaration). The
"existing thing" must either be a variable of the same type as the
alias (i.e. scalar, array, or hash), or (if the alias is a scalar
variable) a constant:

    alias $PI = 3.1415926;

In the latter case, of course, the alias will be a constant too.


=head1 DIAGNOSTICS

=over

=item C<< 'alias' keyword requires Data::Alias module under Perl %d >>

Under Perl 5.12 to 5.18, the module uses Data::Alias to implement
its magic. You used the module, but it couldn't load Data::Alias.

=back

The module may also produce any diagnostic that Data::Alias or
Perl's built-in refaliasing does. For example:

    use 5.24;
    alias my @foo = %bar;
    # Dies with: Assigned value is not an ARRAY reference...



=head1 CONFIGURATION AND ENVIRONMENT

Alias::Any requires no configuration files or environment variables.


=head1 DEPENDENCIES

Keyword::Declare
Data::Alias (under Perl 5.18 or earlier)


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

The module defines a new C<alias> keyword, so it
only works under Perl 5.12 or later.

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
