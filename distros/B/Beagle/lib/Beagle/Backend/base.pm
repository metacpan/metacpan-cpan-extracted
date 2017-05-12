package Beagle::Backend::base;
use Any::Moose;
use Beagle::Util;

has 'root' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    trigger  => sub {
        my $self  = shift;
        my $value = shift;
        $self->encoded_root( encode( locale_fs => $value ) );
    },
);

has 'encoded_root' => (
    isa => 'Str',
    is  => 'rw',
);

sub type {
    my $self = shift;
    my $class = ref $self || $self;
    $class =~ /::(\w+)$/ or die "$class is invalid";
    return lc $1;
}

sub create {
    my $self   = shift;
    my $object = shift;
}

sub read {
    my $self = shift;
    my %args = @_;
    return unless -e $self->encoded_root;
    my $root             = $self->root;
    my $encoded_root     = $self->encoded_root;
    my $top_encoded_root = $encoded_root;

    if ( $args{path} ) {
        my $full_path =
          encode( locale_fs => catfile( $self->root, $args{path} ) );
        local $/;
        open my $fh, '<', $full_path or die $!;
        binmode $fh;
        return $args{path} => decode_utf8 <$fh>;
    }

    my $type = $args{type} || 'article';

    my %file;

    if ( $type eq 'attachment' ) {
        my $encoded_root = catdir( $encoded_root, 'attachments' );
        return unless -e $encoded_root;

        opendir my $dh, $encoded_root or die $!;

        while ( my $dir = readdir $dh ) {
            if ( $dir =~ /^\w{2}$/ ) {
                opendir my $dh2, catdir( $encoded_root, $dir )
                  or die $!;
                while ( my $left = readdir $dh2 ) {
                    if ( $left =~ /^\w{30}$/ ) {
                        opendir my $dh3, catdir( $encoded_root, $dir, $left )
                          or die $!;

                        $file{ $dir . $left } = [
                            map { decode( locale_fs => $_ ) }
                            grep { $_ ne '.' && $_ ne '..' } readdir $dh3
                        ];
                    }
                }
            }
        }
        return %file;
    }
    else {
        require Lingua::EN::Inflect;
        my $root = catdir( $encoded_root, Lingua::EN::Inflect::PL($type) );
        return unless -e $root;

        opendir my $dh, $root or die $!;

        while ( my $dir = readdir $dh ) {
            next unless $dir =~ /^\w{2}$/;
            opendir my $dh2, catdir( $root, $dir )
              or die $!;
            while ( my $left = readdir $dh2 ) {
                next unless $left =~ /^\w{30}$/;
                my $path = catfile( $root, $dir, $left );
                next unless -f $path;
                local $/;
                open my $fh, '<', $path or die $!;
                binmode $fh;
                $path =~ s!^\Q$top_encoded_root\E[/\\]?!!;
                $file{ $dir . $left } = {
                    path    => decode( locale_fs => $path ),
                    content => decode_utf8 <$fh>,
                };
            }
        }
    }
    return %file;
}

sub update {
    my $self   = shift;
    my $object = shift;
}

sub delete {
    my $self   = shift;
    my $object = shift;
}

sub updated {
    my $self = shift;
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

