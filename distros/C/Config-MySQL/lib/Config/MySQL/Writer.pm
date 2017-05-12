package Config::MySQL::Writer;

use warnings;
use strict;

use base 'Config::INI::Writer';

=head1 NAME

Config::MySQL::Writer - Write MySQL-style configuration files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

If C<$config> contains

    {
        'mysqld' => {
            'datadir'      => '/var/lib/mysql',
            'skip-locking' => undef,
        },
        'mysqldump' => {
            'quick'              => undef,
            'max_allowed_packet' => '16M',
        },
        '_' => {
            '!include' => [
                '/etc/my_extra.cnf',
                '/etc/my_other.cnf',
            ],
            '!includedir' => [
                '/etc/my.cnf.d',
            ],
        },
    }

Then when your program contains

    my $config = Config::MySQL::Writer->write_file( $config, 'my.cnf' );

F<my.cnf> will contain
    !include /etc/my_extra.cnf
    !include /etc/my_other.cnf
    !includedir /etc/my.cnf.d

    [mysqld]
    datadir=/var/lib/mysql
    skip-locking

    [mysqldump]
    quick
    max_allowed_packet = 16M

=head1 DESCRIPTION

This module extends L<Config::INI::Writer> to support writing
MySQL-style configuration files.  Although deceptively similar to
standard C<.INI> files, they can include bare boolean options with no
value assignment and additional features like C<!include> and C<!includedir>.

=head1 METHODS FOR WRITING CONFIG

=head2 write_file, write_string, and write_handle

See L<Config::INI::Writer/"METHODS FOR WRITING CONFIG"> for usage
details.

=head1 OVERRIDDEN METHODS

=head2 stringify_value_assignment

Copes with MySQL-style include directives and boolean properties that have no
value assignment

=cut

sub stringify_value_assignment {
    my ( $self, $name, $value ) = @_;
    return "$name\n" unless defined $value;
    if ( $name =~ /^!include(?:dir)?$/ && ref $value eq 'ARRAY' ) {
        return $name . ' ' . join( "\n$name ", @$value ) . "\n";
    } else {
        return $self->SUPER::stringify_value_assignment( $name, $value );
    }
}

=head1 SEE ALSO

=over 4

=item L<Config::INI>

=item L<MySQL::Config>

=item L<Config::Extend::MySQL>

=back

=head1 AUTHOR

Iain Arnell, C<< <iarnell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ini-mysql at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-MySQL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::MySQL::Writer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-MySQL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-MySQL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-MySQL>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-MySQL/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ricardo Signes for Config-INI.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Iain Arnell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Config::MySQL::Writer
