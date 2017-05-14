package Class::CompiledC;

=head1 NAME

Class::CompiledC

=cut

use 5.008007;
use strict;
use warnings;
use Carp;
use base     qw/Attribute::Handlers/;
use Inline;
use Exporter qw/import/;

=head1 VERSION

This document describes version 2.21 of Class::CompiledC,
released Fri Oct 27 23:28:06 CEST 2006 @936 /Internet Time/

=cut

our $VERSION = 2.21;
our %includes;
our %funcs;
our %extfuncs;
our %code;
our %scheduled;
our %types;
our %EXPORT_TAGS;
our @EXPORT_OK;
our $re_ft;
our $re_ft_isa;

sub __circumPrint($$$);
sub __include;
sub __baseref($$);
sub __hashref($);
sub __arrayref($);
sub __coderef($);
sub __fetchSymbolName($);
sub __promoteFieldTypeToMacro($);
sub __parseFieldType;


$re_ft     = qr/^(?:\s*)(int|float|number|string|ref|arrayref|hashref|
                         coderef|object|regexpref|any|uint)(?:\s*)/xi;

$re_ft_isa = qr/^(?:\s*)isa(?:\s*)\((?:\s*)([\w:]*)(?:\s*)\)(?:\s*)/i;

=head1 ABSTRACT

Class::CompiledC -- use C structs for your objects.

=head1 SYNOPSIS

  package Foo;
  use strict;
  use warnings;

  use base qw/Class::CompiledC/;

  sub type     : Field(String);
  sub data     : Field(Hashref);
  sub count    : Field(Int);
  sub callback : Field(Coderef);
  sub size     : Field(Float);
  sub dontcare : Field(Number);
  sub dumper   : Field(Isa(Data::Dumper));
  sub items    : Field(Arrayref);
  sub notsure  : Field(Object);

  my $x;

  $x = Foo->new(-type     => "example",
                -data     => {},
                -count    => 0,
                -callback => sub { print "j p " ^ " a h " ^ " " x 4 while 1},
                -size     => 138.4,
                -dontcare => 12,
                -dumper   => Data::Dumper->new,
                -items    => [qw/coffee cigarettes beer/],
                -notsure  => SomeClass->new
                );




=head1 DESCRIPTION

Note: Documentation is incomplete, partly outdated, of poor style and full of
typos. I need a ghostwriter.

