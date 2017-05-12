#########################################################################
package AnyData::Storage::PassThru;
#########################################################################
#  This module is copyright (c), 2000 by Jeff Zucker
#  All rights reserved.
#########################################################################
#  Nothing of interest here, it just passes the storage duties to the
#  parser for formats like XML that do both format and storage
#########################################################################
use strict;
use warnings;
use vars qw($VERSION @ISA);

$VERSION = '0.12';

use AnyData::Storage::File;
@ISA = qw( AnyData::Storage::File);
sub file2str          { 1 }
sub push_row          { my($s,$f)=@_;$s->{parser}->push_row(@$f) }
sub seek_first_record { shift->{parser}->seek_first_record }
sub get_col_names     { shift->{col_names} }
sub delete_record     { shift->{parser}->delete_record }
sub truncate          { shift->{parser}->truncate(@_) }
sub drop              { shift->{parser}->drop(@_)}
sub close_table       { shift->{parser}->close_table(@_)}
sub get_pos           { shift->{parser}->get_pos(@_)}
sub go_pos            { shift->{parser}->go_pos(@_)}
sub seek              { shift->{parser}->seek(@_)}
sub export            { shift->{parser}->export(@_)}

sub DESTROY {
    #print "PASSTHRU DESTROYED";
}

#####################################
# push_names()
#####################################
sub print_col_names {
    my($self, $parser, $names) = @_;
    $names = $parser->push_names($names);
    $self->{col_names} = $names;
    my($col_nums) = {};
    for (my $i = 0;  $i < @$names;  $i++) {
        $col_nums->{$names->[$i]} = $i;
    }
    $self->{col_nums} = $col_nums;
}

1;
