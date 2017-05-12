package App::Office::CMS::View::Base;

use Any::Moose;
use common::sense;

use Lingua::EN::Inflect::Number 'to_S';

use Path::Class; # For file().

use Text::Xslate 'mark_raw';

extends 'App::Office::CMS::Database::Base';

has config =>
(
	is  => 'rw',
	isa => 'Any',
);

has form_action =>
(
	is  => 'rw',
	isa => 'Any',
);

has session =>
(
	is  => 'rw',
	isa => 'Any',
);

has templater =>
(
	is  => 'rw',
	isa => 'Text::Xslate',
);

has tmpl_path =>
(
	is  => 'rw',
	isa => 'Str',
);

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

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

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
