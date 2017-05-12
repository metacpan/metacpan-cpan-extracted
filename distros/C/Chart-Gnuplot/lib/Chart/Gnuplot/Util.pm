package Chart::Gnuplot::Util;
use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(_lineType _pointType _borderCode _fillStyle _copy);

# Convert named line type to indexed line type of gnuplot
#
# XXX
# Assuming postscript terminal is used
# This may subjected to change when postscript/gnuplot changes its convention
sub _lineType
{
	my ($type) = @_;
	return($type) if ($type =~ /^\d+$/);

	# Indexed line type of postscript terminal of gnuplot
	my %type = (
		solid          => 1,
		longdash       => 2,
		dash           => 3,
		dot            => 4,
		'dot-longdash' => 5,
		'dot-dash'     => 6,
		'2dash'        => 7,
		'2dot-dash'    => 8,
		'4dash'        => 9,
	);
	return($type{$type});
}


# Convert named line type to indexed line type of gnuplot
#
# XXX
# Assuming postscript terminal is used
# This may subjected to change when postscript/gnuplot changes its convention
sub _pointType
{
	my ($type) = @_;
	return($type) if ($type =~ /^\d+$/);

	# Indexed line type of postscript terminal of gnuplot
	my %type = (
		dot               => 0,
		plus              => 1,
		cross             => 2,
		star              => 3,
		'dot-square'      => 4,
		'dot-circle'      => 6,
		'dot-triangle'    => 8,
		'dot-diamond'     => 12,
		'dot-pentagon'    => 14,
		'fill-square'     => 5,
		'fill-circle'     => 7,
		'fill-triangle'   => 9,
		'fill-diamond'    => 13,
		'fill-pentagon'   => 15,
		square            => 64,
		circle            => 65,
		triangle          => 66,
		diamond           => 68,
		pentagon          => 69,
		'opaque-square'   => 70,
		'opaque-circle'   => 71,
		'opaque-triangle' => 72,
		'opaque-diamond'  => 74,
		'opaque-pentagon' => 75,
	);
	return($type{$type});
}


# Encode the border name
# - Used by setting graph border display
sub _borderCode
{
    my ($side) = @_;
    return($side) if ($side =~ /^\d+$/);

    my $code = 0;
    $code += 1 if ($side =~ /(^|,)\s*(1|bottom|bottom left front)\s*(,|$)/);
    $code += 2 if ($side =~ /(^|,)\s*(2|left|bottom left back)\s*(,|$)/);
    $code += 4 if ($side =~ /(^|,)\s*(4|top|bottom right front)\s*(,|$)/);
    $code += 8 if ($side =~ /(^|,)\s*(8|right|bottom right back)\s*(,|$)/);
    $code += 16 if ($side =~ /(^|,)\s*(16|left vertical)\s*(,|$)/);
    $code += 32 if ($side =~ /(^|,)\s*(32|back vertical)\s*(,|$)/);
    $code += 64 if ($side =~ /(^|,)\s*(64|right vertical)\s*(,|$)/);
    $code += 128 if ($side =~ /(^|,)\s*(128|front vertical)\s*(,|$)/);
    $code += 256 if ($side =~ /(^|,)\s*(256|top left back)\s*(,|$)/);
    $code += 512 if ($side =~ /(^|,)\s*(512|top right back)\s*(,|$)/);
    $code += 1024 if ($side =~ /(^|,)\s*(1024|top left front)\s*(,|$)/);
    $code += 2048 if ($side =~ /(^|,)\s*(2048|top right front)\s*(,|$)/);
    return($code);
}


# Generate box filling style string
# - called by _thaw() and _setObjOpt()
sub _fillStyle
{
    my ($fill) = @_;

    if (ref($fill) eq 'HASH')
    {
		my $style = "";
		if (defined $$fill{pattern})
		{
			$style .= " transparent" if (defined $$fill{alpha} &&
				$$fill{alpha} == 0);
			$style .= " pattern $$fill{pattern}";
		}
		else
		{
			if (defined $$fill{alpha})
			{
				$style .= " transparent solid $$fill{alpha}";
			}
			elsif (defined $$fill{density})
			{
        		$style .= " solid $$fill{density}";
			}
			else
			{
				$style .= " solid 1";
			}
		}

        $style .= " noborder" if (defined $$fill{border} &&
            $$fill{border} =~ /^(off|no)$/);
        return($style);
    }

    return(" $fill");
}


# Copy object using dclone() of Storable
sub _copy
{
    my ($obj, $num) = @_;
    use Storable;

    my @clones = ();
    $num = 1 if (!defined $num);

    for (my $i = 0; $i < $num; $i++)
    {
        push(@clones, Storable::dclone($obj));
    }
    return(@clones);
}


1;

__END__
