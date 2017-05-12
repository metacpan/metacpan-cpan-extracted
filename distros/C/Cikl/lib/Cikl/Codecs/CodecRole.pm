package Cikl::Codecs::CodecRole;
use strict;
use warnings;

use Mouse::Role;
use namespace::autoclean;

requires 'content_type';

requires 'encode_event';
requires 'decode_event';

1;
