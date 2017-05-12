package App::Presto::InstallableCommand;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::InstallableCommand::VERSION = '0.010';
# ABSTRACT: Role for command modules that can be installed

use Moo::Role;
use Scalar::Util qw(blessed);

has context => (
    is => 'ro',
    isa => sub { die "not an App::Presto (it's a $_[0])" unless blessed $_[0] && $_[0]->isa('App::Presto') },
    weak_ref => 1,
    handles => ['term','config', 'client','stash'],
);

requires 'install';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::InstallableCommand - Role for command modules that can be installed

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
