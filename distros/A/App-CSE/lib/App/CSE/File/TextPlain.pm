package App::CSE::File::TextPlain;
$App::CSE::File::TextPlain::VERSION = '0.013';
use Moose;
extends qw/App::CSE::File/;

sub effective_object{
  my ($self) = @_;
  if( $self->file_path() =~ /\.pod$/ ){
    return $self->requalify('application/x-perl');
  }  elsif( $self->file_path() =~ /\.ini$/ ){
    return $self->requalify('application/x-wine-extension-ini');
  }  elsif( $self->file_path() =~ /\.rbw$/ ){
      return $self->requalify('application/x-ruby');
  } elsif( $self->file_path() =~ /\.tt$/ &&
           $self->content() &&
           $self->content() =~ /\[%.+%\]/ ){
    return $self->requalify('application/x-templatetoolkit');
  }
  return $self;
}

__PACKAGE__->meta->make_immutable();
