package App::Changelord;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: cli-based changelog manager
$App::Changelord::VERSION = 'v0.0.1';
use 5.36.0;

use Moo;
use CLI::Osprey
    desc => 'changelog manager';

use YAML;

use List::AllUtils qw/ pairmap partition_by /;

use App::Changelord::Role::ChangeTypes;

sub run($self) {
    App::Changelord::Command::Print->new(
        parent_command => $self,
    )->run;
}

subcommand $_ => 'App::Changelord::Command::' . ucfirst $_ =~ s/-(.)/uc $1/er
    for qw/ schema validate version bump init add git-gather print /;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord - cli-based changelog manager

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

C<App::Changelord> offers a collection of cli commands to
interact with a YAML-based CHANGELOG file format, from which
a Markdown CHANGELOG fit for general comsumption can be generated.

See the original blog entry in the C<SEE ALSO> section for the full
motivation.

For a list of the commands, C<changelord --help>, then to
get information on the individual commands C<changelord *subcommand* --man>.

=head1 SEE ALSO

L<Changelord, registrar of deeds extraordinaire|https://techblog.babyl.ca/entry/changelord> - the introducing blog entry.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
