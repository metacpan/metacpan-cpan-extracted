package Catalyst::Model::CDBI;

# work around CDBI being incompatible with C3 mro, due to both Ima::DBI and Class::DBI::__::Base
# inheriting from Class::Data::Inheritable in an inconsistent order.
BEGIN {
    require Class::DBI;
    @Class::DBI::__::Base::ISA = grep { $_ ne 'Class::Data::Inheritable' } @Class::DBI::__::Base::ISA;
}

use strict;
use base qw/Catalyst::Component Class::DBI/;
use MRO::Compat;
use Class::DBI::Loader;

our $VERSION = '0.12';

__PACKAGE__->mk_accessors('loader');

=head1 NAME

Catalyst::Model::CDBI - [DEPRECATED] CDBI Model Class

=head1 SYNOPSIS

    # use the helper
    create model CDBI CDBI dsn user password

    # lib/MyApp/Model/CDBI.pm
    package MyApp::Model::CDBI;

    use base 'Catalyst::Model::CDBI';

    __PACKAGE__->config(
        dsn           => 'dbi:Pg:dbname=myapp',
        password      => '',
        user          => 'postgres',
        options       => { AutoCommit => 1 },
        relationships => 1
    );

    1;

    # As object method
    $c->comp('MyApp::Model::CDBI::Table')->search(...);

    # As class method
    MyApp::Model::CDBI::Table->search(...);

=head1 DESCRIPTION

This is the C<Class::DBI> model class. It's built on top of 
C<Class::DBI::Loader>. C<Class::DBI> is generally not used for new
applications, with C<DBIx::Class> being preferred instead. As such
this model is deprecated and (mostly) unmaintained.

It is preserved here for older applications which still need it for
backwards compatibility.

=head2 new

Initializes Class::DBI::Loader and loads classes using the class
config. Also attempts to borg all the classes.

=cut

sub new {
    my $class = shift;
    my $self  = $class->next::method( @_ );
    my $c     = shift;
    $self->{namespace}               ||= ref $self;
    $self->{additional_base_classes} ||= ();
    push @{ $self->{additional_base_classes} }, ref $self;
    eval { $self->loader( Class::DBI::Loader->new(%$self) ) };
    if ($@) { 
        Catalyst::Exception->throw( message => $@ );
    }
    else {
        $c->log->debug(
            'Loaded tables "' . join( ' ', $self->loader->tables ) . '"' )
          if $c->debug;
    }
    for my $class ( $self->loader->classes ) {
        $class->autoupdate(1);
        $c->components->{$class} ||= bless {%$self}, $class;
        no strict 'refs';
        *{"$class\::new"} = sub { bless {%$self}, $class };
    }
    return $self;
}

=head1 SEE ALSO

L<Catalyst>, L<Class::DBI> L<Class::DBI::Loader>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 CONTRIBUTORS

mst: Matt S Trout C<mst@shadowcat.co.uk>

Arathorn: Matthew Hodgson C<matthew@arasphere.net>

=head1 COPYRIGHT

Copyright (c) 2005 - 2010 the Catalyst::Model::CDBI L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
