#!perl
#
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use Test::More tests => 1;
use warnings;
use strict;

use Comedi::Lib;

my @subs = qw(
   close
   open
   loglevel
   perror
   strerror
   errno
   fileno
   get_n_subdevices
   get_version_code
   get_driver_name
   get_board_name
   get_subdevice_type
   find_subdevice_by_type
   get_read_subdevice
   get_write_subdevice
   get_subdevice_flags
   get_n_channels
   range_is_chan_specific
   maxdata_is_chan_specific
   get_maxdata
   get_n_ranges
   get_range
   find_range
   get_buffer_size
   get_max_buffer_size
   set_buffer_size
   do_insnlist
   do_insn
   lock
   unlock
   data_read
   data_read_delayed
   data_read_hint
   data_write
   dio_config
   dio_get_config
   dio_read
   dio_write
   dio_bitfield2
   get_cmd_src_mask
   get_cmd_generic_timed
   cancel
   command
   command_test
   poll
   set_max_buffer_size
   get_buffer_contents
   mark_buffer_read
   mark_buffer_written
   get_buffer_offset
);

can_ok('Comedi::Lib', @subs);
