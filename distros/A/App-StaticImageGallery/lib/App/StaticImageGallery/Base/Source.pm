package     # hidden from pause
  App::StaticImageGallery::Base::Source;

use DateTime;
use Template;
use File::Basename ();
use parent 'App::StaticImageGallery::Base::NeedDir';

sub _build_tt {
    my $self    = shift;
    my $tt_args = shift;

    $self->{_TT} = Template->new({
        # INCLUDE_PATH => '',    # or list ref
        INTERPOLATE => 1,           # expand "$var" in plain text
        POST_CHOMP  => 1,           # cleanup whitespace
        # PRE_PROCESS  => 'header', # prefix each template
        EVAL_PERL   => 0,           # evaluate Perl code blocks
        %$tt_args,
    });
}

sub TT { return shift->{_TT} };

sub write_style_files { die "write_style_files must be implemented in " . ref(shift) }
sub template_config { die "template_config must be implemented in " . ref(shift) }
sub image_page_template_name { die "image_page_template_name must be implemented in " . ref(shift) }
sub index_page_template_name { die "index_page_template_name must be implemented in " . ref(shift) }

sub stash {
    my ( $self, $stash ) = @_;

    $stash->{now} = DateTime->now()
      unless ( defined $stash->{now} );

    $stash->{version} = $App::StaticImageGallery::VERSION
      unless ( defined $stash->{version} );

    $stash->{work_dir} = File::Basename::basename($self->work_dir)
      unless ( defined $stash->{work_dir} );

    $stash->{sig} = $self
      unless ( defined $stash->{sig} );


    return $stash;
};

sub write_image_page {
    my ( $self,$size,$previous,$current,$next ) = @_;

    my $image_filename = $self->data_dir . '/' . $current->original . '.' . $size . '.html';
    $self->msg_verbose(3,"Write image html: %s",$image_filename);
    # TODO
    # if ( $self->tt_class->template_config('write_image_html') ){
        unless ($self->TT->process( $self->image_page_template_name(), $self->stash({
            previous => $previous,
            current  => $current,
            next     => $next,
            size     => $size,
        }), $image_filename )){
            $self->msg("Can't write image html for image %s.\n\tTT-error: %s",
              $image_filename,$self->TT->error());
        }
    # }
}

sub write_index_page {
    my ( $self,$images,$dirs,$stash ) = @_;
    $stash ||= {};

    my $index_filename = $self->work_dir . '/index.html';
    $self->msg_verbose(3,"Write index.html: %s",$index_filename);

    unless($self->TT->process( $self->index_page_template_name(),$self->stash({
        images => $images,
        dirs   => $dirs,
        %$stash,
    }), $index_filename )){
        $self->msg("Can't write index.html: %s.\n\tTT-error: %s",
          $index_filename,$self->TT->error());
    }
}

1;
__END__

=head1 NAME

App::StaticImageGallery::Base::Source

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 TT

=head2 image_page_template_name

=head2 index_page_template_name

=head2 stash

=head2 template_config

=head2 write_image_page

=head2 write_index_page

=head2 write_style_files

=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=cut