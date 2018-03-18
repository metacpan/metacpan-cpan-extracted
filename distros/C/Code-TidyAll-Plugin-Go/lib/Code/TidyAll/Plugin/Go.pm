package Code::TidyAll::Plugin::Go;

use strict;
use warnings;

our $VERSION = '0.04';

# ABSTRACT: Provides gofmt and go vet plugins for Code::TidyAll

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::Go - Provides gofmt and go vet plugins for Code::TidyAll

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your F<.tidyallrc> file:

    [Go::Fmt]
    select = **/*.go

    [Go::Vet]
    select = **/*.go

=head1 DESCRIPTION

This distro ships with two Go-related plugins for L<Code::TidyAll>. The
C<Go::Fmt> plugin formats your code with C<gofmt>. The C<Go::Vet> plugin runs
C<go vet> against your code and dies if that command finds anything to
complain about.

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/Code-TidyAll-Plugin-Go/issues>.

=head1 AUTHOR

Gregory Oschwald <oschwald@maxmind.com>

=head1 CONTRIBUTORS

=for stopwords Andy Jack Dave Rolsky Greg Oschwald

=over 4

=item *

Andy Jack <andyjack@users.noreply.github.com>

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
