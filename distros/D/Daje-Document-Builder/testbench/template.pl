#!/usr/bin/perl
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use v5.42;
use Moo;
use MooX::Options;
use Cwd;
use Mojo::Pg;
use Data::Dumper;
use Daje::Document::Builder;
use Daje::Workflow::Errors::Error;
use Daje::Document::Templates::Tools::Generate::SQL;

use namespace::clean -except => [qw/_options_data _options_config/];

sub template() {

    # my $pg = Mojo::Pg->new()->dsn(
    #     "dbi:Pg:dbname=Toolstest;host=database;port=54321;user=test;password=test"
    # );
    my $field;
    my $fields;

    $field->{fieldname} = 'field_one';
    $field->{datatype}  = 'DECIMAL';
    $field->{length}    = 20;
    $field->{scale}     = 10;
    $field->{default}   = 0.0;
    $field->{notnull}   = 1;
    push @{$fields}, $field;

    my $table->{table_name} = 'table_one';
    $table->{fields} = $fields;

    my $version->{version} = 1;
    push @{$version->{tables}}, $table;
    my $versions;
    push @{$versions->{versions}}, $version;

    my $context->{context}->{payload}->{tools_projects_pkey} = 8;
    #$context->{context}->{payload};

    my $builder = Daje::Document::Builder->new(
        source        => 'Daje::Document::Templates::Tools::Generate::Perl',
        data_sections => 'sql',
        data          => $versions,
        error         => Daje::Workflow::Errors::Error->new()
    );

    $builder->process();

    my $documents = $builder->output();
    say $builder->error->error if $builder->error->has_error;

}

template();
