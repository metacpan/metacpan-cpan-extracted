package Catalyst::Helper::Model::Bitcoin;

use strict;
use warnings;

our $VERSION = '0.02';


sub mk_compclass {
  my ($self, $helper, $uri) = @_;

  $helper->{uri} = $uri;

  $helper->render_file('bitcoin', $helper->{file});
}

1;

=head1 NAME

Catalyst::Helper::Model::Bitcoin - Helper class for Bitcoin models 

=head1 SYNOPSIS

  ./script/myapp_create.pl model BitcoinClient Bitcoin

=head1 DESCRIPTION

A Helper for creating models to interface with Bitcoin Server

=head1 SEE ALSO

L<https://github.com/hippich/Catalyst--Model--Bitcoin>, L<https://www.bitcoin.org>, L<Finance::Bitcoin>, L<Catalyst>

=head1 AUTHOR

Pavel Karoukin
E<lt>pavel@yepcorp.comE<gt>
http://www.yepcorp.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pavel Karoukin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

__DATA__
=begin pod_to_ignore

__bitcoin__
package [% class %];

use strict;
use warnings;

use base qw/ Catalyst::Model::Bitcoin /;

__PACKAGE__->config(
  uri => '[% uri %]',
);

=head1 NAME

[% class %] - Bitcoin Server Model Class

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION 

Bitcoin Server Model Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;
