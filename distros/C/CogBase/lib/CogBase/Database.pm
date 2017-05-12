package CogBase::Database;
use CogBase::Base -base;
use IO::All;

sub create {
    my ($class, $db_path) = @_;
    io("$db_path/nodes")->mkpath;
    io("$db_path/index/hid")->mkpath;
    io("$db_path/index/type/Schema")->mkpath;
}

=head1 NAME

CogBase::Database - Database Management Class

=cut

1;
