use strict;
use warnings;

package Code::Statistics::Target;
{
  $Code::Statistics::Target::VERSION = '1.112980';
}

# ABSTRACT: base class for Code::Statistic targets

use 5.004;

use Module::Pluggable search_path => __PACKAGE__, require => 1, sub_name => 'all';


sub find_targets {
    my ( $class, $file ) = @_;
    return [];
}


sub incompatible_with {
    my ( $class, $target ) = @_;
    return 0;
}


sub force_support {
    my ( $class, $target ) = @_;
    return 0;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Target - base class for Code::Statistic targets

=head1 VERSION

version 1.112980

=head2 find_targets
    Returns an arrayref to a list of targets found in the given file.
    Is called with the target class name and a Code::Statistics::File object.
    This function should be overridden with specific logic to actually retrieve
    the target list.

=head2 incompatible_with
    Returns true if the given metric is explicitly not supported by this target.
    Is called with the target class name and a string representing the metric
    identifiers after 'Code::Statistics::Metric::'.
    Default is that all targets are compatible with all metrics.

=head2 force_support
    Returns true if the given metric is forcibly supported by this target.
    Is called with the target class name and a string representing the metric
    identifiers after 'Code::Statistics::Metric::'.
    Default is that no forcing happens.

    Has higher precedence than 'incompatible_with' and should be used to
    override incompatibilities set by other metrics.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

