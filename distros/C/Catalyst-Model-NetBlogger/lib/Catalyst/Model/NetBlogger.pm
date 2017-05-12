# $Id: /local/CPAN/Catalyst-Model-NetBlogger/lib/Catalyst/Model/NetBlogger.pm 1392 2008-03-08T01:58:08.842672Z claco  $
package Catalyst::Model::NetBlogger;
use strict;
use warnings;
use Net::Blogger;
use NEXT;
use base 'Catalyst::Base';

our $VERSION = '0.04001';
our $AUTOLOAD;

__PACKAGE__->config(
    engine => 'blogger'
);

sub new {
    my ($self, $c) = @_;
    $self = $self->NEXT::new(@_);

    my $netblogger = Net::Blogger->new({
        engine   => $self->config->{'engine'},
        appkey   => $self->config->{'appkey'},
        blogid   => $self->config->{'blogid'},
        username => $self->config->{'username'},
        password => $self->config->{'password'}
    });

    $netblogger->Proxy($self->config->{'proxy'});
    if ($netblogger->can('Uri')) {
        $netblogger->Uri($self->config->{'uri'});
    };

    $self->config->{'netblogger'} = $netblogger;

    return $self;
};

sub AUTOLOAD {
    my $self = shift;

    return if $AUTOLOAD =~ /::DESTROY$/;

    $AUTOLOAD =~ s/^.*:://;
    $self->config->{'netblogger'}->$AUTOLOAD(@_);
};

1;
__END__

=head1 NAME

Catalyst::Model::NetBlogger - Catalyst Model to post and retrieve blog entries using Net::Blogger

=head1 SYNOPSIS

    # Model
    __PACKAGE__->config(
        engine   => 'movabletype',
        blogid   => 1,
        username => 'login',
        password => 'apipassword',
        proxy    => 'http://example.com/mt/mt-xmlrpc.cgi'
    );

    # Controller
    sub default : Private {
        my ($self, $c) = @_;

        {
            local $^W = 0;

            my ($return, @entries) = $c->model('Blog')->metaWeblog->getRecentPosts({numberOfPosts => 5});

            if ($return) {
                $c->stash->{'entries'} = \@entries;
            };
        };

        $c->stash->{'template'} = 'blog.tt';
    };

=head1 DESCRIPTION

This model class uses Net::Blogger to post and retrieve blog entries to various
web log engines XMLRPC API.

=head1 CONFIG

The following configuration options are available. They are taken directly from
L<Net::Blogger>:

=head2 engine

The name of the blog engine to use. This defaults to 'blogger',

=head2 proxy

The url of the remote XMLRPC listener to connect to.

=head2 blogid

The id of the blog to post or retrieve entries to.


=head2 username

The username used to log into the specified blog.

=head2 password

The password used to log into the specified blog.


=head2 appkey

The magic appkey used when connecting to Blogger blogs.


=head2 uri

The URI to post to at the proxy specified above.

=head1 METHODS

See L<Net::Blogger> for the available methods.


=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Net::Blogger>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
