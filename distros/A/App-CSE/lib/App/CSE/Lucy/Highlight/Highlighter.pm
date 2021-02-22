package App::CSE::Lucy::Highlight::Highlighter;
$App::CSE::Lucy::Highlight::Highlighter::VERSION = '0.016';
use base qw/Lucy::Highlight::Highlighter/;

use strict;
use warnings;
use Carp;

## See issue https://github.com/dagolden/class-insideout/issues/6
## to know why we cannot use that for now.
# use Class::InsideOut qw( private register );

# Inside out attributes.
my %cse_command;
my %cse;

=head2 new

Adds the cse_command new argument.

=cut

sub new{
  my ($class, %options) = @_;
  my $cse_command = delete $options{'cse_command'} || confess("Missing cse_command");
  my $self = $class->SUPER::new(%options);
  # register($self);
  $cse_command{ $self } = $cse_command;
  $cse{ $self } = $cse_command->cse();
  return $self;
}

=head2 encode

Overrides the Lucy encode method to avoid any HTMLI-zation.

=cut

sub encode{
  my ($self, $text) = @_;
  return $text;
}

=head2 highlight

Highlights the bit of text using either colors or pure text.

=cut

sub highlight{
  my ($self, $text) = @_;

  my $cse = $cse{ $self };

  if( $cse->interactive() ){
    return $cse->colorizer->colored($text , 'yellow on_black');
  }else{
    return '[>'.$text.'<]';
  }
}

sub DESTROY{
  my ($self) = @_;
  delete $cse_command{ $self };
  delete $cse{ $self };
  $self->SUPER::DESTROY();
}

1;
