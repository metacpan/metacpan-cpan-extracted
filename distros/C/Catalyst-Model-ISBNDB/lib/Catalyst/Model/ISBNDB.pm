###############################################################################
#
# This file copyright (c) 2008-2009 by Randy J. Ray, all rights reserved
#
# Copying and distribution are permitted under the terms of the Artistic
# License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php) or
# the GNU LGPL (http://www.opensource.org/licenses/lgpl-license.php).
#
###############################################################################
#
#   Description:    A Catalyst model for providing access to the isbndb.com
#                   web service.
#
#   Functions:      get_agent
#                   allocate_agent
#
#   Libraries:      WebService::ISBNDB::API
#                   NEXT
#
#   Global Consts:  $VERSION
#
###############################################################################

package Catalyst::Model::ISBNDB;

use 5.008;
use strict;
use warnings;
use vars qw($VERSION);
use base 'Catalyst::Model';

use NEXT;
use WebService::ISBNDB::API;

$VERSION = '0.12';
$VERSION = eval $VERSION;  ## no critic

BEGIN
{
	# Don't let Perl::Critic whinge about this; I don't want to add
	# Sub::Installer to my deps list...
    no strict 'refs'; ## no critic

    my %map = ( Authors    => 'author',
                Books      => 'book',
                Categories => 'category',
                Publishers => 'publisher',
                Subjects   => 'subject' );

    for my $method (keys %map)
    {
        my $name = "find_$map{$method}";
        *$name = sub
            {
                my ($self, $id) = @_;

                my $api = $self->get_agent;
                my $obj;
                eval { $obj = $api->find($method => $id); };
                die "$@" if $@;

                $obj;
            };

        $name = 'search_' . lc $method;
        *$name = sub
            {
                my ($self, $args) = @_;

                my $api = $self->get_agent;
                my $iter;
                eval { $iter = $api->search($method => $args); };
                die "$@" if $@;

                $iter;
            };
    }
}

###############################################################################
#
#   Sub Name:       get_agent
#
#   Description:    Get the agent from the config for this class. If none has
#                   been set yet, thread through to the allocation of one.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Returns:        Success:    agent instance
#                   Failure:    dies
#
###############################################################################
sub get_agent
{
    my $self = shift;
    my $config = $self->config;

    $config->{agent} || $self->allocate_agent($config);
}

###############################################################################
#
#   Sub Name:       allocate_agent
#
#   Description:    Allocate an agent. Store it on the config and return the
#                   new object. Uses the value from calling
#                   WebService::ISBNDB::API::get_default_agent().
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $config   in      hashref   The config info for this class
#                                                 (it was already available)
#
#   Returns:        Success:    new agent
#                   Failure:    dies
#
###############################################################################
sub allocate_agent
{
    my ($self, $config) = @_;

    my $key = $config->{access_key} ||
        WebService::ISBNDB::API->get_default_api_key;

    $config->{agent} = WebService::ISBNDB::API->new({ api_key => $key });
}

1;

=pod

=head1 NAME

Catalyst::Model::ISBNDB - Provide Catalyst access to isbndb.com

=head1 SYNOPSIS

    package MyApp::Model::ISBNDB;
    use base 'Catalyst::Model::ISBNDB';

    __PACKAGE__->config(access_key => 'XXX');

    # Within a Catalyst application:
    my $book = $c->model('ISBNDB')->find_book($isbn);

=head1 DESCRIPTION

This package provides a Catalyst model that makes requests of the
B<isbndb.com> web service, using their published REST interface. The model
creates an instance of the B<WebService::ISBNDB::API> class and uses it as
a factory for making requests for data in any of the classes supported
(Authors, Books, Categories, Publishers and Subjects).

=head1 CONFIGURATION

The model requires the application to configure a valid access key
from the B<isbndb.com> service:

    __PACKAGE__->config(access_key => $KEY)

No other configuration is needed. If you choose to load and manipulate the
B<WebService::ISBNDB::API> class directly, you may also use the
C<set_default_api_key> method of that class to set your access key.

=head1 METHODS

The following methods are available to users or sub-classes:

=over 4

=item find_author($ID)

=item find_book($ISBN|$ID)

=item find_category($ID)

=item find_publisher($ID)

=item find_subject($ID)

Find a single record of the respective type, using the ID. When searching for
a book, the ISBN may be specified instead of an ID. Returns the matching
object, C<undef> if no match is found, or throws an exception if an error
occurs.

=item search_authors($ARGS)

=item search_books($ARGS)

=item search_categories($ARGS)

=item search_publishers($ARGS)

=item search_subjects($ARGS)

Perform a search for the respective type of records. The parameter is a
hash-reference of search terms, as defined in the corresponding manual pages
for the types that derive from B<WebService::ISBNDB::API>. The return value
is a B<WebService::ISBNDB::Iterator> instance. An exception is thrown on
error.

=item get_agent

This method is called by the previous methods to retrieve the internal API
factory agent. If one has not yet been created, it is first created and
then returned.

=item allocate_agent($CONFIG)

The first time get_agent() is called, it calls this method to allocate an
instance of B<WebService::ISBNDB::API>. The single parameter is the
configuration information from Catalyst. This is used to look up the access
key that would have been configured when the application started. The return
value is either an API object instance, or an exception is thrown to signal
an error.

=back

=head1 CAVEATS

In order to access the B<isbndb.com> service, you must register on their site
and create an API access key.

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<WebService::ISBNDB::Iterator>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-model-isbndb at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-ISBNDB>. I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-ISBNDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-ISBNDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Model-ISBNDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-ISBNDB>

=item * Source code on GitHub

L<http://github.com/rjray/catalyst-model-isbndb/tree/master>

=back

=head1 COPYRIGHT & LICENSE

This file and the code within are copyright (c) 2009 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 2.0 (L<http://www.opensource.org/licenses/artistic-license-2.0.php>) or
the GNU LGPL 2.1 (L<http://www.opensource.org/licenses/lgpl-2.1.php>).

=head1 AUTHOR

Randy J. Ray C<< <rjray@blackperl.com> >>

=cut
