#!/bin/sh

set -e
set -u

ROOT=$PWD
mkdir $ROOT/git-test

mkdir $ROOT/git-test/repo.git
cd $ROOT/git-test/repo.git
git init --bare

cat <<EOF > $ROOT/git-test/repo.git/hooks/post-receive
#!/bin/sh

tee -a $ROOT/git-test/reflog | PERL5LIB=$ROOT/lib $ROOT/script/kgb-client --repository git --uri http://localhost:9999 --pass "truely secret" --repo-id test --git-reflog -
EOF

chmod 0755 $ROOT/git-test/repo.git/hooks/post-receive

mkdir $ROOT/git-test/work
cd $ROOT/git-test/work
echo "testing" > a
git init
git add a
git commit -m "initial import"
git remote add origin file://$ROOT/git-test/repo.git
git config --add branch.master.remote origin
git config --add branch.master.merge refs/heads/master

git push

echo "more testing" > b
echo "twisted testing" > a
git add .
git commit -m 'some modifications'

echo "third file" > c
git add .
git commit -m 'short note

followed by a longer thing'
git push
