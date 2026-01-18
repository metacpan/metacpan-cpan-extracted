package Cwd::utf8;
use strict;
use warnings;
use 5.010; # state

# ABSTRACT: Fully UTF-8 aware Cwd
our $VERSION = '0.013'; # VERSION

#pod =begin :prelude
#pod
#pod =for test_synopsis
#pod my $file;
#pod
#pod =end :prelude
#pod
#pod =head1 SYNOPSIS
#pod
#pod     # Using the utf-8 versions of cwd, getcwd, fastcwd, fastgetcwd
#pod     use Cwd::utf8;
#pod     my $dir = getcwd;
#pod
#pod     # Using the utf-8 versions of abs_path
#pod     use Cwd::utf8 qw(abs_path);
#pod     my $abs_path = abs_path($file);
#pod
#pod     # Exporting no functions
#pod     use Cwd::utf8 qw(:none); # NOT "use Cwd::utf8 qw();"!
#pod     my $real_path = Cwd::real_path($file);
#pod
#pod =head1 DESCRIPTION
#pod
#pod While the original L<Cwd> functions are capable of handling UTF-8
#pod quite well, they expects and return all data as bytes, not as
#pod characters.
#pod
#pod This module replaces all the L<Cwd> functions with fully UTF-8 aware
#pod versions, both expecting and returning characters.
#pod
#pod B<Note:> Replacement of functions is not done on DOS, Windows, and OS/2
#pod as these systems do not have full UTF-8 file system support.
#pod
#pod =head2 Behaviour
#pod
#pod The module behaves as a pragma so you can use both C<use
#pod Cwd::utf8> and C<no Cwd::utf8> to turn utf-8 support on
#pod or off.
#pod
#pod By default, cwd(), getcwd(), fastcwd(), and fastgetcwd() (and, on
#pod Win32, getdcwd()) are exported (as with the original L<Cwd>). If you
#pod want to prevent this, use C<use Cwd::utf8 qw(:none)>. (As all the
#pod magic happens in the module's import function, you can not simply use
#pod C<use Cwd::utf8 qw()>)
#pod
#pod =head1 COMPATIBILITY
#pod
#pod The filesystems of Dos, Windows, and OS/2 do not (fully) support
#pod UTF-8. The L<Cwd> function will therefore not be replaced on these
#pod systems.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Cwd> -- The original module
#pod * L<File::Find::utf8> -- Fully utf-8 aware versions of the L<File::Find>
#pod   functions.
#pod * L<utf8::all> -- Turn on utf-8, all of it.
#pod   This was also the module I first added the utf-8 aware versions of
#pod   L<Cwd> and L<File::Find> to before moving them to their own package.
#pod
#pod =cut

use Cwd ();
use Encode ();

# Holds the pointers to the original version of redefined functions
state %_orig_functions;

# Current (i.e., this) package
my $current_package = __PACKAGE__;

# Original package (i.e., the one for which this module is replacing the functions)
my $original_package = $current_package;
$original_package =~ s/::utf8$//;

require Carp;
$Carp::Internal{$current_package}++; # To get warnings reported at correct caller level

#pod =attr $Cwd::utf8::UTF8_CHECK
#pod
#pod By default C<Cwd:::utf8> marks decoding errors as fatal (default value
#pod for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
#pod setting C<Cwd::utf8::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
#pod the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
#pod ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
#pod I<always> enforced.
#pod
#pod =cut

our $UTF8_CHECK = Encode::FB_CROAK | Encode::LEAVE_SRC; # Die on encoding errors

# UTF-8 Encoding object
my $_UTF8 = Encode::find_encoding('UTF-8');

