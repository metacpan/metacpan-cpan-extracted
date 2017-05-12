# Data/Define.pm
#
# Copyright (c) 2006 Serguei Trouchelle. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# History:
#  1.03  2007/02/04 Quality update (Test::Pod, Test::Pod::Coverage, eg)
#  1.02  2006/11/02 Dist fixed
#  1.01  2006/09/07 Initial revision

=head1 NAME

Data::Define - Make undef's defined

=head1 SYNOPSIS

 use Data::Define;
 
 print define undef; # prints ''


 use Data::Define qw/ brockets /;

 print define undef; # prints '<undef>';
 

 use Data::Define qw/ define_html brockets /;

 print define_html undef; # prints '&lt;undef&gt;';
 
 use Data::Define qw/ define_html div-class-undef /;

 print define_html undef; # prints '&lt;undef&gt;';
 

=head1 DESCRIPTION

Data::Define

=head1 METHODS

=head2 define

This method takes one parameter and returns it defined even if it was not
defined primordially.

This method is exported by default.

Default return value is ''. If you asked to export 'brockets' using
Data::Define, return value becomes 'E<lt>undefE<gt>'.
You can specify your own default value using Data::Define-E<gt>L</set_undef_value>.

=head2 define_html

This method works exactly the same as 'define', but when exporting 'brockets',
return value becomes '&lt;undef*gt;', so you can send it to HTML browser
without need to escape.

Additionally, you can ask to export 'div-class-undef', then return value will be
'E<lt>div class="undef"E<gt>E<lt>/divE<gt>'.

You can specify your own default value using Data::Define-E<gt>L</set_undef_value_html>.

=head2 set_undef_value( $value )

This method allows you to specify your own default value for define. 
Usage is C<Data::Define-E<gt>set_undef_value( $value )>.

If $value is not defined, default value ('', or 'E<lt>undefE<gt>' if 'brockets'
is exported) is used.

=head2 set_undef_value_html( $value )

This method allows you to specify your own default value for define_html. 
Usage is C<Data::Define-E<gt>set_undef_value_html( $value )>.

If $value is not defined, default value ('', or '&lt;undef&gt;' if 'brockets'
is exported, or 'E<lt>div class="undef"E<gt>E<lt>/divE<gt>' if
'div-class-undef' is exported) is used.

=cut

package Data::Define;

require Exporter;
use Config;

use strict;
use warnings;

our @EXPORT    = qw/ define /;
our @EXPORT_OK = qw/ define_html div-class-undef brockets /;
our %EXPORT_TAGS = ();
our @ISA = qw/Exporter/;

$Data::Define::VERSION = "1.03";

our $UNDEFVALUE = '';
our $UNDEFVALUEHTML = '';
our $DEFAULT_UNDEFVALUE = '';
our $DEFAULT_UNDEFVALUEHTML = '';

sub define {
  my $val = shift;
  return defined $val ? $val : $UNDEFVALUE;
}

sub define_html {
  my $val = shift;
  return defined $val ? $val : $UNDEFVALUEHTML;
}

sub set_undef_value {
  my $self = shift;
  $UNDEFVALUE = shift;
  $UNDEFVALUE = $DEFAULT_UNDEFVALUE unless defined $UNDEFVALUE;
}

sub set_undef_value_html {
  my $self = shift;
  $UNDEFVALUEHTML = shift;
  $UNDEFVALUEHTML = $DEFAULT_UNDEFVALUEHTML unless defined $UNDEFVALUEHTML;
}

sub import {
  my $pkg = shift;
  my %routines;
  my @name;

  if (@name = grep m/^name=/, @_) {
    my $n = (split(/=/,$name[0]))[1];
    @_ = grep !/^name=/, @_;
  }
  grep $routines{$_}++, @_, @EXPORT ;

  if ($routines{'brockets'}) {
    $UNDEFVALUEHTML = '&lt;undef&gt;';
    $UNDEFVALUE = '<undef>';
    $DEFAULT_UNDEFVALUE = '<undef>';
    $DEFAULT_UNDEFVALUEHTML = '&lt;undef&gt;'; # for set_undef_value with undefined param
  }
  if ($routines{'div-class-undef'}) {
    $UNDEFVALUEHTML = '<div class="undef"></div>';
    $DEFAULT_UNDEFVALUEHTML = '<div class="undef"></div>'; # for set_undef_value_html with undefined param
  }

  my $oldlevel = $Exporter::ExportLevel;
  $Exporter::ExportLevel = 1;
  Exporter::import($pkg, keys %routines);
  $Exporter::ExportLevel = $oldlevel;
}


1;

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@railways.dp.ua>E<gt>

=head1 COPYRIGHT

Copyright (c) 2006 Serguei Trouchelle. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
