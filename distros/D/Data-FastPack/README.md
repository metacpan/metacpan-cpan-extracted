# NAME 

Data::FastPack - FastPack Record format, parsing and serialising module

# DESCRIPTION 

Implements an incremental parser to parse an incoming buffer into messages.
Provides basic encoding and decoding functions.

# FASTPACK FORMAT SUMMARY

FastPack format is a binary format for storing records of opaque data related
to a time index into a stream, padded to a multiple of 89 bytes. Within each
stream of data, an ID refers to a channel of data. All multi byte fields are in
little endian byte order processing unless otherwise indicated by the
description/metadata. The fields
of a message are:

```
time(double float)  # 8 byte aligned
id(32)              # uint32
len(32)                   # uint32
payload               bytes     # 8 byte aligned
padding (as required)

```

`time` is the absolute time of the sample or the difference in time from the
current message to the previous message in the same stream. The exact meaning
of the time is as per the definition messages. It is a double float to allow web
browsers to utilise high resolution time, as they do not support 64bit integers.

`id` is is the channel id within the file/stream. It relates to a definition
file. 0 indicates a meta data point which is JSON or other structured data,
which alters the processing of the file. 

`len` is the length of the payload. If the length is larger than 2^32 then it
must be fragmented at the 'application level'.

`payload` is the data.

`padding` Every record is padded to an 8 byte bounadary, with nulls, if nessicary

# CONCEPTS 

The message format is primarily intended to store a sequence of time indexed
values which are to be parameterized to another channel.  For example indexing
a sensor to position where both the sensor and the position are sampled
separately, but can be stored with the same time base.

There is only one reserved channel id, 0 , which is a meta data channel. This
channel is JSON or message pack, and provides the meta/header data to control
the stream from that point forward.

The meta data semantics are application dependant, giving great flexibility, in
time base, channel relationships etc

- Efficient use of memory access for ARM cpus

    Multi byte data types are stored in little endian order, unless otherwise
    specified in the meta data. Payloads are also on a 8 byte boundary allows
    direct access for double precision float

- Messages stored in one or more files

    Multiple streams of message can be stored in a single file if they share a time
    base. For streams that have differing time bases, they are stored in a separate
    files. This give good compression ability

- External defintition file(s) for message types if required.

    The definitions of a file can be pointed to externally, or can be stored
    internally in a meta data message

- Highly compresssable and suitable for self contained web applications

    The message time, id, length fields will be mostly unchanging when multiple
    message source of same time base are recorded together. The 24 byte header will
    basically be reduced to 1 or 2 bytes after compression for most messages.

## Timimg

Timing data is a double float field and can represent many different timing
scenarios.

- Direct time (seconds)

    The simplest case is the storing seconds as floating point values in the field.
    Whether the value is a difference to the previous message or an absolute value
    is based on definition messages for the file.

- Multiple of a time base

    Similar to direct time above, however the value is multiplied by an external
    time base factor to generate the actual time.

- Argument/index into a timing function.

    The value is used as an index into a timing function stored in external
    JavaScript, which when called calculates a time. ie for processing video with
    fixed non integer frame rates

For a system reporting only a single message, the time field will constantly be
updated for each message. However with multiple channels (eg, gamma, caliper,
lsd, ssd), only the first message from the group will have a non zero time when
using difference mode.  Most messages in a system will have a 0 time because of
this. 

## Padding

Padding to an 8 byte boundary is implicit to every message.  Arbitrary bytes
can be appended to ensure the alignment.

## Payload Length

A 32 bit field indicating the length of the data in the payload. It is stored
just before the payload to allow more efficient decoding in scripting languages

## Payload

The payload of the message. It is 8 byte aligned for better memory access (ie a
double can extracted directly out of the payload field)

# META AND STRUCTURED DATA

All message ids of 0 are designated "Meta Data". This means the
payload is encoded either in a JSON array or object or as a MessagePack
structure

This gives the fast encoding/decoding of simple time series values and the
ability to have arbitrarily complex data when required

Decoding of meta data automatically picks MesagePack or JSON as required,
as long as the encoded values are are map or array types.

It is recommended that general structured data in other message ids also either
JSON or MessagePack also.
