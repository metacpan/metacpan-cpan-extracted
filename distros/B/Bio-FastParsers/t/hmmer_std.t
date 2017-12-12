#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::FastParsers;
use Smart::Comments;

my $class = 'Bio::FastParsers::Hmmer::Standard';

check_iterations(
    file('test', 'hmmer_double_short.stdout'),
    2,
);

check_info_and_targets(
    file('test', 'hmmer3.stdout'),
        [ qw(Meredith169AA 6705) ],
        [
            [ qw(0 12909.9 47.3 0 4943.5 15.5), 3.0, qw(3 Abrocoma_bennettii), undef ],
        ],
);

check_domains(
    file('test', 'hmmer3.stdout'),
    [
        [
            [ qw(3876.6 0) ],
            [ qw(4102.0 0) ],
            [ qw(4943.5 0) ],
        ],
    ],
);

check_info_and_targets(
    file('test', 'hmmer_short.stdout'),
        [ qw(tmpfile_Qfco 6705) ],
        [
            [ qw(0 12909.9 47.3 0 4943.5 15.5), 3.0, qw(3 Abrocoma_bennettii), undef ],
            [ 0, 12562.0, qw(71.7 0 11808.5 45.4 2.8 2 Aepyprymnus_rufescens), undef ],
            [ qw(0 12214.1 81.9 0 5245.2 11.3), 4.0, qw(4 Acrobates_pygmaeus), undef ],
        ],
);

check_domains(
    file('test', 'hmmer_short.stdout'),
    [
        [
            [ qw(3876.6 0) ],
            [ qw(4102.0 0) ],
            [ qw(4943.5 0) ],
        ],
        [
            [ qw(757.3 3.1e-231) ],
            [ qw(11808.5 0) ],
        ],
        [
            [ qw(762.4 9.3e-233) ],
            [ qw(1351.8 0) ],
            [ qw(5245.2 0) ],
            [ qw(4873.3 0) ],
        ],
    ],
);

