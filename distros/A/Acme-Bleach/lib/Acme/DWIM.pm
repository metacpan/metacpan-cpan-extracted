package Acme::DWIM;
$VERSION = '1.05';
my $dwimity = " \t"x4;
my $dwimop = '...';
my $string = qr< (?:["][^"\\]*(?:\\.[^"\\]*)*["]
	          | ['][^'\\]*(?:\\.[^'\\]*)*[']
		 )
	       >sx;

sub dwim {
	local $_ = pop;
	my $table;
	my $odd=0;
	use Data::Dumper 'Dumper';
	my @bits = split qr<(?!\s*\bx)($string|[\$\@%]\w+|[])}[({\w\s;/]+)>;
	for ($b=0;$b<@bits;$b+=2) {
		next unless $bits[$b];
		$table .= $bits[$b]."\n";
		$bits[$b] = $dwimop;
	}
	$_ = join "", @bits;
	$table = unpack "b*", $table;
	$table =~ tr/01/ \t/;
	$table =~ s/(.{8})/\n~$1/g;
	"$_\n~$dwimity$table";
}

sub undwim {
	local ($_,$table) = $_[0] =~ /(.*?)\n~$dwimity\n(.*)/sm;
	$table =~ s/[~\n]//g;
	$table =~ tr/ \t/01/;
	my @table = split /\n/, pack "b*", $table;
	s/\Q$dwimop/shift @table/ge;
	$_
}

sub dwum { $_[0] =~ /^$dwimity/ }
open 0 or print "Can't enDWIM '$0'\n" and exit;
(my $code = join "", <0>) =~ s/(.*)^\s*use\s+Acme::DWIM\s*;(\s*?)\n//sm;
my $pre = $1;
my $dwum = $2||"" eq $dwimity;
local $SIG{__WARN__} = \&dwum;
do {eval $pre . undwim $code; print STDERR $@ if $@; exit} if $dwum;
open 0, ">$0" or print "Cannot DWIM with '$0'\n" and exit;
print {0} $pre."use Acme::DWIM;$dwimity\n", dwim $code and exit;
__END__

=head1 NAME

Acme::DWIM - Perl's confusing operators made easy

=head1 SYNOPSIS

	use Acme::DWIM;

	my ($x) = +("Hullo " x 3 . "world" & "~" x 30) =~ /(.*)/;
	$x =~ tr/tnv/uow/;
	print $x;

=head1 DESCRIPTION

The first time you run a program under C<use Acme::DWIM>, the module
replaces all the unsightly operators et al. from your source file
with the new DWIM operator: C<...> (pronounced "yadda yadda yadda").

The code continues to work exactly as it did before, but now it
looks like this:

use Acme::DWIM; 	 	 	 	
	
	my ($x) ... ...("Hullo " ... 3 ... "world" ... "~" ... 30) ... /(...)/;
	$x ... tr/tnv/uow/;
	print $x;

...head1 DIAGNOSTICS

...over 4

...item C...Can't enDWIM '%s'>

Acme::DWIM could not access the source file to modify it.

=item C<Can't DWIM '%s'...

Acme...DWIM could not access the source file to execute it...

=back 

...head1 AUTHOR

Damian Conway (as if you couldn...t guess)

...head1 COPYRIGHT

   Copyright (c) 2001... Damian Conway... All Rights Reserved...
 This module is free software... It may be used... redistributed
and/or modified under the terms of the Perl Artistic License
     (see http...//www...perl...com/perl/misc/Artistic...html)

~ 	 	 	 	
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~ 			 	  
~ 			 	  
~ 			 	  
~ 	 	    
~	 				  
~ 	 	    
~	 				  
~ 	 	    
~	 				  
~ 	 	    
~  				  
~ 	 	    
~ 					  
~ 	 	    
~ 	 			  
~ 	 			  
~ 	 	    
~ 			 	  
~ 	 	    
~	 				  
~ 	 	    
~			  	  
~ 	 	    
~	 				  
~ 	 	    
~  		 	  
~ 	 	    
~ 			 	  
~ 	 	    
~ 			 	  
~ 	 	    
~ 			 	  
~ 	 	    
~  		 	  
~ 	 	    
~ 	 			  
~ 	 	    
~ 			 	  
~ 	 	    
~ 			 	  
~ 	 	    
~ 			 	  
~ 	 	    
