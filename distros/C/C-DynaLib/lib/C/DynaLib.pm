#
#   "Better to do it in Perl than C.
#    Better to do it in C than Assembler.
#    Better to do it in Assembler than V****l B***c."
#
package C::DynaLib;

require 5.002;

use strict;
use warnings;
no strict 'refs';
use Carp;
#use Convert::Binary::C;
use Config;
use vars qw($VERSION @ISA $AUTOLOAD @EXPORT @EXPORT_OK);
use vars qw($GoodRet $DefConv $decl);
use subs qw(AUTOLOAD new LibRef DESTROY DeclareSub);
$VERSION = '0.61';
use File::Spec;
use C::DynaLib::Struct;

# inline-able constants?
sub DYNALIB_DEFAULT_CONV ();
sub PTR_TYPE ();

@EXPORT = qw(PTR_TYPE);
@EXPORT_OK = qw(Poke DeclareSub LibRef Parse);

require DynaLoader;
require Exporter;

@ISA = qw(DynaLoader Exporter);

bootstrap C::DynaLib $VERSION, \$C::DynaLib::Callback::Config;

#sub dl_findfile { DynaLoader::dl_findfile(@_) }
#sub dl_load_file { DynaLoader::dl_load_file(@_) }
# dlopen/win32 platforms only:
#sub dl_unload_file { DynaLoader::dl_unload_file(@_) }

$GoodRet = '(?:[ilscILSCfdZp'.(PTR_TYPE eq 'q'?'qQ':'').']?|P\d+)';

sub AUTOLOAD {
  my $constname;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  my $val = constant($constname);
  $! and croak "Undefined subroutine &$AUTOLOAD called";
  eval "sub $AUTOLOAD () { '$val' }";
  goto &$AUTOLOAD;
}

$DefConv = DYNALIB_DEFAULT_CONV;

sub new {
  my $class = shift;
  my $libname = $_ = shift;
  scalar(@_) <= 1
    or croak 'Usage: $lib = new C::DynaLib( $library [, $decl, $flags] )';
  my $so = $libname;
  -e $so or $so = DynaLoader::dl_findfile($libname) || $libname;
  my $lib;
  my $decl = shift || $DefConv;
  $lib = DynaLoader::dl_load_file($so, @_) unless $so =~ /\.a$/;
  if (!$lib) {
    # Duplicate most of the DynaLoader code, since DynaLoader is
    # not ready to find MSWin32 dll's.
    if ($^O =~ /MSWin32|cygwin/) {
      my ($found, @dirs, @names, @dl_library_path);
      my $lib = $libname;
      $lib =~ s/^-l//;
      if ($^O eq 'cygwin' and $lib =~ m{^(c|m|pthread|/usr/lib/libc\.a)$}) {
        $lib = DynaLoader::dl_load_file("/bin/cygwin1.dll", @_);
        return bless [$lib, $decl], $class;
      }
      if ($^O eq 'MSWin32' and $lib =~ /^(c|m|msvcrt|msvcrt\.lib)$/) {
        if ($lib = DynaLoader::dl_load_file($ENV{SYSTEMROOT}.
					    "\\System32\\MSVCRT.DLL", @_))
	{
          return bless [$lib, $decl], $class;
        }
        push(@names, "MSVCRT.DLL","MSVCRT90","MSVCRT80","MSVCRT71","MSVCRT70",
             "MSVCRT60","MSVCRT40","MSVCRT20");
      }
      # Either a dll if there exists a unversioned dll,
      # or the import lib points to the versioned dll.
      push(@dirs, "/lib", "/usr/lib", "/usr/bin/", "/usr/local/bin")
        unless $^O =~ /^(MSWin32|VMS)$/;
      push(@dirs, $ENV{SYSTEMROOT}."\\System32", $ENV{SYSTEMROOT}, ".")
        if $^O eq 'MSWin32';
      push(@names, "cyg$_.dll", "lib$_.dll.a") if $^O eq 'cygwin';
      push(@names, "$_.dll", "lib$_.a") if $^O eq 'MSWin32';
      push(@names, "lib$_.so", "lib$_.a");
      my $pthsep = $Config::Config{path_sep};
      push(@dl_library_path, split(/$pthsep/, $ENV{LD_LIBRARY_PATH} || ""))
        unless $^O eq 'MSWin32';
      push(@dirs, split(/$pthsep/, $ENV{PATH}));
    LOOP:
      for my $name (@names) {
        for my $dir (@dirs, @dl_library_path) {
          next unless -d $dir;
          my $file = File::Spec->catfile($dir,$name);
          if (-f $file) {
            $found = $file;
            last LOOP;
          }
        }
      }
      if ($found) {
        $found = system("dllimport -I $found") if $found =~ /\.a$/;
        $lib = DynaLoader::dl_load_file($found, @_);
      }
    }
    # last ressort, try $so which might trigger a Windows MessageBox.
    unless ($lib) {
      $lib = DynaLoader::dl_load_file($so, @_) if $so;
      return undef unless $lib;
    }
  }
  bless [$lib, $decl], $class;
}

