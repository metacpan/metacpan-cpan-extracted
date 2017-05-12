package Catalyst::Helper::Model::Redis;

use strict;
use warnings;

our $VERSION = "0.02";
$VERSION = eval $VERSION;

=head1 NAME

Catalyst::Model::Redis - Redis Model Class

=head1 VERSION

0.01

=head1 SYNOPSIS

    create model Redis Redis -- --host localhost --port 6379 --utf8

=head1 USAAGE

You can specify following configuration options:

=over 4

=item B<--host> I<hostname>

=item B<--port> I<port>

=item B<--database> I<db>

=item B<--password> I<password>

=item B<--lazy>

=item B<--utf8>

=back

See description of options in L<RedisDB> documentation.

=cut

=head2 $self->mk_compclass

Creates model class

=cut

use Getopt::Long qw(GetOptionsFromArray);

sub mk_compclass {
    my ( $class, $helper, @args ) = @_;
    my %conf;
    GetOptionsFromArray(
        \@args,
        "host=s"     => \$conf{host},
        "port=i"     => \$conf{port},
        "path=s"     => \$conf{path},
        "database=i" => \$conf{database},
        "password=s" => \$conf{password},
        "utf8"       => \$conf{utf8},
        "lazy"       => \$conf{lazy},
    ) or die "Invalid options for model";

    use Data::Dumper;
    warn Dumper [ \%conf ];
    my $file = $helper->{file};
    $helper->render_file( 'modelclass', $file, { conf => \%conf } );
}

=head2 $self->mk_comptest

creates test for model class

=cut

sub mk_comptest {
    my ( $self, $helper ) = @_;

    $helper->render_file( 'modeltest', $helper->{test} );
}

1;

=head1 SEE ALSO

L<Catalyst>, L<RedisDB>

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/trinitum/perl-Catalyst-Model-Redis/issues>.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__DATA__

=begin ignore

__modelclass__
package [% class %];
use strict;
use warnings;
use base 'Catalyst::Model::Redis';

__PACKAGE__->config(
[% FOR param IN conf -%]
[% IF param.value %]    [% param.key %] => "[% param.value %]",
[% END %]
[%- END -%]
);

1;

=head1 NAME

[% class %] - Redis Catalyst model

=head1 DESCRIPTION

Redis Catalyst model component. See L<Catalyst::Model::Redis>

__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');
