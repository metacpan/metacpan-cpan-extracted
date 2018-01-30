package CSS::DOM::Interface;

use Exporter 5.57 'import';
our $VERSION = '0.17';

require CSS::DOM::Constants;

=head1 NAME

CSS::DOM::Interface - A list of CSS::DOM's interface members in machine-readable format

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  use CSS::DOM::Interface ':all';

  # name of DOM interface (CSSStyleRule):
  $CSS::DOM::Interface{"CSS::DOM::Rule::Style"};
  
  # interface it inherits from (CSSRule):
  $CSS::DOM::Interface{CSSStyleRule}{_isa};
  
  # whether this can be used as an array
  $CSS::DOM::Interface{MediaList}{_array}; # true
  # or hash
  $CSS::DOM::Interface{MediaList}{_hash}; # false
  
  
  # Properties and Methods
  
  # list them all
  grep !/^_/, keys %{ $CSS::DOM::Interface{CSSStyleSheet} };
  
  # see whether a given property is supported
  exists $CSS::DOM::Interface{CSSStyleSheet}{foo}; # false
  
  # Is it a method?
  $CSS::DOM::Interface{CSSStyleSheet}{cssRules}   & METHOD; # false
  $CSS::DOM::Interface{CSSStyleSheet}{insertRule} & METHOD; # true
  
  # Does the method return nothing?
  $CSS::DOM::Interface{MediaList}{deleteMedium} & VOID; # true
  
  # Is a property read-only?
  $CSS::DOM::Interface{StyleSheetList}{length} & READONLY; # true
  
  # Data types of properties
  ($CSS::DOM::Interface{CSSStyleSheet}{type}      & TYPE)
                                                    == STR;  # true
  ($CSS::DOM::Interface{CSSStyleSheet}{disabled}  & TYPE)
                                                    == BOOL; # true
  ($CSS::DOM::Interface{CSSStyleSheet}{ownerNode} & TYPE)
                                                    == NUM;  # false
  ($CSS::DOM::Interface{CSSStyleSheet}{href}     & TYPE)
                                                    == OBJ;  # false
  
  # and return types of methods:
  ($CSS::DOM::Interface{MediaList}{item} & TYPE) == STR;  # true
  ($CSS::DOM::Interface{CSSMediaRule}
                          ->{insertRule} & TYPE) == BOOL; # false
  ($CSS::DOM::Interface{CSSStyleDeclaration}
                     ->{getPropertyVaue} & TYPE) == NUM;  # false
  ($CSS::DOM::Interface{CSSStyleDeclaration}
                      ->{removeProperty} & TYPE) == OBJ;  # false
  
  
  # Constants

  # list of constant names in the form "CSS::DOM::Node::STYLE_RULE";
  @{ $CSS::DOM::Interface{CSSRule}{_constants} };

=head1 DESCRIPTION

The synopsis should tell you almost everything you need to know. But be
warned that C<$foo & TYPE> is meaningless when C<$foo & METHOD> and
C<$foo & VOID> are both true. For more
gory details, look at the source code. In fact, here it is:

=cut

0 and q r

