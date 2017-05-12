# $Id: /mirror/claco/Catalyst-Model-SVN/branches/devel-0.07-t0m/lib/Catalyst/Helper/Model/SVN.pm 695 2005-11-02T00:59:12.554101Z claco  $
package Catalyst::Helper::Model::SVN;
use strict;
use warnings;

sub mk_compclass {
    my ($self, $helper, $repository, $revision) = @_;
    my $file = $helper->{file};
    $helper->{'repository'}  = $repository  || die 'No repository specified!';
    $helper->{'revision'} = $revision || 'HEAD';

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
use base 'Catalyst::Model::SVN';

__PACKAGE__->config(
    repository => '[% repository %]',
    revision => '[% revision %]'
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

Catalyst::Helper::Model::SVN - Helper for SVN Models

=head1 SYNOPSIS

    script/create.pl model <newclass> SVN <repository> [<revision>]
    script/create.pl model SVN SVN http://xample.com/svn/repos HEAD

=head1 DESCRIPTION

A Helper for creating models to browse Subversion repositories.

=head1 METHODS

=head2 mk_compclass

Makes a SVN Model class for you.

=head2 mk_comptest

Makes a SVN Model test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::Model::SVN>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
