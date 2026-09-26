#
#  This file is part of ASPEER::MakeMaker.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package ASPEER::MakeMaker::MM::Util;


#  Pragma
#
use strict;
use warnings;
use vars qw($VERSION $DEBUG $QUIET $VERBOSE @EXPORT);


#  External modules
#
use FindBin qw($RealBin $Script);
FindBin::again();
use Data::Dumper;
use File::Spec;
use IO::File;
local $Data::Dumper::Indent=1;
local $Data::Dumper::Terse=1;
local $Data::Dumper::Sortkeys=1;


#  Export functions
#
use base 'Exporter';
@EXPORT=qw(err msg verbose debug quiet_enable verbose_enable debug_enable Dumper slurp blurp touch arg perlrun);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#  Debugging on ?
#
$Script=~s/\.pl$//;
($Carp::Verbose=++$DEBUG) if $ENV{uc("${Script}_DEBUG")};


#  Done
#
1;

#==================================================================================================


sub quiet_enable {


    #  Turn on quiet flag
    #
    $QUIET=shift() || 1;


}


sub verbose {

    #  Print verbose message
    #
    return if $QUIET || !$VERBOSE;
    return CORE::print STDERR &fmt(@_), $/;

}


sub verbose_enable {

    #  Turn on verbose flag
    #
    $VERBOSE=shift() || 1;

}


sub debug_enable {

    #  Turn on debugging flag
    #
    $DEBUG=shift();

}


sub debug {

    #  Debug
    #
    $DEBUG || return;
    my $debug=sprintf(shift(), @_);
    chomp($debug);
    my ($package, undef, $line, $method) = caller(1);  # '1' for caller of the function
    print STDERR sprintf("[%s:%d] %s$/",
        join('::', grep {$_} ($package, $method)),
        $line,
        $debug
    );

}


sub err {

    #  Quit on errors
    #
    my $msg=&fmt('error: %s', @_);
    CORE::print STDERR $msg, "\n";
    eval {require Carp; 1};
    Carp::croak;

}


sub fmt {


    #  Format message nicely. Always called by err or msg so caller=2
    #
    my $message=sprintf(shift(), @_);
    chomp($message);
    my @caller=(caller(2));
    my $caller=$caller[3] || $caller[0];
    my ($class, $method)=($caller=~/^(.*)::([^:]+)$/);
    $method ||=$caller[0];
    $caller=~s/^_?!(_)//;
    my $format=' @<<<<<<<<<<<<<<<<<< @*';
    local $^A='';
    formline $format, "[$method]", $message;
    return $^A;

}


sub msg {

    #  Print message
    #
    return (CORE::print STDERR &fmt(@_), $/) unless $QUIET;

}


sub slurp {

    #  Slurp in file content
    #
    my ($fn)=@_;
    my $fh=IO::File->new($fn, 'r') ||
        return err("unable to open file $fn, $!");
    local $/=undef;
    my $text=<$fh>;
    $fh->close();
    return $text || '';

}


sub blurp {

    #  Save file content
    #
    my ($fn, $text)=@_;
    my $fh=IO::File->new($fn, 'w') ||
        return err("unable to open $fn for write, $!");
    $fh->print($text) ||
        return err("unable to write file $fn, $!");
    $fh->close() ||
        return err("unable to close file $fn, $!");
    return 1;

}


sub touch {

    my ($fn)=@_;
    return 1 if -e $fn;
    return blurp($fn, '');

}


sub perlrun {


    #  Get self ref
    #
    my ($self, $mm_or)=@_;


    #  Construct PERL runtime
    #
    my $perl_inc_ar=&perl_inc;


    #  And modules
    #
    my $perl_mod_ar=&perl_mod;
    my @import_class;
    {
        no warnings qw(once);
        @import_class=@MY::ExtUtils_MM_Import_Order;
    }
    @import_class=(ref($self)) unless @import_class;
    my %import_class=map {$_=>1} @import_class;
    my @perl_mod_no_import=grep {!$import_class{$_}} @{$perl_mod_ar};
    my %seen;
    my @perl_mod=grep {!$seen{$_}++} (
        @perl_mod_no_import,
        @import_class
    );


    #  Now construct final PERLRUN string
    #
    my $perlrun;
    my $quote_cr=$mm_or && $mm_or->can('quote_literal');
    my $perlrun_inc=join(' ', map {
        my $arg="-I$_";
        $quote_cr ? $quote_cr->($mm_or, $arg) : $arg
    } @{$perl_inc_ar});
    my $perlrun_mod=join(' ', map {
        my $class=$_;
        no warnings qw(once);
        my $import_tag_ar=$MY::ExtUtils_MM_Import_Tag{$class};
        $import_tag_ar && @{$import_tag_ar} ?
            sprintf('-M%s=%s', $class, join(',', @{$import_tag_ar})) :
            "-M$class"
    } @perl_mod);
    $perlrun="\$(PERL) $perlrun_inc $perlrun_mod";


    #  And return
    #
    return $perlrun

}


sub perl_mod {

    my %seen=(
        __PACKAGE__ => 1
    );
    my @m=sort
        grep { !$seen{$_}++ }
        map {(my $m = $_) =~ s{\.pm$}{}; $m =~ s{/}{::}g; $m;}
        grep { m{^ExtUtils/} }
        keys %INC;
    return \@m;
}


sub perl_inc {

    #  Return array ref of any additional libraries specified via command line (-I)
    #
    my %default_inc=map { $_ => 1 } @{ perl_inc_default() || [] };
    my %seen;
    my @lib=grep {
        !$default_inc{$_} && !$seen{$_}++
    } map {
        File::Spec->rel2abs($_)
    } grep {
        defined($_) && !ref($_) && length($_) && -d $_
    } @INC;

    return \@lib;
}


sub perl_inc_default {

    my @default_inc;
    if (open(my $perl_fh, '-|', $^X, '-e', 'print join qq(\0), grep { defined && !ref && length && -d } @INC')) {
        local $/;
        my $inc=<$perl_fh>;
        close($perl_fh);
        @default_inc=map {
            File::Spec->rel2abs($_)
        } split(/\0/, ($inc || ''));
    }
    return \@default_inc;
}


sub arg {

    #  Convert MakeMaker target args to a named parameter hash.
    #
    my (%param, @argv);
    (@param{qw(
        NAME
        NAME_SYM
        DISTNAME
        DISTVNAME
        VERSION
        VERSION_SYM
        VERSION_FROM
        LICENSE AUTHOR
        TO_INST_PM
        EXE_FILES
        DIST_DEFAULT_TARGET
        SUFFIX
        ABSTRACT_FROM
    )}, @argv)=@_;
    $param{'TO_INST_PM_AR'}=[split /\s+/, $param{'TO_INST_PM'}];
    $param{'EXE_FILES_AR'}=[split /\s+/, $param{'EXE_FILES'}];
    $param{'ARGV_AR'}=\@argv;
    return \%param

}

__END__

=begin markdown

# ASPEER::MakeMaker::MM::Util

## Name

ASPEER::MakeMaker::MM::Util - shared utility functions for MakeMaker helpers

## Synopsis

```perl
use ASPEER::MakeMaker::MM::Util;

msg('building %s', $name);
my $text = slurp($file);
blurp($file, $text);

my $param = arg(@make_target_args);
my $perlrun = perlrun($hook_object, $make_maker_object);
```

## Description

`ASPEER::MakeMaker::MM::Util` exports support functions used by the rest
of the distribution. The helpers cover formatted messages, debugging, simple
file I/O, MakeMaker target argument parsing, and construction of a Perl command
for generated make targets.

All listed functions are exported by default.

## Functions

### quiet_enable

```perl
quiet_enable();
quiet_enable($value);
```

Enables quiet mode. When quiet mode is active, `msg` and `verbose` output is
suppressed.

### verbose_enable

```perl
verbose_enable();
verbose_enable($value);
```

Enables verbose output for `verbose`.

### debug_enable

```perl
debug_enable($value);
```

Sets the debug flag used by `debug`.

The module also enables debug mode at load time if an environment variable
named after the current script plus `_DEBUG` is set.

### msg

```perl
msg('message %s', $value);
```

Prints a formatted message to standard error unless quiet mode is enabled.

### verbose

```perl
verbose('message %s', $value);
```

Prints a formatted message to standard error only when verbose mode is enabled
and quiet mode is not enabled.

### debug

```perl
debug('message %s', $value);
```

Prints a debug message to standard error when debug mode is enabled. The output
includes caller package, method, and line information.

### err

```perl
err('unable to process %s', $file);
```

Prints a formatted error message and croaks.

### slurp

```perl
my $text = slurp($file);
```

Reads and returns the full contents of a file using `IO::File`. On failure,
calls `err`.

### blurp

```perl
blurp($file, $text);
```

Writes text to a file, replacing any existing content. Open, write, and close
failures call `err`.

### touch

```perl
touch($file);
```

Ensures a file exists. If the file is missing, creates it as an empty file.

### arg

```perl
my $param = arg(@args);
```

Parses the fixed argument sequence passed by generated make targets into a hash
reference. The recognized fields are:

- `NAME`
- `NAME_SYM`
- `DISTNAME`
- `DISTVNAME`
- `VERSION`
- `VERSION_SYM`
- `VERSION_FROM`
- `LICENSE`
- `AUTHOR`
- `TO_INST_PM`
- `EXE_FILES`
- `DIST_DEFAULT_TARGET`
- `SUFFIX`
- `ABSTRACT_FROM`

Any remaining values are stored in `ARGV_AR`.

The helper also derives:

- `TO_INST_PM_AR` from whitespace-splitting `TO_INST_PM`
- `EXE_FILES_AR` from whitespace-splitting `EXE_FILES`

### perlrun

