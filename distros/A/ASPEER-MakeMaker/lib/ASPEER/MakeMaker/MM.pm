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
package ASPEER::MakeMaker::MM;


#  Compiler Pragma
#
use strict qw(vars);
use warnings;
use vars qw($VERSION);


#  External Packages
#
use ASPEER::MakeMaker::MM::Util;
use ASPEER::MakeMaker::MM::Constant;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#  All done, init finished
#
1;


__END__

=begin markdown

# ASPEER::MakeMaker::MM

## Name

ASPEER::MakeMaker::MM - namespace module for MakeMaker helper support

## Synopsis

```perl
use ASPEER::MakeMaker::MM;
```

This module is normally loaded indirectly by `ASPEER::MakeMaker` and
`ASPEER::MakeMaker::MM::Import`.

## Description

`ASPEER::MakeMaker::MM` currently acts as a namespace and dependency
anchor for the MakeMaker helper implementation. It loads:

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


## Methods

### const_config0

```perl
ASPEER::MakeMaker::MM::const_config0($hook, $mm, @args);
```

Legacy or parked implementation of a `const_config` wrapper. It calls the
saved original MakeMaker section, copies constants into the Makefile macro
table, and updates `PERLRUN`.

The active implementation is currently
`ASPEER::MakeMaker::MM::Import::const_config`.

### postamble0

```perl
ASPEER::MakeMaker::MM::postamble0($hook, $mm, @args);
```

Legacy or parked implementation of a `postamble` wrapper. It calls the saved
original MakeMaker section and appends the configured postamble template.

The active implementation is currently
`ASPEER::MakeMaker::MM::Import::postamble`.

## Usage Conventions

Do not call this module's methods directly from a `Makefile.PL`. Use the
top-level entry point:

```perl
use ASPEER::MakeMaker;
```

New active MakeMaker hook behavior should generally be documented against
`ASPEER::MakeMaker::MM::Import`, since that module installs and provides
the current hook implementations.

## See Also

- `ASPEER::MakeMaker`
- `ASPEER::MakeMaker::MM::Import`
- `ASPEER::MakeMaker::MM::Util`
- `ASPEER::MakeMaker::MM::Constant`

=end markdown


=head1 ASPEER::MakeMaker::MM


=head2 Name

ASPEER::MakeMaker::MM - namespace module for MakeMaker helper support


=head2 Synopsis


 use ASPEER::MakeMaker::MM;
This module is normally loaded indirectly by C<ASPEER::MakeMaker> and
C<ASPEER::MakeMaker::MM::Import>.


=head2 Description

C<ASPEER::MakeMaker::MM> currently acts as a namespace and dependency
anchor for the MakeMaker helper implementation. It loads:

=over

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

The active MakeMaker section wrappers and replacement methods are implemented
in C<ASPEER::MakeMaker::MM::Import>.


=head2 Methods


=head3 const_config0


 ASPEER::MakeMaker::MM::const_config0($hook, $mm, @args);
Legacy or parked implementation of a C<const_config> wrapper. It calls the
saved original MakeMaker section, copies constants into the Makefile macro
table, and updates C<PERLRUN>.

The active implementation is currently
C<ASPEER::MakeMaker::MM::Import::const_config>.


=head3 postamble0


 ASPEER::MakeMaker::MM::postamble0($hook, $mm, @args);
Legacy or parked implementation of a C<postamble> wrapper. It calls the saved
original MakeMaker section and appends the configured postamble template.

The active implementation is currently
C<ASPEER::MakeMaker::MM::Import::postamble>.


=head2 Usage Conventions

Do not call this module's methods directly from a C<Makefile.PL>. Use the
top-level entry point:


 use ASPEER::MakeMaker;
New active MakeMaker hook behavior should generally be documented against
C<ASPEER::MakeMaker::MM::Import>, since that module installs and provides
the current hook implementations.


=head2 See Also

=over

=item -

C<ASPEER::MakeMaker>


=item -

C<ASPEER::MakeMaker::MM::Import>


=item -

C<ASPEER::MakeMaker::MM::Util>


=item -

C<ASPEER::MakeMaker::MM::Constant>


=back

=cut
