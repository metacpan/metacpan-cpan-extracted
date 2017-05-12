package Data::v;

use warnings;
use strict;

use Carp;
use Scalar::Util 'blessed';
use List::MoreUtils 'any';

our $VERSION = '0.03';

use base 'Data::Header::Fields';

our %v_types = (
	'VCARD' => 'Data::v::Card',
);

sub new {
	my $class = shift;
	return $class->SUPER::new(
		tight_folding => 1,
		key_cmp       => \&default_key_cmp,
		parent        => $class->_default_parent,
		@_,
	);
}

sub default_key_cmp {
	my $a = shift;
	my $b = shift;
	
	$a = lc $a;
	$b = lc $b;
	
	return 0
		if $b =~ qr{^$a (?: ; | $)}xms;
	
	return $a cmp $b;
}

sub decode {
	my $self = shift;
	my $any  = shift;
	
	my $return_self = ref $self;
	$self = $self->new()
		if not ref $self;

	my $dhf = $self->SUPER::decode($any);
	my $lines = $dhf->_lines;
	
	my @v_entries;
	my $v_type;
	while (my $line = shift @{$lines}) {
		if ($line->key eq 'BEGIN') {
			$v_type = $line->value->as_string;
			croak 'unknown v-type "'.$v_type.'"'
				if not $v_types{$v_type};
			
			my $v_data = $v_types{$v_type}->new();
			my $v_entry = ($v_types{$v_type}.'::Entry')->new(
				'key'           => $v_type,
				'value'         => $v_data,
				'parent'        => $self,
			);
			$v_data->parent($v_entry);
			push @v_entries, $v_entry;
			next;
		}
		elsif ($line->key eq 'END') {
			croak 'BEGIN and END mismatch "'.$v_type.'" ne "'.$line->value->as_string.'"'
				if $v_type ne $line->value->as_string;
			
			$v_type = undef;
			next;
		}
		
		push @{$v_entries[-1]->value->_lines}, $line;
	}
		
	foreach my $v_entry (@v_entries) {
		$v_entry->value->rebless_lines;
	}
	
	if (not $return_self) {
		return \@v_entries;
	}

	$dhf->_lines(\@v_entries);
	return $dhf;	
}

sub _read_lines {
	my $self = shift;
	my $any  = shift;
	
	my $fh = IO::Any->read($any);
	
	# put folded lines to an array http://tools.ietf.org/html/rfc2822#section-2.2.3
	my @lines;
	my $quoted_printable = 0;
	while (my $line = <$fh>) {
		# folded line
		if (($line =~ m/^\s/xms) or ($quoted_printable and ($lines[-1] =~ m/ = \r? \Z /xms))) {
			# ignore if the first line starts with white space
			next if not @lines;
			
			$lines[-1] .= $line;
			next;
		}
		
		# detect quoted-printable encoding which continues on a next lines when the line ends with "="
		my ($key, $value) = split(/:/, $line, 2);
		my @key_parts = split(/;/, $key);
		shift @key_parts;
		$quoted_printable = (any { $_ eq 'encoding=quoted-printable' } map { lc $_; } @key_parts);
				
		push @lines, $line;
	}
	
	close $fh;

	return @lines;	
}

sub _default_parent {
	return 'Data::Header::Fields';
}

sub parent {
	my $self   = shift;
	$self->{'parent'} = shift
		if @_;
	
	return (ref $self ? $self->{'parent'} : $self->_default_parent);
}

1;

package Data::v::Card;

use base 'Data::v';

use List::MoreUtils 'any';
use Carp 'croak';

sub version { return $_[0]->get_value('version') || '2.1'; }

sub rebless_lines {
	my $self = shift;
	
	foreach my $line (@{$self->_lines}) {
		$line = Data::v::Card::Line->new(
			line   => $line,
			parent => $self,
		);
	}
}

sub _default_parent {
	return 'Data::v::Card::Entry';
}

sub line_ending {
	my $self = shift;
	return $self->parent->parent->line_ending(@_);
}

sub get_fields {
	my $self        = shift;
	my $field_name  = shift or croak 'field_name argument is mandatory';
	my $param_name  = shift;
	my $param_value = shift;
	
	my @fields = $self->SUPER::get_fields($field_name);
	if (defined $param_name) {
		@fields = 
			grep { any { lc $_->value eq $param_value } $_->get_key_params($param_name) }
			@fields
		;
	}
	
	return @fields;
}

1;


package Data::v::Card::Line;

use base 'Data::Header::Fields::Line';

use Carp 'croak';
use MIME::QuotedPrint 'encode_qp', 'decode_qp';
use MIME::Base64 'encode_base64', 'decode_base64';
use Encode ();
use List::MoreUtils 'none';

use overload
	'""'  => \&as_string,
	'cmp' => \&Data::Header::Fields::Line::cmp,
;

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(
		@_,
	);
	$self->_decode_key_params;
	return $self;
}

sub version { return $_[0]->parent->version; }

sub params {
	my $self = shift;
	
	if (@_) {
		$self->{params} = shift;
	}
	$self->{params} = []
		if (not $self->{params});
	
	return $self->{params};
}

sub _decode_key_params {
	my $self = shift;
	
	my $key = $self->key;
	
	if ($key =~ m/^([^;]+);(.+)$/xms) {
		my $orig_key_name  = $1;
		my @raw_key_params = split /;/, $2;
		my @key_params;
		
		my $key_name = lc $orig_key_name;

		foreach my $key_param (@raw_key_params) {
			croak 'unknown key param "'.$key_param.'"'
				if $key_param !~ m/^ (?: ([^=]+) = )? (.+) $/xms;
			my $param_name = $1 || 'TYPE';
			my $param_str  = $2;
			
			push
				@key_params,
					map { Data::v::Param->new('name' => $param_name, 'value' => $_, 'parent' => $self) }
					(split(/,/, $param_str))
			;
		}
		
		$self->key($orig_key_name);
		$self->params(\@key_params);
		
		my $enc_type   = lc ($self->get_key_param_value('encoding') || '');
		if ($enc_type) {
			if ($enc_type eq 'quoted-printable') {
				$self->{value} = Data::Header::Fields::Value->new(
					decode_qp($self->{value})
				);
			}
			elsif ($enc_type eq 'base64') {
				$self->{value} = Data::Header::Fields::Value->new(
					decode_base64($self->{value})
				);
			}
			else {
				croak 'unknown encoding "'.$enc_type.'"';
			}
		}

		my $charset = lc ($self->get_key_param_value('charset') || '');
		$charset ||= 'utf8'
			if (none { $_ eq $key_name } qw(photo logo sound key));

		if ($charset) {
			$self->{'value'} = Data::Header::Fields::Value->new(
				eval { Encode::decode($charset, $self->{'value'}) }
			);
		}
	}
	
	if ((lc $self->key eq 'n') and (not $self->key->isa('Data::v::Card::Value::Name'))) {
		$self->{'value'} = Data::v::Card::Value::Name->new(    # not calling value() because the set doesn't affect the content of the value
			'value' => $self->value,
			'parent' => $self,
		);
	}
	elsif ((lc $self->key eq 'adr') and (not $self->key->isa('Data::v::Card::Value::Adr'))) {
		$self->{'value'} = Data::v::Card::Value::Adr->new(     # not calling value() because the set doesn't affect the content of the value
			'value'  => $self->value,
			'parent' => $self,
		);
	}
	
	return;
}

sub get_key_params {
	my $self       = shift;
	my $param_name = shift or croak 'param param_name is mandatory';
	my $params     = $self->params;
	
	$param_name = lc $param_name;
	return grep { lc $_->{'name'} eq $param_name } @{$params};
}

