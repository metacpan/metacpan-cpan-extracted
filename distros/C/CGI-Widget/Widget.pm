package CGI::Widget;

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION $AUTOLOAD);
#use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.15';

require Exporter;
@ISA = 'Exporter';
@EXPORT_OK   = qw(AUTOLOAD);
%EXPORT_TAGS = ( 'standard' => [qw(AUTOLOAD)] );

use overload
 '""'     => \&asString,
 fallback => 1;

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init(@_);
  return $self;
}

sub import {
  my $exportset = $_[1];
  my $to_package = ((caller)[0]);
  my $code = '';

  return unless $exportset;

  if ($exportset eq ':html' or $exportset eq ':standard') {
    $code = "*".$to_package."::AUTOLOAD = \\&AUTOLOAD_html";
  } elsif ($exportset eq ':wml') {
    $code = "*".$to_package."::AUTOLOAD = \\&AUTOLOAD_wml";
  } elsif ($exportset eq ':javascript') {
    $code = "*".$to_package."::AUTOLOAD = \\&AUTOLOAD_javascript";
  }

  eval $code;
  die $@ if $@;
}

sub AUTOLOAD_html {
  my ($pack,$func) = $AUTOLOAD =~ /(.+)::([^:]+)$/;
  $func =~ s/__/::/g;

  my $req = "CGI::Widget::$func";
  eval "require $req" || die "couldn't find $req : $!";

  return CGI::Widget::html($func) unless $req->can('html');
  return $req->html(@_);
}

sub AUTOLOAD_wml {
  my ($pack,$func) = $AUTOLOAD =~ /(.+)::([^:]+)$/;
  $func =~ s/__/::/g;
    
  my $req = "CGI::Widget::$func";
  eval "require $req" || die "couldn't find $req : $!";

  return CGI::Widget::wml($func) unless $req->can('wml');
  return $req->wml(@_);
}

sub AUTOLOAD_javascript {
  my ($pack,$func) = $AUTOLOAD =~ /(.+)::([^:]+)$/;
  $func =~ s/__/::/g;

  my $req = "CGI::Widget::$func";
  eval "require $req" || die "couldn't find $req : $!";

  return CGI::Widget::javascript($func) unless $req->can('javascript');
  return $req->javascript(@_);
}

sub AUTOLOAD {
  my ($pack,$func) = $AUTOLOAD =~ /(.+)::([^:]+)$/;

  $func =~ s/__/::/g;

  my $req = "CGI::Widget::$func";
  eval "require $req" || die "couldn't find $req : $!";
  return $req->new(@_);
}

sub DESTROY {}

sub _init {
  my $self = shift;
  return 1;
}

sub html       { die "Looks like html() isn't defined in package ".shift;       }
sub wml        { die "Looks like wml() isn't defined in package ".shift;        }
sub javascript { die "Looks like javascript() isn't defined in package ".shift; }

sub asString {
  my $self = shift;
  return $self;  #what did you expect from the base class?
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGI::Widget - Base class for CGI::Widget::...

=head1 SYNOPSIS

  use CGI::Widget qw(:standard);
  #prints 1,2,3,4,
  print Series(-length=>4,-render=>sub{return shift.','});

=head1 DESCRIPTION

The CGI::Widget module's purpose is to allow authors of CGI or other 
dynamically generated HTML documents an easy way to create common, 
and possibly complex, page elements.

Widgets can be accessed either by explicitly creating Widget objects, as:

  use CGI::Widget::Series;
  my $series_widget = CGI::Widget::Series->new();
  print $series_widget,"\n";

or by using a CGI::Widget import tag, as:
  use CGI::Widget qw(:standard);
  print Series(),"\n";    #constructs CGI::Widget::Series
  print HList__Node,"\n"; #constructs CGI::Widget::HList::Node

you can construct CGI::Widget subclasses by name.  Deeper subclasses
can be constructed by replacing double-colon (::) with double-underscore
(__).

=head2 EXPORT

 A modified AUTOLOADer is exported.  How the autoloader functions depends
 on what import tags with which CGI::Widget was brought into the namespace.
 The first import tag is used, while additional tags are silently ignored.

 Tag             Returns
 --------------------------
 :standard       HTML
 :html           HTML
 :wml            WML
 :javascript     javascript

=head1 ACKNOWLEDGMENTS

 Thanks to Slaven Rezic for valuable ideas.

=head1 AUTHOR

 Allen Day E<allenday@ucla.edu>
 Copyright (c) 2001.

=head1 SEE ALSO

L<Perl>.
L<CGI::Widget::Series>

=cut
