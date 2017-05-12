package Acme::RPC;

Devel::Trace::trace('off') if exists $INC{'Devel/Trace.pm'};

use strict;
use warnings;

our $VERSION = '0.01';

use B;
use B::Deparse;
use Continuity;
use IO::Handle;
# use Devel::Pointer;
use JSON;
use Data::Dumper;
use Devel::Caller 'caller_cv';
use PadWalker 'peek_sub';
use Scalar::Util 'blessed';

my $comment = <<'EOF';

Todo:

* Accept JSON as input too, for the parameters!

* When taking apart CODE, do closes_over() too, not just peek_my().

* Weaken references held in %registry.

* Bug:  Second hit with an oid= finds the server not accepting.

* Optionally require a password... use Acme::RPC password => whatever;

* entersubs=1, enterpackages=1, etc args to control how far the recurse goes in building $tree.

* Maybe don't recurse into blessed objects, but dump them nicely upon request.
  Or maybe do recurse into them and dump their instance data.
  If $oid is passed then recurse into arrays, hashes, and object instance data.

* We don't dump references found inside CODE in the main view.
  But if they request a dump for that object, dump it.
  Likewise, we're not dumping arrays and hashes, but if they request a dump on it, dump it.

* JSON output on the default tree view too.
  We'd have to sanitize our tree...

* Document that people need to use Event::loop or something; an Acme module to insert calls to cede would be awesome for this

* Package names like foo:: should be hyperlinked too; should be able call ?oid=whatever&action=new&args=whatever on them

* The whole tree() recurse thing if it gets any more complicated is going to need a %seen list to avoid infinite recursion.

Think About:

* ?ref is for plain references (array, hash, scalar, code);  ?obj is for objects...?

* ?action parameter:  dump, call, set, new
  new is like call but it accepts a bare package name rather than an oid.

Done:

* The tree structure where each only leafs contain "hits" (references to things that get ?oid links made from them)
  is causing confusion and grief.
  Need a structure where for any given $node, $node->{chr(0)} is the (possible) object representing that node,
  and $node->{everything else} is the stuff under it.
  Then given a code ref, $node->{chr(0)} would be the code ref itself, and $node->{everything else} would be lexicals vars.
  Given a stash like "foo::", $node->{chr(0)} would actually be \%{'foo::'} and $node->{everything else} would be stuff in that package.

* Rather than only taking oids to dump/call, also take a path in the tree.

* lazy=1 parameter where the last $tree is re-used rather than re-computed.

* Should switch to our own recurse logic from Data::Dumper to support these other things.

* action=dump on anything; in the case of a coderef, find its source on disc or else deparse it

* action=call on coderefs and blessed objects, with an args parameter, or arg1, arg2, arg3, etc, and a method parameter for blessed objs.

* json will croak if a reference contains objects in side it somewhere.  Should handle this gracefully.

* Offer JSON output!  Not just Data::Dumper.  Do this for action=dump, action=call, and the default tree view.

* If Devel::Leak won't give us refs... have to do an Acme::State style crawl from main::, 
  but crawling into each sub and looking at its lexicals with PadWalker.
  Could make for a nice tree view.
  Would also make it easy to filter out the variables that hold refs.

* Maybe this should be called Acme::RPC.

* Actually crawl into code refs when recursing the output!

* Devel pointer is too much work also.  Maybe we should just cache $tree and then
  walk it again when passed an oid.  *sigh*  Magic isn't working for me today.
  Bleah.


EOF

# our $lt;
our $continuity;  # don't lose this reference
our @keepalive;   # stuff instances of objects created over RPC in there so they don't get garbage collected before the other end can use them
our $tree;        # cached tree
our %registry;    # oid=>objectrefs


sub import {

    Devel::Trace::trace('off') if exists $INC{'Devel/Trace.pm'};

    $continuity = Continuity->new(port => 7777, callback => sub {

        my $request = shift;
        while(1) {

            $SIG{PIPE} = 'IGNORE';

            my $action = $request->param('action') || 'dump';
            my $output = $request->param('output');
            my $ob;

            $tree = tree('main::') unless $tree and $request->param('lazy');

            #
            # if they're referencing a specific object, find it
            #

            if($request->param('oid')) {
                my $oid = $request->param('oid');
                $ob = $registry{$oid};
                $ob or do { $request->print("no object with that oid"); next; };
            } elsif($request->param('path')) {
                my @path = split m{/}, $request->param('path');
                my $node = $tree;
                while(@path) {
                    my $step = shift @path;
                    $node = $node->{$step} or do {
                        $step =~ s{[^a-z0-9:_-]}{}g;
                        $request->print("step ``$step'' not found in path");
                        $node = undef;
                        last;
                    };
                }
                $node or next;
                $ob = $node->{chr(0)} or do {
                    $request->print("tried to look up a path that has no object associated");
                };
            }

            #
            # default view -- index of everything, up to a certain point
            #

            if( ! $ob ) {

                my $htmlout = sub {
                    my $node = shift; 
                    no strict 'refs';
                    # each node now possibily contains named refs to other nodes (recurse into those),
                    # and a possible single chr(0), a ref to something in the running program.
                    $request->print("<ul>\n");
                    for my $k (sort { $a cmp $b } keys %$node) {
                        next if $k eq chr(0); # doesn't exist in root node and our calling instance needs to have handled it otherwise
                        next if $k eq chr(1);
                        if(exists $node->{$k}{chr(0)}) {
                            my $addy = 0+($node->{$k}{chr(0)});
                            my $comment = $node->{$k}{chr(1)} || '';
                            $request->print(qq{<li><a href="?oid=$addy">$k</a> $comment</li>\n});
                        } else {
                            $request->print(qq{<li>$k</li>\n});
                        }
                        caller_cv(0)->($node->{$k}); # caller_cv(0)->($node->{$k});
                    }       
                    $request->print("</ul>\n");
                };

                my $jsonout = sub {
                    my $node = shift; 
                    my $outnode = { };
                    no strict 'refs';
                    for my $k (sort { $a cmp $b } keys %$node) {
                        next if $k eq chr(0) or $k eq chr(1);
                        $outnode->{$k} = caller_cv(0)->($node->{$k});
                        if(exists $node->{$k}{chr(0)}) {
                            my $addy = 0+($node->{$k}{chr(0)});
                            $outnode->{$k}{oid} = $addy;
                        }
                    }
                    return $outnode;
                };

                # XXX json support here too... feed to_json a pruned $tree?
                # if($output and $output eq 'json') 
                #    $request->print(eval { to_json($ob, { ascii => 1}, ) } || $@);

                if($output and $output eq 'json') {
                    # $request->print("<pre>", eval { to_json( $jsonout->($tree), { ascii => 1, pretty => 1, } ) } || $@, "</pre>" );
                    $request->print(eval { to_json( $jsonout->($tree), { ascii => 1, } ) } || $@ );
                } else {
                    $htmlout->($tree);
                }

            } elsif($action eq 'dump') {

                # Devel::Trace::trace('on') if exists $INC{'Devel/Trace.pm'};

                if(ref($ob) eq 'CODE') {
                    my $buf = B::Deparse->new()->coderef2text($ob);
                    $buf =~ s{<}{\&lt;}g;
                    $request->print("<pre>$buf</pre>\n");
                } else {
                    if($output and $output eq 'json') {
                        $ob = tryunref($ob, $request) or next;
                        $ob = tryunobject($ob, $request) or next;
                        $request->print(eval { to_json($ob, { ascii => 1, allow_unknown => 1, allow_blessed => 1, }, ) } || $@);
                    } else {
                        $ob = tryunref($ob, $request) or next;
                        $request->print("<pre>", Data::Dumper::Dumper($ob), "</pre>\n");
                    }
                }

                # Devel::Trace::trace('off') if exists $INC{'Devel/Trace.pm'};

            } elsif($action eq 'call') {

                my @ret;
                my @args;

                my $i = 0;
                while(defined $request->param("arg$i")) {
                    $args[$i] = $request->param("arg$i");
                    # if($args[$i] =~ m/^\d+$/ and exists $registry{$args[$i]}) {
                    #     # try to find args in our %registry
                    #     $args[$i] = $registry{$args[$i]};
                    # }
                    $i++;
                }

                if(ref($ob) eq 'CODE') {
                    @ret = $ob->(@args);
                } elsif(blessed($ob)) {
                    my $method = $request->param('method');
                    $ob->can($method) or do { $request->print("object does not define that method"); next; }; 
                    @ret = $ob->can($method)->($ob, @args);
                }

                if($output and $output eq 'json') {
                     request->print(eval { to_json(\@ret, { ascii => 1}, ) } || $@);
                } else {
                    my $buf = Data::Dumper::Dumper(\@ret);
                    $request->print(qq{<pre>$buf</pre>\n});
                }

                for my $item (@ret) {
                    # add newly created items to the registry
                    $registry{0+$item} = $item if ref $item;
                }

            }

        } continue {

            # warn "doing request-next";
            $request->next;
            # warn "got next request";
        }

    });
}

sub reg ($) {
    $registry{0+$_[0]} = $_[0];
}

sub tree {

    # first, recurse through stashes starting with main::, then as we hit arrayrefs, hashrefs, and coderefs,
    # recurse into those.

    # XXX reworking this a bit.  each node should contain things logically under it as well as a ref to the
    # object that it logically refers to.  items under it are $node{whatever}, and itself is $node{chr(0)} now.
    # so, it follows that given $node{whatever}, $node{whatever}{chr(0)} is the reference for whatever.
    # this way, all nodes are hashes with children and a seperated off reference to the target object.

    # scalars can appear in packages, in object instance data, or in code refs.  same for lots of things.

    my $package = shift;

    return sub {
        # recurse through stashes (happens at the topmost level)
        my $object = shift;
        my $node = { };
        no strict 'refs';
        if(! ref($object) and $object =~ m/::$/) {
            # I don't like how each scenario is replicated here, but each is pretty short, after the custom logic for dealing with the stash.
            my $package = $object;
            for my $k (keys %{$package}) {
                next if $k =~ m/main::$/;
                next if $k =~ m/[^\w:]/;
                if($k =~ m/::$/) {
                    # found a package inside of a package
                    # my $modulepath = $package.$k;
                    # for($modulepath) { s{^main::}{}; s{::$}{}; s{::}{/}g; $_ .= '.pm'; }
                    $node->{$k} = caller_cv(0)->($package.$k);
                    reg( $node->{$k}{chr(0)} = \%{$package.$k} ); # have to do this after assinging in from the recursie call
                } elsif( *{$package.$k}{HASH} ) {
                    # our or 'use vars' variable
                    # don't recurse into hashes and arrays... if they want to see what's inside, they need to request a dump on it.
                    reg( $node->{'%'.$k}{chr(0)} = *{$package.$k}{HASH} );
                } elsif( *{$package.$k}{ARRAY} ) {
                    # our or 'use vars' variable
                    # don't recurse into hashes and arrays... if they want to see what's inside, they need to request a dump on it.
                    reg( $node->{'@'.$k}{chr(0)} = *{$package.$k}{ARRAY} );
                } elsif( *{$package.$k}{CODE} ) {
                    # subroutine inside of a package, declared with sub foo { }, else *foo = sub { }, exported, or XS.
                    # save coderefs but only if they aren't XS (can't serialize those) and weren't exported from elsewhere.
                    my $ob = B::svref_2object(*{$package . $k}{CODE});
                    my $rootop = $ob->ROOT;
                    my $stashname = $$rootop ? $ob->STASH->NAME . '::' : '(none)';
                    if($$rootop and ($stashname eq $package or 'main::'.$stashname eq $package or $stashname eq 'main::' )) {
                        # when we eval something in code in main::, it comes up as being exported from main::.  *sigh*
                        reg( $node->{$k.'()'}{chr(0)} = *{$package . $k}{CODE} );
                    }
                } elsif( ref(*{$package.$k}{SCALAR}) ne 'GLOB' ) {
                    # found a scalar inside of the package... create an entry for the scalar itself and if it contains a ref, recurse, I guess
                    my $scalar = *{$package.$k}{SCALAR};   # this is a scalarref in the case of "our $var = 1" or other simple things
                    my $scalarcontains = $$scalar;
                    if(ref $scalarcontains) {
                        $node->{'$'.$k} = caller_cv(0)->($scalarcontains);
                    }
                    reg( $node->{'$'.$k}{chr(0)} = $scalar ); # have to do this after assigning in from the recursive call
                }
            }
            # end for %{$package}, if %{$package}
        } elsif(my $class = blessed($object)) {
            # classes... instance data, methods XXX
            reg( $node->{chr(0)} = $object);  # do this after any recursive call, probably replacing the chr(0) value that came back
            $node->{chr(1)} = $class;   # comment
            # let's skip the instance data, for now
            # if( UNIVERSAL::isa($ob, 'HASH') ) {
            #     for my $k (keys %$object) {
            #         next unless ref $object->{$k};
            #         $node->{$k} = caller_cv(0)->($object->{$k});
            #     }
            # }
            my @isa = ($class, @{$class.'::ISA'});
            for my $package (@isa) {
                for my $k (keys %{$package.'::'}) {
                    next if $k =~ m/[^\w:]/;
                    next if $k =~ m/^_/;
                    next if exists $node->{$k};  # XXX $node->{$class}{chr(0)} could probably point to the correct stash or something
                    next unless *{$package.'::'.$k}{CODE};
                    reg( $node->{$k.'()'}{chr(0)} = sub { $object->can($k)->($object, @_); } ); # XXX hackish
                    # not recursing into the coderef here; if the sub is found hanging off of a stash, we'll recurse into it then.
                }
            }
        } elsif(ref($object) eq 'HASH') {
            # either our parent knows our name and did $node->{whatever} = caller_cv($ref), or else they made something up for us.
            reg( $node->{chr(0)} = $object );
        } elsif(ref($object) eq 'ARRAY') {
            reg( $node->{chr(0)} = $object );
        } elsif(ref($object) eq 'SCALAR') {
            # a scalar... if it's not a ref, this node will get one item put in it; otherwise, it may get many.
            # each of these can put whatever they want into $node!
            # the above is a bit strange in trying to fill in child nodes as well as the node itself... it should probably be recursing. XXX
            reg( $node->{chr(0)} = $object );
            my $scalarcontains = $$object;
            if(ref($scalarcontains) and ref($scalarcontains) ne 'SCALAR') {
                $node->{ref($scalarcontains)} = caller_cv(0)->($scalarcontains);
            }
        } elsif(ref($object) eq 'CODE') {
            # generic name for ourself -- this was found inside another code ref, in instance data, array element, or something.
            reg( $node->{chr(0)} = $object );
            # variables inside code refs
            # walk into the sub and pick out lexical variables
            # normally only closures would contain data in their lexical variables, but with multiple
            # coroutines executing concurrently, there's the chance that a subroutine is currently
            # running, in which case it has data in its pad.  if it's recursive, it might have data
            # at multiple depths too!
            my $p = peek_sub($object);
            for my $k (sort { $a cmp $b } keys %$p) {
                $node->{$k} = caller_cv(0)->($p->{$k});  # anything it contains by way of refs, which might be nothing
                reg( $node->{$k}{chr(0)} = $p->{$k} );  # have to do this after assigning in from the recursie call
            }
        } elsif( ! ref($object) ) {
            # XXX how could we represent constant data, as in the case of our $foo = "hi there", or instance data fields, or...?
        }
        return $node;
    }->('main::');
}

sub tryunref {
    my $ob = shift;
    my $request = shift;
    for(1..4) {
        $ob = $$ob if(ref $ob) eq 'REF';
    }
    ref($ob) eq 'REF' and do {
        $request->print("REF derefs to REF four times; probably circular");
        return;
    };
    return $ob;
}

sub tryunobject {
    my $ob = shift;
    my $request = shift;
    if( blessed($ob) and UNIVERSAL::isa($ob, 'HASH') ) {
        $ob = { %$ob };
    } elsif( blessed($ob) and UNIVERSAL::isa($ob, 'ARRAY') ) {
        $ob = [ @$ob ];
    } elsif( blessed($ob) and UNIVERSAL::isa($ob, 'SCALAR') ) {
        $ob = \ ${$ob};
    } elsif( blessed($ob) ) {
        $request->print("object not blessed hash, array or scalar... no logic for converting to JSON, sorry"); 
        return;
    }
    return $ob;
}

END { $continuity->loop }


1;

=head1 NAME

Acme::RPC - Easy remote function and method call and more

=head1 SYNOPSIS

  use Acme::RPC;
  our $test2 = t2->new();

  package t2; 
  sub new { bless {  one => 1 }, $_[0] }; 
  sub add { ($_[1] + $_[2]); }'

Then go to:

  http://localhost:7777/?path=%24test2/add()&action=call&arg0=10&arg1=15

The C<path> part, decoded, reads C<< $test2/add() >>.

=head1 DESCRIPTION

By my estimate, there are over 10,000 RPC modules on CPAN.  Each one makes RPC more
difficult than the one before it.  They all want you to pass tokens back and forth,
register handlers for which methods may be called, create sessions, and so.
With L<Acme::RPC>, there's only one required step:  GET or POST to your method.
And if you don't know which methods are available, L<Acme::RPC> will help you find them.
Even if they're hidden away in objects referenced from inside of closures.

The RPC daemon starts after the program finishes, or whe it does C<< Event::loop >>.

=head2 CGI Parameters

=over 4

=item C<< / >>

(No parameter.)

=item C<< action=dump >>

Gives an index of packages, subroutines, variables in those subroutines, closures in those variables, and so on.

=item C<< output=json >>

Output a JavaScript datastructures (JSON) instead of Perl style L<Data::Dumper> or HTML.
The main index page otherwise prints out HTML (under the assumption that a human will be digging through it)
and other things mostly emit L<Data::Dumper> formatted text.

=item C<< oid=(number) >>

=item C<< path=/path/to/something >>

There are two ways to specify or reference an object:  by it's C<oid> or by the path to navigate to it from the 
main index screen.
JSON and HTML output from the main index screen specifies the oids of each item and the paths can be derived from
the labels in the graph.
With no action specified, it defaults to C<dump>.

=item C<< action=call >>

Invokes a method or code ref.
It does I<not> invoke object references.
Requires either C<oid> or C<path> be specified.
You may also set C<arg0>, C<arg1>, C<arg2> etc GET or POST parameters to pass data into the function.
There's currently no way to pass in an arbitrary object (see TODO below).

=item C<< action=method >>

Used with C<< method=[method name] >> and either an C<< oid=[oid] >> or C<< path=[path] >> to an
object reference, it calls that method on that object.
As above, takes argument data from C<arg0>, C<arg1>, C<arg2>, etc.

=item C<< lazy=1 >>

Avoid rebuilding the entire object graph to speed things up a bit.

=head2 TODO

C<oidarg[n]> to pass in an arbitrary other object as a parameter.

JSON posted to the server to specify arguments.

JSON posted to the server to specify the entire function/method call.

=head2 BUGS

There is no security.  At all.

A lot of this stuff hasn't been tested.  At all.

You will leak memory like crazy.

Really, I wasted about three days on this, so I'm very much in a "it compiles, ship it!" mode.
Want to see it rounded out better?  Drop me some email.

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options:

  -A -C -X -b 5.8.0 -c -n Acme::RPC

=back

=head1 SEE ALSO

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

USE AT YOUR OWN RISK.

NOT SUITABLE FOR ANY PURPOSE.


=cut

__END__

        if(ref($object) eq 'HASH' and B::svref_2object($object)->NAME) {
            # a HASH with a NAME is a stash (package).
            my $package = B::svref_2object($object)->NAME;

use Devel::Leak;
    # $lt or Devel::Leak::NoteSV($lt);
                open my $olderr, '>&', \*STDERR or die "Can't dup STDERR: $!";
                close STDERR;
                open STDERR, ">", \my $buf or die $!;
                Devel::Leak::CheckSV($lt);
                # $buf =~ tr/A-Z/a-z/; print $buf;
                close STDERR;
                open STDERR, '>&', $olderr;
                close $olderr;
                $buf =~ s{(0x[a-f0-9]{6,})}{<a href="?oid=$1">$1</a>}g;

                # $oid =~ m/^0x[0-9a-f]{8,}$/
                # my $ob = Devel::Pointer::deref(hex($oid));
                my $ob = Devel::Pointer::deref($oid);
                my $buf = Data::Dumper::Dumper($ob);
                # $buf =~ s{(0x[a-f0-9]{6,})}{<a href="?oid=$1">$1</a>}g;
                $request->print(qq{<pre>$buf</pre>\n});
* Accepts posts as well, and handle by data type.
  Posts to CODE refs run them with the arguments (attempt to reconstitute object references in the arguments... move to 0x style oids again
  to support this).
  Posts to object references (blessed things) invoke the named method in them (again, reconstituting the args).
  Posts to scalars, arrays, hashes, etc merely replace their data.


