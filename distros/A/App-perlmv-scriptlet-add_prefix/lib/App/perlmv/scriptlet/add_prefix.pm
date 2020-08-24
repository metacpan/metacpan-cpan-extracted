package App::perlmv::scriptlet::add_prefix;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-22'; # DATE
our $DIST = 'App-perlmv-scriptlet-add_prefix'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SCRIPTLET = {
    summary => 'Add prefix to filenames',
    args => {
        prefix => {
            summary => 'The prefix string',
            schema => 'str*',
            req => 1,
        },
        avoid_duplicate_prefix => {
            summary => 'Avoid adding prefix when filename already has that prefix',
            schema => 'bool*',
        },
    },
    code => sub {
        package
            App::perlmv::code;

        use vars qw($ARGS);

        $ARGS && defined $ARGS->{prefix}
            or die "Please specify 'prefix' argument (e.g. '-a prefix=new-')";

        if ($ARGS->{avoid_duplicate_prefix} && index($_, $ARGS->{prefix}) == 0) {
            return $_;
        }
        "$ARGS->{prefix}$_";
    },
};

1;

# ABSTRACT: Add prefix to filenames

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::add_prefix - Add prefix to filenames

=head1 VERSION

This document describes version 0.002 of App::perlmv::scriptlet::add_prefix (from Perl distribution App-perlmv-scriptlet-add_prefix), released on 2020-08-22.

=head1 SYNOPSIS

With filenames:

 foo.txt
 new-bar.txt

This command:

 % perlmv add-prefix -a prefix=new- *

will rename the files as follow:

 foo.txt -> new-foo.txt
 new-bar.txt -> new-new-bar.txt

This command:

 % perlmv add-prefix -a prefix=new- -a avoid_duplicate_prefix=1 *

will rename the files as follow:

 foo.txt -> new-foo.txt

=head1 SCRIPTLET ARGUMENTS

Arguments can be passed using the C<-a> (C<--arg>) L<perlmv> option, e.g. C<< -a name=val >>.

=head2 avoid_duplicate_prefix

Avoid adding prefix when filename already has that prefix. 

=head2 prefix

Required. The prefix string. 

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-add_prefix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-add_prefix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-add_prefix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::perlmv::scriptlet::add_suffix>

The C<remove-common-prefix> scriptlet

L<perlmv> (from L<App::perlmv>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
