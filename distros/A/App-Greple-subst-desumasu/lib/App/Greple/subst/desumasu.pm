package App::Greple::subst::desumasu;

our $VERSION = "0.06";

use 5.014;
use warnings;
use utf8;

use App::Greple::subst;

use File::Share qw(:all);
$ENV{DESUMASU_DICT} = dist_dir __PACKAGE__ =~ s/::/-/gr;

1;

=encoding utf-8

=head1 NAME

App::Greple::subst::desumasu - Japanese DESU/MASU dictionary for App::Greple::subst

=head1 SYNOPSIS

    greple -Msubst::desumasu --dearu --subst --all file

    greple -Msubst::desumasu --dearu --diff file

    greple -Msubst::desumasu --dearu --replace file

=head1 DESCRIPTION

greple -Msubst module based on
L<desumasu-converter|https://github.com/kssfilo/desumasu-converter>.

This is a simple checker/converter module for Japanese writing style
so called DUSU/MASU (ですます調: 敬体) and DEARU (である調: 常体).
This is not my own idea and the dictionary is based on
L<https://github.com/kssfilo/desumasu-converter>.

See article L<https://kanasys.com/tech/722> for detail.

=head1 OPTIONS

=over 7

=item B<--dearu>

=item B<--dearu-n>

=item B<--dearu-N>

Convert DESU/MASU to DEARU style.

DESU (です) and MASU (ます) sometimes followed by NE (ね) in frank
situation, and that NE (ね) is removed from converted result by
default.  Option with B<-n> keep that NE (ね), and option with B<-N>
igonore them.

=item B<--desumasu>

=item B<--desumasu-n>

=item B<--desumasu-N>

Convert DEARU to DESU/MASU style.

=back

Use them with B<greple> B<-Msubst> options.

=over 7

=item B<--subst --all --no-color>

Print converted text.

=item B<--diff>

Produce diff output of original and converted text.  Use B<cdif>
command in L<App::sdif> to visualize the difference.

=item B<--create>

=item B<--replace>

=item B<--overwrite>

To update the file, use these options.  Option B<--create> make new
file with C<.new> suffix.  Option B<--replace> update the target file
with backup, while option B<--overwrite> does without backup.

=back

See L<App::Greple::subst> for other options.

=head1 INSTALL

=head2 CPANMINUS

From CPAN:

    cpanm App::Greple::subst::desumasu

From GIT repository:

    cpanm https://github.com/kaz-utashiro/greple-subst-desumasu.git

=head1 SEE ALSO

L<App::Greple>, L<App::Greple::subst>

L<App::sdif>

L<https://github.com/kssfilo/desumasu-converter>,
L<https://kanasys.com/tech/722>

L<greple で「ですます調」を「である化」する|https://qiita.com/kaz-utashiro/items/8f4878300043ce7b73e7>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

option default -Msubst

define DICTDIR $ENV{DESUMASU_DICT}

option --desumasu --dict DICTDIR/desumasu.dict
option --dearu    --dict DICTDIR/dearu.dict

option --desumasu-n --dict DICTDIR/desumasu-keep-ne.dict
option --dearu-n    --dict DICTDIR/dearu-keep-ne.dict

option --desumasu-N --dict DICTDIR/desumasu-ignore-ne.dict
option --dearu-N    --dict DICTDIR/dearu-ignore-ne.dict

#  LocalWords:  diff cdif
