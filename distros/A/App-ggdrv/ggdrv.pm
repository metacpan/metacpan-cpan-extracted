package App::ggdrv ;  
our $VERSION = '0.031' ; 
our $DATE = '2023-03-16T11:45+09:00' ; 

=encoding utf8

=head1 NAME

App::ggdrv

=head1 SYNOPSIS

This module App::ggdrv provides a Unix-like command `F<ggdrv>'. 

=head1 DESCRIPTION

=head1
 ggdrv 

  サブコマンド方式で、様々な関連する機能を実行可能としている。
  OAuthの仕組みでGoogleドライブにファイルを自動更新で同期する機能を提供する。

 利用例 :

   ggdrv --help  # --help により、このヘルプの文面が現れる。

  [設定系]
   ggdrv   # 引数無しで実行すると、最初のセットアップの仕方(ブラウザ越しで「クライアントシークレット」を作る方法)が表示される。
   ggdrv crecord  # クライアントシークレット(Client)などを、設定ファイルに書き込む方法が表示される。
   ggdrv crecord --run  # 表示される内容を実際に実行する。
   ggdrv tokens  #  トークンの情報2個を単に表示する。(リフレッシュトークン(使わないと半年で無効化)とアクセストークンがある。)
   ggdrv tokens --get   # トークンを取得する(設定ファイルに書き込む)。書き込む前のファイルはバックアップは1回のみ保管。
   ggdrv tokens --get --try   # トークンを取得するが、設定ファイルには書き込まない。
   ggdrv tokens --atoken  # アクセストークンのみ更新する。60分未使用であれば、更新は必要。-try を指定すると設定ファイルに書き込まない。

  [ファイル検索]
   ggdrv fsearch FILENAME # ファイルを最大100個まで探す(フォルダは指定不能)。ワイルドカードを指定可能。タブ区切り5列で出力。
   ggdrv fsearchall -g10  # ファイルを100個ずつ -g で指定した回数出力(フォルダは指定不能)。1個のファイルにつき、縦に4行を出力。## <-- 時々リフレッシュトークンを更新する必要あり。

  [(単純な)アップロード/更新/ダウンロード]
   ggdrv upload -f フォルダID(28文字) FILE [FILE] .. # アップロードする。 同名ファイルに対し複数回実行したら、その分グーグルドライブ上に現れるので注意。
   ggdrv update ID1 FILE1 [ID2 FILE2] [ID3 FILE3] .. # 更新する。33文字のIDに対して、ローカルのファイルの名前をペアにして指定。
   ggdrv download ファイルID(33文字) ローカルで予定するファイル名 # ダウンロードする。

  [作業対象のファイルを管理しつつアップロード/更新/ダウンロード] ※ サブコマンドに「5」が後置するのが特徴。
   ggdrv upload5 FOLDER_ID LOCAL_DIR > VAR_FILE # アップロードする。標準出力をファイルに保管して、続くサブコマンドでも使う。
   ggdrv download5 LOCAL_DIR < VAR_FILE        # ダウンロードする。
   ggdrv sync5 OLD_DIR NEW_DIR < VAR_FILE   # 同期に使う。OLD_DIRはGoogleドライブと予め同期させ、NEW_DIRと違えば、それをアップデート。

 オプション: 
   -2 0 : 最後に2次情報を標準エラー出力に出さない。サブコマンドの後ろに置くこと。

 環境変数 : export VAR=VALUE で指定。unset VAR で解除が可能。

   GGDRV_API    :  クライアントIDやクライアントシークレットを保管するファイルの名前。未指定なら ~/ggdrv2303v1 である。
 
=head1 AUTHOR

下野寿之 Toshiyuki SHIMONO <bin4tsv@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Toshiyuki SHIMONO. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1 ;
