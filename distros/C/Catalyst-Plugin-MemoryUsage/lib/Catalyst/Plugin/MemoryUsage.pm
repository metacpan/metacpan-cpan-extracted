package Catalyst::Plugin::MemoryUsage;
BEGIN {
  $Catalyst::Plugin::MemoryUsage::AUTHORITY = 'cpan:YANICK';
}
{
  $Catalyst::Plugin::MemoryUsage::VERSION = '0.4.0';
}
#ABSTRACT: Profile memory usage of requests

use strict;
use warnings;

use namespace::autoclean;
use Moose::Role;
use MRO::Compat;

use Memory::Usage;

use Devel::CheckOS;
use Text::SimpleTable;
use Number::Bytes::Human qw/ format_bytes /;
use List::Util qw/ max /;

our @SUPPORTED_OSES = qw/ Linux NetBSD /;

our $os_not_supported = Devel::CheckOS::os_isnt( @SUPPORTED_OSES );

if ( $os_not_supported ) {
    warn "OS not supported by Catalyst::Plugin::MemoryUsage\n",
         "\tStats will not be collected\n";
}


has memory_usage => (
    is => 'rw',
    default => sub { Memory::Usage->new },
);

our $_memory_usage_report;
our $_memory_usage_record_actions;


after setup_finalize => sub {
    my $c = shift;

    my %config = %{ $c->config->{'Plugin::MemoryUsage'} || {} };

    $_memory_usage_report = 
        exists $config{report} ? $config{report} : $c->debug;

    $_memory_usage_record_actions = 
        exists $config{action_milestones} 
            ? $config{action_milestones} : $c->debug;
};




sub reset_memory_usage {
    my $self = shift;

    $self->memory_usage( Memory::Usage->new );
}

sub memory_usage_report {
    my $self = shift;

    my $title_width = max 10,
        map { length $_->[1] } @{ $self->memory_usage->state };

    my $table = Text::SimpleTable->new( 
        [$title_width, ''],
        [4, 'vsz'],
        [4, 'delta'],
        [4, 'rss'],
        [4, 'delta'],
        [4, 'shared'],
        [4, 'delta'],
        [4, 'code'],
        [4, 'delta'],
        [4, 'data'],
        [4, 'delta'],
    );

    my @previous;

    for my $s ( @{ $self->memory_usage->state } ) {
        my ( undef, $msg, @sizes ) = @$s;

        my @data = map { $_ ? format_bytes( 1024 * $_) : '' } map { 
            ( $sizes[$_], @previous ? $sizes[$_] - $previous[$_]  : 0 )
        } 0..4;
        @previous = @sizes;

        $table->row( $msg, @data );
    }

    return $table->draw;
}

unless ( $os_not_supported ) {

after execute => sub {
    return unless $_memory_usage_record_actions;

    my $c = shift;
    $c->memory_usage->record( "after " . join " : ", @_ );
};

around prepare => sub {
    my $orig = shift;
    my $self = shift;

    my $c = $self->$orig(@_);

    $c->memory_usage->record('preparing for the request') 
        if $_memory_usage_record_actions;

    return $c;
};

after finalize => sub {
    return unless $_memory_usage_report;

    my $c = shift;
    $c->log->debug(
        sprintf(qq{[%s] memory usage of request "%s" from "%s"\n},
            [split m{::}, __PACKAGE__]->[-1],
            $c->req->uri,
            $c->req->address,
        ),
        $c->memory_usage_report
    );
};

}

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::MemoryUsage - Profile memory usage of requests

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

In YourApp.pm:

    package YourApp;

    use Catalyst qw/
        MemoryUsage
    /;

In a Controller class:

    sub foo :Path( '/foo' ) {
         # ...
         
         something_big_and_scary();
         
         $c->memory_usage->record( 'finished running iffy code' );
         
         # ...
    }

In yourapp.conf:

    <Plugin::MemoryUsage>
        report            1
        action_milestones 1
    </Plugin::MemoryUsage>

=head1 DESCRIPTION

C<Catalyst::Plugin::MemoryUsage> adds a memory usage profile to your debugging
log, which looks like this:   

 [debug] [MemoryUsage] memory usage of request "http://localhost/index" from "127.0.0.1"
 .--------------------------------------------------+------+------+------+------+------+------+------+------+------+------.
 |                                                  | vsz  | del- | rss  | del- | sha- | del- | code | del- | data | del- |
 |                                                  |      | ta   |      | ta   | red  | ta   |      | ta   |      | ta   |
 +--------------------------------------------------+------+------+------+------+------+------+------+------+------+------+
 | preparing for the request                        | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | after TestApp::Controller::Root : root/_BEGIN    | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | after TestApp::Controller::Root : root/_AUTO     | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | in the middle of index                           | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | after TestApp::Controller::Root : root/index     | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | after TestApp::Controller::Root : root/_ACTION   | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | after TestApp::Controller::Root : root/_END      | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 | after TestApp::Controller::Root : root/_DISPATCH | 28M  |      | 22M  |      | 2.2M |      | 1.1M |      | 20M  |      |
 '--------------------------------------------------+------+------+------+------+------+------+------+------+------+------'  

=head1 CONFIGURATION

=head2 report

If true, the memory usage is reported automatically (at debug level)
at the end of the request.  

Defaults to true if we are in debugging mode,
false otherwise.

=head2 action_milestones

If true, automatically adds milestones for each action, as seen in the
DESCRIPTION.  

Defaults to true if we are in debugging mode,
false otherwise.

=head1 METHODS

=head2 C<memory_usage()>

Returns the L<Memory::Usage> object available to the context.

To record more measure points for the memory profiling, use the C<record()>
method of that object:

    sub foo :Path {
        my ( $self, $c) = @_;

        ...

        big_stuff();

        $c->memory_usage->record( "done with big_stuff()" );

        ...
    }

=head2 C<reset_memory_usage()>

Discards the current C<Memory::Usage> object, along with its recorded data,
and replaces it by a shiny new one.

=head1 BUGS AND LIMITATIONS

C<Memory::Usage>, which is the module C<Catalyst::Plugin::MemoryUsage> relies
on to get its statistics, only work for Linux-based platforms. Consequently,
for the time being C<Catalyst::Plugin::MemoryUsage> only work on Linux and
NetBSD. This being said, patches are most welcome. :-)

=head1 SEE ALSO

L<Memory::Usage>

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
