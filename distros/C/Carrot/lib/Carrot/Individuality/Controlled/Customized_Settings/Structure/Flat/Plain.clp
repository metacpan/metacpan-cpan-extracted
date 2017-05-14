sub NCV_IPL_FIRST_LINE() { 0 }; #INHERITABLE_CONSTANT#
sub NCV_IPL_JOINED_LINES() { 1 }; #INHERITABLE_CONSTANT#
sub NCV_IPL_ALL_LINES() { 2 }; #INHERITABLE_CONSTANT#

	'[=project_pkg=]::Relation::Discrete::Generic::',
		my $first_line_class = '::First_Line',
		my $joined_lines_class = '::Joined_Lines',
		my $all_lines_class = '::All_Lines'

sub modify
# method (<this>, <raw_data>) public
{
	my ($this, $raw_data) = @_;

	my $input_policy = $this->[ATR_TYPE]->customized_setting_input_policy;
	if ($input_policy == NCV_IPL_FIRST_LINE)	
	{
		bless($this, $first_line_class);

	} elsif ($input_policy == NCV_IPL_JOINED_LINES)	
	{
		bless($this, $joined_lines_class);

	} elsif ($input_policy == NCV_IPL_ALL_LINES)	
	{
		bless($this, $all_lines_class);

	} else {
		die("#FIXME: input_policy='$input_policy'.");
	}
	$this->modify($raw_data);
	return;
}

package Carrot::Individuality::Controlled::Customized_Settings::Structure::Discrete::Generic::First_Line;

use strict;
use warnings;

BEGIN {
	my $meta_monad = Carrot::modularity;
	$meta_monad->parent_classes->add(qw(
		[=project_pkg=]::Relation::Discrete::Generic
	));
}
UNITCHECK {
	Carrot::quality;
}

my $meta_monad = Carrot::individuality;

sub modify
# method (<this>, <raw_data>) public
{
	my ($this, $raw_data) = @_;

	$this->_modify($raw_data->[ADX_FIRST_ELEMENT]);
	return;
}

return(1);

