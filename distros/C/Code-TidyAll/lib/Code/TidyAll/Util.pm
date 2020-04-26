package Code::TidyAll::Util;

use strict;
use warnings;

use File::Spec;
use Path::Tiny 0.098 qw(tempdir);

use Exporter qw(import);

our $VERSION = '0.78';

our @EXPORT_OK = qw(tempdir_simple);

use constant IS_WIN32 => $^O eq 'MSWin32';

sub tempdir_simple {
    my $template = shift || 'Code-TidyAll-XXXX';

    my %args = (
        TEMPLATE => $template,
        CLEANUP  => 1
    );

    # On Windows the default tmpdir is under C:\Users\<Current User>. If the
    # current user name is long or has spaces, then you get a short name like
    # LONGUS~1. But lots of other code, particularly in the tests, will end up
    # seeing long path names. This makes comparing paths to see if one path is
    # under the tempdir fail, because the long name and short name don't
    # compare as equal.
    if (IS_WIN32) {
        require Win32;
        $args{DIR} = Win32::GetLongPathName( File::Spec->tmpdir );
    }

    return tempdir(
        { realpath => 1 },
        %args,
    );
}

1;

# ABSTRACT: Utility functions for internal use by Code::TidyAll

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Util - Utility functions for internal use by Code::TidyAll

=head1 VERSION

version 0.78

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
