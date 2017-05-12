package Od_o;

our $VERSION = '0.14';

use B;
use Carp;

sub import {
    my ($class, @options) = @_;
    my $backend = shift (@options);
    # XXX This messes up COP line info when stepping into the compiler callback.
    eval q[
	CHECK {
	    use B::].$backend.q[ ();
	    if ($@) { croak "use of backend $backend failed: $@"; }
        }
	INIT {
	    # local $savebackslash = $\; local ($\,$",$,) = (undef,' ','');
	    &{"B::${backend}::compile"}(@options);
	}
    ];
    die $@ if $@;
}

1;

__END__

=head1 NAME

Od_o - Debug into a Perl Compilers backend options handling

=head1 SYNOPSIS

	perl -d -MOd_o=Backend[,OPTIONS] foo.pl

	Od_o::CODE(0x14d5e00)((eval 9)[lib/Od_o.pm:12]:8):
	8:                  &{"B::${backend}::compile"}(@options);
  	DB<1> s
	B::C::compile(lib/B/C.pm:3159):
	3159:     my @options = @_;

=head1 DESCRIPTION

This module is a minor variant to L<Od> to step into the compiler backend
B<option handling>.

B<Od> passes through the options at compile-time and steps through the compile
method. B<Od_o> passes through the options at run-time but fails to step
through the compile method with proper cop settings, i.e. line info.

Think of B<Od> as fast way into the compiler and B<Od_o> as fast way into the
option handling part of compile.

=head1 AUTHOR

Reini Urban, C<rurban@cpan.org> 2009

=cut
