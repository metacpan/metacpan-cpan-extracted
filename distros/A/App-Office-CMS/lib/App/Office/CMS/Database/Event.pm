package App::Office::CMS::Database::Event;

use Any::Moose;
use common::sense;

use Date::Format;

extends 'App::Office::CMS::Database::Base';

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# --------------------------------------------------

sub add
{
	my($self, $action, $object) = @_;

	$self -> log(debug => "add($action, $$object{name})");

	$self -> save_event_record($action, $object);

	return "Saved event $action for object '$$object{name}'";

} # End of add.

# --------------------------------------------------

sub save_event_record
{
	my($self, $context, $object) = @_;

	$self -> log(debug => "save_event_record($context, $$object{name})");

	my($table_name) = 'events';
	my(@time)       = localtime;
	my($time)       = strftime('%Y-%m-%d %X', @time);
	my(@field)      = (qw/
event_type_id
id_list
/);
	my($data) = {};

	for (@field)
	{
		$$data{$_} = $$object{$_};
	}

	if ($context eq 'add')
	{
		$$data{timestamp} = $time;
		$$object{id}      = $self -> db -> insert_hash_get_id($table_name, $data);
	}
	else
	{
		die "save_event_record called with context not being 'add'";
	}

	$self -> log(debug => "Saved ($context) object '$$object{name}' with id $$data{id}");

} # End of save_event_record.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
