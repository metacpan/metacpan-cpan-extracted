package Config::From;
$Config::From::VERSION = '0.06';

use utf8;
use Moose;

use Moose::Util::TypeConstraints;
use Carp qw/croak/;
use Module::Load;
use Hash::Merge qw( merge );



has 'debug' => (
                is       => 'rw',
               );

has  config => (
               isa        => "HashRef",
               is         => "rw",
 );

has  backends => (
               isa        => "ArrayRef",
               is         => "rw",
               default    => sub {[]},
               trigger    => sub {
                   shift->_build_config;
               },
           );


sub _build_config {
    my $self = shift;

    $self->_log("build config ...");

    my $config = {};
    foreach my $backend ( @{$self->backends }) {
        $self->_log("merge config " . ($backend->name || ref($backend)));
        $config = merge( $config, $backend->datas );
    }
    $self->config($config);
}

# XXX: => role
sub _log{
  my ($self, $msg ) = @_;

  return if ! $self->debug;

  say STDERR "[debug] $msg";
}



=head1 NAME

Config::From - Merge the configuration from several sources


=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Config::From;

    my $bckfile = Config::From::Backend::File->new(file => 't/conf/file1.yml');
    my $bckdbix = Config::From::Backend::DBIx->new(schema => $schema, table => 'Config');

    my $config = Config::From->new( backends => [ $bckfile, $bckdbix] )->config;


=head1 SUBROUTINES/METHODS



=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ordered at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-From>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::From


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-From>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-From>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-From>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-From/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Config::From