sub import {
    # Target package (i.e., the one loading this module)
    my $target_package = caller;

    # If run on the dos/os2/windows platform, ignore overriding functions silently.
    # These platforms do not have (proper) utf-8 file system suppport...
    unless ($^O =~ /MSWin32|cygwin|dos|os2/) {
        no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no warnings qw(redefine);

        # Redefine each of the functions to their UTF-8 equivalent
        for my $f (@{$original_package . '::EXPORT'}, @{$original_package . '::EXPORT_OK'}) {
            # If we already have the _orig_function, we have redefined the function
            # in an earlier load of this module, so we need not do it again
            unless ($_orig_functions{$f}) {
                $_orig_functions{$f} = \&{$original_package . '::' . $f};
                *{$original_package . '::' . $f} = sub { return _utf8_cwd($f, @_); };
            }
        }
        $^H{$current_package} = 1; # Set compiler hint that we should use the utf-8 version
    }

    # Determine symbols to export
    shift; # First argument contains the package (that's us)
    @_ = (':DEFAULT') if !@_; # If nothing provided, use default
    @_ = map { $_ eq ':none' ? () : $_ } @_; # Replace :none tag with empty list

    # Use exporter to export
    require Exporter;
    Exporter::export_to_level($original_package, 1, $target_package, @_) if (@_);

    return;
}

sub unimport { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    $^H{$current_package} = 0; # Set compiler hint that we should not use the utf-8 version
    return;
}

sub _utf8_cwd {
    my $func = shift;

    my $hints = (caller 1)[10]; # Use caller level 1 because of the added anonymous sub around call
    if (! $hints->{$current_package}) {
        # Use original function if we're not using Cwd::utf8 in calling package
        return $_orig_functions{$func}->(@_);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        my @args = map { $_ ? $_UTF8->encode($_, $UTF8_CHECK) : $_ } @_;
        if (wantarray) {
            return map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } $_orig_functions{$func}->(@args);
        } else {
            my $r = $_orig_functions{$func}->(@args);
            return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cwd::utf8 - Fully UTF-8 aware Cwd

=head1 VERSION

version 0.013

=for test_synopsis my $file;

=head1 SYNOPSIS

    # Using the utf-8 versions of cwd, getcwd, fastcwd, fastgetcwd
    use Cwd::utf8;
    my $dir = getcwd;

    # Using the utf-8 versions of abs_path
    use Cwd::utf8 qw(abs_path);
    my $abs_path = abs_path($file);

    # Exporting no functions
    use Cwd::utf8 qw(:none); # NOT "use Cwd::utf8 qw();"!
    my $real_path = Cwd::real_path($file);

=head1 DESCRIPTION

While the original L<Cwd> functions are capable of handling UTF-8
quite well, they expects and return all data as bytes, not as
characters.

This module replaces all the L<Cwd> functions with fully UTF-8 aware
versions, both expecting and returning characters.

B<Note:> Replacement of functions is not done on DOS, Windows, and OS/2
as these systems do not have full UTF-8 file system support.

=head2 Behaviour

The module behaves as a pragma so you can use both C<use
Cwd::utf8> and C<no Cwd::utf8> to turn utf-8 support on
or off.

By default, cwd(), getcwd(), fastcwd(), and fastgetcwd() (and, on
Win32, getdcwd()) are exported (as with the original L<Cwd>). If you
want to prevent this, use C<use Cwd::utf8 qw(:none)>. (As all the
magic happens in the module's import function, you can not simply use
C<use Cwd::utf8 qw()>)

=head1 ATTRIBUTES

=head2 $Cwd::utf8::UTF8_CHECK

By default C<Cwd:::utf8> marks decoding errors as fatal (default value
for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
setting C<Cwd::utf8::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
I<always> enforced.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/Cwd-utf8/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COMPATIBILITY

The filesystems of Dos, Windows, and OS/2 do not (fully) support
UTF-8. The L<Cwd> function will therefore not be replaced on these
systems.

=head1 SEE ALSO

=over 4

=item *

L<Cwd> -- The original module

=item *

L<File::Find::utf8> -- Fully utf-8 aware versions of the L<File::Find> functions.

=item *

L<utf8::all> -- Turn on utf-8, all of it. This was also the module I first added the utf-8 aware versions of L<Cwd> and L<File::Find> to before moving them to their own package.

=back

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
