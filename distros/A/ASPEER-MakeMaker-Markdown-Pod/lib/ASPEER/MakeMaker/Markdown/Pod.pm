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
package ASPEER::MakeMaker::Markdown::Pod;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION $VERSION_GIT_SHA $AUTHORITY @ISA);
use warnings;


#  Inherit the shared MakeMaker integration and keep the historic processing
#  API as a compatibility facade.
#
use ASPEER::MakeMaker ();
use ASPEER::MakeMaker::Markdown::Pod::MM ();
use Markdown::Pod::Embed ();
@ISA=qw(ASPEER::MakeMaker Markdown::Pod::Embed);


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='1.014';
$VERSION_GIT_SHA=do { local(@ARGV, $/, $_); @ARGV=($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined($VERSION_GIT_SHA);


#  Done
#
1;


__END__

=begin markdown

# NAME

ASPEER::MakeMaker::Markdown::Pod - MakeMaker integration for Markdown-maintained POD

# SYNOPSIS

In `Makefile.PL`:

```perl
use ExtUtils::MakeMaker;
use ASPEER::MakeMaker::Markdown::Pod;

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
);
```

This adds `doc` and `readme` targets to the generated Makefile.

For optional integration, load and import the module before `WriteMakefile`:

```perl
use ExtUtils::MakeMaker;

eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1;
};

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
);
```

If the optional module cannot be loaded, MakeMaker continues without the
additional lifecycle hooks and documentation targets. The equivalent explicit
command-line activation is:

```text
perl -MASPEER::MakeMaker::Markdown::Pod Makefile.PL
```

# DESCRIPTION

`ASPEER::MakeMaker::Markdown::Pod` integrates documentation maintenance and the project's
established distribution conventions with `ExtUtils::MakeMaker`. Importing it
from `Makefile.PL` installs the MakeMaker lifecycle hooks used to configure the
generated Makefile, package metadata and install map, Git-SHA provenance, and
documentation targets. The generated global `PERLRUN` preserves
the active local library paths and MakeMaker extensions.

The responsibilities are deliberately separated:

- `ASPEER::MakeMaker::Markdown::Pod` inherits the common MakeMaker behavior
  from `ASPEER::MakeMaker`.
- `ASPEER::MakeMaker::MM::Import` installs and implements the MakeMaker
  lifecycle hooks.
- `ASPEER::MakeMaker::Markdown::Pod::MM` generates and executes the `doc` and `readme`
  targets.
- `Docbook::Convert::Pandoc` discovers DocBook articles beneath `doc/` and
  converts them to sibling Markdown files.
- `Markdown::Pod::Embed` selects Markdown, converts it to POD, and updates Perl
  source files.

The `doc` target discovers DocBook articles beneath `doc/` independently of
`MANIFEST`, converts them to sibling Markdown files, and then processes Markdown
sidecars listed in `MANIFEST` for matching Perl modules, scripts, and declared
executable files. `readme` renders the best available README Markdown source as
plain text.

# PROCESSOR COMPATIBILITY

For compatibility with earlier releases, this package inherits the processing
methods supplied by `Markdown::Pod::Embed`. New code that only converts or
updates Markdown/POD should use `Markdown::Pod::Embed` directly; it does not
need MakeMaker and does not install MakeMaker hooks.

# ERRORS

MakeMaker hook errors and target failures are fatal. Importing this module from
a program other than `Makefile.PL` does not alter `ExtUtils::MakeMaker`.

# SEE ALSO

`ASPEER::MakeMaker`, `ASPEER::MakeMaker::Markdown::Pod::MM`,
`ASPEER::MakeMaker::MM::Import`,
`Markdown::Pod::Embed`, `ExtUtils::MakeMaker`

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

ASPEER::MakeMaker::Markdown::Pod - MakeMaker integration for Markdown-maintained POD


=head1 SYNOPSIS

In C<Makefile.PL>:


 use ExtUtils::MakeMaker;
 use ASPEER::MakeMaker::Markdown::Pod;

 WriteMakefile(
     NAME         => 'Example',
     VERSION_FROM => 'lib/Example.pm',
 );
This adds C<doc> and C<readme> targets to the generated Makefile.

For optional integration, load and import the module before C<WriteMakefile>:


 use ExtUtils::MakeMaker;

 eval {
     require ASPEER::MakeMaker::Markdown::Pod;
     ASPEER::MakeMaker::Markdown::Pod->import();
     1;
 };

 WriteMakefile(
     NAME         => 'Example',
     VERSION_FROM => 'lib/Example.pm',
 );
If the optional module cannot be loaded, MakeMaker continues without the
additional lifecycle hooks and documentation targets. The equivalent explicit
command-line activation is:


 perl -MASPEER::MakeMaker::Markdown::Pod Makefile.PL

=head1 DESCRIPTION

C<ASPEER::MakeMaker::Markdown::Pod> integrates documentation maintenance and the project's
established distribution conventions with C<ExtUtils::MakeMaker>. Importing it
from C<Makefile.PL> installs the MakeMaker lifecycle hooks used to configure the
generated Makefile, package metadata and install map, Git-SHA provenance, and
documentation targets. The generated global C<PERLRUN> preserves
the active local library paths and MakeMaker extensions.

The responsibilities are deliberately separated:

=over

=item -

C<ASPEER::MakeMaker::Markdown::Pod> inherits the common MakeMaker behavior
  from C<ASPEER::MakeMaker>.


=item -

C<ASPEER::MakeMaker::MM::Import> installs and implements the MakeMaker
  lifecycle hooks.


=item -

C<ASPEER::MakeMaker::Markdown::Pod::MM> generates and executes the C<doc> and C<readme>
  targets.


=item -

C<Docbook::Convert::Pandoc> discovers DocBook articles beneath C<doc/> and
  converts them to sibling Markdown files.


=item -

C<Markdown::Pod::Embed> selects Markdown, converts it to POD, and updates Perl
  source files.


=back

The C<doc> target discovers DocBook articles beneath C<doc/> independently of
C<MANIFEST>, converts them to sibling Markdown files, and then processes Markdown
sidecars listed in C<MANIFEST> for matching Perl modules, scripts, and declared
executable files. C<readme> renders the best available README Markdown source as
plain text.


=head1 PROCESSOR COMPATIBILITY

For compatibility with earlier releases, this package inherits the processing
methods supplied by C<Markdown::Pod::Embed>. New code that only converts or
updates Markdown/POD should use C<Markdown::Pod::Embed> directly; it does not
need MakeMaker and does not install MakeMaker hooks.


=head1 ERRORS

MakeMaker hook errors and target failures are fatal. Importing this module from
a program other than C<Makefile.PL> does not alter C<ExtUtils::MakeMaker>.


=head1 SEE ALSO

C<ASPEER::MakeMaker>, C<ASPEER::MakeMaker::Markdown::Pod::MM>,
C<ASPEER::MakeMaker::MM::Import>,
C<Markdown::Pod::Embed>, C<ExtUtils::MakeMaker>


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