=for ;

  our @EXPORT_OK = qw/METHOD VOID READONLY BOOL STR NUM OBJ TYPE/;
  our %EXPORT_TAGS = (all => \@EXPORT_OK);

  sub METHOD   () {      1 }
  sub VOID     () {   0b10 } # for methods
  sub READONLY () {   0b10 } # for properties
  sub BOOL     () { 0b0000 }
  sub STR      () { 0b0100 }
  sub NUM      () { 0b1000 }
  sub OBJ      () { 0b1100 }
  sub TYPE     () { 0b1100 } # only for use as a mask

  %CSS::DOM::Interface = (
  	'CSS::DOM' => 'CSSStyleSheet',
  	'CSS::DOM::StyleSheetList' => 'StyleSheetList',
  	'CSS::DOM::MediaList' => 'MediaList',
  	'CSS::DOM::RuleList' => 'CSSRuleList',
  	'CSS::DOM::Rule' => 'CSSRule',
  	'CSS::DOM::Rule::Style' => 'CSSStyleRule',
  	'CSS::DOM::Rule::Media' => 'CSSMediaRule',
  	'CSS::DOM::Rule::FontFace' => 'CSSFontFaceRule',
  	'CSS::DOM::Rule::Page' => 'CSSPageRule',
  	'CSS::DOM::Rule::Import' => 'CSSImportRule',
  	'CSS::DOM::Rule::Charset' => 'CSSCharsetRule',
  	'CSS::DOM::Style' => 'CSSStyleDeclaration',
  	'CSS::DOM::Value' => 'CSSValue',
  	'CSS::DOM::Value::Primitive' => 'CSSPrimitiveValue',
  	'CSS::DOM::Value::List' => 'CSSValueList',
  	'CSS::DOM::Counter' => 'Counter',
  	 StyleSheetList => {
		_hash => 0,
		_array => 1,
  		length => NUM | READONLY,
  		item => METHOD | OBJ,
  	 },
  	 MediaList => {
		_hash => 0,
		_array => 1,
  		mediaText => STR,
  		length => NUM | READONLY,
  		item => METHOD | STR,
  		deleteMedium => METHOD | VOID,
  		appendMedium => METHOD | VOID,
  	 },
  	 CSSRuleList => {
		_hash => 0,
		_array => 1,
  		length => NUM | READONLY,
  		item => METHOD | OBJ,
  	 },
  	 CSSRule => {
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			CSS::DOM::Rule::UNKNOWN_RULE
  			CSS::DOM::Rule::STYLE_RULE
  			CSS::DOM::Rule::CHARSET_RULE
  			CSS::DOM::Rule::IMPORT_RULE
  			CSS::DOM::Rule::MEDIA_RULE
  			CSS::DOM::Rule::FONT_FACE_RULE
  			CSS::DOM::Rule::PAGE_RULE
  		]],
  		type => NUM | READONLY,
  		cssText => STR,
  		parentStyleSheet => OBJ | READONLY,
  		parentRule => OBJ | READONLY,
  	 },
  	 CSSStyleRule => {
		_isa => 'CSSRule',
		_hash => 0,
		_array => 0,
  		selectorText => STR,
  		style => OBJ | READONLY,
  	 },
  	 CSSMediaRule => {
		_isa => 'CSSRule',
		_hash => 0,
		_array => 0,
  		media => OBJ | READONLY,
  		cssRules => OBJ | READONLY,
  		insertRule => METHOD | NUM,
  		deleteRule => METHOD | VOID,
  	 },
  	 CSSFontFaceRule => {
		_isa => 'CSSRule',
		_hash => 0,
		_array => 0,
  		style => OBJ | READONLY,
  	 },
  	 CSSPageRule => {
		_isa => 'CSSRule',
		_hash => 0,
		_array => 0,
  		selectorText => STR,
  		style => OBJ | READONLY,
  	 },
  	 CSSImportRule => {
		_isa => 'CSSRule',
		_hash => 0,
		_array => 0,
  		href => STR | READONLY,
  		media => OBJ | READONLY,
  		styleSheet => OBJ | READONLY,
  	 },
  	 CSSCharsetRule => {
		_isa => 'CSSRule',
		_hash => 0,
		_array => 0,
  		encoding => STR,
  	 },
  	 CSSStyleDeclaration => {
		_hash => 0,
		_array => 1,
  		cssText => STR,
  		getPropertyValue => METHOD | STR,
  		getPropertyCSSValue => METHOD | OBJ,
  		removeProperty => METHOD | STR,
  		getPropertyPriority => METHOD | STR,
  		setProperty => METHOD | VOID,
  		length => NUM | READONLY,
  		item => METHOD | STR,
  		parentRule => OBJ | READONLY,
  		azimuth => STR,
  		background => STR,
  		backgroundAttachment => STR,
  		backgroundColor => STR,
  		backgroundImage => STR,
  		backgroundPosition => STR,
  		backgroundRepeat => STR,
  		border => STR,
  		borderCollapse => STR,
  		borderColor => STR,
  		borderSpacing => STR,
  		borderStyle => STR,
  		borderTop => STR,
  		borderRight => STR,
  		borderBottom => STR,
  		borderLeft => STR,
  		borderTopColor => STR,
  		borderRightColor => STR,
  		borderBottomColor => STR,
  		borderLeftColor => STR,
  		borderTopStyle => STR,
  		borderRightStyle => STR,
  		borderBottomStyle => STR,
  		borderLeftStyle => STR,
  		borderTopWidth => STR,
  		borderRightWidth => STR,
  		borderBottomWidth => STR,
  		borderLeftWidth => STR,
  		borderWidth => STR,
  		bottom => STR,
  		captionSide => STR,
  		clear => STR,
  		clip => STR,
  		color => STR,
  		content => STR,
  		counterIncrement => STR,
  		counterReset => STR,
  		cue => STR,
  		cueAfter => STR,
  		cueBefore => STR,
  		cursor => STR,
  		direction => STR,
  		display => STR,
  		elevation => STR,
  		emptyCells => STR,
  		cssFloat => STR,
  		font => STR,
  		fontFamily => STR,
  		fontSize => STR,
  		fontSizeAdjust => STR,
  		fontStretch => STR,
  		fontStyle => STR,
  		fontVariant => STR,
  		fontWeight => STR,
  		height => STR,
  		left => STR,
  		letterSpacing => STR,
  		lineHeight => STR,
  		listStyle => STR,
  		listStyleImage => STR,
  		listStylePosition => STR,
  		listStyleType => STR,
  		margin => STR,
  		marginTop => STR,
  		marginRight => STR,
  		marginBottom => STR,
  		marginLeft => STR,
  		markerOffset => STR,
  		marks => STR,
  		maxHeight => STR,
  		maxWidth => STR,
  		minHeight => STR,
  		minWidth => STR,
  		opacity => STR,
  		orphans => STR,
  		outline => STR,
  		outlineColor => STR,
  		outlineStyle => STR,
  		outlineWidth => STR,
  		overflow => STR,
  		padding => STR,
  		paddingTop => STR,
  		paddingRight => STR,
  		paddingBottom => STR,
  		paddingLeft => STR,
  		page => STR,
  		pageBreakAfter => STR,
  		pageBreakBefore => STR,
  		pageBreakInside => STR,
  		pause => STR,
  		pauseAfter => STR,
  		pauseBefore => STR,
  		pitch => STR,
  		pitchRange => STR,
  		playDuring => STR,
  		position => STR,
  		quotes => STR,
  		richness => STR,
  		right => STR,
  		size => STR,
  		speak => STR,
  		speakHeader => STR,
  		speakNumeral => STR,
  		speakPunctuation => STR,
  		speechRate => STR,
  		stress => STR,
  		tableLayout => STR,
  		textAlign => STR,
  		textDecoration => STR,
  		textIndent => STR,
  		textShadow => STR,
  		textTransform => STR,
  		top => STR,
  		unicodeBidi => STR,
  		verticalAlign => STR,
  		visibility => STR,
  		voiceFamily => STR,
  		volume => STR,
  		whiteSpace => STR,
  		widows => STR,
  		width => STR,
  		wordSpacing => STR,
  		zIndex => STR,
  	 },
  	 CSSValue => {
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			CSS::DOM::Value::CSS_INHERIT
  			CSS::DOM::Value::CSS_PRIMITIVE_VALUE
  			CSS::DOM::Value::CSS_VALUE_LIST
  			CSS::DOM::Value::CSS_CUSTOM
  		]],
  		cssText => STR,
  		cssValueType => NUM | READONLY,
  	 },
  	 CSSPrimitiveValue => {
		_isa => 'CSSValue',
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			CSS::DOM::Value::Primitive::CSS_UNKNOWN
  			CSS::DOM::Value::Primitive::CSS_NUMBER
  			CSS::DOM::Value::Primitive::CSS_PERCENTAGE
  			CSS::DOM::Value::Primitive::CSS_EMS
  			CSS::DOM::Value::Primitive::CSS_EXS
  			CSS::DOM::Value::Primitive::CSS_PX
  			CSS::DOM::Value::Primitive::CSS_CM
  			CSS::DOM::Value::Primitive::CSS_MM
  			CSS::DOM::Value::Primitive::CSS_IN
  			CSS::DOM::Value::Primitive::CSS_PT
  			CSS::DOM::Value::Primitive::CSS_PC
  			CSS::DOM::Value::Primitive::CSS_DEG
  			CSS::DOM::Value::Primitive::CSS_RAD
  			CSS::DOM::Value::Primitive::CSS_GRAD
  			CSS::DOM::Value::Primitive::CSS_MS
  			CSS::DOM::Value::Primitive::CSS_S
  			CSS::DOM::Value::Primitive::CSS_HZ
  			CSS::DOM::Value::Primitive::CSS_KHZ
  			CSS::DOM::Value::Primitive::CSS_DIMENSION
  			CSS::DOM::Value::Primitive::CSS_STRING
  			CSS::DOM::Value::Primitive::CSS_URI
  			CSS::DOM::Value::Primitive::CSS_IDENT
  			CSS::DOM::Value::Primitive::CSS_ATTR
  			CSS::DOM::Value::Primitive::CSS_COUNTER
  			CSS::DOM::Value::Primitive::CSS_RECT
  			CSS::DOM::Value::Primitive::CSS_RGBCOLOR
  		]],
  		primitiveType => NUM | READONLY,
  		setFloatValue => METHOD | VOID,
  		getFloatValue => METHOD | NUM,
  		setStringValue => METHOD | VOID,
  		getStringValue => METHOD | STR,
  #		getCounterValue => METHOD | OBJ,
  #		getRectValue => METHOD | OBJ,
  #		getRGBColorValue => METHOD | OBJ,
  		red => OBJ | READONLY,
  		green => OBJ | READONLY,
  		blue => OBJ | READONLY,
  		alpha => OBJ | READONLY,
  		top => OBJ | READONLY,
  		right => OBJ | READONLY,
  		bottom => OBJ | READONLY,
  		left => OBJ | READONLY,
  	 },
  	 CSSValueList => {
		_isa => 'CSSValue',
		_hash => 0,
		_array => 1,
  		length => NUM | READONLY,
  		item => METHOD | OBJ,
  	 },
  #	 Counter => {
  #		_hash => 0,
  #		_array => 0,
  #		identifier => STR | READONLY,
  #		listStyle => STR | READONLY,
  #		separator => STR | READONLY,
  #	 },
  	 CSSStyleSheet => {
  		type => STR | READONLY,
		_hash => 0,
		_array => 0,
  		disabled => BOOL,
  		ownerNode => OBJ | READONLY,
  		parentStyleSheet => OBJ | READONLY,
  		href => STR | READONLY,
  		title => STR | READONLY,
  		media => OBJ | READONLY,
  		ownerRule => OBJ | READONLY,
  		cssRules => OBJ | READONLY,
  		insertRule => METHOD | NUM,
  		deleteRule => METHOD | VOID,
  	 },
  );

__END__

=head1 SEE ALSO

L<CSS::DOM>
