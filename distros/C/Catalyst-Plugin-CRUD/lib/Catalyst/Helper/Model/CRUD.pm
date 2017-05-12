package Catalyst::Helper::Model::CRUD;

use strict;
use Jcode;
use XML::Simple;

our $VERSION = '0.21';

=head1 NAME

Catalyst::Helper::Model::CRUD - generate sqls, controllers and templates from DBDesigner 4 file

=head1 SYNOPSIS

    ./myapp_create.pl model DBIC CRUD [DBDesigner 4 File] [some modules]

=head1 DESCRIPTION

Helper for Catalyst::Plugin::CRUD.

This helper generates sqls, default controllers and default templates.

=head1 METHODS

=cut

# relation list
my @relations;

# table list
my @tables;

=head2 encode($str)

This method translates comment of DBDesigner4 to UTF-8.

=cut

sub encode {
    my ( $this, $str ) = @_;
    my @array = split( //, $str );
    my @list;
    for ( my $i = 0 ; $i < scalar(@array) ; $i++ ) {

        # translate "\\n" to "。"
        if ( $array[$i] eq '\\' && $array[ $i + 1 ] eq 'n' ) {
            push @list, 129;
            push @list, 66;
            $i++;

            # translate "\\\\" to "0x5C"
        }
        elsif ( $array[$i] eq '\\' && $array[ $i + 1 ] eq '\\' ) {
            push @list, 92;
            $i++;

            # "\\144" etc
        }
        elsif ( $array[$i] eq '\\' ) {
            push @list, $array[ $i + 1 ] . $array[ $i + 2 ] . $array[ $i + 3 ];
            $i += 3;

            # "[" etc
        }
        elsif ( 13 < ord( $array[$i] ) && ord( $array[$i] ) < 128 ) {
            push @list, ord( $array[$i] );
        }
    }

    # translate Shift-JIS to UTF-8
    my $result = pack( "C*", @list );
    return jcode( $result, 'sjis' )->utf8;
}

=head2 get_class_name($str)

This method translates hoge_fuga_master to HogeFugaMaster.

=cut

sub get_class_name {
    my ( $this, $str ) = @_;
    my @array = split( //, $str );
    for ( my $i = 0 ; $i < scalar(@array) ; $i++ ) {
        if ( $i == 0 ) {
            $array[$i] = uc $array[$i];
        }
        elsif ( $array[$i] eq '_' ) {
            $array[ $i + 1 ] = uc $array[ $i + 1 ];
        }
    }
    my $result = join( '', @array );
    $result =~ s/_//g;
    return $result;
}

=head2 get_relation($relation_id)

This method returns relation of appointed ID.

=cut

sub get_relation {
    my ( $this, $relation_id ) = @_;
    foreach my $relation (@relations) {
        if ( $relation_id eq $relation->{'ID'} ) {
            return $relation;
        }
    }
}

=head2 get_table($table_id)

This methods returns table of appointed ID.

=cut

sub get_table {
    my ( $this, $table_id ) = @_;
    foreach my $table (@tables) {
        if ( $table_id eq $table->{'ID'} ) {
            return $table;
        }
    }
}

=head2 get_setting_index($array, $name)

This method returns setting number of appointed name.

=cut

sub get_setting_index {
    my ( $this, $array, $name ) = @_;
    for ( my $i = 0 ; $i < scalar( @{$array} ) ; $i++ ) {
        if ( $name eq $array->[$i]->{'name'} ) {
            return $i;
        }
    }
    return -1;
}

=head2 get_primary(@sqls)

This method returns primary key name.

=cut

sub get_primary {
    my ( $this, @sqls ) = @_;
    for my $sql (@sqls) {
        if ( $sql->{type} eq 'serial' ) {
            return $sql->{name};
        }
    }
    return 'id';
}

=head2 get_columns(@sqls)

This method returns columns string.

=cut

sub get_columns {
    my ( $this, @sqls ) = @_;
    shift @sqls;
    my @names;
    for my $sql (@sqls) {
        push @names, $sql->{name};
    }
    return join( " ", @names );
}

=head2 mk_compclass($helper, $file, @limited_file)

This method analyse DBDesigner 4 file and generate sqls, controllers and templates.

=cut

sub mk_compclass {
    my ( $this, $helper, $file, @limited_file ) = @_;

    print "==========================================================\n";

    # ファイル名は必須
    unless ($file) {
        die "usage: ./myapp_create.pl model CRUD CRUD [DBDesigner 4 File] [some modules]\n";
        return 1;
    }

    # XMLファイル解析
    my $parser = new XML::Simple();
    my $tree   = $parser->XMLin($file);

    # SQL・コントローラ・テンプレート用のディレクトリを作る
    my $schema_dir     = sprintf( "%s/sql/schema",        $helper->{'base'} );
    my $i18n_dir       = sprintf( "%s/lib/%s/I18N",       $helper->{'base'}, $helper->{'app'} );
    my $controller_dir = sprintf( "%s/lib/%s/Controller", $helper->{'base'}, $helper->{'app'} );
    my $template_dir   = sprintf( "%s/root/template",     $helper->{'base'} );
    $helper->mk_dir($schema_dir);
    $helper->mk_dir($i18n_dir);
    $helper->mk_dir($controller_dir);
    $helper->mk_dir($template_dir);

    # リレーションとテーブル一覧を取得する
    if ( ref $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} eq 'ARRAY' ) {
        @relations = @{ $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} };
    }
    else {
        push( @relations, $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} );
    }
    if ( ref $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} eq 'ARRAY' ) {
        @tables = @{ $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} };
    }
    else {
        push( @tables, $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} );
    }

    # 指定したモジュールのみ
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    # 言語ファイル用キーワードファイル
    my @keywords;

    foreach my $table (@tables) {
        my $model_name = $this->get_class_name( $table->{'Tablename'} );
        my $class_name = $model_name;
        $class_name =~ s/Master//g;

        # 指定したモジュールのみ
        if ( scalar @limited_file ) {
            next unless ( $limit{$class_name} );
        }

        # 言語ファイルに追加
        push @keywords, 
            {
                name    => $class_name . '_class_name', 
                desc_ja => $this->encode( $table->{'Comments'} ),
                desc_en => $class_name
            };

        # 各テーブルの列一覧取得
        my @columns = @{ $table->{'COLUMNS'}->{'COLUMN'} }
          if ref $table->{'COLUMNS'}->{'COLUMN'} eq 'ARRAY';

        # 各テーブルのインデックス覧取得
        my %indices;
        if ( ref( $table->{'INDICES'}->{'INDEX'} ) eq 'HASH' ) {

            # 要素一個のときはハッシュになってしまうのでその対策
            my $key = $table->{'INDICES'}->{'INDEX'}->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
            my $val = $table->{'INDICES'}->{'INDEX'}->{'FKRefDef_Obj_id'};

            # 主キーは無視する
            unless ( $val eq '-1' ) {
                $indices{$key} = $val;
            }
        }
        elsif ( ref( $table->{'INDICES'}->{'INDEX'} ) eq 'ARRAY' ) {
            foreach my $index ( @{ $table->{'INDICES'}->{'INDEX'} } ) {
                my $key = $index->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
                my $val = $index->{'FKRefDef_Obj_id'};

                # 主キーは無視する
                unless ( $val eq '-1' ) {
                    $indices{$key} = $val;
                }
            }
        }

        my @serials;     # シーケンス一覧
        my @sqls;        # SQL一覧
        my @settings;    # スキーマ一覧
        foreach my $column (@columns) {
            my $sql;
            my @setting;

            # カラム名
            push @setting, ( "        " . $column->{'ColName'} );

            # 型
            if ( $column->{'AutoInc'} eq "1" ) {

                # AutoInc="1" だったら「テーブル名_カラム名_seq」という
                # テーブルを Postgresql が自動作成するのでその対応
                $sql->{'type'} = "serial";
                push @setting, "SERIAL";
                push @serials,
                  sprintf( "GRANT ALL ON %s_%s_seq TO PUBLIC;\n", $table->{'Tablename'}, $column->{'ColName'} );
            }
            elsif ( $column->{'idDatatype'} eq '5' ) {
                $sql->{'type'} = "int";
                push @setting, "INTEGER";
            }
            elsif ( $column->{'idDatatype'} eq '14' ) {
                $sql->{'type'} = "date";
                push @setting, "DATE";
            }
            elsif ( $column->{'idDatatype'} eq '16' ) {
                $sql->{'type'} = "timestamp with time zone";
                push @setting, "TIMESTAMP with time zone";
            }
            elsif ( $column->{'idDatatype'} eq '20' ) {
                $sql->{'type'} = "varchar(255)";
                push @setting, "VARCHAR(255)";
            }
            elsif ( $column->{'idDatatype'} eq '22' ) {
                $sql->{'type'} = "bool";
                push @setting, "BOOL";
            }
            elsif ( $column->{'idDatatype'} eq '28' ) {
                $sql->{'type'} = "text";
                push @setting, "TEXT";
            }
            else {
                $sql->{'type'} = "text";
                push @setting, "TEXT";
            }

            # 主キーかどうか
            if ( $column->{'PrimaryKey'} eq '1' ) {
                $sql->{'primarykey'} = 1;
                push @setting, "PRIMARY KEY";
            }
            elsif ( 'id' eq lc( $column->{'ColName'} ) ) {

                # id は自動的に主キーにする
                $sql->{'primarykey'} = 1;
                push @setting, "PRIMARY KEY";
            }

            # デフォルト値
            if ( length( $column->{'DefaultValue'} ) > 0 ) {
                $sql->{'default'} = $column->{'DefaultValue'};
                push @setting, sprintf( "DEFAULT '%s'", $column->{'DefaultValue'} );
            }
            elsif ( $column->{'idDatatype'} eq '14' ) {

                # 日付は自動的に設定する
                $sql->{'default'} = "('now'::text)::timestamp";
                push @setting, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( $column->{'idDatatype'} eq '16' ) {

                # 日時は自動的に設定する
                $sql->{'default'} = "('now'::text)::timestamp";
                push @setting, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に 0 にする
                $sql->{'default'} = "0";
                push @setting, "DEFAULT '0'";
            }

            # NOT NULL 制約
            if ( $column->{'NotNull'} eq '1' ) {
                $sql->{'notnull'} = 1;
                push @setting, "NOT NULL";
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に NOT NULL にする
                $sql->{'notnull'} = 1;
                push @setting, "NOT NULL";
            }

            # 参照制約
            if ( $indices{ $column->{'ID'} } ) {
                my $relation   = $this->get_relation( $indices{ $column->{'ID'} } );
                my $src_table  = $this->get_table( $relation->{'SrcTable'} );
                my $class_name = sprintf( "%s::Model::ShanonDBI::%s",
                    $helper->{'app'}, $this->get_class_name( $src_table->{'Tablename'} ) );
                $sql->{'references'} = {
                    class    => $class_name,
                    name     => 'id',
                    onupdate => 'cascade',
                    ondelete => 'cascade'
                };
                push @setting,
                  sprintf( "CONSTRAINT ref_%s REFERENCES %s (id) ON DELETE cascade ON UPDATE cascade",
                    $column->{'ColName'}, $src_table->{'Tablename'} );
            }

            # コメント
            if ( 'id' eq lc( $column->{'ColName'} ) ) {

                # id は自動的に ID にする
                push @setting, '/* ID */';
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に 削除 にする
                push @setting, '/* 削除 */';
            }
            elsif ( 'date_regist' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に 登録日時 にする
                push @setting, '/* 登録日時 */';
            }
            elsif ( 'date_update' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に 更新日時 にする
                push @setting, '/* 更新日時 */';
            }
            else {
                push @setting, sprintf( "/* %s */", $this->encode( $column->{'Comments'} ) );
            }
                
            # 言語ファイル
            if ( 'id' eq lc( $column->{'ColName'} ) ) {
                push @keywords, 
                    {
                        name    => $class_name . '_' . $column->{'ColName'}, 
                        desc_ja => 'ID',
                        desc_en => 'ID'
                    };
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {
                push @keywords, 
                    {
                        name    => $class_name . '_' . $column->{'ColName'}, 
                        desc_ja => '削除',
                        desc_en => 'DISABLE'
                    };
            }
            elsif ( 'date_regist' eq lc( $column->{'ColName'} ) ) {
                push @keywords, 
                    {
                        name    => $class_name . '_' . $column->{'ColName'}, 
                        desc_ja => '登録日時',
                        desc_en => 'DATE_REGIST'
                    };
            }
            elsif ( 'date_update' eq lc( $column->{'ColName'} ) ) {
                push @keywords, 
                    {
                        name    => $class_name . '_' . $column->{'ColName'}, 
                        desc_ja => '更新日時',
                        desc_en => 'DATE_UPDATE'
                    };
            }
            else {
                push @keywords, 
                    {
                        name    => $class_name . '_' . $column->{'ColName'}, 
                        desc_ja => 
                            length( $column->{'Comments'} ) == 0 ? 
                                uc $column->{'ColName'} : $this->encode( $column->{'Comments'} ),
                        desc_en => uc $column->{'ColName'}
                    };
            }

            # 列名の代入
            $sql->{'name'} = $column->{'ColName'};

            # 列の説明の代入
            $sql->{'desc'} = $class_name . '_' . $column->{'ColName'};

            push @sqls, $sql;
            push @settings, join( " ", @setting );
        }

        # SQL出力
        my $setting_vars;
        $setting_vars->{'table'}   = $table->{'Tablename'};
        $setting_vars->{'comment'} = $this->encode( $table->{'Comments'} );
        $setting_vars->{'columns'} = join( ",\n", @settings );
        $setting_vars->{'serials'} = join( "", @serials );
        $helper->render_file( 'schema_sql', "$schema_dir/$table->{'Tablename'}.sql", $setting_vars );

        # コントローラ出力
        my $controller_vars;
        $controller_vars->{'app_name'}   = $helper->{'app'};
        $controller_vars->{'path_name'}  = lc $class_name;
        $controller_vars->{'base_name'}  = $helper->{'name'};
        $controller_vars->{'model_name'} = $model_name;
        $controller_vars->{'class_name'} = $class_name;
        $controller_vars->{'comment'}    = $this->encode( $table->{'Comments'} );
        $controller_vars->{'primary'}    = $this->get_primary(@sqls);
        $controller_vars->{'columns'}    = $this->get_columns(@sqls);
        $controller_vars->{'sqls'}       = \@sqls;
        $helper->render_file( 'controller_class', "$controller_dir/$class_name.pm", $controller_vars );

        # テンプレート出力
        my $path_name = lc $class_name;
        $helper->mk_dir("$template_dir/$path_name");

        # Template-Toolkit
        $helper->render_file( 'create_tt', "$template_dir/$path_name/create.tt", $controller_vars );
        $helper->render_file( 'read_tt',   "$template_dir/$path_name/read.tt",   $controller_vars );
        $helper->render_file( 'update_tt', "$template_dir/$path_name/update.tt", $controller_vars );
        $helper->render_file( 'list_tt',   "$template_dir/$path_name/list.tt",   $controller_vars );

        # ClearSilver
        #$helper->render_file( 'create_cs', "$template_dir/$path_name/create.cs", $controller_vars );
        #$helper->render_file( 'read_cs',   "$template_dir/$path_name/read.cs",   $controller_vars );
        #$helper->render_file( 'update_cs', "$template_dir/$path_name/update.cs", $controller_vars );
        #$helper->render_file( 'list_cs',   "$template_dir/$path_name/list.cs",   $controller_vars );
    }

    # ヘッダー・フッター出力
    unless ( scalar @limited_file ) {
        my $header_footer_vars;
        $header_footer_vars->{'app_name'} = $helper->{'app'};

        # Template-Toolkit
        $helper->render_file( 'header_html', "$template_dir/header.tt", $header_footer_vars );
        $helper->render_file( 'footer_html', "$template_dir/footer.tt", $header_footer_vars );

        # ClearSilver
        #$helper->render_file( 'header_html', "$template_dir/header.cs", $header_footer_vars );
        #$helper->render_file( 'footer_html', "$template_dir/footer.cs", $header_footer_vars );
    }

    # 言語ファイル出力
    my $i18n_vars;
    $i18n_vars->{'keywords'} = \@keywords;
    if ( scalar @limited_file ) {
        $helper->render_file( 'ja_po', "$i18n_dir/ja.po", $i18n_vars );
        $helper->render_file( 'en_po', "$i18n_dir/en.po", $i18n_vars );
    } else {
        $helper->render_file( 'mini_ja_po', "$i18n_dir/ja.po", $i18n_vars );
        $helper->render_file( 'mini_en_po', "$i18n_dir/en.po", $i18n_vars );
    }

    print "==========================================================\n";
}

=head1 SEE ALSO

DBDesigner 4 -- http://fabforce.net/dbdesigner4/index.php

Catalyst::Helper::Model, Catalyst::Plugin::CRUD, XML::Simple

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__DATA__

__schema_sql__
-- DROP TABLE [% table %];

-- [% comment %]
CREATE TABLE [% table %] (
[% columns %]
);

GRANT ALL ON [% table %] TO PUBLIC;
[% serials %]

__controller_class__
package [% app_name %]::Controller::[% class_name %];

use strict;
use warnings;
use base 'Catalyst::Controller';
use Class::Trigger;

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
}

sub read : Local {
    my ( $self, $c ) = @_;
    $c->read($self);
}

sub update : Local {
    my ( $self, $c ) = @_;
    $c->update($self);
}

sub delete : Local {
    my ( $self, $c ) = @_;
    $c->delete($self);
}

sub list : Local {
    my ( $self, $c ) = @_;
    $c->list($self);
}

sub setting {
    my ( $self, $c ) = @_;
    my $hash = {
        'name'     => '[% path_name %]',
        'type'     => '[% base_name %]',
        'model'    => '[% base_name %]::[% model_name %]',
        'primary'  => '[% primary %]',
        'columns'  => [qw([% columns %])],
        'default'  => '/[% path_name %]/list',
        'template' => {
            'prefix' => 'template/[% path_name %]/',
            'suffix' => '.tt'
        },
    };
    return $hash;
}

1;

__header_html__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>[% app_name %]</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <!-- http://openjsan.org/doc/k/ko/komagata/Widget/Dialog/ -->
    <script type="text/javascript" src="/static/js/Widget/Dialog.js"></script>
    <!-- link rel="stylesheet" href="styles.css" / -->
    <style type="text/css">
    <!--
      #centre {
      border:1px solid #202020;
      border-bottom:0;
      border-top:0;
      color:#000;
      padding:1.5em;
      }

      #conteneur {
      background-color:#fafafa;
      margin:1em 5%;
      min-width:60em;
      position:absolute;
      width:90%;
      }

      #haut {
      background-color:#202020;
      height:2.4em;
      max-height:2.4em;
      }

      #header {
      background-color:#2D4B9B;
      border:1px solid #fafafa;
      color:#fafafa;
      font-size:2em;
      height:2.5em;
      padding-left:2em;
      padding-top:1em;
      }

      #pied {
      border:1px solid #202020;
      border-top:0;
      padding:0.5em;
      text-align:right;
      }

      .menuhaut {
      font-size:1em;
      list-style-type:none;
      margin:0;
      padding:0;
      }

      .menuhaut a {
      color:#fafafa;
      margin:0 0.4em;
      text-decoration:none;
      }

      .menuhaut a:hover {
      color:#FF0;
      text-decoration:none;
      }

      .menuhaut li {
      border-right:1px solid #fff;
      display:inline;
      float:left;
      margin:0;
      padding:0.6em 10px;
      }

      a {
      color:#000;
      text-decoration:underline;
      }

      body {
      background-color:#CDCDCD;
      font-family:Verdana, Arial, Helvetica, sans-serif;
      font-size:0.75em;
      }

      h1 {
      font-size:1.6em;
      margin:0.5em 0.5em 1em 0;
      }

      h2 {
      font-size:1.2em;
      margin:0.8em 0.5em 0.3em 0.6em;
      }

      h3 {
      font-size:1.1em;
      margin:0.8em 0.5em 0.3em 0.8em;
      }

      h4 {
      font-size:1em;
      margin:0.7em 0.5em 0.3em 1em;
      }

      h5 {
      font-size:0.9em;
      margin:0.6em 0.5em 0.2em 1.5em;
      }

      p {
      margin:1px 0.5em 0.5em 1.5em;
      }

      table {
      border-collapse: collapse;
      margin:1px 0.5em 0.5em 1.5em;
      }

      th {
      background-color: #C0C0C0;
      border: 1px solid #202020;
      padding: 3px;
      color: #202020;
      }

      td {
      background-color: #FFFFFF;
      border: 1px solid #202020;
      padding: 3px;
      }
    -->
    </style>
  </head>
  <body>
    <div id="conteneur">
      <!-- header -->
      <div id="header">[% app_name %]</div>
      <!-- menu -->
      <div id="haut">
        <ul class="menuhaut">
          <li><a href="#">menu1</a></li>
          <li><a href="#">menu2</a></li>
          <li><a href="#">menu3</a></li>
        </ul>
      </div>
      <!-- contents -->
      <div id="centre">

