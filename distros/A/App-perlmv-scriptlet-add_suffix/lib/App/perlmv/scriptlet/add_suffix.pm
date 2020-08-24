package App::perlmv::scriptlet::add_suffix;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-22'; # DATE
our $DIST = 'App-perlmv-scriptlet-add_suffix'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SCRIPTLET = {
    summary => 'Add suffix to filenames',
    args => {
        suffix => {
            summary => 'The suffix string',
            schema => 'str*',
            req => 1,
        },
        before_ext => {
            summary => 'Put suffix before filename extension',
            schema => 'bool*',
        },
        avoid_duplicate_suffix => {
            summary => 'Avoid adding suffix when filename already has that suffix',
            schema => 'bool*',
        },
    },
    code => sub {
        package
            App::perlmv::code;

        use vars qw($ARGS);

        $ARGS && defined $ARGS->{suffix}
            or die "Please specify 'suffix' argument (e.g. '-a suffix=-new')";

        my ($name, $ext);

        if ($ARGS->{before_ext} && /\A(.+)((?:\.\w+)+)\z/) {
            ($name, $ext) = ($1, $2);
            #say "ext=<$ext>";
        } else {
            $name = $_;
            $ext = "";
        }

        #say "D:rindex=", rindex($name, $ARGS->{suffix});
        #say "D:length(suffix)=", length($ARGS->{suffix});
        #say "D:length(name)=", length($name);

        if ($ARGS->{avoid_duplicate_suffix} &&
                rindex($name, $ARGS->{suffix})+length($ARGS->{suffix}) == length($name)) {
            #say "D:1";
            return $_;
        }
        "$name$ARGS->{suffix}$ext";
    },
};

1;

# ABSTRACT: Add suffix to filenames

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::add_suffix - Add suffix to filenames

=head1 VERSION

This document describes version 0.001 of App::perlmv::scriptlet::add_suffix (from Perl distribution App-perlmv-scriptlet-add_suffix), released on 2020-08-22.

=head1 SYNOPSIS

With files:

 foo.txt
 bar-new.txt
 baz.txt-new

This command:

 % perlmv add-suffix -a suffix=-new *

will rename the files as follow:

 foo.txt -> foo.txt-new
 bar-new.txt -> bar-new.txt-new
 baz.txt-new baz.txt-new-new

This command:

 % perlmv add-suffix -a suffix=-new- -a before_ext=1 *

will rename the files as follow:

 foo.txt -> foo-new.txt
 bar-new.txt -> bar-new-new.txt
 baz.txt-new baz-new.txt-new

This command:

 % perlmv add-suffix -a suffix=-new- -before_ext=1 -a avoid_duplicate_suffix=1 *

will rename the files as follow:

 foo.txt -> foo-new.txt
 baz.txt-new baz-new.txt-new

=head1 SCRIPTLET ARGUMENTS

Arguments can be passed using the C<-a> (C<--arg>) L<perlmv> option, e.g. C<< -a name=val >>.

=head2 avoid_duplicate_suffix

Avoid adding suffix when filename already has that suffix. 

=head2 before_ext

Put suffix before filename extension. 

=head2 suffix

Required. The suffix string. 

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-add_suffix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-add_suffix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-add_suffix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::perlmv::scriptlet::add_prefix>

The C<remove-common-suffix> scriptlet

L<perlmv> (from L<App::perlmv>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