sub get_key_param {
	my $self       = shift;
	my $param_name = shift or croak 'param param_name is mandatory';
	
	my @params = $self->get_key_params($param_name);
	croak 'more then one key param with name "'.$param_name.'"'
		if @params > 1;
	
	return $params[0];	
}

sub get_key_param_value {
	my $self       = shift;
	my $param_name = shift or croak 'param param_name is mandatory';
	
	my $param = $self->get_key_param($param_name);
	return undef if not $param;
	return $param->{'value'};
}

sub update_key_params {
	my $self        = shift;
	my $param_name  = shift or croak 'param param_name is mandatory';
	my $param_value = shift;
	
	# updating via array set
	if (ref $param_value) {
		my @new_params     = @{$param_value};
		
		# update existing
		foreach my $param (@{$self->params}) {
			$param->value(shift @new_params)    # will returns undefs if depleeted
				if ($param->name eq $param_name);
		}
		
		# add any additional new
		foreach my $add_value (@new_params) {
			push @{$self->{params}}, Data::v::Param->new(
				'parent' => $self,
				'name'   => $param_name,
				'value'  => $add_value,
			);
		}
		
		# remove any additional old
		$self->{params} = [
			grep { defined $_->{'value'} }
			@{$self->{params}}
		];
		return $self;
	}

	my @params = (
		map {
			($_->{'name'} eq $param_name ? $_->{value} = $param_value : ());
			$_;
		} @{$self->params}
	);
	
	return $self;
}

sub set_key_param {
	my $self        = shift;
	my $param_name  = shift or croak 'param param_name is mandatory';
	my $param_value = shift;

	my @params = $self->get_key_params($param_name);
	if ((@params > 0) or (ref $param_value)) {
		$self->update_key_params($param_name, $param_value);
	}
	elsif (@params == 0) {
		push @{$self->params}, Data::v::Param->new('name' => $param_name, 'value' => $param_value, 'parent' => $self);
	}
	else { 
		croak 'more then one param field with name "'.$param_name.'"';
	}
	
	return $self;
}

sub rm_key_param {
	my $self        = shift;
	my $param_name  = shift or croak 'param param_name is mandatory';

	my @params = (
		grep {
			$_->name ne $param_name
		} @{$self->params}
	);
	$self->params(\@params);
	
	return $self;
}

sub _encode_key_params {
	my $self = shift;

	my $params = $self->params;
	return if scalar @{$params} == 0;
	my $key   = $self->key;

	my $charset = lc ($self->get_key_param_value('charset') || 'utf8');
	$self->{value} = eval { Encode::encode($charset, $self->{value}) };
	
	my $enc_type   = lc ($self->get_key_param_value('encoding') || '');
	if ($enc_type) {
		if ($enc_type eq 'quoted-printable') {
			$self->{value} = encode_qp($self->{value}, "");
		}
		elsif ($enc_type eq 'base64') {
			$self->{value} = encode_base64($self->{value}, "");
		}
		else {
			croak 'unknown encoding "'.$enc_type.'"';
		}
	}
	
	if ($self->version eq '2.1') {
		$key .= ';'.(
			join(
				';',
				(
					map  { $_->as_string }
					grep { defined $_->value }
					@{$params}
				),
			)
		);
	}
	elsif ($self->version ge '3.0') {
		my @types = map { $_->as_string } $self->get_key_params('type');
		$key .= ';'.(
			join(
				';',
				(
					map {
						(lc $_->name eq 'type')
						? ( @types ? ('TYPE='.join(',',splice(@types,0,scalar @types))) : () )
						: $_->as_string
					}
					grep { defined $_->value }
					@{$params}
				),
			)
		);
	}
	else {
		croak 'unsupported VCARD version '.$self->version;
	}
	
	$self->params(undef);
	$self->key($key);
	
	return;
}

