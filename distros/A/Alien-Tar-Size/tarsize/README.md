# tarsize
Calculates the exact potential size of the output of tar by hooking wrappers of syscalls

To run `./tarsize.sh -c <FileOrFoldername>`

If tarsize.so is not compatible with your system, compile by running `./build.sh`

Works by eliminating syscalls to `read` and `write` in tar, by hooking their wrappers using LD_PRELOAD. Does not work with compression (as a part of the tar command) as the data is not actually read, the count parameter is just summed.

```
$ time tar -c /media/storage/music/Macintosh\ Plus-\ Floral\ Shoppe\ \(2011\)\ \[Flac\]/ | wc -c
tar: Removing leading / from member names
332308480

real    0m0.457s
user    0m0.064s
sys     0m0.772s
```

```
tarsize$ time ./tarsize.sh -c /media/storage/music/Macintosh\ Plus-\ Floral\ Shoppe\ \(2011\)\ \[Flac\]/
tar: Removing leading / from member names
332308480

real    0m0.016s
user    0m0.004s
sys     0m0.008s
```
