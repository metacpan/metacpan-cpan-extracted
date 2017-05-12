package Bolts::Role::Opaque;
$Bolts::Role::Opaque::VERSION = '0.143171';
# ABSTRACT: Make a bag/artifact opaque to acquisition

use Moose::Role;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Role::Opaque - Make a bag/artifact opaque to acquisition

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    package MyApp::Secrets;
    use Moose;

    with 'Bolts::Role::Opaque';

    sub foo { "secret" }

    package MyApp;
    use Bolts;

    artifact 'secrets' => (
        class => 'MyApp::Secrets',
    );

    my $bag = MyApp->new;
    my $secrets = $bag->acquire('secrets'); # OK!
    my $foo     = $secrets->foo;            # OK!

    # NO NO NO! Croaks.
    my $foo_direct = $bag->acquire('secrets', 'foo'); # NO!

=head1 DESCRIPTION

Marks an artifact/bag so that the item cannot be reached via the C<acquire> method. 

Why? I don't know. It seemed like a good idea.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
