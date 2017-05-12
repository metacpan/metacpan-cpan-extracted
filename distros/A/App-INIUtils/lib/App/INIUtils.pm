package App::INIUtils;

our $VERSION = '0.02'; # VERSION
our $DATE = '2015-12-10'; # DATE

use 5.010001;

our %args_common = (
    ini => {
        summary => 'INI file',
        schema  => ['str*'],
        req     => 1,
        pos     => 0,
        cmdline_src => 'stdin_or_file',
        tags    => ['common'],
    },
);

our %arg_parser = (
    parser => {
        summary => 'Parser to use',
        schema  => ['str*', {
            in => [
                'Config::INI::Reader',
                'Config::IniFiles',
            ],
        }],
        default => 'Config::INI::Reader',
        tags    => ['common'],
    },
);

sub _parse_str {
    my ($ini, $parser) = @_;

    if ($parser eq 'Config::INI::Reader') {
        require Config::INI::Reader;
        return Config::INI::Reader->read_string($ini);
    } elsif ($parser eq 'Config::IniFiles') {
        require Config::IniFiles;
        require File::Temp;
        my ($tempfh, $tempnam) = File::Temp::tempfile();
        print $tempfh $ini;
        close $tempfh;
        my $cfg = Config::IniFiles->new(-file => $tempnam);
        die join("\n", @Config::IniFiles::errors) unless $cfg;
        unlink $tempnam;
        return $cfg;
    } else {
        die "Unknown parser '$parser'";
    }
}

1;
# ABSTRACT: INI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::INIUtils - INI utilities

=head1 VERSION

This document describes version 0.02 of App::INIUtils (from Perl distribution App-INIUtils), released on 2015-12-10.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<parse-ini>

=back

The main feature of these utilities is tab completion.

=head1 SEE ALSO

L<App::IODUtils>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-INIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-INIUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-INIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
