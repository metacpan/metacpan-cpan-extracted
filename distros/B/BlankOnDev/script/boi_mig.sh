#!/bin/bash

PKG_NAME=$1

echo "\ncloning $PKG_NAME ..."
bzr branch http://dev.blankonlinux.or.id/browser/tambora/$PKG_NAME $PKG_NAME;
cd $PKG_NAME;
echo "\ninitialize git & remove bzr"
git init
bzr fast-export $(pwd) | git fast-import
git reset HEAD
rm -rf .bzr
#git remote add origin https://github.com/blankon-packages/$PKG_NAME.git
echo "\nadd remote origin master and tambora"
git remote add origin git@github.com:blankon-packages/$PKG_NAME.git
echo "\npush to master..."
git push -u origin master
echo "\nswitch branch to tambora"
git checkout -b tambora
echo "\npush to tambora"
git push -u origin tambora
echo "done"