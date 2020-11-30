#!/bin/bash
rm -rf tmp_repo
git init tmp_repo
cd tmp_repo

git commit --allow-empty -m initial\ commit

echo 1 > a
git add a
git commit -m A

echo 2 > a
../git-autofixup HEAD~

git status
