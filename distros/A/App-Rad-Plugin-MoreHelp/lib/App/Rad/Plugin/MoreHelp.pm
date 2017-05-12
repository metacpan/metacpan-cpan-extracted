package App::Rad::Plugin::MoreHelp;
use strict;
use warnings;

our $VERSION = '0.0001'; # VERSION

sub more_help {
    my ($c, $msg) = @_;
    $c->register(help => sub { App::Rad::Help::help($c) . "\n$msg" },
        'show syntax and available commands');
}

# ABSTRACT: App::Rad plugin for providing extra help info.


1;

__END__
=pod

=head1 NAME

App::Rad::Plugin::MoreHelp - App::Rad plugin for providing extra help info.

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use App::Rad qw(MoreHelp);

    sub setup {
        my $c = shift;
        $c->more_help('This string gets appended to the main help message.');
    }

    App::Rad->run();

=head1 DESCRIPTION

This is an L<App::Rad> plugin for providing extra help info.
It provides a C<more_help> method which can be used to provide extra info
that will be appended to to bottom of the help message.

=head1 METHODS

=head2 more_help

    $c->more_help('This string gets appended to the help message.');

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

