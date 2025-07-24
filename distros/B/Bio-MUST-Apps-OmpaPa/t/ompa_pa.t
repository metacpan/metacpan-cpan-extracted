#!/usr/bin/env perl

use Test::Most;
use Test::Files;
use Test::Output;

use autodie;
use feature qw(say);

use Path::Class qw(file);
use Smart::Comments '###';

use Bio::MUST::Apps::OmpaPa;
use aliased 'Bio::MUST::Apps::OmpaPa::Parameters';

{
    my $class = 'Bio::MUST::Apps::OmpaPa::Hmmer';

    my $oum = $class->new(
        file         => file('test', 'hmmsearch_dom.out'),
        extract_seqs => 1,
        database     => file('test', 'database'),
        parameters   => Parameters->new( max_hits => 10 ),
    );
    isa_ok $oum, $class;
    cmp_ok $oum->count_hits, '==', 10, 'processed expected number of hits (considering max_hits)';

    cmp_ok $oum->list_selection( 'all' ), 'eq', <<'EOT', 'got expected selection list (all in bounds) with default values (considering max_hits)';
=================================================================================================================
keep accession                                        description length evalue  count max alignment ratio_length
-----------------------------------------------------------------------------------------------------------------
*    Cyanothece_sp._497965@ADN14832                   none        371    3.5e-65 1     1   0.897     1.742
*    Cyanothece_sp._65393@ACK69229                    none        360    3.5e-63 1     1   0.840     1.690
*    Nostoc_sp._103690@BAB77266                       none        232    8.2e-63 1     1   0.911     1.089
*    Gloeocapsa_sp._1173026@AFZ30697                  none        230    1.6e-62 1     1   0.939     1.080
*    Nostoc_sp._103690@BAB78081                       none        320    6.3e-62 1     1   0.892     1.502
*    Rivularia_sp._373994@AFY57759                    none        240    1.2e-61 1     1   0.911     1.127
*    Synechocystis_sp._927677@ELR88413                none        217    2e-61   1     1   0.901     1.019
*    Sulfurimonas_autotrophica_563040@ADN08900        none        675    2.1e-61 1     1   0.906     3.169
*    Desulfotomaculum_carboxydivorans_868595@AEF93225 none        233    6.6e-61 1     1   0.897     1.094
*    Microcoleus_vaginatus_756067@EGK88082            none        237    1.5e-60 1     1   0.911     1.113
=================================================================================================================
EOT

}

