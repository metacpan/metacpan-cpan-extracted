package App::perlmv::scriptlet::add_extension_according_to_mime_type;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-24'; # DATE
our $DIST = 'App-perlmv'; # DIST
our $VERSION = '0.606'; # VERSION

our $SCRIPTLET = {
    summary => q[Guess the file content's MIME type using LWP::MediaTypes then add an extension if type can be determined, or leave the filename alone otherwise],
    code => sub {
        package
            App::perlmv::code;
        require LWP::MediaTypes;

        # we skip directories
        return if -d $_;

        my $type = LWP::MediaTypes::guess_media_type($_);
        return unless $type;
        my @suffixes = LWP::MediaTypes::media_suffix($type);
        my $suffix_of_choice = LWP::MediaTypes::media_suffix($type); # since @suffixes will be in random order
        die "Bug! media_suffix() does not return suffixes for type '$type'" unless @suffixes;
        my $has_suffix;
        for my $suffix (@suffixes) {
            if (/\.\Q$suffix\E\z/i) {
                $has_suffix++;
                last;
            }
        }
        $_ = "$_.$suffix_of_choice" unless $has_suffix;
        $_;
    },
};

1;

# ABSTRACT: Guess the file content's MIME type using LWP::MediaTypes then add an extension if type can be determined, or leave the filename alone otherwise

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::add_extension_according_to_mime_type - Guess the file content's MIME type using LWP::MediaTypes then add an extension if type can be determined, or leave the filename alone otherwise

=head1 VERSION

This document describes version 0.606 of App::perlmv::scriptlet::add_extension_according_to_mime_type (from Perl distribution App-perlmv), released on 2022-06-24.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv>.

=head1 SEE ALSO

L<perlmv> (from L<App::perlmv>)

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
