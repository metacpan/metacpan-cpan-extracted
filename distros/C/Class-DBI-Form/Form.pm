package Class::DBI::Form;

use 5.006;

use strict;
use warnings;

use base 'Exporter';

use Class::DBI::Plugin::Type ();
use HTML::Tag;
use Tie::IxHash;
use URI::Escape;

our @EXPORT    = qw( to_cgi to_field _to_SELECT _to_generic _to_LOOKUP
	type_of primary_key_value);
our $VERSION = '00.03';

=head1 NAME

=head2 to_cgi

This returns a hash mapping all the column names of the class to
HTML::Element objects representing form widgets.

=cut

sub to_cgi {
	my $class 			= shift;
	my $values			= shift;
	my $force_type 	= shift;
	map { $_ => $class->to_field($_,$values->{$_},$force_type->{$_}) } 
		($class->columns,$class->columns('TEMP'));
}

=head2 to_field($field [, $how])

This maps an individual column to a form element. The C<how> argument
can be used to force the field type into one of C<textfield>, C<textarea>
or C<select>; you can use this is you want to avoid the automatic detection
of has-a relationships.

=cut

sub to_field {
	my ($self, $field, $value, $how) = @_;
	my $class = ref $self || $self;
	if ($how) {
		my $element = ref $how ? $how->{element} : $how;
		no strict 'refs';
		my $meth;
		if ($element eq 'LOOKUP') {
			$meth = "_to_$element";
			if (ref $how) {
				my $lhow = {};
				$lhow->{$_} = $how->{$_} for (qw/classdbi name key_col val_col selected maybenull/);
				delete $how->{$_} for (qw/element classdbi name key_col val_col selected maybenull/);
				return $self->$meth($field,$value,$lhow->{classdbi},$lhow->{name},
					$lhow->{key_col},$lhow->{val_col},$lhow->{selected},$lhow->{maybenull},$how);
			}
		} else {
			$meth = "_to_generic";
		}
		return $self->$meth($field,$value,$how);
	}
	my $hasa = $class->__hasa_rels->{$field};
	return $self->_to_LOOKUP($field, $value,$hasa->[0])
		if defined $hasa
		and $hasa->[0]->isa("Class::DBI");

	# Right, have some of this!
	eval "package $class; Class::DBI::Plugin::Type->import()";
	my $type = $class->column_type($field);
	return $self->_to_generic($field,$value,'TEXTAREA')
		if $type
		and $type =~ /^(TEXT|BLOB)$/i;
	return $self->_to_generic($field,$value,'TEXTFIELD');
}

sub _to_generic {
	my ($self, $col, $value,$how) = @_;
	my $element = ref $how ? $how->{element} : $how;
	my %opts		= ref $how ? %$how  : ();
	my $a = HTML::Tag->new(element=>$element, name => $col,%opts, id => $col);
	eval {$a->selected}; 	# workaround perche' in alcuni casi
												# $a->can... non funzionava anche se 
												# selected esisteva
	if (defined($value) && "$value" ne '' && $a->can('selected')) {
		$a->selected("$value") ;
	} else {
		$a->value($value) if (defined $value && "$value" ne '');
	}
	return $a;
}

sub _to_LOOKUP {
	my ($self, $col, $value) = (shift,shift,shift);
	my $has_a_class = shift || $self->__hasa_rels->{$col}->[0];
	my $name				= shift || $col;
	my $key_col			= shift || 'id';
	my $val_col			= shift || $key_col;
	my $selected		= shift;
	my $maybenull		= shift; $maybenull = 1 unless (defined $maybenull);
	my $how					= shift || {};
	#my $sel
	eval "require $has_a_class" unless (exists $INC{$has_a_class});
	die ($@) if ($@);
	my @objs        = $has_a_class->retrieve_all;
	my $a           = HTML::Tag->new(element=>'SELECT', name => $name, 
		maybenull => $maybenull,%$how,id => $name);
	tie my %values,'Tie::IxHash';
	for (@objs) {
		$values{$_->$key_col} = $_->$val_col;
	}
	if ("$value" eq '') {
		$a->selected($selected) if ($selected);
	} else {
		$a->selected("$value");
	}
	$a->value(\%values);
	return $a;
}

sub primary_key_value {
	my $self	= shift;
	my $ret		= '';
	my @pk		= $self->primary_column;
	foreach (@pk) {
		$ret .= uri_escape($_) . "=" . uri_escape($self->$_) . "&";
	}
	$ret =~ s/\&$//;
	return $ret;
}

1;

# vim: set ts=2:
