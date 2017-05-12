use strict;
use warnings;
package Config::Any::CSV;
#ABSTRACT: Load CSV as config files
our $VERSION = '0.05'; #VERSION

use v5.10;
use base 'Config::Any::Base';
use Text::CSV;

sub load {
    my ($class, $file, $driver) = @_;

    my $with_key = 0;
    my $args = { binary => 1, allow_whitespace => 1 };
    if ($driver) {
        $with_key = delete $driver->{with_key};
        $args->{$_} = $driver->{$_} for keys %$driver;
    }
    my $csv = Text::CSV->new( $args );
    my $config = { };
    open my $fh, "<", $file or die $!;

    my $default = $args->{empty_is_undef} ? undef : "";
 
    my $names = $csv->getline($fh);
    if ( $names ) {
        my $columns = scalar @$names - 1;
        while ( my $row = $csv->getline( $fh ) ) {
            next if @$row == 1 and $row->[0] eq ''; # empty line
            my $id = $row->[0] // "";
            $config->{ $id } = {
                map { ( $names->[$_] // "" ) => ( $row->[$_] // $default ) }
                (1..$columns)
            };
            $config->{ $id }->{ $names->[0] // "" } = $id if $with_key;
        }
    }
    die $csv->error_diag() unless $csv->eof;
    close $fh;

    return $config;
}

sub extensions {
    return ('csv');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Any::CSV - Load CSV as config files

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Config::Any;
 
    my $config = Config::Any->load_files({files => \@files});

I recommend to use L<Config::ZOMG> for a nicer interface to Config::Any:

    use Config::ZOMG;

    # just load a single file
    my $config_hash = Config::ZOMG->open( $csv_file );

    # load foo.csv (and possible foo_local.csv)
    my $config = Config::ZOMG->new( 
        path => '/path/to/config',
        name => 'foo'
    );

    # load with CSV options
    my $config = Config::ZOMG->new( 
        path => '/path/to/config',
        name => 'foo',
        drivers => {
            CSV => { 
                sep_char => ';', 
                with_key => 1,
            } 
        }
    );

=head1 DESCRIPTION

This small module adds support of CSV files to L<Config::Any>. Files with
extension C<.csv> are read with L<Text::CSV> - see that module for
documentation of the particular CSV format. By default, Config::Any::CSV
enables the options C<binary> and C<allow_whitespace>.  One can modify options
with C<driver_args> (L<Config::Any>) or C<driver> (L<Config::ZOMG>). The first
row of a CSV file is always interpreted as a list of field names and the first
field is always interpreted as key field. For instance this CSV file

    name,age,mail
    alice, 42, alice@example.org
    bob, 23, bob@example.org

Is parsed into this Perl structure:

    {
        alice => {
            age  => '42',
            mail => 'alice@example.org',
        },
         bob => {
            age => '23',
            mail => 'bob@example.org'
        }
    }

The driver option C<with_key> adds key field to each row:

    {
        alice => {
            name => 'alice',
            age  => '42',
            mail => 'alice@example.org',
        },
         bob => {
            name => 'bob',
            age => '23',
            mail => 'bob@example.org'
        }
    }

The name of the first field is irrelevant and the order of rows gets lost. If a
file contains multiple rows with the same first field value, only the last of
these rows is used. Empty lines are ignored.

This module requires Perl 5.10 but it could easily be modified to also run in
more ancient versions of Perl.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
