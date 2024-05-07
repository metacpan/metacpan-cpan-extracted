package Test2::Tools::QuickDB;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use Test2::API qw/context/;
use DBIx::QuickDB();

use Importer Importer => 'import';

our @EXPORT = qw/get_db_or_skipall get_db skipall_unless_can_db/;

sub skipall_unless_can_db {
    my %spec;
    if (@_ == 1) {
        my $type = ref($_[0]) || '';
        if (!$type) {
            $spec{driver} = $_[0];
        }
        elsif ($type eq 'ARRAY') {
            $spec{drivers} = $_[0];
        }
        elsif ($type eq 'HASH') {
            %spec = %{$_[0]};
        }
        else {
            croak "Invalid Argument: $_[0]";
        }
    }
    else {
        %spec = @_;
    }

    my $ctx = context();

    $spec{bootstrap} = 1 unless defined $spec{bootstrap};
    $spec{autostart} = 1 unless defined $spec{autostart};
    $spec{load_sql}  = 1 unless defined $spec{load_sql};

    my $drivers = $spec{driver} ? [$spec{driver}] : $spec{drivers} || [DBIx::QuickDB->plugins];

    my $reason;
    my $ok = 0;
    for my $driver (@$drivers) {
        next unless defined $driver;
        my ($v, $fqn, $why) = DBIx::QuickDB->check_driver($driver, \%spec);
        $reason = $why if @$drivers == 1;
        next unless $v;
        $ok = $fqn;
        last;
    }

    if ($ok) {
        $ctx->release;
        return $ok;
    }

    $ctx->plan(0, 'SKIP' => $reason || "no db driver is viable");
    $ctx->release;

    return;
}

sub get_db {
    # Get a context in case anything below here has testing code.
    my $ctx = context();

    my $db = DBIx::QuickDB->build_db(@_);

    $ctx->release;

    return $db;
}

sub get_db_or_skipall {
    my $name = ref($_[0]) ? undef : shift(@_);
    my $spec = shift(@_) || {};

    my $ctx = context();

    skipall_unless_can_db(%$spec);
    my $db = get_db($name ? $name : (), $spec);

    $ctx->release;

    return $db;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::QuickDB - Quickly spin up temporary Database servers for tests.

=head1 DESCRIPTION

This is a test library build around DBIx::QuickDB.

=head1 SYNOPSIS

    use Test2::V0 -target => DBIx::QuickDB::Driver::PostgreSQL;
    use Test2::Tools::QuickDB;

    skipall_unless_can_db(driver => 'PostgreSQL');

    my $db = get_db(driver => 'PostgreSQL', load_sql => 't/schema/postgresql.sql'});

    ...

=head1 EXPORTS

=over 4

=item $driver = skipall_unless_can_db('MyDriver')

=item $driver = skipall_unless_can_db(['MyDriver', 'OurDriver'])

=item $driver = skipall_unless_can_db(%spec)

This will look for a usable driver. If no usable driver is found, this will
issue a skip_all to skip the current test or subtest. If at least one suable
driver is found then the first one found will be returned.

If you pass in 1 argument it should either be a driver to try, or an arrayref
of drivers to try.

If you passing multiple argument then you should follow the specifications in
L<DBIx::QuickDB/"SPEC HASH">.

Feel free to ignore the return value.

=item $db = get_db

=item $db = get_db($name)

=item $db = get_db(\%spec)

=item $db = get_db($name, \%spec)

=item $db = get_db $name => \%spec

Get a database.

With no arguments it will give you an instance of the first working driver it
finds.

You can provide a name for the db, the same instance can then be retrieved
anywhere B<GLOBALLY> using the same name.

You can provide a spec hashref which can contain any arguments documented in
L<DBIx::QuickDB/"SPEC HASH">.

=item $db = get_db_or_skipall $name => \%spec

=item $db = get_db_or_skipall($name, \%spec)

=item $db = get_db_or_skipall($name)

=item $db = get_db_or_skipall(\%spec)

This combines C<get_db()> and C<skipall_unless_can_db()>. The arguments
supported are identical to C<get_db()>.

=back

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
