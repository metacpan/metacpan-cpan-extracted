package Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp;
{
  $Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp::VERSION = '0.1.5';
}
{
  $Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp::DIST = 'Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp';
}

use Moose;
use Net::Stomp;
use Data::Dump qw/pp/;
use Data::Serializer;
use MooseX::Types -declare => [qw/Serializer/];
use MooseX::Types::Moose qw/Str HashRef/;
use Moose::Util::TypeConstraints;
use Path::Class::File;
use Fcntl qw(:flock);

=head1 NAME

Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp - Plugin for ErrorCatcher to throw exceptions over ActiveMQ using Stomp

=head1 VERSION

version 0.1.5

=cut



class_type 'Data::Serializer';
subtype Serializer, as 'Data::Serializer';
coerce Serializer, from 'Str',
    via { Data::Serializer->new( serializer => $_ ) };

has serializer => (
    is          => 'ro',
    isa         => Serializer,
    required    => 1,
    default     => 'JSON',
    coerce      => 1,
);

has destination => (
    is          => 'rw',
    isa         => 'Str',
);

has hostname => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has port => (
    is          => 'ro',
    isa         => 'Str',
    default     => '61613',
);

has connection => (
    is          => 'ro',
    isa         => 'Net::Stomp',
    lazy        => 1,
    builder     => '_build_connection',
);

has dump_dir => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'is_under_test',
);

has debug => (
    is          => 'ro',
    default     => 0,
);
sub _build_connection {
    my ($self) = @_;

    return Net::Stomp->new({
        hostname    => $self->hostname,
        port        => $self->port,
    });
}

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;

    my $hash = $self->$orig(@args);

    # $c is passed so pull it out and get the config
    my $c = undef;
    if ($hash->{c}) {
        $c = $hash->{c};
    }

    my $config = $c->_errorcatcher_c_cfg->{"Plugin::ErrorCatcher::ActiveMQ::Stomp"};

    # if its not set properly then trash it
    delete $config->{dump_dir} unless $config->{dump_dir};

    return $config;
};


=head1 SYNOPSIS

Put this sort of thing into the catalyst conf file..

<Plugin::ErrorCatcher::ActiveMQ::Stomp>
    destination     test-message
    hostname        localhost
    # defaults to 61613
    #port

</Plugin::ErrorCatcher::ActiveMQ::Stomp>



=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 emit

=cut

sub emit {
    my($self,$c,$content) = @_;

    if (not $self->serializer->can('raw_serialize')) {
        die __PACKAGE__ .": missing method 'raw_serialize' for "
            . ref($self->serializer);
    }

    my $send_data = {
        destination     => $self->destination,
        body            => $self->serializer->raw_serialize({ output => $content }),
    };

    if ($self->is_under_test) {
        my $fname = $self->_next_test_filename($self->dump_dir, $self->destination);

        $self->_dump_to_file( $fname, $send_data );

        if ($self->debug) {
            $c->log->info(__PACKAGE__ .": in test mode");
        }

    } else {
        if ($self->debug) {
            $c->log->info(__PACKAGE__ .": in live mode");
        }
        $self->connection->connect();

        $self->connection->send( $send_data );

        $self->connection->disconnect();
    }

    return;
}

sub _next_test_filename {
    my($self,$dir, $queue) = @_;

    # Get a lock on "$dir/.lock" to avoid prove -j issues
    my $lock;
    mkdir $dir;
    open($lock, ">", "$dir/.lock") or die "Unable to open lock file $dir/.lock";
    flock($lock, LOCK_EX) or die "Cannot lock ActiveMQ dump dir";

    $queue =~ s{^/}{};
    $queue =~ s{/}{_}g;
    my $i = 0;
    my $file;
    do {
        $i++;
        $file = sprintf("%s/%04d__%s", $dir, $i, $queue);
    } while (-f $file);

    Path::Class::File->new($file)->touch;

    flock($lock, LOCK_UN) or die "Cannot unlock ActiveMQ dump dir";
    close($lock);

    return $file;
}

sub _dump_to_file {
    my($self,$filename, $send_data) = @_;

    open(FILE, ">$filename") or die "Cannot write to file $filename: $!";

    print FILE $self->serializer->raw_serialize($send_data);

    close FILE;

    return;
}


=head1 SEE ALSO

L<Catalyst::Plugin::ErrorCatcher>

=head1 AUTHOR

Jason Tang, C<< <tang.jason.ch at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-errorcatcher-activemq-stomp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jason Tang, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp
