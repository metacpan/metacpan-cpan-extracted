#!/usr/bin/perl

package BACnet::PDUTypes::Utils;

use warnings;
use strict;

use bytes;

use BACnet::APDU;

our $confirmed_service = {
    'AcknowledgeAlarm'           => 0,
    'ConfirmedCOVNotification'   => 1,     # Implemented
    'ConfirmedEventNotification' => 2,
    'GetAlarmSummary'            => 3,
    'GetEnrollmentSummary'       => 4,
    'SubscribeCOV'               => 5,     # Implemented
    'AtomicReadFile'             => 6,
    'AtomicWriteFile'            => 7,
    'AddListElement'             => 8,
    'RemoveListElement'          => 9,
    'CreateObject'               => 10,
    'DeleteObject'               => 11,
    'ReadProperty'               => 12,    # Implemented
    'ReadPropertyConditional'    => 13,
    'ReadPropertyMultiple'       => 14,
    'WriteProperty'              => 15,
    'WritePropertyMultiple'      => 16,
    'DeviceCommunicationControl' => 17,
    'ConfirmedPrivateTransfer'   => 18,
    'ConfirmedTextMessage'       => 19,
    'ReinitializeDevice'         => 20,
    'VT-Open'                    => 21,
    'VT-Close'                   => 22,
    'VT-Data'                    => 23,
    'Authenticate'               => 24,
    'RequestKey'                 => 25,
    'ReadRange'                  => 26,
    'LifeSafetyOperation'        => 27,
    'SubscribeCOVProperty'       => 28,
    'GetEventInformation'        => 29,
};

our $confirmed_service_rev = { reverse %$confirmed_service };

our $unconfirmed_service = {
    'I-Am'                         => 0,
    'I-Have'                       => 1,
    'UnconfirmedCOVNotification'   => 2,    # Implemented
    'UnconfirmedEventNotification' => 3,
    'UnconfirmedPrivateTransfer'   => 4,
    'UnconfirmedTextMessage'       => 5,
    'TimeSynchronization'          => 6,
    'Who-Has'                      => 7,
    'Who-Is'                       => 8,
    'UTC-TimeSynchronization'      => 9,
    'WriteGroup'                   => 10,
};

our $unconfirmed_service_rev = { reverse %$unconfirmed_service };

our $reject_reason = {
    'Other'                    => 0,
    'BufferOverflow'           => 1,
    'InconsistentParameters'   => 2,
    'InvalidParameterDataType' => 3,
    'InvalidTag'               => 4,
    'MissingRequiredParameter' => 5,
    'ParameterOutOfRange'      => 6,
    'TooManyArguments'         => 7,
    'UndefinedEnumeration'     => 8,
    'UnrecognizedService'      => 9,
};

our $reject_reason_rev = { reverse %$reject_reason };

our $abort_reason = {
    'Other'                         => 0,
    'BufferOverflow'                => 1,
    'InvalidAPDUInThisState'        => 2,
    'PreemptedByHigherPriorityTask' => 3,
    'SegmentationNotSupported'      => 4,
    'SecurityError'                 => 5,
    'InsufficientSecurity'          => 6,
    'WindowSizeOutOfRange'          => 7,
    'ApplicationExceededReplyTime'  => 8,
    'OutOfResources'                => 9,
    'TSMTimeout'                    => 10,
    'APDUTooLong'                   => 11,
};

our $abort_reason_rev = { reverse %$abort_reason };

sub _holder {
    return undef;
}

1;
