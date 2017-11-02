package App::Office::CMS::Util::Validator;

use strict;
use warnings;

use Brannigan;

use CGI::Untaint;

use Moo;

use Types::Standard qw/Any HashRef/;

extends 'App::Office::CMS::Database::Base';

has config =>
(
	is  => 'rw',
	isa => HashRef,
	required => 1,
);

has query =>
(
	is  => 'ro',
	isa => Any, # 'CGI'.
	required => 1,
);

our $VERSION = '0.93';

# -----------------------------------------------

sub clean_user_data
{
	my($data, $max_length) = @_;
	$max_length  ||= 255;
	my($integer) = 0;
	$data = '' if (! defined($data) || (length($data) == 0) || (length($data) > $max_length) );
	#$data = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i);	# http://www.perl.com/pub/a/2002/02/20/css.html.
	$data = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);		# Ditto, but much more strict.
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	$data = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

	return $data;

}	# End of clean_user_data.

# --------------------------------------------------
# Warning: This is a sub, not a method.

sub check_length
{
	my($value, $min_length, $max_length) = @_;
	my($length) = length $value;

	return ( ($length >= $min_length) && ($length <= $max_length) ) ? 1 : 0;

} # End of check_length.

# --------------------------------------------------

sub validate_content
{
	my($self) = @_;

	$self -> log(debug => 'validate_content()');

 	my($handler) = CGI::Untaint -> new(map{$_ => $self -> query -> param($_)} $self -> query -> param);
	my($data)    = {};

	my($key);

	for $key (qw/sid/)
	{
		$$data{$key} = $handler -> extract(-as_hex => $key);
	}

	for $key (qw/body_text head_text submit_update_content/)
	{
		$$data{$key} = $handler -> extract(-as_printable => $key);
	}

	my($max_content_length) = ${$self -> config}{max_content_length};
	my($validator)          = Brannigan -> new
	({
	 name   => 'validate_content',
	 params =>
	 {
		body_text =>
		{
			default        => '',
			length_between => [0, $max_content_length],
			required       => 0,
		},
		head_text =>
		{
			default        => '',
			length_between => [0, $max_content_length],
			required       => 0,
		},
		sid =>
		{
			exact_length => 32,
			required     => 1,
		},
		submit_update_content => # 'Save'.
		{
			exact_length => 4,
			required     => 0,
		},
	 },
	});

	return $validator -> process('validate_content', $data);

} # End of validate_content.

# --------------------------------------------------

sub validate_page
{
	my($self) = @_;

	$self -> log(debug => 'validate_page()');

 	my($handler) = CGI::Untaint -> new(map{$_ => $self -> query -> param($_)} $self -> query -> param);
	my($data)    = {};

	my($key);

	for $key (qw/action asset_type_id/)
	{
		$$data{$key} = $handler -> extract(-as_integer => $key);
	}

	for $key (qw/sid/)
	{
		$$data{$key} = $handler -> extract(-as_hex => $key);
	}

	for $key (qw/homepage name new_name submit_add_menu submit_delete_page submit_extend_menu_left submit_extend_menu_right submit_extend_submenu_down submit_extend_submenu_up submit_update_page/)
	{
		$$data{$key} = $handler -> extract(-as_printable => $key);
	}

	my($validator) = Brannigan -> new
	({
	 name   => 'validate_page',
	 params =>
	 {
		action =>
		{
			required      => 1,
			value_between => [1, 7],
		},
		asset_type_id => # Template type.
		{
			required      => 1,
			value_between => [1, 2],
		},
		homepage => # 'Yes' or ''.
		{
			default        => 'No',
			length_between => [0, 3],
			required       => 0,
		},
		name => # Page name.
		{
			length_between => [1, 255],
			required       => 1,
		},
		new_name => # New page name for duplication.
		{
			length_between => [1, 255],
			required       => 0,
		},
		sid =>
		{
			exact_length => 32,
			required     => 1,
		},
		submit_child => # 'Add page as a child of the current page'.
		{
			exact_length => 39,
			required     => 0,
		},
		submit_delete_page => # 'Delete current page'.
		{
			exact_length => 19,
			required     => 0,
		},
		submit_sibling_above => # 'Add page as a sibling above the current page'.
		{
			exact_length => 44,
			required     => 0,
		},
		submit_sibling_below => # 'Add page as a sibling below the current page'.
		{
			exact_length => 44,
			required     => 0,
		},
		submit_update_page => # 'Save'.
		{
			exact_length => 4,
			required     => 0,
		},
	 },
	});

	return $validator -> process('validate_page', $data);

} # End of validate_page.

# --------------------------------------------------

sub validate_site_and_design
{
	my($self) = @_;

	$self -> log(debug => 'validate_site_and_design()');

	my($handler) = CGI::Untaint -> new($self -> query -> Vars);
	my($data)    = {};

	my($key);

	for $key (qw/sid/)
	{
		$$data{$key} = $handler -> extract(-as_hex => $key);
	}

	for $key (qw/action menu_orientation_id os_type_id/)
	{
		$$data{$key} = $handler -> extract(-as_integer => $key);
	}

	for $key (qw/design_name name new_name output_directory output_doc_root submit_delete_design submit_delete_site submit_edit_page submit_new_site submit_update_site/)
	{
		$$data{$key} = $handler -> extract(-as_printable => $key);
	}

	my($validator) = Brannigan -> new
	({
	 name   => 'validate_site_and_design',
	 params =>
	 {
		action =>
		{
			required      => 1,
			value_between => [1, 6],
		},
		design_name =>
		{
			length_between => [1, 255],
			required       => 1,
		},
#		menu_orientation_id =>
#		{
#			required      => 1,
#			value_between => [1, 4],
#		},
#		os_type_id =>
#		{
#			required      => 1,
#			value_between => [1, 5],
#		},
		name => # Site name.
		{
			length_between => [1, 255],
			required       => 1,
		},
		new_name => # New site or design name for duplication.
		{
			length_between => [1, 255],
			required       => 0,
		},
		output_directory =>
		{
			length_between => [1, 255],
			required       => 1,
		},
		output_doc_root =>
		{
			length_between => [1, 255],
			required       => 1,
		},
		sid =>
		{
			length_between => [1, 32],
			required       => 1,
		},
		submit_delete_design => # 'Delete design'.
		{
			exact_length => 13,
			required     => 0,
		},
		submit_delete_site => # 'Delete site'.
		{
			exact_length => 11,
			required     => 0,
		},
		submit_duplicate_design => # 'Duplicate design'.
		{
			exact_length => 16,
			required     => 0,
		},
		submit_duplicate_site => # 'Duplicate site'.
		{
			exact_length => 14,
			required     => 0,
		},
		submit_edit_page => # 'Edit pages'.
		{
			exact_length => 10,
			required     => 0,
		},
		submit_new_site => # 'Save'.
		{
			exact_length => 4,
			required     => 0,
		},
		submit_update_site => # 'Save'.
		{
			exact_length => 4,
			required     => 0,
		},
	 },
	});

	return $validator -> process('validate_site_and_design', $data);

} # End of validate_site_and_design.

# --------------------------------------------------

1;