__footer_html__
      </div>
      <!-- footer -->
      <div id="pied">Copyright (C) 2007 foobar.</div>
    </div>
  </body>
</html>

__create_tt__
[% TAGS [- -] -%]
[% INCLUDE template/header.tt -%]

<h1>[- comment -] [% c.loc('New') %]</h1>

[% IF c.stash.create.error -%]
<p><font color="red">[% c.stash.create.error %]</font></p>
[% END -%]
<form name="[- path_name -]" method="post" action="/[- path_name -]/create">
<table>
[- FOREACH sql = sqls --]
  <tr>
    <td>[% c.loc('[- sql.desc -]') %]</td><td><input type="text" name="[- sql.name -]" size="25" value="[% c.req.param('[- sql.name -]') %]"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="btn_create" value="[% c.loc('Add') %]"></td>
  </tr>
</table>
</form>

[% INCLUDE template/footer.tt -%]

__create_cs__
[% TAGS [- -] -%]
<?cs include:"template/header.cs" ?>

<h1>[- comment -] <?cs var:loc.New ?></h1>

<?cs if:create.error ?>
<p><font color="red"><?cs var:create.error ?></font></p>
<?cs /if ?>
<form name="[- path_name -]" method="post" action="/[- path_name -]/create">
<table>
[- FOREACH sql = sqls --]
  <tr>
    <td><?cs var:loc.[- sql.desc -] ?></td><td><input type="text" name="[- sql.name -]" size="25" value="<?cs var:req_param.[- sql.name -] ?>"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="btn_create" value="<?cs var:loc.Add ?>"></td>
  </tr>
</table>
</form>

<?cs include:"template/footer.cs" ?>

__read_tt__
[% TAGS [- -] -%]
[% INCLUDE template/header.tt -%]

<h1>[- comment -] [% c.loc('Detail') %]</h1>

<form>
  <input type="button" name="btn_update" value="[% c.loc('Edit') %]" onclick="javascript:window.location='/[- path_name -]/update/[% c.stash.[- path_name -].[- primary -] %]';"><br/>
  <br/>
</form>

<table>
[- FOREACH sql = sqls --]
  <tr>
    <td>[% c.loc('[- sql.desc -]') %]</td><td>[% c.stash.[- path_name -].[- sql.name -] %]</td>
  </tr>
[- END --]
</table>

[% INCLUDE template/footer.tt -%]

__read_cs__
[% TAGS [- -] -%]
<?cs include:"template/header.cs" ?>

<h1>[- comment -] <?cs var:loc.Detail ?></h1>

<form>
  <input type="button" name="btn_update" value="<?cs var:loc.Edit ?>" onclick="javascript:window.location='/[- path_name -]/update/<?cs var:[- path_name -].[- primary -] ?>';"><br/>
  <br/>
</form>

<table>
[- FOREACH sql = sqls --]
  <tr>
    <td><?cs var:loc.[- sql.desc -] ?></td><td><?cs var:[- path_name -].[- sql.name -] ?></td>
  </tr>
