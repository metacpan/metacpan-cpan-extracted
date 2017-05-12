#!/usr/bin/perl

use strict;
use warnings;

package App::Module::Setup::Templates;

our $VERSION = "0.02";

sub templater {
    my ( $text, $vars ) = @_;

    my %warned;
    my $repl = sub {
	my ( $key, $def ) = @_;
	unless ( defined $vars->{$key} ) {
	    warn( "Template ", $vars->{" file"},
		  ": No replacement text for $key\n" )
	      unless $warned{$vars->{" file"} . $key}++;
	    return $def;
	}
	$vars->{$key};
    };

    $text =~ s/(\[\%\s*(.*?)\s*\%\])/$repl->($2, $1)/ge;

    $text;
}

1;
