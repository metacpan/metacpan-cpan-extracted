package App::optex::textconv::git;

our $VERSION = '1.04';

=encoding utf-8

=head1 NAME

textconv::git - optex::textconv submodule to handle git arguments

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

optex -Mtextconv::load=git command

=head1 DESCRIPTION

This is a submodule for L<App::optex::textconv> to handle GIT
arguments.  You don't have to call it explicitly.

=head1 OPTIONS

=head1 SEE ALSO

L<https://github.com/kaz-utashiro/optex>

L<https://github.com/kaz-utashiro/optex-textconv>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Data::Dumper;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ \&is_git_object => 'git show "%s"' ],
    );

1;

sub is_git_object {
    /.+:(?<path>.+)/ and -e $+{path} or return;
    my $ans = `git rev-parse $_ 2>&1`;
    $? == 0;
}

__DATA__

option default -Mtextconv