sub LibRef {
  $_[0]->[0];
}

sub LibDecl {
  $_[0]->[1];
}

sub DESTROY {
  DynaLoader::dl_unload_file($_[0]->LibRef)
    if defined (&DynaLoader::dl_unload_file);
}

sub DeclareSub {

  # We eval $obj->isa and $obj->can for 5.003 compatibility.
  local ($@);
  my $self = shift;

  # Calling as a method is equivalent to supplying the "libref" named arg.
  my $is_method;
  $is_method = ref($self) && eval { $self->isa("C::DynaLib") };
  $@ and $is_method = (ref($self) eq 'C::DynaLib');
  my $first = ($is_method ? shift : $self);

  my ($libref, $name, $ptr, @arg_type);
  my ($convention, $ret_type) = ($is_method ? $self->LibDecl : $DefConv, '');

  if (ref($first) eq 'HASH') {

    # Using named parameters.
    ! @_ && (($ptr = $first->{'ptr'}) || defined ($name = $first->{'name'}))
      or croak 'Usage: $lib->DeclareSub('.
        '{ "name" => $func_name [, "return" => $ret_type] [,'.
        '  "args" => \@arg_types] [, "decl" => $decl] })';

    $libref = $first->{'libref'};
    $convention = $first->{'decl'} || $convention;
    $ret_type = $first->{'return'} || $ret_type;
    @arg_type = @{ $first->{'args'} || [] };

  } else {

    # Using positional parameters.
    ($is_method ? $name : $ptr) = $first
      or croak 'Usage: $lib->DeclareSub( $func_name [, $return_type [, \@arg_types]] )';
    $ret_type = shift || $ret_type;
    @arg_type = @_;
  }

  unless ($ptr) {
    # No pointer, so we're looking up the function in a library...
    $libref ||= $is_method && $self->LibRef()
      or croak 'C::DynaLib::DeclareSub: non-method form requires a "ptr" or "libref"';
    $ptr = eval { DynaLoader::dl_find_symbol($libref, $name) };
    if ($@ || ! $ptr) {
      return undef;
    }
  }

  $ret_type =~ /^$GoodRet$/o
    or croak "Invalid return type: '$ret_type'";

  my $glue_sub_name = $convention . '_call_packed';
  my $glue_sub = ($is_method && eval { $self->can($glue_sub_name) })
    || (defined(&{"$glue_sub_name"}) && \&{"$glue_sub_name"});

  if (! $glue_sub) {
    carp "Unsupported calling convention: decl => '$convention'"
      if $^W;
    return undef;
  }

  my @pre_args = ($ptr, $ret_type, $libref);
  my $pkg = caller();

  # This 'inner' closure must be an eval-string in order to compile the
  # function call in our caller's package.
  my $proc = eval q/ sub {
    package /.$pkg.q/;
    &$glue_sub(@pre_args, map { pack($_, shift) } @arg_type);
  }/;

  return sub {
    if ($^W) {
      if ($#_ < $#arg_type) {
	carp 'Missing arguments supplied as undef';
      } elsif ($#_ > $#arg_type) {
	carp 'Extra arguments ignored';
      }
    }
    local $SIG{'__WARN__'} = \&my_carp;
    local $SIG{'__DIE__'} = \&my_croak;
    &$proc;
  };
}

