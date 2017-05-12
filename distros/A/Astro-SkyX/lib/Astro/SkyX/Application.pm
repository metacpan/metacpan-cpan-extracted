package Astro::SkyX::Application;

use 5.006001;
use strict;
use warnings;
require IO::Socket;
require Exporter;
require Astro::SkyX;

#use vars qw( $SkyXConnection $_count );
our @ISA = qw(Exporter );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our ($AUTOLOAD);
# This allows declaration	use SkyX ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
new connect Send Get
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.11';
our @FUNCTIONS = qw(  );

# Preloaded methods go here.

##---##

  sub new {
    my ($caller, %arg) = @_;
    my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;
    my $self = bless {
        _debug          => $_[1],
	}, $class;
  # Private count increment/decrement methods
#    $self->_incr_count();
    return $self;
  }

 sub AUTOLOAD ($;$) {
    no strict "refs";
    my ($self, @newval) = @_;
    my $newtext = '';
    my $js = "/* Java Script */ \r\n";
    if ($AUTOLOAD =~ /.*::(.*::.*)/) {
      my $method = $1;
      # Let's build the javascript
      $newtext = join ',', map{ /^[0-9.-]*$/ ? $_ : qq/'$_'/ }@newval;
      $method =~ tr/::/./s;

      my ($package, $propertyName) = $AUTOLOAD =~ m/^(.+::)(.+)$/;
      if(haveFunction($propertyName)){
        $js .= $method . "(" . $newtext . ");\r\n";
      } elsif(length($propertyName) and length($newtext) ){
        $js .= $method . ' = ' . $newtext . ";\r\n";
      } else {
        $js .= $method . ";\r\n";
      }
      Astro::SkyX::Send($self,$js);
      return Astro::SkyX::Get($self);
    }
    die "No such method: $AUTOLOAD";
 }

 sub haveFunction{
        my ($value) = @_;
        for my $function (@FUNCTIONS){
                if($function eq $value){
                        return "1";
                }
        }
        return undef;
 }

 sub DESTROY {
#    $_[0]->_decr_count();
 }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SkyX - Perl extension for communications with The SkyX Professional Version 10.2.0

=head1 SYNOPSIS

  use Astro::SkyX;
  my $SX = Astro::SkyX->new();
  $Skysock = $SX->connect('localhost','3040');

  print "\nSkyX Initialized status: ",
    $SX->Application->initialized,
    "\nRunning version: ",
    $SX->Application->version,
    " Build " . $SX->Application->build,
    " on OS: " . $SX->Application->operatingSystem,
    "\n";


=head1 DESCRIPTION

Implementation of the SkyX Application Class.

=head2 EXPORT

None by default.


=head1 SEE ALSO

Don't forget ScriptTheSkyX documentation from Software Bisque.

=head1 AUTHOR

Robert Woodard, E<lt>kayak.man@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Robert Woodard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

There are restrictions on commercial use of the SkyX scripting engine.
Please see the Software Bisque End User License Agreement prior to
using this module in a commercial setting.

=cut
