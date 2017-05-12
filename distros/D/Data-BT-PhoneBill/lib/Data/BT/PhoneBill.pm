package Data::BT::PhoneBill;

$VERSION = '1.00';

=head1 NAME

Data::BT::PhoneBill - Parse a BT Phone Bill from their web site

=head1 SYNOPSIS

  my $bill = Data::BT::PhoneBill->new($filename);

  while (my $call = $bill->next_call) {
    print $call->date, $call->time, $call->destination,
          $call->number, $call->duration, $call->type, $call->cost;
    }
  }

=head1 DESCRIPTION

This module provides an interface for querying your BT phone bill,
as produced from their "View My Bill" service at http://www.bt.com/

You should use their "Download Calls" option to save your bill as a CSV
file, and then feed it to this module.

=head1 CONSTRUCTOR

=head2 new

  my $bill = Data::BT::PhoneBill->new($filename);

Parses the bill stored in $filename.

=head1 FETCHING DATA

=head2 next_call

  while (my $call = $bill->next_call) {
    print $call->date, $call->time, $call->destination,
          $call->number, $call->duration, $call->type, $call->cost;
    }
  }

Each time you call $bill->next_call it will return a
Data::BT::PhoneBill::_Call object representing a telephone call (or false
when there are no more to read)

Each Call object has the following methods defined:

=head2 date

A Date::Simple object represeting the date of the call.

=head2 time

A string representing the time of the call in the 24-hr format 'hh:mm'.

=head2 destination

A string that for local and national calls will usually be the
town. However this can also contain things like "Premium Rate", "Local
Rate" etc for 'non-geographic' calls.

=head2 number

A string representing the telephone number dialled, formatted as it
appears on the bill.

=head2 duration

The length of the call in seconds.

=head2 type

The 'type' of call - e.g. "DD Local", "DD International".

=head2 cost

The cost of the call, before any discounts are applied, in pence.

=head2 chargecard

Any chargecard number used make the call.

=head2 installation

The phone number from which the call was placed.

=head2 line

The line from which the call was placed (if a secondary line with the
same number is installed).

=head2 rebate

Any rebates applied to the call.

=cut

use strict;
use Text::CSV_XS;
use IO::File;

use overload 
 '<>' => \&next_call,
 fallback => 1;

sub new {
  my ($class, $file) = @_;
  my $fh = new IO::File $file, "r"  or die "Can't read $file: $!\n";
  my $headers;
  # Downloads now have blank lines at the top
  while (($headers = <$fh>) !~ /Date/) {
    die "Couldn't find header line" if eof($fh);
  }
  bless {
    _fh => $fh,
    _parser => Text::CSV_XS->new,
  }, $class;
}

sub _fh  { shift->{_fh}     }
sub _csv { shift->{_parser} }

sub next_call {
  my $self = shift;
  my $fh = $self->_fh;
  my $line = <$fh>;
  return unless defined $line;
  if ($self->_csv->parse($line)) {
    return Data::BT::PhoneBill::_Call->new($self->_csv->fields)
  } else {
    warn "Cannot parse: " . $self->_csv->error_input . "\n";
    return;
  }
}

# ==================================================================== #

package Data::BT::PhoneBill::_Call;

use Date::Simple;

#ChargeCode,InstallationNo,LineNo,ChargeCardNo,Date,Time,Destination,CalledNo,Duration,TxtDirectRebate,Cost
our @fields = qw(type installation line chargecard _date time destination 
    _number _duration rebate _cost);

for my $f (@fields) {
    no strict 'refs';
    *{$f} = sub { shift->{$f} };
}

sub new {
  my ($class, @data) = @_;
  bless { map { $fields[$_] => $data[$_] } 0..$#fields } => $class;
}

sub date {
  my @parts = split /\//, shift->_date;
  return Date::Simple->new(@parts[2,1,0]);
}

sub number {
  my $num = shift->_number;
  $num =~ s/\s+$//; $num;
}

sub duration { 
  my ($h, $m, $s) = split /:/, shift->_duration;
  return ($h * 60 * 60) + ($m * 60) + $s;
}

sub cost { shift->_cost * 100 }

1;

=head1 AUTHOR

Tony Bowden, with improvements from Simon Cozens 

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Data-BT-PhoneBill@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

The Perl.com article on Class::DBI is based around Data::BT::PhoneBill - 
  http://www.perl.com/pub/a/2002/11/27/classdbi.html

=cut
