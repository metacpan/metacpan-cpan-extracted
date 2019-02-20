package App::mycnfdiff;
$App::mycnfdiff::VERSION = '1.00';
use strict;
use warnings;
use Data::Dumper;
use Data::Dump qw(dd);
use Text::CSV qw( csv );
use Cwd qw(getcwd);
use App::mycnfdiff::Utils qw(:all);
use Config::MySQL::Writer;
use File::Slurper qw(write_text);    # for writing diff


my $COMMON_FILENAME = 'common.mycnfdiff';
my $DIFF_FILENAME   = 'diff.mycnfdiff';

sub run {
    my ( $self, $opts ) = @_;    # $opts is Getopt::Long::Descriptive::Opts

    my $dir = ( $opts->dir ? $opts->dir : '.' );
    my @exclude      = ( $opts->skip ? split( ',', $opts->skip ) : () );
    my @include_only = ( $opts->list ? split( ',', $opts->list ) : () );

    # read source content into hash
    my $configs_content = get_configs(
        dir          => $dir,
        skip         => \@exclude,
        include_only => \@include_only,
        v            => $opts->verbose
    );

    my $cmp = split_compare_hash( compare($configs_content) );
    Config::MySQL::Writer->write_file( $cmp->{same}, $COMMON_FILENAME );
    write_text( $DIFF_FILENAME, Dumper $cmp->{diff} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::mycnfdiff

=head1 VERSION

version 1.00

=head1 SYNOPSIS

  $ mycnfdiff -d /foo/bar -l my.cnf.1,my.cnf.bak
  $ mycnfdiff -l server1/my.cnf,server2/my.cnf
  $ mycnfdiff -l 'exec:docker run -it percona mysqld --verbose --help,my.ini' 
  $ mycnfdiff -s s2.ini,s3,ini  # read all cnf and ini files in current dir except s2.ini

Files must have .cnf or .ini extension otherwise they will not be parsed by default

To specify particular source without format restriction use -l option. 

If one of source is compiled defaults you can only use -l option

to-do: 

diff in csv format

=head1 DESCRIPTION

By default, it produce two output files

1) common.mycnfdiff with common options

2) diff.mycnfdiff with different options (hash style)

If utility can not write files it will print result to STDOUT and warn user about permissions

=head1 NAME

App::mycnfdiff - compare MySQL server configs. 

Can also compare with compiled defaults (values after reading options)

=head1 OPTIONS

For more info please check mycnfdiff --help

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
