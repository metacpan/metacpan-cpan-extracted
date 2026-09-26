#
#  This file is part of ASPEER::MakeMaker::Markdown::Pod.
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
package ASPEER::MakeMaker::Markdown::Pod::MM;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA $IMPORTED);
use warnings;
no warnings qw(uninitialized);
sub BEGIN {local $^W=0}


#  Base packages and shared utility functions
#
use ASPEER::MakeMaker::MM ();
use ASPEER::MakeMaker::MM::Util;
use ASPEER::MakeMaker::Markdown::Pod::MM::Constant ();
@ISA=qw(ASPEER::MakeMaker::MM);


#  External Packages
#
use Digest::MD5 qw(md5_hex);


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.013';


#  All done, init finished
#
1;


#======================================================================================================================

#  Makefile targets from here down
#
sub doc {


    #  Convert DocBook articles under doc to sibling Markdown files
    #
    my ($self, $param_hr)=(shift(), arg(@_));
    msg($self);
    if (-d 'doc') {
        require Docbook::Convert::Pandoc;
        my $docbook_or=Docbook::Convert::Pandoc->new();
        my $changed_fn_ar=$docbook_or->convert_articles('doc');
        msg('docbook: %s: updated', $_) foreach @{$changed_fn_ar};
    }


    #  Convert MD files to POD
    #
    my $exe_files_ar=$param_hr->{'EXE_FILES_AR'};
    my %exe_files=map {$_ => 1} @{$exe_files_ar};
    require Markdown::Pod::Embed;


    #  Get manifest - only convert files in manifest
    #
    require ExtUtils::Manifest;
    my $manifest_hr=ExtUtils::Manifest::maniread();


    #  Hash to hold files we generate so not processed twice
    #
    my %ignore_fn;


    #  Look for all Markdown files ignoring ones we created ourselves
    #
    my @manifest_md_fn=sort grep {/\.md$/ && !m{^t/}} keys %{$manifest_hr};
    @manifest_md_fn=grep    {!$ignore_fn{$_}} @manifest_md_fn;


    #  Iterate
    #
    foreach my $fn (@manifest_md_fn) {

        #  Get target file name. If foo.pm.md, bar.pl.md and foo.pm or bar.pl exists, then
        #  convert Markdown to POD and install into target file.
        #

        #
        (my $target_fn=$fn)=~s/\.md$//;

        if ($target_fn=~/\.pm$/ || $target_fn=~/\.pl$/ || $exe_files{$target_fn}) {
            unless (-f $target_fn) {
                verbose("markpod: %s -> %s: skipped, missing target", $fn, $target_fn);
                next;
            }
            msg("markpod: %s -> %s: starting merge", $fn, $target_fn);
            my $markpod_or=Markdown::Pod::Embed->new();
            my $pod_changed=$markpod_or->markpod_process_and_update($target_fn);
            if (!defined $pod_changed) {
                msg("markpod: %s -> %s: finished, skipped", $fn, $target_fn);
            }
            elsif ($pod_changed) {
                msg("markpod: %s -> %s: finished, updated pod", $fn, $target_fn);
            }
            else {
                msg("markpod: %s -> %s: finished, no changes", $fn, $target_fn);
            }
        }
        else {
            verbose("markpod: %s -> %s: skipped, unsupported target", $fn, $target_fn);

        }

    }


    #  Done
    #
    return undef;

}


