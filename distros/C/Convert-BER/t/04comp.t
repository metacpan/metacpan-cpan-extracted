#!/usr/local/bin/perl

#
# Complex test
#

use Convert::BER;

print "1..1\n";

@data = (
         [
           0,
           {
             fred => 'joe'
           }
         ],
         [
           1,
           {
             beth => [
                       'jack',
                       'paul'
                     ]
           }
         ]
       );

$ber = new Convert::BER;

$ber->encode(
    SEQUENCE => [
	INTEGER    	=> 1,
	SEQUENCE_OF	=> [ \@data,

				# this sub will be called for each
				# element in the array @data
				# each element of @data is an array ref
				# of which the first element is a number

	    ENUM 	    => sub { $_[0]->[0] },

				# this sub will be called for each
				# element in the array @data
				# each element of @data is an array ref
				# of which the second element is a hashref

	    SEQUENCE_OF 	=> [ sub { $_[0]->[1] }, 

				# this sub will be called for each
				# key in the hashref returned by the sub above
				# $_[0] will be the hashref, $_[1] will
				# be the key being processed

		STRING		=> sub { $_[1] },
		SET 		=> [

				# Depending on whether the hashref entry
				# contains a scalar or an array ref will
				# determine how many strings are added

		    STRING 	    => sub { $_[0]->[1]{$_[1]} }
		]
	    ]
	]
    ]
);

my $result = pack("C*", 0x30, 0x30, 0x02, 0x01, 0x01, 0x30, 0x2B, 0x0A,
			0x01, 0x00, 0x30, 0x0D, 0x04, 0x04, 0x66, 0x72,
			0x65, 0x64, 0x31, 0x05, 0x04, 0x03, 0x6A, 0x6F,
			0x65, 0x0A, 0x01, 0x01, 0x30, 0x14, 0x04, 0x04,
			0x62, 0x65, 0x74, 0x68, 0x31, 0x0C, 0x04, 0x04,
			0x6A, 0x61, 0x63, 0x6B, 0x04, 0x04, 0x70, 0x61,
			0x75, 0x6C);

print "not "
    unless $ber->buffer eq $result;
print "ok 1\n";

