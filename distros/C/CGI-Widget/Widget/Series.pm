package CGI::Widget::Series;

use lib '../';
use CGI::Widget;
use vars qw(@ISA $VERSION);
use strict;
use overload '""' => \&html;

@ISA = qw(CGI::Widget);
$VERSION = '1.01';


sub _init {
  my $self = shift;
  #clean out leading -'s;
  my @t = @_;


  for(my $i = 0; $i < @t; $i+=2){ $t[$i] =~ s/^-//; }
  my %param = @t;

  $param{break} ||= 0;
  $param{linebreak} ||= 0;

  foreach my $i (qw(length render break linebreak)){
    defined $param{$i} ? $self->$i($param{$i}) : die "$i undefined in $0 : $!";
  }

  return 1;
}

sub html {
  my ($self,@args) = @_;

  $self = __PACKAGE__->new(@args) unless ref $self;

  my $return = '';
  for my $i (1..$self->length){
	  $return .= $self->render->($i);
          $return .= $self->linebreak ? '<br>' : '';
          $return .= $self->break ? "\n" : '';
  }
  return $return;
}

sub length {
  my($self,$val) = @_;
  return $self->{length} unless defined $val;
  $self->{length} = $val;
}

sub render {
  my($self,$val) = @_;
  return $self->{render} unless defined $val;
  $self->{render} = $val;
}

sub break {
  my($self,$val) = @_;
  return $self->{break} unless defined $val;
  $self->{break} = $val;
}

sub linebreak {
  my($self,$val) = @_;
  return $self->{linebreak} unless defined $val;
  $self->{linebreak} = $val;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGI::Widget::Series - Class for making CGI series forms

=head1 SYNOPSIS

  use CGI::Widget::Series;
  my $series = CGI::Widget::Series->new(
                                         -length    => 10,
                                         -linebreak => 1,
                                        );
  print $series;   #prints <form><table>...</form>

=head1 DESCRIPTION

This class allows you to create simple image-based gradients for use
in simple CGI forms.  This class is intended to be an aesthetically
pleasing alternative to the clunky HTML radio and select form types.
For more information, see L<CGI>.

=head2 Constuctors

CGI::Widget::Series has only one constructor: new().

new() accepts the following parameters:

 Parameter                   Purpose
 ------------------------------------------------------------------
 length                      Number of element in the series
 break                       Insert <BR> tag after each element
 linebreak                   Insert linebreak after each element
 render                      A callback that returns the HTML
                             for a defined position in the series.
                             The position is passed as a parameter.

=head2 Methods

Interpreted in a scalar context, the object is overloaded to return 
the html for the series.  Easy!  

html() can also be called to produce the series html.

The remainder of the methods are of the same name as the parameter
passed to new(), minus the optional leading dash.  They are 
read/write-able.

=head1 AUTHOR

 Thanks to Adrian Arva and Lincoln Stein.

 Allen Day <allenday@ucla.edu>
 Copyright (c) 2001.

=head1 SEE ALSO

L<perl>.
L<CGI::Widget>.

=cut