{
    my $class = 'Bio::MUST::Apps::OmpaPa::Hmmer';

    my $oum = $class->new(
        file         => file('test', 'hmmsearch_dom.out'),
        extract_seqs => 1,
        database     => file('test', 'database'),
    );
    isa_ok $oum, $class;
    cmp_ok $oum->count_hits, '==', 242, 'processed expected number of hits';

    cmp_ok $oum->count_selection, '==', 242, 'got expected number of selected hits with default values';

    cmp_ok $oum->list_selection( 'all' ), 'eq', <<'EOT', 'got expected selection list (all in bounds) with default values';
=====================================================================================================================
keep accession                                            description length evalue  count max alignment ratio_length
---------------------------------------------------------------------------------------------------------------------
*    Cyanothece_sp._497965@ADN14832                       none        371    3.5e-65 1     1   0.897     1.742
*    Cyanothece_sp._65393@ACK69229                        none        360    3.5e-63 1     1   0.840     1.690
*    Nostoc_sp._103690@BAB77266                           none        232    8.2e-63 1     1   0.911     1.089
*    Gloeocapsa_sp._1173026@AFZ30697                      none        230    1.6e-62 1     1   0.939     1.080
*    Nostoc_sp._103690@BAB78081                           none        320    6.3e-62 1     1   0.892     1.502
*    Rivularia_sp._373994@AFY57759                        none        240    1.2e-61 1     1   0.911     1.127
*    Synechocystis_sp._927677@ELR88413                    none        217    2e-61   1     1   0.901     1.019
*    Sulfurimonas_autotrophica_563040@ADN08900            none        675    2.1e-61 1     1   0.906     3.169
*    Desulfotomaculum_carboxydivorans_868595@AEF93225     none        233    6.6e-61 1     1   0.897     1.094
*    Microcoleus_vaginatus_756067@EGK88082                none        237    1.5e-60 1     1   0.911     1.113
*    Paenibacillus_polymyxa_886882@ADO56408               none        223    3.6e-60 1     1   0.906     1.047
*    Chamaesiphon_minutus_1173020@AFY95414                none        218    4.9e-60 1     1   0.887     1.023
*    Bacillus_macauensis_1196324@EIT85841                 none        231    5.8e-60 1     1   0.944     1.085
*    Paenibacillus_sp._481743@ACX66507                    none        228    6.5e-60 1     1   0.906     1.070
*    Pelosinus_fermentans_1122947@EIW31336                none        227    1.3e-59 1     1   0.925     1.066
*    Stanieria_cyanosphaera_111780@AFZ34417               none        239    2.8e-58 1     1   0.925     1.122
*    Chamaesiphon_minutus_1173020@AFY93037                none        214    3.4e-58 1     1   0.873     1.005
*    Gillisia_limnaea_865937@EHQ04246                     none        248    4.7e-58 1     1   0.958     1.164
*    Paenibacillus_curdlanolyticus_717606@EFM13001        none        219    8.9e-58 1     1   0.920     1.028
*    Halobacillus_halophilus_866895@CCG44366              none        241    2.3e-57 1     1   0.934     1.131
*    Kyrpidia_tusciae_562970@ADG04796                     none        208    3.5e-57 1     1   0.883     0.977
*    Sporosarcina_newyorkensis_1027292@EGQ24744           none        270    3.9e-57 1     1   0.930     1.268
*    Aequorivita_sublithincola_746697@AFL81580            none        242    1.6e-56 1     1   0.930     1.136
*    Hippea_maritima_760142@AEA33167                      none        698    1.8e-56 1     1   0.906     3.277
*    Enterococcus_italicus_888064@EFU72982                none        221    2e-56   1     1   0.883     1.038
*    Carnobacterium_sp._208596@AEB29259                   none        219    3.2e-56 1     1   0.925     1.028
*    Pelosinus_fermentans_1122947@EIW29018                none        380    5.3e-56 1     1   0.944     1.784
*    Fulvivirga_imtechensis_1237149@ELR72804              none        246    5.7e-56 1     1   0.930     1.155
*    Bacillus_megaterium_1006007@AEN88081                 none        208    1.3e-55 1     1   0.869     0.977
*    Tolumonas_auensis_595494@ACQ92628                    none        533    1.9e-55 1     1   0.911     2.502
*    Rhodovulum_sp._1187851@EJW13402                      none        251    2.1e-55 1     1   0.901     1.178
*    Enterococcus_pallens_1158607@EOU15019                none        218    5.4e-55 1     1   0.883     1.023
*    Tistrella_mobilis_1110502@AFK56498                   none        228    6.5e-55 1     1   0.911     1.070
     Deferribacter_desulfuricans_639282@BAI80200          none        709    1.1e-54 1     1   0.263     3.329
*    Clostridium_tetani_212717@AAO35487                   none        240    1.4e-54 1     1   0.915     1.127
*    Enterococcus_faecalis_1158663@EOJ06185               none        216    2.9e-54 1     1   0.878     1.014
*    Krokinobacter_sp._983548@AEE18286                    none        242    2.9e-54 1     1   0.911     1.136
*    Myxococcus_xanthus_246197@ABF91494                   none        234    3.2e-54 1     1   0.906     1.099
*    Enterococcus_sulfureus_1140003@EOT87665              none        210    4.2e-54 1     1   0.878     0.986
*    Atopobium_vaginae_525256@EGF23167                    none        248    4.6e-54 1     1   0.915     1.164
*    Olsenella_uli_633147@ADK68824                        none        240    5.1e-54 1     1   0.897     1.127
     Nitrosomonas_eutropha_335283@ABI58807                none        345    5.4e-54 1     1   0.122     1.620
*    Cesiribacter_andamanensis_1279009@EMR01711           none        254    5.6e-54 1     1   0.930     1.192
*    Mesorhizobium_loti_266835@BAB51197                   none        236    6.3e-54 1     1   0.925     1.108
*    Enterococcus_casseliflavus_565652@EEV29916           none        216    6.5e-54 1     1   0.883     1.014
*    Rhodopirellula_europaea_1263867@EMB17723             none        248    7.9e-54 1     1   0.930     1.164
*    Planctomyces_maris_344747@EDL59677                   none        248    9.9e-54 1     1   0.930     1.164
*    Leeuwenhoekiella_blandensis_398720@EAQ48771          none        243    1.4e-53 1     1   0.934     1.141
*    Roseomonas_cervicalis_525371@EFH12025                none        245    2.3e-53 1     1   0.906     1.150
*    Atopobium_rimae_553184@EEE17627                      none        260    2.8e-53 1     1   0.915     1.221
*    Azorhizobium_caulinodans_438753@BAF89997             none        256    2.9e-53 1     1   0.934     1.202
*    Enterococcus_asini_1158606@EOT57035                  none        216    3e-53   1     1   0.887     1.014
*    Psychrobacter_cryohalolentis_335284@ABE76281         none        331    3.5e-53 1     1   0.915     1.554
*    Opitutus_terrae_452637@ACB73488                      none        242    3.6e-53 1     1   0.906     1.136
*    Staphylococcus_pettenkoferi_904314@EHM72354          none        204    3.9e-53 1     1   0.892     0.958
*    Polaribacter_sp._313598@EAQ42250                     none        242    4.1e-53 1     1   0.920     1.136
*    Salimicrobium_sp._1230341@EKE31691                   none        230    4.6e-53 1     1   0.939     1.080
*    Streptococcus_equi_40041@CAW98176                    none        216    4.6e-53 1     1   0.897     1.014
*    Mesorhizobium_loti_266835@BAB53720                   none        230    6.3e-53 1     1   0.948     1.080
*    Mesorhizobium_loti_266835@BAB54865                   none        238    7.7e-53 1     1   0.944     1.117
*    Spirosoma_linguale_504472@ADB42688                   none        251    8.9e-53 1     1   0.930     1.178
*    Robiginitalea_biformata_313596@EAR14610              none        246    1.1e-52 1     1   0.911     1.155
*    Pontibacter_sp._1144253@EJF09742                     none        263    1.4e-52 1     1   0.915     1.235
*    Oscillatoria_acuminata_56110@AFY82089                none        244    1.5e-52 1     1   0.915     1.146
*    Carboxydothermus_hydrogenoformans_246194@ABB14572    none        216    1.6e-52 1     1   0.930     1.014
*    Parascardovia_denticolens_641144@EFG32644            none        264    3.2e-52 1     1   0.901     1.239
*    Geobacter_bemidjiensis_404380@ACH37799               none        252    3.6e-52 1     1   0.925     1.183
*    Arthrobacter_aurescens_290340@ABM09950               none        276    3.8e-52 1     1   0.901     1.296
*    Rubrobacter_xylanophilus_266117@ABG03209             none        238    4.6e-52 1     1   0.906     1.117
*    Scardovia_inopinata_641146@EFG26502                  none        246    6.6e-52 1     1   0.836     1.155
*    Gracilibacillus_halophilus_1308866@ENH97249          none        226    6.9e-52 1     1   0.920     1.061
*    Thermobaculum_terrenum_525904@ACZ41329               none        252    8.6e-52 1     1   0.934     1.183
*    Pontibacter_sp._1144253@EJF08271                     none        235    9.7e-52 1     1   0.911     1.103
*    Aerococcus_viridans_655812@EFG49715                  none        231    1.9e-51 1     1   0.915     1.085
*    Bacillus_subtilis_1147161@AGG61352                   none        203    2e-51   1     1   0.845     0.953
*    Bacillus_subtilis_1204343@BAM52631                   none        203    2e-51   1     1   0.845     0.953
*    Haloplasma_contractile_1033810@EGM25763              none        239    2.2e-51 1     1   0.915     1.122
*    Haloplasma_contractile_1033810@EGM29912              none        239    2.2e-51 1     1   0.915     1.122
*    Psychrobacter_sp._349106@ABQ94025                    none        331    2.6e-51 1     1   0.911     1.554
*    Lactobacillus_sp._872326@CCK84127                    none        221    3.6e-51 1     1   0.915     1.038
*    Staphylococcus_aureus_282458@CAG40426                none        204    3.8e-51 1     1   0.887     0.958
*    Pediococcus_acidilactici_1306952@EOA08128            none        211    3.8e-51 1     1   0.901     0.991
*    Bifidobacterium_gallicum_561180@EFA22864             none        232    4.1e-51 1     1   0.911     1.089
*    Ktedonobacter_racemifer_485913@EFH90230              none        294    4.3e-51 1     1   0.906     1.380
*    Bacillus_nealsonii_1202533@EOR24990                  none        219    4.6e-51 1     1   0.934     1.028
*    Atopobium_parvulum_521095@ACV51745                   none        238    4.7e-51 1     1   0.920     1.117
*    Psychrobacter_cryohalolentis_335284@ABE75027         none        331    5.3e-51 1     1   0.930     1.554
*    Macrococcus_caseolyticus_458233@BAH17775             none        207    6.5e-51 1     1   0.901     0.972
*    Listeria_monocytogenes_1639@CCQ21097                 none        217    7.3e-51 1     1   0.897     1.019
*    Hyphomonas_neptunium_228405@ABI75362                 none        230    8.9e-51 1     1   0.901     1.080
*    Bacillus_sp._666686@AGK52556                         none        225    1.2e-50 1     1   0.911     1.056
*    Scardovia_wiggsiae_857290@EJD64896                   none        326    1.3e-50 1     1   0.897     1.531
*    Aerococcus_urinae_866775@AEA01410                    none        295    1.7e-50 1     1   0.887     1.385
*    Solobacterium_moorei_706433@EFW24906                 none        209    2.7e-50 1     1   0.906     0.981
*    Brevibacillus_sp._1144311@EJL41297                   none        222    3.4e-50 1     1   0.892     1.042
*    Dolosigranulum_pigrum_883103@EHR35184                none        218    4e-50   1     1   0.901     1.023
*    Truepera_radiovictrix_649638@ADI14034                none        279    4.4e-50 1     1   0.939     1.310
*    Listeria_grayi_525367@EFI84470                       none        232    4.8e-50 1     1   0.934     1.089
*    Caulobacter_crescentus_190650@AAK24981               none        259    5.6e-50 1     1   0.911     1.216
*    Alloiococcus_otitis_883081@EKU92949                  none        219    6.1e-50 1     1   0.897     1.028
*    Lactobacillus_rhamnosus_568704@CAR89737              none        223    6.3e-50 1     1   0.920     1.047
*    Xanthomonas_axonopodis_1085630@CCF66452              none        204    7.3e-50 1     1   0.892     0.958
*    Bacillus_clausii_66692@BAD65430                      none        208    8.1e-50 1     1   0.897     0.977
*    Anaerofustis_stercorihominis_445971@EDS72172         none        217    8.1e-50 1     1   0.911     1.019
*    Helicobacter_cetorum_1163745@AFI05441                none        227    1.1e-49 1     1   0.887     1.066
*    Lactobacillus_buchneri_1071400@AFS00432              none        213    1.4e-49 1     1   0.897     1.000
*    Weissella_confusa_1127131@CCF30672                   none        208    1.6e-49 1     1   0.897     0.977
*    Listeria_grayi_525367@EFI83470                       none        230    1.8e-49 1     1   0.934     1.080
*    Deinococcus_deserti_546414@ACO46049                  none        236    2.2e-49 1     1   0.897     1.108
*    Desulfovibrio_africanus_1262666@EMG35817             none        299    3e-49   1     1   0.901     1.404
*    Ktedonobacter_racemifer_485913@EFH90556              none        272    4.3e-49 1     1   0.911     1.277
*    Aminobacterium_colombiense_572547@ADE56604           none        704    4.5e-49 1     1   0.934     3.305
*    Bacillus_stratosphericus_1236481@EMI11977            none        212    4.6e-49 1     1   0.869     0.995
*    Listeria_monocytogenes_1639@CCQ21567                 none        231    5.7e-49 1     1   0.911     1.085
*    Segniliparus_rugosus_679197@EFV11956                 none        256    5.9e-49 1     1   0.803     1.202
*    Thermus_scotoductus_743525@ADW22350                  none        212    6e-49   1     1   0.854     0.995
*    Cyanothece_sp._395961@ACL45187                       none        252    6.1e-49 1     1   0.911     1.183
*    Bordetella_holmesii_1281885@EMD76860                 none        248    7.3e-49 1     1   0.897     1.164
*    Haliangium_ochraceum_502025@ACY14375                 none        282    8.2e-49 1     1   0.911     1.324
*    Staphylococcus_pseudintermedius_984892@ADX76632      none        207    9.8e-49 1     1   0.883     0.972
*    Melissococcus_plutonius_1090974@BAL61666             none        224    1.4e-48 1     1   0.930     1.052
*    Gemella_haemolysans_546270@EER67761                  none        202    1.6e-48 1     1   0.873     0.948
*    Brevibacillus_laterosporus_1118154@CCF15846          none        220    1.7e-48 1     1   0.925     1.033
*    Lactobacillus_crispatus_748671@CBL51077              none        221    1.7e-48 1     1   0.887     1.038
*    Staphylococcus_massiliensis_1229783@EKU47500         none        208    1.8e-48 1     1   0.892     0.977
*    Helicobacter_pylori_85963@AAD06379                   none        228    2.2e-48 1     1   0.901     1.070
*    Clostridium_ultunense_1288971@CCQ93525               none        204    2.5e-48 1     1   0.901     0.958
*    Joostella_marina_926559@EIJ39316                     none        223    3.8e-48 1     1   0.925     1.047
*    Pedobacter_saltans_762903@ADY51686                   none        218    4e-48   1     1   0.892     1.023
*    Deinococcus_gobiensis_745776@AFD24371                none        198    4.7e-48 1     1   0.808     0.930
*    Streptococcus_pyogenes_1235829@AFV37449              none        216    4.9e-48 1     1   0.897     1.014
*    Thermovirga_lienii_580340@AER67233                   none        250    5.5e-48 1     1   0.822     1.174
*    Syntrophus_aciditrophicus_56780@ABC76372             none        242    7.3e-48 1     1   0.892     1.136
*    Sorangium_cellulosum_448385@CAN99160                 none        309    7.5e-48 1     1   0.906     1.451
*    Weissella_confusa_1127131@CCF30711                   none        231    7.6e-48 1     1   0.887     1.085
*    Rhodococcus_sp._1268303@CCQ17754                     none        183    9e-48   1     1   0.798     0.859
*    Bacillus_thuringiensis_1195464@AFU11941              none        205    1.4e-47 1     1   0.883     0.962
*    Helicobacter_mustelae_679897@CBG39985                none        209    2.1e-47 1     1   0.892     0.981
*    Saccharimonas_aalborgensis_1332188@AGL62109          none        246    3.5e-47 1     1   0.939     1.155
*    Deinococcus_deserti_546414@ACO45175                  none        239    3.6e-47 1     1   0.887     1.122
*    Gloeocapsa_sp._102232@ELR98864                       none        209    3.7e-47 1     1   0.864     0.981
*    Coriobacterium_glomerans_700015@AEB06813             none        211    3.7e-47 1     1   0.887     0.991
*    Microcoleus_sp._1173027@AFZ19920                     none        256    3.8e-47 1     1   0.901     1.202
*    Solibacillus_silvestris_1002809@BAK14800             none        197    4.7e-47 1     1   0.897     0.925
*    Staphylococcus_simulans_883166@EKS25136              none        207    6.1e-47 1     1   0.883     0.972
*    Nitrosococcus_watsonii_105559@ADJ27340               none        273    1.2e-46 1     1   0.883     1.282
*    Paenibacillus_polymyxa_886882@ADO58467               none        237    1.6e-46 1     1   0.911     1.113
*    Deinococcus_gobiensis_745776@AFD25500                none        179    1.7e-46 1     1   0.770     0.840
*    Sulfurovum_sp._1165841@EIF51488                      none        215    2.2e-46 1     1   0.887     1.009
*    Brevibacterium_mcbrellneri_585530@EFG47975           none        251    3.4e-46 1     1   0.911     1.178
*    Bacillus_selenitireducens_439292@ADI00405            none        218    5.1e-46 1     1   0.878     1.023
*    Deinococcus_maricopensis_709986@ADV67026             none        235    5.8e-46 1     1   0.869     1.103
*    Streptococcus_pneumoniae_373153@ABJ55342             none        216    6e-46   1     1   0.887     1.014
     Methylovorus_sp._887061@ADQ85527                     none        258    6.1e-46 1     1   0.254     1.211
*    Salinisphaera_shabanensis_1033802@EGM28989           none        288    1e-45   1     1   0.915     1.352
*    Enterococcus_pallens_1158607@EOU16302                none        190    1.8e-45 1     1   0.873     0.892
*    Zymomonas_mobilis_627344@AFN56649                    none        235    2.6e-45 1     1   0.906     1.103
     Bacillus_thuringiensis_1195464@AFU12901              none        156    2.7e-45 1     1   0.681     0.732
*    Lactobacillus_pentosus_1136177@EIW14130              none        216    3.3e-45 1     1   0.873     1.014
*    Stanieria_cyanosphaera_111780@AFZ35174               none        221    4.1e-45 1     1   0.892     1.038
*    Pediococcus_pentosaceus_1133596@CCG89996             none        227    4.4e-45 1     1   0.897     1.066
*    Lactococcus_lactis_1111678@AFW91609                  none        218    6.7e-45 1     1   0.897     1.023
*    Lactobacillus_oris_944562@EGS39494                   none        216    6.9e-45 1     1   0.887     1.014
*    Lactobacillus_crispatus_748671@CBL50527              none        210    7.6e-45 1     1   0.897     0.986
*    Clostridium_ramosum_445974@EDS20177                  none        200    8.5e-45 1     1   0.859     0.939
     Bacillus_nealsonii_1202533@EOR22662                  none        132    1e-44   1     1   0.577     0.620
*    Cyanothece_sp._41431@ACK68321                        none        229    1.3e-44 1     1   0.887     1.075
*    Herpetosiphon_aurantiacus_316274@ABX05452            none        238    1.4e-44 1     1   0.925     1.117
*    Lactobacillus_buchneri_1071400@AFS00859              none        221    1.9e-44 1     1   0.873     1.038
*    Paenibacillus_mucilaginosus_997761@AFH61817          none        216    2.5e-44 1     1   0.878     1.014
*    Xylella_fastidiosa_405441@ACB93459                   none        235    2.7e-44 1     1   0.873     1.103
*    Gloeocapsa_sp._102232@ELR98104                       none        217    4.5e-44 1     1   0.854     1.019
*    Moorella_thermoacetica_264732@ABC19666               none        201    5e-44   1     1   0.878     0.944
*    Lysinibacillus_fusiformis_1231627@EKU44272           none        202    5.9e-44 1     1   0.915     0.948
*    Paenibacillus_curdlanolyticus_717606@EFM12020        none        212    6.2e-44 1     1   0.906     0.995
*    Clostridium_phytofermentans_357809@ABX41065          none        208    6.6e-44 1     1   0.897     0.977
*    Acinetobacter_radioresistens_903900@EJO34596         none        213    8.8e-44 1     1   0.911     1.000
*    Coprobacillus_sp._469596@EFW05673                    none        187    1.5e-43 1     1   0.897     0.878
*    Oenococcus_kitaharae_1045004@EHN59593                none        215    1.9e-43 1     1   0.826     1.009
*    Acinetobacter_baumannii_696749@ADX04671              none        208    2.2e-43 1     1   0.873     0.977
*    Lactobacillus_murinus_1235801@EMZ16325               none        213    3.2e-43 1     1   0.869     1.000
*    Actinomyces_graevenitzii_435830@EHM89689             none        224    3.7e-43 1     1   0.878     1.052
*    Cyanothece_sp._497965@ADN15154                       none        219    4.3e-43 1     1   0.864     1.028
*    Commensalibacter_intestini_1088868@EHD13103          none        206    4.8e-43 1     1   0.873     0.967
*    Actinomyces_sp._1105029@EJN45844                     none        213    4.9e-43 1     1   0.845     1.000
*    Streptomyces_sp._465541@EDX21624                     none        255    6.3e-43 1     1   0.897     1.197
*    Leuconostoc_citreum_1127129@CCF28724                 none        212    6.5e-43 1     1   0.892     0.995
*    Helicobacter_suis_710394@EFX42398                    none        222    8.9e-43 1     1   0.892     1.042
*    Bacillus_selenitireducens_439292@ADH97722            none        217    9e-43   1     1   0.901     1.019
*    Lactobacillus_gastricus_1144300@EHS87085             none        222    1e-42   1     1   0.883     1.042
*    Oenococcus_kitaharae_1045004@EHN58688                none        221    2.1e-42 1     1   0.883     1.038
*    Acinetobacter_bouvetii_1120925@ENV81913              none        199    2.5e-42 1     1   0.883     0.934
*    Turicibacter_sp._910310@EGC92823                     none        216    3e-42   1     1   0.906     1.014
*    Nitrolancea_hollandica_1129897@CCF82852              none        253    3e-42   1     1   0.873     1.188
*    Streptomyces_coelicolor_100226@CAA20086              none        272    3.2e-42 1     1   0.850     1.277
*    Helicobacter_felis_936155@CBY82396                   none        199    3.8e-42 1     1   0.826     0.934
*    Parvimonas_sp._944565@EGV08763                       none        209    5e-42   1     1   0.892     0.981
*    Dehalococcoides_mccartyi_1193807@AGG06846            none        207    5.1e-42 1     1   0.873     0.972
*    Lactobacillus_salivarius_712961@ADJ79487             none        208    6.3e-42 1     1   0.845     0.977
*    Staphylococcus_aureus_282458@CAG39476                none        224    6.7e-42 1     1   0.897     1.052
*    Cyanothece_sp._65393@ACK73666                        none        220    7.5e-42 1     1   0.878     1.033
*    Pediococcus_acidilactici_1306952@EOA08643            none        226    2.3e-41 1     1   0.901     1.061
*    Streptococcus_pasteurianus_981540@BAK30621           none        218    3.2e-41 1     1   0.887     1.023
*    Lactobacillus_florum_1221537@EKK20560                none        221    6.8e-41 1     1   0.878     1.038
*    Finegoldia_magna_866779@EGS32593                     none        209    7.9e-41 1     1   0.911     0.981
*    Streptomyces_sp._253839@EFL19643                     none        268    1e-40   1     1   0.887     1.258
*    Ktedonobacter_racemifer_485913@EFH80739              none        276    1.1e-40 1     1   0.934     1.296
*    Leuconostoc_citreum_1127129@CCF29515                 none        215    2e-40   1     1   0.869     1.009
*    Janthinobacterium_sp._375286@ABR90578                none        231    2.4e-40 1     1   0.883     1.085
*    Mycobacterium_tuberculosis_83332@AFN48163            none        238    5.3e-40 1     1   0.897     1.117
*    Streptomyces_sp._465541@EDX21576                     none        283    5.7e-40 1     1   0.897     1.329
*    Acidithiobacillus_ferrooxidans_380394@ACH82784       none        248    1.8e-39 1     1   0.911     1.164
*    Exiguobacterium_sp._856854@EPE61043                  none        194    2e-39   1     1   0.850     0.911
*    Chloracidobacterium_thermophilum_981222@AEP12562     none        232    2e-39   1     1   0.850     1.089
*    Actinomyces_cardiffensis_888050@ENO18360             none        240    2.4e-39 1     1   0.869     1.127
*    marine_actinobacterium_312284@EAR25301               none        254    2.4e-39 1     1   0.911     1.192
*    Lactobacillus_salivarius_712961@ADJ79041             none        225    1.2e-38 1     1   0.897     1.056
     Pediococcus_pentosaceus_1133596@CCG90416             none        120    1.2e-38 1     1   0.526     0.563
*    Lactobacillus_oris_944562@EGS35788                   none        224    1.4e-38 1     1   0.892     1.052
*    Microcystis_aeruginosa_213618@CCI09118               none        216    2.5e-38 1     1   0.906     1.014
*    Synechococcus_sp._91464@EDX83995                     none        246    2.6e-38 1     1   0.911     1.155
*    Thermomicrobium_roseum_309801@ACM04857               none        216    3.7e-38 1     1   0.864     1.014
*    Kocuria_rhizophila_378753@BAG30395                   none        243    1.3e-37 1     1   0.897     1.141
*    gamma_proteobacterium_83406@CBL43600                 none        263    1.7e-36 1     1   0.869     1.235
     Streptomyces_griseoflavus_467200@EFL42720            none        183    2.4e-36 1     1   0.634     0.859
*    Renibacterium_salmoninarum_288705@ABY23844           none        283    2.7e-36 1     1   0.779     1.329
*    Lactobacillus_pentosus_1136177@EIW14677              none        220    2.9e-36 1     1   0.883     1.033
*    Parvimonas_sp._944565@EGV09241                       none        203    1.6e-35 1     1   0.892     0.953
*    Ktedonobacter_racemifer_485913@EFH80622              none        253    1.8e-35 1     1   0.930     1.188
*    Corynebacterium_casei_1110505@CCE55849               none        174    6.4e-35 1     1   0.742     0.817
*    Finegoldia_magna_866779@EGS32533                     none        211    8.9e-35 1     1   0.883     0.991
*    Corynebacterium_matruchotii_553207@EFM49520          none        168    1.8e-33 1     1   0.770     0.789
*    Corynebacterium_amycolatum_553204@EEB64190           none        215    5e-33   1     1   0.864     1.009
*    Dehalogenimonas_lykanthroporepellens_552811@ADJ25427 none        207    2.5e-32 1     1   0.864     0.972
*    Ignavibacterium_album_945713@AFH49870                none        219    4.2e-31 1     1   0.925     1.028
*    actinobacterium_SCGC_913338@EJX36112                 none        213    1e-29   1     1   0.897     1.000
*    Actinomyces_coleocanis_525245@EEH64406               none        219    4.8e-27 1     1   0.840     1.028
*    Oenococcus_oeni_203123@ABJ56439                      none        212    5.2e-27 1     1   0.826     0.995
     Mesoplasma_florum_265311@AAT75823                    none        299    2.9e-25 1     1   0.427     1.404
*    Helicobacter_pylori_85963@AAD05898                   none        220    3.7e-22 1     1   0.897     1.033
     Lactobacillus_mali_1046596@EJF01642                  none        127    1.8e-19 1     1   0.540     0.596
*    Lactobacillus_mali_1046596@EJF01639                  none        161    8.6e-08 1     1   0.751     0.756
=====================================================================================================================
EOT

    cmp_ok $oum->list_selection( 'keep' ), 'eq', <<'EOT', 'got expected selection list (keep after filtering) with default values';
=====================================================================================================================
keep accession                                            description length evalue  count max alignment ratio_length
---------------------------------------------------------------------------------------------------------------------
*    Cyanothece_sp._497965@ADN14832                       none        371    3.5e-65 1     1   0.897     1.742
*    Cyanothece_sp._65393@ACK69229                        none        360    3.5e-63 1     1   0.840     1.690
*    Nostoc_sp._103690@BAB77266                           none        232    8.2e-63 1     1   0.911     1.089
*    Gloeocapsa_sp._1173026@AFZ30697                      none        230    1.6e-62 1     1   0.939     1.080
*    Nostoc_sp._103690@BAB78081                           none        320    6.3e-62 1     1   0.892     1.502
*    Rivularia_sp._373994@AFY57759                        none        240    1.2e-61 1     1   0.911     1.127
*    Synechocystis_sp._927677@ELR88413                    none        217    2e-61   1     1   0.901     1.019
*    Sulfurimonas_autotrophica_563040@ADN08900            none        675    2.1e-61 1     1   0.906     3.169
*    Desulfotomaculum_carboxydivorans_868595@AEF93225     none        233    6.6e-61 1     1   0.897     1.094
*    Microcoleus_vaginatus_756067@EGK88082                none        237    1.5e-60 1     1   0.911     1.113
*    Paenibacillus_polymyxa_886882@ADO56408               none        223    3.6e-60 1     1   0.906     1.047
*    Chamaesiphon_minutus_1173020@AFY95414                none        218    4.9e-60 1     1   0.887     1.023
*    Bacillus_macauensis_1196324@EIT85841                 none        231    5.8e-60 1     1   0.944     1.085
*    Paenibacillus_sp._481743@ACX66507                    none        228    6.5e-60 1     1   0.906     1.070
*    Pelosinus_fermentans_1122947@EIW31336                none        227    1.3e-59 1     1   0.925     1.066
*    Stanieria_cyanosphaera_111780@AFZ34417               none        239    2.8e-58 1     1   0.925     1.122
*    Chamaesiphon_minutus_1173020@AFY93037                none        214    3.4e-58 1     1   0.873     1.005
*    Gillisia_limnaea_865937@EHQ04246                     none        248    4.7e-58 1     1   0.958     1.164
*    Paenibacillus_curdlanolyticus_717606@EFM13001        none        219    8.9e-58 1     1   0.920     1.028
*    Halobacillus_halophilus_866895@CCG44366              none        241    2.3e-57 1     1   0.934     1.131
*    Kyrpidia_tusciae_562970@ADG04796                     none        208    3.5e-57 1     1   0.883     0.977
*    Sporosarcina_newyorkensis_1027292@EGQ24744           none        270    3.9e-57 1     1   0.930     1.268
*    Aequorivita_sublithincola_746697@AFL81580            none        242    1.6e-56 1     1   0.930     1.136
*    Hippea_maritima_760142@AEA33167                      none        698    1.8e-56 1     1   0.906     3.277
*    Enterococcus_italicus_888064@EFU72982                none        221    2e-56   1     1   0.883     1.038
*    Carnobacterium_sp._208596@AEB29259                   none        219    3.2e-56 1     1   0.925     1.028
*    Pelosinus_fermentans_1122947@EIW29018                none        380    5.3e-56 1     1   0.944     1.784
*    Fulvivirga_imtechensis_1237149@ELR72804              none        246    5.7e-56 1     1   0.930     1.155
*    Bacillus_megaterium_1006007@AEN88081                 none        208    1.3e-55 1     1   0.869     0.977
*    Tolumonas_auensis_595494@ACQ92628                    none        533    1.9e-55 1     1   0.911     2.502
*    Rhodovulum_sp._1187851@EJW13402                      none        251    2.1e-55 1     1   0.901     1.178
*    Enterococcus_pallens_1158607@EOU15019                none        218    5.4e-55 1     1   0.883     1.023
*    Tistrella_mobilis_1110502@AFK56498                   none        228    6.5e-55 1     1   0.911     1.070
*    Clostridium_tetani_212717@AAO35487                   none        240    1.4e-54 1     1   0.915     1.127
*    Enterococcus_faecalis_1158663@EOJ06185               none        216    2.9e-54 1     1   0.878     1.014
*    Krokinobacter_sp._983548@AEE18286                    none        242    2.9e-54 1     1   0.911     1.136
*    Myxococcus_xanthus_246197@ABF91494                   none        234    3.2e-54 1     1   0.906     1.099
*    Enterococcus_sulfureus_1140003@EOT87665              none        210    4.2e-54 1     1   0.878     0.986
*    Atopobium_vaginae_525256@EGF23167                    none        248    4.6e-54 1     1   0.915     1.164
*    Olsenella_uli_633147@ADK68824                        none        240    5.1e-54 1     1   0.897     1.127
*    Cesiribacter_andamanensis_1279009@EMR01711           none        254    5.6e-54 1     1   0.930     1.192
*    Mesorhizobium_loti_266835@BAB51197                   none        236    6.3e-54 1     1   0.925     1.108
*    Enterococcus_casseliflavus_565652@EEV29916           none        216    6.5e-54 1     1   0.883     1.014
*    Rhodopirellula_europaea_1263867@EMB17723             none        248    7.9e-54 1     1   0.930     1.164
*    Planctomyces_maris_344747@EDL59677                   none        248    9.9e-54 1     1   0.930     1.164
*    Leeuwenhoekiella_blandensis_398720@EAQ48771          none        243    1.4e-53 1     1   0.934     1.141
*    Roseomonas_cervicalis_525371@EFH12025                none        245    2.3e-53 1     1   0.906     1.150
*    Atopobium_rimae_553184@EEE17627                      none        260    2.8e-53 1     1   0.915     1.221
*    Azorhizobium_caulinodans_438753@BAF89997             none        256    2.9e-53 1     1   0.934     1.202
*    Enterococcus_asini_1158606@EOT57035                  none        216    3e-53   1     1   0.887     1.014
*    Psychrobacter_cryohalolentis_335284@ABE76281         none        331    3.5e-53 1     1   0.915     1.554
*    Opitutus_terrae_452637@ACB73488                      none        242    3.6e-53 1     1   0.906     1.136
*    Staphylococcus_pettenkoferi_904314@EHM72354          none        204    3.9e-53 1     1   0.892     0.958
*    Polaribacter_sp._313598@EAQ42250                     none        242    4.1e-53 1     1   0.920     1.136
*    Salimicrobium_sp._1230341@EKE31691                   none        230    4.6e-53 1     1   0.939     1.080
*    Streptococcus_equi_40041@CAW98176                    none        216    4.6e-53 1     1   0.897     1.014
*    Mesorhizobium_loti_266835@BAB53720                   none        230    6.3e-53 1     1   0.948     1.080
*    Mesorhizobium_loti_266835@BAB54865                   none        238    7.7e-53 1     1   0.944     1.117
*    Spirosoma_linguale_504472@ADB42688                   none        251    8.9e-53 1     1   0.930     1.178
*    Robiginitalea_biformata_313596@EAR14610              none        246    1.1e-52 1     1   0.911     1.155
*    Pontibacter_sp._1144253@EJF09742                     none        263    1.4e-52 1     1   0.915     1.235
*    Oscillatoria_acuminata_56110@AFY82089                none        244    1.5e-52 1     1   0.915     1.146
*    Carboxydothermus_hydrogenoformans_246194@ABB14572    none        216    1.6e-52 1     1   0.930     1.014
*    Parascardovia_denticolens_641144@EFG32644            none        264    3.2e-52 1     1   0.901     1.239
*    Geobacter_bemidjiensis_404380@ACH37799               none        252    3.6e-52 1     1   0.925     1.183
*    Arthrobacter_aurescens_290340@ABM09950               none        276    3.8e-52 1     1   0.901     1.296
*    Rubrobacter_xylanophilus_266117@ABG03209             none        238    4.6e-52 1     1   0.906     1.117
*    Scardovia_inopinata_641146@EFG26502                  none        246    6.6e-52 1     1   0.836     1.155
*    Gracilibacillus_halophilus_1308866@ENH97249          none        226    6.9e-52 1     1   0.920     1.061
*    Thermobaculum_terrenum_525904@ACZ41329               none        252    8.6e-52 1     1   0.934     1.183
*    Pontibacter_sp._1144253@EJF08271                     none        235    9.7e-52 1     1   0.911     1.103
*    Aerococcus_viridans_655812@EFG49715                  none        231    1.9e-51 1     1   0.915     1.085
*    Bacillus_subtilis_1147161@AGG61352                   none        203    2e-51   1     1   0.845     0.953
*    Bacillus_subtilis_1204343@BAM52631                   none        203    2e-51   1     1   0.845     0.953
*    Haloplasma_contractile_1033810@EGM25763              none        239    2.2e-51 1     1   0.915     1.122
*    Haloplasma_contractile_1033810@EGM29912              none        239    2.2e-51 1     1   0.915     1.122
*    Psychrobacter_sp._349106@ABQ94025                    none        331    2.6e-51 1     1   0.911     1.554
*    Lactobacillus_sp._872326@CCK84127                    none        221    3.6e-51 1     1   0.915     1.038
*    Staphylococcus_aureus_282458@CAG40426                none        204    3.8e-51 1     1   0.887     0.958
*    Pediococcus_acidilactici_1306952@EOA08128            none        211    3.8e-51 1     1   0.901     0.991
*    Bifidobacterium_gallicum_561180@EFA22864             none        232    4.1e-51 1     1   0.911     1.089
*    Ktedonobacter_racemifer_485913@EFH90230              none        294    4.3e-51 1     1   0.906     1.380
*    Bacillus_nealsonii_1202533@EOR24990                  none        219    4.6e-51 1     1   0.934     1.028
*    Atopobium_parvulum_521095@ACV51745                   none        238    4.7e-51 1     1   0.920     1.117
*    Psychrobacter_cryohalolentis_335284@ABE75027         none        331    5.3e-51 1     1   0.930     1.554
*    Macrococcus_caseolyticus_458233@BAH17775             none        207    6.5e-51 1     1   0.901     0.972
*    Listeria_monocytogenes_1639@CCQ21097                 none        217    7.3e-51 1     1   0.897     1.019
*    Hyphomonas_neptunium_228405@ABI75362                 none        230    8.9e-51 1     1   0.901     1.080
*    Bacillus_sp._666686@AGK52556                         none        225    1.2e-50 1     1   0.911     1.056
*    Scardovia_wiggsiae_857290@EJD64896                   none        326    1.3e-50 1     1   0.897     1.531
*    Aerococcus_urinae_866775@AEA01410                    none        295    1.7e-50 1     1   0.887     1.385
*    Solobacterium_moorei_706433@EFW24906                 none        209    2.7e-50 1     1   0.906     0.981
*    Brevibacillus_sp._1144311@EJL41297                   none        222    3.4e-50 1     1   0.892     1.042
*    Dolosigranulum_pigrum_883103@EHR35184                none        218    4e-50   1     1   0.901     1.023
*    Truepera_radiovictrix_649638@ADI14034                none        279    4.4e-50 1     1   0.939     1.310
*    Listeria_grayi_525367@EFI84470                       none        232    4.8e-50 1     1   0.934     1.089
*    Caulobacter_crescentus_190650@AAK24981               none        259    5.6e-50 1     1   0.911     1.216
*    Alloiococcus_otitis_883081@EKU92949                  none        219    6.1e-50 1     1   0.897     1.028
*    Lactobacillus_rhamnosus_568704@CAR89737              none        223    6.3e-50 1     1   0.920     1.047
*    Xanthomonas_axonopodis_1085630@CCF66452              none        204    7.3e-50 1     1   0.892     0.958
*    Bacillus_clausii_66692@BAD65430                      none        208    8.1e-50 1     1   0.897     0.977
*    Anaerofustis_stercorihominis_445971@EDS72172         none        217    8.1e-50 1     1   0.911     1.019
*    Helicobacter_cetorum_1163745@AFI05441                none        227    1.1e-49 1     1   0.887     1.066
*    Lactobacillus_buchneri_1071400@AFS00432              none        213    1.4e-49 1     1   0.897     1.000
*    Weissella_confusa_1127131@CCF30672                   none        208    1.6e-49 1     1   0.897     0.977
*    Listeria_grayi_525367@EFI83470                       none        230    1.8e-49 1     1   0.934     1.080
*    Deinococcus_deserti_546414@ACO46049                  none        236    2.2e-49 1     1   0.897     1.108
*    Desulfovibrio_africanus_1262666@EMG35817             none        299    3e-49   1     1   0.901     1.404
*    Ktedonobacter_racemifer_485913@EFH90556              none        272    4.3e-49 1     1   0.911     1.277
*    Aminobacterium_colombiense_572547@ADE56604           none        704    4.5e-49 1     1   0.934     3.305
*    Bacillus_stratosphericus_1236481@EMI11977            none        212    4.6e-49 1     1   0.869     0.995
*    Listeria_monocytogenes_1639@CCQ21567                 none        231    5.7e-49 1     1   0.911     1.085
*    Segniliparus_rugosus_679197@EFV11956                 none        256    5.9e-49 1     1   0.803     1.202
*    Thermus_scotoductus_743525@ADW22350                  none        212    6e-49   1     1   0.854     0.995
*    Cyanothece_sp._395961@ACL45187                       none        252    6.1e-49 1     1   0.911     1.183
*    Bordetella_holmesii_1281885@EMD76860                 none        248    7.3e-49 1     1   0.897     1.164
*    Haliangium_ochraceum_502025@ACY14375                 none        282    8.2e-49 1     1   0.911     1.324
*    Staphylococcus_pseudintermedius_984892@ADX76632      none        207    9.8e-49 1     1   0.883     0.972
*    Melissococcus_plutonius_1090974@BAL61666             none        224    1.4e-48 1     1   0.930     1.052
*    Gemella_haemolysans_546270@EER67761                  none        202    1.6e-48 1     1   0.873     0.948
*    Brevibacillus_laterosporus_1118154@CCF15846          none        220    1.7e-48 1     1   0.925     1.033
*    Lactobacillus_crispatus_748671@CBL51077              none        221    1.7e-48 1     1   0.887     1.038
*    Staphylococcus_massiliensis_1229783@EKU47500         none        208    1.8e-48 1     1   0.892     0.977
*    Helicobacter_pylori_85963@AAD06379                   none        228    2.2e-48 1     1   0.901     1.070
*    Clostridium_ultunense_1288971@CCQ93525               none        204    2.5e-48 1     1   0.901     0.958
*    Joostella_marina_926559@EIJ39316                     none        223    3.8e-48 1     1   0.925     1.047
*    Pedobacter_saltans_762903@ADY51686                   none        218    4e-48   1     1   0.892     1.023
*    Deinococcus_gobiensis_745776@AFD24371                none        198    4.7e-48 1     1   0.808     0.930
*    Streptococcus_pyogenes_1235829@AFV37449              none        216    4.9e-48 1     1   0.897     1.014
*    Thermovirga_lienii_580340@AER67233                   none        250    5.5e-48 1     1   0.822     1.174
*    Syntrophus_aciditrophicus_56780@ABC76372             none        242    7.3e-48 1     1   0.892     1.136
*    Sorangium_cellulosum_448385@CAN99160                 none        309    7.5e-48 1     1   0.906     1.451
*    Weissella_confusa_1127131@CCF30711                   none        231    7.6e-48 1     1   0.887     1.085
*    Rhodococcus_sp._1268303@CCQ17754                     none        183    9e-48   1     1   0.798     0.859
*    Bacillus_thuringiensis_1195464@AFU11941              none        205    1.4e-47 1     1   0.883     0.962
*    Helicobacter_mustelae_679897@CBG39985                none        209    2.1e-47 1     1   0.892     0.981
*    Saccharimonas_aalborgensis_1332188@AGL62109          none        246    3.5e-47 1     1   0.939     1.155
*    Deinococcus_deserti_546414@ACO45175                  none        239    3.6e-47 1     1   0.887     1.122
*    Gloeocapsa_sp._102232@ELR98864                       none        209    3.7e-47 1     1   0.864     0.981
*    Coriobacterium_glomerans_700015@AEB06813             none        211    3.7e-47 1     1   0.887     0.991
*    Microcoleus_sp._1173027@AFZ19920                     none        256    3.8e-47 1     1   0.901     1.202
*    Solibacillus_silvestris_1002809@BAK14800             none        197    4.7e-47 1     1   0.897     0.925
*    Staphylococcus_simulans_883166@EKS25136              none        207    6.1e-47 1     1   0.883     0.972
*    Nitrosococcus_watsonii_105559@ADJ27340               none        273    1.2e-46 1     1   0.883     1.282
*    Paenibacillus_polymyxa_886882@ADO58467               none        237    1.6e-46 1     1   0.911     1.113
*    Deinococcus_gobiensis_745776@AFD25500                none        179    1.7e-46 1     1   0.770     0.840
*    Sulfurovum_sp._1165841@EIF51488                      none        215    2.2e-46 1     1   0.887     1.009
*    Brevibacterium_mcbrellneri_585530@EFG47975           none        251    3.4e-46 1     1   0.911     1.178
*    Bacillus_selenitireducens_439292@ADI00405            none        218    5.1e-46 1     1   0.878     1.023
*    Deinococcus_maricopensis_709986@ADV67026             none        235    5.8e-46 1     1   0.869     1.103
*    Streptococcus_pneumoniae_373153@ABJ55342             none        216    6e-46   1     1   0.887     1.014
*    Salinisphaera_shabanensis_1033802@EGM28989           none        288    1e-45   1     1   0.915     1.352
*    Enterococcus_pallens_1158607@EOU16302                none        190    1.8e-45 1     1   0.873     0.892
*    Zymomonas_mobilis_627344@AFN56649                    none        235    2.6e-45 1     1   0.906     1.103
*    Lactobacillus_pentosus_1136177@EIW14130              none        216    3.3e-45 1     1   0.873     1.014
*    Stanieria_cyanosphaera_111780@AFZ35174               none        221    4.1e-45 1     1   0.892     1.038
*    Pediococcus_pentosaceus_1133596@CCG89996             none        227    4.4e-45 1     1   0.897     1.066
*    Lactococcus_lactis_1111678@AFW91609                  none        218    6.7e-45 1     1   0.897     1.023
*    Lactobacillus_oris_944562@EGS39494                   none        216    6.9e-45 1     1   0.887     1.014
*    Lactobacillus_crispatus_748671@CBL50527              none        210    7.6e-45 1     1   0.897     0.986
*    Clostridium_ramosum_445974@EDS20177                  none        200    8.5e-45 1     1   0.859     0.939
*    Cyanothece_sp._41431@ACK68321                        none        229    1.3e-44 1     1   0.887     1.075
*    Herpetosiphon_aurantiacus_316274@ABX05452            none        238    1.4e-44 1     1   0.925     1.117
*    Lactobacillus_buchneri_1071400@AFS00859              none        221    1.9e-44 1     1   0.873     1.038
*    Paenibacillus_mucilaginosus_997761@AFH61817          none        216    2.5e-44 1     1   0.878     1.014
*    Xylella_fastidiosa_405441@ACB93459                   none        235    2.7e-44 1     1   0.873     1.103
*    Gloeocapsa_sp._102232@ELR98104                       none        217    4.5e-44 1     1   0.854     1.019
*    Moorella_thermoacetica_264732@ABC19666               none        201    5e-44   1     1   0.878     0.944
*    Lysinibacillus_fusiformis_1231627@EKU44272           none        202    5.9e-44 1     1   0.915     0.948
*    Paenibacillus_curdlanolyticus_717606@EFM12020        none        212    6.2e-44 1     1   0.906     0.995
*    Clostridium_phytofermentans_357809@ABX41065          none        208    6.6e-44 1     1   0.897     0.977
*    Acinetobacter_radioresistens_903900@EJO34596         none        213    8.8e-44 1     1   0.911     1.000
*    Coprobacillus_sp._469596@EFW05673                    none        187    1.5e-43 1     1   0.897     0.878
*    Oenococcus_kitaharae_1045004@EHN59593                none        215    1.9e-43 1     1   0.826     1.009
*    Acinetobacter_baumannii_696749@ADX04671              none        208    2.2e-43 1     1   0.873     0.977
*    Lactobacillus_murinus_1235801@EMZ16325               none        213    3.2e-43 1     1   0.869     1.000
*    Actinomyces_graevenitzii_435830@EHM89689             none        224    3.7e-43 1     1   0.878     1.052
*    Cyanothece_sp._497965@ADN15154                       none        219    4.3e-43 1     1   0.864     1.028
*    Commensalibacter_intestini_1088868@EHD13103          none        206    4.8e-43 1     1   0.873     0.967
*    Actinomyces_sp._1105029@EJN45844                     none        213    4.9e-43 1     1   0.845     1.000
*    Streptomyces_sp._465541@EDX21624                     none        255    6.3e-43 1     1   0.897     1.197
*    Leuconostoc_citreum_1127129@CCF28724                 none        212    6.5e-43 1     1   0.892     0.995
*    Helicobacter_suis_710394@EFX42398                    none        222    8.9e-43 1     1   0.892     1.042
*    Bacillus_selenitireducens_439292@ADH97722            none        217    9e-43   1     1   0.901     1.019
*    Lactobacillus_gastricus_1144300@EHS87085             none        222    1e-42   1     1   0.883     1.042
*    Oenococcus_kitaharae_1045004@EHN58688                none        221    2.1e-42 1     1   0.883     1.038
*    Acinetobacter_bouvetii_1120925@ENV81913              none        199    2.5e-42 1     1   0.883     0.934
*    Turicibacter_sp._910310@EGC92823                     none        216    3e-42   1     1   0.906     1.014
*    Nitrolancea_hollandica_1129897@CCF82852              none        253    3e-42   1     1   0.873     1.188
*    Streptomyces_coelicolor_100226@CAA20086              none        272    3.2e-42 1     1   0.850     1.277
*    Helicobacter_felis_936155@CBY82396                   none        199    3.8e-42 1     1   0.826     0.934
*    Parvimonas_sp._944565@EGV08763                       none        209    5e-42   1     1   0.892     0.981
*    Dehalococcoides_mccartyi_1193807@AGG06846            none        207    5.1e-42 1     1   0.873     0.972
*    Lactobacillus_salivarius_712961@ADJ79487             none        208    6.3e-42 1     1   0.845     0.977
*    Staphylococcus_aureus_282458@CAG39476                none        224    6.7e-42 1     1   0.897     1.052
*    Cyanothece_sp._65393@ACK73666                        none        220    7.5e-42 1     1   0.878     1.033
*    Pediococcus_acidilactici_1306952@EOA08643            none        226    2.3e-41 1     1   0.901     1.061
*    Streptococcus_pasteurianus_981540@BAK30621           none        218    3.2e-41 1     1   0.887     1.023
*    Lactobacillus_florum_1221537@EKK20560                none        221    6.8e-41 1     1   0.878     1.038
*    Finegoldia_magna_866779@EGS32593                     none        209    7.9e-41 1     1   0.911     0.981
*    Streptomyces_sp._253839@EFL19643                     none        268    1e-40   1     1   0.887     1.258
*    Ktedonobacter_racemifer_485913@EFH80739              none        276    1.1e-40 1     1   0.934     1.296
*    Leuconostoc_citreum_1127129@CCF29515                 none        215    2e-40   1     1   0.869     1.009
*    Janthinobacterium_sp._375286@ABR90578                none        231    2.4e-40 1     1   0.883     1.085
*    Mycobacterium_tuberculosis_83332@AFN48163            none        238    5.3e-40 1     1   0.897     1.117
*    Streptomyces_sp._465541@EDX21576                     none        283    5.7e-40 1     1   0.897     1.329
*    Acidithiobacillus_ferrooxidans_380394@ACH82784       none        248    1.8e-39 1     1   0.911     1.164
*    Exiguobacterium_sp._856854@EPE61043                  none        194    2e-39   1     1   0.850     0.911
*    Chloracidobacterium_thermophilum_981222@AEP12562     none        232    2e-39   1     1   0.850     1.089
*    Actinomyces_cardiffensis_888050@ENO18360             none        240    2.4e-39 1     1   0.869     1.127
*    marine_actinobacterium_312284@EAR25301               none        254    2.4e-39 1     1   0.911     1.192
*    Lactobacillus_salivarius_712961@ADJ79041             none        225    1.2e-38 1     1   0.897     1.056
*    Lactobacillus_oris_944562@EGS35788                   none        224    1.4e-38 1     1   0.892     1.052
*    Microcystis_aeruginosa_213618@CCI09118               none        216    2.5e-38 1     1   0.906     1.014
*    Synechococcus_sp._91464@EDX83995                     none        246    2.6e-38 1     1   0.911     1.155
*    Thermomicrobium_roseum_309801@ACM04857               none        216    3.7e-38 1     1   0.864     1.014
*    Kocuria_rhizophila_378753@BAG30395                   none        243    1.3e-37 1     1   0.897     1.141
*    gamma_proteobacterium_83406@CBL43600                 none        263    1.7e-36 1     1   0.869     1.235
*    Renibacterium_salmoninarum_288705@ABY23844           none        283    2.7e-36 1     1   0.779     1.329
*    Lactobacillus_pentosus_1136177@EIW14677              none        220    2.9e-36 1     1   0.883     1.033
*    Parvimonas_sp._944565@EGV09241                       none        203    1.6e-35 1     1   0.892     0.953
*    Ktedonobacter_racemifer_485913@EFH80622              none        253    1.8e-35 1     1   0.930     1.188
*    Corynebacterium_casei_1110505@CCE55849               none        174    6.4e-35 1     1   0.742     0.817
*    Finegoldia_magna_866779@EGS32533                     none        211    8.9e-35 1     1   0.883     0.991
*    Corynebacterium_matruchotii_553207@EFM49520          none        168    1.8e-33 1     1   0.770     0.789
*    Corynebacterium_amycolatum_553204@EEB64190           none        215    5e-33   1     1   0.864     1.009
*    Dehalogenimonas_lykanthroporepellens_552811@ADJ25427 none        207    2.5e-32 1     1   0.864     0.972
*    Ignavibacterium_album_945713@AFH49870                none        219    4.2e-31 1     1   0.925     1.028
*    actinobacterium_SCGC_913338@EJX36112                 none        213    1e-29   1     1   0.897     1.000
*    Actinomyces_coleocanis_525245@EEH64406               none        219    4.8e-27 1     1   0.840     1.028
*    Oenococcus_oeni_203123@ABJ56439                      none        212    5.2e-27 1     1   0.826     0.995
*    Helicobacter_pylori_85963@AAD05898                   none        220    3.7e-22 1     1   0.897     1.033
*    Lactobacillus_mali_1046596@EJF01639                  none        161    8.6e-08 1     1   0.751     0.756
=====================================================================================================================
EOT

    $oum->save_selection;
    compare_filter_ok(
        file('test', 'hmmsearch_dom-2.idl'),
        file('test', 'hmmsearch_dom-1.exp-idl'),  # TODO: use 'my_' naming scheme
            \&filter,
            'wrote expected IDL file for hmmsearch.out with default values'
    );
    compare_filter_ok(
        file('test', 'hmmsearch_dom-2.fasta'),
        file('test', 'hmmsearch_dom-1.exp-fasta'),
            \&filter,
            'wrote expected FASTA file for hmmsearch.out with default values'
    );
}

