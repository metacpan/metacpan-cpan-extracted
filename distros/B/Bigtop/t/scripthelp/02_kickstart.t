use strict;

use Test::More tests => 6;

use File::Spec;

use Bigtop::ScriptHelp::Style;

my $style = Bigtop::ScriptHelp::Style->get_style( 'Kickstart' );

#--------------------------------------------------------------------
# simple test of original features
#--------------------------------------------------------------------

my $struct = $style->get_db_layout(
        '  job<->skill pos->job res->pos stray ',
        { pos => 1 }
);

my $correct_struct = {
        'joiners' => [ [ 'job', 'skill' ] ],
        'all_tables' => {
            'skill' => 1,
            'pos' => 1,
            'res' => 1,
            'job' => 1,
            'stray' => 1,
        },
        'new_tables' => [ 'job', 'skill', 'res', 'stray' ],
        'foreigners' => {
            'pos' => [ { table => 'job', col => 1 } ],
            'res' => [ { table => 'pos', col => 1 } ],
        },
        'columns' => {
            'job'   => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
            'skill' => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
            'res'   => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
            'stray' => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
        },
};

is_deeply( $struct, $correct_struct, 'original ascii art' );

#--------------------------------------------------------------------
# specifying some columns for one table
#--------------------------------------------------------------------

$struct = $style->get_db_layout( 'job(ident,descr,created:date)' );

