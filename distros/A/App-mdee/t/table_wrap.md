# Wrap

| key | description |
|-----|-------------|
| k1 | the quick brown fox jumps over the lazy dog and keeps on running through the field |
| - alpha | this is a fairly long description cell that goes well beyond forty columns wide |
| 日本 | これは長い説明文で、幅に収まらないので折り返されるはずの文章です。句読点、括弧（あり）。 |
| k2 | short |

- `ls | grep foo` lists the files whose names contain foo, and this line is long enough to need folding at forty
- `ps | wc -l` counts the processes, and this line is also long enough to need folding at forty columns
- `cat a | sort` sorts the file, and this line is likewise long enough to need folding at forty columns
