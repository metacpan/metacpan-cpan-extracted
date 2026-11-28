# リリース手順

リリースは tagpr で行う。手元で `minil release` は実行しない（版を上げてタグを打つのは tagpr の役目）。
仕組みの詳細と、落ちたときの扱いは `scripts/tagpr/README.md` の「The tagpr workflow」と
「The CPAN publish workflow」にある。

## 普段の流れ

1. 変更は PR で入れる。利用者に見える変更の PR は、`CHANGELOG.md` の `## [Unreleased]` の下に
   1 行を足す。その節がそのままリリースノートになる
2. `master` へマージされるたびに、`tagpr.yml` がリリース PR（ブランチ `tagpr-from-v<前の版>`）を
   作り直す。リリース PR は `lib/Acme/PrettyCure.pm` の `$VERSION` と `META.json` の版を上げ、
   `## [Unreleased]` をその版の節に変える
3. 出したくなったら、リリース PR の中身（版と CHANGELOG の節）を確かめてマージする
   - **tagpr の run が赤いリリース PR はマージしない**（落ちた run はリリース PR を draft にする）
   - リリース PR では CI（`ci.yml` など）が走らない。tagpr が `GITHUB_TOKEN` で作る PR は、
     workflow を起動しないため。版と CHANGELOG の検査は、tagpr の run の中の
     `release-prepare.mjs` が行う。ブランチ保護で CI を必須にしているので、リリース PR は
     管理者の bypass でマージする（下の「ブランチ保護」）
   - 版の上がり方はラベルで決まる。`enhancement` の PR が入っていれば minor、それ以外は patch。
     変えたいときはリリース PR に `tagpr:minor` / `tagpr:major` を付ける。`tagpr-label.yml` が
     リリース PR を draft にして作り直し、ready に戻す。ready に戻るのを待ってからマージする
4. マージすると、tagpr がタグ（`vX.Y.Z`）を打ち、`publish.yml` が起動する。`publish.yml` は
   テストして tarball を作り、PAUSE へアップロードしてから GitHub Release を作る
5. PAUSE から届く索引のメールを確かめる

**PAUSE へのアップロードは取り消せない。** 同じファイル名は二度と受け付けられないので、壊れた版を
出したら版を上げて出し直す。

## 最初に一度だけ要る設定

- tagpr が数え始めるタグとして、`v0.1.3` を 0789dce（今の `0.1.3` のタグと同じコミット）に
  annotated で打って push する。`.tagpr` が `master` に入る前に済ませる。無いと tagpr は前の版を
  0.0.0 と見て、版のファイルを書き換えられない

  ```bash
  git tag -a -m "Release v0.1.3" v0.1.3 0789dce
  git push origin v0.1.3
  ```

- Settings → Actions → General の「Allow GitHub Actions to create and approve pull requests」を
  有効にする（無いと最初の tagpr の run が 403 で落ちる）
- Settings → Environments に `cpan` を作り、secret `PAUSE_USER`（PAUSE の ID。今までの版は `MIKIHOSHI` で上げている）と `PAUSE_PASSWORD` を
  置く。「Deployment branches and tags」で、タグ `v*` だけに絞る
- ブランチ保護を設定する（下の「ブランチ保護」）

## ブランチ保護

Settings → Rules → Rulesets で、`master`（Default branch）に次の ruleset を作る。

- Restrict deletions、Block force pushes
- Require a pull request before merging（`master` へ直接 push させない。tagpr はマージされた PR から
  リリース PR を組み立てるので、直接 push した変更はリリースの流れから漏れる）
  - Allowed merge methods に **Merge** を含める。`scripts/tagpr/` を `git subtree pull` で上げる PR は
    マージコミットでマージする（squash すると次の subtree pull が壊れる）
- Require status checks to pass: `test (perl 5.44)`、`author`、`dist`、`tagpr-subtree`、
  `Verify actions.lock`
  - `test (perl devel)` は必須にしない（開発版の Perl で落ちてもよいジョブ）
- Bypass list に Repository admin を「For pull requests only」で入れる。リリース PR では CI が
  走らず、必須のチェックが揃わないため

## 1.0.0 について

tagpr での最初のリリースは 1.0.0 にする（#5）。0.x の 3 つ組の版は、数値にすると小さくなり
（0.1.3 は 0.001003）、前に出した 0.1 や 0.08 より古い版として扱われる。最初のリリース PR に
`tagpr:major` を付ける。
