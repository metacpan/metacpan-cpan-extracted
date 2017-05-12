package Class::DBI::FormBuilder::Plugin::Time::Piece;
use strict;
use warnings;

our $VERSION = '0.1';

my %rx = (
	date		=>	'/^(?:|\d{4}-\d\d-\d\d)$/',
	time		=>	'/^(?:|\d\d:\d\d:\d\d)$/',
	datetime	=>	'/^(?:|\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)$/',
	timestamp	=>	'//', #'/^(?:|\d{14})$/',
);

sub field {
	my($class,$cdbifb,$them,$form,$field) = @_;
	
	# for certain CDBI::FB versions
	$field = $field->name if UNIVERSAL::isa($field,'Class::DBI::Column');

	my $type = $cdbifb->table_meta($them)->column($field)->type;

	my %args = (
		name		=> $field,
		value		=> '',
		required	=>	0,
		validate	=>	'//',
	);

	# called as a class method
	# no data; create empty field
	unless(ref $them) {
		$args{validate} = $rx{$type};
		return $form->field(%args);
	}

	my $value = do {
		no warnings 'uninitialized';
		$them->$field.''; # lousy default
	};
	my $validate = undef;
	if($type =~ /\btime\b/) {
		$args{value} =	UNIVERSAL::can($them->$field,'hms') ? $them->$field->hms : '';
	} elsif($type =~ /date\b/) {
		$args{value} =	UNIVERSAL::can($them->$field,'ymd') ? $them->$field->ymd : '';
	} elsif($type =~ /timestamp\b/) {
		$args{value} =	UNIVERSAL::can($them->$field,'strftime')
						? $them->$field->strftime('%Y%m%d%H%M%S')
						: '';
		$args{readonly} = 1; # no update of timestamps
	} elsif($type =~ /datetime\b/) {
		$args{value} =	UNIVERSAL::can($them->$field,'strftime')
						? $them->$field->strftime('%Y-%m-%d %H:%M:%S')
						: '';
	} else {
		die "don't understand column type '$type'";
	}

	$form->field(%args);
}


1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::DBI::FormBuilder::Plugin::Time::Piece - Output Dates/Times Properly

=head1 SYNOPSIS

  Class::DBI::FormBuilder::Plugin::Time::Piece-E<gt>require;
  my $ok = Class::DBI::FormBuilder::Plugin::Time::Piece-E<gt>field($obj,$form,$column);

=head1 DESCRIPTION

This module is loaded implicitly by CDBI::FormBuilder E<lt>= 0.32, when it encounters
a Time::Piece object as a has_a field within a Class::DBI object/class. When that happens,
Class::DBI::FormBuilder::Plugin::Time::Piece-E<gt>field($obj,$form,$column) is called.

=head2 my $ok = $class-E<gt>field($obj,$form,$column)

This routine will accept the object for which a form is being created,
the CGI::FormBuilder object we're working with, and the field in question. field() is
then expected to call (and return the return value of) $form-E<gt>field(%args). As a result, a
text field will be created within the form.

At this point, CDBI::FB::Plugin::Time::Piece serializes itself based upon MySQL
types. Patches are most welcome!

=head1 WARNING

We call column_type() on $obj, so it must be a Class::DBI::mysql object, or 
it needs to have used Class::DBI::Plugin::Type.

=head1 SEE ALSO

Class::DBI, CGI::FormBuilder, Class::DBI::FormBuilder

=head1 AUTHOR

James Tolley, E<lt>james@bitperfect.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by James Tolley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