{
    my $class = 'Bio::MUST::Apps::OmpaPa::Hmmer';

    my $oum = $class->new(
        file         => file('test', 'hmmsearch_dom.out'),
        extract_seqs => 1,
        database     => file('test', 'database'),
        parameters   => file('test', 'hmmsearch_dom-1.json'),
    );
    isa_ok $oum, $class;
    cmp_ok $oum->count_hits, '==', 242, 'processed expected number of hits';

    cmp_ok $oum->count_selection, '==', 4, 'got expected number of selected hits with a parameter file';

    cmp_ok $oum->list_selection( 'all' ), 'eq', <<'EOT', 'got expected selection list (all in bounds) with a parameter file';
=============================================================================================================
keep accession                                    description length evalue  count max alignment ratio_length
-------------------------------------------------------------------------------------------------------------
*    Psychrobacter_cryohalolentis_335284@ABE76281 none        331    3.5e-53 1     1   0.915     1.554
*    Psychrobacter_sp._349106@ABQ94025            none        331    2.6e-51 1     1   0.911     1.554
*    Psychrobacter_cryohalolentis_335284@ABE75027 none        331    5.3e-51 1     1   0.930     1.554
     Scardovia_wiggsiae_857290@EJD64896           none        326    1.3e-50 1     1   0.897     1.531
=============================================================================================================
EOT

    cmp_ok $oum->list_selection( 'keep' ), 'eq', <<'EOT', 'got expected selection list (keep after filtering) with a parameter file';
=============================================================================================================
keep accession                                    description length evalue  count max alignment ratio_length
-------------------------------------------------------------------------------------------------------------
*    Psychrobacter_cryohalolentis_335284@ABE76281 none        331    3.5e-53 1     1   0.915     1.554
*    Psychrobacter_sp._349106@ABQ94025            none        331    2.6e-51 1     1   0.911     1.554
*    Psychrobacter_cryohalolentis_335284@ABE75027 none        331    5.3e-51 1     1   0.930     1.554
=============================================================================================================
EOT

    $oum->save_selection;
    compare_filter_ok(
        file('test', 'hmmsearch_dom-3.idl'),
        file('test', 'hmmsearch_dom-2.exp-idl'),  # TODO: use 'my_' naming scheme
            \&filter,
            'wrote expected IDL file for hmmsearch.out with a parameter file'
    );
    compare_filter_ok(
        file('test', 'hmmsearch_dom-3.fasta'),
        file('test', 'hmmsearch_dom-2.exp-fasta'),
            \&filter,
            'wrote expected FASTA file for hmmsearch.out with a parameter file'
    );
}

