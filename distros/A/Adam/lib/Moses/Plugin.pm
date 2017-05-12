package Moses::Plugin;
BEGIN {
  $Moses::Plugin::VERSION = '0.91';
}
# ABSTRACT: Sugar for Moses Plugins
# Dist::Zilla: +PodWeaver
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



=pod

=head1 NAME

Moses::Plugin - Sugar for Moses Plugins

=head1 VERSION

version 0.91

=head1 DESCRIPTION

The Moses::Plugin builds a declarative sugar layer for
L<POE::Component::IRC|POE::Component::IRC> plugins based on the
L<Adam::Plugin|Adam::Plugin> class.

=head1 FUNCTIONS

=head2 events (@events)

Insert description of subroutine here...

=head1 BUGS AND LIMITATIONS

None known currently, please report bugs to L<https://rt.cpan.org/Ticket/Create.html?Queue=Adam>

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

