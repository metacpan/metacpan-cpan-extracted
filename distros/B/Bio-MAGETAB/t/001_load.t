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
# $Id: 001_load.t 333 2010-06-02 16:41:31Z tfrayner $
#
# t/001_load.t - check module loading

use strict;
use warnings;

use Test::More tests => 56;

BEGIN {
    use_ok( 'Bio::MAGETAB' );
    use_ok( 'Bio::MAGETAB::BaseClass' );
    use_ok( 'Bio::MAGETAB::ArrayDesign' );
    use_ok( 'Bio::MAGETAB::Assay' );
    use_ok( 'Bio::MAGETAB::Comment' );
    use_ok( 'Bio::MAGETAB::CompositeElement' );
    use_ok( 'Bio::MAGETAB::Contact' );
    use_ok( 'Bio::MAGETAB::ControlledTerm' );
    use_ok( 'Bio::MAGETAB::Data' );
    use_ok( 'Bio::MAGETAB::DataAcquisition' );
    use_ok( 'Bio::MAGETAB::DatabaseEntry' );
    use_ok( 'Bio::MAGETAB::DataFile' );
    use_ok( 'Bio::MAGETAB::DataMatrix' );
    use_ok( 'Bio::MAGETAB::DesignElement' );
    use_ok( 'Bio::MAGETAB::Edge' );
    use_ok( 'Bio::MAGETAB::Event' );
    use_ok( 'Bio::MAGETAB::Extract' );
    use_ok( 'Bio::MAGETAB::Factor' );
    use_ok( 'Bio::MAGETAB::FactorValue' );
    use_ok( 'Bio::MAGETAB::Feature' );
    use_ok( 'Bio::MAGETAB::Investigation' );
    use_ok( 'Bio::MAGETAB::LabeledExtract' );
    use_ok( 'Bio::MAGETAB::Material' );
    use_ok( 'Bio::MAGETAB::MatrixColumn' );
    use_ok( 'Bio::MAGETAB::MatrixRow' );
    use_ok( 'Bio::MAGETAB::Measurement' );
    use_ok( 'Bio::MAGETAB::Node' );
    use_ok( 'Bio::MAGETAB::Normalization' );
    use_ok( 'Bio::MAGETAB::ParameterValue' );
    use_ok( 'Bio::MAGETAB::Protocol' );
    use_ok( 'Bio::MAGETAB::ProtocolApplication' );
    use_ok( 'Bio::MAGETAB::ProtocolParameter' );
    use_ok( 'Bio::MAGETAB::Publication' );
    use_ok( 'Bio::MAGETAB::Reporter' );
    use_ok( 'Bio::MAGETAB::Sample' );
    use_ok( 'Bio::MAGETAB::SDRF' );
    use_ok( 'Bio::MAGETAB::SDRFRow' );
    use_ok( 'Bio::MAGETAB::Source' );
    use_ok( 'Bio::MAGETAB::TermSource' );
    use_ok( 'Bio::MAGETAB::Util::Builder' );
    use_ok( 'Bio::MAGETAB::Util::Reader::Tabfile' );
    use_ok( 'Bio::MAGETAB::Util::Reader::TagValueFile' );
    use_ok( 'Bio::MAGETAB::Util::Reader::ADF' );
    use_ok( 'Bio::MAGETAB::Util::Reader::DataMatrix' );
    use_ok( 'Bio::MAGETAB::Util::Reader::IDF' );
    use_ok( 'Bio::MAGETAB::Util::Reader::SDRF' );
    use_ok( 'Bio::MAGETAB::Util::Reader' );
    use_ok( 'Bio::MAGETAB::Util::Writer' );
    use_ok( 'Bio::MAGETAB::Util::Writer::Tabfile' );
    use_ok( 'Bio::MAGETAB::Util::Writer::IDF' );
    use_ok( 'Bio::MAGETAB::Util::Writer::ADF' );
    use_ok( 'Bio::MAGETAB::Util::Writer::SDRF' );
    use_ok( 'Bio::MAGETAB::Util::RewriteAE' );
}

SKIP: {

    eval {
        require Tangram;
        require DBI;
    };

    skip 'Persistence needs Tangram and DBI.',
        2 if $@;

    require_ok('Bio::MAGETAB::Util::Persistence');
    require_ok('Bio::MAGETAB::Util::DBLoader');
}

SKIP: {

    eval {
        require GraphViz;
    };

    skip 'Visualisation needs GraphViz',
        1 if $@;

    use_ok( 'Bio::MAGETAB::Util::Writer::GraphViz' );
}

