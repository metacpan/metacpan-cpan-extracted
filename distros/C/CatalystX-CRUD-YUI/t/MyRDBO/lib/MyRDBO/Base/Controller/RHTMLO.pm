package MyRDBO::Base::Controller::RHTMLO;
use strict;
use warnings;

# **IMPORTANT** ISA order
use base qw(
    CatalystX::CRUD::YUI::Controller
    CatalystX::CRUD::Controller::RHTMLO
);

# **IMPORTANT** since we have a classic diamond MRO
use MRO::Compat;
use mro "c3";

1;

