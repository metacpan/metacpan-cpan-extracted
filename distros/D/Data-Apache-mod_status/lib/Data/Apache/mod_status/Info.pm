package Data::Apache::mod_status::Info;

=head1 NAME

Data::Apache::mod_status::Info - information object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.02';

use Moose;
use Moose::Util::TypeConstraints;
use DateTime::Format::Strptime;

my $build_datetime_parser = DateTime::Format::Strptime->new(
    pattern   => '%b %e %Y %H:%M:%S',
    on_error => 'croak',
);
my $server_datetime_parser = DateTime::Format::Strptime->new(
    pattern   => '%A, %d-%b-%Y %H:%M:%S %Z',
    on_error => 'croak',
);

=head1 PROPERTIES

=cut

subtype 'DateTime' => as 'Object' => where { $_->isa('DateTime') };

has 'server_version'           => ( 'is' => 'rw', 'isa' => 'Str', );
has 'server_build_str'         => ( 'is' => 'rw', 'isa' => 'Str', );
has 'server_build'             => ( 'is' => 'rw', 'isa' => 'DateTime',
    'lazy'    => 1,
    'default' => sub { $build_datetime_parser->parse_datetime($_[0]->server_build_str) },
);
has 'current_time_str'         => ( 'is' => 'rw', 'isa' => 'Str', );
has 'current_time'             => ( 'is' => 'rw', 'isa' => 'DateTime',
    'lazy'    => 1,
    'default' => sub { $server_datetime_parser->parse_datetime($_[0]->current_time_str) },
);
has 'restart_time_str'         => ( 'is' => 'rw', 'isa' => 'Str', );
has 'restart_time'             => ( 'is' => 'rw', 'isa' => 'DateTime',
    'lazy'    => 1,
    'default' => sub { $server_datetime_parser->parse_datetime($_[0]->restart_time_str) },
);
has 'parent_server_generation' => ( 'is' => 'rw', 'isa' => 'Int', );
has 'server_uptime_str'        => ( 'is' => 'rw', 'isa' => 'Str', );
has 'server_uptime'            => ( 'is' => 'rw', 'isa' => 'Int',
    'lazy'    => 1,
    'default' => sub { $_[0]->_server_uptime },
);
has 'total_accesses'           => ( 'is' => 'rw', 'isa' => 'Int', );
has 'total_traffic_str'        => ( 'is' => 'rw', 'isa' => 'Str', );
has 'total_traffic'            => ( 'is' => 'rw', 'isa' => 'Int|Undef',
    'lazy'    => 1,
    'default' => sub { $_[0]->_total_traffic },
);
has 'cpu_usage_str'            => ( 'is' => 'rw', 'isa' => 'Str', );
has 'current_requests'         => ( 'is' => 'rw', 'isa' => 'Int', );
has 'idle_workers'             => ( 'is' => 'rw', 'isa' => 'Int', );


=head1 METHODS

=cut

sub _server_uptime {
    my $self = shift;
    
    my $server_uptime_str = $self->server_uptime_str;
    die 'badly formated server uptime string "', $server_uptime_str,'"'
        if $server_uptime_str !~ m/^(\d+) \s hours \s (\d+) \s minutes \s (\d+) \s seconds$/xms;
    
    return $1*60*60+$2*60+$3;
}

my %_total_traffic_multiply = (
    'kB' => 1024,
    'MB' => 1024*1024,
    'GB' => 1024*1024*1024,
    'TB' => 1024*1024*1024*1024,
);
sub _total_traffic {
    my $self = shift;
    
    my $traffic = $self->total_traffic_str;
    return
        if not defined $traffic;    
    die 'badly formated traffic string "', $traffic,'"'
        if $traffic !~ m/^(\d+(?:.\d)?) \s (kB|MB|GB|TB)$/xms;
    
    my ($volume, $units) = ($1, $2);
    
    return int($volume*$_total_traffic_multiply{$units});
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
