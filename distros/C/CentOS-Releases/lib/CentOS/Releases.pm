package CentOS::Releases;

our $DATE = '2017-09-08'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_redhat_releases
               );

our %SPEC;

our $meta = {
    summary => 'CentOS releases',
    fields => {
        version              => {pos=> 0, schema=>'str*' , unique=>1},
        code_name            => {pos=> 1, schema=>'str*' , unique=>1},
        reldate              => {pos=> 2, schema=>'date*'},
        eoldate              => {pos=> 3, schema=>'date*'},

        linux_version        => {pos=> 4, schema=>'str*'},

        mysql_version        => {pos=> 5, schema=>'str*'},
        mariadb_version      => {pos=> 6, schema=>'str*'},
        postgresql_version   => {pos=> 7, schema=>'str*'},
        apache_httpd_version => {pos=> 8, schema=>'str*'},
        nginx_version        => {pos=> 9, schema=>'str*'},

        perl_version         => {pos=>10, schema=>'str*'},
        python_version       => {pos=>11, schema=>'str*'},
        php_version          => {pos=>12, schema=>'str*'},
        ruby_version         => {pos=>13, schema=>'str*'},
        bash_version         => {pos=>14, schema=>'str*'},
    },
    pk => 'version',
};

our $data = do {
    no warnings 'void';
    [];
 [
   {
     apache_httpd_version => "2.0.46",
     bash_version         => "2.05b",
     code_name            => undef,
     eoldate              => undef,
     linux_version        => "2.4.21",
     mariadb_version      => "--",
     mysql_version        => "3.23.58",
     nginx_version        => undef,
     perl_version         => "5.8.0",
     php_version          => "4.3.2",
     postgresql_version   => "7.3.19",
     python_version       => "2.2.3",
     reldate              => "2007-07-27",
     ruby_version         => undef,
     version              => 3.9,
   },
   {
     apache_httpd_version => "2.0.52",
     bash_version         => "3.0",
     code_name            => undef,
     eoldate              => undef,
     linux_version        => "2.6.9",
     mariadb_version      => "--",
     mysql_version        => "4.1.22",
     nginx_version        => undef,
     perl_version         => "5.8.5",
     php_version          => "4.3.9",
     postgresql_version   => "7.4.19",
     python_version       => "2.3.4",
     reldate              => "2009-08-22",
     ruby_version         => undef,
     version              => 4.8,
   },
   {
     apache_httpd_version => "2.2.3",
     bash_version         => 3.2,
     code_name            => undef,
     eoldate              => "2017-03",
     linux_version        => "2.6.18",
     mariadb_version      => "--",
     mysql_version        => "5.0.95",
     nginx_version        => undef,
     perl_version         => "5.8.8",
     php_version          => "5.1.6",
     postgresql_version   => "8.1.23",
     python_version       => "2.4.3",
     reldate              => "2014-09-30",
     ruby_version         => undef,
     version              => 5.11,
   },
   {
     apache_httpd_version => "2.2.15",
     bash_version         => 4.1,
     code_name            => undef,
     eoldate              => "2020-11",
     linux_version        => "2.6.32",
     mariadb_version      => "--",
     mysql_version        => "5.1.73",
     nginx_version        => undef,
     perl_version         => "5.10.1",
     php_version          => "5.3.3",
     postgresql_version   => "8.4.20",
     python_version       => "2.6.6",
     reldate              => "2017-04-05",
     ruby_version         => undef,
     version              => 6.9,
   },
   {
     apache_httpd_version => "2.4.6",
     bash_version         => 4.2,
     code_name            => undef,
     eoldate              => "2024-06",
     linux_version        => "3.10",
     mariadb_version      => "5.5.52",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.16.3",
     php_version          => "5.4.16",
     postgresql_version   => "9.2.18",
     python_version       => "2.7.5",
     reldate              => "2016-12-12",
     ruby_version         => undef,
     version              => "7-1611",
   },
 ]

};

my $res = gen_read_table_func(
    name => 'list_centos_releases',
    table_data => $data,
    table_spec => $meta,
    #langs => ['en_US', 'id_ID'],
);
die "BUG: Can't generate func: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: List CentOS releases

__END__

=pod

=encoding UTF-8

=head1 NAME

CentOS::Releases - List CentOS releases

=head1 VERSION

This document describes version 0.030 of CentOS::Releases (from Perl distribution CentOS-Releases), released on 2017-09-08.

