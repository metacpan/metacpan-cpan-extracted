#!/bin/sh


if [ ! -e user.dic ]; then
    where mecab-dict-index
    /usr/local/libexec/mecab/mecab-dict-index \
        -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd \ # 環境依存
        -u user.dic -f UTF8 -t UTF8 share/MeCab.csv
fi
