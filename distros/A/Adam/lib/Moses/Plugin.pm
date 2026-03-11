package Moses::Plugin;
# ABSTRACT: Sugar for Moses Plugins
our $VERSION = '1.003';
use Moose       ();
use MooseX::POE ();
use Moose::Exporter;
use Adam::Plugin;

Moose::Exporter->setup_import_methods(
    with_caller => [qw(events)],
    also        => [qw(Moose)],
);


sub init_meta {
    my ( $class, %args ) = @_;

    my $for = $args{for_class};
    eval qq{
        package $for;
        use POE;
        use POE::Component::IRC::Common qw( :ALL );
        use POE::Component::IRC::Plugin qw( :ALL );
    };

    Moose->init_meta(
        for_class  => $for,
        base_class => 'Adam::Plugin'
    );
}

sub events {
    my ( $caller, @events ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_method( 'default_events' => sub { return \@events } );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moses::Plugin - Sugar for Moses Plugins

=head1 VERSION

version 1.003

=head1 DESCRIPTION

The Moses::Plugin module provides a declarative sugar layer for
L<POE::Component::IRC> plugins based on the L<Adam::Plugin> class.

=head2 events

    events qw( S_public S_privmsg );

Declare which IRC events this plugin should listen to. Event names should be
prefixed with C<S_> for server events or C<U_> for user events.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/perigrin/adam-bot-framework/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
