package App::CSE::File;
$App::CSE::File::VERSION = '0.016';
use Moose;

use App::CSE;
use Class::Load;
use Encode;
use File::Basename;
use File::Slurp;
use File::stat qw//;
use DateTime;
use String::CamelCase;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

has 'cse' => ( is => 'ro' , isa => 'App::CSE' , required => 1 );

has 'mime_type' => ( is => 'ro', isa => 'Str', required => 1);
has 'file_path' => ( is => 'ro', isa => 'Str', required => 1);
has 'dir' => ( is => 'ro' , isa => 'Str' , required => 1, lazy_build => 1);

has 'encoding' => ( is => 'ro' , isa => 'Str', lazy_build => 1 );
has 'content' => ( is => 'ro' , isa => 'Maybe[Str]', required => 1, lazy_build => 1 );
has 'raw_content' => ( is => 'ro' , isa => 'Maybe[Str]', required => 1 , lazy_build => 1);
has 'decl' => ( is => 'ro' , isa => 'ArrayRef[Str]' , lazy_build => 1);
has 'call' => ( is => 'ro' , isa => 'ArrayRef[Str]' , lazy_build => 1);

has 'stat' => ( is => 'ro' , isa => 'File::stat' , lazy_build => 1 );
has 'mtime' => ( is => 'ro' , isa => 'DateTime' , lazy_build => 1);

sub _build_decl{
  return [];
}

sub _build_call{
  return [];
}

sub _build_dir{
  my ($self) = @_;
  return File::Basename::dirname($self->file_path());
}

sub _build_stat{
  my ($self) = @_;
  return File::stat::stat($self->file_path());
}

sub _build_mtime{
  my ($self) = @_;
  return DateTime->from_epoch( epoch => $self->stat->mtime() );
}


sub _build_encoding{
  my ($self) = @_;
  ## This is the default. Override that in specific file types
  return 'UTF-8';
}

sub _build_raw_content{
  my ($self) = @_;
  if( $self->stat()->size() > $self->cse()->max_size() ){
    return undef;
  }
  return scalar( File::Slurp::read_file($self->file_path(), binmode => ':raw') );
}

sub _build_content{
  my ($self) = @_;
  my $raw_content = $self->raw_content();
  unless( defined($raw_content) ){ return undef; }

  my $decoded = eval{ Encode::decode($self->encoding(), $raw_content, Encode::FB_CROAK ); };
  unless( $decoded ){
    $LOGGER->debug("File ".$self->file_path()." failed to be decoded as ".$self->encoding().": ".$@);
    return;
  }
  return $decoded;
}

sub effective_object{
  my ($self) = @_;
  return $self;
}

=head2 requalify

Requalifies this object into the given mimetype.

=cut

sub requalify{
  my ($self, $mimetype) = @_;

  my $class = __PACKAGE__->class_for_mime($mimetype, $self->file_path());
  unless( $class ){
    confess("Cannot requalify in $mimetype. No class found");
  }

  return $class->new({ cse => $self->cse(),
                       file_path => $self->file_path(),
                       mime_type => $mimetype,
                       ( $self->has_dir() ? ( dir => $self->dir() ) : () ),
                       ( $self->has_content() ? ( content => $self->content() ) : () )
                     });
}

=head2 class_for_mime

Returns the File subclass that goes well with the given mimetype.
This is a Class method.

You can also give a file name to make the diagnostic easier in case no
class is found.

Usage:

  my $class = App::CSE::File->class_for_mime('application/x-perl');
  my $class = App::CSE::File->class_for_mime('application/x-perl' , 'the/file/name.something');

=cut

sub class_for_mime{
  my ($class, $mime_type , $file_name) = @_;

  $file_name ||= 'unknown_file_name';

  my $half_camel = $mime_type; $half_camel =~ s/\W/_/g;
  my $file_class_name = 'App::CSE::File::'.String::CamelCase::camelize($half_camel);
  # Protect against unsecure class name
  ( $file_class_name ) = ( $file_class_name =~ /^([\w:]+)$/ );
  my $file_class = eval{ Class::Load::load_class($file_class_name); };
  unless( $file_class ){
    # A bit dirty, but well..
    $LOGGER->debug(App::CSE->instance()->colorizer->colored("No class '$file_class_name' for mimetype $mime_type ($file_name)",'red bold'));
    return undef;
  }
  return $file_class;
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

App::CSE::File - A general file

=head1 METHODS

=head2 effective_object

Effective Object. Some classes can choose to return something different.

=cut
