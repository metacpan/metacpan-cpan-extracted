#!/usr/bin/env perl
# ABSTRACT: App::mkfeyorm wrapper script. Make skeleton code with Fey::ORM.
# PODNAME: mkfeyorm.pl

use utf8;
use strict;
use warnings;
use autodie;
use Getopt::Long::Descriptive;
use App::mkfeyorm;

my ( $opt, $usage ) = describe_options(
    "%c %o ...",
    [ 'schema|s=s',         'schema module name'                        ],
    [ 'tables|t=s@',        'table module name list', { default => [] } ],
    [ 'namespace|n=s',      'base namespace'                            ],
    [ 'table_namespace=s',  'base table namespace'                      ],
    [ 'schema_namespace=s', 'base schema namespace'                     ],
    [ 'cache',              'turn on cache feature'                     ],
    [
        'output_path|o=s',
        'base directory (default: lib/)',
        { default => 'lib' },
    ],
    [],
    [ 'verbose|v', 'print extra stuff', { default => 0 } ],
    [ 'help|h',    'print usage message and exit'        ],
);

print($usage->text), exit                          if     $opt->help;
print("must specify schema\n", $usage->text), exit unless $opt->schema;
print("must specify tables\n", $usage->text), exit unless $opt->tables;

my $app = App::mkfeyorm->new(
    schema           => $opt->schema,
    tables           => {
        map {
            my ( $table, $db_table ) = split /,/;
            $table => $db_table;
        } @{ $opt->tables }
    },

    output_path      => $opt->output_path,
    namespace        => $opt->namespace        || q{},
    table_namespace  => $opt->table_namespace  || q{},
    schema_namespace => $opt->schema_namespace || q{},
    cache            => $opt->cache            || 0,
);

$app->process;



=pod

=encoding utf-8

=head1 NAME

mkfeyorm.pl - App::mkfeyorm wrapper script. Make skeleton code with Fey::ORM.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

If you want to generate C<My::Blog::Schema>
and C<My::Blog::Model::*> modules, then run following script.

    $ mkfeyorm.pl \
        --namespace My::Blog \
        --schema Schema \
        --table_namespace Model \
        --tables User \
        --tables Role \
        --tables UserRole \
        --tables Post \
        --tables Comment

You can also specify database name explicitly.

    $ mkfeyorm.pl \
        --namespace My::Blog \
        --table_namespace Model \
        --schema Schema \
        --tables User,user \
        --tables Role,role \
        --tables UserRole,user_role \
        --tables Post,post \
        --tables Comment,comment

=head1 DESCRIPTION

This is a L<App::mkfeyorm> wrapper script.
At least C<--schema> and C<--tables> options are needed.

=head1 OPTIONS

    mkfeyorm.pl [-hnostv] [long options...] ...
        -s --schema             schema module name
        -t --tables             table module name list
        -n --namespace          base namespace
        --table_namespace       base table namespace
        --schema_namespace      base schema namespace
        -o --output_path        base directory (default: lib/)
    
        -v --verbose            print extra stuff
        -h --help               print usage message and exit

=head1 SEE ALSO

=over

=item L<Fey::ORM>

=item L<App::mkfeyorm>

=back

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

