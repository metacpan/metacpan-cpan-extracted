package Apache::Handlers;

# $Id: Handlers.pm,v 1.2 2002/01/07 15:28:35 jgsmith Exp $

use strict;
use Carp;
use Apache::Constants qw(OK SERVER_ERROR DECLINED);
use Perl::WhichPhase qw: in_BEGIN :;
use vars qw:$VERSION @EXPORT_OK @ISA:;

my $has_mod_perl = defined $INC{'Apache'};

eval {
  use Apache::Log ();
  Apache::ModuleConfig -> has_srv_config;
} if $has_mod_perl;

$VERSION = "0.02";
@ISA = qw!Exporter!;

my %code = ( );

sub dump {
  eval {
    use Data::Dumper;
    return Data::Dumper -> Dump([\%code]);
  };
}

my %phases = qw:
  CHILDINIT       PerlChildInitHandler
  POSTREADREQUEST PerlPostReadRequestHandler
  CHILDEXIT       PerlChildExitHandler
  CLEANUP         PerlCleanupHandler
  LOG             PerlLogHandler
  CONTENT         PerlHandler
  FIXUP           PerlFixupHandler
  TYPE            PerlTypeHandler
  AUTHZ           PerlAuthzHandler
  AUTHEN          PerlAuthenHandler
  ACCESS          PerlAccessHandler
  HEADERPARSER    PerlHeaderParserHandler
  TRANS           PerlTransHandler
  RESTART         PerlRestartHandler
:;

@EXPORT_OK = (qw:run_phase:, keys %phases);

my %sigil = qw:
  CODE   &
  ARRAY  @
  SCALAR $
  HASH   %
:;

sub _do_handler {
  my($method, $referent, $data) = @_;
  my($rsig, $dsig);

  foreach my $s (keys %sigil) {
    $rsig = $sigil{$s} if(UNIVERSAL::isa($referent, $s));
    $dsig = $sigil{$s} if(UNIVERSAL::isa($data, $s));
  }

  croak "Unknown referent type" if !defined $rsig;

  if(UNIVERSAL::isa($referent, 'CODE')) {
    $method->($referent);
  } elsif(!defined $data) {
    $method->(eval "sub { undef $rsig\$referent; }");
  } elsif(!defined $dsig and $rsig eq q+$+) {
    $method->(sub { $$referent = $data; });
  } else {
    croak "Potential referent and data mismatch" if !defined $dsig;
    if($dsig eq '&') {
      $method -> (eval "sub { $rsig\$referent = &\$data(\$referent); }");
    } else {
      $method -> (eval "sub { $rsig\$referent = $dsig\$data; }");
    }
  }
}

foreach my $p (keys %phases) {
  my($code, $keeper, $pusher);

  if($p eq 'ACCESS' || $p eq 'AUTHEN' || $p eq 'AUTHZ') {
    $pusher = "\$r -> push_handlers('$phases{$p}', sub { &\$c; return DECLINED; })";
  } else {
    $pusher = "\$r -> push_handlers('$phases{$p}', sub { &\$c; return OK; })";
  }

  if($p eq 'CLEANUP' || $p eq 'CHILDEXIT') {
    $keeper = "unshift \@{\$code{$p}}, shift";
  } else {
    $keeper = "push \@{\$code{$p}}, shift";
  }

  if($has_mod_perl) {
    eval qq{
      sub $p (&) {
        my \$r;
        if(!in_BEGIN && \$r = Apache->request) {
          my \$c = shift;
          $pusher;
        } else {
          \$code{$p} = [ ] if !ref \$code{$p};
          $keeper;
        }
      }
    };
  } else {
    eval qq{
      sub $p (&) {
        \$code{$p} = [ ] if !ref \$code{$p};
        $keeper;
      }
    };
  }
}

sub run_phase {
  my $r;
  foreach my $h (@_) {
    if(defined $code{$h}) {
      foreach my $c (@{$code{$h}}) {
        eval{ &$c };
        next unless $@;
        if($has_mod_perl && ($r = Apache -> request)) {
          $r -> log -> debug($@);
          return SERVER_ERROR;
        } else {
          die "$@\n";
        }
      }
    }
  }
}

my $yet_initialized = 0;

sub reset {
  &run_phase( qw: RESTART :);
  %code = ( );
  $yet_initialized = 0;
}

sub handler($) {
  my($r) = @_;

  return SERVER_ERROR
    if not $yet_initialized and run_phase(qw: CHILDINIT :) == SERVER_ERROR;

  $yet_initialized = 1;

  return OK if $r -> current_callback() eq 'PerlChildInitHandler';

  # install handlers
  foreach my $p (keys %code) {
    my $count;
    next if $p eq 'CHILDINIT' or $p eq 'POSTREADREQUEST' or $p eq 'CHILDEXIT';
    $r -> push_handlers($phases{$p} => sub {
        my $ret;
        foreach my $c (@{$code{$p} || []}) {
          eval { &$c() };
          if($@) {
            $r -> log -> debug($@);
            return SERVER_ERROR;
          }
        }
        if($p eq 'AUTHZ' || $p eq 'AUTHEN' || $p eq 'ACCESS') {
          return DECLINED;
        }
        return OK;
    });
  }

  return SERVER_ERROR
      if run_phase(qw: POSTREADREQUEST :) == SERVER_ERROR;
     
}

