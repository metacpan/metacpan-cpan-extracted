package Dancer::SearchApp::Utils;
use strict;
use Exporter 'import';
use AnyEvent;

use vars qw(@EXPORT_OK $VERSION);
$VERSION = '0.06';
@EXPORT_OK = (qw(await));

=head1 NAME

Dancer::SearchApp::Utils - helper routines

=head1 EXPORTS

=head2 C<< await >>

  sub some_routine {
      my $p = deferred;
      ...
      $p->promise
  }

  my $result = await some_routine( ... );
  print $result;

Waits for a promise to be fulfilled. Needs L<AnyEvent>
to wait for a promise.

=cut

sub await($) {
    my $promise = $_[0];
    my @res;
    if( $promise->is_unfulfilled ) {
        require AnyEvent;
        my $await = AnyEvent->condvar;
        $promise->then(sub{ $await->send(@_)});
        @res = $await->recv;
    } else {
        @res = @{ $promise->result }
    }
    @res
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/dancer-searchapp>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 TALKS

I've given a talk about this module at Perl conferences:

L<German Perl Workshop 2016, German|http://corion.net/talks/dancer-searchapp/dancer-searchapp.html>

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dancer-SearchApp>
or via mail to L<dancer-searchapp-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut