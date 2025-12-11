#!/usr/bin/perl

package BACnet::DataTypes::Enums::PropertyIdentifier;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use BACnet::DataTypes::Bone;

our $prop_types = {
    'Accepted-Modes'                => 175, # List of BACnetLifeSafetyMode
    'Acked-Transitions'             => 0,   # BACnetEventTransitionBits
    'Ack-Required'                  => 1,   # BACnetEventTransitionBits
    'Action'                        => 2,   # BACnetARRAY[N] of BACnetActionList
    'Adjust-Value'                  => 176, # REAL
    'All-Writes-Successful'         => 9,   # BOOLEAN
    'APDU-Timeout'                  => 11,  # Unsigned
    'Application-Software-Version'  => 12,  # CharacterString
    'Archive'                       => 13,  # BOOLEAN
    'Attempted-Samples'             => 124, # Unsigned
    'Average-Value'                 => 125, # REAL
    'Buffer-Size'                   => 126, # Unsigned32
    'Controlled-Variable-Reference' => 19,  # BACnetObjectPropertyReference
    'Controlled-Variable-Units'     => 20,  # BACnetEngineeringUnits
    'Controlled-Variable-Value'     => 21,  # REAL
    'Count'                         => 177, # Unsigned
    'Count-Before-Change'           => 178, # Unsigned
    'Count-Change-Time'             => 179, # BACnetDateTime
    'Database-Revision'             => 155, # Unsigned
    'Date-List'                     => 23,  # List of BACnetCalendarEntry
    'Description'                   => 28,
    'Device-Address-Binding'        => 30,  # List of BACnetAddressBinding
    'Effective-Period'              => 32,  # BACnetDateRange
    'Event-Enable'                  => 35,  # BACnetEventTransitionBits
    'Event-Parameters'              => 83,  # BACnetEventParameter
    'Event-State'                   => 36,  # BACnetEventState
    'Event-Time-Stamps'             => 130, # BACnetARRAY[3] of BACnetTimeStamp
    'Event-Type'                    => 37,  # BACnetEventType
    'File-Access-Method'            => 41,  # BACnetFileAccessMethod
    'File-Size'                     => 42,  # Unsigned
    'File-Type'                     => 43,  # CharacterString
    'Firmware-Revision'             => 44,  # CharacterString
    'In-Process'                    => 47,  # BOOLEAN
    'List-Of-Group-Members'         => 53,  # List of ReadAccessSpecification
    'List-Of-Object-Property-References' =>
      54,    # List of BACnetDeviceObjectPropertyReference
    'Location'                       => 58,
    'Log-Buffer'                     => 131,    # List of BACnetLogRecord
    'Log-Enable'                     => 133,    # BOOLEAN
    'Manipulated-Variable-Reference' => 60,     # BACnetObjectPropertyReference
    'Maximum-Value'                  => 135,    # REAL
    'Max-APDU-Length-Accepted'       => 62,     # Unsigned
    'Max-Pres-Value'                 => 65,     # Unsigned
    'Minimum-Value'                  => 136,    # REAL
    'Mode'                           => 160,    # BACnetLifeSafetyMode
    'Model-Name'                     => 70,     # CharacterString
    'Modification-Date'              => 71,     # BACnetDateTime
    'Notification-Class'             => 17,     # Unsigned
    'Notify-Type'                    => 72,     # BACnetNotifyType
    'Number-Of-APDU-Retries'         => 73,     # Unsigned
    'Number-Of-States'               => 74,     # Unsigned
    'Object-Identifier'              => 75,     # BACnetObjectIdentifier
    'Object-List' => 76,    # BACnetARRAY[N] of BACnetObjectIdentifier
    'Object-Name' => 77,    # CharacterString
    'Object-Property-Reference' => 78,     # BACnetDeviceObjectPropertyReference
    'Object-Type'               => 79,     # BACnetObjectType
    'Operation-Expected'        => 161,    # BACnetLifeSafetyOperation
    'Out-Of-Service'            => 81,     # BOOLEAN
    'Output-Units'              => 82,     # BACnetEngineeringUnits
    'Polarity'                  => 84,     # BACnetPolarity
    'Present-Value'             => 85,     # ...
    'Priority'                  => 86,     # BACnetARRAY[3] of Unsigned
    'Priority-Array'            => 87,     # BACnetPriorityArray
    'Priority-For-Writing'      => 88,     # Unsigned(1..16)
    'Program-Change'            => 90,     # BACnetProgramRequest
    'Program-State'             => 92,     # BACnetProgramState
    'Protocol-Object-Types-Supported' => 96,     # BACnetObjectTypesSupported
    'Protocol-Revision'               => 139,    # Unsigned
    'Protocol-Services-Supported'     => 97,     # BACnetServicesSupported
    'Protocol-Version'                => 98,     # Unsigned
    'Read-Only'                       => 99,     # BOOLEAN
    'Recipient-List'                  => 102,    # List of BACnetDestination
    'Record-Count'                    => 141,    # Unsigned32
    'Reliability'                     => 103,    # BACnetReliability
    'Relinquish-Default'              => 104,    # REAL
    'Scale'                           => 187,    # BACnetScale
    'Scale-Factor'                    => 188,    # REAL
    'Schedule-Default'                => 174,    # Any
    'Segmentation-Supported'          => 107,    # BACnetSegmentation
    'Setpoint'                        => 108,    # REAL
    'Setpoint-Reference'              => 109,    # BACnetSetpointReference
    'Silenced'                        => 163,    # BACnetSilencedState
    'Status-Flags'                    => 111,    # BACnetStatusFlags
    'Stop-When-Full'                  => 144,    # BOOLEAN
    'System-Status'                   => 112,    # BACnetDeviceStatus
    'Total-Record-Count'              => 145,    # Unsigned32
    'Units'                           => 117,    # BACnetEngineeringUnits
    'Update-Time'                     => 189,    # BACnetDateTime
    'Valid-Samples'                   => 146,    # Unsigned
    'Vendor-Name'                     => 121,    # CharacterString
    'Vendor-Identifier'               => 120,    # Unsigned16
    'Window-Interval'                 => 147,    # Unsigned
    'Window-Samples'                  => 148,    # Unsigned
    'Zone-Members' => 165,    # List of BACnetDeviceObjectReference
};

our $prop_types_rev = { reverse %$prop_types };

our $bit_string_string         = 'BACnet::DataTypes::BitString';
our $bool_string               = 'BACnet::DataTypes::Bool';
our $char_string_string        = 'BACnet::DataTypes::CharString';
our $date_string               = 'BACnet::DataTypes::Date';
our $double_string             = 'BACnet::DataTypes::Double';
our $enum_string               = 'BACnet::DataTypes::Enum';
our $int_string                = 'BACnet::DataTypes::Int';
our $null_string               = 'BACnet::DataTypes::Null';
our $real_string               = 'BACnet::DataTypes::Real';
our $octet_string_string       = 'BACnet::DataTypes::OctetString';
our $object_identifier_string  = 'BACnet::DataTypes::ObjectIdentifier';
our $time_string               = 'BACnet::DataTypes::Time';
our $sequence_of_values_string = 'BACnet::DataTypes::SequenceOfValues';
our $sequence_value_string     = 'BACnet::DataTypes::SequenceValue';
our $unsigned_int_string       = 'BACnet::DataTypes::UnsignedInt';
our $choice_string             = 'BACnet::DataTypes::Choice';

my $date_tag              = BACnet::DataTypes::Utils::DATE_TAG;
my $time_tag              = BACnet::DataTypes::Utils::TIME_TAG;
my $bit_string_tag        = BACnet::DataTypes::Utils::BIT_STRING_TAG;
my $bool_tag              = BACnet::DataTypes::Utils::BOOL_TAG;
my $double_tag            = BACnet::DataTypes::Utils::DOUBLE_TAG;
my $enum_tag              = BACnet::DataTypes::Utils::ENUMERATED_TAG;
my $int_tag               = BACnet::DataTypes::Utils::SIGNED_INT_TAG;
my $null_tag              = BACnet::DataTypes::Utils::NULL_TAG;
my $real_tag              = BACnet::DataTypes::Utils::REAL_TAG;
my $octet_string_tag      = BACnet::DataTypes::Utils::OCTET_STRING_TAG;
my $object_identifier_tag = BACnet::DataTypes::Utils::OBJECT_ID_TAG;
my $unsigned_int_tag      = BACnet::DataTypes::Utils::UNSIGNED_INT_TAG;