check_scoreseq(
    file('test', 'hmmer3.stdout'),
    [
        [
            ['CSFLPTMSMEYMVFFSFFTWIFIPLVVMCAIYLNIFHVIRNKLSQNLSASKETGAFYGREFRTAKSLFLVLFLFALCWLPLSIINCALYFPDDIMFLGILLSHXXXXXXILGNALGILAVLTSRSLRAPQNLFLVSLAAADILVATLIIPFSLANELLGYWYFRRTWCEVYLALDVLFCTSSIVHLCXISLDRYWAVSRALEYNSKRTPRRIKCIILTVWLIAAVISLPPLVYKGDQGPQPGRPQCKLNQEAWYILASSIGSFFAPCLIMILVYLRIYLIAKRSGGQWWRRRTQMTREKRFTFVLAVVIGVFVLCWFPFFFSYSLGAICPQHCKVPHGLFITSLACADLVMGLAVVPFGASHILMKMWTFGNFWCEFWTSIDVLCVTASIETLCVIAVDRYFAITSPFKYQSLLTKNKARVVILMVWVVSCLTSFLPIQMHWYRATHQEAINCYAKETCCDFFTNQAYAIASSIVSFYLPLVVMVFVYSRVFQVAKKQLQKIDKSEGRFHTQNLSQVEHDGRSGLRRSSKFYLKEHKALKTLGIIMGTFTLCWLPFFIVNIVHVIQDNLIPKEVYILLNWPLAIPEMNLPYTTTPSVKDFSIWEETGLKEFLKTTKQSFDLNVKIQYKKNKDKHSIAVPLGV-YKFISQNVNYLDSYFETVRDNALDFLTTSYNKAKIKLDKYKAEKSHNTLPRTFRNPGYTIPVNTEVSPFSVETLPFSPVIPKAMNTPNFSIPGSDFHVPSYTLVLPLELPELHIPSNLLKLSLPDFKELSAVNNIFIPAMGNITYDFSFKSSVITLNTNAGLYNQSDIVAHFLSSSSSVIDALQYKLEGTSRLTRKRGLKLATALSLSNKFVEGSHDSTISFTKKNMEASVTTAARVHIPVLRMNFKQELTGNPKSKPAVSSSIELNYDFNSPKLLPTAKGAIDHKLSLESLTSYFSIESSTKADIKGVILSDYSGTLASEASTYLNSKATRSSVKLQGSSKVDGIWNVDVKENFAGEAALLRIYAMWEHSMKNLLQPFSTHGEHVSKATLELSPGALSALIQVRAREINSVLDIPHFGQEVALNANTKNQKFSWKSDIQVHFGTLQNSLHLSNDQKEARFDIAGSLGGHLRFLKFIILPVYNKSLWDLLKLDVTTSSXKRQHLHASTALVYTKNTKGYPLSLPVQELTDKFIPSYKLNFNAIKIYKTLSTSPFALNLPTLPKIKFPQVDVFTQYSKPEDSLIPFFEITVPEVQLTISQFTLPKSFSIGSAVLDLNKVAHMXGDLELPTITVPEQTVELPPIKFSIPVGVLIPITVEEIKKQIEALGFPAYVKKQPKHLKLGAIDVERLKKTPVRSPEGSQQRSPSYTNDLTSIFIIDGMHCKSCVSNIENALSTLHYVSSVAVSLENRSAIVKYSANLATPEILRKAIEAVSPGQYTVSIASEGENTSNSLSSSSLQTIPLNIPLTHETVINIDGMTCNSCVQSIEGVISKKKGVKSIQVSLENSNGTIEYDPLLTSPETLYGGGFQTGTSSLHVYDGKFLARVERVIVVSMNYRLGALGFLALPGNPEAPGNLGLFDQQLALQWVQNNIVTFGGNPTSVTLFGESAGAASVGLHLLSSKSHPYFTRAILQSGSPSAPWAVMSPYEARNRTLTLAKLIGCSKDNETEMIKCLQNKDPQEILLNEVFVVSYDTLLSVNFGPTIDGDFLTDMPETLLRLGQFKRTQILVGVNKDEGSAFLVYGAPGFSKDNNSIITRREFQEGLKLFFPGVSEFGRESVLFHYADWLDDQRPEHYREALDDVVGDXX',
            'c+f  +m+m+ymv+fsfftwi+iplvvmcaiyl+if+virnklsqn+s+sketgafygref+takslflvlflfal+wlplsiinc++yfp+ +++lgillsh      i gnal ilavltsrslrapqnlflvslaaadilvatliipfslanellgywyfrrtwcevylaldvlfctssivhlc isldrywavsraleynskrtprrikciiltvwliaavislppl+ykgdqgpqpgrpqcklnqeawyilassigsffapclimilvylriyliakrsggqwwrrr+q+trekrftfvlavvigvfvlcwfpfffsyslgaicpqhckvphglfitslacadlvmglavvpfgashilmkmwtfgnfwcefwtsidvlcvtasietlcviavdryfaitspfkyqslltknkarvvilmvw+vs+ltsflpiqmhwyrathqeaincyaketccdfftnqayaiassivsfylplvvmvfvysrvfqvak+qlqkidksegrfh+qnlsqve+dgrsg+rrsskf+lkehkalktlgiimgtftlcwlpffivnivhviqdnlipkevyillnwpl ipem+lpytttp+vkdfs+we+tgLKefLkTtKQsfDL+vk+qYkKNkdkhsi++pL+v y+fi+qn+n l+++fe+vrd+aldflt+sYn+akik+dkyk+ekS+n+lprtf+ pgYtiPvn+evspf+ve+l+f+ viPk+++tp+f+ipgs+f+vpsytlvlpleLp+Lh+p+nllklsLpdfk+ls++nnI+iPAmGNiTYdFSFKSsviTLntnaglYnqsDivahflssSssvidaLqykleGts+ltrkRglKlAtalslsnkfveg+hdstiS+tkknmeasvtt a+v+ip+lrmnfkqel+Gn kskp vsssiel+Ydfnspkl  takGa+dhklslesltsyfsiesstk+dikg++ls+ysgt+aseastYlnsk+trssvklqg+skvdgiwn++vkenfagea l riya+weh++kn lq fst+geh skatlelsp  +sal+qvra++++s+ldi+++gqev+lnant+nqk+swks++qvh g+lqn+++lsndq+ear+diagsl ghl+flk i+lpvy+kslwdllkldvtts+ ++q+lhastalvytkn +gy++s+pvqel+dkfipsy+l+f+ ikiyk+lstspfalnlptlpk+kfp+vdv+t+Ys+peds +pffeitvpe+qlt+sqftlpks+s+gsavldln+va++  d+elptitvpeqt+e p+ikfs+p g++ipitveeikkqiea+gfpa++kkqpk+lklgaidverlk+tpv+s+egsqqrspsytnd t +fiidgmhckscvsnie+alstl+yvss++vslenrsaivky+a+l+tpe+lrkaieavspgqy+vsiase e+tsns sssslq iplniplt+etvinidgmtcnscvqsiegviskk+gvksi+vsl+nsngt+eydplltspetlygggfqtgtsslhvydgkflarvervivvsmnyr+galgflalpgnpeapgn+glfdqqlalqwvq+ni +fggnp+svtlfgesagaasv+lhlls+kshp+ftrailqsgs++apwavms++earnrtltlak++gcs++nete+ikcl+nkdpqeillnevfvv+ydtllsvnfgpt+dgdfltdmp+tll+lgqfk+tqilvgvnkdeg+aflvygapgfskdnnsiitr+efqeglk+ffpgvsefg+es+lfhy+dwlddqrpe+yrealddvvgd  ',
            'c+f  +m+m+ymv+fsfftwi+iplvvmcaiyl+if+virnklsqn+s+sketgafygref+takslflvlflfal+wlplsiinc++yfp+ +++lgillsh      i gnal ilavltsrslrapqnlflvslaaadilvatliipfslanellgywyfrrtwcevylaldvlfctssivhlc isldrywavsraleynskrtprrikciiltvwliaavislppl+ykgdqgpqpgrpqcklnqeawyilassigsffapclimilvylriyliakrsggqwwrrr+q+trekrftfvlavvigvfvlcwfpfffsyslgaicpqhckvphglfitslacadlvmglavvpfgashilmkmwtfgnfwcefwtsidvlcvtasietlcviavdryfaitspfkyqslltknkarvvilmvw+vs+ltsflpiqmhwyrathqeaincyaketccdfftnqayaiassivsfylplvvmvfvysrvfqvak+qlqkidksegrfh+qnlsqve+dgrsg+rrsskf+lkehkalktlgiimgtftlcwlpffivnivhviqdnlipkevyillnwpl ipem+lpytttp+vkdfs+we+tgLKefLkTtKQsfDL+vk+qYkKNkdkhsi++pL+vy+fi+qn+n l+++fe+vrd+aldflt+sYn+akik+dkyk+ekS+n+lprtf+ pgYtiPvn+evspf+ve+l+f+ viPk+++tp+f+ipgs+f+vpsytlvlpleLp+Lh+p+nllklsLpdfk+ls++nnI+iPAmGNiTYdFSFKSsviTLntnaglYnqsDivahflssSssvidaLqykleGts+ltrkRglKlAtalslsnkfveg+hdstiS+tkknmeasvtt a+v+ip+lrmnfkqel+Gn kskp vsssiel+Ydfnspkl  takGa+dhklslesltsyfsiesstk+dikg++ls+ysgt+aseastYlnsk+trssvklqg+skvdgiwn++vkenfagea l riya+weh++kn lq fst+geh skatlelsp  +sal+qvra++++s+ldi+++gqev+lnant+nqk+swks++qvh g+lqn+++lsndq+ear+diagsl ghl+flk i+lpvy+kslwdllkldvtts+ ++q+lhastalvytkn +gy++s+pvqel+dkfipsy+l+f+ ikiyk+lstspfalnlptlpk+kfp+vdv+t+Ys+peds +pffeitvpe+qlt+sqftlpks+s+gsavldln+va++  d+elptitvpeqt+e p+ikfs+p g++ipitveeikkqiea+gfpa++kkqpk+lklgaidverlk+tpv+s+egsqqrspsytnd t +fiidgmhckscvsnie+alstl+yvss++vslenrsaivky+a+l+tpe+lrkaieavspgqy+vsiase e+tsns sssslq iplniplt+etvinidgmtcnscvqsiegviskk+gvksi+vsl+nsngt+eydplltspetlygggfqtgtsslhvydgkflarvervivvsmnyr+galgflalpgnpeapgn+glfdqqlalqwvq+ni +fggnp+svtlfgesagaasv+lhlls+kshp+ftrailqsgs++apwavms++earnrtltlak++gcs++nete+ikcl+nkdpqeillnevfvv+ydtllsvnfgpt+dgdfltdmp+tll+lgqfk+tqilvgvnkdeg+aflvygapgfskdnnsiitr+efqeglk+ffpgvsefg+es+lfhy+dwlddqrpe+yrealddvvgd  '],
            ['XXVNEWFSRSDEMETSEDGCDWEXEKTDLKASDPQRAVTCATVRGCPSAGKGSVEDKVFGKTYRRKGSLANLSHSAXVTQECPLTSTVKRKRRTLSCLHPEDFIKKAGLAAAQKTPEKDTQGMKQSSQVTSIPNNN-ENETEGVAVQRXQNPSPVQSLEKESVPGMGTEPQSSSGNSMELEWNVCPPGAPQGNRLRKRSSARQVP--------HLSPPGHPELQIDTSTSSEEKGDSSWQVQVRHGRKLTLAGALDA-------AAGEAVPEQKLASVPSNSSSPDKLTEFXSANPQKETLQGSGSTRDPKDLLSSGEKGLRSAESTSVSLVPDTDYSTQDSVSLLETDSRRASLQCVAYVAVTKPKDLLPAQSKDAGXGXEGFDXPSRFNMSHREADAEVEDSELDTQYLQNTFLSXKRQSFVLFGGSFKTASNKEIKVSEHDIKKGKMLFKDIEERYNSASFEQSSASVSDRENNHTAFQILSSNSNSNLTSSQRAEIAELSIILEESGSQFEFTQFRKPIHLIQLETTSEESKGDLHPVIDASSISQEDSSKKFEGALGEKQKFAYLLQNSPNNSAAGFLINEKE-XYKGFYSARGKLNVSSEALQRALKLFSDIENISEETSAEVDP-SFCSSRSSDSVSXLKIENHNNDKNLNEKNTHCQLVLQNNAEMTTGISVEENTENYMRNTENKN-TYASYQLGQFGGTDSSKVHKDENDLPCHNILLKSSSQFIREVSTQ-KESLSDLTCLEVVKAEETCYIS-ASKEQLTAGEMXQYNNF---DISFHTASGKNIRVSKESLNKVVNFFDQKPEE-WDDFSDALNSKLLSGR-KNRMDLSRHGETNKNKILGESTPGNIGTEL-SLLQEPEYKIGHNKEPNLLGFYTAXGKKVNIVKESLDKVKSLFDESKIGKSSHQVAKTLKGRECKEGVELAHETVERTADPKHEEM----------------PSL--NLDRQSENLRISSSISLEVKPSTSSGTNQFPYSAINDLPLAFYIGHGKKISVFSTASGKSVEVSDGSLQKARQMFCYRGSPFQEKMTAGDNAQLVPADPGNLTEFYNKSLSSYKENDENIQCGENFMDMECFMILNPSQQLAIAVLSLTLGTFTVLENLLVLCVILHSRSLRCRPSYHFIGSLAVXDLLGSVIFVYSXVDFHVFHRKDSPNVFLFKLGGVTASFTASVGSLFLTAIDRYISIHRPLAYKRIVTRPKAVVAFCLMWTIAIVIAVLPLLGWNCKKLQSVCSDIFPLIDETYLMFWIGVTSVLLLFIVYAYMYILWKAHSHAVRMIQRGTQKSIIIHTSEDGKVQVTRPDQARMDIRLAKTLVLILVVLIICWGPLLAIMVYDVFGKMNKLIKTVFAFCEDDSGDDTFGDEDNGLGPQK-----------DSAGTTQSREDSASR-EDSTQYLASNSRDLDVEDGV-----------NSESEERWVGGSSEGDSSHGDSSEFHDNGIQSDDPDSTRSEGGSSRMDSSKAKSRESQGDS-KQEXTQDSGDRQSVESSSKKFFRKSRISEEDDRDDLEDSNTMEDLRSDSTESSKSDSQEDTESESQEDSEDT-DTSSSPSQESSSESQEDGVESRGDNPDA-----T-SQEDSDSSEEDSLNSFSSSESESREQQADSESNESLSEESQESPEDDNSSSQEGLQSQSTSQSQ---ESRSGEDTDSNSSSSEEGGQPKNMEAESRKLTMDFKPQFYNDDSWVEFIELDIDDPDEKIEGSDTDRLLSSDHQKSLNILGAKDDDSGRTSCYEPDXLEADFNVGDVCHGTSEVVQQDKLKGEPDLLCLDEKNQTNSPC-DAPDPQPANVIPAKQDKPQLLFIGKTESAKQDAPTQISNPSSLANMDFYAQVSDITPAGSVVLSPGQKNKAGMSQCEE------ANFIKDSACFFKGDAQQCIATSPHVEVQSEEPSLRQEDTYITTESLTTAAEKSGAAGQAPCSEMALPDYTSVHIVQSPQALILNAAANKEFLSSCGYXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXYVMSIVCKNNKKVTFRCTEKDLVGDVPEARYGHXIDVVYSRGKSMGVLFGGRSYMPSTQRTTEKWNSVADCXPHVFLVDFEFGCATSYVLPELXDGLSFHVSIAKTDTVYILGGHSLANNIRPPNLYRIRVDLPLGSPAVSCTVLEELLARLQRNIRHEVXQGNVGYLRVDDLPGQEVLSRLGGFLVNHVWKQLMGTSALVLDLRQCPSGHVSGIPYVISYLHPGNTVLHVDTIYDRPSNTTTEIWTLPQVLGERYSAEKDVVVLTSGRTGGVAEDVAYILKQMRRAIVVGERTEGGALDLRKLRIGQSSFFLTVPVSRSLGPLSGGSQTWEGSGVLPCVSTPAEQALEKALAILTLRRALPGVVHRLQEALQEYYTLVDRVXALLHRLSSMDYSTVVSEEDLVTKLNSGLQAVSEDPRLVVRAAGPRETSSGPPKDEAARQALVDTVFQVSXX',
            '  vnewfsrsde+ ts+d +d + ek+dl asdp++a++c++ r ++ + + ++edk+fgktyrrk sl nlsh + +tqe+plt+++krkrrt s+lhpedfikk+ la +qktpek ++g++q++qv++i nn+ enet+g  vq+ +n++p++slekes+  + +ep+sss ++mele+n++   ap+ nrlr++ss+r+++        + spp h elqid ++sseek+ +s q++vrh+rkl l +  ++        a +a+pe+kl+++p+n+ss +kl+ef + ++q+et+q s st+dpkdl+ sgekglrs+ests+slvpdtdy+tqds+slle+d+ +a+ qcv+++a+++pk+l++++skd++ + egf  p r +++h+e+  e+e+seldtqylqntf   krqsf+lfg++f+tasnkeik+seh+ikk+kmlfkdiee+y++a++eqssa+vsd+en+ht++q+ls+nsn+nlt sq+aei els ileesgsqfeftqfrkp h+iqlettsee k dlh +i+a+sisq dsskkfega+g+kqkfa+ll+n+ n+sa+g+l +++e  ++gfysa+gklnvssealq+a+klfsdieniseetsaevdp sf+ss+++dsvs +kien+nndknlnekn++cql+lqnn+emttgi veenteny+rnten++ ++ +++lg++ g+dssk+hkdendlpchni lk+ssqf++e +tq ke+lsdltclevvkaeet++++  +keqlta +m q+++f   d+sf+tasgknirvskeslnkvvn+fd+k ee +++fsd+lns+llsg  kn+md+s+h et+knkil es+p +++++l +l q+pe++i + kep+llgf+ta gkkv+i+kesldkvk+lfdes+i + shq aktlk reckeg+ela+etve t+ pk+eem                p+l  +l+rq+enl++s+sisl+vk +t + tnq++ysai++ +lafy ghg+kisvfstasgksv+vsd slqkarq+f +rgspfqekmtagdn+qlvpad+ n+tefynkslssyken+eniqcgenfmdmecfmilnpsqqlaiavlsltlgtftvlenllvlcvilhsrslrcrpsYhfigslav dllgsvifvys vdfhvfhrkdspnvflfklggvtasftasvgslfltaidrYisihrplaYkrivtrpkavvafclmwtiaiviavlpllgwnckklqsvcsdifplidetylmfwigvtsvlllfivyaymyilwkahshavrmiqrgtqksiiihtsedgkvqvtrpdqarmdirlaktlvlilvvliicwgpllaimvydvfgkmnkliktvfafceddsgddtfgdedng+gp++           dsa ttqsredsas+ eds+q+ +s+srdld ed v           +sesee+wvgg+segdsshgd+sef+d+g+qsddpds+rse ++srm+s ++ks+es+g+s +q+ tqdsg++qsve++s+kffrksriseeddr++l+dsntme+++sdste+sks+sqed+es+sqeds+++ d+ss psqesssesqe+ vesrgdnpd      + +qedsdsseedsln++sssesesre+qadsesneslsees+es+e++nsssqeglqsqs+s+sq   +s+s e++ds+ssssee gq+kn+e+esrklt+d kp+fynddswvefieldiddpdek+egsdtdrlls+dhqkslnilgakdddsgrtscyepd le+dfn+ dvc+gtsev+q+++lkge dllcld+knq+nsp+ dap++q+++vi+a+++kp+ l+ig+tes++q+a+tq+snpsslan+dfyaqvsditpagsvvlspgqknkag+sqc+e      anfi+d+a+f++ da++cia+ phvev+s eps+ qed+yittesltt+a++sg+a +ap sem++pdyts+hivqspq l+lna+a+keflsscgy                                        yvms+vcknnkkvtfrctekdlvgdvpearYgh idvvysrgksmgvlfggrsYmps+qrttekwnsvadc phvflvdfeFgc+tsy+lpel dglsFhvsia+ dt+Yilgghslannirp+nlyrirvdlplgspav+ctvleella+lq++irhev +gnvgylrvdd+pgqev+s+lg+flv++vwk+lmgtsalvldlr+c +ghvsgipyvisylhpgntvlhvdtiydrpsnttteiwtlpqvlgerysa+kdvvvltsgrtggvaed+ayilkqmrraivvgert+ggaldl+klrigqs+ffltvpvsrslgpl+ggsqtwegsgvlpcv+tpaeqalekalailtlrralpgvv+rlqealq+yytlvdrv allh+l+smd+s+vvseedlvtkln+glqavsedprl+vra +p+etssgpp+deaarqalvd+vfqvs  ',
            '  vnewfsrsde+ ts+d +d + ek+dl asdp++a++c++ r ++ + + ++edk+fgktyrrk sl nlsh + +tqe+plt+++krkrrt s+lhpedfikk+ la +qktpek ++g++q++qv++i nn+enet+g  vq+ +n++p++slekes+  + +ep+sss ++mele+n++   ap+ nrlr++ss+r++++ spp h elqid ++sseek+ +s q++vrh+rkl l +  ++ a +a+pe+kl+++p+n+ss +kl+ef + ++q+et+q s st+dpkdl+ sgekglrs+ests+slvpdtdy+tqds+slle+d+ +a+ qcv+++a+++pk+l++++skd++ + egf  p r +++h+e+  e+e+seldtqylqntf   krqsf+lfg++f+tasnkeik+seh+ikk+kmlfkdiee+y++a++eqssa+vsd+en+ht++q+ls+nsn+nlt sq+aei els ileesgsqfeftqfrkp h+iqlettsee k dlh +i+a+sisq dsskkfega+g+kqkfa+ll+n+ n+sa+g+l +++e ++gfysa+gklnvssealq+a+klfsdieniseetsaevdpsf+ss+++dsvs +kien+nndknlnekn++cql+lqnn+emttgi veenteny+rnten++++ +++lg++ g+dssk+hkdendlpchni lk+ssqf++e +tqke+lsdltclevvkaeet++++ +keqlta +m q+++fd+sf+tasgknirvskeslnkvvn+fd+k ee+++fsd+lns+llsg kn+md+s+h et+knkil es+p +++++l+l q+pe++i + kep+llgf+ta gkkv+i+kesldkvk+lfdes+i + shq aktlk reckeg+ela+etve t+ pk+eemp+l+l+rq+enl++s+sisl+vk +t + tnq++ysai++ +lafy ghg+kisvfstasgksv+vsd slqkarq+f +rgspfqekmtagdn+qlvpad+ n+tefynkslssyken+eniqcgenfmdmecfmilnpsqqlaiavlsltlgtftvlenllvlcvilhsrslrcrpsYhfigslav dllgsvifvys vdfhvfhrkdspnvflfklggvtasftasvgslfltaidrYisihrplaYkrivtrpkavvafclmwtiaiviavlpllgwnckklqsvcsdifplidetylmfwigvtsvlllfivyaymyilwkahshavrmiqrgtqksiiihtsedgkvqvtrpdqarmdirlaktlvlilvvliicwgpllaimvydvfgkmnkliktvfafceddsgddtfgdedng+gp++dsa ttqsredsas+eds+q+ +s+srdld ed v+sesee+wvgg+segdsshgd+sef+d+g+qsddpds+rse ++srm+s ++ks+es+g+s+q+ tqdsg++qsve++s+kffrksriseeddr++l+dsntme+++sdste+sks+sqed+es+sqeds+++d+ss psqesssesqe+ vesrgdnpd ++qedsdsseedsln++sssesesre+qadsesneslsees+es+e++nsssqeglqsqs+s+sq+s+s e++ds+ssssee gq+kn+e+esrklt+d kp+fynddswvefieldiddpdek+egsdtdrlls+dhqkslnilgakdddsgrtscyepd le+dfn+ dvc+gtsev+q+++lkge dllcld+knq+nsp+dap++q+++vi+a+++kp+ l+ig+tes++q+a+tq+snpsslan+dfyaqvsditpagsvvlspgqknkag+sqc+eanfi+d+a+f++ da++cia+ phvev+s eps+ qed+yittesltt+a++sg+a +ap sem++pdyts+hivqspq l+lna+a+keflsscgy                                        yvms+vcknnkkvtfrctekdlvgdvpearYgh idvvysrgksmgvlfggrsYmps+qrttekwnsvadc phvflvdfeFgc+tsy+lpel dglsFhvsia+ dt+Yilgghslannirp+nlyrirvdlplgspav+ctvleella+lq++irhev +gnvgylrvdd+pgqev+s+lg+flv++vwk+lmgtsalvldlr+c +ghvsgipyvisylhpgntvlhvdtiydrpsnttteiwtlpqvlgerysa+kdvvvltsgrtggvaed+ayilkqmrraivvgert+ggaldl+klrigqs+ffltvpvsrslgpl+ggsqtwegsgvlpcv+tpaeqalekalailtlrralpgvv+rlqealq+yytlvdrv allh+l+smd+s+vvseedlvtkln+glqavsedprl+vra +p+etssgpp+deaarqalvd+vfqvs  '],
            ['XXNSSGMKSAFVTVRVLDTPSPPVNLKVTEITKDSVSITWEPPLLDGGSKIKNYIVEKREATRKSYAAVVTNCHKNSWKIDQLQEGCSYYFRVTAENEYGIGLPARTADPIKVAEVPQPPGKITVDDVTRNSVSLSWTKPEHDGGSKIIQYIVEMQAKHSEKWSECARVKSLEAVITNLTQGEEYLFRVVAVNEKGRSDPRSLAVPIIAKDLVIEPDVRPAFSSYSVQVGQDLKIEVPISGRPKPTITWTKDDLPLKQTTRINVTDSLDLTTLSIKETHKDDSGHYGITVANVVGQKTASIEIITLDKPDPPKGPVKFDEISAESITLSWQPPVYTGGCQITNYVVQKRDTTTTVWDIVSATVARTTLKVTKLKTGTEYQFRIFAENRYGQSFALESEPVVAKNPNKEPGPPGTPFARAISKDSMVIQWHEPINNGGSPIIGYHLERKERNSILWTKVNKTIIHDTQFKVLNLEEGIEYEFRVCAENIVGVGKPSKTSECYVARDPCDPPGTPEAIIVKRNEITLQWTKPVYDGGSMITGYIVEKRDLPEGRWMKASFTNVIETQFTVSGLTEDQRYEFRVIAKNAAGAISKPSDSTGPITAKDEVELPRISMDPKFRDTIVVNAGETFRLEADVHGKPLPTIEWLRGDKEVEESARCEIKNTDFKALLIIKDAIRIDGGQYILRASNVAGSKSFPVNVKVLDRPGPPEGPVQVTGVTAEKCTLAWSPPLQDGGSDISHYVVEKRETSRLAWTVVASEVVTNSLKITKLLEGNEYIFRIMAVNKYGVGEPLESAPVLMKNPFVLPGPPKSLEVTNIAKDSMTVCWNRPDSDGGSEIIGYIVEKRDRSGIRWIKCNKRRITDLRLRVTGLTEDHEYEFRVSAENAAGVGEPSPATVYYKACDPVFKPGPPTNVHVVDTTKSSITLAWSKPIYDGGSEILGYIVEICKADEEEWQIVTPQTGLRVTRFEIAKLTEHQEYKIRVCALNKVGLGEAASVPGTVKPEDKLEAPELDLDSELRKGIVVRAGGSARIHIPFKGRPTPEITWSREEGEFTDRVQIEKGLNFTQLSIDNCDRNDAGKYLLKLENSSGSKSAFVTVKVLDTPGPPQNLTVKEIRKDSVLLAWEPPIIDGGXKVKNYVVDKRESTRKAYANVSSKCSKTNFKVENLTEGAIYYFRVMAENEFGIGVPVETTDAVKASEPPSPPGKVTLTDVSQTSTSLMWEKPEHDGGSRVLGYIVEMQPKGTEKWSVVAESKVCNAVVTGLSSGQEYQFRIKAYNEKGKSDPRVLGVPVIAKDLTIQPSFKLPFNTYSVQAGEDLKIEIPVIGRPRPKISWVKDGEPLKQTTRVNVEETPTSTILHIKDSSKDDFGKYTITATNSAGTATENLSIIVLEKPGPPVGPVKFDEVSADFVVISWEPPAYTGGCQISNYIVEKRDTTTTTWHMVSATVARTTIKVTKLKTGTEYQFRIFAENRYSCQDVLLSQAPFGPQFPFTGVDDRESWPSVFYNRTCQCSGNFRGFSCGSCRFGYGGPDCSQKRVLVRRNIFDLSVAEKDKFLAYLTLAKHTVSADYVIPTGTYGQMKNGSTAMFNDVNIYDLFVWMHYYVSRDTLLRXXxXXXSSRLSEADFEVLKAFVVSVMERLHISQKRIRVAVVEYHDGSHAYLELKARKRPSELRRIASQVKYVGSQVASTSEVLKYTLFQIFGKIERPEASRIVLLLTASSEPKHMTRNLVRSVQGLKKKKVILMPVAIGPHVNLQQIRLIEKQAPENKAFMLSGVDELEQRRDEIINYLCDHAPEAPAVAQVTVGPRLSELSPEPKRSMVLDVVFVLEGSDKVGEANFNRSKEFMVEVIQRMDVGQDGVHVTVLQYSYMVAVEYTFREAQSKGDVLQHVREIQFRGGNQTNTGLALQYLSEHSFSASQGDREQAPNLVYMV',
            '  nssg+ksafvtvrvldtpsppvnlkvteitkdsvsitwepplldggskiknyivekreatrksYaAvvTnchKnsWKidqLqeGcsYyFRVtAeneYGiGlpartadpiKvaeVpqPpgKitvdDVTRnSVSLsWtKPEHDGGSKIiqYiVEMQAKhseKWSeCARVKsLEAVITNLtQGEEYLFRVvAVNEKGRSDPRSLAVPi+AKDLVIEPDVRPaF+sYSvQVGqDLKIEVpISGRPKPtITWtKD+lpLKQTTRiNVtDsldlT+LsiKEthKdD+GhYgItVANVvGqKtAsieIitLDKPDPPkGPVKfDe+SAESITLSW+Pp+YTGGcqItnY+VqKRDTTtTvWd+vsatvarttlkvtklktgteyqfrifaenrygqsfalesep+va+ p kepgppgtpf+ aiskdsmv+qwhepinnggsp+igyhlerkernsilwtkvnktiihdtqfk+lnleegieyefrv+aenivgvgk+sk+secyvardpcdppgtpeaiivkrneitlqwtkpvydggsmitgyivekrdlpegrwmkasftnvietqftvsgltedqryefrviaknaagaiskpsdstgpitakdevelprismdpkfrdtivvnagetfrleadvhgkplptiewlrgdkeveesarceikntdfkalli+kdairidggqyilrasnvagsksfpvnvkvldrpgppegpvqvtgvt+ekctl+wspplqdggsdishYvvekretsrlawtvvasevvtnslk+tkllegneYifrimavnkYgvgeplesapvlmknpfvlpgppkslevtniakdsmtvcwnrpdsdggseiigyivekRdrsgirwikcnkrRitdlRlRvtgltedheYeFRvsaenaagvgepspatvYYkacdpvfkpgpptn+h+vdttk+sitlaw+kpiydggseilgy+veickadeeewqivtpqtglrvtrfei kl+ehqeYkirvcalnkvglgeaasvpgtvkpedkleapeldlDSeLRKGivvrAGGsaRihipFKGrptpeitwsreeGeftd+vqiekgln+tqLsidncDRnDAGKY+lkLenSsGsksAFvtvKVLDtpGppqnL+Vke++kdsvll weppiidGG kvKnYv+dkrestrkayanvsskcskt+fkvenltegaiyyfrvmaenefg+gvpvet+davka+eppsppgkvtltdvsqts SlmWeKPehDGGSR+LGY+VEmqPKGtekWsvvaesKvCnAvvtGLSsGqeYqFr+kAYNeKGkSDPRvLGvPvIAkDLTIqPsfkLpFntYsvqAGedlkieipvigrprpkiswvkdgeplkqttrvnveet tstilhik+s+kddfgkYtitatnsagtatenlsiivlekpgppvgpv+fdevsadfvvisweppaYtggcqisnyivekrdtttttw+mvsatvarttik+tklktgteyqfrifaenryscqd+lls+ap+gpqfpftgvddreswpsvfynrtcqcsgnf gf+cg+c+fg+ gp c ++r+lvrrnifdlsv+ek+kflayltlakht+s+dyviptgtygqm+ngst mfnd+niydlfvwmhyyvsrdtll       ss+lsea+fevlkafvv++merlhisqkrirvavveyhdgshay+elk+rkrpselrriasqvky+gsqvastsevlkytlfqifgki+rpeasri+llltas+ep++++rnlvr vqglkkkkvi++pv igph++l+qirliekqapenkaf+lsgvdeleqrrdeii+ylcd+apeapavaqvtvgp+l++ s++pkrsmvldvvfvlegsdkvgeanfnrskefm eviqrmdvgqd++hvtvlqysy+v+veytfreaqsk+dvlq+vrei++rggn+tntglalqylsehsfsasqgdreqapnlvymv',
            '  nssg+ksafvtvrvldtpsppvnlkvteitkdsvsitwepplldggskiknyivekreatrksYaAvvTnchKnsWKidqLqeGcsYyFRVtAeneYGiGlpartadpiKvaeVpqPpgKitvdDVTRnSVSLsWtKPEHDGGSKIiqYiVEMQAKhseKWSeCARVKsLEAVITNLtQGEEYLFRVvAVNEKGRSDPRSLAVPi+AKDLVIEPDVRPaF+sYSvQVGqDLKIEVpISGRPKPtITWtKD+lpLKQTTRiNVtDsldlT+LsiKEthKdD+GhYgItVANVvGqKtAsieIitLDKPDPPkGPVKfDe+SAESITLSW+Pp+YTGGcqItnY+VqKRDTTtTvWd+vsatvarttlkvtklktgteyqfrifaenrygqsfalesep+va+ p kepgppgtpf+ aiskdsmv+qwhepinnggsp+igyhlerkernsilwtkvnktiihdtqfk+lnleegieyefrv+aenivgvgk+sk+secyvardpcdppgtpeaiivkrneitlqwtkpvydggsmitgyivekrdlpegrwmkasftnvietqftvsgltedqryefrviaknaagaiskpsdstgpitakdevelprismdpkfrdtivvnagetfrleadvhgkplptiewlrgdkeveesarceikntdfkalli+kdairidggqyilrasnvagsksfpvnvkvldrpgppegpvqvtgvt+ekctl+wspplqdggsdishYvvekretsrlawtvvasevvtnslk+tkllegneYifrimavnkYgvgeplesapvlmknpfvlpgppkslevtniakdsmtvcwnrpdsdggseiigyivekRdrsgirwikcnkrRitdlRlRvtgltedheYeFRvsaenaagvgepspatvYYkacdpvfkpgpptn+h+vdttk+sitlaw+kpiydggseilgy+veickadeeewqivtpqtglrvtrfei kl+ehqeYkirvcalnkvglgeaasvpgtvkpedkleapeldlDSeLRKGivvrAGGsaRihipFKGrptpeitwsreeGeftd+vqiekgln+tqLsidncDRnDAGKY+lkLenSsGsksAFvtvKVLDtpGppqnL+Vke++kdsvll weppiidGG kvKnYv+dkrestrkayanvsskcskt+fkvenltegaiyyfrvmaenefg+gvpvet+davka+eppsppgkvtltdvsqts SlmWeKPehDGGSR+LGY+VEmqPKGtekWsvvaesKvCnAvvtGLSsGqeYqFr+kAYNeKGkSDPRvLGvPvIAkDLTIqPsfkLpFntYsvqAGedlkieipvigrprpkiswvkdgeplkqttrvnveet tstilhik+s+kddfgkYtitatnsagtatenlsiivlekpgppvgpv+fdevsadfvvisweppaYtggcqisnyivekrdtttttw+mvsatvarttik+tklktgteyqfrifaenryscqd+lls+ap+gpqfpftgvddreswpsvfynrtcqcsgnf gf+cg+c+fg+ gp c ++r+lvrrnifdlsv+ek+kflayltlakht+s+dyviptgtygqm+ngst mfnd+niydlfvwmhyyvsrdtll       ss+lsea+fevlkafvv++merlhisqkrirvavveyhdgshay+elk+rkrpselrriasqvky+gsqvastsevlkytlfqifgki+rpeasri+llltas+ep++++rnlvr vqglkkkkvi++pv igph++l+qirliekqapenkaf+lsgvdeleqrrdeii+ylcd+apeapavaqvtvgp+l++ s++pkrsmvldvvfvlegsdkvgeanfnrskefm eviqrmdvgqd++hvtvlqysy+v+veytfreaqsk+dvlq+vrei++rggn+tntglalqylsehsfsasqgdreqapnlvymv'],
        ],
    ],
);

