package App::Provision::Repoupdate;
$App::Provision::Repoupdate::VERSION = '0.0402';
BEGIN {
  $App::Provision::Repoupdate::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;
use parent qw( App::Provision::Tiny );

sub condition
{
    my $self = shift;

    die "Program '$self->{program}' must include a --repo\n"
        unless $self->{repo};

    return 0; # Always update
}

sub meet
{
    my $self = shift;
    $self->recipe(
      [
"find $self->{repo} -type d -name .git | xargs -n 1 dirname | sort | while read line; do echo \$line && cd \$line && git pull; done"
      ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Repoupdate

=head1 VERSION

version 0.0402

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
