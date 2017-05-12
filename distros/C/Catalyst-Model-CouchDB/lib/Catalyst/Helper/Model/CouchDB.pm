
package Catalyst::Helper::Model::CouchDB;
use strict;
use warnings;

our $VERSION = '0.01';

=pod

=head1 NAME

Catalyst::Helper::Model::CouchDB - Helper for CouchDB models

=head1 SYNOPSIS

 script/myapp_create.pl model MyModel CouchDB uri

=head1 DESCRIPTION

Helper for the L<Catalyst> CouchDB model.

=head1 USAGE

When creating a new CouchDB model class using this helper, you may specify
the server to which to connect (assuming you don't intend to load that
parameter from an external configuration). If you would like to see other
options exposed simply ask.

=head1 METHODS

=head2 mk_compclass

Makes the model class.

=head2 mk_comptest

Makes tests.

=cut

sub mk_compclass {
    my ($self, $helper, $uri) = @_;

    $helper->{uri} = $uri if $uri;
    $helper->render_file('modelclass', $helper->{file});
    return 1;
}

sub mk_comptest {
    my ($self, $helper) = @_;
    $helper->render_file('modeltest', $helper->{test});
}

=pod

=head1 AUTHOR

Robin Berjon, <robin @t berjon d.t com>

=head1 BUGS 

Please report any bugs or feature requests to bug-catalyst-model-couchdb at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-CouchDB.

=head1 COPYRIGHT & LICENSE 

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may 
have available.

=cut

1;

__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use strict;
use warnings;
use base 'Catalyst::Model::CouchDB';

[% IF uri %]
__PACKAGE__->config(
    uri => '[% uri %]',
);
[% END %]

=head1 NAME

[% class %] - CouchDB Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

CouchDB Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');
