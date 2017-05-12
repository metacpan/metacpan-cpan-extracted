use strict;
use warnings;

package Code::Statistics::MooseTypes;
{
  $Code::Statistics::MooseTypes::VERSION = '1.112980';
}

# ABSTRACT: provides coercion types for Code::Statistics

use Moose::Util::TypeConstraints;

subtype 'CS::InputList' => as 'ArrayRef';
coerce 'CS::InputList' => from 'Str' => via {
    my @list = split /;/, $_;
    return \@list;
};

1;

__END__
=pod

=head1 NAME

Code::Statistics::MooseTypes - provides coercion types for Code::Statistics

=head1 VERSION

version 1.112980

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