INIT {
  run_phase(qw: CHILDINIT TRANS HEADERPARSER ACCESS 
                AUTHEN AUTHZ TYPE FIXUP CONTENT :) unless $has_mod_perl;
}

END {
  run_phase(qw: LOG CLEANUP CHILDEXIT :) unless $has_mod_perl;
}

# the eval has an "uninitialized string" warning for some reason, but since
# this is the last bit and we don't care so much if it fails, we're turning
# off warnings through the end of this file...

no warnings;

eval {

use Attribute::Handlers;

sub UNIVERSAL::PerlChildInitHandler : ATTR(BEGIN) 
  { _do_handler(\&CHILDINIT, $_[2], $_[4]); }

sub UNIVERSAL::PerlPostReadRequestHandler : ATTR(BEGIN) 
  { _do_handler(\&POSTREADREQUEST, $_[2], $_[4]); }

sub UNIVERSAL::PerlTransHandler : ATTR(BEGIN) 
  { _do_handler(\&TRANS, $_[2], $_[4]); }

sub UNIVERSAL::PerlHeaderParserHandler : ATTR(BEGIN) 
  { _do_handler(\&HEADERPARSER, $_[2], $_[4]); }

sub UNIVERSAL::PerlAccessHandler : ATTR(BEGIN) 
  { _do_handler(\&ACCESS, $_[2], $_[4]); }

sub UNIVERSAL::PerlAuthenHandler : ATTR(BEGIN) 
  { _do_handler(\&AUTHEN, $_[2], $_[4]); }

sub UNIVERSAL::PerlAuthzHandler : ATTR(BEGIN) 
  { _do_handler(\&AUTHZ, $_[2], $_[4]); }

sub UNIVERSAL::PerlTypeHandler : ATTR(BEGIN) 
  { _do_handler(\&TYPE, $_[2], $_[4]); }

sub UNIVERSAL::PerlFixupHandler : ATTR(BEGIN)
  { _do_handler(\&FIXUP, $_[2], $_[4]); }

sub UNIVERSAL::PerlHandler : ATTR(BEGIN) 
  { _do_handler(\&CONTENT, $_[2], $_[4]); }

sub UNIVERSAL::PerlLogHandler : ATTR(BEGIN)
  { _do_handler(\&LOG, $_[2], $_[4]); }

sub UNIVERSAL::PerlCleanupHandler : ATTR(BEGIN)
  { _do_handler(\&CLEANUP, $_[2], $_[4]); }

sub UNIVERSAL::PerlChildExitHandler : ATTR(BEGIN)
  { _do_handler(\&CHILDEXIT, $_[2], $_[4]); }

sub UNIVERSAL::PerlRestartHandler : ATTR(BEGIN)
  { _do_handler(\&RESTART, $_[2], $_[4]); }

};

1;

__END__

=head1 NAME

Apache::Handlers

=head1 SYNOPSIS

In code:

  use Apache::Handlers qw(CLEANUP);

  our $global;
  my $session : PerlCleanupHandler;

  CLEANUP {
    our $global = undef;
  };

In httpd.conf:

  PerlModule Apache::Handlers
  PerlChildInitHandler Apache::Handlers
  PerlPostReadRequestHandler Apache::Handlers
  <Perl>
    Apache::Handlers -> reset;
  </Perl>

=head1 DESCRIPTION

C<Apache::Handlers> provides two different methods of declaring when code
snippets should be run during the Apache request phase.

The code defined with the constructs provided by this module do not
directly affect the success or failure of the request.  Thus, this module
does not provide a replacement for content, access, or other handlers.

The code is executed in the order it is encountered except for
C<CHILDEXIT>, C<CLEANUP>, C<PerlChildExitHandler>, and
C<PerlCleanupHandler> code.  These are executed in the reverse order,
similar to the pairing of C<BEGIN> and C<END> blocks.

The block construct or attribute must be run before the phase it refers
to.  Otherwise, it won't be run in that phase.  The phases are run in the
following order:

CHILDINIT TRANS HEADERPARSER ACCESS AUTHEN AUTHZ TYPE FIXUP CONTENT LOG
CLEANUP CHILDEXIT

The RESTART phase is not an actual Apache request phase and has no effect
after the server has started.  It is used to define code that should run
during the server startup phase when Apache reads the server configuration
the second time or is gracefully (or not so gracefully) restarted.  It
should be used to clean up so the second configuration process won't
duplicate information or cause errors.

If this module is called during the ChildInit phase, then it will only call
that code associated with CHILDINIT blocks.  Otherwise, the CHILDINIT code
will be run at the first opportunity (basically, the first request made of
the child process).  Thus the two Perl*Handler configuration directives in
the Synopsis.

=head2 Running without mod_perl