Class::CompiledC creates classes which are based on C structs, it does this by
generating C code and compiling the code when your module is compiled (1). You
can add constraints on the type of the data that can be stored in the instance
variables of your objects by specifiying a C<field type> (i call instance
variables fields because it's shorter). A field without constraints are declared
by using the C<: Field> attribute (2) on a subroutine stub (3) of the name you
would like to have for your field eg. C<sub Foo : Field;> this would generate a
field called 'foo' and it's accesor method, also called 'foo' If you want to add
a constraint to the field just name the type as a parameter for the attribute eg
C<sub foo : Field(Ref)>.

(1) I<(actually, Class::CompiledC utilizes L<Inline> to do the dirty work;
L<Inline> uses L<Inline::C> to do it's job and L<Inline::C> employes your C
compiler to compile the code. This means you need Inline Inline::C and a working
C compiler on the runtime machine.>

(2) I<C<attributes> perl6 calls them traits or properties; see L<attributes> not
to confuse with instance variables (fields) which are sometimes also called
attributes; terms differ from language to language and perlmodules use all of
them with different meanings, very confusing>

(3) I<sub foo; remember ? also called C<forward declaration> see L<perlsub>>


I<for the truly insane.>

  TODO

=head2 Supported Field Types

The following Field types are currently supported by Class::CompiledC

=head3 Any

  sub Foo : Field(Any)

NOOP. Does nothing, is even optimized away at compile time.
You can use it to explicitly declare that you don't care.

=head3 Arrayref

  sub Foo : Field(Arrayref)

Ensures that the field can only hold a reference to an array.
(beside the always legal undefined value).

=head3 Coderef

  sub Foo : Field(Coderef)

Ensures that the field can only hold a reference to some kind of subroutine.
(beside the always legal undefined value).

=head3 Float

  sub Foo : Field(Float)

Ensures that the field can only hold a valid floating point value.
(An int is also a valid floating point value, as is undef).

=head3 Hashref

  sub Foo : Field(Hashref)

Ensures that the field can only hold a reference to a hash.
(beside the always legal undefined value).

=head3 Int

  sub Foo : Field(Int)

Ensures that the field can only hold a valid integer value.
(beside the always legal undefined value).

=head3 Isa

  sub Foo : Field(Isa(Some::Class))

Ensures that the field can only hold a reference to a object of the specified
class, or a subclass of it. (beside the always legal undefined value). (The
relationship is determined the same way as the C<UNIVERSAL->isa> method)

=head3 Number

  sub Foo : Field(Number)

At current this just an alias for the C<Float> type, but that may change.

=head3 Object

  sub Foo : Field(Object)

Ensures that the field can only hold a reference to a object.
(beside the always legal undefined value).


=head3 Ref

  sub Foo : Field(Ref)

Ensures that the field can only hold a reference to something.
(beside the always legal undefined value).

=head3 Regexpref

  sub Foo : Field(Regexpref)

Ensures that the field can only hold a reference to a regular expression object.
(beside the always legal undefined value).

=head3 String

  sub Foo : Field(String)

Ensures that the field can only hold a string value. Even everything could
theoretically expressed as a string, only true string values are legal. (beside
the always legal undefined value).

=head2 Field Types Specification Syntax Note

Field types are case insensitve. If a type expects a parameter, as the C<Isa>
type, then it should be enclosed in parenthises. Whitespace is always ingnored,
around Field types and parameters, if any. Note, however that the field type
Int, spelled in lowercase letters will be misparsed as the `int` operator, so be
careful.

=head2 Additional Features

Currently there are two categories of additional features: those going to stay,
and those going to be relocated into distinct packages.

First the stuff that will stay:

=head3 parseArgs method

Every subclass inherits this method. Its purpose is to ease the use of named
parameters in constructors. It takes a list of key => value pairs. Foreach pair
it calls a method named like the key with value as it only parameter (beside the
object, of course), i.e:

  $obj->parseArgs(foo => [], bar => 'bar is better than foo');

Would result in the following method calls:

  $obj->foo([]);
  $obj->bar('bar is better than foo');

The method also strips a leading dash ('-') from the method name, in case you
prefer named arguments starting with a dash, therefore the following calls are
equivalent :

  $obj->parseArgs(-foo => 123, -bar => 456); # dashed style

  $obj->parseArgs(foo => 123, bar => 456);   # dashless style

  $obj->parseArgs(-foo => 123, bar => 456);  # no style

Since this method needs key => value pairs it will croak if you supply it an odd
number of arguments. I<actually it croaks on an even number of arguments, if you
also count the object. but the check for oddnes is done after the object is
shifted from the argument list>

C<parseArgs> returns the object.

=head3 new method

Every subclass inherits this method, it is merely a wrapper around the real
constructor (which is called 'create'). It first constructs the object (with the
help of the real constructor) and then calls parseArgs on it. This means the
following code is equivalent :

  my $obj = class->new(-foo => 'bar');

  #----

  my $obj = class->create;
  $obj->parseArgs(-foo => 'bar');

Only shorter ;)

=head3 inspect method

This method is created for each subclass. It returns a hashref with the field
names and their types. A short example should clarify what I try to say:

  package SomeClass;
  use base qw/Class::CompiledC/;

  sub foo : Field(Int);
  sub bar : Filed(Hashref);

  #### at same time in some other package:

  use SomeClass;
  use Data::Dumper;

  my $obj = Somelass->new;

  print Dumper($obj->inspect);

  ### prints something like

  $VAR1 = {
                'foo' => 'Int',
                'bar' => 'Hashref',
          }

Be aware that this purely informational. Even you can change the data behind
this reference, nothing will happen. The changes will not persist, if you call
C<inspect> again, the output will be the same. Especially do not expect that you
can change a class on the fly with that hash, this won't work. You should also
know that two calls to inspect will result in two distinct hash references, so
don't try to compare those references. Even the hash those references refer to
is diffrent, if you really want to compare than you have to do a deep compare.

=head3 the C attribute

The C attribute allows you to write a subroutine in C, eg:

  sub add : C(int, int a, int b)
  {q{
        return a + b;
  }}

The return type and the parameters are specified in the attribute, and
the function body is in the subroutine body. Therefore the resulting C code
looks like:

  int add(int a, int b)
  {
          return a + b;
  }

You may have noticed that the actual body of the C function is whatever the
(Perl subroutine returned, so this code :

  sub getCompileTime(int, )
  {
          my $time = time;
          my $code = "return $time";

          return $code;
  }

will result in this C code :

  int getCompileTime()
  {
          return 1162140297;
  }

The time value, is subject of change, of course. If you wonder what perl can do
with c intergers, all (with a few exceptions) C code is subject to XS-fication
by the L<Inline::C module>, which handles this sort of crap behind the scenes.
You should have a look at L<Inline::C> for bugs and deficiencies, but do
yourself and the author of Inline a favor and not report any bugs that might
showup in conjunction with Class::CompiledC to the author of Inline, report them
to me. I'm cheating with Inline, and most problems you might encounter wouldn't
show up by using Inline correctly.

Be advised that you have full access to perls internals within your C code and
to take any usage out of this feature you should read the following documents:

=over

=item L<perlxstut>

Perl XS tutorial

=item L<perlxs>

Perl XS application programming interface

=item L<perlclib>

Internal replacements for standard C library functions

=item L<perlguts>

Perl internal functions for those doing extensions

=item L<perlcall>

Perl calling conventions from C

=back


XXX The stuff that will be outsourced is not yet documented.

Of course, you should also know how to code in C. One final notice: This feature
has been proven as an endless source of fun and coredumps.

=head2 Methods

The methods listed here are not considered part of the public api, and should
not be used in any way, unless you know better.

Class::CompiledC defines the following methods:

=cut

=head3 __scheduled

  __scheduled SELF, PACKAGE
  Type: class method

the __scheduled method checks if package has already been scheduled for
compilation. returns a a true value if so, a false value otherwise.

=cut

sub __scheduled
{
        return exists $scheduled{$_[1]} && $scheduled{$_[1]};
}

=head3 __schedule

  __scheduled SELF, PACKAGE
  Type: class method

the __schedule method schedules PACKAGE for compilation.
Note.: try not to schedule a package for compilation more than once,
you can test for a package beeing scheduled with the C<__scheduled> method,
or you can use the C<__scheduleIfNeeded> which ensures that a package doesn't
get scheduled multiple times.

=cut

sub __schedule
{
        my $self;
        my $package;

        $self    = shift || croak "no package supplied";
        $package = shift || croak "no target package supplied";

        $scheduled{$package} = 1;

        eval qq
        {
                package $package;
                {
                        no warnings 'void';
                        CHECK
                        {
                                $self->__doIt('$package');
                        }
                }
        };

        croak $@ if $@;


}

=head3 __scheduleIfNeeded

  __scheduleIfNeeded SELF, PACKAGE
  Type: class method

the __scheduleIfNeeded method schedules PACKAGE for compilation unless it
already has been scheduled. Uses C<__scheduled> to determine 'scheduledness'
and C<__schedule> to do the hard work.

=cut

sub __scheduleIfNeeded
{
        $_[0]->__scheduled($_[1]) || $_[0]->__schedule($_[1]);
}

=head3 __addCode

  __addCode SELF, PACKAGE, CODE, TYPE
  Type: class method

Add code CODE for compilation of type TYPE to PACKAGE.
Currently supported types are C<base> (code for fields) and
C<ext> (code for addional c functions). Before compilation
C<base> and C<ext> coe is merged, C<base> first, so that C<ext> code
can access functions and macros from the base code.

=cut

sub __addCode
{
        my $code;
        my $type;
        my $package;
        my $self;

        $self    =  shift      || croak "no package supplied";
        $package =  shift      || croak "no target package supplied";
        $code    =  shift      || croak "no code supplied";
        $type    =  shift      || croak "no type supplied";
        $type    =~ /base|ext/ || croak "bad type supplied";

        $code{$package}         = {} unless __hashref $code{$package};
        $code{$package}{$type}  = '' unless $code{$package}{$type};
        $code{$package}{$type} .= $code;

        return;
}

=head3 __compile

  __compile SELF, PACKAGE
  Type: class method

Compiles the code for PACKAGE.

=cut

sub __compile
{
        my $self;
        my $package;
        my $code;
        my $sub;

        $self    = shift || croak "no package supplied";
        $package = shift || croak "no target package supplied";

        $code    = '';
        $code   .=  __include foreach (@{$includes{$package}});
        $code   .= $code{$package}{base} if $code{$package}{base};
        $code   .= $code{$package}{ext}  if $code{$package}{ext};


        #dark magic see the comment in __doIt for an explanation

        @_ = ('Inline', 'C', $code, 'NAME', $package,
              'BUILD_NOISY', 0, 'CLEAN_AFTER_BUILD', 0,);

        $sub = Inline->can('bind');
        goto &$sub;
}

=head3 __traverseISA

  __traverseISA SELF, PACKAGE, HASHREF, [CODEREF]
  Type: class method

Recursivly traverses the C<@ISA> array of PACKAGE,
and returns a list of fields declared in the inheritance
tree of PACKAGE. HASHREF which must be supplied (and will be modified)
is used to ensure that fields will only show up once.
CODEREF is a optional parameter, which, when supplied,must be a reference to
the method itself and is used for recursion. If CODEREF is not supplied,
__traverseISA determines it on it's own.

=cut

sub __traverseISA
{
        my $self;
        my $package;
        my $found;
        my $f;
        my @funcs;

        $self    = shift || croak "no package supplied";
        $package = shift || croak "no target package supplied";
        $found   = shift || croak "no found hash supplied";
        $f       = shift || $self->can((caller(0))[3]);

        __hashref $found || croak "fail0r: not a hash reference";
        __coderef $f     || croak "fail0r: f arg supplied but not a code ref";

        push @funcs, $package unless exists $found->{$package};

        # XXX get rid of eval (or hide it somewhere)
        foreach my $pak ((eval '@'."${package}::ISA"))
        {
                unless (exists $found->{$pak})
                {
                        $found->{$pak} = 1;
                        push @funcs, $pak;
                }
                push @funcs, $f->($self, $pak, $found, $f);
        }

        return @funcs;
}

=head3 __addParentFields

  __addParentFields SELF, PACKAGE
  Type: class method

Adds the fields from SUPER classes to the list of fields.

=cut

sub __addParentFields
{
        my $self;
        my $package;
        my $found;

        $self    = shift || croak "no package supplied";
        $package = shift || croak "no target package supplied";

        $found  = {};

        foreach my $pkg ($self->__traverseISA($package, {}))
        {
                #print "processing package $pkg\n";
                foreach my $field (@{$funcs{$pkg}})
                {
                        #print "  processing func $field\n";
                        $found->{$field} = ($types{$pkg}{$field} || 'Any');
                }
        }

        $funcs{$package} = [keys %{$found}];
        $types{$package} = $found;

}

=head3 __doIt

  __doIt SELF, PACKAGE
  Type: class method

Inherits parents fields, generates base code, generates ext code, and starts
compilation for package PACKAGE. This method is meant to be called from CHECK
block in the target package. The C<__schedule> or more safely the
C<__scheduleIfNeeded> method can arrange that for you.

=cut

sub __doIt
{
        my $self;
        my $package;
        my $sub;

        # dark goto &Sub magic, because the method which actually compiles the
        # code (Inline->bind, FYI) needs to think it is called on behalf of the
        # class we're engineering

        $self    = $_[0] || croak "no package supplied";
        $package = $_[1] || croak "no target package supplied";

        $self->__addParentFields($package);
        $self->__genBaseCode($package);
        $self->__genExtCode($package);
        $sub = $self->can('__compile');
        goto &$sub;
}

=head3 __genExtFuncCode

  __genExtFuncCode SELF, PACKAGE, NAME, RETVAL, ARGS, CODEREF
  Type: class method

Generates a single ext function, NAME in package PACKAGE with return type RETVAL
and parameters ARGS, with the body returned from CODEREF. Meant to be called by
the C<__genExtCode> method.

=cut

sub __genExtFuncCode
{
        my $self;
        my $package;
        my $name;
        my $retval;
        my $args;
        my $code;
        my $ref;

        $self       = shift || croak "no package supplied";
        $package    = shift || croak "no target package supplied";
        $name       = shift || croak "no name supplied";
        $retval     = shift || croak "no retval supplied";
        $args       = shift || croak "no args supplied";
        $ref        = shift || croak "no ref supplied";


        $code       =  $retval ;
        $code      .=  ' ';
        $code      .=  $name;
        $code      .=  $args;
        $code      .= __circumPrint($ref->(), "\n{", "\n}\n");

        $self->__addCode($package, $code, 'ext');

        return;
}

=head3 __genExtCode

  __genExtCode SELF, PACKAGE
  Type: class method

Generates all ext functions in package PACKAGE. Utilizes the C<__genExtFuncCode>
method to do the dirty work. You can define ext functions with the C<C>
attribute.

=cut

sub __genExtCode
{
        my $self;
        my $package;
        my $func;

        $self    = shift || croak "no package supplied";
        $package = shift || croak "no target package supplied";

        foreach my $func (@{$extfuncs{$package}})
        {
                $self->__genExtFuncCode
                (
                        $package,
                        $func->{name},
                        $func->{retval},
                        $func->{args},
                        $func->{ref},
                );
        }

        return;
}

=head3 __genBaseCode

  __genBaseCode SELF, PACKAGE
  Type: class method

Generates the C code for all fields.
You can define fields with the C<Field> attribute.

=cut

sub __genBaseCode
{
        my $macros;
        my $structdef;
        my $accessor;
        my $createSub;
        my $destroySub;
        my $funcs;
        my $pkg;
        my $structGuts;
        my $accessors;
        my $code;
        my $self;
        my $spc;
        my $init;
        my $cleanup;
        my $inspectSub;
        my $inspectGuts;
        my $inspectLine;

        $self        = shift;
        $pkg         = shift;
        $funcs       = $funcs{$pkg};
        $structGuts  = '';
        $accessors   = '';
        $spc         = ' ' x 8;
        $inspectGuts = '';
        $inspectLine = 'hv_store(hash, "%s", %d, newSVpv("%s", %d), 0);';

        return unless __arrayref $funcs;
        return unless @{$funcs};

        # XXX outsource the bodies so they are overwritable from outside ?

        $macros     = <<'        END_OF_MACROS';

        #define sv2ptr(X) INT2PTR(hive, SvIV(SvRV(X)))
        #define dHive(X)  struct hive* X

        #define __ISFLOAT(X)    looks_like_number(X)
        #define __ISINT(X)      SvIOK(X)
        #define __ISUINT(X)     SvIOK_UV(X)
        #define __ISNUMBER(X)   __ISFLOAT(X)
        #define __ISSTRING(X)   SvPOK(X)
        #define __ISREF(X)      SvROK(X)
        #define __ISARRAYREF(X) SvROK(X) && SvTYPE(SvRV(X)) == SVt_PVAV
        #define __ISHASHREF(X)  SvROK(X) && SvTYPE(SvRV(X)) == SVt_PVHV
        #define __ISCODEREF(X)  SvROK(X) && SvTYPE(SvRV(X)) == SVt_PVCV
        #define __ISOBJECT(X)   sv_isobject(X)
        #define __ISREGEXPREF(X) sv_isa(X, "Regexp")
        #define __ISA(X,Y)      sv_derived_from(X, Y )
        #define __ANY           1
        #define __WRONG_TYPE(X) croak("fail0r: bad arguments, expected "X"\n");
        #define __CHECK(X, Y)   if(!(X)) {__WRONG_TYPE(Y)}
        #define __ARG0          Inline_Stack_Item(1)

        END_OF_MACROS

        $structdef  = <<'        END_OF_STRUCTDEF';

        struct hive
        {
        %s
        };

        typedef struct hive* hive;

        END_OF_STRUCTDEF

        $accessor   = <<'        END_OF_ACCESSOR';

        void %s(SV* svp, ...)
        {
                dHive(p);
                Inline_Stack_Vars;

                p =  sv2ptr(svp);

                if (Inline_Stack_Items == 2)
                {
                        if (SvOK(__ARG0))
                        {
                                %2$s /* here be check code */
                        }

                        if (SvOK(p->%1$s))
                        {
                                SvREFCNT_dec(p->%1$s);
                        }

                        if (SvROK(Inline_Stack_Item(1)))
                        {
                                SvREFCNT_inc(Inline_Stack_Item(1));
                                p->%1$s = Inline_Stack_Item(1);
                        }
                        else
                        {
                                p->%1$s = newSVsv(Inline_Stack_Item(1));
                        }

                        POPs;
                }
                POPs;
                XPUSHs(sv_mortalcopy(p->%1$s));
                XSRETURN(1);

        }

        static SV* get%1$s(SV* svp)
        {
                dHive(p);
                p = sv2ptr(svp);

                return sv_mortalcopy(p->%1$s);
        }

        #undef  __ARG0
        #define __ARG0 val

        static void set%1$s(SV* svp, SV* val)
        {
                dHive(p);
                p = sv2ptr(svp);

                if (SvOK(val))
                {
                        %2$s // here be check code
                }
                if (SvROK(p->%1$s))
                {
                        SvREFCNT_dec(p->%1$s);
                }

                p->%1$s = val;

                if (SvROK(val))
                {
                        SvREFCNT_inc(val);
                }

                return;
        }

        #undef  __ARG0
        #define __ARG0 Inline_Stack_Item(1)

        END_OF_ACCESSOR

        $createSub  = <<'        END_OF_CREATESUB';

        SV* create(SV* self)
        {
                dHive(p);
                New(1, p, 1, struct hive);
        %s
                return sv_bless(newRV_noinc(newSViv(PTR2IV(p))),
                                gv_stashsv(self, 0));
        }

        END_OF_CREATESUB

        $destroySub = <<'        END_OF_DESTROYSUB';

        void DESTROY(SV* svp)
        {
                dHive(p);
                p =  sv2ptr(svp);
        %s
                Safefree(p);
                return;
        }

        END_OF_DESTROYSUB

        $inspectSub = <<'        END_OF_INSPECTSUB';

        SV* inspect(SV* svp)
        {
                HV* hash;
                SV* hashref;

                hash = newHV();

        %s
                hashref = newRV_noinc((SV*) hash);

                return hashref;
        }

        END_OF_INSPECTSUB

        s/\n[ ]{8}/\n/g foreach ($macros, $structdef, $accessor,
                                 $createSub, $destroySub, $inspectSub);

        foreach (@{$funcs})
        {

                $structGuts .= $spc."SV* $_;\n";
                $accessors  .= sprintf($accessor, $_,
                                       $types{$pkg}{$_} ?
                                         __parseFieldType $types{$pkg}{$_}
                                         : '//');
                $init       .= __circumPrint($_, $spc."p->",' = &PL_sv_undef;');
                $init       .= "\n";
                $cleanup    .= $spc."if (SvOK(p->$_))\n";
                $cleanup    .= __circumPrint(($spc x 2)."SvREFCNT_dec(p->$_);\n",
                                             $spc."{\n", $spc."}\n");

                $inspectGuts .= $spc;
                $inspectGuts .= sprintf $inspectLine, $_,
                                        length $_,  $types{$pkg}{$_},
                                        length $types{$pkg}{$_};
                $inspectGuts .= "\n";
        }

        $code = join("\n",
                     $macros,
                     sprintf($structdef, $structGuts),
                     sprintf($createSub, $init),
                     sprintf($destroySub, $cleanup),
                     sprintf($inspectSub, $inspectGuts),
                     $accessors);

        $self->__addCode($pkg, $code, 'base');

        return;
}

=head3 parseArgs

  parseArgs SELF, LOTS_OF_STUFF
  Type: object method

Used for named parameters in constructors.
Returns the object, for simplified use in constructors.

=cut

sub parseArgs
{
        my $self;
        my $method;
        my $opt;

        $self = shift;
        @_ % 2 && croak "odd number of arguments";

        while (@_)
        {
                $method = shift;
                $opt    = shift;

                $method =~ s/^-?//g;
                $self->$method($opt);
        }

        return $self;
}

=head3 new

  new SELF, PACKAGE, LOTS_OF_STUFF
  Type: class method

Highlevel Constructor, first calls the C<create> constructor to allocate the C
structure, and then calls parseArgs to initialize the object.

=cut

sub new
{
        return shift->create->parseArgs(@_);
}

=head2 Subroutines

The subroutines listed here are not considered part of the public api, and
should not be used in any way, unless you know better.

Class::CompiledC defines the following subroutines

=head3 __circumPrint

  __circumPrint TEXT, LEFT, RIGHT
  Type: Subroutine.
  Export: on request.
  Prototype: $$$

Utitlity function, concatenates it's arguments, in the order
C<$_[1].$_[0].$_[1]> and returns the resulting string. Does not print anything.

=cut

sub __circumPrint($$$)
{
        return $_[1].$_[0].$_[2];
}

=head3 __include

  __include I<NOTHING>
  Type: Subroutine.
  Export: on request.
  Prototype: none

Takes C<$_> and returns a string in form C<\n#include $_\n>. This subroutine is
used to generate C<C> include directives, from the C<Include> attribute. Note
that it doesn't add C<<>> or C<""> around the include, you have to do this your
self.

=cut

sub __include
{
        return __circumPrint($_ , "\n#include ", "\n");
}

=head3 __baseref

  __baseref REFERENCE, TYPE
  Type: Subroutine.
  Export: on request.
  Prototype: $$

Determines if REFERENCE is actually a reference and and is of type TYPE.

=cut

sub __baseref($$)
{
        defined $_[0] && ref $_[0] && ref $_[0] eq $_[1];
}

=head3 __hashref

  __hashref REFERENCE
  Type: Subroutine.
  Export: on request.
  Prototype: $

Determines if REFERENCE is actually a hash reference.
Utitlizes C<__baseref>.

=cut

sub __hashref($)
{
        __baseref $_[0], 'HASH';
}

=head3 __arrayref

  __arrayref REFERENCE
  Type: Subroutine.
  Export: on request.
  Prototype: $

Determines if REFERENCE is actually a array reference.
Utitlizes C<__baseref>.

=cut

sub __arrayref($)
{
        __baseref $_[0], 'ARRAY';
}

=head3 __coderef

  __coderef REFERENCE
  Type: Subroutine.
  Export: on request.
  Prototype: $

Determines if REFERENCE is actually a code reference.
Utitlizes C<__baseref>.

=cut

sub __coderef($)
{
        __baseref($_[0], 'CODE')
}

=head3 __fetchSymbolName

  __fetchSymbolName GLOBREF
  Type: Subroutine.
  Export: on request.
  Prototype: $

Returns the Symbol name from the glob reference GLOBREF.
Croaks if GLOBREF acutally isn't a glob reference.

=cut

sub __fetchSymbolName($)
{
        no strict 'refs';
        my $symbol = shift;

        __baseref $symbol, 'GLOB' or croak 'not a GLOB reference';

        return *$symbol{NAME};
}

=head3 __promoteFieldTypeToMacro

  __promoteFieldTypeToMacro FIELDTYPE
  Type: Subroutine.
  Export: on request.
  Prototype: none

Takes a fieldtype specfication, and returns a C<C> macro for doing the test.
Does not handle parametric types like C<isa>. See C<__parseFieldType> for that.

=cut

sub __promoteFieldTypeToMacro($)
{
        my $type = shift;

        return '' unless ($type);
        return '' if     ($type =~ /^any$/i);
        return sprintf '__CHECK(__IS%s(__ARG0), "%s")', uc $type, $type;
}

=head3 __parseFieldType

  __parseFieldType FIELDTYPE
  Type: Subroutine.
  Export: on request.
  Prototype: none

Takes a fieldtype specfication, and returns a C<C> macro for doing the test.
Handles all field types. Delegates most work to the C<__promoteFieldTypeToMacro>
subroutine.

=cut

sub __parseFieldType
{
      local $_ = shift;

      if (/$re_ft/)
      {
             # warn sprintf "yeah %s !", __promoteFieldTypeToMacro $1;
              return __promoteFieldTypeToMacro($1);
      }
      elsif (/$re_ft_isa/)
      {
              croak "fail0r: isa type needs a classname argument\n" unless $1;
              return '__CHECK(__ISA(__ARG0, '."\"$1\"), \"__ISA\")";

      }
      else
      {
              croak "fail0r: bad type specified $_\n";
      }

}


=head3 Include

  sub Foo : C(...)     Include(<math.h>)
  sub Foo : Field(...) Include("bar.h")

  Type: Attribute Handler
  Export: no.

=cut

sub Include : ATTR(CODE, BEGIN)
{
        my $package;
        my $symbol;
        my $ref;
        my $attribute;
        my $data;

        $package    = shift || croak "no package supplied";
        $symbol     = shift || croak "no symbol supplied";
        $ref        = shift || croak "no reference supplied";
        $attribute  = shift || croak "no attribute supplied";
        $data       = shift || croak "no includes supplied";

        $data               = [ $data ] unless __arrayref $includes{$package};
        $includes{$package} = []        unless __arrayref $data;

        push @{$includes{$package}}, @{$data};
}

=head3 C

  sub Foo : C(RETVAL, ARG0, ...)

  Type: Attribute Handler
  Export: no.

=cut

sub C       : ATTR(CODE, CHECK, RAWDATA)
{
        my $package;
        my $symbol;
        my $attribute;
        my $data;
        my $ref;
        my $retval;
        my $name;
        my $self;

        $package    = shift || croak "no package supplied";
        $symbol     = shift || croak "no symbol supplied";
        $ref        = shift || croak "no reference supplied";
        $attribute  = shift || croak "no attribute supplied";
        $data       = shift || croak "no return type and parameters specified";

        $extfuncs{$package} = [] unless __arrayref $extfuncs{$package};
        $data       =~ s/(?:\s*)([a-zA-Z_]+[a-zA-Z0-9_]*(?:\*)*)(?:\s*),//;
        $retval     = $1;

        push @{$extfuncs{$package}},
        {
                name    => __fetchSymbolName($symbol),
                args    => __circumPrint($data, '(', ')'),
                retval  => $retval,
                ref     => $ref,

        };

        $self       = __PACKAGE__;
        $self->__scheduleIfNeeded($package);

        return;
}

=head3 Field

  sub Foo : Field(TYPE)

  Type: Attribute Handler
  Export: no.

=cut

sub Field   : ATTR(CODE, CHECK)
{
        my $package;
        my $symbol;
        my $ref;
        my $attribute;
        my $data;
        my $self;
        my $name;

        $package    = shift || croak "no package supplied";
        $symbol     = shift || croak "no symbol supplied";
        $ref        = shift || croak "no reference supplied";
        $attribute  = shift || croak "no attribute supplied";
        $data       = shift;

        $self       = __PACKAGE__;
        $name       = __fetchSymbolName($symbol);

        $funcs{$package} = [] unless __arrayref $funcs{$package};

        push @{$funcs{$package}}, $name;

        $types{$package}{$name} = $data if $data;

        $self->__scheduleIfNeeded($package);
        return;
}

=head3 Alias

  sub Foo : Alias(\&REALMETHOD)

  Type: Attribute Handler
  Export: no.

=cut

sub Alias : ATTR(CODE)
{
        my $package;
        my $symbol;
        my $attribute;
        my $data;
        my $ref;

        $package   = shift || croak "no package supplied";
        $symbol    = shift || croak "no symbol supplied";
        $ref       = shift || croak "no reference supplied";
        $attribute = shift || croak "no attribute supplied";
        $data      = shift || croak "no alias supplied";

        __coderef $data    or croak "parameter for Alias must be coderef";
        *$symbol   = $data;

        return;
}

=head3 Overload

  sub Foo : Overload(OPERATOR)

  Type: Attribute Handler
  Export: no.

=cut

sub Overload : ATTR(CODE)
{
        my $package;
        my $symbol;
        my $attribute;
        my $data;
        my $ref;

        $package   = shift || croak "no package supplied";
        $symbol    = shift || croak "no symbol supplied";
        $ref       = shift || croak "no reference supplied";
        $attribute = shift || croak "no attribute supplied";
        $data      = shift || croak "no operator to Overload supplied";

        $package->overload::OVERLOAD($data, $ref);

        return;

}

=head3 Const

  sub Foo : Const(VALUE)

  Type: Attribute Handler
  Export: no.

=cut

sub Const : ATTR(CODE, CHECK)
{
        no warnings 'prototype';

        my $package;
        my $symbol;
        my $attribute;
        my $data;
        my $ref;

        $package   = shift || croak "no package supplied";
        $symbol    = shift || croak "no symbol supplied";
        $ref       = shift || croak "no reference supplied";
        $attribute = shift || croak "no attribute supplied";
        $data      = shift || croak "no value supplied ";

        *$symbol   = sub () {$data};

        return;

}

=head3 Abstract

  sub Foo : Abstract

  Type: Attribute Handler
  Export: no.

=cut

sub Abstract : ATTR(CODE, CHECK)
{
        my $package;
        my $symbol;
        my $attribute;
        my $data;
        my $ref;
        my $name;


        $package   = shift || croak "no package supplied";
        $symbol    = shift || croak "no symbol supplied";
        $ref       = shift || croak "no reference supplied";
        $attribute = shift || croak "no attribute supplied";
        $data      = shift && croak "Abstract doesn't take parameters";

        $name      = __fetchSymbolName $symbol;

        *$symbol   = sub
        {
                Carp::croak("Abstract method '", $name,
                            "' in package '", $package,
                            "' not implemented");
        };

        return;
}


=head3 Class

  sub Foo : Class(CLASS)

  Type: Attribute Handler
  Export: no.

=cut

sub Class : ATTR(CODE, CHECK)
{
        my $package;
        my $symbol;
        my $attribute;
        my $data;
        my $ref;
        my $name;

        $package   = shift || croak "no package supplied";
        $symbol    = shift || croak "no symbol supplied";
        $ref       = shift || croak "no reference supplied";
        $attribute = shift || croak "no attribute supplied";
        $data      = shift;

        $name      = __fetchSymbolName $symbol;

        $data ? eval "use $data" : eval "use ${package}::Method::${name}";
        bless *{$symbol}{CODE}, ($data || "${package}::Method::${name}");

        return;
}

=head2 Inheritance

Class::CompiledC inherits the following methods from it's ancestors

=over

=item methods inherited from C<Attribute::Handlers>

=over

=item C<import>

=item C<_resolve_lastattr>

=item C<DESTROY>

=item C<_gen_handler_AH_>

=item C<_apply_handler_AH_>

=back

=back

=head2 Export

Class::CompiledC does not export anything by default but has a number of subroutines
to Export on request.

=head2 Export Tags

Class::CompiledC defines the following export tags:

=over

=item ref Subroutines to verify the type of references

=item misc miscellanous subroutines

=item field specification subroutines

=item intern miscellanous subroutines with low value outside this package

=item all Everything.

=back

=cut

BEGIN
{
        $EXPORT_TAGS{ref}    = [qw/__arrayref  __coderef __hashref/];
        $EXPORT_TAGS{misc}   = [qw/__fetchSymbolName __baseref __circumPrint/];
        $EXPORT_TAGS{field}  = [qw/__parseFieldType __promoteFieldTypeToMacro/];
        $EXPORT_TAGS{intern} = [qw/__include/];
        $EXPORT_TAGS{all}    = [map {@{$_}} values %EXPORT_TAGS ];
}

=head2 Exportable Symbols

The following subroutines are (im|ex)portable, either explicitly by name or
as part of a tag.

=over

=item C<__include>

=item C<__arrayref>

=item C<__coderef>

=item C<__hashref>

=item C<__fetchSymbolName>

=item C<__baseref>

=item C<__circumPrint>

=item C<__parseFieldType>

=item C<__promoteFieldTypeToMacro>

=back

=cut

BEGIN
{
        @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

=head1 EXAMPLES

  TODO

=head1 DIAGNOSTICS

=over

=item C<no package supplied>

this message is usually caused by an class method called as a subroutine.
I<fatal error>

=item C<no target package supplied>

Some methods (and subroutines, btw) need a target package to operate on,
it seems that the argument is missing, or has evaluated to false value, which
very unlikely to be valid.
I<fatal error>

=item C<no code supplied>

This message is is caused by the __addCode method, which renders useless
without a supplied code argument.
I<fatal error>

=item C<no type supplied>

This message is caused by the __addCode method, when called without a type
argument. The __addCode method can only operate with a valid type argument.
Currently valid types are C<base> and C<ext> but more may be added in future.
I<fatal error>


=item C<bad type supplied>

This message is caused by the __addCode method, when called with a invalid type
argument. Currently valid types are C<base> and C<ext>
but more may be added in future.
I<fatal error>

=item C<fail0r: isa type needs a classname argument>

This message is caused by the __parseFieldType subroutine. The __parseFieldType
subroutine (which gets called by the Field attribute handler) found C<isa> as
type but without a classname. A is a check doesn't make sense without a
classname. If you just want to make sure that it is a object, you may use
C<Isa(Universal)> or (generally faster and shorter) C<Object>.
I<fatal error>

=item C<fail0r: not a hash reference>

This message is caused by the __traverseISA method, which needs
a hashreference as third argument, for speed considerartions.
I<fatal error>

=item C<fail0r: f arg supplied but not a code ref>

This message is caused by the __traverseISA method, which accepts
a reference to itself, both for efficiency reasons and security from renamings.
I<fatal error>

=item C<no found hash supplied>

This message is caused by the __traverseISA method, when called without the
third argument.
(Which must be a hashreference, I<and> will be changed by the method)
I<fatal error>

=item C<no symbol supplied>

This message can be issued from different sources, but most often by attribute
handlers, which misses a reference to a typeglob. Don't call attribute handlers
on your own. (unless you really know what you do) I<fatal error>

=item C<no reference supplied>

This message can be issued from different sources, but most often by attribute
handlers, which misses a reference to whatever they decorate. Don't call a
ttribute handlers on your own. (unless you really know what you do)
I<fatal error>

=item C<no attribute supplied>

This message can be issued from different sources, but most often by attribute
handlers, which misses the attribute they should handler. Don't call a
ttribute handlers on your own. (unless you really know what you do)
I<fatal error>

=item C<no includes supplied>

This message is caused by the C<Include> attribute handler.
The C<Include> handlers just couldn't figure out what to do.
Give him a hand and specify what should be included. I<fatal error>

=item C<no return type and parameters specified>

This message is specific to the C<C> attribute handler subroutine.
To compile the code it needs to know the return type and the parameter list
of the C function to be compiled. I<fatal error>

=item C<no name supplied>

This message is caused by the __genExtFuncCode method when
called without a fieldname. I<fatal error>

=item C<no retval supplied>

This message is caused by the __genExtFuncCode method when called without a
return type argument. I<fatal error>

=item C<no args supplied>

This message is caused by the __genExtFuncCode method when called without a
args argument. I<fatal error>

=back

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere.

=over

=item there is a (undocumented) UINT type specifier for unsigned ints,
but it doesn't work right, actually it doesn't work at all, don't try to use it.

=back

=head1 TODO

=over

=item *serious code cleanup

I still find too much things that are done the fast way instead of the right
way, this really bothers me.

=item *outsourcing

A few things need to be outsourced right away. I just don't know where to put
them. Especially the stuff not related to classes should be placed somewhere
else. The utility __.* subs (not methods!) could be placed in a different
package and locally (or maybe lexically?) imported, to avoid namespace pollution
of subclasses.

Random thought: lexical importing ? what a cute idea! is this possible?


=back

=head1 SEE ALSO

=over

=item TODO

=back

=head1 AUTHOR

blackhat.blade
 The Hive

blade@focusline.de

=head1 COPYRIGHT

                          Copyright (c) 2005, 2006
              blackhat.blade The Hive.  All Rights Reserved.
       This module is free software. It may be used, redistributed
           and/or modified under the terms of the Artistic license.

=cut

1;

__END__
2.14 Wed Jan 18 00:44:39 CET 2006 @31 /Internet Time/
     everything till here...
2.15 Thu Jan 19 20:28:41 CET 2006 @853 /Internet Time/
     fixed documentation issues, the Field type for regular exprssions
     is C<Regexpref> and I<not> C<Regexref>. I also had Regexenref in mind...
2.16 Sun Oct 08 00:05:19 CEST 2006 @962 /Internet Time/
     fixed (?:Array|Code|Hash)ref type checking code
2.17 Sat Oct 21 01:01:45 CEST 2006 @1 /Internet Time/
     added a few sanity checks for __fetchSymbolName
2.18 Sun Oct 22 13:21:16 CEST 2006 @514 /Internet Time/
     fixed some serious bugs concerning refcounts of non ref values
     fixed (?:Array|Code|Hash)ref type checking code
2.19 Sun Oct 22 19:52:04 CEST 2006 @786 /Internet Time/
     relocated field type parsing into __genBaseCode in anticipation to support
       introspection
     refactored __promoteFieldTypeToMacro sub
     adapted __addParentFields to emit only valid field types
     added inspect method, it returns a hashref with fieldnames as keys and
      field types as values. (you may change that hash but don't expect any
      changes to persist, or even to propagate back and change the class on the
      fly, we are not at this point, and we're not going into this directon)
2.20 Thu Oct 26 21:48:22 CEST 2006 @866 /Internet Time/
     first public release
     renamed to Class::CompiledC to avoid the creation of a new root namespace
     added version requirement for 5.8.7, sorry for this but I cannot tell if
     it will run with earlier versions.
2.21 Fri Oct 27 23:27:38 CEST 2006 @935 /Internet Time/
     no code changes, fixed errors in Makefile.pl
2.22 Sun Oct 29 22:52:42 CET 2006 @953 /Internet Time/
     updated documentation,
     minor code cleanups.
