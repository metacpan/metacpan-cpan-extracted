package Beagle::Handle;
use Any::Moose;
use Lingua::EN::Inflect 'PL';
use Beagle::Util;
use Beagle::Backend;
has 'name' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { root_name( $_[0]->root ) },
);

has 'drafts' => (
    isa     => 'Bool',
    is      => 'ro',
    lazy    => 1,
    default => 1,
);

has 'trusted' => (
    isa     => 'Bool',
    is      => 'ro',
    lazy    => 1,
    default => 0,
);

has 'backend' => (
    isa     => 'Beagle::Backend::base',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $root = current_root();
        return Beagle::Backend->new( root => $root, type => root_type($root) );
    },
    handles => [qw/type root/],
);

has 'cache' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $name = $self->name;
        my $file =
          encode( locale_fs =>
              catfile( cache_root(), $name . ( $self->drafts ? '.drafts' : '' ) )
          );
        my $parent = parent_dir($file);
        make_path( $parent ) unless -e $parent;
        return $file;
    },
);

has 'info' => (
    isa     => 'Beagle::Model::Info',
    is      => 'rw',
    handles => ['sites'],
);

my $type_info = entry_type_info();
for my $type ( keys %$type_info ) {
    my $pl    = $type_info->{$type}{plural};
    my $class = $type_info->{$type}{class};
    has $pl => (
        isa     => "ArrayRef[$class]",
        is      => 'rw',
        default => sub { [] },
        $type ne 'comment'
        ? (
            trigger => sub {
                my $self = shift;
                $self->_init_entries;
            }
          )
        : (),
    );
}

has 'entries' => (
    isa     => 'ArrayRef[Beagle::Model::Entry]',
    is      => 'rw',
    default => sub { [] },
);

has 'map' => (
    isa     => 'HashRef[Beagle::Model::Entry]',
    is      => 'rw',
    default => sub { {} },
    lazy    => 1,
);

has 'attachments_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
    lazy    => 1,
);

has 'comments_map' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
    lazy    => 1,
);

has 'updated' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    if ( $args->{root} || $args->{name} ) {
        my $root = $args->{root} || name_root( $args->{name} );
        $self->backend(
            Beagle::Backend->new(
                root => $root,
                type => $args->{type} || root_type($root),
            )
        );
        $self->name( root_name($root) );
    }

    my $cache       = $self->cache;
    my $need_update = 1;

    if ( enabled_cache() && -e $cache ) {
        require Storable;
        %$self = %{ Storable::retrieve($cache) };
        $self->root( $args->{root} )
          if $args->{root} && ( $self->root || '' ) ne $args->{root};

        if ( $self->updated eq $self->backend->updated ) {
            undef $need_update;
        }
    }

    if ($need_update) {

        $self->map( {} );
        $self->init_info;
        $self->init_entries;

        $self->init_attachments;

        my $updated = $self->backend->updated;
        $self->updated($updated) if $updated;
        $self->update_cache;
        $self->update_relation;
    }

    return $self;
}

sub update_cache {
    my $self = shift;
    return unless enabled_cache();

    unless ( -e $self->cache ) {
        my $parent = parent_dir( $self->cache );
        make_path($parent) or die $! unless -e $parent;
    }

    require Storable;
    Storable::nstore( $self, $self->cache );
}

sub update_relation {
    my $self = shift;
    my $map  = relation();
    for my $key ( keys %$map ) {
        delete $map->{$key}
          if $map->{$key} eq $self->name;
    }
    for my $entry ( @{ $self->comments }, @{ $self->entries } ) {
        $map->{ $entry->id } = $self->name if $entry->can('id');
    }
    set_relation($map);
}

sub init_info {
    my $self    = shift;
    my $backend = $self->backend;
    ( undef, my $string ) = $backend->read( path => 'info' );
    my $info = Beagle::Model::Info->new_from_string(
        $string,
        root => $self->root,
        path => 'info'
    );
    $self->info($info);
    $self->map->{ $info->id } = $info;
}

sub init_entry_type {
    my $self    = shift;
    my $type    = shift;
    my $attr = $type_info->{$type}{plural};
    my $backend = $self->backend;
    {
        my %all = $backend->read( type => $type );
        my @entries;
        for my $id ( keys %all ) {
            my $class = $type_info->{$type}{class};

            my $entry = $class->new_from_string(
                $all{$id}{content},
                id       => $id,
                path     => $all{$id}{path},
                root     => $self->root,
                timezone => $self->info->timezone || 'UTC',
            );
            next if $entry->draft && !$self->drafts;

            $entry->author( current_user() ) unless $entry->author;

            push @entries, $entry;
            $self->map->{ $entry->id } = $entry;
        }

        @entries =
          sort { $b->created <=> $a->created } @entries;
        $self->$attr( \@entries );
    }
}

sub init_attachments {
    my $self            = shift;
    my $backend         = $self->backend;
    my %attachments_map = ();
    my %all             = $backend->read( type => 'attachment' );
    for my $id ( keys %all ) {
        $attachments_map{$id} = {
            map {
                $_ => Beagle::Model::Attachment->new(
                    name      => $_,
                    parent_id => $id,
                    root      => $self->root,
                  )
              } @{ $all{$id} }
        };
    }
    $self->attachments_map( \%attachments_map );
}

sub init_comments {
    my $self = shift;
    $self->init_entry_type('comment');
    my %comments_map;
    for my $comment ( @{ $self->comments } ) {
        $comments_map{ $comment->parent_id }{ $comment->id } = $comment;
    }
    $self->comments_map( \%comments_map );
}

sub total_size {
    my $self = shift;
    require Devel::Size;
    return Devel::Size::total_size($self);
}