[- END --]
</table>

<?cs include:"template/footer.cs" ?>

__update_tt__
[% TAGS [- -] -%]
[% INCLUDE template/header.tt -%]

<h1>[- comment -] [% c.loc('Edit') %]</h1>

[% IF c.stash.update.error -%]
<p><font color="red">[% c.stash.update.error %]</font></p>
[% END -%]
<form name="[- path_name -]" method="post" action="/[- path_name -]/update">
<table>
[- FOREACH sql = sqls --]
  <tr>
    <td>[% c.loc('[- sql.desc -]') %]</td><td><input type="text" name="[- sql.name -]" size="25" value="[% c.stash.[- path_name -].[- sql.name -] %]"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="btn_update" value="[% c.loc('Update') %]"></td>
  </tr>
</table>
</form>

[% INCLUDE template/footer.tt -%]

__update_cs__
[% TAGS [- -] -%]
<?cs include:"template/header.cs" ?>

<h1>[- comment -] <?cs var:loc.Edit ?></h1>

<?cs if:update.error ?>
<p><font color="red"><?cs var:update.error ?></font></p>
<?cs /if ?>
<form name="[- path_name -]" method="post" action="/[- path_name -]/update">
<table>
[- FOREACH sql = sqls --]
  <tr>
    <td><?cs var:loc.[- sql.desc -] ?></td><td><input type="text" name="[- sql.name -]" size="25" value="<?cs var:[- path_name -].[- sql.name -] ?>"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="btn_update" value="<?cs var:loc.Update ?>"></td>
  </tr>
