package Acme::Ook;

use strict;
use vars qw($VERSION);
$VERSION = '0.11';

my %Ook = (
	   '.' => {'?'	=> '$Ook++;',
		   '.'	=> '$Ook[$Ook]++;',
		   '!'	=> '$Ook[$Ook]=read(STDIN,$Ook[$Ook],1)?ord$Ook[$Ook]:0;'},
	   '?' => {'.'	=> '$Ook--;',
		   '!'	=> '}'},
	   '!' => {'!'	=> '$Ook[$Ook]--;',
		   '.'	=> 'print chr$Ook[$Ook];',
		   '?'	=> 'while($Ook[$Ook]){',
		   }
	    );

BEGIN {
    no strict 'refs';
    *{'O?'} = sub { @_ ? $Ook{$_[0]} : %Ook };
    *{'O!'} = sub { $Ook{$_[0]} = $_[1] };
}

sub optimise {
    # Coalesce sequences of increments or decrements
    my $prog = $_[1];
    # print "Before '$prog'\n";
    foreach my $thing ('$Ook', '$Ook[$Ook]') {
	foreach my $op ('+', '-') {
	    my $left = length "$thing$op$op;";
	    $prog =~ s{((?:\Q$thing$op$op\E;){2,})}
	      {"$thing$op=".(length ($1)/$left).';'}ges;
	}
    }
    # print "After '$prog'\n";
    return $prog;
}

sub _compile {
    shift;
    chomp $_[0];
    $_[0] =~ s/\s*(Ook(.)\s*Ook(.)\s*|(\#.*)|\S.*)/$;=$Ook{$2||@@}{$3||''};$;?$;:defined$4?"$4\n":die"OOK? $_[1]:$_[2] '$1'\n"/eg;
    return $_[0];
}

sub compile {
    my $self = shift;
    my $prog;
    $prog .= $self->_compile($$self, "(new)", 0) if defined $$self && length $$self;
    if (@_) {
	local *OOK;
	while (@_) {
	    my $code = shift;
	    if (ref $code eq 'IO::Handle') {
		while (<$code>) {
		    $prog .= $self->_compile($_, $code, $.);
		}
		close(OOK);
	    } else {
		if (open(OOK, $code)) {
		    while (<OOK>) {
			$prog .= $self->_compile($_, $code, $.);
		    }
		    close(OOK);
		} else {
		    die "OOK! $code: $!\n";
		}
	    }
	}
    } else {
	while (<STDIN>) {
	    $prog .= $self->_compile($_, "(stdin)", $.);
	}
    }
    return '{my($Ook,@Ook);local$^W = 0;BEGIN{eval{require bytes;bytes::import()}}' . $prog . '}';
}

sub Ook {
    eval $_[0]->optimise(&compile);
}

sub new {
    my $class = shift;
    bless \$_[0], ref $class || $class;
}

1;
__END__
=pod

=head1 NAME

Acme::Ook - the Ook! programming language

=head1 SYNOPSIS

    ook ook.ook

or

    use Acme::Ook;
    my $Ook = Acme::Ook->new;
    $Ook->Ook($Ook);

=head1 DESCRIPTION

As described in http://www.dangermouse.net/esoteric/ook.html

    Since the word "ook" can convey entire ideas, emotions, and
    abstract thoughts depending on the nuances of inflection, Ook!
    has no need of comments. The code itself serves perfectly well to
    describe in detail what it does and how it does it. Provided you
    are an orang-utan.

Here's for example how to print a file in reverse order:

    Ook. Ook. Ook! Ook? Ook. Ook? Ook. Ook! Ook? Ook!
    Ook? Ook. Ook! Ook! Ook! Ook? Ook. Ook. Ook! Ook.
    Ook? Ook. Ook! Ook! Ook? Ook!

The language specification can be found from the above URL.

Despite the above, the interpreter does understand comments,
the #-until-end-of-line kind.

=head1 MODULE

The Acme::Ook is the backend for the Ook interpreter.

=head2 Methods

=over 4

=item new

The constructor.  One optional argument, a string of Ook! that will
be executed before any code supplied in Ook().

=item Ook

The interpreter.  Compiles, optimises and executes the Ook! code.  Takes
one or more arguments, either filenames or IO globs, or no arguments, in
which case the stdin is read.

=item compile

The compiler.  Takes the same arguments as Ook().  Normally not used
directly but instead via Ook() that also executes the code.  Returns
the intermediate code.

=item optimise

The optimiser.  Takes the intermediate code from the compiler and
optimises it slightly. Currently it creates better code for runs of
repeated increment or decrement.

=back

=head1 INTERPRETER

The interpreter is the frontend to the Acme::Ook module.  It is used
as one would imagine: given one (or more) Ook! input files (or none,
in which case stdin is expected to contain Ook!), the interpreter
compiles and executes the Ook.

=head2 Command Line Options

There are three command line options:

=over 4

=item -l

Some example programs look better if an extra newline is shown
after the execution.

=item -O

Use the optimiser on the intermediate code.

=item -S

If you want to see the intermediate code.

=back

=head2 BLACK MAGIC

To re-ook the Ook you can use the C<O?> and C<O!> class methods.
Not that you should.

=head1 DIAGNOSTICS

If your code doesn't look like proper Ook!, the interpreter will
make its confusion known, similarly if an input file cannot be read.

=head1 AUTHOR, COPYRIGHT, LICENSE

Jarkko Hietaniemi <jhi@iki.fi>

Copyright (C) 2002,2006 Jarkko Hietaniemi 

This is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

The sample programs (the ook/ subdirectory) are Copyright (C) 2002
Lawrence Pit (BlueSorcerer) from http://bluesorcerer.net/esoteric/ook.html
except for the bananas, coffee, and ok.ook, which are
Copyright (C) 2002 Nicholas Clark.

=head1 DISCLAIMER

I never called anyone a monkey.  Honest.

=cut
