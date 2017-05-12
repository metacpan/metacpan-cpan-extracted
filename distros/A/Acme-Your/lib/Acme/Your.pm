package Acme::Your;
use strict;
use warnings;
require v5.6;

use vars qw/$VERSION $into/;
$VERSION = '0.01';

sub import {
    my $self = shift;
    return unless @_;
    $into = shift;

    # slide around damians cunning - our import needs to go first
    require Acme::Your::Filter;
    Acme::Your::Filter->import();
}

1;
__END__


=head1 NAME

Acme::Your - not our variables, your variables

=head1 SYNOPSIS

    use Data::Dumper;
    use Acme::Your "Data::Dumper";

    your $Varname;  # This is really $Data::Dumper::Varname

    print "The default variable name for DD is $Varname";

=head1 DESCRIPTION

Acme::Your gives you a language construct "your" that behaves
similarly to Perl's own "our" constuct.  Rather than defining
lexically unqualified varibles to be in our own package however, you
can define lexically unqualified variable to be from anothter package
namespace entirely.

It all starts with the use statement.

    use Acme::Your "Some::Package";

This both 'imports' the your construct and states the package that any
variables defined with a your statement will be created in.

Then you can do 'your' statements.  Note that these are lexical, and
fall out of scope much the same way that our variables would.  For
example

    use Acme::Your "Fred"

    my $foo = "bar";

    {
        your $foo = "wilma";
        print $foo;  # prints "wilma"
    }

    print $foo;      # prints "foo"
    print $Fred::foo # prints "wilma"

Your allows you to import symbols from other packages into your
own lexical scope and have access to them.

=head1 BUGS

Acme::Your functions by parsing your source code and filtering it
with a source filter.  It is possible to fool the parser with some
pathelogical cases and you should be aware that this module faces all
the standard problems that perl faces when parsing Perl Code.

=head1 VERSION

Acme::Your 0.01 was released on 14th January 2002.

=head1 AUTHOR

Richard Clamp E<lt>richardc@unixbeard.netE<gt>

Original idea, documentation, and tests which kill, Mark Fowler
E<lt>mark@twoshortplanks.comE<gt>

=head1 COPYRIGHT

       Copyright (C) 2002 Richard Clamp and Mark Fowler.
       All Rights Reserved.

       This module is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Filter::Simple>, L<Parse::RecDescent>.

=cut
