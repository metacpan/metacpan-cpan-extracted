#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::App;
# ABSTRACT: magpie's App::Cmd
$App::Magpie::App::VERSION = '2.010';
use App::Cmd::Setup -app;

sub allow_any_unambiguous_abbrev { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::App - magpie's App::Cmd

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This is the main application, based on the excellent L<App::Cmd>.
Nothing much to see here, see the various subcommands available for more
information, or run one of the following:

    magpie commands
    magpie help

Note that each subcommand can be abbreviated as long as the abbreviation
is unambiguous.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