sub readme {


    #  Build README files from README.md or VERSION_FROM markdown
    #
    my ($self, $param_hr)=(shift(), arg(@_));
    require Markdown::Pod::Embed;


    #  Get manifest for any file additions we make
    #
    require ExtUtils::Manifest;
    my $manifest_hr=ExtUtils::Manifest::maniread();
    my @manifest_add;
    my $version_from_fn=$param_hr->{'VERSION_FROM'};
    my $readme_md_fn='README.md';
    my $readme_fn='README';
    my $markpod_or=Markdown::Pod::Embed->new();
    my $md;
    my $source_fn;


    #  Use an existing Markdown README when one is available
    #
    if (-f $readme_md_fn) {
        $source_fn=$readme_md_fn;
        $md=slurp($readme_md_fn);
    }
    elsif (-e $readme_md_fn || -l $readme_md_fn) {
        return err("$readme_md_fn exists and is not a regular file");
    }
    elsif (-e $readme_fn || -l $readme_fn) {
        verbose('markpod: %s exists without %s, leaving both unchanged', $readme_fn, $readme_md_fn);
        return undef;
    }
    else {
        unless (defined $version_from_fn && length $version_from_fn) {
            verbose('markpod: no VERSION_FROM file, no README files created');
            return undef;
        }
        $md=$markpod_or->markpod_markdown_source($version_from_fn);
        unless (defined $md && length $md) {
            msg('markpod: %s -> %s: skipped, no markdown source', $version_from_fn, $readme_fn);
            return undef;
        }
        my $readme_md=$md;
        $readme_md.=$/ unless $readme_md=~/\n\z/;
        blurp($readme_md_fn, $readme_md) ||
            return err();
        push @manifest_add, $readme_md_fn unless exists $manifest_hr->{$readme_md_fn};
        $source_fn=$readme_md_fn;
    }
    msg('markpod: %s -> %s: starting render', $source_fn, $readme_fn);


    #  No markdown means nothing to render
    #
    unless (defined $md && length $md) {
        msg('markpod: %s -> %s: finished, skipped empty markdown source', $source_fn, $readme_fn);
        manifest_add(\@manifest_add) if @manifest_add;
        return undef;
    }


    #  Convert markdown to text
    #
    my $text=$markpod_or->markpod_markdown_text($md);


    #  Update README only when changed
    #
    my $existing_readme=-f $readme_fn ? slurp($readme_fn) : '';
    if (md5_hex($existing_readme) ne md5_hex($text)) {
        $markpod_or->outfile($text, $readme_fn) ||
            return err();
        msg('markpod: %s -> %s: finished, updated', $source_fn, $readme_fn);
    }
    else {
        msg('markpod: %s -> %s: finished, no changes', $source_fn, $readme_fn);
    }

    push @manifest_add, $readme_fn unless exists $manifest_hr->{$readme_fn};
    manifest_add(\@manifest_add) if @manifest_add;

}


sub manifest_add {

    my ($file_ar)=@_;
    return undef unless @{$file_ar};
    require ExtUtils::Manifest;
    my %add=map { $_ => '' } @{$file_ar};
    ExtUtils::Manifest::maniadd(\%add);
    return 1;

}


1;


__END__

=begin markdown

# NAME

ASPEER::MakeMaker::Markdown::Pod::MM - MakeMaker integration for ASPEER::MakeMaker::Markdown::Pod

# SYNOPSIS

In `Makefile.PL`:

```perl
BEGIN {
    use lib './lib';
    eval {
        require ASPEER::MakeMaker::Markdown::Pod;
        ASPEER::MakeMaker::Markdown::Pod->import;
        1;
    };
}
```

Then run:

```bash
perl Makefile.PL
make doc
make readme
```

# DESCRIPTION

`ASPEER::MakeMaker::Markdown::Pod::MM` generates and executes the documentation targets
used by `ExtUtils::MakeMaker`. DocBook article conversion is delegated to
`Docbook::Convert::Pandoc`. Markdown source selection, Markdown-to-POD conversion,
and Perl source updates are delegated to `Markdown::Pod::Embed`.

This class inherits the common MakeMaker namespace from
`ASPEER::MakeMaker::MM` and imports shared helper functions from
`ASPEER::MakeMaker::MM::Util`.

`ASPEER::MakeMaker::MM::Import` installs the MakeMaker lifecycle hooks and
appends the target template. This module handles the resulting `doc` and
`readme` invocations.

# MAKEFILE INTEGRATION

The module adds a postamble fragment containing targets that invoke
`ASPEER::MakeMaker::Markdown::Pod::MM` from the generated Makefile.

`doc`
: Recursively converts DocBook article XML beneath `doc/` to sibling Markdown
  files without using `MANIFEST` as a discovery list. It then finds Markdown
  files listed in `MANIFEST`, derives each target by removing the trailing
  `.md`, and merges supported sidecars into matching `.pm`, `.pl`, or executable
  files. Markdown files under `t/` are ignored so test fixtures are not rewritten.

`readme`
: Builds `README` from the best available Markdown source.

The generated status output is concise and goes to STDERR:

```text
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: finished, updated pod
```

Unsupported or missing targets are reported only when verbose output has been
enabled.

# README SOURCE PRECEDENCE

README generation observes the existing project files before creating anything:

1. If `README.md` exists, it is used to generate or update `README`.
2. If `README` exists without `README.md`, both are left unchanged.
3. If neither exists, Markdown is obtained from the sidecar or embedded
   documentation of the file named by `VERSION_FROM` and written to a new,
   regular `README.md` file. `README` is then rendered from that file.
4. If the `VERSION_FROM` file has no sidecar or embedded Markdown, no README
   file is created.

The module never creates a `VERSION_FROM.md` sidecar. Generated README files are
added to `MANIFEST`.

`Markdown::Pod::Embed` renders the Markdown to plain text with `pandoc`.

# FUNCTIONS

## arg

Converts the positional arguments passed through the generated Makefile target
into a named hash used by `doc` and `readme`.

## doc

Converts DocBook article XML beneath `doc/` to sibling Markdown files, then
processes sidecar Markdown files from `MANIFEST` and updates supported Perl
targets in place.