sub Parse {
  my $self = shift;
  my $is_method = ref($self) && eval { $self->isa("C::DynaLib") };
  $@ and $is_method = (ref($self) eq 'C::DynaLib');
  my $first = ($is_method ? shift : $self);
  my ($code,$cc,$inc,$filter);
  if (ref($first) eq 'HASH') {
    $code = $first->{code} or die "code missing\n";
    $cc = $first->{cc} || "gcc";
    $inc = $first->{inc};
    $filter = $first->{filter};
    $cc = "$cc -I$inc" if $inc;
  } else {
    $code = $first;
    $cc = shift;
    $filter = shift;
  }
  require C::DynaLib::Parse;
  C::DynaLib::Parse->import (qw(declare_func declare_struct
			       pack_types process_struct process_func));
  my $node = C::DynaLib::Parse::GCC_prepare($code, $cc);
  while ($node) {
    if ($node->isa('GCC::Node::function_decl')
	and ($filter ? $node->name->identifier =~ /$filter/
	     : $node->name->identifier !~ /^_/))
    {
      declare_func process_func($node);
    }
    if ($node->isa('GCC::Node::record_type')
	and ($filter ? $node->name->identifier =~ /$filter/
	     : $node->name->identifier !~ /^_/))
    {
      declare_struct process_struct($node);
    }
  } continue {
    $node = $node->chain;
  }
 POST:
  while ($node = shift @C::DynaLib::Parse::post) {
    if ($node->isa('GCC::Node::record_type')) {
      declare_struct process_struct($node);
    }
  }
}

sub my_carp {
  # inspired by Exporter
  my $text = shift;
  local $Carp::CarpLevel = 0;
  if ((caller 2)[3] =~ /^\QC::DynaLib::__ANON__/) {
    $Carp::CarpLevel = 2;
    $text =~ s/(?: in pack)? at \(eval \d+\) line \d+.*\n//;
  }
  carp($text);
};

sub my_croak {
  my $text = shift;
  local $Carp::CarpLevel = 0;
  if ((caller 2)[3] =~ /^\QC::DynaLib::__ANON__/) {
    $Carp::CarpLevel = 2;
    $text =~ s/(?: in pack)? at \(eval \d+\) line \d+.*\n//;
  }
  croak($text);
};


package C::DynaLib::Callback;

use strict;
use Carp;
use vars qw($Config $GoodRet $GoodFirst $GoodArg $empty);
use subs qw(new Ptr DESTROY);

sub CONFIG_TEMPLATE () { C::DynaLib::PTR_TYPE ."pp". C::DynaLib::PTR_TYPE }
$empty = "";

if (C::DynaLib::PTR_TYPE eq 'q') {
  $GoodRet = '[iIq]?';
  $GoodFirst = '(?:[ilscILSCpqQ]?|P\d+)';
  $GoodArg = '(?:[ilscILSCfdpqQ]?|P\d+)';
} else {
  $GoodRet = '[iI]?';
  $GoodFirst = '(?:[ilscILSCp]?|P\d+)';
  $GoodArg = '(?:[ilscILSCfdp]?|P\d+)';
}

