package    # hidden from pause
  App::StaticImageGallery::Base::Any;

use Carp;
use DateTime;
sub new {
    my $class = shift;
    my $self  = {};

    my %args = @_;

    if ( defined $args{ctx} and ref( $args{ctx} ) eq 'App::StaticImageGallery' ) {
        $self->{_ctx} = $args{ctx};
    } else {
        croak "Missing ctx or wrong type: " . ref $args{ctx};
    }

    bless $self, $class;

    if ( $self->can('init') ){
        $self->init(@_);
    };

    return $self;
}

sub ctx { return shift->{_ctx}; }

sub opt { return shift->ctx->opt; }

sub config { return shift->ctx->config; }

sub verbose { return shift->ctx->opt->get_verbose(); }

sub msg_verbose { return shift->ctx->msg_verbose(@_); }
sub msg { return shift->ctx->msg(@_); }
sub msg_warning { return shift->ctx->msg_warning(@_); }

1;
__END__

=head1 NAME

App::StaticImageGallery::Image - Handles a image

=head1 VERSION

version 0.002

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 config
=head2 ctx
=head2 msg
=head2 msg_verbose
=head2 msg_warning
=head2 new
=head2 opt
=head2 verbose


=head1 AUTHOR

See L<App::StaticImageGallery/AUTHOR> and L<App::StaticImageGallery/CONTRIBUTORS>.

=head1 COPYRIGHT & LICENSE

=cut