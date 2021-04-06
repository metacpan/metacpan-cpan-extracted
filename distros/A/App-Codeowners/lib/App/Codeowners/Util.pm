package App::Codeowners::Util;
# ABSTRACT: Grab bag of utility subs for Codeowners modules


use warnings;
use strict;

use Exporter qw(import);
use File::Codeowners::Util;
use Path::Tiny;

our @EXPORT_OK = qw(
    colorstrip
    find_codeowners_in_directory
    find_nearest_codeowners
    git_ls_files
    git_toplevel
    run_command
    run_git
    stringf
    stringify
    unbackslash
    zip
);

our $VERSION = '0.50'; # VERSION


sub find_nearest_codeowners { goto &File::Codeowners::Util::find_nearest_codeowners }


sub find_codeowners_in_directory { goto &File::Codeowners::Util::find_codeowners_in_directory }


sub run_command { goto &File::Codeowners::Util::run_command }


sub run_git { goto &File::Codeowners::Util::run_git }


sub git_ls_files { goto &File::Codeowners::Util::git_ls_files }


sub git_toplevel { goto &File::Codeowners::Util::git_toplevel }


sub colorstrip {
    my $str = shift || '';
    $str =~ s/\e\[[\d;]*m//g;
    return $str;
}


sub stringify {
    my $item = shift;
    return ref($item) eq 'ARRAY' ? join(',', @$item) : $item;
}


# The stringf code is from String::Format (thanks SREZIC), with changes:
# - Use Unicode::GCString for better Unicode character padding,
# - Strip ANSI color sequences,
# - Prevent 'Negative repeat count does nothing' warnings
sub _replace {
    my ($args, $orig, $alignment, $min_width,
        $max_width, $passme, $formchar) = @_;

    # For unknown escapes, return the orignial
    return $orig unless defined $args->{$formchar};

    $alignment = '+' unless defined $alignment;

    my $replacement = $args->{$formchar};
    if (ref $replacement eq 'CODE') {
        # $passme gets passed to subrefs.
        $passme ||= "";
        $passme =~ tr/{}//d;
        $replacement = $replacement->($passme);
    }

    my $replength;
    if (eval { require Unicode::GCString }) {
        my $gcstring = Unicode::GCString->new(colorstrip($replacement));
        $replength = $gcstring->columns;
    }
    else {
        $replength = length colorstrip($replacement);
    }

    $min_width  ||= $replength;
    $max_width  ||= $replength;

    # length of replacement is between min and max
    if (($replength > $min_width) && ($replength < $max_width)) {
        return $replacement;
    }

    # length of replacement is longer than max; truncate
    if ($replength > $max_width) {
        return substr($replacement, 0, $max_width);
    }

    my $padding = $min_width - $replength;
    $padding = 0 if $padding < 0;

    # length of replacement is less than min: pad
    if ($alignment eq '-') {
        # left align; pad in front
        return $replacement . ' ' x $padding;
    }

    # right align, pad at end
    return ' ' x $padding . $replacement;
}
my $regex = qr/
               (%             # leading '%'
                (-)?          # left-align, rather than right
                (\d*)?        # (optional) minimum field width
                (?:\.(\d*))?  # (optional) maximum field width
                (\{.*?\})?    # (optional) stuff inside
                (\S)          # actual format character
             )/x;
sub stringf {
    my $format = shift || return;
    my $args = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
       $args->{'n'} = "\n" unless exists $args->{'n'};
       $args->{'t'} = "\t" unless exists $args->{'t'};
       $args->{'%'} = "%"  unless exists $args->{'%'};

    $format =~ s/$regex/_replace($args, $1, $2, $3, $4, $5, $6)/ge;

    return $format;
}


# The unbacklash code is from String::Escape (thanks EVO), with changes:
# - Handle \a, \b, \f and \v (thanks Berk Akinci)
my %unbackslash;
sub unbackslash {
    my $str = shift;
    # Earlier definitions are preferred to later ones, thus we output \n not \x0d
    %unbackslash = (
        ( map { $_ => $_ } ( '\\', '"', '$', '@' ) ),
        ( 'r' => "\r", 'n' => "\n", 't' => "\t" ),
        ( map { 'x' . unpack('H2', chr($_)) => chr($_) } (0..255) ),
        ( map { sprintf('%03o', $_) => chr($_) } (0..255) ),
        ( 'a' => "\x07", 'b' => "\x08", 'f' => "\x0c", 'v' => "\x0b" ),
    ) if !%unbackslash;
    $str =~ s/ (\A|\G|[^\\]) \\ ( [0-7]{3} | x[\da-fA-F]{2} | . ) / $1 . $unbackslash{lc($2)} /gsxe;
    return $str;
}


# The zip code is from List::SomeUtils (thanks DROLSKY), copied just so as not
# to bring in the extra dependency.
sub zip (\@\@) {    ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $max = -1;
    $max < $#$_ && ( $max = $#$_ ) foreach @_;
    map {
        my $ix = $_;
        map $_->[$ix], @_;
    } 0 .. $max;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Util - Grab bag of utility subs for Codeowners modules

=head1 VERSION

version 0.50

=head1 DESCRIPTION

B<DO NOT USE> except in L<App::Codeowners> and related modules.

=head1 FUNCTIONS

=head2 find_nearest_codeowners

Deprecated.

Use L<File::Codeowners::Util/find_nearest_codeowners> instead.

=head2 find_codeowners_in_directory

Deprecated.

Use L<File::Codeowners::Util/find_codeowners_in_directory> instead.

=head2 run_command

Deprecated.

Use L<File::Codeowners::Util/run_command> instead.

=head2 run_git

Deprecated.

Use L<File::Codeowners::Util/run_git> instead.

=head2 git_ls_files

Deprecated.

Use L<File::Codeowners::Util/git_ls_files> instead.

=head2 git_toplevel

Deprecated.

Use L<File::Codeowners::Util/git_toplevel> instead.

=head2 colorstrip

    $str = colorstrip($str);

Strip ANSI color control commands.

=head2 stringify

    $str = stringify($scalar);
    $str = stringify(\@array);

Get a useful string representation of a scallar or arrayref.

=head2 stringf

TODO

=head2 unbackslash

Deprecated.

Use L<File::Codeowners::Util/unbackslash> instead.

=head2 zip

Same as L<List::SomeUtils/zip-ARRAY1-ARRAY2-[-ARRAY3-...-]>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
