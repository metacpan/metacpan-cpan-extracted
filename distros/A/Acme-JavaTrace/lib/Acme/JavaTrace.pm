package Acme::JavaTrace;
use strict;

{
    no strict;
    $VERSION = '0.08';
}

# Install warn() and die() substitutes
$SIG{'__WARN__'} = \&_do_warn;
$SIG{'__DIE__' } = \&_do_die;

my $stderr = '';
my $in_eval = 0;
my %options = (
    showrefs => 0, 
);


# 
# import()
# ------
sub import {
    my $class = shift;
    
    for my $opt (@_) {
        exists $options{$opt} ? $options{$opt} = not $options{$opt}
                              : CORE::warn "warning: Unknown option: $opt\n"
    }
}


# 
# _use_data_dumper()
# ----------------
sub _use_data_dumper {
    require Data::Dumper;
    import Data::Dumper;
    $Data::Dumper::Indent = 1;      # no fancy indent
    $Data::Dumper::Terse  = 1;      # don't use $VAR unless needed
    $Data::Dumper::Sortkeys = 1;    # sort keys
    #$Data::Dumper::Deparse = 1;     # deparse code refs
    {
        local $^W = 0; 
        *Devel::SimpleTrace::_use_data_dumper = sub {};
    }
}


# 
# _do_warn()
# --------
sub _do_warn {
    local $SIG{'__WARN__'} = 'DEFAULT';
    
    my $msg = join '', @_;
    $msg =~ s/ at (.+?) line (\d+)\.$//;
    $stderr .= $msg;
    $stderr .= "\n" if substr($msg, -1, 1) ne "\n";
    
    _stack_trace($1, $2);
    
    print STDERR $stderr;
    $stderr = '';
    $in_eval = 0;
}


# 
# _do_die()
# -------
sub _do_die {
    local $SIG{'__WARN__'} = 'DEFAULT';
    local $SIG{'__DIE__' } = 'DEFAULT';
    
    CORE::die @_ if ref $_[0] and not $options{showrefs};
    CORE::die @_ if index($_[0], "\n\tat ") >= 0;
    my @args = @_;
    
    _use_data_dumper() if ref $args[0];
    my $msg = join '', map { ref $_ ? "Caught exception object: $_\: ".Dumper($_) : $_ } @args;
    $msg =~ s/ at (.+?) line (\d+)\.$//;
    $stderr .= $msg;
    $stderr .= "\n" if substr($msg, -1, 1) ne "\n";
    
    _stack_trace($1, $2);
    
    if($in_eval) {
        $@ = $stderr;
        $stderr = '';
        $in_eval = 0;
        CORE::die $@
        
    } else {
        print STDERR $stderr;
        $stderr = '';
        exit -1
    }
}


# 
# _stack_trace()
# ------------
sub _stack_trace {
    my($file,$line) = @_;
    $file ||= '';  $line ||= '';
    $file =~ '(eval \d+)' and $file = '<eval>';
    
    my $level = 2;
    my @stack = ( ['', $file, $line] );  # @stack = ( [ function, file, line ], ... )
    
    while(my @context = caller($level++)) {
        $context[1] ||= '';  $context[2] ||= '';
        $context[1] =~ '(eval \d+)' and $context[1] = '<eval>' and $in_eval = 1;
        $context[3] eq '(eval)' and $context[3] = '<eval>' and $in_eval = 1;
        $stack[-1][0] = $context[3];
        push @stack, [ '', @context[1, 2] ];
    }
    $stack[-1][0] = (caller($level-2))[0].'::' || 'main::';
    
    for my $func (@stack) {
        $$func[1] eq '' and $$func[1] = 'unknown source';
        $$func[2] and $$func[1] .= ':';
        $stderr .= "\tat $$func[0]($$func[1]$$func[2])\n";
    }
}


1;

__END__

=head1 NAME

Acme::JavaTrace - Module for using Java-like stack traces

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

On the command-line:

    perl -wMAcme::JavaTrace program_with_strange_errors.pl

Inside a module:

    use Acme::JavaTrace;
    warn "some kind of non-fatal exception occured";
    die "some kind of fatal exception occured";


=head1 DESCRIPTION

C<< <buzzword> >>This module tries to improves the Perl programmer 
experience by porting the Java paradigm to print stack traces, which 
is more professional than Perl's way. C<< </buzzword> >>

This is achieved by modifying the functions C<warn()> and C<die()> 
in order to replace the standard messages by complete stack traces 
that precisely indicates how and where the error or warning occurred. 
Other than this, their use should stay unchanged, even when using 
C<die()> inside C<eval()>. 

For a explanation of why I wrote this module, you can read the slides 
of my lightning talk I<Entreprise Perl>, available here: 
L<http://maddingue.org/conferences/yapc-eu-2004/entreprise-perl/>


=head1 OPTIONS

Options can be set at import time using: 

    perl -wMDevel::SimpleTrace=option1,option2

or 

    use Devel::SimpleTrace qw(option1 option2);

Available options are: 

=over 4

=item C<showrefs>

Using this option will tell C<Devel::SimpleTrace> to stringify objects and 
references passed in argument to C<die()>. This option is disabled by default 
in order to leave objects and references untouched. 

=back


=head1 EXAMPLE

Here is an example of stack trace produced by C<Acme::JavaTrace> 
using a fictional Perl program: 

    Exception: event not implemented
            at MyEvents::generic_event_handler(workshop/events.pl:26)
            at MyEvents::__ANON__(workshop/events.pl:11)
            at MyEvents::dispatch_event(workshop/events.pl:22)
            at MyEvents::call_event(workshop/events.pl:17)
            at main::(workshop/events.pl:30)

Please note that even the professionnal indentation present in the 
Java environment is included in the trace. 


=head1 DIAGNOSTICS

=over 4

=item Unknown option: %s

B<(W)> This warning occurs if you try to set an unknown option. 

=back


=head1 CAVEATS

This module is currently not compatible with other modules that also 
work by overriding C<die()> and C<warn()>, like C<CGI::Carp>. 


=head1 BLAME

Java, for its unhelpful kilometre-long stack traces. 


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-Acme-JavaTrace@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-JavaTrace>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Acme::JavaTrace is Copyright (C)2004-2011 SE<eacute>bastien Aperghis-Tramoni.

This program is free software. You can redistribute it and/or modify it 
under the same terms as Perl itself. 

=cut
