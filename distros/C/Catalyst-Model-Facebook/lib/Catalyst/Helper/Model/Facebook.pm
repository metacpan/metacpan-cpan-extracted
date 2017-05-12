package Catalyst::Helper::Model::Facebook;
BEGIN {
  $Catalyst::Helper::Model::Facebook::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Catalyst::Helper::Model::Facebook::VERSION = '0.101';
}
# ABSTRACT: Helper for Facebook models
use strict;
use warnings;


sub mk_compclass {
    my ( $self, $helper, $app_id, $api_key, $secret, $facebook_class, $facebook_signed_class ) = @_;

	my %args = (
		app_id => $app_id,
		api_key => $api_key,
		secret => $secret,
		facebook_class => $facebook_class,
		facebook_signed_class => $facebook_signed_class,
	);

    my $file = $helper->{file};
    (my $template = do { local $/; <DATA> }) =~ s/^\s\s//g;
    $helper->render_file_contents($template, $file);
	
    $helper->render_file('modelclass', $helper->{file}, \%args);
    return 1;
}

sub mk_comptest {
    my ($self, $helper) = @_;
    $helper->render_file('modeltest', $helper->{test});
}


1;



=pod

=head1 NAME

Catalyst::Helper::Model::Facebook - Helper for Facebook models

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  script/myapp_create.pl model MyModel Facebook app_id api_key secret [facebook_class] [facebook_signed_class]

=head1 DESCRIPTION

Helper for the L<Catalyst> L<Facebook> model.

=head1 NAME

  Catalyst::Helper::Model::Facebook - Helper for Facebook models

=head1 USAGE

=head1 METHODS

=head2 mk_compclass

Makes the model class.

=head2 mk_comptest

Makes tests.

=head1 SUPPORT

IRC

  Join #facebook on irc.perl.org.

Repository

  http://github.com/Getty/p5-catalyt-model-facebook
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-catalyt-model-facebook/issues

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=item *

Frank Sheiness <syndesis@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Facebook Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use Moose;
extends 'Catalyst::Model::Facebook';

__PACKAGE__->config(
	app_id => '[% app_id %]',
	api_key => '[% api_key %]',
	secret => '[% secret %]',
	facebook_class => '[% facebook_class || 'Facebook' %]',
	facebook_signed_class => '[% facebook_signed_class || 'Facebook::Signed' %]',
);

=head1 NAME

[% class %] - Facebook Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Facebook Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');
