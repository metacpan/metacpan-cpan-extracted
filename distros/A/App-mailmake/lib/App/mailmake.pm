##----------------------------------------------------------------------------
## Mail Builder CLI - ~/lib/App/mailmake.pm
## Version v0.1.2
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/06
## Modified 2026/03/13
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package App::mailmake;
use strict;
use warnings;
use vars qw( $VERSION );
our $VERSION = 'v0.1.2';

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

App::mailmake - App harness for the mailmake CLI

=head1 SYNOPSIS

Run C<mailmake -h> or C<perldoc mailmake> for more options.

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

Tiny distribution wrapper so the C<mailmake> CLI can be installed via CPAN.
All functionality is in the C<mailmake> script.

=head1 INSTALLATION

=head2 Installing using cpanm

    cpanm App::mailmake

If you do not have C<cpanm>, check L<App::cpanminus>.

This will install C<mailmake> to your bin directory, e.g. C</usr/local/bin>.

=head2 Manual installation

Download from https://metacpan.org/pod/App::mailmake

Extract the archive:

    tar zxvf App-mailmake-v0.1.0.tar.gz

Then build and install:

    cd ./App-mailmake && perl Makefile.PL && make && make test && sudo make install

=head1 DEPENDENCIES

=over 4

=item * C<v5.16.0>

=item * C<Encode>

=item * C<Getopt::Class>

=item * C<Mail::Make>

=item * C<Module::Generic>

=item * C<Pod::Usage>

=item * C<Term::ANSIColor::Simple>

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::GPG>, L<Mail::Make::SMIME>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
