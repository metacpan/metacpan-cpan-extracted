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
#   Description:    Helper file for auto-generating Catalyst::Model::ISBNDB
#                   sub-classes by means of a Catalyst project's create.pl
#                   script.
#
#   Functions:      mk_compclass
#                   mk_comptest
#
#   Global Consts:  $VERSION
#
###############################################################################

package Catalyst::Helper::Model::ISBNDB;

use 5.008;
use strict;
use warnings;
use vars qw($VERSION);
use subs qw(mk_compclass mk_comptest);

use Catalyst::Model::ISBNDB;

$VERSION = '0.12';
$VERSION = eval $VERSION;  ## no critic

=head1 NAME

Catalyst::Helper::Model::ISBNDB - Catalyst::Helper assist for ISBNDB

=head1 SYNOPSIS

    perl script/myapp_create.pl model MyISBNDB ISBNDB API_KEY

=head1 DESCRIPTION

This is a B<Catalyst::Helper> component to allow you to add model components
deriving from the B<Catalyst::Model::ISBNDB> class, using the
Catalyst-generated C<create.pl> helper-script.

When run via the creation-helper, a new model class and a simple test suite
for it will be added to your Catalyst application. The class will be added in
the same directory as your other models, and the test added to the C<t/>
directory in the top-level of the project.

=head1 USAGE

When the helper script is invoked, you provide it with 3 or 4 arguments:

=over 4

=item C<model>

This is always C<model>, when adding a model component.

=item C<MyClass>

The name of the new class you want to add.

=item C<ISBNDB>

The name of the model class you are deriving from, B<ISBNDB> in this case.

=item C<API_KEY>

(This parameter is optional.)

The B<isbndb.com> API key your application will be using, if you wish to have
it explicitly defined in the configuration block of the new class.

=back

You can provide just C<model> and C<ISBNDB> alone (two arguments), in which
case the new class will be given a name using your project's class hierarchy
and ending in C<ISBNDB>, and no default API key will be configured.

=head1 METHODS

This class defines the following two methods:

=over 4

=item mk_compclass($SELF, $HELPER, [$KEY])

Creates the class by using the B<Catalyst::Helper> instance pointed to by
C<$HELPER>. If C<$KEY> is passed and is non-null, the call to C<config> in
the generated class will set the value as the default API key used for data
calls to B<isbndb.com>.

=cut

###############################################################################
#
#   Sub Name:       mk_compclass
#
#   Description:    Create the component class from one of the two templates
#                   provided later, after the __DATA__ token.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $helper   in      ref       Catalyst::Helper instance
#                   $api_key  in      scalar    Default API key to use
#
#   Returns:        1
#
###############################################################################
sub mk_compclass
{
    my ($self, $helper, $api_key) = @_;

    $helper->{api_key} = $api_key || '';
    $helper->{this_module} = __PACKAGE__ . "/$VERSION";
    $helper->{base_module} =
        "Catalyst::Model::ISBNDB/$Catalyst::Model::ISBNDB::VERSION";

    $helper->render_file('modelclass', $helper->{file});

    1;
}

=item mk_comptest($SELF, $HELPER)

Creates the unit test suite for the new model. Does this by using the
C<Catalyst::Helper> instance pointed to by C<$HELPER>.

=cut

###############################################################################
#
#   Sub Name:       mk_comptest
#
#   Description:    Create the a basic test-suite for the component class,
#                   using the other of the two templates provided after the
#                   __DATA__ token.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $helper   in      ref       Catalyst::Helper instance
#
#   Returns:        1
#
###############################################################################
sub mk_comptest
{
    my ($self, $helper) = @_;

    $helper->render_file('modeltest', $helper->{test});

    1;
}

=pod

=back

=head1 SEE ALSO

L<Catalyst::Model::ISBNDB>, L<Catalyst::Helper>

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

1;

__DATA__

=begin pod_to_ignore

__modelclass__
# Automatically-generated model component. See [% base_module %].
# Generated via helper-class [% this_module %].

package [% class %];

use strict;
use warnings;
use base 'Catalyst::Model::ISBNDB';

[% IF api_key %]__PACKAGE__->config(access_key => '[% api_key %]');

[% END %]=head1 NAME

[% class %] - Catalyst model derived from Catalyst::Model::ISBNDB

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

This is a Catalyst model component that accesses the B<isbndb.com> web
service. It sub-classes the existing B<Catalyst::Model::ISBNDB> model.

=head1 AUTHOR

[% author %]

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');

exit;