sub as_string {
	my $self = shift;
	
	if (exists $self->{'original_line'}) {
		my $original_line = $self->{'original_line'};
		
		# make sure the line has line_ending, even the original one could be created without using ->new()
		$original_line .= $self->parent->line_ending
			if $original_line !~ m/ \n \Z /xms;
		
		return $original_line;
	}

	$self->_encode_key_params;

	my ($key, $value) = ($self->key, $self->value);
	#$value = String::Escape::printable($value);
	# FIXME ^^^ should be moved to _encode_key_params

	my $line = join(':', $key, $value);
	
	$line .= $self->parent->line_ending
		if $line !~ m/\n$/xms;

	$self->_decode_key_params;
	
	return $line;
}

1;

package Data::v::Card::Entry;

use base 'Data::Header::Fields::Line';

use overload
	'""'  => \&as_string,
	'cmp' => \&Data::Header::Fields::Line::cmp,
;

sub as_string {
	my $self = shift;

	return
		'BEGIN:VCARD'.$self->parent->line_ending
		.$self->value->as_string()
		.'END:VCARD'.$self->parent->line_ending
	;
}

1;

package Data::v::Card::Value::Name;

use base 'Data::Header::Fields::Value';

our @NAME_PART_TYPES = qw{family_name given_name additional_names honorific_prefixes honorific_suffixes};

use overload
	'""'  => \&Data::Header::Fields::Value::as_string,
	'cmp' => \&Data::Header::Fields::Value::cmp,
;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	defined $self->{'value'}
	? $self->_parse_value()
	: $self->_update_value();
	
	return $self;
}

sub _update_value {
	my $self = shift;
	
	my @name_parts = map { $self->$_() } @NAME_PART_TYPES;
	# remove the undef fields from the end of the N
	while ((@name_parts) and (not defined $name_parts[-1])) {
		pop @name_parts;
	}
	@name_parts = map { defined $_ ? $_ : '' } @name_parts;
	
	$self->value(join(';', @name_parts));
	
	return $self;
}

sub _parse_value {
	my $self = shift;
	
	my $name_str = $self->{'value'};
	my @name_parts = split(/;/, $name_str);
	
	foreach my $name_part_type (@NAME_PART_TYPES) {
		my $name_part_value = shift @name_parts;
		$self->{$name_part_type} = $name_part_value;
	}
	
	return $self;
}

sub family_name {
	my $self   = shift;	
	
	if (@_) {
		$self->{'family_name'} = shift;
		$self->_update_value();
	}
	return $self->{'family_name'};
}
sub given_name {
	my $self   = shift;	
	if (@_) {
		$self->{'given_name'} = shift;
		$self->_update_value();
	}
	return $self->{'given_name'};
}
sub additional_names {
	my $self   = shift;	
	if (@_) {
		$self->{'additional_names'} = shift;
		$self->_update_value();
	}
	return $self->{'additional_names'};
}
sub honorific_prefixes {
	my $self   = shift;	
	if (@_) {
		$self->{'honorific_prefixes'} = shift;
		$self->_update_value();
	}
	return $self->{'honorific_prefixes'};
}
sub honorific_suffixes {
	my $self   = shift;	
	if (@_) {
		$self->{'honorific_suffixes'} = shift;
		$self->_update_value();
	}
	return $self->{'honorific_suffixes'};
}

1;

package Data::v::Card::Value::Adr;

use base 'Data::Header::Fields::Value';

our @ADR_PART_TYPES = qw{po_box ext_address street city state postal_code country};

use overload
	'""'  => \&Data::Header::Fields::Value::as_string,
	'cmp' => \&Data::Header::Fields::Value::cmp,
;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	defined $self->{'value'}
	? $self->_parse_value()
	: $self->_update_value();
	
	return $self;
}

sub _update_value {
	my $self = shift;

	my @adr_parts = map { $self->$_() } @ADR_PART_TYPES;
	# remove the undef fields from the end of the N
	while ((@adr_parts) and (not defined $adr_parts[-1])) {
		pop @adr_parts;
	}
	@adr_parts = map { defined $_ ? $_ : '' } @adr_parts;
	
	$self->value(join(';', @adr_parts));
	
	return $self;
}

