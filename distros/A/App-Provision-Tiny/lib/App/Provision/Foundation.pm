package App::Provision::Foundation;
$App::Provision::Foundation::VERSION = '0.0402';
BEGIN {
  $App::Provision::Foundation::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;
use parent qw( App::Provision::Tiny );

sub deps
{
    my $self = shift;
    return qw( wget unzip );
}

sub condition
{
    my $self = shift;

    die "Program '$self->{program}' must include a --site and --release\n"
        unless $self->{site} && $self->{release};

    my $condition = -e "$self->{site}/js/foundation.min.js";
    warn $self->{program}, ' is', ($condition ? '' : "n't"), " installed\n";

    return $condition ? 1 : 0;
}

sub meet
{
    my $self = shift;
    $self->recipe(
      [ 'wget', "http://foundation.zurb.com/cdn/releases/foundation-$self->{release}.zip", '-P', "$ENV{HOME}/Downloads/" ],
      [ 'unzip', "$ENV{HOME}/Downloads/foundation-$self->{release}.zip", '-d', "$ENV{HOME}/Downloads/foundation/" ],
      # TODO Make these a single * glob:
      [ 'mv', "$ENV{HOME}/Downloads/foundation/index.html", $self->{site} ],
      [ 'mv', "$ENV{HOME}/Downloads/foundation/css", $self->{site} ],
      [ 'mv', "$ENV{HOME}/Downloads/foundation/img", $self->{site} ],
      [ 'mv', "$ENV{HOME}/Downloads/foundation/js", $self->{site} ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Foundation

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
