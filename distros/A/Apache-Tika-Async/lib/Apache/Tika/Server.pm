package Apache::Tika::Server;
use strict;
use Carp qw(croak);
# Fire up/stop a Tika instance
use Moo;
use Apache::Tika::DocInfo;
use Data::Dumper;
use Promises;

=head1 SYNOPSIS

    use Apache::Tika::Server;

    # Launch our own Apache Tika instance
    my $tika= Apache::Tika::Server->new();
    $tika->launch();

    my $fn= shift;

    use Data::Dumper;
    print Dumper $tika->get_meta($fn);
    print Dumper $tika->get_text($fn);
    print Dumper $tika->get_language($fn);

    my $info = $tika->get_all($fn);
    print Dumper $info->meta;

=cut

use vars '$VERSION';
$VERSION = '0.06';

extends 'Apache::Tika::Async';

sub load_module {
    my( $module ) = @_;
    $module =~ s!::!/!g;
    require "$module.pm"
}

has pid => (
    is => 'rw',
    #isa => 'Int',
);

has port => (
    is => 'ro',
    #isa => 'Int',
    default => sub { 9998 },
);

has fh => (
    is => 'rw',
    #isa => 'Array',
);

has connection_class => (
    is => 'ro',
    default => 'Apache::Tika::Connection::AEHTTP',
);

has ua => (
    is => 'ro',
    #isa => 'Str',
    default => sub { load_module( $_[0]->connection_class ); $_[0]->connection_class->new },
);

sub cmdline {
    my( $self )= @_;
    $self->java,
    @{$self->java_args},
    '-jar',
    $self->jarfile,
    #'--port', $self->port,
    @{$self->tika_args},
};

sub launch {
    my( $self )= @_;
    if( !$self->pid ) {
        my $cmdline= join " ", $self->cmdline; # well, for Windows...
        #warn $cmdline;
        my $pid= open my $fh, "$cmdline |"
            or croak "Couldn't launch [$cmdline]: $!/$^E";
        $self->pid( $pid );
        $self->fh( $fh );
        sleep 2; # Java...
    };
}

sub url {
    # Should return URI instead
    my( $self, $type )= @_;
    $type||= 'text';
    
    my $url= {
        text => 'rmeta',
        test => 'tika', # but GET instead of PUT
        meta => 'rmeta',
        #all => 'all',
        language => 'language/string',
        all => 'rmeta',
        # unpack
    }->{ $type };
    
    sprintf
        'http://127.0.0.1:%s/%s',
        $self->port,
        $url
};


sub synchronous($) {
    my $promise = $_[0];
    my @res;
    if( $promise->is_unfulfilled ) {
        require AnyEvent;
        my $await = AnyEvent->condvar;
        $promise->then(sub{ $await->send(@_)});
        @res = $await->recv;
    } else {
        @res = @{ $promise->result }
    }
    @res
};

# /rmeta
# /unpacker
# /all
# /tika
# /language
#    hello world
sub fetch {
    my( $self, %options )= @_;
    $options{ type }||= 'text';
    my $url= $self->url( $options{ type } );
    
    my $content= $options{ content };
    if(! $content and $options{ filename }) {
        # read $options{ filename }
        open my $fh, '<', $options{ filename }
            or croak "Couldn't read '$options{ filename }': $!";
        binmode $fh;
        local $/;
        $content = <$fh>;
    };
    
    my $method;
    if( 'test' eq $options{ type } ) {
        $method= 'get';

    } else {
        $method= 'put';
        ;
    };
    
    my $headers = $options{ headers } || {};
    
    my ($code,$res) = synchronous
        $self->ua->request( $method, $url, $content, %$headers );
    my $info;
    if(    'all' eq $options{ type }
        or 'text' eq $options{ type }
        or 'meta' eq $options{ type } ) {
        if( $code !~ /^2..$/ ) {
            croak "Got HTTP error code $code";
        };
        my $item = $res->[0];
        
        # Should/could this be lazy?
        my $c = delete $item->{'X-TIKA:content'};
        # Ghetto-strip HTML we don't want:
        if( $c =~ m!<body>(.*)</body>!s ) {
            $c = $1;
            
            if( $item->{"Content-Type"} and $item->{"Content-Type"} =~ m!^text/plain\b!) {
                # Also strip the enclosing <p>..</p>
                $c =~ s!\A\s*<p>(.*)\s*</p>\s*\z!$1!s;
            };
        } else {
            warn "Couldn't find HTML body in response";
        };
        
        $info= Apache::Tika::DocInfo->new({
            content => $c,
            meta => $item,
        });
        
        if( ! defined $info->{meta}->{"meta:language"} ) {
            # Yay. Two requests.
            my $lang_meta = $self->fetch(%options, type => 'language', 'Content-Type' => $item->{'Content-Type'});
            $info->{meta}->{"meta:language"} = $lang_meta->meta->{"info"};
        };
        
    } else {
        # Must be '/language'
        if( $code !~ /^2..$/ ) {
            croak "Got HTTP error code $code";
        };
        if( ref $res ) {
            $res = $res->[0];
        } else {
            $res = { info => $res };
        };

        my $c = delete $res->{'X-TIKA:content'};
        $info= Apache::Tika::DocInfo->new({
            meta => $res,
            content => undef,
        });
    };
    $info
}

sub DEMOLISH {
    kill -9 => $_[0]->pid
        if( $_[0] and $_[0]->pid );
}

__PACKAGE__->meta->make_immutable;

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/apache-tika>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Tika-Async>
or via mail to L<apache-tika-async-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut