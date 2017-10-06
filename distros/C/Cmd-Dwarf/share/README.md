# <APP_NAME> プロジェクト

## ローカル開発環境

主にフロント開発者向けに Docker でローカル開発環境を立ち上げられるようにしました。

URL: [http://localhost:5000/](http://localhost:5000/)

\* 要 [Docker for Mac](https://download.docker.com/mac/stable/Docker.dmg)

### 初期設定

```
% docker-compose up
```

### 更新

```
% docker-compose down --rmi all
% docker-compose up -d --force-recreate --build
```

### マウントポイント

以下はホストマシンのディレクトリをマウントするため、ファイル更新時に毎回 `docker-compose down` 及び `up` し直す必要はありません。

- app/lib
- app/tmpl
- app/t
- app/script
- app/sql
- htdocs

### ログの確認方法

`docker-compose up` に `-d` を付けるとバックグラウンドでの実行になる。その場合、ログの確認は以下で行える。


```
% docker-compose logs -f
```

### エイリアス

docker-compose 長いのでエイリアスを作っておくと良い。

```
alias fig='docker-compose'
```

### 参考

- [docker-compose コマンドまとめ](https://qiita.com/aild_arch_bfmv/items/d47caf37b79e855af95f)