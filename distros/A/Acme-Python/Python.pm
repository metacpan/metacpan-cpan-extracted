package Acme::Python;

$VERSION = 0.01;

my $signed = "Hisssssssssssssssss";

sub encode {
	local $_ = unpack "b*", pop;
	$_ = join ' ', map{ (/1/?'H':'h').'is'.('s' x length); } m/(0+|1+)/g;
	s/(.{40,}?\s)/$1\n/g;
	"$signed\n$_"
}
sub decode {
	local $_ = pop;
	s/(^$signed|\s)//g;
	s/([hH])is(s+)/ ($1 eq 'H'?'1':'0')x(length $2); /ge;
	pack "b*", $_
}
sub garbled {
	$_[0] =~ /\S/
}
sub signed {
	$_[0] =~ /^$signed/
}

open 0 or print "Can't execute '$0'\n" and exit;

(my $program = join "", <0>) =~ s/.*^\s*use\s+Acme::Python\s*;\n//sm;

local $SIG{__WARN__} = \&garbled;

do {
	eval decode $program; 
	exit
} unless garbled $program && not signed $program;


open 0, ">$0" or print "Can't python-ise '$0'\n" and exit;

print {0} "use Acme::Python;\n", encode $program and exit;

__END__

=head1 NAME

Acme::Python - For I<real> python programs

=head1 SYNOPSIS

	use Acme::Python;

	print "Hello world\n";


=head1 DESCRIPTION

The first time you run a program under C<use Acme::Python>, the module
transforms the horrid perl syntax into beautiful python-speak.
The code continues to work exactly as it did before, but now it
looks like this:

	use Acme::Python;
	Hisssssssssssssssss
	hiss Hiss hiss Hiss hisssssssss Hissss hisss 
	Hiss hisss Hissss hiss Hiss hisss Hiss hiss 
	Hisss hisss Hissss hiss Hisss hissss Hiss 
	hiss Hissss hisssssss Hiss hissss Hiss hissss 
	Hiss hissssss Hiss hisss Hiss hiss Hiss hiss 
	Hiss hisss Hisss hissss Hisss hiss Hisss 
	hissss Hisss hiss Hisss hiss Hisssss hiss 
	Hisss hisssssss Hiss hisss Hissss hiss Hiss 
	hiss Hiss hiss Hisssss hiss Hisss hisss Hiss 
	hisss Hissss hissss Hisss hiss Hisss hissss 
	Hiss hisss Hisss hissss Hissss hiss Hiss 
	hisss Hissss hiss Hisss hisss Hiss hissss 
	Hiss hisss Hisss hiss Hissss hisss


=head1 DIAGNOSTICS

=over 4

=item C<Can't python-ise '%s'>

Acme::Python could not access the source file to modify it.

=item C<Can't execute '%s'>

Acme::Python could not access the source file to execute it.


=head1 AUTHOR

Copyright (C) 2004-2005, Cal Henderson, E<lt>cal@iamcal.comE<gt>


=head1 SEE ALSO

L<Acme::Bleach>,

=cut

