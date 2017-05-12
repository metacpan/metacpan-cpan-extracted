package DBIx::Connect::FromConfig;
use strict;
use warnings;
use Carp;
use DBI ();


{
    no strict;
    $VERSION = '0.07';
}


#
# import()
# ------
sub import {
    if (grep { /^-in_dbi$/i } @_) {
        *DBI::connect_from_config = \&connect
    }
}


#
# connect()
# -------
sub connect {
    my ($class, @args) = @_;
    croak "error: No parameter given" unless @args;
    croak "error: Odd number of arguments" if @args % 2 != 0;

    my %args = @args;
    my @params = qw<
        driver host port database options username password attributes
    >;

    my %db = ();
    my %db_param_name = (
        CSV         => 'f_dir',
        DB2         => 'DATABASE',
        Excel       => 'file',
        InterBase   => 'database',
        Mock        => 'dbname',
        mysql       => 'database',
        mysqlPP     => 'database',
        Oracle      => 'sid',
        Pg          => 'dbname',
        PgLite      => 'dbname',
        PgPP        => 'dbname',
        SQLite      => 'dbname',
        SQLite2     => 'dbname',
        Sybase      => 'database',
    );

    my $section_name = $args{section} || 'database';

    my $config = $args{config};

    # configuration in a Config::IniFiles object
    if (eval { $config->isa('Config::IniFiles') }) {
        for my $param (@params) {
            $db{$param} = $config->val($section_name => $param)
        }
    }
    # configuration in a Config::Simple object
    elsif (eval { $config->isa('Config::Simple') }) {
        my $block = $config->get_block($section_name);

        for my $param (@params) {
            $db{$param} = $block->{$param};
        }
    }
    # configuration in a Config::Tiny object
    elsif (eval { $config->isa('Config::Tiny') }) {
        for my $param (@params) {
            $db{$param} = $config->{$section_name}{$param};
        }
    }
    # configuration in a hashref
    elsif (ref $config eq 'HASH') {
        for my $param (@params) {
            $db{$param} = $config->{$param}
        }
    }
    else {
        croak "error: Unknown type of configuration"
    }

    # check mandatory values
    $db{driver} or croak "error: Database driver not specified";
    exists $db_param_name{$db{driver}}
        or croak "error: Database driver \Q$db{driver}\E not supported";

    # default values
    $db{database}   = "" unless defined $db{database};
    $db{host}       = "" unless defined $db{host};
    $db{port}       = "" unless defined $db{port};
    $db{options}    = "" unless defined $db{options};
    $db{username}   = "" unless defined $db{username};
    $db{password}   = "" unless defined $db{password};
    $db{attributes} ||= {};

    # handle DBI attributes
    if (ref $db{attributes}) {
        croak "error: DBI attributes must be given as a hashref or a string"
            unless ref $db{attributes} eq "HASH";
    }
    else {
        # copied from DBI::parse_dsn()
        $db{attributes} = { split /\s*=>?\s*|\s*,\s*/, $db{attributes}, -1 };
    }

    # construct the DSN
    my $dsn = sprintf "dbi:$db{driver}:%s%s%s=%s%s",
        ( $db{host} ? "host=$db{host};" : '' ),
        ( $db{port} ? "port=$db{port};" : '' ),
        $db_param_name{$db{driver}}, $db{database},
        ( $db{options} ? ";$db{options}" : '' );

    my $dbh = DBI->connect($dsn, $db{username}, $db{password}, $db{attributes});

    return $dbh
}


1; # End of DBIx::Connect::FromConfig


__END__

=head1 NAME

DBIx::Connect::FromConfig - Creates a DB connection from a configuration file

=head1 VERSION

Version 0.07


=head1 SYNOPSIS

    use DBI;
    use DBIx::Connect::FromConfig -in_dbi;

    my $dbh = DBI->connect_from_config(config => $config);
    # do DBI stuff

or, if you don't want to pollute C<DBI> namespace:

    use DBI;
    use DBIx::Connect::FromConfig;

    my $dbh = DBIx::Connect::FromConfig->connect(config => $config);
    # do DBI stuff


=head1 DESCRIPTION

C<DBIx::Connect::FromConfig> provides a generic way to connect to a 
database using settings from a configuration object.


=head1 EXPORT

This module does not export any function, but if given the C<-in_dbi> 
import option, it will install an alias of the C<connect()> function 
in the C<DBI> namespace, thus allowing it to be called as a method of 
C<DBI> (see the synopsis).


=head1 FUNCTIONS

=head2 connect()

Try to connect to a database using DBI and return the corresponding object.

B<Settings>

=over

=item *

C<driver> - the name of the C<DBI> driver for the database. This parameter 
is mandatory.

=item *

C<database> the name of the database. This parameter is mandatory.

=item *

C<host> - the hostname of the database. May be empty.

=item *

C<port> - the port of the database. May be empty.

=item *

C<options> - C<DBD> options, given as a plain string. Will be appended
at the end of the constructed DSN.

=item *

C<username> - the user name used to connect to the database. Defaults to the 
current user.

=item *

C<password> - the password used to connect to the database. May be empty.

=item *

C<attributes> - C<DBI> attributes, like C<RaiseError> or C<AutoCommit>.

=back


B<Parameters>

=over

=item *

C<config> - expects something that contains the settings: 

=over

=item *

a hash reference with the settings stored as first-level keys.

=item *

a C<Config::IniFiles> object; the settings must be available from 
the section named as given by the C<section> parameter.

=item *

a C<Config::Simple> object; the settings must be available from 
the section named as given by the C<section> parameter.

=item *

a C<Config::Tiny> object; the settings must be available from 
the section named as given by the C<section> parameter.

=back

=item *

C<section> - name of the section to look for the database settings; 
defaults to C<"database">

=back

B<Examples>

Connect to a database, passing the settings in a plain hash reference:

    my %settings = (
        driver      => 'Pg', 
        host        => 'bigapp-db.society.com', 
        database    => 'bigapp', 
        username    => 'appuser', 
        password    => 'sekr3t', 
        attributes  => { AutoCommit => 1, RaiseError => 1 },
    );

    my $dbh = DBI->connect_from_config(config => \%settings);

Connect to a database, passing the settings from a configuration file:

    my $config = Config::IniFiles->new(-file => '/etc/hebex/mail.conf');
    my $dbh = DBI->connect_from_config(config => $config);

where the configuration file could look like:

    [database]
    driver      = Pg
    host        = bigapp-db.society.com
    database    = bigapp
    username    = appuser
    password    = sekr3t
    attributes  = AutoCommit=1,RaiseError=1


=head1 DIAGNOSTICS

=over

=item C<Database driver not specified>

B<(E)> The setting specifying the database driver was not found or was empty.

=item C<Database driver %s not supported>

B<(E)> The specified database driver is not supported by this module.

=item C<DBI attributes must be given as a hashref or a string>

B<(E)> The function was given an improper value for the DBI attributes.

=item C<No parameter given>

B<(E)> The function can't do anything if you don't give it the required 
arguments.

=item C<Odd number of arguments>

B<(E)> The function expects options as a hash. Getting this message means 
something's missing.

=item C<Unknown type of configuration>

B<(E)> The function doesn't know how to handle the type of configuration 
you gave it. Use a supported one, bug the author, or send a patch C<;-)>

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests to 
C<bug-dbix-connect-fromconfig at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Connect-FromConfig>. 
I will be notified, and then you'll automatically be notified of progress 
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Connect::FromConfig


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Connect-FromConfig>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Connect-FromConfig>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Connect-FromConfig>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Connect-FromConfig>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008-2012 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