sub _parse_value {
	my $self = shift;
	
	my $adr_str = $self->{'value'};
	$adr_str =~ s/ \r? \n \Z//xms;
	my @adr_parts = split(/;/, $adr_str);
	
	foreach my $adr_part_type (@ADR_PART_TYPES) {
		my $adr_part_value = shift @adr_parts;		
		$self->{$adr_part_type} = $adr_part_value;
	}
	
	return $self;
}

sub po_box {
	my $self   = shift;

	if (@_) {
		$self->{'po_box'} = shift @_;
		$self->_update_value();
	}

	return $self->{'po_box'};
}
sub ext_address {
	my $self   = shift;	

	if (@_) {
		$self->{'ext_address'} = shift @_;
		$self->_update_value();
	}

	return $self->{'ext_address'};
}
sub street {
	my $self   = shift;	

	if (@_) {
		$self->{'street'} = shift @_;
		$self->_update_value();
	}

	return $self->{'street'};
}
sub city {
	my $self   = shift;	

	if (@_) {
		$self->{'city'} = shift @_;
		$self->_update_value();
	}

	return $self->{'city'};
}
sub state {
	my $self   = shift;	

	if (@_) {
		$self->{'state'} = shift @_;
		$self->_update_value();
	}

	return $self->{'state'};
}
sub postal_code {
	my $self   = shift;	

	if (@_) {
		$self->{'postal_code'} = shift @_;
		$self->_update_value();
	}

	return $self->{'postal_code'};
}
sub country {
	my $self   = shift;	

	if (@_) {
		$self->{'country'} = shift @_;
		$self->_update_value();
	}

	return $self->{'country'};
}

1;

package Data::v::Param;

use overload
	'""'  => \&as_string,
	'cmp' => \&Data::Header::Fields::Value::cmp,
;

sub new {
	my $class = shift;
	return bless {
		@_
	}, $class;
}

sub name {
	my $self   = shift;	

	$self->{'name'} = shift @_
		if (@_);

	return $self->{'name'};
}

sub value {
	my $self   = shift;	

	$self->{'value'} = shift @_
		if (@_);

	return $self->{'value'};
}

sub as_string {
	my $self   = shift;	
	
	return
		(lc $self->name eq 'type')
		? $self->value
		: $self->name.'='.$self->value
	;
}

1;

package Data::v::Calendar;

use base 'Data::v';

1;


__END__

=head1 NAME

=head1 SYNOPSIS

	use Data::v;

	my $vdata = Data::v->new->decode([ '..', 't', 'vcf', 'aldo.vcf' ]);
	my $vcard = $vdata->get_value('vcard');
	
	print 'version:   ', $vcard->get_value('version'), "\n";
	print 'full name: ', $vcard->get_value('fn'), "\n";
	print 'email:     ', $vcard->get_value('email'), "\n";
	
	my @cell_phones = $vcard->get_fields('tel');
	
	use List::MoreUtils 'any';
	my @cell_phones =
		map { $_->value->as_string }
		$vcard->get_fields('tel', 'type' => 'cell')
	;
	print 'cell:      ', join(', ', @cell_phones), "\n";
	
	print "\n";
	
	$vcard->set_value('email' => 'dada@internet');
	$vcard->rm_fields('rev', 'photo', 'adr', 'X-MS-OL-DEFAULT-POSTAL-ADDRESS', 'label');
	
	print $vdata->encode, "\n";

=head1 DESCRIPTION

=head1 SEE ALSO

L<http://tools.ietf.org/html/rfc2425> - A MIME Content-Type for Directory Information

L<http://tools.ietf.org/html/rfc2426> - vCard MIME Directory Profile

L<http://tools.ietf.org/html/rfc5545> - Internet Calendaring and Scheduling Core Object Specification (iCalendar)


=head1 AUTHOR

Jozef Kutej

=cut
