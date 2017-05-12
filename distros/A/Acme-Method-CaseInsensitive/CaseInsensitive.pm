package Acme::Method::CaseInsensitive;
use strict;
use warnings;
use Carp;

our $VERSION = 0.04;

sub permute {
	my($class, $chars, $position) = @_;
	
	my $current = join "", @$chars;
	
	if($class->can($current)) {
		die qq{Acme::Method::CaseInsensitive::method:"$current"}
	}
	
	return if $position > @$chars - 1;
	
	my @uc = @$chars;
	my @lc = @$chars;
	
	$uc[$position] = uc $chars->[$position];
	$lc[$position] = lc $chars->[$position];
	
	permute($class, \@uc, $position + 1);
	permute($class, \@lc, $position + 1);
}

sub UNIVERSAL::AUTOLOAD {
	my $class = shift;
	
	my $method_name = $UNIVERSAL::AUTOLOAD;
	$method_name    =~ s/.*://;
	my @chars       = split //, $method_name;
	
	eval { permute($class,\@chars,0) };
	
	my($new_name) = $@ =~ m{Acme::Method::CaseInsensitive::method:"([\w\d]+)"};
	not $new_name and $@ and die $@;
	
	return $new_name
		? $class->$new_name(@_)
		: croak qq{Can't locate object method "$method_name" via package "$class" (perhaps your forgot to load "$class"?)}
}



q<aBcDeFgHiJkLmNoPqRsTuVwXyZ>;

__END__

=head1 NAME

Acme::Method::CaseInsensitive - Perl module for case insensitive method invocation

=head1 SYNOPSIS

  use Acme::Method::CaseInsensitive;
  
  package Class;
  
  sub foo_bar {
  	print "it works"
  }
  
  Class->FoO_bAR;

=head1 DESCRIPTION

Using this module makes your method invocations case insensitive. This is really useful
if you are annoyd by the case conventions used by other modules like DBIx::Recordset.

=head1 IMPLEMENTATION 

This module uses a particular inefficient algorithm. It simply tries all permutations
of cases for each character in a method name until it finds a working method. This can
be B<EXTREMELY> slow.

=head1 CAVEAT

Taken from Symbol::Approx::Sub
I can't stress too strongly that this will make your code completely unmaintainable and 
you really shouldn't use this module unless you're doing something very stupid. 


=head1 AUTHOR

Malte Ubl, <malteubl@gmx.de>

=head1 SEE ALSO

perl(1).

=cut