</table>
</form>

<?cs include:"template/footer.cs" ?>

__list_tt__
[% TAGS [- -] -%]
[% INCLUDE template/header.tt -%]

<h1>[- comment -] [% c.loc('List') %]</h1>

<form>
  <input type="button" name="btn_create" value="[% c.loc('New') %]" onclick="javascript:window.location='/[- path_name -]/create';"><br/>
  <br/>
</form>

<script>
<!--
function confirmDelete(name, id) {
    var dialog = new Widget.Dialog;
    dialog.confirm('Can you delete ' + name + ' ?', {
        width: 300,
        height: 70,
        onOk: function(val) {
            window.location = '/[- path_name -]/delete/' + id;
        }
    });
}
//-->
</script>

<table>
<tr>
[- FOREACH sql = sqls --]
  <th>[% c.loc('[- sql.desc -]') %]</th>
[- END --]
  <th>[% c.loc('Detail') %]</th>
  <th>[% c.loc('Edit') %]</th>
  <th>[% c.loc('Delete') %]</th>
</tr>
[% FOREACH [- path_name -] = c.stash.[- path_name -]s -%]
<tr>
[- FOREACH sql = sqls --]
  <td>[% [- path_name -].[- sql.name -] %]</td>
[- END --]
  <td><a href="/[- path_name -]/read/[% [- path_name -].[- primary -] %]">[% c.loc('Detail') %]</a></td>
  <td><a href="/[- path_name -]/update/[% [- path_name -].[- primary -] %]">[% c.loc('Edit') %]</a></td>
  <td><a href="#" onClick="confirmDelete('[% [- path_name -].[- primary -] %]',[% [- path_name -].[- primary -] %]);return false;">[% c.loc('Delete') %]</a></td>
