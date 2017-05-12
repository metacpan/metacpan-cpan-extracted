package Beagle::Model::Info;
use Any::Moose;
extends 'Beagle::Model::Entry';
use Beagle::Util;

sub path { 'info' }

has 'url' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'http://localhost',
);

has 'title' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'beagle',
);

has 'copyright' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'layout' => (
    isa     => 'BeagleLayout',
    is      => 'rw',
    default => 'blog',
);

has 'theme' => (
    isa     => 'BeagleTheme',
    is      => 'rw',
    default => 'orange',
);

has 'style' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
    trigger => sub {
        my $self = shift;
        my $value = shift;
        return unless $value && $value !~ m{/};
        $value = join '/', 'static', split_id($self->id), $value;
        $self->{style} = $value;
    },
);

has 'sites' => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] },
);

has 'language' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'name' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'beagle user',
    trigger => sub {
        my $self  = shift;
        my $value = shift;
        require Beagle::Backend;
        my $backend = Beagle::Backend->new( root => $self->root );
        if ( $backend->isa('Beagle::Backend::Git') ) {
            my $old_name = $backend->git->config( '--get', 'user.name' ) || '';
            chomp $old_name;
            if ( $old_name ne $value ) {
                $backend->git->config( '--replace-all', 'user.name', $value );
            }
        }
    },
);

has 'email' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
    trigger => sub {
        my $self  = shift;
        my $value = shift;
        require Beagle::Backend;
        my $backend = Beagle::Backend->new( root => $self->root );

        if ( $backend->isa('Beagle::Backend::Git') ) {
            my $old_email = $backend->git->config( '--get', 'user.email' )
              || '';
            chomp $old_email;
            if ( $old_email ne $value ) {
                $backend->git->config( '--replace-all', 'user.email', $value );
            }
        }
    },
);

has 'career' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'location' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'avatar' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'system/images/beagle.png',
    trigger => sub {
        my $self = shift;
        my $value = shift;
        return unless $value && $value !~ m{/};
        $value = join '/', 'static', split_id($self->id), $value;
        $self->{avatar} = $value;
    },
);

has 'page_limit' => (
    isa     => 'Str',
    is      => 'rw',
    default => sub {
        $ENV{BEAGLE_PAGE_LIMIT} || core_config->{page_limit} || 10;
    },
);

has 'feed_limit' => (
    isa     => 'Str',
    is      => 'rw',
    default => sub {
        $ENV{BEAGLE_FEED_LIMIT} || core_config->{feed_limit} || 20;
    },
);

has 'public_key' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
    trigger => sub {
        my $self = shift;
        my $value = shift;
        return unless $value && $value !~ m{/};
        $value = join '/', 'static', split_id($self->id), $value;
        $self->{public_key} = $value;
    },
);

sub parse_sites {
    my $self = shift;
    my $str  = shift;
    return [] unless $str;

    # , is valid in url, so let's force spaces after it.
    my @sites = split /\s*,\s+/, $str;

    my $value = [];
    for my $site (@sites) {
        my ( $name, $url ) = split /=/, $site, 2;
        if ( defined $name && $url ) {
            push @$value, { name => $name, url => $url };
        }
        else {
            warn "invalid site format: $site";
        }
    }
    return $value;
}

around 'serialize_meta' => sub {
    my $orig = shift;
    my $self = shift;
    my %opt  = ( @_, author => 0, draft => 0 );
    my $str = $self->_serialize_meta('id') . $self->$orig(%opt);

    return $str;
};

sub serialize_sites {
    my $self = shift;
    my $str = join ', ',
      map { join '=', $_->{name}, $_->{url} } @{ $self->sites };
    return $str;
}

sub summary {
    my $self = shift;
    return $self->title . ' ' . $self->url;
}

sub author {
    my $self = shift;
    return Email::Address->new( $self->name, $self->email )->format;
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

