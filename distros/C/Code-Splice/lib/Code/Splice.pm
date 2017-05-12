package Code::Splice;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

<<comment;

Todo:

* Change the nextstate instructions in the code as we paste it:
  Line number should be where it's inserted at, but filename should have info about the code
  having been spliced.
* Option about whether to splice out the matching op or append/prepend to it.
* Option about whether to splice into an expression or to splice only at a nextstate/at the line level.
* Positional argument syntax, where arguments to the code being replced can be re-spliced into the
  user provided code (needed to do real macroy stuff)
* Feature where certain subroutine names (or subroutines tagged with a certain attribute)
  get replaced with their definitions at each point they appear, with their arguments spliced in

comment

use B qw< OPf_KIDS OPf_STACKED OPf_WANT OPf_WANT_VOID OPf_WANT_SCALAR OPf_WANT_LIST OPf_REF OPf_MOD OPf_SPECIAL OPf_KIDS >;
use B qw< OPpTARGET_MY ppname>; 
use B qw< SVf_IOK SVf_NOK SVf_POK SVf_IVisUV >;
use B::Generate;
use B::Concise;
use B::Deparse;
# use B::Utils;
sub SVs_PADMY () { 0x00000400 }     # use B qw< SVs_PADMY >;

use strict;
use warnings;

#
# debugging
#

my $debug;
# use Data::Dumper 'Dumper'; # debug
# use Carp 'confess';
# BEGIN { $SIG{USR1} = sub { use Carp; print confess("crap."); exit; }; };

#
# api
#

sub inject {

    my %args = @_;
    my $code = delete $args{code};          # what to insert
    my $package = delete $args{package};    # where to insert it
    my $method = delete $args{method};

    # user-provided arrays-of-code specifications of where to inject at

    my $preconditions = delete $args{preconditions} || [ ];
    my $postconditions = delete $args{postconditions} || [ ];

    for(my $i = 0; $i < @_; $i += 2) { 
        $_[$i] eq 'precondition' and push @$preconditions, $_[$i+1];
        $_[$i] eq 'postcondition' and push @$postconditions, $_[$i+1];
    }

    delete $args{precondition};
    delete $args{postcondition};

    # specifications with which to build 

    my $line = delete $args{line};
    my $label = delete $args{label};

    $debug = delete $args{debug};

    %args and die "unknown arguments: " . join ', ', keys %args;

    UNIVERSAL::isa($code, 'CODE') or die;

    # Build list of conditions that must be true for the injection and list of things which cannot be true

    $line and push @$preconditions, sub {
        my $op = shift;
        $op->name eq 'nextstate' or return;
        $line and $op->line == $line or return;
        return 1;
    };

    $label and push @$preconditions, sub {
        my $op = shift;
        $op->name eq 'nextstate' or return;
        $line and $op->label eq $label or return;
        return 1;
    };

    # Look up the method we're supposed to insert into

    my $cv = do { no strict 'refs'; B::svref_2object(*{$package.'::'.$method}{CODE} or die "no such package/method"); }; 
    $cv->ROOT() or die "no code in $package\::method";
    $cv->STASH()->isa('B::SPECIAL') and die "can't splice into binary compiled XS code you twit"; # Can't locate object method "NAME" via package "B::SPECIAL"
    $cv->ROOT()->can('first') or die "$package\::$method cannot do ->ROOT->first\n"; 

    # Ready the code we're support to inject

    # Code we're to insert should have a structure as follows:

    # 5  <1> leavesub[1 ref] K/REFC,1 ->(end)                                     <--- $newop
    # -     <@> lineseq KP ->5
    # 1        <;> nextstate(splice 38 splice.pm:99) v/2 ->2
    # 4        <@> print sK ->5                                                   <--- $newopfirst ( $newop->first->first->sibling ); also $newlastop here
    # 2           <0> pushmark s ->3
    # 3           <$> const(PV "test!!\n") s ->4

    # We want the nextstate and all of its siblings (print, another nextstate perhaps, more stuff...)

    my $newcv = B::svref_2object($code);
    $debug and do { print "\n\ncode to splice:\n"; B::Concise::concise_cv_obj('basic', $newcv); }; # dump the opcode tree of this code value
    my $newop = $newcv->ROOT;                            # $newop points to a leavesub instruction
    $newop->name eq 'leavesub' or die;
    my $newopfirst = $newop->first->first;  $newopfirst = $newopfirst->has_sibling if $newopfirst->has_sibling and $newopfirst->name  eq 'nextstate'; # was causing coredumps when the nextstate was inserted into the wrong place
    my $newoplast = do { my $x = $newopfirst; $x = $x->has_sibling while $x->has_sibling; $x; };

    # XXXX moved rewrite pad entries

    my @srcpad = lexicals($newcv);
    my @destpad = lexicals($cv); 

    my %destpad = map { ( $destpad[$_] => $_ ) } grep defined $destpad[$_], 0 .. $#destpad; # build a name-to-number index

    # map { ( $_ => $padnames[$_]->PVX) }  grep { ! $padnames[$_]->isa('B::SPECIAL') } 0 .. $#padnames;

    $debug and do { print "debug: srcpad: ", join ', ', map $_||'(undef)', @srcpad; print "\n"; };
    $debug and do { print "debug: destpad: ", join ', ', map $_||'(undef)', @destpad; print "\n"; };

    # Translate the spliced-in code's idea of lexicals to match where it's spliced in to

    walkoptree_slow($newcv->ROOT, sub {
        my $op = shift or die;       # op object
# warn "rewriting pad looking at an: " . B::class($op);
        $op->can('targ') or return;  # B::NULL cannot
        $srcpad[$op->targ] or return; 
        $debug and print "debug: ", $op->name, " references pad slot ", $op->targ, " which contains ", $srcpad[$op->targ]||'', "\n";
        exists $destpad{$srcpad[$op->targ]} or die "variable ``$srcpad[$op->targ]'' doesn't exist in target context";
        $op->targ($destpad{$srcpad[$op->targ]});
        # print "debug: variable name: $srcpad[$op->targ]\n";
        # print "debug: index of same variable in dest: ", $destpad{$srcpad{$op->targ}}, "\n";
    }); 

    my $redo_reverse_indices = sub {
        my $siblings = { };
        walkoptree_slow($cv->ROOT, sub { 
            my $self = shift;       return unless $self and $$self;
            my $next = $self->next; 
            my $sibl = $self->can('sibling') ? $self->sibling : undef;
            $siblings->{$$sibl} = $self if $sibl and $$sibl;
        });
        return $siblings;
    };

    # Get ready to recurse through the bytecode tree - build a reverse index, previous, from the next link

    my $siblings = $redo_reverse_indices->();

    # build a table of deparsed code to line number

    my @codelines;
    
    walkoptree_slow($cv->ROOT, sub {

        my $op = shift;
        return if $op->isa('B::NULL');
        return unless $op->name eq  'nextstate';

        my $line = $op->line or die;
        $op = $op->sibling;
        return if $op->isa('B::NULL');

        my $dp = B::Deparse->new;
        $dp->{curcv} = $cv;
        $debug and print "debug: deparse: $line: ", $dp->deparse($op, 0), "\n";
        $codelines[$line] = $dp->deparse($op, 0);

    });

    # debugging for before we modify anything

    $debug and do { print "\n\nbefore:\n"; B::Concise::concise_cv_obj('basic', $cv); }; # dump the opcode tree of this code value

    # identify the pointcut and insert the target code in right there

    my $curcop;
    my $codeline;

    my $look_for_things_to_diddle = sub {
     
        my $op = shift or die;       # op object
        my $level = shift;
        my $parents = shift or die;
    
        return unless $op and $$op;
        return if $op->isa('B::NULL');

        $debug and print "debug: look_for_things_to_diddle: doing an ", $op->name, "\n";
    
        return unless exists $parents->[0]; # root op isn't that interesting and we need a parent
        my $parent = $parents->[-1];
    
        my $pointcut = sub {
    
            # When splicing bytecode, we must consider the parent's first, parent's last, our previous sibling, our next sibling
            # That ignores threading next, which gets done later

            # print "modifying ", $op->name, " at addresss ", $$op, "\n";

            # XXX alternate between the two according to some test

            my $prev_sibling = $siblings->{$$op}; # may be undef
            my $next_sibling = $op->sibling;      # may be undef

            $prev_sibling->sibling($newopfirst) if $prev_sibling and $$prev_sibling;
            $newoplast->sibling($op->sibling) if $op->sibling and ${$op->sibling};
    
            $debug and print "debug: splicing code, I think the parent is a ", $parent->name, "\n";
    
            $parent->first($newopfirst) if $parent->can('first') and ${$parent->first} == $$op;
            $parent->last($newoplast) if $parent->can('last') and ${$parent->last} == $$op;
    
            $siblings = $redo_reverse_indices->(); # only one swath of code is injected at a time, so this isn't currently needed

            # One chunk of bytecode can only be spliced into one place unless we make a deep copy of it,
            # which we don't know how to do yet, so we just bail.  

            goto did_pointcut;
    
        };

        $curcop = $op if $op->name eq 'nextstate';
        $codeline = $codelines[$curcop->line] if $curcop and defined $codelines[$curcop->line];
 
        for my $post (@$postconditions) {
            if($post->($op, $codeline)) {
                die "post condition true before insert point found: ". B::Deparse->new->coderef2text($post);
            }
        }

        for my $i (0 .. @$preconditions-1) {
            if($preconditions->[$i]->($op, $codeline)) {
                splice @$preconditions, $i, 1, ();
            }
        }
    
        if(! @$preconditions) {
            $op = $op->has_sibling if $op->has_sibling and $op->name eq 'nextstate';
            $pointcut->();
            goto did_pointcut;
        }
    
        return;
    
    };

    walkoptree_slow($cv->ROOT, $look_for_things_to_diddle);
    die "pointcut failed";
    did_pointcut:

    # re-thread next:

    fix($cv->ROOT->first, $cv->ROOT);

#    my @srcpad = lexicals($newcv);
#    my @destpad = lexicals($cv); 
#
#    my %destpad = map { ( $destpad[$_] => $_ ) } grep defined $destpad[$_], 0 .. $#destpad; # build a name-to-number index
#
#    # map { ( $_ => $padnames[$_]->PVX) }  grep { ! $padnames[$_]->isa('B::SPECIAL') } 0 .. $#padnames;
#
#    $debug and do { print "debug: srcpad: ", join ', ', map $_||'(undef)', @srcpad; print "\n"; };
#    $debug and do { print "debug: destpad: ", join ', ', map $_||'(undef)', @destpad; print "\n"; };

# original version of pad rewriting:
#    walkoptree_slow($cv->ROOT, sub {
#        my $op = shift or die;       # op object
#        $op->can('targ') or return;  # B::NULL cannot
#        $srcpad[$op->targ] or return; 
#        $debug and print "debug: ", $op->name, " references pad slot ", $op->targ, " which contains ", $srcpad[$op->targ]||'', "\n";
#        exists $destpad{$srcpad[$op->targ]} or die "variable ``$srcpad[$op->targ]'' doesn't exist in target context";
#        $op->targ($destpad{$srcpad[$op->targ]});
#        # print "debug: variable name: $srcpad[$op->targ]\n";
#        # print "debug: index of same variable in dest: ", $destpad{$srcpad{$op->targ}}, "\n";
#    }); 
# that's not working either now...

    $debug and do { print "\n\nafter:\n"; B::Concise::concise_cv_obj('basic', $cv); }; # dump the opcode tree of this code value

    return 1;
}


