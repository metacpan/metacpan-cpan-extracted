package Code::TidyAll::Plugin::MasonTidy;

use strict;
use warnings;

use Mason::Tidy::App;
use Text::ParseWords qw(shellwords);

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.78';

sub _build_cmd {'masontidy'}

sub transform_source {
    my ( $self, $source ) = @_;

    local @ARGV = shellwords( $self->argv );
    local $ENV{MASONTIDY_OPT};
    my $dest = Mason::Tidy::App->run($source);
    return $dest;
}

1;

# ABSTRACT: Use masontidy with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::MasonTidy - Use masontidy with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   In configuration:

   [MasonTidy]
   select = comps/**/*.{mc,mi}
   argv = --indent-perl-block 0 --perltidy-argv "-noll -l=78"

=head1 DESCRIPTION

Runs L<masontidy>, a tidier for L<HTML::Mason> and L<Mason 2|Mason> components.

=head1 INSTALLATION

Install L<masontidy> from CPAN.

    cpanm masontidy

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 argv

Arguments to pass to C<masontidy>.

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
