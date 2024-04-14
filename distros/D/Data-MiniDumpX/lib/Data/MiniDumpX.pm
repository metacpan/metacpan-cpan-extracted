## no critic: TestingAndDebugging::RequireUseStrict
package Data::MiniDumpX;

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

use Exporter qw(import);
use Plugin::System (
    hooks => {
        dump => {},
        dump_scalar => {},
        dump_array => {},
        dump_hash => {},
        dump_unknown_ref => {},
    },
);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-02'; # DATE
our $DIST = 'Data-MiniDumpX'; # DIST
our $VERSION = '0.000001'; # VERSION

our @EXPORT = qw(dd); ## no critic: Modules::ProhibitAutomaticExportation
our @EXPORT_OK = qw(dump);

my %esc = (
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);

# from Data::Dump
sub _quote {
    local($_) = $_[0];
    # If there are many '"' we might want to use qq() instead
    s/([\\\"\@\$])/\\$1/g;
    return qq("$_") unless /[^\040-\176]/;  # fast exit

    s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

    # no need for 3 digits in escape for these
    s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

    s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
    s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

    return qq("$_");
}

sub _str {
    _quote(shift);
}

sub dump {
    my $data = shift;

    hook_dump {
        my $ref = ref $data;

        if (!$ref) {
            hook_dump_scalar { _str($data) };
        } elsif ($ref eq 'ARRAY') {
            "[" . (hook_dump_array { join(", ", map { &dump($_) } @$data) }) . "]";
        } elsif ($ref eq 'HASH') {
            "{" . (hook_dump_hash  { join(", ", map { _quote($_) . ' => ' . &dump($data->{$_}) } sort keys %$data) }) . "}";
        } else {
            hook_dump_unknown_ref {
                die "Unsupported ref '$ref'";
            };
        }
    };
}

sub dd {
    my $data = shift;
    my $dump = &dump($data);

    print $dump;
    print "\n" unless $dump =~ /\R\z/;

    $data;
}

1;
# ABSTRACT: A simplistic data structure dumper (demo for Plugin::System)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MiniDumpX - A simplistic data structure dumper (demo for Plugin::System)

=head1 VERSION

This document describes version 0.000001 of Data::MiniDumpX (from Perl distribution Data-MiniDumpX), released on 2024-03-02.

=head1 SYNOPSIS

 use Data::MiniDumpX; # imports dd()

 dd [1, 2, 3]; # prints "[1, 2, 3]"

=head1 DESCRIPTION

This is a simplistic (limited) data structure dumper, meant to be a demo and
testing tool for L<Plugin::System>. See L<Data::DumpX> for the real thing.

=head1 FUNCTIONS

=head2 dump

Usage:

 my $dump = dump($data);

Not exported by default, exportable.

=head2 dd

Usage:

 dd($data); # returns $data

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-MiniDumpX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-MiniDumpX>.

=head1 SEE ALSO

L<Data::DumpX>

L<Plugin::System>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-MiniDumpX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