sub new {
  my $class = shift;
  my $self = [];
  my ($index, $coderef);
  my ($codeptr, $ret_type, $arg_type, @arg_type, $func);
  my $i;
  for ($index = 0; $index <= $#{$Config}; $index++) {
    ($codeptr, $ret_type, $arg_type, $func)
      = unpack(CONFIG_TEMPLATE, $Config->[$index]);
    last unless $codeptr;
  }
  if ($index > $#{$Config}) {
    carp "Limit of ", scalar(@$Config), " callbacks exceeded";
    return undef;
  }
  ($coderef, $ret_type, @arg_type) = @_;

  $ret_type =~ /^$GoodRet$/o
    or croak "Invalid callback return type: '$ret_type'";
  ! @arg_type || $arg_type[0] =~ /^$GoodFirst$/o
    or croak "Invalid callback first argument type: '$arg_type[0]'";
  for $i (@arg_type[1..$#arg_type]) {
    $i =~ /^$GoodArg$/o
      or croak "Invalid callback argument type: '$i'";
  }

  unshift @$self, $coderef;
  $codeptr = \$self->[0] + 0;
  $arg_type = join ('', @arg_type);

  unshift @$self, $codeptr, $ret_type, $arg_type, $func, $index;
  $Config->[$index] = pack (CONFIG_TEMPLATE, @$self);

  bless $self, $class;
}

sub Ptr {
  $_[0]->[3];
}

sub DESTROY {
  $Config->[$_[0]->[4]] = pack(CONFIG_TEMPLATE, 0, $empty, $empty,
			       $_[0]->[3]);
}

package C::DynaLib;
1;
__END__

=head1 NAME

C::DynaLib - Dynamic Perl interface to C compiled code.

=head1 SYNOPSIS

  use C::DynaLib;
  use sigtrap;	# recommended

  $lib = new C::DynaLib( $library [, $decl, [$dlopen_flags]] );

  $func = $lib->DeclareSub( $symbol_name
			    [, $return_type [, @arg_types] ] );
  $result = &$func(@args);
  # or
  $func = $lib->DeclareSub( { "name" => $symbol_name,
                              "decl" => 'stdcall',
			      [param => $value,] ... } );
  $func = $lib->DeclareSub( $symbol_name, $ret, $params...);
  # or
  use C::DynaLib qw(DeclareSub);
  $func = DeclareSub( $function_pointer,
		      [, $return_type [, @arg_types] ] );
  # or
  $func = DeclareSub( { "ptr" => $function_pointer,
			[param => $value,] ... } );
  $result = $func->( @args );

  my $user32 = new C::DynaLib( 'user32', 'stdcall' );
  my $PostQuitMessage = §user32->DeclareSub("PostQuitMessageA",
	"i",   # return type
        "i");  # argument type(s)

  $callback = new C::DynaLib::Callback( \&my_sub,
			$return_type, @arg_types );
  $callback_pointer = $callback->Ptr();

=head1 PLUG FOR PERL XS

If you have a C compiler that Perl supports, you will get better
results by writing XSubs than by using this module.  B<I GUARANTEE
IT!>  It may take you longer to do what you want, but your code will
be much more solid and portable.  See L<perlxs>.

This module brings "pointers" to Perl.  Perl's non-use of pointers is
one of its great strengths.  If you don't know what I mean, then maybe
you ought to practice up a bit on C or C++ before using this module.
If anything, pointers are more dangerous in Perl than in C, due to
Perl's dynamic, interpretive nature.

The XSub interface and Perl objects provide a means of calling C and
C++ code while preserving Perl's abstraction from pointers.  Once
again, I I<urge> you to check out L<perlxs>!  It's really cool!!!

=head1 DESCRIPTION

This module allows Perl programs to call C functions in dynamic
libraries.  It is useful for testing library functions, writing simple
programs without the bother of XS, and generating C function pointers
that call Perl code.

Your Perl must be of the dynamic variety and have a working
F<DynaLoader> to use the dynamic loading capabilities of this module.
Be sure you answered "y" when F<Configure> (from the Perl source kit)
asked, "Do you wish to use dynamic loading?".

The mechanics of passing arguments to and returning values from C
functions vary greatly among machines, operating systems, and
compilers.  Therefore, F<Makefile.PL> checks the Perl configuration and
may even compile and run a test program before the module is built.

This module is divided into two packages, C<C::DynaLib> and
C<C::DynaLib::Callback>.  Each makes use of Perl objects (see
L<perlobj>) and provides its own constructor.
See also L<C::DynaLib::Struct> for easy struct accessors.

A C<C::DynaLib> object corresponds to a dynamic library whose
functions are available to Perl.  A C<C::DynaLib::Callback> object
corresponds to a Perl sub which may be accessed from C.

=head2 C<new C::DynaLib> public constructor

The first argument to C<new> may be the file name or base name 
of a dynamic library.
Alternatively, a linker command-line argument (e.g., C<"-lc">) may be
specified. See L<DynaLoader(3)> for details on how such arguments are
mapped to file names.

An optional 2nd argument may specify an alternate calling convention, 
one of @C::DynaLib::decl. Default: $C::DynaLib::decl. This is usually 
required for mingw or cygwin for 'stdcall'.

Note: On cygwin or mingw the import library
F</usr/lib/lib"name".dll.a> contains the name of the .dll, so
-l"name" is enough, and you don't have to use the versioned
name of the dll. C<dllimport -I libname> will be used to get the dll name.

On failure, C<new> returns C<undef>.  Error information I<might> be
obtainable by calling C<DynaLoader::dl_error()>.

=head2 DeclareSub( {} | name return args ... ) - Declare a function pack-style

Before you can call a function in a dynamic library, you must specify
its name, the return type, and the number and types of arguments it
expects.  This is handled by C<DeclareSub>.

C<C::DynaLib::DeclareSub> can be used as either an object method or an
ordinary sub.  You can pass its arguments either in a list (what we
call I<positional parameters>) or in a hash (I<named parameters>).

The simplest way to use C<DeclareSub> is as a method with positional
parameters.  This form is illustrated in the first example above and
both examples below.  When used in this way, the first argument is a
library function name, the second is the function return type, and the
rest are function argument types.

B<THIS IS VERY IMPORTANT>.  You must not forget to specify the return
type as the second argument to C<DeclareSub>.  If the function returns
C<void>, you should use C<""> as the second argument.

C data types are specified using the codes used by Perl's C<pack> and
C<unpack> operators. See L<perlfunc/pack> for their description.
'p' is a perl string which points to the foreign buffer. Note that not
all perl-level modifications do the same as their c-level counterparts.
E.g. changing the start of the string will not do a memmove c-side, rather
the SvOOK hack is used (See L<perlguts>. Extending the length of the
string will destructively modify foreign data, only causing SIGSEGV if
you are lucky.

As a convenience (and to hide system dependencies), C<PTR_TYPE> is
defined as a code suitable for pointer types (typically C<"i">).

The possible arguments to C<DeclareSub> are shown below.  Each is
listed under the name that is used when passing the arguments in a
hash.

=over 4

=item C<name>

The name of a function exported by C<$lib>.  This argument is ignored
in the non-method forms of C<DeclareSub>.

=item C<ptr>

The address of the C function.  This argument is required in the
non-method forms of C<DeclareSub>.  Either it or the C<name> must be
specified in the method forms.

=item C<return>

The return type of the function, encoded for use with the C<pack>
operator.  Not all of the C<pack> codes are supported, but the
unsupported ones mostly don't make sense as C return types.
Functions that return a C<struct> are not supported.
However, a I<pointer> to struct is okay.

Many C functions return pointers to various things.  If you have a
function that returns C<S<char *>> and all you're interested in is the
string (i.e., the C<char> sequence pointed to, up to the first nul),
then you may use C<"p"> as the return type.  The C<"P"> code (followed
by a number of bytes) is also permissible.

For the case where a returned pointer value must be remembered (for
example, I<malloc()>), use C<PTR_TYPE>.  The returned scalar will be
the pointer itself.  You can use L<unpack> to find the thing pointed
to.

=item C<args>

A list of the types of arguments expected by the function, specified
using the notation of Perl's C<pack> operator.  For example, C<"i">
means an integer, C<"d"> means a double, and C<"p"> means a
nul-terminated string pointer.  If you need to handle pointers to
things other than Perl scalars, use type C<PTR_TYPE>.

Note: you probably don't want to use C<"c"> or C<"s"> here, since C
normally converts the corresponding types (C<char> and C<short>) to
C<int> when passing them to a function.  The C::DynaLib package
may or may not perform such conversions.  Use C<"i"> instead.
Likewise, use C<"I"> in place of C<"C"> or C<"S">, and C<"d"> in place
of C<"f">.  Stick with C<"i">, C<"I">, C<"d">, C<"p">, C<"P">, and
C<PTR_TYPE> if you want to be safe.

Passing structs by value is not generally supported, but you might
find a way to do it with a given compiler by experimenting or
using L<C::DynaLib::Struct>.

=item C<decl>

Allows you to specify a function's calling convention.  This is
possible only with a named-parameter form of C<DeclareSub>. See below
for information about the supported calling conventions.
This overrides LibDecl().

The global $C::DynaLib::decl holds the string for the current
global declaration convention.

=back

=head2 ->LibRef()

A library reference obtained from either C<DynaLoader::dl_load_file>
or the C<C::DynaLib::LibRef> method. 

=head2 ->LibDecl()

Read the name of the calling convention in which this libary was 
declared. The 2nd arg to new, or the default calling convention.
All functions in this library are called with this calling convention 
by default,

=head2 PTR_TYPE()

Type declaration for an opaque pointer, which is either "i", "q",
"l" or "s".

If you want to use strings use "p" instead.

=head2 $DefConv

Name of the currently used default calling convention. See below.

=head2 Parse( '<<EOS' ) - Parse macro, function and struct declarations c-style

The argument may be c-string (best done via '<<EOS' ... EOS)
or a Convert::Binary::C object.

NYI for funcs. Only C::DynaLib::Struct->Parse is implemented yet.
TODO with L<GCC::TranslationUnit>. See F<script/hparse.pl>

=head2 Calling a declared function

The returned value of C<DeclareSub> is a code reference.  Calling
through it results in a call to the C function.  See L<perlref(1)> on
how to use code references.

=head2 C::DynaLib::Callback( \&some_sub, $ret_type, @arg_types )

Using callback routines

Some C functions expect a pointer to another C function as an
argument.  The library code that receives the pointer may use it to
call an application function at a later time.  Such functions are
called I<callbacks>.

This module allows you to use a Perl sub as a C callback, subject to
certain restrictions.  There is a hard-coded maximum number of
callbacks that can be active at any given time.  The default (4) may
be changed by specifying C<CALLBACKS=number> on the F<Makefile.PL>
command line.

A callback's argument and return types are specified using C<pack>
codes, as described above for library functions.  Currently, the
return value must be interpretable as type C<int> or C<void>, so the
only valid codes are C<"i">, C<"I">, and C<"">.  There are also
restrictions on the permissible argument types, especially for the
first argument position.  These limitations are considered bugs to be
fixed someday.

To enable a Perl sub to be used as a callback, you must construct an
object of class C<C::DynaLib::Callback>.  The syntax is

  $cb_ref = new C::DynaLib::Callback( \&some_sub,
                    $ret_type, @arg_types );

where C<$ret_type> and C<@arg_types> are the C<pack>-style types of
the function return value and arguments, respectively.  C<\&some_sub>
must be a code reference or sub name (see L<perlref>).

C<$cb_ref-E<gt>Ptr()> then returns a function pointer.  C code that
calls it will end up calling C<&some_sub>.

=head1 EXAMPLES

This code loads and calls the math library function I<sinh()>.  It
assumes that you have a dynamic version of the math library which will
be found by C<DynaLoader::dl_findfile("-lm")>.  If this doesn't work,
replace C<"-lm"> with the name of your dynamic math library.

  use C::DynaLib;
  $libm = new C::DynaLib("-lm");
  $sinh = $libm->DeclareSub("sinh", "d", "d");
  print "The hyperbolic sine of 3 is ", &{$sinh}(3), "\n";
  # The hyperbolic sine of 3 is 10.0178749274099

The following example uses the C library's I<strncmp()> to compare the
first I<n> characters of two strings:

  use C::DynaLib;
  $libc = new C::DynaLib("-lc");
  $strncmp = $libc->DeclareSub("strncmp", "i", "p", "p", "I");
  $string1 = "foobar";
  $string2 = "foolish";
  $result = &{$strncmp}($string1, $string2, 3);  # $result is 0
  $result = &{$strncmp}($string1, $string2, 4);  # $result is -1

The files F<test.pl> and F<README.win32> contain examples using
callbacks.

=head1 CALLING CONVENTIONS

This section is intended for anyone who is interested in debugging or
extending this module.  You probably don't need to read it just to
I<use> the module.

=head2 The problem

The hardest thing about writing this module is to accommodate the
different calling conventions used by different compilers, operating
systems, and CPU types.

"What's a calling convention?" you may be wondering.  It is how
compiler-generated functions receive their arguments from and make
their return values known to the code that calls them, at the level of
machine instructions and registers.  Each machine has a set of rules
for this.  Compilers and operating systems may use variations even on
the same machine type.  In some cases, it is necessary to support more
than one calling convention on the same system.

"But that's all handled by the compiler!" you might object.  True
enough, if the calling code knows the signature of the called function
at compile time.  For example, consider this C code:

  int foo(double bar, const char *baz);
  ...
  int res;
  res = foo(sqrt(2.0), "hi");

A compiler will generate specific instruction sequences to load the
return value from I<sqrt()> and a pointer to the string C<"hi"> into
whatever registers or memory locations I<foo()> expects to receive
them in, based on its calling convention and the types C<double> and
C<S<char *>>.  Another specific instruction sequence stores the return
value in the variable C<res>.

But when you compile the C code in this module, it must be general
enough to handle all sorts of function argument and return types.

"Why not use varargs/stdarg?"  Most C compilers support a special set
of macros that allow a function to receive a variable number of
arguments of variable type.  When the function receiving the arguments
is compiled, it does not know with what argument types it will be
called.

But the code that I<calls> such a function I<does> know at compile
time how many and what type of arguments it is passing to the varargs
function.  There is no "reverse stdarg" standard for passing types to
be determined at run time.  You can't simply pass a C<va_list> to a
function unless that function is defined to receive a C<va_list>.
This module uses varargs/stdarg where appropriate, but the only
appropriate place is in the callback support.

=head2 The solution (well, half-solution)

Having failed to find a magic bullet to spare us from the whims of
system designers and compiler writers, we are forced to examine the
calling conventions in common use and try to put together some "glue"
code that stands a chance of being portable.

In writing glue code (that which allows code written in one language
to call code in another), an important issue is reliability.  If we
don't get the convention just right, chances are we will get a core
dump (protection fault or illegal instruction).

To write really solid Perl-to-C glue, we would have to use assembly
language and have detailed knowledge of each calling convention.
Compiler source code can be helpful in this regard, and if your
compiler can output assembly code, that helps, too.

However, this is Perl, Perl is meant to be ported, and assembly
language is generally not portable.  This module typically uses C
constructs that happen to work most of the time, as opposed to
assembly code that follows the conventions faithfully.

By avoiding the use of assembly, we lose some reliability and
flexibility.  By loss of reliability, I mean we can expect crashes,
especially on untested platforms.  Lost flexibility means having
restrictions on what parameter types and return types are allowed.

The code for all conventions other than C<hack30> (described below)
relies on C's I<alloca()> function.  Unfortunately, I<alloca()>
itself is not standard, so its use introduces new portability
concerns.  For C<cdecl> (the most general convention) F<Makefile.PL>
creates and runs a test program to try to ferret out any compiler
peculiarities regarding I<alloca()>.  If the test program fails, the
default choice becomes C<hack30>.

=head2 Supported conventions

C<C::DynaLib> currently supports the parameter-passing conventions
listed below.  The module can be compiled with support for one or more
of them by specifying (for example) C<DECL=cdecl> on F<Makefile.PL>'s
command-line.  If none are given, F<Makefile.PL> will try to choose
based on your perl configuration and/or the results of running a test
program.

At run time, a calling convention may be specified using a
named-parameter form of C<DeclareSub> (described above), or a default
may be used.  The first C<DECL=...> supplied to F<Makefile.PL> will be
the default convention.

Note that the convention must match that of the function in the
dynamic library, otherwise crashes or incorrect results are likely to
occur.

=over 4

=item C<cdecl>

All arguments are placed on the stack in reverse order from how the
function is invoked. This seems to be the default for Intel-based
machines and some others.
The generated F<cdecl.h> contains some internal options for this
declaration. Normal stack order is also detected and supported,
though this is no strict _cdecl convention.

=item C<cdecl3> or C<cdecl6>

Same as C<cdecl>, but with special-casing a new gcc limitation that on
function calls without args, the first three or six pointers alloca'd 
are reserved, they may not be overwritten. 

This is not a calling convention, just a fastcall-like hack. 
Argument types longer as the pointer-size will not work for the 
first args, similar to 'hack30'. The subsequent args after the reserved 
words may be longer (double, long double, long long, ...).

The generated F<cdecl.h> contains some internal options for this
declaration. CDECL_STACK_RESERVE = 1, 2, 3, 4 or 6.
Valid names are only C<cdecl3> or C<cdecl6>.

=item C<cdecltr>

Another variant of C<cdecl> with "typed return" values. 
You can try to use this with C<perl Makefile.PL DECL=cdecltr> 
if the default does not compile or work for non-register
return values.

=item C<sparc>

The first 24 bytes of arguments are cast to an array of six C<int>s.
The remaining args (and possibly piece of an arg) are placed on the
stack. Then the C function is called as if it expected six integer
arguments. On a Sparc, the six "pseudo-arguments" are passed in
special registers.

=item C<alpha>

This is similar to the C<sparc> convention, but the pseudo-arguments
have type C<long> instead of C<int>, and all arguments are extended to
eight bytes before being placed in the array.  On the AXP, a special
sequence of assembly instructions is used to ensure that any function
parameters of type C<double> are passed correctly.

=item C<hack30>

This is not really a calling convention, it's just some C code that
will successfully call a function most of the time on a variety of
systems.  All arguments are copied into an array of 6 long integers
(or 30 if 6 is not enough).  The function is called as if it expected
6 (or 30) long arguments.

You will run into problems if the C function either (1) takes more
arguments than can fit in the array, (2) takes some non-long arguments
on a system that passes them differently from longs (but C<cdecl>
currently has the same flaw), or (3) cares if it is passed extra
arguments (Win32 API functions crash because of this).

Because of these problems, the use of C<hack30> is recommended only as
a quick fix until your system's calling convention is supported.

=item C<stdcall> NOT YET IMPLEMENTED FULLY

All arguments are placed on the stack in normal order from how the
function is invoked.

Additionally the callee cleans up the stack, contrary to cdecl,
where the caller cleans up the stack. This is not yet implemented.

This is the default for PASCAL and the Win32 API.
C<stdcall> is detected as C<cdecl> with C<CDECL_REVERSE = 0>.

=item C<fastcall> NOT YET IMPLEMENTED

The ia64 variant of C<alpha>, used in x86_64 libraries, but using
4 registers, not 6. I<(amd64/x86_64 uses rdi,rdx,rcx,rbx for the
first 4 args)>
We try to detect and mimic this behaviour in C<cdecl3> with
C<CDECL_STACK_RESERVE = 4>.

But there are many more fastcall conventions.
See L<http://en.wikipedia.org/wiki/X86_calling_conventions>.

=back

=head1 BUGS

Several unresolved issues surround this module.

=head2 Portability

The "glue" code that allows Perl values to be passed as arguments to C
functions is architecture-dependent.  This is because the authors knows
of no standard means of determining a system's parameter-passing
conventions or passing arguments to a C function whose signature is
not known at compile time.

Although some effort is made in F<Makefile.PL> to find out how
parameters are passed in C, this applies only to the integer type
(Perl's C<I32>, to be precise).  Functions that recieve or return type
C<double>, for example, may not work on systems that use
floating-point registers for this purpose.  Specialized code may be
required to support such systems.

=head2 Robustness

Usually, Perl programs run under the control of the Perl interpreter.
Perl is extremely stable and can almost guarantee an environment free
of the problems of C, such as bad pointers causing memory access
violations.  Some modules use a Perl feature called "XSubs" to call C
code directly from a Perl program.  In such cases, a crash may occur
if the C or XS code is faulty.  However, once the XS module has been
sufficiently debugged, one can be reasonably sure that it will work
right.

Code called through this module lacks such protection.  Since the
association between Perl and C is made at run time, errors due to
incompatible library interfaces or incorrect assumptions have a much
greater chance of causing a crash than with either straight Perl or XS
code.

=head2 Security

This module does not require special privileges to run.  I have no
reason to think it contains any security bugs (except to the extent
that the known bugs impact security).  However, when this module is
installed, Perl programs gain great power to exploit C code which
could potentially have such bugs.  I'm not really sure whether this is
a major issue or not.

I haven't gotten around to understanding Perl's internal tainting
interface, so taint-checking may not accomplish what you expect.  (See
L<perlsec>)

=head2 Deallocation of Resources

To maximize portability, this module uses the F<DynaLoader> interface
to dynamic library linking.  F<DynaLoader>'s main purpose is to
support XS modules, which are loaded once by a program and not (to my
knowledge) unloaded.

L<DynaLoader::dl_unload_file> was added March 2000 for solaris, aix,
linux, hpux, OS/390, symbian, cygwin and win32. For darwin e.g. not.

=head2 Literal and temporary strings

Before Perl 5.00402, it was impossible to pass a string literal as a
pointer-to-nul-terminated-string argument of a C function.  For
example, the following statement (incorrectly) produced the error
C<Modification of a read-only value attempted>:

  &$strncmp("foo", "bar", 3);

To work around this problem, one must assign the value to a variable
and pass the variable in its place, as in

  &$strncmp($dummy1 = "foo", $dummy2 = "bar", 3);

=head2 Callbacks

Only a certain number of callbacks can exist at a time.  Callbacks can
mess up the message produced by C<die> in the presence of nested
C<eval>s.  The Callback code uses global data, and is consequently not
thread-safe.

=head2 Miscellaneous Bugs

There are restrictions on what C data types may be used.  Using
argument types of unusual size may have nasty results.  The techniques
used to pass values to and from C functions are generally hackish and
nonstandard.  Assembly code would be more complete.  Makefile.PL does
too much.  I haven't yet checked for memory leaks.

=head1 TODO

  Support fastcall (regs only) and ia64 (first four in regs, rest on stack)
  calling conventions. Very similar to alpha. See cdecl3 with stack_reserve=4

  Fiddle with autoloading so we don't have to call DeclareSub
  all the time.

  Mangle C++ symbol names.

  Parse C header files (macros, structs and function declarations) via
  Convert::Binary::C and/or GCC::TranslationUnit to make them useful here.
  Convert::Binary::C should be extended to return function types.
  The struct parser using Convert::Binary::C  needs more robustness.
  See hparse.pl for using GCC::TranslationUnit. gccxml might also be
  worthwhile.

  Multiple calling-conventions:
  Add stdcall dynamically on cdecl/cdecl3/hack30 for the W32 API.
  Include and link the useful ones per platform, and define a
  DeclareSub or LibRef syntax.

=head1 LICENSE

Copyright (c) 1997, 2000 by John Tobey.
Copyright (c) 2005, 2007, 2008, 2010 by Reini Urban.
This package is distributed under the same license as Perl itself.
There is no expressed or implied warranty, since it is free software.
See the file README in the top level Perl source directory for details.
The Perl source may be found at:

  http://www.perl.com/CPAN/src/

=head1 AUTHOR

John Tobey C<lt>jtobey@john-edwin-tobey.orgC<gt>

Maintainer: Reini Urban C<lt>rurban@cpan.orgC<gt>

=head1 SEE ALSO

L<perl(1)>, L<perlfunc/pack>, L<perlref>,
L<sigtrap(3)>, L<DynaLoader>, L<perlxs>, L<perlcall>

L<C::DynaLib::Struct> to conveniently declare and access structs.

The other perl FFIs:
L<Win32::API>, L<FFI>, L<P5NCI>, L<CTypes> I<(not yet)>

=cut
