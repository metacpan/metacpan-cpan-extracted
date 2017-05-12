package App::StaticImageGallery::Style::Source::FromPackage;
BEGIN {
  $App::StaticImageGallery::Style::Source::FromPackage::VERSION = '0.002';
}
use MIME::Base64;
use Class::MOP     ();
use Template::Provider::FromDATA;
use parent 'App::StaticImageGallery::Base::Source';

sub init {
    my $self = shift;
    my %args = @_;

    # if ( defined $args{style_name} ) {
        $self->{_style_name} = $self->opt->get_style();
        $self->{_style_class} = 'App::StaticImageGallery::Style::' . $self->{_style_name};
        Class::MOP::load_class( $self->{_style_class} );
        $self->{_TT} = $self->_build_tt({
            LOAD_TEMPLATES => [
                Template::Provider::FromDATA->new( { CLASSES => $self->{_style_class} } ),
            ]
        });
    # }

    $self->{init_args} = \%args;

    return $self;
}

sub style_class { return shift->{_style_class}; }

# Default config
sub template_config {
    my $self = shift;
    my $key  = shift;
    my $config = { write_image_html => 1 };
    if ( $self->style_class->can('_build_config') ){
        $config = $self->style_class->_build_config();
    }
    return $config->{$key};
}

sub write_style_files {
    my ($self ) = @_;
    if ( $self->style_class->can('files') ){
        my @files = $self->style_class->files();
        foreach my $file ( @files ){
            my $filename = join '/',$self->data_dir,$file->{filename};
            $self->msg_verbose(2,"Write file %s",$filename);
            open(my $fh,'>', $filename) or die "Can't write $filename: $!\n";
            CORE::binmode($fh);
            if ( defined $file->{base64} ){
                print $fh MIME::Base64::decode_base64($file->{base64});
            }elsif ( defined $file->{content}){
                print $fh $file->{content};
            }
            close $fh;
        }
    }
}

sub image_page_template_name { return 'image'; }
sub index_page_template_name { return 'index'; }

1;
__END__

=head1 NAME

App::StaticImageGallery::Style::Source::FromPackage

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 image_page_template_name

=head2 index_page_template_name

=head2 init

=head2 style_class

=head2 template_config

=head2 write_style_files

=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=cut