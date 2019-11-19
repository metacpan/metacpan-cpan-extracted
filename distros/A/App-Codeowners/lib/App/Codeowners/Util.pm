package App::Codeowners::Util;
# ABSTRACT: Grab bag of utility subs for Codeowners modules


use warnings;
use strict;

use Encode qw(decode);
use Exporter qw(import);
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

our $VERSION = '0.47'; # VERSION


sub find_nearest_codeowners {
    my $path = path(shift || '.')->absolute;

    while (!$path->is_rootdir) {
        my $filepath = find_codeowners_in_directory($path);
        return $filepath if $filepath;
        $path = $path->parent;
    }
}


sub find_codeowners_in_directory {
    my $path = path(shift) or die;

    my @tries = (
        [qw(CODEOWNERS)],
        [qw(docs CODEOWNERS)],
        [qw(.bitbucket CODEOWNERS)],
        [qw(.github CODEOWNERS)],
        [qw(.gitlab CODEOWNERS)],
    );

    for my $parts (@tries) {
        my $try = $path->child(@$parts);
        return $try if $try->is_file;
    }
}

sub run_command {
    my $filter;
    $filter = pop if ref($_[-1]) eq 'CODE';

    print STDERR "# @_\n" if $ENV{GIT_CODEOWNERS_DEBUG};

    my ($child_in, $child_out);
    require IPC::Open2;
    my $pid = IPC::Open2::open2($child_out, $child_in, @_);
    close($child_in);

    binmode($child_out, ':encoding(UTF-8)');

    my $proc = App::Codeowners::Util::Process->new(
        pid     => $pid,
        fh      => $child_out,
        filter  => $filter,
    );

    return wantarray ? ($proc, @{$proc->all}) : $proc;
}

sub run_git {
    return run_command('git', @_);
}

sub git_ls_files {
    my $dir = shift || '.';
    return run_git('-C', $dir, 'ls-files', @_, \&_unescape_git_filepath);
}

# Depending on git's "core.quotepath" config, non-ASCII chars may be
# escaped (identified by surrounding dquotes), so try to unescape.
sub _unescape_git_filepath {
    return $_ if $_ !~ /^"(.+)"$/;
    return decode('UTF-8', unbackslash($1));
}

sub git_toplevel {
    my $dir = shift || '.';

    my ($proc, $path) = run_git('-C', $dir, qw{rev-parse --show-toplevel});

    return if $proc->wait != 0 || !$path;
    return path($path);
}

sub colorstrip {
    my $str = shift || '';
    $str =~ s/\e\[[\d;]*m//g;
    return $str;
}

sub stringify {
    my $item = shift;
    return ref($item) eq 'ARRAY' ? join(',', @$item) : $item;
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

{
    package App::Codeowners::Util::Process;

    sub new {
        my $class = shift;
        return bless {@_}, $class;
    }

    sub next {
        my $self = shift;
        my $line = readline($self->{fh});
        if (defined $line) {
            chomp $line;
            if (my $filter = $self->{filter}) {
                local $_ = $line;
                $line = $filter->($line);
            }
        }
        $line;
    }

    sub all {
        my $self = shift;
        chomp(my @lines = readline($self->{fh}));
        if (my $filter = $self->{filter}) {
            $_ = $filter->($_) for @lines;
        }
        \@lines;
    }

    sub wait {
        my $self = shift;
        my $pid  = $self->{pid} or return;
        if (my $fh = $self->{fh}) {
            close($fh);
            delete $self->{fh};
        }
        waitpid($pid, 0);
        my $status = $?;
        print STDERR "# -> status $status\n" if $ENV{GIT_CODEOWNERS_DEBUG};
        delete $self->{pid};
        return $status;
    }

    sub DESTROY {
        my ($self, $global_destruction) = @_;
        return if $global_destruction;
        $self->wait;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Util - Grab bag of utility subs for Codeowners modules

=head1 VERSION

version 0.47

=head1 DESCRIPTION

B<DO NOT USE> except in L<App::Codeowners> and related modules.

=head1 FUNCTIONS

=head2 find_nearest_codeowners

    $filepath = find_nearest_codeowners($dirpath);

Find the F<CODEOWNERS> file in the current working directory, or search in the
parent directory recursively until a F<CODEOWNERS> file is found.

Returns C<undef> if no F<CODEOWNERS> is found.

=head2 find_codeowners_in_directory

    $filepath = find_codeowners_in_directory($dirpath);

Find the F<CODEOWNERS> file in a given directory. No recursive searching is done.

Returns the first of (or undef if none found):

=over 4

=item *

F<CODEOWNERS>

=item *

F<docs/CODEOWNERS>

=item *

F<.bitbucket/CODEOWNERS>

=item *

F<.github/CODEOWNERS>

=item *

F<.gitlab/CODEOWNERS>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
