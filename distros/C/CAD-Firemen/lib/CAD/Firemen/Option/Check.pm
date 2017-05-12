#!/usr/bin/perl
######################
#
#    Copyright (C) 2011  TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

use strict;
use warnings;

# Pod::Weaver infos
# ABSTRACT: An option check error

package CAD::Firemen::Option::Check;
{
  $CAD::Firemen::Option::Check::VERSION = '0.7.2';
}
use Exporter 'import';

sub new {
  my ($class) = shift;
  my (%params) = @_;

  # check parameters
  if(!exists($params{"name"})){
    $params{"name"} = "";
  }
  #if(!exists($params{"line"})){
  #  $params{"line"} = "";
  #}
  if(!exists($params{"errorString"})){
    $params{"errorString"} = "";
  }
  if(!exists($params{"case"})){
    $params{"case"} = 0;
  }

  my $self = {
    '_option' => $params{"name"},
    #'_line' => $params{"line"}
    '_errorString' => $params{"errorString"},
    '_case' => $params{"case"}
  };
  bless $self, $class;
  return $self;
}

sub setOption {
  my $self = shift;
  my $name = shift;
  if(!defined($name)){
    return 0;
  }
  $self->{'_option'} = $name;
  return 1;
}

sub option {
  my $self = shift;
  return $self->{'_option'};
}

sub setErrorString {
  my $self = shift;
  my $string = shift;
  if(!defined($string)){
    return 0;
  }
  $self->{'_errorString'} = $string;
  return 1;
}

sub errorString {
  my $self = shift;
  return $self->{'_errorString'};
}

sub setCase {
  my $self = shift;
  my $case = shift;
  if(!defined($case)){
    return 0;
  }
  $self->{'_case'} = $case;
  return 1;
}

sub case {
  my $self = shift;
  return $self->{'_case'};
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen::Option::Check - An option check error

=head1 VERSION

version 0.7.2

=head1 DESCRIPTION

Create a new object of CAD::Firemen::Option::Check with

my $check = new CAD::Firemen::Option::Check("name" => "OPTION_NAME");

afterwards, set the error string (or specify it already
at the constructor with ("errorString" => "YOUR ERROR MESSAGE"))

$check->setErrorString("YOUR ERROR MESSAGE");

=head1 METHODS

=head2 new

Creates a new object of type CAD::Firemen::Option::Check.
Per default, all values are empty-

You can specify values like that:

my $change = new CAD::Firemen::Change(
  "name" => "OPTION_NAME",
  "errorString" => "YOUR ERROR MESSAGE"
);

=head2 setOption

Sets the option name. To read it, just use method option().

=head2 option

Returns the name of this option.

=head2 setErrorString

Sets the error string. To read it, just use method errorString().

=head2 errorString

Returns the error string related to this option.

=head2 setCase

Sets the case. To read it, just use method case().
Should be set to true, if the error is only a case problem.

=head2 case

Returns the case related to this option.

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
