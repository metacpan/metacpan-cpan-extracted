package App::Provision::Perlbrew;
$App::Provision::Perlbrew::VERSION = '0.0402';
BEGIN {
  $App::Provision::Perlbrew::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;
use parent qw( App::Provision::Tiny );

sub deps
{
    return qw( curl );
}

sub meet
{
    my $self = shift;

    $self->{release} ||= '5.18.2';

    $self->recipe(
      [ 'curl -L http://install.perlbrew.pl | bash' ],
      [ 'touch', "$ENV{HOME}/.bash_profile" ],
      [ "echo 'source ~/perl5/perlbrew/etc/bashrc' >> $ENV{HOME}/.bash_profile" ],
      [ "`source', $ENV{HOME}/.bash_profile`" ],
      [qw( perlbrew install ), "perl-$self->{release}" ],
      [qw( perlbrew switch ), "perl-$self->{release}" ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Perlbrew

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