</tr>
[% END -%]
</table>

[% INCLUDE template/footer.tt -%]

__list_cs__
[% TAGS [- -] -%]
<?cs include:"template/header.cs" ?>

<h1>[- comment -] <?cs var:loc.List ?></h1>

<form>
  <input type="button" name="btn_create" value="<?cs var:loc.New ?>" onclick="javascript:window.location='/[- path_name -]/create';"><br/>
  <br/>
</form>

<script>
<!--
function confirmDelete(name, id) {
    var dialog = new Widget.Dialog;
    dialog.confirm('Can you delete ' + name + ' ?', {
        width: 300,
        height: 70,
        onOk: function(val) {
            window.location = '/[- path_name -]/delete/' + id;
        }
    });
}
//-->
</script>

<table>
<tr>
[- FOREACH sql = sqls --]
  <th><?cs var:loc.[- sql.desc -] ?></th>
[- END --]
  <th><?cs var:loc.Detail ?></th>
  <th><?cs var:loc.Edit ?></th>
  <th><?cs var:loc.Delete ?></th>
</tr>
<?cs each:[- path_name -] = [- path_name -]s ?>
<tr>
[- FOREACH sql = sqls --]
  <td><?cs var:[- path_name -].[- sql.name -] ?></td>
[- END --]
  <td><a href="/[- path_name -]/read/<?cs var:[- path_name -].[- primary -] ?>"><?cs var:loc.Detail ?></a></td>
  <td><a href="/[- path_name -]/update/<?cs var:[- path_name -].[- primary -] ?>"><?cs var:loc.Edit ?></a></td>
  <td><a href="#" onClick="confirmDelete('<?cs var:[- path_name -].[- primary -] ?>',<?cs var:[- path_name -].[- primary -] ?>);return false;"><?cs var:loc.Delete ?></a></td>
