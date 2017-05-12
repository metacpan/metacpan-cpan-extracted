#########################################################
package AnyData::Format::Base;
#########################################################
# AnyData driver for plain text files
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################
use strict;
use warnings;
use vars qw( @ISA $DEBUG );
$DEBUG = 0;

sub new {
    my $class = shift;
    my $self = shift || {};
    $self->{record_sep} ||= "\n";
###    $self->{slurp_mode} = 1 unless defined $self->{slurp_mode};
    return bless $self, $class;
}
sub DESTROY {
    # print "PARSER DESTROYED"
}
sub get_data     { undef }
sub storage_type { undef }
sub init_parser  { undef }

sub write_fields {
    my $self   = shift;
    my @ary = @_;
    return \@ary;
}
sub read_fields {
    my $self   = shift;
    my $aryref = shift;
    return @$aryref;
}
1;

