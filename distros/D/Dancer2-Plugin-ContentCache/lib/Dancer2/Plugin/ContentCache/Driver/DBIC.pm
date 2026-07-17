package Dancer2::Plugin::ContentCache::Driver::DBIC;
use v5.20;
use warnings;
use Carp;
use Moo;
use Scalar::Util qw(blessed);
use DateTime;
use DateTime::Format::Strptime;

with 'Dancer2::Plugin::ContentCache::Driver';

our $VERSION = '1.0000'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

has plugin => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has schema_name => (
    is      => 'ro',
    default => sub { 'default' },
);

has result_set_name => (
    is       => 'ro',
    required => 1,
);

has resultset => (
    is  => 'lazy',
);

has _columns => (
    is  => 'lazy',
);

has _primary_column => (
    is  => 'lazy',
);

my $DT_FORMAT = DateTime::Format::Strptime->new(
    pattern   => '%Y-%m-%d %H:%M:%S',
    time_zone => 'local',
    on_error  => 'croak',
);

sub create_entry {
    my ( $self, %entry ) = @_;

    my %row = (
        $self->_primary_column => $entry{uuid},
        data                   => $entry{data},
        metadata               => $entry{metadata},
    );

    $row{created_dt} = $self->_deflate_dt( $entry{created_dt} )
        if $entry{created_dt} && $self->_columns->{created_dt};

    $row{expiry_dt} = $self->_deflate_dt( $entry{expiry_dt} )
        if $entry{expiry_dt} && $self->_columns->{expiry_dt};

    $self->resultset->create( \%row );

    return $entry{uuid};
}

sub delete_expired {
    my $self = shift;

    return 0 unless $self->_columns->{expiry_dt};

    return $self->resultset->search(
        { expiry_dt => { '<' => $self->_deflate_dt( DateTime->now ) } }
    )->delete_all;
}

sub find_entry {
    my ( $self, $uuid ) = @_;

    my $row = $self->resultset->find($uuid) or return undef;

    return {
        uuid       => $row->get_column( $self->_primary_column ),
        data       => $row->get_column('data'),
        metadata   => $row->get_column('metadata'),
        created_dt => $self->_columns->{created_dt}
            ? $self->_inflate_dt( $row->get_column('created_dt') )
            : undef,
        expiry_dt => $self->_columns->{expiry_dt}
            ? $self->_inflate_dt( $row->get_column('expiry_dt') )
            : undef,
    };
}

sub has_aging_columns {
    my $self = shift;
    return ( $self->_columns->{created_dt} && $self->_columns->{expiry_dt} ) ? 1 : 0;
}

sub has_created_column {
    my $self = shift;
    return $self->_columns->{created_dt} ? 1 : 0;
}

sub _build__columns {
    my $self = shift;
    return { map { $_ => 1 } $self->resultset->result_source->columns };
}

sub _build__primary_column {
    my $self = shift;

    my @pk = $self->resultset->result_source->primary_columns;
    croak 'ContentCache: the \'' . $self->result_set_name
        . '\' result set must have a single-column primary key'
        unless @pk == 1;

    return $pk[0];
}

sub _build_resultset {
    my $self = shift;
    my $app  = $self->plugin->app;

    # Dancer2::Plugin::DBIC and Dancer2::Plugin::DBIx::Class are
    # interchangeable here -- both provide a 'schema' method. Prefer
    # whichever one the app has actually loaded (find_plugin only looks at
    # plugins already registered; it won't instantiate one). Blindly trying
    # with_plugin() would happily instantiate whichever plugin class is
    # merely *installed*, even if the app was never configured to use it,
    # and it would then fail later with a confusing "schema not configured"
    # error instead of falling through.
    my $dbic = $app->find_plugin('Dancer2::Plugin::DBIC')
        // $app->find_plugin('Dancer2::Plugin::DBIx::Class');

    if ( !$dbic ) {
        my $plugin_config = $app->config->{plugins} // {};
        my $name
            = exists $plugin_config->{DBIC}         ? 'DBIC'
            : exists $plugin_config->{'DBIx::Class'} ? 'DBIx::Class'
            :                                           'DBIx::Class';
        $dbic = $app->with_plugin($name);
    }

    return $dbic->schema( $self->schema_name )->resultset( $self->result_set_name );
}

sub _deflate_dt {
    my ( $self, $dt ) = @_;
    return undef unless $dt;
    return $dt if !blessed($dt);

    # Storage is always in local wall-clock time (see _inflate_dt), so any
    # incoming DateTime -- e.g. DateTime->now, which defaults to UTC -- must
    # be converted to local before its fields are extracted for storage.
    return $DT_FORMAT->format_datetime( $dt->clone->set_time_zone('local') );
}

sub _inflate_dt {
    my ( $self, $value ) = @_;
    return undef unless defined $value;
    return $value if blessed($value) && $value->isa('DateTime');
    return $DT_FORMAT->parse_datetime($value);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ContentCache::Driver::DBIC - DBIx::Class storage driver for Dancer2::Plugin::ContentCache

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

 # In config.yml:
 plugins:
   ContentCache:
     driver: DBIx::Class          # the default; you don't need to say so
     schema: default
     cache_result_set: ContentCache

=head1 DESCRIPTION

This is the default storage driver for L<Dancer2::Plugin::ContentCache>. It
consumes L<Dancer2::Plugin::ContentCache::Driver> and stores cache entries
using L<Dancer2::Plugin::DBIx::Class> (or any other plugin that provides a
compatible C<schema> keyword).

It expects the configured result set to provide at least a single-column
primary key, plus C<data> and C<metadata> columns. If C<created_dt> and/or
C<expiry_dt> columns are also present, they will be populated automatically;
see L<Dancer2::Plugin::ContentCache/"SUGGESTED SCHEMA">.

This driver does not require the result class to use
L<DBIx::Class::InflateColumn::DateTime>; timestamps are read and written as
plain local-time strings, so it works whether or not that component is
loaded.

=head1 SEE ALSO

=over 3

=item * L<Dancer2::Plugin::ContentCache>

=item * L<Dancer2::Plugin::ContentCache::Driver>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: DBIx::Class storage driver for Dancer2::Plugin::ContentCache