our $action_command_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'device_identifier',
        dt   => $object_identifier_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'object_identifier',
        dt   => $object_identifier_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag          => 2,
        name         => 'property_identifier',
        dt           => $enum_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 3,
        name => 'property_array_index',
        dt   => $unsigned_int_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag          => 4,
        name         => 'property_value',
        dt           => 'property_identifier',
        substitution => "default",
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 5,
        name => 'priority',
        dt   => $unsigned_int_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 6,
        name => 'post_delay',
        dt   => $unsigned_int_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 7,
        name => 'quit_on_failure',
        dt   => $bool_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 8,
        name => 'write_successful',
        dt   => $bool_string
    ),
];

our $object_property_reference_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'object_identifier',
        dt   => $object_identifier_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag          => 1,
        name         => 'property_identifier',
        dt           => $enum_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'property_array_index',
        dt   => $unsigned_int_string
    ),
];

our $list_of_action_command_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $action_command_skeleton,
    ),
];

our $action_list_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag      => 0,
        name     => 'action',
        dt       => $sequence_of_values_string,
        skeleton => $list_of_action_command_skeleton,
    ),
];

our $list_of_action_list_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $action_list_skeleton,
    ),
];

our $date_time_skeleton = [
    BACnet::DataTypes::Bone->construct(
        name => 'date',
        dt   => $date_string
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'time',
        dt   => $time_string
    ),
];

our $date_range_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => $date_tag,
        name => 'start_date',
        dt   => $date_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => $date_tag,
        name => 'end_date',
        dt   => $date_string
    ),
];

our $calendar_entry_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'date',
        dt   => $date_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag      => 1,
        name     => 'date_range',
        dt       => $sequence_value_string,
        skeleton => $date_range_skeleton
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'week_N_day',
        dt   => $octet_string_string
    ),
];

our $address_skeleton = [
    BACnet::DataTypes::Bone->construct(
        name => 'network_number',
        dt   => $unsigned_int_string
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'mac_address',
        dt   => $octet_string_string
    ),
];

our $address_binding_skeleton = [
    BACnet::DataTypes::Bone->construct(
        name => 'device_object_identifier',
        dt   => $object_identifier_string
    ),
    BACnet::DataTypes::Bone->construct(
        name     => 'device_address',
        dt       => $sequence_value_string,
        skeleton => $address_skeleton
    ),
];

our $list_of_address_binding_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $address_binding_skeleton
    ),
];

our $list_of_bit_string_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    )
];

our $change_of_bit_string_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'time_delay',
        dt   => $unsigned_int_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'bitmask',
        dt   => $bit_string_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag      => 2,
        name     => 'list_of_bit_string_values',
        dt       => $sequence_of_values_string,
        skeleton => $list_of_bit_string_skeleton
    ),
];

our $property_states_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag => 0,
        dt  => $bool_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 1,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 2,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 3,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 4,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 5,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 6,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 7,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 8,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 9,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 10,
        dt  => $enum_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 11,
        dt  => $unsigned_int_string
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 12,
        dt  => $enum_string
    ),
];

our $time_stamp_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag => 0,
        dt  => $time_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 1,
        dt  => $unsigned_int_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag      => 2,
        dt       => $sequence_value_string,
        skeleton => $date_time_skeleton,
    ),
];

our $list_of_time_stamp_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $choice_string,
        skeleton => $time_stamp_skeleton,
        wrapped  => 1,
    ),
];

our $list_of_object_property_reference_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $object_property_reference_skeleton,
    ),
];

our $device_object_property_reference_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'object_identifier',
        dt   => $object_identifier_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag          => 1,
        name         => 'property_identifier',
        dt           => $enum_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'property_array_index',
        dt   => $unsigned_int_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 3,
        name => 'device_identifier',
        dt   => $object_identifier_string,
    ),
];

our $list_of_device_object_property_reference_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $device_object_property_reference_skeleton,
    ),
];

our $list_of_object_identifier_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt => $object_identifier_string,
    ),
];

our $list_of_unsigned_int_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string,
    ),
];

our $recipient_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag => 0,
        dt  => $object_identifier_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag      => 1,
        dt       => $sequence_value_string,
        skeleton => $address_skeleton,
    ),
];

