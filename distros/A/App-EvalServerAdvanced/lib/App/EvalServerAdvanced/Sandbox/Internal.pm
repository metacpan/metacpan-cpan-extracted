package App::EvalServerAdvanced::Sandbox::Internal;

use strict;
use warnings;

use Data::Dumper;
use B::Deparse;
use Perl::Tidy;

# Easter eggs
# Just a bad joke from family guy, use this module and it'll just die on you
do {package 
Tony::Robbins; sub import {die "Tony Robbins hungry: https://www.youtube.com/watch?v=GZXp7r_PP-w\n"}; $INC{"Tony/Robbins.pm"}=1};

# This started out as a bad babylon 5 joke
do {
    package 
    Zathras; 
    our $AUTOLOAD; 
    use overload '""' => sub {
        my $data = @{$_[0]{args}}? qq{$_[0]{data}(}.join(', ', map {"".$_} @{$_[0]{args}}).qq{)} : qq{$_[0]{data}};
        my $old = $_[0]{old};

        my ($pack, undef, undef, $meth) = caller(1);

        if ($pack eq 'Zathras' && $meth ne 'Zahtras::dd_freeze') {
            if (ref($old) ne 'Zathras') {
                return "Zathras->$data";
            } else {
                return "${old}->$data";
            }
        } else {
           $old = "" if (!ref($old));
           return "$old->$data"
        }
      };
    sub AUTOLOAD {$AUTOLOAD=~s/.*:://; bless {data=>$AUTOLOAD, args => \@_, old => shift}}
    sub DESTROY {}; # keep it from recursing
    sub dd_freeze {$_[0]=\($_[0]."")}
    sub can {my ($self, $meth) = @_; return sub{$self->$meth(@_)}}
    };

sub deparse_perl_code {
    my( $class, $lang, $code ) = @_;
    my $sub;
    {
        no strict; no warnings; no charnames;
        $sub = eval "use $]; package botdeparse; sub{ $code\n }; use namespace::autoclean;";
    }
    if( $@ ) { die $@ }

    my %methods = (map {$_ => botdeparse->can($_)} grep {botdeparse->can($_)} keys {%botdeparse::}->%*);

    my $dp = B::Deparse->new("-p", "-q", "-x7", "-d");
    local *B::Deparse::declare_hints = sub { '' };
    my @out;

    my $clean_out = sub {
        my $ret = shift;
        $ret =~ s/\{//;
        $ret =~ s/package (?:\w+(?:::)?)+;//;
        $ret =~ s/no warnings;//;
        $ret =~ s/\s+/ /g;
        $ret =~ s/\s*\}\s*$//;
        $ret =~ s/no feature ':all';//;
        $ret =~ s/use feature [^;]+;//;
        $ret =~ s/^\(\)//g;
        $ret =~ s/^\s+|\s+$//g;
        return $ret;
    };

    for my $sub (grep {!/^(can|DOES|isa)$/} keys %methods) {
        my $ret = $clean_out->($dp->coderef2text($methods{$sub}));

        push @out, "sub $sub {$ret} ";
    }

    my $ret = $dp->coderef2text($sub);
    $ret = $clean_out->($ret);
    push @out, $ret;

    my $fullout = join(' ', @out);

    my $hide = do {package hiderr; sub print{}; bless {}}; 
    my $tidy_out="";
    eval {
        my $foo = "$fullout";
        Perl::Tidy::perltidy(source => \$foo, destination => \$tidy_out, errorfile => $hide, logfile => $hide);
    };

    $tidy_out = $fullout if ($@);

    print STDOUT $tidy_out;
}

#-----------------------------------------------------------------------------
# Evaluate the actual code
#-----------------------------------------------------------------------------
sub run_perl {
    my( $class, $lang, $code ) = @_;

    my $outbuffer = "";
    open(my $stdh, ">", \$outbuffer);
    select($stdh);
    $|++;

    local $@;
    local @INC = map {s|/home/ryan||r} @INC;
#        local $$=24601;
    close STDIN;
    my $stdin = q{Biqsip bo'degh cha'par hu jev lev lir loghqam lotlhmoq nay' petaq qaryoq qeylis qul tuq qaq roswi' say'qu'moh tangqa' targh tiq 'ab. Chegh chevwi' tlhoy' da'vi' ghet ghuy'cha' jaghla' mevyap mu'qad ves naq pach qew qul tuq rach tagh tal tey'. Denibya' dugh ghaytanha' homwi' huchqed mara marwi' namtun qevas qay' tiqnagh lemdu' veqlargh 'em 'e'mam 'orghenya' rojmab. Baqa' chuy da'nal dilyum ghitlhwi' ghubdaq ghuy' hong boq chuydah hutvagh jorneb law' mil nadqa'ghach pujwi' qa'ri' ting toq yem yur yuvtlhe' 'e'mamnal 'iqnah qad 'orghenya' rojmab 'orghengan. Beb biqsip 'ugh denibya' ghal ghobchuq lodni'pu' ghochwi' huh jij lol nanwi' ngech pujwi' qawhaq qeng qo'qad qovpatlh ron ros say'qu'moh soq tugh tlhej tlhot verengan ha'dibah waqboch 'er'in 'irneh.
    Cha'par denib qatlh denibya' ghiq jim megh'an nahjej naq nay' podmoh qanwi' qevas qin rilwi' ros sila' tey'lod tus vad vay' vem'eq yas cha'dich 'entepray' 'irnehnal 'urwi'. Baqa' be'joy' bi'res chegh chob'a' dah hos chohwi' piq pivlob qa'ri' qa'rol qewwi' qo'qad qi'tu' qu'vatlh say'qu'moh sa'hut sosbor'a' tlhach mu'mey vid'ir yas cha'dich yergho. Chegh denibya'ngan jajvam jij jim lev lo'lahbe'ghach ngun nguq pa' beb pivlob pujwi' qab qid sosbor'a' tlhepqe' tlhov va 'o'megh 'ud haqtaj. Bor cha'nas denibya' qatlh duran lung dir ghogh habli' homwi' hoq je' notqa' pegh per pitlh qarghan qawhaq qen red tey'lod valqis vid'ir wab yer yintagh 'edjen. Bi'rel tlharghduj cheb ghal lorlod ne' ngij pipyus pivlob qutluch red sila' tuqnigh.
    Chob'a' choq chuq'a' dol jev jij lev marwi' mojaq ngij ngugh pujmoh puqni'be' qaywi' qirq qi'yah qum taq tey'be' tlhup valqis 'edsehcha. Chadvay' cha'par ghal je' lir lolchu' lursa' maqmigh ngun per qen qevas quv bey' soq targh tiq tlhot veqlargh wen. Baqa' chuq'a' jev juch logh lol lor mistaq nahjej nuh bey' nguq pujmoh qovpatlh ron tahqeq tuy' vithay' yo'seh yahniv yuqjijdivi' 'em 'orghenya'ngan. Beb cheb chob da'nal da'vi' ghoti' ghuy'cha' hoq loghqam ngav po ha'dibah qen qo'qad qid ril siq tuy' tlhoy' sas vinpu' wab yuqjijqa' 'em 'o'megh. Bachha' biq boqha''egh cheb dor duran lung dir ghang hos chohwi' je' luh mu'qad ves nav habli' qab qan rach siqwi' tennus tepqengwi' tuqnigh tlhoy' sas va vin yeq yuqjijdivi' 'ab 'edjen 'iqnah 'ud'a' 'urwi'.
    Baqa' bi'res boq'egh da'vi' dol dor ghet ghetwi' ghogh habli' hos chohwi' nga'chuq petaq pirmus puqni' qutluch qaj qid qi'tu' qongdaqdaq siq tahqeq ti'ang toq tlhup yatqap yer 'ur. Biqsip 'ugh chang'eng choq choq hutvagh jajlo' qa' jer nanwi' nav habli' pirmus qab qa'meh vittlhegh qa'ri' sen siv vem'eq yer yo'seh yahniv yuqjijdivi' 'arlogh 'e'mamnal 'och. Chang'eng chas cha'dich choq lursa' mil natlh nay' puqni'be' qeng qid qulpa' ret sa'hut viq wen yiq yuqjijdivi' yu'egh 'edsehcha 'entepray' 'er'in 'ev 'irneh 'iw 'ip ghomey 'orwi' 'ud haqtaj 'usgheb. Chadvay' gheb lol lorbe' lursa' pivlob qep'it sen senwi' rilwi' je tajvaj wogh. Chevwi' tlhoy' huh lol lorbe' neslo' ne' pipyus qaq qi'yah tal 'ev.
    Biqsip biqsip 'ugh chan ghitlh lursa' nuh bey' ngun petaq qeng soj tlhej waqboch 'ab 'entepray' 'e'mam. Bo denibya' ghetwi' ghochwi' ghuy' ghuy'cha' holqed huh jaj je' matlh pegh petaq qawhaq qa'meh qay' tagh tey' wogh yer yu'egh 'orghen 'urwi'. Boq'egh choq dav jim laq nga'chuq ngoqde' ngusdi' qan qu'vatlh sen tijwi'ghom ti'ang wogh 'orghenya'ngan. Biq cha'nas chegh chob dilyum ghetwi' juch me'nal motlh po ha'dibah puqni'lod qab qarghan qaywi' qaj rutlh say'qu'moh todsah tus yas wa'dich 'aqtu' 'edjen 'e'nal 'orwi'. Bor chob jaghla' je' jorneb mellota' meqba' nguq rachwi' ron tey' tiqnagh lemdu' vay' 'usgheb. Bis'ub cheb chob'a' dugh homwi' lotlhmoq mu'qad ves nahjej nanwi' naw' nitebha' ngoqde' ngusdi' pach pujmoh puqni'lod qan qay' rech senwi' tangqa' tepqengwi' tlhej tlhot valqis waqboch 'aqtu' 'e'mam 'iqnah 'orghen rojmab.};
    open(STDIN, "<", \$stdin);

    local $_;

    my $ret;
    {
        no strict; no warnings; package main;
        do {
            local $/="\n";
            local $\;
            local $,;
            if ($] >= 5.026) {
                $code = "use $]; use feature qw/postderef refaliasing lexical_subs postderef_qq signatures/; use experimental 'declared_refs';\n#line 1 \"(IRC)\"\n$code";
            } else {
                $code = "use $]; use feature qw/postderef refaliasing lexical_subs postderef_qq signatures/;\n#line 1 \"(IRC)\"\n$code";
            }
            $ret = eval $code;
        }
    }
    select STDOUT;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Freezer = "dd_freeze";

    my $out = ref($ret) ? Dumper( $ret ) : "" . $ret;

    print $out unless $outbuffer;
    print $outbuffer;

    if( $@ ) { print "ERROR: $@" }
}

sub perl_wrap {
    my ($class, $lang, $code) = @_;
    my $qcode = quotemeta $code;

    my $wrapper = 'use Data::Dumper; 
    
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Quotekeys = 0;
		local $Data::Dumper::Indent = 0;
		local $Data::Dumper::Useqq = 1;

    my $val = eval "#line 1 \"(IRC)\"\n'.$qcode.'";

    if ($@) {
      print $@;
    } else {
      $val = ref($val) ? Dumper ($val) : "".$val;
      print " ",$val;
    }
    ';
    return $wrapper;
}

1;