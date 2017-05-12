package Data::AnyBoolean;

use warnings;
use strict;
use Exporter;

our @ISA         = qw(Exporter);
our @EXPORT      = qw(anyBool);
our @EXPORT_OK   = qw(anyBool);
our %EXPORT_TAGS = (DEFAULT => [qw(anyBool)]);


=head1 NAME

Data::AnyBoolean - Check none Perl boolean values.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Data::AnyBoolean;
    
    if(anyBool( 'yes' )){
        print 'True'
    }
    if(anyBool( 'no' )){
        print 'True'
    }

Any of the items below are considered false.

    undef
    /^[Nn][Oo]$/
    /^[Ff][Aa][Ll][Ss][Ee]$/
    /^[Ff]$/
    /^[Oo][Ff][Ff]$/

Any of the items below are considered true.

    /^[Yy][Ee][Ss]$/
    /^[Tt][Rr][Uu][Ee]$/
    /^[Tt]$/
    /^[Oo][Nn]$/

If any of the above are not matched, it is evaulated as a standard
Perl boolean.

=head1 FUNCTIONS

=head2 anyBool

This returns '0' or '1' after checking the value passed
for the boolean check.

=cut

sub anyBool{
	my $bool=$_[0];

	if (!defined( $bool )) {
		return 0;
	}

	#yes/no
	if ($bool =~/^[Yy][Ee][Ss]$/) {
		return 1;
	}
	if ($bool =~/^[Nn][Oo]$/) {
		return 0;
	}

	#true/false
	if ($bool =~/^[Tt][Rr][Uu][Ee]$/) {
		return 1;
	}
	if ($bool =~/^[Ff][Aa][Ll][Ss][Ee]$/) {
		return 0;
	}

	#on/off
	if ($bool =~/^[Oo][Nn]$/) {
		return 1;
	}
	if ($bool =~/^[Oo][Ff][Ff]$/) {
		return 0;
	}	

	#t/f
	if ($bool =~/^[Tt]$/) {
		return 1;
	}
	if ($bool =~/^[Ff]$/) {
		return 0;
	}

	#try it the perl way
	if ( $bool ) {
		return 1
	}

	return 0;
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-anybollean at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-AnyBollean>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::AnyBoolean


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-AnyBoolean>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-AnyBoolean>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-AnyBoolean>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-AnyBoolean/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Data::AnyBoolean
