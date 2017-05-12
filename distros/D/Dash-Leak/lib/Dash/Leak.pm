package Dash::Leak;

use 5.008008;
use strict;
use warnings;

=head1 NAME

Dash::Leak - Track memory allocation

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Quick summary of what the module does.


    BEGIN {
        # enables operation of Dash::Leak, leaksz is a nop without this
        $ENV{DEBUG_MEM} = 1;
    }

    use Dash::Leak;
    
    {
        leaksz "block label";
        # some code, that may leak
    }
    # If your code leaked, you'll be noticed about change
    # of process vsize after leaving block
    
    leaksz "tests begin";
    some_operation($arg);
    leaksz "some_operation", sub {
        warn sprintf "We leaked after some_operation($arg) by %+d kilobytes;", shift
    };
    another_operation();
    leaksz "another_operation";
    # ...

    use Dash::Leak sub { ... }; # Will call this cb for every alloc, instead of warn

=head1 EXPORT

Export of this module is "virtual", by using L<Devel::Declare>.
When C<$ENV{DEBUG_MEM}> is true, it will work, when false, this opcodes will be ignored, like with C<leaksz ... if 0>;

=head1 FUNCTIONS

=head2 leaksz $label, [$cb->($delta)]

Starts tracking current block.
If something changed since last note, notice will be warned.
If callback is passed, it will be invoked instead of warn.

=cut

use Devel::Declare ();
use Guard;

sub sz();

BEGIN {
	if ($^O eq 'freebsd') {
		require BSD::Process;
		*sz = sub () { BSD::Process->new->{size} };
	}
	elsif ($^O eq 'linux') {
		require Proc::ProcessTable;
		*sz = sub () { (map { $_->{size} } grep { $_->{pid} == $$ } @{Proc::ProcessTable->new->table})[0] };
	} else {
		require Win32::Process::Info;
		Win32::Process::Info->import( 'WMI' );

		my $pi = Win32::Process::Info->new;
		$pi->Set( elapsed_in_seconds => 0 );

		*sz = sub () { $pi->GetProcInfo( { no_user_info => 1 }, $$ )->[0]->{PrivatePageCount} };
	}
}

our $cmem = 0;
our $SUBNAME = 'leaksz';
our $idx;
our $OUT = 0;

BEGIN {
	if ($ENV{DEBUG_MEM}) {
		my $debug = $ENV{DEBUG_MEM};
		*DEBUG = sub () { $debug };
	} else {
		*DEBUG = sub () { 0 };
	}
}

our $FIRST;
our %CBS;
sub import{
	my $class = shift;
	my $caller = caller;
	my $cb = shift if @_;
	check("use $class from @{[ (caller)[1,2] ]}",$cb ? $cb : ()) if DEBUG;
	if (DEBUG and $cb) {
		$FIRST ||= $cb;
		$CBS{$caller} = $cb;
	}
	Devel::Declare->setup_for(
		$caller,
		{ $SUBNAME => { const => \&parse } }
	);
	{
		no strict 'refs';
		*{$caller.'::'.$SUBNAME } = sub() { DEBUG };
	}
}

sub check(@) {
	use integer;
	my $cb;
	$cb = pop if @_ > 1 and UNIVERSAL::isa( $_[-1], 'CODE' );
	my $op = "@_";
	my $mem = sz / 1024;
	my $delta = $mem - $cmem;
	if ($delta != 0) {
		$cmem = $mem;
		if ($cb) {
			$cb->($delta,$OUT ? 'out' : 'in' ,$op);
		} else {
			my ($caller,$file,$line) = (caller($OUT))[0..2];
			if (exists $CBS{$caller}) {
				$CBS{$caller}->($delta, $OUT ? 'out' : 'in' ,$op);
			} else {
				warn sprintf "%s %s: %+dk at %s line %s\n",($OUT ? '<-' : '->'),$op,$delta,$file,$line;
			}
		}
	}
	return 1 if $OUT;
	return guard {
		local $OUT = 1;
		check($op,$cb ? $cb : ());
	};
}


sub parse {
	my $offset = $_[1];
	$offset += Devel::Declare::toke_move_past_token($offset);
	my $linestr = Devel::Declare::get_linestr();
	substr($linestr,$offset,0) = 'and my $__leaksz_'.++$idx.'__ = '.__PACKAGE__.'::check';
	Devel::Declare::set_linestr($linestr);
	return;
}

END {
	DEBUG and check("Finishing", $FIRST ? $FIRST : ());
}

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Thanks to knevgen (L<http://github.com/knevgen>) for linux version patch

=back

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Dash::Leak
