# $Id: /local/CPAN/Catalyst-Model-NetBlogger/lib/Catalyst/Helper/Model/NetBlogger.pm 1378 2005-11-19T23:26:50.755054Z claco  $
package Catalyst::Helper::Model::NetBlogger;
use strict;
use warnings;

sub mk_compclass {
    my ($self, $helper, $engine, $proxy, $blogid, $username, $password, $appkey, $uri) = @_;
    my $file = $helper->{file};
    $helper->{'engine'}   = $engine   || die 'No engine specified!';
    $helper->{'proxy'}    = $proxy    || die 'No proxy specified!';
    $helper->{'blogid'}   = $blogid   || die 'No blogid specified!';
    $helper->{'username'} = $username;
    $helper->{'password'} = $password;
    $helper->{'appkey'}   = $appkey;
    $helper->{'uri'}      = $uri;

    $helper->render_file('model', $file);
};

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    $helper->render_file('test', $test);
};

1;
__DATA__
__model__
package [% class %];
use strict;
use warnings;
use base 'Catalyst::Model::NetBlogger';

__PACKAGE__->config(
    engine   => '[% engine %]',
    proxy    => '[% proxy %]',
    blogid   => '[% blogid %]',
    username => '[% username %]',
    password => '[% password %]',
    appkey   => '[% appkey %]',
    uri      => '[% uri %]'
);

1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
__END__

=head1 NAME

Catalyst::Helper::Model::NetBlogger - Helper for Net::Blogger Models

=head1 SYNOPSIS

    script/create.pl model <newclass> NetBlogger <engine> <proxy> <blogid> [<username> <password> <appkey> <uri>]
    script/create.pl model Blog NetBlogger movabletype http://example.com/mt-xmlrpc.cgi 123 myuser mypass

=head1 DESCRIPTION

A Helper for creating models to post and retrieve blog entries.

=head1 METHODS

=head2 mk_compclass

Makes a NetBlogger Model class for you.

=head2 mk_comptest

Makes a NetBlogger Model test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::Model::NetBlogger>,
L<Net::Blogger>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