## readme

Renders the project README from Markdown according to the precedence described
above.

## manifest_add

Adds generated support files to `MANIFEST`.

# CAVEATS

This module contains MakeMaker-specific target execution. Hook installation is
provided by `ASPEER::MakeMaker::MM::Import`, and Markdown/POD processing is
isolated in `Markdown::Pod::Embed`.

The implementation expects a traditional MakeMaker distribution layout with a
usable `MANIFEST` file.

# SEE ALSO

`ASPEER::MakeMaker::Markdown::Pod`, `ASPEER::MakeMaker::MM::Import`,
`Markdown::Pod::Embed`, `ExtUtils::MakeMaker`, `ExtUtils::Manifest`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Pod.

This software is copyright (c) 2026 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

ASPEER::MakeMaker::Markdown::Pod::MM - MakeMaker integration for ASPEER::MakeMaker::Markdown::Pod


=head1 SYNOPSIS

In C<Makefile.PL>:


 BEGIN {
     use lib './lib';
     eval {
         require ASPEER::MakeMaker::Markdown::Pod;
         ASPEER::MakeMaker::Markdown::Pod->import;
         1;
     };
 }
Then run:


 perl Makefile.PL
 make doc
 make readme

=head1 DESCRIPTION

C<ASPEER::MakeMaker::Markdown::Pod::MM> generates and executes the documentation targets
used by C<ExtUtils::MakeMaker>. DocBook article conversion is delegated to
C<Docbook::Convert::Pandoc>. Markdown source selection, Markdown-to-POD conversion,
and Perl source updates are delegated to C<Markdown::Pod::Embed>.

This class inherits the common MakeMaker namespace from
C<ASPEER::MakeMaker::MM> and imports shared helper functions from
C<ASPEER::MakeMaker::MM::Util>.

C<ASPEER::MakeMaker::MM::Import> installs the MakeMaker lifecycle hooks and
appends the target template. This module handles the resulting C<doc> and
C<readme> invocations.


=head1 MAKEFILE INTEGRATION

The module adds a postamble fragment containing targets that invoke
C<ASPEER::MakeMaker::Markdown::Pod::MM> from the generated Makefile.

C<doc>
: Recursively converts DocBook article XML beneath C<doc/> to sibling Markdown
  files without using C<MANIFEST> as a discovery list. It then finds Markdown
  files listed in C<MANIFEST>, derives each target by removing the trailing
  C<.md>, and merges supported sidecars into matching C<.pm>, C<.pl>, or executable
  files. Markdown files under C<t/> are ignored so test fixtures are not rewritten.

C<readme>
: Builds C<README> from the best available Markdown source.

The generated status output is concise and goes to STDERR:


 markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
 markpod: lib/My/Module.pm.md -> lib/My/Module.pm: finished, updated pod
Unsupported or missing targets are reported only when verbose output has been
enabled.


=head1 README SOURCE PRECEDENCE

README generation observes the existing project files before creating anything:

=over

=item 1.

If C<README.md> exists, it is used to generate or update C<README>.


=item 2.

If C<README> exists without C<README.md>, both are left unchanged.


=item 3.

If neither exists, Markdown is obtained from the sidecar or embedded
   documentation of the file named by C<VERSION_FROM> and written to a new,
   regular C<README.md> file. C<README> is then rendered from that file.


=item 4.

If the C<VERSION_FROM> file has no sidecar or embedded Markdown, no README
   file is created.


=back

The module never creates a C<VERSION_FROM.md> sidecar. Generated README files are
added to C<MANIFEST>.

C<Markdown::Pod::Embed> renders the Markdown to plain text with C<pandoc>.


=head1 FUNCTIONS


=head2 arg

Converts the positional arguments passed through the generated Makefile target
into a named hash used by C<doc> and C<readme>.


=head2 doc

Converts DocBook article XML beneath C<doc/> to sibling Markdown files, then
processes sidecar Markdown files from C<MANIFEST> and updates supported Perl
targets in place.


=head2 readme

Renders the project README from Markdown according to the precedence described
above.


=head2 manifest_add

Adds generated support files to C<MANIFEST>.


=head1 CAVEATS

This module contains MakeMaker-specific target execution. Hook installation is
provided by C<ASPEER::MakeMaker::MM::Import>, and Markdown/POD processing is
isolated in C<Markdown::Pod::Embed>.

The implementation expects a traditional MakeMaker distribution layout with a
usable C<MANIFEST> file.


=head1 SEE ALSO

C<ASPEER::MakeMaker::Markdown::Pod>, C<ASPEER::MakeMaker::MM::Import>,
C<Markdown::Pod::Embed>, C<ExtUtils::MakeMaker>, C<ExtUtils::Manifest>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Pod.

This software is copyright (c) 2026 by Andrew Speer
L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
