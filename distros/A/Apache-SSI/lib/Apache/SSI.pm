package Apache::SSI;

use strict;
use vars qw($VERSION);
use Apache::Constants qw(:common :http OPT_INCNOEXEC);
use File::Basename;
use HTML::SimpleParse;
use Symbol;
use POSIX;

$VERSION = '2.19';
my $debug = 0;


sub handler($$) {
    my ($pack, $r) = @_>1 ? @_ : (__PACKAGE__, shift());
    
    my $fh;
    if (lc($r->dir_config('Filter')) eq 'on') {
        $r = $r->filter_register;
        my ($status);
        ($fh, $status) = $r->filter_input();
        return $status unless $status == OK;
        
    } else {
        my $file = $r->filename;

        unless (-e $file) {
	#unless (-e $r->finfo) {
            $r->log_error("$file not found");
            return NOT_FOUND;
        }

        $fh = gensym;
        unless (open *{$fh}, $file) {
            $r->log_error("$file: $!");
            return FORBIDDEN;
        }
    }
    $r->send_http_header;
    return OK if $r->header_only;
    
    do {local $/=undef; $pack->new( scalar(<$fh>), $r )}->output;
    return OK;
}

sub new {
  my ($pack, $text, $r) = @_;
  $pack = ref($pack) if ref($pack);
  
  return bless 
    {
     'text' => $text,
     '_r'   => $r,
     'suspend' => [0],
     'if_state' => [1], # A stack reflecting the current state of if/else parser.
                        # Each entry is 1 when we've seen a true condition in this if-chain,
                        # 0 when we haven't.  Initially it's as if we're in a big true 
                        # if-block with no else.
     'errmsg'  => "[an error occurred while processing this directive]",
     'sizefmt' => 'abbrev',
     'timefmt' => undef, # undef means the current locale's default
    }, $pack;
}

sub text {
    my $self = shift;
    if (@_) {
        $self->{'text'} = shift;
    }
    return $self->{'text'};
}

