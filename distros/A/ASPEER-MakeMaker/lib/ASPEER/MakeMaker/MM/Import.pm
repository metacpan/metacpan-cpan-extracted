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
package ASPEER::MakeMaker::MM::Import;


#  Pragma
#
use strict qw(vars);
use warnings;
use vars qw($VERSION);


#  Base Packages
#
use ASPEER::MakeMaker::MM;
use ASPEER::MakeMaker::MM::Util;
use ASPEER::MakeMaker::MM::Constant;


#  External Packages
#
use ExtUtils::MakeMaker;
use Software::LicenseUtils;
use File::Basename qw(basename);
use Tie::File;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#  All done, init finished
#
1;


#======================================================================================================================


sub import {


    #  Manage activation of various ExtUtils::Makemaker sections for this class.
    #
    #  use ExtUtils::<This Package> qw(const_config) to just replace the macros section of the Makefile
    #  .. qw(dist_ci) to replace standard MakeMaker targets with our own
    #  .. qw(:all) or no tag (i.e defaults) to all targers
    #
    #
    my ($class, @section)=@_;
    return if $_{$class}{'loaded'}++;
    return unless ($0=~/Makefile\.PL$/);
    msg("initializing $class import");


    #  Remember extension activation order for generated PERLRUN commands
    #
    {
        no warnings qw(once);
        push(@MY::ExtUtils_MM_Import_Order, $class)
            unless grep {$class eq $_} @MY::ExtUtils_MM_Import_Order;
        $MY::ExtUtils_MM_Import_Tag{$class}=[@section];
    }


    #  Get params, bless self ref and remember import tags spec'd for later
    #  re-use
    #
    my $self=bless (\my %self, $class);


    #  Build chain of MM modules loaded for this OS so we can search for
    #  code ref's associated with various ExtUtils::MakeMaker sections;
    #
    my @mm_isa=grep {/^ExtUtils::MM/} @ExtUtils::MM::ISA;
    push @mm_isa, map { @{"${_}::ISA"} } @mm_isa;
    die('no ExtUtils::MM inheritance found in @ISA') unless @mm_isa;


    #  Sections to augment with additional targets
    #
    {   no warnings qw(redefine once);
        foreach my $section (qw(const_config depend postamble post_initialize), @section) {
            next if $self{$section};
            $self{$section} =*{"ExtUtils::MM::${section}"}{CODE}; # unless (*{"ExtUtils::MM::${section}"}{CODE} eq \&{$section});
            $self{$section} ||= do {
                my ($cr)=grep {$_} (map { $_->can($section) } @mm_isa);
                $cr || sub {''};
            };
            $self{$section} ||= ExtUtils::MM_Unix->can($section) || sub {''};
            my $sub=sprintf('%s::MM::%s', ref($self), $section);
            if (my $cr=*{$sub}{CODE}) {
                msg("import $section from $sub");
                *{"ExtUtils::MM::${section}"}=sub { $cr->($self, @_) };
            }
            else {
                msg("import $section from %s", __PACKAGE__);
                *{"ExtUtils::MM::${section}"}=sub { &{$section}($self, @_) };
            }
        }
    }
    msg("initializing $class import complete");

}


