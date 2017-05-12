package Beagle::Role::Body;

use Any::Moose 'Role';
use Beagle::Util;

has 'format' => (
    isa     => 'BeagleFormat',
    is      => 'rw',
    default => default_format(),
    lazy    => 1,
    trigger => sub {
        my $self  = shift;
        $self->_body_html( undef ) if defined $self->_body_html;
    },
);

has 'body' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
    trigger => sub {
        my $self  = shift;
        $self->_body_html( undef ) if defined $self->_body_html;
    },
);

has '_body_html' => (
    isa     => 'Maybe[Str]',
    is      => 'rw',
    default => undef,
    lazy    => 1,
);

sub body_html {
    my $self = shift;
    if ( $self->format eq 'plain' && $self->body !~ /\[BeagleAttachmentPath\]/ )
    {
        return '<pre class="entry body">' . encode_entities( $self->body ) . '</pre>';
    }
    else {
        unless ( defined $self->_body_html ) {
            $self->_body_html( $self->_parse_body( $self->body ) );
        }
        return $self->_body_html;
    }
}

sub _parse_image {
    my $self  = shift;
    my $value = shift;
    return '' unless $value;

    my ( $path, $title ) = split /\s*\|\s*/, $value;
    my $img = qq{<img src="$path" };
    if ($title) {
        $img .= qq< title="$title">;
    }
    $img .= '/>';
    return $img;
}

sub _parse_body {
    my $self  = shift;
    my $value = shift;
    return '' unless defined $value && $self->format;

    return '<pre class="entry body">' . encode_entities($value) . '</pre>'
      if $self->format eq 'plain';

    return $value if $self->format eq 'html';

    my $id =
      $self->can('id')
      ? join( '/', split_id( $self->id ) )
      : undef;
    my $path = '/static/';
    $path .= "$id/" if $id;

    $value =~ s!\[BeagleAttachmentPath\]!$path!gi;

    if ( $self->format eq 'wiki' ) {
        $value =~ s/\[\[Image:(.*?)\]\]/$self->_parse_image( $1 )/egi;
        return parse_wiki( $value,
            roots()->{ root_name( $self->root ) }{trust} );
    }
    elsif ( $self->format eq 'markdown' ) {
        return parse_markdown( $value,
            roots()->{ root_name( $self->root ) }{trust} );
    }
    elsif ( $self->format eq 'pod' ) {
        return parse_pod( $value,
            roots()->{ root_name( $self->root ) }{trust} );
    }
    else {
        warn 'invalid format: ' . $self->format;
        return $value;
    }
}

sub parse_body {
    my $self  = shift;
    my $value = shift;
    return $value unless defined $value;

    $value =~ s!\r\n!\n!g;
    $value =~ s!\s*$!\n!;    # make the end only one \n
    return $value;
}

no Any::Moose 'Role';
1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

