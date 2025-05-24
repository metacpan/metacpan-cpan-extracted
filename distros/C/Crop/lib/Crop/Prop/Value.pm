package Crop::Prop::Value;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Prop::Value
	Global value.
	
	The Value isn't linked to user-defined objects. Object have link to Value instead.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	id_prop         - id of prop <Crop::Prop>
	id_proptype     - id of prop type <Crop::Prop::Type>  ; fkey=propscale
	id_sys          - id of sys <Crop::Sys>               ; fkey=propscale
	proppart_n      - part number of complex value        ; fkey=propscale
	propscale_n     - propscale number <Crop::Prop::Scale>; fkey=propscale
	val_id_file     - real value for the file
	val_int         - real value for the integer
	val_string      - real value for the string
=cut
our %Attributes = (
	id_prop      => {key => 'extern'},
	id_proptype  => {mode => 'read', key => 'extern'},
	id_sys       => {key => 'extern'},
	proppart_n   => {key => 'extern'},
	propscale_n  => {key => 'extern'},
	val_id_file  => {mode => 'read'},
	val_int      => {mode => 'read'},
	val_string   => {mode => 'read'},
);

sub Table { 'val' }

1;
