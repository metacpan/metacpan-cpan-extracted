" Bigtop filetype file
"if exists("did_load_filetypes")
"    finish
"endif
augroup filetypedetect
    au! Bufread,BufNewFile *.bigtop     setfiletype bigtop
augroup END