sub const_config {


    #  Get self ref
    #
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original const_config ready for append
    #
    my $const_config=$self->{$section}($mm_or, @param);


    #  Import Constants into macros
    #
    my $constant_hr=\%{sprintf('%s::MM::Constant::Constant', ref($self))};
    foreach my $key (keys %{$constant_hr}) {

        #  Update macros with our config
        #
        next if $key eq 'MM_PREFIX';
        my $value=$constant_hr->{$key};
        msg("add macro: $key, value: $value");
        $mm_or->{'macro'}{$key}=$value;

    }


    #   Update license data. Get license type and author
    #
    my $license=$mm_or->{'LICENSE'};
    my @author=@{$mm_or->{'AUTHOR'} || []};
    my $author=shift(@author);


    #  Publish supplied values and enrich complete license metadata
    #
    $mm_or->{'macro'}{'LICENSE'}=$license if defined($license) && length($license);
    $mm_or->{'macro'}{'AUTHOR'}=$author if defined($author) && length($author);
    if ($license && $author) {
        my @license_module=Software::LicenseUtils->guess_license_from_meta_key($license);
        @license_module ||
            return err("unable to determine correct license module from string: $license");
        (@license_module > 1) &&
            return err("ambiguous license string: $license, resolves to %s", join(',', @license_module));
        my $license_or=(shift @license_module)->new({holder => $author});
        $mm_or->{'META_MERGE'}{'resources'}{'license'}=$license_or->url();
    }


    #  Now construct final PERLRUN string
    #
    my $perlrun=&perlrun($self, $mm_or);
    $mm_or->{'PERLRUN'}=$perlrun;


    #  Keep copy of DIST_DEFAULT
    #
    $mm_or->{'macro'}{'DIST_DEFAULT_TARGET'}=$mm_or->{'DIST_DEFAULT'};


    #  Return whatever our parent does
    #
    return $const_config;


}



#  MakeMaker::MY replacement depend section
#
sub depend {


    #  Get self ref
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original and modify
    #
    my $depend=$self->{$section}($mm_or, @param);


    #  Add VERSION_FROM without replacing existing dependencies
    #
    $depend='' unless defined($depend);
    if ($mm_or->{'VERSION_FROM'} &&
        $depend!~/^Makefile\s*:[^\n]*\$\(VERSION_FROM\)/m) {
        $depend.=$/ if length($depend) && substr($depend, -1) ne $/;
        $depend.='Makefile : $(VERSION_FROM)'.$/;
    }
    return $depend;

}


#  MakeMaker::MY replacement postamble section
#
sub postamble {


    #  Get self ref
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original postamble ready for append
    #
    my $postamble=$self->{$section}($mm_or, @param);


    #  Get this extension's postamble template
    #
    my $constant_hr=\%{sprintf('%s::MM::Constant::Constant', ref($self))};
    if (my $patch_fn=$constant_hr->{'TEMPLATE_POSTAMBLE_FN'}) {


        #  Yes, exists as var so implement
        #
        msg('using template: %s', basename($patch_fn));


        #  Generate a platform-safe target command and append the template
        #
        my $mm_prefix=$constant_hr->{'MM_PREFIX'} || mm_prefix(ref($self));
        my $pm_macro="${mm_prefix}_PM";
        my $argv_macro="${mm_prefix}_PM_ARGV";
        my $target_macro="${mm_prefix}_PM_TARGET";
        my $pm_target=$mm_or->oneliner(sprintf(
            'my $method=shift(@ARGV); $(%s)->$method($(%s), @ARGV)',
            $pm_macro,
            $argv_macro
        ));
        $pm_target=~s/^\$\(ABSPERLRUN\)/\$\(PERLRUN\) -M\$\($pm_macro\)/;
        $postamble.="$target_macro=$pm_target$/";
        $postamble.=slurp($patch_fn);


    }


    #  All done, return result
    #
    return $postamble;

}


sub post_initialize {


    #  Add license file, other support files here
    #
    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));


    #  Get original postamble ready for append
    #
    my $post_initialize=$self->{$section}($mm_or, @param);


    #  Add license file
    #
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE' if -e 'LICENSE';


    #  Don't install docs/tmp files etc.
    #
    my %pm=map { $_=>$mm_or->{'PM'}{$_} } grep { !/\.(?:md|xml|pod|bak|tmp|new|old|ref|0|1)$/ } keys %{$mm_or->{'PM'}};
    $mm_or->{'PM'}=\%pm;


    #  Update and install Git ref if needed/available
    #
    my $devnull=File::Spec->devnull();
    my $version_from_fn=$mm_or->{'VERSION_FROM'};
    my $git_ref_fn=$version_from_fn && "${version_from_fn}.sha";
    if ($version_from_fn && -f $version_from_fn &&
        (my $git_version=qx(git rev-parse --short HEAD 2>$devnull)) && !$?) {
        chomp($git_version);
        tie(my @lines, 'Tie::File', $git_ref_fn) ||
            die("error on Tie::File, $!");
        @lines=($git_version)
            unless @lines==1 && $lines[0] eq $git_version;
    }
    if ($git_ref_fn && -f $git_ref_fn) {
        if ($mm_or->{'PM'}{$version_from_fn}) {
            $mm_or->{'PM'}{$git_ref_fn}=$mm_or->{'PM'}{$version_from_fn}.'.sha';
        }
        elsif (grep {$version_from_fn eq $_} @{$mm_or->{'EXE_FILES'}}) {
            (my $git_ref_base_fn=$git_ref_fn)=~s{^.*[/\\]}{};
            $mm_or->{'PM'}{$git_ref_fn}='$(INST_SCRIPT)/'.$git_ref_base_fn;
        }
    }

    #  Done
    #
    return $post_initialize

}


#  Construct a default Makefile macro prefix from an extension class
#
sub mm_prefix {

    my $class=shift();
    $class=~s/::/_/g;
    return uc($class)

}


#  Not used yet
#
sub special_targets {

    my ($self, $mm_or, @param)=@_;
    (my $section = (caller(0))[3]) =~ s/^.*:://;
    msg("generating %s $section", ref($self));

    my $special_targets=$self->{$section}($mm_or, @param);
    $special_targets=~s/\.PHONY:\s+(.*)/\.PHONY: $1 cpanfile/m;
    return $special_targets;

}



__END__

=begin markdown

# ASPEER::MakeMaker::MM::Import

## Name

ASPEER::MakeMaker::MM::Import - MakeMaker hook installer and active section implementations

## Synopsis

```perl
use ASPEER::MakeMaker;
```

```perl
use ASPEER::MakeMaker qw(const_config postamble);
```

Usually this module is not used directly. It is loaded by
`ASPEER::MakeMaker::import`.

## Description

`ASPEER::MakeMaker::MM::Import` installs and implements the current
`ExtUtils::MakeMaker` hooks for this distribution.

It only performs hook installation while running under a `Makefile.PL` process.
If imported outside that context, it returns without modifying `ExtUtils::MM`.

The module always considers `const_config`, `depend`, `postamble`, and
`post_initialize`, and also honors any additional section names passed by the
caller. For each section, it saves the original MakeMaker implementation and
then replaces `ExtUtils::MM::$section` with a wrapper.

If a method named `<importing class>::MM::<section>` exists, the wrapper calls
that method. Otherwise it calls the section method implemented in this module.

## Import Behavior

```perl
ASPEER::MakeMaker::MM::Import->import(@sections);
```

The import process:

1. Returns immediately if this class has already been loaded.
2. Returns immediately unless the current process name matches `Makefile.PL`.
3. Builds a list of active `ExtUtils::MM::*` classes from `@ExtUtils::MM::ISA`.
4. Saves the original implementation for each requested section.
5. Replaces the matching `ExtUtils::MM::*` symbol with a wrapper.

The original method is stored in the hook object's internal hash and is called
by the replacement section methods before augmenting the result.

The importing class and requested section names are also recorded in activation
order. Generated `PERLRUN` commands use this registry so chained extensions are
reloaded once each and in the same order.

## Section Methods

### const_config

```perl
ASPEER::MakeMaker::MM::Import::const_config($hook, $mm, @args);
```

Calls the original MakeMaker `const_config`, then copies constants from
`ASPEER::MakeMaker::MM::Constant` into the Makefile macro table.
`MM_PREFIX` is private hook configuration and is not emitted as a Makefile
macro.

It publishes supplied license metadata:

- copies `LICENSE` and the first `AUTHOR` into the macro table when supplied
- uses `Software::LicenseUtils` to resolve the license when both are supplied
- writes the resulting URL into `META_MERGE.resources.license`

Neither `LICENSE` nor `AUTHOR` is required by this helper.

The method then installs a global `PERLRUN` command which preserves loaded
MakeMaker extensions and local include paths. Include arguments are quoted
through the active MakeMaker implementation. It also stores `DIST_DEFAULT` in
the `DIST_DEFAULT_TARGET` macro.

### depend