#
# utility methods
#

my @parents = ();

sub walkoptree_slow {
    # actually recurse the bytecode tree
    # stolen from B.pm, modified
    my $op = shift;
    my $sub = shift;
    my $level = shift;

    $level ||= 0;

    # warn "walkoptree_debug: $level " . $op->name if our($walkoptree_debug) and $op and $$op;

    $sub->($op, $level, \@parents);
    if ($op->can('flags') and $op->flags() & OPf_KIDS) {
        # print "debug: go: ", '  ' x $level, $op->name(), "\n"; # debug
        push @parents, $op;
        my $kid = $op->first();
        my $next;
        next_kid:
          # was being changed right out from under us, so pre-compute
          $next = 0; $next = $kid->sibling() if $$kid;
          walkoptree_slow($kid, $sub, $level + 1);
          $kid = $next;
          goto next_kid if $kid;
        pop @parents;
    }
    if (B::class($op) eq 'PMOP' && $op->pmreplroot() && ${$op->pmreplroot()}) {
        # pattern-match operators
        push @parents, $op;
        walkoptree_slow($op->pmreplroot(), $sub, $level + 1);
        pop @parents;
    }
};

sub fix {
    my ($op, $parent) = @_;
    $debug and print "fixing: ", $$op ? $op->name : '(null)', "\n";
    if($op->isa('B::NULL')) {
        $debug and print "skipping null\n";
        #return fix($op->first, $parent);
        return $op;
    }
    # $op = denull($op);
    if($op->has_sibling) {
        $debug and print "has sibling, fixing and hooking\n";
        $op->next(fix($op->has_sibling, $parent));
    } else {
        $debug and print "no sibling, hooking to parent (if applicable)\n";
        $op->next($parent) if $parent;
    }
    if($op->has_first) {
        $debug and print "Fixing children, and getting lastmost first\n";
        return fix($op->has_first, $op);
    } else {
        $debug and print "No kids... we are the lastmost first!\n";
        return $op;
    }
}

