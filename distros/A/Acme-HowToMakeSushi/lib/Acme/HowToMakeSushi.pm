package Acme::HowToMakeSushi;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";
our $sushi= 0;


END{

    unless ($? != 0) { #  success making sushi
        print << 'EOFEOD';
  `` `` `` `````````````````````````````````````````````````````````````````````````.```.`..`..`..`..`...`.................................................~....~..~..~.~.~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`  ` ` ` `` `  `  ` ` `` `` ```````````````````````````````````````````````````.`.``.`.``.`.`.`.`.`..`..`.`.``.``.`..`..`.............................~.~...~~.~.~.~.~.~.~.~..~~.~.~.~~.~~.~~~~~~~~~~~~~
``` ` ` ` `` ````` ``` `` `` ``` ``` ``` ````````````````````````````````.`.``.`.`.`.``.``.`.`.`.`.`..`....`..`....`..`..`...........................~..~~.~..~~..~.~.~.~.~.~~.~~.~~.~.~~.~~~~.~~~~~~~~~
 ` ` `` `` ``` ` ```` ``````` ````````````````````````````````````.``.`.````.``````.`.`.`..`..`..`..`.``.`..`..`..`.......`.`...................~..~...~....~..~.~.~.~.~~~.~.~~~~~~~~.~~.~~.~~~.~~~~~~~~
` ` ` `` `` ` ``` `` `` ` ` ``` ``` `` ``` ```````` ``````````````````.``.`````.```.``.``.`.`.`.`.`..`...`..`.`.`..`.`.`...`.................~........~..~.~.~..~.~.~..~.~..~.~..~.~~~.~~.~~~~~~.~~.~~~~
` `` ` ` ``` `` ``` ```` ``` ```````````````````````````````````.``.````.``.````.``.``.`.`...`.`..`.`..`...`.`..`.....`.`...................~..~..~...~...~..~..~..~.~~.~.~~.~~~~.~.~~~~~.~~~~~~~~~~~~~~
 ` `` ` ` ``` `` ```` ```` ````` ``` `` ``````` ```````````````.`````.``````.``.``.`.``.``.``..`.`..`.`.`..`..`..`..`................................~..~...~.~~.~..~..~.~..~.~.~~~~.~.~~~~.~.~~~~~~~~~~
` ` ` ````  ````` `` `` ``` `````` `````` `````````````````````````````.````````..``.`.``..`.`..`..`...`..`..`.`..`..`..`..`..`...............~..~....~..~.~..~..~~.~~.~.~~.~~.~.~.~~~~.~~~~~~~.~~~~~~~~
` `` ` `` `` ` `` ```` `` ``` ```````` ``````````````````````````.``.```.`.``.``.````.`.``..`.`..`.`.`..`..`..`.`.....`.`.......`..........~..........~..~..~..~..~..~.~.~~~~~~~~.~~~~.~~.~~~~~~~~~~~~~~
 ` ` `` ````` ` `` ` `````````` ``` `````` ``````````````````````````.`````.``````.`.``.`.`..`.``.`.`.`.`.`.`..`..`.`....`........................~..~..~..~.~~.~..~.~..~.~.~.~.~~.~~.~~~~~~.~~~~~~~~~~~
`` `` `` ` ` ``` ```` ` `` `````` `````````` ```````````````````.``````.``````.````.`..`.`.`.`..`..`...`...`.`.......`.......`...`........~....~...~..~..~..~..~.~~.~.~~.~.~.~~.~~.~~~~~~.~~~.~~~~~~~~~~
` ` ` `` `` `` ``` ````` ```` `````````` `````````````````````````.``.```.``.``.`.``.```.`..`.`..`..`..`.`..`.`.`..`....`......`....................~..~..~.~.~.~..~.~.~.~.~.~~~.~~.~~~.~~.~~~~.~~~~~~~~
 ` ``` `` ``` ` ``` ```````````` `` ``````` `` ````````````````.``````````.`````..`.`.`.`.`.`..`.`.`.`..`.`..`.`...`..`.`.``....................~....~..~..~.~..~..~..~.~.~.~.~.~~.~.~~~.~~~.~~~~~~~~~~~
` `` `` `` ` ``` `` `  ``` `` ``````` `````````` ``````````````````.``.``````.````.``..`.`.`.``.`.....``..`..`..`...`.......`...`...........~.......~..~..~...~.~~.~~.~.~.~..~~.~~~~~~~~~.~~~~~~~~~~~~~~
` `` `` ``` `` `` `````````````````````` ``` ````````````````.``.``````.`.``.``.``.``.`.`..`..`..``.`..`...`..`....`..`..`.....................~......~..~..~~.~..~.~~.~.~.~~.~~.~.~.~~.~~~.~~.~~~~~~~~~
 ` `` `` ```` ```` ``` `` ```` `` ```````` ```````````````````````.``.``.````.`..`.`.`.`..`.`..`...`.`........--------------..............~....~..~...~.~..~.~~..~...~.~~~.~~~.~~.~~~.~~~~~~~~~~~~~~~~~~
` `` `` `  ` `` ```` ``` ````````` ```````````````````````````.`````.`.`.`.``.``.``.`..`.`.`.`.`.`. .-_(:>>><<+1<+1z??lllll=z++----..................~..~.~...~.~.~~..~..~~.~.~~~~~.~~~~~.~~.~~~~~~~~~~~
` `` `````` `` ` ` `` ````` ``` ```` `` ``` `````````````````````.`````.````.``.`..`.`..`..`.`..___:<<__~_~<<<<+?=+???<<?1zlOttttltz++--_..~.~........~..~.~~..~.~.~~.~~.~~.~~.~.~~~.~~~~~.~~~~~~~~~~~~~
 ` `` `  ``` ```` ``````````````````` ``````````````````````.`````.````````.``..`.`..``..` .-_:::~~__~__.___~~_.~~~~<<<+<<<1zzzzOrwrtOOOzz+--..~~.~.~..~..~..~~..~..~~~.~.~~.~~.~.~~.~~.~~~~~~~~~~~~~~~~
` `` ``` ` `` ````` ` ` `` `` `````````` `````````````````````.`````.``.``.`````.``.....-_(<<~__~.___  .____.~_.__~~._~:<<><?><<zOltrrrvzzzvOO+-_.~~...~..~..~.~..~..~.~~~.~~.~~~~.~~~.~~~.~~.~~~~~~~~~~
`` `` ````` `` ` ``` `````````` ``````````` `````````````````.`.``.``.``.``.`.``..``..__::::~~_``_._.~_....~..__~~_~~_~~(;<:<;<>+zlOtrrvrrzvzwwvwz--_~..~..~.~.~~.~~.~~~.~~.~~.~~.~~~.~~~~~.~~~~~~~~~~~~
 ` ` ` ` `` ``` ` ```` ````` ```` ``` ````````````````````.``````.````.``.``.`..` ._(::~~~_..__`..___.~~.~_..-_..._~~~___(<<(<<+=lzttttttrvzzvuzuXzvO+-_.~..~.~...~.~...~.~~.~~.~~~.~~.~~.~~~~~~~~~~~~~~
` `` `` ` `` ````` `` `` ````` ````` ````````````````````.``.``.```.`.```.`.`` _(;<~____..  _._..... .__.~~___~._~___:::<<><:~<?=lltttlltttrrrzuzuuuuuzw&+-_..~..~..~~.~.~.~~~..~~.~.~~~~~~~~~~~~~~~~~~~
`` `` ```` `` ` ``` `````` `````````````````````````````.````.``..``.`.`.`. ._<:<<~._ ` `` --.... .....-_~~______~_<~_~~_::~~(+?=====lll=ltttttwvwXuwwuzuuzwx-.~~..~..~.~.~~~.~~~.~~~~~~.~~~~~~~~~~~~~~~
 ` `` ` `` `` `` ``` `` ````` `` ``````````````````  ............   ``.`` .(><:<;<_. ````  -.._-_____~~:_(<(+<;<~::~_(_((:~~_(>>???zzlll==tlllttrttOXuuZzuzuwzw+--....~..~..~~~~~~~~~.~~~.~~~~~~~~~~~~~~
` `` ``` `` ````` ```` `` ```````````` ...--_(((++++++++++++++++++<<<<(___<<<:~_~.__...~~_<<(<<<((:;<+<:(+?1<<<<(:_<<;;<:;<:<<<<<+z>?=l=zzl=ztOtttrOlzOrOwrzXzwvOOc-_.~~.~.~..~..~~~~~~~~~~~.~~~~~~~~~~~
` `` `` ` `` ` `` ``````````````` .--(<;;<<<<<<<<1111?zllz1==lz?1zzzzl=zzzz++(__..--_~_::_(>>zzz1zz1+1z==z=1+=;<<<(::;>:(<_:_(;<<<>?=O<==zv1ttllOOlztOrlttlzuzzXuuXwz+-_.~..~~.~~~.~~~.~~~~~~~~~~~~~~~~~
 ` `` `` `` ``` `` `` ````````..__(;><<<<_~~~~_.__~~:::><<<<+==?=?1ztrttrttOtlz++=<<<<>?<<<<<+<+z+1lzzzz1zzzz=++<><<><:<(__(:(<;?<>+??+11?1l=1=zzztzzzzOOrlOvvvvwzvuuwuw+-_.~.~.~~~~~.~~.~~~~~~~~~~~~~~~
` `` `` `` `` ````` `` ```` .(<;:;<<~_ ``` .``` ...._..~~:~~~<11?<>+zOrrrzzvrrttz?zz<<<~(<+1zOzzzzOtzzzOtzzzzz1<z1+++;<<<(<:<<;;>><1?==??=1?1=?1=zzOllzlllzrrrrrOvzuuzuuXww&-_~..~.~~~~~~~~~~~~~~~~~~~~~
``` `` ``````` ` ```````` .(<><<<<_ __` ` ``` .` _<_-.~~~~<<<_(>>?+<;1zlOwOOvwOtllll=z+zzwwwrvvOrrwwrOwOOllzz=z?1+><>>><_;;<;+<<<:++?>>>?>??<??l1==z=lll=zrtlttrtrrwzuzuuuuXvwz-_~..~~.~~~.~~~~~~~~~~~~~
` ``` `` `` ````` ```` ._(<<~::<-~_   .._`....--` `--.__~~<::__(?<<+<<<1zlOOrrvvrwOltOtrvwXXXXXZuXwwvzwwuzvO===Ozz=+>?>+>11>>+?>++=??++>;+=z===llzlltzzzzrrttrttOrrrrwzzuuXZZuuwrO-_.~~.~~~~.~~~~~~~~~~~
`` ``` `` `` ` ````` ._(;:;<~<<<____.______-~.._ .._(__<~__~(:<:__(;;++?+?1zOOwzuzvrtttrzuXXZUXXXyZyZkwwwwwrwXwrv1z==z+<1zz1?1<>>;+?1?<<>1z?1zlzzzOzOOOOOrvrrrrOwvrvvwvzuuuuZZZZuXww+_~~.~~~~~~~~~~~~~~~
` ` ` `` ```` ```  ._:~::::::+>>?>>(___~_~.__.._:~_~<~___.~~<<:~_~~;:<<;;:;1l?1OzOXvrrvrrzXuXZyZZ0XXUUUIzzwuuwOOvz<1<<_(;;<1<<;;<<<<1<11==?1z1+zllztvO1zvrrrrrrvvvzvzXuuuuuZuzuZZuZuXo-~~~~~~~~~~~~~~~~~
 ``` `` `` ````` _~~_::;;:;><(:<>1?<<<+1<;;<-___:::__:___~~~~__~_~~~~~~~:(;+?<??<>1OruuXzzzzzzvwUXOzzzXZuUZXuwXXzOz+1+<<<1<__~<~:;<;<<=zz>==1lzllzrttOzwXvvvvzwrzwzzuuuuuuuuuuuuuuuuZuXx~~~~~~~~~~~~~~~~
``````` `````  -:_::_:_:<<<;>>?????+=z1<<<<::;;::~~:~~~_~~___:_`._~._~(:<<<+<+<<+zz=OrzuuuuuuuuuwzwXXXkXwwzXwwwvOttlz?I<<(<(><;<;;<;(+<1++?zzlztlttttOtzzzzzrvzzuuzuuuZZuuuuZZuuuuZuzuXXx_~_~~~~~~~~~~~~
` `  ``` ``  _::::__<~(<~<;;<>++??1z1+++1++zlz>><_~~~~~~~~~~__~~~~~_~(::<:<<<<;<(1z1lzOwzuzzzzuuzzwXWuXVXUXXuZzwrOz+z+(<?<<(((-;<<<<:;+1=z+OzztrrttrtrrvrrrrvvzuuuzuuuuuuZuuZZZuuuZuuuzzX+~_~~~~~~~~~~~~
` ``` ``` ._:::::_~:_~_:<<>>;+<??1zll1??++<>1?<>+++__~~_-___<~~::~~;::<~~_(:;<<<+>;+zz?zrrvzXuvuuuzuwXWWfffWXXXwzuXOtz1<_:~<<<_(__<~(;+z1=zttrrOrwzwtrrwuzuuuuuuuuZuuuZZZZZZZZZZuuuZZuwzZX+~.~~~~~~~~~~~
`` ```  ._:::::::::_~(::<<:<?+z?=1?=?????=z?11z<;<++((_((__~_~~~__~~~___(::;;<:;<++??1zllOOvOrzwuzuuzzXWHkbpppffWyXXXXwwwwwXOz++-__(zOOOtOvvrvvzXzuzvrwuXuzuuuuuuuuZZyyyZZZyZZZyZZuuuzuuuZX+~~~~~~~~~~~~
`` `  ._:::::::;::;:;:><;>+<>?==1zzzl=lllllOz+===1+>+?+<~(__:_(-(__:<~::<<:<:(;>;+=zzzzzllOltrrwzuvzzzuzzUWHbbkppfffVVyXWVWXXXZXzwwzOz+zzrrwrwwzuuzzOOzuwuXzuuZZZZZyVyyyyyyyZZyXZZZuuuZuuXXuc_~~~~~~~~~~
``` ._::::::::;<>;;;<;<<+?+?=zlzzlllllllzzllOll=?=11+<<<<<<?<;:_~~<<<___+<:(:;<>1==lzz1zlltOtrrOtwzzzzzzzzuXUWbbpbppffffVyVfVVZZZZyXXwuzuXwwwuwuXXuwtwwuuuZZZZZZyyyyyyyyVVVyyZyyZZZZuZZuuZyZXo~~~~~~~~~~
 `._:(<~~::::;;>>>>>>>????=llltllttlllllltltttll==?=z=?=1<_~~(__(<~_.~_~~_~(++<+>?+??+zOllztwZOZOOvvrzzzuzvvuuXWHbpppffpyVffffpffVXVyVVyyuZuUyXwwuuXwuXuZZZZZZyyyyVyyyyVVVVfVyyyyVyyyZZZZZZZuXo_~~~~~~~~
` _~:;><><::;;;;>?>??=====llltlllttllllllltllllllltt=?11++?+1+<:<<<_~~~_:(;<;+<>zzzz1llOllIOOzztwIOrwwOvwuuzzzzuXXUWpfppVVpfffppppfffffffWZXkuXZXWXXXwwZyyZZyyyyyyyVfVVffffffpfWfyyyZZyyZZyXZXvz-.~~~~~~
`` ~~;>>????>>>>>????????===lltlllllllllzltlllllOOl=lz++=?=?>>?1++(<<<<<:(;<<<?=1z1zz1==OOOtltrttzZIzwwuzwuuuwzzzzOwUWWfVyVVfffppfppppffffWyWWXZZXuXyZyZZyZXVyyyyVVVfpffffpppfpfffVyyyXyZZyyZZXOv<~~~~~~
```_~(;>???????????=?????==ll=l=l==l=lllllltltllllll=zzzzlz==zz=?1z1?++>+=<+?>>+zz<?zltzOrttOtrOzwOOuwwuuwzuuuuuzuuvwuuuXZyyyVVfffffpppffffVVyVVyyXXXZUW0wuZyVfVVfffpfpfppppppfpfffVfVyyyyyyyZuvI<_~~~~~
 `` _(;<<><>?>>??===lllll1l==l=======ll==lllltllll=lllzl=llllll==zzlOzzz=zzllzzzz?+ztlztttrrrrrwzrrruzzzXuzuzuuuuuuzzzuXZZuuXUWyVVfVVVffffffVffffWyyZyuuZUXXZXWWppppppppppbbpppppfffVVyyyZyyZZuzOz<~~~~~
` ` _<;:<<~__<<;;<+?1===llttz===?========llllll=llllltlltttttttlztttlrzzlOOrtOOzOrOzOOwwwrtrvvwXXzzzwwzwvuuuwzuuuuuuzuzuZZZXZCzOXuXUUWyyyyyZyVfffffVyZyZZZuZuXyyWWpppppppbbbppppppfpffVyyyyyZZuzwO<_~~~~
`````````````` `___~<<<<+11=lllzzz?=======llllllllltllllltrtrttttrrOrOOwvrrrOOOrrwOrrwwZXrwuuXwXZuwZ0rzzzvzuuzuuuzuuuuuuXyyZXO++zlOwzzzXXZyZZyyyVVffpyZyZZuuuXyVVyyWpbbbkbkkbbbpfpppfffVVyyVyZuuvtz<~~~~
`` ````````````````._~~~~~~<<11==lll====?=l=======lllttllttttltttrrrrrrrrwvwvvrwvvzuuuuuyuwuX0wX0XwuvwurwXZuuuuuuuuuzzuuXXWyZXOl==<+zzwvvvuuXXZyyyVVVyVyyZZyZZyyVVVffVfWbbbkbkbbbbppppfVyyyVZZZuvrtz_~~~
` ` ` `````````````..~~~~~:~~::~<+1=llll==l===l==lllllltlltttttttrrrtttrvzuzzzzzXzvrzzzzwXuXu0VtwwXwwuXzXXuuuuuuuZZZZuuuXXXZyZuOll??=1?1zOwvzzXXZZZyyyVVyVVVyyVVfVWpppppppbkbkkbppbpffffVyVyyZZZzvrO>~~~
````````````````.........~~~~~~~~~:<?1====ll=lll=ll=lllllltttttttrrvvrwvrvzuuuuuZyyXXZuZuuZykkwXZZXwwuZZZXXyZZZZXuZZuZZuXfVyyZuwO=====????zwzuuuuuXZZyyyyyVVfffffffffffppbbkkkbbbbbppppfVVyyVyyZuzrr>~~~
`` ``````````.....~_........~~~:~~~~~~<<1?1zl=lll==l==llllltttlltttOrrrzrrzuuuuZZyyyyyyyyyXyWffyVWXZZXZXWXyZZZyZyyZyyZZZVpffyZuuwl=====??>+zrvzuzzzZXuXyyyyZWVVVyVfffVfpbpppbbbbbbpbpppffVVyyVyyZzvt>~~~
`` `` ````....._~~~__.........~~~:~~~~_._<<<?===llllll=llltlltlltttttrrtrzzuZZuZyZZZyyyyVVVyyyyVfVVyyyVfpfpVZZyyyyyyZZZZfppfyyZuvOOzz==??11zrrrvvvrrOzwXuyyyZyZyyyffffpbbbkbbbbpppppppffffVyyVVyZzvt>~~~
````````....~_~_:;+<>_.....~.~~~~...~..~.~~._<1??=zlllllllllllttlttlttrrrrzwzuZZZyfVyyyyyyyyyyyXWpppfpppWppVVVVyyyyyyyyyfpppVyZuvtrvvrrrrrrrvvrrvrrrrrrrrXUZZZyyVVffppfpppbbbkbbbbpppfffffVyyfVWuXwO<~~:
```````...~~~::<+1z<.~.~~~~~.~~.~...~...~~.~~_~_~<+1==ltttltlllllllllllOrrvzuuuXyyyVfyyyyyyyfpfWWyWppppppVyVVfffffVfWWyWfppfVyZurtwzzzvrvvzvvvvvrrttrrrrvrOwXyyWyVffffffffpbbkkbbbpppfpffffVVyyyXwrZ<~:~
``````...~~~:;++zltz_.~..~~~~~..~~..~~~~~.~~~~~~~~_(<+1=lOtttllllllllllttOrvzuuuuZyyyVVyyVyVWyyfffVWpbpppppVffpppppppfpppppfyyZzvrOvvrrrrvvzvvrOv<<zOtrrtttrrwXWyyVVVVfffpppbbbpbbbppfpfffVVyXyyZuOI<~~~
````....~~::;>?=lttrw+-~~~~~~~~~~~~.~~~~~...~.~~~~~~~~~<<1=lllll==l=lllllltwzzXOwXZyyVVVyyVfffVfpppffWbbbbbpbpfpppbWpfpppppfVyZuvttrrrrrrvvvzrvO??>>?lttrttttttwWyZyyyVVfpppbbbppppppfpffpVyXZXUZZtv~:::
`````..~~~:;;?=ltrrrrrrO+_~~:~:~~~~~..~~~.~~.~~..~~~~~~~~~_<<1lltOOzz==llllrvzuuZZyyyyVyVVffffppfppppfpbbbbkbbkkbbbbbppWpppfVyZurtOrrrrrrrrvXXrvwOzwvrrvrtttrttrzXuZZyyVffpppppppffpppppffyWfWXXXXO>::~~
````...~~~:;;?=ltrvvzzzzuww+:::~~~~~~~.~......~~~~_~~~~~~~~.._<<1ztrrrrOzlttOrXuZZZyyyyyVVVyVpfpffppppppbkkkkkkbkkkkbppWpppfyyZXrtztrrrtrrrvZuzvzvzzvrrvrrttttttttwuuZyyyVVffpppffVWWVpppWyXWfWzzrr<::::
````...~~:::;??lttvzzzuzuuuXz<_:~~~~~~~~........~~~~~~~~~~~~.~~~~<+zlltOrOOlOXuuZZZZyyyyyyyfffpfpffpppppbbkkkkkkkkkkkbbpppffVyZXrtOOwwOtrrvvzuzzwOtrrrvvrrtllltttrrwXZyyyVVfffpffppfyXWppWfpXXXXzZO<::::
```...~~~:::;>?=ltrzzuzuuuuuuA+(:_~~~_~~~~~........~~~~~.~~~~~.~~~~~<+1lltrrrrvuuuZyyZyyVVVVffffpfffpbbbbbbkqkqqqqkkkkkkppfffWZzrO<;+XXXwrvzzuuvllttrrrrrrtlllllOttrrwXZZZyVffffppfVXWWWfWVVWUWZukv<;:::
```...~~~:::;>?=ltrvzzzuuuZZZZyA&+((+(<_~~~~~~~~.~..~~~...~~~~~~..~~_:<<1zltwrrrzuuZZyyyyyyVVVfffpppbbbbkkkkkkqqqqqqqkkbbpffyZuztz<<zXZyZuvzvzzzOtttOwrrvrrt=lz<+zrtttOwuXZyyyffffffpfWZyZWpVXXyXwI;;;;;
````.~~~~~::;>>?=ltrvzuuuuuZZZZZZyyXXfI_~~~~~~~~~~~~~.~~~.~.~~~~~~.~~:<;<~+zllOrvzzuuZZyZyyyyyVVffpbbkkkkkkkkqqqqmmmqqbppppfZZZuwz(:<wuuuzzuuuzvvzzzzuuzvrrtzlllltttttrlwuzuZyyVfVfppppWkXXWWyyZXZz?>>>;
```...~~~~::;>>??=ltrvzzuuuZZZZZZZZyyWI___:~~~~~~~~~~~.~~~.~~~~~_~~~~~::~~~<1lztrvvzuuZuZZyyyyVVVffppkkkqkqqqqkqqmmmqqbWbppVyZuuvO<(;zuXuuzuuuZuzuuzuzuzrrrrrrttttrttrtrtzXzXZZZVVffffpppXWWVVZuuO=??>>>
```..~~~~::::;;???llttrvuuuuuuuZZZZyZyWw&+;<:~~~~~~~~~~~~~.~~~....~~~~::~~~~(1llttrzzuuuZZZyyyyVVffppbkkqkkkqkqkqqmmmqppfffyyZzzvr<<>zwwkuzuuuuZykuuzzwzvrrttrrttltttttttl=zXzuZZyyffpfppyWffWZurll=????
```...~~~~~:::;;>?=lltrrvzuuuZZZZZZZZyZyyk+;<_~~~~~~~~~~~~~..~..~~~~~~~~~~~~~:<1lltrvzuuuuZZyyyyVfffppbkkkkqkqqqqqqqqkbfppWyyZuvrO<;>dMMNmkuZuuuuWVXZz=lltrtrrrtlltlttlltl==zXzuZZyyVffffVfffyZurtl===??
````..~~~~~::::;>>?=lltrrvzuuuuZuZZZZZyZZyyyyk&-_~~~:~~~~~~~~~~~~~~~~~~~~~:~:~:~<1ztrrzzuuuuZZyyVVffppbbkkkqqqqqqqqqkbWXWpWyyZuXvO??+dMMNNNkuuvvwXVVOzllltttrtrttlllltzzI=11?1wuuZZyyVVffpffVZZZXttl==??
````...~~~~~:::;;>>?1llOrrvzuuuuZuZZZZZZyyyyyV0<<:::::::::~~~~~~~:~:::~::~~::::~~(1ztrrzzuuuZZZyyyfppppbkkkqqqqqqqqkkWWWZWWyyZuvvI>11dMM####NkwrrXfWwOtlttlOrtttlll==zzz??1z+uwkXuuZyyffpWpWyXWVXwOt====
``..` ..~~~~:::;;;>??==lltrvvzuuuZuuZZZZZZZyyyWAx+((((+++<_:~::::::::::_:~::~:::~_~?OltrwzuuuZyyyVVffppbbkkkkkqkqkqkkkXWyyVyVyuuwz?=zMHHHH####NHkkWWWmwOtrrrrrtll==llzzuwQWkkkbkkkZuZyVfpfWXXppVXuwrtlz=
````. .~~~~~~~:::;;;???=lOtrrvzuuuuuuZZZZZZZZZZZyZyyVpWWRo<;(::::;;;::::::~~~~::::~:_<1lOrvuuZZZyyyVfpppbbkkkkkqkqkkqHHVWf0Wfyuzvz1zdMHHHHHHHHHHHHHHHHHNmmmAAAAAQQAzudWmqkkkkkkkkHkkXyyVpWpbWppfyZurtlll
``````._~~~~~:::::;;>>??==llOrrzzuuuuuuuZZZZZZyZZyXyyVVfpko<>;;+++zz;:::::::::::::::::<1tOtrzuZZZyVVffpppbbkkkkkqkkqqkVyWpWWyyuzvvzXM@HHHHHHHHHHHH@HH@HH@@@@@@gggHgmgmqqqqqkkkqkkkkkkkkkbbbkbppfyZuzrrtl
`````.....~~~~~::::;;;>??=lltttrvvvzzuuuuZZZZZZZZZZyyyVVfpWkmmQWWI<_~::~::::::<++::<:_~:<1ttwvuuZZyVVffppppkkkkkkkqqbVffffbpfyZuwOdH@HH@H@HHHH@H@@H@@@@@@@@@@ggggggggmmmqqqqqqqkkkkkkqkkkkkkkbppyyZuvrrt
`````.``.~~~~~~~::::;;;>>>?=llttrrvvzzuuuuuuZZZZZZZZyyyyVfffpppbHH&<:::::::;;:<+<:;;;:::::<1ttwuuZZyyVffppppbbkkqkkkHffpfpbpWyXVXW@@@@@@@@@@@@@H@@@@H@@@@@@ggg@g@gg@gggmmmmmmqmmqqqqqqqqkkkkkbppVyuzvrrr
``````....~~~~~~~~~:::;;>>??==llttrrvvvzzuuuuuuZZZZZZyyyyVVVVffpbpbHA++<;;;;;;<:::::;:::~~~:<OOOwuZyyyyVVVfpppbkbkkkpfbffppfVWXuWH@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@g@ggggggggmgggmmmqqqqqqqkkkppVyZuzrvr
``.`````..~.~~~~~~:::::;;;>>??==llttrrrrrvzzzzuuuuZZZZZZyyyyyfffpppbbbHkWWkkkAy<::::::::::~:;;+1zOzuZZyyVVfffpppbbkkbfWpfVyVVXyXgHg@@@@@@@@gggg@@@@@@@@@@@@@g@ggg@g@g@@@@@g@ggggggmmmqqqqkqkkkppyZuuzzvr
````.`..`.__~~~~~~~~::::;;;;<???==llltttrrrvvvzuuuuuuZZZZZyyyVVVVfppppbbbkbbbbHC;;:;:::::::;;;>;;zuwXZZyyyVffffppbkkppWffpWyVXVWgHgggg@gggggmmmmmgggmmgggggggg@ggg@g@@g@@@@@g@gggggggmmqqqkkkbpfyZZuzzvr
`````````._...~~~~~:~::::;;;;>?????=llllttttrrvzvzzuuuuuZZZZyyyyVVfffppppppbbpkz+;;;;;;::;;:;;;;;?zOwzXXZZyyffpffbkppWWffyWWWpfW@gggggggmmmmqqqqqqqqqqqqqqqmggggggggggggg@gg@@@@@@gggggmmqqkkbbfyZZuzzrr
```````.```...~~~~:~~~:::::;;;;>>????=llllltttrrrvvvzuuuuuZZZZyyyyyVffffpppppppppko+<<;;;+>;;;><>>><1OwXuZyyVffffpbppWVyWfXZyyWHggggggmmqqqkqqkkqkkkqkkqkkqqqqqqqmmmmgggggg@g@gg@@@ggggmmqqqkbpfyyZuzvrr
````.``..`......~~~~~~~~:::::;;;;>>????=1llllttttrrrvvzuuuuuZZZZZyyyyVVVfffpppppffWkAzzz1?>>???>?=zXkkkwzuZyyfVfffppfffWWWpWXZWggggggmmqqkkkkkbbkbbbbbbbkbbbbkkkkqqqqqqqqmmmgmgggggggggmqqkkbpffyZuuzvrt
```.``````.``....._~~~~:~:::::;;;;>>>>???===llllttttrrrvzzuuzuuuZZyyyyyyVffffpppppppppbpppWmxzz+uuXHmmgHkuXZZyyVVWppWyfyXWfWVyWgggmmqqqqkkkkkbbppppppppfppfppppbbbbbkkkkkqkkkqkqqqqqqqqqkkkbppfVyZuzzvvr
``````.`````.`....._~~_~~~::~::::;;;;;>??????==llzltttrrrrvvzzuuuZZZZZyyyVVVffffppfpppppppbWkbkkkkkqqqmqqHkuZZXVVWpppyVVWkdVyfWmmmmmqqqkkkkbppppffffffVVVVfffffffppppppppbbbbbbbkkkkkkkkkbpppfVyyZuvvrrr
````.``.`.`.`.`.......~~~~~:::::::;;;;>>>>>???====lllltttrrrvvzzuuuuZZZyyyyVVVVVfVffffppppbbbkbkbbkkkqkqqqkHkZyyVVfpppfWWWWWyWWmmqqqkkkkbbbppffffVVyyVyyyyVyVyyVyyyVVVfffpfpfpppppppbbpppppfVyyyZuuvrttt
````````.```.``.``......~~~~~:::::::::;;;;>>>?????====llltttrrrvvzuuuuZuZZyyyyVVyyVVffpppppbbbbbkbbkkkkkkkqqqHWyyfffyfWXWWXZWWqqqqqkkkbppppffffVVVyyyyyyyZyyZyyZyZyZyyyyyVyyVVVVfffffffffVyyyyZZuzvrtttl
```.``.````.``.```..`....~~~~~~~:~~:::;;;;;;>>>>???===lllllttttrrrvzzuuuuZZZyyyyyyyVVfffpppppbbbbbkkkkkkkkkkkqkWWVffVfyZXVyyVWkqkkkkbbpppfffffVyyyyyyZZZZZZZuZZZuZuZZZZZZZyZZZyyyyyyyyyyyyZZZZuuzzrtttll
````.```.`.`..`...`.`......._~~~:<~:::~::;;;>;;>>>>???=?==llttttrrrrvzzuuuuZZZZyyyyyyVVfffppppppbbbkbkkkkkqqkkqkkWpfffyXZyXyfWqkkkkkkbppffffVVVyyyZZZZuuuuuuuuuuuuuuuuuuuuuuuuZuZZZZZZZZuuuuuuuzrrttllll
`````````.```.``.`..`..`......-~~~~~~~:::::;;;;;;;?>>????==llllttltrrrvzuuuuuZZZZZyyyyVVVffpppppbbbbbkkkkkkkqkqqkqHpfffWXXfffWqkkkkbppfffVVVVyZyZZZuuZuuuuuzzzzzuzzzzzzzuzzuuzuzzuzuuuuuzzuzzvrrtttll===
```.``.`.`.`.`.``..``..`...... ....~~~:::::::::;;;>>>>>>???=??==llttttrrrvzuuzuZZZZyyyyyVVVffpppbbbbbkkkkqkkkqqkqqqkHWfpWffpfWqkkkkbppfVVVyyyyZZZZuuuuuuzzzzvvvvvrvvrrrvvvvrrvvzvvvrrvvrvvvrrtttlll====?
```..``.``````..``..`.`.`.`.....___.~..~~~~:::;::;;;;>>>>>?????==lllltrtOrrwzzuuuuZZZZyyyyyfppppppbkkkkkkkqkqqkqqkqqqqHbbppbpkkkkbbppffVyyyyZZZZZuuuuzzzvzvvvrrrrrrrrrtrrtrrrrrrtrrrrtrrtttttlll====????
`.`````````.```..``..`...`.``.`........~~~~~~:::::::;;;;;>>?????=?===zttttrrrvvuuuuuZZZyyVyyVVppppbkkkkkkkkkqqqqkqqqqqqkqkkkkkkkkbpfVyZyyXXuuuuuuzzzzvrvvvrrrttrtttttttttttttttttttttttttllll===????=???
``.```.`.``.``.``.``.`.`..................~~~~::~:::::;;;;;>>?>>???====llttrrrrrvzzuuuZZZyyyyfffpppbbkkkkqqkqqqkqqqqqqqqqqqkkkkbbppyZZykwuzuzuXXzvvvrrvrrrrttttttltlltlllllllllllllll=ll======?>????????
```.```.`````.``.`.`..`.`.`.`.``.........~.~~~~~~~~::::;;;;;>;>>????=?==l=ltttrrrrvzuuuuuZZyyyVffpppbbkkkkkqqkqqmmmqmmmmqmqqkbbbbpVXXrtOtrOrrrtrrrrtrttttttttttllllllll=lll==ll====??=???????????>>>>>>>
`.```.``.``.``..``.`.`.....`..`..............~~_~~_~~~:~:::;;;;;;>>????===lllllttrrrvzzzuZuZyyyVVffppppbkkkkqqkqqqqqqmmmmqqkkbpffWZXOwvOlttOzrOOttllttlllllllllll============?=????????????>??>>>>>>>>>>
`..`.``.``.``.``.``.`.`...`....`.`.........~....~~~~~~~~::::;;;>;;>>>???>=?===ltltttrrvzuuuuuZZZyyVVVfppppbbbbkqkkkkkkkkkkkbbpfVyXzrtrOlttllllll=l=======l=====?===?????????>>>?>>>>>>>>?>>;;>;>>>>;>>>;
````.``.``.``.`.`....`.`..`..`....`.........~......~~~~~~~:~::::;;;;>>>?????===l=lttttrrvvzuuuuZZZyyyVVVffpppppbkkbbbbbbppppffVyyZuOtrttll=zl=======???????==??????>??>>>>>>>>>>;;>;;;;;;;;;;;;;;;;;;;;;
`````.``.`.`.`.`.``.`..`...`.`..``..`.........~..~..~~~~~~~~~::::;;;;;>>>?????====lllttttrrvvzuuuuZZZyyyyyVVffffpppppfppfffVVyyZZuurttlll=l=?======?==??????????>?>>>>>;>>;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
`..`.````.```.`.`.``.``.`..`..`....`.................~.~~~~~~::<<:;:;;:;>>>>?????===llltttrrrvvzuuuuuZZZZZyyyyyyyyyyyVyyyVyyyZZZuzzOttl=======?????????????>?>>>>>>;>>;;;;;;;;;;:;;;;;;:;;;;;;;;;;;;;;;;
````..`.``.`.```.`..`.`..``..`..`....`..............~....~~~~~~~~:::::<;;;;>>>????=====lltttttrrrrzzuuuuuZuZZZZZyZZyZyZZyZZZZZuuuzwtll====?=???????????>>?>>>>>>;>;;>;;;;:;;;;;:;;;;::::;:::;::;;:::::::
```````..``.`.`.``.`..`......``.`.....`.``..........~......~~~~~~_~::::;;;>>;>>>>????=====lltlttrtrrwzvzzuuuuuuZZZZZZZZuZZuuuuzXzvttz?===?????????>?>>?>>>>>;>>;;;;;;;;;;;;::;:;;::;:;;;:::::;::::;;::;;
.`..`.``.`.``..`.`.`.``.`.`..`...`.``...................~....~~~~~~~:~::::;;;;;>>???????====llllttttrrrrvrvvvzzuzzuuuuuuzuuuuzzzvrOz1??????>?>>>>>>>>>>>>>>;;;;;;;;;;:;;;;::::;:::::::::;::;::::;:::;::;
```..`.``.``.``.`.`.`..`.`.`...`.....`...`..`............~~...~~~_~~~~~:::::;;;;;>>>>>?????=====lltllttttrrrrvrvvvvvvvvzzzvrrvvrrOI=?????>?>>>>>>>>>>>;>>;>;;;;;;;:;;::;:::;;:::::;:;:::::::::::;:::::::
``````.``.`.`..`.`.`..`.....``..``.`..`....................~~.....~~~~~~~:::::;;;;;;;;>>?>???=?=====lllllttttrtrrtrrrrrrrrrrtttll=?????>>>>>>>>>>>;>;;;;;;;;;;;;;:;;:;;::;:::::::::::::::::::::::::::;::
`..`.``.``.`.``.`.`.`.`.``..`.`...`....................~.....~..~~.~~~~~~~~~::::::;;;;;>>>>>???????=====lzlltlllttttttrttttttl==??>??>>;>>;>;>>;>;;;;;;;;;;;;;;;;;;:::;:::::::::::::::::::::::::::::::::
.``..`..`..`..`.`.`..`.`..`..`.`....`.`..................~..~..~..~~.~.~~~~~~:::::::;;;;;>>;>>>>>???=?=======ll==llllttllll==???>>>>>;;;;;;;;;>;;;;;;;;;::;;::;:::;::::;::::::::::::::::::::::::::::::::
`.```.``.``.`..`.`.`.`..`..`...`.`..`..`..`................~..~..~~.~~~~~~~~~~~~~::::;;:;;;;;;;>>>>>>??>????=?==========l=????>>;;;;;;;;;;;;;;;;;;:;;;;;;::;:::::::::::::;::::::::::::::::::::::::::::::
``.`.`..`.`..`....`.`.`.``.`..`...`..`.................~....~..~.~..~.~.~~~~~~~~~~::::::::::;;:<;:;><>>>>?>>>>???>>?????>>>>;;;;;;;;:;;;;;::;:;;:;;::;:;;::;::;::;;;:::::::::::::::::::~::::::::::::::::
EOFEOD

    } else { # Holy shit, you ruined everything
print <<'EOF_SHUSI';
Holy sit, you ruined everything. Like everything you do
This sushi is like your life.
Begining a lot of things, left undone
And nobody loves you.

;::;::::;::::::::::::::::::::::::::::::~:::~:::::::::::~::~:~:::~::~::~:~~:~~~:~~~:~~~:~~~:~~~:~~~:~~~~~~:~~~~:~~~~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~::
;;;;;;;;;:;:;::;::;::::::::::::::::~::~::~::~:~~::~::~:::::::~::~:~::~::~:::::~::~~::~~::~~:~:~:~:~:~::~:~:~:~:~::~:~:~~:~:~~:~~:~~:~::~:~:~~:~~:~:~~:~~::~::~:~:~~~:~~~:~~~:~~~:~:~~:~~:~::~:~:~:~:~:~:
;;;;;;;;;;;;;;;;;;;;;:::::::::::::~::~::::~:::::~~:::::::~::::::::::~::::::~:::::::::::::::::::~:::::~::~:~:::~:~::~::::~:~::~::~::~:~::~::~:~::~:~::~::~~:~~:~:~::~::~:~::~::~:~:~::~::~:~::~::~::~:::~
???>>>>>>?>>>>>>;;::::::::::::::::::::::~:::~::~::~::::::;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
????????????>>>;;::::;;;;;<;+++>>;><;;;::::::~:::::~:::::;;;;;;;;;;;>;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;:;;;;;;;;;;;;:;;;;;;;;;;;;;;;;
;;<;;<;;;>>;;;;:;;;<++11zzzzzzOOOzzzzzz1+<;;::::~::~::~:::;;;::::::::;:::::::::::::::::::::::::::::::::;:;::;:::;:::::::;:;::;::;:::::::::;:;;;:;;:;:;:;:;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;>>;>>
~~~~~::::::;;;<++1zzzwwvrwwOOOOOOOOOrvwOOzzz+>;:::~::~::::::::~~~~~~~~~~~~~~~~~~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<~
~~~~~:::::;;++zzOwvwZOv11<<<<<<<<<<<+1zOwzwwOzz+<;:::~:~~:~~~~~~~..............~~~~~~~~...~......................................................................................~...~...~....~...~....~
~~::::::;;+1zwwXZOz1<<<<:::::::::::::;<<1zOXuwOzz+<<:::::~::::~~~~....``.``...~~~.~.~..~.~~~....`.`.`.``.`.``.`.`.`..`.`.``.``.``.`..`..`..`.`.`..`.`..`.`..`..`..`.....................................
:::::::;+1zwwZOz<<<:::::::::::::::::::::<<+1OwXXwOzz+<::::~::~::~:~~~...`.._~..~~~.~~~.~~~.~~~._.`.`.`..`.`..`.`.`.``.`.`..`.`.`.```.``.``.``.`.``.`.``.`.``.``.``.`````````.``.````.``````.```.`````.``
::::::;+zOwXOz<<:::::::::::::::::::::::::::<<+zOwzwOzzz+<;:::~:~:~:~~~~~..~~~~~~.~~~~.~~~.~.~~~..--..``.``.``.``.``.``.``.``.``.`.`.``.``.`.`.``.``.````.``.``.``.``.`..`.`.``.``.`.``.`..``..``..`.``.`
:::::;+zOwVIz<:::::::::::::::::~::~:::::::::::<<+zOXzwOzz1<<::::~:~:~~~~~~~~.~~~~~~.~~.~~~~~..~~.~~~_.``.``.``.``.`.`.``.``.`.```.``.`.`.```.`.``.``..`.``.`.``.``.``.``.`.`.`.`.`.``.`.``.`.`.`.`.`..`.
:::::;?zwXOz<:::::::::::::::::::::::~::~:~:::::::<<1zwXwwOzz+<<::::~::~~~~~.~~~~~~~~~~~~~~.~~~.~.~...`.``.``.``..```.`.`.`.``.`.``.``.``.`.``.``.````````.```.``.``.`````````.```.``.```.`.``.```.``.``.
:::::;1Ouwv>;::::::::::::::::~:::~::::::::~:~:~::::<<+zOXuwwOzz+<::~~~~~~~~~~.....~~~~~~~~~~~.~.~...`.`..`.... .  .. ``.``.```.`.``.``.``.`````.``.``.``.````````.``.`.`.``.``.`.```.`.``.``.``.`.``.`.`
:::::;+zwXOz;;::::::::::::~::::::::::~:::::::~::~::~::<<+zOXzwOzz<:~~~~~~~~~~.~~....~.~~..~.~~.~.~~.`.`` ..~.~.~~.~~...``.`.`.``.```.`.``.`..````.``.``.``.`.`.````````.``.``.````.``.`.``.``.`.``..``.`
:::::::+zOrOz>;;:::::::::::::::~::~:::~::~:::::~::~::::::<<1OXVI<<~~~~~~~~~~~~~~~~.~...~.~.~.~.~....... .~~.~.~.~.._.``..``.``.``..``.``.``.``.````.```````.```.`.`.`````.````.``.``.```.`.`.`.`.```.``.
::::::::<+1zlz+>;;:::::~:::~:::::::::::~::~~::~:::::~:~~::::<<<<~~~~~~~:~~~~~~..~~~~~~~.~.~.~.~.~......~.~.~~~~~~..``.``..``.``.``.`.``.`.````.`.```.`.`.````.````.`.`.```.``.``.````.``.``.```.````.`.`
::::::::::<<+1=zz+;;::::::::::::~::~::::~::::~::~::~::~::~::~:~~~~~~~:~~~~~~~.~~~~~~~~~...~.~.~.~.~~~.~.~~.~~.~~~~...`.-.~_.`.``.``.`.``.`.`.````.`````.``.```.``````.`.```.`````.``.``.````.````..``.``
:::::::::::::<<1=lz+>;::::::~::::::::~:::::::::::~::~:::~~~_~~~~~:::~~~~~~~~~~~~.~~~~.~~~~.~.~~~~~...~~.~.~~~~.~~.~.~-_~~.......``.``.`.```.`.`.``.`.````.``.``.`.``````.```.`.```.``````..``..`````.``.
:::::::::::::::<<+1lzz>;:::::::::~::~::~:~:~:~::~:::~::~:~~~~~~~~~~~~~~~~~~....~.~~.~~.~..~.~~.~~.~....~.~.~.~.~.~._.~~~~.~...~._..```.`.`.``.``.`.``.``.``.````.`.`.``.``.````.```.`.``.```.``..`.`.`.`
:::::::::::::::::<<+1zz1<;;::::~::::::::::::~::~::~::~:~:~:~~~~~~~~~~~~~~~~~~~~~~.~~~.~_-.~~~..~~.~~~~~.~.~.~~~... -~~~~~.~~.~.~..`.`.```.``.`.``.`.`.`.`````.`````.``.````.``.``.````.``.``.````.```.``
::::::::~::~::::::::<+1zlz+;;::::::~::~:::~::::::~::~:::~~~~~~~~~~~~~~~~~~.~~.~.~.~~_...~~~.~.~.~~.~...~.~~.~.~~~..~~.~~~..~~.~._``.``.`.``.``.`.```.```.`.``.`.`````.``.```.```.``.```.``.``.``.```.``.
;::::::::::::~::::::::<<1zlz1<;::::::::~:::~:~:~:::::~~::~~~~:~~~~~~~....~~.~~.~~...~~~~~~~.~~~~~~~~.~~.~~.~...~.~..~~..~~...........--..`.`.``.``.``.`.``.```.`..``.````.```.````.``.``.``.``.``.`.``.`
>>;::::~::::::::~::::::::<+zlzz+;:::::::::~:::~::~:~::~~::~::~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..~..~~~~~~~.~~~~~~~.~~.~~~~.~~~~.~....~.~.~~._-..``.``.`.``.``.`````.```.```.```.``.``.`.``.``.``.``.``.``
z1+>;:::::::~::::::~:::::::<<1zOz+>;::::::::::::::~::::::::~~~~~::~~~~~~~~~~~~.~~_~_~~~~~~~.~~~.~~..~~~~~~~~.~~~~~~.~.~..~...~~.~.~.......~~~...- ```.``.``.`.`.``.``.`.`.``.``.```.```.``.``.``.``.``..
XOzz+>;::::::::::::::::~:::~:<<1zlz1>;;::::::~:((:::::::~~~~~~::~~~:~:~~~____~~~~~~~~~~..~.~~_.~~~.~~~~~.~~~.~~..~.~~..~~.~~~..~.~~.~~~-.._~.~_-~_``.``.``.```.`.``.``.```.``.``.```.```.``.`.``.`.`.```
WXXOzz+>;:::::::::~:::::~:::::::<<<+??>>;;;><>>;;::::::::::::::::::;::::::~:~~~~~~~~~~~~~~~~.~~~.~~~~.~~~~~~~_~~~~_~.~~~~~.~.~~~.~..~~._-.~.~.~_._.``.``.``.`````.``.``.``.``.``.`.``.``.`.`.`.`.``.`..`
UWWXXwOz+>;::::::~:::~:::::::~:::::::<<:::<<<;;<;:::~:~:::::~~::::::::::~~:~::~~~~~~~~~_~~~.~~~.~~~~._~~~~~~~~~~_~~~~~~_-~_~~.~..~~....~.~~..~.._``.``.``.``..`.`.`.`.``.``.``.``.`.``..``.``.``.``.``.`
1OUWWXXwOz+<;::::::::::::::~::~::~::~::::~:::::~(<;;:_::::~:~:~~:::::::~::~::~:::~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~_~~~~~~~~.~~`_~.~.~_ ~..__~~~_...`.`.``.`.``.```.`.``.``.``.`.`.``.`.```.``.`.``..`.`.`.
:<1OUWWXXwOz1<;:::::::::::~::::~::~:::::~::~~:::<>;;;;::_::~::::~::::(;<:::::::~::~_~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.~~.~~~~.~~~~~~~~~.~.~~``.```.``.`.``.`.``.``..``.``.``.``.``..``..`.`.``.``.```
:;;>zwUUXXzwOzz+++++++<<+<<+++++++++++z+<::::~~::::<;;;_::::::::::(+>>+?+;;<::::::~~~_~~~~__~~_~~~~~~~~~:~~~~~~~~~:~~_~_~~_~~___~~~~~~~~~~__-_~_`.``.`.``.``.`.``.`.```.`.`.`.``.``.``..``.``.`.``.`..`.
zzzwwuuuwwuuuuuuuuzwlOOzwzzrtOOOz1lttlllz<;<:::::::<<>;;;;;;;;;>>??????=?>;;:::;;;::~~__~~~~~~~~~~~~~~_::~~~~~~~~~~:~__~~~~~~~_~~_~~.~~~~~~~~~~_.`.`.``.``.``.``.``..`.`.``.``.`..`.`.``.``.`.`..`.`.``.
wwuuZZZyyyyyyyZZZZZZXwlOXuwvrzzz+zwuzvOtl=??<::::::+?>>>>>>>?????==ll====1?><:::;;:~::(<_:~~~~~~~~~~~_::_~~::~:~~~~~::::::~~~~~__~_~~~~.~~~~~~~~_``.`.``.``.``.`.````.``.``.`.````.`.`.`..`.``.``.`.`.``
ZyyyVyVyVyyyVffyZXXZXwwwwXXXwZuuXZuuuuzvOtllz<::::::;>>>????=zzzl=llllll=l==?????<_:((;;;;<_:~~~~_::~~~_<;::::<~::~~~~~~.~~~_~~~~~~~~~~~~~~___~~_`.``.`.`.`.`.``.`..``.``.``.`..`.```.```.``.`.``.```.``
yVVVVVyyyVyVVVVVyVVyVVVVVVyyyZuZZZuuuzuzvrOllz::::;;;>>>???=zwXOlllllllllll======?>>>;<<~~~:~~~~<:~~~~~~~:~:__~:~~~~~~~~~~~~_~~_::~~:~~~~~~~~~~~_.``.`.```.``.`.``.`.`.`.`.``.``.`..`.`.``..`.`..`.`.`.`
VffVVVVVVffVVVVVyyVyyyyyyyyZZXXXuuwrvzZOOOOttz<;;;;>?>???==ltwXll=lllltttttll====z?1?><:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_~~~~~_~~~_~:::~~~~~~::~~~_..``.`.`.``.``.``.``.```.`.``.``.``.`.`.`.``.``.``.`.`.
VVVfVyVffpfWXVVVVVVVyyyyXuuzvOOwuwrOwuuzwtOzttz??????===llltrXXOllllltttttrtllllll?=??><_::~~~~~~~:~~:~~:~~~~~~~~~_~~~~~~~~~~~~~~~~~_~~~~~~:::::~__-.`.`.`.`.`.`.``.``.`.``.`.`.`.``.``.`.``.`.``.`.``.`
fffffffVfffffVVVVVyyZXwuuuZZuwwuZuXI1OXuwwwrttz????===llltttrXWkXwOtttttttrttttlll=?=?>><;;;<((::::::~:~~:_:~:~:~~~~__~~~~~~~~~~~~~~__~~~~~~:::::~~:__-.`.`.```.`.``.``.``.`.``.``..`.``.`..`.`..`.`.`..
VVVffpfyWWfffVVyyyyuuuXyZZXuuzzuyZXXwXzuuuwwrrtz===llllzzzrrrzXH@Klttttttrzvrrrttl===???>;;;;<<~~~~~~~:::~~::_:::::~::_~:::~:~~~~~~(__~~~__~:~:~~:::~:~__..``..``.`.`.`.`.``.`.`.`.``..``.``.``.``.``.``
yyyVffffffVyWZyyyyyXuXyffVVVXZZXyyVXuuuZZuZuzvrI==llltl=??1zOlOZUStttttttwuuwvvzrOO=l==???<;;:::::~~::::~:_::__:::::::_<<:~:::~::~~:_~~_::::::::::~::~::~~__..``.`.``.``.`.``.`.`.``.``.`.``.`.``.`..`..
yyyyyyVyyWZZXyuXXVyyZ0XXyWWWWVVyVVXXyyyyyyZZZuOz??===l===???=l==llllttttrwyyZZuXvrrtlll==1?+><:~~:__~:::<:::::<:(;;<::::::_::_:::::~:_:::::::::~:~::~:::::::~__..``.``.`.`..`.``.`.`.`.`.`..`.`..`.`..``
ZZZyyyZyZZyVyyyffVVVVyyyyWZZXXXXWffVffpffVyyZuZz????===ll=====llllllttttrXXyZZZvrvvvrrtll===1?<:~::~:(:~:~::::::((<<<;:;::::~:::::::(;:;;::;;:::~::~::~::::::::~__..`.`.`.``.`.``.`.`.``.``.``.`.`.``..`
yyyyyZZZXZZZXwyUXXXuZZUXuOOOXWXwXXXVppppfffWZZwl===llttrOllllltttttttttttrrXZZyXwzzzrtttlllzttz+((:<<<:::::<;;<<;;:<?+;;;:;<(;;;;;;;>;>>;;;;;;::::~::::~:~~::~:::::__..``.``.`..``.``.`.`.``..`.`.`.`.`.
OwVyyyZZZZuZZkOOOwwXXkwwwzXXWpppppHUXWWppffVVyXOlllllltrvOOltttrvvZOlltllttwWVVyXXuuwtttttttOOlllz=???????===?=?<<<??>><>;>>>;;;;;;>>;>>>;;;;;:<<::~:~:::::~:::::::::___...``.``..`.``.`.`..``.`.`...`..
XyyVyyZXyZzZlOzzwXXuXVXOzztwXVWUUUXOwZwwXWfWWfkwOtllttrrrvvvrrrrvOlllltllttdWWWWWyWXyXwrtrOztl===l=====z=??=====??????>>>??>?+1+>>>>>>>>>>>>;;:+>:::::~:::::::~:~:::::::__-..``.``.`.`.``.`.`..`.``.`.``
yyXkXySuVXwXXyyyWWfWUZZZZZZZyyWkwwwVOlzXffpVfbWykllltttrrvzzrrrrttllltttttOXWHHHHHHppppfWzvwOttll=lll==1?==zltllzzzz??==?+?>?1==1?++>>>>>>>>;;+z><:~::::~::~:~:::::::::(<;<_`.`.`.`.`.`.`.``.``.`..`.`..
yyyZXXkwXUXyyWZ0VXZXZX0uZZZZZZXXXZXI1zzXfVWWWHHkkOtllltrrrrvvwwwwttttrrrrtwXVfWHH@MHppWXuuzvrrtttllllllzttlll=llllt=======zz==lll===??>>??>>;;+O?<::::::::::::::::::(<<>?1z~``.`.`.``.``...`..`.`.`.`.`.
yZyZZyWyyyyZyAwksZXXXXXuuuZZZXZZXXOzl?1OXyXXHM@@HkwtlllltrrrvvzXuwOrOzrrrvzXWVVffHMMMHHkuuuzrtttrtttllttrrtttllllltll======lllzll=lz???1??>>>>j0?>:::::::~::::::::(<;>?zzlz_`.`.``.`.`.``.``.`.`.`.`..`.
uvwZyZXykXXXZyyXUyyVyyXuuZZyyyVfWwOwZOzOwyWHH#HHMHkkOlllllttrrrrvvzuuXwwzzzuuyVVfVVWHMMMkXuurrrttrttttttttttttttllllll====l==llllllllll==????1XIz;;::::::::::::<<;>?1zlttl>_.`.`.``.`..`.`..`.`..`..`...
ZZUUruVC1zXzdywZZzZX0XuZZZZyyVVyyWXZOwzOzXVvVMM#HMHHkkOlllltrtrrrrvvuXXXWyyyyyyyyyyyyWHMHNkXZXwwrrrrOtttttrrtttttOlllllllz===llllllttlll===zzdkI>;;;;::::::::<;>>?zltltlll>_`.`.`..`.``.`.``.`.``.`.`.`.
ZyWyyXXyXWWXwyZZXy0wuuuuZyVyVyUWyyyZXXXrwrvv?1ZMM#MHHWWXOttllOOOtOOOOtrrvXuXXUXuuXXZZyyWWMMMHkXyXXwvvvzOrrtrrrrtrtrrtttttllttttllllttltllzzwdHI<;;;;;:::::++>>+1ztttlttlll<_.`.`.`.`..`..`..`..`...`....
XUWUWyZZyyXXyZZXUXXwuuwXyyyVyykuXUZZwuzzvvOz>>><OWMHHHHWXXOl==??????===zllOOrrvvvzzuzuuuuXWHMMHHWfyWwzzwvrrrrrrrrrrrrrrttrtrrrttttOwrrrwQkWHBI<>>;;::::(<>>+1zlttttltlltll<.`.`.`.`..`.``.`..`.........`
ZZZyZyXVXyyXXXwOwZuXywZZZZZyyyyyksXXzuurrv<;;;:::<zWMHHHWWXXOz??>>>>?????===lllttrrvvzzzuuuuUHMMHWXXyyVWkXXuXkwwrrrrrrrrwzzzzzvrrrwZZyXWHgHSz>>>;;;::<>>+1zlltttllltltlllz<.`....`..`.`...``..`.`.`.`...
uuXWZZyyyyyXXWyyyXZuXuuuuZZyWVyyXZuvuXvO1?>;;:;;;;:;1TM@HHWWXXOz=?>>>>>>>?????==lltttrrvzzuuuuXWHkkyyyyyVVVfWWyyZyXXXXXZyyVyXXXXXXyyWWHgHSI?>?>;;;;<>++1zlltlttltttltllllz<..`.`...`...`.......`........
yZZXXXXZyZyyVyyZZuXOrwuZXyyZ0UUuZuZuXvI??;::;;:::;;::<+XHgHkWWXXOz=?>>>>>>>????==lllttrrvvvzzzzzuUWyyyyyyVVVyyyZZyyyyyyyZZyZXVVVVWWHHH961???>>;;+>>+=zltlttttltlltlllllllz~.`...`.`..`..`..`............
XwZZXXzzwdyZuZXwuZuuXuwXUXyZwzwXXOOOrrz>>>;;;;;;;:;;;:;;<vHmqbWWXXOz=?+>>>>>>?????=1lOttrrvvrzuzuuzuXUyyVVffXZZuuZZZZZZyZXXWWkWHHHH9Vz==???>;><>+=zzlttltttltttlltlllllllz~..``.`.`...`...`..`......`...
XGsXXZyyuXXVXXwXuXXuuuXG+ZXZuuZXOzwvOI1>;::;::::;;:::;;:::<vWqkbWWXXOz???>>>>>????====lllttrvvvvvzvzuXzzXXUWyXXXXXkkWkkHHgHHHH9UZtlll==1?>>>??+=lltltttttlttlllllllllllllz~........`....................
wwzwOuXXVXuXuwOzxzwZVXuZZZuzuuZZZuVI<>;>;;;;;;;;;;;;;;;;<:::<vWqkbWWXXwz=?1>>>>>????===llttttrvrrzzvvvzzzzzuzuzXUXUXyWXZXUXzzOtttll=??>>+??11lltttttlttlltlltllllllltllll<_.`..`.......`..........`.....
ykrvwXC4GOvOXuuXwwwwZXuZXnwOwZZZ0I<;;;;:::;;:::;::::<;:::;;;::<vWqkbpWyXwz===?>?????==lllltttrrvvvvvvvvzvvzvvvvzzzzvvvwrrrOtttlll=??>++??1llllttltttltlttllllltllllllllll<......`..............`........
yWUXXOVXXXXXwZXXZXZXwOvwZXwuuZXVz=?;;;;;<;;;>;;;;;;;;;<<<;;;<<;<<zWkkbpWWXXOl==?>>+???=zllltrtrrrrvrvvvvvvvvvvvvvrrrtttttlzllz==<??+=?1zllttttttttlttlllltllltllllllltttO<_........`......`.............
n(dwXdoJVUWVWkXXuZXwZXwJOuuuuzZI<;::;;:::;;:::;;:::;;:::;;;::;;;:;<zWHkbpWWZXO==?>><?????===lllttrrrvrrrvvrvvvrrrrttttllll===?+????1zlltlttllttltlttlltllltltlllltttOwwO1<_.............................
wvTVwVXXZZXZyI(zVXZZZXZZuuuzvOlz<<;;;;;;;;;;<<;;>;<;;<(<<;;;(:;;;<(;<?THkkpfWXXz==+>>>????====lltttrtrrrrrrrrtttttttlltl===z1??z=zlltttttlltltlttllllttlllllllltttwzZO===<~.............................
SwXZrVZXZwXfVyWXXwwwuZXwXuzzrOz<;::;;;::;;;::;;:::;:;::;:::;;:;::<;:;:<1THqkbWWXwz=<>>???????1=1=lllOOOOvOOOIlOzz===l=1=1<++z=1lltttttltlllttllltlllltlllltllltOwuZI=====<_.............................
XX000uwXXZXXWfWXWZXOwuuuuXzrtt1<<(;;;<<<;(<<<;;;<_;<;;:<;<<:;;;;:::;;::;<1THqkbWykz?<;>;>>>>><>>?+>?<??<?<>>><<<<<<>><;<<1==zlttltttlttlttlltlttlltllllllltttwwXOO==l=z<<_....`....................~....
XXX0udXZZyZZXuXWVyyZXwwuzvrOl<<;:<;;:::;;;::;;;::;:;;:;;;;;;::;;;;:;;;;:;;<zWgqHWWk??;:<;;;:;;;;;<<;;;;<;;;;;;;;;;;<:<+?+1zlttttttttlltltltttlltlttlllllttOwu0Ol==l=z<~_..................~..~.~.~...~..
WXXXdU0ZXuuXX0OOwZXZZuXjOrrttz<<_<;<<;<;;<((;;<:<<;;::_;:<:(;;:::<;;::(;:::<?dggqHkz?<;<:::::::;:<(;::;;:;;;;:;:::<<???+ztttttttlttttttlltlllttlllllllttww0VIl===z<<~..................~...~..~....~..~.
XyWkXXXX0XukuZkwOOVXuuzzzOtllz<;;:;<<;;<;<<;;;;;;:;;<;:;;<;;;;<<;:;;;;;:;;<:<>dM@HHS><::;<:;:;;;;::;::;:;;::;::;<++?1zttttttttlttlttllttlltltlltlllttOwXUOlll=lz<<_.................~.~..~..~....~..~...
WWWVXXXz4uuuuuuXNNkkfWyXrtlOz>;:<;;;::;;:<~;<:::<;;<:<;;:::;;:::(;;:::;;:<:;(>+MH@HK><::(;(;::;:;;:;::;:;;:<<;++??zzttltttttttlttlltltltttltlllllttwwXVOll=l=z<~.................~......~....~.~~..~..~~
WHkXW0dX&ZXOOwuuMMMMHWfWZ<<;;<;;;;;<;;:<<<;;;;<;;;;<<;;;;<;;;>><<<;;<<;;;<<<:>?d#H@b><;;::;:;<::::;;;;::::;++??1ztttttttttlltlttlttltttltltlttttOwXUZIllllz<<~...~...........~..~..~.~.~..~.~....~..~..~

EOF_SHUSI
    }

}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::HowToMakeSushi - It's making sushi.

=head1 SYNOPSIS

    use Acme::HowToMakeSushi;

If it is that exit code is 0, you can make sushi


=head1 DESCRIPTION

Acme::HowToMakeSushi is making shusi module.
So, Most programer is like sushi.
programer is like programing.
Make sushi after programming.

https://twitter.com/molgh/status/726854917214879744

=head1 LICENSE

Copyright (C) AnaTofuZ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

AnaTofuZ E<lt>e155730@ie.u-ryukyu.ac.jpE<gt>

=cut