=head1 SYNOPSIS

 use CentOS::Releases qw(list_centos_release);
 my $res = list_centos_releases(detail=>1);
 # raw data is in $CentOS::Releases::data;

=head1 DESCRIPTION

This module contains list of CentOS releases. Data source is currently at:
L<https://github.com/perlancar/gudangdata-distrowatch> (table/centos_release)
which in turn is retrieved from L<http://distrowatch.com>.

=head1 FUNCTIONS


=head2 list_centos_releases

Usage:

 list_centos_releases(%args) -> [status, msg, result, meta]

CentOS releases.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<apache_httpd_version> => I<str>

Only return records where the 'apache_httpd_version' field equals specified value.

=item * B<apache_httpd_version.contains> => I<str>

Only return records where the 'apache_httpd_version' field contains specified text.

=item * B<apache_httpd_version.in> => I<array[str]>

Only return records where the 'apache_httpd_version' field is in the specified values.

=item * B<apache_httpd_version.is> => I<str>

Only return records where the 'apache_httpd_version' field equals specified value.

=item * B<apache_httpd_version.isnt> => I<str>

Only return records where the 'apache_httpd_version' field does not equal specified value.

=item * B<apache_httpd_version.max> => I<str>

Only return records where the 'apache_httpd_version' field is less than or equal to specified value.

=item * B<apache_httpd_version.min> => I<str>

Only return records where the 'apache_httpd_version' field is greater than or equal to specified value.

=item * B<apache_httpd_version.not_contains> => I<str>

Only return records where the 'apache_httpd_version' field does not contain specified text.

=item * B<apache_httpd_version.not_in> => I<array[str]>

Only return records where the 'apache_httpd_version' field is not in the specified values.

=item * B<apache_httpd_version.xmax> => I<str>

Only return records where the 'apache_httpd_version' field is less than specified value.

=item * B<apache_httpd_version.xmin> => I<str>

Only return records where the 'apache_httpd_version' field is greater than specified value.

=item * B<bash_version> => I<str>

Only return records where the 'bash_version' field equals specified value.

=item * B<bash_version.contains> => I<str>

Only return records where the 'bash_version' field contains specified text.

=item * B<bash_version.in> => I<array[str]>

Only return records where the 'bash_version' field is in the specified values.

=item * B<bash_version.is> => I<str>

Only return records where the 'bash_version' field equals specified value.

=item * B<bash_version.isnt> => I<str>

Only return records where the 'bash_version' field does not equal specified value.

=item * B<bash_version.max> => I<str>

Only return records where the 'bash_version' field is less than or equal to specified value.

=item * B<bash_version.min> => I<str>

Only return records where the 'bash_version' field is greater than or equal to specified value.

=item * B<bash_version.not_contains> => I<str>

Only return records where the 'bash_version' field does not contain specified text.

=item * B<bash_version.not_in> => I<array[str]>

Only return records where the 'bash_version' field is not in the specified values.

=item * B<bash_version.xmax> => I<str>

Only return records where the 'bash_version' field is less than specified value.

=item * B<bash_version.xmin> => I<str>

Only return records where the 'bash_version' field is greater than specified value.

=item * B<code_name> => I<str>

Only return records where the 'code_name' field equals specified value.

=item * B<code_name.contains> => I<str>

Only return records where the 'code_name' field contains specified text.

=item * B<code_name.in> => I<array[str]>

Only return records where the 'code_name' field is in the specified values.

=item * B<code_name.is> => I<str>

Only return records where the 'code_name' field equals specified value.

=item * B<code_name.isnt> => I<str>

Only return records where the 'code_name' field does not equal specified value.

=item * B<code_name.max> => I<str>

Only return records where the 'code_name' field is less than or equal to specified value.

=item * B<code_name.min> => I<str>

Only return records where the 'code_name' field is greater than or equal to specified value.

=item * B<code_name.not_contains> => I<str>

Only return records where the 'code_name' field does not contain specified text.

=item * B<code_name.not_in> => I<array[str]>

Only return records where the 'code_name' field is not in the specified values.

=item * B<code_name.xmax> => I<str>

Only return records where the 'code_name' field is less than specified value.

=item * B<code_name.xmin> => I<str>

Only return records where the 'code_name' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<eoldate> => I<date>

Only return records where the 'eoldate' field equals specified value.

=item * B<eoldate.in> => I<array[date]>

Only return records where the 'eoldate' field is in the specified values.

=item * B<eoldate.is> => I<date>

Only return records where the 'eoldate' field equals specified value.

=item * B<eoldate.isnt> => I<date>

