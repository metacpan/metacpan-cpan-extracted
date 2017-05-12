package App::CharmKit::Command::lint;
$App::CharmKit::Command::lint::VERSION = '2.07';
# ABSTRACT: CharmKit Lint command


use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';
use App::CharmKit -command;
use parent 'App::CharmKit::Role::Lint';

sub abstract { "charm linter" }
sub description { "Lints your charm and its hooks" }
sub opt_spec {
    return ();
}

sub usage_desc {'%c lint'}

sub execute($self, $opt, $args) {
    $self->parse();
    exit($self->has_error);
}

1;

__END__

=pod

=head1 NAME

App::CharmKit::Command::lint - CharmKit Lint command

=head1 SYNOPSIS

  $ charmkit lint

=head1 DESCRIPTION

This will try to perform an indepth charm proof check so that uploaded charms
may receive quicker turnaround times during review process.

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
