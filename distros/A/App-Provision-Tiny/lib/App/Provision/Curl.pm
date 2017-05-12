package App::Provision::Curl;
$App::Provision::Curl::VERSION = '0.0402';
BEGIN {
  $App::Provision::Curl::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;
use parent qw( App::Provision::Tiny );

sub deps
{
    return qw( homebrew );
}

sub meet
{
    my $self = shift;
    if ($self->{system} eq 'osx' )
    {
        $self->recipe(
          [qw( brew install curl )],
        );
    }
    elsif ($self->{system} eq 'apt' )
    {
        $self->recipe(
          [qw( sudo apt-get install curl )],
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Curl

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