{
    my $class = 'Bio::MUST::Apps::OmpaPa::Hmmer';

    my $oum = $class->new(
        file         => file('test', 'hmmsearch_dom.out'),
        extract_seqs => 1,
        database     => file('test', 'database'),
        restore_last_params => 1,
    );
    isa_ok $oum, $class;
    cmp_ok $oum->count_hits, '==', 242, 'processed expected number of hits';

    cmp_ok $oum->count_selection, '==', 4, 'got expected number of selected hits with the last parameter file';

    cmp_ok $oum->list_selection( 'all' ), 'eq', <<'EOT', 'got expected selection list (all in bounds) with the last parameter file';
=============================================================================================================
keep accession                                    description length evalue  count max alignment ratio_length
-------------------------------------------------------------------------------------------------------------
*    Psychrobacter_cryohalolentis_335284@ABE76281 none        331    3.5e-53 1     1   0.915     1.554
*    Psychrobacter_sp._349106@ABQ94025            none        331    2.6e-51 1     1   0.911     1.554
*    Psychrobacter_cryohalolentis_335284@ABE75027 none        331    5.3e-51 1     1   0.930     1.554
     Scardovia_wiggsiae_857290@EJD64896           none        326    1.3e-50 1     1   0.897     1.531
=============================================================================================================
EOT

    cmp_ok $oum->list_selection( 'keep' ), 'eq', <<'EOT', 'got expected selection list (keep after filtering) with the last parameter file';
=============================================================================================================
keep accession                                    description length evalue  count max alignment ratio_length
-------------------------------------------------------------------------------------------------------------
*    Psychrobacter_cryohalolentis_335284@ABE76281 none        331    3.5e-53 1     1   0.915     1.554
*    Psychrobacter_sp._349106@ABQ94025            none        331    2.6e-51 1     1   0.911     1.554
*    Psychrobacter_cryohalolentis_335284@ABE75027 none        331    5.3e-51 1     1   0.930     1.554
=============================================================================================================
EOT

    $oum->save_selection;
    compare_filter_ok(
        file('test', 'hmmsearch_dom-4.idl'),
        file('test', 'hmmsearch_dom-2.exp-idl'),  # TODO: use 'my_' naming scheme
            \&filter,
            'wrote expected IDL file for hmmsearch.out with the last parameter file'
    );
    compare_filter_ok(
        file('test', 'hmmsearch_dom-4.fasta'),
        file('test', 'hmmsearch_dom-2.exp-fasta'),
            \&filter,
            'wrote expected FASTA file for hmmsearch.out with the last parameter file'
    );
}

