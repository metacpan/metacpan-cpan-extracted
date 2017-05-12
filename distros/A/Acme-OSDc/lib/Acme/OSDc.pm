package Acme::OSDc;

use base 'Acme::Ook';

my %OSDc = &{"Acme::Ook::O?"};

use strict;
use warnings;

our $VERSION = '1.01';

sub _compile {
    shift;
    chomp $_[0];
    $_[0] =~ s/\s*(OSDc(.)\s*OSDc(.)\s*|(\#.*)|\S.*)/$;=$OSDc{$2||@@}{$3};$;?$;:defined$4?"$4\n":die"OSDc? $_[1]:$_[2] '$1'\n"/eg;
    return $_[0];
}

1;

__END__

=head1 NAME

Acme::OSDc - the OSDc programming language

=head1 SYNOPSIS

	use Acme::OSDc;
	my $OSDc = Acme::OSDc->new;
	
	my $compiled = $OSDc->compile($file);
	
	eval $compiled;

=head1 DESCRIPTION

The I<OSDc> programming language is a transformation of the
I<Ook> programming language described at
<http://www.dangermouse.net/esoteric/ook.html>.  It was first
presented at the Australian Open Source Deevloper's conference
in 2006.

=head1 THANKS

A great many thanks go to:

=over 4

=item Jon Oxer

For writing the first OSDc code generator in php5, and presenting
it as a lightning talk at OSDC-AU 2006.

=item Jarkko Hietaniemi

For writing the L<Acme::Ook> module upon which this is based,
and for publishing a patched version to CPAN with less than
24 hours notice so I could write my lightning talk.

=item The OSDC-AU committee

For putting together such a fantastic conference every year!

=back

=head1 SEE ALSO

L<Acme::Ook>  L<http://www.osdc.com.au/>

=cut

