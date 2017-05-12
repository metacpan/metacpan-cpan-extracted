package App::Provision::SourceTree;
$App::Provision::SourceTree::VERSION = '0.0402';
BEGIN {
  $App::Provision::SourceTree::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;
use parent qw( App::Provision::Tiny );

sub deps
{
    return qw( wget );
}

sub condition
{
    my $self = shift;

    die "Program '$self->{program}' must include a --release\n"
        unless $self->{release};

    # The program name is a special case for OSX.apps.
    $self->{program} = '/Applications/SourceTree.app';

    my $condition = -d $self->{program};
    warn $self->{program}, ' is', ($condition ? '' : "n't"), " installed\n";

    return $condition ? 1 : 0;
}

sub meet
{
    my $self = shift;
    if ( $self->{system} eq 'osx' )
    {
        $self->recipe(
          [ 'wget', "http://downloads.atlassian.com/software/sourcetree/SourceTree_$self->{release}.dmg", '-P', "$ENV{HOME}/Downloads/" ],
          [ 'hdiutil', 'attach', "$ENV{HOME}/Downloads/SourceTree_$self->{release}.dmg", ],
          [ 'cp', '-r', '/Volumes/SourceTree/SourceTree.app', '/Applications/' ],
          [ 'hdiutil', 'detach', '/Volumes/SourceTree' ],
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::SourceTree

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
