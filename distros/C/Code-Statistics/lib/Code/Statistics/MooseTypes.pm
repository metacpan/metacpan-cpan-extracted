use strict;
use warnings;

package Code::Statistics::MooseTypes;
$Code::Statistics::MooseTypes::VERSION = '1.190680';
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

=encoding UTF-8

=head1 NAME

Code::Statistics::MooseTypes - provides coercion types for Code::Statistics

=head1 VERSION

version 1.190680

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
