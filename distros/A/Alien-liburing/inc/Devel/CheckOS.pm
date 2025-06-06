package #
Devel::CheckOS;

use strict;
use warnings;

use Exporter;
# if we're loading this from Makefile.PL, FFR might not yet be installed
eval 'use File::Find::Rule';
use File::Spec;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS %OS_ALIASES);

our $VERSION = '2.04';

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    os_is os_isnt die_if_os_is die_if_os_isnt die_unsupported
    list_platforms list_family_members register_alias
);
%EXPORT_TAGS = (
    all      => \@EXPORT_OK,
    booleans => [qw(os_is os_isnt die_unsupported)],
    fatal    => [qw(die_if_os_is die_if_os_isnt)]
);

# get a list of the .pm files under a list of dirs, or the empty list
# in taint mode
sub _find_pm_files_in_dirs {
    my @files;
    eval { @files = File::Find::Rule->file()->name('*.pm')->in(@_) };
    return @files;
}

if(exists($INC{'File/Find/Rule.pm'})) {
    foreach my $alias_module (
        _find_pm_files_in_dirs(
            grep { -d }
            map { File::Spec->catdir($_, qw(Devel AssertOS Alias)) }
            @INC
        )
    ) {
        my(undef, undef, $file_part) = File::Spec->splitpath($alias_module);
        $file_part =~ s/\.pm$//;
        eval "use Devel::AssertOS::Alias::$file_part";
        warn("Bad alias module 'Devel::AssertOS::Alias::$file_part' ignored\n") if($@);
    }
}

=head1 NAME

Devel::CheckOS - check what OS we're running on

=head1 DESCRIPTION

A learned sage once wrote on IRC:

   $^O is stupid and ugly, it wears its pants as a hat

Devel::CheckOS provides a more friendly interface to $^O, and also lets
you check for various OS "families" such as "Unix", which includes things
like Linux, Solaris, AIX etc.

It spares perl the embarrassment of wearing its pants on its head by
covering them with a splendid Fedora.

=head1 SYNOPSIS

    use Devel::CheckOS qw(os_is);
    print "Hey, I know this, it's a Unix system\n" if(os_is('Unix'));

    print "You've got Linux 2.6\n" if(os_is('Linux::v2_6'));

=head1 USING IT IN Makefile.PL or Build.PL

If you want to use this from Makefile.PL or Build.PL, do
not simply copy the module into your distribution as this may cause
problems when PAUSE and search.cpan.org index the distro.  Instead, use
the use-devel-assertos script.

=head1 FUNCTIONS

Devel::CheckOS implements the following functions, which load subsidiary
OS-specific modules on demand to do the real work. They can all be exported
by listing their names after C<use Devel::CheckOS>. You can also export
groups of functions thus:

    use Devel::CheckOS qw(:booleans); # export the boolean functions
                                      # and 'die_unsupported'
    
    use Devel::CheckOS qw(:fatal);    # export those that die on no match

    use Devel::CheckOS qw(:all);      # export everything exportable

=head2 Boolean functions

=head3 os_is

Takes a list of OS names.  If the current platform matches any of them,
it returns true, otherwise it returns false.  The names can be a mixture
of OSes and OS families, eg ...

    os_is(qw(Unix VMS)); # Unix is a family, VMS is an OS

Matching is case-insensitive provided that Taint-mode is not enabled, so the
above could also be written:

    os_is(qw(unix vms));

=cut

sub os_is {
    my @targets = @_;
    my $rval = 0;

    TARGET: foreach my $target (@targets) {
        # resolve aliases
        ALIAS: foreach my $alias (keys %OS_ALIASES) {
            if($target =~ /^$alias$/i) {
                $target = $OS_ALIASES{$alias};
                last ALIAS;
            }
        }

        # resolve case-insensitive names (no-op in taint-mode as list_platforms
        # won't work)
        my @available_platforms = list_platforms();
        CANDIDATE: foreach my $candidate (@available_platforms) {
            if($target =~ /^\Q$candidate\E$/i) {
                $target = $candidate;
                last CANDIDATE;
            }
        }

        die("Devel::CheckOS: $target isn't a legal OS name\n")
            unless($target =~ /^\w+(::\w+)*$/);

        $@ = undef;
        if(! "Devel::AssertOS::$target"->can('os_is')) {
            eval "use Devel::AssertOS::$target";
        }
        if(!$@) {
            no strict 'refs';
            $rval = 1 if(&{"Devel::AssertOS::${target}::os_is"}());
        }
    }
    return $rval;
}

=head3 os_isnt

If the current platform matches (case-insensitively) any of the parameters it
returns false, otherwise it returns true.

=cut

sub os_isnt {
    my @targets = @_;
    my $rval = 1;
    foreach my $target (@targets) {
        $rval = 0 if(os_is($target));
    }
    return $rval;
}

=head2 Fatal functions

=head3 die_if_os_isnt

As C<os_is()>, except that it dies instead of returning false.  The die()
message matches what the CPAN-testers look for to determine if a module
doesn't support a particular platform.

=cut

sub die_if_os_isnt {
    os_is(@_) ? 1 : die_unsupported();
}

=head3 die_if_os_is

As C<os_isnt()>, except that it dies instead of returning false.

=cut

sub die_if_os_is {
    os_isnt(@_) ? 1 : die_unsupported();
}

=head2 And some utility functions ...

=head3 die_unsupported

This function simply dies with the message "OS unsupported", which is what
the CPAN testers look for to figure out whether a platform is supported or
not.

=cut

sub die_unsupported { die("OS unsupported\n"); }

=head3 list_platforms

Return a list of all the platforms for which the corresponding
Devel::AssertOS::* module is available.  This includes both OSes and OS
families, and both those bundled with this module and any third-party
add-ons you have installed.

