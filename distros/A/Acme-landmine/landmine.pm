package Acme::landmine;

use 5.000;
use strict;
use Carp;
no strict 'refs';

use vars qw'$VERSION $AUTOLOAD';

$VERSION = '1.00';


sub DESTROY{

};

sub AUTOLOAD {

         if($AUTOLOAD =~ /TIE/) {

		eval <<EOF;
		sub $AUTOLOAD {
			my \$flavor = shift;
			my \$sin = shift;
			bless \\\$sin, \$flavor;
		}
EOF
	}else{
		eval <<EOF;
		sub $AUTOLOAD {
			my \$sin = shift;
			confess  \$\$sin;
		};

EOF
	};

        goto &$AUTOLOAD;
}
	

1;
__END__

=head1 NAME

Acme::landmine -  variables that explode 

=head1 SYNOPSIS

  use Acme::landmine; # crucial, this line
  tie $scalar, "Acme::landmine" => "first use of \$scalar";
  tie @array, "Acme::landmine" => "first use of \@array";
  tie %hash, "Acme::landmine" => "first use of \%hash";

=head1 ABSTRACT

  variables that "explode", which useful for locating the first
  use of a variable after a checkpoint, while debugging.

=head1 DESCRIPTION

 a tie interface that C<confess>es.  This is useful
 for creating out-of-bounds markers when modeling data structures,
 or setting a checkpoint when you want to know the next time
 a variable is accessed after some point.

 DESTROY is not mined, but everything else is. 

=head2 EXPORT

None.

=head1 HISTORY

2002 - released version 0.01

2006 - cleaned up the documentation to describe how I actually
use this module in production work, bumped version to 1.00

=head1 how it works

we've got two functions, DESTROY, which is just there so
AUTOLOAD isn't called at DESTROY time, and AUTOLOAD, which
behaves differently if you are calling TIE-something or if
you are using your tied variable.  at C<tie> time, the AUTOLOAD
function blesses the tie argument, if any, as a scalar reference,
so the argument is saved as the "sin" to "confess" (that is, 
die with a stack-trace) when the
exploding variable is used any other way.

If you look at the source code of this module, which is very short,
you will see that the sin variable is associated with the
named autoloaded function with a string evaluation, which might
appear to allow executing arbitrary code, as long as it is
well-formed and begins with an r-value, but this is not the
case: the argument is never interpolated into the string, and
the TIE functions are abstracted in this way to avoid having to
duplicate code for TIESCALAR, TIEARRAY, TIEHASH, TIEFILE, TIESCARF,
and any other future TIE* possibilities that might happen to
appear.

=head1 COPYRIGHT AND LICENSE

copyright 2002, 2006 David Nicol davidnico@cpan.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

please feedback and bugreport via

   https://rt.cpan.org/Ticket/Create.html?Queue=Acme-landmine

=head1 SEE ALSO

L<Carp>

=cut
