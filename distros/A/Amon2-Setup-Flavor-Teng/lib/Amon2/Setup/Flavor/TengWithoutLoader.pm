use strict;
use warnings;
use utf8;

package Amon2::Setup::Flavor::TengWithoutLoader;
use parent qw(Amon2::Setup::Flavor);

sub run {
    my $self = shift;

    $self->write_file('lib/<<PATH>>.pm', <<'...');
package <% $module %>;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
use 5.008001;

__PACKAGE__->load_plugin(qw/DBI/);

# initialize database
use DBI;
sub setup_schema {
    my $self = shift;
    my $dbh = $self->dbh();
    my $driver_name = $dbh->{Driver}->{Name};
    my $fname = lc("sql/${driver_name}.sql");
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    my $source = do { local $/; <$fh> };
	for my $stmt (split /;/, $source) {
        next unless $stmt =~ /\S/;
		$dbh->do($stmt) or die $dbh->errstr();
	}
}

use <% $module %>::DB;
sub db {
    my $self = shift;
    if ( !defined $self->{db} ) {
        my $conf = $self->config->{'DBI'}
        or die "missing configuration for 'DBI'";
        my $dbh = DBI->connect(@{$conf});
        $self->{db} = <% $module %>::DB->new(
            dbh    => $dbh,
	    );
    }
    return $self->{db};
}

1;
...

    $self->write_file('lib/<<PATH>>/DB.pm', <<'...');
package <% $module %>::DB;
use parent qw(Teng);
1;
...

    $self->write_file('lib/<<PATH>>/DB/Schema.pm', <<'...');
package <% $module %>::DB::Schema;
use Teng::Schema::Declare;

table {
    name 'sessions';
    pk 'id';
    columns qw(id session_data);
};

1;
...

    $self->write_file('t/09_teng_without_loader.t', <<'...');
use strict;
use warnings;
use Test::More;
use <% $module %>;

my $teng = <% $module %>->new;
is(ref $teng, '<% $module %>', 'instance');
is(ref $teng->db, 'My::App::DB', 'instance');
$teng->db->do("create table if not exists sessions (id char(72) primary key, session_data text)") or die $teng->db->errstr;
$teng->db->insert('sessions', { id => 'abcdefghijklmnopqrstuvwxyz', session_data => 'ka2u' });
my $res = $teng->db->single('sessions', { id => 'abcdefghijklmnopqrstuvwxyz' });
is($res->get_column('session_data'), 'ka2u', 'search');
$teng->db->delete('sessions', {id => 'abcdefghijklmnopqrstuvwxyz'});

done_testing;
...
}

1;

__END__

=encoding utf-8

=head1 NAME

Amon2::Setup::Flavor::TengWithoutLoader - Teng Schema Flavor for Amon2

=head1 SYNOPSIS

    amon2-setup.pl --flavor Basic,TengWithoutLoader My::App

=head1 DESCRIPTION

Easy setup Teng ORM for Amon2.
This doesn't use Teng::Schema::Loader, create schema class.

=head1 AUTHOR

Kazuhiro Shibuya

=head1 SEE ALSO

Amon2 L<http://search.cpan.org/~tokuhirom/Amon2/> , Teng L<http://search.cpan.org/~nekokak/Teng/>

=head1 LICENSE

Copyright (C) Kazuhiro Shibuya

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