Unfortunately, on some platforms this list may have platform names'
case broken, eg you might see 'freebsd' instead of 'FreeBSD'.
This is because they have case-insensitive filesystems so things
should Just Work anyway.

This function does not work in taint-mode.

=cut

my $case_flag = File::Spec->case_tolerant ? '(?i)' : '';
my $re_Devel    = qr/$case_flag ^Devel$/x;
my $re_AssertOS = qr/$case_flag ^AssertOS$/x;
my $re_Alias    = qr/$case_flag ^Alias\b/x;

sub list_platforms {
    my @modules = sort keys %{ {map { $_ => 1 } grep {
        $_ !~ $re_Alias
    } map {
        my (undef, $dir_part, $file_part) = File::Spec->splitpath($_);
        $file_part =~ s/\.pm$//;
        my (@dirs) = grep {+length} File::Spec->splitdir($dir_part);
        foreach my $i (reverse 1..$#dirs) {
            next unless(
                $dirs[$i] =~ $re_AssertOS &&
                $dirs[$i - 1] =~ $re_Devel
            );;
            splice @dirs, 0, $i + 1;
            last;
        }
        join('::', @dirs, $file_part);
    } _find_pm_files_in_dirs(
        grep { -d }
        map { File::Spec->catdir($_, qw(Devel AssertOS)) }
        @INC
    )}};

    return @modules;
}

=head3 list_family_members

Takes the name of an OS 'family' and returns a list of all its members.

If called on something that isn't a family, you get an empty list.

=cut

sub list_family_members {
    my $family = shift() ||
        die(__PACKAGE__."::list_family_members needs a parameter\n");

    # this will die if it's the wrong OS, but the module is loaded ...
    eval qq{use Devel::AssertOS::$family};
    # ... so we can now query it
    return eval qq{
        no strict 'refs';
        &{"Devel::AssertOS::${family}::matches"}()
    };
}

=head3 register_alias

It takes two arguments, the first being an alias name, the second being the
name of an OS. After the alias has been registered, any queries about the
alias will return the appropriate result for the named OS.

It returns true unless you invoke it incorrectly or you attempt to change
an existing alias.

Aliases don't work under taint-mode.

See L<Devel::AssertOS::Extending>.

=cut

sub register_alias {
    my($alias, $os) = @_;
    ($alias && $os) || return 0;
    if(!exists($OS_ALIASES{$alias}) || $OS_ALIASES{$alias} eq $os) {
        return $OS_ALIASES{$alias} = $os;
    } else {
        return 0
    }
}

=head1 PLATFORMS SUPPORTED

To see the list of platforms for which information is available, run this:

    perl -MDevel::CheckOS -e 'print join(", ", Devel::CheckOS::list_platforms())'

These are the names of the underlying Devel::AssertOS::* modules
which do the actual platform detection, so they have to
be 'legal' filenames and module names, which unfortunately precludes
funny characters, so platforms like OS/2 are mis-spelt deliberately.
Sorry.

Also be aware that not all of them have been properly tested.  I don't
have access to most of them and have had to work from information
gleaned from L<perlport> and a few other places.  For a complete list of
OS families, see L<Devel::CheckOS::Families>.

If you want to add your own OSes or families, see L<Devel::AssertOS::Extending>
and please feel free to upload the results to the CPAN.

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<https://github.com/DrHyde/perl-modules-Devel-CheckOS/issues>.

You will need to include in your bug report the exact value of $^O, what
the OS is called (eg Windows Vista 64 bit Ultimate Home Edition), and,
if relevant, what "OS family" it should be in and who wrote it.

If you are feeling particularly generous you can encourage me in my
open source endeavours by buying me something from my wishlist:
  L<http://www.cantrell.org.uk/david/wishlist/>

=head1 COMPATIBILITY

Version 1.90 made all matches case-insensitive. This is a change in behaviour, but
if it breaks your code then your code was already broken, you just didn't know it.

As of version 2.00 the list_* functions always return plain old lists. Calling them
in scalar context was deprecated and has emitted warnings for over 2 years, since
version 1.90.

=head1 SEE ALSO

$^O in L<perlvar>

L<perlport>

L<Devel::AssertOS>

L<Devel::AssertOS::Extending>

L<Probe::Perl>

The use-devel-assertos script

L<Module::Install::AssertOS>

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Thanks to David Golden for the name and ideas about the interface, and
to the cpan-testers-discuss mailing list for prompting me to write it
in the first place.

Thanks to Ken Williams, from whose L<Module::Build> I lifted some of the
information about what should be in the Unix family.

Thanks to Billy Abbott for finding some bugs for me on VMS.

Thanks to Matt Kraai for information about QNX.

Thanks to Kenichi Ishigaki and Gabor Szabo for reporting a bug on Windows,
and to the former for providing a patch.

Thanks to Paul Green for some information about VOS.

Thanks to Yanick Champoux for a patch to let Devel::AssertOS support
negative assertions.

Thanks to Brian Fraser for adding Android support.

Thanks to Dale Evans for Debian detection, a bunch of Mac OS X specific version
detection modules, and perl 5.6 support.

Thanks to Graham Knop for fixing a build bug on perl 5.8.

Thanks to Alceu Rodrigues de Freitas Junior for improving Ubuntu detection
and providing a way to detect a lot more Linux variants.

Thanks to Leos Stejskal for https://github.com/stejskalleos/os_release from
which I got many sample /etc/os-release files.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Devel-CheckOS.git>

=head1 COPYRIGHT and LICENCE

Copyright 2024 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 HATS

I recommend buying a Fedora from L<http://hatsdirect.com/>.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
