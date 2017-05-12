package Config::Apachish::Base;

our $DATE = '2016-03-11'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Carp; # avoided to shave a bit of startup time

sub new {
    my ($class, %attrs) = @_;
    #$attrs{process_include} //= 0;
    bless \%attrs, $class;
}

# borrowed from Parse::CommandLine. differences: returns arrayref. return undef
# on error (instead of dying).
sub _parse_command_line {
    my ($self, $str) = @_;

    $str =~ s/\A\s+//ms;
    $str =~ s/\s+\z//ms;

    my @argv;
    my $buf;
    my $escaped;
    my $double_quoted;
    my $single_quoted;

    for my $char (split //, $str) {
        if ($escaped) {
            $buf .= $char;
            $escaped = undef;
            next;
        }

        if ($char eq '\\') {
            if ($single_quoted) {
                $buf .= $char;
            }
            else {
                $escaped = 1;
            }
            next;
        }

        if ($char =~ /\s/) {
            if ($single_quoted || $double_quoted) {
                $buf .= $char;
            }
            else {
                push @argv, $buf if defined $buf;
                undef $buf;
            }
            next;
        }

        if ($char eq '"') {
            if ($single_quoted) {
                $buf .= $char;
                next;
            }
            $double_quoted = !$double_quoted;
            next;
        }

        if ($char eq "'") {
            if ($double_quoted) {
                $buf .= $char;
                next;
            }
            $single_quoted = !$single_quoted;
            next;
        }

        $buf .= $char;
    }
    push @argv, $buf if defined $buf;

    if ($escaped || $single_quoted || $double_quoted) {
        return undef;
    }

    \@argv;
}

sub _err {
    my ($self, $msg) = @_;
    die join(
        "",
        @{ $self->{_include_stack} } ? "$self->{_include_stack}[0] " : "",
        "line $self->{_linum}: ",
        $msg
    );
}

sub _push_include_stack {
    require Cwd;

    my ($self, $path) = @_;

    # included file's path is based on the main (topmost) file
    if (@{ $self->{_include_stack} }) {
        require File::Spec;
        my ($vol, $dir, $file) =
            File::Spec->splitpath($self->{_include_stack}[-1]);
        $path = File::Spec->rel2abs($path, File::Spec->catpath($vol, $dir));
    }

    my $abs_path = Cwd::abs_path($path) or return [400, "Invalid path name"];
    return [409, "Recursive", $abs_path]
        if grep { $_ eq $abs_path } @{ $self->{_include_stack} };
    push @{ $self->{_include_stack} }, $abs_path;
    return [200, "OK", $abs_path];
}

sub _pop_include_stack {
    my $self = shift;

    die "BUG: Overpopped _pop_include_stack"
        unless @{$self->{_include_stack}};
    pop @{ $self->{_include_stack} };
}

sub _init_read {
    my $self = shift;

    $self->{_include_stack} = [];
}

sub _read_file {
    my ($self, $filename) = @_;
    open my $fh, "<", $filename
        or die "Can't open file '$filename': $!";
    binmode($fh, ":utf8");
    local $/;
    return ~~<$fh>;
}

sub read_file {
    my ($self, $filename) = @_;
    $self->_init_read;
    my $res = $self->_push_include_stack($filename);
    die "Can't read '$filename': $res->[1]" unless $res->[0] == 200;
    $res =
        $self->_read_string($self->_read_file($filename));
    $self->_pop_include_stack;
    $res;
}

sub read_string {
    my ($self, $str) = @_;
    $self->_init_read;
    $self->_read_string($str);
}

1;
# ABSTRACT: Base class for Config::Apachish and Config::Apachish::Reader

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Apachish::Base - Base class for Config::Apachish and Config::Apachish::Reader

=head1 VERSION

This document describes version 0.03 of Config::Apachish::Base (from Perl distribution Config-Apachish-Reader), released on 2016-03-11.

=head1 ATTRIBUTES

=for BEGIN_BLOCK: attributes

=for END_BLOCK: attributes

=head1 METHODS

=for BEGIN_BLOCK: methods

=head2 new(%attrs) => obj

=head2 $reader->read_file($filename)

Read Apachish configuration from a file. Die on errors.

=head2 $reader->read_string($str)

Read Apachish configuration from a string. Die on errors.

=for END_BLOCK: methods

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-Apachish-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-Apachish-Reader>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Apachish-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