our $destination_skeleton = [
    BACnet::DataTypes::Bone->construct(
        name => 'valid_days',
        dt   => $bit_string_string,
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'from_time',
        dt   => $time_string,
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'to_time',
        dt   => $time_string,
    ),
    BACnet::DataTypes::Bone->construct(
        name     => 'recipient',
        dt       => $choice_string,
        skeleton => $recipient_skeleton,
        wrapped  => 1,
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'process_identifier',
        dt   => $unsigned_int_string,
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'issue_confirmed_notification',
        dt   => $bool_string,
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'transition',
        dt   => $bit_string_string,
    ),
];

our $scale_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag => 0,
        dt  => $real_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 1,
        dt  => $int_string,
    ),
];

our $set_point_reference = [
    BACnet::DataTypes::Bone->construct(
        tag      => 0,
        dt       => $sequence_value_string,
        skeleton => $object_property_reference_skeleton,
    ),
];

our $device_object_reference_skeleton = [
    BACnet::DataTypes::Bone->construct(
        name => 'device_identifier',
        tag  => 0,
        dt   => $object_identifier_string,
    ),
    BACnet::DataTypes::Bone->construct(
        name => 'object_identifier',
        tag  => 1,
        dt   => $object_identifier_string,
    ),
];

our $list_of_device_object_reference_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $device_object_reference_skeleton,
    ),
];

our $property_value_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag          => 0,
        name         => 'property_identifier',
        dt           => $enum_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'property_array_index',
        dt   => $unsigned_int_string,
    ),
    BACnet::DataTypes::Bone->construct(
        tag          => 2,
        name         => 'value',
        dt           => 'property_identifier',
        substitution => "default",
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 3,
        name => 'priority',
        dt   => $unsigned_int_string,
    ),
];

our $list_of_property_value_skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $property_value_skeleton,
    ),
];

our $prop_type_type = {
    175 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    0 => BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    ),
    1 => BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    ),
    2 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_action_list_skeleton
    ),
    176 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    9 => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    11 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    12 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    13 => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    124 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    125 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    126 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    19 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $object_property_reference_skeleton
    ),
    20 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    21 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    177 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    178 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    179 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $date_time_skeleton
    ),
    155 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    23 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $calendar_entry_skeleton
    ),
    28 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    30 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_address_binding_skeleton
    ),
    32 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $date_range_skeleton
    ),
    35 => BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    ),
    83 => undef,
    36 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string,
    ),
    130 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_time_stamp_skeleton,
    ),
    37 => undef,
    41 => undef,
    42 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    43 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    44 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    47 => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    53 => undef,
    54 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_device_object_property_reference_skeleton,
    ),
    58 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    131 => undef,
    133 => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    60 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_object_property_reference_skeleton,
    ),
    135 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    62 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    65 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    136 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    160 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    70 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    71 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $date_time_skeleton,
    ),
    17 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    72 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    73 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    74 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    75 => BACnet::DataTypes::Bone->construct(
        dt => $object_identifier_string
    ),
    76 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_object_identifier_skeleton,
    ),
    77 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    78 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $device_object_property_reference_skeleton,
    ),
    79 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    161 => undef,
    81  => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    82 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    84 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    85 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    86 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_unsigned_int_skeleton,
    ),
    87 => undef,
    88 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    90 => undef,
    92 => undef,
    96 => BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    ),
    139 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    97 => BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    ),
    98 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    99 => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    102 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $destination_skeleton,
    ),
    141 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    103 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    104 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    187 => BACnet::DataTypes::Bone->construct(
        dt       => $choice_string,
        skeleton => $scale_skeleton,
        wrapped  => 1,
    ),
    188 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    174 => undef,
    107 => undef,
    108 => BACnet::DataTypes::Bone->construct(
        dt => $real_string
    ),
    109 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $set_point_reference,
    ),
    163 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    111 => BACnet::DataTypes::Bone->construct(
        dt => $bit_string_string
    ),
    144 => BACnet::DataTypes::Bone->construct(
        dt => $bool_string
    ),
    112 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    145 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    117 => BACnet::DataTypes::Bone->construct(
        dt => $enum_string
    ),
    189 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_value_string,
        skeleton => $date_time_skeleton,
    ),
    146 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    121 => BACnet::DataTypes::Bone->construct(
        dt => $char_string_string
    ),
    120 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    147 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    148 => BACnet::DataTypes::Bone->construct(
        dt => $unsigned_int_string
    ),
    165 => BACnet::DataTypes::Bone->construct(
        dt       => $sequence_of_values_string,
        skeleton => $list_of_device_object_reference_skeleton,
    ),
};

1;
