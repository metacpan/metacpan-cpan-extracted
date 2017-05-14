
sub _shorten_scalar
# method (<this>, <value>) public
{
	return($_[SPX_VALUE]);
	my $l = length($_[SPX_VALUE]);
	my $value = substr($_[SPX_VALUE], 0, 60);
	if ($l > 60)
	{
		$value .= '... ('. ($l-60) .' bytes truncated)';
	}
	return($value);
}

sub beautify_hash_data
# method (<this>, <hash_data>) public
{
	my ($this, $hash_data) = @ARGUMENTS;

	foreach my $key (keys(%$details))
	{
		if (defined(my $type = Scalar::Util::reftype($details->{$key})))
		{
			if ($type eq 'HASH')
			{
				my @values = ();
				keys(%{$details->{$key}});
				while ( my ($name, $value) = each(%{$details->{$key}}))
				{
					push(\@values, $name.': '. $this->_shorten_scalar($value));
				}
				if ($#values > 9)
				{
					my $i = $#values-9;
					splice(\@values, 10);
					push(\@values, "... ($i more truncated) ...");
				}
				$details->{$key} = join(TXT_LINE_BREAK, @values);

			} elsif ($type eq 'ARRAY')
			{
				my @values = @{$details->{$key}};
				if ($#values > 9)
				{
					my $i = $#values-9;
					splice(\@values, 10);
					push(\@values, "... ($i more truncated) ...");
#			} else {
#				$list = join(TXT_LINE_BREAK, @values);
				}
				map($this->_shorten_scalar($_), @values);
				$details->{$key} = join(TXT_LINE_BREAK, @values);

			} elsif ($type eq 'SCALAR')
			{
				$details->{$key} =
					$this->_shorten_scalar(${$details->{$key}});

			} elsif ($type eq '')
			{
				$details->{$key} =
					$this->_shorten_scalar($details->{$key});
			}
		} elsif (defined(Scalar::Util::blessed($details->{$key})))
		{
			$details->{$key} = $details->{$key}->as_text;

		}
	}
return;
}
	#FIXME: move to
# =--------------------------------------------------------------------------= #

sub _shorten_scalar
# method (<this>, <value>) public
{
	return($_[SPX_VALUE]);
	my $l = length($_[SPX_VALUE]);
	my $value = substr($_[SPX_VALUE], 0, 60);
	if ($l > 60)
	{
		$value .= '... ('. ($l-60) .' bytes truncated)';
	}
	return($value);
}

sub beautify_hash_data
# method (<this>, <hash_data>) public
{
	my ($this, $hash_data) = @ARGUMENTS;

	foreach my $key (keys(%$details))
	{
		if (defined(my $type = Scalar::Util::reftype($details->{$key})))
		{
			if ($type eq 'HASH')
			{
				my @values = ();
				keys(%{$details->{$key}});
				while ( my ($name, $value) = each(%{$details->{$key}}))
				{
					push(\@values, $name.': '. $this->_shorten_scalar($value));
				}
				if ($#values > 9)
				{
					my $i = $#values-9;
					splice(\@values, 10);
					push(\@values, "... ($i more truncated) ...");
				}
				$details->{$key} = join(TXT_LINE_BREAK, @values);

			} elsif ($type eq 'ARRAY')
			{
				my @values = @{$details->{$key}};
				if ($#values > 9)
				{
					my $i = $#values-9;
					splice(\@values, 10);
					push(\@values, "... ($i more truncated) ...");
#			} else {
#				$list = join(TXT_LINE_BREAK, @values);
				}
				map($this->_shorten_scalar($_), @values);
				$details->{$key} = join(TXT_LINE_BREAK, @values);

			} elsif ($type eq 'SCALAR')
			{
				$details->{$key} =
					$this->_shorten_scalar(${$details->{$key}});

			} elsif ($type eq '')
			{
				$details->{$key} =
					$this->_shorten_scalar($details->{$key});
			}
		} elsif (defined(Scalar::Util::blessed($details->{$key})))
		{
			$details->{$key} = $details->{$key}->as_text;

		}
	}
return;
}
