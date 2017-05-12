package App::StaticImageGallery::Dir;
BEGIN {
  $App::StaticImageGallery::Dir::VERSION = '0.002';
}

use Path::Class    ();
use File::Basename ();
use App::StaticImageGallery::Image;
use App::StaticImageGallery::Style::Source::Dispatcher;
use parent 'App::StaticImageGallery::Base::Any';

sub init {
    my $self = shift;
    my %args = @_;
    $self->msg_verbose(10,"App::StaticImageGallery::Dir->init: %s",$args{work_dir});
    foreach my $key (qw/tt_dir tt_class link_to_parent_dir work_dir/){
        if ( defined $args{$key} ) {
            $self->{'_' . $key} = $args{$key};
        }
    }
    $self->{init_args} = \%args;

    return $self;
}


# 
# Images
########################################################################################

sub _build__images {
    my $self   = shift;
    my @images = ();
    while (my $file = $self->work_dir->next) {
        if ( $file->is_dir and ( $self->opt->get_recursive() > 0 ) ){
            $self->msg_verbose(10,"Check dir %s",File::Basename::basename($file->stringify));
            unless (
                File::Basename::basename($file->stringify) =~ /^\./ 
                or $self->work_dir->stringify eq $file->stringify
            ){
                $self->msg_verbose(1,"Go into %s",$file);
                $self->add_dir(File::Basename::basename($file->stringify));

                my $args = $self->{init_args};
                $args->{work_dir} = $file;
                $args->{link_to_parent_dir} = 1;
                my $dir = App::StaticImageGallery::Dir->new(%$args);
                $dir->write_index;
            }
        }else{
            if ( $file->stringify =~ /.*(jpg|png|jpeg|tif)$/i ){
                $self->msg_verbose(10,"Push Image %s - %s",$self->work_dir,$file->basename);
                push @images, App::StaticImageGallery::Image->new(
                    dir      => $self,
                    original => $file->basename,
                    ctx      => $self->ctx,
                );
            }

        }
    }
    return \@images;
}

sub all_images {
    my $self = shift;
    $self->{_images} = $self->_build__images() unless ( defined $self->{_images} );
    return wantarray ? @{ $self->{_images} } : $self->{_images};
};
sub images { return shift->all_images };


sub count_images{
    my $self = shift;
    return scalar @{ $self->all_images }
};
sub get_image {
    my $self = shift;
    my $indx = shift;
    $self->{_images} = $self->_build__images() unless ( defined $self->{_images} );
    return $self->{_images}[$indx];
};

# 
# Directories 
########################################################################################
sub _build__dirs { return [] };
sub all_dirs {
    my $self = shift;
    $self->{_dirs} = $self->_build__dirs() unless ( defined $self->{_dirs} );
    return wantarray ? @{ $self->{_dirs} } : $self->{_dirs};
}
sub dirs { return shift->all_dirs };
sub count_dirs{
    my $self = shift;
    return scalar @{ $self->all_dirs }
};
sub get_dir {
    my $self = shift;
    my $indx = shift;
    $self->{_dirs} = $self->_build__dirs() unless ( defined $self->{_dirs} );
    return $self->{_dirs}[$indx];
};
sub add_dir {
    my $self = shift;
    my $dir = shift;
    $self->{_dirs} = $self->_build__dirs() unless ( defined $self->{_dirs} );
    push @{$self->{_dirs}}, $dir;
    return wantarray ? @{ $self->{_dirs} } : $self->{_dirs};
};

sub data_dir {
    my $self = shift;

    return $self->{_data_dir} if ( defined $self->{_data_dir} );

    $self->{_data_dir} = join '/',$self->work_dir, $self->config->{data_dir_name};
    mkdir $self->{_data_dir} unless -d $self->{_data_dir};

    return Path::Class::dir($self->{_data_dir});
}

sub work_dir { return shift->{_work_dir}; }

sub clean_work_dir {
    my $self = shift;

    my $index_filename = $self->work_dir . '/index.html';
    if ( -f $index_filename ){
        $self->msg_verbose(1,"Remove " . $index_filename );
        unlink($index_filename);
    }else{
        $self->msg("Can't find index file: " . $index_filename );
    }

    my $data_dir = join '/',$self->work_dir, $self->config->{data_dir_name};
    if ( -d $data_dir ){
        $self->msg_verbose(1,"Remove dir " . $data_dir );
        File::Path::rmtree( $data_dir );
    }else{
        $self->msg("Can't find data dir:   " . $data_dir );
    }

    return if ( $self->opt->get_recursive() < 1 ) ;

    while (my $file = $self->work_dir->next) {
        if ( $file->is_dir ){
            unless (
                File::Basename::basename($file->stringify) =~ /^\./ 
                or $self->work_dir->stringify eq $file->stringify
            ){
                $self->msg_verbose(1,"Go into %s",$file);

                my $args = $self->{init_args};
                $args->{work_dir} = $file;
                $args->{link_to_parent_dir} = 1;
                my $dir = App::StaticImageGallery::Dir->new(%$args);
                $dir->clean_work_dir;
            }
        }
    }

    return;
}
#
# TT
########################################################################################

sub style {
    my $self = shift;
    return $self->{_style} if ( defined $self->{_style} );

    $self->{_style} = App::StaticImageGallery::Style::Source::Dispatcher->new(
        dir => $self,
        ctx => $self->ctx,
    );
    $self->msg_verbose(5,"Style source is: %s",ref( $self->{_style} ));

    return $self->{_style}
}

sub link_to_parent_dir { return ( shift->{_link_to_parent_dir} ) ? 1 : 0; }

sub write_index {
    my ($self) = @_;

    foreach my $i (0..($self->count_images-1)){
        my $next     = ( ($i+1) < $self->count_images  ) ? $self->get_image($i+1) : undef;
        my $previous = ( ($i-1) >= 0 ) ? $self->get_image($i-1) : undef;
        my $current  = $self->get_image($i);
        foreach my $size (qw/small medium large/){
            $self->style->write_image_page($size,$previous,$current,$next);
        }
    }

    $self->style->write_index_page([$self->images],[$self->dirs],{
        link_to_parent_dir => $self->link_to_parent_dir()
    });
    $self->style->write_style_files();

    return;
}


1;
__END__

=head1 NAME

App::StaticImageGallery::Dir - Handles a directory

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 DIRECTORY NAMES

    Pictures                    -> work_dir
    |-- .StaticImageGallery     -> data_dir
    |   |-- 101_7426.JPG
    |   |-- 101_7428.JPG
    |   |-- 101_7429.JPG
    |   |-- 101_7430.JPG
    |   `-- style.css
    |-- 101_7426.JPG
    |-- 101_7426.JPG.html
    |-- 101_7428.JPG
    |-- 101_7428.JPG.html
    |-- 101_7429.JPG
    |-- 101_7429.JPG.html
    |-- 101_7430.JPG
    |-- 101_7430.JPG.html
    `-- index.html

    1 directory, 14 files

=head1 METHODS

=head2 add_dir

=head2 all_dirs

=head2 all_images

=head2 count_dirs

=head2 count_images

=head2 dirs

=head2 get_dir

=head2 get_image

=head2 images

=head2 init

=head2 link_to_parent_dir

=head2 style

=head2 write_index

=head2 data_dir

=head2 work_dir

=head2 clean_work_dir

Remove all files created by StaticImageGallery

=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=head1 COPYRIGHT & LICENSE

=cut