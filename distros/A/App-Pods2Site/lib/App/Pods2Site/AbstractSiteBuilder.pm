package App::Pods2Site::AbstractSiteBuilder;

use strict;
use warnings;

use App::Pods2Site::Util qw(slashify writeUTF8File);

use File::Copy;

# CTOR
#
sub new
{
	my $class = shift;
	my $styleName = shift;

	my $self = bless( { stylename => $styleName }, $class );

	return $self;
}

sub prepareCss
{
	my $self = shift;
	my $args = shift;

	my $sitedir = $args->getSiteDir();

	my $sbName = $self->getStyleName();
	my $sbCssContent = $self->_getCssContent();

	my $sbCssFile = slashify("$sitedir/$sbName.css");
	writeUTF8File($sbCssFile, $sbCssContent);

	my $systemCSSContent = <<SYSCSS;
\@charset "UTF-8";
\@import url($sbName.css);
SYSCSS
 	
	my $inUserCSSFile = $args->getCSS();
	if ($inUserCSSFile)
	{
		my $outUserCSSFile = slashify("$sitedir/user.css");
		copy($inUserCSSFile, $outUserCSSFile) || die("Failed to copy CSS '$inUserCSSFile' => '$outUserCSSFile': $!\n");
		$systemCSSContent .= "\@import url(user.css)";
	}

	my $sysCssName = $self->getSystemCssName();
	my $systemCSSFile = slashify("$sitedir/$sysCssName.css");
	writeUTF8File($systemCSSFile, $systemCSSContent);
}

sub getStyleName
{
	my $self = shift;
	
	return $self->{stylename};
}

sub getSystemCssName
{
	return 'pods2site';
}

sub _getCssContent
{
	die("Missing override: getCssContent()");
}

1;
