package Acme::CPANModules::MIMETypes;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-30'; # DATE
our $DIST = 'Acme-CPANModules-MIMETypes'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';
All recipes are categorized by tasks, then by most recommended module.

**1. Finding out filename extensions for a certain MIME type**

**1a. With <pm:File::MimeInfo> (uses system's type database):**

    use File::MimeInfo qw(extensions);
    $ext  = extensions("image/jpeg"); # => "jpeg"
    @exts = extensions("image/jpeg"); # => ("jpeg", "jpe", "jpg")

**1b. With <pm:MIME::Types> (comes with its own type database):**

    use MIME::Types;
    my $mt = MIME::Types->new->type("image/jpeg") or die "Unknown MIME type";
    my @exts = $m->extensions; # => ("jpeg", "jpg", "jpe", "jfif", "jfif-tbnl")

**1c. With <pm:Media::Type::Simple> (can uses system's C</etc/mime.types>):**

    use Media::Type::Simple;
    $ext  = ext_from_type("image/jpeg"); # => "jpeg"
    @exts = ext_from_type("image/jpeg"); # => ("jpeg", "jpg", "jpe", "jfif")

**2. Finding out the MIME type associated with a certain filename extension**

**2a. With MIME::Types:**

    use MIME::Types;
    my $mt = MIME::Types->new->mimeTypeOf("gif") or die "Unknown MIME type";
    say "$mt" ;# => "image/gif"

**2b. With Media::Type::Simple:**

    use Media::Type::Simple;
    $type = type_from_ext("jpg"); # => "image/jpeg"

**2c. With <pm:MIME::Type::FileName> (comes with its own type database, last updated 2012):**

    use MIME::Type::FileName;
    my $mimetype = MIME::Type::FileName::guess ("my-file.xls") or die "Unknown MIME type";


**3. Guessing MIME type of a file based on its extension**

**3a. With File::MimeInfo:**

    use File::MimeInfo;
    my $mime_type = mimetype('test.png') or die "Unknown MIME type";

**3b. With <pm:LWP::MediaTypes> (comes with its own type database):**

    use LWP::MediaTypes;
    my $type = LWP::MediaTypes::guess_media_type("file.xls") or die "Unknown MIME type";


**4. Guessing MIME type of a file based on its content**

**4a. Using <pm:File::MimeInfo::Magic> (same interface as File::MimeInfo):**

    use File::MimeInfo::Magic;

    $type = mimetype("file.jpg"); # => "image/jpeg"

    # For symlink, will return "octet/symlink". To follow symlink, open file and
    # pass filehandle.
    open my $fh, "<", "symlink-to-file.jpg" or die "Can't open file: $!";
    $type = mimetype($fh); # => "image/jpeg"

**4b. Using other modules:**

<pm:Alien::LibMagic>

<pm:File::LibMagic>

<pm:File::LibMagic::FFI>

<pm:File::MMagic>

<pm:File::MMagic::XS>

<pm:File::Type>

_

our $LIST = {
    summary => 'List of modules to work with MIME types',
    tags => ['recipes'],
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to work with MIME types

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::MIMETypes - List of modules to work with MIME types

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::MIMETypes (from Perl distribution Acme-CPANModules-MIMETypes), released on 2023-06-30.

=head1 DESCRIPTION

All recipes are categorized by tasks, then by most recommended module.

B<1. Finding out filename extensions for a certain MIME type>

B<< 1a. With L<File::MimeInfo> (uses system's type database): >>

 use File::MimeInfo qw(extensions);
 $ext  = extensions("image/jpeg"); # => "jpeg"
 @exts = extensions("image/jpeg"); # => ("jpeg", "jpe", "jpg")

B<< 1b. With L<MIME::Types> (comes with its own type database): >>

 use MIME::Types;
 my $mt = MIME::Types->new->type("image/jpeg") or die "Unknown MIME type";
 my @exts = $m->extensions; # => ("jpeg", "jpg", "jpe", "jfif", "jfif-tbnl")

B<< 1c. With L<Media::Type::Simple> (can uses system's C</etc/mime.types>): >>

 use Media::Type::Simple;
 $ext  = ext_from_type("image/jpeg"); # => "jpeg"
 @exts = ext_from_type("image/jpeg"); # => ("jpeg", "jpg", "jpe", "jfif")

B<2. Finding out the MIME type associated with a certain filename extension>

B<2a. With MIME::Types:>

 use MIME::Types;
 my $mt = MIME::Types->new->mimeTypeOf("gif") or die "Unknown MIME type";
 say "$mt" ;# => "image/gif"

B<2b. With Media::Type::Simple:>

 use Media::Type::Simple;
 $type = type_from_ext("jpg"); # => "image/jpeg"

B<< 2c. With L<MIME::Type::FileName> (comes with its own type database, last updated 2012): >>

 use MIME::Type::FileName;
 my $mimetype = MIME::Type::FileName::guess ("my-file.xls") or die "Unknown MIME type";

B<3. Guessing MIME type of a file based on its extension>

B<3a. With File::MimeInfo:>

 use File::MimeInfo;
 my $mime_type = mimetype('test.png') or die "Unknown MIME type";

B<< 3b. With L<LWP::MediaTypes> (comes with its own type database): >>

 use LWP::MediaTypes;
 my $type = LWP::MediaTypes::guess_media_type("file.xls") or die "Unknown MIME type";

B<4. Guessing MIME type of a file based on its content>

B<< 4a. Using L<File::MimeInfo::Magic> (same interface as File::MimeInfo): >>

 use File::MimeInfo::Magic;
 
 $type = mimetype("file.jpg"); # => "image/jpeg"
 
 # For symlink, will return "octet/symlink". To follow symlink, open file and
 # pass filehandle.
 open my $fh, "<", "symlink-to-file.jpg" or die "Can't open file: $!";
 $type = mimetype($fh); # => "image/jpeg"

B<4b. Using other modules:>

L<Alien::LibMagic>

L<File::LibMagic>

L<File::LibMagic::FFI>

L<File::MMagic>

L<File::MMagic::XS>

L<File::Type>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<File::MimeInfo>

Author: L<MICHIELB|https://metacpan.org/author/MICHIELB>

=item L<MIME::Types>

Author: L<MARKOV|https://metacpan.org/author/MARKOV>

=item L<Media::Type::Simple>

Author: L<RRWO|https://metacpan.org/author/RRWO>

=item L<MIME::Type::FileName>

Author: L<JHIVER|https://metacpan.org/author/JHIVER>

=item L<LWP::MediaTypes>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

=item L<File::MimeInfo::Magic>

Author: L<MICHIELB|https://metacpan.org/author/MICHIELB>

=item L<Alien::LibMagic>

Author: L<ZMUGHAL|https://metacpan.org/author/ZMUGHAL>

=item L<File::LibMagic>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item L<File::LibMagic::FFI>

Author: L<PLICEASE|https://metacpan.org/author/PLICEASE>

=item L<File::MMagic>

Author: L<KNOK|https://metacpan.org/author/KNOK>

=item L<File::MMagic::XS>

Author: L<DMAKI|https://metacpan.org/author/DMAKI>

=item L<File::Type>

Author: L<PMISON|https://metacpan.org/author/PMISON>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n MIMETypes

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries MIMETypes | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=MIMETypes -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::MIMETypes -E'say $_->{module} for @{ $Acme::CPANModules::MIMETypes::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-MIMETypes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-MIMETypes>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-MIMETypes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