When developing outside mod_perl, all code associated with CHILDINIT,
TRANS, HEADERPARSER, ACCESS, AUTHEN, AUTHZ, TYPE, FIXUP, and CONTENT is run
in an C<INIT> block.  All code associated with LOG, CLEANUP, and CHILDEXIT
is run in an C<END> block.

=head2 Block Constructs

The following allow for blocks of code to be run at the specified phase.
Note that these are subroutines taking a single code reference argument and
thus require a terminating semi-colon (;).  They are named to be like the
BEGIN, END, etc., constructs in Perl, though they are not quite at the same
level in the language.

If the code is seen and handled before Apache has handled a request, it
will be run for each request.  Otherwise, it is pushed on the handler
stack, run, and then removed at the end of the request.

These are named the same as the Apache/mod_perl configuration directives
except the C<Perl> and C<Handler> strings have been removed and the
remainder has been capitalized.

=over 4

=item ACCESS

=item AUTHEN

=item AUTHZ

=item CHILDEXIT

=item CHILDINIT

=item CLEANUP

=item CONTENT

=item FIXUP

=item HEADERPARSER

=item LOG

=item POSTREADREQUEST

=item RESTART

=item TRANS

=item TYPE

=back 4



=head2 Attributes

If L<Attribute::Handlers|Attribute::Handlers> is available, then the
following attributes are available (N.B.: Attribute::Handlers requires Perl
5.6.0).  These are named the same as the Apache/mod_perl configuration
directives.

If the attribute argument is a constant value (non-CODE reference), then
the variable is assigned that value.  Otherwise, it is assigned the value
that the CODE reference returns.

If the attribute is being applied to a subroutine, then that subroutine is
called during that phase.  For example, the following two snippets result
in the same code being run at the same time.

 my $something  = sub : PerlChildExitHandler {
   print "We did it!\n";
 };

 sub something : PerlChildExitHandler {
   print "We did it!\n";
 };

When an attribute is applied to a subroutine, the argument is ignored.

When the attribute argument is itself a CODE reference, the referent (the
variable the attribute applies to) is passed as a reference:

 my $global : PerlChildInitHandler(sub { print "global: $$_[0]\n" });

This will print the value of $global and set it equal to 1 (or the value of
the print statement).

=over 4

=item PerlAccessHandler

=item PerlAuthenHandler

=item PerlAuthzHandler

=item PerlChildInitHandler

=item PerlChildExitHandler

=item PerlCleanupHandler

=item PerlFixupHandler

=item PerlHandler

=item PerlHeaderParserHandler

=item PerlLogHandler

=item PerlPostReadRequestHandler

=item PerlRestartHandler

=item PerlTransHandler

=item PerlTypeHandler

=back 4



=head2 Other Methods

=over 4

=item dump

This will dump the current set of code references and return the string.
This uses L<Data::Dumper|Data::Dumper>.

=item reset

This will clear out all previously set code.  This should only be used in
the C<startup.pl> or equivalent so that code doesn't get run twice during a
request (when it should only be run once).  This will also run any RESET
blocks that have been defined.

=item run_phase

Given a list of phases (using the names for the block constructs above),
this will run through the code for that phase, C<die>ing (outside mod_perl)
or logging (if in mod_perl) if there is an error.  For example,

  run_phase( qw: CONTENT LOG CLEANUP : );

will run any code associated with the CONTENT, LOG, and CLEANUP phases.

=back 4


=head1 CAVEATS

Caveats are things that at first glance might be bugs, but end up
potentially useful.  So I am going to make this section into a kind of
cookbook for non-obvious uses for these potential bugs.

=head2 Authentication and Authorization

Be aware that these two phases only run if Apache has reason to believe
they are needed.  This can be a bit handy since the following snippet
should tell you if the authentication phase was run.  Of course, if an
authentication handler runs before this and returns OK, then this may not
run.

  my $authentication_ran : PerlTransHandler(0) PerlAuthenHandler(1);

  LOG {
    if($authentication_ran) {
      # log something special
    }
  };

=head2 Errors

If code causes an error (such that an eval would set $@), then the request
will throw a SERVER_ERROR and write $@ to either STDERR (if not in mod_perl
and there is no C<die> handler, such as the L<Error|Error> module) or to
the Apache error log with a log level of debug.

=head2 C<Use>ing modules

Any of the block constructs or attributes provided by this module that are
used in the body of a module that is brought in via the C<use> keyword will
be considered to take place before the child is spawned.  This means that
any code designated to run during a particular phase will be run at the
appropriate time as if the module had been loaded during the server
startup.

Modules can now rest assured that using a CLEANUP block in their file will
mean that code is run at the end of every request, even if the module was
loaded in the child process and not during server startup.

This is done by looking for code run during the BEGIN phase.

=head1 BUGS

Unlike caveats, bugs are features that are undesirable and/or get in the
way of doing something useful.  I'm sure there are some.  Please let me
know when you find them.

=head2 Security

There is no way (currently) to limit registration of code for later
processing during a particular phase.  Ideas are welcome for how this
should be designed.

=head1 SEE ALSO

L<Apache>,
L<Attribute::Handlers>,
L<Data::Dumper>.

=head1 AUTHOR

James G. Smith <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2002 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