{
    my $class = 'Bio::MUST::Apps::OmpaPa::Parameters';

    my $default = $class->new();
    cmp_ok $default->max_copy, '==', 3, 'got expected default value max_copy';
    cmp_ok $default->min_copy, '==', 1, 'got expected default value min_copy';
    #cmp_ok $default->max_eval, '==', 0, 'got expected default value max_eval'; ### !
    cmp_ok $default->min_eval, '==', 0, 'got expected default value min_eval';
    #cmp_ok $default->max_len, '==', , 'got expected default value max_len'; ### !
    cmp_ok $default->min_len, '==', 0, 'got expected default value min_len';
    cmp_ok $default->max_cov, '==', 1, 'got expected default value max_cov';
    cmp_ok $default->min_cov, '==', 0.7, 'got expected default value min_cov';

    my $file = file('test', 'modified.json')->stringify;
    my $param = $class->load( $file );
    cmp_ok $param->max_copy, '==', 5, 'got expected param value max_copy';
    cmp_ok $param->min_copy, '==', 2, 'got expected param value min_copy';
    cmp_ok $param->max_eval, '==', 50, 'got expected param value max_eval';
    cmp_ok $param->min_eval, '==', 10, 'got expected param value min_eval';
    cmp_ok $param->max_len, '==', 60, 'got expected param value max_len';
    cmp_ok $param->min_len, '==', 20, 'got expected param value min_len';
    cmp_ok $param->max_cov, '==', 0.9, 'got expected param value max_cov';
    cmp_ok $param->min_cov, '==', 0.5, 'got expected param value min_cov';

    #### temp: $param->store_bounds
}

{
    my $class = 'Bio::MUST::Apps::OmpaPa::Roles::Parsable';
    #### file: $class->last_parameter_file
}

my @files2del = qw(
    hmmsearch_dom-2.fasta hmmsearch_dom-2.idl hmmsearch_dom-2.json hmmsearch_dom-2.list
    hmmsearch_dom-3.fasta hmmsearch_dom-3.idl hmmsearch_dom-3.json hmmsearch_dom-3.list
    hmmsearch_dom-4.fasta hmmsearch_dom-4.idl hmmsearch_dom-4.json hmmsearch_dom-4.list
);

file('test', $_)->remove for @files2del;

# TODO: insert BLAST tests (old and new XML results)
# TODO: test JSON writing?

sub filter {
    my $line = shift;

    # trim lines (due to blastdbcmd returning deflines with a trainling space)
    $line =~ s{\ +$}{}xmsg;
    return $line;
}

done_testing;
