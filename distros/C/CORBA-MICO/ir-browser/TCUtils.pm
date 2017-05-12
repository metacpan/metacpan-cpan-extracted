package TCUtils;
require Exporter;

use strict;

@TCUtils::ISA = qw(Exporter);
@TCUtils::EXPORT = qw(stringify_tc);

sub get_absname {
    my ($ir, $tc) = @_;

    my $id = $tc->id;
    if ($id ne "" && defined $ir) {
	my $ir_node = $ir->lookup_id ($id);
	if (defined $ir_node) {
	    my ($name) = $ir_node->_get_absolute_name =~ /:*(.*)/;
	    return $name;
	}
    }

    return undef;
}

sub string_simple {
    my ($ir, $tc) = @_;
    my $kind = $tc->kind;

    $kind =~ s/^tk_//;
    $kind =~ s/^u/unsigned /;
    $kind =~ s/long([a-z])/long $1/;

    $kind;
}

sub string_objref {
    my ($ir, $tc) = @_;

    my $absname = get_absname ($ir, $tc);
    return defined $absname ? $absname : "CORBA::Object";
}

sub string_struct {
    my ($ir, $tc, $leading) = @_;

    my $absname = get_absname ($ir, $tc);
    defined $absname and return $absname;

    my $result;
    if ($tc->kind eq 'tk_struct') {
	$result = "struct {\n";
    } else {
	$result = "exception {\n";
    }
    
    for my $i (0..$tc->member_count-1) {
	my $name = $tc->member_name($i);
	my $type = stringify_tc ($ir, $tc->member_type($i), "$leading    ");
	$result .= "$leading    $type $name\n";
    }
    return $result . "}";
}

sub string_union {
    my ($ir, $tc, $leading) = @_;

    my $absname = get_absname ($ir, $tc);
    defined $absname and return $absname;

    my $discriminator_tc = $tc->discriminator_type;
    my $default_idx = $tc->default_index;
    
    my $result = join ("", 
		       "union switch (",
		       stringify_typecode ($ir, $discriminator_tc),
		       ") {\n");
		      
    for my $i (0..$tc->member_count-1) {
	my $name = $tc->member_name($i);
	my $label = $tc->member_label($i);
	my $type = stringify_tc ($ir, $tc->member_type($i), "$leading    ");
	if ($i == $default_idx) {
	    $result .= "${leading}default:\n";
	} else {
	    $result .= "${leading}case $label:\n";
	    
	}
	$result .= "$leading    $type $name\n";
    }
    return $result . "}";
}

sub string_enum {
    my ($ir, $tc, $leading) = @_;

    my $absname = get_absname ($ir, $tc);
    defined $absname and return $absname;

    my $result = "enum {\n";
    
    for my $i (0..$tc->member_count-1) {
	if ($i != 0) {
	    $result .= ",\n";
	}
	$result .= "$leading    ".$tc->member_name($i);
    }
    return $result . "\n}";
}

sub string_string {
    my ($ir, $tc, $leading) = @_;

    my $result;
    if ($tc->kind eq 'tk_string') {
	$result = "string";
    } else {
	$result = "wstring";
    }

    if ($tc->length > 0) {
	$result .= "<".$tc->length.">";
    }

    return $result;
}

sub string_sequence {
    my ($ir, $tc, $leading) = @_;

    my $content = stringify_tc ($ir, $tc->content_type, "$leading    ");

    my $result = "sequence <$content";
    if ($tc->length > 0) {
	$result .= ", ".$tc->length;
    }
    $result .= ">";

    return $result;
}

sub string_array {
    my ($ir, $tc, $leading) = @_;

    my $content = stringify_tc ($ir, $tc->content_type, $leading);

    return  "$content\[".$tc->length."]";
}

sub string_alias {
    my ($ir, $tc, $leading) = @_;

    my $absname = get_absname ($ir, $tc);
    defined $absname and return $absname;

    return stringify_tc ($tc->content_type);
}

sub string_fixed {
    my ($ir, $tc, $leading) = @_;

    return "fixed<".$tc->fixed_digits.", ".$tc->fixed_scale.">";
}

my %string_funcs = (
		   tk_null =>       \&string_simple,
		   tk_void =>       \&string_simple,
		   tk_short =>      \&string_simple,
		   tk_long =>       \&string_simple,
		   tk_ushort =>     \&string_simple,
		   tk_ulong =>      \&string_simple,
		   tk_float =>      \&string_simple,
		   tk_double =>     \&string_simple,
		   tk_boolean =>    \&string_simple,
		   tk_char =>       \&string_simple,
		   tk_octet =>      \&string_simple,
		   tk_any =>        \&string_simple,
		   tk_TypeCode =>   \&string_simple,
		   tk_Principal =>  \&string_simple,
		   tk_objref =>     \&string_objref,
		   tk_struct =>     \&string_struct,
		   tk_union =>      \&string_union,
		   tk_enum =>       \&string_enum,
		   tk_string =>     \&string_string,
		   tk_sequence =>   \&string_sequence,
		   tk_array =>      \&string_array,
		   tk_alias =>      \&string_alias,
		   tk_except =>     \&string_struct,
		   tk_longlong =>   \&string_simple,
		   tk_ulonglong =>  \&string_simple,
		   tk_longdouble => \&string_simple,
		   tk_wchar =>      \&string_simple,
		   tk_wstring =>    \&string_string,
		   tk_fixed =>      \&string_fixed
		  );  

sub stringify_tc {
    my ($ir, $tc, $leading) = @_;
    defined $leading or $leading = "";

    my $kind = $tc->kind;

    if (exists $string_funcs{$kind}) {
	return $string_funcs{$kind}->($ir, $tc, $leading);
    } else {
	return undef;
    }
}
