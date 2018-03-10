package App::CSE::File::TextTroff;
$App::CSE::File::TextTroff::VERSION = '0.013';
use Moose;
extends qw/App::CSE::File/;

sub effective_object{
  my ($self) = @_;

  # This could have been wrongly detected as text/troff when
  # it is effectively application/x-perl
  if( ( $self->content() || '' ) =~ /^(?:.*?)perl(?:.*?)\n/ ){
    return $self->requalify('application/x-perl');
  }
  return $self;
}


__PACKAGE__->meta->make_immutable();
