package Data::Swap;

=head1 NAME

Data::Swap - Swap type and contents of variables

=head1 SYNOPSIS

    use Data::Swap;

    my $p = [];
    my $q = {};
    print "$p $q\n";		# ARRAY(0x965cc) HASH(0x966b0)
    swap $p, $q;		# swap referenced variables
    print "$p $q\n";		# HASH(0x965cc) ARRAY(0x966b0)

    my $x = {};
    my $y = $x;			# $x and $y reference same var
    swap $x, [1, 2, 3];		# swap referenced var with an array
    print "@$y\n";		# 1 2 3

    use Data::Swap 'deref';

    my @refs = (\$x, \@y);
    $_++ for deref @refs;	# dereference a list of references

    # Note that I omitted \%z from the @refs because $_++ would fail 
    # on a key, but deref does work on hash-refs too of course.

=head1 DESCRIPTION

This module allows you to swap the contents of two referenced variables, even
if they have different types.

The main application is to change the base type of an object after it has been
created, for example for dynamic loading of data structures:

    swap $self, bless $replacement, $newclass;

This module additionally contain the function C<deref> which acts like a
generic list-dereferencing operator.

=head1 FUNCTIONS

=head2 swap I<REF1>, I<REF2>

Swaps the contents (and if necessary, type) of two referenced variables.

=head2 deref I<LIST>

Dereferences a list of scalar refs, array refs and hash refs.  Mainly exists 
because you can't use C<map> for this application, as it makes copies of the 
dereferenced values.

=head1 KNOWN ISSUES

You can't C<swap> an overloaded object with a non-overloaded one, 
unless you use Perl 5.10 or later.

Also, don't use C<swap> to change the type of a directly accessible 
variable -- like C<swap \$x, \@y>.  That's just asking for segfaults.  
Unfortunately there is no good way for me to detect and prevent this.

=head1 AUTHOR

Matthijs van Duin <xmath@cpan.org>

Copyright (C) 2003, 2004, 2007, 2008  Matthijs van Duin.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.08';

use base 'Exporter';
use base 'DynaLoader';

our @EXPORT = qw(swap);
our @EXPORT_OK = qw(swap deref);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

bootstrap Data::Swap $VERSION;

1;
