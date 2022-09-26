package App::Provision::Homebrew;
$App::Provision::Homebrew::VERSION = '0.0404';
our $AUTHORITY = 'cpan:GENE';
use strict;
use warnings;
use parent qw( App::Provision::Tiny );
use File::Which;


sub deps
{
    return qw( curl );
}


sub condition
{
    my $self = shift;

    # Reset the program name.
    $self->{program} = 'brew';

    my $callback  = shift || sub { which($self->{program}) };
    my $condition = $callback->();

    warn $self->{program}, ' is', ($condition ? '' : "n't"), " installed\n";

    return $condition ? 1 : 0;
}


sub meet
{
    my $self = shift;
    if ($self->{system} eq 'osx' )
    {
        $self->recipe(
            [ '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' ],
            [ 'brew', 'doctor' ],
        );
    }
    elsif ($self->{system} eq 'apt' )
    {
        $self->recipe(
            [ 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"' ],
            [ 'test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)' ],
            [ 'test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' ],
            [ 'test -r ~/.profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile' ],
            [ 'echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile' ],
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Homebrew

=head1 VERSION

version 0.0404

=head1 FUNCTIONS

=head2 deps

=head2 condition

=head2 meet

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
