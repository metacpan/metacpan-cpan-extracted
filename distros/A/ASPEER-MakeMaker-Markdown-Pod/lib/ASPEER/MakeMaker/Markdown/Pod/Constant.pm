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

#


#  Pragma
#
package ASPEER::MakeMaker::Markdown::Pod::Constant;
use strict qw(vars);
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  Modules we need
#
use File::Spec;


#  Version information
#
$VERSION='1.013';


#  Get module file name and path, derive name of file to store local constants
#
use Cwd qw(abs_path);
my $local_fn=abs_path(__FILE__) . '.local';


#  Find file in path
#
sub bin_find {


    #  Find a binary file
    #
    my @bin_fn=@_;
    my $bin_fn;


    #  Find the bin file/files if given array ref. If not supplied as array ref
    #  convert.
    #
    my @dir=grep {-d $_} split(/:|;/, $ENV{'PATH'});
    my %dir=map  {$_ => 1} @dir;
    DIR: foreach my $dir (@dir) {
        next unless delete $dir{$dir};
        next unless -d $dir;
        foreach my $bin (@bin_fn) {
            if (-f File::Spec->catfile($dir, $bin)) {
                $bin_fn=File::Spec->catfile($dir, $bin);
                last DIR;
            }
        }
    }


    #  Normalize fn
    #
    $bin_fn=File::Spec->canonpath($bin_fn) if $bin_fn;


    #  Return
    #
    return $bin_fn || '';

}



#  Hash of constants
#
%Constant=(

    OPTION_HR => {
        dialect => 'GitHub',
    },


    PANDOC_EXE => &bin_find(qw(pandoc pandoc.exe)),

    PANDOC_CMD_MD2TEXT_CR => sub {
        return [
            shift(),                # PANDOC_EXE
            '-fmarkdown_github',    # from markdown (github dialect)
            '-tplain',              # to plaintext
            shift(),                # File name
        ]
    },

    #  Local constants override anything above
    #
    %{do($local_fn) || {}},
    %{do(glob(sprintf('~/.%s.local', __PACKAGE__))) || {}}    # || {} avoids warning

);


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA=qw(Exporter);
foreach (keys %Constant) {${$_}=$Constant{$_}}
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
__END__

=begin markdown

# NAME

ASPEER::MakeMaker::Markdown::Pod::Constant - constants for ASPEER::MakeMaker::Markdown::Pod

# SYNOPSIS

```perl
use ASPEER::MakeMaker::Markdown::Pod::Constant;

my $default_dialect = $OPTION_HR->{dialect};
my $pandoc          = $PANDOC_EXE;
my $cmd             = $PANDOC_CMD_MD2TEXT_CR->($pandoc, '-');
```

# DESCRIPTION

`ASPEER::MakeMaker::Markdown::Pod::Constant` defines exported constants used by the core
processor and command-line tool.

The constants are stored in `%Constant`, exported as package variables, and can
be overridden by local configuration files loaded at compile time.

# CONSTANTS

`$OPTION_HR`
: Default processor options. The current default Markdown dialect is `GitHub`.

`$PANDOC_EXE`
: Path to `pandoc` discovered from `PATH`, or an empty string when `pandoc` is
  not available.

`$PANDOC_CMD_MD2TEXT_CR`
: Code reference that builds the `pandoc` command used to render Markdown to
  plain text for README generation.

# FUNCTIONS

## bin_find

```perl
my $path = ASPEER::MakeMaker::Markdown::Pod::Constant::bin_find(qw(pandoc pandoc.exe));
```

Searches `PATH` for the first executable-like file matching one of the supplied
names and returns a canonical path. If no candidate is found, it returns an
empty string.

# LOCAL OVERRIDES

Local constants can be overridden by files loaded from:

```text
lib/ASPEER/MakeMaker/Markdown/Pod/Constant.pm.local
~/.ASPEER::MakeMaker::Markdown::Pod::Constant.local
```

Those files are expected to return a hash reference suitable for merging into
`%Constant`.

# SEE ALSO

`ASPEER::MakeMaker::Markdown::Pod`

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

ASPEER::MakeMaker::Markdown::Pod::Constant - constants for ASPEER::MakeMaker::Markdown::Pod


=head1 SYNOPSIS


 use ASPEER::MakeMaker::Markdown::Pod::Constant;

 my $default_dialect = $OPTION_HR->{dialect};
 my $pandoc          = $PANDOC_EXE;
 my $cmd             = $PANDOC_CMD_MD2TEXT_CR->($pandoc, '-');

=head1 DESCRIPTION

C<ASPEER::MakeMaker::Markdown::Pod::Constant> defines exported constants used by the core
processor and command-line tool.

The constants are stored in C<%Constant>, exported as package variables, and can
be overridden by local configuration files loaded at compile time.


=head1 CONSTANTS

C<$OPTION_HR>
: Default processor options. The current default Markdown dialect is C<GitHub>.

C<$PANDOC_EXE>
: Path to C<pandoc> discovered from C<PATH>, or an empty string when C<pandoc> is
  not available.

C<$PANDOC_CMD_MD2TEXT_CR>
: Code reference that builds the C<pandoc> command used to render Markdown to
  plain text for README generation.


=head1 FUNCTIONS


=head2 bin_find


 my $path = ASPEER::MakeMaker::Markdown::Pod::Constant::bin_find(qw(pandoc pandoc.exe));
Searches C<PATH> for the first executable-like file matching one of the supplied
names and returns a canonical path. If no candidate is found, it returns an
empty string.


=head1 LOCAL OVERRIDES

Local constants can be overridden by files loaded from:


 lib/ASPEER/MakeMaker/Markdown/Pod/Constant.pm.local
 ~/.ASPEER::MakeMaker::Markdown::Pod::Constant.local
Those files are expected to return a hash reference suitable for merging into
C<%Constant>.


=head1 SEE ALSO

C<ASPEER::MakeMaker::Markdown::Pod>


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