Only return records where the 'eoldate' field does not equal specified value.

=item * B<eoldate.max> => I<date>

Only return records where the 'eoldate' field is less than or equal to specified value.

=item * B<eoldate.min> => I<date>

Only return records where the 'eoldate' field is greater than or equal to specified value.

=item * B<eoldate.not_in> => I<array[date]>

Only return records where the 'eoldate' field is not in the specified values.

=item * B<eoldate.xmax> => I<date>

Only return records where the 'eoldate' field is less than specified value.

=item * B<eoldate.xmin> => I<date>

Only return records where the 'eoldate' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<linux_version> => I<str>

Only return records where the 'linux_version' field equals specified value.

=item * B<linux_version.contains> => I<str>

Only return records where the 'linux_version' field contains specified text.

=item * B<linux_version.in> => I<array[str]>

Only return records where the 'linux_version' field is in the specified values.

=item * B<linux_version.is> => I<str>

Only return records where the 'linux_version' field equals specified value.

=item * B<linux_version.isnt> => I<str>

Only return records where the 'linux_version' field does not equal specified value.

=item * B<linux_version.max> => I<str>

Only return records where the 'linux_version' field is less than or equal to specified value.

=item * B<linux_version.min> => I<str>

Only return records where the 'linux_version' field is greater than or equal to specified value.

=item * B<linux_version.not_contains> => I<str>

Only return records where the 'linux_version' field does not contain specified text.

=item * B<linux_version.not_in> => I<array[str]>

Only return records where the 'linux_version' field is not in the specified values.

=item * B<linux_version.xmax> => I<str>

Only return records where the 'linux_version' field is less than specified value.

=item * B<linux_version.xmin> => I<str>

Only return records where the 'linux_version' field is greater than specified value.

=item * B<mariadb_version> => I<str>

Only return records where the 'mariadb_version' field equals specified value.

=item * B<mariadb_version.contains> => I<str>

Only return records where the 'mariadb_version' field contains specified text.

=item * B<mariadb_version.in> => I<array[str]>

Only return records where the 'mariadb_version' field is in the specified values.

=item * B<mariadb_version.is> => I<str>

Only return records where the 'mariadb_version' field equals specified value.

=item * B<mariadb_version.isnt> => I<str>

Only return records where the 'mariadb_version' field does not equal specified value.

=item * B<mariadb_version.max> => I<str>

Only return records where the 'mariadb_version' field is less than or equal to specified value.

=item * B<mariadb_version.min> => I<str>

Only return records where the 'mariadb_version' field is greater than or equal to specified value.

=item * B<mariadb_version.not_contains> => I<str>

Only return records where the 'mariadb_version' field does not contain specified text.

=item * B<mariadb_version.not_in> => I<array[str]>

Only return records where the 'mariadb_version' field is not in the specified values.

=item * B<mariadb_version.xmax> => I<str>

Only return records where the 'mariadb_version' field is less than specified value.

=item * B<mariadb_version.xmin> => I<str>

Only return records where the 'mariadb_version' field is greater than specified value.

=item * B<mysql_version> => I<str>

Only return records where the 'mysql_version' field equals specified value.

=item * B<mysql_version.contains> => I<str>

Only return records where the 'mysql_version' field contains specified text.

=item * B<mysql_version.in> => I<array[str]>

Only return records where the 'mysql_version' field is in the specified values.

=item * B<mysql_version.is> => I<str>

Only return records where the 'mysql_version' field equals specified value.

=item * B<mysql_version.isnt> => I<str>

Only return records where the 'mysql_version' field does not equal specified value.

=item * B<mysql_version.max> => I<str>

Only return records where the 'mysql_version' field is less than or equal to specified value.

=item * B<mysql_version.min> => I<str>

Only return records where the 'mysql_version' field is greater than or equal to specified value.

=item * B<mysql_version.not_contains> => I<str>

Only return records where the 'mysql_version' field does not contain specified text.

=item * B<mysql_version.not_in> => I<array[str]>

Only return records where the 'mysql_version' field is not in the specified values.

=item * B<mysql_version.xmax> => I<str>

Only return records where the 'mysql_version' field is less than specified value.

=item * B<mysql_version.xmin> => I<str>

Only return records where the 'mysql_version' field is greater than specified value.

=item * B<nginx_version> => I<str>

Only return records where the 'nginx_version' field equals specified value.

=item * B<nginx_version.contains> => I<str>

Only return records where the 'nginx_version' field contains specified text.

