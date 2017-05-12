package    # hidden from pause
  App::StaticImageGallery::Base::NeedDir;

use Carp;
use DateTime;
use parent 'App::StaticImageGallery::Base::Any';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my %args = @_;

    if ( defined $args{dir} and ref( $args{dir} ) eq 'App::StaticImageGallery::Dir' ) {
        $self->{_dir} = $args{dir};
    } else {
        croak "Missing dir or wrong type: " . ref $args{work_dir};
    }

    return $self;
}

sub dir { return shift->{_dir}; }
sub work_dir { return shift->{_dir}->work_dir; }
sub data_dir { return shift->{_dir}->data_dir; }

1;
__END__

=head1 NAME

App::StaticImageGallery::Base::NeedDir

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 data_dir

=head2 dir

=head2 new

=head2 work_dir

=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=cut