```perl
ASPEER::MakeMaker::MM::Import::depend($hook, $mm, @args);
```

Calls the original MakeMaker `depend` section. When `VERSION_FROM` is set, it
appends the following dependency unless it is already present:

```make
Makefile : $(VERSION_FROM)
```

### postamble

```perl
ASPEER::MakeMaker::MM::Import::postamble($hook, $mm, @args);
```

Calls the original MakeMaker `postamble`, then appends the template named by
`TEMPLATE_POSTAMBLE_FN` in the importing class's `MM::Constant` package.

The module uses `MM_PREFIX` from the importing class's `MM::Constant` package
when naming its command macro. If it is absent, the class name is uppercased
and `::` is replaced with `_`. MakeMaker's `oneliner` method generates the
platform-specific Perl command. The command deliberately uses the global
`PERLRUN` macro so the same extension environment is available to generated
targets, then explicitly reloads the dispatch module belonging to this prefix.
This keeps the target callable when a subsequently loaded extension replaces
the shared `PERLRUN` value.

The parent class's bundled template is:

```text
lib/ASPEER/MakeMaker/MM/postamble.inc
```

### post_initialize

```perl
ASPEER::MakeMaker::MM::Import::post_initialize($hook, $mm, @args);
```

Calls the original MakeMaker `post_initialize` section, then:

- installs `LICENSE` when it exists
- excludes `.md`, `.xml`, `.pod`, `.bak`, `.tmp`, `.new`, `.old`, `.ref`,
  `.0`, and `.1` sources from the install map
- records the current short Git revision beside `VERSION_FROM` when Git and
  the source file are available
- avoids rewriting an unchanged Git revision file
- installs the revision file beside its module or executable

Executable names remain exactly as declared in `EXE_FILES`; the helper does not
remove `.pl` or `.sh` extensions.

## Usage Conventions

Callers should normally use `ASPEER::MakeMaker`, not this module
directly.

Because the module modifies `ExtUtils::MM` symbol table entries, it should be
used only during Makefile generation.

## Diagnostics

The module emits formatted status messages through
`ASPEER::MakeMaker::MM::Util::msg`. It dies if no `ExtUtils::MM`
inheritance chain can be found, if a supplied license string cannot be resolved
unambiguously, or if a Git-revision sidecar cannot be opened.

## See Also

- `ASPEER::MakeMaker`
- `ASPEER::MakeMaker::MM`
- `ASPEER::MakeMaker::MM::Constant`
- `ASPEER::MakeMaker::MM::Util`
- `ExtUtils::MakeMaker`

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


=head1 ASPEER::MakeMaker::MM::Import


=head2 Name

ASPEER::MakeMaker::MM::Import - MakeMaker hook installer and active section implementations


=head2 Synopsis


 use ASPEER::MakeMaker;

 use ASPEER::MakeMaker qw(const_config postamble);
Usually this module is not used directly. It is loaded by
C<ASPEER::MakeMaker::import>.


=head2 Description

C<ASPEER::MakeMaker::MM::Import> installs and implements the current
C<ExtUtils::MakeMaker> hooks for this distribution.

It only performs hook installation while running under a C<Makefile.PL> process.
If imported outside that context, it returns without modifying C<ExtUtils::MM>.

The module always considers C<const_config>, C<depend>, C<postamble>, and
C<post_initialize>, and also honors any additional section names passed by the
caller. For each section, it saves the original MakeMaker implementation and
then replaces C<ExtUtils::MM::$section> with a wrapper.

If a method named C<<< <importing class>::MM::<section> >>> exists, the wrapper calls
that method. Otherwise it calls the section method implemented in this module.


=head2 Import Behavior


 ASPEER::MakeMaker::MM::Import->import(@sections);
The import process:

=over

=item 1.

Returns immediately if this class has already been loaded.


=item 2.

Returns immediately unless the current process name matches C<Makefile.PL>.


=item 3.

Builds a list of active C<ExtUtils::MM::*> classes from C<@ExtUtils::MM::ISA>.


=item 4.

Saves the original implementation for each requested section.


=item 5.