check_info_and_targets(
    file('test', 'hmmer_description.stdout'),
        [ qw(GNTPAN12210_noloxo 779) ],
        [
            [ qw(0 1563.7 0 0 1563.4 0), 1.0, qw(1  L), 'oxodonta_africana@ENSLAFP00000006713_that is really long with strange stuff' ],
        ],
);

check_info_and_targets(
    file('test', 'hmmer_domthresh.stdout'),
        [ qw(tmpfile_IV_h_model 524) ],
        [
            [ qw(4.6e-05 9.6 21.6 0.014 1.4 21.6), 3.0, qw(0  Scoe_bact|CAB99155), undef ],
        ],
);

check_domains(
    file('test', 'hmmer_domthresh.stdout'),
    [
        [],
    ],
);


sub check_iterations {
    my $infile          = shift;
    my $exp_iterations  = shift;

    ok my $report = $class->new( file => $infile ),
        'Hmmer::Standard constructor';
    isa_ok $report, $class, $infile;
    cmp_ok $report->count_iterations, '==', $exp_iterations,
        'got expected number of iterations';

    return;
}


sub check_info_and_targets {
    my $infile = shift;
    my $exp_info    = shift;
    my $exp_targets = shift;

    ok my $report = $class->new( file => $infile ),
        'Hmmer::Standard constructor';
    isa_ok $report, $class, $infile;

    my $iteration = $report->next_iteration;
    isa_ok $iteration, $class . '::Iteration';

    my @info_attrs = qw(query query_length);
    cmp_deeply [ map { $iteration->$_ } @info_attrs ], $exp_info,
        'got expected infos';

    my @target_attrs = qw(
               evalue    score    bias
            best_dom_evalue     best_dom_score  best_dom_bias
                exp      dom
            query_name          target_description
        );

    my $n = 0;
    while (my $target = $iteration->next_target) {
        ok $target, 'Hmmer::Standard::Target constructor';
        isa_ok $target, $class . '::Target';
        cmp_deeply [ map { $target->$_ } @target_attrs ],
            shift @{ $exp_targets },
            'got exp values for all methods for target-' . $n++
        ;
    }

    return;
}


