package CSS::Adaptor::Pretty;

$VERSION = 1.01;

use CSS::Adaptor;
@ISA = ('CSS::Adaptor');

use strict;
use warnings;

sub output_rule {
	my ($self, $rule) = @_;
	return $rule->selectors." {\n".$rule->properties."}\n\n" ;
}

sub output_properties {
	my ($self, $properties) = @_;
	my $longest_prop = 0;
	for(@{$properties}){
		if (length($_->{property}) > $longest_prop){
			$longest_prop = length($_->{property});
		}
	}
	my $tabs = int (($longest_prop + 1)/8);
	return join("", map {
		my $sp = "\t";
		my $this = int ((length($_->{property}) + 1)/8);
		$sp .= "\t" x ($tabs - $this);
		"\t".$_->{property}.":".$sp.$_->values.";\n";
	} @{$properties});
}

1;

__END__

=head1 NAME

CSS::Adaptor::Pretty - An example adaptor for pretty-printing CSS.

=head1 SYNOPSIS

  use CSS;
  ...

=head1 DESCRIPTION

This class implements a CSS::Adaptor object to display a
stylesheet in a 'pretty' style.

=head1 AUTHORS

Copyright (C) 2003-2004, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<CSS>, L<CSS::Adaptor>

=cut
