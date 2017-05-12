#########################################################
package AnyData::Format::FileSys;
#########################################################
# AnyData driver for plain text files
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################
use strict;
use warnings;
use AnyData::Format::Base;
use vars qw( @ISA $DEBUG );
@AnyData::Format::FileSys::ISA = qw( AnyData::Format::Base );
$DEBUG = 0;

sub new {
    my $class = shift;
    my $self = shift || {};
    $self->{rec_sep}   ||= "\n";
    $self->{keep_first_line} = 1;
    $self->{storage} = 'FileSys';
    return bless $self, $class;
}

1;