=item * B<nginx_version.in> => I<array[str]>

Only return records where the 'nginx_version' field is in the specified values.

=item * B<nginx_version.is> => I<str>

Only return records where the 'nginx_version' field equals specified value.

=item * B<nginx_version.isnt> => I<str>

Only return records where the 'nginx_version' field does not equal specified value.

=item * B<nginx_version.max> => I<str>

Only return records where the 'nginx_version' field is less than or equal to specified value.

=item * B<nginx_version.min> => I<str>

Only return records where the 'nginx_version' field is greater than or equal to specified value.

=item * B<nginx_version.not_contains> => I<str>

Only return records where the 'nginx_version' field does not contain specified text.

=item * B<nginx_version.not_in> => I<array[str]>

Only return records where the 'nginx_version' field is not in the specified values.

=item * B<nginx_version.xmax> => I<str>

Only return records where the 'nginx_version' field is less than specified value.

=item * B<nginx_version.xmin> => I<str>

Only return records where the 'nginx_version' field is greater than specified value.

=item * B<perl_version> => I<str>

Only return records where the 'perl_version' field equals specified value.

=item * B<perl_version.contains> => I<str>

Only return records where the 'perl_version' field contains specified text.

=item * B<perl_version.in> => I<array[str]>

Only return records where the 'perl_version' field is in the specified values.

=item * B<perl_version.is> => I<str>

Only return records where the 'perl_version' field equals specified value.

=item * B<perl_version.isnt> => I<str>

Only return records where the 'perl_version' field does not equal specified value.

=item * B<perl_version.max> => I<str>

Only return records where the 'perl_version' field is less than or equal to specified value.

=item * B<perl_version.min> => I<str>

Only return records where the 'perl_version' field is greater than or equal to specified value.

=item * B<perl_version.not_contains> => I<str>

Only return records where the 'perl_version' field does not contain specified text.

=item * B<perl_version.not_in> => I<array[str]>

Only return records where the 'perl_version' field is not in the specified values.

=item * B<perl_version.xmax> => I<str>

Only return records where the 'perl_version' field is less than specified value.

=item * B<perl_version.xmin> => I<str>

Only return records where the 'perl_version' field is greater than specified value.

=item * B<php_version> => I<str>

Only return records where the 'php_version' field equals specified value.

=item * B<php_version.contains> => I<str>

Only return records where the 'php_version' field contains specified text.

=item * B<php_version.in> => I<array[str]>

Only return records where the 'php_version' field is in the specified values.

=item * B<php_version.is> => I<str>

Only return records where the 'php_version' field equals specified value.

=item * B<php_version.isnt> => I<str>

Only return records where the 'php_version' field does not equal specified value.

=item * B<php_version.max> => I<str>

Only return records where the 'php_version' field is less than or equal to specified value.

=item * B<php_version.min> => I<str>

Only return records where the 'php_version' field is greater than or equal to specified value.

=item * B<php_version.not_contains> => I<str>

Only return records where the 'php_version' field does not contain specified text.

=item * B<php_version.not_in> => I<array[str]>

Only return records where the 'php_version' field is not in the specified values.

=item * B<php_version.xmax> => I<str>

Only return records where the 'php_version' field is less than specified value.

=item * B<php_version.xmin> => I<str>

Only return records where the 'php_version' field is greater than specified value.

=item * B<postgresql_version> => I<str>

Only return records where the 'postgresql_version' field equals specified value.

=item * B<postgresql_version.contains> => I<str>

Only return records where the 'postgresql_version' field contains specified text.

=item * B<postgresql_version.in> => I<array[str]>

Only return records where the 'postgresql_version' field is in the specified values.

=item * B<postgresql_version.is> => I<str>

Only return records where the 'postgresql_version' field equals specified value.

=item * B<postgresql_version.isnt> => I<str>

Only return records where the 'postgresql_version' field does not equal specified value.

=item * B<postgresql_version.max> => I<str>

Only return records where the 'postgresql_version' field is less than or equal to specified value.

=item * B<postgresql_version.min> => I<str>

Only return records where the 'postgresql_version' field is greater than or equal to specified value.

=item * B<postgresql_version.not_contains> => I<str>

Only return records where the 'postgresql_version' field does not contain specified text.

=item * B<postgresql_version.not_in> => I<array[str]>

Only return records where the 'postgresql_version' field is not in the specified values.

=item * B<postgresql_version.xmax> => I<str>

Only return records where the 'postgresql_version' field is less than specified value.

