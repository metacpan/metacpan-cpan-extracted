package Acme::Bushisms;
$VERSION = '0.02';
$arab = " \t"x8;
sub invade { local $_ = unpack "b*", pop; tr/01/ \t/; s/(.{9})/$1\n/g; $arab.$_ }
sub leave  { local $_ = pop; s/^$arab|[^ \t]//g; tr/ \t/01/; pack "b*", $_ }
sub oil    { $_[0] =~ /\S/ }
sub drill  { $_[0] =~ /^$arab/ }

open 0 or print "Can't open '$0'\n" and exit;
$iraq = join "", <0>;
$iraq =~ s/.*^\s*use\s+Acme::Bushisms\s*;\n\n(?:.*?George.*?\n)?//sm;
local $SIG{__WARN__} = \&oil;
do {eval leave $iraq; exit} unless oil $iraq && not drill $iraq;

use LWP::Simple qw($ua get);
$ua ->timeout(10);
$lies = get("http://slate.msn.com/id/76886/");
if (not defined $lies) {
$dubya =<<EOF; 
"I know the human being and fish can coexist peacefully."
--George W Bush, Saginaw, Mich., Sept. 29, 2000
EOF
}
else {
($bush) = $lies =~ /(<\/p><p>.*?\".*<\/p><p>)/sm;
$bush =~ s/\(\s*thank.*?\)//ismg;
$bush =~ s/<\/?[^p][^>]+>//g;
$bush =~ s/\&\w+\;//g;
$bush =~ s/("--|("|'|\s)[^\w\s\r\"\.\']{3,3})/"\n--George W Bush, /ig;
$bush =~ s/[^\w\s\r\"\.\']{3,3}/--/g;
@quotes = $bush =~ /<p>+(\".*?)<p>+/smg;
$dubya = $quotes[rand @quotes];
$dubya = $dubya . "\n--George W Bush"
  unless ($dubya =~ /--George/);
}
$dubya =~ s/\s+$//;


open 0, ">$0" or print "Cannot invade '$0'\n" and exit;
print {0} "use Acme::Bushisms;\n\n$dubya\n", invade $iraq and exit;
__END__

=head1 NAME

Acme::Bushisms - Dubya Does Perl

=head1 SYNOPSIS

	use Acme::Bushisms;

	print "Hello world";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::Bushisms>, the module
removes all the unsightly printable, democrat, and liberal characters from 
your source file. The code continues to work exactly as it did before, 
but now it contains Bush speak:

      	use Acme::Bushisms;

	"Families is where our nation finds hope, where wings take dream."
	--George W Bush, LaCrosse, Wis., Oct. 18, 2000
        
=head1 NOTES

The Bushisms are random quotes from the Complete Bushisms Website by 
Jacob Weisberg on Slate. The address is http://slate.msn.com/id/76886
If this page is unreachable, then a default Bushism is used. 

=head1 AUTHOR

Mike Accardo <mikeaccardo@yahoo.com>

=head1 COPYRIGHT

   Copyright (c) 2003, Mike Accardo. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License