sub B::OP::has_sibling {
    my $op = shift;
    # eval { warn 'has_sibling: ' . $op->sibling; };
    return unless $op->can('sibling') and $op->sibling and ${$op->sibling}; #  and ref $op->sibling ne 'B::NULL';
    return denull($op->sibling);
}

sub B::OP::has_first {
    my $op = shift;
    # eval { warn 'has_first: ' . $op->first; };
    return unless $op->can('first') and $op->first and ${$op->first}; #  and ref $op->first ne 'B::NULL';
    return denull($op->first);
}

sub denull {
    my $op = shift;
    if( $op->isa('B::NULL') ) {
        return denull($op->first);
    } else {
        return $op;
    }
}

sub lexicals {
    my $cv = shift;
    map { $_->isa('B::SPECIAL') ? undef : $_->PVX } ($cv->PADLIST->ARRAY)[0]->ARRAY;
}

1;

=pod

=head1 NAME

Code::Splice - Injects the contents of one subroutine at a specified point elsewhere.

=head1 SYNOPSIS

  use Code::Splice;

  Code::Splice::inject(
    code => sub { print "fred\n"; }, 
    package => 'main', 
    method => 'foo', 
    precondition => sub { 
      my $op = shift; 
      my $line = shift;
      $line =~ m/print/ and $line =~ m/four/;
    },
    postcondition => sub { 
      my $op = shift; 
      my $line = shift;
      $line =~ m/print/ and $line =~ m/five/;
    },
  );

  sub foo {
    print "one\n";
    print "two\n";
    print "three\n";
    print "four\n";
    print "five\n";
  }

=head1 DESCRIPTION

Removes the contents of a subroutine (usually an anonymous subroutine created just
for the purpose) and splices in into the program elsewhere.

Why, you ask?

=over 1

=item Write stronger unit tests than the granularity of the API would otherwise allow

=item Write unit tests for nasty, interdependant speghetti code (my motivation -- hey, you gotta have tests before you can start refactoring, and if you can't write tests for the code, you're screwed)

=item Fix stupid bugs and remove stupid restrictions in other people's code in a way that's more resiliant across upgrades than editing files you don't own

=item Be what "aspects" should be

=item Screw with your cow-orkers by introducing monster heisenbugs

=item Play with self-modifying code

=item Write self-replicating code (but be nice, we're all friends here, right?)

=back

The specifics:

The body of the C<< code { } >> block are extracted from the subroutine and inserted in a place
in the code specified by the call to the C<splice()> function.
Where the new code is spliced in, the old code is spliced out.
The C<package> and C<method> arguments are required and tell the thing how to find the
code to be modified.
The C<code> argument is required as it specifies the code to be spliced in.
That same code block should not be used for anything else under penalty of coredump.

The rest of the argumets specify where the code is to be inserted.  
Any number of C<precondition> and C<postcondition> arguments provide callbacks
to help locate the exact area to splice the code in at.
Before the code can e spliced in, all of the C<precondition> blocks must have returned
true, and none of the C<postcondition> blocks may have yet returned true.
If a C<postcondition> returns true before all of the C<precondition> blocks have,
an error is raised.
Both blocks get called numerous times per line and get passed a reference to the C<B> OP object currently under consideration
and the text of the current line:

    precondition => sub { 
      my $op = shift; 
      my $line = shift;
      $line =~ m/print/ and $line =~ m/four/;
    },

... or...

    precondition => sub { my $op = shift; $op->name eq 'padsv' and $op->sv->sv =~ m/fred/; },

It's possible to insert code in the middle of an expression when testing ops, but when
testing the text of the line of code, the spliced in code will always replace the whole line.

I'll probably drop sending in the opcode in a future version, at least for the
precondition/postcondition blocks, or maybe I'll swap them to the 2nd arg so they're
more optional.

Do not attempt to match text in comments as it won't be there.
The code in C<$line> is re-generated from the bytecode using F<B::Deparse> and will
vary from the original source code in a few ways, including changes to formatting,
changes to some idioms and details of the expressions, and formatting of the code
with regards to whitespace.

The splicing code will C<die> if it fails for any reason.
This will likely change in possible future versions.

There are also C<label> and C<line> arguments that create preconditions for you, for
simple cases.
Of course, you shouldn't use C<line> for anything other than simple experimentation.

References to lexical variables in the code to be injected are replaced with references to the
lexical variables of the same name in the location the code is inserted into.
If a variable of the same name doesn't exist there, it's an error.
... but it probably shouldn't be an error, at least in the cases where the code being
spliced in declares that lexical with C<my>, or when the variable was initiailized entirely
outside of the sub block being spliced in and was merely closed over by it.

See the comments in the source code (at the top, in a nice block) for my todo/desired features.
Let me know if there are any features in there or yet unsuggested that you want.
I won't promise them, but I would like to hear about them.

=head1 BUGS

The original code reference passed in cannot be used elsewhere.
It can't be called, and it should not be passed back to C<< inject() >> again.
Failure to heed these warnings will result in coredumps and strange behaviors.

Until I get around to finishing reworking C<B::Generate>, C<B::Generate-1.06> needs
line 940 of C<B-Generate-1.06/lib/B/Generate.c> changed to read 
C<o = Perl_fold_constants(o);> (the word C<Perl> and an understore should be inserted).
This is in order to build C<B::Generate-1.06> on newer Perls.
I have a fixed and slightly extended version in my area on CPAN, if you search
for SWALTERS.

Should gracefully default to not fixing up lexicals where no direct equivilent exists.

Should repair the provided subroutine reference so that if were to be accidentally
called, Perl wouldn't coredump.


=head1 HISTORY

0.1 -- initial release.

=head1 SEE ALSO

L<http://search.cpan.org/~swalters/B-Generate-1.06_1/> -- slightly updated B::Generate -- you'll need this

L<http://perldesignpatterns.com/?PerlAssembly> attempts to document the Perl internals I'm prodding so bluntly.

=head1 AUTHORS

Scott Walters L<scott@slowass.net> - http://slowass.net/

Brock Wilcox L<awwaiid@thelackthereof.org> - http://thelackthereof.org/

Code lifted from various B modules...

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Scott Walters and Brock Wilcox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


__END__

        my $stringrep = do {
            my $cachedstringrep;
            sub {
                again: $cachedstringrep and return $cachedstringrep;
                my $leave = B::LISTOP->new('leave', OPf_WANT_LIST | OPf_KIDS, 0, 0);
                my $dp = B::Deparse->new;
                $dp->init;
                $dp->{curcv} = $cv;
                my $save_sibling = $op->sibling;
                my $save_next = $op->next;
                $leave->first($op);
                $leave->last($op);
                $op->sibling(0);
                $op->next($leave);
                print "start deparse:\n";
	            print $dp->deparse($op, 0);
                print "\nend deparse\n\n";
                $op->sibling($save_sibling);
                $op->next($save_next);
                goto again;
            };
        };


Notes:

It currently crawls deeply into the bytecode rather than just walking down the top level
even though the pointcut thingie only allows line level resolution on modification right
now.  The pointcut interface is just for demonstration only right now.  Something
more useful might take a list of constraints along the lines of:

* After a variable of a given name is declared
* After/before a variable of a given name is assigned to
* After/before a method call of a specific name
* After/before a variable of a given name is used as an argument in a method call to a method of a specific name
* After/before a specific operation, such as print, close, etc

Done:

* Change instructions to use the pad of the routine they got moved into:
  Lookup variable names in the anonsub, find variables of the same names in the target sub's pad,
  and change the targ to match.

............. the version of this above shouldn't be correct, but attempts at a corrected version of the rewriting the pads just hit brokenness and confusion.

    walkoptree_slow($newcv->ROOT, sub {
# XXXX redid the $op->targs in here to $idx; highly experimental; still have to change them elsewhere too if this works
# XXX do this before we splice the code in?  so that we can stay contained to that?
        my $op = shift or die;       # op object
        return unless $op and $$op;
warn "XXXX considering changing pad for an " . $op->name . " of class " . B::class($op); # "XXXX considering changing pad for an padav of class OP at /usr/local/lib/perl5/site_perl/5.16.1/Code/Splice.pm line 155."
        # $op->can('targ') or return;  # B::NULL cannot
# warn $op->name . " is a " . ref $op;
        # ref($op) eq 'B::PADOP' or return;  # XXX highly experimental; we were screwing up apparently the refcnt on leavesubs, which use targ for that; nope, padav is a B::OP according to ref
        # return if $op->name eq 'leavesub'; # XXX surely there are more
        return if $op->name eq 'const'; # how are those making it through?  argh.
        # return unless grep $_ eq B::class($op), 'SVOP', 'PADOP';  # nope, padvs come back with a class B::OP.
        return if $op->name eq 'aelemfast' and $op->flags & OPf_SPECIAL; # no idea why; cargo culted from B::Concise
        # my $idx = B::class($op) eq 'SVOP' ? $op->targ : $op->padix; # no idea; cargo culted from B::Concise XXX B.pm says padix is a method of B::SVOP; that means that this is backwards?!
warn "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX changing pad for " . $op->name . " from $srcpad[$idx] to $destpad{$srcpad[$idx]}";
        $srcpad[$idx] or return;
        $debug and print "debug: ", $op->name, " references pad slot ", $idx, " which contains ", $srcpad[$idx]||'', "\n";
        exists $destpad{$srcpad[$idx]} or die "variable ``$srcpad[$idx]'' doesn't exist in target context";
        # $op->targ($destpad{$srcpad[$idx]});
        if( B::class($op) eq 'SVOP' ) { $op->targ($destpad{$srcpad[$idx]}); } else { $op->padix($destpad{$srcpad[$idx]}); }
        # print "debug: variable name: $srcpad[$idx]\n";
        # print "debug: index of same variable in dest: ", $destpad{$srcpad{$idx}}, "\n";
    });


