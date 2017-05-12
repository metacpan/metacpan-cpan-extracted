## ----------------------------------------------------------------------------
#  Contextual::Call
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package Contextual::Call;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(ccall);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.01';
1;

# -----------------------------------------------------------------------------
# my $result = ccall \&sub;
#
sub ccall ($;$)
{
	my $wantarray;
	my $sub;
	
	@_ or die "ccall: argument required";
	if( UNIVERSAL::isa($_[0], 'CODE') )
	{
		$wantarray = (caller(1))[5];
		$sub       = shift;
	}else
	{
		$wantarray = shift;
		$sub       = shift;
	}
	
	Contextual::Call->new({
		context => $wantarray,
		sub     => $sub,
	});
}

# -----------------------------------------------------------------------------
# $pkg->new({ context => wantarray, sub => \&sub });
#
sub new
{
	my $pkg  = shift;
	my $opts = shift;
	
	my $wantarray = $opts->{context};
	my $sub       = $opts->{sub};
	my @result;
	
	if( $wantarray )
	{
		# list context.
		@result = $sub->(@_);
	}elsif( defined($wantarray) )
	{
		# scalar context.
		$result[0] = $sub->(@_);
	}else
	{
		# void context.
		$sub->(@_);
	}
	
	my $this = bless {}, __PACKAGE__;
	$this->{context} = $wantarray;
	$this->{result}  = \@result;
	
	$this;
}

# -----------------------------------------------------------------------------
# $cresult->result();
#
sub result
{
	my $this = shift;
	my $wantarray = $this->{context};
	if( $wantarray )
	{
		# list context.
		@{$this->{result}};
	}elsif( defined($wantarray) )
	{
		# scalar context.
		$this->{result}->[0];
	}else
	{
		# void context.
		return;
	}
}

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT
	OO-style
	ccall

=head1 NAME

Contextual::Call - call sub with caller's context


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

 use Contextual::Call qw(ccall);

 # invoke sub with your context.
 my $cc = ccall($coderef);
 
 ... some processes ..
 
 # and return value which was returned by $coderef and 
 # is matched with context.
 return $cc->result;

=head1 DESCRIPTION

L</ccall> function can invoke a function undef specified context
(default is caller's context) and reproduce return value of that
invocation.


This function is useful when you will override a method
which returns different values between scalar and list context.


=head1 EXPORT

This module can export C<ccall> function.


=head1 FUNCTIONS

=head2 ccall

 $cc = ccall($coderef);

Call specified code-ref with your context, and return 
a Contextual::Call object which contains result of that call.
You can get the result appropriate for context.


This function is shortcut to L</new> constructor.


=head1 CONSTRUCTOR

=head2 new

 $obj = Contextual::Call->new({ context => wantarray, sub => $coderef });

Call specified code-ref with your context, 
and return a Contextual::Call object.
This method is OO-style of L</ccall> function.


=head1 METHODS

=head2 result

 return $obj->result();

Return result value with same context with ccall/new.


=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-contextual-call at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Contextual-Call>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.


    perldoc Contextual::Call

You can also look for information at:


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Contextual-Call>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Contextual-Call>


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Contextual-Call>


=item * Search CPAN

L<http://search.cpan.org/dist/Contextual-Call>


=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 YAMASHINA Hio, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


