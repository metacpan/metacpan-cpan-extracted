# $Id: /mirror/perl/Catalyst-Plugin-Apoptosis/trunk/lib/Catalyst/Plugin/Apoptosis.pm 2552 2007-09-18T08:36:57.555445Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Catalyst::Plugin::Apoptosis;
use strict;
use warnings;
our $VERSION = '0.00002';

sub handle_request
{
    my ($class, @arguments) = @_;
    my $status = $class->NEXT::handle_request(@arguments);

    $class->check_apoptosis_condition();

    return $status;
}

sub check_apoptosis_condition {}

package Catalyst::Exception::Apoptosis;
use strict;
use base qw(Catalyst::Exception);

1;

__END__

=head1 NAME

Catalyst::Plugin::Apoptosis - Stop Execution Of A Catalyst App

=head1 SYNOPSIS

  use Catalyst qw(
    Apoptosis::GTop
  );
  __PACKAGE__->config(
    apoptosis => {
      gtop => {
        size => 1_000_000
      }
    }
  )

=head1 DESCRIPTION

Sometimes you're bound by the amount of memory you can use, so you want your
long-running app to exit gracefully. This plugin overrides handle_request()
and attempts to exit the application when such conditions area reached.

=head1 METHODS

=head2 handle_request

=head2 check_apoptosis_condition

=head1 TODO

Tests. Other apoptosis conditions.

=head1 SEE ALSO

L<Catalyst::Plugin::Apoptosis::GTop|Catalyst::Plugin::Apoptosis::GTop>

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut