#!/usr/bin/perl

use strict;
use Data::Dumper;

use vars qw($skip_all);
return if ( $skip_all );

BEGIN {
    eval "use Tangram::Relational";

    if ( my $error = $@ ) {
	print "Skippity do dah\n";
	eval 'use Test::More skip_all => $error." loading Tangram"';
	$skip_all = 1;
    } else {
	print "Testy do yay\n";
	eval 'use Test::More tests => 5';
    }
}

package Meme;
eval "use base qw(Class::Tangram)";
main::is($@, "", "use base qw(Class::Tangram)");
use vars qw($schema);
$schema = { fields =>
	    { transient =>
	      { 'closure' =>
		{ check_func => sub {
		      ref ${ (shift) } eq "CODE"
			  or die "closure not a code reference";
		  }
		}
	      },
	      string =>
	      { 'waveform' => { check_func => sub { } }
	      },
	    },
	  };

package Capture;

use base qw(Class::Tangram);
use vars qw($schema);

$schema = { fields => { perl_dump => [ qw(stdout)]  } };

sub capture_print {
    my $self = shift;
    #open STDCAPTURE, ">/dev/null" or die $!;
    $self->{so} = tie(*STDOUT, 'Capture', \$self->{stdout})
	or die "failed to tie STDOUT; $!";

    #select STDCAPTURE;
}

sub release_stdout {
    my $self = shift;
    delete $self->{so};
    untie(*STDOUT);
}

sub TIEHANDLE {
    my $class = shift;
    my $ref = shift;
    return bless({ stdout => $ref }, $class);
}

sub PRINT {
    my $self = shift;
    ${${$self->{stdout}}} .= join('', map { defined $_?$_:""} @_); 
}

sub PRINTF {
    my ($self) = shift;
    my ($fmt) = shift;
    ${${$self->{stdout}}} .= sprintf($fmt, @_)
	if (@_);
}


sub glob {
    return \*STDOUT;
}

package main;

use_ok("Tangram");

eval { Class::Tangram::import_schema("Meme") };

main::is($@, "", 'Class::Tangram::import_schema("Meme")');

my $schema =
    Tangram::Relational->schema
    (
     { classes =>
       [ Meme => $Meme::schema ]
     }
    );

my $output;
my $tty = Capture->new(stdout => \$output);

$tty->capture_print;

Tangram::Relational->deploy($schema, \*STDOUT);

$tty->release_stdout;

like($output, qr/waveform.*varchar/i,
     "Tangram::Transient doesn't break Tangram::Relational->deploy");

ok($output !~ m/closure/,
   "Tangram::Transient doesn't show up in "
   ."Tangram::Relational->deploy");
