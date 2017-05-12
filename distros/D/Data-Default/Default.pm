package Data::Default;
use strict;
use base 'Exporter';
use vars qw[@ISA @EXPORT_OK %EXPORT_TAGS];

# version
use vars '$VERSION';
$VERSION = '0.11';

=head1 NAME

Data::Default -- Small utility for getting the default value of
an argument or variable.

=head1 SYNOPSIS

 use Data::Default ':all';

 # variables
 my ($var);

 # later...

 if (default $var, 1) {
    # stuff if the $var is undef or set to a true value
 }
 else {
    # stuff if the $var is defined and set to true
 }

=head1 DESCRIPTION

Just a little utility for getting the default value of an argument or
parameter.  All it really does is accept an array of arguments, then
return the first argument that is defined.

This function is usually used in a subroutine to get the
default value of a parameter.  A typical usage would be in a subroutine
like this:

 sub mysub {
    my (%opts) = @_;

    if (default $opts{'some-option'}, 1) {
        # do stuff some-option was sent and was true or was not sent
    }
    else {
        # do stuff some-option was sent and was false
    }
}

You might prefer to use C<Attribute::Default> by Stephen Nelson which
provides similar functionality.

=head1 INSTALLATION

String::Util can be installed with the usual routine:

	perl Makefile.PL
	make
	make test
	make install

=cut

# export
@ISA = 'Exporter';
@EXPORT_OK = qw[ default defcontent modcontent choose ];
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);

# default
sub default {
	for (my $i=0; $i<=$#_; $i++) {
		defined($_[$i]) and return $_[$i];
	}
	
	return undef;
}

# return true
1;

=head1 TERMS AND CONDITIONS

Copyright (c) 2010 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

=over

=item Version 0.10    November 7, 2010

Initial release

=item Version 0.11    November 8, 2010

Fixed bug: Exporter was not being loaded.

=back


=cut