</tr>
<?cs /each ?>
</table>

<?cs include:"template/footer.cs" ?>

__ja_po__
msgid "New"
msgstr "新規"

msgid "Detail"
msgstr "詳細"

msgid "Edit"
msgstr "編集"

msgid "Delete"
msgstr "削除"

msgid "List"
msgstr "一覧"

msgid "Add"
msgstr "追加"

msgid "Update"
msgstr "更新"

msgid "Search"
msgstr "検索"

msgid "Login"
msgstr "ログイン"

msgid "Logout"
msgstr "ログアウト"

[% FOREACH keyword = keywords -%]
msgid "[% keyword.name -%]"
msgstr "[% keyword.desc_ja -%]"

[% END -%]

__mini_ja_po__
[% FOREACH keyword = keywords -%]
msgid "[% keyword.name -%]"
msgstr "[% keyword.desc_ja -%]"

[% END -%]

__en_po__
msgid "New"
msgstr ""

msgid "Detail"
msgstr ""

msgid "Edit"
msgstr ""

msgid "Delete"
msgstr ""

msgid "List"
msgstr ""

msgid "Add"
msgstr ""

msgid "Update"
msgstr ""

msgid "Search"
msgstr ""

msgid "Login"
msgstr ""

msgid "Logout"
msgstr ""

[% FOREACH keyword = keywords -%]
msgid "[% keyword.name -%]"
msgstr "[% keyword.desc_en -%]"

[% END -%]

__mini_en_po__
[% FOREACH keyword = keywords -%]
msgid "[% keyword.name -%]"
msgstr "[% keyword.desc_en -%]"

[% END -%]
