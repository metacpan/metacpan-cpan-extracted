package Acme::Bleach::Numerically;

use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.4 $ =~ /(\d+)/g;
our $MAX_SIZE = 0x7fff_ffff;
use Math::BigInt lib => 'GMP'; # faster if there, fallbacks if not
use Math::BigFloat;
use Math::BigRat;

sub str2num{
    my $str = shift;
    return 0 if $str eq '';
    Math::BigFloat->accuracy(length($str) * 8); 
    my $bnum = Math::BigFloat->new(0);
    my $bden = Math::BigInt->new(256);
    $bden **= length($str);
    for my $ord (unpack "C*", $str){
	$bnum = $bnum * 256 + $ord;
    }    
    $bnum /= $bden;
    $bnum =~ s/0+$//o;
    return $bnum;
}

sub num2str{
    my $num = shift;
    return '' unless $num;
    my $bnum = Math::BigFloat->new($num);
    my $str = '';
    while($bnum > 0){
	$bnum *= 256;
	my $ord = int $bnum->copy;
	$str .= chr $ord;
	$bnum -= $ord;
    }
    return $str;
}

sub import{
    my $class = shift;
    if (@_){ # behave nicely
	my ($pkg, $filename, $line) = caller;
	for my $arg (@_){
	    no strict 'refs';
	    next unless defined &{ "$arg" };
	    *{ $pkg . "::$arg" } = \&{ "$arg" };
	}
    }else{ # bleach!
	open my $in, "<:raw", $0 or die "$0 : $!";
	my $src = join '', grep !/use\s*Acme::Bleach::Numerically/, <$in>;
	close $in;
	# warn $src;
	if ($src =~ /^0\.[0-9]+;?\s*$/){ # bleached
	    my $code = num2str($src);
	    eval $code;
	}else{                       # whiten
	    {
		no warnings;
		eval $src;
		if ($@){                 # dirty
		    $@ =~ s/\(eval \d+\)/$0/eg;
		    die $@;
		}
	    }
	    open my $out, ">:raw", $0 or die "$0 : $!";
	    print $out 
		"use ", __PACKAGE__, ";\n", 
		    str2num($src), "\n";
	}
	exit;
    }
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::Bleach::Numerically - Fit the whole world between 0 and 1

=head1 SYNOPSIS

  # To bleach your script numerically
  use Acme::Bleach::Numerically;
  print "Hello, world!\n";

  # Or do your own bleaching
  use Acme::Bleach::Numerically qw/num2str str2num/;
  my $world = str2num(qq{print "hello, world!\n";})

=head1 DESCRIPTION

Georg Cantor has found that you can squeeze the whole world between
zero and one.  Many say he went insane because of that but the reality
is, he just bleached himself with continuum hypothesis :)

This module does just that -- map your whole world onto a single point
between 0 and 1.  Welcome to the Programming Continuum of Perl!

=head2 EXPORT

This module autobleaches when no argument is passed via C<use>.  When
you pass arguments, you can import C<str2num> and C<num2str> functions
on demand.

=head1 BUGS

This module is pretty slow when trying to bleach very large scripts.

=head1 SEE ALSO

Georg Cantor L<http://en.wikipedia.org/wiki/Georg_Cantor>

L<Acme::Bleach>

L<Math::BigFloat>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=head1 SIGNATURE

  use Acme::Bleach::Numerically;
  0.43924578615781276573636996716277576435622482573471906469302823689043324274942438624694293330322859397882541185113124301737140129679390558528856757159461814533814416533092575624304971700174578115589069897446392714317394330698719965791863652492717345302658253407691232285183052024315270516691972601467999332334238068845967684072917336379759944975376129150390625

=cut
