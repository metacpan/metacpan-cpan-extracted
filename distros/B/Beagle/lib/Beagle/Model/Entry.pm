package Beagle::Model::Entry;
use Any::Moose;
use Data::UUID;
use Beagle::Util;
use Storable 'dclone';

has 'tags' => (
    isa     => 'ArrayRef[Str]',
    is      => 'rw',
    default => sub { [] },
);

has 'root' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { current_root() },
);

has 'update' => (
    isa => 'Str',
    is  => 'rw',
);

has 'original_path' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->path;
    }
);

with 'Beagle::Role::Body', 'Beagle::Role::File', 'Beagle::Role::Date';

has 'id' => (
    isa     => 'Str',
    is      => 'rw',
    builder => '_gen_id',
    lazy    => 1,
);

has 'draft' => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
    lazy    => 1,
    coerce  => 1,
);

use Email::Address;

has 'author' => (
    isa => 'Str',
    is  => 'rw',
);

has 'commit_message' => (
    isa     => 'Maybe[Str]',
    is      => 'rw',
    default => '',
    lazy    => 1,
);

sub new_from_string {
    my $class  = shift;
    my $input = shift;
    die "missing string" unless defined $input;
    my %args = @_;
    my $self;
    if ( ref $class ) {
        $self = dclone $class;
        for my $key ( keys %args ) {
            if ( $self->can( $key ) ) {
                eval { $self->$key( $args{$key} ) };
                if ($@) {
                    warn "failed to set $key to $args{$key}: $@";
                }
            }
            else {
                warn "unknown key: $key";
            }
        }
    }
    else {
        $self = $class->new( %args);
    }

    my ( $message, $string ) = $class->split_message($input);

    my @wiki = split /\r?\n/, $string;
    while ( my $line = shift @wiki ) {
        chomp $line;
        last unless $line =~ /^(\w+):\s*(.*?)\s*$/;
        my $key   = lc $1;
        my $value = $2;
        if ( $key eq 'created' || $key eq 'updated' ) {
            if ( $value =~ /^(\d{10})/ ) {
                $value = $1;
            }
            else {
                warn "couldn't find epoch.";
            }
        }

        if ( $self->can($key) ) {
            eval { $self->$key( $self->parse_field( $key, $value ) ) };
            if ($@) {
                warn "failed to set $key to $args{$key}: $@";
            }
        }
        else {
            warn "unknown key: $key";
        }
    }
    $self->body( join "\n", @wiki );

    $self->commit_message( $message ) if $message;

    for my $type (qw/id created/) {
        if ( !$self->$type ) {
            warn "no mandatory $type defined, skipping";
        }
    }

    return $self;
}

sub serialize_meta {
    my $self = shift;
    my %args = (
        id      => 0,
        author  => 1,
        created => 1,
        updated => 1,
        format  => 1,
        draft   => 1,
        tags    => 1,
        path    => 0,
        update  => 1,
        type    => 0,
        @_
    );
    my $str = '';

    for my $type (qw/type id format author tags draft path/) {
        $str .= $self->_serialize_meta($type) if $args{$type};
    }

    if ( $args{update} && $self->update ) {
        $str .= $self->_serialize_meta('update');
    }

    my $extra = $self->extra_meta_fields;
    for my $field ( @$extra ) {
        next if exists $args{$field} && !$args{$field};
        $str .= $self->_serialize_meta($field);
    }

    if ( $args{created} ) {
        $str .=
            'created: '
          . $self->created . ' ('
          . $self->created_string . ')' . "\n";
    }

    if ( $args{updated} ) {
        $str .=
            'updated: '
          . $self->updated . ' ('
          . $self->updated_string . ')' . "\n";
    }

    return $str;
}

sub _serialize_meta {
    my $self      = shift;
    my $type      = shift;
    my $serialize = $self->can("serialize_$type");
    my $value     = $serialize ? $self->$serialize : $self->$type;

    if ( defined $value && length $value ) {
        return "$type: " . $value . "\n";
    }
    else {
        return "$type:\n";
    }
}

sub serialize_body {
    my $self = shift;
    my $str  = '';
    $str .= $self->body if defined $self->body;
    $str .= "\n" unless $str =~ /\n$/;
    return $str;
}

sub serialize {
    my $self = shift;
    my $str  = $self->serialize_meta(@_);
    $str .= "\n" if length $str;
    $str .= $self->serialize_body(@_);
    return $str;
}

sub _gen_id {
    my $self = shift;
    my $ug   = Data::UUID->new;
    my $id   = $ug->create_hex;
    $id =~ s!^0x!!;
    return lc $id;
}

sub path {
    my $self = shift;

    require Lingua::EN::Inflect;
    return catfile( Lingua::EN::Inflect::PL( $self->type ),
        split_id( $self->id ) );
}

sub type {
    my $self = shift;
    my $class = ref $self || $self;
    $class =~ /::(\w+)$/ or die "$class is invalid";
    return lc $1;
}

sub summary {
    my $self = shift;
    $self->_summary( $self->body, @_ );
}

sub _summary {
    my $self   = shift;
    my $body   = shift;
    my $length = shift;
    return '' unless $body;

    $body =~ s/^\s+//;
    $body =~ s/\s+$//;
    $body =~ s/\s+/ /g;

    if ($length) {
        return length $body > $length
          ? substr( $body, 0, $length - 3 ) . "..."
          : $body;
    }
    else {
        return $body;
    }

}

sub parse_field {

    my $self  = shift;
    my $field = shift;
    return '' unless $field && $self->can($field);

    die "no value fed for $field" unless @_;
    my $value = shift;
    my $parse = "parse_$field";
    if ( $self->can($parse) ) {
        return $self->$parse($value);
    }
    else {
        return $value;
    }
}

sub serialize_field {
    my $self  = shift;
    my $field = shift;
    return '' unless $field && $self->can($field);

    my $serialize = "serialize_$field";
    my $value;
    if ( $self->can($serialize) ) {
        $value = $self->$serialize;
    }
    else {
        $value = $self->$field;
    }

    return defined $value ? $value : '';
}

sub parse_tags {
    my $self = shift;
    my $str  = shift;
    return to_array($str);
}

sub serialize_tags {
    my $self = shift;
    return from_array( $self->tags );
}

sub extra_meta_fields {
    my $self = shift;
    return [ sort $self->meta->get_attribute_list ];
}

sub extra_meta_fields_in_web_view {
    my $self = shift;
    return [ grep { $_ ne 'title' } @{$self->extra_meta_fields} ];
}

sub split_message {
    my $self    = shift;
    my $input   = shift;
    my @str     = split /\r?\n/, $input;
    my $message = '';
    while (@str) {
        my $line = $str[0];
        if ( $line =~ s/^# ?// ) {
            $message .= $line . newline;
            shift @str;
        }
        else {
            last;
        }
    }
    return ( $message, join newline, @str );
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

