#!/usr/bin/perl

package BACnet::ServiceRequestSequences::COVConfirmedNotification;

use warnings;
use strict;

use BACnet::ServiceRequestSequences::COVUnconfirmedNotification;

our $request_skeleton =
  $BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request_skeleton;

sub request {
    return
      BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request(@_);
}

our $negative_response_skeleton =
  $BACnet::ServiceRequestSequences::Utils::error_type_skeleton;

sub negative_response {
    return BACnet::ServiceRequestSequences::Utils::_error_type(@_);
}

1;
