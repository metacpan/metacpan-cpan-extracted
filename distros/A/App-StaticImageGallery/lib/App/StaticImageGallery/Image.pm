package App::StaticImageGallery::Image;
BEGIN {
  $App::StaticImageGallery::Image::VERSION = '0.002';
}

use File::Basename ();
use Imager;
use Carp;
use parent 'App::StaticImageGallery::Base::NeedDir';

sub init {
    my $self = shift;
    my %args = @_;

    if ( defined $args{original} ) {
        $self->{_original} = $args{original};
    }else{
        croak "Missing option 'original'";
    }

    return $self;
}

sub original { return shift->{_original}; }

sub Imager {
    my $self = shift;
    return $self->{_Imager} if defined $self->{_Imager};

    my $file = sprintf("%s/%s",$self->work_dir,$self->original);
    $self->{_Imager} = Imager->new( file => $file );

    unless ( $self->{_Imager} ){
        $self->msg_warning("SKIP: %s : %s",$file,$self->{_Imager}->errstr);
        return;
    }

    return $self->{_Imager};
}

sub metadata {
    my $self = shift;
    return $self->{_metadata} if defined $self->{_metadata};

    $self->{_metadata} = {};
    foreach my $md ( $self->Imager->tags() ){
        $self->{_metadata}->{ $md->[0] } = $md->[1];
    }

    return $self->{_metadata};
}

sub thumbnail {
    my $self = shift;
    return $self->{_thumbnail} if defined $self->{_thumbnail};

    my $thumb = $self->Imager
      ->scale( xpixels=> 125, ypixels=>125, type=>'max' )
      ->crop(width=>125, height=>125);

    $self->{_thumbnail} =   sprintf("%s.%s.jpg",
          File::Basename::basename( $self->original ),
          'thumbnail',
      );

    return $self->{_thumbnail} unless $self->must_create($self->{_thumbnail});


    $self->msg_verbose(2,"Write file %s",$self->{_thumbnail});
    unless ( $thumb->write( file => $self->data_dir. '/' .$self->{_thumbnail}, type=>'jpeg' ) ) {
        $self->msg_warning("SKIP thumbnail: %s : %s",$self->{_thumbnail},$thumb->errstr);
        return;
    }

    return $self->{_thumbnail};
}

sub small { return shift->_scale('small', xpixels => 256 ); }
sub medium { return shift->_scale('medium', xpixels => 512 ); }
sub large { return shift->_scale('large', xpixels => 1024 ); }

sub _scale{
    my ($self, $infix, @scale_options) = @_;

    my $image = $self->Imager->scale( @scale_options );
    my $filename = sprintf("%s.%s.jpg",
        File::Basename::basename( $self->original ),
        $infix,
    );
    return $filename unless $self->must_create($filename);

    $self->msg_verbose(2,"Write file %s",$filename);

    unless ( $image->write( file => $self->data_dir . '/' . $filename ) ) {
        $self->msg_warning("SKIP: %s : %s",$filename,$image->errstr);
        return;
    }
    return $filename;
}

sub must_create {
    my ($self,$filename) = @_;
    my $original = sprintf("%s/%s",$self->work_dir,$self->original);
    my $new = sprintf("%s/%s",$self->data_dir,$filename);

    my $mtime_original = (stat($original))[9];
    my $mtime_new = (stat($new))[9] || 0;

    if ( $mtime_new > $mtime_original ){
        $self->msg_verbose(6,"must_create:FALSE Original:%s:%d New:%s:%d",
          $original,
          $mtime_original,
          $new,
          $mtime_new,
        );
        return 0;
    }
    $self->msg_verbose(6,"must_create:TRUE Original:%s:%d New:%s:%d",
      $original,
      $mtime_original,
      $new,
      $mtime_new,
    );
    return 1;
}

1;
__END__

=head1 NAME

App::StaticImageGallery::Image - Handles a image

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 Imager

=head2 init

=head2 large

=head2 medium

=head2 metadata

=head2 original

=head2 small

=head2 thumbnail

=head2 must_create

=over 4

=item Arguments: $filename

=item Return value: Bool [0|1]

=back

Compare $filename with the original file. If the original file newer then
$filenamen in the data dir then return 1.

=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=head1 COPYRIGHT & LICENSE

=cut