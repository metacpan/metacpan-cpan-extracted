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
package ASPEER::MakeMaker;


#  Pragma
#
use strict;
use warnings;
use vars qw($VERSION $VERSION_GIT_SHA $AUTHORITY);


#  Base packages
#
use ASPEER::MakeMaker::MM::Util;


#  Other modules
#
use File::Basename qw(dirname basename);
use File::Spec;
use File::Temp qw(tempfile);
local $Data::Dumper::Sortkeys=1;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='1.012';
$VERSION_GIT_SHA=do { local(@ARGV, $/, $_); @ARGV=($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined($VERSION_GIT_SHA);


#  Init Done
#
1;
#==============================================================================
#
#  Forward import on to dedicated module
#
sub import {

    push (@_, qw(const_config postamble)) unless $_[1];
    require ASPEER::MakeMaker::MM::Import;
    goto &ASPEER::MakeMaker::MM::Import::import;

}



#==============================================================================
#
#  Methods to support Makefile targets from here on
#
sub dump_param {

    my ($self, $param_hr)=(shift(), arg(@_));
    print Dumper($param_hr);

}



#  Copy template files from this module to target
#
sub util_sync {

    my ($self, $param_hr)=(shift(), arg(@_));
    my ($srce_pn)=@{$param_hr->{'ARGV_AR'}};


    #  Get dest
    #
    msg('util_sync start');
    my $srce_fn=basename($srce_pn) ||
        return err("unable to get basebane from path: $srce_pn");
    my $to_inst_pm_ar=$param_hr->{'TO_INST_PM_AR'} ||
        return err('unable to get TO_INST_PM_AR Makefile param');
    my ($dest_pn)=(grep { /MM\/${srce_fn}$/ } @{$to_inst_pm_ar});
    $dest_pn ||
        return err("unable to get destination for $srce_fn from TO_INST_PM_AR: %s, dest file must exist !", Dumper($to_inst_pm_ar));


    die "usage: $self->util_sync(..., source_filename)\n"
        unless $srce_pn && $dest_pn;

    die "source file not found: $srce_pn\n"
        unless -e $srce_pn;
    die "source is not a regular file: $srce_pn\n"
        unless -f _;
    die "source is not readable: $srce_pn\n"
        unless -r _;

    my $dest_dir=dirname($dest_pn);
    die "destination directory not found: $dest_dir\n"
        unless -d $dest_dir;

    my $srce_abs=File::Spec->rel2abs($srce_pn);
    my $dest_abs=File::Spec->rel2abs($dest_pn);
    die "source and destination are the same path: $srce_abs\n"
        if $srce_abs eq $dest_abs;

    my @srce_stat=stat($srce_pn)
        or die "stat failed for source $srce_pn: $!\n";

    if (-e $dest_pn) {

        my @dest_stat=stat($dest_pn)
            or die "stat failed for destination $dest_pn: $!\n";

        die "source and destination are the same file: $srce_pn -> $dest_pn\n"
            if $srce_stat[0] == $dest_stat[0] && $srce_stat[1] == $dest_stat[1];

    }

    my ($tmp_fh, $tmp_fn)=tempfile('.util_sync.XXXXXXXX', DIR => $dest_dir);
    close($tmp_fh)
        or die "close failed for temporary file $tmp_fn: $!\n";

    eval {
        my $text=slurp($srce_pn);
        my $name=$param_hr->{'NAME'} ||
            die "target module name unavailable for $dest_pn\n";
        my $version=$param_hr->{'VERSION'};
        my $version_from_fn=$param_hr->{'VERSION_FROM'};
        if ($version_from_fn && -f $version_from_fn) {
            require ExtUtils::MakeMaker;
            my $version_from=MM->parse_version($version_from_fn);
            $version=$version_from
                if defined($version_from) && length($version_from) && $version_from ne 'undef';
        }
        $text=~s/\Q$self\E/$name/g;
        $text=~s/(\$VERSION\s*=\s*')[^']*(';)/$1$version$2/
            if defined($version) && length($version);
        blurp($tmp_fn, $text);
        chmod($srce_stat[2] & 07777, $tmp_fn)
            or die "chmod failed for temporary file $tmp_fn: $!\n";
        utime($srce_stat[8], $srce_stat[9], $tmp_fn)
            or die "utime failed for temporary file $tmp_fn: $!\n";
        rename($tmp_fn, $dest_pn)
            or die "rename failed from $tmp_fn to $dest_pn: $!\n";
        1;
    } or do {
        my $err=$@ || 'unknown error';
        unlink($tmp_fn) if -e $tmp_fn;
        die $err;
    };


    msg("updated $dest_pn");
    return 1;
}

__END__

=begin markdown

# ASPEER::MakeMaker

## Name

ASPEER::MakeMaker - parent entry point and shared make-target methods for MakeMaker plugins

## Synopsis

```perl
use ASPEER::MakeMaker;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Some::Module',
    VERSION_FROM => 'lib/Some/Module.pm',
);
```

```perl
use ASPEER::MakeMaker qw(const_config postamble);
```

## Description

`ASPEER::MakeMaker` is the public parent entry point for the distribution. It
sets version metadata, imports shared utility functions from
`ASPEER::MakeMaker::MM::Util`, and forwards import handling to
`ASPEER::MakeMaker::MM::Import`.

When imported without arguments, it requests the `const_config` and `postamble`
MakeMaker sections. The hook installer also enables `depend` and
`post_initialize`, which provide the standard dependency, install-map, and
Git-provenance behavior. Import handling is lazy-loaded and then delegated to
`ASPEER::MakeMaker::MM::Import`.

Child plugins inherit this class and provide a matching `<plugin>::MM` class
and `<plugin>::MM::Constant` package. The shared import layer then dispatches
the plugin's own targets while retaining the common lifecycle behavior. The
module also contains methods intended to be invoked by generated make targets.

## Methods

### import

```perl
use ASPEER::MakeMaker;
use ASPEER::MakeMaker qw(const_config postamble);
```

Enables MakeMaker section hooks. If no sections are supplied, `const_config`
and `postamble` are requested; `depend` and `post_initialize` are installed by
the hook manager as common defaults.

The implementation loads `ASPEER::MakeMaker::MM::Import` and forwards to
its `import` method.

### dump_param

```perl
ASPEER::MakeMaker->dump_param(@makemaker_args, @args);
```

Debugging method. It parses the MakeMaker-style argument list with `arg` and
prints the resulting hash using `Dumper`.

### util_sync

```perl
ASPEER::MakeMaker->util_sync(
    @makemaker_args,
    $source_file,
);
```

Copies one of this distribution's helper files into a consuming
distribution. The method expects the fixed MakeMaker argument block first,
followed by the source file path. The destination is not passed directly.
Instead, `util_sync` derives it from the parsed `TO_INST_PM` MakeMaker value.

The destination lookup uses the source basename and selects an installed module
path ending in:

```text
MM/<source basename>
```

For example, a source named `Util.pm` is matched against a target path ending
in `MM/Util.pm`.

The method validates that:

- a source argument is present
- `TO_INST_PM` can be parsed into `TO_INST_PM_AR`
- the destination can be found in `TO_INST_PM_AR`
- the source exists, is a regular file, and is readable
- the destination directory exists
- the source and destination are not the same path or same file

It reads the source and replaces the helper package name with the consuming
distribution's `NAME`. When `VERSION_FROM` names an available source file, its
declared `$VERSION` is parsed using MakeMaker and applied to the copied helper.
The MakeMaker `VERSION` value is used as a fallback. The result is written
through a temporary file in the destination directory; source mode and
timestamps are preserved before the temporary file is renamed into place.

Current behavior allows overwriting an existing destination file. Current
ASPEER child plugins inherit the shared modules directly; this method is
retained for possible future vendoring or standalone synchronization.

## Usage Conventions

Load this module from `Makefile.PL` before MakeMaker generates the Makefile.
It is build-time infrastructure and is not intended to be part of normal module
runtime behavior.

Target methods should accept the fixed MakeMaker argument block first and use
`ASPEER::MakeMaker::MM::Util::arg` to separate MakeMaker fields from
target-specific arguments.

The module supports Perl 5.8 and later.

## See Also

- `ASPEER::MakeMaker::MM`
- `ASPEER::MakeMaker::MM::Import`
- `ASPEER::MakeMaker::MM::Util`
- `ASPEER::MakeMaker::MM::Constant`

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


=head1 ASPEER::MakeMaker


=head2 Name

ASPEER::MakeMaker - parent entry point and shared make-target methods for MakeMaker plugins


=head2 Synopsis


 use ASPEER::MakeMaker;
 use ExtUtils::MakeMaker;

 WriteMakefile(
     NAME         => 'Some::Module',
     VERSION_FROM => 'lib/Some/Module.pm',
 );

 use ASPEER::MakeMaker qw(const_config postamble);

=head2 Description

C<ASPEER::MakeMaker> is the public parent entry point for the distribution. It
sets version metadata, imports shared utility functions from
C<ASPEER::MakeMaker::MM::Util>, and forwards import handling to
C<ASPEER::MakeMaker::MM::Import>.

When imported without arguments, it requests the C<const_config> and C<postamble>
MakeMaker sections. The hook installer also enables C<depend> and
C<post_initialize>, which provide the standard dependency, install-map, and
Git-provenance behavior. Import handling is lazy-loaded and then delegated to
C<ASPEER::MakeMaker::MM::Import>.

Child plugins inherit this class and provide a matching C<<< <plugin>::MM >>> class
and C<<< <plugin>::MM::Constant >>> package. The shared import layer then dispatches
the plugin's own targets while retaining the common lifecycle behavior. The
module also contains methods intended to be invoked by generated make targets.


=head2 Methods


=head3 import


 use ASPEER::MakeMaker;
 use ASPEER::MakeMaker qw(const_config postamble);
Enables MakeMaker section hooks. If no sections are supplied, C<const_config>
and C<postamble> are requested; C<depend> and C<post_initialize> are installed by
the hook manager as common defaults.

The implementation loads C<ASPEER::MakeMaker::MM::Import> and forwards to
its C<import> method.


=head3 dump_param


 ASPEER::MakeMaker->dump_param(@makemaker_args, @args);
Debugging method. It parses the MakeMaker-style argument list with C<arg> and
prints the resulting hash using C<Dumper>.


=head3 util_sync


 ASPEER::MakeMaker->util_sync(
     @makemaker_args,
     $source_file,
 );
Copies one of this distribution's helper files into a consuming
distribution. The method expects the fixed MakeMaker argument block first,
followed by the source file path. The destination is not passed directly.
Instead, C<util_sync> derives it from the parsed C<TO_INST_PM> MakeMaker value.

The destination lookup uses the source basename and selects an installed module
path ending in:


 MM/<source basename>
For example, a source named C<Util.pm> is matched against a target path ending
in C<MM/Util.pm>.

The method validates that:

=over

=item -

a source argument is present


=item -

C<TO_INST_PM> can be parsed into C<TO_INST_PM_AR>


=item -

the destination can be found in C<TO_INST_PM_AR>


=item -

the source exists, is a regular file, and is readable


=item -

the destination directory exists


=item -

the source and destination are not the same path or same file


=back

It reads the source and replaces the helper package name with the consuming
distribution's C<NAME>. When C<VERSION_FROM> names an available source file, its
declared C<$VERSION> is parsed using MakeMaker and applied to the copied helper.
The MakeMaker C<VERSION> value is used as a fallback. The result is written
through a temporary file in the destination directory; source mode and
timestamps are preserved before the temporary file is renamed into place.

Current behavior allows overwriting an existing destination file. Current
ASPEER child plugins inherit the shared modules directly; this method is
retained for possible future vendoring or standalone synchronization.


=head2 Usage Conventions

Load this module from C<Makefile.PL> before MakeMaker generates the Makefile.
It is build-time infrastructure and is not intended to be part of normal module
runtime behavior.

Target methods should accept the fixed MakeMaker argument block first and use
C<ASPEER::MakeMaker::MM::Util::arg> to separate MakeMaker fields from
target-specific arguments.

The module supports Perl 5.8 and later.


=head2 See Also

=over

=item -

C<ASPEER::MakeMaker::MM>


=item -

C<ASPEER::MakeMaker::MM::Import>


=item -

C<ASPEER::MakeMaker::MM::Util>


=item -

C<ASPEER::MakeMaker::MM::Constant>


=back


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