```perl
my $command = perlrun($hook_object, $make_maker_object);
```

Builds the global Makefile `PERLRUN` command beginning with `$(PERL)`. It
includes non-default local `@INC` directories as `-I` options, loaded
`ExtUtils::*` modules as `-M` options, and the registered MakeMaker extension
classes in activation order. Modules are emitted once. When supplied, the
active MakeMaker object quotes `-I` arguments for the platform shell.

This value is installed into MakeMaker's `PERLRUN` macro by
`ASPEER::MakeMaker::MM::Import::const_config` and is reused by generated
targets.

## Usage Conventions

Functions in this module are intended for build-time helper code and generated
make target methods. New make target methods should use `arg` to decode their
calling arguments instead of reading positional values directly.

## See Also

- `ASPEER::MakeMaker`
- `ASPEER::MakeMaker::MM`
- `ASPEER::MakeMaker::MM::Import`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of ASPEER::MakeMaker.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 ASPEER::MakeMaker::MM::Util


=head2 Name

ASPEER::MakeMaker::MM::Util - shared utility functions for MakeMaker helpers


=head2 Synopsis


 use ASPEER::MakeMaker::MM::Util;

 msg('building %s', $name);
 my $text = slurp($file);
 blurp($file, $text);

 my $param = arg(@make_target_args);
 my $perlrun = perlrun($hook_object, $make_maker_object);

=head2 Description

C<ASPEER::MakeMaker::MM::Util> exports support functions used by the rest
of the distribution. The helpers cover formatted messages, debugging, simple
file I/O, MakeMaker target argument parsing, and construction of a Perl command
for generated make targets.

All listed functions are exported by default.


=head2 Functions


=head3 quiet_enable


 quiet_enable();
 quiet_enable($value);
Enables quiet mode. When quiet mode is active, C<msg> and C<verbose> output is
suppressed.


=head3 verbose_enable


 verbose_enable();
 verbose_enable($value);
Enables verbose output for C<verbose>.


=head3 debug_enable


 debug_enable($value);
Sets the debug flag used by C<debug>.

The module also enables debug mode at load time if an environment variable
named after the current script plus C<_DEBUG> is set.


=head3 msg


 msg('message %s', $value);
Prints a formatted message to standard error unless quiet mode is enabled.


=head3 verbose


 verbose('message %s', $value);
Prints a formatted message to standard error only when verbose mode is enabled
and quiet mode is not enabled.


=head3 debug


 debug('message %s', $value);
Prints a debug message to standard error when debug mode is enabled. The output
includes caller package, method, and line information.


=head3 err


 err('unable to process %s', $file);
Prints a formatted error message and croaks.


=head3 slurp


 my $text = slurp($file);
Reads and returns the full contents of a file using C<IO::File>. On failure,
calls C<err>.


=head3 blurp


 blurp($file, $text);
Writes text to a file, replacing any existing content. Open, write, and close
failures call C<err>.


=head3 touch


 touch($file);
Ensures a file exists. If the file is missing, creates it as an empty file.


=head3 arg


 my $param = arg(@args);
Parses the fixed argument sequence passed by generated make targets into a hash
reference. The recognized fields are:

=over

=item -

C<NAME>


=item -

C<NAME_SYM>


=item -

C<DISTNAME>


=item -

C<DISTVNAME>


=item -

C<VERSION>


=item -

C<VERSION_SYM>


=item -

C<VERSION_FROM>


=item -

C<LICENSE>


=item -

C<AUTHOR>


=item -

C<TO_INST_PM>


=item -

C<EXE_FILES>


=item -

C<DIST_DEFAULT_TARGET>


=item -

C<SUFFIX>


=item -

C<ABSTRACT_FROM>


=back

Any remaining values are stored in C<ARGV_AR>.

The helper also derives:

=over

=item -

C<TO_INST_PM_AR> from whitespace-splitting C<TO_INST_PM>


=item -

C<EXE_FILES_AR> from whitespace-splitting C<EXE_FILES>


=back


=head3 perlrun


 my $command = perlrun($hook_object, $make_maker_object);
Builds the global Makefile C<PERLRUN> command beginning with C<$(PERL)>. It
includes non-default local C<@INC> directories as C<-I> options, loaded
C<ExtUtils::*> modules as C<-M> options, and the registered MakeMaker extension
classes in activation order. Modules are emitted once. When supplied, the
active MakeMaker object quotes C<-I> arguments for the platform shell.

This value is installed into MakeMaker's C<PERLRUN> macro by
C<ASPEER::MakeMaker::MM::Import::const_config> and is reused by generated
targets.


=head2 Usage Conventions

Functions in this module are intended for build-time helper code and generated
make target methods. New make target methods should use C<arg> to decode their
calling arguments instead of reading positional values directly.


=head2 See Also

=over

=item -

C<ASPEER::MakeMaker>


=item -

C<ASPEER::MakeMaker::MM>


=item -

C<ASPEER::MakeMaker::MM::Import>


=back


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
