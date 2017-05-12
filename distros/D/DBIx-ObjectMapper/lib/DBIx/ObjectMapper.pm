package DBIx::ObjectMapper;
use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.3013';

use Carp::Clan qw/^DBIx::ObjectMapper/;
use Params::Validate qw(:all);

use DBIx::ObjectMapper::Log;
use DBIx::ObjectMapper::Utils;
use DBIx::ObjectMapper::Metadata;
use DBIx::ObjectMapper::Mapper;
use DBIx::ObjectMapper::Session;

my $DEFAULT_MAPPING_CLASS = 'DBIx::ObjectMapper::Mapper';
my $DEFAULT_SESSION_CLASS = 'DBIx::ObjectMapper::Session';

sub new {
    my $class = shift;
    my %param_tmp = @_;

    my %param = validate(
        @_,
        {   engine => { type => OBJECT, isa => 'DBIx::ObjectMapper::Engine' },
            metadata => {
                type => OBJECT,
                isa => 'DBIx::ObjectMapper::Metadata',
                default => DBIx::ObjectMapper::Metadata->new(),
            },
            mapping_class => {
                type     => SCALAR,
                isa      => $DEFAULT_MAPPING_CLASS,
                default  => $DEFAULT_MAPPING_CLASS,
            },
            session_class => {
                type     => SCALAR,
                isa      => $DEFAULT_SESSION_CLASS,
                default  => $DEFAULT_SESSION_CLASS,
            },
            session_attr => {
                type => HASHREF,
                default => +{},
            },
        }
    );

    $param{metadata}->engine($param{engine});

    return bless \%param, $class;
}

sub metadata      { $_[0]->{metadata} }
sub engine        { $_[0]->{engine} }
sub mapping_class { $_[0]->{mapping_class} }
sub session_class { $_[0]->{session_class} }

sub maps {
    my $self = shift;

    my $metatable = shift;
    my $mapping_class = shift;

    $metatable = $self->metadata->t($metatable) unless ref($metatable);
    my $mapper = $self->mapping_class->new( $metatable => $mapping_class, @_ );
}

sub begin_session {
    my $self = shift;
    my %attr = (
        %{$self->{session_attr}},
        @_
    );
    $attr{engine} = $self->engine unless exists $attr{engine};
    return $self->session_class->new(%attr);
}

sub relation {
    my $self = shift;
    my $class = ref($self) || $self;
    my $rel_type = shift;
    my $rel_class
        = $class
        . '::Relation::'
        . DBIx::ObjectMapper::Utils::camelize($rel_type);
    Class::MOP::load_class($rel_class)
        unless Class::MOP::is_class_loaded($rel_class);
    return $rel_class->new( @_ );
}

sub attribute {
    my $self = shift;
    my $map_class = shift;
    if( DBIx::ObjectMapper::Mapper->is_initialized($map_class) ) {
        return $map_class->__class_mapper__->attributes;
    }
    else {
        my $class = ref($self);
        confess "the $map_class is not under the management of $class";
    }
}

*attr = \&attribute;

1;
__END__

=head1 NAME

DBIx::ObjectMapper - An implementation of the Data Mapper pattern (object-relational mapper).

=head1 SYNOPSIS

Create a engine and a mapper object.

 use DBIx::ObjectMapper;
 use DBIx::ObjectMapper::Engine::DBI;

 my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'dbi:SQLite:',
    username => undef,
    password => undef,
 });

 my $mapper = DBIx::ObjectMapper->new( engine => $engine );

Create a ordinary perl class.

 package My::User;
 use base qw(Class::Accessor::Fast);
 __PACKAGE__->mk_accessors(qw(id name));

 1;

Get/Define metadata of the table.

 my $user_meta = $mapper->metadata->table( 'user' => 'autoload' );

 # or

 use DBIx::ObjectMapper::Metadata::Sugar qw(:all);
 my $user_meta = $mapper->metadata->table(
     'user' => [
         Col( id => Int(), PrimaryKey ),
         Col( name => String(128), NotNull ),
     ]
 );

Map the table metadata to the ordinary class.

 $mapper->maps( $user_meta => 'My::User' );

Create session. And add My::User object to session object.

 my $session = $mapper->begin_session;
 my $user = My::User->new({ id => 1, name => 'name1' });
 $session->add($user);

When the $session is destroyed, the session object send a insert query to the database.

Get a My::User Object.

 my $session = $mapper->begin_session;
 my $user = $session->get( 'My::User' => 1 );
 $user->id;
 $user->name;

=head1 DESCRIPTION

DBIx::ObjectMapper is a implementation of the Data Mapper pattern. And abstraction layer for database access.

Concepts and interfaces of this module borrowed from SQLAlchemy.
L<http://www.sqlalchemy.org/>

=head1 METHODS

=head2 new(%args)

=over 5

=item B<engine>

L<DBIx::ObjectMapper::Engine>


=item B<metadata>

By default L<DBIx::ObjectMapper::Metadata>.
Set a L<DBIx::ObjectMapper::Metadata> based object if you want.

=item B<mapping_class>

By default L<DBIx::ObjectMapper::Mapper>.
Set a L<DBIx::ObjectMapper::Mapper> based object if you want.

=item B<session_class>

By default L<DBIx::ObjectMapper::Session>.
Set a L<DBIx::ObjectMapper::Session> based class if you want.

=item B<session_attr>

Set a hash reference of counstructor parameters of L<DBIx::ObjectMapper::Session>.
When you call the L<begin_session> method, you get a L<DBIx::ObjectMapper::Session> object that this option is set up.

=back

=head2 begin_session(%session_option)

Gets a session object instance, and begins session.
See the L<DBIx::ObjectMapper::Session> for more information.

=head2 maps(%map_config)

Sets a configuration of mapping.
See the L<DBIx::ObjectMapper::Mapper> for more information.

=head2 relation( $relation_type => \%relation_config )

L<DBIx::ObjectMapper::Relation>

=head2 metadata()

Returns the metadata object.

=head2 engine()

Returns the engine object.

=head2 mapping_class()

Returns the mapping_class.

=head2 session_class()

Returns the session_class.

=head1 AUTHOR

Eisuke Oishi

=head1 CONTRIBUTORS

nekokak: Atsushi Kobayashi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

