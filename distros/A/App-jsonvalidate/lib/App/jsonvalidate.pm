##----------------------------------------------------------------------------
## JSON Schema Validator - ~/lib/App/jsonvalidate.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/11/10
## Modified 2025/11/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package App::jsonvalidate;
use strict;
use warnings;
use vars qw( $VERSION );
our $VERSION = 'v0.1.0';

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

App::jsonvalidate - App harness for the jsonvalidate CLI

=head1 SYNOPSIS

Run C<jsonvalidate -h> or C<perldoc jsonvalidate> for more options.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Tiny distribution wrapper so the C<jsonvalidate> CLI can be installed via CPAN. All functionality is in the C<jsonvalidate> script.

=head1 INSTALLATION

=head2 Installing using cpanm

    cpanm App::jsonvalidate

If you do not have C<cpanm>, check L<App::cpanminus>

This will install C<jsonvalidate> to your bin directory like C</usr/local/bin>

=head2 Manual installation

Download from https://metacpan.org/pod/App::jsonvalidate

Extract the data from the archive

    tar zxvf App::jsonvalidate-v0.1.0.tar.gz

Then, go into the newly created directory, build, and install

    cd ./App::jsonvalidate && perl Makefile.PL && make && make test && sudo make install

=head1 DEPENDENCIES

=over 4

=item * C<v5.16.0>

=item * C<Getopt::Class>

=item * C<JSON>

=item * C<JSON::Schema::Validate>

=item * C<Module::Generic>

=item * C<Pod::Usage>

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<JSON::Schema::Validate>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
