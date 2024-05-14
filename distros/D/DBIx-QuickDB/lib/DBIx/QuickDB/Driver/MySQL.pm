package DBIx::QuickDB::Driver::MySQL;
use strict;
use warnings;

our $VERSION = '0.000033';

use Carp qw/confess croak/;
use Scalar::Util qw/reftype blessed/;
use Capture::Tiny qw/capture/;

use DBIx::QuickDB::Driver::MariaDB;
use DBIx::QuickDB::Driver::Percona;

use parent 'DBIx::QuickDB::Driver';
use DBIx::QuickDB::Util::HashBase;

sub choose {
    my $this = shift;

    my $spec = { bootstrap => 1, load_sql => 1 };

    my ($ok, $why) = DBIx::QuickDB::Driver::MariaDB->viable($spec);
    return 'DBIx::QuickDB::Driver::MariaDB' if $ok;

    ($ok, $why) = DBIx::QuickDB::Driver::Percona->viable($spec);
    return 'DBIx::QuickDB::Driver::Percona' if $ok;

    return undef;
}

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my ($ok1, $why1) = DBIx::QuickDB::Driver::MariaDB->viable($spec);
    my ($ok2, $why2) = DBIx::QuickDB::Driver::Percona->viable($spec);

    return (1, undef) if $ok1 || $ok2;

    return (0, join("\n" => $why1, $why2));
}

sub new {
    my $class = shift;

    my $real_class = $class->choose or croak("Neither MariaDB or Percona are viable");
    return $real_class->new(@_);
}

sub version_string {
    my ($class, @other) = @_;

    my $binary;

    # Go in reverse order assuming the last param hash provided is most important
    for my $arg (reverse @_) {
        my $type = reftype($arg) or next;    # skip if not a ref
        next unless $type eq 'HASH';         # We have a hashref, possibly blessed

        # If we find a launcher we are done looping, we want to use this binary.
        if (blessed($arg) && $arg->can('server_bin')) {
            $binary = $arg->server_bin and last;
        }

        for my $l (qw/server_bin mysqld mariadbd/) {
            $binary = $arg->{$l} and last;
        }

        last if $binary;
    }

    if (my $sel = $class->choose) {
        $binary ||= $sel->server_bin or croak "Could not find a viable server binary";
    }

    # Call the binary with '-V', capturing and returning the output using backticks.
    my ($v) = capture { system($binary, '-V') };

    return $v;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::MySQL - MySQL driver for DBIx::QuickDB.

=head1 DESCRIPTION

MySQL driver for L<DBIx::QuickDB>.

This will automatically pick L<DBIx::QuickDB::Driver::MariaDB> or
L<DBIx::QuickDB::Driver::Percona> depending on which provider your MySQL was
built by.

=head1 SYNOPSIS

See L<DBIx::QuickDB>.

=head1 MYSQL SPECIFIC OPTIONS

=over 4

=item dbd_driver => $DRIVER

Should be either L<DBD::mysql> or L<DBD::MariaDB>. If not specified then
DBD::MariaDB is preferred with a fallback to DBD::MySQL.

=back

=head1 ENVIRONMENT VARIABLES

=head2 QDB_MYSQL_SSL_FIPS

Set to 1 to enable, 0 to disable or enter any string accepted by the
C<ssl_fips_mode> mysqld config option. If this environment variable is not
defined then the C<ssl_fips_mode> option will not be included in the generated
config file at all by default.

This is mainly used to allow this dists test suite to pass on systems where
FIPS is required and enforced.

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
