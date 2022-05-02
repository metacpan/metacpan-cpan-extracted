package App::Greple::git;

our $VERSION = "0.01";

1;

=encoding utf-8

=head1 NAME

git - Greple git module

=head1 SYNOPSIS

    greple -Mgit ...

=head1 DESCRIPTION

App::Greple::git is a greple module to handle git output.

=head1 OPTIONS

=over 7

=item B<--color-blame>

Read L<git-blame(1)> output and apply unique color for each
commit ids.

Set F<$HOME/.gitconfig> like this:

    [pager]
	blame = greple -Mgit --color-blame | less -cR

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-git/main/images/git-blame-small.png">

=end html

=back

=head1 ENVIRONMENT

=over 7

=item B<LESS>

=item B<LESSANSIENDCHARS>

Since B<greple> produces ANSI Erase Line terminal sequence, it is
convenient to set B<less> command understand them.

    LESS=-cR
    LESSANSIENDCHARS=mK

=back

=head1 SEE ALSO

L<App::Greple>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

option --color-blame \
	--re '^[0-9a-f^][0-9a-f]{7,39}\b.+' \
	--uniqcolor --uniqsub 'sub{s/\s.*//r}' \
	--all --face +E-D
