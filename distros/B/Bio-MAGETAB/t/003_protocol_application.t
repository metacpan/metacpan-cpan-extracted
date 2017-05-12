#!/usr/bin/env perl
#
# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: 003_protocol_application.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::ProtocolApplication' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

use Bio::MAGETAB::Protocol;
use Bio::MAGETAB::ProtocolParameter;
use Bio::MAGETAB::Measurement;
use Bio::MAGETAB::ParameterValue;
use Bio::MAGETAB::Comment;
use Bio::MAGETAB::Contact;

my $prot = Bio::MAGETAB::Protocol->new( name => 'test protocol' );
my $parm = Bio::MAGETAB::ProtocolParameter->new( name => 'test param', protocol => $prot );
my $meas = Bio::MAGETAB::Measurement->new( measurementType => 'test measurement', value => 'value' );
my $pval = Bio::MAGETAB::ParameterValue->new( parameter => $parm, measurement => $meas );
my $comm = Bio::MAGETAB::Comment->new( name => 'test comment', value => 'of interest' );
my $perf = Bio::MAGETAB::Contact->new( lastName => 'test_performer' );

my %required_attr = (
    protocol        => $prot,
);

# Dates can be flexibly expressed as anything Date::Manip will
# understand.
my %optional_attr = (
    date            => '2008-01-01T00:00:00',
    parameterValues => [ $pval ],
    performers      => [ $perf ],
    comments        => [ $comm ],
);

my %bad_attr = (
    protocol        => 'test',
    date            => [],
    parameterValues => 'test',
    performers      => [ 'test' ],
    comments        => [ 'test' ],
);

my $prot2 = Bio::MAGETAB::Protocol->new( name => 'test protocol 2' );
my $parm2 = Bio::MAGETAB::ProtocolParameter->new( name => 'test param', protocol => $prot2 );
my $meas2 = Bio::MAGETAB::Measurement->new( measurementType => 'test measurement', value => 'value 2' );
my $pval2 = Bio::MAGETAB::ParameterValue->new( parameter => $parm2, measurement => $meas2 );
my $comm2 = Bio::MAGETAB::Comment->new( name => 'test comment', value => 'of interest 2' );
my $perf2 = Bio::MAGETAB::Contact->new( lastName => 'test_performer 2' );

# N.B. dates may also be expressed as a hashref to be passed to
# DateTime->new(), but we don't test that here.
my %secondary_attr = (
    protocol        => $prot2,
    date            => DateTime->new( year => 2008, month=> 01, day=> 01 ),
    parameterValues => [ $pval2 ],
    performers      => [ $perf, $perf2 ],
    comments        => [ $comm2 ],
);

# We need to specify UTC as the time zone, since Date::Manip returns
# UTC times by default.
$ENV{'TZ'} = 'UTC';

my $obj = test_class(
    'Bio::MAGETAB::ProtocolApplication',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