Replaces the matching C<ExtUtils::MM::*> symbol with a wrapper.


=back

The original method is stored in the hook object's internal hash and is called
by the replacement section methods before augmenting the result.

The importing class and requested section names are also recorded in activation
order. Generated C<PERLRUN> commands use this registry so chained extensions are
reloaded once each and in the same order.


=head2 Section Methods


=head3 const_config


 ASPEER::MakeMaker::MM::Import::const_config($hook, $mm, @args);
Calls the original MakeMaker C<const_config>, then copies constants from
C<ASPEER::MakeMaker::MM::Constant> into the Makefile macro table.
C<MM_PREFIX> is private hook configuration and is not emitted as a Makefile
macro.

It publishes supplied license metadata:

=over

=item -

copies C<LICENSE> and the first C<AUTHOR> into the macro table when supplied


=item -

uses C<Software::LicenseUtils> to resolve the license when both are supplied


=item -

writes the resulting URL into C<META_MERGE.resources.license>


=back

Neither C<LICENSE> nor C<AUTHOR> is required by this helper.

The method then installs a global C<PERLRUN> command which preserves loaded
MakeMaker extensions and local include paths. Include arguments are quoted
through the active MakeMaker implementation. It also stores C<DIST_DEFAULT> in
the C<DIST_DEFAULT_TARGET> macro.


=head3 depend


 ASPEER::MakeMaker::MM::Import::depend($hook, $mm, @args);
Calls the original MakeMaker C<depend> section. When C<VERSION_FROM> is set, it
appends the following dependency unless it is already present:


 Makefile : $(VERSION_FROM)

=head3 postamble


 ASPEER::MakeMaker::MM::Import::postamble($hook, $mm, @args);
Calls the original MakeMaker C<postamble>, then appends the template named by
C<TEMPLATE_POSTAMBLE_FN> in the importing class's C<MM::Constant> package.

The module uses C<MM_PREFIX> from the importing class's C<MM::Constant> package
when naming its command macro. If it is absent, the class name is uppercased
and C<::> is replaced with C<_>. MakeMaker's C<oneliner> method generates the
platform-specific Perl command. The command deliberately uses the global
C<PERLRUN> macro so the same extension environment is available to generated
targets, then explicitly reloads the dispatch module belonging to this prefix.
This keeps the target callable when a subsequently loaded extension replaces
the shared C<PERLRUN> value.

The parent class's bundled template is:


 lib/ASPEER/MakeMaker/MM/postamble.inc

=head3 post_initialize


 ASPEER::MakeMaker::MM::Import::post_initialize($hook, $mm, @args);
Calls the original MakeMaker C<post_initialize> section, then:

=over

=item -

installs C<LICENSE> when it exists


=item -

excludes C<.md>, C<.xml>, C<.pod>, C<.bak>, C<.tmp>, C<.new>, C<.old>, C<.ref>,
  C<.0>, and C<.1> sources from the install map


=item -

records the current short Git revision beside C<VERSION_FROM> when Git and
  the source file are available


=item -

avoids rewriting an unchanged Git revision file


=item -

installs the revision file beside its module or executable


=back

Executable names remain exactly as declared in C<EXE_FILES>; the helper does not
remove C<.pl> or C<.sh> extensions.


=head2 Usage Conventions

Callers should normally use C<ASPEER::MakeMaker>, not this module
directly.

Because the module modifies C<ExtUtils::MM> symbol table entries, it should be
used only during Makefile generation.


=head2 Diagnostics

The module emits formatted status messages through
C<ASPEER::MakeMaker::MM::Util::msg>. It dies if no C<ExtUtils::MM>
inheritance chain can be found, if a supplied license string cannot be resolved
unambiguously, or if a Git-revision sidecar cannot be opened.


=head2 See Also

=over

=item -

C<ASPEER::MakeMaker>


=item -

C<ASPEER::MakeMaker::MM>


=item -

C<ASPEER::MakeMaker::MM::Constant>


=item -

C<ASPEER::MakeMaker::MM::Util>


=item -

C<ExtUtils::MakeMaker>


=back


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
