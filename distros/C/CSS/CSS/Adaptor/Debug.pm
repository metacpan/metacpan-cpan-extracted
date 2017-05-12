package CSS::Adaptor::Debug;

$VERSION = 1.01;

use CSS::Adaptor;
@ISA = qw(CSS::Adaptor);

use strict;
use warnings;

my $DIV_LINE = ('-'x50)."\n";

sub output_rule {
	my ($self, $rule) = @_;
	return "NEW RULE\n".$DIV_LINE.$rule->selectors.$rule->properties.$DIV_LINE."\n";
}

sub output_selectors {
        my ($self, $selectors) = @_;
        return "SELECTORS:\n".join('', map {"\t".$_->{name}."\n"} @{$selectors})."\n";
}

sub output_properties {
        my ($self, $properties) = @_;
        return "PROPERTIES:\n".join('', map {"\t".$_->{property}.":\t".$_->values.";\n"} @{$properties})."\n";
}

sub output_values {
        my ($self, $values) = @_;
        return join '', map {$_->{value}} @{$values};
}


1;

__END__

=head1 NAME

CSS::Adaptor::Debug - An example adaptor for debugging CSS.

=head1 SYNOPSIS

  use CSS;
  ...

=head1 DESCRIPTION

This class implements a CSS::Adaptor object to display a 
stylesheet in  'debugging' style.

=head1 AUTHORS

Copyright (C) 2003-2004, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<CSS>, L<CSS::Adaptor>

=cut
