package App::StaticImageGallery::Style::Source::Dispatcher;
BEGIN {
  $App::StaticImageGallery::Style::Source::Dispatcher::VERSION = '0.002';
}

use App::StaticImageGallery::Style::Source::FromPackage;
# use App::StaticImageGallery::Style::Source::FromDir;
sub new {
    my $class = shift;
    my $self  = {};
    # 
    # my %args = @_;
    # 
    # TODO: Write Dispatcher
    return App::StaticImageGallery::Style::Source::FromPackage->new(@_);
}

1;
__END__

=head1 NAME

App::StaticImageGallery::Style::Source::Dispatcher

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 new

=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=cut