sub get_output {
    my $self = shift;
    
    my $out = '';
    my $ssi;
    my @parts = split m/(<!--#.*?-->)/s, $self->{'text'};
    while (@parts) {
        $out .= ('', shift @parts)[1-$self->{'suspend'}[0]];
        last unless @parts;
        $ssi = shift @parts;
        # There's some weird 'uninitialized' warning on the next line, but I can't find it.
        if ($ssi =~ m/^<!--#(.*)-->$/s) {
            $out .= $self->output_ssi($1);
        } else { die 'Parse error' }
    }
    return $out;
}


sub output {
    my $self = shift;
    
    my @parts = split m/(<!--#.*?-->)/s, $self->{'text'};
    while (@parts) {
        $self->{_r}->print( ('', shift @parts)[1-$self->{'suspend'}[0]] );
        last unless @parts;
        my $ssi = shift @parts;
        if ($ssi =~ m/^<!--#(.*)-->$/s) {
            $self->{_r}->print( $self->output_ssi($1) );
        } else { die 'Parse error' }
    }
}

sub output_ssi {
    my ($self, $text) = @_;
    
    if ($text =~ s/^(\w+)\s*//) {
        my $tag = $1;
        return if ($self->{'suspend'}[0] and not $tag =~ /^(if|elif|else|endif)/);
        my $method = lc "ssi_$tag";

	local $HTML::SimpleParse::FIX_CASE = -1;
        my $args = [ HTML::SimpleParse->parse_args($text) ];
        return $self->$method( {@$args}, $args );
    }
    return '';
}

sub ssi_if {
    my ($self, $args) = @_;
    unshift @{$self->{if_state}}, 0;
    unshift @{$self->{suspend}},  $self->{suspend}[0];
    return '' if $self->{suspend}[0];
    return $self->_handle_ifs( $self->_eval_vars($args->{'expr'}) );
}

sub ssi_elif {
    my ($self, $args) = @_;
    # Make sure we're in an 'if' chain
    return $self->error("Malformed if..endif SSI structure") unless @{$self->{if_state}} > 1;
    return '' if $self->{suspend}[1];
    return $self->_handle_ifs( $self->_eval_vars($args->{'expr'}) );
}

sub ssi_else {
    my $self = shift;
    # Make sure we're in an 'if' chain
    return $self->error("Malformed if..endif SSI structure") unless @{$self->{if_state}} > 1;
    return '' if $self->{suspend}[1];
    return $self->_handle_ifs(1);
}

sub ssi_endif {
    my $self = shift;
    # Make sure we're in an 'if' chain
    return $self->error("Malformed if..endif SSI structure") unless @{$self->{if_state}} > 1;
    shift @{$self->{if_state}};
    shift @{$self->{suspend}};
    return '';
}

sub _handle_ifs {
    my $self = shift;
    my $cond = shift;
    
    if ($self->{if_state}[0]) {
        $self->{suspend}[0] = 1;
    } else {
        $self->{suspend}[0] = !($self->{if_state}[0] = !!$cond);
    }
    return '';
}


sub ssi_include {
  my ($self, $args) = @_;
  unless (exists $args->{file} or exists $args->{virtual}) {
    return $self->error("No 'file' or 'virtual' attribute found in SSI 'include' tag");
  }
  my $subr = $self->find_file($args);

  # Subrequests can fuck up %ENV, make sure it's restored upon exit.
  # Unfortunately 'local(%ENV)=%ENV' reportedly causes segfaults.
  my %save_ENV = %ENV;

  if ( $subr->status == HTTP_OK ) {
    $subr->run == OK
      or $self->error("Include of '@{[$subr->filename()]}' failed: $!");
  }
  
  %ENV = %save_ENV;

  return '';
}

sub ssi_fsize { 
    my ($self, $args) = @_;
    my $size = -s $self->find_file($args)->filename();
    if ($self->{'sizefmt'} eq 'bytes') {
        return $size;
    } elsif ($self->{'sizefmt'} eq 'abbrev') {
        return "   0k" unless $size;
        return "   1k" if $size < 1024;
        return sprintf("%4dk", ($size + 512)/1024) if $size < 1048576;
        return sprintf("%4.1fM", $size/1048576.0)  if $size < 103809024;
        return sprintf("%4dM", ($size + 524288)/1048576);
    } else {
        $self->error("Unrecognized size format '$self->{'sizefmt'}'");
        return '';
    }
}

sub ssi_flastmod {
    my($self, $args) = @_;
    return $self->_lastmod( $self->find_file($args)->filename(), $args->{'timefmt'} || $self->{'timefmt'} );
}

sub find_file {
    my ($self, $args) = @_;
    my $req;
    if (exists $args->{'file'}) {
        $self->_interp_vars($args->{'file'});
        $req = $self->{_r}->lookup_file($args->{'file'});
    } elsif (exists $args->{'virtual'}) {
        $self->_interp_vars($args->{'virtual'});
        $req = $self->{_r}->lookup_uri($args->{'virtual'});
    } else {
        $req = $self->{_r};
    }
    return $req;
}

sub ssi_printenv() {
    return join "", map( {"$_: $ENV{$_}<br>\n"} keys %ENV );
}

sub ssi_exec {
    my($self, $args) = @_;
    #XXX did we check enough?
    my $r = $self->{_r};
    my $filename = $r->filename;

    if ($r->allow_options & OPT_INCNOEXEC) {
        $self->error("httpd: exec used but not allowed in $filename");
        return "";
    }
    return scalar `$args->{cmd}` if exists $args->{cmd};
    
    unless (exists $args->{cgi}) {
        $self->error("No 'cmd' or 'cgi' argument given to #exec");
        return '';
    }

    # Okay, we're doing <!--#exec cgi=...>
    my $rr = $r->lookup_uri($args->{cgi});
    unless ($rr->status == 200) {
        $self->error("Error including cgi: subrequest returned status '" . $rr->status . "', not 200");
        return '';
    }
    
    # Pass through our own path_info and query_string (does this work?)
    $rr->path_info( $r->path_info );
    $rr->args( scalar $r->args );
    $rr->content_type("application/x-httpd-cgi");
    &_set_VAR($rr, 'DOCUMENT_URI', $r->uri);
    
    my $status = $rr->run;
    return '';
}

sub ssi_perl {
    my($self, $args, $margs) = @_;

    my ($pass_r, @arg1, @arg2, $sub) = (1);
    {
        my @a;
        while (@a = splice(@$margs, 0, 2)) {
            $a[1] =~ s/\\(.)/$1/gs;
            if (lc $a[0] eq 'sub') {
                $sub = $a[1];
            } elsif (lc $a[0] eq 'arg') {
                push @arg1, $a[1];
            } elsif (lc $a[0] eq 'args') {
                push @arg1, split(/,/, $a[1]);
            } elsif (lc $a[0] eq 'pass_request') {
                $pass_r = 0 if lc $a[1] eq 'no';
            } elsif ($a[0] =~ s/^-//) {
                push @arg2, @a;
            } else { # Any unknown get passed as key-value pairs
                push @arg2, @a;
            }
        }
    }

    warn "sub is $sub, args are @arg1 & @arg2" if $debug;
    my $subref;
    if ( $sub =~ /^\s*sub\s/ ) {     # for <!--#perl sub="sub {print ++$Access::Cnt }" -->
        $subref = eval($sub);
        if ($@) {
            $self->error("Perl eval of '$sub' failed: $@") if $self->{_r};
            warn("Perl eval of '$sub' failed: $@") unless $self->{_r};  # For offline mode
        }
        return $self->error("sub=\"sub ...\" didn't return a reference") unless ref $subref;
    } else {             # for <!--#perl sub="package::subr" -->
        no strict('refs');
	$subref = (defined &{$sub} ? \&{$sub} :
		   defined &{"${sub}::handler"} ? \&{"${sub}::handler"} : 
		   \&{"main::$sub"});
    }
    
    $pass_r = 0 if $self->{_r} and lc $self->{_r}->dir_config('SSIPerlPass_Request') eq 'no';
    unshift @arg1, $self->{_r} if $pass_r;
    warn "sub is $subref, args are @arg1 & @arg2" if $debug;
    return scalar &{ $subref }(@arg1, @arg2);
}

sub ssi_set {
    my ($self, $args) = @_;
    
    $self->_interp_vars($args->{value});
    $self->{_r}->subprocess_env( $args->{var}, $args->{value} );
    return '';
}

sub ssi_config {
    my ($self, $args) = @_;
    
    $self->{'errmsg'}  =    $args->{'errmsg'}  if exists $args->{'errmsg'};
    $self->{'sizefmt'} = lc $args->{'sizefmt'} if exists $args->{'sizefmt'};
    $self->{'timefmt'} =    $args->{'timefmt'} if exists $args->{'timefmt'};
    return '';
}

sub ssi_echo {
    my($self, $args) = @_;
    my $var = $args->{var};
    $self->_interp_vars($var);
    my $value;
    no strict('refs');
    
    if (exists $ENV{$var}) {
        return $ENV{$var};
    } elsif ( defined ($value = $self->{_r}->subprocess_env($var)) ) {
        return $value;
    } elsif ($self->can(my $method = "echo_$var")) {
	return $self->$method($self->{_r});
    }
    return '';
}

sub echo_DATE_GMT   { shift()->_format_time(time(), undef, 'GMT') }
sub echo_DATE_LOCAL { shift()->_format_time(time()              ) }
sub echo_DOCUMENT_NAME {
    shift();
    my $r = _2main(shift);
    return &_set_VAR($r, 'DOCUMENT_NAME', basename $r->filename);
}
sub echo_DOCUMENT_URI {
    shift();
    my $r = _2main(shift);
    return &_set_VAR($r, 'DOCUMENT_URI', $r->uri);
}
sub echo_LAST_MODIFIED {
    my ($self, $r) = (shift(), _2main(shift));
    return &_set_VAR($r, 'LAST_MODIFIED', $self->_lastmod($r->filename));
}

sub _set_VAR {
    $_[0]->subprocess_env($_[1], $_[2]);
    return $_[2];
}

sub _eval_vars {
    my $self = shift;
    my $text = shift;
    $text =~ s{ (^|[^\\]) (\\\\)* \$(\{)?(\w+)(\})? }
              { $1 . substr($2,length($2)/2) . "\${ \\(\$self->ssi_echo({var=>'$4'})) }" }exg;
    #;  For poor BBEdit because of that last line
    package main; # In case they're running functions
    my $result = eval $text;
    $self->error("Eval error: $@") if $@;
    return $result;
}

sub _interp_vars {
    # Find all $var and ${var} expressions in the string and fill them in.
    my $self = shift;
    my ($a,$b,$c);  # Because ssi_echo may change $1, $2, ...
    $_[0] =~ s{ (^|[^\\]) (\\\\)* \$(\{)?(\w+)(\})? }
              { ($a,$b,$c) = ($1,$2,$4);
                $a . substr($b,length($b)/2) . $self->ssi_echo({var=>$c}) }exg;
}

# This might be better for _interp_vars:
#sub _interp_vars {
#    local $_ = shift;
#    my $out;
#
#    while (1) {
#
#        if ( /\G([^\\\$]+)/gc ) {
#            $out .= $1;
#            
#        } elsif ( /\G(\\\\)+/gc ) {
#            $out .= '\\' x (length($1)/2);
#            
#        } elsif ( /\G\\([^\$])/gc ) {
#            $out .= &escape_char($1);
#            
#        } elsif ( /\G\$(\w+)/gc ) {
#            $out .= &lookup($1);
#        
#        } elsif ( /\G\$\{(\w+)\}/gc ) {
#            $out .= &lookup($1);
#        
#        } else {
#            last;
#        }
#    }
#    $out;
#}

sub error {
    my $self = shift;
    print $self->{'errmsg'};
    $self->{_r}->log_error($_[0]) if @_ and $self->{_r};
    return '';
}


sub _2main { $_[0]->is_main() ? $_[0] : $_[0]->main() }

sub _format_time {
  my ($self, $time, $format, $tzone) = @_;
  $format ||= $self->{timefmt};
  return ($format ? 
	  POSIX::strftime($format, $self->_time_args($time, $tzone)) :
	  scalar $self->_time_args($time, $tzone));
}

sub _time_args {
  # This routine must respect the caller's wantarray() context.
  my ($self, $time, $zone) = @_;
  return ($zone && $zone =~ /GMT/) ? gmtime($time) : localtime($time);
}

sub _lastmod {
  my ($self, $file, $format) = @_;
  return $self->_format_time((stat $file)[9], $format);
}

1;

__END__

=head1 NAME

Apache::SSI - Implement Server Side Includes in Perl

=head1 SYNOPSIS

In httpd.conf:

    <Files *.phtml>  # or whatever
    SetHandler perl-script
    PerlHandler Apache::SSI
    </Files>

You may wish to subclass Apache::SSI for your own extensions.  If so,
compile mod_perl with PERL_METHOD_HANDLERS=1 (so you can use object-oriented
inheritance), and create a module like this:

    package MySSI;
    use Apache::SSI ();
    @ISA = qw(Apache::SSI);

    #embedded syntax:
    #<!--#something param=value -->
    sub ssi_something {
       my($self, $attr) = @_;
       my $cmd = $attr->{param};
       ...
       return $a_string;   
    }
 
 Then in httpd.conf:
 
    <Files *.phtml>
     SetHandler perl-script
     PerlHandler MySSI
    </Files>

=head1 DESCRIPTION

Apache::SSI implements the functionality of mod_include for handling
server-parsed html documents.  It runs under Apache's mod_perl.

In my mind, there are two main reasons you might want to use this module:
you can sub-class it to implement your own custom SSI directives, and/or you
can parse the output of other mod_perl handlers, or send the SSI output
through another handler (use Apache::Filter to do this).

Each SSI directive is handled by an Apache::SSI method with the prefix
"ssi_".  For example, <!--#printenv--> is handled by the ssi_printenv method.
attribute=value pairs inside the SSI tags are parsed and passed to the
method in a hash reference.

'Echo' directives are handled by the ssi_echo method, which delegates
lookup to methods with the prefix "echo_".  For instance, <!--#echo
var=DOCUMENT_NAME--> is handled by the echo_DOCUMENT_NAME method.

You can customize behavior by inheriting from Apache::SSI and
overriding 'ssi_*' and 'echo_*' methods, or writing new ones.

=head2 SSI Directives

This module supports the same directives as mod_include.  At least, that's
the goal. =)  For methods listed below but not documented, please see
mod_include's online documentation at http://www.apache.org/ .

=over 4

=item * config

=item * echo

=item * exec

=item * fsize

=item * flastmod

=item * include

=item * printenv

=item * set

=item * perl

There are two ways to call a Perl function, and two ways to supply it with
arguments.  The function can be specified either as an anonymous subroutine
reference, or as the name of a function defined elsewhere:

 <!--#perl sub="sub { localtime() }"-->
 <!--#perl sub="time::now"-->

If the 'sub' argument matches the regular expression /^\s*sub[^\w:]/,
it is assumed to be a subroutine reference.  Otherwise it's assumed to
be the name of a function.  In the latter case, the string "main::"
will be prepended to the function name if the name doesn't contain
"::" (this forces the function to be in the main package, or a package
you specify).  Note that it's a pretty bad idea to put your code in
the main package, so I only halfheartedly endorse this feature.

In general, it will be slower to use anonymous subroutines, because
each one has to be eval()'ed and there is no caching.  For best
results, pre-load any code you need in the parent process, then call
it by name.

If you're calling a subroutine like "&Package::SubPack::handler", you
can omit the "handler" portion, making your directive like this:

 <!--#perl sub="Package::Subpack"-->

If you want to supply a list of arguments to the function, you use either
the "arg" or the "args" parameter:

 <!--#perl sub="sub {$_[0] * 7}" arg=7-->
 <!--#perl sub=holy::matrimony arg=Hi arg=Lois-->
 <!--#perl sub=holy::matrimony args=Hi,Lois-->

The "args" parameter will simply split on commas, meaning that currently
there's no way to embed a comma in arguments passed via the "args"
parameter.  Use the "arg" parameter for this.

If you give a key-value pair and the key is not 'sub', 'arg', 'args', or 
'pass_request' (see below), then your routine will be passed B<both> the 
key and the value.  This lets you pass a hash of key-value pairs to your 
function:

 <!--#perl sub=holy::matrimony groom=Hi bride=Lois-->
 Will call &holy::matrimony('groom', 'Hi', 'bride', 'Lois');

As of version 1.95, we pass the current Apache request object ($r) as the
first argument to the function.  To turn off this behavior, give the key-value
pair 'pass_request=no', or put 'PerlSetVar SSIPerlPass_Request no' in your
server's config file.

See C<http://perl.apache.org/src/mod_perl.html> for more information on Perl
SSI calls.

=item * if

=item * elif

=item * else

=item * endif

These four directives can be used just like in C<mod_include>, with one important
difference: the boolean expression is evaluated using Perl's eval().  This means
you use C<==> or C<eq> instead of C<=> to test equality.  It also means you can use
pre-loaded Perl subroutines in the conditions:

 <!--#if expr="&Movies::is_by_Coen_Brothers($MOVIE)"-->
  This movie is by the Coen Brothers.
 <!--#else-->
  This movie is not by the Coen Brothers.
 <!--#endif-->

It can't handle very sophistocated Perl though, because it manually looks for
variables (of the form $var or ${var}, just like C<mod_include>), and will get tripped 
up on expressions like $object->method or $hash{'key'}.  I'll welcome any suggestions
for how to allow arbitrary Perl expressions while still filling in Apache variables.

=back

=head1 CHAINING HANDLERS

There are two fairly simple ways for this module to exist in a stacked handler
chain.  The first uses C<Apache::Filter>, and your httpd.conf would look something
like this:

 PerlModule Apache::Filter
 PerlModule Apache::SSI
 PerlModule My::BeforeSSI
 PerlModule My::AfterSSI
 <Files ~ "\.ssi$">
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler My::BeforeSSI Apache::SSI My::AfterSSI
 </Files>

The C<"PerlSetVar Filter On"> directive tells the three stacked handlers that
they should use their filtering mode.  It's mandatory.

The second uses C<Apache::OutputChain>, and your httpd.conf would look something
like this:

 PerlModule Apache::OutputChain
 PerlModule Apache::SSIChain
 PerlModule My::BeforeSSI
 PerlModule My::AfterSSI
 <Files ~ "\.ssi$">
  SetHandler perl-script
  PerlHandler Apache::OutputChain My::AfterSSI Apache::SSIChain My::BeforeSSI
 </Files>

Note that the order of handlers is reversed in the two different methods.  One 
reason I wrote C<Apache::Filter> is to get the order to be more intuitive.  
Another reason is that C<Apache::SSI> itself can be used in a handler stack using
C<Apache::Filter>, whereas it needs to be wrapped in C<Apache::SSIChain> to 
be used with C<Apache::OutputChain>.

Please see the documentation for C<Apache::OutputChain> and C<Apache::Filter>
for more specific information.  And look at the note in CAVEATS too.
 

=head1 CAVEATS

* When chaining handlers via Apache::Filter, if you use <!--#include ...-->
or <!--#exec cgi=...-->, then Apache::SSI must be the last filter in the
chain.  This is because Apache::SSI uses $r->lookup_uri(...)->run to include
the files, and this sends the output through C's stdout rather than Perl's
STDOUT.  Thus Apache::Filter can't catch it and filter it.

If Apache::SSI is the last filter in the chain, or if you stick to simpler SSI
directives like <!--#fsize-->, <!--#flastmod-->, etc. you'll be fine.

* Currently, the way <!--#echo var=whatever--> looks for variables is
to first try $r->subprocess_env, then try %ENV, then the five extra environment
variables mod_include supplies.  Is this the correct order?

=head1 TO DO

Revisit http://www.apache.org/docs/mod/mod_include.html and see what else
there I can implement.

It would be nice to have a "PerlSetVar ASSI_Subrequests 0|1" option that
would let you choose between executing a full-blown subrequest when
including a file, or just opening it and printing it.

I'd like to know how to use Apache::test for the real.t test.

=head1 SEE ALSO

mod_include, mod_perl(3), Apache(3), HTML::Embperl(3), Apache::ePerl(3),
Apache::OutputChain(3)

=head1 AUTHOR

Ken Williams ken@mathforum.org

Concept based on original version by Doug MacEachern dougm@osf.org .
Implementation different.

=head1 COPYRIGHT

Copyright 1998 Swarthmore College.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut
