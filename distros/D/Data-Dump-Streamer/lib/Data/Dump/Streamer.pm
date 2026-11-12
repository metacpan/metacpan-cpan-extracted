package Data::Dump::Streamer;
use 5.012;
use strict;
use warnings;
use warnings::register;
use B            ();
use B::Deparse   ();
use Data::Dumper ();
use DynaLoader   ();
use Exporter     ();
use IO::Handle   ();
use Symbol       ();
use Hash::Util   qw(lock_keys lock_ref_keys lock_keys_plus lock_ref_keys_plus);
use re           ();

our ($VERSION, $XS_VERSION, $HasPadWalker, $DEBUG);
our (@ISA, @EXPORT, @EXPORT_OK, @EXPORT_FAIL, %EXPORT_TAGS);

BEGIN {
    $VERSION= '3.002';
    $XS_VERSION= eval $VERSION;
    @ISA= qw(Exporter DynaLoader);
    @EXPORT= qw(Dump DumpLex DumpVars);
    @EXPORT_OK= qw(
        Dump
        DumpLex
        DumpVars
        Stream
        alias_av
        alias_hv
        alias_ref
        push_alias
        dualvar

        alias_to

        blessed
        reftype
        refaddr
        refcount
        sv_refcount
        looks_like_number
        regex
        readonly
        make_ro
        _make_ro
        reftype_or_glob
        refaddr_or_glob
        globname
        is_numeric

        all_keys
        legal_keys
        hidden_keys
        lock_ref_keys
        lock_keys
        lock_ref_keys_plus
        lock_keys_plus
        SvREADONLY_ref
        SvREFCNT_ref
        isweak
        weaken
        weak_refcount

        readonly_set

        Dumper
        DDumper

        alias
        sqz
        usqz
    );

    %EXPORT_TAGS= (
        undump => [
            qw( alias_av alias_hv alias_ref make_ro
                lock_ref_keys
                lock_keys
                lock_ref_keys_plus
                lock_keys_plus
                alias_to
                dualvar
                weaken
                usqz
            )
        ],
        special => [qw( readonly_set )],
        all     => [ @EXPORT, @EXPORT_OK ],
        alias   => [qw( alias_av alias_hv alias_ref push_alias )],
        bin     => [@EXPORT_OK],
        Dumper  => [qw( Dumper DDumper )],
        util    => [ qw (
                dualvar
                blessed reftype refaddr refcount sv_refcount
                readonly looks_like_number regex is_numeric
                make_ro readonly_set reftype_or_glob
                refaddr_or_glob globname
                weak_refcount isweak weaken
            )
        ],

    );

    Data::Dump::Streamer->bootstrap($XS_VERSION);
    if ($] >= 5.013006 && $] < 5.013010) {

        # These development releases exposed flags that were not yet legal
        # in regexp literals. Preserve the original compatibility rule.
        *regex= sub {
            return scalar re::regexp_pattern($_[0]) unless wantarray;
            my ($pattern, $modifiers)= re::regexp_pattern($_[0]);
            $modifiers =~ tr/dlua?//d if defined $modifiers;
            return ($pattern, $modifiers);
        };
    }
    elsif ($] >= 5.009004) {
        *regex= \&re::regexp_pattern;
    }

    # Older interpreters use the regex XSUB installed by bootstrap above.
    $HasPadWalker= eval { require PadWalker; PadWalker->VERSION('0.99'); 1 };
}
$DEBUG= 0;
*DDumper= \&Data::Dumper::Dumper;
*_get_lexicals= \&_xs_get_lexicals;

# Export the requested API and optionally install a package alias selected by
# the caller's "as" argument.
sub import {
    my ($pkg)= @_;
    my ($idx, $alias);

    if ($idx= (grep lc($_[$_]) eq 'as', 0 .. $#_)) {

        #print "found alias at $idx:\n";
        ($idx, $alias)= splice(@_, $idx, 2);

        #print "found alias: $idx => $alias\n";

        no strict 'refs';
        *{ $alias . '::' }= *{ __PACKAGE__ . '::' };
    }
    $pkg->export_to_level(1, @_);
}

# Provide the decompressor import prelude or a compressed reconstruction
# expression for one string.
sub _compressor {
    return "use Data::Dump::Streamer qw(usqz);\n"
        if !@_;
    return sqz($_[0], "usqz('", "')");
}

# Compress a private byte copy and Base64-encode it, tagging Unicode strings
# so usqz can restore their UTF-8 flag. Optional text wraps the payload.
sub sqz {
    require Compress::Zlib;
    require MIME::Base64;

    my $value= $_[0];
    my $unicode= utf8::is_utf8($value);
    utf8::encode($value) if $unicode;
    my $res= Compress::Zlib::compress($value, 9);
    my $payload= MIME::Base64::encode($res, '');

    # A colon cannot occur in legacy Base64 payloads. Keep byte strings
    # untagged so their existing representation remains unchanged.
    $payload= 'u:' . $payload if $unicode;
    return $_[1]
        ? $_[1] . $payload . $_[2]
        : $payload;
}

# Decode and decompress a string emitted by sqz, loading the optional
# compression modules in the reconstruction interpreter as needed.
sub usqz {
    require Compress::Zlib;
    require MIME::Base64;

    my $payload= $_[0];
    my $unicode= $payload =~ s/\Au://;
    my $value= Compress::Zlib::uncompress(MIME::Base64::decode($payload));
    if ($unicode && defined $value) {
        utf8::decode($value)
            or die "Invalid UTF-8 in compressed Unicode string";
        utf8::upgrade($value);
    }
    return $value;
}

# Return copied catalogue rows ordered by minimum depth and canonical name for
# diagnostic display.
sub _diag_rows {
    my ($self, $kind)= @_;
    return [ sort { $a->{depth} <=> $b->{depth} || $a->{name} cmp $b->{name} }
            @{ $self->_xs_catalogue->{$kind} } ];
}

# Format one catalogue row, including identity, counts, depth, flags and
# completion status.
sub _diag_row {
    my ($kind, $idx, $row, $prefix)= @_;
    return '' unless $row;
    return sprintf "%s%s %2d : %#x(c%2d|%2d) Dp:%2d %s %s Du:%d => %s\n",
        $prefix || '', $kind, $idx, @$row{qw(address count encounters depth)},
        $row->{readonly} ? 'RO' : 'RW', $row->{weak} ? 'WK' : '  ',
        $row->{done}, $row->{name};
}

# Print scalar-slot and referent catalogue diagnostics to a handle and return
# the dumper for chaining.
sub diag {
    my $self= shift;
    my $handle= shift || \*STDOUT;
    print $handle "+---+\n";
    for my $kind (qw(slots references)) {
        my $rows= $self->_diag_rows($kind);
        for my $idx (0 .. $#$rows) {
            print $handle _diag_row(substr(uc($kind), 0, 1), $idx + 1,
                $rows->[$idx]);
        }
    }
    print $handle "+---+\n";
    return $self;
}

# Format the requested one-based scalar-slot diagnostic row with an optional
# prefix.
sub diag_sv_idx {
    my ($self, $idx, $prefix)= @_;
    return _diag_row('S', $idx, $self->_diag_rows('slots')->[ $idx - 1 ],
        $prefix);
}

# Format the requested one-based referent diagnostic row with an optional
# prefix.
sub diag_ref_idx {
    my ($self, $idx, $prefix)= @_;
    return _diag_row('R', $idx, $self->_diag_rows('references')->[ $idx - 1 ],
        $prefix);
}

# PadWalker supplies names; the native DumpLex entry point handles capture,
# contexts, and dumping. XS frames do not add a Perl caller level here.
sub _xs_lexical_names {
    my %pad_vars;
    for my $pad (PadWalker::peek_my(1), PadWalker::peek_our(1)) {
        while (my ($var, $ref)= each %$pad) {
            $pad_vars{ refaddr($ref) } ||= $var;
        }
    }
    return [
        map {
                   $pad_vars{ refaddr(\$_) }
                || (ref($_) && $pad_vars{ refaddr($_) })
                || undef
        } @_
    ];
}

# Deparse a code reference with catalogue-selected closure names and output
# indentation, falling back to the configured stub on failure.
sub _xs_code_text {
    my ($self, $item, $name, $indent, $class)= @_;
    unless ($self->{style}{deparse}) {
        return $self->{style}{codestub};
    }
    else {    #deparseopts
        my $cv= B::svref_2object($item);

        if (ref($cv->ROOT) =~ /NULL/) {
            my $gv= $cv->GV;
            return "\\&" . $gv->STASH->NAME . "::" . $gv->SAFENAME;
        }

        my $deparser= Data::Dump::Streamer::Deparser->new(
            @{ $self->{style}{deparseopts} });

        my $used= _xs_get_lexicals($item);
        my %targ;
        foreach my $targ (keys %$used) {
            next if $targ =~ /\D/;
            my $addr= refaddr($used->{$targ});
            $targ{$targ}= $self->{lexicals}{a2n}{$addr}
                if $self->{lexicals}{a2n}{$addr};
        }

        # we added this method, its not a normal method. see bottom of file.
        $deparser->dds_usenames(\%targ);

        my $code;
        eval {
            $deparser->init;
            local $deparser->{in_coderef2text}= 1;
            $code= $deparser->indent($deparser->deparse_sub($cv));
        };
        if ($@) {
            warnings::warnif
                "Using CODE stub for $name as B::Deparse failed: $@";
            return $self->{style}{codestub};
        }

        $code =~ s/(\%\{)(\s*\{\}\s*)/$1;$2/g;

        $code= "sub" . ($code =~ /^\s*\(/ ? "" : " ") . $code;
        if ($self->{style}{indent}) {
            $code =~ s/\n/"\n"." " x $indent/meg;
        }

        if ($name =~ s/^\&//) {
            $code =~ s/sub(\s)?/sub $name$1/;
        }
        return $code;
    }
    return;
}

# Reconstruct a format reference, using formatstub when deparsing is disabled
# or no format is found. A deparse exception produces a diagnostic format body.
sub _xs_format_text {

    # from link from [ysth]: http://groups.google.com/groups?selm=laUs8gzkgOlT092yn%40efn.org
    # translate arg (or reference to it) into a B::* object
    my ($self, $item, $name, $indent)= @_;

    if ($self->{style}{deparse}) {
        my $Bobj= B::svref_2object($item);

        # if passed a glob or globref, get the format
        $Bobj= B::GV::FORM($Bobj) if ref $Bobj eq 'B::GV';
        if (ref $Bobj eq 'B::FM') {
            my $format;
            eval {
                my $deparser= Data::Dump::Streamer::Deparser->new();
                $format= $deparser->indent($deparser->deparse_format($Bobj));
            };
            if ($@) {
                warnings::warnif
                    "B::Deparse (v$B::Deparse::VERSION on @{[$^V]}) failed FORMAT ref deparse.\n";
                $format=
                    "B::Deparse (v$B::Deparse::VERSION on @{[$^V]}) failed FORMAT ref deparse.\n.\n";
            }
            my $ind= $self->{style}{indent} ? ' ' x $indent : '';
            $format= "format F =\n$format";
            $format =~ s/^/${ind}# /gm;

            my $end= '_EOF_FORMAT_';
            $end =~ s/T(\d*)_/sprintf "T%02d_",($1||0)+1/e
                while $format =~ /$end/;

            return (
                "do{ local *F; my \$F=<<'$end'; \$F=~s/^\\s+# //mg; eval \$F; die \$F.\$@ if \$@; *F{FORMAT};\n$format\n$end\n$ind}"
            );
        }
    }

    return $self->{style}{formatstub};

}

# Deparse a glob's FORMAT slot into a named format declaration, returning an
# empty string when no format is available.
sub _xs_glob_format_text {
    my ($self, $item, $name)= @_;
    my $obj= B::svref_2object($item);
    $obj= B::GV::FORM($obj) if ref($obj) eq 'B::GV';
    return '' unless ref($obj) eq 'B::FM';
    $name =~ s/^\*(::)?//;
    my $deparser= Data::Dump::Streamer::Deparser->new;
    return
        "format $name =\n"
        . $deparser->indent($deparser->deparse_format($obj)) . "\n";
}

# Apply the configured eclipse-name template while preserving the captured
# variable's sigil.
sub _xs_eclipse_name {
    my ($name, $format, $n)= @_;
    return sprintf "%s" . $format, substr($name, 0, 1),
        $format =~ /^[^%]*%s/
        ? (substr($name, 1), $n)
        : ($n, substr($name, 1));
}

package Data::Dump::Streamer::Deparser;
use B::Deparse;
our @ISA= qw(B::Deparse);
my %cache;

our $VERSION= '3.002';
if ($VERSION ne $Data::Dump::Streamer::VERSION) {
    die
        "Incompatible Data::Dump::Streamer::Deparser v$VERSION vs Data::Dump::Streamer v$Data::Dump::Streamer::VERSION";
}

# Associate pad offsets with catalogue-selected lexical names for this
# deparser instance.
sub dds_usenames {
    my $self= shift;
    my $names= shift;
    $cache{ Data::Dump::Streamer::refaddr $self}= $names;
}

# Return an explicitly assigned closure name, falling back to B::Deparse's
# pad-name lookup.
sub padname {
    my $self= shift;
    my $targ= shift;
    if (    $cache{ Data::Dump::Streamer::refaddr $self}
        and $cache{ Data::Dump::Streamer::refaddr $self}{$targ})
    {
        return $cache{ Data::Dump::Streamer::refaddr $self}{$targ};
    }
    return $self->padname_sv($targ)->PVX;
}

# Remove this deparser's name overrides from the external cache when the
# instance is destroyed.
sub DESTROY {
    my $self= shift;
    delete $cache{ Data::Dump::Streamer::refaddr $self};
}

1;
__END__

=encoding utf8

=head1 NAME

Data::Dump::Streamer - Accurately serialize a data structure as Perl code.

=head1 SYNOPSIS

  use Data::Dump::Streamer;
  use DDS;                           # optionally installed alias

  Dump($x,$y);                       # Prints to STDOUT
  Dump($x,$y)->Out();                #   "          "

  my $o=Data::Dump::Streamer->new(); # Returns a new ...
  my $o=Dump();                      # ... uninitialized object.

  my $o=Dump($x,$y);                 # Returns an initialized object
  my $s=Dump($x,$y)->Out();          #  "  a string of the dumped obj
  my @l=Dump($x,$y);                 #  "  a list of code fragments
  my @l=Dump($x,$y)->Out();          #  "  a list of code fragments

  Dump($x,$y)->To(\*STDERR)->Out();  # Prints to STDERR

  Dump($x,$y)->Names('foo','bar')    # Specify Names
             ->Out();

  Dump($x,$y)->Indent(0)->Out();     # No indent

  Dump($x,$y)->To(\*STDERR)          # Output to STDERR
             ->Indent(0)             # ... no indent
             ->Names('foo','bar')    # ... specify Names
             ->Out();                # Print...

  $o->Data($x,$y);                   # OO form of what Dump($x,$y) does.
  $o->Names('Foo','Names');          #  ...
  $o->Out();                         #  ...

=head1 DESCRIPTION

Given a list of scalars or reference variables, writes out
their contents in perl syntax. The references can also be
objects. The contents of each variable is output using the least
number of Perl statements as convenient, usually only one.
Self-referential structures, closures, and objects are output
correctly.

The return value can be evaled to get back an identical copy
of the original reference structure. In some cases this may
require the use of utility subs that
L<Data::Dump::Streamer|Data::Dump::Streamer> will optionally
export.

This module is very similar in concept to the core module
L<Data::Dumper|Data::Dumper>, with the major differences
being that this module is designed to output to a stream
instead of constructing its output in memory (trading speed
for memory), and that the traversal over the data structure
is effectively breadth first versus the depth first
traversal done by the others.

In fact the data structure is scanned twice, first in
breadth first mode to perform structural analysis, and then
in depth first mode to actually produce the output, but
obeying the depth relationships of the first pass.

=head2 XPerl class objects

On XPerl builds providing the class snapshot helpers, DDS preserves native
C<class> fields as well as the object's ordinary blessed payload. This
includes inherited and role fields, scalar aliases, aggregate sharing,
cycles, weak references, and readonly field values. Class definitions must
already be loaded when the generated code is evaluated. Reconstruction
uses C<builtin::class_object_from_hash> and bypasses constructors and
C<ADJUST> blocks.

Explicit freezer replacements take precedence. DDS resolves field aliases
before attaching class storage, and attaches storage before calling a thaw
method on that object. Temporary field snapshots are scoped inside the
output. C<Terse> uses a C<do> expression when class reconstruction needs
multiple statements. Generated class dumps require XPerl's snapshot helpers
to reconstruct their objects.

=head2 Caveats Dumping Closures (CODE Refs)

As of version 1.11 DDS has had the ability to dump closures properly. This
means that the lexicals that are bound to the closure are dumped along
with the subroutine that uses them. This makes it much easier to debug
code that uses closures and to a certain extent provides a persistency
framework for closure based code. The way this works is that DDS figures
out what all the lexicals are that are bound to CODE refs it is dumping
and then pretends that it had originally been called with all of them as
its arguments, (along with the original arguments as well of course.)

One consequence of the way the dumping process works is that all of the
recreated subroutines will be in the same scope. This of course can lead
to collisions as two subroutines can easily be bound to different
variables that have the same name.

The way that DDS resolves these collisions is that it renames one of the
variables with a special name so that presumably there are no collisions.
However this process is very simplistic with no checks to prevent
collisions with other lexicals or other globals that may be used by other
dumped code.  In some situations it may be necessary to change the default
value of the rename template which may be done by using the C<EclipseName>
method.

Similarly to the problem of colliding lexicals is the problem of colliding
lexicals and globals. DDS pays no attention to globals when dumping
closures which can potentially result in lexicals being declared that will
eclipse their global namesake. There is currently no way around this other
than to avoid accessing a global and a lexical with the same name from the
subs being dumped. An example is

  my $a = sub { $a++ };
  Dump( sub { $a->() } );

which will not be dumped correctly. Generally speaking this kind of thing
is bad practice anyway, so this should probably be viewed as a "feature".
:-)

Generally if the closures being dumped avoid accessing lexicals and
globals with the same name from out of scope and that all of the CODE
being dumped avoids vars with the C<EclipseName> in their names the dumps
should be valid and should eval back into existence properly.

Note that the behaviour of dumping closures is subject to change in future
versions as its possible that I will put some additional effort into more
sophisticated ways of avoiding name collisions in the dump.

=head1 USAGE

While Data::Dump::Streamer is at heart an object oriented module, it is
expected (based on experience with using L<Data::Dumper|Data::Dumper>)
that the common case will not exploit these features. Nevertheless the
method based approach is convenient and accordingly a compromise hybrid
approach has been provided via the C<Dump()> subroutine. Such as

   Dump($foo);
   $as_string= Dump($foo)->Out();

All attribute methods are designed to be chained together.  This means
that when used as set attribute (called with arguments) they return the
object they were called against. When used as get attributes (called
without arguments) they return the value of the attribute.

From an OO point of view the key methods are the C<Data()> and C<Out()>
methods. These correspond to the breadth first and depth first traversal,
and need to be called in this order. Some attributes I<must> be set prior
to the C<Data()> phase and some need only be set before the C<Out()>
phase.

Attributes once set last the lifetime of the object, unless explicitly
reset.

=head2 Controlling Object Representation

This module provides hooks to allow objects to override how they are
represented. The basic idea is that a subroutine (or method) is provided
which is responsible for the override. The return of the method governs
how the object will be represented when dumped, and how it will be
restored. The basic calling convention is

    my ( $proxy, $thaw, $postop )= $callback->($obj);
    #or                          = $obj->$method();

The L<C<Freezer()>|/Freezer> method controls what methods to use as a default method
and also allows per class overrides. When dumping an object of a given
class the first time it tries to execute the class specific handler if
it is specified, then the user specific generic handler if its been
specified and then "DDS_freeze". This means that class authors can
implement a C<DDS_freeze()> method and their objects will automatically
be serialized as necessary. B<Note> that if either the class specific or
generic handler is defined but false C<DDS_freeze()> will not be used
even if it is present.

The interface of the L<C<Freezer()>|/Freezer> handler in detail is as follows:

=over 4

=item B<C<$obj>>

The object being dumped.

=item B<C<$proxy>>

This is what will be dumped instead of C<$obj>. It may be one of
the following values:

=over 8

=item I<C<undef>> (first time only)

On the first time a serialization hook is called in a dump it may return
undef or the empty list to indicate that it shouldn't be used again for
this class during this pass. Any other time undef is treated the same
as false.

=item I<FALSE value>

A false value for C<$proxy> is taken to mean that it should be ignored.
Its like saying IgnoreClass(ref($obj)); B<Note> that undef has a special
meaning when the callback is called the first time.

=item I<A Reference>

A reference that will be dumped instead of the object.

=item I<Perl Code>

A string that is to be treated as code and inserted directly into the
dump stream as a proxy for the original. Note that the code must be
able to execute inline or in other words must evaluate to a perl EXPR.
Use C<do{}> to wrap multistatement code.

=back

=item B<C<$thaw>>

This values is used to allow extra control over how the object will be
recreated when dumped. It is used for converting the C<$proxy> representation
into the real thing. It is only relevant when C<$proxy> is a reference.

=over 8

=item I<FALSE value>

Indicates no thaw action is to be included for this object.

=item I<Sub or Method Name>

A string matching C<< /^(->)?((?:\w*::)\w+)(\(\))?$/ >> in which case it
is taken as a sub name when the string ends in () and a method name
when the string doesn't. If the C<< -> >> is present then the sub or method
is called inline. If it is not then the sub or method is called
after the main dump.

=item I<Perl Code>

Any other string, in which case the result will be taken as code
which will be emitted after the main dump. It will be wrapped
in a for loop that aliases C<$_> to the variable in question.

=back

=item B<C<$postdump>>

This is the similar to C<$thaw> but is called in process instead
of being emitted as part of the dump. Any return is ignored.
It is only relevant when C<$proxy> is a reference.

=over 8

=item I<FALSE value>

No postdump action is to occur.

=item I<Code Reference>

The code ref will be called after serialization is complete
with the original object as the argument. Hooks run after the graph and
its reconstruction fixups have been serialized, once per original object
per C<Out()> call. Distinct objects sharing a proxy each receive their
own hook; chained proxies retain each original object's hook.

=item I<Method Name>

The method will be called after serialization is complete

=back

=back

An example DDS_freeze method is one I had to put together for an object
which contained a key whose value was a ref to an array tied to the value
of another key. Dumping this got crazy, so I wanted to suppress dumping
the tied array. I did it this way:

    sub DDS_freeze {
        my $self=shift;
        delete $self->{'tie'};
        return ($self,'->fix_tie','fix_tie');
    }

    sub fix_tie {
        my $self=shift;
        if ( ! $self->{'tie'} ) {
            $self->{str}="" unless defined $self->{str};
            tie my @a, 'Tie::Array::PackedC', $self->{str};
            $self->{'tie'} = \@a;
        }
        return $self;
    }

The C<$postop> means the object is relatively unaffected after the
dump, the C<$thaw> says that we should also include the method
inline as we dump. An example dump of an object like this might be

   $Foo1=bless({ str=>'' },'Foo')->fix_tie();

Wheras if we omit the C<< -> >> then we would get:

    $Foo1=bless({ str=>'' },'Foo');
    $Foo1->fix_tie();

In our example it wouldn't actually make a difference, but the former
style can be nicer to read if the object is embedded in another.
However the non arrow notation is slightly more dangerous, in that
its possible that the internals of the object will not be fully linked
when the method is evaluated. The second form guarantees that the object
will be fully linked when the method is evaluated.

See L<Controlling Hash Traversal and Display Order> for a different way
to control the representation of hash based objects.

=head2 Controlling Hash Traversal and Display Order

When dumping a hash you may control the order the keys will be output
and which keys will be included. The basic idea is to specify a subroutine
which takes a hash as an argument and returns a reference to an array
containing the keys to be dumped.

You can use the L<KeyOrder()|/KeyOrder TYPE_OR_OBJ> routine or the L<SortKeys()|/SortKeys> routine to
specify the sorter to be used.

The routine will be called in the following way:

   ( $key_array, $thaw ) = $sorter->($hash,($pass=0),$addr,$class);
   ( $key_array,)        = $sorter->($hash,($pass=1),$addr,$class);

C<$hash> is the hash to be dumped, C<$addr> is the refaddr() of the
C<$hash>, and C<$class> will be set if the hash has been blessed.

When C<$pass> is 0 the C<$thaw> variable may be supplied as well as the
keyorder. If it is defined then it specifies what thaw action to perform
after dumping the hash. See L<C<$thaw>|/$thaw> in L<Controlling Object
Representation> for details as to how it works.  This allows an object
to define those keys needed to recreate itself properly, and a followup
hook to recreate the rest.

B<Note> that if a L<Freezer()|/Freezer> method is defined and returns
a L<C<$thaw>|/$thaw> then the L<C<$thaw>|/$thaw> returned by the sorter
will override it.

=head2 Controlling Array Presentation and Run Length Encoding

By default Data::Dump::Streamer will "run length encode" array values.
This means that when an array value is simple (ie, its not referenced and
does contain a reference) and is repeated multiple times the output will
be single a list multiplier statement, and not each item output
separately. Thus: L<C<Dump([0,0,0,0])>|/Dump> will be output something like

   $ARRAY1 = [ (0) x 4 ];

This is particularly useful when dealing with large arrays that are only
partly filled, and when accidentally the array has been made very large,
such as with the improper use of pseudo-hash notation.

To disable this feature you may set the L<Rle()|/Rle> property to FALSE, by
default it is enabled and set to TRUE.

=head2 Installing I<DDS> as a package alias

Its possible to have an alias to Data::Dump::Streamer created and
installed for easier usage in one liners and short scripts.
Data::Dump::Streamer is a bit long to type sometimes. However because this
technically means polluting the root level namespace, and having it listed
on CPAN, I have elected to have the installer not install it by default.
If you wish it to be installed you must explicitly state so when
Makefile.PL is run:

  perl Makefile.PL DDS [Other MakeMaker options]

Then a normal 'make test, make install' invocation will install DDS.

Using DDS is identical to Data::Dump::Streamer.

=head2 use-time package aliasing

You can also specify an alias at use-time, then use that alias in the rest
of your program, thus avoiding the permanent (but modest) namespace
pollution of the previous method.

  use Data::Dumper::Streamer as => 'DDS';

  # or if you prefer
  use Data::Dumper::Streamer;
  import Data::Dumper::Streamer as => 'DDS';

You can use any alias you like, but that doesn't mean you should.. Folks
doing as => 'DBI' will be mercilessly ridiculed.

=head2 Interpreter and engine requirements

Perl 5.12 or newer and a C compiler are required.
Both graph analysis and
Perl source emission run in XS. Object construction, options, dumping entry points, and callback dispatch
also run in XS. Perl supplies loading and export glue, B::Deparse and
PadWalker integration, compression helpers, and developer diagnostics.

The analyzer records candidate identities in breadth-first order. The
emitter uses a heap frame stack and rejects traversal depths above 16384
with an exception. Scalar and referent visits each contribute to depth.
This permits approximately 8192 nested containers. The previous Perl
engine had no explicit traversal-depth limit.
Weak references are weakened after reconstruction fixups finish.

Captured roots remain live variables. Replacing a root is detected before
output. Do not modify the graph while a dump is running, including from
callbacks. Call C<Data()> again after changing sharing or moving descendant
locations, so canonical names reflect the new graph. Handling of structural
changes without reanalysis is best effort; correct reconstruction is not
guaranteed.

The catalogue stores addresses as lookup keys and never dereferences them
to recover input values. Analysis does not attach weak references or magic
to tracked values. Callback handling retains values needed by active
traversal frames and pending work; it does not retain values by scanning
the catalogue.

Unicode scalar values retain their UTF-8 flag, including ASCII-only,
Latin-1, and empty values. Dumps may use C<\N{U+...}> escapes to force
Unicode literals.

Dumper objects are excluded from ithread cloning. Create a new dumper in
each child interpreter; native engine state belongs to its interpreter.
This differs from the previous Perl implementation, whose objects could
be cloned.

=head2 PadWalker support

If PadWalker 1.0 is installed you can use DumpLex() to try to
automatically determine the names of the vars being dumped. As
long as the vars being dumped have my or our declarations in scope
the vars will be correctly named. Closure pad values are inspected directly in XS; PadWalker is optional.

=head1 INTERFACE

=head2 Data::Dumper Compatibility

For drop in compatibility with the Dumper() usage of Data::Dumper, you may
request that the L<Dumper()|/Dumper> method is exported. It will not be exported by
default. In addition the standard Data::Dumper::Dumper() may be exported
on request as C<DDumper>. If you provide the tag C<:Dumper> then both will
be exported.

=over 4

=item Dumper

=item Dumper LIST

A synonym for scalar Dump(LIST)->Out for usage compatibility with
L<Data::Dumper|Data::Dumper>

=item DDumper

=item DDumper LIST

A secondary export of the actual L<Data::Dumper::Dumper|Data::Dumper>
subroutine.

=back

=head2 Constructors

=over 4

=item new

Creates a new Data::Dump::Streamer object. Currently takes no
arguments and simply returns the new object with a default style
configuration.

See C<Dump()> for a better way to do things.

=cut
=item Dump

=item Dump VALUES

Smart non method based constructor.

This routine behaves very differently depending on the context it is
called in and whether arguments are provided.

If called with no arguments it is exactly equivalent to calling

  Data::Dump::Streamer->new()

which means it returns an object reference.

If called with arguments and in scalar context it is equivalent to calling

  Data::Dump::Streamer->new()->Data(@vals)

except that the actual depth first traversal is I<delayed> until C<Out()>
is called.  This means that options that must be provided before the
C<Data()> phase can be provided after the call to C<Dump()>.  Again, it
returns a object reference.

If called with arguments and in void or list context it is equivelent to
calling

  Data::Dump::Streamer->new()->Data(@vals)->Out()

The reason this is true in list context is to make
C<print Dump(...),"\n";> do the right thing. And also that combined with
method chaining options can be added or removed as required quite easily
and naturally.

So to put it short:

  my $obj=Dump($x,$y);         # Returns an object
  my $str=Dump($x,$y)->Out();  # Returns a string of the dump.
  my @code=Dump($x,$y);        # Returns a list of the dump.

  Dump($x,$y);                 # prints the dump.
  print Dump($x,$y);           # prints the dump.

It should be noted that the setting of C<$\> will affect the behaviour of
both of

  Dump($x,$y);
  print Dump($x,$y);

but it will not affect the behaviour of

  print scalar Dump($x,$y);

B<Note> As of 1.11 Dump also works as a method, with identical properties
as when called as a subroutine, with the exception that when called with
no arguments it is a synonym for C<Out()>. Thus

  $obj->Dump($foo)->Names('foo')->Out();

will work fine, as will the odd looking:

  $obj->Dump($foo)->Names('foo')->Dump();

which are both the same as

  $obj->Names('foo')->Data($foo)->Out();

Hopefully this should make method use more or less DWIM.

=cut
=item DumpLex VALUES

DumpLex is similar to Dump except it will try to automatically determine
the names to use for the variables being dumped by using PadWalker to
have a poke around the calling lexical scope to see what is declared. If
a name for a var can't be found then it will be named according to the
normal scheme. When PadWalker isn't installed this is just a wrapper for
L<Dump()|/Dump>.

Thanks to Ovid for the idea of this. See L<Data::Dumper::Simple> for a
similar wrapper around L<Data::Dumper>.

=cut
=item DumpVars PAIRS

This is wrapper around L<Dump()|/Dump> which expect to receive
a list of name=>value pairs instead of a list of values.
Otherwise behaves like L<Dump()|/Dump>. Note that names starting
with a '-' are treated the same as those starting with '*' when
passed to L<Names()|/Names>.

=cut
=back

=head2 Methods

=over 4

=item Data

=item Data LIST

Analyzes a list of variables in breadth first order.

If called with arguments then the internal object state is reset before
scanning the list of arguments provided.

If called with no arguments then whatever arguments were provided to C<Dump()>
will be scanned.

Returns $self.

=cut
=item Out

=item Out VALUES

Prints out a set of values to the appropriate location. If provided a list
of values then the values are first scanned with C<Data()> and then
printed, if called with no values then whatever was scanned last with
C<Data()> or C<Dump()> is printed.

If the C<To()> attribute was provided then will dump to whatever object
was specified there (any object, including filehandles that accept the
print() method), and will always return $self.

If the C<To()> attribute was not provided then will use an internal
printing object, returning either a list or scalar or printing to STDOUT
in void context.

This routine is virtually always called without arguments as the last
method in the method chain.

 Dump->Arguments(1)->Out(@vars);
 $obj->Data(@vars)->Out();
 Dump(@vars)->Out;
 Data::Dump::Streamer->Out(@vars);

All should DWIM.

=cut
=item Names

=item Names LIST

=item Names ARRAYREF

Takes a list of strings or a reference to an array of strings to use for
var names for the objects dumped. The names may be prefixed by a *
indicating the variable is to be dumped as its dereferenced type if it is
an array, hash or code ref. Otherwise the star is ignored. Other sigils
may be prefixed but they will be silently converted to *'s.

If no names are provided then names are generated automatically based on
the type of object being dumped, with abbreviations applied to compound
class names.

If called with arguments then returns the object itself, otherwise in list
context returns the list of names in use, or in scalar context a reference
or undef. In void context with no arguments the names are cleared.

B<NOTE:>
Must be called before C<Data()> is called.

If you wish to have no names, use L<Terse>.

=cut
=item Terse

=item Terse BOOL

When true, no variable names will be created.  Data will be dumped as
anonymous references or values.

    Dump([])->Out;              # $ARRAY1 = []
    Dump([])->Terse(1)->Out;    # []

=cut
=for UEDIT
sub Purity {}

=item Purity

=item Purity BOOL

This option can be used to set the level of purity in the output. It
defaults to TRUE, which results in the module doing its best to ensure
that the resulting dump when eval()ed is precisely the same as the input.
However, at times such as debugging this can be tedious, resulting in
extremely long dumps with many "fix" statements involved.  By setting
Purity to FALSE the resulting output won't necessarily be legal Perl, but
it will be more legible. In this mode the output is broadly similar to
that of the default setting of Data::Dumper (Purity(0)). When set to TRUE
the behaviour is likewise similar to Data::Dumper in Purity(1) but more
accurate.

When Purity() is set to FALSE aliases will be output with a function call
wrapper of 'alias_to' whose argument will be the value the item is an
alias to. This wrapper does nothing, and is only there as a visual cue.
Likewise, 'make_ro' will be output when the value was readonly, and again
the effect is cosmetic only.

=item To

=item To STREAMER

Specifies the object to print to. Data::Dump::Streamer can stream its
output to any object supporting the print method. This is primarily meant
for streaming to a filehandle, however any object that supports the method
will do.

If a filehandle is specified then it is used until it is explicitly
changed, or the object is destroyed.

=cut
=for UEDIT
sub Declare     {}

=item Declare

=item Declare BOOL

If Declare is True then each object is dumped with 'my' declarations
included, and all rules that follow are obeyed. (Ie, not referencing an
undeclared variable). If Declare is False then all objects are expected to
be previously defined and references to top level objects can be made at
any time.

Defaults to False.

=cut
=item Indent

=item Indent INT

If Indent is True then data is output in an indented and fairly neat
fashion. If the value is 2 then hash key/value pairs and array values each
on their own line. If the value is 1 then a "smart" indenting mode is
activated where multiple key/value or values may be printed to the same
line. The heuristics for this mode are still experimental so it may
occasional not indent very nicely.

Default is Indent(2)

If indent is False then no indentation is done, and all optional whitespace.
is omitted. See <OptSpace()|/OptSpace> for more details.

Defaults to True.

Newlines are appended to each statement regardless of this value.

=for UEDIT
sub IndentKeys      {}

=item Indentkeys

=item Indentkeys BOOL

If Indent() and Indentkeys are True then hashes with more than one key
value pair are dumped such that the keys and values line up. Note however
this means each key has to be quoted twice. Not advised for very large
data structures. Additional logic may enhance this feature soon.

Defaults to True.

B<NOTE:>
Must be set before C<Data()> is called.

=for UEDIT
sub OptSpace      {}

=item OptSpace

=item OptSpace STR

Normally DDS emits a lot of whitespace in between tokens that it
emits. Using this method you can control how much whitespace it
will emit, or even if some other string should be used.

If Indent is set to 0 then this value is automatically set to
the empty string. When Indent is set back to a non zero value
the old value will be restored if it has not been changed from
the empty string in the intervening time.

=for UEDIT
sub Keyorder      {}

=item KeyOrder TYPE_OR_OBJ

=item KeyOrder TYPE_OR_OBJ, VALUE

Sets or returns the key order to for use for a given type or object.

TYPE_OR_OBJ may be a string representing a class, or "" for representing
unblessed objects, or it maybe a reference to a hash.

VALUE may be a string representing one of built in sort mechanisms, or
it may be a reference to a subroutine, or a method name if TYPE_OR_OBJ
is not an object.

The built in sort mechanisms are 'aphabetical'/'lexical', 'numeric',
'smart'/'intelligent' and 'each'.

If VALUE is omitted returns the current value for the given type.

If TYPE_OR_OBJ is omitted or FALSE it defaults to "" which represents
unblessed hashes.

See L<"Controlling Hash Traversal and Display Order"> for more details.

=item SortKeys

=item SortKeys VALUE

This is a wrapper for KeyOrder. It allows only the generic hash
sort order to be specified a little more elegantly than via KeyOrder().
It is syntactically equivalent to

  $self->KeyOrder( "", @_ );

=for UEDIT
sub Verbose      {}

=item Verbose

=item Verbose BOOL

If Verbose is True then when references that cannot be resolved in a
single statement are encountered the reference is substituted for a
descriptive tag saying what type of forward reference it is, and to what
is being referenced. The type is provided through a prefix, "R:" for
reference, and "A:" for alias, "V:" for a value and then the name of the
var in a string. Automatically generated var names are also reduced to
the shortest possible unique abbreviation, with some tricks thrown in
for Long::Class::Names::Like::This (which would abbreviate most likely
to LCNLT1)

If Verbose if False then a simple placeholder saying 'A' or 'R' is
provided. (In most situations perl requires a placeholder, and as such
one is always provided, even if technically it could be omitted.)

This setting does not change the followup statements that fix up the
structure, and does not result in a loss of accuracy, it just makes it a
little harder to read. OTOH, it means dumps can be quite a bit smaller
and less noisy.

Defaults to True.

B<NOTE:>
Must be set before C<Data()> is called.

=for UEDIT
sub DumpGlob {}

=item DumpGlob

=item DumpGlob BOOL

If True then globs will be followed and fully defined, otherwise the globs
will still be referenced but their current value will not be set.

Defaults to True

B<NOTE:>
Must be set before C<Data()> is called.

=for UEDIT
sub Deparse {}

=item Deparse

=item Deparse BOOL

If True then CODE refs will be deparsed use L<B::Deparse|B::Deparse> and
included in the dump. If it is False the a stub subroutine reference will
be output as per the setting of C<CodeStub()>.

Caveat Emptor, dumping subroutine references is hardly a secure act, and
it is provided here only for convenience.

Note using this routine is at your own risk as of DDS 1.11, how it
interacts with the newer advanced closure dumping process is undefined.

=for UEDIT
sub EclipseName {}

=item EclipseName

=item EclipseName SPRINTF_FORMAT

When necessary DDS will rename vars output during deparsing with this
value. It is a sprintf format string that should contain only and both of
the "%s" and a "%d" formats in any order along with whatever other literal
text you want in the name. No checks are performed on the validity of this
value so be careful. It defaults to

  "%s_eclipse_%d"

where the "%s" represents the name of the var being eclipsed, and the "%d"
a counter to ensure all such mappings are unique.

=for UEDIT
sub DeparseOpts {}

=item DeparseOpts

=item DeparseOpts LIST

=item DeparseOpts ARRAY

If Deparse is True then these options will be passed to B::Deparse->new()
when dumping a CODE ref. If passed a list of scalars the list is used as
the arguments. If passed an array reference then this array is assumed to
contain a list of arguments. If no arguments are provided returns a an
array ref of arguments in scalar context, and a list of arguments in list
context.

Note using this routine is at your own risk as of DDS 1.11, how it
interacts with the newer advanced closure dumping process is undefined.

=for UEDIT
sub CodeStub {}

=item CodeStub

=item CodeStub STRING

If Deparse is False then this string will be used in place of CODE
references. Its the users responsibility to make sure its compilable and
blessable.

Defaults to 'sub { Carp::confess "Dumped code stub!" }'

=for UEDIT
sub FormatStub {}

=item FormatStub

=item FormatStub STRING

If Deparse is False then this string will be used in place of FORMAT
references. Its the users responsibility to make sure its compilable and
blessable.

Defaults to 'do{ local *F; eval "format F =\nFormat Stub\n.\n"; *F{FORMAT} }'

=for UEDIT
sub DeparseGlob {}

=item DeparseGlob

=item DeparseGlob BOOL

If Deparse is TRUE then this style attribute will determine if subroutines
and FORMAT's contained in globs that are dumped will be deparsed or not.

Defaults to True.

=for UEDIT
sub DualVars {}
sub Dualvars {}

=item Dualvars

=item Dualvars BOOL

=item Dualvars

=item Dualvars BOOL

If TRUE then dualvar checking will occur and the required statements
emitted to recreate dualvars when they are encountered, otherwise items
will be dumped in their stringified form always. It defaults to TRUE.

=for UEDIT
sub Rle {}
sub RLE {}

=item Rle

=item Rle BOOL

=item RLE

=item RLE BOOL

If True then arrays will be run length encoded using the C<x> operator.
What this means is that if an array contains repeated elements then
instead of outputting each and every one a list multiplier will be output.
This means that considerably less space is taken to dump redundant data.

=item Freezer

=item Freezer ACTION

=item Freezer CLASS, ACTION

This method can be used to override the DDS_freeze hook for a
specific class. If CLASS is omitted then the ACTION applies to
all blessed object.

If ACTION is false it indicates that the given CLASS should not
have any serilization hooks called.

If ACTION is a string then it is taken to be the method name that
will be executed to freeze the object. CLASS->can(METHOD) must return
true or the setting will be ignored.

If ACTION is a code ref it is executed with the object as the argument.

When called with no arguments returns in scalar context the generic
serialization method (defaults to 'DDS_freeze'), in list context
returns the generic serialization method followed by a list of pairs
of Classname=>ACTION.

If the action executes a sub or method it is expected to return
a list of three values:

   ( $proxy, $thaw, $postdump )=$obj->DDS_Freeze();

See L<Controlling Object Representation> for more details.

B<NOTE:>
Must be set before C<Data()> is called.

=cut
=item Ignore

=item Ignore OBJ_OR_CLASS

=item Ignore OBJ_OR_CLASS, BOOL

Allows a given object or class to be ignored, and replaced with
a string containing the name of the item ignored.

If called with no args returns a list of items ignored (using the refaddr
to represent objects). If called with a single argument returns whether
that argument is ignored. If called with more than one arguments then
expects a list of pairs of object => is_ignored.

Returns $self when setting.

B<NOTE:>
Must be set before C<Data()> is called.

=cut
=for UEDIT
sub Compress {}

=item Compress

=item Compress SIZE

Controls compression of string values (not keys). If this value
is nonzero and a string to be dumped is longer than its value then
the L<Compressor()|/Compressor> if defined is used to compress
the string.  Setting size to -1 will cause all strings to be
processed, setting size to 0 will cause no strings to be processed.

=for UEDIT
sub Compressor {}

=item Compressor

=item Compressor CODE

This attribute is used to control the compression of strings.
It is expected to be a reference to a subroutine with the following
interface:

  my $prelude_code=$compressor->(); # no arguments.
  my $code=$compressor->('string'); # string argument

The sub will be called with no arguments at the beginning of the
dump to allow any require statements or similar to be added. During
the dump the sub will be called with a single argument when
compression is required. The code returned in this case is expected
to be an EXPR that will evaluate back to the original string.

By default DDS will use L<Compress::Zlib> in conjunction with
L<MIME::Base64> to do compression and encoding, and exposes the
'usqz' subroutine for handling the decoding and decompression.

The default compressor supports byte strings and Unicode strings, preserving
both their characters and their UTF-8 flag without changing the input.
Compressed byte-string dumps from older releases remain readable.

The abbreviated name was chosen as when using the default compressor
every string will be represented by a string like

   usqz('....')

Meaning that eight characters are required without considering the
data itself. Likewise Base64 was chosen because it is a representation
that is high-bit safe, compact and easy to quote. Escaped strings are
much less efficient for storing binary data.

=cut
=back

=head2 Reading the Output

As mentioned in L<Verbose> there is a notation used to make understanding
the output easier. However at first glance it can probably be a bit
confusing. Take the following example:

    my $x=1;
    my $y=[];
    my $array=sub{\@_ }->( $x,$x,$y );
    push @$array,$y,1;
    unshift @$array,\$array->[-1];
    Dump($array);

Which prints (without the comments of course):

    $ARRAY1 = [
                'R: $ARRAY1->[5]',        # resolved by fix 1
                1,
                'A: $ARRAY1->[1]',        # resolved by fix 2
                [],
                'V: $ARRAY1->[3]',        # resolved by fix 3
                1
              ];
    $ARRAY1->[0] = \$ARRAY1->[5];         # fix 1
    alias_av(@$ARRAY1, 2, $ARRAY1->[1]);  # fix 2
    $ARRAY1->[4] = $ARRAY1->[3];          # fix 3

The first entry, C<< 'R: $ARRAY1->[5]' >> indicates that this slot in the
array holds a reference to the currently undefined C<< $ARRAY1->[5] >>,
and as such the value will have to be provided later in what the author
calls 'fix' statements. The third entry C<< 'A: $ARRAY1->[1]' >> indicates
that is element of the array is in fact the exact same scalar as exists in
C<< $ARRAY1->[1] >>, or is in other words, an alias to that variable.
Again, this cannot be expressed in a single statement and so generates
another, different, fix statement. The fifth entry C<< 'V: $ARRAY1->[3]' >>
indicates that this slots holds a value (actually a reference value)
that is identical to one elsewhere, but is currently undefined.  In this
case it is because the value it needs is the reference returned by the
anonymous array constructor in the fourth element (C<< $ARRAY1->[3] >>).
Again this results in yet another different fix statement.  If Verbose()
is off then only a 'R' 'A' or 'V' tag is emitted as a marker of some form
is necessary.

All of this specialized behaviour can be bypassed by setting Purity() to
FALSE, in which case the output will look very similar to what
Data::Dumper outputs in low Purity setting.

In a later version I'll try to expand this section with more examples.

=head2 A Note About Speed

Data::Dumper is much faster than this module for many things. However IMO
it is less readable, and definitely less accurate. YMMV.

=head1 EXPORT

By default exports the Dump() command. Or may export on request the same
command as Stream(). A Data::Dumper::Dumper compatibility routine is
provided via requesting Dumper and access to the real Data::Dumper::Dumper
routine is provided via DDumper. The later two are exported together with
the :Dumper tag.

Additionally there are a set of internally used routines that are exposed.
These are mostly direct copies of routines from Array::RefElem,
Lexical::Alias and Scalar::Util, however some where marked have had their
semantics slightly changed, returning defined but false instead of undef
for negative checks, or throwing errors on failure.

The following XS subs (and tagnames for various groupings) are exportable
on request.

  :Dumper
        Dumper
        DDumper

  :undump          # Collection of routines needed to undump something
        alias_av              # aliases a given array value to a scalar
        alias_hv              # aliases a given hashes value to a scalar
        alias_ref             # aliases a scalar to another scalar
        make_ro               # makes a scalar read only
        lock_keys             # pass through to Hash::Util::lock_keys
        lock_keys_plus        # like lock_keys, but adds keys to those present
        lock_ref_keys         # like lock_keys but operates on a hashref
        lock_ref_keys_plus    # like lock_keys_plus but operates on a hashref
        dualvar               # make a variable with different string/numeric
                              # representation
        alias_to              # pretend to return an alias, used in low
                              # purity mode to indicate a value is actually
                              # an alias to something else.

  :alias           # all croak on failure
     alias_av(@Array,$index,$var);
     alias_hv(%hash,$key,$var);
     alias_ref(\$var1,\$var2);
     push_alias(@array,$var);

  :util
     blessed($var)           #undef or a class name.
     isweak($var)            #returns true if $var contains a weakref
     reftype($var)           #the underlying type or false but defined.
     refaddr($var)           #a references address
     refcount($var)          #the number of times a reference is referenced
     sv_refcount($var)       #the number of times a scalar is referenced.
     weak_refcount($var)     #the number of weakrefs to an object.
                             #sv_refcount($var)-weak_refcount($var) is the true
                             #SvREFCOUNT() of the var.
     looks_like_number($var) #if perl will think this is a number.

     regex($var)     # In list context returns the pattern and the modifiers,
                     # in scalar context returns the pattern in (?msix:) form.
                     # If not a regex returns false.
     readonly($var)  # returns whether the $var is readonly
     weaken($var)    # cause the reference contained in var to become weak.
     make_ro($var)   # causes $var to become readonly, returns the value of $var.
     reftype_or_glob # returns the reftype of a reference, or if its not
                     # a reference but a glob then the globs name
     refaddr_or_glob # similar to reftype_or_glob but returns an address
                     # in the case of a reference.
     globname        # returns an evalable string to represent a glob, or
                     # the empty string if not a glob.
  :all               # (Dump() and Stream() and Dumper() and DDumper()
                     #  and all of the XS)
  :bin               # (not Dump() but all of the rest of the XS)


By default exports only Dump(), DumpLex() and DumpVars(). Tags are
provided for exporting 'all' subroutines, as well as 'bin' (not Dump()),
'util' (only introspection utilities) and 'alias' for the aliasing
utilities. If you need to ensure that you can eval the results (undump)
then use the 'undump' tag.

=head1 BUGS

Code with this many debug statements is certain to have errors. :-)

Please report them with as much of the error output as possible.

Be aware that to a certain extent this module is subject to whimsies of
your local perl. The same code may not produce the same dump on two
different installs and versions. Luckily these don't seem to pop up often.

=head1 AUTHOR AND COPYRIGHT

Yves Orton, yves at cpan org.

Copyright (C) 2003-2005 Yves Orton

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Contains code derived from works by Gisle Aas, Graham Barr, Jeff Pinyan,
Richard Clamp, and Gurusamy Sarathy.

Thanks to Dan Brook, Yitzchak Scott-Thoennes, eric256, Joshua ben
Jore, Jim Cromie, Curtis "Ovid" Poe, Lars Dɪᴇᴄᴋᴏᴡ, and anybody that
I've forgotten for patches, feedback and ideas.

=head1 SEE ALSO (its a crowded space, isn't it!)

L<Data::Dumper>
- the mother of them all

L<Data::Dumper::Simple>
- Auto named vars with source filter interface.

L<Data::Dumper::Names>
- Auto named vars without source filtering.

L<Data::Dumper::EasyOO>
- easy to use wrapper for DD

L<Data::Dump>
- Has cool feature to squeeze data

L<Data::Dump::Streamer>
- The best perl dumper. But I would say that. :-)

L<Data::TreeDumper>
- Non perl output, lots of rendering options

And of course L<www.perlmonks.org> and L<perl> itself.

=cut
