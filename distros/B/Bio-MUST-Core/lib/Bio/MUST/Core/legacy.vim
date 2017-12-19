let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
imap <silent> <Home> <Home>
map! <S-Insert> <MiddleMouse>
map  :bNext
nmap 	 i	
vmap 	 >gv
map  "+gp
map Q vipgq
xmap S <Plug>VSurround
nmap <silent> [e <Plug>JumpDiffCharPrevEnd
nmap <silent> [b <Plug>JumpDiffCharPrevStart
nmap <silent> \ig <Plug>IndentGuidesToggle
map \\ <Plug>(easymotion-prefix)
nmap <silent> ]e <Plug>JumpDiffCharNextEnd
nmap <silent> ]b <Plug>JumpDiffCharNextStart
vnoremap <silent> _d :!perl -mo=deparse 2>/dev/null
nnoremap <silent> _d :.!perl -mo=deparse 2>/dev/null
vnoremap <silent> _t :!perltidy -q
nnoremap <silent> _t :%!perltidy -q
vmap _C :s/^#//gi
vmap _c :s/^/#/gi
nmap cS <Plug>CSurround
nmap cs <Plug>Csurround
nmap ds <Plug>Dsurround
nmap gx <Plug>NetrwBrowseX
xmap gS <Plug>VgSurround
map j gj
map k gk
nmap ySS <Plug>YSsurround
nmap ySs <Plug>YSsurround
nmap yss <Plug>Yssurround
nmap yS <Plug>YSurround
nmap ys <Plug>Ysurround
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
nnoremap <silent> <Plug>SurroundRepeat .
nmap <silent> <F7> <Plug>ToggleDiffCharAllLines
map <silent> <Plug>(easymotion-prefix)N <Plug>(easymotion-N)
map <silent> <Plug>(easymotion-prefix)n <Plug>(easymotion-n)
map <silent> <Plug>(easymotion-prefix)k <Plug>(easymotion-k)
map <silent> <Plug>(easymotion-prefix)j <Plug>(easymotion-j)
map <silent> <Plug>(easymotion-prefix)gE <Plug>(easymotion-gE)
map <silent> <Plug>(easymotion-prefix)ge <Plug>(easymotion-ge)
map <silent> <Plug>(easymotion-prefix)E <Plug>(easymotion-E)
map <silent> <Plug>(easymotion-prefix)e <Plug>(easymotion-e)
map <silent> <Plug>(easymotion-prefix)B <Plug>(easymotion-B)
map <silent> <Plug>(easymotion-prefix)b <Plug>(easymotion-b)
map <silent> <Plug>(easymotion-prefix)W <Plug>(easymotion-W)
map <silent> <Plug>(easymotion-prefix)w <Plug>(easymotion-w)
map <silent> <Plug>(easymotion-prefix)T <Plug>(easymotion-T)
map <silent> <Plug>(easymotion-prefix)t <Plug>(easymotion-t)
map <silent> <Plug>(easymotion-prefix)s <Plug>(easymotion-s)
map <silent> <Plug>(easymotion-prefix)F <Plug>(easymotion-F)
map <silent> <Plug>(easymotion-prefix)f <Plug>(easymotion-f)
xnoremap <silent> <Plug>(easymotion-activate) :call EasyMotion#activate(1)
nnoremap <silent> <Plug>(easymotion-activate) :call EasyMotion#activate(0)
snoremap <silent> <Plug>(easymotion-activate) :call EasyMotion#activate(0)
onoremap <silent> <Plug>(easymotion-activate) :call EasyMotion#activate(0)
noremap <silent> <Plug>(easymotion-dotrepeat) :call EasyMotion#DotRepeat()
xnoremap <silent> <Plug>(easymotion-repeat) :call EasyMotion#Repeat(1)
nnoremap <silent> <Plug>(easymotion-repeat) :call EasyMotion#Repeat(0)
snoremap <silent> <Plug>(easymotion-repeat) :call EasyMotion#Repeat(0)
onoremap <silent> <Plug>(easymotion-repeat) :call EasyMotion#Repeat(0)
xnoremap <silent> <Plug>(easymotion-prev) :call EasyMotion#NextPrevious(1,1)
nnoremap <silent> <Plug>(easymotion-prev) :call EasyMotion#NextPrevious(0,1)
snoremap <silent> <Plug>(easymotion-prev) :call EasyMotion#NextPrevious(0,1)
onoremap <silent> <Plug>(easymotion-prev) :call EasyMotion#NextPrevious(0,1)
xnoremap <silent> <Plug>(easymotion-next) :call EasyMotion#NextPrevious(1,0)
nnoremap <silent> <Plug>(easymotion-next) :call EasyMotion#NextPrevious(0,0)
snoremap <silent> <Plug>(easymotion-next) :call EasyMotion#NextPrevious(0,0)
onoremap <silent> <Plug>(easymotion-next) :call EasyMotion#NextPrevious(0,0)
xnoremap <silent> <Plug>(easymotion-wl) :call EasyMotion#WBL(1,0)
nnoremap <silent> <Plug>(easymotion-wl) :call EasyMotion#WBL(0,0)
snoremap <silent> <Plug>(easymotion-wl) :call EasyMotion#WBL(0,0)
onoremap <silent> <Plug>(easymotion-wl) :call EasyMotion#WBL(0,0)
xnoremap <silent> <Plug>(easymotion-lineforward) :call EasyMotion#LineAnywhere(1,0)
nnoremap <silent> <Plug>(easymotion-lineforward) :call EasyMotion#LineAnywhere(0,0)
snoremap <silent> <Plug>(easymotion-lineforward) :call EasyMotion#LineAnywhere(0,0)
onoremap <silent> <Plug>(easymotion-lineforward) :call EasyMotion#LineAnywhere(0,0)
xnoremap <silent> <Plug>(easymotion-lineanywhere) :call EasyMotion#LineAnywhere(1,2)
nnoremap <silent> <Plug>(easymotion-lineanywhere) :call EasyMotion#LineAnywhere(0,2)
snoremap <silent> <Plug>(easymotion-lineanywhere) :call EasyMotion#LineAnywhere(0,2)
onoremap <silent> <Plug>(easymotion-lineanywhere) :call EasyMotion#LineAnywhere(0,2)
xnoremap <silent> <Plug>(easymotion-bd-wl) :call EasyMotion#WBL(1,2)
nnoremap <silent> <Plug>(easymotion-bd-wl) :call EasyMotion#WBL(0,2)
snoremap <silent> <Plug>(easymotion-bd-wl) :call EasyMotion#WBL(0,2)
onoremap <silent> <Plug>(easymotion-bd-wl) :call EasyMotion#WBL(0,2)
xnoremap <silent> <Plug>(easymotion-linebackward) :call EasyMotion#LineAnywhere(1,1)
nnoremap <silent> <Plug>(easymotion-linebackward) :call EasyMotion#LineAnywhere(0,1)
snoremap <silent> <Plug>(easymotion-linebackward) :call EasyMotion#LineAnywhere(0,1)
onoremap <silent> <Plug>(easymotion-linebackward) :call EasyMotion#LineAnywhere(0,1)
xnoremap <silent> <Plug>(easymotion-bl) :call EasyMotion#WBL(1,1)
nnoremap <silent> <Plug>(easymotion-bl) :call EasyMotion#WBL(0,1)
snoremap <silent> <Plug>(easymotion-bl) :call EasyMotion#WBL(0,1)
onoremap <silent> <Plug>(easymotion-bl) :call EasyMotion#WBL(0,1)
xnoremap <silent> <Plug>(easymotion-el) :call EasyMotion#EL(1,0)
nnoremap <silent> <Plug>(easymotion-el) :call EasyMotion#EL(0,0)
snoremap <silent> <Plug>(easymotion-el) :call EasyMotion#EL(0,0)
onoremap <silent> <Plug>(easymotion-el) :call EasyMotion#EL(0,0)
xnoremap <silent> <Plug>(easymotion-gel) :call EasyMotion#EL(1,1)
nnoremap <silent> <Plug>(easymotion-gel) :call EasyMotion#EL(0,1)
snoremap <silent> <Plug>(easymotion-gel) :call EasyMotion#EL(0,1)
onoremap <silent> <Plug>(easymotion-gel) :call EasyMotion#EL(0,1)
xnoremap <silent> <Plug>(easymotion-bd-el) :call EasyMotion#EL(1,2)
nnoremap <silent> <Plug>(easymotion-bd-el) :call EasyMotion#EL(0,2)
snoremap <silent> <Plug>(easymotion-bd-el) :call EasyMotion#EL(0,2)
onoremap <silent> <Plug>(easymotion-bd-el) :call EasyMotion#EL(0,2)
xnoremap <silent> <Plug>(easymotion-jumptoanywhere) :call EasyMotion#JumpToAnywhere(1,2)
nnoremap <silent> <Plug>(easymotion-jumptoanywhere) :call EasyMotion#JumpToAnywhere(0,2)
snoremap <silent> <Plug>(easymotion-jumptoanywhere) :call EasyMotion#JumpToAnywhere(0,2)
onoremap <silent> <Plug>(easymotion-jumptoanywhere) :call EasyMotion#JumpToAnywhere(0,2)
xnoremap <silent> <Plug>(easymotion-vim-n) :call EasyMotion#Search(1,0,1)
nnoremap <silent> <Plug>(easymotion-vim-n) :call EasyMotion#Search(0,0,1)
snoremap <silent> <Plug>(easymotion-vim-n) :call EasyMotion#Search(0,0,1)
onoremap <silent> <Plug>(easymotion-vim-n) :call EasyMotion#Search(0,0,1)
xnoremap <silent> <Plug>(easymotion-n) :call EasyMotion#Search(1,0,0)
nnoremap <silent> <Plug>(easymotion-n) :call EasyMotion#Search(0,0,0)
snoremap <silent> <Plug>(easymotion-n) :call EasyMotion#Search(0,0,0)
onoremap <silent> <Plug>(easymotion-n) :call EasyMotion#Search(0,0,0)
xnoremap <silent> <Plug>(easymotion-bd-n) :call EasyMotion#Search(1,2,0)
nnoremap <silent> <Plug>(easymotion-bd-n) :call EasyMotion#Search(0,2,0)
snoremap <silent> <Plug>(easymotion-bd-n) :call EasyMotion#Search(0,2,0)
onoremap <silent> <Plug>(easymotion-bd-n) :call EasyMotion#Search(0,2,0)
xnoremap <silent> <Plug>(easymotion-vim-N) :call EasyMotion#Search(1,1,1)
nnoremap <silent> <Plug>(easymotion-vim-N) :call EasyMotion#Search(0,1,1)
snoremap <silent> <Plug>(easymotion-vim-N) :call EasyMotion#Search(0,1,1)
onoremap <silent> <Plug>(easymotion-vim-N) :call EasyMotion#Search(0,1,1)
xnoremap <silent> <Plug>(easymotion-N) :call EasyMotion#Search(1,1,0)
nnoremap <silent> <Plug>(easymotion-N) :call EasyMotion#Search(0,1,0)
snoremap <silent> <Plug>(easymotion-N) :call EasyMotion#Search(0,1,0)
onoremap <silent> <Plug>(easymotion-N) :call EasyMotion#Search(0,1,0)
xnoremap <silent> <Plug>(easymotion-eol-j) :call EasyMotion#Eol(1,0)
nnoremap <silent> <Plug>(easymotion-eol-j) :call EasyMotion#Eol(0,0)
snoremap <silent> <Plug>(easymotion-eol-j) :call EasyMotion#Eol(0,0)
onoremap <silent> <Plug>(easymotion-eol-j) :call EasyMotion#Eol(0,0)
xnoremap <silent> <Plug>(easymotion-sol-k) :call EasyMotion#Sol(1,1)
nnoremap <silent> <Plug>(easymotion-sol-k) :call EasyMotion#Sol(0,1)
snoremap <silent> <Plug>(easymotion-sol-k) :call EasyMotion#Sol(0,1)
onoremap <silent> <Plug>(easymotion-sol-k) :call EasyMotion#Sol(0,1)
xnoremap <silent> <Plug>(easymotion-sol-j) :call EasyMotion#Sol(1,0)
nnoremap <silent> <Plug>(easymotion-sol-j) :call EasyMotion#Sol(0,0)
snoremap <silent> <Plug>(easymotion-sol-j) :call EasyMotion#Sol(0,0)
onoremap <silent> <Plug>(easymotion-sol-j) :call EasyMotion#Sol(0,0)
xnoremap <silent> <Plug>(easymotion-k) :call EasyMotion#JK(1,1)
nnoremap <silent> <Plug>(easymotion-k) :call EasyMotion#JK(0,1)
snoremap <silent> <Plug>(easymotion-k) :call EasyMotion#JK(0,1)
onoremap <silent> <Plug>(easymotion-k) :call EasyMotion#JK(0,1)
xnoremap <silent> <Plug>(easymotion-j) :call EasyMotion#JK(1,0)
nnoremap <silent> <Plug>(easymotion-j) :call EasyMotion#JK(0,0)
snoremap <silent> <Plug>(easymotion-j) :call EasyMotion#JK(0,0)
onoremap <silent> <Plug>(easymotion-j) :call EasyMotion#JK(0,0)
xnoremap <silent> <Plug>(easymotion-bd-jk) :call EasyMotion#JK(1,2)
nnoremap <silent> <Plug>(easymotion-bd-jk) :call EasyMotion#JK(0,2)
snoremap <silent> <Plug>(easymotion-bd-jk) :call EasyMotion#JK(0,2)
onoremap <silent> <Plug>(easymotion-bd-jk) :call EasyMotion#JK(0,2)
xnoremap <silent> <Plug>(easymotion-eol-bd-jk) :call EasyMotion#Eol(1,2)
nnoremap <silent> <Plug>(easymotion-eol-bd-jk) :call EasyMotion#Eol(0,2)
snoremap <silent> <Plug>(easymotion-eol-bd-jk) :call EasyMotion#Eol(0,2)
onoremap <silent> <Plug>(easymotion-eol-bd-jk) :call EasyMotion#Eol(0,2)
xnoremap <silent> <Plug>(easymotion-sol-bd-jk) :call EasyMotion#Sol(1,2)
nnoremap <silent> <Plug>(easymotion-sol-bd-jk) :call EasyMotion#Sol(0,2)
snoremap <silent> <Plug>(easymotion-sol-bd-jk) :call EasyMotion#Sol(0,2)
onoremap <silent> <Plug>(easymotion-sol-bd-jk) :call EasyMotion#Sol(0,2)
xnoremap <silent> <Plug>(easymotion-eol-k) :call EasyMotion#Eol(1,1)
nnoremap <silent> <Plug>(easymotion-eol-k) :call EasyMotion#Eol(0,1)
snoremap <silent> <Plug>(easymotion-eol-k) :call EasyMotion#Eol(0,1)
onoremap <silent> <Plug>(easymotion-eol-k) :call EasyMotion#Eol(0,1)
xnoremap <silent> <Plug>(easymotion-iskeyword-ge) :call EasyMotion#EK(1,1)
nnoremap <silent> <Plug>(easymotion-iskeyword-ge) :call EasyMotion#EK(0,1)
snoremap <silent> <Plug>(easymotion-iskeyword-ge) :call EasyMotion#EK(0,1)
onoremap <silent> <Plug>(easymotion-iskeyword-ge) :call EasyMotion#EK(0,1)
xnoremap <silent> <Plug>(easymotion-w) :call EasyMotion#WB(1,0)
nnoremap <silent> <Plug>(easymotion-w) :call EasyMotion#WB(0,0)
snoremap <silent> <Plug>(easymotion-w) :call EasyMotion#WB(0,0)
onoremap <silent> <Plug>(easymotion-w) :call EasyMotion#WB(0,0)
xnoremap <silent> <Plug>(easymotion-bd-W) :call EasyMotion#WBW(1,2)
nnoremap <silent> <Plug>(easymotion-bd-W) :call EasyMotion#WBW(0,2)
snoremap <silent> <Plug>(easymotion-bd-W) :call EasyMotion#WBW(0,2)
onoremap <silent> <Plug>(easymotion-bd-W) :call EasyMotion#WBW(0,2)
xnoremap <silent> <Plug>(easymotion-iskeyword-w) :call EasyMotion#WBK(1,0)
nnoremap <silent> <Plug>(easymotion-iskeyword-w) :call EasyMotion#WBK(0,0)
snoremap <silent> <Plug>(easymotion-iskeyword-w) :call EasyMotion#WBK(0,0)
onoremap <silent> <Plug>(easymotion-iskeyword-w) :call EasyMotion#WBK(0,0)
xnoremap <silent> <Plug>(easymotion-gE) :call EasyMotion#EW(1,1)
nnoremap <silent> <Plug>(easymotion-gE) :call EasyMotion#EW(0,1)
snoremap <silent> <Plug>(easymotion-gE) :call EasyMotion#EW(0,1)
onoremap <silent> <Plug>(easymotion-gE) :call EasyMotion#EW(0,1)
xnoremap <silent> <Plug>(easymotion-e) :call EasyMotion#E(1,0)
nnoremap <silent> <Plug>(easymotion-e) :call EasyMotion#E(0,0)
snoremap <silent> <Plug>(easymotion-e) :call EasyMotion#E(0,0)
onoremap <silent> <Plug>(easymotion-e) :call EasyMotion#E(0,0)
xnoremap <silent> <Plug>(easymotion-bd-E) :call EasyMotion#EW(1,2)
nnoremap <silent> <Plug>(easymotion-bd-E) :call EasyMotion#EW(0,2)
snoremap <silent> <Plug>(easymotion-bd-E) :call EasyMotion#EW(0,2)
onoremap <silent> <Plug>(easymotion-bd-E) :call EasyMotion#EW(0,2)
xnoremap <silent> <Plug>(easymotion-iskeyword-e) :call EasyMotion#EK(1,0)
nnoremap <silent> <Plug>(easymotion-iskeyword-e) :call EasyMotion#EK(0,0)
snoremap <silent> <Plug>(easymotion-iskeyword-e) :call EasyMotion#EK(0,0)
onoremap <silent> <Plug>(easymotion-iskeyword-e) :call EasyMotion#EK(0,0)
xnoremap <silent> <Plug>(easymotion-b) :call EasyMotion#WB(1,1)
nnoremap <silent> <Plug>(easymotion-b) :call EasyMotion#WB(0,1)
snoremap <silent> <Plug>(easymotion-b) :call EasyMotion#WB(0,1)
onoremap <silent> <Plug>(easymotion-b) :call EasyMotion#WB(0,1)
xnoremap <silent> <Plug>(easymotion-iskeyword-b) :call EasyMotion#WBK(1,1)
nnoremap <silent> <Plug>(easymotion-iskeyword-b) :call EasyMotion#WBK(0,1)
snoremap <silent> <Plug>(easymotion-iskeyword-b) :call EasyMotion#WBK(0,1)
onoremap <silent> <Plug>(easymotion-iskeyword-b) :call EasyMotion#WBK(0,1)
xnoremap <silent> <Plug>(easymotion-iskeyword-bd-w) :call EasyMotion#WBK(1,2)
nnoremap <silent> <Plug>(easymotion-iskeyword-bd-w) :call EasyMotion#WBK(0,2)
snoremap <silent> <Plug>(easymotion-iskeyword-bd-w) :call EasyMotion#WBK(0,2)
onoremap <silent> <Plug>(easymotion-iskeyword-bd-w) :call EasyMotion#WBK(0,2)
xnoremap <silent> <Plug>(easymotion-W) :call EasyMotion#WBW(1,0)
nnoremap <silent> <Plug>(easymotion-W) :call EasyMotion#WBW(0,0)
snoremap <silent> <Plug>(easymotion-W) :call EasyMotion#WBW(0,0)
onoremap <silent> <Plug>(easymotion-W) :call EasyMotion#WBW(0,0)
xnoremap <silent> <Plug>(easymotion-bd-w) :call EasyMotion#WB(1,2)
nnoremap <silent> <Plug>(easymotion-bd-w) :call EasyMotion#WB(0,2)
snoremap <silent> <Plug>(easymotion-bd-w) :call EasyMotion#WB(0,2)
onoremap <silent> <Plug>(easymotion-bd-w) :call EasyMotion#WB(0,2)
xnoremap <silent> <Plug>(easymotion-iskeyword-bd-e) :call EasyMotion#EK(1,2)
nnoremap <silent> <Plug>(easymotion-iskeyword-bd-e) :call EasyMotion#EK(0,2)
snoremap <silent> <Plug>(easymotion-iskeyword-bd-e) :call EasyMotion#EK(0,2)
onoremap <silent> <Plug>(easymotion-iskeyword-bd-e) :call EasyMotion#EK(0,2)
xnoremap <silent> <Plug>(easymotion-ge) :call EasyMotion#E(1,1)
nnoremap <silent> <Plug>(easymotion-ge) :call EasyMotion#E(0,1)
snoremap <silent> <Plug>(easymotion-ge) :call EasyMotion#E(0,1)
onoremap <silent> <Plug>(easymotion-ge) :call EasyMotion#E(0,1)
xnoremap <silent> <Plug>(easymotion-E) :call EasyMotion#EW(1,0)
nnoremap <silent> <Plug>(easymotion-E) :call EasyMotion#EW(0,0)
snoremap <silent> <Plug>(easymotion-E) :call EasyMotion#EW(0,0)
onoremap <silent> <Plug>(easymotion-E) :call EasyMotion#EW(0,0)
xnoremap <silent> <Plug>(easymotion-bd-e) :call EasyMotion#E(1,2)
nnoremap <silent> <Plug>(easymotion-bd-e) :call EasyMotion#E(0,2)
snoremap <silent> <Plug>(easymotion-bd-e) :call EasyMotion#E(0,2)
onoremap <silent> <Plug>(easymotion-bd-e) :call EasyMotion#E(0,2)
xnoremap <silent> <Plug>(easymotion-B) :call EasyMotion#WBW(1,1)
nnoremap <silent> <Plug>(easymotion-B) :call EasyMotion#WBW(0,1)
snoremap <silent> <Plug>(easymotion-B) :call EasyMotion#WBW(0,1)
onoremap <silent> <Plug>(easymotion-B) :call EasyMotion#WBW(0,1)
xnoremap <silent> <Plug>(easymotion-Tln) :call EasyMotion#TL(-1,1,1)
nnoremap <silent> <Plug>(easymotion-Tln) :call EasyMotion#TL(-1,0,1)
snoremap <silent> <Plug>(easymotion-Tln) :call EasyMotion#TL(-1,0,1)
onoremap <silent> <Plug>(easymotion-Tln) :call EasyMotion#TL(-1,0,1)
xnoremap <silent> <Plug>(easymotion-t2) :call EasyMotion#T(2,1,0)
nnoremap <silent> <Plug>(easymotion-t2) :call EasyMotion#T(2,0,0)
snoremap <silent> <Plug>(easymotion-t2) :call EasyMotion#T(2,0,0)
onoremap <silent> <Plug>(easymotion-t2) :call EasyMotion#T(2,0,0)
xnoremap <silent> <Plug>(easymotion-t) :call EasyMotion#T(1,1,0)
nnoremap <silent> <Plug>(easymotion-t) :call EasyMotion#T(1,0,0)
snoremap <silent> <Plug>(easymotion-t) :call EasyMotion#T(1,0,0)
onoremap <silent> <Plug>(easymotion-t) :call EasyMotion#T(1,0,0)
xnoremap <silent> <Plug>(easymotion-s) :call EasyMotion#S(1,1,2)
nnoremap <silent> <Plug>(easymotion-s) :call EasyMotion#S(1,0,2)
snoremap <silent> <Plug>(easymotion-s) :call EasyMotion#S(1,0,2)
onoremap <silent> <Plug>(easymotion-s) :call EasyMotion#S(1,0,2)
xnoremap <silent> <Plug>(easymotion-tn) :call EasyMotion#T(-1,1,0)
nnoremap <silent> <Plug>(easymotion-tn) :call EasyMotion#T(-1,0,0)
snoremap <silent> <Plug>(easymotion-tn) :call EasyMotion#T(-1,0,0)
onoremap <silent> <Plug>(easymotion-tn) :call EasyMotion#T(-1,0,0)
xnoremap <silent> <Plug>(easymotion-bd-t2) :call EasyMotion#T(2,1,2)
nnoremap <silent> <Plug>(easymotion-bd-t2) :call EasyMotion#T(2,0,2)
snoremap <silent> <Plug>(easymotion-bd-t2) :call EasyMotion#T(2,0,2)
onoremap <silent> <Plug>(easymotion-bd-t2) :call EasyMotion#T(2,0,2)
xnoremap <silent> <Plug>(easymotion-tl) :call EasyMotion#TL(1,1,0)
nnoremap <silent> <Plug>(easymotion-tl) :call EasyMotion#TL(1,0,0)
snoremap <silent> <Plug>(easymotion-tl) :call EasyMotion#TL(1,0,0)
onoremap <silent> <Plug>(easymotion-tl) :call EasyMotion#TL(1,0,0)
xnoremap <silent> <Plug>(easymotion-bd-tn) :call EasyMotion#T(-1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-tn) :call EasyMotion#T(-1,0,2)
snoremap <silent> <Plug>(easymotion-bd-tn) :call EasyMotion#T(-1,0,2)
onoremap <silent> <Plug>(easymotion-bd-tn) :call EasyMotion#T(-1,0,2)
xnoremap <silent> <Plug>(easymotion-fn) :call EasyMotion#S(-1,1,0)
nnoremap <silent> <Plug>(easymotion-fn) :call EasyMotion#S(-1,0,0)
snoremap <silent> <Plug>(easymotion-fn) :call EasyMotion#S(-1,0,0)
onoremap <silent> <Plug>(easymotion-fn) :call EasyMotion#S(-1,0,0)
xnoremap <silent> <Plug>(easymotion-bd-tl) :call EasyMotion#TL(1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-tl) :call EasyMotion#TL(1,0,2)
snoremap <silent> <Plug>(easymotion-bd-tl) :call EasyMotion#TL(1,0,2)
onoremap <silent> <Plug>(easymotion-bd-tl) :call EasyMotion#TL(1,0,2)
xnoremap <silent> <Plug>(easymotion-fl) :call EasyMotion#SL(1,1,0)
nnoremap <silent> <Plug>(easymotion-fl) :call EasyMotion#SL(1,0,0)
snoremap <silent> <Plug>(easymotion-fl) :call EasyMotion#SL(1,0,0)
onoremap <silent> <Plug>(easymotion-fl) :call EasyMotion#SL(1,0,0)
xnoremap <silent> <Plug>(easymotion-bd-tl2) :call EasyMotion#TL(2,1,2)
nnoremap <silent> <Plug>(easymotion-bd-tl2) :call EasyMotion#TL(2,0,2)
snoremap <silent> <Plug>(easymotion-bd-tl2) :call EasyMotion#TL(2,0,2)
onoremap <silent> <Plug>(easymotion-bd-tl2) :call EasyMotion#TL(2,0,2)
xnoremap <silent> <Plug>(easymotion-bd-fn) :call EasyMotion#S(-1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-fn) :call EasyMotion#S(-1,0,2)
snoremap <silent> <Plug>(easymotion-bd-fn) :call EasyMotion#S(-1,0,2)
onoremap <silent> <Plug>(easymotion-bd-fn) :call EasyMotion#S(-1,0,2)
xnoremap <silent> <Plug>(easymotion-f) :call EasyMotion#S(1,1,0)
nnoremap <silent> <Plug>(easymotion-f) :call EasyMotion#S(1,0,0)
snoremap <silent> <Plug>(easymotion-f) :call EasyMotion#S(1,0,0)
onoremap <silent> <Plug>(easymotion-f) :call EasyMotion#S(1,0,0)
xnoremap <silent> <Plug>(easymotion-bd-fl) :call EasyMotion#SL(1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-fl) :call EasyMotion#SL(1,0,2)
snoremap <silent> <Plug>(easymotion-bd-fl) :call EasyMotion#SL(1,0,2)
onoremap <silent> <Plug>(easymotion-bd-fl) :call EasyMotion#SL(1,0,2)
xnoremap <silent> <Plug>(easymotion-Fl2) :call EasyMotion#SL(2,1,1)
nnoremap <silent> <Plug>(easymotion-Fl2) :call EasyMotion#SL(2,0,1)
snoremap <silent> <Plug>(easymotion-Fl2) :call EasyMotion#SL(2,0,1)
onoremap <silent> <Plug>(easymotion-Fl2) :call EasyMotion#SL(2,0,1)
xnoremap <silent> <Plug>(easymotion-tl2) :call EasyMotion#TL(2,1,0)
nnoremap <silent> <Plug>(easymotion-tl2) :call EasyMotion#TL(2,0,0)
snoremap <silent> <Plug>(easymotion-tl2) :call EasyMotion#TL(2,0,0)
onoremap <silent> <Plug>(easymotion-tl2) :call EasyMotion#TL(2,0,0)
xnoremap <silent> <Plug>(easymotion-f2) :call EasyMotion#S(2,1,0)
nnoremap <silent> <Plug>(easymotion-f2) :call EasyMotion#S(2,0,0)
snoremap <silent> <Plug>(easymotion-f2) :call EasyMotion#S(2,0,0)
onoremap <silent> <Plug>(easymotion-f2) :call EasyMotion#S(2,0,0)
xnoremap <silent> <Plug>(easymotion-Fln) :call EasyMotion#SL(-1,1,1)
nnoremap <silent> <Plug>(easymotion-Fln) :call EasyMotion#SL(-1,0,1)
snoremap <silent> <Plug>(easymotion-Fln) :call EasyMotion#SL(-1,0,1)
onoremap <silent> <Plug>(easymotion-Fln) :call EasyMotion#SL(-1,0,1)
xnoremap <silent> <Plug>(easymotion-sln) :call EasyMotion#SL(-1,1,2)
nnoremap <silent> <Plug>(easymotion-sln) :call EasyMotion#SL(-1,0,2)
snoremap <silent> <Plug>(easymotion-sln) :call EasyMotion#SL(-1,0,2)
onoremap <silent> <Plug>(easymotion-sln) :call EasyMotion#SL(-1,0,2)
xnoremap <silent> <Plug>(easymotion-tln) :call EasyMotion#TL(-1,1,0)
nnoremap <silent> <Plug>(easymotion-tln) :call EasyMotion#TL(-1,0,0)
snoremap <silent> <Plug>(easymotion-tln) :call EasyMotion#TL(-1,0,0)
onoremap <silent> <Plug>(easymotion-tln) :call EasyMotion#TL(-1,0,0)
xnoremap <silent> <Plug>(easymotion-fl2) :call EasyMotion#SL(2,1,0)
nnoremap <silent> <Plug>(easymotion-fl2) :call EasyMotion#SL(2,0,0)
snoremap <silent> <Plug>(easymotion-fl2) :call EasyMotion#SL(2,0,0)
onoremap <silent> <Plug>(easymotion-fl2) :call EasyMotion#SL(2,0,0)
xnoremap <silent> <Plug>(easymotion-bd-fl2) :call EasyMotion#SL(2,1,2)
nnoremap <silent> <Plug>(easymotion-bd-fl2) :call EasyMotion#SL(2,0,2)
snoremap <silent> <Plug>(easymotion-bd-fl2) :call EasyMotion#SL(2,0,2)
onoremap <silent> <Plug>(easymotion-bd-fl2) :call EasyMotion#SL(2,0,2)
xnoremap <silent> <Plug>(easymotion-T2) :call EasyMotion#T(2,1,1)
nnoremap <silent> <Plug>(easymotion-T2) :call EasyMotion#T(2,0,1)
snoremap <silent> <Plug>(easymotion-T2) :call EasyMotion#T(2,0,1)
onoremap <silent> <Plug>(easymotion-T2) :call EasyMotion#T(2,0,1)
xnoremap <silent> <Plug>(easymotion-bd-tln) :call EasyMotion#TL(-1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-tln) :call EasyMotion#TL(-1,0,2)
snoremap <silent> <Plug>(easymotion-bd-tln) :call EasyMotion#TL(-1,0,2)
onoremap <silent> <Plug>(easymotion-bd-tln) :call EasyMotion#TL(-1,0,2)
xnoremap <silent> <Plug>(easymotion-T) :call EasyMotion#T(1,1,1)
nnoremap <silent> <Plug>(easymotion-T) :call EasyMotion#T(1,0,1)
snoremap <silent> <Plug>(easymotion-T) :call EasyMotion#T(1,0,1)
onoremap <silent> <Plug>(easymotion-T) :call EasyMotion#T(1,0,1)
xnoremap <silent> <Plug>(easymotion-bd-t) :call EasyMotion#T(1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-t) :call EasyMotion#T(1,0,2)
snoremap <silent> <Plug>(easymotion-bd-t) :call EasyMotion#T(1,0,2)
onoremap <silent> <Plug>(easymotion-bd-t) :call EasyMotion#T(1,0,2)
xnoremap <silent> <Plug>(easymotion-Tn) :call EasyMotion#T(-1,1,1)
nnoremap <silent> <Plug>(easymotion-Tn) :call EasyMotion#T(-1,0,1)
snoremap <silent> <Plug>(easymotion-Tn) :call EasyMotion#T(-1,0,1)
onoremap <silent> <Plug>(easymotion-Tn) :call EasyMotion#T(-1,0,1)
xnoremap <silent> <Plug>(easymotion-s2) :call EasyMotion#S(2,1,2)
nnoremap <silent> <Plug>(easymotion-s2) :call EasyMotion#S(2,0,2)
snoremap <silent> <Plug>(easymotion-s2) :call EasyMotion#S(2,0,2)
onoremap <silent> <Plug>(easymotion-s2) :call EasyMotion#S(2,0,2)
xnoremap <silent> <Plug>(easymotion-Tl) :call EasyMotion#TL(1,1,1)
nnoremap <silent> <Plug>(easymotion-Tl) :call EasyMotion#TL(1,0,1)
snoremap <silent> <Plug>(easymotion-Tl) :call EasyMotion#TL(1,0,1)
onoremap <silent> <Plug>(easymotion-Tl) :call EasyMotion#TL(1,0,1)
xnoremap <silent> <Plug>(easymotion-sn) :call EasyMotion#S(-1,1,2)
nnoremap <silent> <Plug>(easymotion-sn) :call EasyMotion#S(-1,0,2)
snoremap <silent> <Plug>(easymotion-sn) :call EasyMotion#S(-1,0,2)
onoremap <silent> <Plug>(easymotion-sn) :call EasyMotion#S(-1,0,2)
xnoremap <silent> <Plug>(easymotion-Fn) :call EasyMotion#S(-1,1,1)
nnoremap <silent> <Plug>(easymotion-Fn) :call EasyMotion#S(-1,0,1)
snoremap <silent> <Plug>(easymotion-Fn) :call EasyMotion#S(-1,0,1)
onoremap <silent> <Plug>(easymotion-Fn) :call EasyMotion#S(-1,0,1)
xnoremap <silent> <Plug>(easymotion-sl) :call EasyMotion#SL(1,1,2)
nnoremap <silent> <Plug>(easymotion-sl) :call EasyMotion#SL(1,0,2)
snoremap <silent> <Plug>(easymotion-sl) :call EasyMotion#SL(1,0,2)
onoremap <silent> <Plug>(easymotion-sl) :call EasyMotion#SL(1,0,2)
xnoremap <silent> <Plug>(easymotion-Fl) :call EasyMotion#SL(1,1,1)
nnoremap <silent> <Plug>(easymotion-Fl) :call EasyMotion#SL(1,0,1)
snoremap <silent> <Plug>(easymotion-Fl) :call EasyMotion#SL(1,0,1)
onoremap <silent> <Plug>(easymotion-Fl) :call EasyMotion#SL(1,0,1)
xnoremap <silent> <Plug>(easymotion-sl2) :call EasyMotion#SL(2,1,2)
nnoremap <silent> <Plug>(easymotion-sl2) :call EasyMotion#SL(2,0,2)
snoremap <silent> <Plug>(easymotion-sl2) :call EasyMotion#SL(2,0,2)
onoremap <silent> <Plug>(easymotion-sl2) :call EasyMotion#SL(2,0,2)
xnoremap <silent> <Plug>(easymotion-bd-fln) :call EasyMotion#SL(-1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-fln) :call EasyMotion#SL(-1,0,2)
snoremap <silent> <Plug>(easymotion-bd-fln) :call EasyMotion#SL(-1,0,2)
onoremap <silent> <Plug>(easymotion-bd-fln) :call EasyMotion#SL(-1,0,2)
xnoremap <silent> <Plug>(easymotion-F) :call EasyMotion#S(1,1,1)
nnoremap <silent> <Plug>(easymotion-F) :call EasyMotion#S(1,0,1)
snoremap <silent> <Plug>(easymotion-F) :call EasyMotion#S(1,0,1)
onoremap <silent> <Plug>(easymotion-F) :call EasyMotion#S(1,0,1)
xnoremap <silent> <Plug>(easymotion-bd-f) :call EasyMotion#S(1,1,2)
nnoremap <silent> <Plug>(easymotion-bd-f) :call EasyMotion#S(1,0,2)
snoremap <silent> <Plug>(easymotion-bd-f) :call EasyMotion#S(1,0,2)
onoremap <silent> <Plug>(easymotion-bd-f) :call EasyMotion#S(1,0,2)
xnoremap <silent> <Plug>(easymotion-F2) :call EasyMotion#S(2,1,1)
nnoremap <silent> <Plug>(easymotion-F2) :call EasyMotion#S(2,0,1)
snoremap <silent> <Plug>(easymotion-F2) :call EasyMotion#S(2,0,1)
onoremap <silent> <Plug>(easymotion-F2) :call EasyMotion#S(2,0,1)
xnoremap <silent> <Plug>(easymotion-bd-f2) :call EasyMotion#S(2,1,2)
nnoremap <silent> <Plug>(easymotion-bd-f2) :call EasyMotion#S(2,0,2)
snoremap <silent> <Plug>(easymotion-bd-f2) :call EasyMotion#S(2,0,2)
onoremap <silent> <Plug>(easymotion-bd-f2) :call EasyMotion#S(2,0,2)
xnoremap <silent> <Plug>(easymotion-Tl2) :call EasyMotion#TL(2,1,1)
nnoremap <silent> <Plug>(easymotion-Tl2) :call EasyMotion#TL(2,0,1)
snoremap <silent> <Plug>(easymotion-Tl2) :call EasyMotion#TL(2,0,1)
onoremap <silent> <Plug>(easymotion-Tl2) :call EasyMotion#TL(2,0,1)
xnoremap <silent> <Plug>(easymotion-fln) :call EasyMotion#SL(-1,1,0)
nnoremap <silent> <Plug>(easymotion-fln) :call EasyMotion#SL(-1,0,0)
snoremap <silent> <Plug>(easymotion-fln) :call EasyMotion#SL(-1,0,0)
onoremap <silent> <Plug>(easymotion-fln) :call EasyMotion#SL(-1,0,0)
nmap <silent> <F8> <Plug>ToggleDiffCharCurrentLine
map <F2> :set spelllang=fr spell
map <F3> z=
map <F6> zg
map <F4> [s
map <F5> ]s
noremap <F10> :%s/\s\+$//
noremap <F11> :s/  / /g
noremap <F12> vipJ
noremap <silent> <expr> <Home> col('.') == match(getline('.'),'\s')+1 ? '0' : '^'
nmap <S-Tab> ^i<BS>
vmap <S-Tab> <gv
map <S-Insert> <MiddleMouse>
imap S <Plug>ISurround
imap s <Plug>Isurround
imap  <Plug>Isurround
inoremap # X<BS>#
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set autowrite
set background=dark
set backspace=2
set diffexpr=DiffCharExpr(200,\ 1)
set errorformat=%f:%l:%m
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set formatoptions=tcqw
set guioptions=agimrLtT
set helplang=fr
set history=100
set incsearch
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,:
set iskeyword=@,48-57,_,192-255,:
set laststatus=2
set makeprg=perl\ -c\ %\ $*
set nomodeline
set mouse=a
set pastetoggle=<F11>
set printoptions=paper:a4
set ruler
set runtimepath=~/.vim,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim74,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,~/.vim/after
set shiftwidth=4
set showcmd
set showmatch
set showtabline=2
set smartindent
set softtabstop=4
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set tabline=%!airline#extensions#tabline#get()
set tabstop=4
set termencoding=utf-8
set textwidth=80
set undolevels=150
set window=53
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1191 Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/Taxonomy.pm
badd +805 Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/SeqId.pm
badd +72 Documents/M2/pperl/scripts/process-OGs.pl
badd +280 Documents/doct/strain-solution/bio-must-core/t/seq_id.t
badd +8 Documents/doct/strain-solution/bio-must-core/test/query-strains.lis
badd +1 Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/__Tagbar__
badd +1 Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/session
silent! argdel *
edit Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/SeqId.pm
set splitbelow splitright
wincmd _ | wincmd |
vsplit
wincmd _ | wincmd |
vsplit
wincmd _ | wincmd |
vsplit
3wincmd h
wincmd w
wincmd w
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe 'vert 1resize ' . ((&columns * 31 + 107) / 215)
exe 'vert 2resize ' . ((&columns * 71 + 107) / 215)
exe 'vert 3resize ' . ((&columns * 70 + 107) / 215)
exe 'vert 4resize ' . ((&columns * 40 + 107) / 215)
argglobal
enew
file NERD_tree_2
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=hide
setlocal nobuflisted
setlocal buftype=nofile
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'nerdtree'
setlocal filetype=nerdtree
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcqw
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal nomodifiable
setlocal nrformats=octal,hex
set number
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal smartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=%!airline#statusline(1)
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'nerdtree'
setlocal syntax=nerdtree
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal winfixwidth
setlocal nowrap
setlocal wrapmargin=0
lcd ~/Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core
wincmd w
argglobal
let s:cpo_save=&cpo
set cpo&vim
inoremap <buffer> <silent> <F9> :call Perl_Debugger()
inoremap <buffer> <silent> <S-F1> :call Perl_perldoc()
inoremap <buffer> <S-F9> :PerlScriptArguments 
inoremap <buffer> <silent> <C-F9> :call Perl_Run()
inoremap <buffer> <silent> <M-F9> :call Perl_SyntaxCheck()
nnoremap <buffer> <silent> <NL> i=Perl_JumpCtrlJ()
vnoremap <buffer> <silent> \rh :call Perl_Hardcopy("v")
vnoremap <buffer> <silent> \ry :call Perl_Perltidy("v")
vnoremap <buffer> <silent> \ft :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"File Tests")
nnoremap <buffer> <silent> \ft :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"File Tests")
vnoremap <buffer> <silent> \nxs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.regex")
nnoremap <buffer> <silent> \nxs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.regex")
vnoremap <buffer> <silent> \njt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.jump tags")
nnoremap <buffer> <silent> \njt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.jump tags")
vnoremap <buffer> <silent> \pm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.markup sequences","v")
nnoremap <buffer> <silent> \pm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.markup sequences")
vnoremap <buffer> <silent> \pi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.item")
nnoremap <buffer> <silent> \pi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.item")
vnoremap <buffer> <silent> \pob :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.over, back","v")
nnoremap <buffer> <silent> \pob :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.over, back")
vnoremap <buffer> <silent> \ph3 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head3")
nnoremap <buffer> <silent> \ph3 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head3")
vnoremap <buffer> <silent> \ph2 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head2")
nnoremap <buffer> <silent> \ph2 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head2")
vnoremap <buffer> <silent> \ph1 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head1")
nnoremap <buffer> <silent> \ph1 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head1")
vnoremap <buffer> <silent> \pbt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin text, end","v")
nnoremap <buffer> <silent> \pbt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin text, end")
vnoremap <buffer> <silent> \pbm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin man, end","v")
nnoremap <buffer> <silent> \pbm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin man, end")
vnoremap <buffer> <silent> \pbh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin html, end","v")
nnoremap <buffer> <silent> \pbh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin html, end")
vnoremap <buffer> <silent> \pfc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.for, cut","v")
nnoremap <buffer> <silent> \pfc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.for, cut")
vnoremap <buffer> <silent> \ppc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.pod, cut","v")
nnoremap <buffer> <silent> \ppc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.pod, cut")
vnoremap <buffer> <silent> \xms :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.metasymbols")
nnoremap <buffer> <silent> \xms :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.metasymbols")
vnoremap <buffer> <silent> \xex :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.extended Regex","v")
nnoremap <buffer> <silent> \xex :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.extended Regex")
vnoremap <buffer> <silent> \xup :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.Unicode Property")
nnoremap <buffer> <silent> \xup :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.Unicode Property")
vnoremap <buffer> <silent> \xpc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.POSIX classes")
nnoremap <buffer> <silent> \xpc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.POSIX classes")
vnoremap <buffer> <silent> \vue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.use English")
nnoremap <buffer> <silent> \vue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.use English")
vnoremap <buffer> <silent> \vs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.POSIX signals")
nnoremap <buffer> <silent> \vs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.POSIX signals")
vnoremap <buffer> <silent> \vr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.regexp")
nnoremap <buffer> <silent> \vr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.regexp")
vnoremap <buffer> <silent> \vio :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IO")
nnoremap <buffer> <silent> \vio :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IO")
vnoremap <buffer> <silent> \vid :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IDs")
nnoremap <buffer> <silent> \vid :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IDs")
vnoremap <buffer> <silent> \vf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.filehandle")
nnoremap <buffer> <silent> \vf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.filehandle")
vnoremap <buffer> <silent> \ve :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.errors")
nnoremap <buffer> <silent> \ve :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.errors")
vnoremap <buffer> <silent> \vb :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.basics")
nnoremap <buffer> <silent> \vb :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.basics")
vnoremap <buffer> <silent> \ise :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDERR")
nnoremap <buffer> <silent> \ise :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDERR")
vnoremap <buffer> <silent> \iso :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDOUT")
nnoremap <buffer> <silent> \iso :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDOUT")
vnoremap <buffer> <silent> \isi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDIN")
nnoremap <buffer> <silent> \isi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDIN")
vnoremap <buffer> <silent> \ipi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open pipe","v")
nnoremap <buffer> <silent> \ipi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open pipe")
vnoremap <buffer> <silent> \io :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open output file","v")
nnoremap <buffer> <silent> \io :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open output file")
vnoremap <buffer> <silent> \ii :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open input file","v")
nnoremap <buffer> <silent> \ii :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open input file")
vnoremap <buffer> <silent> \ip :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.print")
nnoremap <buffer> <silent> \ip :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.print")
vnoremap <buffer> <silent> \isu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.subroutine","v")
nnoremap <buffer> <silent> \isu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.subroutine")
vnoremap <buffer> <silent> \it :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.translate")
nnoremap <buffer> <silent> \it :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.translate")
vnoremap <buffer> <silent> \is :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.substitute")
nnoremap <buffer> <silent> \is :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.substitute")
vnoremap <buffer> <silent> \im :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.match")
nnoremap <buffer> <silent> \im :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.match")
vnoremap <buffer> <silent> \ir :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.regex")
nnoremap <buffer> <silent> \ir :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.regex")
vnoremap <buffer> <silent> \iha :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash+assignment")
nnoremap <buffer> <silent> \iha :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash+assignment")
vnoremap <buffer> <silent> \ih :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash")
nnoremap <buffer> <silent> \ih :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash")
vnoremap <buffer> <silent> \iaa :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array+assignment")
nnoremap <buffer> <silent> \iaa :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array+assignment")
vnoremap <buffer> <silent> \ia :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array")
nnoremap <buffer> <silent> \ia :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array")
vnoremap <buffer> <silent> \idd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar_list")
nnoremap <buffer> <silent> \idd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar_list")
vnoremap <buffer> <silent> \ida :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar+assignment")
nnoremap <buffer> <silent> \ida :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar+assignment")
vnoremap <buffer> <silent> \id :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar")
nnoremap <buffer> <silent> \id :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar")
vnoremap <buffer> <silent> \swh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.when")
nnoremap <buffer> <silent> \swh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.when")
vnoremap <buffer> <silent> \sg :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.given")
nnoremap <buffer> <silent> \sg :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.given")
vnoremap <buffer> <silent> \sw :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.while","v")
nnoremap <buffer> <silent> \sw :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.while")
vnoremap <buffer> <silent> \st :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.until","v")
nnoremap <buffer> <silent> \st :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.until")
vnoremap <buffer> <silent> \sue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless-else","v")
nnoremap <buffer> <silent> \sue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless-else")
vnoremap <buffer> <silent> \su :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless","v")
nnoremap <buffer> <silent> \su :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless")
vnoremap <buffer> <silent> \sie :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if-else","v")
nnoremap <buffer> <silent> \sie :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if-else")
vnoremap <buffer> <silent> \sei :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.elsif","v")
nnoremap <buffer> <silent> \sei :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.elsif")
vnoremap <buffer> <silent> \se :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.else","v")
nnoremap <buffer> <silent> \se :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.else")
vnoremap <buffer> <silent> \si :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if","v")
nnoremap <buffer> <silent> \si :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if")
vnoremap <buffer> <silent> \sfe :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.foreach","v")
nnoremap <buffer> <silent> \sfe :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.foreach")
vnoremap <buffer> <silent> \sf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.for","v")
nnoremap <buffer> <silent> \sf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.for")
vnoremap <buffer> <silent> \sd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.do-while","v")
nnoremap <buffer> <silent> \sd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.do-while")
vnoremap <buffer> <silent> \cma :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.macros")
nnoremap <buffer> <silent> \cma :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.macros")
vnoremap <buffer> <silent> \ck :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.keyword comments")
nnoremap <buffer> <silent> \ck :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.keyword comments")
vnoremap <buffer> <silent> \ct :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date+time")
nnoremap <buffer> <silent> \ct :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date+time")
vnoremap <buffer> <silent> \cd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date")
nnoremap <buffer> <silent> \cd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date")
vnoremap <buffer> <silent> \chpo :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pod")
nnoremap <buffer> <silent> \chpo :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pod")
vnoremap <buffer> <silent> \cht :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description t")
nnoremap <buffer> <silent> \cht :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description t")
vnoremap <buffer> <silent> \chpm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pm")
nnoremap <buffer> <silent> \chpm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pm")
vnoremap <buffer> <silent> \chpl :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pl")
nnoremap <buffer> <silent> \chpl :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pl")
vnoremap <buffer> <silent> \cme :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.method")
nnoremap <buffer> <silent> \cme :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.method")
vnoremap <buffer> <silent> \cfu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.function")
nnoremap <buffer> <silent> \cfu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.function")
vnoremap <buffer> <silent> \cfr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.frame")
nnoremap <buffer> <silent> \cfr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.frame")
noremap <buffer> <silent> \rpco :call Perl_PerlcriticOptionsInput()
noremap <buffer> <silent> \rpcv :call Perl_PerlcriticVerbosityInput()
noremap <buffer> <silent> \rpcs :call Perl_PerlcriticSeverityInput()
noremap <buffer> <silent> \ro :call Perl_Toggle_Gvim_Xterm()
noremap <buffer> <silent> \rx :call Perl_XtermSize()
noremap <buffer> <silent> \rk :call Perl_Settings()
nnoremap <buffer> <silent> \rh :call Perl_Hardcopy("n")
onoremap <buffer> <silent> \rh :call Perl_Hardcopy("n")
noremap <buffer> <silent> \rt :call Perl_SaveWithTimestamp()
noremap <buffer> <silent> \rpc :call Perl_Perlcritic()
nnoremap <buffer> <silent> \ry :call Perl_Perltidy("n")
onoremap <buffer> <silent> \ry :call Perl_Perltidy("n")
noremap <buffer> <silent> \rg :call Perl_perldoc_generate_module_list()
noremap <buffer> <silent> \ri :call Perl_perldoc_show_module_list()
noremap <buffer> <silent> \re :call Perl_MakeScriptExecutable()
noremap <buffer> <silent> \rd :call Perl_Debugger()
noremap <buffer> \rw :PerlSwitches 
noremap <buffer> \ra :PerlScriptArguments 
noremap <buffer> <silent> \rs :call Perl_SyntaxCheck()
noremap <buffer> <silent> \rr :call Perl_Run()
nnoremap <buffer> <silent> \rpnh :call perlsupportprofiling#Perl_NYTprofReadHtml()
nnoremap <buffer> <silent> \rpns :call perlsupportprofiling#Perl_NYTProfSortInput()
nnoremap <buffer> <silent> \rpnc :call perlsupportprofiling#Perl_NYTprofReadCSV("read","line")
nnoremap <buffer> <silent> \rpn :call perlsupportprofiling#Perl_NYTprof()
nnoremap <buffer> <silent> \rpfs :call perlsupportprofiling#Perl_FastProfSortInput()
nnoremap <buffer> <silent> \rpf :call perlsupportprofiling#Perl_Fastprof()
nnoremap <buffer> <silent> \rpss :call perlsupportprofiling#Perl_SmallProfSortInput()
nnoremap <buffer> <silent> \rps :call perlsupportprofiling#Perl_Smallprof()
nnoremap <buffer> <silent> \podt :call Perl_POD('text')
nnoremap <buffer> <silent> \podm :call Perl_POD('man')
nnoremap <buffer> <silent> \podh :call Perl_POD('html')
nnoremap <buffer> <silent> \pod :call Perl_PodCheck()
vnoremap <buffer> <silent> \xe :call perlsupportregex#Perl_RegexExplain( "v" )
nnoremap <buffer> <silent> \xe :call perlsupportregex#Perl_RegexExplain( "n" )
nnoremap <buffer> <silent> \xmm :call perlsupportregex#Perl_RegexMatchSeveral( )
nnoremap <buffer> <silent> \xm :call perlsupportregex#Perl_RegexVisualize( )
vnoremap <buffer> <silent> \xf :call perlsupportregex#Perl_RegexPickFlag( "v" )'>j
vnoremap <buffer> <silent> \xs :call perlsupportregex#Perl_RegexPick( "String", "v" )'>j
vnoremap <buffer> <silent> \xr :call perlsupportregex#Perl_RegexPick( "Regexp", "v" )'>j
nnoremap <buffer> <silent> \xf :call perlsupportregex#Perl_RegexPickFlag( "n" )
nnoremap <buffer> <silent> \xs :call perlsupportregex#Perl_RegexPick( "String", "n" )j
nnoremap <buffer> <silent> \xr :call perlsupportregex#Perl_RegexPick( "Regexp", "n" )j
nnoremap <buffer> <silent> \nts :call mmtemplates#core#ChooseStyle(g:Perl_Templates,"!pick")
nnoremap <buffer> <silent> \ntr :call mmtemplates#core#ReadTemplates(g:Perl_Templates,"reload","all")
nnoremap <buffer> <silent> \ntl :call mmtemplates#core#EditTemplateFiles(g:Perl_Templates,-1)
nnoremap <buffer> <silent> \nv :call Perl_CodeSnippet("view")
nnoremap <buffer> <silent> \ne :call Perl_CodeSnippet("edit")
vnoremap <buffer> <silent> \nw :call Perl_CodeSnippet("writemarked")
nnoremap <buffer> <silent> \nw :call Perl_CodeSnippet("write")
nnoremap <buffer> <silent> \nr :call Perl_CodeSnippet("read")
nnoremap <buffer> <silent> \cub :call Perl_UncommentBlock()
vnoremap <buffer> <silent> \cb :call Perl_CommentBlock("v")
nnoremap <buffer> <silent> \cb :call Perl_CommentBlock("a")
vnoremap <buffer> <silent> \cc :call Perl_CommentToggle()j
nnoremap <buffer> <silent> \cc :call Perl_CommentToggle()j
nnoremap <buffer> <silent> \cs :call Perl_GetLineEndCommCol()
vnoremap <buffer> <silent> \cj :call Perl_AlignLineEndComm()
nnoremap <buffer> <silent> \cj :call Perl_AlignLineEndComm()
noremap <buffer> <silent> \cl :call Perl_EndOfLineComment()
noremap <buffer> <silent> \hp :call Perl_HelpPerlsupport()
noremap <buffer> <silent> \h :call Perl_perldoc()
noremap <buffer> \rcm :MakeFile 
noremap <buffer> \rma :MakeCmdlineArgs 
noremap <buffer> <silent> \rmc :Make clean
noremap <buffer> <silent> \rm :Make
vnoremap <buffer> { s{}kp=iB
noremap <buffer> <silent> <F9> :call Perl_Debugger()
noremap <buffer> <silent> <S-F1> :call Perl_perldoc()
noremap <buffer> <S-F9> :PerlScriptArguments 
noremap <buffer> <silent> <C-F9> :call Perl_Run()
noremap <buffer> <silent> <M-F9> :call Perl_SyntaxCheck()
inoremap <buffer> <silent> <NL> =Perl_JumpCtrlJ()
inoremap <buffer> <silent> \ft :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"File Tests","i")
inoremap <buffer> <silent> \nxs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.regex","i")
inoremap <buffer> <silent> \njt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.jump tags","i")
inoremap <buffer> <silent> \pm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.markup sequences","i")
inoremap <buffer> <silent> \pi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.item","i")
inoremap <buffer> <silent> \pob :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.over, back","i")
inoremap <buffer> <silent> \ph3 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head3","i")
inoremap <buffer> <silent> \ph2 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head2","i")
inoremap <buffer> <silent> \ph1 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head1","i")
inoremap <buffer> <silent> \pbt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin text, end","i")
inoremap <buffer> <silent> \pbm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin man, end","i")
inoremap <buffer> <silent> \pbh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin html, end","i")
inoremap <buffer> <silent> \pfc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.for, cut","i")
inoremap <buffer> <silent> \ppc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.pod, cut","i")
inoremap <buffer> <silent> \xms :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.metasymbols","i")
inoremap <buffer> <silent> \xex :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.extended Regex","i")
inoremap <buffer> <silent> \xup :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.Unicode Property","i")
inoremap <buffer> <silent> \xpc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.POSIX classes","i")
inoremap <buffer> <silent> \vue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.use English","i")
inoremap <buffer> <silent> \vs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.POSIX signals","i")
inoremap <buffer> <silent> \vr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.regexp","i")
inoremap <buffer> <silent> \vio :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IO","i")
inoremap <buffer> <silent> \vid :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IDs","i")
inoremap <buffer> <silent> \vf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.filehandle","i")
inoremap <buffer> <silent> \ve :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.errors","i")
inoremap <buffer> <silent> \vb :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.basics","i")
inoremap <buffer> <silent> \ise :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDERR","i")
inoremap <buffer> <silent> \iso :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDOUT","i")
inoremap <buffer> <silent> \isi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDIN","i")
inoremap <buffer> <silent> \ipi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open pipe","i")
inoremap <buffer> <silent> \io :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open output file","i")
inoremap <buffer> <silent> \ii :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open input file","i")
inoremap <buffer> <silent> \ip :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.print","i")
inoremap <buffer> <silent> \isu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.subroutine","i")
inoremap <buffer> <silent> \it :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.translate","i")
inoremap <buffer> <silent> \is :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.substitute","i")
inoremap <buffer> <silent> \im :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.match","i")
inoremap <buffer> <silent> \ir :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.regex","i")
inoremap <buffer> <silent> \iha :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash+assignment","i")
inoremap <buffer> <silent> \ih :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash","i")
inoremap <buffer> <silent> \iaa :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array+assignment","i")
inoremap <buffer> <silent> \ia :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array","i")
inoremap <buffer> <silent> \idd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar_list","i")
inoremap <buffer> <silent> \ida :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar+assignment","i")
inoremap <buffer> <silent> \id :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar","i")
inoremap <buffer> <silent> \swh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.when","i")
inoremap <buffer> <silent> \sg :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.given","i")
inoremap <buffer> <silent> \sw :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.while","i")
inoremap <buffer> <silent> \st :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.until","i")
inoremap <buffer> <silent> \sue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless-else","i")
inoremap <buffer> <silent> \su :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless","i")
inoremap <buffer> <silent> \sie :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if-else","i")
inoremap <buffer> <silent> \sei :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.elsif","i")
inoremap <buffer> <silent> \se :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.else","i")
inoremap <buffer> <silent> \si :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if","i")
inoremap <buffer> <silent> \sfe :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.foreach","i")
inoremap <buffer> <silent> \sf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.for","i")
inoremap <buffer> <silent> \sd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.do-while","i")
inoremap <buffer> <silent> \cma :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.macros","i")
inoremap <buffer> <silent> \ck :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.keyword comments","i")
inoremap <buffer> <silent> \ct :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date+time","i")
inoremap <buffer> <silent> \cd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date","i")
inoremap <buffer> <silent> \chpo :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pod","i")
inoremap <buffer> <silent> \cht :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description t","i")
inoremap <buffer> <silent> \chpm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pm","i")
inoremap <buffer> <silent> \chpl :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pl","i")
inoremap <buffer> <silent> \cme :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.method","i")
inoremap <buffer> <silent> \cfu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.function","i")
inoremap <buffer> <silent> \cfr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.frame","i")
inoremap <buffer> <silent> \ro :call Perl_Toggle_Gvim_Xterm()
inoremap <buffer> <silent> \rx :call Perl_XtermSize()
inoremap <buffer> <silent> \rk :call Perl_Settings()
inoremap <buffer> <silent> \rh :call Perl_Hardcopy("n")
inoremap <buffer> <silent> \rt :call Perl_SaveWithTimestamp()
inoremap <buffer> <silent> \rpc :call Perl_Perlcritic()
inoremap <buffer> <silent> \ry :call Perl_Perltidy("n")
inoremap <buffer> <silent> \rg :call Perl_perldoc_generate_module_list()
inoremap <buffer> <silent> \ri :call Perl_perldoc_show_module_list()
inoremap <buffer> <silent> \re :call Perl_MakeScriptExecutable()
inoremap <buffer> \rw :PerlSwitches 
inoremap <buffer> \ra :PerlScriptArguments 
inoremap <buffer> <silent> \rs :call Perl_SyntaxCheck()
inoremap <buffer> <silent> \rr :call Perl_Run()
inoremap <buffer> <silent> \rpnh :call perlsupportprofiling#Perl_NYTprofReadHtml()
inoremap <buffer> <silent> \rpns :call perlsupportprofiling#Perl_NYTProfSortInput()
inoremap <buffer> <silent> \rpnc :call perlsupportprofiling#Perl_NYTprofReadCSV("read","line")
inoremap <buffer> <silent> \rpn :call perlsupportprofiling#Perl_NYTprof()
inoremap <buffer> <silent> \rpfs :call perlsupportprofiling#Perl_FastProfSortInput()
inoremap <buffer> <silent> \rpf :call perlsupportprofiling#Perl_Fastprof()
inoremap <buffer> <silent> \rpss :call perlsupportprofiling#Perl_SmallProfSortInput()
inoremap <buffer> <silent> \rps :call perlsupportprofiling#Perl_Smallprof()
inoremap <buffer> <silent> \podt :call Perl_POD('text')
inoremap <buffer> <silent> \podm :call Perl_POD('man')
inoremap <buffer> <silent> \podh :call Perl_POD('html')
inoremap <buffer> <silent> \pod :call Perl_PodCheck()
inoremap <buffer> <silent> \nts :call mmtemplates#core#ChooseStyle(g:Perl_Templates,"!pick")
inoremap <buffer> <silent> \ntr :call mmtemplates#core#ReadTemplates(g:Perl_Templates,"reload","all")
inoremap <buffer> <silent> \ntl :call mmtemplates#core#EditTemplateFiles(g:Perl_Templates,-1)
inoremap <buffer> <silent> \nv :call Perl_CodeSnippet("view")
inoremap <buffer> <silent> \ne :call Perl_CodeSnippet("edit")
inoremap <buffer> <silent> \nw :call Perl_CodeSnippet("write")
inoremap <buffer> <silent> \nr :call Perl_CodeSnippet("read")
inoremap <buffer> <silent> \cb :call Perl_CommentBlock("a")
inoremap <buffer> <silent> \cj :call Perl_AlignLineEndComm()
inoremap <buffer> <silent> \cl :call Perl_EndOfLineComment()
inoremap <buffer> <silent> \hp :call Perl_HelpPerlsupport()
inoremap <buffer> <silent> \h :call Perl_perldoc()
inoremap <buffer> \rcm :MakeFile 
inoremap <buffer> \rma :MakeCmdlineArgs 
inoremap <buffer> <silent> \rmc :Make clean
inoremap <buffer> <silent> \rm :Make
inoremap <buffer> { {}O
let &cpo=s:cpo_save
unlet s:cpo_save
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=~/.vim/perl-support/wordlists/perl.list
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=wcrqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=2
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,/etc/perl,/usr/local/lib/perl/5.18.2,/usr/local/share/perl/5.18.2,/usr/lib/perl5,/usr/share/perl5,/usr/lib/perl/5.18,/usr/share/perl/5.18,/usr/local/lib/site_perl,,
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal smartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=%!airline#statusline(2)
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 804 - ((25 * winheight(0) + 25) / 51)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
804
normal! 0
lcd ~/Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core
wincmd w
argglobal
edit ~/Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/Taxonomy.pm
let s:cpo_save=&cpo
set cpo&vim
inoremap <buffer> <silent> <F9> :call Perl_Debugger()
inoremap <buffer> <silent> <S-F1> :call Perl_perldoc()
inoremap <buffer> <S-F9> :PerlScriptArguments 
inoremap <buffer> <silent> <C-F9> :call Perl_Run()
inoremap <buffer> <silent> <M-F9> :call Perl_SyntaxCheck()
nnoremap <buffer> <silent> <NL> i=Perl_JumpCtrlJ()
vnoremap <buffer> <silent> \rh :call Perl_Hardcopy("v")
vnoremap <buffer> <silent> \ry :call Perl_Perltidy("v")
nnoremap <buffer> <silent> \rh :call Perl_Hardcopy("n")
onoremap <buffer> <silent> \rh :call Perl_Hardcopy("n")
nnoremap <buffer> <silent> \ry :call Perl_Perltidy("n")
onoremap <buffer> <silent> \ry :call Perl_Perltidy("n")
vnoremap <buffer> <silent> \ft :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"File Tests")
nnoremap <buffer> <silent> \ft :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"File Tests")
vnoremap <buffer> <silent> \nxs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.regex")
nnoremap <buffer> <silent> \nxs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.regex")
vnoremap <buffer> <silent> \njt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.jump tags")
nnoremap <buffer> <silent> \njt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.jump tags")
vnoremap <buffer> <silent> \pm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.markup sequences","v")
nnoremap <buffer> <silent> \pm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.markup sequences")
vnoremap <buffer> <silent> \pi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.item")
nnoremap <buffer> <silent> \pi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.item")
vnoremap <buffer> <silent> \pob :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.over, back","v")
nnoremap <buffer> <silent> \pob :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.over, back")
vnoremap <buffer> <silent> \ph3 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head3")
nnoremap <buffer> <silent> \ph3 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head3")
vnoremap <buffer> <silent> \ph2 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head2")
nnoremap <buffer> <silent> \ph2 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head2")
vnoremap <buffer> <silent> \ph1 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head1")
nnoremap <buffer> <silent> \ph1 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head1")
vnoremap <buffer> <silent> \pbt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin text, end","v")
nnoremap <buffer> <silent> \pbt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin text, end")
vnoremap <buffer> <silent> \pbm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin man, end","v")
nnoremap <buffer> <silent> \pbm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin man, end")
vnoremap <buffer> <silent> \pbh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin html, end","v")
nnoremap <buffer> <silent> \pbh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin html, end")
vnoremap <buffer> <silent> \pfc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.for, cut","v")
nnoremap <buffer> <silent> \pfc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.for, cut")
vnoremap <buffer> <silent> \ppc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.pod, cut","v")
nnoremap <buffer> <silent> \ppc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.pod, cut")
vnoremap <buffer> <silent> \xms :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.metasymbols")
nnoremap <buffer> <silent> \xms :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.metasymbols")
vnoremap <buffer> <silent> \xex :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.extended Regex","v")
nnoremap <buffer> <silent> \xex :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.extended Regex")
vnoremap <buffer> <silent> \xup :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.Unicode Property")
nnoremap <buffer> <silent> \xup :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.Unicode Property")
vnoremap <buffer> <silent> \xpc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.POSIX classes")
nnoremap <buffer> <silent> \xpc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.POSIX classes")
vnoremap <buffer> <silent> \vue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.use English")
nnoremap <buffer> <silent> \vue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.use English")
vnoremap <buffer> <silent> \vs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.POSIX signals")
nnoremap <buffer> <silent> \vs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.POSIX signals")
vnoremap <buffer> <silent> \vr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.regexp")
nnoremap <buffer> <silent> \vr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.regexp")
vnoremap <buffer> <silent> \vio :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IO")
nnoremap <buffer> <silent> \vio :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IO")
vnoremap <buffer> <silent> \vid :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IDs")
nnoremap <buffer> <silent> \vid :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IDs")
vnoremap <buffer> <silent> \vf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.filehandle")
nnoremap <buffer> <silent> \vf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.filehandle")
vnoremap <buffer> <silent> \ve :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.errors")
nnoremap <buffer> <silent> \ve :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.errors")
vnoremap <buffer> <silent> \vb :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.basics")
nnoremap <buffer> <silent> \vb :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.basics")
vnoremap <buffer> <silent> \ise :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDERR")
nnoremap <buffer> <silent> \ise :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDERR")
vnoremap <buffer> <silent> \iso :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDOUT")
nnoremap <buffer> <silent> \iso :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDOUT")
vnoremap <buffer> <silent> \isi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDIN")
nnoremap <buffer> <silent> \isi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDIN")
vnoremap <buffer> <silent> \ipi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open pipe","v")
nnoremap <buffer> <silent> \ipi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open pipe")
vnoremap <buffer> <silent> \io :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open output file","v")
nnoremap <buffer> <silent> \io :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open output file")
vnoremap <buffer> <silent> \ii :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open input file","v")
nnoremap <buffer> <silent> \ii :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open input file")
vnoremap <buffer> <silent> \ip :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.print")
nnoremap <buffer> <silent> \ip :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.print")
vnoremap <buffer> <silent> \isu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.subroutine","v")
nnoremap <buffer> <silent> \isu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.subroutine")
vnoremap <buffer> <silent> \it :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.translate")
nnoremap <buffer> <silent> \it :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.translate")
vnoremap <buffer> <silent> \is :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.substitute")
nnoremap <buffer> <silent> \is :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.substitute")
vnoremap <buffer> <silent> \im :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.match")
nnoremap <buffer> <silent> \im :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.match")
vnoremap <buffer> <silent> \ir :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.regex")
nnoremap <buffer> <silent> \ir :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.regex")
vnoremap <buffer> <silent> \iha :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash+assignment")
nnoremap <buffer> <silent> \iha :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash+assignment")
vnoremap <buffer> <silent> \ih :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash")
nnoremap <buffer> <silent> \ih :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash")
vnoremap <buffer> <silent> \iaa :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array+assignment")
nnoremap <buffer> <silent> \iaa :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array+assignment")
vnoremap <buffer> <silent> \ia :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array")
nnoremap <buffer> <silent> \ia :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array")
vnoremap <buffer> <silent> \idd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar_list")
nnoremap <buffer> <silent> \idd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar_list")
vnoremap <buffer> <silent> \ida :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar+assignment")
nnoremap <buffer> <silent> \ida :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar+assignment")
vnoremap <buffer> <silent> \id :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar")
nnoremap <buffer> <silent> \id :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar")
vnoremap <buffer> <silent> \swh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.when")
nnoremap <buffer> <silent> \swh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.when")
vnoremap <buffer> <silent> \sg :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.given")
nnoremap <buffer> <silent> \sg :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.given")
vnoremap <buffer> <silent> \sw :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.while","v")
nnoremap <buffer> <silent> \sw :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.while")
vnoremap <buffer> <silent> \st :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.until","v")
nnoremap <buffer> <silent> \st :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.until")
vnoremap <buffer> <silent> \sue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless-else","v")
nnoremap <buffer> <silent> \sue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless-else")
vnoremap <buffer> <silent> \su :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless","v")
nnoremap <buffer> <silent> \su :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless")
vnoremap <buffer> <silent> \sie :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if-else","v")
nnoremap <buffer> <silent> \sie :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if-else")
vnoremap <buffer> <silent> \sei :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.elsif","v")
nnoremap <buffer> <silent> \sei :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.elsif")
vnoremap <buffer> <silent> \se :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.else","v")
nnoremap <buffer> <silent> \se :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.else")
vnoremap <buffer> <silent> \si :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if","v")
nnoremap <buffer> <silent> \si :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if")
vnoremap <buffer> <silent> \sfe :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.foreach","v")
nnoremap <buffer> <silent> \sfe :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.foreach")
vnoremap <buffer> <silent> \sf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.for","v")
nnoremap <buffer> <silent> \sf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.for")
vnoremap <buffer> <silent> \sd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.do-while","v")
nnoremap <buffer> <silent> \sd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.do-while")
vnoremap <buffer> <silent> \cma :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.macros")
nnoremap <buffer> <silent> \cma :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.macros")
vnoremap <buffer> <silent> \ck :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.keyword comments")
nnoremap <buffer> <silent> \ck :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.keyword comments")
vnoremap <buffer> <silent> \ct :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date+time")
nnoremap <buffer> <silent> \ct :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date+time")
vnoremap <buffer> <silent> \cd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date")
nnoremap <buffer> <silent> \cd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date")
vnoremap <buffer> <silent> \chpo :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pod")
nnoremap <buffer> <silent> \chpo :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pod")
vnoremap <buffer> <silent> \cht :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description t")
nnoremap <buffer> <silent> \cht :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description t")
vnoremap <buffer> <silent> \chpm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pm")
nnoremap <buffer> <silent> \chpm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pm")
vnoremap <buffer> <silent> \chpl :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pl")
nnoremap <buffer> <silent> \chpl :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pl")
vnoremap <buffer> <silent> \cme :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.method")
nnoremap <buffer> <silent> \cme :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.method")
vnoremap <buffer> <silent> \cfu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.function")
nnoremap <buffer> <silent> \cfu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.function")
vnoremap <buffer> <silent> \cfr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.frame")
nnoremap <buffer> <silent> \cfr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.frame")
noremap <buffer> <silent> \rpco :call Perl_PerlcriticOptionsInput()
noremap <buffer> <silent> \rpcv :call Perl_PerlcriticVerbosityInput()
noremap <buffer> <silent> \rpcs :call Perl_PerlcriticSeverityInput()
noremap <buffer> <silent> \ro :call Perl_Toggle_Gvim_Xterm()
noremap <buffer> <silent> \rx :call Perl_XtermSize()
noremap <buffer> <silent> \rk :call Perl_Settings()
noremap <buffer> <silent> \rt :call Perl_SaveWithTimestamp()
noremap <buffer> <silent> \rpc :call Perl_Perlcritic()
noremap <buffer> <silent> \rg :call Perl_perldoc_generate_module_list()
noremap <buffer> <silent> \ri :call Perl_perldoc_show_module_list()
noremap <buffer> <silent> \re :call Perl_MakeScriptExecutable()
noremap <buffer> <silent> \rd :call Perl_Debugger()
noremap <buffer> \rw :PerlSwitches 
noremap <buffer> \ra :PerlScriptArguments 
noremap <buffer> <silent> \rs :call Perl_SyntaxCheck()
noremap <buffer> <silent> \rr :call Perl_Run()
nnoremap <buffer> <silent> \rpnh :call perlsupportprofiling#Perl_NYTprofReadHtml()
nnoremap <buffer> <silent> \rpns :call perlsupportprofiling#Perl_NYTProfSortInput()
nnoremap <buffer> <silent> \rpnc :call perlsupportprofiling#Perl_NYTprofReadCSV("read","line")
nnoremap <buffer> <silent> \rpn :call perlsupportprofiling#Perl_NYTprof()
nnoremap <buffer> <silent> \rpfs :call perlsupportprofiling#Perl_FastProfSortInput()
nnoremap <buffer> <silent> \rpf :call perlsupportprofiling#Perl_Fastprof()
nnoremap <buffer> <silent> \rpss :call perlsupportprofiling#Perl_SmallProfSortInput()
nnoremap <buffer> <silent> \rps :call perlsupportprofiling#Perl_Smallprof()
nnoremap <buffer> <silent> \podt :call Perl_POD('text')
nnoremap <buffer> <silent> \podm :call Perl_POD('man')
nnoremap <buffer> <silent> \podh :call Perl_POD('html')
nnoremap <buffer> <silent> \pod :call Perl_PodCheck()
vnoremap <buffer> <silent> \xe :call perlsupportregex#Perl_RegexExplain( "v" )
nnoremap <buffer> <silent> \xe :call perlsupportregex#Perl_RegexExplain( "n" )
nnoremap <buffer> <silent> \xmm :call perlsupportregex#Perl_RegexMatchSeveral( )
nnoremap <buffer> <silent> \xm :call perlsupportregex#Perl_RegexVisualize( )
vnoremap <buffer> <silent> \xf :call perlsupportregex#Perl_RegexPickFlag( "v" )'>j
vnoremap <buffer> <silent> \xs :call perlsupportregex#Perl_RegexPick( "String", "v" )'>j
vnoremap <buffer> <silent> \xr :call perlsupportregex#Perl_RegexPick( "Regexp", "v" )'>j
nnoremap <buffer> <silent> \xf :call perlsupportregex#Perl_RegexPickFlag( "n" )
nnoremap <buffer> <silent> \xs :call perlsupportregex#Perl_RegexPick( "String", "n" )j
nnoremap <buffer> <silent> \xr :call perlsupportregex#Perl_RegexPick( "Regexp", "n" )j
nnoremap <buffer> <silent> \nts :call mmtemplates#core#ChooseStyle(g:Perl_Templates,"!pick")
nnoremap <buffer> <silent> \ntr :call mmtemplates#core#ReadTemplates(g:Perl_Templates,"reload","all")
nnoremap <buffer> <silent> \ntl :call mmtemplates#core#EditTemplateFiles(g:Perl_Templates,-1)
nnoremap <buffer> <silent> \nv :call Perl_CodeSnippet("view")
nnoremap <buffer> <silent> \ne :call Perl_CodeSnippet("edit")
vnoremap <buffer> <silent> \nw :call Perl_CodeSnippet("writemarked")
nnoremap <buffer> <silent> \nw :call Perl_CodeSnippet("write")
nnoremap <buffer> <silent> \nr :call Perl_CodeSnippet("read")
nnoremap <buffer> <silent> \cub :call Perl_UncommentBlock()
vnoremap <buffer> <silent> \cb :call Perl_CommentBlock("v")
nnoremap <buffer> <silent> \cb :call Perl_CommentBlock("a")
vnoremap <buffer> <silent> \cc :call Perl_CommentToggle()j
nnoremap <buffer> <silent> \cc :call Perl_CommentToggle()j
nnoremap <buffer> <silent> \cs :call Perl_GetLineEndCommCol()
vnoremap <buffer> <silent> \cj :call Perl_AlignLineEndComm()
nnoremap <buffer> <silent> \cj :call Perl_AlignLineEndComm()
noremap <buffer> <silent> \cl :call Perl_EndOfLineComment()
noremap <buffer> <silent> \hp :call Perl_HelpPerlsupport()
noremap <buffer> <silent> \h :call Perl_perldoc()
noremap <buffer> \rcm :MakeFile 
noremap <buffer> \rma :MakeCmdlineArgs 
noremap <buffer> <silent> \rmc :Make clean
noremap <buffer> <silent> \rm :Make
vnoremap <buffer> { s{}kp=iB
noremap <buffer> <silent> <F9> :call Perl_Debugger()
noremap <buffer> <silent> <S-F1> :call Perl_perldoc()
noremap <buffer> <S-F9> :PerlScriptArguments 
noremap <buffer> <silent> <C-F9> :call Perl_Run()
noremap <buffer> <silent> <M-F9> :call Perl_SyntaxCheck()
inoremap <buffer> <silent> <NL> =Perl_JumpCtrlJ()
inoremap <buffer> <silent> \ft :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"File Tests","i")
inoremap <buffer> <silent> \nxs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.regex","i")
inoremap <buffer> <silent> \njt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Snippets.jump tags","i")
inoremap <buffer> <silent> \pm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.markup sequences","i")
inoremap <buffer> <silent> \pi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.item","i")
inoremap <buffer> <silent> \pob :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.over, back","i")
inoremap <buffer> <silent> \ph3 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head3","i")
inoremap <buffer> <silent> \ph2 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head2","i")
inoremap <buffer> <silent> \ph1 :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.head1","i")
inoremap <buffer> <silent> \pbt :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin text, end","i")
inoremap <buffer> <silent> \pbm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin man, end","i")
inoremap <buffer> <silent> \pbh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.begin html, end","i")
inoremap <buffer> <silent> \pfc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.for, cut","i")
inoremap <buffer> <silent> \ppc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"POD.pod, cut","i")
inoremap <buffer> <silent> \xms :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.metasymbols","i")
inoremap <buffer> <silent> \xex :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.extended Regex","i")
inoremap <buffer> <silent> \xup :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.Unicode Property","i")
inoremap <buffer> <silent> \xpc :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Regex.POSIX classes","i")
inoremap <buffer> <silent> \vue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.use English","i")
inoremap <buffer> <silent> \vs :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.POSIX signals","i")
inoremap <buffer> <silent> \vr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.regexp","i")
inoremap <buffer> <silent> \vio :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IO","i")
inoremap <buffer> <silent> \vid :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.IDs","i")
inoremap <buffer> <silent> \vf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.filehandle","i")
inoremap <buffer> <silent> \ve :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.errors","i")
inoremap <buffer> <silent> \vb :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Special Variables.basics","i")
inoremap <buffer> <silent> \ise :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDERR","i")
inoremap <buffer> <silent> \iso :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDOUT","i")
inoremap <buffer> <silent> \isi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.STDIN","i")
inoremap <buffer> <silent> \ipi :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open pipe","i")
inoremap <buffer> <silent> \io :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open output file","i")
inoremap <buffer> <silent> \ii :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.open input file","i")
inoremap <buffer> <silent> \ip :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.print","i")
inoremap <buffer> <silent> \isu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.subroutine","i")
inoremap <buffer> <silent> \it :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.translate","i")
inoremap <buffer> <silent> \is :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.substitute","i")
inoremap <buffer> <silent> \im :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.match","i")
inoremap <buffer> <silent> \ir :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.regex","i")
inoremap <buffer> <silent> \iha :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash+assignment","i")
inoremap <buffer> <silent> \ih :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.hash","i")
inoremap <buffer> <silent> \iaa :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array+assignment","i")
inoremap <buffer> <silent> \ia :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.array","i")
inoremap <buffer> <silent> \idd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar_list","i")
inoremap <buffer> <silent> \ida :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar+assignment","i")
inoremap <buffer> <silent> \id :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Idioms.scalar","i")
inoremap <buffer> <silent> \swh :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.when","i")
inoremap <buffer> <silent> \sg :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.given","i")
inoremap <buffer> <silent> \sw :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.while","i")
inoremap <buffer> <silent> \st :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.until","i")
inoremap <buffer> <silent> \sue :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless-else","i")
inoremap <buffer> <silent> \su :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.unless","i")
inoremap <buffer> <silent> \sie :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if-else","i")
inoremap <buffer> <silent> \sei :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.elsif","i")
inoremap <buffer> <silent> \se :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.else","i")
inoremap <buffer> <silent> \si :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.if","i")
inoremap <buffer> <silent> \sfe :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.foreach","i")
inoremap <buffer> <silent> \sf :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.for","i")
inoremap <buffer> <silent> \sd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Statements.do-while","i")
inoremap <buffer> <silent> \cma :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.macros","i")
inoremap <buffer> <silent> \ck :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.keyword comments","i")
inoremap <buffer> <silent> \ct :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date+time","i")
inoremap <buffer> <silent> \cd :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.date","i")
inoremap <buffer> <silent> \chpo :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pod","i")
inoremap <buffer> <silent> \cht :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description t","i")
inoremap <buffer> <silent> \chpm :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pm","i")
inoremap <buffer> <silent> \chpl :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.file description pl","i")
inoremap <buffer> <silent> \cme :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.method","i")
inoremap <buffer> <silent> \cfu :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.function","i")
inoremap <buffer> <silent> \cfr :call mmtemplates#core#InsertTemplate(g:Perl_Templates,"Comments.frame","i")
inoremap <buffer> <silent> \ro :call Perl_Toggle_Gvim_Xterm()
inoremap <buffer> <silent> \rx :call Perl_XtermSize()
inoremap <buffer> <silent> \rk :call Perl_Settings()
inoremap <buffer> <silent> \rh :call Perl_Hardcopy("n")
inoremap <buffer> <silent> \rt :call Perl_SaveWithTimestamp()
inoremap <buffer> <silent> \rpc :call Perl_Perlcritic()
inoremap <buffer> <silent> \ry :call Perl_Perltidy("n")
inoremap <buffer> <silent> \rg :call Perl_perldoc_generate_module_list()
inoremap <buffer> <silent> \ri :call Perl_perldoc_show_module_list()
inoremap <buffer> <silent> \re :call Perl_MakeScriptExecutable()
inoremap <buffer> \rw :PerlSwitches 
inoremap <buffer> \ra :PerlScriptArguments 
inoremap <buffer> <silent> \rs :call Perl_SyntaxCheck()
inoremap <buffer> <silent> \rr :call Perl_Run()
inoremap <buffer> <silent> \rpnh :call perlsupportprofiling#Perl_NYTprofReadHtml()
inoremap <buffer> <silent> \rpns :call perlsupportprofiling#Perl_NYTProfSortInput()
inoremap <buffer> <silent> \rpnc :call perlsupportprofiling#Perl_NYTprofReadCSV("read","line")
inoremap <buffer> <silent> \rpn :call perlsupportprofiling#Perl_NYTprof()
inoremap <buffer> <silent> \rpfs :call perlsupportprofiling#Perl_FastProfSortInput()
inoremap <buffer> <silent> \rpf :call perlsupportprofiling#Perl_Fastprof()
inoremap <buffer> <silent> \rpss :call perlsupportprofiling#Perl_SmallProfSortInput()
inoremap <buffer> <silent> \rps :call perlsupportprofiling#Perl_Smallprof()
inoremap <buffer> <silent> \podt :call Perl_POD('text')
inoremap <buffer> <silent> \podm :call Perl_POD('man')
inoremap <buffer> <silent> \podh :call Perl_POD('html')
inoremap <buffer> <silent> \pod :call Perl_PodCheck()
inoremap <buffer> <silent> \nts :call mmtemplates#core#ChooseStyle(g:Perl_Templates,"!pick")
inoremap <buffer> <silent> \ntr :call mmtemplates#core#ReadTemplates(g:Perl_Templates,"reload","all")
inoremap <buffer> <silent> \ntl :call mmtemplates#core#EditTemplateFiles(g:Perl_Templates,-1)
inoremap <buffer> <silent> \nv :call Perl_CodeSnippet("view")
inoremap <buffer> <silent> \ne :call Perl_CodeSnippet("edit")
inoremap <buffer> <silent> \nw :call Perl_CodeSnippet("write")
inoremap <buffer> <silent> \nr :call Perl_CodeSnippet("read")
inoremap <buffer> <silent> \cb :call Perl_CommentBlock("a")
inoremap <buffer> <silent> \cj :call Perl_AlignLineEndComm()
inoremap <buffer> <silent> \cl :call Perl_EndOfLineComment()
inoremap <buffer> <silent> \hp :call Perl_HelpPerlsupport()
inoremap <buffer> <silent> \h :call Perl_perldoc()
inoremap <buffer> \rcm :MakeFile 
inoremap <buffer> \rma :MakeCmdlineArgs 
inoremap <buffer> <silent> \rmc :Make clean
inoremap <buffer> <silent> \rm :Make
inoremap <buffer> { {}O
let &cpo=s:cpo_save
unlet s:cpo_save
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=~/.vim/perl-support/wordlists/perl.list
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=wcrqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=2
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,/etc/perl,/usr/local/lib/perl/5.18.2,/usr/local/share/perl/5.18.2,/usr/lib/perl5,/usr/share/perl5,/usr/lib/perl/5.18,/usr/share/perl/5.18,/usr/local/lib/site_perl,,
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal smartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=%!airline#statusline(3)
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
set nowrap
setlocal nowrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 232 - ((44 * winheight(0) + 25) / 51)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
232
normal! 0
lcd ~/Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core
wincmd w
argglobal
enew
file ~/Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core/legacy
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=TagbarBalloonExpr()
setlocal nobinary
setlocal bufhidden=hide
setlocal nobuflisted
setlocal buftype=nofile
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'tagbar'
setlocal filetype=tagbar
endif
setlocal foldcolumn=0
setlocal nofoldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcqw
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal nomodifiable
setlocal nrformats=octal,hex
set number
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal smartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=%#airline_a#\ Tagbar\ %#airline_a_to_airline_b#>%#airline_b#\ Name\ %#airline_b_to_airline_c#>%#airline_c#\ Taxonomy.pm\ 
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'tagbar'
setlocal syntax=tagbar
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal winfixwidth
set nowrap
setlocal nowrap
setlocal wrapmargin=0
lcd ~/Documents/doct/strain-solution/bio-must-core/lib/Bio/MUST/Core
wincmd w
3wincmd w
exe 'vert 1resize ' . ((&columns * 31 + 107) / 215)
exe 'vert 2resize ' . ((&columns * 71 + 107) / 215)
exe 'vert 3resize ' . ((&columns * 70 + 107) / 215)
exe 'vert 4resize ' . ((&columns * 40 + 107) / 215)
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
