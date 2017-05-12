package Catalyst::Helper::Model::MogileFS::Client;

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::MogileFS::Client - Helper for MogileFS Client models.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

script/myapp_create.pl model My::Model::Name MogileFS::Client [my.domain]

=head1 DESCRIPTION

Helper class for Catalyst::Model::MogileFS::Client.

=head1 METHODS

=head2 mk_compclass

Makes MogileFS Client model class

=cut

sub mk_compclass {
    my ( $self, $helper, $domain ) = @_;

    $helper->{domain} = $domain || '';
    $helper->render_file( 'modelclass', $helper->{file} );

    return 1;
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-helper-model-mogilefs-client at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue==Catalyst-Model-MogileFS-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Helper::Model::MogileFS::Client

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/=Catalyst-Model-MogileFS-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/=Catalyst-Model-MogileFS-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist==Catalyst-Model-MogileFS-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/=Catalyst-Model-MogileFS-Client>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Catalyst::Helper::Model::MogileFS::Client

__DATA__

=begin pod_to_ignore

__modelclass__

package [% class %];

use strict;
use warnings;

use base qw/Catalyst::Model::MogileFS::Client/;

__PACKAGE__->config([% IF domain %]
  domain => '[% domain %]'
[% END %]);

=head1 NAME

[% class %] - Catalyst MogileFS Client Model

=head1 SYNOPSIS

SEE L<[% app %]>

=head1 DESCRIPTION

SEE L<Catalyst::Model::MogileFS::Client>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

