package App::Provision::Sequelpro;
$App::Provision::Sequelpro::VERSION = '0.0402';
BEGIN {
  $App::Provision::Sequelpro::AUTHORITY = 'cpan:GENE';
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
    $self->{program} = '/Applications/Sequel Pro.app';

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
          [ 'wget', "https://sequel-pro.googlecode.com/files/sequel-pro-$self->{release}.dmg", '-P', "$ENV{HOME}/Downloads/" ],
          [ 'hdiutil', 'attach', "$ENV{HOME}/Downloads/sequel-pro-$self->{release}.dmg", ],
          [ 'cp', '-r', "/Volumes/Sequel Pro $self->{release}/Sequel Pro.app", '/Applications/' ],
          [ 'hdiutil', 'detach', "/Volumes/Sequel Pro $self->{release}" ],
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Sequelpro

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
