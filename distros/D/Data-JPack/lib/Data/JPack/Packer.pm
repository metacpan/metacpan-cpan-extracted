package Data::JPack::Packer;
use strict;
use warnings;

use constant KEY_OFFSET=>0;
use enum ("byte_limit_=".KEY_OFFSET, qw<
	byte_size_
	message_limit_
	message_count_
	messages_
	html_root_
	html_container_
	jpack_
	jpack_options_
	write_threshold_
	ifh_
	out_fh_
	in_buffer_
	in_offset_
	out_buffer_
	out_offset_
	input_done_flag_
	jpack_flag_
	file_count_
	first_
	>);
use constant KEY_COUNT=>
sub new {
}

sub init {
}


sub close_output_file {
}


sub open_output_file {

}

sub pack_files {

}

1;
