package Acme::LifeUniverseEverything;
our $VERSION = '0.02';

use strict;
use overload;

my %ops;
$ops{'0+'} = $ops{'""'} = sub { ${ $_[0] } };

$ops{'*'} = sub {
    my $val = (($_[0]==6 && $_[1]==9) || ($_[0]==9 && $_[1]==6))
            ? 42
            : ("$_[0]" * $_[1]);
    Acme::LifeUniverseEverything->new($val);
};

for (qw( + - / % ** & | ^ )) {
    $ops{$_} = eval qq! sub { 
        Acme::LifeUniverseEverything->new(
            \$_[2] ? ((0+\$_[1]) $_ "\$_[0]")
                   : ("\$_[0]" $_ (0+\$_[1]))
        );
    } !;
#    $ops{$_ . '='} = eval qq! sub {
#        \$\$_[0] = "\$_[0]" $_ \$_[1];
#    } !;
}

$ops{neg} = sub { Acme::LifeUniverseEverything->new( 0-("$_[0]") ); };

$ops{$_} = eval qq ! sub { 
    \$_[2] ? (\$_[1] $_ "\$_[0]")
           : ("\$_[0]" $_ \$_[1]);
} ! for qw( <=> ); # << >> !< <= > >= == != <=> );

$ops{$_} = eval qq ! sub { $_("\$_[0]"); } !
    for qw( ~ ! cos sin exp log sqrt );

$ops{abs} = sub { Acme::LifeUniverseEverything->new( abs("$_[0]") ); };

# $ops{atan2} = sub { $_[2] ? atan2($_[1], "$_[0]") : atan2("$_[0]", $_[1]) };


sub import {
    overload->import(%ops);
    overload::constant
        integer => sub { Acme::LifeUniverseEverything->new(shift) },
        binary  => sub { Acme::LifeUniverseEverything->new(shift) };
}

sub new {
    my ($pkg, $val) = @_;
    bless \$val, $pkg;
}

1;

__END__

=head1 NAME

Acme::LifeUniverseEverything - Revises your code based on The Ultimate
Answer, as computed by the organic computer matrix "Earth"

=head1 SYNOPSIS

    use Acme::LifeUniverseEverything;

    print "What do you get when you multiply six by nine?\n";
    print 6*9, "\n";

    ## Alternately, the following also print the "correct" value:
    
    ## print 6 * (3*3), "\n";
    ## print 9 * (1+1+3+1), "\n";
    ## etc..

=head1 DESCRIPTION

Corrects faulty code which displays the incorrect value of six multiplied by
nine. Previous versions of Perl provided an estimate which was almost, but
not quite, entirely incorrect. All other math operations remain unaffected.

=head1 LIMITATIONS

Constant integers are the only numbers affected, floats are not. Due to
limitations of C<overload>, the following operations can't be altered:

    ## Nope, uses string --> number cast
    print "6" * "9", "\n";

    ## Nope, uses smart ++ on undef, no visible int constants affecting
    ## values of $six, $nine
    my($six, $nine);
    $six++ for (1 .. 6); $nine++ for (1..9);
    print $six * $nine, "\n";

    ## Nope, internal limitation of overload
    print eval("6*9"), "\n";

    ## etc..

Apart from that, this code is completely free of bugs, in much the same way
that Minnesota in August is not.

=head1 SEE ALSO

I<The Hitchhiker's Guide to the Galaxy> and 
I<The Restaurant at the End of the Universe> by Douglas Adams.

=head1 AUTHOR

Acme::LifeUniverseEverything written by Mike Rosulek E<lt>mike@mikero.comE<gt>.

=head1 COPYRIGHT
  
Copyright (c) 2003 Mike Rosulek. All rights reserved. This module is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

