package Acme::LSD;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use base qw<Tie::Handle>;
use Symbol qw<geniosym>;

sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub PRINT {
    shift;

    foreach my $str (@_) {
        my $copy = $str;
        $copy =~ s/[^\w']/ /g;   # convert all non-words into spaces
        $copy =~ s/ +/ /g;       # convert all multiple spaces into single space
        $copy =~ tr/A-Z/a-z/;    # convert all words to lowercase
        foreach my $char (split("", $copy)) {
            my $r = int(rand(6)) + 31;
            my $s = int(rand(8));
	    print TRUE_STDOUT "\033[" . "$s;$r" . "m$char\033[0m";
        }
    }	
}

open(TRUE_STDOUT, '>', '/dev/stdout');
tie *STDOUT, __PACKAGE__, (*STDOUT);

1;
__END__

=encoding utf-8

=head1 NAME

Acme::LSD - A dumb module that colorize your prints

=head1 SYNOPSIS

    use Acme::LSD;

    # That's all ! 
    # (You will see the effect as soon as you print something...)
    # e.g. 
    print("Survive just one more day\n");

=head1 DESCRIPTION

Acme::LSD is a module that overrides the CORE::GLOBAL::print function.

=head1 LICENSE

Copyright (C) Thibault DUPONCHELLE.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Thibault DUPONCHELLE E<lt>thibault.duponchelle@gmail.comE<gt>

=cut

