package Code::TidyAll::Result;

use strict;
use warnings;

use Moo;

our $VERSION = '0.65';

has 'error'         => ( is => 'ro' );
has 'new_contents'  => ( is => 'ro' );
has 'orig_contents' => ( is => 'ro' );
has 'path'          => ( is => 'ro' );
has 'state'         => ( is => 'ro' );

sub ok { return $_[0]->state ne 'error' }

1;

# ABSTRACT: Result returned from processing a file/source

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Result - Result returned from processing a file/source

=head1 VERSION

version 0.65

=head1 SYNOPSIS

    my $ct = Code::TidyAll->new(...);
    my $result = $ct->process_file($file);
    if ($result->error) {
       ...
    }

=head1 DESCRIPTION

Represents the result of
L<Code::TidyAll::process_file|Code::TidyAll/process_file> and
L<Code::TidyAll::process_file|Code::TidyAll/process_source>. A list of these is
returned from L<Code::TidyAll::process_paths|Code::TidyAll/process_paths>.

=head1 METHODS

=over

=item path

The path that was processed, relative to the root (e.g. "lib/Foo.pm")

=item state

A string, one of

=over

=item C<no_match> - No plugins matched this file

=item C<cached> - Cache hit (file had not changed since last processed)

=item C<error> - An error occurred while applying one of the plugins

=item C<checked> - File was successfully checked and did not change

=item C<tidied> - File was successfully checked and changed

=back

=item orig_contents

Contains the original contents if state is 'tidied' and with some errors (like
when a file needs tidying in check-only mode)

=item new_contents

Contains the new contents if state is 'tidied'

=item error

Contains the error message if state is 'error'

=item ok

Returns true iff state is not 'error'

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

This software is copyright (c) 2011 - 2017 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
