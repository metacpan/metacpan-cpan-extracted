#
# This file is part of Dancer-Plugin-Params-Normalization
#
# This software is copyright (c) 2011 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::Params::Normalization::Trim;
{
  $Dancer::Plugin::Params::Normalization::Trim::VERSION = '0.52';
}
use strict;
use warnings;

# TRIM: normalization class for white space filtering

use base 'Dancer::Plugin::Params::Normalization::Abstract';

#set the trim_filter
my $trim_filter = sub {
    return scalar($_[0] =~ s/^\s+|\s+$//g)
};

sub normalize {
    my ($self, $params) = @_;
    $trim_filter->($_) for values %$params;
    return $params;
}

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::Params::Normalization::Trim

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This subclass of Dancer::Plugin::Params::Normalization::Abstract removes whitespace from hash values.

=head1 NAME

Dancer::Plugin::Params::Normalization::Trim - normalization class for white space filtering

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
