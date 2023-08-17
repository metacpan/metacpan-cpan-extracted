package Catalyst::View::MojoTemplate::PerContext;

use Moo;
use Mojo::Template;
use Scalar::Util qw(blessed);
use File::Spec;
use String::CamelCase;

extends 'Catalyst::View::BasePerRequest';

our $VERSION = 0.005;
our @MojoArgs = (qw/
  auto_escape append capture_end capture_start comment_mark encoding
  escape_mark expression_mark line_start prepend trim_mark tag_start tag_end
/);

has __mt => (is=>'ro', required=>1);

sub modify_init_args {
  my ($class, $app, $merged_args) = @_;
  my $extension = exists($merged_args->{'file_extension'}) ? delete($merged_args->{'file_extension'}) : '';
  my %mojo_args = ();
  foreach my $ma (@MojoArgs) {
    $mojo_args{$ma} = delete($merged_args->{$ma}) if exists($merged_args->{$ma});
  };

  $class->modify_mojo_args($app, %mojo_args);
  $merged_args->{__mt} = $class->build_mojo($app, $extension, %mojo_args);

  return $merged_args;
}

sub modify_mojo_args {
  my ($class, $app, %mojo_args) = @_;
  $mojo_args{prepend} = 'my ($self, $c) = (shift @_ , shift @_);' . ($mojo_args{prepend}||'');
  $mojo_args{namespace} = "${class}::MojoSandbox";
}

sub build_mojo {
  my ($class, $app, $extension, %mojo_args) = @_;
  my $mt = Mojo::Template->new(%mojo_args);
  my $data = $class->find_template($app, $extension);
  $mt->parse($data);
}

sub find_template {
  my ($class, $app, $extension) = @_;
  {
    no strict 'refs';
    my $data_fh = \*{"${class}::DATA"};
    if(not eof $data_fh) {
      my $data = join '', <$data_fh>;
      return $data if $data;
    }
  }
  return $class->template_from_path($app, $extension);
}

sub get_path_to_template {
  my ($class, $app, $extension) = @_;
  my @parts = split("::", $class);
  my $filename = (pop @parts);
  $filename = String::CamelCase::decamelize($filename);
  my $path = "$class.pm";
  $path =~s/::/\//g;
  my $inc = $INC{$path};
  my $base = $inc;
  $base =~s/$path$//g;
  my $template_path = File::Spec->catfile($base, @parts, $filename);
  $template_path .= ".$extension" if $extension;
  $app->log->debug("Looking for template at: $template_path") if $app->debug;
  return $template_path;
}
 
sub template_from_path {
  my ($class, $app, $extension) = @_;
  my $template_path = $class->get_path_to_template($app, $extension);
  open(my $fh, '<', $template_path)
    || die "can't open '$template_path': $@";
  local $/; my $slurped = $fh->getline;
  close($fh);
  return $slurped;
}

sub process_mojo_template {
  my ($self, $c) = @_;
  return $self->__mt->process($self, $c);
}

sub render {
  my ($self, $c) = @_;
  $c->log->debug("Processing Template: @{[ ref $self ]}") if $c->debug;

  my $rendered = $self->process_mojo_template($c);

  if(blessed($rendered) && $rendered->isa('Mojo::Exception')) {
    $c->log->error("Processing the template returning ann error");
    $c->log->debug($rendered) if $c->debug;
  }
    
  return $rendered;
}

1
