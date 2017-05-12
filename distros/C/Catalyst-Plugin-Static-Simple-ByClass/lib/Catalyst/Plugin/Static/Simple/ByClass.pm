package Catalyst::Plugin::Static::Simple::ByClass;

use warnings;
use strict;
use Carp;
use Moose::Role;
use namespace::autoclean;
use Class::Inspector;
use Path::Class;
with 'Catalyst::Plugin::Static::Simple';

our $VERSION = '0.005';

=head1 NAME

Catalyst::Plugin::Static::Simple::ByClass - locate static content in @INC

=head1 SYNOPSIS

 use Catalyst qw(
    Static::Simple::ByClass
 );
 
 __PACKAGE__->config(
     'Plugin::Static::Simple::ByClass' => {
         classes => [ qw( MyClass::Foo ) ]
     }
 );

=head1 DESCRIPTION

Catalyst::Plugin::Static::Simple::ByClass is a subclass of
Catalyst::Plugin::Static::Simple. It extends the base class to alter
the include_path config to include @INC paths for classes. The idea
is that you can distribute static files (.js and .css for example)
with applications, and those files can be served during development
directly from the installed @INC location.
 
=head1 METHODS

Only new or overridden method are documented here.

=head2 setup

Calls next::method and then checks the B<classes> config option
for a list of class names to require and add to the include_path.

=cut

before setup_finalize => sub {
    my $c = shift;

    $c->log->warn(
        "Deprecated 'static' config key used, please use the key 'Plugin::Static::Simple::ByClass' instead"
    ) if exists $c->config->{static};

    my $config = $c->config->{'Plugin::Static::Simple::ByClass'}
        = Catalyst::Utils::merge_hashes(
        $c->config->{'Plugin::Static::Simple::ByClass'} || {},
        $c->config->{static} || {} );

    for my $class ( @{ $config->{classes} || [] } ) {

        eval "require $class";
        if ($@) {
            $c->error( __PACKAGE__ . " : Failed to load $class" );
            return;
        }
        my $base = Class::Inspector->loaded_filename($class);
        $base =~ s/\.pm$//;
        push( @{ $c->config->{'Plugin::Static::Simple'}->{include_path} }, Path::Class::dir($base) );

    }
    return $c;
};

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-static-simple-byclass@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2009 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