sub check_domains {
    my $infile = shift;
    my $exp_targets = shift;

    ok my $report = $class->new( file => $infile ),
        'Hmmer::Standard constructor';
    isa_ok $report, $class, $infile;

    my $iteration = $report->next_iteration;
    isa_ok $iteration, $class . '::Iteration';

    for my $exp_target (@$exp_targets) {
        my $target = $iteration->next_target;
        ok @$exp_target == $target->count_domains,
            'got exp number of domains';

        my @dom_attrs = ( qw(score expect) );

        my $n=0;
        while (my $domain = $target->next_domain) {
            ok $domain, 'Hmmer::Standard::Domain constructor';
            isa_ok $domain, $class . '::Domain';
            cmp_deeply [ map { $domain->$_ } @dom_attrs ],
                shift @{ $exp_target },
                'got exp values for all methods for domain-'
                    . $n++ .' in ' . $target->name
            ;
        }
    }

    return;
}

sub check_scoreseq {
    my $infile = shift;
    my $exp_targets = shift;

    ok my $report = $class->new( file => $infile ),
        'Hmmer::Standard constructor';
    isa_ok $report, $class, $infile;

    my $iteration = $report->next_iteration;
    isa_ok $iteration, $class . '::Iteration';

    for my $exp_target (@$exp_targets) {
        my $target = $iteration->next_target;
        ok @$exp_target == $target->count_domains,
            'got exp number of domains';

        my @dom_attrs = ( qw(seq scoreseq get_degap_scoreseq) );

        my $n=0;
        while (my $domain = $target->next_domain) {
            ok $domain, 'Hmmer::Standard::Domain constructor';
            isa_ok $domain, $class . '::Domain';
            cmp_deeply [ map { $domain->$_ } @dom_attrs ],
                shift @{ $exp_target },
                'got exp strings for all methods for domain-'
                    . $n++ .' in ' . $target->name
            ;
        }
    }

    return;
}

done_testing;
