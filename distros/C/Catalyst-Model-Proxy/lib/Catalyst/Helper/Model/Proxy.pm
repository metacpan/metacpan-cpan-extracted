package Catalyst::Helper::Model::Proxy;

use strict;
use File::Spec;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Helper::Model::Proxy - Helper for Proxy Models

=head1 SYNOPSIS

    script/create.pl model Proxy Proxy dsn user password

=head1 DESCRIPTION

Helper for Proxy Model.

=head2 METHODS

=over 4

=item mk_compclass

Reads the database and makes a main model class

=item mk_comptest

Makes tests for the Proxy Model.

=back 

=cut

sub mk_compclass {
  my ( $self, $helper, $target_class, $subroutines ) = @_;
  $helper->{target_class} = $target_class  || '';
  $helper->{subroutines} = $subroutines || '';
  my $file = $helper->{file};
  $helper->render_file( 'dbiclass', $file );
  return 1;
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__DATA__

__dbiclass__
package [% class %];

use strict;
use base 'Catalyst::Model::Proxy';

__PACKAGE__->config(
    target_class           => '[% target_class %]',
    subroutines            => '[ [% subroutines %] ]'
);

=head1 NAME

[% class %] - Proxy Model Class

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Proxy Model Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
