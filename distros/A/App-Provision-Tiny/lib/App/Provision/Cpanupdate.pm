package App::Provision::Cpanupdate;
$App::Provision::Cpanupdate::VERSION = '0.0404';
our $AUTHORITY = 'cpan:GENE';
use strict;
use warnings;
use parent qw( App::Provision::Tiny );


sub condition
{
    my $self = shift;

    die "Program '$self->{program}' must include a --repo\n"
        unless $self->{repo};

    return 0; # Always update.
}


sub meet
{
    my $self = shift;
    $self->recipe(
      [
"find $self->{repo} -type d -name lib | xargs -n 1 dirname | sort | while read line; do echo \$line && cd \$line && cpan .; done"
      ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Provision::Cpanupdate

=head1 VERSION

version 0.0404

=head1 FUNCTIONS

=head2 condition

=head2 meet

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