=item * B<postgresql_version.xmin> => I<str>

Only return records where the 'postgresql_version' field is greater than specified value.

=item * B<python_version> => I<str>

Only return records where the 'python_version' field equals specified value.

=item * B<python_version.contains> => I<str>

Only return records where the 'python_version' field contains specified text.

=item * B<python_version.in> => I<array[str]>

Only return records where the 'python_version' field is in the specified values.

=item * B<python_version.is> => I<str>

Only return records where the 'python_version' field equals specified value.

=item * B<python_version.isnt> => I<str>

Only return records where the 'python_version' field does not equal specified value.

=item * B<python_version.max> => I<str>

Only return records where the 'python_version' field is less than or equal to specified value.

=item * B<python_version.min> => I<str>

Only return records where the 'python_version' field is greater than or equal to specified value.

=item * B<python_version.not_contains> => I<str>

Only return records where the 'python_version' field does not contain specified text.

=item * B<python_version.not_in> => I<array[str]>

Only return records where the 'python_version' field is not in the specified values.

=item * B<python_version.xmax> => I<str>

Only return records where the 'python_version' field is less than specified value.

=item * B<python_version.xmin> => I<str>

Only return records where the 'python_version' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<reldate> => I<date>

Only return records where the 'reldate' field equals specified value.

=item * B<reldate.in> => I<array[date]>

Only return records where the 'reldate' field is in the specified values.

=item * B<reldate.is> => I<date>

Only return records where the 'reldate' field equals specified value.

=item * B<reldate.isnt> => I<date>

Only return records where the 'reldate' field does not equal specified value.

=item * B<reldate.max> => I<date>

Only return records where the 'reldate' field is less than or equal to specified value.

=item * B<reldate.min> => I<date>

Only return records where the 'reldate' field is greater than or equal to specified value.

=item * B<reldate.not_in> => I<array[date]>

Only return records where the 'reldate' field is not in the specified values.

=item * B<reldate.xmax> => I<date>

Only return records where the 'reldate' field is less than specified value.

=item * B<reldate.xmin> => I<date>

Only return records where the 'reldate' field is greater than specified value.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<ruby_version> => I<str>

Only return records where the 'ruby_version' field equals specified value.

=item * B<ruby_version.contains> => I<str>

Only return records where the 'ruby_version' field contains specified text.

=item * B<ruby_version.in> => I<array[str]>

Only return records where the 'ruby_version' field is in the specified values.

=item * B<ruby_version.is> => I<str>

Only return records where the 'ruby_version' field equals specified value.

=item * B<ruby_version.isnt> => I<str>

Only return records where the 'ruby_version' field does not equal specified value.

=item * B<ruby_version.max> => I<str>

Only return records where the 'ruby_version' field is less than or equal to specified value.

=item * B<ruby_version.min> => I<str>

Only return records where the 'ruby_version' field is greater than or equal to specified value.

=item * B<ruby_version.not_contains> => I<str>

Only return records where the 'ruby_version' field does not contain specified text.

=item * B<ruby_version.not_in> => I<array[str]>

Only return records where the 'ruby_version' field is not in the specified values.

=item * B<ruby_version.xmax> => I<str>

Only return records where the 'ruby_version' field is less than specified value.

=item * B<ruby_version.xmin> => I<str>

Only return records where the 'ruby_version' field is greater than specified value.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<version> => I<str>

Only return records where the 'version' field equals specified value.

=item * B<version.contains> => I<str>

Only return records where the 'version' field contains specified text.

=item * B<version.in> => I<array[str]>

Only return records where the 'version' field is in the specified values.

=item * B<version.is> => I<str>

Only return records where the 'version' field equals specified value.

=item * B<version.isnt> => I<str>

Only return records where the 'version' field does not equal specified value.

=item * B<version.max> => I<str>

Only return records where the 'version' field is less than or equal to specified value.

=item * B<version.min> => I<str>

Only return records where the 'version' field is greater than or equal to specified value.

=item * B<version.not_contains> => I<str>

Only return records where the 'version' field does not contain specified text.

=item * B<version.not_in> => I<array[str]>

Only return records where the 'version' field is not in the specified values.

=item * B<version.xmax> => I<str>

Only return records where the 'version' field is less than specified value.

=item * B<version.xmin> => I<str>

Only return records where the 'version' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CentOS-Releases>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CentOS-Releases>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CentOS-Releases>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Debian::Releases>

L<Ubuntu::Releases>

L<LinuxMint::Releases>

L<RedHat::Releases>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
