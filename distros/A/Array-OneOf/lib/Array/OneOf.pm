package Array::OneOf;
use strict;

# version
our $VERSION = '1.04';

# export
use base 'Exporter';
use vars qw[@EXPORT_OK %EXPORT_TAGS];
@EXPORT_OK = qw[ oneof ];
%EXPORT_TAGS = ('all' =>[@EXPORT_OK]);


=head1 NAME

Array::OneOf -- checks if an element is in an array

=head1 SYNOPSIS

 use Array::OneOf ':all';
 
 # this test will pass
 if (oneof 'a', 'a', 'b', 'c') {
    # do stuff
 }
 
 # this test will not pass
 if (oneof 'x', 'a', 'b', 'c') {
    # do stuff
 }

=head1 DESCRIPTION

Array::OneOf provides one simple utility, the oneof function.  Its use is
simple: if the first param is equal to any of the remaining params (in a
string comparison), it returns true.  Otherwise it returns false.

In this module, undef is considered the same as undef, and not the same as any
defined value.  This is different than how most Perl programmers usually expect
comparisons to work, so caveat programmer.

=head1 ALTERNATIVES

Array::OneOf is not a particularly efficient way to test if a value is in an
array.  If efficiency is an important goal you may want to look at
List::MoreUtils or Syntax::Keyword::Junction.  You may also want to
investigate using grep and/or the smart match operator (~~).  I use
Array::OneOf because it compares values the way my projects need them compared,
its simple syntax, and small footprint.

=head1 INSTALLATION

Array::OneOf can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=cut

#------------------------------------------------------------------------------
# oneof
#
sub oneof {
	my ($base, @remaining) = @_;
	
	COMPARE_LOOP:
	foreach my $rem (@remaining) {
		# if both are undef, return true
		if ( (! defined $base) && (! defined $rem) )
			{ return 1 }
		
		# if just one is undef, go to next loop
		if ( (! defined $base) || (! defined $rem) )
			{ next COMPARE_LOOP }
		
		# if they're the same, return true
		if ($base eq $rem)
			{ return 1 }
	}
	
	# not found, return false
	return 0;
}
#
# oneof
#------------------------------------------------------------------------------


# return true
1;

__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2012-2013 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=head1 HISTORY

=over

=item Version 1.00    November 22, 2012

Initial release.

=item Version 1.01    November 25, 2012

Removed dependency on String::Util.  Clarified in documentation the advantages
and disadvantages of Array::OneOf, and suggested some alternative modules.

=item Version 1.02    November 28, 2012

Cleaned up test.pl so that it compiles on many of the testers' machines.

=item Version 1.03    February 5, 2013

Fixed problem with mismatched newlines.

=item Version 1.04    April 25, 2014

Fixed problem in CPAN package.

=back

=cut