$correct_struct = {
    joiners => [],
    new_tables => [ 'job' ],
    all_tables => { job => 1 },
    foreigners => {},
    columns => {
        job => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'ident', types => [ 'varchar' ] },
            { name => 'descr', types => [ 'varchar' ] },
            { name => 'created',     types => [ 'date' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
    },
};

is_deeply( $struct, $correct_struct, 'one table with columns' );

#--------------------------------------------------------------------
# specifying some columns
#--------------------------------------------------------------------

$struct = $style->get_db_layout(
        '  job(ident,descr)<->skill pos->job '
            .   'res(id:integer:pk:auto,name=Phil,+body:text)->pos ',
        { pos => 1 }
);

$correct_struct = {
    'joiners' => [ [ 'job', 'skill' ] ],
    'all_tables' => {
        'skill' => 1,
        'pos' => 1,
        'res' => 1,
        'job' => 1
    },
    'new_tables' => [ 'job', 'skill', 'res' ],
    'foreigners' => {
        'pos' => [ { table => 'job', col => 1 } ],
        'res' => [ { table => 'pos', col => 1 } ]
    },
    'columns' => {
        'skill' => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'ident',       types => [ 'varchar'  ], },
            { name => 'description', types => [ 'varchar'  ], },
            { name => 'created',     types => [ 'datetime' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
        'res'   => [
            { name => 'id',
              types => [ 'integer', 'pk', 'auto'    ], },
            { name => 'name', types => [ 'varchar'  ], default => 'Phil' },
            { name => 'body', types => [ 'text'     ], optional => 1 },
            { name => 'created',     types => [ 'datetime' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
        'job'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'ident',       types => [ 'varchar'  ], },
            { name => 'descr',       types => [ 'varchar'  ], },
            { name => 'created',     types => [ 'datetime' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
    }
};

is_deeply( $struct, $correct_struct, 'ascii art /w full column info' );

#--------------------------------------------------------------------
# Using a file name
#--------------------------------------------------------------------

my $input_file = File::Spec->catfile( qw( t scripthelp ascii_sample ) );

$struct = $style->get_db_layout( $input_file, { pos => 1 } );

is_deeply( $struct, $correct_struct, 'ascii art from input file' );

#--------------------------------------------------------------------
# Table with columns not in direct relationship.
#--------------------------------------------------------------------

$struct = $style->get_db_layout(
        'user_info(name,age:int) '
            .   'prof(school,field)<*user_info '
            .   'user_info*>stud(school,expected_grad_date)'
);

$correct_struct = {
    'joiners' => [],
    'all_tables' => {
        'user_info' => 1,
        'prof' => 1,
        'stud' => 1,
    },
    'new_tables' => [ 'user_info', 'prof', 'stud' ],
    'foreigners' => {
        'prof' => [ { table => 'user_info', col => 1 } ],
        'stud' => [ { table => 'user_info', col => 1 } ]
    },
    'columns' => {
        'user_info' => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'name',     types => [ 'varchar'  ], },
            { name => 'age',      types => [ 'int'      ], },
            { name => 'created',  types => [ 'datetime' ], },
            { name => 'modified', types => [ 'datetime' ], },
        ],
        'prof'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'    ], },
            { name => 'school',   types => [ 'varchar'  ] },
            { name => 'field',    types => [ 'varchar'  ] },
            { name => 'created',  types => [ 'datetime' ] },
            { name => 'modified', types => [ 'datetime' ] },
        ],
        'stud'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'school',             types => [ 'varchar'  ], },
            { name => 'expected_grad_date', types => [ 'varchar'  ], },
            { name => 'created',            types => [ 'datetime' ], },
            { name => 'modified',           types => [ 'datetime' ], },
        ],
    }
};

is_deeply( $struct, $correct_struct, 'solo tables in ASCII art' );

#--------------------------------------------------------------------
# Tim's blog which failed for him Feb 23, 2007
#--------------------------------------------------------------------

$struct = $style->get_db_layout(
'
link<->tag
blog<->tag
blog<-image
blog<-attachment
blog<-author
blog<-comment
blog<->section
blog(active,ident,title,subtitle,blurb,body,gps,rank,username)
author(name,address,city,state,country,gps)
comment(active:int4,rejected:int4,name,email,url,body)
link(active:int4,location,label,posted_date,score,username)
tag(active:int4,label,rank)
image(active:int4,label,descr,file,default_image,file_ident,file_name,file_size:int4,file_mime,file_suffix)
'
);

$correct_struct = {
    'joiners' => [
        [ 'link', 'tag' ],
        [ 'blog', 'tag' ],
        [ 'blog', 'section' ]
    ],
    'all_tables' => {
        'link' => 1,
        'tag' => 1,
        'blog' => 1,
        'attachment' => 1,
        'tag' => 1,
        'comment' => 1,
        'section' => 1,
        'author' => 1,
        'image' => 1,
    },
    'new_tables' => [
            qw( link tag blog image attachment author comment section )
    ],
    'foreigners' => {
        'image'      => [ { table => 'blog', col => 1 } ],
        'attachment' => [ { table => 'blog', col => 1 } ],
        'author'     => [ { table => 'blog', col => 1 } ],
        'comment'    => [ { table => 'blog', col => 1 } ],
    },
    'columns' => {
        'image'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'    ], },
            { name => 'active',        types => [ 'int4'  ] },
            { name => 'label',         types => [ 'varchar'  ] },
            { name => 'descr',         types => [ 'varchar'  ] },
            { name => 'file',          types => [ 'varchar'  ] },
            { name => 'default_image', types => [ 'varchar'  ] },
            { name => 'file_ident',    types => [ 'varchar'  ] },
            { name => 'file_name',     types => [ 'varchar'  ] },
            { name => 'file_size',     types => [ 'int4'  ] },
            { name => 'file_mime',     types => [ 'varchar'  ] },
            { name => 'file_suffix',   types => [ 'varchar'  ] },
            { name => 'created',       types => [ 'datetime' ] },
            { name => 'modified',      types => [ 'datetime' ] },
        ],
        'attachment'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'    ], },
            { name => 'ident',       types => [ 'varchar'  ] },
            { name => 'description', types => [ 'varchar'  ] },
            { name => 'created',     types => [ 'datetime' ] },
            { name => 'modified',    types => [ 'datetime' ] },
        ],
        'section'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'    ], },
            { name => 'ident',       types => [ 'varchar'  ] },
            { name => 'description', types => [ 'varchar'  ] },
            { name => 'created',     types => [ 'datetime' ] },
            { name => 'modified',    types => [ 'datetime' ] },
        ],
        'link'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'    ], },
            { name => 'active',      types => [ 'int4'  ] },
            { name => 'location',    types => [ 'varchar'  ] },
            { name => 'label',       types => [ 'varchar'  ] },
            { name => 'posted_date', types => [ 'varchar'  ] },
            { name => 'score',       types => [ 'varchar'  ] },
            { name => 'username',    types => [ 'varchar'  ] },
            { name => 'created',     types => [ 'datetime' ] },
            { name => 'modified',    types => [ 'datetime' ] },
        ],
        'blog' => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'active',   types => [ 'varchar'  ], },
            { name => 'ident',    types => [ 'varchar'  ], },
            { name => 'title',    types => [ 'varchar'  ], },
            { name => 'subtitle', types => [ 'varchar'  ], },
            { name => 'blurb',    types => [ 'varchar'  ], },
            { name => 'body',     types => [ 'varchar'  ], },
            { name => 'gps',      types => [ 'varchar'  ], },
            { name => 'rank',     types => [ 'varchar'  ], },
            { name => 'username', types => [ 'varchar'  ], },
            { name => 'created',  types => [ 'datetime' ], },
            { name => 'modified', types => [ 'datetime' ], },
        ],
        'author'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'    ], },
            { name => 'name',     types => [ 'varchar'  ] },
            { name => 'address',  types => [ 'varchar'  ] },
            { name => 'city',     types => [ 'varchar'  ] },
            { name => 'state',    types => [ 'varchar'  ] },
            { name => 'country',  types => [ 'varchar'  ] },
            { name => 'gps',      types => [ 'varchar'  ] },
            { name => 'created',  types => [ 'datetime' ] },
            { name => 'modified', types => [ 'datetime' ] },
        ],
        'comment'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'active',   types => [ 'int4'  ], },
            { name => 'rejected', types => [ 'int4'  ], },
            { name => 'name',     types => [ 'varchar'  ] },
            { name => 'email',    types => [ 'varchar'  ] },
            { name => 'url',      types => [ 'varchar'  ] },
            { name => 'body',     types => [ 'varchar'  ] },
            { name => 'created',  types => [ 'datetime' ], },
            { name => 'modified', types => [ 'datetime' ], },
        ],
        'tag'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'active',   types => [ 'int4'  ], },
            { name => 'label',    types => [ 'varchar'  ] },
            { name => 'rank',     types => [ 'varchar'  ] },
            { name => 'created',  types => [ 'datetime' ], },
            { name => 'modified', types => [ 'datetime' ], },
        ],
    }
};

is_deeply( $struct, $correct_struct, 'top relations, then cols ASCII art' );
