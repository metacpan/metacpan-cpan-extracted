package Carrot::Personality::Valued::Internet::Protocol::HTTP::Form_Data
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Personality::Valued::Internet::Codec::URL
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $url_codec = '::Personality::Valued::Internet::Codec::URL');

	#FIXME: limit resource consumption

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_FORM_DATA] = {};
	$this->[ATR_ORDERED_NAMES] = [];
	$this->[ATR_BODY_SIZE] = IS_UNDEFINED;
	$this->[ATR_PARSED] = IS_FALSE;

	return;
}

sub enabled_body_size
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_BODY_SIZE]);
}

sub enable_body_size
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	$_[THIS][ATR_BODY_SIZE] = $_[SPX_VALUE];
	return;
}

sub parse
# /type method
# /effect ""
# //parameters
#	projection      Mica::Projection
#	limit
# //returns
{
	my ($this, $projection, $limit) = @ARGUMENTS;

#FIXME: although 2nd limit might be higher
	return if ($this->[ATR_PARSED]);

	my $request = $projection->request;
	my $method = $request->line->method->value;

	if ($request->is_pending)
	{
		#if body not complete and criteria allow full loading:
		#$projection->control->set_restart
		#return;
		#otherwise
		#$projection->control->set_drop / error
	}

	my $query_string_ref = IS_UNDEFINED;
	if (($method eq 'GET') or ($method eq 'HEAD'))
	{
		$query_string_ref = $request->line->uri->query_string_ref;
	} elsif (($method eq 'POST') or ($method eq 'PUT'))
	{
#FIXME: limit would be most important here, because it might be a file
		$query_string_ref = $request->body;
	}

	if (defined($query_string_ref))
	{
		die('FIXME');
		$this->url_query_string_decode($query_string_ref);
	}
	$this->[ATR_PARSED] = IS_TRUE;

	return;
}

sub url_query_string_decode
# /type method
# /effect ""
# //parameters
#	settings
# //returns
{
	my ($this, $settings) = @ARGUMENTS;

	$$settings =~ tr/+/ /;

	my $form_data = $this->[ATR_FORM_DATA];
	my $ordered_names = $this->[ATR_ORDERED_NAMES];
	my $split = [split(qr{&}, $$settings, PKY_SPLIT_RETURN_FULL_TRAIL)];
	foreach my $setting (@$split)
	{
		my ($name, $value) = split (qr{=}, $setting, 2);

		$url_codec->decode($name);
		$url_codec->decode($value);

		if (exists($form_data->{$name}))
		{
			push($form_data->{$name}, $value);
		} else {
			push($ordered_names, $name);
			$form_data->{$name} = [$value];
		}
	}

	return;
}

sub provide_matching_type
# /type method
# /effect ""
# //parameters
#	value_names  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $form_data = $this->[ATR_FORM_DATA];
	foreach my $value (@ARGUMENTS)
	{
		my $type = ref($value);
		if ($type eq '')
		{
			if (exists($form_data->{$value}))
			{
				$value = join(',', @{$form_data->{$value}});
			} else {
				$value = IS_UNDEFINED;
			}
		} elsif ($type eq 'ARRAY')
		{
			my $key = $value->[ADX_FIRST_ELEMENT];
			if (exists($form_data->{$value}))
			{
				$value = $form_data->{$value};
			} else {
				$value = IS_UNDEFINED;
			}
		} else {
			die('#FIXME');
		}
	}
	return;
}

sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	value_names  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $form_data = $this->[ATR_FORM_DATA];
	foreach my $key (@ARGUMENTS)
	{
		if (exists($form_data->{$key}))
		{
			$key = join(',', @{$form_data->{$key}});
		} else {
			$key = IS_UNDEFINED;
		}
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.74
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
