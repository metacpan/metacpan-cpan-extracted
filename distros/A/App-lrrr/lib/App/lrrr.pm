package App::lrrr;
# ABSTRACT: Little Restart Runner (Really)
use version;
our $VERSION = 'v0.0.3'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod     lrrr [--watch|-w <dir>]... <command>
#pod     lrrr --help|-h
#pod
#pod =head1 DESCRIPTION
#pod
#pod This program will watch one or more directories and re-run the given
#pod command when the contents of the files in those directories changes.
#pod
#pod See L<lrrr> for detailed documentation.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojo::Server::Morbo>
#pod
#pod =head1 AUTHOR
#pod
#pod (E<0xa9> 2019) Sebastian Riedel and the Mojolicious developers
#pod (E<0xa9>) Grant Street Group
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lrrr - Little Restart Runner (Really)

=head1 VERSION

version v0.0.3

=head1 SYNOPSIS

    lrrr [--watch|-w <dir>]... <command>
    lrrr --help|-h

=head1 DESCRIPTION

This program will watch one or more directories and re-run the given
command when the contents of the files in those directories changes.

See L<lrrr> for detailed documentation.

=head1 SEE ALSO

L<Mojo::Server::Morbo>

=head1 AUTHOR

(E<0xa9> 2019) Sebastian Riedel and the Mojolicious developers
(E<0xa9>) Grant Street Group

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 CONTRIBUTORS

=for stopwords Doug Bell LapVeesh Steven Arnott

=over 4

=item *

Doug Bell <doug.bell@grantstreet.com>

=item *

Doug Bell <preaction@users.noreply.github.com>

=item *

LapVeesh <rabbiveesh@gmail.com>

=item *

Steven Arnott <steven.arnott@grantstreet.com>

=back

=cut
