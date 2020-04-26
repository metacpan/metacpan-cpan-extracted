package Code::TidyAll::Role::Tempdir;

use strict;
use warnings;

use Path::Tiny qw(tempdir);
use Specio::Library::Builtins;
use Specio::Library::Path::Tiny;

use Moo::Role;

our $VERSION = '0.78';

has _tempdir => (
    is      => 'ro',
    isa     => t('Dir'),
    lazy    => 1,
    builder => 1,
);

has no_cleanup => (
    is      => 'ro',
    isa     => t('Bool'),
    default => 0,
);

sub _build__tempdir {
    my ($self) = @_;
    return tempdir(
        'Code-TidyAll-XXXX',
        CLEANUP => !$self->no_cleanup,
    );
}

1;

# ABSTRACT: Provides a _tempdir attribute for Code::TidyAll classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Role::Tempdir - Provides a _tempdir attribute for Code::TidyAll
classes

=head1 VERSION

version 0.78

=head1 SYNOPSIS

    package Whatever;
    use Moo;
    with 'Code::TidyAll::Role::Tempdir';

=head1 DESCRIPTION

A role to add tempdir attributes to classes.

=head1 ATTRIBUTES

=over

=item _tempdir

The temp directory. Lazily constructed if not passed

=item no_cleanup

A boolean indicating if the temp directory created by the C<_tempdir> builder
should not automatically clean up after itself

=back

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
