package App::Provision::Homebrew;
$App::Provision::Homebrew::VERSION = '0.0402';
BEGIN {
  $App::Provision::Homebrew::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;
use parent qw( App::Provision::Tiny );
use File::Which;

sub deps
{
    return qw( ruby curl );
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
    $self->recipe(
      [ 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"' ],
      [ 'brew', 'doctor' ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Homebrew

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
