package App::ShellCompleter::perlbrew;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Util qw(complete_array_elem);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       complete_perl_available_to_install
                       complete_perl_installed_to_use
                       complete_perl_installed_name
                       complete_perl_alias
                       list_available_perls
                       list_available_perl_versions
                       list_installed_perls
                       list_installed_perl_versions
                       list_perl_libs
                       list_perl_aliases
               );

sub list_available_perls {
    require File::Spec;
    require File::Slurper;
    my $tmp_path = File::Spec->tmpdir() . "/_perlbrew_available_perls.tmp";
    unless ((-f $tmp_path) && (-M _) <= 1) {
        File::Slurper::write_text($tmp_path, scalar `perlbrew available`);
    }
    my $available = File::Slurper::read_text($tmp_path);
    my @res;
    for (split /^/, $available) {
        s/^[i ] //;
        chomp;
        push @res, $_;
    }
    @res;
}

sub list_available_perl_versions {
    my @res;
    for (list_available_perls()) {
        s/\D+(?=\d)//;
        push @res, $_;
    }
    @res;
}

sub list_installed_perls {
    my @res;
    for (split /^/, `perlbrew list`) {
        s/^[* ] //;
        s/ \(.+\)$//; # alias
        chomp;
        push @res, $_;
    }
    @res;
}

sub list_installed_perl_versions {
    my @res;
    for (list_installed_perls()) {
        next unless /\d/;
        s/\D+(?=\d)//;
        push @res, $_;
    }
    @res;
}

sub list_perl_aliases {
    my @res;
    for (split /^/, `perlbrew list`) {
        s/^[* ] //;
        s/ \(.+\)$// or next; # alias
        chomp;
        push @res, $_;
    }
    @res;
}

sub list_perl_libs {
    my @res;
    for (split /^/, `perlbrew lib list`) {
        chomp;
        push @res, $_;
    }
    @res;
}

sub complete_perl_available_to_install {
    my $word = shift;

    local $Complete::Common::OPT_FUZZY = 0;
    complete_array_elem(
        word => $word,
        array => [
            ( list_available_perls(),
              "perl-stable", "stable",
              "perl-blead", "blead" ) x
                  ($word =~ /^\D|^$/ ? 1:0),
            list_available_perl_versions(),
        ],
    );
}

sub complete_perl_installed_to_use {
    my $word = shift;

    local $Complete::Common::OPT_FUZZY = 0;
    complete_array_elem(
        word => $word,
        array => [
            ( list_installed_perls() ) x
                ($word =~ /^\D|^$/ ? 1:0),
            list_installed_perl_versions(),
        ],
    );
}

sub complete_perl_installed_name {
    my $word = shift;
    local $Complete::Common::OPT_FUZZY = 0;
    return complete_array_elem(
        word => $word,
        array => [list_installed_perls()],
    );
}

sub complete_perl_alias {
    my $word = shift;

    local $Complete::Common::OPT_FUZZY = 0;
    complete_array_elem(
        word => $word,
        array => [
            list_perl_aliases(),
        ],
    );
}

1;
# ABSTRACT: Shell completion for perlbrew

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ShellCompleter::perlbrew - Shell completion for perlbrew

=head1 VERSION

This document describes version 0.007 of App::ShellCompleter::perlbrew (from Perl distribution App-ShellCompleter-perlbrew), released on 2017-07-10.

=head1 SYNOPSIS

See L<_perlbrew> included in this distribution.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ShellCompleter-perlbrew>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ShellCompleter-perlbrew>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ShellCompleter-perlbrew>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::perlbrew>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
