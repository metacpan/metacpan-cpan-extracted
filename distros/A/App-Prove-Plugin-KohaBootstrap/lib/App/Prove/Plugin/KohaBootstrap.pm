package App::Prove::Plugin::KohaBootstrap;

use 5.010;
use strict;
use warnings;

use DBI;
use File::Temp qw( tempfile );
use XML::LibXML;

=head1 NAME

App::Prove::Plugin::KohaBootstrap - prove plugin to run Koha tests on a separate database

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    prove -P KohaBootstrap=database,koha_test,marcflavour,MARC21

=head1 SUBROUTINES/METHODS

=head2 load

Drop and recreate a database, and run the necessary installation steps to fill
the database

=cut

sub load {
    my ($class, $p) = @_;

    my $app  = $p->{app_prove};
    my %args = @{ $p->{args} };

    unless (defined $args{database}) {
        die "Test database is not defined";
    }

    $args{marcflavour} //= 'MARC21';

    my $xml = XML::LibXML->load_xml(location => $ENV{KOHA_CONF});
    my $root = $xml->documentElement();
    my ($databaseElement) = $root->findnodes('//config/database');
    my $currentDatabase = $databaseElement->textContent();

    if ($currentDatabase eq $args{database}) {
        die "Test database is the same as database in KOHA_CONF, abort!";
    }

    $databaseElement->firstChild()->setData($args{database});

    my ($fh, $filename) = tempfile('koha-conf.XXXXXX', TMPDIR => 1, UNLINK => 1);
    $xml->toFH($fh);
    close $fh;

    $ENV{KOHA_CONF} = $filename;

    require C4::Context;
    C4::Context->import;

    require C4::Installer;
    C4::Installer->import;

    require C4::Languages;

    my $host = C4::Context->config('hostname');
    my $port = C4::Context->config('port');
    my $database = C4::Context->config('database');
    my $user = C4::Context->config('user');
    my $pass = C4::Context->config('pass');

    say "Create test database $database...";

    my $dbh = DBI->connect("dbi:mysql:;host=$host;port=$port", $user, $pass, {
        RaiseError => 1,
        PrintError => 0,
    });

    $dbh->do("DROP DATABASE IF EXISTS $database");
    $dbh->do("CREATE DATABASE $database");

    my $installer = C4::Installer->new();
    $installer->load_db_schema();
    $installer->set_marcflavour_syspref($args{marcflavour});
    my (undef, $fwklist) = $installer->marc_framework_sql_list('en', $args{marcflavour});
    my (undef, $list) = $installer->sample_data_sql_list('en');
    my @frameworks;
    foreach my $fwk (@$fwklist, @$list) {
        foreach my $framework (@{ $fwk->{frameworks} }) {
            push @frameworks, $framework->{fwkfile};
        }
    }
    my $all_languages = C4::Languages::getAllLanguages();
    $installer->load_sql_in_order('en', $all_languages, @frameworks);
    require Koha::SearchEngine::Elasticsearch;
    Koha::SearchEngine::Elasticsearch->reset_elasticsearch_mappings;
    $installer->set_version_syspref();

    return 1;
}


=head1 AUTHOR

Julian Maurice, C<< <julian.maurice at biblibre.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-prove-plugin-kohabootstrap at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Prove-Plugin-KohaBootstrap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Prove::Plugin::KohaBootstrap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Prove-Plugin-KohaBootstrap>

=item * Search CPAN

L<https://metacpan.org/release/App-Prove-Plugin-KohaBootstrap>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Julian Maurice.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
