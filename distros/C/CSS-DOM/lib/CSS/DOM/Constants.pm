package CSS::DOM::Constants;

$VERSION = '0.17';

use Exporter 5.57 'import';

my $exception_constants;
use constant 1.03 $exception_constants = {
# DOMException:
	INDEX_SIZE_ERR              => 1,
	DOMSTRING_SIZE_ERR          => 2,
	HIERARCHY_REQUEST_ERR       => 3,
	WRONG_DOCUMENT_ERR          => 4,
	INVALID_CHARACTER_ERR       => 5,
	NO_DATA_ALLOWED_ERR         => 6,
	NO_MODIFICATION_ALLOWED_ERR => 7,
	NOT_FOUND_ERR               => 8,
	NOT_SUPPORTED_ERR           => 9,
	INUSE_ATTRIBUTE_ERR         => 10,
	INVALID_STATE_ERR           => 11,
	SYNTAX_ERR                  => 12,
	INVALID_MODIFICATION_ERR    => 13,
	NAMESPACE_ERR               => 14,
	INVALID_ACCESS_ERR          => 15,

## EventException:
#	UNSPECIFIED_EVENT_TYPE_ERR => 0,


};

my @rule_constants;
use constant do {
	my $x = 0;
	+{ map +($_ => $x++), @rule_constants = qw/
		UNKNOWN_RULE  
		STYLE_RULE    
		CHARSET_RULE  
		IMPORT_RULE   
		MEDIA_RULE    
		FONT_FACE_RULE
		PAGE_RULE
	 / }
};

my @val_constants;
use constant do {
	my $x = 0;
	+{ map +($_ => $x++), @val_constants = qw/
		CSS_INHERIT        
		CSS_PRIMITIVE_VALUE
		CSS_VALUE_LIST     
		CSS_CUSTOM         
	  /}
};

my @prim_constants;
use constant do {
	my $x = 0;
	+{ map +($_ => $x++), @ prim_constants = qw/
		CSS_UNKNOWN    
		CSS_NUMBER     
		CSS_PERCENTAGE 
		CSS_EMS        
		CSS_EXS        
		CSS_PX         
		CSS_CM         
		CSS_MM         
		CSS_IN         
		CSS_PT         
		CSS_PC         
		CSS_DEG        
		CSS_RAD        
		CSS_GRAD       
		CSS_MS         
		CSS_S          
		CSS_HZ         
		CSS_KHZ        
		CSS_DIMENSION  
		CSS_STRING     
		CSS_URI        
		CSS_IDENT      
		CSS_ATTR       
		CSS_COUNTER    
		CSS_RECT       
		CSS_RGBCOLOR   
	  /}
};

our %EXPORT_TAGS = (
 exception => [keys %$exception_constants],
 rule => \@rule_constants,
 value => \@val_constants,
 primitive => \@prim_constants,
);
our @EXPORT_OK = ('%SuffixToConst', map @$_, values %EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

{package
CSS::DOM::Exception;
CSS::DOM::Constants->import(':exception');
package
CSS::DOM::Rule;
CSS::DOM::Constants->import(':rule');
package
CSS::DOM::Value;
CSS::DOM::Constants->import(':value');
package
CSS::DOM::Value::Primitive;
CSS::DOM::Constants->import(':primitive');
}

%SuffixToConst = ( # dimension suffix -> CSSPrimitiveValue type constant
	'em' => CSS_EMS,
	'ex' => CSS_EXS,
	'px' => CSS_PX,
	'cm' => CSS_CM,
	'mm' => CSS_MM,
	'in' => CSS_IN,
	'pt' => CSS_PT,
	'pc' => CSS_PC,
	 deg => CSS_DEG,
	 rad => CSS_RAD,
	grad => CSS_GRAD,
	'ms' => CSS_MS,
	's'  => CSS_S,
	'hz' => CSS_HZ,
	 khz => CSS_KHZ,
);

                              !()__END__()!

=head1 NAME

CSS::DOM::Constants - Constants for CSS::DOM

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  use CSS::DOM::Constants ':all';
  
  # or
  
  use CSS::DOM::Constants ':rule';
  
  # or individually
  
  use CSS::DOM::Constants 'SYNTAX_ERR', ...;

=head1 DESCRIPTION

This module provides all the constants used by
L<CSS::DOM>.

=head1 EXPORTS

You can import individual constants by name, or all of them with the ':all'
tag. In addition, you can specify one of the following tags, to import a
group of constants (which can also be imported from other CSS::DOM 
modules):

=over

=item :exception

All the constants listed under L<CSS::DOM::Exception/EXPORTS>.

=item :rule

All the constants listed under L<CSS::DOM::Rule/EXPORTS>.

=item :value

All the constants listed under L<CSS::DOM::Value/CONSTANTS>.

=item :primitive

All the constants listed under L<CSS::DOM::Value::Primitive/CONSTANTS>.

=back

There is also a C<%SuffixToConst> hash which maps dimension suffixes (such
as 'px'; all lowercase) to CSSPrimitiveValue type constants (such as
C<CSS_PX>). This is included in the
':all' tag.

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Exception>

L<CSS::DOM::Rule>