sub list {
    my $self = shift;

    my %ret;

    return map { $_ => $self->$_ } qw/info total_size sites
      map attachments_map comments_map updated
      entry_types
      /, map { $type_info->{$_}{plural} } keys %$type_info;
}

sub update_info {
    my $self = shift;
    my $info = shift;
    my %args = @_;
    my $message = 'update info';
    $message .= "\n\n" . $args{message} if defined $args{message};
    $message .= "\n\n" . $info->commit_message if $info->commit_message;
    return unless $self->backend->update( $info, @_, message => $message );
    $self->info($info);
    return 1;
}

sub update {
    my $self    = shift;
    my $updated = $self->backend->updated;
    my $map     = $self->map;

    if ( $self->updated != $updated ) {
        $self->map( {} );
        $self->init_info;
        $self->init_entries;

        $self->init_attachments;
        $self->updated($updated);

        $self->update_cache;
        $self->update_relation;
    }
}

sub create_entry {
    my $self   = shift;
    my $entry  = shift;
    my $type   = $entry->type;
    my $method = "create_$type";
    if ( $self->can($method) && $method ne 'create_entry' ) {
        return $self->$method( $entry, @_ );
    }
    else {
        my %args = @_;
        my $message =
            'create '
          . $entry->type . ' '
          . $entry->id . ': '
          . $entry->summary(20);
        $message .= "\n\n" . $args{message} if defined $args{message};
        $message .= "\n\n" . $entry->commit_message if $entry->commit_message;

        return unless $self->backend->create( $entry, @_, message => $message );
        $self->map->{ $entry->id } = $entry;
        if ( $type eq 'comment' ) {
            $self->comments( [ $entry, @{ $self->comments } ] );
            $self->comments_map->{ $entry->parent_id }{ $entry->id } = $entry;
        }
        else {
            my $attr = PL($type);
            $self->$attr( [ $entry, @{ $self->$attr || [] } ] );
        }
    }
    return 1;
}

sub update_entry {
    my $self   = shift;
    my $entry  = shift;
    my $type   = $entry->type;
    my $method = "update_$type";
    if ( $self->can($method) ) {
        return $self->$method( $entry, @_ );
    }
    else {
        my %args = @_;
        my $message =
            'update '
          . $entry->type . ' '
          . $entry->id . ': '
          . $entry->summary(20);
        $message .= "\n\n" . $args{message} if defined $args{message};
        $message .= "\n\n" . $entry->commit_message if $entry->commit_message;

        return unless $self->backend->update( $entry, @_, message => $message );
        if ( $type eq 'comment' ) {
            $self->comments(
                [
                    map { $_->id eq $entry->id ? $entry : $_ }
                      @{ $self->comments }
                ]
            );
            $self->comments_map->{ $entry->parent_id }{ $entry->id } = $entry;
        }
        else {
            my $attr = PL($type);
            $self->$attr(
                [
                    map { $_->id eq $entry->id ? $entry : $_ } @{ $self->$attr || [] }
                ]
            );
        }
    }
    return 1;
}

sub delete_entry {
    my $self   = shift;
    my $entry  = shift;
    my $type   = $entry->type;
    my $method = "delete_$type";
    if ( $self->can($method) ) {
        return $self->$method( $entry, @_ );
    }
    else {
        my %args = @_;
        my $message =
            'delete '
          . $entry->type . ' '
          . $entry->id . ': '
          . $entry->summary(20);
        $message .= "\n\n" . $args{message} if defined $args{message};
        $message .= "\n\n" . $entry->commit_message if $entry->commit_message;
        return unless $self->backend->delete( $entry, @_, message => $message );
        delete $self->map->{ $entry->id };
        if ( my $att = $self->attachments_map->{ $entry->id } ) {
            $self->delete_attachment($_)
              or warn "failed to delete attachment " . $_->id
              for values %$att;
        }
        if ( my $comment = $self->comments_map->{ $entry->id } ) {
            $self->delete_entry($_)
              or warn "failed to delete comment " . $_->id
              for values %$comment;
        }

        if ( $entry->type eq 'comment' ) {
            delete $self->comments_map->{ $entry->parent_id }{ $entry->id };
        }
    }
    return 1;
}

sub create_attachment {
    my $self       = shift;
    my $attachment = shift;
    my %args = @_;
    my $message = 'create attachment ' . $attachment->name;
    $message .= "\n\n" . $args{message} if defined $args{message};
    $message .= "\n\n" . $attachment->commit_message
      if $attachment->commit_message;
    return unless $self->backend->create( $attachment, @_, message => $message );
    $self->attachments_map->{ $attachment->parent_id }{ $attachment->name } =
      $attachment;
    return 1;
}

sub delete_attachment {
    my $self       = shift;
    my $attachment = shift;
    my %args = @_;
    my $message = 'delete attachment ' . $attachment->name;
    $message .= "\n\n" . $args{message} if defined $args{message};
    $message .= "\n\n" . $attachment->commit_message
      if $attachment->commit_message;
    return unless $self->backend->delete( $attachment, @_ );
    delete $self->attachments_map->{ $attachment->parent_id }
      { $attachment->name };
    return 1;
}

sub _init_entries {
    my $self = shift;
    my @entries =
      sort { $b->created <=> $a->created }
      map  { @{ $self->$_ || [] } }
      grep { $_ ne 'comments' }
      map { $type_info->{$_}{plural} } keys %{$type_info};

    $self->entries( \@entries );
}

sub init_entries {
    my $self = shift;
    for my $type ( keys %{$type_info} ) {
        my $pl = $type_info->{$type}{plural};
        my $method = "init_$pl";
        if ( $self->can($method) ) {
            $self->$method;
        }
        else {
            $self->init_entry_type($type);
        }
    }
}

sub DEMOLISH {
    my $self = shift;
    $self->update_relation;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

