package App::Office::CMS::View::Base;

use strict;
use warnings;

use Lingua::EN::Inflect::Number 'to_S';

use Moo;

use Types::Standard qw/Any/;

use Text::Xslate 'mark_raw';

extends 'App::Office::CMS::Database::Base';

has config =>
(
	is  => 'rw',
	isa => Any,
);

has form_action =>
(
	is  => 'rw',
	isa => Any,
);

has session =>
(
	is  => 'rw',
	isa => Any,
);

has templater =>
(
	is  => 'rw',
	isa => Any, # 'Text::Xslate'.
);

our $VERSION = '0.93';

# -----------------------------------------------

sub build_select
{
	my($self, $class_name, $default) = @_;
	$default ||= 1;

	$self -> log(debug => "build_select($class_name, $default)");

	my($singular) = lc to_S($class_name);
	my($id_name)  = "${singular}_id";
	my($option)   = $self -> db -> get_id2name_map($class_name);

	return $self -> templater -> render
	(
	 'select.tx',
	 {
		 name => $id_name,
		 loop =>
			 [map
				  {
					  {
						  default => $_ == $default ? 1 : 0,
						  name    => $$option{$_},
						  value   => $_,
					  };
				  } sort{$$option{$a} cmp $$option{$b} } keys %$option
			 ],
	 }
	);

} # End of build_select.

# -----------------------------------------------

sub format_errors
{
	my($self, $error) = @_;
	my($param) =
	{
		data => [],
	};

	my($s);

	for my $key (sort keys %$error)
	{
		$s = "$key: " . join(', ', @{$$error{$key} });

		push @{$$param{data} }, {td => $s};

		$self -> log(debug => "Error. $s");
	}

	return $self -> templater -> render('error.tx', $param);

} # End of format_errors.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> db -> log($level, $s);

} # End of log.

# --------------------------------------------------

1;
