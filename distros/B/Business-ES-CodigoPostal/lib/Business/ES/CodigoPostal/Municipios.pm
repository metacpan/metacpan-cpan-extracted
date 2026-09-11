package Business::ES::CodigoPostal::Municipios;

# ABSTRACT: Localidades por codigo postal espanol (datos de GeoNames)

use strict;
use warnings;

our $VERSION = '0.03';


my %MUNICIPIOS;
my $CARGADO = 0;

sub _cargar {
    return if $CARGADO;
    $CARGADO = 1;
    binmode DATA, ':encoding(UTF-8)';
    while (my $l = <DATA>) {
        chomp $l;
        my ($cp, $lugares) = split /\t/, $l, 2;
        next unless defined $lugares;
        $MUNICIPIOS{$cp} = $lugares;
    }
    close DATA;
}

sub municipios {
    my $cp = shift;
    return () unless defined $cp && $cp =~ /\A[0-9]{5}\z/;
    _cargar();
    my $l = $MUNICIPIOS{$cp} or return ();
    return split /\|/, $l;
}

sub asignado {
    my $cp = shift;
    return 0 unless defined $cp && $cp =~ /\A[0-9]{5}\z/;
    _cargar();
    return exists $MUNICIPIOS{$cp} ? 1 : 0;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::ES::CodigoPostal::Municipios - Localidades por codigo postal espanol (datos de GeoNames)

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Tabla de localidades indexada por codigo postal. GENERADO AUTOMATICAMENTE por
C<maint/gen-municipios.pl>; no editar a mano.

Se carga solo cuando se pide una localidad: el modulo principal no lo toca
para validar un codigo postal ni para resolver la provincia, que es el uso
mayoritario. Los datos viven en C<__DATA__> y no en un hash literal a
proposito -- el compilador de Perl no mira ahi hasta que alguien lee, asi que
cargar el modulo cuesta lo mismo que cargar un fichero vacio.

Las localidades salen como CARACTERES, igual que el resto del modulo desde
la 0.03.

=head1 NAME

Business::ES::CodigoPostal::Municipios - Localidades por codigo postal

=head1 FUENTE

Datos de L<GeoNames|https://www.geonames.org/>, distribuidos bajo
Creative Commons Attribution 4.0 (L<https://creativecommons.org/licenses/by/4.0/>).
Volcado C<export/zip/ES.zip>. 37867 pares codigo/localidad, 11150 codigos.

=head1 SUBROUTINES

=head2 municipios($cp)

Lista de localidades de ese codigo postal, ordenada. Vacia si no consta.

=head2 asignado($cp)

Cierto si el codigo postal figura en los datos. Un codigo dentro del rango
01000-52999 puede no estar asignado a ninguna localidad -- 28107 es real y no
existe -- y eso lo ve esta funcion, no la validacion por rango del modulo
principal. Falso significa "no consta en este volcado de GeoNames", que para
Espana equivale en la practica a no asignado, pero no es lo mismo.

=head1 AUTHOR

HDELGADO <hdelgado@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by HDELGADO.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
01001	Vitoria-Gasteiz
01002	Vitoria-Gasteiz
01003	Vitoria-Gasteiz
01004	Vitoria-Gasteiz
01005	Vitoria-Gasteiz
01006	Vitoria-Gasteiz
01007	Armentia|Vitoria-Gasteiz
01008	Vitoria-Gasteiz
01009	Vitoria-Gasteiz
01010	Ali|Ehari|Vitoria-Gasteiz
01012	Vitoria-Gasteiz
01013	Abetxuko|Arriaga|Betoño|Gamarra Mayor|Gamarra Nagusia|Vitoria-Gasteiz
01015	Vitoria-Gasteiz
01071	Vitoria-Gasteiz
01080	Vitoria-Gasteiz
01100	Centro Militar Araka
01110	Campezo|Kanpezu|Santa Cruz De Campezo|Santikurutze Kanpezu
01117	Alda|Done Bikendi Harana|Harana/Valle De Arana|Kontrasta|Orbiso|Oteo|San Vicente De Arana|Ullibarri-Arana|Uribarri-Harana
01118	Angostina|Bajauri|Bernedo|Lagran|Nafarrete|Obecuri|Urturi|Villafria|Villaverde
01120	Arraia-Maeztu|Maeztu/Maestu
01128	Antoñana|Atauri|Azazeta|Berrozi|Bujanda|Durruma Kanpezu|Kintana|San Roman De Campezo
01129	Aletxa|Apellaniz|Apinaiz|Areatza|Arenaza|Birgara Barren|Birgara Goien|Cicujano|Elortza|Erroeta|Erroitegi|Ibisate|Korres|Leorza|Musitu|Onraita|Roitegui|Sabando|Virgala Mayor|Virgala Menor|Zekuiano
01130	Murgia|Zuia
01138	Acosta|Apodaka|Berrikano|Buruaga|Eribe|Etxaguen (Zigoitia)|Gopegi|Larrinoa|Letona|Manurga|Murua|Okoizta|Olano|Ondategi|Zaitegi|Zestafe|Zigoitia
01139	Altube|Ametzaga Zuia|Aperregi|Aretxaga|Bitoriano|Domaikia|Gilierna|Guillerna|Jugo|Lukiano|Markina|Sarria|Zarate
01160	Ibarra
01165	Oleta
01169	Aramaio|Arexola|Arriola (Aramaio)|Azkoaga|Barajuen|Etxaguen (Aramaio)|Gantzaga|Untzilla|Uribarri
01170	Elosu|Goiain|Legutio|Nafarrate|Ollerias/Ollerieta|Urrunaga
01191	Astegieta|Estarrona|Gobeo|Hueto Abajo/Otobarren|Hueto Arriba/Otogoien|Martioda|Mendoza|Trasponte|Trespuentes|Ullibarri-Viña|Uribarri-Dibiña
01192	Arbulo|Arbulu|Arcaute/Arkauti|Argomaniz|Añua|Burgelu|Elburgo|Elorriaga|Gazeta|Ilarratza|Junguitu/Jungitu|Lubiano|Matauko|Oreitia|Zerio
01193	Aberasturi|Andollu|Argandoña|Arkaia|Askartza|Azilu|Egileta|Erentxun|Gauna|Hijona|Ixona|Trokoniz|Villafranca
01194	Aretxabaleta|Berrostegieta|Bolibar|Castillo|Eskibel|Gamiz|Gardelegi|Gaztelu|Izartza|Lasarte|Mendiola|Monasterioguren|Okina|Otazu|Ullibarri De Los Olleros|Uribarri Nagusia
01195	Ariñez|Billoda|Crispijana|Gometxa|Krispiñana|Lermanda|Margarita|Subijana De Alava|Subillana-Gasteiz|Villodas|Zuazo De Vitoria|Zuhatzu|Zumeltzu|Zumelzu
01196	Antezana/Andetxa|Arangiz|Aranguiz|Artatza Foronda|Etxabarri Ibiña|Foronda|Gereña|Legarda|Lopidana|Mandojana|Mendarozketa|Mendiguren|Yurre/Ihurre
01200	Agurain|Salvatierra
01206	Arrieta|Audikana|Dallo|Elgea|Etura|Etxabarri-Urtupiña|Ezkerekotxa|Gazeo|Gebara|Heredia|Langarika|Marieta-Larrintzar|Maturana|Mendijur|Ozaeta
01207	Adana|Alaitza|Alangua|Arrizala|Bikuña|Durruma Donemiliaga|Egilatz|Egileor|Eguilaz|Gereñu|Jauregi|Mezkia|Munain|Okariz|Opakua|San Roman De San Millan|Txintxetru|Ullibarri-Jauregi|Uribarri-Jauregi|Vicuña
01208	Albeiz|Albeniz|Ametzaga (Asparrena)|Arriola (Asparrena)|Aspuru|Axpuru|Barria|Donemiliaga|Erdoñana|Galarreta|Gordoa|Hermua|Larrea|Luzuriaga|Narbaiza|Ordoñana|Zalduondo|Zuazo De San Millan|Zuhatzu Donemiliaga
01211	Baroja|Berantevilla|Escanzana|Lacorzana|Lacorzanilla|Mijancas|Moraza|Pagoeta|Payueta|Pipaon|Santurde|Tobera
01212	Berganzo|Gatzaga Buradon|Loza|Montoria|Ocio|Peñacerrada|Portilla|Salinillas De Buradon|Santa Cruz Del Fierro|Urizaharra|Zabalate|Zambrana
01213	Caicedo De Yuso/Kaizedo Behekoa|Comunion|Erribera Beitia|Igai|Komunioi|Lantaron|Leciñana Del Camino|Leziñana|Melledes|Molinilla|Quintanilla De La Ribera|Ribera Baja|Rivabellosa|Salcedo|San Miguel|Turiso|Villabezana|Zubillaga
01216	Arluzea|Faidu|Markinez|Urarte
01220	Antezana De La Ribera|Armiñon|Estavillo|Lacervilla|Leciñana De La Oca|Manzanos|Rivaguda
01230	Langraiz Oka|Nanclares De La Oca
01240	Alegria-Dulantzi
01250	Araia|Asparrena
01260	Andoin|Egino|Ibarguren|Ilarduia|Urabain
01300	Biasteri|Laguardia
01306	Lapuebla De Labarca
01307	Baños De Ebro|Eskuernaga|Mañueta|Samaniego|Villabuena De Alava
01308	Assa|El Campillar|Kripan|Lanciego|Lantziego|Viñaspre/Biasteri
01309	Bilar|Elvillar|Leza|Navaridas|Paganos
01320	Oion|Oyon
01321	Laserna
01322	Barriobusto|Labraza|Moreda Araba|Moreda De Alava|Yecora / Iekora
01330	Bastida|Labastida
01340	Elciego
01400	Laudio/Llodio
01408	Luiaondo
01409	Billatxica|Irabien|Jandiola|Okondo|Okondogoiena|Okondojena|San Roman|Ugalde|Zudibiarte
01420	Arbigano|Basquiñuelas|Caicedo-Sopeña|Castillo Sopeña|Hereña|Paul|Pobes
01423	Alcedo|Atiaga|Atiega|Bachicabo|Barrio|Bellojin|Bergonda|Bergüenda|Espejo|Fontecha|Larrazubi|Puentelarra|Sobron|Tuesta|Villamaderne|Villambrosa
01426	Arreo|Astulez|Añana|Caranca|Fresneda|Karkamu|Nograro|Osma|Salinas De Añana/Gesaltza Añana|Villanañe|Villanueva De Valdegovia|Viloria
01427	Acebedo|Arroyo De San Zadornil|Basabe|Boveda|Corro|Gurendes-Quejo|Jurisdiccion De San Zadornil|Lahoz|Lalastra|Mioma|Pinedo|Quejo|Quintanilla De Valdegovia|Ribera|San Millan De San Zadornil|San Zadornil|Tobillas|Valluerca|Valpuesta|Villafria De San Zadornil|Villamardones
01428	Anucita|Anuntzeta|Artatza|Artaza|Axkoeta|Barron|Escota|Guinea|Lasierra|Mandaita|Montevite|Morillas|Nuvilla|Olabarri|Ollavarre|Ormijana|Subijana-Morillas|Tuyo|Villaluenga
01430	Zuhatzu-Kuartango
01439	Anda|Andagoia|Aprikano|Arriano|Artxua|Etxabarri-Kuartango|Gillarte|Inurrieta|Jokano|Katadiano|Luna|Marinda|Santa Eulalia|Sendadiano|Tortura|Urbina Basabe|Urbina Eza|Uribarri-Kuartango|Villamanca
01440	Izarra|Urkabustaiz
01449	Abezia|Abornikano|Apregindana|Beluntza|Goiuri-Ondona|Larrazketa|Oiardo|Untzaga-Apregindana|Unza-Apreguindana|Uzkiano
01450	Baranbio|Inoso|Lekamaña|Lezama|Ziorraga
01468	Aloria|Artomaña|Delika|Larrinbe|Saratxo|Tertanga
01470	Amurrio|Etxegoien
01474	Artziniega
01476	Aiara|Arespalditza|Ayala|Respaldiza
01477	Añes|Beotegi|Costera|Erbi|Kexaa|Lejarzo|Lexartxu|Lujo|Luxo|Menagarai-Beotegi|Menoio|Opellora|Ozeka|Quejana|Retes De Llanteno|Zuaza
01478	Campijo|Gordeliz|Llanteno|Mendieta|Retes De Tudela/Erretes Tudela|Santa Koloma|Sojo|Soxo|Soxoguti
01479	Agiñaga|Izoria|Madaria|Maroño|Murga|Olabezar|Salmanton
01510	Betolaza|Erretana|Gamarra Gutxia|Gamarra Menor|Luko|Miñano Mayor|Miñano Menor|Miñao|Miñao Gutxia|Urbina|Ziriano
01520	Amarita|Arroiabe|Arzubiaga|Durana|Landa|Mendibil|Nanclares De Ganboa / Langara Ganboa|Ullibarri-Arrazua|Ullibarri-Gamboa|Zurbano|Zurbao
02001	Albacete
02002	Albacete
02003	Albacete
02004	Albacete
02005	Albacete
02006	Albacete
02007	Albacete
02008	Albacete
02049	Aguas Nuevas|Albacete
02070	Albacete
02071	Albacete
02080	Albacete
02100	Tarazona De La Mancha
02110	La Gineta|La Grajuela
02120	Peñas De San Pedro
02124	Alcadozo|Casablanca|Casasola|La Herreria|La Navazuela|La Noguera
02125	Ayna|Ginete, El (Ayna)|Royo Odrea
02127	Berro|Burrueco|Casa Cañete|El Sahuco|Fuenlabrada|La Solana|Navalengua
02129	Campillo De La Virgen|El Molinar|El Royo|Fontanar De Las Viñas|Fuente Del Pino|La Fuensanta|La Molata|Los Pocicos|Santa Ana (Fuente Del Pino)
02130	Bogarra
02136	Paterna De Madera
02137	Arteaga|Batan Del Puerto|Casa Rosa|Cortijo De Tortas|Los Catalmerejos|Rio Madera
02139	Cañadas De Haches Abajo|Cañadas De Haches Arriba|Dehesa Del Val|Dehesa, La (Ayna)|El Griego|El Villarejo|La Sarguilla|Las Casas De Haches|Las Mohedas|Moriscote|Potiche
02140	Albacete|El Salobral|Los Anguijes
02141	Pozohondo
02142	Mullidar|Nava De Abajo|Nava De Arriba
02150	Valdeganga
02151	Casas De Juan Nuñez
02152	Alatoz
02153	Carcelen|Casas De Juan Gil
02154	Pozo-Lorente|Villavaliente
02155	Tinajeros
02156	La Felipa
02160	Lezuza
02161	La Yunquera|Tiriez
02162	El Cuartico|La Herrera|Oncebreros (La Herrera)
02200	Casas-Ibañez
02210	Alcala Del Jucar
02211	Casas Del Cerro|La Gila|Tolosa
02212	Casas De Ves
02213	La Pared|Villa De Ves
02214	Balsa De Ves|Cantoblanco|El Viso|Las Eras|Zulema
02215	Alborea|Cilanco|Villatoya
02220	Motilleja
02230	Madrigueras
02240	Mahora
02246	Navas De Jorquera
02247	Cenizate
02248	Jorquera
02249	Alcozarejos|Bormate|Calzada De Vergara|La Recueja|Maldonado|Ribera De Cubas
02250	Abengibre
02251	Campoalbillo
02252	Mariminguez
02253	Golosalvo
02260	Fuentealbilla
02270	Villamalea
02300	Alcaraz
02310	Viveros
02311	Povedilla
02312	Canaleja|La Mesta De Alcaraz
02313	Peñascosa
02314	Cilleruelo|El Horcajo|Ituero|La Hoz|Masegoso|Pesebre|Peñarrubia De Masegoso|Solanilla|Zorio
02315	Vianos
02316	Reolid|Salobre
02320	Balazote
02326	Casas De Abajo|Cañada Juncosa|San Pedro
02327	Argamason|Casica Del Madroño|La Zarza|Pozuelo
02328	Santa Ana
02329	Casas De Lazaro|Cucharal
02340	Cubillo|El Jardin|Los Chospes|Robledo
02350	Villapalacios
02360	Bienservida
02400	Hellin
02409	Agra|Cañada De Agra|Mingogil|Nava Campaña
02410	Lietor
02420	Isso
02430	Elche De La Sierra
02434	Letur
02435	Socovos
02436	Ferez
02437	Cañada De Buendia|El Cañar|Los Olmos|Tazona
02439	Abejuela|Gallego|Vicorto|Villares
02440	Molinicos
02448	Cañada Del Provencio|La Alfera|Las Animas|Las Yeguarizas|Los Alejos|Pinilla (Vegallera)|Quejigal|Vegallera
02449	Cañada De Morote|El Pardal|Fuente Carrasca|Fuente Higuera|Las Hoyas|Los Collados|Mesones|Puerto Del Pino|Torre Pedro
02450	Riopar
02459	Casa De La Noguera|Cortijos Del Cura|El Gollizo|El Laminador|El Lugar Nuevo|El Nogueron|El Villar
02460	Bellotar|Villaverde De Guadalimar
02461	Cotillas
02462	Arroyofrio|Campillo|Umbria Angulo
02480	Yeste
02484	Arguellite
02485	Tus
02486	Horno Ciego|Peñarrubia|Rala
02487	Juan Quilez|Sege
02489	Alcantarilla|Gontar|Parolis|Paules
02490	Agramon
02499	Cancarix|La Horca|Las Minas|Minateda
02500	Tobarra
02510	Pozo Bueno|Pozo Cañada
02511	Campillo De Las Doblas|Las Abuzaderas
02512	Aljube|Casa Blanca De Los Rioteros|Casa De Las Monjas|Los Mardos
02513	Cordovilla|Mora De Santa Quiteria|Santiago De Mora|Sierra
02520	Chinchilla De Monte Aragon
02530	Nerpio
02534	Cañadas|Jutia|Pedro Andres
02536	Beg|Casa De La Cabeza|Chorretites De Abajo|Cortijos Del Herrero|Yetas De Abajo
02600	Villarrobledo
02610	El Bonillo
02611	Ossa De Montiel
02612	Munera
02614	El Ballestero
02620	Minaya
02630	La Roda
02636	Villalgordo Del Jucar
02637	Fuensanta
02638	Montalvos
02639	Barrax|Santa Marta
02640	Almansa
02650	Montealegre Del Castillo
02651	Fuente-Alamo
02652	Ontur
02653	Albatana
02660	Caudete
02690	Alpera
02691	Bonete|Horna
02692	Las Anorias|Petrola|Pinilla
02693	Corral Rubio|La Higuera
02694	Higueruela
02695	Villar De Chinchilla
02696	Hoya Gonzalo
03001	Alicante/Alacant
03002	Alicante/Alacant
03003	Alicante/Alacant
03004	Alicante/Alacant
03005	Alicante/Alacant
03006	Alicante/Alacant
03007	Alicante/Alacant
03008	Alicante/Alacant
03009	Alicante/Alacant
03010	Alicante/Alacant
03011	Alicante/Alacant
03012	Alicante/Alacant
03013	Alicante/Alacant
03014	Alicante/Alacant
03015	Alicante/Alacant
03016	Alicante/Alacant
03070	Alicante/Alacant
03071	Alicante/Alacant
03080	Alicante/Alacant
03100	Abio|Carrasqueta (Urbanizacion)|Segorb|Xixona
03108	Alcoyes|Barranco Orta|Sierra Grana (Partida)|Torre De Les Maçanes, La/Torremanzanas|Viola
03109	Aljibe, El (Urbanizacion)|Bonaire (Urbanizacion)|Maigmo (Urbanizacion)|Pinares De Mecli (Urbanizacion)|Tibi|Torrosella
03110	Almajada, La (Urbanizacion)|Bayona, La (Partida)|Benaud (Partida)|Benessiu / Benissiu (Partida)|Borrachina (Partida)|Calera, La (Urbanizacion)|Calvari (Partida)|Cantalar, El (Partida)|Capellans (Partida)|Collao, El (Partida)|Cotoveta (Urbanizacion)|Entredos, L' (Urbanizacion)|Gialma (Urbanizacion)|Girasoles, Los (Mutxamel) (Urbanizacion)|Huerta, La (Mutxamel) (Urbanizacion)|La Venteta|Marseta (Partida)|Moli-Foc (Urbanizacion)|Mutxamel|Obrera, La (Partida)|Olmos, Los (Urbanizacion)|Paulinas, Las / Paulines (Les) (Urbanizacion)|Peñacerrada|Peñetes, Les / Penyetes (Les) (Urbanizacion)|Pino, El / Pi, El (Urbanizacion)|Ravel (Urbanizacion)|Rio-Park (Urbanizacion)|Roseta, La (Urbanizacion)|San Peret / Sant Peret (Urbanizacion)|Serveres (Partida)|Señal, El (Partida)|Tosal Redo (Partida)|Valle Del Sol (Urbanizacion)|Volador, El / Volaor, El (Urbanizacion)|Volveta Ganga
03111	Busot|Carril (Urbanizacion)|Cava, La (Busot)|El Figueralet|Hoya Berenguer (Partida)|Hoya De Los Patos|Hoya De Parra|Llano Pastores (Urbanizacion)|Pisnella (Partida)|Pla De Cabeco (Urbanizacion)|Pla Lloma (Urbanizacion)|Planet, El (Partida)|Vercheret (Partida)
03112	Alicante/Alacant|Chareus|Mariquitos|Tangel|Villafranqueza - Palamo
03113	Alicante/Alacant|El Rebolledo|Foncalent / Font- Calent|Santa Ana (Rebolledo)|Xeperut, Lo (Partida)
03114	Alicante/Alacant|Bacarot|Poligono Industrial Las Atalayas
03115	Monnegre
03130	Santa Pola
03138	Tabarca
03139	Barrio Alto|El Vincle|Elx/Elche|Nova Vallverda|Vallverda/Valverde|Valverde (Elche) (Partida)|Valverde Alto|Valverde Bajo
03140	Chapaprietas, Los (Partida)|Guardamar Del Segura|Mare Nostrum (Camping)|Pall-Mall (Camping)|Pinada, La (Camping)|San Jose (Camping)
03149	Almarjal|Los Rasos|Moncayo|San Bruno|Ventosala
03150	Dolores
03158	Casicas, Las / Casicas|Catral|Domingos, Los (Caserio)|Hornos|Madrigueras|Nonduermas|Palomar|Rincon De Los Pablos|San Felipe Neri
03159	Bodega, La (Dolores)|Camino De San Fulgencio|Cuadra Nueva|Cuatro Caminos|Daya Nueva|Escorredor|Florida Alta (Partida)|Florida Baja (Partida)|Llobregales|Mayayo|Puebla De Rocamora|Puente De Mateos|Rincon De Los Pertusas (Partida)|Vereda Del Pozo
03160	Almoradi
03169	Algorfa|Almazarica (Caserio)|Bañet (Caserio)|Cruz De Galindo|El Bañet|El Camino De Catral|El Camino De La Maja|El Gabato|El Puente De Don Pedro|El Raiguero|El Saladar|Era Alta|La Fogaria|La Pinada|La Venta|Lomas De La Juliana (Partida)
03170	Ciudad Quesada|El Nido|La Garriga|Pepin (Lo) (Urbanizacion)|Rojales
03176	Garrofero, Lo (Partida)|Lo Crispin|Montebello
03177	Daya Vieja|Escuera, La (Urbanizacion)|Lo Pedreño|Los Martinez|Marina, La (Urbanizacion)|Oasis (La Marina) (Urbanizacion)|Pesqueras, Las (Partida)|San Fulgencio
03178	Benijofar|Monteazul (Urbanizacion)|Talaya Park (Urbanizacion)
03179	Formentera Del Segura|Heredades|Los Palacios
03180	Torrevieja
03181	Torrevieja
03182	Torrevieja
03183	Torrevieja
03184	Torrevieja
03185	Torrevieja
03186	Torrevieja
03187	Herrada, La (Urbanizacion)|La Marquesa|La Rafaela|Las Casitas|Lo Blanque|Lo Sastre|Los Montesinos|Los Paredes|Los Pinicos|Miras, Los (Montesinos)|Perez, Los (Ayuntamiento Los Montesinos)
03188	Torrevieja
03189	Almendros, Los (Orihuela-Costa) (Urbanizacion)|Cabo Roig|Castillo De Don Juan|Dehesa De Campoamor (Urbanizacion)|El Gato|Filipinas (Urbanizacion)|Flamenca (Playa)|Florida, La (Orihuela-Costa) (Urbanizacion)|Horizonte, El (Urbanizacion)|La Regia|La Zenia|Las Mimosas|Las Solanas|Lomas De San Juan (Urbanizacion)|Los Dolses|Monte Zenia|Oleza (Urbanizacion)|Orihuela-Costa (Nucleo)|Punta Prima|Serena Ii (Urbanizacion)|Solana, La (Urbanizacion)|Torre Zenia (Urbanizacion)|Villacostas (Urbanizacion)|Villamartin
03190	Pilar De La Horadada
03191	Cañada De Praes / Caña De Praez|Hortelanos, Los (Caserio)|Los Saez|Mil Palmeras (Urbanizacion)|Pinar De Campoverde|Pueblo Latino (Urbanizacion)|Torre De La Horadada
03193	Presidente, El / Urbanizacion El Presidente (Urbanizacion)|San Miguel De Salinas
03194	La Marina Del Pinet|Molar, El (Partida)|Pinet, El (Partida)
03195	Balsares, Los (Altet)|El Altet|Los Arenales Del Sol
03200	Elx/Elche
03201	Elx/Elche
03202	Elx/Elche
03203	Elx/Elche|Parque Industrial De Elche (Poligono Industrial)
03204	Elx/Elche
03205	Carrus (Elche) (Partida)|Elx/Elche
03206	Elx/Elche
03207	Altabix (Elche) (Partida)|Elx/Elche
03208	Elx/Elche
03290	Alzabares (Elche) (Partida)|Elx/Elche
03291	Elx/Elche|Ferriol (Elche) (Partida)|Vallonga, De La (Elche) (Partida)
03292	Asprillas (Elche) (Partida)|Bayas, Las (Elche) (Partida)|Elx/Elche
03293	Algoros (Elche) (Partida)|Derramador (Elche) (Partida)|Elx/Elche|Llano De San Jose (Elche) (Partida)
03294	Daimes (Elche) (Partida)|Elx/Elche|Foia, La (Elche) (Partida)
03295	Elx/Elche|Jubalcoi (Elche) (Partida)|Maitino (Elche) (Partida)|Perleta (Elche) (Partida)|Saladas (Elche) (Partida)
03296	Algoda (Elche) (Partida)|Elx/Elche|Matola (Elche) (Partida)|Peña De Las Aguilas (Elche) (Partida)|Puzol (Elche) (Partida)
03300	Los Huertos|Orihuela
03310	Correntias Bajas (Jacarilla)|Jacarilla
03311	Bonanza (Raiguero De)|Camino De En Medio|La Aparecida|Molino De La Ciudad
03312	Arneva|Las Norias|Los Desamparados
03313	Alcachofar|Hurchillo|Rebate|Torremendo
03314	San Bartolome
03315	Asensios, Los (Caserio)|Cabecico, El (Caserio)|Candel, Lo (Caserio)|Carmen, Lo (Caserio)|Cutillas, Los (Caserio)|Gavilanes, Los (Caserio)|La Murada|Los Riquelmes|Mazones, Los (Caserio)|Perez, Los (Caserio)|Pinos, Los (Caserio)|Ronderos, Los (Caserio)|Torre Ines (Caserio)|Vives, Los (Caserio)
03316	Benferri|La Matanza|Montepinar (Urbanizacion)
03317	Bodega, La (Orihuela)|El Escorratel|La Naya|Los Carasos / Carazos|Media Legua|Viejo De Callosa (Camino)|Virgen Del Camino (Partida)
03318	Lo Rocamora|Los Vicentes
03319	Entrenaranjos / Urb. Entre Naranjos (Urbanizacion)
03320	Torrellano
03321	Chapitel (Vereda)|Correntias Medias|Fabregal (Vereda)
03322	Brunete (Vereda)|Don Faustino (Vereda)|Molins|Serranos (Vereda)
03325	Barrio Carretera (Campaneta)|La Campaneta|Puente Los Cirios
03330	Crevillent
03339	Amoros (Partida)|Barranco De San Cayetano|Barranco San Cayetano (Partida)|Barrio De La Estacion De Crevillente|Boch|Cachap, El (Partida)|Carga (Partida)|El Realengo|Estacio, L' (Crevillente) (Partida)|Los Campillos|Mangranera, La (Partida)|Marchant (Partida)|Molineta, La (Partida)|Molinos De Magro / Molins De Magro (Partida)|Monje (Partida)|San Pascual
03340	Albatera
03348	Granja De Rocamora|Los Monecillos|Mos Del Bou
03349	Arzabon (Partida)|Cabezo, El (Zona)|Gallegos, Los (Zona)|San Isidro De Albatera
03350	Callosilla (Orihuela)|Cox|El Salar|Huerta, La (Callosa Segura)|Jabonero, Lo (Partida)|Los Collereros|Los Diaz|Montero, Lo (Orihuela)|Motor Del Carmen|Polanco, Lo (Partida)|Puntas, Los (Partida)|Rambleta (Paraje)|San Isidro (Paraje)
03360	Almajal (Cami)|Almunia (Cami)|Barrio Cementerio|Barrio El Palmeral|Barrio Los Dolores|Benejuzar, Viejo / Camino Viejo De Benejuzar (Camino)|Benimira (Partida)|Callosa De Segura|Cartagena, Lo (Callosa De Segura) (Grupo)|Cerca, Lo (Partida)|Ferrocarril, Paralelo (Camino)|Muñosa, La (Partida)|Orilla Acequia (Grupo)|Palmeral, El (Poblado)|Perpen, Lo (Grupo)|San Jose|San Pedro (Grupo)|San Roque|Serrana, La (Camino)|Vereda De Los Cubos|Yesera, La (Partida)
03369	Baden, El (Partida)|Mudamiento|Rafal
03370	La Magdalena|Los Benitos|Redovan|San Carlos
03380	Bigastro|Correntias Bajas (Bigastro)
03390	Benejuzar|Secano De Barracas
03400	Villena
03408	Encina, La (Nucleo)|Tiesas, Las (Partida)|Zafra, La (Nucleo)
03409	Cañada|Las Virtudes
03410	Biar
03420	Castalla|Sarganella
03430	Onil
03440	Ibi
03450	Banyeres De Mariola|La Marjal|Molines, Les
03459	Casas De Beneyto (Caserio)|Casas De Maestre|Villa-Rosa (Caserio)
03460	Beneixama
03469	Balsa, La (Partida)|Casas Del Rio|El Campo De Mirra/Camp De Mirra|El Salse|Penyetes (Partida)
03500	Benidorm
03501	Benidorm
03502	Benidorm|Tolls (Partida)
03503	Almafra (Partida)|Armanello (Partida)|Benidorm|Coves (Partida)|Foya Manera, La (Partida)|Lloma (Partida)|Saltet (Partida)
03508	Benidorm
03509	Figueretes (Partida)|Finestrat|Golf Bahia (Urbanizacion)|Hortetes, Les (Partida)|Molino, El (Urbanizacion)|Ramal De Loix (Urbanizacion)|Tamarit, El (Urbanizacion)|Tapiada, La (Urbanizacion)
03510	Almedia|Callosa D'En Sarria|Marchequivir|Tosal De Banderes
03516	Benimantell
03517	Abdet|Beniarda|Benifato|Confrides|El Castell De Guadalest
03518	Algar, El (Partida)|Bolulla|Tarbena
03519	Chines
03520	Alberca, La (Urbanizacion)|Bovalar (Urbanizacion)|Campulles (Partida)|Chirles (Nucleo)|Cotelles|Creueta, La (Urbanizacion)|Fonts, Les (Partida)|Pla De Terol (Urbanizacion)|Polop|Raco (Partida)|Torrent (Partida)
03530	Arcos Este (Urbanizacion)|Arcos Norte (Urbanizacion)|Arcos, Los (Urbanizacion)|Barranco Hondo / Baranc Fondo|Bello Horizonte / Bell Horitzo (Urbanizacion)|Caravana (Urbanizacion)|Cautivador|Colina, La (Urbanizacion)|Coloma (Urbanizacion)|Dorado, El (Urbanizacion)|Entrepinos (Urbanizacion)|Floriana (Urbanizacion)|Hapimag (Urbanizacion)|Holiday - Club|Kristal (Urbanizacion)|La Nucia|Las Vegas|Maylan (Urbanizacion)|Montahud (Urbanizacion)|Montebello|Montecasino (Urbanizacion)|Muixara, La (Urbanizacion)|Nou Espai I (Urbanizacion)|Nou Espai Ii (Urbanizacion)|Nucia Hills, La / Nucia-Hill|Nucia-Park (Urbanizacion)|Olivos, Los (Urbanizacion)|Orquideas, Las (Urbanizacion)|Panorama (La Nucia)|Patrax (Urbanizacion)|Patricia (Urbanizacion)|Perla, La (Urbanizacion)|Pinar De Garaita (Urbanizacion)|Pla De Garaita (Urbanizacion)|Promere Bella Vista (Urbanizacion)|Puerta De Hierro (Urbanizacion)|Puerto Azul (Urbanizacion)|Rosales (Urbanizacion)|Sol Saliente (Urbanizacion)|Torre, La (Urbanizacion)|Tosal (Urbanizacion)|Tosal, El / Tossal, El (Urbanizacion)|Valle, El (Urbanizacion)|Varadero (Urbanizacion)
03540	Alicante/Alacant|Cabo De Las Huertas
03550	Benimagrell|Fabraquer (Ayuntamiento San Juan)|Frank Espinos|Huertas|La Font|Lloixa|Mezquitas, Las, F-Ii Y Iii (Urbanizacion)|Racholetes (Urbanizacion)|Rajoletes / Racholetes (Urbanizacion)|Salafranca (Urbanizacion)|Sant Joan D'Alacant|Santa Faz (San Juan)
03559	Alicante/Alacant|Apostoles, Los (Urbanizacion)|Orgegia|Santa Faz (Alicante)
03560	Alkabir (Urbanizacion)|Amerador, L|Banyets, Els (Urbanizacion)|Bonny Barrio|Cala D'Or (Urbanizacion)|Colonia Trinidad|Coveta Fuma|El Campello|La Almadraba|La Merced|Messell, El (Poligono Industrial)|Mezquitas, Las (Urbanizacion)|Muchavista (Playa)|Poblet, El (Urbanizacion)|Pueblo Acantilado|Urbanizacion Bonanza (Urbanizacion)|Venta Lanuza
03569	Aigües
03570	Aixihuili (Partida)|Alcocons|Almiserat (Partida)|Amunt De L'Horta (D) (Partida)|Atalayas (Villajoyosa)|Barberes|Bol Nou (Partida)|Carrichal (Partida)|Charco, El (Partida)|Chovades|Era Soler|Galandu (Partida)|Gasparot (Urbanizacion)|La Villajoyosa/Vila Joiosa|Mediases|Montesol|Montiboli (Urbanizacion)|Parais|Plands (Urbanizacion)|Plans|Poligono Industrial El Torres|Robella, La (Partida)|Rodacucos (Partida)|Sainvi (Urbanizacion)|Salomo, El (Partida)|Secanet|Setines (Partida)|Torretes (Partida)
03578	Relleu
03579	Orxeta|Sella
03580	Alfas Del Pi, L'|Barranco Hondo / Barranc Fondo (Urbanizacion)|Cautivador (Urbanizacion)|Colonia Escandinavia / Escandinavia|Devesa|El Tosalet (Alfaz Del Pi) /Tossalet|Entre Naranjos -Flores|Foya Blanca / Foia Blanca (Urbanizacion)|Jardin De Alfaz (Urbanizacion)|Limoneros (Urbanizacion)|Oasis (Urbanizacion)|Pla Del Devesa (Urbanizacion)|Residence Park (Urbanizacion)|Romeral, El (Urbanizacion)
03581	Albir, L' (Nucleo)|Alfas Del Pi, L'-Playa / Alfas Del Pi-Playa (Nucleo)|Estrada, La (Urbanizacion)|Guixa, La (Partida)|Lloma, La (Partida)|Sant Pere (Partida)
03589	Santa Fe (Urbanizacion)
03590	Altea|Cap Blanc (Altea) (Urbanizacion)|Olla, L'|Planet, El (Altea)
03599	Alhama Springs (Urbanizacion)|Altea Hills (Zona)|Altea La Vella|Carretera De Callosa Ensarria (Altea La Vella) (Carretera)|El Mascarat|Font De Ferrer (Partida)|Galera De Las Palmeras (Urbanizacion)|La Galera|Mimosas, Las (Urbanizacion)|Pila, La (Partida)|Pueblo Mascarat|Puerto Campomanes-Grenwich (Urbanitzacio)|Riquet (Partida)|Sogay (Partida)|Villa Gadea
03600	Agualejas|Azafranar|Barranco Gobernador|Bateig|Boveda|Camara|Campico|Campo Alto|El Chorrillo|El Monastil|Elda|Huerta Nueva|Jaud|La Horteta|La Siesta|Molinos, Los (Elda)|Pata|Sigmat
03610	Aguarrios (Zona)|Almafra (Zona)|Caprala|Cati|El Cid|Genibre / Ginibre (Partida)|Guirney|Llovera / Llobera, La (Partida)|Loma Bada (Urbanizacion)|Palomaret|Pedreras, Las (Petrel)|Petrer|Pusa / Puça|Rebenton / Rebento, El (Partida)|Salinetas De Petrel|Santa Barbara (Zona)|Troset (Zona)
03630	Sax
03638	Salinas
03639	La Colonia De Santa Eulalia
03640	Alquebla (Partida)|Barrio Cenefa (Extrarradio)|Basso (Partida)|Bellich (Partida)|Beties (Partida)|Bilaire (Partida)|Buitrera (Partida)|Bull (Partida)|Cantarranas (Partida)|Cavafria (Partida)|Cavarrasa (Partida)|Cañada Farina (Partida)|Cañaeta (Partida)|Cenia, La (Monover/Monovar) (Partida)|Charco Amargo (Casas)|Chinorla|Collado Almendro (Partida)|Collado Azorin (Partida)|Collado De Victoriano|Collado Novelda (Partida)|El Gallo|Esvarador (Partida)|Falcones|Fumarol (Partida)|Hondon Alto (Partida)|Hondon Bajo (Partida)|Molinos, Los (Casa)|Monover/Monovar|Pedrera (Monover/Monovar)|Peñetas / Peñetes (Partida)|Rejuela, La (Partida)|Romaneta|Siri, El (Partida)|Zafarich (Partida)
03649	Almorqui (Casa)|Casas De Juan Blanco / Cases Joan Blanco|Casas De Sanchiz / Cases De Sanchis|Casas Del Señor / Cases Del Senyor|Cañada Roja|Cañadas De Don Ciro / Canyades D'En Cirus|Chinorlet / Xinorlet|Collado De Salinas|Fuente Del Pino (Partida)|Madara|Mañan / Manya|Rambleta, La (Partida)|Solaneta (Partida)
03650	Pinoso
03657	Capellania|Casas De Ibañez|Paredon|Raspay
03658	Camarillas|Casas Del Hospital|Culebron|El Faldar|Encebras|Lel|Los Purgateros|Prado|Rodriguillo|Sonca|Tejera, La (Pinoso)|Ubeda
03659	Cañada Del Trigo|La Caballusa
03660	Campet|Casas De Sala|Cucuch|Duayme|Fuente La Reina|Horna Alta|Horna Baja|La Ledua|Molinos, Los (Novelda)|Novelda|Salinetas De Novelda|Serreta (Novelda)
03668	Algueña|La Solana De Algueña
03669	Alcana|Algayat|Barrio De San Anton|Batistes|Beltrans / Beltran|Canicios|La Boquera|La Romana|Los Joveres|Los Leros|Los Palaos|Los Pomares
03670	Monforte Del Cid
03679	Baños Nuestra Señora De Orito|Capitania, La (Monforte Cid) (Urbanizacion)|El Llano Alto|El Llano Bajo|Ermita De San Pascual|Espejeras|Orito|Pozoblanco|Serreta, La (Monforte Cid)
03680	Aspe|Tejera, La (Partida)
03688	Cava, La (Hondon De Las Nieves)|El Rebalso|Fondo De Les Neus, El/Hondon De Las Nieves|La Canalosa|La Solana
03689	Barbarroja|Casas De Cofer|Casas De Galiana|Hondon De Los Frailes
03690	Boqueres|Sant Vicent Del Raspeig
03698	Agost
03699	La Alcoraya|La Cañada|Monteaud|Monteros, Los (San Vicente Del Raspeig)|Moralet|Verdegas
03700	Altomira|Balcon (Denia)|Belems|Bovetes|Campusos|Corral De Calafat|Denia|El Palmar|Florida (Denia)|Galeras|Galeretes|Lloma De Castazar|Los Rotes|Marines|Mirambells|Pedrera, La (Denia)|Punta Negra|Quijote|Saladar|Santa Lucia|Santa Paula|Suertes Del Mar|Tosalet (Denia)|Tossal Gross (Partida)|Troyas
03709	Benimaquia (Partida)|Casablanca (Partida)|Hersi La Plana (Partida)|Pinella (A Y B) (Partida)|Planes De Elias (Partida)|Planes, Les (Partida)|Xara, La (Nucleo)
03710	Adelfas, Las (Urbanizacion)|Basetes, Les (Urbanizacion)|Benicolada (Urbanizacion)|Calalga (Urbanizacion)|Calp|Carrio (Urbanizacion)|Colari (Urbanizacion)|Cometa, La (Calpe) (Urbanizacion)|Corralets (Urbanizacion)|Ifach|La Canuta|Marisol - Park (Urbanizacion)|Maryvilla|Merced (Urbanizacion)|Oltamar (Urbanizacion)|Ortembach (Urbanizacion)|Pinos, Los (Partida)|Pla De Mar (Partida)|Ricarlos (Urbanizacion)
03720	Baladrar (Partida)|Bellita|Benimarco (Benissa)|Benissa|Berdica|Bonaire|Canor|Fanadix (Benissa) (Partida)|Fustera|Montemar|Paratella|Patmore (Partida)|Pedramala|Pinos|Quisi|San Jaime-Benissa
03723	Llosa De Camacho
03724	Alcasar|Benimeit (Zona)|Cap Blanc (Moraira/Teulada) (Urbanizacion)|Cometa, La (Moraira/Teulada) (Partida)|Fanadix (Moraira/Teulada) (Partida)|Moraira|Moravit|Paichi (Urbanizacion)|Pinar Del Advocat (Partida)|Sabatera, La (Urbanizacion)|San Jaime (Urbanizacion)
03725	Benimarco (Partida)|Castellons (Partida)|Teulada
03726	Abiar, L' (Partida)|Benicambra (Partida)|Benitachell (Nucleo)|Cumbre Del Sol|Poble Nou De Benitatxell, El/Benitachell|Pueblo Alcasar|Yuca (Partida)
03727	Xalo
03728	Alcalali|Benarrosa (Zona)|Cumbres De Alcalali (Urbanizacion)|La Solana|Trosos, Los (Zona)|Vereda Park (Urbanizacion)
03729	Cometa (Senija)|Lliber|Senija
03730	Aduanas De Mar|Xabia/Javea
03737	Ermita (Urbanizacion)|Montgo-Toscamar
03738	Arenal|Bahia De Javea (Urbanizacion)|Balcon Al Mar (Javea/Xabia) (Urbanizacion)|Cap Marti|Costa Nova|Costa Nova (Urbanizacion)|Parque Calablanca (Urbanizacion)|Toscal|Trencal
03739	Alborada (Urbanizacion)|La Mandarina|Lluca|Los Cerezos|Rafalet (Urbanizacion)|Sol Del Este|Tosalet, El (Javea/Xabia)
03740	Bolerias|Comes|Cuadros|Ecles Altos|Ecles Bajos|Gata De Gorgos|Gaya|La Faja|Miralbons|Mirandas|Mirandes|Senies|Serillars|Tossals|Troset
03749	Alqueria Gasens|Biserot|Casas Nuevas|Cova Ampla|Ferrandos|Foyes Blanques|Jesus Pobre|Los Lagos|Planises|Rompudetes|Senieta Reina|Sun Valley|Tosal|Tosal Roig
03750	Barranco Parra|Cometa-Orbeta|Monte Pedreguer / Muntanya De Pedreguer (Urbanizacion)|Monte Sella / Muntanya De La Sella (Urbanizacion)|Pedreguer|Ventas De Pedreguer
03759	Aldea De Las Cuevas (Urbanizacion)|Benidoleig|Colina Del Sol (Urbanizacion)|Cueva De Las Calaveras|España La Vieja (Urbanizacion)|Rincon Del Silencio (Urbanizacion)
03760	Ondara|Pamis|Tosals (Partida)|Viñals (Partida)
03769	Benimeli|El Rafol D'Almunia|Montesano|Sanet Y Negrals
03770	El Verger
03778	Beniarbeig
03779	Almadrava (Playa)|Almetlerals (Partida)|Alters (Partida)|Barranquet (Partida)|Buscarrons (Urbanizacion)|Deveses (Partida)|Miraflor (Nucleo)|Mirarrosa (Nucleo)|Molinell (Nucleo)|Playa Santa Ana|Poblets, Els|Pueblo Naranjo (Urbanizacion)|Setla (Nucleo)|Sisques (Partida)|Sorts De La Mar (Partida)|Traveses (Partida)|Xironets (Partida)
03780	Pego
03786	Adsubia (Ajuntament Adsubia)|Beniaia / Beniaya (Nucleo)|Forna|La Vall D'Alcala
03788	Alcala De La Jovada|Beniali (Nucleo)|Benirrama (Nucleo)|Benisili / Benissili|Benisiva (Nucleo)|Benitaia (Nucleo)|Carroja, La (Nucleo)|Llombay|Patro|Vall De Gallinera
03789	La Vall D' Ebo|Monte Pego (Urbanizacion)
03790	Orba (Casco Antiguo)
03791	Benimaurell|Campell|El Eden|Fleix|Fontilles|La Vall De Laguar|Plana, La (Paradisorba)
03792	Coll De Rates|Murla|Orbeta (Urbanizacion)|Parcent
03793	Castell De Castells
03794	Benigembla
03795	Aspre (Partida)|Capso (Partida)|Masils (Partida)|Orbeta (Nucleo)|Sagra|Tormos|Trullent (Partida)
03800	Alcoi/Alcoy
03801	Alcoi/Alcoy
03802	Alcoi/Alcoy
03803	Alcoi/Alcoy
03804	Alcoi/Alcoy
03810	Benilloba
03811	Capellans|Gorga|Quatretondeta
03812	Balones|Benimassot|Millena
03813	Facheca|Famorca|Tollos
03814	Alcoleja|Ares Del Bosque|Benasau|Beniafe
03815	Penaguila
03816	Benifallim
03819	Casas De La Carrasca|Estepar, El (Urbanizacion)|La Canaleta|La Sarga|Riau-Riau (Urbanizacion)
03820	Alcudia|Algars|Alqueria-Benifloret|Cocentaina
03827	Almudaina|Benillup|Benimarfull
03828	Benialfaqui|Catamarruch|Margarida|Planes
03829	Alqueria D'Asnar, L'
03830	Muro De Alcoy|Plana, La (Muro Alcoy) (Urbanizacion)
03837	Agres
03838	Alfafara
03839	Alqueria De Jorda|Benamer|Cela De Nuñez|Turballos
03840	Gaianes
03841	Alcocer De Planes
03850	Beniarres
03860	Lorcha/Orxa, L'
03870	Penella
04001	Almeria
04002	Almeria|El Palmer
04003	Almeria
04004	Almeria
04005	Almeria
04006	Almeria
04007	Almeria
04008	Almeria
04009	Almeria
04070	Almeria
04071	Almeria
04080	Almeria
04100	Nijar
04110	Campohermoso
04113	Atochares|El Viso
04114	Los Cortijillos|Polopos|Saladar Y Leche|Torre Del Campo|Tristanes|Venta Del Pobre
04115	Rodalquilar
04116	Albaricoques|Fernanperez|Hornillos|Hortichuelas|Las Negras
04117	Boca De Los Frailes|Cuevas Del Lino|El Barranquete|Los Grillos|Los Nietos|Pozo De Los Frailes|Presillas Bajas|Pueblo Blanco|San Isidro De Nijar
04118	La Isleta|Los Escullos|San Jose
04119	Huebro
04120	Costacabana|El Bobar|El Mami|La Cañada De San Urbano|Loma Cabrera|Venta Gaspar
04130	El Alquian
04131	Retamar
04140	Carboneras|La Cañada De Don Rodrigo
04149	Aguamarga|El Argamason|El Cañarico|El Cumbrero|El Llano De Don Antonio|El Saltador Alto|El Saltador Bajo|Gafares (Carboneras)|Gafares (Sorbas)|La Cueva Del Pajaro|La Islica|La Mesa Roldan|Los Alamillos
04150	El Cabo De Gata|Rambla Morales
04151	La Fabriquilla|Mazarrulleque|Pujaire (Almeria)|Pujaire (Nijar)|Ruescas (Almeria)|Ruescas (Nijar)
04160	Cuevas De Los Medinas|Cuevas De Los Ubedas
04200	Cartero|Espeliz|Joluque|Nudos, Los (Tabernas)|Oro Verde|Puente De Guayar|Tabernas
04210	Lucainena De Las Torres
04211	La Vega|Los Encalmados|Los Olivillos|Los Pichiriches|Los Retacos|Los Yesos|Rambla Honda, La (Lucainena De Las Torres)|Saltador, El (Lucainena De Las Torres)|Turrillas
04212	Castro De Filabres|El Tallon Bajo|Olula De Castro|Pago Aguilar Bajo|Velefique
04213	Moraton|Nudos, Los (Senes)|Senes
04230	Club De Tenis (Urbanizacion)|El Carmen|Fuensanta, La (Huercal)|Huercal De Almeria|Las Cumbres
04240	Campamento|La Juaida|Viator
04250	Pechina
04259	Sierra Alhamilla
04260	Abriojal|Marraque|Rioja
04270	Cinta Blanca|Garrido|Hueli|La Cumbre|Los Mañas|Molinos, Los (Sorbas)|Pilar, El (Sorbas)|Sorbas
04271	Breña|El Campico De Las Moletas|El Chive|El Fonte|El Pilar|El Sacristan|El Saeti|Fuenblanquilla|Jauro (Lubrin)|La Alameda|La Mela|La Rambla Aljibe|Las Moletas|Los Dioses|Los Herrera|Los Jarales|Los Matreros|Los Ramos|Los Risas|Lubrin|Marchal, El (Lubrin)|Martinez, Los (Sorbas)|Pocico, El (Lubrin)|Puntal, El (Lubrin)|Rambla Honda, La (Lubrin)
04274	La Canal|La Fuentecilla|Los Morales|Marchal, El (Uleila Del Campo)|Rincon, El (Uleila Del Campo)|Zofre
04275	Benitorafe|Cocon Del Peral|Los Arroyos|Tahal
04276	Alcudia De Monteagud|Benitagla|Benizalon|La Fuente De La Higuera|Rambla Del Marques
04277	Campico|Carrasco|El Salto Del Lobo|El Tesoro|Gacia Alto|Gacia Bajo|Gafarillos|Herradura|La Rondeña|Los Loberos|Los Perales|Marchalico Viñicas|Mizala|Peñas Negras|Royo Morera (Turre)|Urra|Varguicas
04278	Cariatiz|Los Alias|Los Andreses|Los Castaños
04279	Albarracin|Barranco De Los Lobos|El Mayordomo|El Pilarico|El Rincon Del Marques|Gochar|La Tejica|Moras|Quijiliana|Uleila Del Campo
04280	Los Gallardos
04288	Alfaix|Bedar|El Albarico|El Campico|El Pinar|La Perulaca|La Serena|Los Collados|Los Pinos
04289	Almocaizar|La Herreria|La Huelga|Los Giles
04400	Alhama De Almeria|Huechar
04409	Alicun|Huecija
04410	Benahadux|El Chuche
04420	La Calderona|Mondujar|Santa Fe De Mondujar
04430	Instincion
04431	Illar
04440	Ragol
04450	Canjayar|La Barriada De Alcora
04458	Almocita|Beires|Padules
04459	Ohanes|Tices
04460	Fondon
04470	Laujar De Andarax
04479	Bayarcal|Benecid|Fuente Victoria|Guarros|Paterna Del Rio
04480	Alcolea
04500	Fiñana|La Heredad|Norias, Las (Fiñana)
04510	Abla|El Camino Real|Las Adelfas|Los Milanes|Montagon
04520	Abrucena
04530	Doña Maria De Ocaña|Ocaña|Soleres, Les
04531	Alboloduy
04532	Cortijo Real|El Haza Del Riego|Escullar|Santillana
04533	Los Monjos|Pago De Escuchagrano
04540	Los Sanchos|Nacimiento
04549	Aulago|Gilma|Las Piletas|Los Navarros|Los Rojas
04550	Arroyo De Verdelecho|El Calar Alto|El Cortijo Alto|Fuente Santa|Gergal|Portocarrero
04558	Las Alcubillas|Las Alcubillas Altas
04559	El Almendral|Las Aneas|Las Tablas
04560	El Ruini|Gador|Las Minas|Moscolux|Paulenca
04567	Alhabia
04568	Alsodux|Santa Cruz De Marchena
04569	Bentarique|Terque
04600	Huercal-Overa|Los Carmonas|San Francisco
04610	Calguerin|Cirera|Cuatro Higueras (Cuevas Del Almanzora)|Cuevas Del Almanzora|El Arteal|El Molino Del Tarahal|El Realengo|El Rulador|Era Alta|Fuente Jaula|La Algarrobina|Las Rozas
04616	Villaricos
04617	Palomares
04618	Algarrobos, Los (Palomares)|Aljarilla|Burjulu|El Martinete|El Morro|El Tomillar|La Cañada De Lorca|La Muleria|Las Cunas|Las Herrerias|Las Orillas|Los Pocos Bollos|Rioja (Palomares)|Silos, Los (Cuevas Del Almanzora)
04619	Arnilla|El Alhanchete|El Largo|Grima|Guazamara|Jordana|Jucaini|La Portilla|Las Cupillas|Los Lobos|Los Perdigones
04620	Vera
04621	Las Marinas|Puerto Rey|Vera-Playa
04628	Antas|El Real|La Fuente Abad|Los Llanos Del Mayor
04629	Aljariz|Jauro (Antas)|La Huerta
04630	Garrucha
04638	Alparatas|El Agua Del Medio|La Alcantarilla|Las Cuartillas|Mojacar|Parata, La (Mojacar)
04639	El Cortijo Grande|La Fuente Del Royo|Turre
04640	Caparroses, Los (Pulpi)|Molino, El (Pulpi)|Pozo Del Esparto (Pulpi)|Pulpi
04647	Benzal|El Convoy|La Fuente|La Herradura|Las Canalejas|Los Aznares|Los Campoys|Los Guiraos|Los Pinares|Pozo De La Higuera|Vizcaino
04648	Barrio Mortero|Cala Panizo|El Calon|El Cocon|Pilar De Jaravia|Pozo Del Esparto (Cuevas Del Almanzora)|San Juan De Los Terreros
04649	Estacion, La (San Miguel De Pulpi)
04650	Almajalejo (Zurgena)|Fuente Del Pino|Llanos, Los (Zurgena)|Los Menchones|Zurgena
04660	Arboleas|Casablanca (Arboleas)|El Chopo|German|Hoya, La (Arboleas)|La Cinta|La Perla|Las Tahullas|Llanos, Los (Arboleas)|Los Blesas|Los Carrascos|Los Castos|Los Cojos|Los Colorados|Los Garcias|Los Huevanillas|Los Peraltas|Prado, El (La Cinta)|Rincon, El (La Cinta)
04661	El Cucador|La Alfoquia|Limaria|Los Carasoles
04662	El Palaces|La Concepcion|Navarros, Los (Huercal Overa)|Pilar, El (Huercal Overa)|Santa Barbara
04690	Goñar|Norias, Las (Huercal Overa)
04691	Abejuela|Fuensanta, La (Urcal)|Gibiley|Los Gibaos|Los Pedregales|Rambla Grande|Urcal
04692	Almajalejo (Los Pardos)|Carrillos, Los (Taberno)|El Aceituno|La Perulera|Llanos, Los (Taberno)|Los Gateros|Pardos, Los (Taberno)|Pedro Garcia|Rambla De Taberno|Santopetar|Taberno|Teones, Los (Taberno)
04693	El Gor|El Puertecico|Fuente Amarga|Hoya, La (Huercal Overa)|La Loma|Menas, Los (Puertecico)|Minas, Las (Huercal Overa)|Piedras, Las (Huercal Overa)|Santa Maria De Nieva
04694	Gacia|Saltador, El (Pulpi)
04700	El Ejido|Santo Domingo
04710	La Redonda|San Silvestre|Santa Maria Del Aguila
04711	Almerimar
04712	Balerma
04713	Balanegra
04715	Los Baños De Guardias Viejas|Matagorda|Pampanico
04716	Las Norias De Daza
04717	San Agustin
04720	Aguadulce|El Campillo Del Moro|El Parador De Las Hortichuelas
04721	Parador, El (Vicar)
04727	La Envia
04728	Felix
04729	Enix|Marchal De Enix
04738	Barrio De Archilla|Cañada Sebastiana|Cortijos De Marin (Vicar)|El Congo|La Gangosa|La Lomilla|Las Cabañuelas|Llanos De Vicar|Puebla De Vicar|Vicar
04740	Marinas, Las (Roquetas De Mar)|Roquetas De Mar|Roquetas De Mar (Urbanizacion)
04741	Cortijos De Marin
04743	El Solanillo
04745	La Mojonera
04746	La Venta Del Viso|Las Cantinas
04750	Celin|Dalias
04760	Berja|Castala|El Cid
04768	Darrical|Lucainena De Darrical
04769	Alcaudique|Beneji|Beninar|Chiran|El Rio Chico|El Rio Grande|Hirmes|La Peñarrodada|San Roque (Berja)
04770	Adra|Canal, El (Adra)|El Corral|El Patio|Gurrias|La Curva|La Loma De Los Vargas|Los Moras|Parra, La (Adra)|Perez, Los (Adra)
04778	El Toril|Guainos Altos|Guainos Bajos|La Alcazaba|La Fuente Del Ahijado|Lance De La Virgen
04779	Alqueria, La (Venta Nueva)|Campillo, El (Venta Nueva)|El Puente Del Rio|La Fuente Santilla|Las Cuatro Higueras|Venta Nueva
04800	Albox|Los Finos
04810	El Barranco De Quiles|El Cerrogordo|Frax|Frax De Arriba|La Ermita|La Fuente Del Negro|La Piedra Amarilla|Los Chacones|Los Chulos|Los Gonzalez|Madrid|Maguas|Malinos|Marchal, El (Oria)|Oria|Partaloa
04811	Arroyo Medina|Campillo, El (Oria)|Capairola|Daimuz|El Margen|El Peñon Alto|El Peñon Bajo|Gazquez, Los (Los Alamos)|La Cañada|Los Adrianes|Los Alamos|Los Jacinto|Martinez, Los (Oria)|San Miguel (Alamos)
04812	El Llano De Las Animas|Fuente Del Mojon|Llanos De Los Olleres|Llanos Del Espino
04813	Doña Juana|El Villar|La Yegua Baja|Las Pocicas|Los Cerricos|Saliente Alto|Saliente Bajo (Albox)
04814	La Aljambra|Las Labores|Locaiba
04815	Almanzora|Los Morillas
04820	El Rio De Mula|Gazquez, Los (Velez Rubio)|Ginte|Los Asensio|Motailon|Velez-Rubio
04825	Aspilla|Chirivel|El Cantal|El Contador|El Mojonar|La Rambla De Abajo|La Rambla De Arriba|Roquez
04826	Los Aranegas|Los Gatos|Los Oquendos|Los Ramales
04827	Los Cabreras|Los Torrentes|Pardos, Los (Velez Rubio)|Parra, La (Torrentes)|Tonosa
04828	Bancalejo|Calabuche|Carrasca, La (Campillo)|La Alamicos, Los - Dehesa|La Dehesa|La Mata De Bolaimi|Los Molinos
04829	Alqueria, La (Velez Rubio)|Canalica|El Charche|El Espadin|El Piar De Abajo|La Losilla|Las Casas|Solana
04830	Alara|Alcoluches|Derde|El Rio Claro|Los Canales|Montalviche|Taibena|Velez-Blanco
04838	Graj|La Alfahuara|Maria
04839	La Cañada De Cañepla|La Cañada Grande|Las Cobatillas|Macian|Mancheño|Topares
04850	Cantoria|El Arroyo Aceituno|Hoya, La (Cantoria)|La Hojilla|Las Casicas|Marchal, El (Cantoria)|Terreros
04857	Albanchez
04858	Carrasca, La (Albanchez)|El Arroyo Albanchez|El Barranco Del Infierno|La Fuente Del Tio Molina|La Hoya De La Zarza|La Palmera|La Piedra De Zahor|La Tia Lucia|Los Borregos|Los Calesas|Los Molinas
04859	Chercos|Chercos Nuevos|Chercos Viejos|Cobdar|El Tablar|Gasparillo|Lijar
04860	Huitar Mayor|Huitar Menor|Noria, La (Olula Del Rio)|Olula Del Rio
04867	El Arroyo Franco Y Estella|El Reul Alto|Macael|Marchal, El (Macael)
04868	Laroya
04869	Cuesta Del Pino|El Olivar|El Palomar|Fines|La Cañada De Las Cruces|Los Entrenas
04870	Purchena
04877	Somontin
04878	Sierro|Sufli
04879	Aguamarga (Urracal)|Urracal
04880	Porteros, Los (Tijola)|Tijola
04887	Cela|Cela (Estacion)|Higueral|Los Manolones|Lucar|Pozo Del Lobo
04888	Armuña De Almanzora|Bayarque
04889	Bacares|Dali
04890	Los Claveros|Los Marteses|Menas, Las (Seron)|Seron
04897	Alcontar|Aldeire|Amarguilla|Angosto De Abajo|Angosto De Arriba|Blanquez De Alcontar|Domenes|El Valle|Fuencaliente Y Calera|Los Brevas|Los Donatos|Los Raspajos|Los Vegas|Perez, Los (Alcontar)|Pilancon
04898	El Hijate|Ramil Alto|Ramil Bajo
04899	El Reconco|Hernandez, Los (Los Zoilos)|Jauca Alta|Jauca Baja|Las Hilarias|Los Zoilos
05001	Avila
05002	Avila
05003	Avila
05004	Avila
05005	Avila
05070	Avila
05071	Avila
05080	Avila
05100	Navaluenga
05110	El Barraco
05111	San Juan De La Nava
05112	Calas Del Burguillo
05113	Burgohondo
05114	Morisco|Villanueva De Avila
05115	Navarrevisca|Serranillos
05120	Navalmoral|Navandrinal|Navarredondilla|San Juan Del Molinillo|Villarejo
05122	Navaquesera|Navatalgordo
05123	Hoyocasero|Navalosa
05130	Baterna|Robledillo|Solosancho|Villaviciosa
05131	La Hija De Dios|Mengamuñoz|Narros Del Puerto
05132	Cepeda La Mora|Hoyos De Miguel Muñoz|Navalsauz|San Martin Del Pimpollar
05133	San Martin De La Vega Alberche
05134	Garganta Del Villar|Navadijos|Navalacruz
05140	Bularros|Casasola|Duruelo|Marlin|Martiherrero|Villaverde
05141	Altamiros|Benitos Del Rebollar|Chamartin De La Sierra|Gallegos De Altamiros|Narrillos Del Rebollar|Sanchorreja
05143	Pasarilla Del Rebollar|Valdecasa
05145	Manjabalago|Muñico|Ortigosa Del Rio Almar|Rinconada Del Rio Almar|San Juan Del Olmo
05146	Blascomillan|El Convento De Duruelo|El Parral|Herreros De Suso|Mancera De Arriba|Mirueña De Los Infanzones|San Garcia De Ingelmos|Vita
05147	Blascojimeno|Gallegos De Sobrinos|Gamonal De La Sierra|Hurtumpascual|Viñegra De La Sierra
05148	Cabezas Del Villar|Rivilla De La Cañada
05149	Cillan|Solana De Rioalmar
05150	Pascualcobo|San Miguel De Serrezuela
05151	Carpio Medianero|Diego Alvaro|Diego Del Carpio|Martinez
05152	Montalbo
05153	Aldealabad Del Miron|Arevalillo|Becedillas|Casillas De Chicapierna|Collado Del Miron|Malpartida De Corneja
05154	El Miron|Mercadillo|Narrillos Del Alamo|Navahermosa De Corneja|Valdemolinos|Ventosa De La Cuesta|Zapardiel De La Cañada
05160	Alamedilla Del Berrocal|Narrillos De San Leonardo
05162	Las Berlanas
05163	Gotarrendura|Monsalupe|Peñalba De Avila|Zorita De Los Molinos
05164	El Oso|Hernansancho|Riocabado
05165	Cabizuela|El Bohodon|Pedro-Rodriguez|Tiñosillos
05166	San Pascual|Villanueva De Gomez
05190	Cabañas|Escalonilla (Riofrio)|Riofrio
05191	Mironcillo|Niharra
05192	La Colilla|La Serrada|Muñopepe
05193	Aldeavieja|Blascoeles|Ojos-Albos|Santa Maria Del Cubillo
05194	Avila|Berrocalejo De Aragona|Brieva|Mediana De Voltoya|Vicolozano
05195	Bernuy Salinero|Urraca Miguel
05196	Tornadizos De Avila
05197	Aldea Del Rey Niño|El Fresno|Gemuño
05198	Bandadas|Palacio|Riatas|Sotalbo
05200	Arevalo
05210	Horcajo De Las Torres
05211	Bernuy- Zapardiel|Cabezas Del Pozo|Cantiveros|Cisla
05212	Aldeaseca|Canales|Fuente El Sauz|Fuentes De Año|Villanueva Del Aceral
05213	Langa
05214	Pajares De Adaja
05215	Donvidas|Palacios De Goda|Sinlabajos|Tornadizos De Arevalo
05216	Magazos|Nava De Arevalo|Noharre|Palacios Rubios|Vinaderos
05217	Cabezas De Alambre|Constanzana|Donjimeno|Jaraices|San Vicente De Arevalo
05220	Madrigal De Las Altas Torres|Villar De Matacabras
05229	Barroman|Bercial De Zapardiel|Castellanos De Zapardiel|San Esteban De Zapardiel
05230	Las Navas Del Marques
05239	Ciudad Ducal|Hoyo De La Guija|Peguerinos
05240	Navalperal De Pinares
05250	El Hoyo De Pinares
05260	Cebreros
05267	San Bartolome De Pinares
05268	Herradon De Pinares|Santa Cruz De Pinares
05270	El Tiemblo
05278	El Burguillo|La Rinconada Del Valle|Las Cruceras|Puente Nuevo
05279	Cerro De Guisando|La Atalaya
05280	Mingorria
05289	Cortos|Escalonilla (Tolbaños)|Gallegos De San Vicente|San Esteban De Los Patos|Saornil De Voltoya|Tolbaños
05290	Blascosancho|Sanchidrian
05291	Coto De Puenteviejo|Maello|Pinar De Puente Viejo
05292	Pozanco|Santo Domingo De Las Posadas|Vega De Santa Maria|Velayos
05294	La Cañada|Navalgrande
05296	Adanero|Espinosa De Los Caballeros|Gutierre-Muñoz|Orbita
05298	Mamblas|Rasueros|San Cristobal De Trabancos
05299	Blasconuño De Matacabras|Moraleja De Matacabras
05300	Crespos
05301	Muñosancho|Villamayor
05309	Chaherreros|Collado De Contreras|Muñogrande|Pascualgrande|Rivilla De Barajas|Viñegra De Moraña
05310	Fontiveros
05320	Cardeñosa
05350	Morañuela|San Pedro Del Arroyo
05357	Aveinte|Bravos|Castilblanco|Grandes|Grandes Y San Martin|Horcajuelo|Muñoyerro|San Martin De Las Cabezas|Santo Tome De Zabarcos|Sigeres|Villaflor
05358	Albornos|Muñomer Del Peco|Narros De Saldueña|Papatrigo|San Juan De La Encinilla
05369	Narros Del Castillo
05370	El Ajo|Flores De Avila
05380	Gimialcon|Salvadios
05400	Arenas De San Pedro|La Parra
05410	Mombeltran
05412	San Esteban Del Valle
05413	Santa Cruz Del Valle|Villarejo Del Valle
05414	Cuevas Del Valle
05415	El Hornillo
05416	El Arenal
05417	Guisando
05418	Hontanares|Ramacastañas
05420	Fuente De La Salud|Sotillo De La Adrada
05427	Fresnedilla|Higuera De Las Dueñas
05428	Casillas
05429	Navahondilla|Santa Maria Del Tietar
05430	La Adrada
05440	Piedralaves
05450	Casavieja
05460	Gavilanes
05461	Mijares
05470	Pedro Bernardo
05480	Candeleda
05489	El Raso
05490	Lanzahita
05491	La Higuera
05492	Poyales Del Hoyo
05500	Piedrahita
05510	Santa Maria Del Berrocal
05514	Bonilla De La Sierra|Cabezas De Bonilla|El Barrio|Mesegar De Corneja|Navaescurial|San Miguel De Corneja|Tortoles
05515	Casas Sebastian Perez|El Soto|La Almohalla|Pesquera
05516	Hoyorredondo|La Alameda|Las Casas Del Camino|Las Casillas|Palacios De Corneja|San Bartolome De Corneja|Villar De Corneja
05520	Aldealabad|Balbarda|Muñochas|Oco|Padiernos|Salobral|Sanchicorto
05530	Muñogalindo|Salobralejo|Santa Maria Del Arroyo
05540	Blacha|Guareña|La Torre|Muñana|Muñez
05560	Amavida|Muñotello|Pascualmuñoz|Poveda|Pradosegar|Vadillo De La Sierra|Villatoro
05571	Casas Del Puerto De Villatoro|Garganta De Los Hornos|La Ribera|Navacepedilla De Corneja|Pajarejos|Villafranca De La Sierra
05580	Aldeanueva Santa Cruz|Avellaneda|Carrascalejo|Collado, El (Santa Maria De Los Caballeros)|Los Cuartos|Navarregadilla|Santa Maria De Los Caballeros
05591	Villanueva Del Campillo
05592	Casas De Navancuerda|Collado, El (Santiago Del Collado)|La Lastra|Navalmahillo|Navamuñana|Nogal|Santiago Del Collado|Santiuste|Valdelaguna|Zarzal
05593	El Rehoyo|La Aldehuela|Las Navas|Las Solanillas|Los Molinos|Solanas Del Carrascal
05600	El Barco De Avila
05610	Becedas
05619	Gilbuena|Medinilla|Neila De San Miguel|San Bartolome De Bejar
05620	Casas De La Sierra|Cereceda|La Carrera|Lancharejo|Navalmoro
05621	Casas Del Rey|La Zarza|Los Narros|Puerto Castilla|Santiago De Aravalle|Solana De Avila
05630	Cardedal|Horcajo De La Ribera|La Aliseda De Tormes|La Lastra Del Cano|La Lastrilla|Navamediana|Navasequilla|Santiago Del Tormes
05631	La Angostura|La Herguijuela|Navalperal De Tormes|Ortigosa De Tormes|San Bartolome De Tormes|Zapardiel De La Ribera
05633	Navacepeda De Tormes|San Juan De Gredos
05634	Hoyos Del Collado|Hoyos Del Espino
05635	Barajas|Navarredonda De Gredos
05690	Bohoyo|Hermosillo|Los Guijuelos|Los Llanos De Tormes|Navamojada
05691	El Tremedal|Los Loros|Mazalinos|Santa Lucia De La Sierra|Serrania
05692	Casas De La Vega|El Barquillo|El Losar|Navamorisca
05693	Casas De Maripedro|Casas Del Abad|Gil Garcia|Hustias|La Canaleja|Retuerta|Umbrias
05694	Junciana|Palacios De Becedas
05695	La Horcajada
05696	El Hoyo|Encinares|Los Sauces|Riofraguas|San Lorenzo De Tormes|Vallehondo
05697	Cabezas Altas|Cabezas Bajas|Nava De Barco|Navalguijo|Navalonguilla|Navamures|Navatejares|Tormellas
06001	Badajoz
06002	Badajoz
06003	Badajoz
06004	Badajoz
06005	Badajoz
06006	Badajoz
06007	Badajoz
06008	Badajoz
06009	Badajoz|La Pilara
06010	Badajoz
06011	Badajoz
06012	Badajoz
06050	Base Aerea Talavera Real
06070	Badajoz
06071	Badajoz
06080	Badajoz
06100	Olivenza
06105	Cheles
06106	San Benito De La Contienda
06107	Villarreal
06108	San Jorge De Alor|Santo Domingo
06109	San Francisco De Olivenza|San Rafael De Olivenza
06110	Villanueva Del Fresno
06120	Oliva De La Frontera
06129	Zahinos
06130	Valverde De Leganes
06131	Alconchel
06132	Higuera De Vargas
06133	Taliga
06134	Valencia Del Mombuey
06140	Talavera La Real
06150	Santa Marta
06160	Barcarrota
06170	Alvarado|La Albuera
06171	Almendral
06172	Torre De Miguel Sesmero
06173	Nogales
06174	Salvaleon
06175	Salvatierra De Los Barros
06176	La Morera|La Parra
06177	Valle De Matamoros
06178	Valle De Santa Ana
06180	Gevora Del Caudillo
06181	Sagrajas
06182	Alcazaba
06183	Novelda Del Guadiana
06184	Pueblonuevo Del Guadiana
06185	Valdelacalzada
06186	Guadiana Del Caudillo
06187	Guadajira
06190	La Roca De La Sierra
06191	Puebla De Obando
06192	Villar Del Rey
06193	Botoa|Puente De Zapaton
06194	Valdebotoa
06195	Balboa|Villafranco Del Guadiana
06196	Aldea De Retamal|Aldea Del Cura|Corte De Peleas|Cortegana
06197	Entrin Alto|Entrin Bajo
06200	Almendralejo
06207	Aceuchal
06208	Villalba De Los Barros
06209	Solana De Los Barros
06210	Torremegia
06220	Villafranca De Los Barros
06225	Ribera Del Fresno
06226	Hinojosa Del Valle
06227	Llera
06228	Hornachos
06229	Puebla Del Prior
06230	Los Santos De Maimona
06240	Fuente De Cantos
06249	Calzadilla De Los Barros
06250	Bienvenida
06260	Monesterio
06270	Segura De Leon
06280	Fuentes De Leon
06290	Usagre
06291	Montemolin
06292	Calera De Leon
06293	Cabeza La Vaca
06300	Zafra
06310	Puebla De Sancho Perez
06320	Medina De Las Torres
06329	Atalaya
06330	Valencia Del Ventoso
06340	Fregenal De La Sierra
06350	Higuera La Real
06360	Fuente Del Maestre
06370	Burguillos Del Cerro
06378	Valverde De Burguillos
06380	Jerez De Los Caballeros
06389	Brovales|La Bazana|Valuengo
06390	Feria
06391	La Lapa
06392	El Raposo
06393	Alconera
06394	Bodonal De La Sierra
06400	Don Benito
06410	Conquista|Santa Amalia|Torrefresneda|Valdehornillos
06411	Medellin
06412	Hernan Cortes|Ruecas|Vivares
06413	Mengabril
06415	Yelbes
06420	Castuera
06427	Monterrubio De La Serena
06428	Puerto Hurraco
06429	Benquerencia De La Serena|Puerto Mejorada
06430	Zalamea De La Serena
06439	Esparragosa De La Serena
06440	Malpartida De La Serena
06441	Higuera De La Serena
06442	Retamal De Llerena
06443	Campillo De Llerena
06444	Valencia De Las Torres
06445	Higuera De Llerena
06446	San Cristobal De Zalamea
06450	Quintana De La Serena
06458	Valle De La Serena
06459	La Guarda
06460	Campanario
06468	Magacela
06469	La Coronada
06470	Guareña
06473	Villagonzalo
06474	Valdetorres
06475	Oliva De Merida
06476	Palomas
06477	Puebla De La Reina
06478	Manchita
06479	Cristina
06480	Montijo
06486	La Nava De Santiago
06487	Cordobilla De Lacara
06488	Carmonita
06489	Lacara, De (Poblado)
06490	Puebla De La Calzada
06498	Lobon
06499	Barbaño
06500	San Vicente De Alcantara
06510	Alburquerque
06518	La Codosera
06519	Bacoco|Benavente|El Marco|La Rocita De Mayorga
06600	Cabeza Del Buey
06610	Peñalsordo
06611	Zarza Capilla
06612	Capilla
06613	Helechal
06614	Almorchon
06615	Nava, La (De Almorchon)
06620	Esparragosa De Lares
06630	Puebla De Alcocer
06640	Talarrubias
06650	Siruela
06655	Sancti-Spiritus
06656	Garlitos
06657	Risco
06658	Tamurejo
06659	Baterno
06660	Fuenlabrada De Los Montes
06670	Herrera Del Duque
06678	Villarta De Los Montes
06679	Peloche
06680	Castilblanco
06689	Valdecaballeros
06690	Garbayuela
06691	Pantano De Cijara
06692	Helechosa De Los Montes
06700	Villanueva De La Serena
06710	Entrerrios
06711	Gargaligas
06712	Zurbaran
06713	Los Guadalperales
06714	La Haba
06715	Rena
06716	Villar De Rena
06717	Palazuelo|Puebla De Alcollarin
06718	Castillo De La Encomienda
06719	El Torviscal
06720	Valdivia
06730	Acedera|Obando
06731	Vegas Altas
06740	Orellana La Vieja
06750	Orellana De La Sierra
06760	Navalvillar De Pela
06770	Casas De Don Pedro
06800	Merida
06810	Calamonte
06820	Don Alvaro
06830	La Zarza
06840	Alange
06850	Arroyo De San Servan
06860	Esparragalejo
06870	La Garrovilla
06880	Torremayor
06890	Valverde De Merida
06891	Mirandilla
06892	Trujillanos
06893	San Pedro De Merida
06894	Aljucen|El Carrascalejo
06900	Llerena
06906	Puebla Del Maestre
06907	Pallares
06908	Santa Maria La Nava
06909	Trasierra
06910	Granja De Torrehermosa
06919	Peraleda Del Zaucejo
06920	Azuaga
06927	Valverde De Llerena
06928	Malcocinado
06929	La Cardenchosa
06930	Berlanga
06939	Maguilla
06940	Ahillones
06950	Villagarcia De La Torre
06960	Casas De Reina
06970	Reina
06980	Fuente Del Arco
07001	Palma De Mallorca
07002	Palma De Mallorca
07003	Palma De Mallorca
07004	Palma De Mallorca
07005	Palma De Mallorca
07006	Palma De Mallorca
07007	Palma De Mallorca
07008	Palma De Mallorca
07009	Palma De Mallorca
07010	Palma De Mallorca
07011	Palma De Mallorca|Son Roca-Son Ximelis (Barri)
07012	Palma De Mallorca
07013	Palma De Mallorca
07014	Palma De Mallorca
07015	Palma De Mallorca
07070	Palma De Mallorca
07071	Palma De Mallorca
07080	Palma De Mallorca
07100	S'Horta (Soller)|Soller
07101	Biniaraix
07108	Port De Soller
07109	Fornalutx
07110	Bunyola
07120	La Garriga|Palma De Mallorca|Son Espanyol|Son Sardina
07121	Palma De Mallorca|Parc Bit (Urbanizacion)
07122	Palma De Mallorca|Universitat Illes Balears
07140	Ca'S Cana|Sencelles
07141	Cabaneta (Sa)|Es Pla De Na Tesa/El Pla De Na Tesa|Es Pont D'Inca/El Pont D'Inca|Marratxi|Marratxinet (Marratxi)|Portol
07142	Alqueries|Coves|Olleries|Santa Eugenia
07143	Biniali|Son Arosa
07144	Costitx|Jornets
07150	Andratx
07157	Port D'Andratx
07159	Arraco (S')|Sant Elm
07160	Camp De Mar (Es)|Peguera
07170	Son Maxella|Valldemossa
07179	Alconasser|Deia|Llucalcari
07180	El Toro|Galatzo (Santa Ponça) (Urbanitzacio)|Santa Ponça
07181	Bendinat|Cas Catala|Castillo De Bendinat|Costa D'En Blanes|Illetes (Ses)|Magaluf|Palmanova|Portals Nous|Portals Vells|Sa Porrassa/La Porrassa|Sol De Mallorca|Son Ferrer (Urbanitzacio)
07183	Costa De La Calma
07184	Calvia
07190	Esporles|Port Des Canonge/Port Del Canonge|S'Esglaieta
07191	Banyalbufar
07192	Estellencs
07193	Coma, Sa (Urbanitzacio)|Palmanyola|Sa Font Seca/La Font Seca
07194	Puigpunyent
07195	Galilea
07196	Capdella, Es
07198	Palma De Mallorca|S'Hostalot (Urbanitzacio)|Sa Creu Vermella/La Creu Vermella|Son Ferriol
07199	Aranjassa (S')|Palma De Mallorca|Pla De Sant Jordi|Sant Jordi
07200	Felanitx
07208	Carritxo (Es)|Cas Concos Des Cavaller|Son Negre
07209	Las Canteras|Son Caldero|Son Mayol|Son Mesquida|Son Proenç|Son Valls
07210	Algaida
07220	Pina
07230	Montuiri
07240	Sant Joan
07250	Vilafranca De Bonany
07260	Porreres
07300	Inca
07310	Campanet|Ullaro (Campanet) (Lloc)
07311	Buger
07312	Mancor De La Vall
07313	Selva
07314	Caimari
07315	Cala Tuent|Escorca|Lluc|Port De Sa Calobra|Sa Calobra/La Calobra
07316	Moscari
07320	Santa Maria Del Cami (Isla De Mallorca)
07330	Consell
07340	Alaro
07349	Orient
07350	Biniagual|Binissalem
07360	Lloseta
07369	Biniamar
07400	Alcudia|Mal Pas - Bon Aire|Marina-Manresa|Platja De Alcudia (Urbanitzacio)|Port D'Alcudia|Son Fe
07420	Pobla (Sa)
07430	Llubi
07440	Muro
07450	Santa Margalida
07458	Ca'N Picafort|Platja De Muro (Urbanitzacio)
07459	Son Serra De Marina
07460	Pollença
07469	Cala Carbo|Cala Sant Vicenç (Pollença)
07470	Base Aeria De Pollença|Port De Pollença
07500	Manacor
07509	Son Fangos|Son Macia
07510	Sineu
07511	Ruberts
07518	Lloret De Vistalegre
07519	Maria De La Salut
07520	Bon Any|Petra
07529	Ariany
07530	Sant Llorenç Des Cardassar
07540	Son Carrio (Mallorca)
07550	Son Servera
07559	Cala Bona|Costa De Los Pinos|Port Verd
07560	Cala Millor|Sa Coma (Cala Millor)
07570	Arta
07579	Betlem|Cala Mitjana (Mallorca)|Colonia De Sant Pere
07580	Capdepera
07589	Cala Mesquida|Cala Provensals|Font De Sa Cala|Na Taconera
07590	Cala Gat|Cala Lliteres|Cala Ratjada|Es Carregador|Pedruscada
07600	Arenal (S')|Cadenes (Ses)|Es Pitlari|Palma De Mallorca|Ses Cadenas
07608	Palma De Mallorca
07609	Badia Blava|Badia Gran|Bellavista|Cala Blava (Urbanitzacio)|Maioris Decima (Urbanitzacio)|Palmeres, Les|Puig De Ros (Urbanitzacio)|Son Veri Nou (Urbanitzacio)|Tollerich|Urbanizacion Sa Torre
07610	Can Pastilla|Las Maravillas|Palma De Mallorca
07611	Palma De Mallorca
07620	Llucmajor
07629	Randa
07630	Campos|El Palmer
07638	Colonia De Sant Jordi
07639	Cala Pi|Covetes (Ses)|Rapita (Sa)|S'Estanyol|Vallgornera
07640	Salines (Ses)
07650	Santanyi
07659	Cala Figuera (Mallorca)|Cala Santanyi|Calo Den Busques|Sa Torre Nova
07660	Cala D'Or
07669	Cala Ferrera|Cala Serena|Calonge|Horta, S' (Felanitx)
07670	Cala Marsal|Portocolom
07680	Cala Anguila - Cala Mendia|Portocristo/Port De Manacor
07687	S'Illot-Cala Morlanda
07688	Cala Murada
07689	Cala Tropicana (Platja)|Calas De Mallorca|Espinagar
07690	Cala Llombards|Cala S'Almonia|Cap Des Moro|Costa, La (Santanyi)|Llombards|Son Moger
07691	Barca Trencada|Cala Mondrago|Portopetro|S'Alqueria Blanca/L'Alqueria Blanca
07700	Grau (Es) (Platja)|Mao|Mesquida (Sa) (Platja)|Murta, Es|San Antonio (Mahon)
07701	Mao
07702	Mao
07703	Mao
07710	Sant Lluis
07711	Binibeca Nou (Sant Lluis) (Urbanitzacio)|Binibeca, De (Platja)|Binibequer|Biniencolla (Sant Lluis) (Urbanitzacio)|Binisafuller Platja (Sant Lluis) (Urbanitzacio)|Binisafuller Roters (Sant Lluis) (Urbanitzacio)|Binissafuller|Cap D'En Font|S'Ullastrar|Torret (Caserio)|Uestra, S' (Sant Lluis) (Urbanitzacio)|Ullastrar, L'
07712	Binixica|Es Canutells/Els Canutells|Llucmaçanes|Sant Climent
07713	Alcaufar|Cala Biniancolla|Es Consell/El Consell (Sant Lluis) (Caserio)|Es Pou Nou|Marina De Son Ganxo|Punta Prima (Platja)|S'Algar
07714	Mao
07720	Cala San Esteban|Es Castell|Son Vilar (Es Castell De Menorca)|Trebeluger
07730	Alaior|Argentina, La (Urbanitzacio)|Cala'N Porter|Calas Covas|Sa Roca|San Jaime Mediterraneo (Urbanitzacio)|Son Bou (Platja)|Torre Soli Nou (Urbanitzacio)
07740	Covas Novas (Mercadal)|Mercadal, Es|Na Macaret (Urbanitzacio)|Port D'Addaia|S'Arenal D'En Castell (Menorca) (Urbanitzacio)|Son Parc (Urbanitzacio)
07748	Fornells|Playa De Fornells (Urbanitzacio)
07749	Es Migjorn Gran/El Migjorn Gran|Sant Tomas, Platja (Urbanitzacio)
07750	Cala Galdana|Ferreries|Serpentona (Urbanizacion)
07760	Ciutadella De Menorca
07769	Cala Blanca (Ciutadella De Menorca) (Urbanitzacio)|Cala Blanes|Cala En Blanes|Cala'N Bosch|Cala'N Morell|Cap D'Artruix (Ciutadella De Menorca)|Delfines, Los (Urbanizacion)|Santandria (Platja)|Son Blanc (Ciutadella De Menorca)|Torre Del Ram
07800	Eivissa|Eivissa-San Juan (Carretera), Hasta Km.1,900
07810	Cala Portinax (Urbanitzacio)|Sant Joan De Labritja
07811	Cala De San Vicente Eivissa|Punta Grossa|Sant Vicent De Sa Cala
07812	Sant Llorenç De Balafia
07813	Can Cabrit|Can Negre|Cas Corp|Puig De'N Valls
07814	Santa Gertrudis De Fruitera
07815	Port De Sant Miquel (Urbanitzacio)|Sant Miquel De Balansat
07816	Sant Mateu D'Albarca|Sant Rafel De Sa Creu/Sant Rafel De La Creu
07817	Aeroport D'Eivissa|Sant Jordi De Ses Salines|Sant Josep De Sa Talaia (Plana Den Fita) (Barriada)|Sant Josep De Sa Talaia (Sa Carroca)|Sant Josep De Sa Talaia (Urbanitzacio Platja Den Bossa)
07818	Sant Josep De Sa Talaia (Sant Francesc De S'Estany)
07819	Ca'N Cirer|Cana Negreta (Barriada)|Cap Martinet|Nuestra Señora De Jesus|Prat De Jesus|Roca Llisa (Urbanitzacio)|Santa Eularia Del Riu (Can Furnet) (Barriada)|Santa Eularia Del Riu (Can Pep Simo) (Barriada)|Santa Eularia Del Riu (Can Ramon, Jesus) (Barriada)|Santa Eularia Del Riu (Cana Ventura) (Barriada)|Santa Eularia Del Riu (Puis Den Vinyets) (Urbanitzacio)|Santa Eularia Del Riu (Puis Manya) (Urbanitzacio)|Santa Eularia Del Riu (Ses Torres) (Urbanitzacio)
07820	Sant Antoni De Portmany
07828	Santa Agnes De Corona
07829	Sant Josep De Sa Talaia (Cala Bou)|Sant Josep De Sa Talaia (Cala Tarida)
07830	Sant Josep De Sa Talaia (Cala Vedella)|Sant Josep De Sa Talaia (Nucleo)
07839	Sant Josep De Sa Talaia (Benimussa)|Sant Josep De Sa Talaia (Sant Agusti Des Vedra) (Nucleo)|Sant Josep De Sa Talaia (Urbanitzacio Es Cubells)|Sant Josep De Sa Talaia (Urbanitzacio Vista Alegre-Sa Caixota)
07840	Sa Caleta (Santa Eularia)|Santa Eularia Del Riu (Buenavista) (Urbanitzacio)|Santa Eularia Des Riu
07849	Cala Llonga (Platja)|Can Frigolas (Barriada)|Can Marça (Barriada)|Can Sanso (Barriada)|Es Cana (Platja)|S'Argamassa (Urbanitzacio)|Sant Carles (Desde Km.7400 Hasta Final) (Carretera)|Santa Eularia Del Riu (Ca Na Polla) (Barriada)|Santa Eularia Del Riu (Can Guasch) (Barriada)|Santa Eularia Del Riu (Can Nadal) (Barriada)|Santa Eularia Del Riu (Can Ramon) (Barriada)|Santa Eularia Del Riu (Club Cala Azul) (Urbanitzacio)|Santa Eularia Del Riu (Esparragos) (Urbanitzacio)|Santa Eularia Del Riu (Miramar) (Urbanitzacio)|Santa Eularia Del Riu (Punta Blanca) (Urbanitzacio)|Santa Eularia Del Riu (Rota Den Pere Cardona) (Urbanitzacio)|Santa Eularia Del Riu (Sa Font) (Urbanitzacio)|Santa Eularia Del Riu (Valverde) (Urbanitzacio)|Siesta, La (Urbanitzacio)
07850	Cala Llenya (Platja)|Cala Mastella|Es Figueral (Platja)|Sant Carles De Peralta|Santa Eularia Del Riu (Barcarrompuda, Sa) (Urbanitzacio)|Santa Eularia Del Riu (Bungalow Park) (Urbanitzacio)|Santa Eularia Del Riu (Cala Boix) (Urbanitzacio)|Santa Eularia Del Riu (Joya, La) (Urbanitzacio)|Santa Eularia Del Riu (Pou Des Lleo) (Platja)|Santa Eularia Del Riu (Trenca, Sa) (Urbanitzacio)
07860	Cap De Barbaria|Sant Francesc De Formentera
07870	La Savina
07871	Pujols|Sant Ferran De Ses Roques
07872	Es Calo|Faro De La Mola|Nuestra Señora Del Pilar|Pilar De La Mola
08001	Barcelona
08002	Barcelona
08003	Barcelona
08004	Barcelona
08005	Barcelona
08006	Barcelona
08007	Barcelona
08008	Barcelona
08009	Barcelona
08010	Barcelona
08011	Barcelona
08012	Barcelona
08013	Barcelona
08014	Barcelona
08015	Barcelona
08016	Barcelona
08017	Barcelona
08018	Barcelona
08019	Barcelona
08020	Barcelona
08021	Barcelona
08022	Barcelona
08023	Barcelona
08024	Barcelona
08025	Barcelona
08026	Barcelona
08027	Barcelona
08028	Barcelona
08029	Barcelona
08030	Barcelona
08031	Barcelona
08032	Barcelona
08033	Barcelona
08034	Barcelona
08035	Barcelona
08036	Barcelona
08037	Barcelona
08038	Barcelona
08039	Barcelona
08040	Barcelona
08041	Barcelona
08042	Barcelona
08070	Barcelona
08071	Barcelona
08075	Barcelona
08080	Barcelona
08100	Mollet Del Valles
08104	Gallecs
08105	Conreria, La (Sant Fost Campcentelles)|Sant Fost De Campsentelles
08106	Santa Maria De Martorelles
08107	Martorelles
08110	La Vallençana|Montcada I Reixac
08120	La Llagosta
08130	La Florida|Mogoda|Santa Perpetua De Mogoda|Santiga (Santa Perpetua De Mogoda)
08140	Caldes De Montbui|Can Valls-To (Urbanitzacio)
08146	Gallifa
08148	Estany, L'
08150	Eixample, L'|Parets Del Valles
08160	Montmelo
08170	Montornes Del Valles
08171	Sant Cugat Del Valles
08172	Sant Cugat Del Valles
08173	Sant Cugat Del Valles
08174	Sant Cugat Del Valles
08178	Collsuspina
08180	Moia
08181	Sentmenat
08182	Sant Feliu De Codines
08183	Castellcir|Castellterçol|Granera
08184	Palau-Solita I Plegamans
08185	Lliça De Vall
08186	Lliça D'Amunt
08187	Rieral, El (Stª Eulalia De Ronçana)|Santa Eulalia De Ronçana
08188	Vallromanes
08189	Sant Quirze Safaja
08190	Sant Cugat Del Valles
08191	Rubi
08192	Sant Quirze Del Valles
08193	Bellaterra|Universitat Autonoma De Barcelona
08194	Fonts, Les (Sant Quirze Del Valles)
08195	Mira-Sol (Ver Callejero Sant Cugat)|Sant Cugat Del Valles
08196	Planes, Les (Ver Callejero Sant Cugat)|Sant Cugat Del Valles
08197	Sant Cugat Del Valles|Valldoreix (Ver Callejero Sant Cugat)
08198	Sant Cugat Del Valles
08199	Colonia Puig, La (Marganell)|Montserrat (Monestir)|Santa Cecilia (Marganell)
08200	Sabadell
08201	Sabadell
08202	Sabadell
08203	Sabadell
08204	Sabadell
08205	Sabadell
08206	Sabadell
08207	Sabadell
08208	Sabadell
08210	Barbera Del Valles
08211	Can Carner (Residencial)|Castellar Del Valles|Pla De La Bruguera|Sant Feliu Del Raco
08212	Sant Llorenç Savall
08213	Polinya
08214	Badia Del Valles
08220	Terrassa
08221	Terrassa
08222	Terrassa
08223	Terrassa
08224	Terrassa
08225	Terrassa
08226	Terrassa
08227	Terrassa|Torrebonica
08228	Fonts, Les (Terrassa)|Terrassa
08230	Matadepera|Pedritxes, Les|Sant Llorenç (Matadepera)
08231	Ullastrell
08232	Viladecavalls
08233	Vacarisses
08240	Manresa|Viladordis
08241	Manresa
08242	Manresa
08243	Manresa
08248	Manresa
08250	Sant Joan De Vilatorrada|Sant Marti De Torroella
08251	Castellnou De Bages|Santpedor
08253	Sant Salvador De Guardiola
08254	El Pont De Vilomara I Rocafort|Pont De Vilumara (Manresa)
08255	Castellfollit Del Boix
08256	Aguilar De Segarra|Rajadell
08259	Fals|Fonollosa
08260	Argensola (Castellnou De Bages)|Suria
08261	Cardona|La Coromina
08262	Callus
08263	Sant Mateu De Bages
08269	Barri La Rata (Navas)|Coaner|El Pala De Torroella|Salo|Sant Salvador De Torroella|Valls De Torruela
08270	Navarcles
08271	Artes
08272	El Pont De Cabrianes|Sant Fruitos De Bages
08273	Santa Maria D'Olo
08274	Sant Feliu Sasserra
08275	Calders|Monistrol De Calders
08278	Mura|Talamanca
08279	Avinyo
08280	Calaf
08281	Calonge De Segarra|Coromines, Les (Aguilar De Segarra)|Enfesta|La Molsosa|Prades De Molsosa|Prats De Rei, Els|Sant Pere Sallavinera
08282	Pujalt|Sant Marti Sesgueioles
08283	Castellfollit De Riubregos
08289	Copons|Veciana
08290	Cerdanyola Del Valles
08291	Ripollet
08292	Can Fosalba (Hostalets De Pierola)|Esparreguera|Serra Alta (Hostalets De Pierola)
08293	Collbato
08294	El Bruc|Mas D'En Pi (Hostalets De Pierola)
08295	Sant Vicenç De Castellet
08296	Castellbell I El Vilar
08297	Castellgali
08298	Marganell|Vilamaric (Monistrol De Montserrat)
08299	Rellinars
08300	Mataro
08301	Mataro
08302	Mataro
08303	Mataro
08304	Mataro
08310	Argentona
08317	Orrius
08318	Canyamars (Dosrius)
08319	Dosrius
08320	El Masnou
08328	Alella
08329	Teia
08330	Premia De Mar
08338	Premia De Dalt
08339	Vilassar De Dalt
08340	Vilassar De Mar
08348	Cabrils
08349	Cabrera De Mar
08350	Arenys De Mar
08358	Arenys De Munt
08359	Sant Iscle De Vallalta
08360	Canet De Mar
08370	Calella
08380	Malgrat De Mar
08389	Palafolls|Sant Genis De Palafolls
08390	Montgat|Virreina, La (Tiana)
08391	Tiana
08392	Sant Andreu De Llavaneres
08393	Caldes D'Estrac
08394	Sant Vicenç De Montalt
08395	Sant Pol De Mar
08396	Can Domenec (Tordera)|Sant Cebria De Vallalta
08397	Pineda De Mar
08398	Santa Susanna
08400	Granollers
08401	Granollers
08402	Granollers
08403	Granollers
08404	Granollers
08410	Valldoriolf (Vilanova Del Valles)|Vilanova Del Valles
08415	Can Barri (Bigues I Riells)|Can Carreras (Bigues I Riells)|Can Fabrera (Bigues I Riells)|Can Regasol (Bigues I Riells)|Can Traver (Bigues I Riells)|Castell-Montbui (Bigues I Riells)|Diamant Del Valles (Bigues I Riells)|Font Del Bou (Bigues I Riells)|Font Granada (Bigues I Riells)|Manantials, Els (Bigues I Riells)|Pineda, La (Bigues I Riells)|Rieral De Bigues (Bigues I Riells)|Saulons D'En Deu, Els (Bigues I Riells)|Turo, El (Bigues I Riells)
08416	Riells Del Fai (Bigues I Riells)
08420	Barriada Nova|Can Diviu|Can Duran|Canovelles
08430	La Roca Del Valles|Santa Agnes De Malanyanes (La Roca)|Valldoriolf (La Roca Del Valles)
08440	Cardedeu
08445	Canoves|Samalus
08450	Collsabadell|Llinars Del Valles|Sanata (Llinars Del Valles)
08455	Vilalba Sasserra
08458	Sant Pere De Vilamajor
08459	Sant Antoni De Vilamajor
08460	Santa Maria De Palautordera
08461	Sant Esteve De Palautordera
08469	Montseny|Rieral, El (Fogars De Montclus)
08470	Sant Celoni
08471	Vallgorguina
08472	Campins
08474	Gualba
08476	Batlloria, La (Sant Celoni)
08479	Fogars De Montclus|La Costa Del Montseny|Mosqueroles
08480	Ametlla Del Valles, L'|El Pinar I El Portus
08490	Tordera
08495	Fogars De La Selva
08500	Vic
08503	Gurb|Sant Bartomeu Del Grau
08504	Font De'N Titus (Calldetenes)|Sant Julia De Vilatorta|Sant Sadurni D'Osormort
08505	Santa Eulalia De Riuprimer|Sentfores
08506	Calldetenes
08507	Santa Eugenia De Berga
08508	Gleva, La (Masies De Voltrega)|Masies De Voltrega, Les|Vinyoles D'Oris (Masies De Voltrega)
08509	Santa Cecilia De Voltrega
08510	Masies De Roda, Les|Roda De Ter
08511	Santa Maria De Corco|Tavertet
08512	Sant Hipolit De Voltrega
08513	Prats De Lluçanes
08514	Lluça
08515	Sant Marti D'Albars|Santa Creu De Jotglar
08516	Olost
08517	Sagas|Santa Maria De Merles
08518	Orista
08519	Folgueroles|Tavernoles|Vilanova De Sau
08520	Corro D'Amunt (Franqueses Del Valles, Les)|Corro D'Avall (Franqueses Del Valles, Les)|Llerona (Franqueses Del Valles, Les)|Marata (Franqueses Del Valles, Les)
08521	Bellavista (Franqueses Del Valles, Les)
08522	Malla
08529	Muntanyola
08530	La Garriga
08540	Centelles
08550	Hostalets De Balenya, Els (Balenya)
08551	Tona
08552	Taradell
08553	Seva
08554	Sant Miquel De Balenya (Seva)
08559	El Brull
08560	Manlleu
08569	Cantonigros|Pruit|Rupit|Sant Marti Sescorts
08570	Torello
08571	Sant Vicenç De Torello
08572	Sant Pere De Torello
08573	Oris
08580	Sant Quirze De Besora
08584	Santa Maria De Besora
08585	Montesquiu
08586	Sant Agusti De Lluçanes
08587	Alpens
08588	Sora
08589	Perafita|Sant Boi De Lluçanes|Sobremunt
08590	Figaro (Montmany)|Montmany- Figaro
08591	Aiguafreda
08592	Sant Marti De Centelles
08593	Tagamanent
08600	Berga|El Poligon De La Valldan
08604	Castell De L'Areny
08605	Montclar
08606	La Quar
08607	Sant Jaume De Frontanya
08610	Avia|Cal Rosal (Avia)
08611	Cal Rosal (Olvan)|Colonia Rosal, La (Berga)|Olvan
08612	Montmajor
08613	Vilada
08614	Espunyola, L'
08617	Capolat
08618	Castellar Del Riu
08619	Borreda
08620	Sant Vicenç Dels Horts
08629	Torrelles De Llobregat
08630	Abrera|Santa Maria De Vilalba
08635	Beguda Alta, La (S. Esteve Sesrovires)|Sant Esteve Sesrovires
08640	Olesa De Montserrat
08650	Cabrianes|Cornet|La Botjosa|Sallent
08660	Balsareny
08670	Navas
08671	Castelladral
08672	Ametlla De Merola, L'|Gaia
08673	Sant Joan De Montdarn (Viver I Serrateix)|Viver I Serrateix
08680	Ametlla De Casserres, L'|El Guixaro|Gironella
08690	Santa Coloma De Cervello
08691	Monistrol De Montserrat
08692	Puig-Reig
08693	Casserres
08694	Guardiola De Bergueda|Sant Julia De Cerdanyola
08695	Baga|Gisclareny
08696	Castellar De N'Hug|La Pobla De Lillet
08697	Saldes
08698	Cercs|Figols|La Nou De Bergueda|Sant Corneli|Sant Jordi De Cercs
08699	Vallcebre
08700	Igualada
08710	Santa Margarida De Montbui|Santa Margarida De Montbui A-Antiguo
08711	Odena
08712	Sant Jaume Sesoliveres Urb. (Igualada)|Sant Marti De Tous
08717	Argençola|Montmaneu
08718	Cabrera D'Anoia
08719	Castelloli|Jorba|Rubio|Santa Maria Cami (Veciana)
08720	El Moli D'En Rovira|Perepau|Salines, Les|Vilafranca Del Penedes
08729	Casetes, Les (Castellet I La Gornal)|Castellet I La Gornal|Clariana (Castellet I La Gornal)
08730	Santa Margarida I Els Monjos
08731	Sant Marti Sarroca
08732	Castellvi De La Marca|Gornal, La (Castellet I La Gornal)|Munia, La (Castellvi De La Marca)|Sant Marçal (Castellet I La Gornal)
08733	El Pla Del Penedes
08734	Arboçar, L' (Avinyonet Del Penedes)|Can Trabal (Olerdola)|Daltmar (Olerdola)|Moja (Olerdola)|Poligon Industrial El Clot De Moja (Olerdola)|Sant Miquel D'Olerdola (Olerdola)
08735	Vilobi Del Penedes
08736	Font-Rubi|Guardiola De Font-Rubi
08737	Torrelles De Foix
08738	Pontons
08739	Subirats
08740	Sant Andreu De La Barca
08750	Molins De Rei|Sant Bartomeu De La Quadra|Santa Creu D'Olorda|Vallpineda
08753	Fontpineda Urbanizacion (Palleja) (Urbanitzacio)
08754	El Papiol
08755	Castellbisbal
08756	La Palma De Cervello
08757	Corbera De Baix|Corbera De Llobregat|Safari (Urbanizacio)
08758	Can Roig (Cervello)|Cervello|Costa De La Perdiu (Cervello)|Inter-Club (Vallirana)|Puigmontmany (Cervello)
08759	Vallirana
08760	Martorell
08769	Castellvi De Rosanes
08770	Can Benet De La Prua|Can Catassus|Espiells|Monistrol D'Anoia|Sant Sadurni D'Anoia
08773	Mediona
08775	Torrelavit
08776	Sant Pere De Riudebitlles
08777	Sant Quinti De Mediona
08779	La Llacuna
08780	Palleja
08781	Hostalets De Pierola, Els
08782	Beguda Alta, La (Masquefa)
08783	Masquefa
08784	El Badorc|La Fortesa|Piera|Sant Jaume Sesoliveres
08785	Vallbona D'Anoia
08786	Capellades
08787	Can Bou (Orpi)|Carme|La Pobla De Claramunt|Orpi|Santa Maria De Miralles
08788	Vilanova Del Cami
08789	La Torre De Claramunt|Pinedes De L'Ermengol, Les|Vilanova D'Espoia
08790	Gelida|Sant Salvador
08791	Beguda Alta, La (S. Llorenç D'Hortons)|Beguda Baixa, La (S.Llorenç D'Hortons)|Sant Joan Samora (S.Llorenç D'Hortons)|Sant Llorenç D'Hortons
08792	Garrofa, La (Avinyonet Del Penedes)|La Granada|Santa Fe Del Penedes
08793	Avinyonet Del Penedes
08794	Cabanyes, Les
08795	Olesa De Bonesvalls
08796	Pacs Del Penedes
08797	Puigdalber
08798	Sant Cugat Sesgarrigues|Sant Sebastia Dels Gorgs (Avinyonet Del Penedes)
08799	Poligon Industrial De Sant Pere Molanta (Olerdola)|Sant Pere Molanta (Olerdola)
08800	Vilanova I La Geltru
08805	Sabadell
08810	Puigmolto|Sant Pere De Ribes
08811	Canyelles
08812	El Mas D'En Serra|Roquetes, Les (Sant Pere De Ribes)|Vilanoveta
08818	Olivella
08820	El Aeroport Del Prat|El Prat De Llobregat
08830	Sant Boi De Llobregat
08840	Viladecans
08849	Sant Climent De Llobregat
08850	Gava
08859	Begues
08860	Botigues De Sitges, Les (Sitges)|Castelldefels|Garraf Ii (Sitges) (Urbanitzacio)|Rat Penat (Sitges) (Urbanitzacio)
08870	Sitges
08871	Garraf (Sitges)
08872	Vallcarca (Sitges)
08880	Cubelles
08900	Hospitalet De Llobregat, L'
08901	Hospitalet De Llobregat, L'
08902	Hospitalet De Llobregat, L'
08903	Hospitalet De Llobregat, L'
08904	Hospitalet De Llobregat, L'
08905	Hospitalet De Llobregat, L'
08906	Hospitalet De Llobregat, L'
08907	Hospitalet De Llobregat, L'
08908	Hospitalet De Llobregat, L'
08910	Badalona
08911	Badalona
08912	Badalona
08913	Badalona
08914	Badalona
08915	Badalona
08916	Badalona|Mas Ram Urb. (Tiana)
08917	Badalona
08918	Badalona
08920	Santa Coloma De Gramenet
08921	Santa Coloma De Gramenet
08922	Santa Coloma De Gramenet
08923	Santa Coloma De Gramenet
08924	Santa Coloma De Gramenet
08930	Sant Adria De Besos
08940	Cornella De Llobregat
08950	Esplugues De Llobregat
08960	Sant Just Desvern
08970	Sant Joan Despi
08980	Sant Feliu De Llobregat
09001	Burgos
09002	Burgos
09003	Burgos
09004	Burgos
09005	Burgos
09006	Burgos
09007	Burgos
09070	Burgos
09071	Burgos
09080	Burgos
09100	Melgar De Fernamental
09107	Arenillas De Riopisuerga|Castrillo Matajudios|Itero Del Castillo|Palacios De Riopisuerga
09108	Castrillo De Rio Pisuerga|Hinojal De Rio Pisuerga|Padilla De Arriba|Rezmondo|Santa Maria Ananuñez|Tagarrosa|Valtierra De Riopisuerga|Zarzosa De Rio Pisuerga
09109	Castrillo De Murcia|Padilla De Abajo|Villasandino|Villasilos|Villaveta
09110	Barrio San Anton|Castrojeriz
09118	Villaquiran De Los Infantes
09119	Hinestrosa|Los Balbases|Pedrosa Del Principe|Valbonilla|Vallunquera|Villaquiran De La Puebla
09120	Villadiego
09121	San Llorente De La Vega
09123	Citores Del Paramo|Olmillos De Sasamon|Sasamon|Villandiego|Villasidro|Yudego
09124	Barrios De Villadiego|Barruelo De Villadiego|Congosto|Fuencaliente De Puerta|Fuenteodra|Humada|Ordejon De Abajo|Ordejon De Arriba|Palazuelos De Villadiego|Rebolledo De Traspeña|Rioparaiso|San Martin De Humada|Sandoval De La Reina|Tapia|Villamartin De Villadiego|Villavedon|Villusto
09125	Boada De Villadiego|Fuenteurbel|La Nuez De Arriba|La Piedra|Montorio|Quintana Del Pino|Quintanilla Pedro Abarca|Rad, La (Basconcillos Del Tozo)|San Pantaleon Del Paramo|Santa Cruz Del Tozo|Tablada De Villadiego|Talamillo Del Tozo|Trashaedo Del Tozo|Urbel Del Castillo|Villahernando|Villalvilla De Villadiego|Villanueva De Puerta|Villaute
09126	Barrio Panizares|Basconcillos Del Tozo|Hoyos Del Tozo|Pradanos Del Tozo|San Mames De Abar
09127	Arcellares Del Tozo|Barrio Lucio|Corralejo|Escuderos De Valdelucio|Fuencaliente De Lucio|Llanillo De Valdelucio|Mundilla|Paul De Valdelucio|Pedrosa De Arcellares|Quintanas De Valdelucio|Renedo De La Escalera|Renedo De Valdelucio|Riba De Valdelucio|Solanas De Valdelucio|Villaescobedo De Valdelucio
09128	Grijalba|Mahallos|Sordillos|Villahizan De Treviño|Villamayor De Treviño|Villamoron|Villanoño|Villanueva De Odra|Villegas
09129	Acedillo|Brulles|Bustillo Del Paramo|Coculina|Fuencivil|Hormazuela|Melgosa De Villadiego|Quintanilla De La Presa|Villalibado
09130	Rabe De Las Calzadas|Tardajos
09131	Arroyal De Vivar|Avellanosa Del Paramo|Las Quintanillas|Lodoso|Marmellar De Abajo|Marmellar De Arriba|Paramo Del Arroyo|Pedrosa De Rio Urbel|San Pedro Samuel|Santa Maria Tajadura|Villarmentero
09133	Arenillas De Villadiego|Barrio Solano|Borcos|Castromorca|Cañizar De Argaño De Los Ajos|La Parte|Las Hormazas|Manciles|Olmos De La Picaza|Pedrosa Del Paramo|Susinos Del Paramo|Tobar|Villorejo
09135	Barrio De San Feciles|Cañizar De Amaya|Guadilla De Villamar|Quintanilla De Riofresno|Sotovellanos|Sotresgudo
09136	Amaya|Cuevas De Amaya|Peones De Amaya|Puentes De Amaya|Salazar De Amaya
09140	Celadilla Sotobrin|Quintanaortuño|Quintanilla Vivar|Sotopalacios|Vivar Del Cid
09141	Abajas De Bureba|Castrillo De Rucios|Cernegula|Gredilla La Polera|Hontomin|La Cabañuela|Lermilla|Mata|Quintanarrio|Quintanarruz|Quintanilla Sobresierra|Robredo Sobresierra|San Martin De Ubierna|Santa Maria De Ubierna|Ubierna|Villalvilla De Sobresierra
09142	Gredilla De Sedano|Masa|Moradillo De Sedano|Mozuelos|Nidaguila|Nocedo|Quintanaloma|Sedano|Terradillos De Sedano
09143	Bañuelos De Rudron|Covanera|Moradillo Del Castillo|San Felices|Santa Coloma Del Rudron|Tablada Del Rudron|Tubilla Del Agua
09144	Ayoluengo|Lorilla|San Andres De Montearados|Sargentes De La Lora|Valdeajos
09145	Baños De Valdelateja|Escalada|Orbaneja Del Castillo|Quintanilla Escalada|Valdelateja
09146	Ailanes De Zamanzas|Barrio La Cuesta|Bascones De Zamanzas|Cortiguera|Gallejones De Zamanzas|Pesquera De Ebro|Quintanilla Colina|Robredo De Zamanzas|Tubilleja|Tudanca|Turzo|Venta De Orbaneja|Villanueva Rampalay
09150	Espinosilla De San Bartolome|Huermeces|Las Celadas|Las Rebolledas|Los Tremellos|Mansilla|Miñon De Santibañez|Ros|Ruyales Del Paramo|Santibañez Zarzaguda|Zumel
09159	La Nuez De Abajo
09191	Hurones|Mijaradas (Granja)|Riocerezo|Villayerno Morquillas
09192	Cardeñuela Riopico|Cotar|Orbaneja Rio Pico|Quintanilla Rio Pico|Villalbal
09193	Carcedo De Burgos|Cardeñajimeno|Castrillo Del Val|Cortes|San Pedro De Cardeña
09194	Barrio Quintanilla|Barrio San Juan|Barrio Sopeña|Cardeñadijo|Los Ausines|Modubar De La Cuesta|Modubar De San Cibrian|Revilla Del Campo
09195	Arcos De La Llana|Renuncio|Villacienzo|Villagonzalo Pedernales|Villariezo
09196	Quintanilleja|Villamiel De Muño
09197	Quintanadueñas|Sotragero|Villanueva De Rio Ubierna|Villarmero
09198	Cabañas De Juarros|Cueva De Juarros|Cuzcurrita De Juarros|Espinosa De Juarros|Ibeas De Juarros|Los Tomillares|Matalindo De Juarros|Mozoncillo De Juarros|Salguero De Juarros|San Adrian De Juarros|San Millan De Juarros|Santa Cruz De Juarros
09199	Ages|Alarcia|Arlanzon|Atapuerca|Barrios De Colina|Castañares|Galarde|Hiniestra|Olmos De Atapuerca|Pantano De Arlanzon|Pineda De La Sierra|Rubena|San Juan De Ortega|San Medel|Santovenia De Oca|Urrez|Villamorico|Villasur De Herreros|Zalduendo
09200	Azucarera Leopoldo|Miranda De Ebro
09210	Cormenzana|Leciñana De Tobalina|Quintana Martin Galindez
09211	Cubilla De La Sierra|Cuezva|Frias|La Aldea Del Portillo De Busto|La Molina Portillo De Busto|Montejo De Cebas|Montejo De San Miguel|Partido De La Sierra En Tobali|Quintanaseca|Ranera|Tobera|Valderrama|Zangandez
09212	Barcina Del Barco|Gabanes|Garoña|Hedeso|Herran|La Prada|Las Viadas|Mijarelengua|Orbañanos|Pajares|Pangusion|Parayuelo|Plagaro|Promediano|Ranedo|Revilla De Herran|Rufrancos|San Martin De Don|Santa Coloma|Santa Maria De Garoña|Tobalinilla|Villaescusa De Tobalina
09213	Bascuñuelos|Cillaperlata|Lomana|Lozares De Tobalina|Palazuelos De Cuestaurria|Quintanamaria|Santocildes|Virues
09214	Portilla|Villanueva Soportilla
09215	Arana|Armentia|Arrieta|Ascarza|Añastro|Busto De Treviño|Cucho|Doroño|Franco|Golernio|Meana|Muergas|San Martin Del Zar|Treviño|Villanueva De Tobera
09216	Aguillo|Ajarte|Albaina|Fuidio|Laño|Marauri|Mesanza|Ogueta|Pariza|Samiano|Saraso|Saseta
09217	Araico|Argote|Dordoniz|Grandival|Imiruri|Moscador De Treviño|Ozana|Pedruzo|San Martin De Galvarin|San Vicentejo|Torre|Uzquiano
09218	Arce|Bayas|Taravero
09219	Altable|Ameyugo|Ayuelas|Bardauri|Bozoo|El Espino|Encio|Guinicio|Ircio|La Nave|Los Corrales|Montañana|Moriana|Oron|San Miguel Del Monte|Santa Gadea Del Cid|Santa Maria Ribarredonda|Suzana|Valluercanes|Villanueva De Teba
09220	Pampliega
09221	Herrera
09226	Barrio De Muño|Belbimbre|Celada Del Camino|Palazuelos De Muño|Torrepadierne|Villanueva De Las Carretas|Villaverde-Mogina|Villazopeque
09227	Castellanos De Castro|Hontanas|Iglesias|Tamaron|Villaldemiro
09228	Ciadoncha|Mahamud|Mazuela|Olmillos De Muño|Presencio|Revenga
09230	Buniel|Estepar|Frandovinez|Granja Altube|Hormaza|Hornillos Del Camino|Medinilla De La Dehesa|Quintanilla De Las Carretas|San Mames De Burgos|Villagutierrez|Vilviestre De Muño
09233	Presillas
09239	Albillos|Arenillas De Muño|Arroyo De Muño|Cavia|Cayuela|Mazuelo De Muño|Pedrosa De Muño|Quintanilla Somuño|Villanueva Matamala|Villavieja De Muño
09240	Briviesca
09244	Busto De Bureba|Calzada De Bureba|Fuentebureba|Marcillo|Quintanaelez|Quintanilla Cabe Soto|Soto De Bureba
09245	Berzosa De Bureba|Cameno|Grisaleña|Vallarta De Bureba|Zuñeda
09246	Barrios De Bureba|Cornudilla|Hermosilla|Llano De Bureba|Movilla|Piernigas|Pino De Bureba|Poza De La Sal|Quintanabureba|Quintanaurria|Quintanilla Cabe Rojas|Rojas|Terrazos De Bureba
09247	Buezo|Caborredondo|Galbarros|Revillalcon|Salinillas De Bureba|San Pedro De La Hoz
09248	Bañuelos De Bureba|Carrias|Castil De Carrias|Pradanos De Bureba|Quintanaloranco|Reinoso|Valdazo
09249	Aguilar De Bureba|Barrio De Diaz Ruiz|La Parte De Bureba|La Vid De Bureba|Las Vesgas|Navas De Bureba|Quintanillabon|Solduengo|Vileña
09250	Belorado
09251	Cubo De Bureba
09252	Miraveche|Silanes
09253	Cascajares De Bureba
09257	Villafranca Montes De Oca
09258	Alcocero De Mola|Castil De Peones|Cueva Cardiel|Espinosa Del Camino|Mozoncillo De Oca|Ocon De Villafranca|Puras De Villafranca|San Miguel De Pedroso|Tosantos|Villalbos|Villalmondar|Villalomez|Villambistia|Villanasur Rio De Oca
09259	Bascuñana|Castildelgado|Fresneña|Ibrillos|Quintanilla Del Monte En Rioja|Redecilla Del Camino|San Cristobal Del Monte|San Pedro Del Monte|Sotillo De Rioja|Villamayor Del Rio|Viloria De Rioja
09260	Pradoluengo
09267	Avellanosa De Rioja|Eterna|Fresneda De La Sierra Tiron
09268	Espinosa Del Monte|Ezquerra|Garganchon|Rabanos|San Clemente Del Valle|San Vicente Del Valle|Santa Cruz Del Valle Urbion|Santa Olalla Del Valle|Valmala|Villagalijo
09269	Villamudria
09270	Cerezo De Rio Tiron|Redecilla Del Campo
09271	Quintanilla San Garcia
09272	Fresno De Rio Tiron|Loranquillo
09280	Obarenes|Pancorbo
09285	La Azuela
09290	Fresno De Rodilla|Quintanapalla
09292	Arraya De Oca|Cerraton De Juaros|Monasterio De Rodilla|Piedrahita De Juarros|Quintanavides|Quintanilla Del Monte Juarros|Revillagodos|San Otero|Santa Maria Del Invierno|Santa Olalla De Bureba|Turrientes|Villaescusa La Solana|Villaescusa La Sombria
09293	Bugedo|Bugedo (Monasterio)|Valverde De Miranda
09294	Burgueta|La Puebla De Arganzon|Ladrera|Ocilla|Pangua|San Esteban De Treviño|Villanueva De La Oca|Zurbitu
09300	Roa
09310	Torresandino|Villatuelda|Villovela De Esgueva
09311	La Horra|Olmedillo De Roa
09312	Tortoles De Esgueva
09313	Anguix
09314	Boada De Roa|Guzman|Pedrosa De Duero|Quintanamanvirgo|Villaescusa De Roa
09315	Fuentecen|Fuentemolinos
09316	Berlangas De Roa|El Carrascal|Hoyales De Roa
09317	Mambrilla De Castrejon|San Martin De Rubiales|Valcabado De Roa
09318	Fuentelisendo|Nava De Roa|Valdezate
09319	La Cueva De Roa
09320	Cogollos|Madrigal Del Monte|Tornadijo|Valdorros
09338	Valles De Palenzuela
09339	Cristo De Villahizan (Finca)|Villafuertes|Villamayor De Los Montes|Villangomez|Villaverde Del Monte|Zael
09340	Lerma
09341	Ruyales Del Agua|Santa Cecilia|Tordomar
09342	Hontoria De Rio Franco|Peral De Arlanza|Santa Maria Del Campo
09343	Villahoz
09344	Royuela De Riofranco|Villafruela
09345	Avellanosa De Muño|Iglesiarrubia|La Veguecilla|Paules Del Agua|Pinedillo|Torrecitores Del Enebral|Torrepadre
09346	Covarrubias|Mecerreyes
09347	Bascones Del Agua|Puentedura|Quintanilla Del Agua Y Torduel|Retuerta|Santillan|Tordueles|Ura
09348	Castrillo De Solarana|Castroceniza|Cebrecos|Nebreda|Quintanilla Del Coco|Revilla Cabriada|Solarana|Villoviado
09349	Cilleruelo De Abajo|Cilleruelo De Arriba|Fontioso|Guimara, De (Granja)|Pineda De Trasmonte|Quintanilla De La Mata|Rabe De Los Escuderos
09350	Bahabon De Esgueva|Cabañes De Esgueva|Oquillas|Santibañez De Esgueva
09351	Hontoria De La Cantera|San Quirce
09352	Cubillo Del Campo
09353	Santa Maria Mercadillo
09354	Pinilla Trasmonte
09360	Venta De Guimara
09370	Gumiel De Izan|La Aguilera|Quintana Del Pidio
09390	Madrigalejo Del Monte|Montuenga|Santa Ines|Torrecilla Del Monte|Villalmanzo
09391	Castrillo De La Vega
09400	Aranda De Duero
09410	Arandilla|Coruña Del Conde|Peñaranda De Duero|Valverde
09430	Huerta De Rey
09440	Pinillos De Esgueva
09441	Sotillo De La Ribera
09442	Terradillos De Esgueva
09443	Gumiel Del Mercado|Ventosilla|Villalba De Duero
09450	Baños De Valdearados|Hontoria De Valdearados|Sinovas|Villanueva De Gumiel
09451	Arauzo De Miel|Arauzo De Salce|Arauzo De Torre|Caleruega|Doña Santos
09453	Tubilla Del Lago|Valdeande|Villalvilla De Gumiel
09454	Hinojar Del Rey|Peñalba De Castro|Quemada|Quintanarraya
09460	Milagros
09461	Fuentenebro
09462	Adrada De Haza|Hontangas|La Sequera De Haza|Moradillo De Roa|Pardilla
09463	Haza
09471	Fuentelcesped|Fuentespina|La Vid|Santa Cruz De La Salceda
09490	Brazacorta|Casanova|San Juan Del Monte|Zazuar
09491	Fresnillo De Las Dueñas|Guma|Vadocondes|Zuzones
09493	Campillo De Aranda|Torregalindo
09500	Medina De Pomar
09510	Baro|Calzada De Losa|Castresana|Lastras De La Torre|Quincoces De Yuso|Relloso|San Miguel De Relloso|Villabasil|Villaventin
09511	Aostri|Barriga De Losa|Berberana|Fresno De Losa|Hozalla|Lastras De Teza|Llorengoz|Mambliga De Losa|Mijala|Murita|San Martin De Losa|Teza De Losa|Villacian|Villalambrus|Villalba De Losa|Villaño|Villota|Zaballa De Losa
09512	Castricciones|Criales De Losa|Gobantes|Momediano|Navangos|Oteo De Losa|Paresotas|Perex De Losa|Quintanilla De La Ojada|Rio De Losa|Robredo De Losa|San Llorente De Losa|San Pantaleon De Losa|Torres|Villaluenga De Losa|Villamor|Villate|Villatomil
09513	El Vado|Medianabella|Miñon|Pomar|Quintanilla De Los Adrianos|Santa Cruz De Andino|Villanueva De La Lastra|Villarias
09514	Angosto|Barcena De Pienza|Barcenillas Del Rivero|Boveda De La Ribera|Castrobarto|Colina De Losa|Cubillo De Losa|El Ribero|Junta De Traslaloma|La Cerca|La Riba|Las Eras|Lastras De Las Heras|Quintanamace|Quintanilla De Pienza|Recuenco|Revilla De Pienza|Rosales|Rosio|Salinas Del Rosio|Santurde|Tabliega De Losa|Villalacre|Villamezan|Villataras
09515	Ael|Aforados De Moneo|Almendres|Baillo|Bustillo De Villarcayo|Casares|Cebolleros|Mijangos|Moneo|Nofuentes|Paralacuesta|Pradolamata|Quintanalacuesta|Quintanillas, Las (Merindades)|San Cristobal De Almendres|Urria|Valdelacuesta|Villacomparada|Villamagrin|Villapanillo|Villaran|Villavedeo
09530	Oña
09540	Tartales De Cilla|Trespaderne
09549	Arroyuelo|Cadiñanos|Extramiana|Hierro|La Orden|Lechedo|Pedrosa De Tobalina|Quintana Entrepeñas|Quintanilla Montecabezas|Santotis|Valujera
09550	Villarcayo
09551	Cubillo De Butron|Dobro|Haedo De Butron|Porquera De Butron
09553	Barriosuso|Bocos|Cespedes|Fresnedo|Villacomparada De Rueda
09554	Andino|Barruelo De Villarcayo|Bisjueces|Horna|La Aldea|Villalain
09555	Campo|La Quintana De Rueda|Mozares|Torme|Villanueva La Blanca
09556	Casillas|Ciguenza|Otedo|Quintanilla Sociguenza|Salazar|Villacanes
09557	Brizuela|Cogullos|Escanduso|Escaño|Haedo De Linares|Leva|Linares|Nela|Puentedey|Quintanilla Valdevodres|Sobrepeña|Tubilla|Villaves
09558	Arges|Cidad De Ebro|Cueva De Manzanedo|Hocina|Incinillas|Manzanedillo|Manzanedo|Peñalba De Manzanedo|Rioseco|San Cristobal De Rioseco|San Martin Del Rojo|Vallejo De Manzanedo|Villasopliz
09559	Arroyo De Valdivielso|Cereceda|Condado De Valdivielso|El Almiñe|Escobados De Abajo|Escobados De Arriba|Hoz De Valdivielso|Huidobro|Panizares|Pesadas|Poblacion De Valdivielso|Puentearenas|Quecedo De Valdivielso|Quintana De Valdivielso|Santa Olalla De Valdivielso|Tartales De Los Montes|Toba De Valdivielso|Valdenoceda|Vallhermosa De Valdivielso|Villaescusa De Butron|Villalta
09560	Espinosa De Los Monteros
09566	Barcenas De Espinosa|Las Machorras|Las Nieves|Rio De La Sia|Rio De Lunada|Rio De Rioseco|Rio De Trueba
09567	Barcenillas De Cerezo|Hornillalatorre|Para|Santa Olalla
09568	Bedon|Butrera|Cornejo De Sotoscueva|Cueva De Sotoscueva|El Rebollar|Entrambosrios|Hornillalastra|Hornillayuso|La Parte De Sotoscueva|Pereda|Quintanilla Del Rebollar|Quintanilla Sotoscueva|Quisicedo Sotoscueva|Redondo|Vallejo De Sotoscueva|Villabascones De Sotoscueva|Villamartin De Sotoscueva
09569	Aguera De Montija|Baranda De Montija|Bercedo|Cuestahedo|Edesa|Gayangos|Loma De Montija|Montecillo|Montecillo De Montija|Noceco|Quintana De Los Prados|Quintanahedo|Quintanilla Sopeña|San Pelayo De Montija|Villalazara|Villasante
09570	Arija
09571	Alfoz De Santa Gadea|Arnedo De Hoz|Herbosa|Higon|Montejo De Bricia|Quintanilla De San Roman|Quintanilla De Santa Gadea|San Vicente De Villamezan|Villamediana De San Roman
09572	Argomedo|Arreba|Barrio De Bricia|Bezana|Bricia|Cabañas De Virtus|Campino De Bricia|Castrillo De Bezana|Cilleruelo De Bezana|Cilleruelo De Bricia|Consortes|Crespos|Cubillos Del Rojo|Hoz De Arreba|Landraves|Montoto|Munilla De Hoz De Arreba|Paradores De Bricia|Poblacion De Arreba|Pradilla De Hoz De Arreba|Quintanantello|Riaño|San Cibrian|San Miguel De Cornezuelo|Soncillo|Torres De Abajo|Villabascones De Bezana|Villanueva De Carrales|Virtus
09573	Busnela|Haedo De Las Pueblas|Robredo De Las Pueblas
09574	Cidad De Valdeporres|Dosante|Pedrosa De Valdeporres|Quintanabaldo|Rozas De Valdeporres|San Martin De Las Ollas|San Martin De Porres|Santelices
09580	Villasana De Mena
09585	Antuñano|Arza|Barcenas De Bortedo|Barcenas De Campillo|Bascones De Bortedo|Bortedo|Cerezo|El Berron|Entrambasaguas|Gijano|Haedillo|La Cayuela|La Presilla|La Vega De Nava|Las Arenas|Las Campas|Las Cuevas|Maltrana|Maltranilla|Menamayor|Nocedal (Chalet)|Nocedal (Fabrica)|Opio|Orrantia|Pantano De Ordunte|Rio De Mena|San Pelayo (De Mena)|Santa Cruz De Mena|Santecilla|Ungo
09586	Abadia La Mena|Cereceda De Mena|Nava De Ordunte|Ro
09587	Arceo|Barrasa|Burceña|Campillo De Mena|Caniego|Cantonad|Concejero De Mena|Hornes|Hoz De Mena|Irus De Mena|La Llosa|Laya|Leciñana|Ordejon De Ordunte|Palacio De Hornes|Paradores De Mena|Partearroyo|Ribota De Ordunte|Santa Maria Egipciaca|Sobreviñas|Taranco|Urbaneja|Villanueva De Mena|Vivanco
09588	Angostina|Angulo|Araduenga|Artieta|Barcenas De Cirion|Berrandulez|Carrasquedo|Ciella|Cirion|Cozuela|Encima De Angulo|Haedo De Angulo|La Llana|Las Fuentes|Llano De Mena|Lorcio|Luengas|Martijana|Medianas De Mena|Mercadillo|Montiano|Oseguera|Roza De Cirion|San Juan De Mena|Santa Maria Del Llano De Tudel|Santa Olaja|Santiago De Tudela|Valluerca|Ventades|Viergol
09589	Anzo|Barriolaza|Barruso De Mena|Cadagua|Casadilla|Cilieza|Covides|Cristantes|El Vigo|La Mata|Las Casetas|Lezana De Mena|Ovilla|Palacio De Siones|Quintanilla De Siones|Santiuste (Campillo)|Siones|Sopeñano|Vallejo De Mena|Vallejuelo|Villasuso De Mena
09591	Celada De La Torre|Cobos De La Molina|Melgosa De Burgos|Molina De Ubierna|Peñahorada|Rioseras|Robredo Temiño|Temiño|Tobes|Villaverde Peñahorada
09592	Arconada|Carcedo De Bureba|Castil De Lences|Lences|Rublacedo De Abajo|Rublacedo De Arriba|Valdearnedo
09593	Aguas Candidas|Barcina De Los Montes|Bentretea|Cantabrana|Castellanos De Bureba|Herrera De Las Caderechas|Hozabejas|Huespeda De Caderechas|Madrid De Caderechas|Ojeda De Caderechas|Padrones De Bureba|Penches|Quintanaopio|Quintanilla Del Rio|Rio Quintanilla|Rucandio|Salas De Bureba|Terminon|Villanueva De Los Montes
09594	Valmayor De Cuesta Urria
09600	Salas De Los Infantes
09610	Briongos De Cervera|Ciruelos De Cervera|Espinosa De Cervera|Hinojar De Cervera|Hortezuelos|Peñacoba|Santo Domingo De Silos
09611	Carazo|Hacinas|Villanueva De Carazo
09612	Cabezon De La Sierra|Gete|La Gallega|Mamolar|Pinilla De Los Barruecos
09613	Barbadillo Del Mercado|Castrovido|Contreras|La Revilla Y Ahedo|Monasterio De La Sierra|Piedrahita De Muño|Pinilla De Los Moros|Terrazas|Vizcainos
09614	Barbadillo Del Pez|Bezares|Huerta De Abajo|Huerta De Arriba|Quintanilla Urrilla|Tolbaños De Abajo|Tolbaños De Arriba|Vallejimeno
09615	Arroyo De Salas|Barbadillo De Herreros|Hoyuelos De La Sierra|Monterrubio De La Demanda|Riocabado De La Sierra
09616	Tejada
09617	Santibañez Del Val
09618	Barriosuso Del Val
09619	Navas Del Pinar
09620	Cojobar|Humienta|Modubar De La Emparedada|Olmos Albos|Palacio De Saldañuela|Revillarruz|Saldaña De Burgos|Saldañuela|Sarracin|Ventas De Saldaña
09640	Cascajares De La Sierra|Hortiguela|Iglesiapinta|Jaramillo De La Fuente|Jaramillo Quemado|La Aceña De Lara|Mambrillas De Lara|Paules De Lara|Quintanilla Cabrera|Rupelo|San Millan De Lara|San Pedro De Arlanza|Tañabueyes|Vega De Lara|Villoruebo
09641	Cuevas De San Clemente
09642	Cubillejo De Lara|Cubillo Del Cesar|Quintanilla De Las Viñas
09645	Torrelara
09646	Mazueco De Lara
09647	Quintanalara
09649	Palazuelos De La Sierra|Tinieblas De La Sierra|Villamiel De La Sierra
09650	Campolara|Villaespasa
09651	Lara De Los Infantes
09652	Villanueva De Argaño
09653	Isar
09654	Palacios De Benaver
09660	Aldea Del Pinar|Hontoria Del Pinar|Rabanera Del Pinar
09670	Quintanar De La Sierra
09679	Neila
09680	Palacios De La Sierra
09690	Vilviestre Del Pinar
09691	Castrillo De La Reina|Moncalvillo
09692	Canicosa De La Sierra
09693	Regumiel De La Sierra
10001	Caceres
10002	Caceres
10003	Caceres
10004	Caceres
10005	Caceres
10070	Caceres
10071	Caceres
10080	Caceres
10100	Miajadas
10109	Alonso De Ojeda|Casar De Miajadas
10110	Madrigalejo
10120	Logrosan
10126	Solana De Cabañas
10129	Berzocana
10130	Zorita
10131	Valdemorales
10132	Almoharin
10133	Escurial
10134	Campo Lugar|Pizarro
10135	Alcollarin
10136	Cañamero
10137	Alia|La Calera
10140	Guadalupe
10150	Centro Militar Santa Ana
10160	Alcuescar
10161	Arroyomolinos
10162	Casas De Don Antonio
10163	Aldea Del Cano
10164	Valdesalor
10170	Montanchez
10180	Valdefuentes
10181	Sierra De Fuentes
10182	Torreorgaz
10183	Torrequemada
10184	Torremocha
10185	Benquerencia
10186	Torre De Santa Maria
10187	Albala
10188	Botija
10189	Salvatierra De Santiago|Santa Ana|Zarza De Montanchez
10190	Casar De Caceres|La Perala
10191	Santiago Del Campo
10192	Hinojal
10193	Talavan
10194	Monroy
10195	Aldea Moret|Caceres|Nacional 630, Del Km. 214 Al 216 (Carretera)
10198	Santa Marta De Magasca
10199	Rincon De Ballesteros
10200	Trujillo
10210	Madroñera
10220	Pago De San Clemente
10230	Herguijuela
10240	Conquista De La Sierra
10250	Garciaz
10251	Aldeacentenera
10252	Torrecilla De La Tiesa
10260	Santa Cruz De La Sierra
10261	Puerto De Santa Cruz
10262	Abertura
10263	Villamesias
10269	Robledillo De Trujillo
10270	La Cumbre
10271	Plasenzuela
10272	Ruanes
10280	Ibahernando
10290	Huertas De Animas
10291	Huertas De La Magdalena|La Aldea Del Obispo
10292	Belen
10300	Navalmoral De La Mata
10310	Talayuela
10317	Vegas De Mesillas
10318	Barquilla De Pinares|Huertas De Miramontes|La Barquilla|Pueblonuevo De Miramontes|Santa Maria De Las Lomas
10319	El Centenillo|Tietar
10320	Bohonal De Ibor
10328	Fresnedoso De Ibor
10329	Campillo De Deleitosa|Mesas De Ibor|Valdecañas De Tajo|Valdemoreno
10330	Villar Del Pedroso
10331	Carrascalejo|Navatrasierra
10332	Valdelacasa De Tajo
10333	Garvin
10334	Peraleda De San Roman
10335	Peraleda De La Mata
10340	Castañar De Ibor
10341	Navalvillar De Ibor
10350	Almaraz
10359	Higuera|Romangordo
10360	Casas De Miravete
10370	Deleitosa
10371	Robledollano
10372	Retamosa
10373	Cabañas Del Castillo|Roturas
10374	Navezuelas
10380	Jaraicejo
10390	Saucedilla
10391	Rosalejo
10392	Berrocalejo|El Gordo
10393	Valdehuncar
10394	Belvis De Monroy|Casas De Belvis|Millanes
10396	Central Nuclear De Almaraz
10400	Jaraiz De La Vera
10410	Arroyomolinos De La Vera
10411	Pasaron De La Vera
10412	Garganta La Olla
10413	Torremenga
10414	Collado
10420	Tejeda
10430	Cuacos De Yuste
10440	Aldeanueva De La Vera
10450	Jarandilla
10459	Guijo De Santa Barbara
10460	Losar De La Vera
10470	Villanueva De La Vera
10480	Madrigal De La Vera
10490	Valverde De La Vera
10491	Talaveruela
10492	Viandar De La Vera
10493	Robledillo De La Vera
10500	Valencia De Alcantara
10510	Santiago De Alcantara
10511	Carbajo
10512	Herrera De Alcantara
10513	Cedillo
10514	El Pino|Las Huertas De Cansa
10515	Aceña La Borrega|Jola
10516	La Fontañera
10519	Las Lanchuelas
10520	Casatejada
10521	Toril
10528	Serrejon
10529	Majadas
10530	Serradilla
10540	Mirabel
10550	Aliseda
10560	Herreruela
10570	Salorino
10580	Membrio
10590	Monfrague
10591	La Bazagona|La Herguijuela|Salto De Torrejon
10592	Casas De Millan
10600	Plasencia
10610	Cabezuela Del Valle
10611	Tornavacas
10612	Jerte
10613	Navaconcejo
10614	Valdastillas
10615	Piornal
10616	Cabrero|Casas Del Castañar
10617	El Torno|Rebollar
10620	Caminomorisco
10623	Arrolobos|Vegas De Coria
10624	Las Mestas|Riomalo De Abajo
10625	Cabezo|Ladrillar|Riomalo De Arriba
10626	Nuñomoral
10627	Cerezal|El Gasco|Fragosa|Martilandran
10628	Asegur|Carabusino|Casares De Las Hurdes|Heras|Huetre|Robledo (Casares De Las Hurdes)
10629	Cambron|Cambroncino|Huerta|Rubiaco
10630	Pedro Muñoz|Pinofranqueado
10638	Aldehuela|Castillo|Erias|Horcajo|Mesegal|Muela
10639	Ovejuela|Sauceda
10640	Casar De Palomero
10649	Azabal|La Pesga|Rivera Oveja
10650	Ahigal
10660	Palomero
10661	El Bronco|Santa Cruz De Paniagua
10662	Marchagaz
10663	Cerezo
10664	Mohedas De Granadilla
10665	Guijo De Granadilla
10666	Aceituna|Santibañez El Bajo
10667	Oliva De Plasencia
10670	Carcaboso
10671	Aldehuela De Jerte|Pradochano|Valderrosas
10672	Valdeobispo
10680	Malpartida De Plasencia
10690	Alagon Del Rio|El Rincon|San Gil
10691	Galisteo|Sartalejo
10692	El Batan
10693	Riolobos
10694	Torrejon El Rubio
10695	Villarreal De San Carlos
10696	Barrado|Garguera
10697	Haza De La Concepcion|Valdeiñigos
10700	Hervas
10710	Zarza De Granadilla
10711	La Granja
10712	Pantano De Gabriel Y Galan
10720	Villar De Plasencia
10728	Jarilla
10729	Cabezabellosa
10730	Casas Del Monte
10739	Segura De Toro
10740	Aldeanueva Del Camino
10748	Abadia
10749	Gargantilla
10750	Baños De Montemayor
10759	La Garganta
10800	Coria
10810	Montehermoso
10811	Morcillo|Puebla De Argeme|Rincon Del Obispo|Valrio
10812	Villanueva De La Sierra
10813	Pozuelo De Zarzon
10814	Villa Del Campo
10815	Guijo De Coria
10816	Guijo De Galisteo
10817	Calzadilla
10818	Casas De Don Gomez|Casillas De Coria
10820	Cañaveral
10828	Portezuelo
10829	Grimaldo|Holguera|Pajares De La Rivera|Pedroso De Acim
10830	Torrejoncillo
10839	Valdencin
10840	Moraleja
10848	Vegaviana
10849	Huelaga|La Moheda De Gata
10850	Hoyos
10857	Acebo
10858	Villasbuenas De Gata
10859	Santibañez El Alto
10860	Gata
10864	Torre De Don Miguel
10865	Cadalso
10866	Descargamaria
10867	Robledillo De Gata
10868	Hernan-Perez
10869	Torrecilla De Los Angeles
10870	Ceclavin
10879	Acehuche
10880	Zarza La Mayor
10881	Cachorrilla
10882	Pescueza
10883	Portaje
10890	Valverde Del Fresno
10891	Eljas
10892	San Martin De Trevejo
10893	Villamiel
10894	Trevejo
10895	Cilleros
10896	Perales Del Puerto
10900	Arroyo De La Luz
10910	Malpartida De Caceres
10930	Navas Del Madroño
10940	Garrovillas De Alconetar
10950	Brozas
10960	Villa Del Rey
10970	Mata De Alcantara
10980	Alcantara
10990	Estorninos
10991	Piedras Albas
11001	Cadiz
11002	Cadiz
11003	Cadiz
11004	Cadiz
11005	Cadiz
11006	Cadiz
11007	Cadiz
11008	Cadiz
11009	Cadiz
11010	Cadiz
11011	Cadiz
11012	Cadiz
11070	Cadiz
11071	Cadiz
11080	Cadiz
11100	Poligono Tres Caminos (San Fernando)|San Fernando
11110	San Fernando Naval
11120	Campo Soto
11130	Campano|Chiclana De La Frontera|Pago Del Humo
11138	Pinar De Los Franceses|San Juan Del Marquesado
11139	Doña Violeta|La Barrosa|La Soledad|Sancti Petri
11140	Conil De La Frontera
11149	Barrio Nuevo|El Colorado|Fuente Del Gallo|La Fontanilla|Roche
11150	El Cañal|El Parralejo|El Soto|La Muela De Vejer|La Oliva|Manzanete|Ribera De La Oliva|San Ambrosio|Vejer De La Frontera
11158	Cabañas|Jandilla|La Barca De Vejer|Los Libreros|Los Naveros|Santa Lucia
11159	El Palmar|Los Caños De Meca|Montecote|Zahora
11160	Barbate|Sierra De Retin
11170	Charco Dulce|Huelvacar|La Canaleja|Las Algamitas|Los Alburejos|Los Hardales|Medina Sidonia
11178	Paterna De Rivera
11179	Cantarranas|Cucarrete|Las Lomas|Los Badalejos|Malcocinado
11180	Alcala De Los Gazules|El Picacho
11190	Benalup-Casas Viejas
11200	Algeciras
11201	Algeciras
11202	Algeciras
11203	Algeciras
11204	Algeciras
11205	Algeciras
11206	Algeciras
11207	Algeciras
11270	Algeciras
11271	Algeciras
11280	Algeciras
11300	La Linea De La Concepcion
11310	Sotogrande
11311	Guadiaro
11312	San Enrique De Guadiaro|Torreguadiaro
11313	Puente Mayorga
11314	Campamento
11315	Santa Margarita|Zabal Bajo
11316	La Alcaidesa
11320	San Pablo De Buceite
11330	Jimena De La Frontera
11339	Aldefilla|Jimena De La Frontera (Estacion)|La Herradura|Los Angeles|Marchenilla
11340	San Martin Del Tesorillo
11349	El Secadero|Montenegral Alto
11350	Castellar De La Frontera|Pueblo Nuevo De Castellar
11351	Almoraima
11360	San Roque
11368	San Roque, Ferrea De (Estacion)
11369	Carteya-Carteya|Miraflores (San Roque)|Taraguilla
11370	Benharas|Los Barrios
11379	Alamos, Los (Urbanizacion)|Barrios, Ferrea De Los (Estacion)|Ciudad Jardin|Cortijillos|Guadacorte|Hiper Continente|La Cañada|Palmones|Poligono Industrial Nuevo
11380	Casas De Porro|Cañada De La Jara|La Costa|La Peña|Los Zorrillos|Paloma Baja|Pedro Valiente|Puertollano|Tarifa|Valdevaqueros
11390	El Bugeo|El Pelayo
11391	Betis|Bolonia|El Alamillo|El Chaparral|El Lentiscal|El Pulido|Facinas|La Gloria|La Herrumbrosa|Las Caheruelas|Las Piñas|Realillo
11392	Tahivilla
11393	El Almarchal|La Zarzuela|Zahara De Los Atunes
11400	Añina|Casablanca|El Romero|El Solete Alto|Fuente Del Rey|La Jarda|Las Tablas|Los Isletes|Mesas De Santa Rosa
11401	Jerez De La Frontera
11402	Jerez De La Frontera
11403	Jerez De La Frontera
11404	Jerez De La Frontera
11405	Jerez De La Frontera
11406	Jerez De La Frontera
11407	Jerez De La Frontera
11408	El Portal|Jerez De La Frontera|Sierra San Cristobal (Jerez De La Frontera)|Sierra San Cristobal (Puerto De Santa Maria)
11470	Jerez De La Frontera
11471	Jerez De La Frontera
11480	Jerez De La Frontera
11500	Berben|Doña Blanca-Poblado|El Puerto De Santa Maria|Poligono Industrial El Palmar|Poligono Industrial Salinas De San Jose|Valdelagrana
11510	Las Canteras|Puerto Real
11518	Barrio De Jarana
11519	Consorcio Bahia De Cadiz|El Trocadero|Rio San Pedro
11520	El Bercial|Las Brevas|Las Meloneras|Rincones|Rota
11530	Rota Naval
11540	Bonanza|La Jara|Sanlucar De Barrameda
11549	La Algaida
11550	Chipiona
11560	Trebujena
11570	Garrapilos|La Barca De La Florida|La Suara|Mesas Del Corral|Puente De La Guareña
11574	Jerez De La Frontera
11579	Jose Antonio
11580	San Jose Del Valle
11590	Mesas De Asta
11591	Guadalcacin|Jerez De La Frontera
11592	Jerez De La Frontera
11593	Cuartillo De La Paz|Estella Del Marques|Jerez De La Frontera
11594	El Torno|San Isidro De Guadalete
11595	La Ina|Torrecera
11596	Gibalbin
11600	Ubrique
11610	Gaidovar|Grazalema
11611	Villaluenga Del Rosario
11612	Benaocaz
11620	El Drago|Jedula|Junta De Los Rios|La Misericordia|La Pedrosa|Majadales|Santa Cecilia|Vega De Los Molinos
11630	Abrajanejo|Arcos De La Frontera|El Concejo|El Yugo|Fuensanta|La Garrapata|La Sierpe|Las Abiertas|Los Barrancos|Toronjil|Vallejas
11638	Industria Quimicas Urumea|Santiscal
11639	Algar|Dehesilla De Algar|La Perdiz
11640	Bornos
11648	Espera
11649	Coto De Bornos
11650	La Cierva|Villamartin
11659	Pozo Amargo|Puerto Serrano
11660	Prado Del Rey
11670	El Bosque
11679	Benamahoma
11680	Algodonales|Arenal|Campo Huerta|Juncales|La Nava Y Lapa|Madrigueras
11687	El Gastor|El Jaral|Era De La Viña|Ventas Nuevas
11688	Arroyomolinos|Bocaleones|Las Casas|Zahara De La Sierra
11689	La Muela De Algodonales
11690	Olvera
11691	Torre Alhaquime
11692	Setenil De Las Bodegas
11693	Alcala Del Valle
12001	Castellon De La Plana/Castello De La Pla
12002	Castellon De La Plana/Castello De La Pla
12003	Castellon De La Plana/Castello De La Pla
12004	Castellon De La Plana/Castello De La Pla
12005	Castellon De La Plana/Castello De La Pla
12006	Castellon De La Plana/Castello De La Pla
12070	Castellon De La Plana/Castello De La Pla
12071	Castellon De La Plana/Castello De La Pla
12080	Castellon De La Plana/Castello De La Pla
12100	Castellon De La Plana/Castello De La Pla|El Grau De Castello/Grao
12110	Alcora, L'
12118	Useres, Les/ Useras
12119	Araya|Costur|Masdavall
12120	Lucena Del Cid
12121	La Foya
12122	Figueroles
12123	Castillo De Villamalefa|Cedraman|Giraba De Abajo|Giraba De Arriba|Ludiente
12124	Bibioj|Villahermosa Del Rio
12125	Zucaina
12126	San Vicente De Cortes
12127	Cortes De Arenoso
12130	Correntilla, De (Masia)|Mas De Flors|Sant Joan De Moro
12131	Las Crevadas
12132	Atzeneta Del Maestrat
12133	Meanes
12134	Benafigos|Xodos/Chodos
12135	Vistabella Del Maestrazgo
12140	Albocasser
12150	Villafranca Del Cid
12159	Castellfort|Mas Llosar
12160	Benasal|Fuentes En Segures
12161	La Torre D'En Besora
12162	Vilar De Canes
12163	Culla|Molinell|Monllat|Pla Del Sabater|Sales De Matella, De (Masia)|Torre De Matella
12164	Los Rosildos
12165	Ares Del Maestrat|Coll D'Ares
12166	Los Ibarzos
12170	Sant Mateu
12179	Tirig
12180	Cabanes
12181	Benlloch
12182	Collet|Sierra Engarceran
12183	Vilanova D'Alcolea
12184	Sarratella|Torre Endomenech
12185	Coves De Vinroma, Les|Mas D'En Ramona|Mas D'En Rieres|Mas Dels Calduch
12186	La Salzadella
12190	Borriol
12191	La Pobla Tornesa
12192	Vilafames
12193	La Barona|La Baseta|Pelechana, La ( Pelechaneta, La)
12194	Montalba|Vall D'Alba
12200	Onda
12210	Ribesalbes
12220	Artesa
12221	Tales
12222	Ain|Alcudia De Veo|Benitandus|Veo
12223	Sueras/Suera
12224	Ayodar|Villamalur
12225	Fuentes De Ayodar|Torralba Del Pinar
12230	Argelita|Espadilla|Fanzara|Toga|Vallat
12231	Cirat
12232	Arañuel|El Tormo|Torrechiva
12300	Morella
12310	Forcall
12311	Ortells|Palanques|Villores|Zorita Del Maestrazgo
12312	La Mata De Morella|Olocau Del Rey|Todolella
12313	La Pobla D'Alcolea
12314	Xiva De Morella
12315	Vallibona
12316	Hostal Nou
12317	Herbes
12318	Cinctorres|Portell De Morella
12319	Castell De Cabres|Herbeset
12320	Sant Jordi/San Jorge
12330	Traiguera
12340	La Jana
12350	Canet Lo Roig
12360	Xert/Chert
12370	Anroig
12400	Segorbe
12410	Altura|La Cueva Santa
12412	Geldo|Villatorcas
12413	Almedijar|Castellnovo
12414	Algimia De Almonacid|Peñalba|Vall De Almonacid
12415	Gaibiel|Matet
12420	Barracas
12428	Fuente La Reina|La Monzona|Los Calpes|Los Cantos|Puebla De Arenoso|Villanueva De Viver
12429	El Toro|Pina De Montalgrao
12430	Artesa De Abajo|Artesa De Arriba|Bejis|Rios De Arriba
12431	Toras
12440	Caudiel
12447	Montan
12448	La Alqueria|Montanejos
12449	Benafer|Higueras|Pavias
12450	Jerica|Novaliches
12460	Viver
12469	Los Canales|Masada Del Sordo|Masia De Los Perez|Masias De Cristo|Rios De Abajo|Sacañet|Teresa
12470	Navajas
12480	Soneja
12489	Sot De Ferrer
12490	Azuebar
12499	Chovar
12500	Vinaros
12510	San Rafael Del Rio
12511	Rossell
12512	Bel
12513	Avella, La (Cati)|Cati
12520	Nules
12526	La Vilavella
12527	Artana
12528	Eslida
12529	Mascarell
12530	Alquerias De Santa Barbara|Alquerias Santa Barbara|Burriana
12539	Alquerias Del Niño Perdido
12540	Vila-Real/Villarreal
12549	Betxi
12550	Almazora/Almassora
12560	Benicasim|Benicassim
12570	Alcala De Xivert
12578	Cervera Del Maestre
12579	Alcossebre|Capycorp|Las Fuentes
12580	Benicarlo
12589	Calig
12590	Almenara
12591	Casablanca (La Llosa)|La Llosa|Platja D'Almenara Casablanca
12592	Chilches/Xilxes
12593	Grao De Moncofar|Moncofa
12594	Oropesa/Oropesa Del Mar
12595	La Ribera De Cabanes|Torre De La Sal
12596	Torreblanca|Torrenostra
12597	Santa Magdalena De Pulpis
12598	Peñiscola
12599	Ballestar|Boixar|Corachar|Fredes|Las Casas Del Rio|Pobla De Benifassa
12600	La Vall D'Uixo
12609	Alfondeguilla
13001	Ciudad Real
13002	Ciudad Real
13003	Ciudad Real
13004	Ciudad Real
13005	Ciudad Real
13070	Ciudad Real
13071	Ciudad Real
13080	Ciudad Real
13100	Piedrabuena
13107	Alcolea De Calatrava
13108	Luciana
13109	Puebla De Don Rodrigo
13110	Bohonal|Horcajo De Los Montes
13113	El Alcornocal
13114	El Robledo|Las Islas|Las Tablillas|Navalajarra|Navalrincon
13115	Santa Quiteria
13116	Alcoba De Los Montes
13117	Anchuras|Encinacaida|Enjambre|Gamonoso
13118	Las Huertas Del Sauceral
13120	Porzuna
13128	Casas Del Rio|Cuesta Del Rio|Garlitera|Las Tiñosillas
13129	El Bonal|El Trincheto|Las Betetas|Las Rabinadas|Piedrala
13130	Fuencaliente
13140	Fernan Caballero|Peralvillo
13150	Carrion De Calatrava
13160	Torralba De Calatrava
13170	Miguelturra
13179	Pozuelo De Calatrava
13180	Abenojar
13189	Navacerrada
13190	Corral De Calatrava
13191	Los Pozuelos De Calatrava
13192	Cabezarados|Tirteafuera
13193	Arroba De Los Montes|Fontanarejo|Navalpino
13194	El Molinillo|El Torno|La Toledana|Navas De Estena|Pueblo Nuevo Del Bullaque|Puentes De Piedrala|Retuerta De Bullaque
13195	Poblete|Valverde
13196	Las Casas|Picon
13200	Herrera De La Mancha|Manzanares
13210	Villarta De San Juan
13220	Llanos Del Caudillo
13230	Membrilla
13240	La Solana
13247	San Carlos Del Valle
13248	Alhambra
13249	Ruidera
13250	Daimiel
13260	Bolaños De Calatrava
13270	Almagro
13279	Valenzuela De Calatrava
13300	Valdepeñas
13310	La Consolacion
13320	Villanueva De Los Infantes
13326	Montiel
13327	Santa Cruz De Los Cañamos
13328	Almedina
13329	Carrizosa
13330	Villanueva De La Fuente
13331	Cañamares
13332	Villahermosa
13333	Fuenllana
13340	Albaladejo
13341	Terrinches
13342	Puebla Del Principe
13343	Villamanrique
13344	Torre De Juan Abad
13345	Cozar
13350	Moral De Calatrava
13360	Granatula De Calatrava
13370	Calzada De Calatrava
13379	Alameda|Belvis|Villanueva De San Carlos
13380	Aldea Del Rey
13390	Pozo De La Serna
13391	Alcubillas
13400	Almaden
13410	Agudo
13411	Valdemanco Del Esteras
13412	Chillon
13413	Alamillo
13414	Gargantiel|Saceruela
13415	San Benito
13420	Malagon
13427	Cortijos De Abajo|Cortijos De Arriba
13428	Charco Del Tamujo|Las Morras|Las Povedillas|Los Ballesteros|Los Quiles|Valdehierro
13429	Cristo De Espiritu Santo|El Sotillo|La Fuencaliente|Las Peralosas
13430	La Cañada De Calatrava
13431	Villar Del Pozo
13432	Ballesteros De Calatrava
13433	Caracuel De Calatrava
13434	Aeropuerto Central Ciudad Real
13440	Argamasilla De Calatrava
13450	Brazatortas
13459	Veredas|Veredilla
13460	Viñuela
13470	Valdeazogues
13473	Fontanosas
13480	Almadenejos
13490	Guadalmez
13500	Puertollano
13580	Almodovar Del Campo
13590	Hinojosas De Calatrava
13591	Cabezarrubias Del Puerto
13592	Mestanza
13593	Solana Del Pino
13594	El Hoyo|Solanilla Del Tamaral
13595	Villamayor De Calatrava
13596	Bienvenida
13597	Barriada Rio Ojailen|El Villar
13598	Retamar
13600	Alcazar De San Juan
13610	Campo De Criptana
13619	Arenales De San Gregorio
13620	Pedro Muñoz
13630	Socuellamos
13640	Herencia
13650	Puerto Lapice
13660	Las Labores
13670	Villarrubia De Los Ojos
13679	Arenas De San Juan
13680	Fuente El Fresno
13690	Alameda De Cervera
13700	Tomelloso
13710	Argamasilla De Alba
13720	Cinco Casas (Estacion)|Cinco Casas (Pueblo)
13730	Santa Cruz De Mudela
13739	Bazan|Los Mirones|Umbria De Fresneda|Villalba De Calatrava
13740	Torrenueva
13750	Castellar De Santiago
13760	Almuradiel
13768	Venta De Cardenas
13770	Viso Del Marques
13779	Huertezuelas|San Bruno|San Lorenzo De Calatrava
14001	Cordoba
14002	Cordoba
14003	Cordoba
14004	Cordoba
14005	Abejorreras (Cordoba)|Aguilarejo Alto Y Bajo (Cordoba) (Nucleo)|Alameda Del Obispo (Cordoba)|Alcaide, El (Cordoba) (Nucleo)|Cordoba|Fontanar De Quintos (Cordoba)|Golondrina, La (Cordoba)|Gorgoja, La (Cordoba)|Llanos Del Castillo (Cordoba)|Moroqui (Cordoba)|Pitas, Las (Cordoba)|Santa Clara (Cordoba)|Terrenos Del Castillo (Cordoba)|Veredon De Los Pinos (Cordoba)
14006	Cordoba
14007	Cordoba
14008	Cordoba
14009	Cordoba
14010	Arenal, El (Cordoba)|Camino Carbonell (Cordoba)|Camino Lope Garcia (Cordoba)|Cordoba|Huerta De La Cruz (Cordoba)
14011	Casilla Del Aire (Santa Maria De Trassierra)|Castillo De La Albaida (Cordoba)|Cordoba|Gitana, La (Cordoba)|Hornillo, El (Cordoba)
14012	Cordoba|Hospital Los Morales (Cordoba)|Jardinito, El (Cordoba) (Finca)|Morales, Los (Cordoba)
14013	Cordoba
14014	Campiñuela Baja (Cordoba)|Cordoba|Doña Manuela (Cordoba)|Las Corralijas|Pedroches (Cordoba) (Nucleo)|Peñatejada (Cordoba) (Urbanizacion)|Quemadillas, Las (Cordoba)--Denominacion Popular;No Oficial--|Torreblanca (Cordoba)|Universidad Laboral (Cordoba)
14029	Cañuelo Bajo (Cordoba)|El Melgarejo|El Negrete|Guardentera (Cordoba)|Hospital Psiquiatrico|La Reina|Las Ermitas|Las Jaras|Los Arenales|Medina Azahara|Nuestra Señora De Linares|San Cristobal|San Llorente|Santo Domingo|Solanas Del Pilar|Torrehoria|Valchillon
14070	Cordoba
14071	Cordoba
14080	Cordoba
14100	Algarbes|El Garabato|El Rinconcillo|La Carlota|La Paz|Monte Alto
14110	Fuente Carreteros|Silillos
14111	Chica Carlota|Fuencubierta|Las Pinedas
14112	La Ventilla
14113	Cañada Del Rabadan
14115	El Villar
14120	Fuente Palmera
14129	La Herreria|Ochavillo Del Rio|Peñalosa|Puebla De La Parrilla|Villalon
14130	Barrio San Vicente (Guadalcazar)|Guadalcazar
14140	La Victoria
14150	San Sebastian De Ballesteros
14190	Puente Viejo
14191	El Arrecife|Quintana, Aldea
14192	Campo Alegre|Cordoba|El Puerto|Las Siete Fincas
14193	Cortijo El Rubio|El Higueron
14200	Peñarroya-Pueblonuevo
14206	Valsequillo
14207	La Granjuela
14208	Los Blazquez
14209	Doña Rama|El Entredicho|El Hoyo|Porvenir De La Industria
14210	Cerro Miguelito|Fuente Agria|La Mimbre|Pabellones De San Isidro|Solana Del Peñon|Villaharta
14220	Central Termica Puente Nuevo|Espiel|Estacion De Espiel|La Ballesta|Mina De La Concepcion
14230	Villanueva Del Rey
14240	Belmez
14249	Alcornocal|Los Panchez|Navalcuervo|Posadilla
14250	Villanueva Del Duque
14260	Fuente La Lancha
14270	Hinojosa Del Duque
14280	Belalcazar|Cachiporro|Chaparral|Dehesa De Las Alcantarillas|Madroñiz|Santa Clara (Belalcazar)
14290	Fuente Obejuna
14297	Cuenca
14298	Argallon|La Coronada|Piconcillo
14299	Cardenchosa|Cañada Del Gamo|Los Morenos|Ojuelos Altos|Ojuelos Bajos
14300	Villaviciosa De Cordoba
14310	Obejo
14320	El Vacar|Obejo, De (Estacion)
14330	Brimz (Centro Militar)
14350	Cerro Muriano (Nucleo)|Cordoba
14400	Pozoblanco
14410	Torrecampo
14412	Pedroche
14413	El Guijo
14420	Villafranca De Cordoba
14430	Adamuz
14439	Algallarin
14440	Villanueva De Cordoba
14445	Cardeña|El Cerezo
14446	Venta Del Charco
14447	Azuel
14448	Conquista
14449	La Garganta|Minas De Horcajo
14450	Añora
14460	Dos Torres
14470	El Viso
14480	Alcaracejos|Mojonera
14490	Villaralto
14491	Santa Eufemia
14500	Cordobilla|El Rabanal|Majada Vieja|Puente Genil
14510	Moriles
14511	Colina De La Virgen|Dehesa Del Cañaveral|Los Piedros|Navas Del Selpillar
14512	Bocas De Riguelo|Isla Del Obispo|La Mina|Palomar|Puerto Alegre|Ribera Alta|Ribera Baja|Sotogordo
14520	Fernan-Nuñez
14530	Montemayor
14540	La Rambla
14546	Santaella
14547	El Fontanar|La Guijarrosa
14548	Montalban De Cordoba
14549	Huertas Bocas Del Salado|Huertas Del Ingeniero|Huertas Del Sol|La Montiela
14550	Carchena|Cerro Del Humo|Cortijo Blanco|Jarata|La Salud|La Zarza|Llano Del Mesto|Montilla|Riofrio|San Francisco|Sierra O Buenavista (Montilla)|Vereda De Cerro Macho
14600	Campiña|Casillas De Velasco|Charco Del Novillo|Estacion, La (Montoro)|Huertos Familiares San Fernando|Madroñal|Montoro|Nava|Santa Brigida|Torrecilla
14610	Alcolea|Barriada Del Angel (Alcolea)|Encinares De Alcolea|Los Cansinos|Monton De Tierra|Porrillas|Ribera Baja (Cordoba)|Sol, El (Alcolea)
14620	El Carpio|La Huelga|Maruanas|San Antonio
14630	Pedro Abad
14640	Villa Del Rio
14650	Bujalance|Dehesa De Potros|La Cruz|Los Leones|Maria Aparicio
14659	Morente
14660	Cañete De Las Torres
14670	Valenzuela
14700	Arriel|Barriada Estacion (Palma Del Rio)|Carrascal, El (Palma Del Rio)|Casas De Huertas Arriel|Casas De Huertas El Rincon|Casas De Huertas Pedro Diaz|Chalets Acebuchal|Chalets Baldio|Chalets La Algaba|El Calonge|El Pizon|El Rincon|La Barqueta|La Chirritana|La Graja|La Jara|Palma Del Rio|Pedro Diaz|Pimentada|Vega De Santa Lucia|Veredon El Mohino
14709	Bembezar Del Caudillo|Cespedes|Mesas De Guadalora
14710	Barquera, La (Villarrubia)|Majaneque|Real Soriana (Villarrubia) (Vereda)|Villarrubia (Villarrubia) (Nucleo)
14711	Encinarejo De Cordoba (Nucleo)
14719	Veredon De Los Frailes
14720	Almodovar Del Rio|Nuestra Señora Del Rosario
14729	Llanos, Los (Almodovar Del Rio)|Los Mochos
14730	Posadas
14739	Rivero De Posadas
14740	Almarja|El Aguila|El Alta|Hornachuelos|Las Aljabaras|Las Mezquetillas|Los Angeles|Los Corrales
14749	Moratalla|Nava De Los Corchos|San Calixto
14800	El Salado|Jaula|Las Navas|Los Prados|Navasequilla|Priego De Cordoba
14810	Bernabe|Carcabuey|El Portazgo|Fuente Dura
14811	Algar|Gaena-Casas Gallegas|Los Lopez|Los Villares
14812	Almedinilla|Cuesta Blanca
14813	Bracana|Carrasca, La (Almedinilla)|La Fuente Grande|Los Rios|Sileras|Venta Valero
14814	Campo Nubes|El Tarajal|Zamoranos
14815	Azores|Castil De Campos|Cañuelo, El (Priego De Cordoba)|El Solvito|Fuente Tojar|La Cubertilla|Las Angosturas|Todos Aires|Vega, La (Priego De Cordoba)
14816	El Esparragal|El Poleo|Genilla|La Concepcion|Las Higueras|Las Paradejas|Villa Turistica De La Subbetica|Zagrilla|Zagrilla Alta|Zagrilla Baja
14817	El Castellar|La Poyata|Las Lagunillas
14820	Atalayuela|Cortijo La Reina|Pragdena|Santa Cruz|Torres Cabrera
14830	Espejo
14840	Castro Del Rio|Garci-Calvo
14850	Aladid|Baena|Manosalva|Palomarejo|Sierra, La (Baena)
14857	Nueva Carteya
14858	Llano Del Espinar
14859	Albendin|Fuentidueña
14860	Doña Mencia
14870	Zuheros
14880	Estacion, La (Luque)|Los Montes|Luque|Marbella|Morellana|Peñillas
14900	Anjaron|Arroyuelos (Lucena)|Campo De Aras|Cristo Marroqui|Las Vegas|Los Santos|Lucena|Martin Gonzalez|Molino Navajas-El Zarpazo
14910	Benameji
14911	Huertas Duque|Huertas Llanos|Jauja
14912	Vadofresno
14913	Encinas Reales|Venta Del Rio Anzur|Zurreon
14914	Palenciana
14915	El Tejar
14920	Aguilar De La Frontera
14930	Monturque
14940	Cabra|Cid Toledo|El Martinete|Ermita De La Esperanza|Ermita Virgen De La Sierra|Estacion, La (Cabra)|Huertas Bajas De Cabra|La Alcaidia|La Alcantarilla|La Benita|Los Aranda|Los Llanos|Piedras De Varo
14950	Arroyo Tijeras|Burbunera|Campullas|Cañada De Zambra|Cerrillo Zambra|El Nacimiento|Granadilla|Las Piedras|Las Viboras|Llanos De Don Juan|Los Perez|Palomares|Zambra
14960	El Vadillo|Fuente De Las Cañas|Isla Alta|Isla Baja|Morales, Los (Rute)|Pantano (Rute)|Rio Anzur|Rute
14970	Cierzos Y Cabreras|Iznajar|Valdearenas
14978	Alarconas Y Antorchas|Arroyo Del Cerezo|Corona Algaida Y Gata|Cruz De Algaida|El Adelantado|Fuente Del Conde|Las Chozas|Los Concejos|Los Pechos|Montes Claros|Valenzuela Y Llanadas
14979	Arroyo De Priego|El Higueral|El Jaramillo|Hoz, La (Iznajar)|Hoz, La (Rute)|La Celada|Lorite|Los Juncares|Solerche
15001	A Coruña
15002	A Coruña
15003	A Coruña
15004	A Coruña
15005	A Coruña
15006	A Coruña
15007	A Coruña
15008	A Coruña|Birloque, O|Cabana, A (Coruña, A)|Castro De Elviña (Carretera)|Martinete, O (Viñas)|San Cristobal Das Viñas|San Vicente De Elviña
15009	A Coruña|Casanova De Eiris|Curramontes|Monserrat (Avenida)
15010	A Coruña|Camiño De Penamoa|San Pedro De Visma (Lugar)
15011	A Coruña
15070	A Coruña
15071	A Coruña
15080	A Coruña
15100	Carballo|Poligono Industrial Bertoa
15102	Brea, A (Carballo)|Carballo (San Xoan)|Loureiros, Os (San Xoan De Carballo-Carballo)|Monte, O (San Xoan De Carballo-Carballo)|Ponte Rosende, A (San Xoan De Carballo-Carballo)|Revolta, A (San Xoan De Carballo-Carballo)
15105	Castrillon (San Cristovo De Lema-Carballo)|Imende, A (Santa Maria De Noicela-Carballo)|Lema (San Cristovo)|Miron (Bertoa)|Noicela (Santa Maria)|Vilela (San Miguel)
15106	Goians (Santo Estevo)|Sisamo (Carballo)|Sisto, O (Sisamo)|Vilares, Os (Carballo)|Xoane (Santo Estevo De Goians-Carballo)|Xoane Da Estrada
15107	Arnados|Cances (San Martiño)|Cances Da Vila (San Martiño De Cances-Carballo)|Cances Grande|Netoma|Oza (San Breixo)|Razo (San Martiño)|Razo Da Costa|Vilar Do Carballo (San Breixo De Oza-Carballo)
15108	Aldemunde (Santa Maria Madanela)|Añon De Berdillo, O (San Lourenzo De Berdillo-Carballo)|Berdillo (San Lourenzo)|Bertoa (Santa Maria)|Bolon (San Salvador De Sofan-Carballo)|Fondal, O (Santa Maria De Bertoa-Carballo)|Moucho, O (San Lourenzo De Berdillo-Carballo)|Paradela (San Salvador De Sofan-Carballo)|Queo De Abaixo (Santa Maria De Bertoa-Carballo)|Rega, A (Santa Maria De Bertoa-Carballo)|Requeixo|Sofan (San Salvador)|Vilarnovo (San Lorenzo De Berdillo-Carballo)
15109	Ardaña (Santa Maria)|Artes (San Xurxo)|Baris (Santa Maria De Rus-Carballo)|Canosa, A (Santa Maria De Rus-Carballo)|Entrecruces (San Xens)|Entrecruces Baja|Feira De Berdillo, A (San Xurxo De Artes-Carballo)|Quintans (Santa Maria De Ardaña-Carballo)|Rebordelos (San Salvador)|Rus (Santa Maria)|San Paio (San Xens De Entrecruces-Carballo)|Vivente (Santa Maria De Ardaña-Carballo)
15110	Anllons (Ponteceso)|Anllons De Arriba (Anllons - Ponteceso)|Brantuas (Ponteceso)|Bugalleira (Santo Andre De Tallo-Ponteceso)|Campara, A (San Martiño De Cores-Ponteceso)|Carballido (San Vicenzo De Graña,A-Ponteceso)|Corcoesto (Cabana De Bergantiños)|Cores (Ponteceso)|Cospindo (Ponteceso)|Couto (Cospindo - Ponteceso)|Gandara (Santa Eleuterio De Tella-Ponteceso)|Graña (Ponteceso)|Langueiron (Ponteceso)|Lestimoño (San Vicenzo De Graña, A-Ponteceso)|Nemeño (Ponteceso)|Niñons (Ponteceso)|Pazos (Ponteceso)|Pazos De Abaixo (Pazos - Ponteceso)|Pazos De Arriba (Pazos - Ponteceso)|Ponteceso|Sergude (San Xoan De Xornes-Ponteceso)|Tallo (Ponteceso)|Tella (Ponteceso)|Trabe (Tella - Ponteceso)|Vereda (Santo Eleuterio De Tella-Ponteceso)|Xornes (Ponteceso)|Xornes (Xornes - Ponteceso)
15111	Buño (Buño)|Buño (Santo Estevo)|Cambre (San Martiño)|Cambre (San Martiño-Malpica)|Leiloio (Santa Maria)|Pedrosa-Tremoa
15112	Cerqueda (San Cristovo)|Pasacondia-Aldeola|Pozacas-Leduzo (San Cristovo De Cerqueda-Malpica De Bergantiños)
15113	Asalo (Santiago De Mens-Malpica De Bergantiños)|Barizo|Barizo (San Pedro)|Beo|Beo (Santiso De Vilanova De Santiso-Malpica De Bergantiños)|Camuza, A|Malpica|Malpica De Bergantiños|Malpica De Bergantiños (San Xulian)|Mens|Mens (Santiago)|Seaia (San Xulian De Malpica De Bergantiños-Malpica De Bergantiños)|Vilanova De Santiso (Santiso)
15114	Aldea (Corme Aldea - Ponteceso)|Corme-Aldea (Ponteceso)|Corme-Porto (Ponteceso)
15115	Aspera (Santo Estevo De Cesullas-Cabana De Bergantiños)|Balado (Santo Estevo De Cesullas-Cabana De Bergantiños)|Bronllo (Santo Estevo De Cesullas-Cabana De Bergantiños)|Cesullas (Cabana De Bergantiños)|Neaño (Santo Estevo De Cesullas-Cabana De Bergantiños)|Ponteceso De Cabanas (Cesullas - Cabana De Bergantiños)
15116	Canduas (Cabana De Bergantiños)|Canduas (Canduas - Cabana De Bergantiños)|Grelas, As (San Martiño De Canduas-Cabana De Bergantiños)|Sinde (San Martiño De Canduas-Cabana De Bergantiños)|Taboido (San Martiño De Canduas-Cabana De Bergantiños)|Telleira, A (San Martiño De Canduas-Cabana De Bergantiños)
15117	Laxe|Laxe (Laxe)|Laxe (Santa Maria)
15118	Aprazaduiro, O (San Simon De Nande-Laxe)|Boaño (Santiago De Traba-Laxe)|Castrelo (Santo Estevo De Soesto-Laxe)|Matio (San Simon De Nande-Laxe)|Mordomo (Santiago De Traba-Laxe)|Nande (San Simon)|Sarces (San Amedio)|Serantes (Santa Maria)|Soesto (Santo Estevo)|Traba (Santiago)
15119	Borneiro (Cabana De Bergantiños)|Vilaseco (San Xoan De Borneiro-Cabana De Bergantiños)
15121	Allo (San Pedro De Ponte Do Porto,A-Camelle|Arou|Camelle|Camelle (Espiritu Santo, O )|Dor (San Pedro De Ponte Do Porto, A-Camelle)|Ponte Do Porto, A (Ponte De Porto)|Ponte Do Porto, A (San Pedro)
15122	Cruceiro, O (Xaviña-Camariñas)|Tasaraño|Xaviña (Camariñas)|Xaviña (Santa Maria)
15123	Camariñas|Camariñas (San Xurxo)
15124	Bardullas (San Xoan)|Coucieiro (San Pedro)|Frixe (Santa Locacia)|Morquintian (Santa Maria)|Muxia|Muxia (Santa Maria)|Nemiña (San Cristovo)|San Tirso De Vuitiron (San Tirso)|Senande|Sorna (San Pedro De Coucieiro-Muxia)|Touriñan (San Martiño)|Vilastose (San Cibran)
15125	Caberta (San Fins)|Foxo|Leis De Nemancos (San Pedro)|Merexo (San Martiño De), Muxia|Moraime (San Xulian)|Muiños, Os (Moraime)|O (Santa Maria Da), Muxia|Ozon (San Martiño)|Quintans (Ozon), Muxia|Suxo (Muxia)|Vilar De Sobremonte (Muxia)
15126	Quintans (San Miguel De Treos-Vimianzo)|Reboredo Santa Maria De Salto (Vimianzo)|Salto (Santa Maria)|Tines|Tines (Santa Baia)|Treos (San Miguel)
15127	Baiñas|Baiñas (Santo Antoiño)|Outeiro, O (Santo Antoiño De Baiñas-Vimianzo)|Serramo (San Sebastian)
15128	Berdoias (San Pedro)|Castrelo (San Martiño)
15129	Braño (Carantoña), Vimianzo|Calo (San Xoan-Vimianzo)|Cambeda (San Xoan)|Carantoña (San Martiño), Vimianzo|Carnes (Carnes)|Carnes (San Cristovo), Vimianzo|Casais (San Vicenzo De Vimianzo-Vimianzo)|Cereixo (Santiago), Vimianzo|Cures, Vimianzo|Montecelos (San Cristovo De Carnes), Vimianzo|Mouzo (San Cristovo De Carnes), Vimianzo|Ogas (San Xoan De Cambeda-Vimianzo)|Pasarela|Tufions|Tufions, Vimianzo|Vimianzo|Vimianzo (San Vicenzo)
15130	Corcubion|Corcubion (San Marcos)
15137	Redonda (San Pedro)
15138	Bazarra (Santo Adran De Toba-Cee)|Bermun (San Xian De Pereiriña, A-Cee)|Estorde (Santo Adran De Toba-Cee)|Lires (Santo Estevo)|Lobelos (San Xian De Pereiriña, A-Cee)|Pereiriña, A (San Xian)|Toba (Santo Adran)
15139	Castelo (Santiago)|Folgueira (Santiago De Castelo-Culleredo)
15140	Meicende (Pastoriza-Arteixo)|Pastoriza (Arteixo)
15141	Oseiro (Arteixo)|Rañobre (Arteixo)|Vilarrodis (Arteixo)
15142	Arteixo (Casco Urbano)|Arteixo (Santiago)|Pedreira (Arteixo)|Rañal (Arteixo)|Suevos (Arteixo)|Suso (Arteixo)
15143	Poligono Industrial Sabon
15144	Armenton (San Pedro)|Barrañan (Arteixo)|Cachada (Arteixo)|Chamin (Arteixo)|Chamin De Abaixo (Arteixo)|Chamin De Arriba (Arteixo)|Larin (Santo Estevo)|Lañas (Santa Mariña-Arteixo)|Monteagudo (Arteixo)|Sorrizo (Arteixo)
15145	Barreira (Santa Maria De Toras-Laracha)|Botica (Santiago De Vilaño-Laracha)|Caion (Santa Maria Do Socorro)|Campo (Santa Maria De Toras-Laracha)|Coiro (San Xian)|Cruceiro (San Xian De Lendo-Laracha)|Erboedo (Santa Maria)|Estramil|Golmar (San Bieito)|Laracha|Laracha, A|Lendo (San Xian)|Leston (San Martiño)|Montemaior (Santa Maria Madalena)|Paiosaco|Pedreira, A (Caion)|Soandres (San Pedro)|Soutullo (Santa Maria)|Toras (Santa Maria)|Vilaño (Santiago)
15146	Braña Grande (San Roman De Cabovilaño-Laracha)|Cabovilaño (San Roman)|Cancelo (Cabovilaño-A Laracha)|Lemaio (Santa Mariña)|Telleira (San Roman De Cabovilaño-Laracha)
15147	Braña (San Salvador De Erbecedo-Coristanco)|Carrizal (Coristanco)|Castro (Santa Baia-Coristanco)|Castrobo (Valencia-Coristanco|Cereo (Coristanco)|Codesido (San Martiño De Oca-Coristanco)|Coristanco|Cuca (San Xusto-Coristanco)|Erbecedo (Coristanco)|Esfarrapa (Coristanco)|Mira (San Mamede De Seavia-Coristanco)|Oca (Coristanco)|Rabadeira (Seavia-Coristanco)|Riveiro (San Salvador De Erbecedo-Coristanco)|Salgueiras (San Mamede De Seavia-Coristanco)|San Roque (Santa Maria De Traba-Coristanco)|San Xusto (Coristanco)|Seavia (Coristanco)|Traba (Coristanco)|Valencia (Coristanco)|Verdes (Coristanco)|Vilaverde (Santa Maria De Cereo-Coristanco)|Xaviña (Coristanco)
15148	Agualada (Coristanco)|Bormoio (Agualada-Coristanco)|Couso (Coristanco)|Cuns (Coristanco)|Ferreira (Coristanco)
15149	Anos (Cabana De Bergantiños)|Cundins (Cabana De Bergantiños)|Esto (Cabana De Bergantiños)|Mata, A (San Martiño De Riobo-Cabana De Bergantiños)|Nanton (Cabana De Bergantiños)|Riobo (Cabana De Bergantiños)|Silvarredonda (Cabana De Bergantiños)
15150	Baio (Santa Maria)|Baio Grande|Baio Pequeño (Santa Maria De Baio-Zas)|Bamiro (San Amedio)|Fornelos (Baio)|Piroga, A (San Amedio De Bamiro-Vimianzo)|Vilar (San Pedro-Zas)
15151	Ansean (San Pedro De Buxantes-Dumbria)|Berdeogas (Santiago)|Buxan (Santa Baia De Dumbria-Dumbria)|Buxantes (San Pedro)|Dumbria|Dumbria (Santa Baia)|Farrapa (Santiago De Berdeogas-Dumbria)|Olveira (Dumbria)|Olveira (San Martiño)|Olveiroa (Santiago)|Regoelle|Vilar (San Martiño De Olveira-Dumbria)
15152	Salgueiros (San Mamede)
15153	Sardiñeiro (San Xoan)|Sardiñeiro De Abaixo
15154	Duio (San Vicenzo)|Escaselas (San Martiño De Duio-Fisterra)|Mallas (San Martiño De Duio-Fisterra)|San Martiño De Abaixo|San Martiño De Duio (San Martiño)
15155	Fisterra|Fisterra (Santa Maria)|Insua, La (Santa Maria De Fisterra-Fisterra)
15160	Fontan (Sada)|Pazos (Santa Maria De Sada-Sada)|Riobao (Santa Maria De Sada-Sada)|Riovao (Sada)|Sada|Sada (Santa Maria)|Sadadarriba (Santa Maria De Sada-Sada)|Samoedo|Tarabelo (Santa Maria De Sada-Sada)
15165	Aldea De Arriba, A (Santa Marta De Babio-Bergondo)|Babio (Santa Marta)|Bergondo|Bergondo (San Salvador)|Carrio (San Salvador De Bergondo-Bergondo)|Cortes (San Salvador De Bergondo-Bergondo)|Fiobre (San Vicente De Moruxo-Bergondo)|Mariñan (San Salvador De Bergondo-Bergondo)|Moruxo (San Vicente)|Rois (Santa Mariña)|San Cidre (Bergondo)|San Cidre (San Salvador De Bergondo-Bergondo)
15166	Armuño (San Xoan De Lubre-Bergondo)|Campo De Leis (San Xoan De Lubre-Bergondo)|Lubre (San Xoan)
15167	Gandario|Lagoa, A (San Xoan De Ouces-Bergondo)|Ouces (San Xoan)|Tatin (San Xoan De Ouces-Bergondo)
15168	Amexeiral (San Xian De Mondego-Sada)|Castelo (Osedo)|Castro, O (Osedo)|Costa (San Xian De Soñeiro-Sada)|Fortiñon (San Xian De Mondego-Sada)|Mandin|Meiras (San Martiño)|Mondego (San Xian)|Mosteiron (San Nicolao)|Osedo (San Xian)|Piñeiro (San Martiño De Meiras-Sada)|Seijeda (San Xian De Osedo-Sada)|Souto Da Iglesia (San Martiño De Meiras-Sada)|Soñeiro (San Xian)|Vilar (San Martiño De Meiras-Sada)
15169	Carnoedo (Santo Andre)|Fraga (Santa Comba De Veigue-Sada)|Souto (Carnoedo)|Taibo (Santo Andre De Carnoedo-Sada)|Veigue (Santa Comba)
15171	Campamento, O|Caño, O (San Xorxe De Iñas-Oleiros)|Fontes (San Xorxe De Iñas-Oleiros)|Iñas (San Xorxe)|Raposeira (San Xorxe De Iñas-Oleiros)|Xesta, A (San Xorxe De Iñas-Oleiros)
15172	Pazo Do Rio (Santaia De Lians-Oleiros)|Pazo Do Rio, O|Perillo|Perillo (Santa Locaia)
15173	Cova, A (Santa Maria De Oleiros-Oleiros)|Hedreira, A (Santa Maria De Oleiros-Oleiros)|Oleiros (Santa Maria)|Pezoca, A (Santa Maria De Oleiros-Oleiros)|Pousada (Oleiros)|Xubin
15174	Acea Da Ma (Fonteculler)|Castro (Rutis)|Conduzo|Cordeda|Corveira, A (Rutis)|Fonteculler|Laxe (Rutis)|Portadego, O (Santa Maria De Rutis-Culleredo)|Portazgo (Rutis)|Rutis (Santa Maria)|Rutis-Culleredo|Silva, A (San Xian De Almeiras-Culleredo)|Telva, A (San Xian De Almeiras-Culleredo)|Vigovidin|Vigovidin (San Xian De Almeiras-Culleredo)|Vilaboa (Santa Maria De Rutis-Culleredo)
15175	Carral|Cañas (Santa Baia)|Coiro (Santo Estevo De Paleo-Carral)|Paleo (San Estevo)|Paraiso (Santo Estevo De Paleo-Carral)|Taramuño (San Vicente De Vigo-Carral)|Vigo (San Vicente)
15176	Batan, O (San Pedro De Nos-Oleiros)|Carballo, O (Nos-Oleiros)|Coroto, O (San Pedro De Nos-Oleiros)|Gandara, A (Nos-Oleiros)|Gandara, A (San Pedro De Nos-Oleiros)|Meson Da Auga (San Pedro De Nos-Oleiros)|San Pedro De Nos (San Pedro)|Sarro (San Pedro De Nos-Oleiros)|Seixal, O (San Pedro De Nos-Oleiros)|Urb. O Viveiro|Valiño, O (San Pedro De Nos-Oleiros)|Veiga, A (San Pedro De Nos-Oleiros)|Vilanova (Nos)|Vilar, O (Nos)
15177	Aba (Santa Maria De Dexo-Oleiros)|Agra Da Pedra (San Xian De Serantes-Oleiros)|Cabreira (Maianca)|Dexo|Dexo (Santa Maria)|Gandara, A (San Xian De Serantes-Oleiros)|Lagoa, A (Maianca)|Lagoa, A (San Cosme De Maianca-Oleiros)|Lorbe (Santa Maria De Dexo-Oleiros)|Maianca|Maianca (San Cosme)|Mera (Serantes)|Puerto|Serantes (San Xian)|Xoez
15178	Abeleiras De Abaixo|Aguieira (Santa Maria De Dexo-Oleiros)|Arillo|Augarrio|Breixo (Dorneda-Oleiros)|Couto, O (Dorneda)|Dorneda (San Martiño)
15179	Choupana (Santaia De Lians-Oleiros)|Coruxo De Arriba|Espiño (Lians)|Ferrala, A (Santaia De Lians-Oleiros)|Franzomel (Lians)|Lians (Santaia)|Montrove|Porto De Santa Cruz (Santaia De Lians-Oleiros)|Porto De Santa Cruz, O|Seixo, O (Lians)
15180	Aeropuerto De Alvedro|Almeiras (San Xian)|Alvedro (San Xian De Almeiras-Culleredo)|Catas, As|Choeira, A (San Xian De Almeiras-Culleredo)|Pelamios
15181	Aian|Altamira (Anceis)|Anceis (San Xoan)|Campons, Os|Castrobo (Anceis, Cambre) (Lugar)|Castrobo (San Xoan De Anceis-Cambre)|Pena, A (Santiago De Sigras-Cambre)|Pena, A (Sigras, Cambre) (Lugar)|Pontido (Santiago De Sigras-Cambre)|Pontido (Sigras, Cambre) (Lugar)|Seoane (Anceis, Cambre) (Lugar)|Seoane (San Xoan De Anceis-Cambre)|Sigras (Santiago)|Sigras De Abaixo (Santiago De Sigras-Cambre)|Souto, O (Santiago De Sigras-Cambre)|Souto, O (Sigras, Cambre) (Lugar)|Telva, A (Santiago De Sigras-Cambre)|Telva, A (Sigras, Cambre) (Lugar)
15182	Gosende (San Martiño De Tabeaio-Carral)|Sergude (San Xian)|Tabeaio (San Martiño)|Tarroeira De Tabeaio (San Martiño De Tabeaio-Carral)
15183	Beira (Santa Mariña)|Canedo (Santa Mariña De Beira-Carral)|Quembre (San Pedro)
15184	Sumio (Santiago)
15185	Baixa, A (Cerceda)|Cerceda|Cerceda (San Martiño)|Cima Arriba (Santa Maria De Queixas-Cerceda)|Meirama (Santo Andre)|Monte Xalo De Carral|Monte Xalo De Cerceda|Queixas (Santa Maria)|Vilar (San Martiño De Cerceda-Cerceda)|Vilar De Queixas, O|Viris (Santa Maria De Queixas-Cerceda)|Xesteda|Xesteda (Santa Comba)
15186	Adro (San Martiño De Rodis-Cerceda)|Rodis (San Martiño)|Silva, A (Rodis)|Tablilla (San Martiño De Rodis-Cerceda)|Vilamarta (San Martiño De Rodis-Cerceda)
15187	Encrobas, As (San Roman)|Morzos (San Roman Das Encrobas, As-Cerceda)|Xalo (San Roman Das Encrobas, As-Cerceda)
15188	Meirama
15189	Culleredo|Culleredo (San Estevo)|Hermida (Culleredo)|Liñares (Santo Estevo De Culleredo-Culleredo)|Tarrio (Santo Estevo De Culleredo-Culleredo)|Toroño (Santo Estevo De Culleredo-Culleredo)
15190	A Coruña|Feans (Elviña-Coruña, A)|Pocomaco (Poligono Industrial)
15198	Celas (Santa Maria)|Celas De Arriba (Celasdepeiro)|Peiro De Arriba|Sueiro (San Esteban)|Vinxeira Grande (Santa Maria De Celas-Culleredo)|Vinxeira Pequena (Santa Maria De Celas-Culleredo)
15199	Boedo (San Silvestre De Veiga-Culleredo)|Ledoño|Ledoño (San Pedro)|Orro (Culleredo)|Orro (San Salvador)|Peiro De Abaixo (San Silvestre De Veiga-Culleredo)|Sesamo (San Martiño)|Veiga (San Silvestre)
15200	Noia|Noia (Logrosa)
15210	Barquiña, A (Barro)|Barro (Santa Cristina)|Barro (Stª. Cristina-Noia)|Carracido (Barro - Noia)|Couto De Arriba, O (Barro - Noia)|Igrexa, A (Barro - Noia)|Orro (Barro-Noia)|Ponte (Barro - Noia)|San Breixo (Barro-Noia)|Vista Alegre (Barro-Noia)|Vista Fermosa (Barro)
15211	Ponte Nafonso, A (Roo)|Roo (Santa Maria)
15212	Lesende (San Martiño De Lesende-Lousame)|Lesende (San Martiño)|Quintans (Lesende-Lousame)|Rasa De Abaixo (Santa Cristina De Barro-Noia)|Rasa De Abaixo, A|Vilacova (Santa Eulalia)
15213	Argalo (Santa Maria)|Entrerrios (Argalo-Noia)|Obre, O (Santa Mariña)|Ousoño|Ousoño (Santa Cristina De Barro-Noia)|Piñeiro (Argalo - Noia)|Portela, A (Obre - Noia)|Sobreviñas (Argalo - Noia)
15214	Chave (Lousame)|Croido|Lousame|Lousame (San Xoan)|Toxos Outos (San Xusto)
15215	Fruime (San Martiño)
15216	Merelle (Tallara-Lousame)|Pousada (Tallara-Lousame)|Tallara (San Pedro)
15218	Boa (San Pedro)|Camboño (San Xoan)
15220	Aldea Nova (Ames)|Bertamirans (Ames)|Lapido (San Xoan De Ortoño-Ames)|Ortoñiño (San Xoan De Ortoño-Ames)|Ortoño (Ames)|Tarroeira (San Xoan De Ortoño-Ames)
15229	Ames (San Tome)|Augapesada (Santo Tome De Ames-Ames)|Castelo (Santo Tome De Ames-Ames)|Castiñeiro Do Lobo (Santo Tome De Ames-Ames)|Covas (Santo Estevo)|Iglesia (Santo Estevo De Covas-Ames)|Oca (Santo Tome De Ames-Ames)|Ventosa (Covas-Ames)
15230	Boel (San Pedro De Outes-Outes)|Lantarou (San Pedro De Outes-Outes)|Outes|Outes (San Pedro)|Serra De Outes,A
15236	Entins (Santa Maria)|Taras (San Xian)
15237	Banzas (Santo Ourente De Santo Ourente De Entins-Outes)|Santo Ourente De Entins (Santo Ourente)
15238	Asenso|Chacin (Santa Baia)|Pino De Val (Santa Baia De Chacin-Mazaricos)|Vioxo (Santa Baia De Chacin-Mazaricos)
15239	Matasueiro (San Lourenzo)|Valadares (San Miguel)
15240	Creo|Esteiro (Santa Mariña)|Maio|Pendente (Santa Mariña De Esteiro-Muros)|Ribeira De Creo, A|Ribeira De Maio, A|Solleiros|Uhia (Lugar)
15250	Campo Das Cortes|Miraflores (Muros)|Muros|Muros (Muros)|Muros (San Pedro)|Virxe Do Camiño, A
15256	Cuiña (San Fins De San Fins De Eiron-Mazaricos|Mazaricos|San Fins De Eiron (San Fins)
15258	Albores (San Mamede)|Antes (San Cosme)|Arcos (Santiago)|Beba (San Xian)|Cabanude (Santiago De Arcos-Mazaricos)|Cives (San Salvador De Coluns-Mazaricos)|Coiro (Santa Maria)|Coluns ( San Salvador De Coluns-Mazaricos)|Coluns (San Salvador)|Corzon (San Cristovo)|Cumbrans (San Cosme De Antes-Mazaricos)|Espigas-Vilaferreiros (San Mamede De Albores-Mazaricos)|Lago (San Xoan De Mazaricos-Mazaricos)|Maroñas, As (Santa Mariña)|Mazaricos (San Xoan)|Pazos (San Cosme De Antes-Mazaricos)|Picota, A (Mazaricos)|San Cosme De Antes-Mazaricos)|Suevos (Santa Maria De Coiro-Mazaricos)|Vaos, Os (San Tome)
15259	Acea, A (Serres)|Arriba (San Xoan De Serres-Muros)|Baño (Serres)|Boavista (Serres)|Portugalete (San Xoan De Serres-Muros)|Retorta (San Xoan De Serres-Muros)|Serres|Serres (San Xoan)|Sestaio (San Miguel)|Vadernado (San Xoan De Serres-Muros)|Valdexeria (San Xoan De Serres-Muros)
15270	Cee|Cee (Santa Maria )|Escabanas (Santa Maria De Cee-Cee)|Lagarteira (Santa Maria De Cee-Cee)|Son (Sant Maria De Cee-Cee)|Xallas (Santa Maria De Cee-Cee)
15280	Alqueidon|Anxeles, Os (Santa Maria-Brion)|Bastavales (San Xulian)|Chave De Ponte (San Xulian De Bastavales-Brion)|Guitiande (Santa Maria Dos Anxeles-Brion)|Sabaxans ( San Xulian De Bastavales-Brion)|San Salvador De Bastavales (San Salvador)|Soigrexa (Santa Maria Dos Anxeles-Brion)|Tremo, O (Santa Maria Dos Anxeles-Brion)
15281	Macedos (Santa Maria De Urdilde-Rois)|Urdilde (Santa Maria)
15282	Ermedelo (San Martiño)
15285	Cornada (Brion)|Luaña (Brion)|Mouretans (Viceso-Brion)|Ons (Brion)|Viceso (Brion)
15286	Cando (San Tirso)|Cuns (San Tirso De Cando-Outes)|Ponte Nafonso, A (San Tirso De Cando-Outes)|Toxeira, A (San Tirso De Cando-Outes)
15287	Bendimon (San Xoan De Roo-Outes)|Brion De Abaixo (San Xoan De Roo-Outes)|Brion De Arriba (San Xoan De Roo-Outes)|Cruceiro De Roo, O (San Xoan De Roo-Outes)|Rates (San Cosme De San Cosme De Outeiro-Outes)|Roo (San Xoan)|Roo De Abaixo (San Xoan De Roo-Outes)|San Cosme De Outeiro (San Cosme)|Serantes (San Cosme De San Cosme De Outeiro-Outes)|Tavilo (San Cosme De San Cosme De Outeiro-Outes)|Vara (San Cosme De San Cosme De Outeiro-Outes)
15288	Braño (Sabardes)|Catasueiro (San Xoan De Freixo De Sabardes, O-Outes)|Freixo De Sabardes (San Xoan)|Mosteiro (San Xoan De Freixo De Sabardes, O-Outes)|Ribeira Do Freixo, A (Sabardes)|Siavo
15290	Abelleira (San Estevo)|Bornalle (Santo Estevo De Abelleira-Muros)|Tal (Santiago)|Tal De Abaixo|Tal De Arriba|Torea (San Xian)
15291	Louro|Louro (Santiago)|San Francisco (Santiago De Louro-Muros)
15292	Agrobello (Santa Maria De Lira-Carnota)|Carballal (Santa Maria De Lira-Carnota)|Gandara (San Martiño De Lariño-Carnota)|Lariño|Lariño (San Martiño)|Lira (Santa Maria)|Miñarzo|Sofan (Santa Maria De Lira-Carnota)
15293	Carnota|Mallou (Santa Comba De Santa Comba De Carnota-Carnota)|Pedrafigueira|San Mamede De Carnota (San Mamede)|Santa Comba De Carnota (Santa Comba)
15295	Caldebarcos|Canedo (San Mamede De San Mamede De Carnota-Carnota)|Panches (San Mamede De San Mamede De Carnota-Carnota)|Parada (San Mamede De San Mamede De Carnota-Carnota)|Piñeiros (San Mamede De San Mamede De Carnota-Carnota)|Quilmas|Quilmas (San Clemente De O Pindo-Carnota)
15296	Pindo, O|Pindo, O (San Clemente)
15297	Ezaro, O|Ezaro, O (Santa Uxia)
15298	Ameixenda, A (Santiago)|Gures (Santiago De Ameixenda, A-Cee)|Igrexa, A (Ameixenda-Cee)|Lamas, As (Ameixenda-Cee)
15299	Brens (Santa Baia)|Camiños Chans, Os|Fadibon (Santa Baia De Brens-Cee)|Grixa, A (Santa Baia De Brens-Cee)|Pontella, A (Santa Baia De Brens-Cee)|Raso (Brens)
15300	Betanzos
15310	Curtis|Curtis (Santaia)|Curtis-Estacion|Foxado (Santa Maria)|Santa Maria De Lurdes (Santa Maria)|Teixeiro (Curtis)
15313	Ambroa (San Tiso)|Chao Da Viña, O (Santaia De A Viña-Irixoa|Churio (San Martin)|Coruxou (San Salvador)|Irixoa|Irixoa (San Lourenzo)|Mantaras (Santa Maria)|Veris (Santa Maria)|Viña, A (Irixoa)|Viña, A (Santaia)
15314	Adragonte (Santiago)|Areas (Santiago De Adragonte-Paderne)|Obre (Santo Andre)|Paderne|Paderne (San Xoan)|Quintas (Santo Estevo)|San Xulian De Vigo (San Xulian)|Vilamourel (San Xoan)
15315	Alto De Xestoso, O (Santa Maria)|Gestoso (San Pedro Del Valle)|Gestoso (Santa Maria)|Monfero (Santa Juliana)|Santa Xia De Monfero (Santa Xia)|Val De Xestoso, O (San Pedro)
15316	Armea (San Vicente)|Coiros|Coiros (San Xulian)|Coiros De Abajo (San Xulian De Coiros-Coiros)|Coiros De Arriba (San Xulian De Coiros-Coiros)|Colantres (San Salvador)|Combarro (Santiago De Santiago De Ois-Coiros)|Figueiras (Santa Mariña De Santa Mariña De Lesa-Coiros)|Queiris (San Salvador De Colantres-Coiros)|Santa Maria De Ois (Santa Maria)|Santa Mariña De Lesa (Santa Mariña)|Santiago De Ois (Santiago)
15317	Aranga|Aranga (San Paio)|Cambas (San Pedro)|Castellana (San Lourenzo De Vilarraso-Aranga)|Feas (San Pedro-Aranga)|Muniferral (San Cristovo)|San Vicente De Fervenzas (San Vicente)|Villarraso (San Lourenzo)
15318	Abegondo|Abegondo (Santa Eulalia)|Bordel (Santa Maria De Sarandon-Abegondo)|Bordelle (Santa Maria De Sarandon-Abegondo)|Cabanas (San Xian)|Calle (Santa Maria De Sarandon-Abegondo)|Cerneda (San Salvador)|Cos (San Esteban)|Crendes (San Pedro)|Cullergondo (Santa Maria)|Figueroa (San Miguel)|Folgoso (Santa Dorotea)|Lamansian (San Tirso De Mabegondo-Abegondo)|Leiro (Santaia)|Limiñon (San Salvador)|Mabegondo (San Tirso)|Meangos (Santiago)|Monte (San Tirso De Mabegondo-Abegondo)|Montouto (Santa Cristina)|Orto (San Martiño)|Penedo (San Tirso De Mabegondo-Abegondo)|Presedo (Santa Maria)|San Marco (Abegondo)|Sarandos (Santa Maria)|Trasiglesia (San Pedro De Crendes-Abegondo)|Vilacoba (Santo Tome)|Vilar (Crendes)|Vilar (San Pedro De Crendes-Abegondo)|Vios (San Salvador)|Vizoño (San Pedro)
15319	Brabio (San Martiño)|Casas Novas (Santiago De Requian-Betanzos)|Castro De San Fiz O (Pontellas)|Chantada (Santa Maria De Souto-Paderne)|Condos (San Salvador De Vilouzas-Paderne)|Cortiñan (Santa Maria)|Coto (San Martiño De Brabio-Betanzos)|Fraga, A (Cortiñan)|Guiliade (Piadela)|Infesta, A (Requian)|Insua (San Pantaleon De San Pantaleon Das Viñas-Paderne)|Insua, A (Viñas-Paderne)|Montecelo (San Pantaleon De San Pantaleon Das Viñas-Paderne)|Montellos (Piadela)|Outeiro, O (Santa Maria De Cortiñan-Bergondo)|Piadela (Santo Estevo)|Pontellas (Santa Maria)|Porto (San Pantaleon De San Pantaleon Das Viñas-Paderne)|Requian (Santiago)|San Pantaleon Das Viñas (San Pantaleon)|San Pedro Das Viñas (San Pedro)|San Victorio (San Fiz De Vixoi-Bergondo)|Souto (Santa Maria)|Tercio (San Salvador De Vilouzas-Paderne)|Tiobre (San Martiño)|Trasdoval (San Fiz De Vixoi-Berrgondo)|Vilouzas (San Salvador)|Vixoi (San Fiz)|Xanrozo (Santiago De Rquian-Betanzos)
15320	Pontes De Garcia Rodriguez, As|Pontes De Garcia Rodriguez, As (Santa Maria)|Pontes, As (Pontes De Garcia Rodriguez)|Pontoibo (Santa Maria De Pontes De Garcia Rodriguez,As)
15324	Seoane (San Xoan)
15325	Faeira, A (San Pedro)|Goente (San Martiño)|San Pedro De Eume (San Pedro)
15326	Deveso, O (Santa Maria)|Freixo, O (San Xoan)|Somede (San Mamede)
15327	Aparral, O (Santa Maria)
15328	Saa (Santa Maria De Vilavella-As Pontes De Garcia Rodriguez)|Vilavella (Santa Maria)
15329	Bermui (Santiago)|Campo (Santa Maria De Ribadeume-As Pontes De Garcia Rodriguez)|Ribadeume (Santa Maria)
15330	Ortigueira|Ortigueira (Santa Marta)
15332	Barbos (San Xulian)|Cuiña (Santiago)|Devesos (San Sebastian)|Freires, Os (San Paulo)|Luama (San Martiño)|Luia (Santa Maria)|Mosteiro, O (San Xoan)|San Antonio (San Xulian De Barbos-Ortigueira)|Santa Ana (Luia)|Santiago (Ortigueira)
15337	Bares|Bares (Santa Maria)|Mañon|Mogor (Santa Maria)|Porto Do Barqueiro|Ribeiras Do Sor, As (San Cristovo)
15338	Ermo, O (San Xulian)|Insua (San Xoan)|Neves, As (Santa Maria)|Nogueirido, O (Senra)|Senra (San Xulian)
15339	Caridad, A (San Xulian De Celtigos-Ortigueira)|Celtigos (San Xulian) (Ortigueira)|Couzadoiro (San Cristovo)|Espasante (San Xoan)|Grañas Do Sor, As (San Mamede)|Ladrido (Santalla)|Loiba (San Xulian)|Mañon (Santa Maria)|Porto De Espasante, O|San Felipe (Celtigos-Ortigueira)|San Juan|San Salvador De Couzadoiro (San Salvador)|San Xulian (Loiba)|Santa Eulalia
15340	Mera De Abaixo (Santiago)|Ponte Mera, A
15347	Cervo (Santalla)
15349	Mera De Arriba (Santa Maria)
15350	Cedeira
15357	Cedeira (Santa Maria Do Mar)
15358	Carballeira (Regoa)|Regoa (Santa Maria)|Teixido ( Santo Andre)
15359	Montoxo (San Xulian)|Mundin (San Xulian De Montoxo-Cedeira)|Piñeiro (San Cosme)|San Roman Demontoxo (San Roman)
15360	Cariño
15365	Cerca, A Santa Maria De A Pedra-Cariño)|Figueiroa (Santa Maria De A Pedra-Cariño)|Pedra, A (Santa Maria)|Sagron (Santa Maria De A Pedra-Cariño)
15366	Feas (San Pedro-Cariño)|Landoi (Santiago)
15367	Veiga (Ortigueira)|Veiga (Santo Adrao)
15368	San Claudio (Santa Maria)|Santa Maria (San Claudio)
15369	Sismundi (Santo Estevo)
15379	Fisteus (Santa Maria)
15380	Lois|Oza (San Pedro)|Oza Dos Rios
15386	Rodeiro (Santa Maria)
15387	Regueira, A (Santa Maria)
15388	Bandoxa (San Martiño)|Frais (Santo Estevo De Parada-Oza Dos Rios)|Parada (Santo Estevo)|Reboredo (Santiago)|Salto (San Tome)
15389	Callobre (Santa Maria De Cuiña-Oza Dos Rios)|Cis (San Nicolao)|Cuiña (Santa Maria)|Mondoi (Oza Dos Rios)|Porzomillos (San Pedro)|Santa Cruz (Mondoi)|Vilar De Costoia (San Pedro De Porzomillos-Oza Dos Rios)|Vivente (Santo Estevo)
15390	Borrifans (San Pedro)|Bragade (San Mamede)|Filgueira De Barranca ( San Pedro )|Trasanquelos (San Salvador)
15391	Carres (San Vicenzo)|Cesuras|Cutian (Santa Maria)|Dordaño (Santa Maria)|Figueredo (Santa Maria)|Filgueira De Traba (San Miguel)|Loureda (Santo Estevo)|Mandaio (San Xiao)|Paderne (Santiago)|Probaos (Santaia)
15401	Ferrol
15402	Ferrol
15403	Ferrol
15404	Ferrol
15405	Aneiros (Serantes, S. Salvador)|Calvario|Ferrol|Leixa (San Pedro)|Malata, A|Pallota, A|Pazos (Pª San Salvador De Serantes)|Recinto Ferial Ferrol (Fimo)|Santa Cecilia De Trasancos (Santa Cecilia)|Serantellos|Serantes (San Salvador)|Viladoniga|Viladoniga (Serantes)|Vinculeiro
15406	Ferrol
15470	Ferrol
15471	Ferrol
15480	Ferrol
15490	Ferrol
15500	Ameneiral, O (Perlio)|Cadavo (San Salvador De Fene-Fene)|Casanova (San Salvador De Fene-Fene)|Centieiras, As|Chamoso (San Salvador De Fene-Fene)|Chancas (Santo Estevo De Perlio-Fene)|Conces De Baixo|Cruceiro, O (Perlio)|Fene|Fene (San Salvador)|Formosende (San Salvador De Fene-Fene)|Foxas (Fene)|Foxas (San Salvador De Fene-Fene)|Fraga, A (Santo Estevo De Perlio-Fene)|Mundin (Santo Estevo De Perlio-Fene)|Perlio|Perlio (Santo Estevo)|Rua Alta (Santo Estevo De Perlio-Fene)|Rua Alta, A|San Valentin|San Valentin ( San Valentin )|Sartego (San Salvador De Fene-Fene)|Tellado (San Salvador De Fene-Fene)|Torre, A (Perlio)|Torre, A (Santo Estevo De Perlio-Fene)|Vista Alegre (San Salvador De Fene-Fene)
15509	Magalofes (San Xurxo)|Orra (Santa Mariña De Sillobre-Fene)|Pedre (Sillobre)|Sillobre (Santa Mariña)|Torre, A (San Xurxo De Magalofes-Fene)|Vilanova (Santa Mariña De Sillobre-Fene)
15510	Coto (Santa Maria De Neda-Neda)|Medico Cebreiro|Mourela Baixa (Santa Maria De Neda-Neda)|Mourela Do Medio (Santa Maria De Neda-Neda)|Neda|Neda (San Nicolas)|Pazos, Os (Neda)|Poulo (Santa Maria De Neda-Neda)|Santa Maria (Neda)|Santa Maria De Neda (Santa Maria)|Xubia-Casadelos
15520	Armada, A (Maniños)|Chao Da Aldea, O (Maniños)|Maniños (San Salvador)|Pumido (San Salvador De Maniños-Fene)|Ribeira, A (Maniños)
15528	Barallobre (Santiago)|Chousas, As (Santiago De Barrallobre-Fene)|Loira - O Castro (Santiago De Barrallobre-Fene)|Penedo De Arriba|Ramo, O (Santiago De Barrallobre-Fene)|Rego Da Moa (Santiago De Barrallobre-Fene)|Romariz (Santiago De Barrallobre-Fene)|Santiago (Santiago De Barrallobre-Fene)
15530	Cerdido|Cerdido (San Martño)
15540	Calvario (San Mateo De Trasancos-Naron)|Trasancos (San Mateo)|Vilar (San Mateo De Trasancos-Naron)
15541	Baltar (Santa Maria A Maior De Val.O-Naron)|Crucero (Santa Maria A Maior De Val, O-Naron)|Pedreira (Santa Maria A Maior De Val, O-Naron)|Quinta (Santa Maria A Maior De Val, O-Naron)|Santa Margarita (Santa Maria A Maior De Val, O-Naron)|Val, O (Santa Maria A Maior)|Vilacornelle (Santa Maria A Maior De Val, O-Naron)
15542	Loira (San Pedro)
15543	Vilaboa (San Vicente)
15550	Cantodomuro, O (San Vicente De Meiras-Valdoviño)|Carreira, A (Santa Maria De Sequeiro, O-Valdoviño)|Carreira, A (Sequeiro, Stª. Mª.)|Gandara, A (San Vicente De Meiras-Valdoviño)|Meiras (San Vicente)|Montefaro (Meiras)|Montefaro (San Vicente De Meiras-Valdoviño)|Riobo (San Vicente De Meiras-Valdoviño)|Sequeiro, O (Santa Maria)|Taraza
15551	Broño (Santiago De Lago-Valdoviño)|Lago (Santiago)|Outeiro, O (Santiago De Lago-Valdoviño)|Vilar, O (Santiago De Lago-Valdoviño)
15552	Valdoviño|Valdoviño (Santalla)
15553	Pantin (Santiago)
15554	Vilarrube (San Martiño)
15555	Esteiro (San Fiz)
15560	Cornide (Santa Maria De San Sadurniño-San Sadurniño)|Marques De Figueroa, Avenida Do (Santa Maria De San Sadurniño)|Outeiro (Santa Maria De San Sadurniño-San Sadurniño)|San Sadurniño|San Sadurniño (Santa Maria)
15561	Santa Mariña Do Monte (Santa Mariña)
15562	Bardaos (Santa Maria-San Sadurniño)|Lamas (San Xiao)
15563	Abade (Santiago)|Moeche|San Ramon (San Xoan De San Xoan De Moeche-Moeche)|San Xoan De Moeche (San Xoan)|San Xurxo De Moeche (San Xurxo)
15564	Labacengos (Santa Maria)|Santa Cruz De Moeche (Santa Cruz)
15565	Iglesia, A Santiago Sere De Somozas, As-Somozas, As|Poligono Industrial As Somozas|Somozas, As (Santiago Sere)
15566	Enchousas, As (San Pedro)
15567	Seixas (Santa Maria)
15568	Recemel (Santa Maria)|Somozas, As
15569	Barqueira, A ( Santo Antonio)|Casas, Os (San Xoan)|Felgosas (Santo Antonio De Barqueira, A-Cerdido|Porto (Santo Antonio De Barqueira, A-Cerdido)
15570	Naron|Poligono Industrial A Gandara|Poligono Industrial As Lagoas/Rio Do Pozo
15572	Naron
15573	Poligono Rio Do Pozo
15576	Naraio (Santa Maria)
15577	Anca (San Pedro)|Roxal, O
15578	Agrande (Santa Maria De Castro-Naron)|Castro (Santa Maria-Naron)|Fraga (San Xiao De Naron-Naron)|Naron (San Xiao)|Nelle (Santa Maria De Castro-Naron)|Pena De Embade (Santa Maria De Castro-Naron)|Sequeiro (San Xiao De Naron-Naron)|Vicas (San Xiao De Naron-Naron)
15579	Roxal, O|Viladonelle (Santo Andre)
15580	Igrexafeita (Santa Maria)
15582	Espiñaredo (Santa Maria)
15590	Brion (Ferrol)|Cabana, A (Ferrol)|Cabana, A (Santo Antonio)|Ferrol|Graña, A (Ferrol)|Graña, A (Santa Rosa De Viterbo)
15591	Brion (Santa Maria)|Corras, Os (Serantes-Ferrol)|Ferrol|Montecoruto|Montecuruto (Santo Antonio Da Cabana, A-Ferrol
15592	Ferrol|San Xurxo Da Marina (San Xurxo)|Vila Da Area|Vila Da Eirexa (A Mariña)
15593	Doniños (San Roman)|Ferrol|Fonta (Pª San Roman De Doniños)|Valon
15594	Aldea (Pª San Martiño De Covas)|Covarradeiras (Pª San Martiño De Covas)|Covas (San Martiño)|Esmelle (San Xoan)|Ferrol|Pedreira, A (Covas-Ferrol)|Ragon|Rioxunto (Pª San Xoan Esmelle)
15595	Bustelo (Mandia-Ferrol)|Cha (Pª Santa Uxia De Mandia)|Ferrol|Mandia (Santa Uxia)|Marmancon (San Pedro)|Taboada (Mandia)|Vilela (Pª Santa Uxia De Mandia)
15596	Placente (Santo Estevo De Sedes-Naron)|Sedes (Santo Estevo)
15597	Doso (San Lourenzo)|Pedroso (San Salvador)
15598	Ferreira (San Paio)
15600	Pontedeume|Pontedeume (Santiago)
15607	Boebre (Pontedeume)|Boebre (Santiago)|Caldagueiro (Santa Maria De Centroña-Pontedeume)|Centroña (Santa Maria)|Vizus (Santa Maria De Centroña-Pontedeume)
15608	Fondal (Perbes)|Hombre (Vilanova-Miño)|Perbes (San Pedro)|Sambollo (San Pedro De Perbes-Miño)|Vilanova (San Xoan)
15609	Cabria Nova (Pontedeume)|Cabria Nova (Santa Maria De Ombre-Pontedeume)|Chao De Ombre (Santa Maria De Ombre-Pontedeume)|Cruz Do Cabildo, A (San Cosme De Nogueirosa-Pontedeume)|Esteiro (Pontedeume)|Nogueirosa (Pontedeume)|Ombre (Pontedeume)|Taboada (Santa Mariña)
15611	Iris (Santo Estevo)|Santa Cruz Do Salto (Santa Cruz)
15612	Laraxe (San Mamede)|Peon (San Mamede De Laraxe-Cabanas)|Pereiro (San Mamede De Laraxe-Cabanas)|Regoela (San Vicente)|Soaserra (Santa Olaia)|Torre, La (San Mamede De Laraxe-Cabanas)
15613	Caaveiro (San Boulo)|Cabalar (Santa Maria)|Capela, A|Capela, A (Santiago)|Cruceiro, O (Caaveiro)|Neves, As
15614	Andrade (San Martiño)|Barro, O (San Miguel De Breamo-Pontedeume)|Breamo (San Miguel)|Campo Longo (Vilar-Pontedeume)|Chao De Vilar|Fontenova, A|Pazos|Regueira, A (San Martiño De Andrade-Pontedeume)|Vilar (San Pedro-Pontedeume)
15615	Doroña (Santa Maria)
15616	Grandal (San Pedro)
15617	Prada (Monfero)|Prada (San Xurxo De Queixeiro-Monfero)|Queixeiro (San Xurxo)|Vilacha (Santa Maria)
15619	Monfero (San Felix)|San Fiz De Monfero ( San Fiz)
15620	Mugardos|Mugardos (San Xulian)|Pedreira, A (Meha)
15621	Cabanas|Cabanas (Santo Andre)
15622	Chao Da Aldea (San Martiño De San Martiño De Porto-Cabanas|Magdalena (San Martiño De San Martiño De Porto-Cabanas)|San Martiño De Porto Porto (San Martin)|Torre, A (San Martiño De San Martiño De Porto-Cabanas)|Val, O (Porto)
15623	Caamouco (San Vicente)|Redes
15624	Ares|Ares (San Xose)|Lubre (San Xose De Ares-Ares)|Pedros (San Xose De Ares-Ares)
15625	Cervas (San Pedro)|Chanteiro
15626	Franza|Franza (Santiago)|Mea (San Vicente)|Rilo (San Vicente De Mea-Mugardos)|Seixo, O (Franza)
15627	Cal, O (Limodre)|Camino Grande, O|Gallada De Piñeiro|Limodre (Santa Eulalia)|Piñeiro (San Xoan)
15630	Miño|Miño (Santa Maria)|Ponte Do Porco (Santa Maria De Miño-Miño)|Sombreu
15635	Bemantes (Santo Tome)|Callobre (San Xoan)|Chao, O (Bemantes)|Retriz
15637	Vilarmaior|Vilarmaior (San Pedro)
15638	Goimil (San Cristobal)|Torres (San Xorxe)|Villamateo (Santiago)
15639	Bañobre|Carantoña (San Xulian)|Castro (Santa Maria-Miño)|Leiro (San Salvador)
15640	Baldomir (Guisamo)|Brea A (Guisamo)|Guisamo (Santa Maria)|San Paio (Santa Maria De Guisamo-Bergondo)|Sobre A Igrexa|Vilar, O (Santa Maria De Guisamo-Bergondo)
15650	Cecebre (San Salvador)|Frais (Cecebre, Cambre) (Lugar)|Frais (San Salvador De Cecebre-Cambre)|Lendoiro|Poligono Industrial Espiritu Santo|Quintan (Cecebre, Cambre) (Lugar)|Quintan (San Salvador De Cecebre-Cambre)
15656	Budian (Santa Maria De Gandara-Zas)|Gandara (Santa Maria)|Sisto, O (Santa Maria De Gandara-Zas)
15659	Brexo (San Paio)|Brexo-Lema|Bribes (San Cibran )|Nebrixe (Bribes, Cambre) (Lugar)|Nebrixe (San Cibran De Bribes-Cambre)|Peiraio|Vigo (Santa Maria)
15660	Barcala, A (Cambre)|Cambre|Cambre (Santa Maria)|Meixigo
15668	Fontenla, A (Pravio, Cambre) (Lugar)|Fontenla, A (San Xoan De Pravio-Cambre)|Pombo, O (Pravio, Cambre) (Lugar)|Pombo, O (San Xoan De Pravio-Cambre)|Pravio (San Xoan)|San Bartolomeu (Pravio, Cambre) (Lugar)|San Bartolomeu (San Xoan De Pravio-Cambre)
15669	Andeiro (San Martiño)|Cela (San Xulian)|Meixigo (San Lourenzo)|Patiña, A (Cela, Cambre) (Lugar)|Patiña, A (San Xulian De Cela-Cambre)
15670	Acea De Ama (O Burgo)|Burgo, O ( O Burgo)|Burgo, O (Santiago)
15679	Graxal, O|Temple, O|Temple, O (Santa Maria)
15680	Casillas (Santa Maria De Ordes-Ordes)|Casillas, As|Ordes|Poligono Industrial Ordes
15683	Bedrobe (San Xian De Cabaleiros-Tordoia)|Cabaleiros (San Xian)|Pontepedra|Tordoia|Tordoia (San Xoan)|Vilarchan (San Xian De Cabaleiros-Tordoia)
15684	Andoio (San Mamede)|Anxeriz (Santa Mariña)|Bardaos (Santa Maria-Tordoia)|Barral (Santa Maria De Bardaos-Tordoia)|Brandoñas (Sanmta Mariña De Anxeriz-Tordoia)|Carballal (San Cibran De Vila Do Abade, A-Tordoia)|Carballal (Santa Maria De Castenda Da Torre-Tordoia)|Castenda Da Torre (Santa Maria)|Codesal (San Cibran De Vila Do Abade, A-Tordoia)|Gorgullos (Santaia)|Igrexa (San Cibran De Vila Do Abade,A--Tordoia)|Lesta (Santo Andre)|Numide (Santiago)|Pazo (Santa Mariña De Anxeriz-Tordoia)|Peton (Santa Maria De Bardaos-Tordoia)|Piñeiro (San Cibran De Vila Do Abade,A-Tordoia)|Portociños (Santaia De Gorgullos-Tordoia)|Tarroeira (Santa Maria De Castenda Da  Torre-Tordoia)|Vila De Abade, A (San Cibran)|Vilar (Santa Maria De Bardaos-Tordoia)
15685	Abella (Santo Estevo)|Albixoi (Santa Marina)|Ardemil (San Pedro)|Barbeiros (Santa Maria)|Bascoi (Santiago)|Bruma (San Lourenzo)|Cabrui (San Martiño)|Castro (San Sebastian)|Cumbraos (Santa Maria)|Frades (San Martiño)|Iglesia, A (Mesia)|Iglesia, A (San Cristovo De Mesia-Mesia)|Lanza (San Mamede)|Mesia|Mesia (San Cristovo)|Meson Do Vento, O|Mesos (San Salvador)|Olas (San Lourenzo)|Papucin (Santa Maria)|Soutelo (Olas)|Soutelo (San Lourenzo De Olas-Mesia)|Taberna (Santo Estevo De Abella-Frades)|Xanceda (San Salvador)
15686	Aiazo (San Pedro)|Aña (Santa Maria)|Benza (San Pedro)|Boado (Santiago)|Brea, A (Benza)|Celtigos (San Xulian) (Frades)|Frades|Gafoi (Santa Mariña)|Galegos (San Martiño)|Ledoira (San Martiño)|Lestrove (San Pedro De Benza -Trazo)|Moar (Santaia)|Monzo (San Martiño)|Noia, A (San Cristovo De Xavestre-Trazo)|Oa (San Cristovo De Xavestre-Trazo)|Pedregueira, A (San Martiño De Monzo-Trazo)|Ponte Carreira (Gafoi)|Restande (Santa Maria)|Tarrio (Santa Maria De Restande-Trazo)|Vitre (San Xoan)|Xavestre (San Cristovo)
15687	Berreo (San Mamede)|Buscas (San Paio)|Calle (San Xulian De Poulo-Ordes)|Campo (San Xoan)|Castelo (Santa Maria)|Chaian (Santa Maria)|Morlan (Santa Maria)|Polveira, A (Chaian)|Poulo (San Xulian)|Torre, A (Santa Maria De Castelo-Trazo)|Trazo|Trazo (Santa Maria)|Viaño Pequeño (San Xoan De Campo-Trazo)|Vilouchada (San Vicenzo)
15688	Anxeles, Os (San Mamede)|Barciela, A (Santo Andre)|Bayuca (Pª Santa Eulalia De Oroso)|Bayuca (Santa Eulalia De Senra-Oroso)|Cachopal (Pª San Mamede)|Calvente (San Xoan)|Carballal (Pª San Martiño)|Carballos (Pª Santa Maria Deixebre-Oroso)|Cardama (Pª Santa Maria De Oroso)|Cardama (Santa Maria De Oroso)|Cesar (Santa Maria)|Deixebre (Santa Maria)|Empalme (Santo Estevo De Trasmonte-Oroso)|Empalme, O (Trasmonte-Oroso)|Estacion Oroso (Oroso)|Gandara, A (San Miguel)|Igrexa (Parroquia San Martiño-Oroso)|Marzoa (San Martiño)|Oroso (San Martiño)|Pasarelos (San Roman)|Piñeiron|Senra (Santa Eulalia)|Sigüeiro (Santo Andre Da Barciela-Santiago)|Trasmonte (Santo Estevo)|Valverde (Pª Villarromaris De Oroso)|Valverde (San Tome De Vilarromaris-Oroso)|Vilanova (San Martiño De Oroso-Oroso)|Villarromaris (Parroquia Santo Tomas-Oroso)
15689	Balado (Santa Maria De Ordes-Ordes)|Bean (Santa Maria)|Casal (Santa Maria De Ordes-Ordes)|Castrelos (Santa Maria De Leira-Ordes)|Espenica (Santa Maria De Ordes-Ordes)|Fosado (Santa Cruz De Montaos-Ordes)|Guindiboo (Santa Cruz De Montaos-Ordes)|Iglesia, A (San Martiño De Visantoña-Mesia)|Iglesia, A (Visantoña-Mesia)|Leira (Santa Maria)|Leobalde (San Cristovo)|Mercurin (San Clemente)|Merelle (Santa Maria De Ordes-Ordes)|Ordes (Santa Maria-Ordes)|Parada (Santa Maria)|Pereira (Santaia)|Queis (Santa Cruz De Montaos-Ordes)|Reboredo (Santa Maria De Ordes-Ordes)|Santa Cruz De Montaos (Santa Cruz)|Vilamaior (Santiago)|Visantoña (San Martiño)
15690	Campo De Golf (Moras-Arteixo)|Ervedins (Arteixo)|Foxo (Arteixo)|Igrexario (Arteixo)|Loureda (Santa Maria)|Monte Das Arcas (Arteixo)|Moras (Arteixo)|Ponte Do Ba (Arteixo)|Uxes (Arteixo)|Valle (Arteixo)
15701	Santiago De Compostela
15702	Santiago De Compostela
15703	Santiago De Compostela
15704	Santiago De Compostela
15705	Santiago De Compostela
15706	Santiago De Compostela
15707	Santiago De Compostela
15770	Santiago De Compostela
15771	Santiago De Compostela
15780	Santiago De Compostela
15781	Santiago De Compostela
15782	Santiago De Compostela
15800	Melide|Melide (San Pedro)|Poligono Industrial Madanela
15805	Agron ( Santa Eulalia)|Baltar (Melide)|Barreiro, O (San Mamede) Melide|Golan (Melide)|Grobas (Melide)|Maceda (San Pedro) Melide|Orois (Melide)|Pedrouzos (Santa Mariña) Melide|Vitiriz (San Vicente) Melide|Xubial (Santiago) Melide|Zas De Rei (San Xiao) Melide
15806	Capela, A (Santa Maria) Toques|Mangoeiro (Santo Tome) Toques|Oleiros (Toques)|Ordes (Santa Maria-Melide) Toques|Paradela (San Paio) Toques|San Martiño De Oleiros (San Martiño) Toques|San Xiao Do Monte (San Xiao) Toques|Santa Eufemia Do Monte ( Santa Eufemia) Toques|Santa Mariña De Brañas (Santa Mariña) Toques|Toques|Vilamor (San Estevo) Toques|Vilouriz (Santiago) Toques
15807	Armental (San Martiño)|Barbeito (San Salvador)|Cruce Sesmonde (San Salvador De Barbeito-Vilasantar)|Foro (San Pedro De Presaras-Vilasantar)|Mezonzo (Santa Maria)|Presaras (San Pedro)|San Vicezo De Curtis (San Vicenzo)|Vilariño (Santa Maria)|Vilasantar|Vilasantar (Santiago)
15808	Barazon (Santa Maria) Santiso|Beigondo (San Cosme) Santiso|Belmil (San Pedro) Santiso|Liñares (Santiago) Santiso|Mourazos (San Xurxo) Santiso|Niñodaguia (San Paio) Santiso|Novela (Santa Maria) Santiso|Pezobre (San Cristovo) Santiso|Pezobres (San Estevo) Santiso|Ponte Arcediago, A (San Xoan) Santiso|Rairiz (Santa Eulalia)|Ribadulla (San Vicenzo) Santiso|San Roman (San Pedro) Santiso|Santiso|Santiso (Santa Maria)|Serantes (Santaia) Santiso|Vimianzo (Santa Maria) Santiso|Visantoña (Santiso)
15809	Abeancos (San Salvador)|Anxeles, Os (Santa Maria-Melide) Melide|Campos (Santa Maria) Melide|Castro (Santo Tome-Melide)|Folladela (San Pedro) Melide|Forte Novo (Santa Maria De Anxeles, Os-Melide|Furelos (San Xoan) Melide|Gondollin (San Martiño) Melide|Leboreiro, O (Santa Maria) Melide|Meire, O (San Pedro ) Melide|Moldes (Melide)|Priorada (San Xoan De Sancibrao-Melide)|San Cibrao (San Xoan) Melide|San Cosme De Abeancos (San Cosme) Melide|Santa Maria De Melide (Santa Maria) Melide|Varelas, As (San Martiño) Melide
15810	Arzua|Arzua (Santiago)|Poligono Industrial Arzua
15813	Porta, A (San Pedro)|Sobrado|Sobrado (Porta)
15814	Carelle (San Lourenzo)|Folgoso (Santa Cristina)|Nogueira (San Xurxo)
15815	Ciadella, A (Santa Maria)|Codesoso (San Miguel)|Cumbraos (San Xiao)|Grixalba (San Xiao)|Pousada (San Mamede)|Roade (Santo Andre)
15816	Andavao (San Martiño)|Anxeles, Os (Santa Maria-Boimorto)|Corneda (San Pedro)|Dormea (San Cristovo)|Rodieiros (San Simon)
15817	Boimil (San Miguel)|Boimorto (Santiago)|Brates (San Pedro)|Mercurin (San Xoan)|Sendelle (Santa Maria)
15818	Arceo|Arceo (San Vicenzo)|Boimorto|Buazo (Santa Maria)|Cardeiro (San Pedro)
15819	Arzua (Santa Maria )|Brandeso (San Lourenzo)|Branza (Santa Locaia)|Burres (San Vicenzo)|Campo (Santo Estevo)|Castañeda A (Santa Maria)|Dodro (Santa Maria) (Arzua)|Dombodan (San Cristovo)|Figueroa (San Paio)|Lema (San Pedro)|Maroxo (Santa Maria)|Mella, A (San Pedro)|Oins (San Cosme)|Pantiñobre (San Estevo)|Rendal (Santa Maria)|San Martiño De Calvos De Sobrecamiño (San Martiño)|Tronceda (Santa Maria)|Viladavil (Santa Maria)|Villantime (San Pedro)|Viños (San Pedro)
15820	Aeropuerto De A Lavacolla|Bando (Santa Eulalia)|Carballal, O (San Xulian)|Esquipa, A (San Paio De Sabugueira-Santiago)|Lavacolla, A|Mourentan (San Paio De Sabugueira-Santiago)|Sabugueira (San Paio)|San Marcos
15821	Arca (Santa Eulalia)|Budiño (Santa Maria)|Castrofeito (Santa Maria)|Pazo, O (Santa Maria De Castrofeito- O Pino)|Pazos De Arriba (Santa Maria De Budiño- O Pino)|Pedrouzo, O (Arca)|Pereira (San Miguel)|Pino, O|Rua, A (Santaia De Arca- O Pino)|Santiso (Santa Maria De Castrofeito-O Pino)
15822	Bendaña (Santa Maria)|Enquerentes (San Miguel)|Fao (Santa Uxia)|Fonte Diaz|Fontes Rosas (San Xoan)|Foxas (San Breixo)|Novefontes (Santiago)|Obra (San Breixo De Foxas-Touro)|Prevediños (Santiago)|Quintas (Santiago De Prevediños-Touro)|San Miguel De Vilar (San Miguel)|San Pedro De Riveira (San Pedro)|Touro|Touro (San Xoan)
15823	Bama (San Vicenzo)|Cabo (San Miguel De Cerceda-O Pino)|Castelo (San Xian De Cebrerio-O Pino)|Castro (San Miguel De Cerceda-O Pino)|Cebreiro (San Xiao)|Cerceda (San Miguel)|Goleta (Santa Maria De Loxo-Touro)|Loxo (Santa Maria)|Pino, O (San Vicenzo)
15824	Andeade (Santiago)|Beseño (San Cristovo)|Cimadevila (San Mamede De Ferreiros-O Pino)|Ferreiros (San Breixo)|Muiña (San Fiz De Quion-Touro)|Quion (San Fiz)|Salceda (San Breixo De Ferreiros-O Pino)|San Mamede De Ferreiros (San Mamede)
15825	Couto Pequeño (Santo Estevo De Medin-O Pino)|Medin (Santo Esteban)|Pastor (San Lourenzo)
15826	Boente (Santiago)
15828	Calvos De Socamiño (San Martiño)|Circes (Santa Mariña)|Cornado (Santiso)|Turces (Santa Maria)
15830	Negreira|Negreira (Negreira)
15837	Barbeira (San Martiño De Fontecada-Santa Comba)|Fontecada (San Martiño)|Pereira, A (Santo Andre)
15838	Alvite (Negreira)|Aro (Negreira)|Broño (Negreira)|Bugallido (Negreira)|Campelo (Negreira)|Campolongo (Negreira)|Landeira (Negreira)|Marcelle (Landeira-Negreira)|Pena, A (Negreira)|Pesadoira (Alvite-Negreira)|Xallas (Negreira)|Zas (Negreira)
15839	Arzon (Negreira)|Cabanas (A Baña)|Chancela (Logrosa - Negreira)|Fiopans (A Baña)|Gonte (Negreira)|Lañas (A Baña)|Liñaio (Negreira)|Logrosa (Negreira)|Lueiro (Negreira)|Portor (Negreira)|Troitosende (A Baña)
15840	Randufe (San Pedro De Santa Comba-Santa Comba)|Santa Comba (Santa Comba)
15841	Mallon (San Cristovo)|San Cristovo (San Cristovo De Mallon-Santa Comba)|Santa Comba|Santa Comba (San Pedro)|Truebe (San Cristovo De Mallon-Santa Comba)
15845	Aranton (San Vicente)|Cicere (San Pedro)|Grixoa (San Xoan)|Mallon (San Pedro De Cicere-Santa Comba)|Rebordelos (San Pedro De Cicere-Santa Comba)|Vilar De Celtigos
15846	Alon (Santa Maria)|Castro, O (San Fins De Freixeiro-Santa Comba)|Couto, O (Santa Maria De Alon-Santa Comba)|Esmorode (Santa Maria De Alon-Santa Comba)|Freixeiro (San Fins)|Illa, A (San Fins De Freixeiro-Santa Comba)|Vilarnovo (San Fins De Freixeiro-Santa Comba)
15847	Bazar (San Mamede)|Pereira (Santa Maria De Vilamaior-Santa Comba)|Sabaceda (San Mameme De Bazar-Santa Comba)|Vilamaior (Santa Maria)
15848	Boaña De Arriba (San Pedro De Xallas De Castriz-Santa Comba)|Frieiro (San Pedro De Xallas De Castriz-Santa Comba)|Padreiro (San Pedro De Xallas De Castriz-Santa Comba)|Xallas De Castriz (San Pedro)
15850	Zas (Santo Andre)|Zas (Zas)
15851	Allo, O (San Pedro)|Andragalla, A (Santa Maria De Lamas-Zas)|Lamas (Santa Maria) (Zas)|San Cremenzo De Pazos|San Cremenzo De Pazos (San Cremenzo)
15855	Carreira (Santiago)|Mira (Santa Maria)
15856	Loroño (Santiago)|Romelle (Santiago De Loroño-Zas)|Santo Adrian De Castro
15857	Langueiron (San Martiño De Meanos-Zas)|Meanos|San Martiño De Meanos (San Martiño)|Vila (San Martiño De Meanos-Zas)
15858	Muiño (San Tirso)
15859	Brandomil (San Pedro)|Brandoñas (Santa Maria)|Pudenza (San Pedro De Brandomil-Zas)|Santa Sia De Roma ( Santa Sia )
15860	Busto, O (Santa Sabiña)|Grixoa De Esternande (Santa Maria)|Guldriz (San Xulian De Santa Sabiña-Santa Comba)|Montouto (Santa Maria)|Mourelle (Santa Maria De Montouto-Santa Comba)|Picotos, Os San Xulian De Santa Sabiña-Santa Comba)|San Salvador De Padreiro (San Salvador)|Santa Sabiña (San Xulian)|Travesas, As (San Xulian De Santa Sabiña-Santa Comba)
15861	Ser (San Pedro)
15862	Ermida, A (A Baña)|Marcelle (A Baña)|Monte (A Baña)|Nanton (Monte - A Baña)|Seilan (Monte - A Baña)|Suevos (A Baña)
15863	Barcala (A Baña)|Barcala (San Cibran - A Baña)|Barro, O (A Baña)|Baña, A (A Baña)|Baña, A (San Vicenzo)|Cobas (Negreira)|Corneira (A Baña)|Ordeste (A Baña)|Riba, A (A Baña)|San Vicente (A Baña)
15864	Agron (San Lourenzo)|Ames|Lens (San Paio)|Trasmonte (Santa Maria)
15865	Boullon (San Miguel)|Brion|Brion (San Fins)|Lamiño (San Fins De Brion-Brion)|Liñares (San Fins De Brion-Brion)|Pedrouzos (San Fins De Brion-Brion)|Tembra (San Miguel De Boullon-Brion)
15866	Ameneiro (San Xoan De Calo-Teo)|Balcaide|Calo (San Xoan-Teo)|Carballal (San Xoan De Calo-Teo)|Casalonga, A|Cesar (San Xoan De Calo-Teo|Cornide (San Xoan De Calo-Teo)|Fixo|Folgueiras (San Xoan De Calo-Teo)|Mouromorto (San Xoan De Calo-Teo)|Oseve (Calo-Teo)|Pedreira (San Xoan De Calo-Teo)|Rua De Francos|San Domingo (San Xoan De Calo Teo)|Sollans|Texexe (San Xoan De Calo-Teo)|Vilar De Calo (San Xoan De Calo-Teo)
15870	Ameixenda (Santa Maria)|Piñeiro (San Mamede)|Tapia (San Cristovo)
15871	Bascuas (San Martiño De Coucieiro-Val Do Dubra)|Coucieiro (San Martiño)|Igrexa, A (San Cosme De Portomeiro-Val Do Dubra)|Paramos (Santa Maria)|Portomeiro (San Cosme)|Portomouro (San Cristovo)|Portomouro (Val Do Dubra)|Vilariño (San Pedro)
15872	Insua (Santa Mariña De San Roman-Val Do Dubra)|San Roman (Santa Mariña)
15873	Bembibre|Bembibre (San Salvador)|Val Do Dubra
15874	Arabexo (Santa Maria)|Boiro (San Vicente De Rial-Val Do Dubra)|Buxan (Santiago)|Campo De Rial (San Vicente De Rial-Val Do Dubra)|Erviñou (San Cristovo)|Niveiro (San Vicente)|Rebordelos (Santa Maria De Arabexo-Val Do Dubra)|Rial (San Vicente)
15880	Galegos|Ponte Ulla, A (Santa Maria Madalena)|San Mamede De Ribadulla (San Mamede)|Santa Cruz De Ribadulla (Santa Cruz)|Tomonde|Vilanova (San Pedro)
15881	Ardesende|Boqueixon|Boqueixon (San Vicente)|Codeso (Santaia)|Forte (San Vicente De Boqueixon-Boqueixon)|Gastrar (Santa Mariña)|Granxa, A (San Lourenzo)|Lamas (Santa Maria) (Boqueixon))|Lestedo|Lestedo (Santa Maria)|Loureda (San Pedro)|Moa (Loureda De San Pedro-Boqueixon)|Rodiño|Rubial (Santa Maria De Lestedo-Boqueixon)|Santaia (Santaia De Codeso-Boqueixon)|Sergude (Boqueixon)|Sergude (San Breixo)|Vigo (Santa Baia)
15882	Camporrapado|Donas (San Pedro)|Ledesma|Ledesma (San Salvador)|Oural (Santa Maria)|Pousada (San Lourenzo)|Sucira (Santa Mariña)
15883	Agoso (Santa Baia De Oza-Teo)|Bustelo (Santa Maria De Luou-Teo)|Cacheiras|Cacheiras (San Simon De Ons)|Cobas (San Simon De Ons-Cacheiras-Teo)|Espasande (Santa Maria De Luou-Teo|Feros (San Simon De Ons Cacheiras-Teo)|Fornelos (San Miguel De Raris-Teo)|Lampai (Santa Maria)|Luci (Santa Mariña)|Luou (Santa Maria)|Oza (Santa Baia)|Pedra (San Xoan De Recesende-Teo)|Penelas (San Simon De Ons-Cacheiras-Teo)|Pite (Santa Mariña De Luci-Teo)|Poboa (San Simon De Ons-Cacheiras-Teo)|Pontevea (San Cristovo De Reis-Teo)|Ramallosa (Santa Mariña De Luci-Teo)|Raris (San Miguel)|Recesende (San Xoan)|Regoufe (Santa Maria De Luou-Teo)|Reis (San Cristovo)|Ribas (Santa Baia De Oza-Teo)|Ribeira (San Cristovo De Reis-Teo)|Ribeira (San Simon De Ons-Cacheiras-Teo)|Sebe (San Simon De Ons-Cacheiras-Teo)|Sisto (San Simon De Ons-Cacheiras-Teo)|Torre (San Simon De Ons-Cacheiras-Teo)|Verxeles, Os (Santa Baia De Oza-Teo)|Vilanova (San Xoan) De Recesende-Teo)
15884	Busto (San Pedro)|Enfesta, A (San Cristovo)|Formaris (San Cristovo De Enfesta A -Santiago)|Marantes (San Vicente)|Nemenzo (Santa Cristina)|Verdia (Santa Mariña)
15885	Avenida Do Mestre Manuel Gomez Lorenzo|Avenida Do Mestre Manuel Gomez Lorenzo (Santa Eulalia De Vedra-Vedra)|Illobre (Santo Andre)|Merin (San Cristovo)|Nande (San Fins De Sales-Vedra)|San Fins De Sales (San Fins)|San Miguel De Sarandon (San Miguel)|San Pedro De Sarandon (San Pedro)|San Xian (Sales)|San Xian (San Xian De Sales-Vedra)|San Xian De Sales (San Xian)|Trobe (Santo Andre)|Vedra|Vedra (Santa Eulalia)
15886	Bamonde (Santa Maria)|Campos (Santa Maria De Teo-Teo)|Teo|Teo (Santa Maria)|Vilariño (San Tome)
15887	Amarelle (Santa Maria De Gonzar-O Pino)|Gonzar (Santa Maria)|Lardeiros (San Xiao)|Rabal De Abaixo (Santa Maria De Gonzar- O Pino)
15888	Sigüeiro (Oroso)|Sigüeiro (San Martiño De Oroso-Oroso)
15890	Granxa De San Lazaro, A|Poligono Industrial Del Tambre (Santiago)|Santiago De Compostela|Son De Abaixo (San Caetano De Santiago-Santiago)
15892	Agra Dos Campos San Martiño De Arins-Santiago)|Arins (San Martiño)|Devesa, A (San Martiño De Arins-Santiago)|Igrexario De Arins, O (San Martiño De Arins-Santiago))|Torre Branca, A (San Martiño De Arins-Santiago)
15893	Aldrei (Santa Maria De Marrozos-Santiago)|Bornais (San Cristovo Do Eixo-Santiago)|Corexo (Santa Maria De Marrozos-Santiago)|Eixo, O (San Cristovo)|Marrozos (Santa Maria)|Piñeiro Do Eixo (San Cristovo Do Eixo-Santiago)|Sisto, O (Santa Maria De Marrozos-Santiago)|Susana (Santa Maria De Marrozos-Santiago)|Veiga, A (San Cristovo Do Eixo-Santiago)
15894	Parque Montouto|San Sadurniño (San Simon De Ons-Cacheiras-Teo)|San Sadurniño (Teo)|Tilos, Os|Tilos, Os (San Francisco De Asis)
15895	Bentin (Santa Maria De Biduido-Ames)|Biduido (Santa Maria)|Biduido De Abaixo (Santa Maria De Biduido-Ames)|Biduido De Arriba (Santa Maria De Biduido-Ames)|Buceleiras (San Pedro De Bugallido-Ames)|Bugallido (San Pedro-Ames)|Costoia (Santa Maria De Biduido-Ames)|Eirapedriña|Firmistans|Framil (Santa Maria De Biduido-Ames)|Guimarans (San Pedro De Bugallido-Ames)|Milladoiro, O|Mimosas, As|Outeiro (San Pedro De Bugallido-Ames)|Poligono Industrial Galanas|Quistilans (San Pedro De Bugallido-Ames)|Raices (Santa Maria De Biduido-Ames)|Tarrio (San Pedro De Bugallido-Ames)
15896	Carballal, O (Santa Maria De Villestro-Santiago)|Fraiz (Santa Maria De Villestro-Santiago)|Portela De Villestro, A ( Santa Maria De Villestro-Santiago)|Quintans De Villestro (Santa Maria De Villestro-Santiago)|Roxos (Santa Maria De Villestro-Santiago)|Silvouta (Santa Maria De Villestro-Santiago)|Vilastrexe (Santa Maria De Villestro-Santiago)|Villestro (Santa Maria)
15897	Barcia, A (San Martiño De Laraño-Santiago)|Codesedas (Santa Maria De Figueiras-Santiago)|Correxins (Santa Maria De Figueiras-Santiago)|Figueiras (Santa Maria)|Laraño (San Martiño)|Pardiñas (San Martiño De Laraño - Santiago)|Paredes De Laraño (San Martiño De Laraño-Santiago)|Santiago De Compostela
15898	Fecha (San Xoan)|Fecha (Santa Cristina)|Grixoa (Santa Maria)|Peregrina, A (Santa Maria)
15899	Curuxeira, A (Santa Maria De Conxo-Santiago)|Porto De Conxo, O (Santa Maria De Conxo-Santiago)|Rocha Vella, A (Santa Maria De Conxo-Santiago)|Santiago De Compostela
15900	Padron
15910	Agronovo (Padron)|Extramundi De Abaixo (Padron)|Extramundi De Arriba (Padron)|Padron (Santiago )|Vilar (Padron)
15911	Cornes (Rois)|Oin (Santa Maria)|Rois|Rois (San Mamede)|Seira (San Lourenzo)
15912	Buxan (San Xoan)|Costa (San Miguel)|Herbogo (San Pedro)|Leroño (Santa Maria)
15913	Augasantas (San Vicente)
15914	Carcacia (San Pedro)|Igrexa,A (Carcacia)
15915	Herbon (Padron)|Morono (Padron)
15916	Lestrove (Dodro)
15917	Iria Flavia (Padron)|Luans (Padron)|Matanza, A (Padron)|Pedreda (Padron)|Porta Dos Mariños (Padron)|Puente-Aldea (Padron)|Quintans (Padron)|Reten (Padron)|Rua, A (Padron)
15920	Barral (Santa Comba De Rianxo-Rianxo)|Cortes, As (Rianxo)|Pazo, O (Rianxo)|Rianxiño|Rianxo|Rianxo (Santa Comba)
15928	Abuin (Santa Maria De Leiro-Rianxo)|Brion (Leiro-Rianxo)|Leiro (Santa Maria)|Raño (Santa Maria De Leiro-Rianxo)|Rial (Leiro-Rianxo)
15930	Boiro
15937	Cures (Santo Andre)|Macenda (San Xoan)|Mieites (Santo Andre De Cures-Boiro)|Moimenta (San Xoan De Macenda-Boiro)
15938	Abanqueiro|Abanqueiro (San Cristovo)|Boiro (Santa Baia)|Boliña (Santa Baia De Boiro-Boiro)|Brion (Santa Baia De Boiro-Boiro)|Comoxo (Santa Baia De Boiro-Boiro)|Coroño (Santa Baia De Boiro-Boiro)|Graso (San Cristovo De Abanqueiro-Boiro)|Igrexa, A (Abanqueiro)|San Martiño (Abanqueiro)|Triñans
15939	Aldea De Arriba (Santa Maria De Castro-Boiro)|Bandalrio (Castro)|Cabo De Cruz Ou Pesqueira, A|Cariño (Castro)|Castro (Santa Maria-Boiro)|Cesar (Santa Maria De Castro-Boiro)|Esteiro (Castro-Boiro)|Pesqueira, A Ou Cabo De Cruz
15940	Pobra Do Caramiñal|Pobra Do Caramiñal, A|Poligono Industrial A Tomada
15948	Angustia, A (Posmarcos)|Conchido (San Isidro De Posmarcos-Pobra Do Caramiñal, A)|Crocha De Levante (San Isidro De Posmarcos-Pobra Do Caramiñal, A)|Crocha De Poniente (San Isidro De Posmarcos-Pobra Do Caramiñal, A)|Leson (Santa Cruz)|Lomba, A|Ponte Barbanza, A (San Isidro De Posmarcos-Pobra Do Caramiñal,A)|Posmarcos (Santo Isidro)|Ribeiriña, A (Posmarcos)|Roupion (Santa Cruz De Leson-Pobra Do Caramiñal,A)|San Lazaro|Virxe Do Monte (Santa Cruz De Leson-Pobra Do Caramiñal, A)
15949	Areos (Santa Maria De Xobre, O Ou Maño-Pobra Do Caramiñal, A)|Camiño Ancho (Santa Maria A Antiga De Caramiñal,O-Pobra Do Caramiñal,A)|Caramiñal, O (Santa Maria A Antiga)|Costa (Santa Maria De Xobre,O Ou Maño-Pobra Do Caramiñal, A)|Mirandela (Santa Maria De Xobre,O Ou Maño-Pobra Do Caramiñal,A)|Xobre, O Ou Maño, O (Santa Maria)
15959	Insuela (Palmeira-Ribeira)|Lombas (Palmeira-Ribeira)|Palmeira (Ribeira)|Saiñas (Palmeira-Ribeira)
15960	Martin (Ribeira)|Poligono Industrial Xaras (Ribeira)|Ribeira|Ribeira (Santa Uxia)|Santa Uxia De Ribeira|Touro (Ribeira)
15965	Aguiño (Ribeira)|Cerca, A (Aguiño-Ribeira)|Listres (Aguiño-Ribeira)
15966	Ameixida (Ribeira)|Areeiros, Os (Castiñeiras-Ribeira)|Castiñeiras (Ribeira)|Revolta (Castiñeiras-Ribeira)
15967	Carreira (Ribeira)|Frions (Carreira-Ribeira)|Graña, A (Carreira-Ribeira)|Vilar, O (Carreira-Ribeira)
15968	Cubeliño (Ribeira)|Dean Grande (Ribeira)|Dean Pequeno (Ribeira)
15969	Artes (Ribeira)|Bretal (Olveira-Ribeira)|Corrubedo (Ribeira)|Olveira (Ribeira)|Sirves (Olveira-Ribeira)
15970	Porto Do Son
15978	Campo Do Prado, O (Santa Maria De Nebra-Porto Do Son)|Nebra (Santa Maria)|Noal (San Vicente)
15979	Abuin (San Pedro De Baroña-Porto Do Son)|Baroña (San Pedro)|Orellan (San Pedro De Baroña-Porto Do Son)|Penas (San Pedro De Baroña-Porto Do Son)|Vilar (San Pedro De Baroña-Porto Do Son)
15980	Angueira De Suso (Padron)|Cruces (Padron)|Esclavitud (Padron)|Francelos (Rois)|Pedroso Sur (Padron)|Poligono Industrial Picaraña|Prada (Padron)|Ribasar (Santa Mariña)|Sisto, O (Rois)|Sorribas (Santo Tome)|Xiaxe (Rois)
15981	Dodro|Igrexa De Dodro, A (Dodro)|Laiño (San Xian)|Revixos (Dodro)|Tallos (Dodro)|Tarrio (Dodro)|Vigo (Dodro)
15982	Bexo (Dodro)|Imo (Dodro)|Laiño (San Xoan-Dodro)|Teaio (Dodro)
15983	Isorna (Santa Maria)|Quintans (Isorna)|Regueiro, O (Santa Maria De Isorna-Rianxo)|Vacariza, A (Santa Maria De Isorna-Rianxo)
15984	Araño, O (Santa Baia)|Asadelos (Santa Maria De Asados-Rianxo)|Asados (Santa Maria)|Atalaia, A (Asados)|Buia (Santa Baia De Araño-Rianxo)|Bures (Santa Maria De Asados-Rianxo)|Capela, A (Santa Baia De Araño-Rianxo)|Contres (Santa Baia De Araño-Rianxo)|Marquesa, A (Santa Maria De Asados-Rianxo)|Mirans, As (Santa Baia De Araño-Rianxo)|Monte Grande (Santa Maria De Asados-Rianxo)|Somoza (Santa Maria De Asados-Rianxo)|Suiglesia (Santa Maria De Asados-Rianxo)|Traba (Santa Baia De Araño-Rianxo)|Xens, Os (Santa Baia De Araño-Rianxo)
15985	Burato, O|Cartomil (San Salvador De Taragoña-Rianxo)|Chorente (San Salvador De Taragoña-Rianxo)|Fachan (San Salvador De Taragoña-Rianxo)|Fonte Susan (San Salvador De Taragoña-Rianxo)|Iglesia, A (San Salvador De Taragoña-Rianxo)|Ourolo|Outeiro (Tagaoña)|Taragoña (San Salvador)
15990	Bealo (San Pedro)|Beluso (San Pedro De Bealo-Boiro)|Cespon (San Vicenzo)|Comba (San Vicenzo De Cespon-Boiro)|Ferreiros (San Vicenzo De Cespon-Boiro)|Puente Beluso (San Pedro De Bealo-Boiro)|Reboredo (San Vicenzo De Cespon-Boiro)|San Roque (San Vicenzo De Cespon-Boiro)|Sandrenzo (San Vicenzo De Cespon-Boiro)|Treites (San Vicenzo De Cespon-Boiro)
15991	Nine|Vilariño (Cespon)
15992	Escarabote|Escarabotiño|Goyanes (Santiago De Lampon-Boiro)|Lampon (Santiago)|Madanela, A (Lampon)|Magdalena (Santiago De Lampon-Boiro)|Peralto
15993	Muiños (San Martiño De Oleiros-Ribeira)|Oleiros (Ribeira)
15994	Basoñas (San Pedro De Muro-Porto Do Son)|Carballosa (Muro)|San Pedro De Muro (San Pedro)|Santa Clara De Novas (San Pedro De Muro-Porto Do Son)|Serans (San Pedro De Muro-Porto Do Son)
15995	Agra, A (Santa Mariña De Xuño-Porto Do Son)|Curro, O (Santa Mariña De Xuño-Porto Do Son)|Laranga (Santa Mariña De Xuño-Porto Do Son)|Xuño (Santa Mariña)
15996	Caamaño|Caamaño (Santa Maria)|Ribasieira (San Fins)
15998	Queiruga (Porto Do Son)|Queiruga (Santo Estevo)|Tarela (Santo Estevo De Queiruga-Porto Do Son)|Tarrio (Queiruga)
15999	Amoreira, A ( San Martiño De Miñortos-Porto Do Son)|Beneso (San Sadurniño De Goians-Porto Do Son)|Boiro (San Martiño De Miñortos-Porto Do Son)|Campanario, O (San Sadurniño De Goians-Porto Do Son)|Freixedo (San Sadurniño De Goians-Porto Do Son)|Goians (San Sadurniño)|Mariño, O (San Sadurniño De Goians-Porto Do Son)|Miñortos (San Martiño)|Portosin|Silva, A (San Sadurniño De Goians-Porto Do Son)
16001	Cuenca
16002	Cuenca
16003	Cuenca
16004	Cuenca
16070	Cuenca
16071	Cuenca
16080	Cuenca
16100	Valverde De Jucar
16111	Albaladejo Del Cuende|Villaverde Y Pasaconsol
16112	Baños De Valdeganga
16113	La Parra De Las Vegas
16114	Buenache De Alarcon
16118	Barchin Del Hoyo|Hontecillas|Olmedilla De Alarcon|Piqueras Del Castillo
16120	Valera De Abajo
16122	El Castellar|Tortola|Valdeganga De Cuenca
16123	Arcas|Arcas Del Villar|Villar Del Saz De Arcas
16140	Villalba De La Sierra
16141	Arcos De La Sierra|Castillejo-Sierra|Fresneda De La Sierra|Portilla
16142	Las Majadas
16143	Collados|Mariana|Sotos
16144	La Frontera|Ribagorda|Villaseca
16145	Pajares|Ribatajada|Ribatajadilla|Torrecilla
16146	Valdecabras|Zarzuela
16147	Sitio De San Antonio|Ventorro Chafe
16150	Tragacete|Vega Del Codorno
16152	Beamud|Huelamo|Uña|Valdemeca
16160	Palomares Del Campo
16161	Torrejoncillo Del Rey|Villar Del Aguila
16162	Horcajada De La Torre|Naharros|Villar Del Horno
16190	Chillaron De Cuenca|Navalon|Sotoca|Villar Del Saz De Navalon
16191	Arcos De La Cantera|Bascuñana De San Pedro|Fuentesclaras Del Chillaron|Nohales|Noheda|Tondos
16192	Buenache De La Sierra|Molinos Del Papel|Palomera
16193	Fuentes|La Melgosa|Las Zomas|Mohorte
16194	Colliga|Colliguilla|Jabaga|Villanueva De Los Escuderos
16195	Abia De Obispalia|Huerta De La Obispalia|Poveda Obispalia|Villarejo Seco|Villarejo Sobrehuerta
16196	Barbalimpia|Villar De Olalla
16200	Motilla Del Palancar
16210	Campillo De Altobuey
16211	El Picazo
16212	Pozoseco|Rubielos Altos|Rubielos Bajos
16214	Alarcon|Gabaldon|Valhermoso De La Fuente|Valverdejo
16215	Almodovar Del Pinar
16216	Chumillas|Olmeda Del Rey|Solera De Gabaldon|Valeria
16220	Quintanar Del Rey
16230	Villanueva De La Jara
16234	Casas De Santa Cruz
16235	Iniesta
16236	Villagarcia Del Llano
16237	Ledaña
16238	Casas Del Olmo
16239	Casasimarro
16240	El Peral
16250	Castillejo De Iniesta
16251	Graja De Iniesta
16260	Minglanilla
16269	La Pesquera|Puebla Del Salvador
16270	Villalpardo
16280	Villarta
16290	Alcahozo|El Herrumblar
16300	Cañete
16311	Boniches|Campillos-Paravientos|Fuentelespino De Moya|Huerguina
16312	Garaballa|Henarejos
16313	Aliaguilla
16315	Alcala De La Vega|El Cubillo
16316	Campillos-Sierra|Huerta Del Marquesado|Laguna Del Marquesado|Valdemoro-Sierra
16317	Salinas Del Manzano|Tejadillos|Zafrilla
16318	Casas Nuevas|Hoya Del Peral|Salvacañete
16320	Talayuelas
16321	Casillas De Ranera
16330	Landete
16336	La Olmeda|Las Rinconadas|Santa Cruz De Moya
16337	Pedro Izquierdo|Santo Domingo De Moya
16338	Algarra|Casas De Garcimolina|El Arrabal|Los Huertos
16339	Graja De Campalbo|Las Higueruelas|Manzaneruela
16340	Cañada Del Hoyo|La Cierva|Valdemorillo De La Sierra
16350	Carboneras De Guadazaon
16360	Arguisuelas|Monteagudo De Las Salinas
16370	San Martin De Boniches|Villar Del Humo
16371	Narboneta|Villora
16372	Enguidanos|Salto De Villora
16373	Cardenete|Paracuellos De La Vega|Yemeda
16390	Pajaron|Pajaroncillo|Reillo
16393	Mira
16400	Tarancon
16410	Horcajo De Santiago
16411	Fuente De Pedro Naharro
16412	El Acebron
16413	Torrubia Del Campo
16414	Pozorrubio
16415	Villamayor De Santiago
16417	Los Hinojosos
16420	Almendros|Villarrubio
16421	Hontanaya|Puebla De Almenara
16422	Tresjuncos
16423	Osa De La Vega
16430	Saelices
16431	Almonacid Del Marquesado
16432	Villarejo De Fuentes
16433	Alconchel De La Estrella|Villar De Cañas
16434	Montalbanejo
16435	La Hinojosa
16440	Montalbo
16441	El Hito
16442	Villares Del Saz
16444	Cervera Del Llano
16452	Rozalen Del Monte|Tribaldos|Ucles
16460	Barajas De Melo
16461	Leganiel
16463	Saceda Trasierra
16464	Alcazar Del Rey
16465	Huelves|Paredes
16470	Belinchon|Valderrios (Urbanitzacio)|Zarza De Tajo
16500	Huete
16510	Garcinarro|Mazarulleque|Vellisca
16512	Buendia|Jabalera|Pantano De Buendia
16520	Moncalvillo De Huete
16521	Valdemoro Del Rey
16522	Portalrubio De Guadamejud|Tinajas
16531	Villanueva De Guadamejud
16532	Gascueña|La Peraleja|Saceda Del Rio
16535	Villalba Del Rey
16537	Alcohujate|Cañaveruelas
16540	Bonilla|Caracenilla|Verdelpino De Huete
16541	Castillejo Del Romeral|Pineda De Giguela|Valdecomenas De Abajo|Valdecomenas De Arriba|Villarejo De La Peñuela
16542	Cuevas De Velasco|Villar Del Maestre
16550	La Langa|Loranca Del Campo|Olmedilla Del Campo|Valparaiso De Abajo|Valparaiso De Arriba
16555	Carrascosa Del Campo
16600	San Clemente
16610	Casas De Fernando Alonso
16611	Casas De Haro
16612	Casas De Los Pinos|Casas De Roldan|Los Estesos|Ventas De Alcolea
16620	La Alberca De Zancara
16621	Santa Maria Del Campo Rus
16622	Pinarejo
16623	Castillo De Garcimuñoz
16630	Mota Del Cuervo
16638	El Pedernoso
16639	Santa Maria De Los Llanos
16640	Belmonte
16646	Villalgordo Del Marquesado
16647	Fuentelespino De Haro|Villaescusa De Haro
16648	Villar De La Encina
16649	Carrascosa De Haro|Monreal Del Llano|Rada De Haro
16650	Las Mesas
16660	Las Pedroñeras
16670	El Provencio
16700	Sisante
16707	Casas De Benitez|La Losa
16708	Casas De Guijarro|Pozo Amargo
16709	El Simarro|Vara De Rey|Villar De Cantos
16710	Atalaya Del Cañavate|Tebar
16720	Cañada Juncosa
16730	Honrubia
16738	El Cañavate
16739	Torrubia Del Castillo
16740	La Almarcha
16760	Olivares De Jucar
16770	San Lorenzo De La Parrilla
16771	El Congosto|Villarejo-Periesteban|Zafra De Zancara
16779	Belmontejo
16780	Altarejos|Mota De Altarejos
16781	Fresneda De Altarejos
16800	Priego
16812	Albendea|Alcantud|Arandilla Del Arroyo|El Pozuelo|Vindel
16813	Salmeroncillos De Abajo|Salmeroncillos De Arriba|San Pedro Palmiches|Valdeolivas|Villar Del Infantado
16840	Villar De Domingo Garcia
16841	Albalate De Las Nogueras
16842	Torralba
16843	Bolliga|Culebras|Fuentesbuenas|La Ventosa|Valdecañas|Villarejo Del Espartal
16850	Cañaveras
16851	Buciegas
16852	Olmeda De La Cuesta
16853	Olmedilla De Eliz
16854	Castillo-Albarañez
16855	Arrancacepas
16856	Castejon
16857	Canalejas Del Arroyo
16860	Villaconejos De Trabaque
16870	Beteta
16878	Lagunaseca|Masegosa|Poyatos|Santa Maria Del Val
16879	Carrascosa|Cueva Del Hierro|El Tobar|Valsalobre
16890	Cañamares|Fuertescusa|Huerta De Los Marojales
16891	Cañizares|Santa Cristina
16892	Puente De Vadillos
16893	Solan De Cabras
17001	Girona
17002	Girona
17003	Girona
17004	Girona
17005	Girona
17006	Girona
17007	Girona
17070	Girona
17071	Girona
17080	Girona
17100	La Bisbal D'Emporda
17110	Fonteta|Sant Climent De Peralta (Pueblo)|Santa Susana De Peralta (Pueblo)
17111	Vullpellac
17113	Canapost|Peratallada
17114	Ullastret
17115	Castell D'Emporda
17116	Cruilles
17117	Sant Miquel De Cruilles
17118	Sant Sadurni De L'Heura|Santa Pellaia
17120	Caça De Pelras|La Pera|Pedrinya (Ajuntament La Pera)|Pubol|Riuras
17121	Casavells|Corça|Matajudaica|Monells
17123	Torrent
17124	Llofriu
17130	Cala Montgo|Cinclaus|Empuries|Escala, L'
17131	Rupia
17132	Cuells (Foixa)|Masos (Foixa)|Vila (Foixa)
17133	Fonolleres|Parlava|Sala, La (Foixa)|Sant Iscle D'Emporda|Serra De Daro|Ultramort
17134	Canet De La Tallada|La Tallada D'Emporda|Maranya|Tor (Pueblo)
17136	Albons
17137	Palaborrell|Viladamat
17140	Ulla
17141	Bellcaire D'Emporda|Sobrestany
17142	Verges
17143	Jafre
17144	Colomers
17150	Sant Gregori (Municipio)
17151	Ginestar|Santa Afra
17152	Llora
17153	Granollers De Rocacorba|Sant Marti De Llemena
17154	Sant Aniol De Finestres|Sant Esteve De Llemana
17160	Angles|Mines Del Sant Pare, Les
17161	Colonia De Les Mines|Osor|Sant Miquel De Ter
17162	Bescano|Montfulla|Vilanna (Pueblo)
17164	Constantins|Sant Julia Del Llor I Bonmati
17165	La Cellera De Ter
17166	Coll, El (Ayto Susqueda)|El Pasteral|Susqueda
17170	Amer
17171	Sant Marti Sacalm
17172	Encies, Les|Planes D'Hostoles, Les
17173	Cogolls
17174	Sant Feliu De Pallerols|Sant Iscle De Colltort
17175	Sant Miquel De Pineda
17176	Joanetes|Sant Esteve D'En Bas|Veinat De Can Trona
17177	Falgars D'En Bas|Hostalets D'En Bas, Els
17178	Boscdetosca|El Malloll|Preses, Les|Puigpardines|Sant Miquel De Corb|Sant Privat D'En Bas
17179	Pinya, La (Pueblo)|Riudaura (Pueblo)
17180	El Perello|Vilablareix
17181	Aiguaviva|Marrocs
17182	Estanyol
17183	Sant Dalmai
17184	Salitja
17185	Aeroport De Girona - Costa Brava|Vilobi D'Onyar
17190	Salt
17199	Adri|Canet D'Adri|Cartella|Montcal|Sant Medir|Taiala
17200	Palafrugell
17210	Calella De Palafrugell
17211	Llafranc
17212	Tamariu
17213	Esclanya
17214	Regencos (Pueblo)
17220	Sant Amanc|Sant Feliu De Guixols
17230	Palamos|Sant Joan De Palamos
17240	La Canyera|Llagostera|Romanya De La Selva|Santa Seclina|Urbanitzacio Can Carbonell|Veinat De Bruguera|Veinat De Cantallops|Veinat De Creu De Serra|Veinat De Gaia|Veinat De Ganix|Veinat De Llobatera|Veinat De Mata|Veinat De Penedes|Veinat De Sant Llorenc|Veinat Pocafarina (Ay Llagoste)
17241	La Creueta|Palol D'Onyar
17242	Castellar De La Selva|Montnegre|Quart|Sant Mateu De Montnegre
17243	Erols|Llambilles
17244	Cassa De La Selva
17245	Bell-Lloc
17246	Canyet De Mar|El Vilar|Santa Cristina D'Aro|Solius
17248	S'Agaro
17249	Castell D'Aro
17250	Platja D'Aro
17251	Calonge
17252	Sant Antoni De Calonge
17253	Mont-Ras|Vall-Llobrega
17255	Aiguablava, D' (Platja)|Aiguafreda, D' (Platja)|Begur|Fornells, De (Platja)|Raco, Del (Platja)|Sa Riera, De (Platja)|Sa Tuna, De (Platja)
17256	Fontclara|Masos De Pals, Els|Palau-Sator|Pals|Sant Feliu De Boada|Sant Julia De Boada
17257	Fontanilles|Gualta|Llabia|Torroella De Montgri
17258	Estartit, L'
17300	Blanes
17310	Canyelles (Ayto Lloret Mar)|Lloret De Mar
17320	Canyelles (Ayto Tossa)|Tossa De Mar
17400	Breda
17401	Arbucies
17402	Joanet
17403	Sant Hilari Sacalm
17404	Riells (Riells I Viabrea)|Riells I Viabrea|Viabrea (Riells I Viabrea)
17405	Espinelves
17406	Viladrau|Vilarnau
17410	Mallorquines, Les|Sils|Vallcanera (Urbanitzacio)
17411	Vidreres
17412	El Moli|Maçanet De La Selva
17420	Mallorquines
17421	Esparra, L'|Riudarenes
17430	Santa Coloma De Farners
17441	Brunyola|Sant Marti Sapresa
17442	Santa Creu D'Horta
17443	Castanyet
17444	Cladells
17445	Sant Pere Cercada
17450	Hostalric
17451	Gaserans|Grions|Sant Feliu De Buixalleu
17452	Massanes
17453	Martorell De La Selva
17454	Sant Andreu Salou (Pueblo)
17455	Caldes De Malavella|El Veinat De Les Mateues
17456	Franciach (Pueblo)
17457	Riudellots De La Selva
17458	Fornells De La Selva
17459	Campllong
17460	Celra
17461	Campdora
17462	Bordils|Juia|Madremanya|Sant Marti Vell|Vilers
17463	Flaça|Sant Joan De Mollet|Sant Llorenç De Les Arenes (Foixa)
17464	Cervia De Ter|Fellines|Mas Nicolau|Raset|Sant Jordi Desvalls|Sobranigues|Veinat De Diana|Viladasens
17465	Camallera (Saus, Camallera I Llampaies)|Camallera (Vilaür)|Llampaies
17466	Garrigoles|Gaüses (Sector)|Olives, Les|Pins (Vilopriu)|Valldavia|Vilopriu
17467	Sant Mori|Saus
17468	Galliners|Olives (Ayto Vilademuls)|Orfes|Orriols|Parets D'Emporda|Sant Esteve De Guialbes|Sant Marçal De Quarantella|Terradelles|Vilademuls|Vilafreser|Vilamari
17469	El Far D'Emporda|Fortia|Pont Del Princep|Riumors|Siurana|Veinat De L'Oliva|Vilamalla
17470	Masos, Els|Sant Pere Pescador
17472	Armentera, L'|Montiro
17473	Ventallo
17474	Sant Tomas De Fluvia|Torroella De Fluvia|Vilacolum|Vilamacolum
17475	Sant Miquel De Fluvia|Vila-Robau
17476	Arenys D'Emporda|Ermedas (Ayto Garrigas)|Garrigas|Palau De Santa Eulalia|Santa Eulalia|Tonya
17480	Canyelles Almadraba (Ajuntament Roses)|El Mas Fumats|El Mas Oliva|Montjoi|Roses
17481	Montagut (Ajuntament San Julia Ram)|Sant Julia De Ramis
17482	El Tomet|Medinya
17483	Bascara|Calabuig|Vilaür
17484	Vilatenim
17485	Vila-Sacra
17486	Castello D'Empuries
17487	Empuriabrava
17488	Cadaques|Portlligat
17489	El Port De La Selva|La Selva De Mar|La Vall De Santa Creu
17490	Grifeu|Llança
17491	Peralada
17492	Vilanova De La Muga
17493	Marza|Pedret I Marza|Vilajüiga
17494	Pau|Vilaüt
17495	Palau-Saverdera
17496	Colera (Villa)|Garbet
17497	Portbou
17500	Colonia Rocafiguera|Ripoll
17510	Brucs|Llaes (Pueblo)
17512	Llosses, Les (Municipio)|Sant Esteve De Vallespirans|Santa Maria De Matamala
17513	Sant Sadurni De Sovelles|Viladonja
17514	Palmerola
17515	Ciuret|Vidra
17520	Puigcerda|Ventajola
17527	Cereja|Gorguja|Llivia
17528	Guils De Cerdanya|Saneja|Sant Marti D'Aravo|Sant Marti De Cerdanya
17529	Age|Vilallobent
17530	Campdevanol|Herand, L'|Sant Marti D'Armencies
17531	Gombren
17532	La Farga De Bebie
17533	Bruguera (Ayto Ribes Frese)
17534	Batet (Ayto Ribes Freser)|Campelles|Fustanya|Nuria|Pardines|Queralbs|Rialb|Ribes De Freser|Ribesaltes|Sola Ventola|Vilamanya|Vilaro
17535	Casetes, Les|Planoles
17536	Dorria|Espinosa|Fornells De La Muntanya|Neva|Toses
17537	La Molina
17538	Alp|Das|Escadarcs|Estoll|Fontanals De Cerdanya|Masella|Mosoll|Queixans|Sanavastre|Soriguerola|Tartera|Urtx|Urus
17539	All|Bolvir|El Moli De Ger|Ger|Greixer|Isovol|Meranges|Olopte|Talltorta
17600	Figueres
17700	La Jonquera
17706	Pont De Molins
17707	Agullana|La Vajol
17708	Cantallops
17709	Limits, Els (Portus, El - La Jonquera)
17710	Centro Militar Sant Climent Sescebes
17720	Maçanet De Cabrenys
17721	Tapis (Maçanet De Cabrenys)
17722	Darnius
17723	Biure|Boadella D'Emporda|Escaules, Les (Boadella I Les Escaules)
17730	Llers
17731	Palau Surroca (Terrades)|Terrades
17732	Sant Llorenç De La Muga
17733	Albanya
17734	Lliurona (Albanya)
17740	Vilafant
17741	Cistella|Taravaus|Vilarig
17742	Avinyonet De Puigventos
17743	Vilanant
17744	Canelles|Navata
17745	Llado|Llavanera (Ayto Llado)
17746	Cabanelles|Queixas|Sant Marti Sesserres|Vilademires
17747	Espinavessa
17750	Capmany|Vall, La (Ayto Capmany)
17751	Sant Climent Sescebes
17752	Mollet De Peralada
17753	Espolla
17754	Rabos D'Emporda
17755	Delfia (Rabos)
17760	Vilabertran
17761	Cabanes
17762	Vilarnadal (Masarac)
17763	Masarac
17770	Borrassa|Creixell|Vilamorell
17771	Santa Llogaia D'Alguema
17772	Ordis
17773	Pontos|Romanya D'Emporda|Vilajoan
17780	Garriguella
17781	Vilamaniscle
17800	Olot
17810	Sant Cristofol Les Fonts
17811	Can Blanc|Can Xel|El Sallent|Sant Miquel De Sacot|Santa Pau
17812	Batet De La Serra
17813	Hostalnou De Bianya (L') (Vall De Bianya)|Sant Marti Del Clot (Vall De Bianya)|Sant Pere Despuig (Vall De Bianya)|Sant Salvador De Bianya (Vall De Bianya)|Santa Margarida De Bianya (Vall De Bianya)
17820	Banyoles|Pins, Els (Banyoles)
17830	El Collell|El Torn|Mieres
17831	Falgons|Sant Marti De Campmajor|Sant Miquel De Campmajor
17832	Crespia|Esponella|Llavanera (Ayto Crespia)|Martis|Pedrinya (Ajuntament Crespia)|Pompia|Portell|Santenys|Vilert
17833	Fontcoberta|Melianta|Ollers (Sector)|Vilademi|Vilavenut
17834	Camos|El Mas Usall|Mianegues|Porqueres|Pujarnol|Sant Vicenç De Camos|Santa Maria De Camos|Usall (Ayto Porqueres)
17840	Sarria De Dalt (Pueblo)|Sarria De Ter
17843	Montbo|Mota, La (Pueblo)|Palol De Revardit|Riudellots De La Creu (Pueblo)
17844	Borgonya|Cornella Del Terri|Corts (Sector)|Pujals Dels Cavallers|Pujals Dels Pagesos|Sords
17845	Ravos Del Terri|Sant Andreu Del Terri|Santa Llogaia Del Terri
17846	Mata
17850	Besalu|Beuda|Fares|Juïnya|La Miana|Lligorda|Sant Ferriol
17851	Dosquers|Jonqueres|Llorens|Maia De Montcal|Seguero|Vilarrodona
17852	Serinya
17853	Argelaguer|Hostal Nou De Llierca, L'|Sadernes|Sales De Llierca|Tortella
17854	Sant Jaume De Llierca
17855	Montagut (Montagut I Oix)|Montagut I Oix|Oix (Montagut I Oix)
17856	Castellfollit De La Roca|Santa Barbara De Pruneres
17857	Beguda|Canya, La (Ajuntament De Sant Joan Les Fonts)|Sant Joan Les Fonts
17858	Canya, La (Vall De Bianya)|Capsec (Vall De Bianya)|Llocalou (Vall De Bianya)|Sant Andreu De Socarrats (Vall De Bianya)|Val Del Bac (Vall De Bianya)
17860	La Colonia Jordana|La Colonia Llaudet|Sant Joan De Les Abadesses
17861	Ogassa|Sant Marti D'Ogassa|Sant Marti De Surroca
17862	Vallfogona De Ripolles
17863	Sant Bernabe De Les Tenes
17864	Sant Pau De Seguries
17866	La Colonia Estevenell
17867	Beget|Camprodon|Creixenturri|Freixenet De Dalt|Llierca
17868	Espinavell|Fabert|Favars|Graells|La Ginestosa|Mollo
17869	Abella|El Llanares|Espinalba|Llanars|Llebro|Roca, La (Ayto Vilallonga)|Setcases (Municipio)|Tregura De Baix|Tregura De Dalt|Vilallonga De Ter
18001	Granada
18002	Granada
18003	Granada
18004	Granada
18005	Granada
18006	Granada
18007	Granada
18008	Granada
18009	Granada
18010	Granada
18011	Granada
18012	Granada
18013	Granada
18014	Granada
18015	Granada
18016	Granada|Parque Tecnologico De La Salud (Armilla)|Parque Tecnologico De La Salud (La Zubia)|Parque Tecnologico De La Salud (Ogijares)
18070	Granada
18071	Granada
18080	Granada
18100	Armilla
18101	Belicena
18102	Ambroz|Purchil
18110	Gabia La Chica|Gabia La Grande|Hijar|Las Gabias
18120	Alhama De Granada
18125	Pilas De Algaida|Ventas De Zafarraya
18126	Arenas Del Rey
18127	Fornes|Jatar|Jayena
18128	Zafarraya
18129	Cacin|El Turro|Pantano Bermejales|Santa Cruz Del Comercio
18130	Escuzar|La Malaha
18131	Ventas De Huelma
18132	Agron
18140	La Zubia
18150	Gojar
18151	Ogijares
18152	Dilar
18160	Guejar Sierra
18170	Alfacar
18179	Viznar
18180	Diezma
18181	Darro|Los Villares|Sillar Baja
18182	Granada
18183	Huetor De Santillan
18184	Beas De Granada
18190	Cenes De La Vega
18191	Canales|Pinos Genil
18192	Dudar|Quentar
18193	Barrio De La Vega|Barrio De Monachil|Monachil
18194	Churriana De La Vega
18195	Cullar Vega
18196	Sierra Nevada
18197	Pulianas|Pulianillas
18198	Huetor Vega
18199	Cajar
18200	Maracena
18210	Juncaril (Peligros) (Poligono Industrial)|Peligros
18211	Cogollos Vega
18212	Güevejar
18213	Jun
18214	Nivar
18220	Albolote|Juncaril (Albolote) (Poligono Industrial)
18230	Atarfe
18240	Pinos Puente
18247	Moclin
18248	Olivares|Tiena
18249	Limones|Puerto Lope|Tozar
18250	Valderrubio
18260	Alhondiguilla|Illora|Vallequemado|Ventas Algarra
18270	Milanos (Montefrio)|Montefrio
18280	Algarinejo
18290	Calicasas|Caparacena|El Chaparral
18291	Anzola|Casa Nueva|Zujaira
18293	Escoznar|Obeilar
18295	Fuentes De Cesna
18300	Esperanza, La (Huetor Tajar)|Esperanza, La (Loja)|Loja
18310	Salar
18311	Carrera De La Viña|Ventorros De San Jose|Zagra
18312	Ventorros De Balerma|Ventorros De La Laguna
18313	Riofrio
18314	Fuente Camacho|La Palma
18320	Santafe
18327	Lachar
18328	Fuensanta|Peñuelas|Trasmulas
18329	Castillo Tajarja|Chimeneas|El Jau
18330	Chauchina|Pedro Ruiz|Sierra Elvira
18339	Cijuela|Romilla
18340	Fuente Vaqueros
18350	Alomartes
18360	Agicampe (Loja)|Fabrica, La (Loja)|Huetor Tajar|Milanos (Loja)
18369	Villanueva Mesia
18370	Moraleda De Zafayona
18380	Tocon
18381	Bracana
18400	Orgiva
18410	Bayacas|Carataunas|Soportujar
18411	Pampaneira
18412	Bubion
18413	Capileira
18414	Atalbeitar|Capilerilla|Ferreirola|Fondales|La Taha|Mecina|Mecinilla|Pitres
18415	Portugos
18416	Busquistar
18417	Trevelez
18418	Cañar|Las Barreras|Los Agustines|Tablones, Los (Orgiva)|Tijola
18420	Lanjaron
18430	Torvizcon
18438	Almegijar|Notaez
18439	Castaras
18440	Cadiar
18448	Narila|Yator
18449	Lobras
18450	Golco|Mecina Bombaron
18451	Berchules
18452	Juviles
18460	Yegen
18470	Mecina Alfahar|Valor
18480	Canteras, Las (Ugijar)|Los Montoros|Ugijar
18490	Murtas
18491	Turon
18492	Cojayar|Jorairatar|Mecina Tedel
18494	Cherin|Jubar|Laroles|Mairena|Nevada|Picena
18500	Guadix
18510	Benalua
18511	Alcudia De Guadix|Charches|Esfiliana|Rambla Del Agua (Charches)|Valle Del Zalabi
18512	Dolar|Hueneja|La Calahorra|Olivos, Los (Hueneja) (Urbanizacion)
18513	Ferreira
18514	Aldeire
18515	Belerda|El Bejarin|Fonelas
18516	Beas De Guadix|Lugros|Marchal|Policar
18517	Cortes Y Graena|La Peza|Lopera|Tocon De Quentar
18518	Albuñan|Alquife|Cogollos De Guadix|Jerez Del Marquesado|Lanteira
18519	Paulenca|Purullena
18520	Alamedilla
18530	Pedro Martinez
18538	Alicun De Ortega|Dehesas De Guadix
18539	Villanueva De Las Torres
18540	Delgadillo|Huelago|Laborcillas|Moreda|Morelabor
18550	Iznalloz
18560	Guadahortuna
18561	Montejicar
18562	Bogarre
18563	Gobernador|Torre Cardela
18564	Colomera
18565	Campotejar
18566	Benalua De Las Villas
18567	Dehesas Viejas|Domingo Perez|Ventas De Andar
18568	Piñar
18569	Gumiel|Montillana
18570	Deifontes
18600	Las Ventillas|Motril|Puntalon|Tablones, Los (Motril)
18610	Lobres
18611	Molvizar
18612	Itrabo
18613	El Varadero|Playa Granada
18614	Gualchos|La Garnatilla|Lujar
18615	Guajar Alto|Guajar Faragüit|Guajar Fondon|Los Guajares
18616	Gorgoracha|Lagos
18620	Alhendin
18630	Otura
18640	Padul
18650	Durcal
18656	Acequias|Beznar|Chite|Lecrin|Mondujar|Murchas|Talara
18657	Niguelas
18658	El Valle|Melegis|Pinos Del Valle|Restabal|Saleres
18659	Albuñuelas|Conchar|Cozvijar|Marchena|Villamena
18660	Izbor
18670	Velez De Benaudalla
18680	La Caleta-Guardia|Salobreña
18690	Almuñecar|Velilla-Taramay
18697	La Herradura
18698	Otivar
18699	Jete|Lentegi
18700	Albuñol
18708	Albondon
18710	Alcazar|Alfornon|Bargis|Fregenite|Haza Del Lino (Polopos)|Olias|Polopos
18711	Rambla Del Agua (Rubite)|Rubite
18713	Melicena|Sorvilan
18720	Torrenueva
18730	Calahonda|Carchuna
18740	Castell De Ferro
18750	Castillo De Baños|Haza Del Trigo|La Mamola
18760	La Rabita
18770	El Pozuelo
18800	Baza
18810	Caniles
18811	Zujar
18812	Freila
18813	Cuevas Del Campo
18814	Cortes De Baza|La Teja|Las Cucharetas|Los Laneros
18815	Campo Camara
18816	Castril
18817	Benamaurel
18818	Castillejar
18820	Puebla Don Fadrique
18830	Huescar
18840	Galera
18850	Cullar
18858	Orce
18859	Las Vertientes|Matian|Pulpite|Venta Quemada
18860	Bacor|Baul|Olivar
18870	Gor|Los Balcones
18880	Hernan Valle
18890	Gorafe
18891	El Margen|Jamula|Venta Del Peral
19001	Guadalajara
19002	Guadalajara
19003	Guadalajara
19004	Guadalajara
19005	Guadalajara
19070	Guadalajara
19071	Guadalajara
19080	Guadalajara
19100	Franciscano Pastrana (Convento)|Pastrana
19110	Mondejar
19111	Yebra
19112	Albares|Pozo De Almoguera
19113	Fuentenovilla
19114	Mazuecos
19115	Almoguera
19116	Driebes
19117	Albalate De Zorita
19118	Almonacid De Zorita
19119	Anguix|Bolarque|Central Nuclear 'Jose Cabrera'|Colonias De San Joaquin, Las (Urbanizacion)|Cuartillejo|Cuartillejo (Urbanizacion)|Escariche|Escopete|Hontoba|Hueva|Illana|Nueva Sierra De Altomira (Urbanizacion)|Rio Llano|Riollano (Urbanizacion)|Sayaton|Soto, El (Illana)|Zorita De Los Canes
19120	Sacedon
19125	Alcocer
19126	Salmeron
19127	Castilforte|Corcoles|Escamilla|Millana
19128	Brisas, Las (Urbanizacion)|Cereceda|Chillaron Del Rey|Las Anclas|Mantiel|Paraiso, El (Urbanizacion)|Peñalagos (Urbanizacion)
19129	Alique|Casasana|Pareja|Tabladillo
19130	Auñon
19131	Entrepeñas|Pantano De Entrepeñas
19132	Alhondiga|Valdeconcha
19133	Alocen|Berninches|Budia|Duron|El Olivar|Picazo|Valdelagua
19134	Peñalver|Tendilla
19135	Armuña De Tajuña
19139	Ciudad Valdeluz
19140	Horche
19141	Aranzueque|Loranca De Tajuña|Valdarachas|Yebes
19142	Lupiana|Valdeavellano
19143	Irueste|Romanones|San Andres Del Rey|Yelamos De Abajo|Yelamos De Arriba
19144	Fuentelencina|Fuentelviejo|Moratilla De Los Meleros
19145	Renera
19150	Iriepal
19151	Centenera
19152	Aldeanueva De Guadalajara
19153	Atanzon
19160	Albolleque|Chiloeches
19161	Pozo De Guadalajara
19162	Monte Alcarria|Piedras Menaras (Finca)|Pioz
19163	Ciudad Residencial El Clavin
19170	Colinas, Las (Urbanizacion)|Coto, El (Urbanizacion)|El Casar|Monte Calderon (Urbanizacion)
19171	Cabanillas Del Campo
19174	Galapagos|Parque De Las Castillas (Urbanizacion)|Torrejon Del Rey|Valdeaveruelo
19180	Marchamalo
19182	Fuentelahiguera De Albatages|Usanos
19184	Alpedrete De La Sierra|Casa De Uceda|Tortuero De La Sierra|Valdepeñas De La Sierra|Villaseca De Uceda|Viñuelas
19185	Lago Del Jaral (Urbanizacion)|Mesones De Uceda|Sotolargo (Urbanizacion)|Valbueno|Valdenuño Fernandez
19186	El Cubillo De Uceda
19187	Uceda
19188	Caraquiz (Urbanizacion)
19190	Torija
19192	Beltraneja (Urbanizacion)|Gajanejos|Mirador Del Cid, El (Urbanizacion)|Trijueque
19193	Taracena
19196	Arcipreste (Urbanizacion)|Argecilla|Ledanca|Muduex|Utande|Valdearenas|Valfermoso De Las Monjas
19197	Cañizar|Ciruelas|El Palacio De Heras|Heras De Ayuso|Rebollosa De Hita|Sopetran|Torre Del Burgo|Valdenoches
19198	Tortola De Henares
19200	Acequilla|Azuqueca De Henares|Barriada De Asfain|Miralcampo
19208	Alovera|Eusebio Centenera (Urbanizacion)
19209	Quer|Villanueva De La Torre
19210	Yunquera De Henares
19219	Malaga Del Fresno|Malaguilla
19220	Humanes De Mohernando
19222	Tamajon
19223	Campillejo|Campillo De Ranas|El Espinar|El Vado|Majaelrayo|Roblelacasa|Robleluengo
19224	Matallana, Presa De|Valverde De Los Arroyos
19225	Almiruete|La Mierla|Muriel|Palancares|Puebla De Valles|Retiendas|Valdesotos
19226	Mohernando
19227	Alarilla|Colegio Salesiano Maluque|Maluque|Maluque, Depuradora|Matarrubia|Robledillo De Mohernando|Taragudo
19229	Cerezo De Mohernando|Humanes De Mohernando (Estacion)|Montarron|Palacios, Los (Finca)|Peñahora (Urbanizacion)|Puebla De Beleña|Razbona|Torrebeleña
19230	Cogolludo
19237	Aleas|Arbancon|Beleña De Sorbe|Fuencemillan|San Andres Del Congosto|Semillas|Zarzuela De Jadraque
19238	Arroyo De Fraguas|La Huerce|La Nava De Jadraque|Umbralejo|Valdepinillos|Veguillas|Zarzuela De Galve
19239	Monasterio
19240	Jadraque
19242	Hiendelaencina
19243	Bustares|Congostrina|Gascueña De Bornova|La Toba|Las Navas De Jadraque|Pradena De Atienza|Robledo De Corpes|Villares De Jadraque
19244	Aldeanueva De Atienza|El Ordial
19245	Angon|Cendejas De Enmedio|Cendejas De La Torre|Cendejas Del Padrastro|Jirueque|Negredo|Palmaces De Jadraque|Pantano De Palmaces|Rebollosa De Jadraque|Santiuste|Torremocha De Jadraque
19246	Casas De San Galindo|Castilblanco De Henares|Medranda|Miralrio|Padilla De Hita|Pinilla De Jadraque|Villanueva De Argecilla
19247	Barrio Estacion De Jadraque|Bujalaro|Carrascosa De Henares|Jadraque (Estacion)|Membrillera|Poligono Peñablanca
19248	Hita
19250	Sigüenza
19260	Alcolea Del Pinar
19261	Cortes De Tajuña|Luzaga|Tortonda|Villaverde Del Ducado
19262	Barbatona|Estriegana|Jodra Del Pinar|Sauca
19263	Bujarrabal|Cubillas Del Pinar|Guijosa
19264	Alboreca|Alcuneza|Horna|Mojares|Olmedillas
19265	Pozancos|Ures
19266	Bujalcayado|Carabias|Cirueches|El Atance|Olmeda De Jadraque|Palazuelos|Salinas De La Olmeda
19267	La Cabrera|Moratilla De Henares
19268	Algora|La Fuensaviñan|La Torresaviñan|Laranueva|Mirabueno|Navalpotro|Pelegrina|Torremocha Del Campo
19269	Cardeñosa|Cercadillo|Imon|La Barbolla|Riba De Santiuste|Rienda|Riofrio Del Llano|Riosalido|Santamera|Sienes|Torre De Valdealmendras|Torrecilla Del Ducado|Valdealmendras|Valdelcubo|Villacorza
19270	Atienza
19274	Villacadima
19275	Albendiego|Campisabalos|Cantalojas|Condemios De Abajo|Condemios De Arriba|Galve De Sorbe|Somolinos
19276	Alpedroches|Bañuelos|Bochones|Casillas De Atienza|Cañamares|Higes|Miedes De Atienza|Romanillos De Atienza|Tordelloso|Ujados
19277	Alcolea De Las Peñas|Cincovillas|Madrigal|Paredes De Siguenza|Tordelrabano
19278	La Bodera|La Miñosa|Naharros
19280	Maranchon
19281	Balbacil|Clares|Codes
19283	Aguilar De Anguita|Anguita|Garbajosa|Iniestola|Santa Maria Del Espino
19285	Ciruelos Del Pinar|Luzon
19286	Mazarete|Tobillos
19287	Anchuela Del Campo|Anquela Del Ducado|Concha|Estables|Fuentelsaz Del Campo|Milmarcos|Turmiel
19290	Fontanar
19292	Copernal|Espinosa De Henares
19294	Aragosa|Castejon De Henares|Mandayona|Matillas|Villaseca De Henares
19295	Baides|Huermeces Del Cerro|Viana De Jadraque
19300	Molina De Aragon
19310	Alcoroches|Checa|Chequilla
19311	Orea
19312	Pinilla De Molina|Terzaga|Traid
19313	Peralejos De Las Truchas
19314	Armalla|Salinas De Armalla|Taravilla
19315	Megina
19320	Alustante|Motos
19323	Tordesilos
19324	Setiles
19325	Adobes|Piqueras|Tordellego
19326	El Pobo De Dueñas
19327	El Pedregal
19328	Castellar De La Muela|Hombrados|Morenilla
19332	Algar De Mesa|Amayas|Mochales|Villel De Mesa
19333	Labros|Tartanedo
19334	Hinojosa
19336	Pardos
19337	Torrubia
19338	Tortuera
19339	Cillas|Embid|Rueda De La Sierra
19340	Rillo De Gallo
19341	Corduente
19342	Herreria
19343	Canales De Molina
19344	Aragoncillo
19345	Arandilla|Torremocha Del Pinar
19346	Selas
19350	Anchuela Del Pedregal
19351	Tordelpalo
19352	Prados Redondos
19353	Chera
19354	Aldehuela
19355	Torrecuadrada De Molina
19356	Otilla
19357	Anquela Del Pedregal
19360	Campillo De Dueñas
19361	La Yunta
19362	Cubillejo De La Sierra
19363	Cubillejo Del Sitio
19390	Baños De Tajo|Escalera|Fuembellida|Teroleja|Tierzo|Valhermoso|Valsalobre
19391	Castilnuevo|Pradilla|Torremochuela
19392	Castellote|Cuevas Labradas|Cuevas Minadas|Lebrancon|Terraza|Torete|Torrecilla Del Pinar|Ventosa
19400	Brihuega
19411	Archilla|Balconete|Romancos|Santa Clara|Tomellosa|Valfermoso De Tajuña
19412	Caspueñas|Fuentes De La Alcarria|Matilla, La (Finca)|Valdegrudas|Valdesaz
19413	Castilmimbre|Hontanares|Malacuera|Olmeda Del Extremo|Pajares|Villaviciosa De Tajuña|Yela
19420	Cifuentes
19429	Huetos|Ruguilla|Sotoca De Tajo|Val De San Garcia
19431	Canredondo|Carrascosa De Tajo|Oter|Torrecuadradilla
19432	Abanades|Canales Del Ducado|Ocentejo|Renales|Sacecorbo
19441	Huertahernando|La Loma|Riba De Saelices|Ribarredonda
19442	Ablanque
19443	Buenafuente Del Sistal|Cobeta|Saelices De La Sal
19444	Olmeda De Cobeta|Villar De Cobeta
19445	Esplegares|La Hortezuela De Ocen|Padilla Del Ducado|Sotodosos|Villarejo De Medina
19450	Trillo
19458	Instituto Leprologico De Trillo
19459	Central Nuclear De Trillo|Central Nuclear De Trillo (Poblado)|Gargoles De Abajo|Gargoles De Arriba|Gualda
19460	Villanueva De Alcoron
19461	Armallones|Huertapelayo
19462	Peñalen
19463	Poveda De La Sierra
19490	Alaminos|Almadrones|Barriopedro|Civica|Cogollor|Masegoso De Tajuña|Valderrebollo|Venta De Almadrones
19491	El Sotillo|Henche|Las Inviernas|Moranchel|Solanillos Del Extremo|Torrecuadrada De Los Valles
19492	Arbeteta|Azañon|El Recuenco|La Puerta|Morillejo|Valdenaya|Valtablado Del Rio|Viana De Mondejar
19493	Peralveche|Villaescusa De Palositos
19495	El Campillo|Zaorejas
20001	Donostia-San Sebastian
20002	Donostia-San Sebastian
20003	Donostia-San Sebastian
20004	Donostia-San Sebastian
20005	Donostia-San Sebastian
20006	Donostia-San Sebastian
20007	Donostia-San Sebastian
20008	Donostia-San Sebastian|Igeldo
20009	Donostia-San Sebastian
20010	Donostia-San Sebastian
20011	Donostia-San Sebastian
20012	Donostia-San Sebastian
20013	Donostia-San Sebastian
20014	Donostia-San Sebastian
20015	Donostia-San Sebastian
20016	Donostia-San Sebastian
20017	Donostia-San Sebastian
20018	Añorga|Donostia-San Sebastian
20070	Donostia-San Sebastian
20071	Donostia-San Sebastian
20080	Donostia-San Sebastian
20100	Errenteria|Landarbaso|Lezo
20110	Pasai Antxo|Pasai Donibane|Pasai San Pedro|Pasaia
20115	Astigarraga
20120	Akerregi|Eziago|Hernani|Jauregi|Martindegi|Osinaga|Santa Barbara|Zikuñaga
20128	Epela|Ereñotzu|Pagoaga
20130	Urnieta
20140	Andoain|Buruntza|Goiburu|Leizotz|Sorabilla
20150	Aduna|Amasa|Elbarrena|Villabona
20159	Asteasu|Beballara|Elizmendi|Errekaballara|Goiballara|Larraul|Upazan|Zizurkil (Pueblo)
20160	Atsobakar|Larrekoetxe|Lasarte|Lasarte-Oria|Oria|Zubieta (Donostia-San Sebastian)|Zubieta (Usurbil)
20170	Aginaga (Usurbil)|Kalezar|Txikierdi|Urdaiaga|Usurbil
20180	Altzibar|Arragua|Elizalde|Ergoien|Gurutze|Iturriotz|Karrika|Oiartzun|Ugaldetxo
20200	Altamira|Antzizar|Beasain|Beasainmendi|Loinatz|Ugartemendi
20210	Lazkao|Lazkaomendi|Senpere|Zubierreka
20211	Aia (Ataun)|Ataun|San Gregorio|San Martin
20212	Ihurre|Olaberria
20213	Idiazabal|Urtsuaran
20214	Mutiloa|Segura|Zerain
20215	Arrieta|Barrenaldea|Goialdea|Olaran|Zegama
20216	Ormaiztegi
20217	Alegia (Gabiria)|Gabiria
20218	Aratz-Matxinbenta|Aratz-Matxinbenta (Ezkio-Itsaso)|Arriaran|Astigarreta|Garin|Gudugarreta|Mandubia|Salbatore
20220	Aztiria|Brinkola|Telleriarte
20230	Legazpi
20240	Ordizia
20247	Zaldibia
20248	Altzaga|Arama|Gaintza
20249	Itsasondo
20250	Legorreta
20259	Baliarrain
20260	Alegia|Errotaldea|Langaurrealdea
20267	Aldaba|Ikaztegieta
20268	Altzo|Amezketa|Bedaio|Ergoiena|Ugarte
20269	Abaltzisketa|Orendain
20270	Anoeta
20271	Irura
20280	Akartegi|Alde Zaharra|Amute-Kosta|Arkolla|Gornutz (Montaña)|Hondarribia|Jaitzubia|Mendelu|Portua|Puntalea|Zimizarga
20300	Irun
20301	Irun
20302	Irun
20303	Irun
20304	Bidasoa|Irun
20305	Irun
20400	Auzotxikia|Ibarra|Monteskue|San Blas|San Esteban (Tolosa)|Santa Lutzia|Tolosa|Txarama|Urkizu|Usabal
20490	Lizartza|Orexa
20491	Belauntza|Gaztelu|Leaburu
20492	Berastegi
20493	Berrobi|Eldua|Elduain
20494	Alkiza|Hernialde
20495	Albiztur
20496	Bidania|Bidegoain|Goiatz
20500	Arrasate/Mondragon|Bedoña|Garagartza (Arrasate/Mondragon)|Gesalibar|Meatzerreka|Udala
20530	Apotzaga|Bolibar-Ugazua|Leintz-Gatzaga|Marin|Mazmela|Zarimutz
20540	Eskoriatza
20550	Aozaratza|Apotzaga-Etxebarri|Areantza|Aretxabaleta|Arkarazo|Galartza|Gellao|Goroeta|Izurieta|Larrino|Mendiola|Oro
20560	Oñati
20567	Arantzazu|Araotz
20568	Uribarri
20569	Berezao|Garagaltza|Garibai|Goribar|Larraña|Lezesarri|Murgia|Olabarrieta (Oñati)|Santxolopeztegi|Torreauzo|Urrexola|Zañartu|Zubillaga
20570	Basalgo|Bergara|Elorregi|Elosua
20577	Antzuola
20578	Angiozar
20579	Ubera
20580	Osintxu
20590	Placencia De Las Armas|Soraluze
20600	Aginaga (Eibar)|Arrate|Eibar|Maltzaga
20690	Elgeta
20700	Urretxu|Zumarraga
20709	Anduaga (Santa Lutzia)|Ezkio|Itsaso|Itsaso-Alegia
20710	Aginaga (Zumarraga)
20720	Arrietamendi|Azkoitia|Izarraitz|Ormaolamendi
20730	Azpeitia|Loiola
20737	Argisain (Santa Marina)|Artzalluz|Erdoizta|Errezil|Ezama|Ibarbia|Letea
20738	Aratz Erreka|Nuarbe|Urrestilla
20739	Beizama
20740	Endoia|Lasao|Zestoa
20749	Aizarna|Aizarnazabal|Arroa Bekoa|Arroa Goikoa|Etxabe|Etxezarreta|Iraeta|Mugitzagaina|Saiatz|Zubialde
20750	Zumaia
20759	Artadi|Oikia
20800	Aitza|Elkano (Zarautz)|Urdaneta|Urteta|Zarautz
20808	Askizu|Eitzaga|Getaria|Meaga|San Prudentzio
20809	Aia|Altzola (Aia)|Andatza|Arrutiegia|Elkano (Aia)|Etxetaballa|Iruretaegia|Kurpidea|Laurgain|Olaskoegia
20810	Orio|Santio Erreka
20820	Deba
20829	Itziar|Lastur
20830	Arzainerreka|Astigarribia|Galdona|Ibiri Laranga|Laranga|Mijoa|Mizkia|Mutriku|Olabarrieta (Mutriku)|Olatz
20850	Azpilgoeta|Garagartza (Mendaro)|Mendaro|Mendarozabal|Plaza
20860	Altzola (Elgoibar)
20870	Aiastai (San Migel)|Azkue (San Roke)|Elgoibar|Idotorbe (San Pedro)|Sallobente-Ermuaran
21001	Huelva
21002	Huelva
21003	Huelva
21004	Huelva
21005	Huelva
21006	Huelva
21007	Huelva
21070	Huelva
21071	Huelva
21080	Huelva
21100	Punta Umbria
21110	Aljaraque
21120	Corrales
21122	Bellavista
21130	Mazagon
21200	Aracena
21207	La Umbria|Linares De La Sierra|Valdezufre
21208	Carboneras|Castañuelo|Cortelazor|Corterrangel|Los Marines
21209	Corteconcepcion|Jabuguillo|Puerto Gil|Puerto Moral
21210	Zufre
21220	Higuera De La Sierra
21230	Cortegana
21239	La Corte|Las Cefiñas|Los Andreses|Los Bravos|Los Viejos|Puerto Lucia
21240	Aroche
21250	Rosal De La Frontera
21260	Santa Olalla Del Cala
21270	Cala|Minas De Cala
21280	Arroyomolinos De Leon
21290	Aguafria|Jabugo|Los Romeros
21291	Galaroza|La Nava|Las Chinas|Valdelarco
21292	Castaño Del Robledo (Poblado)|Fuenteheridos
21300	Calañas
21309	Sotiel Coronada
21310	La Zarza
21319	Minas De Perrunal
21320	El Cerro De Andevalo
21330	Cueva De La Mora|El Lomero|San Telmo|Valdelamusa
21340	Alajar
21342	Acebuche|Almonaster, De (Estacion)|Calabazares|El Arroyo|Gil Marquez (Aldea)|La Canaleja|La Escalada|Las Veredas
21350	Almonaster La Real
21359	Fuente Del Oro|Los Molares|Santa Ana La Real
21360	El Repilado
21380	Cumbres Mayores
21386	Cumbres De San Bartolome
21387	Cumbres De Enmedio
21388	Cañaveral De Leon|Hinojales
21390	Encinasola
21400	Ayamonte
21409	Isla De Canela|Punta Del Moral
21410	Isla Cristina
21420	Pozo Del Camino|Villa Antonia (Poblado)
21430	La Redondela
21440	Lepe
21449	Islantilla|La Antilla
21450	Cartaya
21459	El Portil|El Rompido
21500	Gibraleon
21510	San Bartolome De La Torre
21520	Alosno
21530	Minas De Tharsis
21540	Villanueva De Los Castillejos
21550	Puebla De Guzman
21559	Minas De Herrerias
21560	Paymogo
21570	Santa Barbara De Casa
21580	Cabezas Rubias|Montes De San Benito
21590	Villablanca
21591	San Silvestre De Guzman
21592	Villanueva De Las Cruces
21593	El Almendro
21594	El Granado|Puerto De La Laja
21595	Sanlucar De Guadiana
21600	Los Pinos|Valverde Del Camino
21609	Fuente De La Corcha|Navahermosa
21610	San Juan Del Puerto
21620	Trigueros
21630	Beas
21639	Candon
21640	Zalamea La Real
21647	Berrocal|El Buitron|El Pozuelo|Las Delgadas|Marigenta|Membrillo Alto|Monte Sorromeo
21649	Aldea De Traslasierra|El Patras|El Villar
21650	El Campillo
21660	Minas De Riotinto
21668	Campofrio|La Granada De Rio-Tinto
21669	Dehesa, Aldea De La
21670	Nerva
21700	La Palma Del Condado
21710	Bollullos Par Del Condado
21720	Rociana Del Condado
21730	Almonte
21740	Hinojos
21750	El Rocio
21760	Matalascañas|Torre La Higuera
21800	Moguer
21810	Palos De La Frontera
21819	La Rabida
21820	Lucena Del Puerto
21830	Bonares
21840	Niebla
21850	Villarrasa
21860	Villalba Del Alcor
21870	Escacena Del Campo
21880	Aldea De Tujena|Paterna Del Campo
21890	Manzanilla
21891	Chucena
22001	Huesca
22002	Huesca
22003	Huesca
22004	Huesca
22005	Huesca
22006	Huesca
22070	Huesca
22071	Huesca
22080	Huesca
22100	Sangarren
22110	Salillas|Sesa
22111	Corvinos|Monflorite
22112	Albero Alto
22113	Novales
22120	Sietamo
22121	Arbanies|Castejon De Arbanies
22122	Ibieca|Liesa|Velillas
22123	Angues
22124	Lascellas|Ponzano
22125	Laluenga
22126	Laperdiguera
22131	Berbegal|Lagunarrota
22132	Barbuñales|Lacuadrada|Pertusa|Torres De Alcanadre
22133	Antillon|Bespen|Blecua
22134	Torres De Montes
22135	Alcala Del Obispo|Argavieso|Fañanas|Ola|Pueyo De Fañanas
22140	Ayera|Bandalies
22141	Aguas|Bastaras|Coscullano|La Almunia Del Romeral|Los Molinos De Sipan|Loscertales|Morrano|Panzano|San Roman De Morrano|Santa Cilia De Panzano|Sipan|Yaso
22142	Casbas De Huesca|Junzano|Labata|Sieso De Hueca
22143	Abiego
22144	Bierge|Las Almunias|Rodellar|San Saturnino
22145	Alquezar|Radiquero|San Pelegrin
22146	Buera
22147	Adahuesca|Alberuela De Laliena
22148	Almazorre|Asque|Barcabo|Betorz|Colungo|Eripol|Hospitaled De Barcabo|Lecina
22149	Arcusa|Castellazo|El Coscollar|Las Bellostas|Paules De Sarsa|Pueyo De Morcat|Santa Maria De La Nuez|Sarsa De Surta
22150	Arguis|Bara|Belsue|Bentue De Nocito|Bentue De Rasal|Nocito
22160	Bolea
22161	Lierta|Puibolea
22162	Anies
22190	Vicien
22191	Quicena
22192	Barluenga|Castilsabas|Chibluco|Loporzano|San Julian De Banzo|Santa Eulalia La Mayor|Sasa Del Abadiado|Tierz|Vadiello
22193	Arascues|Igries|Nueno|Sabayes|Santa Eulalia De La Peña|Yequeda
22194	Alerre|Banaries|Banastas|Chimillas|Figueruelas|Huerrios|Torres Secas
22195	Apies|Fornillos De Apies
22196	Bellestar Del Flumen|Buñales|Castillo De Pompien|La Granja|Lascasas|Pompenillo|Tabernas De Isuela
22197	Cuarte
22200	Sariñena
22210	Huerto|Peralta De Alcofea|Uson|Venta De Ballerias
22212	Alberuela De Tubo|Capdesaso|San Lorenzo Del Flumen|Sodeto
22213	La Cartuja De Monegros|Orillena|San Juan Del Flumen
22214	Lalueza
22215	Castelflorite|El Tormillo|Lamasadera|Lastanosa
22216	Cabañas|Cantalobos|Poleñino
22220	Albalatillo
22221	Pallaruelo De Monegros
22222	Castejon De Monegros
22223	Valfarta
22230	Sena
22231	Villanueva De Sigena
22232	Ontiñena
22233	Chalamera
22234	Ballobar
22240	Tardienta
22250	Lanaja
22251	Alcubierre
22252	Robres
22253	Senes De Alcubierre
22254	Torralba De Aragon
22255	Albero Bajo|Almuniente|Barbues|Callen|Torres De Barbues|Valfonda De Santa Ana
22260	Grañen
22268	Fraella|Marcen|Piraces|Tramaced
22269	Curbe|Frula|Montesusin
22270	Almudevar
22280	Camporredondo|Gurrea De Gallego
22281	El Temple|La Paul
22282	Alcala De Gurrea
22283	Artasona Del Llano|San Jorge|Tormos|Valsalada
22300	Barbastro
22310	Castejon Del Puente
22311	Azara|Azlor|Peraltilla|Pueyo, El (Monasterio)
22312	Coscojuela De Fantova|Costean|Enate|Guardia|Hoz De Barbastro|Salinas De Hoz
22313	Castillazuelo|Huerta De Vero|Pozan De Vero
22314	Salas Altas|Salas Bajas
22315	Burceat|Cregenzan|Montesa
22320	Mipanas|Naval|Suelves
22330	Ainsa|Sarratillo
22336	Arro|Charo|Formigales|Morillo De Monclus|Tierrantona
22337	Alueza|Alujan|Buetas|El Humo De Rañin|El Pocino|Lapenilla|Lascorz|Palo|Rañin|Solipueyo
22338	Araguas|El Plano|El Pueyo De Araguas|El Soto|La Muera|Molinos, Los (Pueyo De Araguas)|Oncins|Pardina, La (Pueyo De Araguas)|San Lorien|San Victorian|Torrelisa
22339	Banaston|Gerbe|Griebal
22340	Boltaña
22347	Ascaso|Morillo De San Pietro
22348	Aguilar (Boltaña)|Campodarbe|La Valle|San Belian
22349	Guaso|Latorrecilla|Margudgued|Sieste
22350	Bielsa
22351	Espierba|Javierre (Bielsa)|Pineta
22360	Labuerda|San Vicente (Labuerda)
22361	Ceresa|El Casal|Laspuña|Socastiello
22362	Bestue|Escuain|Puertolas
22363	Belsierre|Escalona|Huertas De Muro|Muro De Bellos|Puyarruego|Santa Maria (Puertolas)
22364	Badain|Hospital De Tella|Lafortunada|Revilla|Tella
22365	Chisagues|Parzan
22366	Saravillo|Serveto|Sin
22367	Gistain|Plan|San Juan De Plan
22370	Broto|Oto
22371	Albella|Janovas|Planillo|San Felices De Ara
22372	Arresa|Asin De Broto|Javierre De Ara|Liguerre De Ara|San Martin De La Solana|Santa Olaria De Ara
22373	Bergua|Borrastre|Fiscal|Lardies|San Juste
22374	Sarvise
22375	Buerba|Buesa|Buisan|Fanlo|Nerin|Vio|Yeba
22376	Torla
22377	Fragen
22378	Linas De Broto
22390	Artasona|El Grado|Grado, El (Poblado)|Presa Del Cinca
22391	Torreciudad (Santuario)
22392	Abizanda|Solanilla
22393	Escanilla|Lamata|Liguerre De Cinca
22394	Castejon De Sobrarbe|Jabierre De Olson|Mediano|Mondot|Olson|Pardina, La (Ainsa)|Samitier
22395	Camporrotuno|Coscojuela De Sobrarbe|Morillo De Tou
22400	Monzon
22410	Alcolea De Cinca
22411	Santalecina
22412	Estiche De Cinca
22413	Pomar De Cinca|San Miguel De Cinca
22414	Conchel
22415	Fornillos De Ilche|Ilche|Monesma De San Juan|Morilla|Odina|Permisan|Selgua
22416	Alfantega|Pueyo De Santa Cruz
22417	Ariestolas|Cofita
22420	Almunia De San Juan
22421	Alins Del Monte|Azanuy
22422	Fonz
22423	Estadilla
22424	Estada
22430	Graus
22435	La Puebla De Castro
22436	Bellestar (Graus)|Benavente De Aragon|Torre De Esera|Ventas De Santa Lucia
22437	Abenozas|Centenera|Coll De Oliva|Coronas|La Puebla De Fantova
22438	Clamosa|Ejep|Panillo|Pano|Salinas De Trillo|Torre De Obato|Trillo|Troncedo
22439	Olvena|Secastilla|Ubiergo
22440	Benasque
22449	Cerler
22450	Beleder|Campo|Senz|Viu
22451	Aguascaldas|Biescas De Campo|Egea|Espluga|Llert|Padarniu|Pueyo (Valle De Lierp)|Sala|Santa Maura|Serrate|Valle De Bardaji|Vilas Del Turbon, Las (Balneario)
22452	Atiart|Foradada Del Toscar|Fosado|Fuendecampo|La Cabezonada|Lacort (Foradada Del Toscar)|Las Colladas|Navarri|Samper|San Juan (La Fueva)
22460	Besians|Perarrua
22461	Aguilar|Santa Liestra Y San Quilez
22462	Bacamorta|Morillo De Liena
22463	Abi|Seira
22464	Barbaruens
22465	Chia|El Run
22466	Arasan|Castejon De Sos|Liri|Urmella
22467	Eresue|Ramastue|Sesue|Sos|Villanova
22468	Guayente (Santuario)|Sahun
22469	Anciles|Eriste
22470	Bisaurri|Buyelgas|Dos|Gabas|La Muria|Renanue|San Feliu De Veri|San Martin De Veri|Veri
22471	Laspaules|Villarue
22472	Abella|Espes|Espes Alto
22473	Alins|Neril|Señiu|Suils|Villaplana
22474	Ardanue|Ardanuy|Benifons|Castanesa|Denuy|Ervera|Escane|Fonchanina|Las Llagunas|Noales|Ribera (Montanuy)
22480	Capella|El Soler|Torrelabad
22481	Guel
22482	Esdolomada|Huerta De Roda|La Puebla De Roda|Merli|Roda De Isabena|San Esteban Del Mall
22483	Barrio Del Pou|Reperos|Riguala De Serraduya|Serraduy|Torre La Ribera|Vileta De Serraduy|Villacarli
22484	Ballabriga|Beranuy|Biascas De Obarra|Pardinella|Visalibons
22485	Calvera|Herrerias De Calvera|Morens|Obarra (Monasterio)
22486	Bibiles|Bonansa|Buira|Castarnes|Cires|Gabarret|Torre De Buira
22487	Aneto|Bono|Estet|Forcat|Ginaste|Montanuy|Viñal
22500	Binefar
22510	Binaced
22511	Valcarca
22512	San Esteban De Litera
22513	Peralta De La Sal
22514	Calasanz|Gabasa
22520	Fraga|Litera (Fraga) (Partida)
22528	Velilla De Cinca
22529	Miralsot
22530	Zaidin
22531	Almudafar
22532	Osso De Cinca
22533	Belver De Cinca|Valonga
22534	Albalate De Cinca
22535	Esplus
22536	Monte Julia
22540	Altorricon
22549	La Melusa|San Miguel|Vencillon
22550	Tamarite De Litera
22558	Albelda
22559	Algayon
22560	Alcampell
22569	Baells|Cuatrocorz|Nacha|Saganta|Zurita
22570	Camporrells
22571	Baldellou
22572	Castillonroy|Santa Ana
22580	Benabarre
22583	Aren|Berganuy|Betesa|Campamento De Aren|Casa Consistorial|El Castellet|El Pont D'Orrit|El Sas|Espluga De Serra|Espluga Freda|La Torre De Tamurcia|Masos De Tamurcia, Els|Molinos, Los (Aren)|Pallerol|Puimolar|Rivera De Vall|San Martin (Aren)|Santorens|Sapeira|Sobrecastell|Sopeira|Soperun
22584	Chiriveta|Escarla|Espills|Montañana|Puente De Montañana|Tercui|Torogo|Torre Baro
22585	Almunia De San Lorenzo|Litera|Luzas|Sagarras Bajas|Tolva|Viacamp
22586	Lascuarre
22587	Badias De Monesma|Cajigar|Castigaleu|Laguarres|Monesma (Cajigar)|Pociello
22588	Aguinaliu|Juseu|La Puebla De Mon|Pueyo De Marguillen|Torres Del Obispo
22589	Aler|Antenza|Caladrones|Caserras Del Castillo|Castillo Del Pla|Ciscar|Estaña|Estopiñan|Mas Blanc|Pilzan|Purroy De La Solana
22590	Torrente De Cinca
22591	Candasnos
22592	Peñalba
22600	Sabiñanigo
22609	Aurin|Puente De Sabiñanigo|Sabiñanigo (Pueblo)
22610	Allue|Yebra De Basa
22611	Fanlillo|Orus|Osan|San Julian De Basa|Sobas
22612	Acumuer|Borres|Cartirana|Larres
22613	Isun De Basa|Javierre Del Obispo|Latas|Sardas|Satue
22620	Abena|Ara|Arto|Binue|Ibort|Latras|Orna De Gallego
22621	Abenilla|Barangua|Castillo De Leres|Hostal De Ipies|Ipies|Lanave|Lasieso|Layes|Leres|Rapun
22622	Arraso|Castiello De Guarga|Gesera|Grasa|Ordoves|San Esteban De Guarga|Yespola
22623	Aineto|Ceresola|Gillue|Laguarta|Molino De Villobas
22624	Caldearenas|Javierrelatre|Latre
22625	Aquilue|Estallo|San Vicente (Caldearena)|Serue
22630	Biescas
22636	Arguisal|Escuer|Olivan|Oros Bajo
22637	Barbenuta|Espierre|Oros Alto
22638	Aso De Sobremonte|Betes De Sobremonte|Yosa De Sobremonte
22639	Gavin|Yesero
22640	Formigal|Sallent De Gallego
22650	Panticosa (Balneario)
22660	Escarrilla
22661	Panticosa (Pueblo)
22662	El Pueyo De Jaca|Hoz De Jaca
22663	Tramacastilla De Tena
22664	Sandinies
22665	Piedrafita De Jaca|Saques
22666	Larrede|Senegue|Sorripas
22700	Jaca
22710	Bescos De Garcipollera|Castiello De Jaca|Villanovilla
22711	Bernues|Botaya
22712	Baros|Noves|Ulle
22713	Abay|Araguas Del Solano|Asieso|Banaguas|Canias|Fraginal Alto|Fraginal Bajo|Guasillo|Lastiesas Altas|Lastiesas Bajas
22714	Baraguas|Espuendolas|Gracionepel|Guasa|Ipas|Jarlata|Leres De Jaca|Martillue|Navasa|Navasilla|Orante|Pardinilla|Sasal
22715	Ascara|Atares
22720	Hecho|Santa Lucia
22728	Anso
22729	Fago
22730	Aragues Del Puerto
22731	Jasa
22732	Urdues
22740	Embun
22750	Javierregay
22751	Arres|Santa Engracia
22752	Somanes
22753	Puente La Reina
22760	Alastruey|Arbues|Bailo
22761	Larues
22770	Berdun
22771	Majones|Villarreal De La Canal
22772	Martes
22773	Binies
22790	Siresa
22791	Binacua|Santa Cilia
22792	Santa Cruz De La Seros
22800	Ayerbe
22806	Moran|Santa Eulalia De Gallego
22807	Biscarrues|Eres|Losanglis|Piedramorrera
22808	Aguero|Las Peñas De Riglos|Murillo De Gallego|Riglos|San Felices (Aguero)
22809	Fontellas|Linas De Marcuello|Loarre|Loscorrales|Santa Engracia (Loarre)|Sarsamarcuello
22810	Esquedas|Las Casas De Nuevo|Plasencia Del Monte|Quinzano
22811	Lupiñen|Montmesa|Ortilla
22820	La Peña|Santa Maria (P. De Riglos)|Triste|Yeste
22821	Rasal
22822	Salinas De Jaca|Villalangua
22830	Anzanigo|Centenero|Ena|Osia
22860	Aisa|Aratores|Borau|Esposa|Sinues
22870	Villanua
22880	Canfranc (Estacion)
22888	Canfranc (Pueblo)
22889	Astun|Candanchu
23001	Jaen
23002	Jaen
23003	Jaen
23004	Jaen
23005	Jaen
23006	Jaen
23007	Jaen
23008	Jaen
23009	Jaen
23070	Jaen
23071	Jaen
23080	Jaen
23100	Mancha Real
23110	Pegalajar
23120	Cambil
23130	Campillo De Arenas
23140	Noalejo
23150	Valdepeñas De Jaen
23159	Chircales
23160	Jaen|Los Villares
23170	La Guardia De Jaen
23180	Fuerte Del Rey
23190	La Cerradura
23191	Carchel
23192	Carchelejo
23193	Arbuniel
23194	Jabalcuz
23196	Puente De La Sierra|Puente Jontoya
23200	La Carolina
23210	Aldea De Los Rios|Guarroman
23211	Acebuchal|Carboneros
23212	Navas De Tolosa
23213	Miranda Del Rey|Santa Elena
23214	El Centenillo|La Fernandina|La Isabela
23215	Aldeaquemada
23220	Vilches
23230	Arquillos
23239	El Porrosillo
23240	Navas De San Juan
23250	Santisteban Del Puerto
23260	Castellar
23264	Chiclana De Segura
23265	Venta De Los Santos
23266	Montizon
23267	Aldeahermosa De Montizon
23268	Los Mochuelos
23269	Camporredondo|El Campillo|La Porrosa
23270	Sorihuela De Guadalimar
23280	Beas De Segura
23289	Cañada Catena|Cuevas De Ambrosio|Prados De Armijo
23290	El Cerezo|El Patronato|La Matea|Los Teatinos|Santiago De La Espada
23291	Ponton Alto|Pontones
23292	Cañada Morales|Hornos De Segura
23293	Arroyo Frio (Segura De La Sierra)|Carrasco|Catena Alto|Cortijos Nuevos|El Ojuelo|Rihornos|Robledo Cortijos Nuevos
23294	Las Juntas|Los Anchos|Tobos
23295	Rio Madera
23296	La Muela|Marchena|Miller|Vites
23297	Casicas Del Rio Segura|La Toba
23298	Peguera Del Madroño
23300	Arroturas|Villacarrillo
23310	Batanejo|Mogon
23311	Agrupacion Santo Tome|Santo Tome
23312	Agrupacion De Mogon|Caleruela
23313	Veracruz, De (Poblado)
23314	Solana De Torralba
23315	La Herrera|Puente Del Condado
23320	Torreperogil
23330	Villanueva Del Arzobispo
23338	Iznatoraf
23339	Gutar
23340	Arroyo Del Ojanco
23350	Puente Genave
23359	Peñolite
23360	La Puerta De Segura
23369	Agracea|Bonache|Los Pascuales|Los Yeguerizos
23370	Orcera
23379	El Batan|Segura De La Sierra
23380	Siles
23390	Benatae
23391	Torres De Albanchez
23392	Genave
23393	Onsares|Villarrodrigo
23400	Ubeda
23410	Sabiote
23411	Yedra
23412	El Marmol
23413	Santa Eulalia
23420	Canena
23430	Rus
23440	Baeza
23450	Ibros
23460	Peal De Becerro
23468	Hornos De Peal
23469	El Molar|Puente De La Cerrada|San Miguel|Valdecazorla
23470	Cazorla|Cañada Del Moro
23476	La Iruela
23477	Chilluevar|Chilluevar La Vieja|Los Almansas
23478	Coto Rios|Loma De Maria Angela
23479	Arroyo Frio (La Iruela)|Burunchel|El Palomar|San Martin|Vadillo Castril
23480	Quesada
23485	El Almiceran|Pozo Alcon
23486	Fontanar|Hinojares
23487	Huesa
23488	Acra|Bruñel Alto|Bruñel Bajo|Higueral|Los Rosales
23489	Belerda Alta|Belerda Baja|Tiscar Don Pedro
23490	Linares-Baeza (Estacion)
23499	Mira El Rio
23500	Jodar
23509	El Donadio
23510	Torreblascopedro
23519	Campillo Del Rio|Guadalimar
23520	Begijar
23526	Sotogordo
23528	Lupion
23529	El Boticario|Estacion De Begijar|Puente Del Obispo|Vados De Torralba
23530	Jimena
23537	Bedmar
23538	Albanchez De Magina
23539	Garciez|Las Escuelas
23540	Torres
23550	Cabra De Santo Cristo
23560	Huelma
23568	Belmez De La Moraleda
23569	La Cabrita|Las Capellanias|Solera
23590	Cabra De Santo Cristo (Estacion)
23591	Larva
23600	Martos
23610	Fuensanta De Martos
23611	Higuera De Calatrava
23612	Santiago De Calatrava
23613	Lendinez
23614	La Carrasca|Las Casillas De Martos
23615	Media Panilla|Monte Lope Alvarez
23616	Veletas
23620	Mengibar
23628	Cazalilla|Espeluy
23630	Villargordo
23638	Torrequebradilla
23639	Las Infantas|Villargordo (Estacion)
23640	Torre Del Campo
23649	Garciez (Torre Del Campo)
23650	Torredonjimeno
23657	Escañuela
23658	Jamilena
23659	Villardompardo
23660	Alcaudete
23669	Bobadilla, La (Alcaudete)|Noguerones|Venta De Pantalones
23670	Castillo De Locubin
23680	Alcala La Real
23684	La Rabita|San Jose De La Rabita
23685	El Sabariego|Las Grageras|Puertollano
23686	Casillas De Mures|Ermita Nueva, Aldea|Las Pilillas|Mures
23687	Charilla
23688	La Pedriza|Venta De Los Agramaderos
23689	Fuente Alamo|Hortichuela|Las Pilas De Fuente De Soto|Peñas De Majalcoron
23690	Frailes
23691	Ribera Alta|Ribera Baja
23692	Fuente Del Rey|Santa Ana
23693	Ventas Del Carrizal
23700	Linares|Vega Santa Maria (Linares)
23710	Bailen
23711	Baños De La Encina
23712	Jabalquinto
23713	Guadalen|Magdalena De Castro-Los Tercios
23730	Villanueva De La Reina
23740	Andujar
23746	Lahiguera
23747	La Ropera|Llanos Del Sotillo|Vegas De Triana
23748	Virgen De La Cabeza, Santuario|Viñas De Peñallana
23749	La Quinteria|Los Villares De Andujar
23750	Arjonilla
23760	Arjona
23770	Marmolejo
23780	Lopera
23790	Porcuna
24001	Leon
24002	Leon
24003	Leon
24004	Leon
24005	Leon
24006	Leon
24007	Leon
24008	Leon
24009	Armunia|Leon|Oteruelo De La Valdoncina|Poligono Villacedre|Villacedre
24010	Leon
24070	Leon
24071	Leon
24080	Leon
24100	Villablino
24110	Caboalles De Abajo
24111	Caboalles De Arriba
24112	Villager De Laciana
24113	Orallo
24114	Llamas De Laceana|Rabanal De Abajo|Rabanal De Arriba
24120	Canales-La Magdalena|Garaño
24121	Azadinos|Pobladura De Bernesga|Sariegos Del Bernesga
24122	Lorenzana
24123	Benllera|Carrocera|Cuevas De Viñayo|Otero De Las Dueñas|Piedrasecha|Santiago De Las Villas|Viñayo
24124	Bobia|Formigones|Quintanilla|Villapodambre
24125	Camposalinas|Carrizal De Luna|Irian|Santovenia De San Marcos|Soto Y Amio|Villaceid
24126	Lago De Omaña|Oterico|Villayuste
24127	Andarraso|Ariego De Abajo|Ariego De Arriba|Bonella|Campo De La Lomba|Castro De La Lomba|Ceide|Curueña|Folloso|Inicio|La Garandilla|La Urz|La Utrera|La Velilla|Murias De Ponjos|Paladin|Ponjos|Riello|Robledo De Omaña|Rosales|Santibañez De La Lomba|Socil|Trascastro De Luna|Valdesamario|Villarin De Riello
24130	Montrondo|Murias De Paredes
24131	Guisatecha|La Omañuela
24132	Arienza|Cornombre|El Castillo|Garueña|Manzaneda De Omaña|Pandorado|Salce|Santibañez De Arienza|Sosas Del Cumbral|Vegarienza
24133	Aguasmestas, Ventas De|Barrio De La Puente|Cirujales|Fasgar|Marzan|Posada De Omaña|Torrecillo|Valbueno|Vegapujin|Villadepan|Villar De Omaña|Villaverde De Omaña
24134	Omañon|Rodicol|Sabugo
24135	Villanueva De Omaña
24136	Lazado|Senra|Villabandin
24137	Los Bayos|Vivero De Omaña
24138	Villar De Santiago
24139	Rioscuro|Robles De Laciana|Sosas De Laciana
24140	Lumajo|Villaseca De Laciana
24141	Carrasconte|La Cueta|La Vega De Los Viejos|Meroy|Piedrafita De Babia|Quejo|Quintanilla De Babia
24142	Cabrillanes|Lago De Babia|Las Murias|Mena|Peñalba De Cilleros
24143	Cospedal|Huergas De Babia|La Riera|Riolago|Robledo De Babia|San Felix De Arce|Torre De Babia
24144	Candemuela|Genestosa|La Majua|Pinos|Puente Orugo|San Emiliano|Torrebarrio|Torrestio|Truebano|Villargusan|Villasecino
24145	Abelgas|Pobladura De Luna|Rabanal De Luna|Sena De Luna|Villafeliz De Babia
24146	Aralla|Caldas De Luna|La Vega De Robledo|Robledo De Caldas
24148	Irede De Luna|Los Barrios De Luna|Mallo De Luna
24149	Mora De Luna|Portilla De Luna|Saguera De Luna|Vega De Los Caballeros
24150	Ambasaguas De Curueño|Barrio De Nuestra Señora|Cerezales Del Condado|Devesa De Curueño
24151	Barrillos De Curueño|Gallegos De Curueño
24152	Candanedo De Boñar|Lugan|Vegaquemada
24153	Castro Del Condado|Santa Maria Del Monte Condado|Vegas Del Condado
24154	San Cipriano Del Condado|San Vicente Del Condado|Villanueva Del Condado
24155	Moral Del Condado|Represa Del Condado|Secos Del Porma O Del Condado|Villafruela De Condado|Villamayor Del Condado
24156	Navafria|Santa Olaja Del Porma|Santibañez De Porma
24160	Garfin|Gradefes|Nava De Los Caballeros|Valdealcon
24161	Carbajal De Rueda|Herreros De Rueda|Llamas De Rueda|Sahechores|Villacidayo|Villanofar
24162	Villafañe
24163	Castrillo Del Condado|Palazuelo De Eslonza|Villaburbula|Villimer
24164	Santa Olaja De Eslonza|Villarmun
24165	Cañizal De Rueda|Mellanzos|Valdealiso|Valduvieco|Villarratel
24166	Casasola De Rueda|Cifuentes De Rueda|Rueda Del Almirante|San Miguel De Escalada
24170	Almanza|Calaveras De Abajo|Calaveras De Arriba|Canalejas|Corcos
24171	Arcayos|Castromudarra|Valdavida|Villaverde De Arcayos
24172	Bustillo De Cea|Mozos De Cea|Sahelices Del Rio|Valdescapa|Villacalabuey
24174	Cea
24175	Villamol|Villapeceñil
24191	Leon|Villabalter
24192	Trobajo Del Cerecedo|Vilecha
24193	Leon|Navatejera|Villaquilambre|Villasinta
24195	Carbajosa|Golpejar De La Sobarriba|Santovenia Del Monte|Tendal|Villafeliz De La Sobarriba|Villamoros De Las Regueras|Villaobispo De Las Regueras|Villavente
24196	Carbajal De La Legua
24197	Canaleja|Castrillino|Robledo De Torio|Villanueva Del Arbol|Villarrodrigo De Las Regueras
24198	La Virgen Del Camino
24199	Alija De La Ribera|Castrillo De La Ribera|Marialba De La Ribera|Santa Olaja De La Ribera
24200	Valencia De Don Juan
24205	Cabañas
24206	Carbajal De Fuentes|Castilfale|Fafilas|Fuentes De Carbajal|Valdemora|Villabraz
24207	Alcuetas|Matanza De Los Oteros|Valdespino Ceron|Zalamillas
24208	Quintanilla De Oteros|Valdesaz De Los Oteros
24209	Fuentes De Los Oteros|Gusendos De Los Oteros|Pajares De Los Oteros|San Roman De Los Oteros
24210	Mansilla De Las Mulas
24217	Mansilla Mayor|Nogales De Mansilla|Villacelama|Villamoros De Mansilla|Villanueva De Las Manzanas|Villaverde De Sandoval
24218	Mansilla Del Esla (Urbanizacion)|Villalquite|Villomar
24219	Valle De Mansilla|Vega De Los Arboles|Villacontilde|Villafale|Villasabariego|Villiguer
24220	Valdefuentes De Valderas|Valderas
24221	Campazas
24222	Castrofuerte|Villaornate
24223	Fresno De La Vega|Morilla De Los Oteros|Pobladura De Los Oteros
24224	Cabreros Del Rio|Cubillas De Los Oteros|Gigosos De Los Oteros|Jabares De Los Oteros|Velilla De Los Oteros
24225	Campo De Villavidel|Corbillos De Los Oteros|Nava De Los Oteros|Palanquinos|Rebollar De Los Oteros|Riego Del Monte|San Justo De Los Oteros|Villavidel
24226	Mancilleros|Marne|Roderos|San Justo De Las Regueras|Toldanos|Valdesogo De Abajo|Valdesogo De Arriba|Villarente|Villarroañe|Villaturiel
24227	Arcahueja|Lomas, Las (Urbanizacion)|San Felismo|Valdelafuente|Villacete
24228	Corbillos De La Sobarriba|Paradilla De La Sobarriba|Solanilla|Valdefresno|Villacil|Villalboñe|Villaseca De La Sobarriba
24230	Valdevimbre
24231	Cembranos|Onzonilla|Viloria De La Jurisdicion
24232	Ardon|Fresnellino Del Monte|San Cibrian De Ardon
24233	Benamariel|Benazolve|Villalobar
24234	Cabañeros|Conforcos|Laguna De Negrillos|San Esteban De Villacalbiel|Villacalbiel|Villace|Villamañan|Villamor De La Laguna|Villamorico
24235	Villaquejida
24236	Villafer
24237	San Millan De Los Caballeros|Toral De Los Guzmanes|Villademor De La Vega
24238	Algadefe|Villamandos|Villarrabines
24239	Bariones De La Vega|Cimanes De La Vega|Lordemanos
24240	Santa Maria Del Paramo
24248	Antoñanes Del Paramo|Grisuela Del Paramo|Laguna Dalga|Mansilla Del Paramo|Matalobos Del Paramo|San Pedro De Las Dueñas (Santa Maria Del Paramo)|Urdiales Del Paramo
24249	Pobladura De Pelayo Garcia|Santa Cristina Del Paramo|Soguillo Del Paramo|Villaestrigo|Villar Del Yermo|Zambroncinos|Zotes Del Paramo|Zuares Del Paramo
24250	Fontecha|Meizara|Mozondiga|Palacios De Fontecha|Pobladura De Fontecha|Vallejo|Villagallegos|Villibañe
24251	Antimio De Abajo|Ardoncino|Banuncias|Cillanueva
24252	Bercianos Del Paramo|La Mata Del Paramo|San Pedro Bercianos|Villarrin Del Paramo
24253	Azares Del Paramo|Valdefuentes Del Paramo
24257	Cerecedo De Boñar
24260	Ferral, Base Militar
24270	Carrizo De La Ribera|Villanueva De Carrizo
24271	Llamas De La Ribera|Quintanilla De Sollamas|San Roman De Los Caballeros|Villaviciosa De La Ribera
24272	Azadon|Cimanes Del Tejar|Velilla De La Reina
24273	Las Omañas|Mataluenga|Pedregal|San Martin De La Falamosa|Santiago Del Molinillo|Secarejo|Villarroquel
24274	Espinosa De La Ribera
24275	Rioseco De Tapia|Selga De Ordas|Tapia De La Ribera
24276	Santa Maria De Ordas|Santibañez De Ordas|Villarrodrigo De Ordas
24277	Adrados De Ordas|Callejo De Ordas|Riocastrillo De Ordas
24280	Benavides De Orbigo
24281	Antoñan Del Valle|Quintanilla Del Valle|Vega De Antoñan
24282	Ferral Del Bernesga|Montejos Del Camino
24283	Huerga Del Rio|La Milla Del Rio|Quiñones Del Rio
24284	Armellada
24285	Gavilanes|Palazuelo De Orbigo|Quintanilla Del Monte|Riofrio|Turcia
24286	Hospital De Orbigo|Puente De Orbigo
24287	Gualtares De Orbigo|Moral De Orbigo|San Feliz De Orbigo
24288	Estebanez De La Calzada|Santibañez De Valdeiglesias|Valdeiglesias|Villares De Orbigo
24290	Matallana De Valmadrigal|Santa Cristina De Valmadrigal
24291	Fontanil De Los Oteros|Matadeon De Los Oteros|San Pedro De Los Oteros|Santa Maria De Los Oteros
24292	Valverde Enrique
24293	Albires|Izagre|Valdemorilla
24294	Gordoncillo
24300	Bembibre
24310	Albares De La Ribera|La Ribera De Folgoso
24311	Folgoso De La Ribera
24312	Boeza|Igueña
24313	Colinas Del Campo|Los Montes De La Ermita|Urdiales De Colinas
24314	Castropodame|Matachana|Villaverde De Los Cestos
24315	El Valle|Rozuelo|San Esteban De Toral|Santibañez De Toral|Tedejo|Villaviciosa De San Miguel
24316	San Pedro Castañero|Turienzo Castañero|Viloria
24317	Las Ventas De Albares|San Andres De Los Puentes
24318	Losada|Rodanillo|San Roman De Bembibre
24319	Arlanza|Cabanillas De San Justo|Labaniego|Noceda|Quintana De Fuseros|San Justo De Cabanillas|Viñales
24320	Sahagun
24323	Castrotierra De Valmadrigal|Castrovega De Valmadrigal|Veguellina, La (Sahagun)
24324	Joarilla De Las Matas|San Miguel De Montañan|Valdespino Vaca|Vallecillo|Villeza
24325	Bercianos Del Real Camino|Gordaliza Del Pino
24326	Celada De Cea|Joara|Riosequillo|San Martin De La Cueza|Villalebrin|Villalman
24327	Castrillo De Valderaduey|Renedo De Valderaduey|Velilla De Valderaduey|Villadiego De Cea|Villavelasco De Valderaduey
24328	Carbajal De Valderaduey|San Pedro De Valderaduey|Sotillo De Cea|Villazanzo De Valderaduey
24329	Arenillas De Valderaduey|Galleguillos De Campos|San Pedro De Las Dueñas (Sahagun)
24330	Santas Martas|Valdearcos
24339	Grajalejo De Las Matas|Luengos|Malillos|Reliegos|Villamoratiel De Las Matas
24340	Grajal De Campos
24341	Escobar De Campos
24342	Calzada Del Coto|Codornillos
24343	Banecidas|Calzadilla De Los Hermanillos|Castellanos|El Burgo Ranero|Grañeras|Santa Maria De Monte Cea
24344	Castroañe|Santa Maria Del Rio|Villaceran|Villacintor|Villamartin De Don Sancho|Villamizar|Villamuñio|Villaselan
24345	Villamarco
24346	Grulleros|Vega De Infanzones
24347	Sotico|Torneros Del Bernesga|Villadesoto
24350	Veguellina De Orbigo
24356	Barrio De Buenos Aires|Castrillo De San Pelayo|Huerga De Frailes|San Pedro De Pegas|San Pelayo Del Paramo|Santa Marinica Del Paramo
24357	Acebes Del Paramo|Bustillo Del Paramo
24358	Veguellina De Fondo|Villarejo De Orbigo|Villoria De Orbigo
24360	Brañuelas
24367	Villagaton
24368	Culebros|Los Barrios De Nistoso|Requejo Y Corus|Tabladas|Villar (Nistoso)
24369	Manzanal Del Puerto|Ucedo|Valbuena De La Encomienda
24370	Torre Del Bierzo
24374	Almagarinos|Cerezal De Tremor|Tremor De Abajo
24375	Pobladura De Las Regueras|Rodrigatos De Las Regueras
24376	Espina De Tremor
24377	Tremor De Arriba
24378	Fonfria|La Granja De San Vicente|San Facundo|Santa Marina De Torre
24379	La Silva|Montealegre|Santa Cruz De Montes|Santibañez De Montes
24380	Puente Domingo Florez
24384	Salas De La Ribera
24385	San Pedro De Trones
24386	Vega De Yeres|Yeres
24387	Robledo De Sobrecastro
24388	Llamas De Cabrera|Lomba|Santalavilla|Sigueya|Silvan|Yebra
24389	Benuza|Castroquilame|Pombriego|Sotillo De Cabrera
24390	Dehesas|Posada Del Bierzo|Villaverde De La Abadia
24391	Aldea De La Valdoncina|Antimio De Arriba|Fresno Del Camino|Oncina De La Valdoncina|Quintana De Raneros|Ribaseca|Robledo De La Valdoncina|San Miguel Del Camino|Santovenia De La Valdoncina|Valverde De La Virgen|Villanueva Del Carnero
24392	Celadilla Del Paramo|Chozas De Abajo|Chozas De Arriba|Fojedo|Villadangos Del Paramo|Villar De Mazarife
24393	Alcoba De La Ribera|La Milla Del Paramo|San Martin Del Camino|Santa Marina Del Rey|Sardonedo|Villamor De Orbigo|Villavante
24394	Barrientos|Carral
24395	Celada|Cuevas De La Sequeda|Nistal
24396	Benamarias|Magaz De Cepeda|Vanidodes|Vega Magaz|Zacos
24397	Abano|Castro De Cepeda|Donillas|Escuredo|Ferreras De Cepeda|La Veguellina De Cepeda|Morriondo|Palaciosmil|Porqueros|Quintana Del Castillo|San Feliz De Las Lavanderas|Villameca|Villarmeriel
24398	Almazcara|Calamocos|Castrillo Del Monte|Cobrana|Congosto|San Miguel De Las Dueñas
24400	Ponferrada
24401	Ponferrada
24402	Ponferrada
24403	Ponferrada
24404	Ponferrada
24410	Camponaraya|Hervededo|La Valgoma|Magaz De Abajo|Magaz De Arriba|Narayola
24411	Fuentes Nuevas
24412	Cabañas Raras|Cortiguera
24413	Acebo De San Miguel|Folgoso Del Monte|Molinaseca|Onamio Y Poblado M.S.P.|Paradasolana|Riego De Ambros
24414	Bouzas|Campo|Carracedo De Compludo|Compludo|Espinoso Compludo|Lombillo (Barrios De Salas)|Palacios De Compludo|Salas De Los Barrios|San Cristobal De Valdueza|Villar De Los Barrios
24415	Manzanedo De Valdueza|Montes De Valdueza|Otero|Ozuela|Peñalba De Santiago|San Adrian De Valdueza|San Clemente De La Valdueza|San Esteban De Valdueza|San Lorenzo|Santa Lucia|Valdecañada|Valdefrancos|Villanueva De Valdueza
24416	Santo Tomas De Las Ollas
24420	Fabero
24428	Lillo Del Bierzo|Otero De Naraguantes
24429	Barcena De La Abadia|Cariseda|Chano|Faro|Fresnedelo|Guimara|Peranzanes|San Pedro De Paradela|Trascastro
24430	Vega De Espinareda
24433	Balouta|Candin|Espinareda De Ancares|Lumeras|Pereda De Ancares|Sorbeira|Suarbol|Suertes|Tejedo De Ancares|Villarbon|Villasumil
24434	Fontoria|Sesamo|Villar De Otero
24435	Valle De Finolledo
24436	Moreda|San Martin De Moreda|San Pedro De Olleros
24437	Burbia|Bustarga|Penoselo|Penoselo (Fabero)
24438	Berlanga Del Bierzo|Langre|San Miguel De Langre|Tombrio De Abajo|Tombrio De Arriba
24439	El Espino|Espinareda De Vega|Ocero|Sancedo
24440	Lago De Carucedo
24441	Campañana|Carril|La Barosa|Valiña|Villarrando
24442	Carucedo|Las Medulas
24443	Borrenes|San Juan De Paluezas
24444	La Chana|Orellan|Voces
24445	Santalla
24446	Paradela De Muces|Villavieja
24447	Villalibre De La Jurisdicion
24448	Priaranza Del Bierzo|Rimor|Toral De Merayo
24450	Toreno
24457	Libran|Pardamaza
24458	Robledo De Las Traviesas|Villar De Las Traviesas
24459	Pradilla|Valdelaloba
24460	Matarrosa Del Sil
24469	San Pedro Mallo|Santa Leocadia|Villamartin Del Sil
24470	Paramo Del Sil
24478	Argayo|Sorbeda
24479	Primout|Salentinos
24480	Corbon Del Sil
24488	Anllares Del Sil|Anllarinos Del Sil
24489	Susañe Del Sil
24490	Columbrianos
24491	Barcena Del Bierzo|San Andres De Montejos
24492	Cabañas De La Dornilla|Cubillinos|Cubillos Del Sil|Finolledo|Fresnedo|Posadinas
24493	Santa Marina Del Sil
24494	Santa Cruz Del Sil
24495	Matalavilla|Palacios Del Sil|Salientes|Valseco
24496	Cuevas Del Sil|Mataotero
24497	Tejedo Del Sil
24498	Villarino Del Sil
24500	Villafranca Del Bierzo
24510	Cela|Paradaseca
24511	Campo Del Agua|Porcarizas|Tejeira|Villar De Acero
24512	Paradiña|Pobladura De Somoza|Prado De Paradiña|Veguellina, La (Villafranca)
24513	Landoiro|Puente De Rey
24514	Corullon
24515	Hornija|Melezna|Viariz
24516	Horta|Otero De Villadecanes|Parandones|Vilela
24517	Cadafresnas|Dragonte|Villagroy
24520	Braña, La (Villafranca)|Moñon|Ransinde|Ruitelan|Sampron|Vega De Valcarce
24521	Albaredos|Barjas|Barrosas|Busmayor|Campo De La Liebre|Corporales De Barjas|Corrales De Barjas|Guimil|Hermide|Las Cruces|Moldes|Mosteiros|Peñacaira|Quintela De Barjas|Serviz|Vegas De Seo|Villasinde
24522	Pereje
24523	Moral De Valcarce|Parada De Soto|Paradela De Trabadelo|Pradela|San Fiz Do Seo|Sotelo|Sotoparada|Trabadelo|Villar De Corrales
24524	Ambasmestas|La Portela De Valcarce|Sotogayoso
24525	Balboa|Cantejeira|Castañeiras|Castañoso|Chan De Villar|Fuente De La Oliva|Lamagrande|Parajis|Pumarin|Quintela De Balboa|Ruideferros|Ruydelamas|Valverde De Balboa|Villafeile|Villanueva De Castañeira|Villariños|Villarmarin
24526	Argenteiro|Bargelas|El Castro|La Cernada|La Faba|La Laguna De Castilla|La Treita|Laballos|Las Herrerias De Valcarce|Las Lamas|Lindoso|San Julian|San Tirso De La Faba
24530	Iglesias Del Campo|Valtuille De Abajo|Villadecanes
24540	Cacabelos
24544	Carracedo De Monasterio
24545	Cueto|San Juan De La Mata
24546	Arganza|Campelo|Canedo|Espanillo|San Miguel De Arganza|San Vicente De Arganza
24547	Arborbuena|Pieros|San Clemente|Valtuille De Arriba
24548	Quilos|Villabuena
24549	Carracedelo
24550	Sorribas|Villamartin De La Abadia|Villanueva De La Abadia
24560	Toral De Los Vados
24565	Villadepalos
24566	Leiroso|Oencia|Sanvitul|Villarrubin
24567	Arnadelo|Cabeza De Campo|Cancela|Friera|Sobrado De Aguiar
24568	Arnado|Gestoso|Lusio
24569	Aguiar|Cabarcos|Castropetre|Paradela De Arriba|Paradela Del Rio|Penedelo|Portela De Aguiar|Requejo De Aguiar|Sobredo
24600	La Pola De Gordon
24607	Vega De Gordon
24608	Beberino|Buiza|Cabornera|Folledo|Geras De Gordon|Paradilla De Gordon
24609	Huergas De Gordon|Llombera|Los Barrios De Gordon|Nocedo De Gordon|Peredilla
24610	Campo Y Santibañez
24620	Cabanillas|Cuadros|Valsemana
24630	Cascantes|La Seca
24640	La Robla
24648	Brugos De Fenar|Candanedo De Fenar|Rabanal De Fenar|Robledo De Fenar|Solana De Fenar
24649	Alcedo De Alba|Llanos De Alba|Olleros De Alba|Puente De Alba|Sorribos De Alba
24650	Santa Lucia
24660	Ciñera
24670	La Vid|Villasimpliz
24680	Villamanin
24687	Rodiezmo|Ventosilla
24688	Casares De Arbas|Cubillas De Arbas|Poladura De La Tercia|San Martin De La Tercia|Viadangos De Arbas
24689	Barrio De La Tercia|Fontun|Golpejar De La Tercia|Millaro|Velilla De La Tercia|Villanueva De La Tercia
24690	Arbas Del Puerto|Busdongo
24699	Camplongo|Pendilla|Tonin
24700	Astorga
24710	San Justo De La Vega|San Roman De La Vega
24711	Castrillo De Cepeda|Fontoria De Cepeda|La Carrera De Otero|Villamejil
24712	Cogorderos|Quintana De Fon|Revilla
24713	Sueros De Cepeda
24714	Bonillos|Pradorrey|Requejo De Pradorrey
24715	Combarros|Quintanilla De Combarros|Rodrigatos De La Obispalia|Veldedo
24716	Brazuelo
24717	Boisan|Lagunas De Somoza|Luyego De Somoza|Quintanilla De Somoza|Val De San Lorenzo|Val De San Roman|Valdespino De Somoza|Villalibre De Somoza
24718	Castrillo De Los Polvazares|El Ganso|Murias De Rechivaldo|Santa Catalina De Somoza|Valdeviejas
24719	Brimeda|Otero De Escarpizo|Villaobispo De Otero
24720	Murias De Pedredo|Pedredo|San Martin Del Agostedo
24721	Castrillo De La Valduerna|Priaranza De La Valduerna|Tabuyo Del Monte|Velilla De La Valduerna|Villar De Golfer
24722	Andiñuela|Argañoso|Foncebadon|La Maluenga|Rabanal Del Camino|Rabanal Viejo|Santa Colomba De Somoza|Santa Marina De Somoza|Tabladillo|Turienzo De Los Caballeros|Valdemanzanas|Viforcos|Villar De Los Ciervos
24723	Chana De Somoza|Filiel|Lucillo
24724	Busnadiego|Molinaferrera|Piedrasalvas|Pobladura De La Sierra
24730	Destriana|Posada De La Valduerna|Robledino De La Valduerna|Robledo De La Valduerna|Villalis De La Valduerna
24731	Morales Del Arcediano|Oteruelo De La Valduerna|Piedralba
24732	Curillas|Santiagomillas|Tejados
24733	Quintanilla De Florez|Torneros De Jamuz
24734	Nogarejas|Pinilla De La Valderia|Pobladura Del Yuso
24735	Castrocontrigo
24736	Morla De La Valderia|Torneros De La Valderia
24738	Cunas|Manzaneda De Cabrera|Pozos|Quintanilla De Yuso|Villar Del Monte
24740	Baillo|Corporales|La Cuesta|Truchas|Truchillas|Valdavido
24741	Iruela|Villarino De Cabrera
24742	Castrillo De Cabrera|Odollo
24743	Ambasaguas De Cabrera|Castrohinojo|Quintanilla De Losada
24744	Marrubio|Noceda De Cabrera|Nogar|Robledo De Losada|Saceda De Cabrera
24745	Encinedo|Santa Eulalia De Cabrera|Trabazos
24746	Forna|La Baña|Losadilla
24750	La Bañeza
24760	Calzada De La Valderia|Castrocalbon|Felechares De La Valderia|San Esteban De Nogales|San Felix De La Valderia
24761	Alija Del Infantado
24762	Quintana Del Marco|Santa Elena De Jamuz|Villanueva De Jamuz
24763	Hinojo, De (Caserio)|Regueras De Abajo|Regueras De Arriba|Requejo De La Vega|Valdesandinas|Villazala
24764	Palacios De La Valduerna|San Mames De La Vega|Santa Colomba De La Vega
24765	Castrotierra De La Valduerna|Fresno De La Valduerna|Miñambres De La Valduerna|Redelga De La Valduerna|Valle De La Valduerna
24766	Ribas De La Valduerna|Santiago De La Valduerna|Villamontan De La Valduerna
24767	Herreros De Jamuz|Jimenez De Jamuz|Palacios De Jamuz|Quintana Y Congosto|Tabuyuelo De Jamuz
24768	Alcaidon O Alquidon|Huerga De Garaballes|Oteruelo De La Vega|Soto De La Vega|Vecilla De La Vega
24769	Cebrones Del Rio|San Juan De Torres|San Martin De Torres
24790	Valcabado Del Paramo
24791	Moscas Del Paramo|Roperuelos Del Paramo
24792	Altobar De La Encomienda|Genestacio|La Nora Del Rio|Navianos De La Vega
24793	Bustos|Castrillo De Las Piedras|Matanza De La Sequeda|Valderrey
24794	Riego De La Vega|Toral Del Fondo|Toralino
24795	Posadilla De La Vega|San Cristobal De La Polantera|San Felix De La Vega|Santa Maria De La Isla|Santibañez De La Isla|Villagarcia De La Vega|Villarnera De La Vega
24796	Audanzas Del Valle|Cazanuecos|Grajal De La Ribera|La Antigua|Pozuelo Del Paramo|Ribera De La Polvorosa|Saludes De Castroponce
24797	San Adrian Del Valle
24800	Cistierna
24810	Sabero
24811	Olleros De Sabero
24812	Saelices De Sabero
24813	Fuentes De Peñacorada|Ocejo De La Peña|Santa Olaja De La Varga
24814	Sotillos De Sabero
24815	Modino|Pesquera|Santibañez De Rueda|Sorriba Del Esla
24816	Quintana De La Peña|Valmartino
24820	Matueca De Torio|Pardave|Pedrun De Torio
24830	Barrio De La Estacion (Matallana)
24836	Coladilla|Matallana De Torio (Pueblo)|Serrilla|Valle De Vegacervera|Vegacervera|Villalfeide|Villar Del Puerto
24837	Felmin|Genicera|Gete|Getino|Lavandera|Pedrosa|Rodillazo|Tabanedo|Valdeteja|Valporquero De Torio|Valverde De Curueño|Valverdin
24838	Almuzara|Canseco|Carmenes|Piedrafita La Mediana|Piornedo|Pontedo|Villanueva De Pontedo
24839	La Valcueva|Naredo De Fenar|Orzonaga|Robles De La Valcueva|Valcueva, La - Palazuelo
24840	La Vecilla De Curueño
24843	Llamazares|Lugueros|Redilluera
24844	Cerulleda|Redipuertas|Villaverde De La Cuerna
24845	Arintero|Braña, La (La Vecilla )|Tolibia De Abajo|Tolibia De Arriba
24846	Montuerto|Nocedo De Curueño|Valdorria
24847	La Mata De La Berbula|Otero De Curueño|Ranedo De Curueño|Valdepielago
24848	La Candana De Curueño|La Mata De Curueño|Pardesivil|Santa Colomba De Curueño|Sopeña De Curueño
24849	Aviados|Campohermoso|Correcillas
24850	Boñar
24852	Barrio De Las Ollas|La Mata De La Riva
24853	Oville|Remellan|Valdecastillo
24854	Poblado Del Pantano Del Porma|Rucayo|Valdehuesa
24855	Isoba|Puebla De Lillo|Redipollos|San Isidro
24856	Pallide|Primajas|Reyero|Viego
24857	Cofiñal|Orones|San Cibrian De Somoza|Solle
24858	Colle|Felechas|Grandoso|Llama De Colle|Veneros
24859	Adrados|Vozmediano|Voznuevo
24860	La Devesa De Boñar|Las Bodas|Losilla, La Y San Adrian
24869	Llamera|Palazuelo De Boñar
24870	La Ercina|Oceja De Valdellorma|Sobrepeña
24877	Acisa De Las Arrimadas|Barrillos De Las Arrimadas|Corral De Las Arrimadas|Laiz De Las Arrimadas|Santa Colomba De Las Arrimadas
24878	Fresnedo De Valdellorma|Palacio De Valdellorma|San Bartolome De Rueda|Valporquero De Rueda
24879	La Serna|San Pedro De Foncallada|Yugueros
24880	Puente Almuhey
24882	La Sota De Valderrueda|Soto De Valderrueda|Valderrueda|Villacorta
24883	Caminayo
24884	Morgovejo|Morgovejo, Balneario De
24885	Besande|Prioro|Tejerina
24886	Ferreras Del Puerto|La Red De Valdetuejar|Las Muñecas
24887	El Otero De Valdetuejar|La Mata De Monteagudo|Renedo Del Valdetuejar|San Martin De Valdetuejar|Taranilla|Villalmonte
24888	Cabrera De Almanza|Carrizal De Almanza|Espinosa De Almanza|Quintanilla De Almanza|Vega De Almanza|Villamorisca
24889	Cegoñal|La Espina|Valcuende
24890	Palazuelo De Torio|Riosequino De Torio|San Feliz De Torio|Venta De La Tuerta|Villaverde De Abajo|Villaverde De Arriba
24891	Abadengo De Torio|Fontanos De Torio|Garrafe De Torio|La Flecha De Torio|Manzaneda De Torio|Palacio De Torio|Ruiforco De Torio|Valderilla De Torio
24892	Cebanico|La Riba|Mondreganes|Santa Olaja De La Accion|Valle De Las Casas
24893	Cerezal De La Guzpeña|Llama De La Guzpeña|Prado De La Guzpeña|Robledo De La Guzpeña
24900	Riaño
24911	Boca De Huergano|Siero De La Reina|Valverde De La Sierra
24912	Llanaves De La Reina
24913	Barniedo De La Reina|Espejos De La Reina|Portilla De La Reina|Villafrea De La Reina
24914	Caldevilla|Soto De Valdeon
24915	Cain|Cordiñanes|Llanos De Valdeon|Posada De Valdeon|Prada De Valdeon|Santa Marina De Valdeon
24916	Oseja De Sajambre|Pio De Sajambre|Ribota De Sajambre|Soto De Sajambre|Vierdes De Sajambre
24917	Casasuertes|Cuenabres|Retuerto|Vegacerneja
24918	Carande|Horcadas
24920	Aldea Del Puente|Sahelices Del Payuelo
24930	Quintana De Rueda|Quintana Del Monte|Valdepolo|Villahibiera|Villamondrin De Rueda|Villaverde De La Chiquita
24940	Cubillas De Rueda|Palacios De Rueda|Quintanilla De Rueda|San Cipriano De Rueda|Vega De Monasterio|Villapadierna
24950	Vidanes
24960	Aleje|Alejico|Verdiago
24970	Valdore|Velilla De Valdore
24980	Corniero|Cremenes
24989	Argovejo|Villayandre
24990	Las Salas|Remolina
24991	Ciguera|Lois|Salamon|Valbuena Del Roblo
24994	Buron|Liegos
24995	Lario|Polvoredo
24996	Acebedo|La Uña|Maraña
25001	Lleida
25002	Lleida
25003	Lleida
25004	Lleida
25005	Lleida
25006	Lleida
25007	Lleida
25008	Lleida
25070	Lleida
25071	Lleida
25080	Lleida
25100	Almacelles|La Saira
25109	El Mas Del Lleo
25110	Alpicat|Malpartit
25111	Raimat
25112	Gimenells
25113	Sucs
25114	El Pla De La Font
25120	Alfarras
25121	Andani
25122	Ivars De Noguera
25123	Torrefarrera
25124	Rossello
25125	Alguaire
25126	Almenar
25130	Algerri
25131	Torre-Serona
25132	Benavent De Segria
25133	Vilanova De Segria
25134	La Portella
25135	Albesa
25136	Castello De Farfanya
25137	Corbins
25138	Torrelameu
25139	Menarguens
25140	Arbeca
25141	Torregrossa
25142	Bellvis
25143	El Poal
25144	Arcs, Els
25150	Artesa De Lleida
25151	Aspa
25152	El Cogul
25153	Puigverd De Lleida
25154	Castelldans
25155	Albages, L'
25160	Granyena De Les Garrigues
25161	Alfes
25162	Alcano
25163	El Soleras
25164	Torms, Els
25165	Juncosa
25170	Torres De Segre|Utxesa
25171	Albatarrec
25172	Montoliu De Lleida
25173	Sudanell
25174	Sunyer
25175	Sarroca De Lleida
25176	Torrebesses
25177	Bellaguarda|La Granadella
25178	Bovera
25179	Maials
25180	Alcarras
25181	Soses
25182	Aitona
25183	Seros
25184	Massalc0reig
25185	La Granja D'Escarp
25186	Llardecans
25187	Almatret
25190	Lleida
25191	Lleida
25192	Lleida
25193	Lleida
25194	Lleida
25195	Lleida
25196	Lleida
25197	Lleida
25198	Lleida
25199	Lleida
25200	Cervera
25210	Guissona
25211	Bellvei|Castellmeja|Comabella|Concabella|El Far|El Llor|Florejacs|Gra|Granollers De Florejacs|Guarda - Si - Venes|Hostafrancs|La Morana|Massoteres|Palou|Palouet|Pelagalls|Ratera|Riber|Sant Guim De La Plana|Sant Marti De La Morana|Sedo|Selvanera|Sistero|Talteull|Tarroja De Segarra|Torrefeta|Vicfred
25212	Mont-Roig De Segarra|Pallargues, Les
25213	Bellmunt (Talavera)|Brianço|Civit|Condals, Els|Hostalets De Cervera, Els|Montfar|Pallerols De Talavera|Pavia|Pomar|Rubinat|Sant Antoli I Vilanova|Sant Pere Dels Arquells|Talavera|Vergos
25214	Castellnou D'Oluges|Estaras|Gaver|La Prenyanosa|Malgrat|Montfalco Murallat|Oluges, Les|Santa Fe D, Oluges
25215	Alta-Riba|Malacara|Sant Ramon
25216	Ferran|Gospi|Ivorra|Portell|Viver De Segarra
25217	Ametlla De Segarra, L'|Cabestany|Gramuntell|Granyena De Segarra|La Guardia Lada|La Sisquella|Llindars|Montoliu De Segarra|Vilagrasseta
25218	Aranyo, L'|El Canos|Fonolleres|Granyanella|La Cardosa|La Curullada|La Mora|Molle|Montcortes De Segarra|Tordera
25220	Bell-Lloc D'Urgell
25221	Alamus, Els
25222	Sidamon
25230	Mollerussa
25240	Linyola
25241	Golmes
25242	Miralcamp
25243	El Palau D'Anglesola
25244	Fondarella
25245	Vila-Sana
25250	Bellpuig
25260	Ivars D'Urgell|Montale
25261	Almassor|Vallverd
25262	Barbens|Cases De Barbens, Les|El Bullidor|Seana
25263	Preixana
25264	Vilanova De Bellpuig
25265	Castellnou De Seana
25266	Belianes|Malda
25267	Llorenç De Rocafort (Sant Marti De Riucorb)
25268	Montblanquet|Omells De Na Gaia, Els|Vallbona De Les Monges
25269	Rocallaura
25270	Sant Guim De Freixenet
25271	Amoros|El Castell De Santa Maria|Freixenet I Altadill|La Rabassa|La Tallada|Melio|Montlleo|Montpalau|Palamos|Sant Domi|Sant Guim De La Rabassa|Vergos Guerrejat
25280	Castellvell, El (Olius)|Pi De Sant Just, El (Olius)|Sant Just Joval|Solsona
25281	Hostal Nou, L' (Llobera)|Llobera (Llobera)|Peracamps|Torredenego
25282	Sant Llorenç De Morunys|Vilamantells
25283	Cambrils (Oden)|Canalda|Lladurs|Oden|Torrents, Els
25284	La Coma|La Pedra
25285	Castelltort|Guixers|La Corriu
25286	Besora|Busa|Cases De Posada, Les|Guilanya|La Selva|La Valldora|Linya|Madrona|Mirave|Naves|Olius|Pegueroles|Pinell De Solsones|Sant Climenç|Tentellatge
25287	Ardevol De Pinos|Brics (Olius)|El Miracle|Matamargo|Pinos|Sant Just D'Ardevol|Su|Vallmanya De Pinos
25288	La Llena|Montpolt|Timoneda
25289	Altes|Bassella|Castellar De La Ribera|Ceuro|Clara|Ogern|Pampe|Serinyana
25290	Clariana De Cardener|Freixinet De Riner|Hortoneda De Clariana|Riner|Sant Ponç|Santa Susanna
25300	Tarrega
25310	Agramunt
25315	Butsenit (Montgai)
25316	Pradell|Preixens|Ventoses, Les
25317	Donzell D'Urgell|Mafet|Montclar|Rocaberti De Sant Salvador
25318	Bellver D'Osso|Castellnou D'Osso|Cosco|Montfalco D'Osso|Osso De Sio|Puelles, Les|Puigverd D'Agramunt|Renant
25320	Anglesola
25330	Vilagrassa
25331	Almenara Alta|El Tarros|Guardia, La (Tornabous)|Tornabous
25332	Boldu|La Fuliola
25333	El Castell Del Remei
25334	Castellsera
25335	Bellestar (Penelles)|Falcons|Penelles
25336	Bellmunt D'Urgell
25337	Bellcaire D'Urgell
25340	El Mas De Bondia|Montornes De Segarra|Verdu
25341	Ciutadilla|Guimera|Nalec
25343	Vilet, El (Sant Marti De Riucorb)
25344	Rocafort De Vallbona (Sant Marti De Riucorb)|Sant Marti De Malda (Sant Marti De Riucorb)
25350	Altet
25351	La Figuerosa
25352	Riudovelles
25353	Claravalls
25354	Santa Maria De Montmagastrell
25360	El Talladell
25400	Borges Blanques, Les
25410	Espluga Calba, L'
25411	Fulleda
25412	Omellons, Els
25413	La Floresta
25420	Puiggros
25430	Juneda
25440	Vinaixa
25450	Albi, L'
25457	El Vilosell
25460	Cervia De Les Garrigues
25471	La Pobla De Cervoles
25480	Tarres
25500	La Pobla De Segur
25510	Beranui|La Plana De Mont-Ros
25511	Aguiro|Astell|Oveix
25512	Molinos|Mont-Ros|Paüls|Pobella
25513	Antist|Bretui|Cabestany De Montcortes|Envall|Estavill|La Pobleta De Bellvei|Mentui|Montcortes De Pallars|Montsor|Peracalç
25514	Cadolla|Cervoles|El Burguet|Lluça|Naens|Pinyana|Puigcerver|Reguard|Senterada
25515	Aiguabella|Cabdella|Castell-Estao|Espui|La Torre De Cabdella
25516	Erinya|Sant Joan De Vinyafrescal|Serradell|Toralla|Torallola
25517	Claverol|El Pont De Claverol|Hortoneda De La Conca|Sossis
25518	Aramunt|Pessonada|Sant Marti De Canals
25520	El Pont De Suert
25526	Cabanasses|Cardet|Castillo De Tor|Coll|Llesp|Sarais
25527	Barruera|Durro
25528	Boi|Caldes De Boi|Erill La Vall|Taull
25529	Castellars (El Pont De Suert)|Erill Castell|Gotarta|Iguerri|Iran|Irgo|Malpas|Peranera|Ventola
25530	Vielha/Viella
25537	Arros|Aubert|Betlan|El Pont D'Arros|Mont|Montcorbau|Vila|Vilac
25538	Casau|Gausac
25539	Betren|Casarilh|Escunhau|Garos
25540	Les
25548	Bordius|Campespin|Canejan|Cassenhau, Era|Porcingles|Pradet, Eth|Sant Joan De Toran
25549	Bausen|Pontaut
25550	Bossost
25551	Arres De Jos|Arres De Sus|Arro|Begos|Benos|Bordes, Es|Bordeta, Era (Arres)|Bordeta, Era (Vilamos)|Vilamos
25552	Casos|Vilaller
25553	Senet
25554	Bordes, Les (El Pont De Suert)|Sarroqueta|Viuet
25555	Avellanos|Benes|Buira|Castellnou D'Avellanos|El Mesull|Erdo|Erta|Iglesies, Les|La Bastida De Bellera|La Mola D'Amunt|Laren|Manyanet|Santa Coloma D'Erdo|Sarroca De Bellera|Sas|Sentis|Vilancos|Vilella|Xerallo
25556	Abella D'Adons|Adons|Beguda D'Adons|Corroncui|Perves|Viu De Llevata
25560	Sort
25566	Embonui|Freixe|Llagunes, Les|Rubio (Soriguera)|Soriguera|Vilamur
25567	Altron|Bernui|La Bastida De Sort|Llessui|Sauri|Sorre
25568	Bressui|Castellviny|Enviny|Llarven|Montardit De Dalt|Olp|Pujalt
25569	Malmercat|Puiforniu|Tornafort
25570	Ribera De Cardos
25571	Ainet De Cardos|Arros De Cardos|Boldis Jussa|Boldis Sobira|Cassibros|Esterri De Cardos|Ginestarre
25572	Anas|Bonestarre|Estaon|Surri
25573	Ainet De Besan|Araos
25574	Alins|Noris|Tor
25575	Areu
25576	Lladorre|Lladros|Lleret
25577	Aineto|Tavascan
25580	Esterri D'Aneu
25586	Alos D'Isil|Arreu|Boren|Isavarre|Isil
25587	La Bonaigua|Sorpe|Valencia D'Aneu
25588	Burgo (La Guingueta D'Aneu)|Cerbi (La Guingueta D'Aneu)|Escalarre (La Guingueta D'Aneu)|Gavas (La Guingueta D'Aneu)|Llavorre (La Guingueta D'Aneu)|Unarre (La Guingueta D'Aneu)
25589	Son
25590	Gerri De La Sal
25591	Ancs|Balestui|Cortscastell|El Comte|Peramea|Pujol De Peramea|Sellui
25592	Baen|Bresca|Buseu|Enseu|Sant Sebastia|Solduga|Useu
25593	Arcalis|Baro|Escos|Estac|Mencui
25594	Berani|Caregue|Escas|Montenartro|Rialp|Rodes|Romadriu|Roni|Sant Roma De Tavernoles|Surp
25595	Aidi|Alendo De Farrera|Arestui|Baiasca|Burg|Estaron (La Guingueta D'Aneu)|Farrera|Llavorsi|Montesclado|Tirvia
25596	Escalo (La Guingueta D'Aneu)|Escart (La Guingueta D'Aneu)
25597	Berros Jussa (La Guingueta D'Aneu)|Dorve (La Guingueta D'Aneu)|Espot|Estais|Guingueta, La (La Guingueta D'Aneu)|Jou (La Guingueta D'Aneu)
25598	Bagergue|Baqueira|Gessa|Montgarri|Salardu|Tredos|Unha
25599	Arties
25600	Balaguer
25610	Os De Balaguer
25611	Alberola|Fontdepou|Masos De Milla, Els|Sant Josep De Fontdepou|Tartareu|Vilamajor D'Ager
25612	Avellanes, Les|El Monestir D'Avellanes|Santa Linya|Vilanova De La Sal
25613	Camarasa|Sant Llorenç De Montgai
25614	Gerb
25615	Figuerola De Meia|Fontllonga|La Baronia De Sant Oisme|La Maçana
25616	Montgai
25617	Hostalnou, L' (Vallfogona De Balaguer)|La Rapita|La Sentiu De Sio|Sant Jordi De Muller
25620	Tremp
25630	Talarn
25631	Cellers
25632	Alsamora|Alzina, L' (Sant Esteve De La Sarga)|Beniure|Castellnou De Montsec|Collmorter|Estorm|Guardia De Tremp|La Clua De La Sarga|La Torre D'Amargos|Moror|Sant Esteve De La Sarga|Santa Llucia De Mur|Vilamolat De Mur
25633	Palau De Noguera|Puigcercos|Puigmaçana
25634	Claramunt|El Meull|Figols De Tremp|Puigverd (Tremp)
25635	Castissent|Claret De Tremp|Eroles
25636	Gurp|Santa Engracia
25637	Sant Adria|Tendrui
25638	Aransis|Mata-Solana|Mereia|Obacs De Llimiana, Els|Perolet|Sant Salvador De Tolo|Tolo
25639	Fontsagrada|Gavet De La Conca|Llimiana|Mas De Solduga|Sant Cristofol De La Vall|Sant Marti De Barcedana|Sant Miquel De La Vall|Sant Serni
25640	Academia General Basica De Suboficiales
25650	Isona
25651	Abella De La Conca|Carreu|La Rua|Siall
25652	Boixols
25653	Covet
25654	Suterranya|Vilamitjana
25655	Basturs|Figuerola D'Orcau|Orcau
25656	Conques|Sant Roma D'Abella
25657	Biscarri|Llorda
25658	Benavent De Tremp|Gramenet (Isona I Conca Della)
25660	Alcoletge
25670	Termens
25680	Vallfogona De Balaguer
25690	Vilanova De La Barca
25691	Ager
25692	Agullo|Ametlla De Montsec, L'|Corça|La Regola|Milla
25693	Rivert|Salas De Pallars|Sensui
25700	La Seu D'Urgell
25710	Castellciutat
25711	Montferrer
25712	Albet|Aravell|Bellestar (Montferrer I Castellbo)|Carmeniu|Castellbo|Eres, Les|Sallent De Castellbo|Sant Andreu De Castellbo|Sant Joan De L'Erm|Santa Creu De Castellbo|Seix|Sendes|Solanell|Turbias|Vilamitjana Del Canto
25713	Arfa|La Coma De Nabiners|La Freita|Nabiners
25714	Avellanet|Biscarbo|Canturri|Cassovall|Guils Del Canto|La Parroquia D'Horto|Pallerols Del Canto|Solans
25715	La Bastida D'Hortons
25716	Gosol|Sorribes (Gosol)
25717	Adraen|Barceloneta|Colldarnat|Cornellana|El Ges|Fornols|Josa Del Cadi|Montargull De La Vansa|Ossera|Padrinas|Sant Pere De La Vansa|Sisquer|Sorribes (La Vansa I Fornols)|Tuixent
25718	Alas|Cerc|Ortedo|Sant Antoni (Les Valls De Valira)|Torres D'Alas|Vilanova De Banat
25719	Bescaran|Estamariu
25720	Bellver De Cerdanya
25721	Baltarga|Beders|Bor|Capdevila|Coborriu De Bellver|Cortas|El Pla|Eller|Nas|Olia|Orden|Pedra (Bellver De Cerdanya)|Pi|Prats|Riu De Cerdanya|Riu De Santa Maria|Sansor|Santa Magdalena De Bellver|Tallo|Talltendre|Vilella (Bellver De Cerdanya)
25722	Ansovell|Aristot|Arseguel|Banys De Sant Vicenç, Els|Castellnou De Carcolze|Cava
25723	Bar|El Pont De Bar|El Querforadat|Toloriu
25724	Martinet|Sant Marti Dels Castells
25725	Beixec|Estana|Montella|Villec
25726	Aranser|Lles|Musser|Senillers|Travesseres|Viliella
25727	Ardovol|Prullans
25730	Artesa De Segre
25735	Vilanova De Meia
25736	Alentorn|Argentera|Boada|Garzola|Lluçars|Santa Maria De Meia
25737	Alos De Balaguer|Baldomar|Clua, La (Artesa De Segre)|Cubells|Foradada|La Torre De Fluvia|La Vall D'Ariet|Marcovau|Montsonis|Rubio De Baix|Rubio De Dalt|Rubio Del Mig|Vernet
25738	Anya|Comiols|Folquer|Montargull|Montmagastre|Torrec|Vall-Llebrera
25739	Colldelrat|Collfred|El Pont D'Alentorn|Sero|Tudela De Segre|Vilves
25740	Ponts
25746	El Tossal|Torreblanca
25747	Bellfort|El Puig De Rialb|Gualter|La Serra De Rialb|La Torre De Rialb|Palau De Rialb|Pallerols De Rialb|Polig|Sant Cristofol De La Donzell|Sant Marti De Rialb|Vilaplana
25748	Alzina, L' (Vilanova De L'Aguda)|Cabanabona|Guardiola De L'Aguda|Plandogau|Ribelles|Vilalta|Vilamajor De Cabanabona
25749	Claret (Oliola)|El Gos|La Força|Maravella|Oliola|Vilanova De L'Aguda
25750	Tora
25751	Cellers De Tora|Claret (Tora)|Fontanet De Llanera|Llanera|Sant Serni De Tora|Vallferosa
25752	Biosca
25753	Lloberola|Sanauja
25788	Os De Civis
25790	Aguilar De Bassella|Anoves, Les|Castell, El (Oliana)|Castell-Llebre|Cortiuda|La Mora Comtal|La Valldan|Nuncarga|Oliana|Peramola|Trago De Peramola
25791	Miralpeix|Tiurana
25792	Castellnou De Bassella|Guardiola De Bassella|La Clua|Mirambell
25793	Coll De Nargo|Gavarra|Masies De Nargo, Les|Valldarques
25794	Alinya|Alzina D'Alinya, L'|Cabo|Canelles D'Organya|El Pujal De Cabo|El Vilar De Cabo|Figols (Figols I Alinya)|Llobera (Figols I Alinya)|Montanissell|Organya|Perles|Romanins|Sallent (Coll De Nargo)|Senyus|Sorts, Les
25795	Argestues|Bellpui|Beren|Castellar De Tost|Castellas Del Canto|Castells, Els (Les Valls D'Aguilar)|Espaen|Gramos|Hostalets De Tost, Els|Junyent|La Bastida De Tost|La Guardia D'Ares|Malgrat De Noves|Miravall|Montan De Tost|Noves De Segre|Palanca De Noves|Sant Pere (Les Valls De Valira)|Saulet|Taus|Tora De Tost|Trejuvell|Vila-Rubla
25796	El Pla De Sant Tirs
25797	Adrall
25798	Anserall|Calbinya
25799	Arcavell|Arduix|Argolell|Ars|Asnurri|Civis|Farrera Dels Llops|La Farga De Moles|Sant Joan Fumat
26001	Logroño
26002	Logroño
26003	Logroño
26004	Logroño
26005	Logroño
26006	Logroño
26007	Logroño
26008	Logroño
26009	Logroño
26070	Logroño
26071	Logroño
26080	Logroño
26100	Ribabellosa|Torrecilla En Cameros
26110	Nestares
26111	Almarza De Cameros|Pinillos
26120	Albelda De Iregua
26121	Castañares De Las Cuevas|Islallana|Panzares|Viguera
26122	Gallinero De Cameros|Pradillo
26123	Aldeanueva De Cameros|Villanueva De Cameros
26124	El Rasillo De Cameros|Montemediano|Nieva De Cameros|Ortigosa De Cameros|Peñaloscintos
26125	Villoslada De Cameros
26126	El Horcajo|Lumbreras|San Andres
26127	Montenegro De Cameros
26130	Clavijo|Ribafrecha|Union De Los Tres Ejercitos
26131	Jubera|Lagunilla De Jubera|Robres Del Castillo|San Bartolome De Jubera|San Martin|San Vicente De Robres|Santa Cecilia|Santa Engracia|Ventas Blancas|Zenzano
26132	Bucesta|El Collado|Leza De Rio Leza|Luezas|Santa Marina|Soto De Cameros|Terroba|Trevijano
26133	Ajamil|Hornillos De Cameros|Rabanera|San Roman De Cameros|Torremuña|Vadillos|Velilla
26134	Jalon De Cameros|Muro De Cameros|Torre En Cameros
26135	Cabezon De Cameros|Laguna De Cameros
26140	Lardero
26141	Alberite
26142	Villamediana De Iregua
26143	Murillo De Rio Leza
26144	Corera|Galilea|Santa Lucia
26145	Aldealobos|Las Ruedas De Ocon|Los Molinos De Ocon|Oteruelo
26146	El Redal
26147	Pipaona
26148	Ocon
26150	El Sequero (Agoncillo)(Poligono Industrial)
26151	Arrubal
26160	Aeropuerto De Algoncillo|Agoncillo|Recajo
26190	Nalda
26191	Sorzano
26200	Haro
26210	Anguciana|Cihuri
26211	Foncea|Fonzaleche|Tirgo
26212	Castilseco|Cellorigo|El Ternero|Galbarruli|Sajazarra|Villaseca
26213	Herramelluri|Leiva|Ochanduri|Tormantos|Velasco
26214	Cuzcurrita De Rio Tiron|Cuzcurritilla
26215	Treviana
26216	San Millan De Yecora
26220	Ollauri
26221	Gimileo
26222	Rodezno
26223	Hormilleja
26224	Torrecilla Sobre Alesanco
26226	Monasterio De Suso|Monasterio De Yuso
26230	Casalarreina
26240	Castañares De Rioja
26241	Baños De Rioja
26250	Santo Domingo De La Calzada
26256	Villalobar De Rioja
26257	Bañares|Hervias
26258	Ciriñuela|Cirueña|Gallinero De Rioja|Manzanares De Rioja
26259	Corporales|Grañon|Morales|Quintana|Quintanar De Rioja|Villarta Quintana
26260	Santurde
26261	Pazuengos|Santurdejo
26270	Amunartia|Arviza|Ojacastro|San Asensio De Los Cantos|Tondeluna|Ulizarna|Uyarra
26280	Ezcaray
26288	Anguta|Valgañon|Zorraquin
26289	Ayabarrena|Azarrulla|Posadas|San Anton|Turza|Urdanta|Zaldierna
26290	Briñas
26291	Casas Blancas|Cidamon|San Torcuato|Zarraton
26292	San Felices|Villalba De Rioja
26300	Najera
26310	Badaran
26311	Arenzana De Abajo|Camprovin|Cardenas|Cordovin|Mahave
26312	Arenzana De Arriba|Bezares|Tricio
26313	Uruñuela
26314	Huercanos
26315	Aleson|Castroviejo|Manjarres|Santa Coloma
26320	Baños De Rio Tobia
26321	Bobadilla|Ledesma De La Cogolla|Matute|Pedroso|Tobia|Villaverde De Rioja
26322	Anguiano|Brieva De Cameros|Monasterio De Nuestra Señora De Valvanera
26323	Azofra|Hormilla
26324	Alesanco
26325	Canillas De Rio Tuerto|Cañas|Villar De Torre|Villarejo
26326	El Rio|San Millan De La Cogolla
26327	Berceo
26328	Estollo
26329	Canales De La Sierra|Mansilla|Tabladas|Ventrosa|Villavelayo|Viniegra De Abajo|Viniegra De Arriba
26330	Briones
26338	San Vicente De La Sonsierra
26339	Abalos|Peciña|Ribas De Tereso
26340	Estrella, Noviciado De La|San Asensio
26350	Cenicero
26359	Torremontalbo
26360	Fuenmayor
26370	Navarrete
26371	Sotes|Ventosa
26372	Hornos De Moncalvillo
26373	Daroca De Rioja
26374	Medrano
26375	Entrena
26376	Sojuela
26500	Calahorra|Murillo De Calahorra
26509	Alcanadre
26510	Pradejon
26511	El Villar De Arnedo
26512	Tudelilla
26513	Ausejo
26520	Cervera Del Rio Alhama|Rincon De Olivedo O Las Casas
26525	Igea
26526	Cornago
26527	Valdeperillo|Ventas Del Baño
26528	Valverde
26529	Cabreton|Valdegutur
26530	Aguilar Del Rio Alhama
26531	Inestrillas
26532	Valdemadera
26533	Navajun
26540	Alfaro
26550	Rincon De Soto
26559	Aldeanueva De Ebro
26560	Autol
26570	Quel
26580	Arnedo
26584	Herce
26585	Santa Eulalia Bajera|Santa Eulalia Somera
26586	Ambasaguas|El Villar De Enciso|Enciso|Larriba|Las Ruedas De Enciso|Munilla|Navalsaz|Peroblasco|Poyales|Zarzosa
26587	Gravalos|Muro De Aguas|Villarroya
26588	Bergasa|Bergasillas Bajera|Bergasillas Somera O B. Alta|Carbonera
26589	Arnedillo|Baños Arnedillo, Los (Balnear)|Monasterio De Nuestra Señora De Vico|Prejano
27001	Lugo
27002	Lugo
27003	Lugo
27004	Lugo
27070	Lugo
27071	Lugo
27080	Lugo
27100	Fonsagrada (Casco Urbano)
27110	Carballido (Santa Maria) (A Fonsagrada)
27111	Maderne (A Fonsagrada)|San Pedro De Neiro (A Fonsagrada)
27112	Bastida, A (San Miguel)|Logares (Santo Andre)|Pobra De Buron, A|Trapa|Trobo (Santa Maria) (Fonsagrada)|Veiga De Logares (Santa Maria)
27113	Allonca, A|Barcela|Ernes|Fonfria (Santa Maria Madanela) (Fonsagrada)|Lamas De Campos|Marentes|Monteseiro|Negueira De Muñiz|Ouviaño|Rio De Porto|Vilar De Cuiña
27114	Vilabol De Suarna
27115	Arroxo (San Martiño) (Fonsagrada)|Cereixido (Santiago) (Fonsagrada)
27116	Cuiñas|Padron|Vieiro (San Antonio) (Fonsagrada, A)
27117	Lamas De Moreira
27118	San Martin De Suarna
27120	Castroverde (Casco Urbano)|Vilariño (Santiago)
27122	Bolaño|Vilabade (Santa Maria)|Villavad
27123	Furis De Abaixo|Furis De Arriba
27124	Barreiros (San Cosme) (Castroverde)|Frairia, A|Masoucos|Riomol (San Pedro)|Vilalle
27125	Covelas (San Miguel) (Castroverde)|Espasande (Santiago) (Castroverde)|Goi|Tordea|Uriz (Sta Maria) (Castroverde)
27126	Seres (San Pedro)
27127	Barredo (San Xoan)|Barredo (Santo Andre)|Camiño (San Miguel) (Castroverde)|Rebordaos (San Xurxo) (Castroverde)
27128	Montecubeiro (San Cibrao)
27129	Pena (Santa Maria Madanela) (Castroverde)
27130	Cadavo, O|Esperela, A (San Pedro)
27131	Corneas
27132	Pousada (San Lourenzo) (Baleira)
27133	Degolada, A|Fontaneira, A (Santiago)|Lastra, A (San Xoan)
27134	Freixo (San Xulian) (A Fonsagrada)|Rio (San Pedro) (Fonsagrada)
27135	Bruicedo|Cubilledo (Vilares)|Paradavella|Piñeira (Santa Maria) (Fonsagrada)
27136	Pacios (Santa Maria) (Fonsagrada)
27140	Boveda (Santa Maria) (Lugo)|Recimil
27141	Romean
27142	Arcos (San Paio) (Castroverde)|Moreira|Soutomerille
27143	Agustin|Cellan De Calvos|Cellan De Mosteiro|Monte (Santa Maria) (Castroverde)|Pereirama|Pumarega, A
27144	Miranda|Mirandela
27145	Folgosa (San Estebo)|Folgosa (San Martin)
27146	Bascuas|Carballido (San Martiño)(Lugo)|Paderne|Recesende (San Cibrao) (Castroverde)|Souto De Torres
27150	Arcos (San Pedro) (Outeiro De Rei)|Folgueira|Matela|Outeiro De Rei (Casco Urbano)|Outeiro De Rei (San Xoan)|Outeiro De Rei (Santa Mariña)|Sobrada
27151	Cela (Santa Maria) (Outeiro De Rei)|Taboi
27152	Castelo De Rei (San Salvador)|Vilela (Santiago) (Outeiro De Rei)
27153	Bonxe (Outeiro De Rei)|Mosteiro (San Salvador) (Outeiro Rei)|San Clodio De Aguiar (Outeiro De Rei)|San Fiz De Paz (Outeiro De Rei)|San Lourenzo De Aguiar (Outeiro De Rei)|Veiga (Bonxe-Outeiro De Rei)
27154	Guillar (San Martiño)|Robra (San Pedro Fiz)|Silvarrei
27155	Francos (Santiago) (Otero De Rey)|Gondai|Latas, As|Martul|Parada (San Juan)|Pazo, O|San Paio|Seivane
27156	Ousa
27157	Aspai (San Cibrao)|Candai|Santiago De Gaioso (Santiago)|Vicinte
27160	Anxos (San Mamede)(Nadela)|Castro (San Andres) (Lugo)|Nadela|Pena (San Xoan) (Lugo)
27161	Santa Comba
27162	Adai (Santiago) (Corgo)|Piñeiro (Santa Maria) (Corgo)|Queizan (Santa Maria) (Corgo)
27163	Ansean|Bergazo|Cabreiros (Santa Marina) (Corgo)|Campelo|Camposo|Cela (San Xoan) (Corgo, O)|Cerceda (Corgo)|Chamoso (San Andres)|Chamoso (San Bartolomeu)|Corgo, O (San Xoan)|Escoureda|Farnadeiros (San Pedro)|Fonteita|Lapio|Laxosa (Santiago)|Maceda (San Pedro) (Corgo)|Manan (San Cosme)|Manan (Santa Maria Madanela)|Paradela (San Pedro Felix) (Corgo)|Quinte (Santalla)|Sabarei|Santo Estevo De Farnadeiros (Santo Estevo)
27164	Abragan|Alto, O (Santalla)|Castrillon|Franquean|Gomean|Marei
27165	Segovia (San Xoan)|Vilacha (San Xiao)
27166	Arrubial|Paramo (San Miguel) (Castroverde)
27168	Arxemil (San Pedro)(Corgo)|Pedrafita (San Miguel) (Corgo)
27169	Chamoso (San Cristobo)|San Pedro Felix
27170	Portomarin (Casco Urbano)|Portomarin (San Nicolas)
27177	Caborrecelle (Portomarin)|Vedro (Portomarin)|Vilaxuste (Portomarin)
27178	Bagude (Portomarin)|Belaz (Portomarin)|Sabadelle (Portomarin)|Vilarbasin (Portomarin)
27180	Soñar
27181	Coeses|Ferroi (Santa Maria)|Ferroi (Santiago)|Mota, A|Piñeiro (San Martiño) (Lugo)|Ribas De Miño (San Mamede) (Lugo)
27182	Campo (San Xoan)(Lugo)
27183	Grolos|Ourol (San Xulian)(Guntin)|Zolle
27184	Mosteiro (Santa Maria) (Guntin)
27185	Castelo De Pallares (San Salvador)|Fixos (Santa Marta)|Lousada (San Mamede)(Guntin)|Lousada (Santa Eulalia) (Guntin)|Mougan|Saa (Santiago) (Lugo)|San Roman
27186	Francos (El Salvador)(Guntin)|Navallos (San Pedro) (Guntin)|Piñeiras
27187	Fiz De Rozas (Portomarin)|Leon (Portomarin)|Recelle (Portomarin)
27188	Castromaior (Portomarin)|Cortapezas (Portomarin)|Gonzar (Portomarin)
27190	Castelo (Santiago) (Lugo)|Coeo (San Vicente)
27191	Benade|Pedreda|Rubias
27192	Lugo|Muxa (San Salvador)|Muxa (Santa Maria)
27200	Palas De Rei (Casco Urbano)
27203	Cabana (Santiago)|Pambre|Ramil (San Martiño) (Palas De Rei)|Remonde|Reposteria (San Cipriano)|Reposteria (San Xusto)|San Breixo (Palas De Rei)
27204	Ambreixo|Camino (San Xulian) (Palas De Rei)|Carballal (San Sebastian)|Curbian|Mato (San Xoan) (Palas De Rei)|Meixide|Orosa
27205	Aguas Santas (San Xurxo)|Felpos|Filgueira|Laia (San Xoan)|Maceda (San Miguel) (Palas De Rei)|Merlan (San Salvador) (Palas De Rei)|Moredo|Ulloa
27206	Berbetouros (Palas De Rei)|Ferreira De Negral (Palas De Rei)|Fontecuberta (Palas De Rei)|Puxeda (Palas De Rei)|Ribeira (Palas De Rei)|Salaia (Palas De Rei)
27207	Alba (Santiago De)|Coence (San Mamede)|Coence (San Miguel)|Pidre
27208	Carballal (San Mamede)|Cuiña (Santa Maria) (Palas De Rei)|Quindimil
27209	Marza|Vilareda
27210	Bazar (San Remixio)(Lugo)|Calde|Costante (San Miguel)|Esperante (Santa Eulalia) (Lugo)|Gomelle|Lamas (Sta Eulalia) (Lugo)|Lamela (Santa Mariña)|Lugo|Monte De Meda (San Cibrao) (Guntin)|Monte De Meda (San Martiño) (Guntin)|Monte De Meda (Santa Maria Madanela) (Lugo)|Pradeda (Santa Eulalia) (Guntin)|Vilamea (San Martiño)
27211	Ferreira De Pallares|Guntin (Casco Urbano)|Guntin (El Salvador) (Guntin)|Santa Euxea (Guntin)|Vilamerelle|Villermao (San Miguel)
27212	Nespereira (Portomarin)|San Mamede Do Rio (Portomarin)
27213	Castro De Soengas (Portomarin)|Naron (Portomarin)
27214	Soengas (Portomarin)
27215	Cumbraos De Abaixo|Fufin|Leborei|Lodoso|Marzan|Vilanova (San Pedro) (M0nterroso)
27216	Lestedo|Vilar De Donas
27217	Carteire|Cubelo (San Xoan)|Mosteiro (Santiago) (Palas De Rei)
27220	Friol (Casco Urbano)
27226	Lamas (Santa Maria) (Friol)|Narla|Trasmonte
27227	Prado (San Martiño)|Xia
27228	Carballo (San Xiao)|Ramelle|Rocha|Silvela
27229	Anafreita|Anxeriz|Bra|Carlin|Lea (San Xurxo)|Madelos|Miraz (Santiago) (Friol)|Nodar|Roimil|Seixon
27230	Alta|Torible
27231	Veral, O|Vilacha De Mera
27232	Bacurin
27233	Alto (San Xoan) (Lugo)|Boveda (Santa Eulalia) (Lugo)|Burgo (San Vicente) (Lugo)|Mera|Poutomillos|Progalo|Retorta (Santa Cruz)|Vilamaior De Negral
27234	Entrambasaugas (Guntin)|San Romao Da Retorta (Guntin)|Sirvian (Guntin)
27235	Apregacion (San Cibrao) (Friol)|Apregacion-Seoane (San Xoan) (Friol)|Condes|Guimarei (Santa Maria) (Friol)|Pacio (Santa Maria)|San Cibrao (Friol)
27240	Meira (Casco Urbano)|Meira (Santa Maria)
27241	Seixosmil (San Isidro)
27243	Acevo (Santiago)|Vaos, Os (San Xoan)
27244	Navallos (San Pedro) (Ribeira De Piquin)|Santalla (Ribeira De Piquin)
27245	San Xurxo De Piquin (Ribeira De Piquin)
27246	Baltar|Crecente|Fomiña (O Salvador)|Paraxes|Pousada (Santa Catarina) (Pastoriza, A)|Saldanxe
27247	Lua
27248	Aguarda, A (San Martiño)|Alvare (Santa Maria)|Gueimonde|Piñeiro (San Cosme) (Pastoriza)
27250	Castro De Rei (Castro De Rei)|Santa Locaia (San Pedro)
27256	Outeiro (Santa Maria) (Castro De Rei)|Pacios Salvador (Castro De Rei)
27257	Azumara|Prevesos
27258	Bazar (San Pedro) (Castro De Rei)|Coea|Quintela
27259	Ansemar|Balmonte|Goberno|Ramil (Santa Mariña) (Castro De Rei)|Viladonga (Santiago)
27260	Castro De Ribeiras De Lea|Ribeiras De Lea
27266	Loentia
27267	Triaba
27268	Mos
27269	Duarria
27270	Andion|Caraño|Gondel|Luaces|Mosteiro (San Salvador) (Pol)|Pol (Capitalidad Municipio : Mosteiro)|Silva
27271	Duancos|Ludrio|Mondriz|Orizon
27272	Carazo|Fraialde
27273	Cirio
27274	Rioxoan|Valonga
27275	Milleiros (Santiago) (Pol)
27276	Martin (Santiago) (Baleira)
27277	Braña, A (Baleira)|Retizos (Baleira)
27278	Cubilledo|Fonteo|Libran
27279	Arcos (Santiago) (Pol)|Lea (San Bartolomeu)(Pol)|Pol (Santo Estebo) (Pol)|Suegos (Santa Eulalia) (Pol)
27280	Hermunde|Torneiros
27282	Matodoso, O
27283	Ferreiros (San Martiño)|Ferreiros (Santo Andre) (Pol)
27286	Bretoña|Regueira, A (San Vicente)|Reigosa (Santiago)|San Martiño De Corvelle (San Martiño) (Pastoriza, A)|Ubeda (San Xoan)|Vian (Santa Maria)
27287	Cadavedo|Lagoa (San Xoan) (Pastoriza, A)|Loboso|Pastoriza, A (Casco Urbano)
27289	Bendia|Dumpin|Teixeiro
27290	Mazoi|Pias
27293	Gondar|Labio|Meda, A
27294	Arieiras, Das|Cuiña (Santa Eulalia) (Lugo)|Lugo|Piugos
27296	Bocamaos|Meilan (Santiago) (Lugo)
27297	Adai (Santa Maria Magdalena)(Lugo)|Lugo|Orbazai|Poligono Da Louzaneta|San Lazaro
27298	Lugo|Tirimol
27299	Camoira|Cota|Devesa (Santa Eulalia) (Friol)|Guldriz|Ombreiro|Outeiro Das Camoiras (San Salvador)|Seren|Vilafiz (Santa Maria) (Friol)|Villalvite
27300	Guitiriz (Casco Urbano)|Lagostelle (San Xoan)
27305	Becin|Parga (El Salvador)|Parga (Santa Cruz)|Roca|Trasparga
27306	Buriz (San Pedro)
27307	Labrada (Santa Maria) (Guitiriz)|Vilares, Os (San Vicenzo)
27308	Mariz (Santa Eulalia) (Guitiriz)|Negradas, As (San Vicente)|Villar (Santa Maria) (Guitiriz)
27309	Lagostelle (Santa Marina)
27310	Ribas De Sil (San Clodio)
27317	Nogueira (Nosa Señora Neves) (Ribas De Sil)|Rairos|Torbeo
27318	Peites|Piñeira (San Cristobo) (Ribas De Sil)|Sotordei
27320	Hospital, 0 (San Salvador)|Quiroga (Casco Urbano)|Quiroga (San Martiño)
27324	Esperante (San Pedro) (Folgoso De Caurel)|Meiraos|Noceda (San Pedro) (Folgoso Do Courel)|Seoane (San Xoan) (Folgoso Do Caurel)
27325	Ferreiros De Abaixo|Ferreiros De Arriba|Folgoso|Seceda|Sobredo|Villamor (Resto Parroquia San Miguel)(Folgoso Do Courel)
27328	Bustelo De Fisteus|Fisteus|Horreos|Outeiro (Santa Maria)(0 Courel)|Pacios Da Serra|Seara, A|Visuña
27329	Bendillo|Bendollo De Feais|Cereixido (Santa Maria) (Quiroga)|Hermida (Santa Maria)|Nocedo|Paradaseca|Sequeiros|Vilar De Lor|Vilarmel
27330	Pobra De Brollon, A (Casco Urbano)
27331	Brence (San Xoan)|Pobra De Brollon, A (Estacion)
27332	Castrosante
27333	Outara (Santa Maria)|Pino (Santa Maria) (A Pobra De Brollon)|Rei (Santabaia)|Veiga (San Xian) (Pobra De Brollon)
27334	Castroncelos|Cereixa|Eixon|Fornelas
27335	Canedo|Ferreirua
27336	Ferreiros (San Salvador)(Pobra De Brollon)|Saa (Santa Maria)(Pobra De Brollon)
27338	Barxa De Lor|Salcedo
27339	Lamaiglesia|Parada Dos Montes
27340	Boveda (San Martiño)(Boveda)
27341	Bardaos (San Xoan)|Bardaos (San Xulian)|Castelo (Santo Tome) (Incio)|Noceda (San Xoan) (Incio, O)|Vila De Mouros
27342	Cervela, A (San Cristobo)|Cubela (San Pedro)|Rubian De Cima (Incio)
27343	Tuimil
27344	Freituxe (Santiago)|Guntin (San Cristobo) (Boveda)|Mosteiro (San Pelaxio)(Boveda)
27345	Eirexalba|Vilasouto
27346	Foilebar|Goo|Incio, O (Santa Cruz)|Mao (San Roman)|Mao (San Salvador) (Incio)|Mao (Santa Maria)|Pacios (Santa Maria) (Incio)|Reboiro|Rendar|Sirgueiros|Toldaos (Santiago) (Incio)|Vilarxoan (San Lourenzo)|Viso, O (Santa Cristina)
27347	Hospital, O (San Pedro)|Incio (Santa Mariña)|San Pedro Do Incio (San Pedro)|Trascastro (Santalla)
27348	Laiosa (San Martiño)
27349	Martin (San Cristobo) (Boveda)|Ribas Pequenas (Santiago)|Ver|Villalpape
27350	Rubian (San Fiz) (Boveda)|Rubian (Santiago) (Boveda)
27359	Remesar|Teilan|Villarbujan
27360	Pobra De San Xiao, A|Vilarello (San Pedro) (Lancara)
27362	Piñeiro (San Salvador) (Paramo)|Reascos|Ribeira, A (San Mamede)|San Andres Da Ribeira (San Pedro)
27363	Adai (Santa Mariña)(Paramo)|Friolfe|Gondrame (San Vicente)|Gondrame (Santa Maria)|Grallas|Neira (Santa Maria Madanela) (Paramo)|Ribas De Miño (Santiago) (Paramo)|Torre, A (San Martiño)|Vilafiz (Santa Maria) (Paramo)|Vilarmosteiro|Vilasante (Santa Cruz) (Paramo)|Vileiriz
27364	Moscan
27366	Toiran|Trasliste
27367	Bande|Carracedo|Lama|Lancara (San Pedro)|Neira (Santa Maria) (Lancara)|Vilaleo
27368	Larin (San Salvador) (Lancara)|Muro|Oleiros (San Martiño) (Lancara)
27369	Ronfe|Saa (Santiago) (Paramo)|Vilambran
27370	Rabade (Casco Urbano)
27371	Baamonde
27372	Boveda (Santa Eulalia) (Begonte)|Carral (San Martiño)|Pacios (San Martiño) (Begonte)|Pigara|Valdomar
27373	Begonte|Castro (Santa Maria) (Begonte)|Cerdeiras|Donalbai|Illan|Pena (San Vicente) (Begonte)|Pena (Santa Eulalia) (Begonte)|Santo Tome De Gaioso|Uriz (Santo Estevo)|Viris
27374	Caboi (San Martiño)
27375	Damil (El Salvador)|Felmil|Gaibor (San Xulian)|Pino (San Martiño) (Cospeito)|Saavedra|Seixas|Trobo (Santa Maria) (Begonte)|Villapene|Xoiban
27376	Cospeito (Santa Maria)|Santa Cristina (San Xiao)
27377	Bexan (San Paio)|Feira Do Monte|Muimenta|Rioaveso (Santalla)|Sistallo|Vilar (Santa Maria)|Xermar|Xustas
27378	Goa|Moman (San Pedro) (Cospeito)|Roas
27379	Arcilla|Bestar|Lamas (San Martiño) (Cospeito)|Sisoi|Tamoga
27380	Parga (Parga Estacion)|Parga (Santa Leocadia)|Parga (Santo Estebo)
27388	San Breixo De Parga
27389	Pedrafita (San Mamede) (Guitiriz)
27390	Enciñeira, A (Santa Isabel)|Montefurado|Vilanuide (San Antonio)|Vilaster
27391	Augas Mestas (Santiago)|Quinta De Lor
27392	Chorente|Froian (San Sadurniño)|Oural, O
27400	Monforte De Lemos (Casco Urbano)
27410	Parte, A|Rivasaltas (San Pedro)|Valverde
27411	Chavaga|Reigada
27412	Bascos|Sindran
27413	Liñares (San Cosme)|Pinel|Rozabales|Vilacha (San Mamede) (Puebla De Brollon)
27414	Nocedas, As (Santo Estevo)|Penela, A
27415	Caneda, A|Monte (Santa Mariña) (Monforte)|Villamarin
27416	Gullade|Guntin (Santa Lucia) (Monforte)|Marcelle
27417	Baamorto
27418	Chao De Fabeiro, O|Fiolleda (San Cosmede)|Vide, A (San Cibrao)
27419	Atan|Distriz (Santo Andre) (Monforte)|Mañente|Seguin|Toldaos (San Xoan) (Panton)
27420	Piñeira (San Martiño) (Monforte)
27421	Barantes
27422	Bulso|Pinol|Santiorxo (San Xurxo)
27423	Amandi|Lobios
27424	Doade
27425	Bolmente|Brosmos|Figueiroa|Refoxo (Santo Estevo)
27430	Ferreira De Panton (Casco Urbano)|Ferreira De Panton (Sta Maria)|Sios
27437	Acedre|Cangas (San Pedro Fiz)(Panton)|Cangas (Santiago) (Panton)|Deade|Fronton|Serode
27438	Castillon (San Vicente)|Castillon (Santiago)|Panton (San Martiño)
27439	Eire|Ribeiras De Miño (San Andres) (Panton)|Vilar De Ortelle
27440	Canaval
27450	Espasantes|Vilamelle
27460	Arroxo (San Martiño)(Sober)|Proendos|Sober (Casco Urbano)
27466	Anllo (San Martiño)|Anllo (Santo Estebo)|Millan|Rosende (San Miguel) (Sober)|Vilaescura (Santa Maria)
27468	Neiras
27469	Gundivos|Liñaran
27470	Pombeiro
27500	Chantada (Casco Urbano)
27510	Mouricios|Muradelle (San Paio)
27511	Ada|Argozon|Monte, O (San Miguel)
27512	Laxe (San Xoan)(Chantada)|Mato (San Xulian)(Chantada)
27513	Agrade, A (San Vicente)|Bermun|Esmeriz|Esmoriz (San Xulian)|Requeixo|Viana (San Pedro)
27514	Belesar (San Bartolomeu) (Chantada)|Camporramiro|Lincora|Vilauxe (El Salvador)
27515	Arriba (Santiago) (Chantada)|Nogueira (Santa Maria) (Chantada)|Sariña, A (San Vicente)
27516	Asma (San Fiz)|Chantada (Santa Marina)|Pesqueiras
27517	Merlan (Santo Tome) (Chantada)|Sabadelle (Santa Maria) (Chantada)
27518	Arcos (Sta Maria) (Chantada)|Asma (San Xurxo)|Fornas (San Cristobo)|Mariz (San Martiño) (Chantada)
27519	Asma (San Salvador)|Asma (Santa Uxia)|Brigos|Viana (Santa Cruz)
27520	Barrela, A|Lousada (Santiago) (Carballedo)
27527	Asma (Santa Cristina)|Cartelos|Castro (Santa Mariña) (Carballedo)|Furco (San Gregorio) (Carballedo)|Lobelle
27528	Bubal (Carballedo)|Carballedo|Marzas (Carballedo)|San Romao De Campos (Carballedo)|San Salvador De Bubal (Carballedo)|Temes
27529	Aguada (Santa Baia)|Buciños (San Miguel)
27530	Castro (San Cristobo) (Carballedo)|Lousada (San Mamede) (Carballedo)
27531	Beascos (Santa Mariña)|Vilaquinte (Santa Maria) (Carballedo)
27532	Chouzan|Cova|Erbedeiro (San Pedro)
27533	Milleiros (San Xoan) (Carballedo)|Oleiros (San Miguel) (Carballedo)|Pereira (San Mamede)|Pradeda (Santiago) (Carballedo)
27540	Escairon (Casco Urbano)
27543	Vilaesteva (San Salvador) (Saviñao)
27544	Chave (San Sadurniño)|Reiriz (Sta Maria) (Saviñao)
27545	Ribas De Miño (San Vitorio) (Saviñao)|Segan
27546	Abuime|Broza|Ousende|Seteventos (Santa Maria) (Saviñao)|Sobreda|Vilacaiz
27547	Eirexafeita|Frean|Laxe (San Fiz)(Saviñao)|Louredo|Marrube|Piñeiro (San Saturnino) (Saviñao)|Rebordaos (Sta Eulalia) (Saviñao)|Vilatan|Vilelos|Xuvencos
27548	Cova, A (San Martiño) (O Saviñao)|Diomondi|Fion|Licin|Mourelos|Rosende (Santa Mariña) (Saviñao)
27549	Mato (Santo Estebo)(Panton)|Tribas|Vilasante (San Salvador) (Saviñao)
27550	Carballo (Santo Tome) (Taboada)|Taboada (Casco Urbano)
27554	Ansar (Santo Estebo)|Frade
27555	Bouzoa (San Xoan)|Cerdeda (Santa Mariña)|Gondulfe|Mato (San Martiño)(Taboada)|Moreda (Santa Maria) (Taboada)|Taboada Dos Freires
27556	Bembibre|Couto (San Martin) (Taboada)|Insua (San Salvador) (Taboada)|Insua (San Xulian) (Taboada)|Mourulle
27557	Mesonfrio (Santa Maria)|Vilar De Cabalos (Santabaia)|Xian
27558	Arxiz|Torre (San Mamede) (Taboada)|Vilameñe
27559	Campo (San Xulian)(Taboada)|Castelo (Santa Maria) (Taboada)|Esperante (Santiago) (Taboada)|Piñeira (Santa Maria) (Taboada)
27560	Monterroso (Sector Urbano)|Tarrio|Viloide
27568	Arada|Lavandelo|Ligonde|Milleiros (San Pedro) (Monterroso)|Novelua|Penas|Pol (San Cibrao) (Monterroso)|Salgueiros|Sanbreixo (San Salvador)|Satrexas|Sirgal
27569	Balboa (San Salvador) (Monterroso)|Bidouredo|Bispo, O|Fente|Ferreiros, Os (San Cibrao)|Framean|Gundin|Pedraza (San Lourenzo)|Pedraza (Santa Maria)|Sucastro
27570	Antas De Ulla (Casco Urbano)|Antas De Ulla (San Xoan)
27576	Amarante (San Martiño)|Castro De Amarante (Santo Estebo)
27577	Arbol (Sta Eulalia) (Antas De Ulla)|Barreiro (San Cibrao)|Castro De Amarante (Santa Mariña)|Cutian|Facha|Reboredo
27578	Aguela|Amarante (San Fiz)|Arcos (Santa Maria) (Antas De Ulla)|Areas|Cibreiro|Queixeiro
27579	Alvidron|Amoexa|Casa De Naia (Santa Maria)|Cervela, A (San Miguel)|Dorra|Olveda|Peibas|Rial, O|Santiso (Santabaia)|Senande|Terracha|Vilanuñe|Vilapoupre (San Martiño)
27590	Seoane (El Salvador) (Monforte)
27591	Tor (San Xoan)|Tor (San Xulian)
27592	Moreda (San Roman) (Panton)|Moreda (San Salvador)(Monforte)
27593	Toiriz (Santa Maria)|Toiriz (Santalla)
27594	Ribas De Miño (San Esteban) (Saviñao)
27595	Pedrafita (Santa Baia)|Veiga (San Xoan) (Chantada)
27596	Cicillon|Sobrecedo|Vilela (San Miguel) (Taboada)
27600	Sarria (Casco Urbano)
27610	Castelo Dos Infantes|Fafian|Fontao|Lier
27611	Aldosende|Andreade|Castro (San Mamede) (Paradela)|Castro (San Martiño)|Castro De Rei De Lemos (Santa Maria)|Cortes, As|Ferreiros (Santa Maria) (Paradela)|Francos (Santa Maria) (Paradela)|Laxe, A|Loio|Paradela (Casco Urbano)|Paradela (San Miguel) (Paradela)|Paradela (San Vicente)|Paradela (Santa Cristina)|Paradela (Santalla)|Ribas De Miño (San Facundo) (Paradela)|Suar|Vilaragunte
27612	Baran|Belante|Biville|Meixente|Ortoa|Pinza, A
27613	Nespereira (Santiago) (Sarria)|Paradela (San Andres) (Sarria)|Vilamaior
27614	Celtigos|Frades|Goian|Mato, O (San Salvador)|Rubin|Veiga (San Xulian) (Sarria)|Veiga (Santiago) (Sarria)|Vilapedre (San Fiz) (Sarria)|Vilapedre (San Miguel) (Sarria)
27615	Ferreiros (San Sadurniño)|Seteventos (San Pedro) (Sarria)
27616	Barbadelo
27617	Betote (San Vicenzo)|Lousadela|Requeixo (Sarria)|Vilar (Santa Maria) (Sarria)
27618	Cesar|Chanca|Froian (San Pedro)|Reimondez
27619	Alban (Sarria)|Calvor (Sarria)|Camiño (Sarria)|Farban (Sarria)|Louseiro (Sarria)|Maside (Sarria)|Piñeira (Sarria)|Santalla De Arxemil (Sarria)|Vilar De Sarria (Sarria)
27620	Samos (Casco Urbano)|Samos (Santa Xertrude)
27623	Gundriz
27624	Freixo (San Silvestre) (Samos)
27625	Louzara (San Cristobo)
27626	Louzara (San Xoan)|Santalla (San Xose) (Samos)
27627	Loureiro (Samos)|Lousada (Samos)|Montan (Samos)|Renche (Samos)|San Martiño Do Real (Samos)|Zoo (Samos)
27628	Couto (San Mamede)|Estraxiz|Pascais|Romelle
27630	Triacastela (Casco Urbano)
27631	Balsa (San Breixo)|Carballo (San Xil)
27632	Lamas Do Biduedo (Santo Isidro)|Triacastela (Santiago)|Vilavella
27633	Real, O (San Cristovo)
27634	Cancelo|Monte (Santa Maria)(Triacastela)
27635	Castroncan|Suñide|Teivilide (San Xiao)
27636	Formigueiros
27637	Froian (San Vicente)|Loureiro (San Martiño)(Sarria)|Mato (Santo Estebo) (Sarria)|Pena (San Salvador)|Pena (Santa Maria) (Sarria)
27638	Frollais|Reiriz (San Estebo)
27639	Alfoz (Triacastela)|Toldaos (El Salvador) (Triacastela)
27640	Becerrea (Casco Urbano)
27646	Tores (San Xoan)
27647	Ferreiros Balboa (Becerrea)|Ouson|Tortes
27648	Cadoalla|Furco (San Xoan) (Becerrea)
27649	Armesto (San Roman)|Guilfrei (Santa Eulalia)|Guillen
27650	Proba, A
27651	Cabanela (Santa Maria)|Queizan (Santiago) (Navia De Suarna)
27652	Muñis|Rao
27653	Son (Santa Maria)
27654	Ribeira, A (San Estebo)
27655	Moia|Ribon|Sabane (San Xoan)
27656	Barcia (San Miguel)
27657	Galegos (Santiago)
27658	Castañedo|Mosteiro (El Salvador) (Navia De S.)
27659	Folgueiras|Frexis|Penamil|Pin|Vallo (Santa Maria)|Vilaquinte (San Breixo)|Vilarpandin
27660	Quinta (Santa Eulalia) (Becerrea)
27661	Ribeira, A (San Martiño) (Cervantes)|Vilaiz (Santiago)
27662	Ambasvias (Santalla)|Dorna (Santa Maria)|Quindous|Vilaver
27663	Pando (San Xoan) (Becerrea)|Sevane (San Xoan) (Becerrea)|Veiga (Santa Mariña)|Vilacha (San Pedro) (Becerrea)|Vilamane (Santa Marria)
27664	Castelo (San Pedro)|Castro, O (Santa Maria) (Cervantes)|Liber (San Remixio)|San Roman De Cervantes (San Roman)
27665	Mosteiro, O (San Xoan)(Cervantes)|Noceda (San Pedro) (Cervantes)|San Tome De Cancelada|Vilarello (Santa Maria) (Cervantes)|Villasante (Santiago) (Cervantes)
27666	Cereixedo|Lamas (San Xiao) (Cervantes)|San Pedro De Cervantes (San Pedro)|Vilapun (Santa Coloma)|Vilaspasantes (San Xoan)
27667	Donis (San Fiz)|Pando, O
27668	Ouselle (San Cosme)
27670	Padornelo (San Xoan)|Pedrafita Do Cebreiro
27671	Cebreiro|Fonfria (San Xoan) (Pedrafita)|Hospital (San Xoan) (Pedrafita)|Liñares (Santo Estevo)|Riocereixa|Veiga De Forcas|Zanfoga
27672	Louzarela
27673	Lousada (San Vicente) (Pedrafita)|Pacios (San Lourenzo) (Pedrafita)
27675	Noceda (San Xoan) (Nogais, As)
27676	Doncos
27677	Alence, A (Santa Lucia)|Nogais, As (Santa Maria Madanela)|Nullan (San Cosme)|Quinta (San Pedro) (Nogais, As)|Santo Andre (As Nogais)|Vilaicente (San Xoan)
27678	Agüeira (San Xoan)|Morcelle
27679	Cruzul
27680	Baralla (Casco Urbano)|Guimarei (Santo Tome) (Baralla)|Lebruxo|Pacios (Santa Maria) (Baralla)|Picato (Santa Cruz)|Recesende (San Cirilo) (Baralla)|Vilachambre (Santa Mariña)|Vilartelin
27685	Constantin|Vilarpunteiro
27686	Berselos|Covas (Santiago) (Baralla)|Ferreiros (San Pedro) (Baralla)|Francos (San Salvador) (Baralla)|Laxes|Pousada (Santiago) (Baralla)|Riva De Neira (Santalla)|San Esteban (Baralla)
27687	Arroxo (San Xoan)(Baralla)|Teixeira
27688	Lexo|Piñeira (San Salvador) (Baralla)|Sixirei (San Pedro)
27689	Aranza|Pol (Santa Maria) (Baralla)|Vale
27690	Corvelle (Santa Maria) (Sarria)|San Antolin
27691	Rio (San Martiño) (Lancara)|Vilouzan
27692	Cedron
27693	Armea (San Pedro) (Lancara)|Galegos (Santa Mariña)|Lagos (Santalla)|Monseiro (San Miguel) (Lancara)|Souto De Ferradal (Santiago)|Toldaos (San Vicente) (Lancara)|Touville
27694	Vilouta
27695	Cascalla|Cereixal, O|Penamaior (Santa Marina De San Lorenzo)
27696	Neira De Rei (San Martiño)|Neira De Rei (San Miguel)
27697	Pedrafita De Camporredondo (Baralla)|Penarrubia
27698	Fontaron (Santi Spiritus)
27699	Vilaesteva (Santa Maria) (Lancara)
27700	Ribadeo (Casco Urbano)
27710	Piñeira (San Xoan) (Ribadeo)|Vilaselan
27711	Cedofeita|Couxela (Santiago)
27712	Vilaosende
27713	Obe (San Xoan)
27714	Arante|Cubelas (San Vicente)
27715	Rinlo
27720	Pontenova, A (Casco Urbano)|Pontenova, A (Sagrado Corazon)
27721	Vilaboa (San Xulian)
27722	Bogo
27723	Xudan
27724	Vilarmide, O (Salvador)
27725	Rececende (San Xoan)|Vilamea (San Vicente)
27726	Rececende (Santo Estebo)
27727	Vilaouruz
27728	Conforto
27729	Vilaoudriz (Santiago)
27730	Abadin (Casco Urbano)|Abadin (Santa Maria)|Abeledo|Cabaneiro (San Bartolomeu)|Corvite (San Pedro)|Goas|Graña|Moncelos (Santa Maria)|Villarente
27737	Labrada (San Pedro) (Abadin)|Montouto|Romariz
27738	Fanoi (Santa Maria Madanela)|Frayas|Galgao (San Martiño)|Quende
27740	Mondoñedo (Casco Urbano)
27742	Lindin|Santa Maria Maior (Santa Maria)
27743	Muxueira, A
27744	Aldurfe (San Pedro)|Espasande De Baixo (Santa Maria) (Riotorto)|Ferreiravella|Galegos (Santa Maria)(Riotorto)|Orrea|Riotorto (Casco Urbano)|Riotorto (San Pedro)
27745	Santa Marta De Meilan (Riotorto)
27747	Remedios, Os (Nosa Señora Dos Remedios)|Viloalle (Santa Maria)
27748	Argomoso (San Pedro)|Carme, O (Nosa Señora Do Carme)
27749	Couboeira (Santa Maria Madanela)|Figueiras (San Martiño)|Masma (Santo Andre)|Oiran (Santo Estevo)
27750	Santo Adrao De Lourenza (Santo Adrao)
27751	Lourenza (Santo Tome)|San Xurxo De Lourenza (San Xurxo)
27752	Santiago De Mondoñedo (Santiago)|Vilamor (Santa Maria) (Mondoñedo)
27760	Lourenza (Casco Urbano)|Lourenza (Santa Maria)|Vilanova (Lourenza)
27765	Trabada (Casco Urbano)|Trabada (Santa Maria)|Vidal (San Mateo)
27766	Ria De Abres, A (Santiago)|Sante (San Xiao)|Valboa, A (Santa Maria Madanela)
27767	Vilaforman|Vilapena
27768	Fornea, A (Santo Estevo)
27770	Ferreira (Santa Maria) (Valadouro, O)|Valadouro, O (Casco Urbano)
27773	Adelan
27774	Lagoa, A (San Vicente) (Alfoz)
27775	Oiras, As (San Mamede)|Pereiro, O (Santa Maria) (Alfoz)|San Pedro De Mor
27776	Alfoz (Alfoz)|Bacoi (Santa Maria)|Carballido (San Sebastian) (Alfoz)|Castro De Ouro, O (San Salvador)
27777	Cadramon, O (San Xurxo)|Frexulfe (Santa Eulalia)|Recare (San Xiao)|Santa Cruz Do Valadouro|Santo Tome De Recare (Santo Tome)
27778	Laxe, A (San Xoan)|Reirado, O|Vilacampa
27779	Budian (Santa Eulalia)|Moucide (Santo Estebo)
27780	Foz (Casco Urbano)|Foz (Santiago)
27785	Santa Cilla Do Valadouro (Santa Cilla)
27786	San Acisclo Do Valadouro (Foz)
27787	San Martiño De Mondoñedo (Foz)
27788	Vilaronte (San Xoan)
27789	Fazouro (Santiago)
27790	Barreiros (San Cosme) (Barreiros)
27791	San Vicente De Trigas (San Vicente) (Mondoñedo)|Sasdonigas (San Lourenzo)
27792	Benquerencia
27793	Reinante (San Miguel)
27794	Reinante (Santiago)
27795	Rochela, A
27796	Devesa, A (Santalla)
27797	Vilaframil
27798	Cabarcos (San Xulian)|Cabarcos (San Xusto)|Celeiro De Mariñaos (Santa Cristina)|Vilamartin Pequeno
27800	Vilalba (Casco Urbano)
27810	Sancobade (Santiago) (Vilalba)
27811	Ladra (O Salvador)|Nete
27812	Noche|Oleiros (San Mamede)
27813	Alba (San Xoan)|Boizan|Insua (San Bartolomeo)|Soeixo (Santa Maria)|Torre (Santa Maria) (Vilalba)
27814	Belesar (San Martiño) (Vilalba)
27815	Costa (San Simon) (Vilalba)
27816	Lanzos (San Martiño)|Lanzos (San Salvador)|Vilapedre (San Mamede)
27817	Balsa, A (Santa Maria) (Muras)
27818	Arbol (San Lourenzo) (Vilalba)|Rioaveso (San Xurxo) (Vilalva)|Santo, O
27820	Mourence
27821	Gondaisque
27822	Distriz (San Martiño) (Vilalba)
27823	Tardade
27824	Cazas
27825	Codesido
27826	Moman (San Mamede)(Xermade)
27830	Santaballa
27832	Arredoada, A|Burgas|Candamil
27833	Miraz (San Pedro) (Xermade)|Piñeiro (San Martiño) (Xermade)|Xermade
27834	Cabreiros
27835	Lousada (Santo Andre) (Xermade)|Roupar (San Pedro Fiz)
27836	Ambosores (Santa Maria) (Muras)|Ameixeiras, As|Burgo, O (Santa Maria) (Muras)|Couce Dos Mouros|Mouriscon, O|Muras (San Pedro)|Muruas|Pena Do Mouriscon|Piocorto|Rego, O|Santar De Baixo|Sisto, O (Santa Maria) (Muras)
27837	Irixoa|Silan (Santo Estevo)|Viveiron, O (Muras)
27840	Goiriz
27841	Roman
27842	Samarugo
27843	Aldixe (San Pedro)|Carballido (Santa Maria) (Vilalba)|Corvelle (San Bartolome) (Vilalba)
27844	Martiñan
27845	Baroncelle|Castro Maior (San Xoan) (Abadin)
27849	Candia
27850	Magazos (Santa Maria)|Viveiro (Casco Urbano)
27860	Vicedo, O
27861	Covas (San Xoan) (Viveiro)|Mosende (San Pedro)|San Miguel De Negradas (San Miguel) (Vicedo, O)|Suegos (Santa Maria) (Vicedo)|Valle
27863	Celeiro (Santiago) (Viveiro)|Faro (San Xiao)
27864	Boimente|Chavin
27865	Ambosores (Santa Maria) (Ourol)|Miñotos|Ourol (Casco Urbano)|Ourol (Santa Maria) (Ourol)|Sisto, O (Santa Maria) (Ourol)|Xerdiz
27866	Landrove (San Xiao)|Merille (Santa Eulalia)|San Pedro De Viveiro (San Pedro)|Valcarria (Santo Estevo)
27867	Bravos (Santiago)|Galdo (Santa Maria)|San Pantaleon De Cabanas (San Pantaleon) (Ourol)
27868	Cabanas (Santa Maria) (Vicedo)|Riobarba
27869	Vieiro (San Cibrao) (Viveiro)
27870	Xove|Xove (San Bartolo)
27876	Moras (San Clemente)
27877	Portocelo|Xuances
27878	Lago (Xove)|Sumoas (Xove)
27879	Monte, O (Santo Isidoro)|Rigueira, A (San Miguel)
27880	Burela
27888	Castelo (San Xiao) (Cervo)|Trasbar
27889	Rua (Santa Maria)|San Roman De Vilaestrofe (San Roman)
27890	Gondras|Lieiro (Parroquia Sta. Maria)|San Cibrao (Cervo)
27891	Cervo|Rio Covo|Sargadelos
27892	Cangas (San Pedro) (Foz)|Cordido
27893	Nois
28001	Madrid
28002	Madrid
28003	Madrid
28004	Madrid
28005	Madrid
28006	Madrid
28007	Madrid
28008	Madrid
28009	Madrid
28010	Madrid
28011	Madrid
28012	Madrid
28013	Madrid
28014	Madrid
28015	Madrid
28016	Madrid
28017	Madrid
28018	Madrid
28019	Madrid
28020	Madrid
28021	Madrid
28022	Madrid
28023	Madrid
28024	Madrid
28025	Madrid
28026	Madrid
28027	Madrid
28028	Madrid
28029	Madrid
28030	Madrid
28031	Madrid
28032	Madrid
28033	Madrid
28034	Madrid
28035	Madrid
28036	Madrid
28037	Madrid
28038	Madrid
28039	Madrid
28040	Madrid
28041	Madrid
28042	Madrid
28043	Madrid
28044	Madrid
28045	Madrid
28046	Madrid
28047	Madrid
28048	El Pardo|Madrid
28049	Madrid
28050	Madrid
28051	Madrid
28052	Madrid
28053	Madrid
28054	Madrid
28055	Madrid
28070	Madrid
28071	Madrid
28080	Madrid
28082	Madrid
28083	Madrid
28085	Madrid
28086	Madrid
28087	Madrid
28100	Alcobendas
28108	Alcobendas
28109	Alcobendas
28110	Algete|El Arrabal
28119	Cottolengo Del Padre Alegre|Poligono Industrial El Nogal
28120	Ciudad Santo Domingo
28130	Alalpardo|Valdeolmos
28140	Fuente El Saz De Jarama
28150	Valdetorres De Jarama
28160	Talamanca Del Jarama
28170	Valdepielagos
28180	Torrelaguna
28189	El Atazar|Patones|Presa Del Atazar (Poblado)|Santuy|Torremocha Del Jarama
28190	Bocigano|Cabida|Colmenar De La Sierra|Corralejo|El Cardoso De La Sierra|Montejo De La Sierra|Peñalba De La Sierra|Puebla De La Sierra
28191	Horcajuelo De La Sierra|La Hiruela|Pradena Del Rincon
28192	Dehesa De Santillana|El Berrueco
28193	Cervera De Buitrago
28194	Berzosa De Lozoya|Robledillo De La Jara
28195	Serrada De La Fuente
28196	Paredes De Buitrago
28200	San Lorenzo De El Escorial
28209	Valle De Los Caidos, Sta Cruz
28210	Cazadero Real I (Urbanizacion)|Cerro Alarcon I (Urbanizacion)|Cerro Alarcon Ii (Urbanizacion)|Infantas, Las (Valdemorillo)|Islas Blancas (Urbanizacion)|Jara Beltran|La Mojadilla|Las Charquillas|Mirador Del Romero|Montemorillo (Urbanizacion)|Paraiso, El (Urbanizacion)|Pino Alto (Urbanizacion)|Pizarrera, La (Urbanizacion)|Puentelasierra (Urbanizacion)|Tres Dehesas (Urbanizacion)|Valdemorillo
28211	Peralejo
28212	Navalagamella
28213	Colmenar Del Arroyo|Valle Del Sol (Urbanizacion)
28214	Fresnedillas De La Oliva
28219	Alcor I (Urbanizacion)|Alcor Ii (Urbanizacion)|Pinosol (Urbanizacion)|Prado Ventorro (Urbanizacion)
28220	Majadahonda
28221	Majadahonda
28222	Majadahonda
28223	Pozuelo De Alarcon
28224	Pozuelo De Alarcon
28229	Santa Maria (Via Del Pardo) (Urbanizacion)|Villanueva Del Pardillo
28230	Las Rozas De Madrid
28231	Las Rozas De Madrid
28232	Las Rozas De Madrid
28240	Hoyo De Manzanares
28248	Ciudad Residencial La Berzosa (Urbanizacion)
28250	Jarales, Los (Galapagar) (Urbanizacion)|Minas, Las (Galapagar) (Urbanizacion)|Pinar De Puente Nuevo (Galapagar) (Urbanizacion)|Torrelodones
28260	Galapagar
28270	Colmenarejo
28279	Alamos, Los (Colmenarejo)|Parque Azul
28280	Ciudad Bosque De Los Arroyos (Urbanizacion)|El Escorial
28290	Las Rozas De Madrid
28292	Cierros, Los (Las Zorreras)|Encinar I Y Ii (Las Zorreras)|España|Herreño, El (Las Zorreras)|Navalquejigo|Navalquejigo, De (Granja)|San Ignacio (Las Zorreras)|Suertes, Las (Las Zorreras)
28293	Colonia Peña Rosal|Zarzalejo|Zarzalejo, De (Estacion)
28294	Canopus|Rio Cofio (Urbanizacion)|Robledo De Chavela|Robledo, De (Estacion)|Suiza Española, La (Urbanizacion)
28295	Rio, El (Urbanizacion)|Valdemaqueda
28296	Las Herreras|Navalespino|Santa Maria Alameda, De (Estacion)|Santa Maria De La Alameda
28297	Hoya, La (Robledondo)|La Cereda|Paradilla (Robledondo)|Robledondo
28300	Aranjuez|El Cortijo De San Isidro
28310	Algodor|El Espinar|El Quintillo|Majazala
28311	Castillejo
28312	Infantas, Las (Aranjuez)
28320	Pinto|Poligono Industrial Aproin|Poligono Industrial Carretera De San Martin De La Vega|Poligono Industrial De Pinto|Poligono Industrial Las Arenas|San Martin De La Vega, De (Carretera)
28330	Poligono Industrial Aimayr|San Martin De La Vega
28339	La Boyeriza
28340	Valdemoro
28341	Valdemoro
28342	Valdemoro
28343	Valdemoro
28350	Ciempozuelos
28359	Titulcia
28360	Villaconejos
28370	Chinchon
28380	Balcon Del Tajo (Urbanizacion)|Colmenar De Oreja|Urtajo (Urbanizacion)|Vallejos, Los (Urbanizacion)|Valles San Juan (Urbanizacion)
28390	Belmonte De Tajo
28391	Valdelaguna
28400	Collado Villalba
28410	Manzanares El Real
28411	Moralzarzal
28412	Cerceda|Montesclaros
28413	El Boalo
28419	Nieves Y Sol
28420	Colonia Alto De La Navata|Colonia De Carranza|La Navata|Las Monjas|Los Enebros|Parquelagos|Rosales, Los (Navata, La)
28430	Alpedrete|Los Negrales|Valdencina
28440	Casa Forestal Tablada (Edificio)|Casa Tere Tablada (Edificio)|Gonzalo (Edificio)|Guadarrama|Residencia San Francisco (Edificio)|Sanatorio De Guadarrama|Serranilla, La (Guadarrama) (Urbanizacion)
28450	Collado Mediano|El Reajo Del Roble
28459	Monte Golf
28460	Los Molinos
28470	Cercedilla|Navacerrada, De (Puerto)
28479	Las Dehesas
28480	Barrio Tablada|Sanatorio Tablada|Tablada (Apeadero)
28490	Becerril De La Sierra
28491	Navacerrada (Pueblo)
28492	La Ponderosa De La Sierra|Matalpino
28500	Arganda Del Rey|El Colmenar|Emisora Radio Elect Campillo (Arganda)|La Poveda|La Serna|Ventorro De La Julia
28510	Campo Real
28511	Valdilecha
28512	Villar Del Olmo
28513	Las Villas De Nuevo Baztan
28514	Nuevo Baztan
28515	Olmeda De Las Fuentes
28521	Rivas-Vaciamadrid
28522	Rivas-Vaciamadrid
28523	Rivas-Vaciamadrid
28524	Rivas-Vaciamadrid
28529	Rivas-Vaciamadrid
28530	Morata De Tajuña
28540	Perales De Tajuña
28550	Tielmes
28560	Carabaña
28570	Orusco De Tajuña
28580	Ambite
28590	Villarejo De Salvanes
28594	Valdaracete
28595	Estremera
28596	Brea De Tajo
28597	Fuentidueña De Tajo
28598	Villamanrique De Tajo
28600	Calipo (Urbanizacion)|Colonia Rio Guadarrama (Urbanizacion)|Navalcarnero
28607	El Alamo
28609	Sevilla La Nueva|Villamantilla|Villanueva De Perales
28610	Villamanta
28620	Aldea Del Fresno
28630	Alamin, El (Finca)|Villa Del Prado
28640	Cadalso De Los Vidrios
28648	Entrepinos (Urbanizacion)
28649	Rozas De Puerto Real
28650	Cenicientos
28660	Boadilla Del Monte|Residencia Nuestra Señora Del Pilar (Boadilla)
28668	Monteprincipe
28669	Bonanza|Club Encinas (Boadilla)|El Olivar Del Miraval|Lomas, Las (Boadilla)|Monte Las Encinas|Parque Boadilla|Pico Centinela (Boadilla)|Valdecabañas
28670	Bosque, El (Urbanizacion)|Villaviciosa De Odon
28679	Residencia Ancianos (Villaviciosa Odon)
28680	Apartamentos Pronto (Urbanizacion)|Ciudad San Ramon|Costa Madrid (Urbanizacion)|San Martin De Valdeiglesias
28690	Brunete
28691	Cerro Del Venero|Fuentes, De Las (Camino)|Guadamonte (Urbanizacion)|Raya Del Palancar, La (Urbanizacion)|Villanueva De La Cañada
28692	Villafranca Del Castillo
28693	Quijorna
28694	Chapineria
28695	Navas Del Rey
28696	Pelayos De La Presa
28700	San Sebastian De Los Reyes
28701	San Sebastian De Los Reyes
28702	San Sebastian De Los Reyes
28703	San Sebastian De Los Reyes
28706	Club De Campo (Urbanizacion)
28707	Ciudalcampo|R.A.C.E. (Real Automovil Club De España)
28708	Fuente Del Fresno
28709	Ciudad Deportiva Del Jarama
28710	El Molar
28720	Bustarviejo
28721	Cabanillas De La Sierra|Redueña
28722	El Espartal|El Vellon
28723	Pedrezuela
28729	Cotos De Monterrey|Navalafuente|Valdemanco|Venturada
28730	Buitrago De Lozoya
28737	Braojos|Gandullas|Gascones|La Serna Del Monte|Piñuecar-Gandullas
28739	Gargantilla Del Lozoya Y Pinil|Navarredonda (Buitrago)|Pinilla De Buitrago|San Mames|Villavieja De Lozoya
28740	Puerto De Cotos|Rascafria
28741	Paular, Real El (Monasterio)
28742	Lozoya Del Valle
28743	Canencia De La Sierra|Garganta De Los Montes
28749	Alameda Del Valle|El Cuadron|Oteruelo Del Valle|Pinilla Del Valle
28750	San Agustin Del Guadalix|Valdeagua|Valdelagua (Urbanizacion)
28751	La Cabrera
28752	Lozoyuela
28753	Molino De Mazacortas|Sieteiglesias
28754	Cinco Villas|Mangiron|Navas De Buitrago|Presa De Puentes Viejas
28755	Aoslos|El Hospital|Horcajo De La Sierra|La Acebeda|La Mantilla|Madarcos|Robregordo
28756	Somosierra
28760	Castillo De Viñuelas|Cedex|Colonia Militar El Goloso|Colonia Valdecastellanos|Goloso, De El (Estacion)|Jarillas, De Las (Finca)|Laboratorio Mopu, Km. 18,6|Madrid-Colmenar Viejo, Del Km. 17,500 Al 22,600 (Carretera)|Soto De Viñuelas|Tratamiento De Aguas (Goloso, El)|Tres Cantos|Valdelamasa, De (Finca)|Valdeloshielos, De Los (Finca)
28770	Centro Militar San Pedro|Colmenar Viejo|Hidraulica Santillana|Presa De Hidraulica (Santillana)|San Pedro
28791	Soto Del Real
28792	Miraflores De La Sierra|Miraflores De La Sierra, Anejos De|Miraflores De La Sierra, Extrarradio De
28793	Los Endrinales
28794	Guadalix De La Sierra|Miralpantano
28800	Alcala De Henares
28801	Alcala De Henares
28802	Alcala De Henares
28803	Alcala De Henares
28804	Alcala De Henares
28805	Alcala De Henares|El Encin
28806	Alcala De Henares
28807	Alcala De Henares
28810	Arlita|Gurugu|Los Hueros|Villalbilla|Zulema
28811	Corpa
28812	Pezuela De Las Torres|Valverde De Alcala
28813	Pozuelo Del Rey|Torres De La Alameda
28814	Daganzo De Arriba
28815	Fresno De Torote|Ribatejada|Serracines
28816	Camarma De Esteruelas|Poligono Alcanar|Valdeavero
28817	Los Santos De La Humosa
28818	Anchuelo|Santorcaz
28820	Coslada
28821	Coslada
28822	Coslada
28823	Coslada
28830	Parque Empresarial San Fernando De Henares|Poligono Industrial San Fernando|San Fernando De Henares
28840	Mejorada Del Campo
28850	Barrio De El Castillo|Base Aerea Conjunta Torrejon|Torrejon De Ardoz
28851	Parque Corredor Del Henares (Mercado)
28860	Paracuellos De Jarama
28861	Los Berrocales De Jarama
28862	Belvis De Jarama|Belvis Nuevo
28863	Cobeña
28864	Ajalvir|Cobeña, De (Ajalvir) (Carretera)|Poligono Del Calvario|Poligono Industrial Ajalvir|Poligono Industrial Coumar
28870	Alcala De Henares
28880	Alameda|Barrio Nuevo (Venta Del Meco)|Meco
28890	Loeches
28891	Velilla De San Antonio
28900	Getafe
28901	Getafe
28902	Getafe
28903	Getafe
28904	Getafe
28905	Getafe
28906	Getafe
28907	Getafe
28909	Getafe
28910	Leganes
28911	Leganes
28912	Leganes
28913	Leganes
28914	Leganes
28915	Leganes
28916	Leganes
28917	La Fortuna|Leganes
28918	Leganes
28919	Leganes
28920	Alcorcon
28921	Alcorcon
28922	Alcorcon
28923	Alcorcon
28924	Alcorcon
28925	Alcorcon
28930	Mostoles
28931	Mostoles
28932	Mostoles
28933	Mostoles
28934	Mostoles
28935	Mostoles
28936	Mostoles
28937	Mostoles
28938	Combos, Los (Arroyomolinos)|Mostoles
28939	Arroyomolinos|San Martin (Arroyomolinos)|Valdefuentes
28940	Fuenlabrada
28941	Fuenlabrada
28942	Fuenlabrada
28943	Fuenlabrada
28944	Fuenlabrada
28945	Fuenlabrada
28946	Fuenlabrada
28947	Fuenlabrada
28950	Moraleja De Enmedio
28970	Humanes De Madrid
28971	Griñon
28976	Batres
28977	Casarrubuelos
28978	Cubas De La Sagra
28979	Serranillos Del Valle
28980	Parla
28981	Parla
28982	Parla
28983	Parla
28984	Parla
28990	Torrejon De Velasco
28991	Torrejon De La Calzada
29001	Malaga
29002	Malaga
29003	Malaga
29004	Malaga
29005	Malaga
29006	Malaga
29007	Malaga
29008	Malaga
29009	Malaga
29010	Malaga
29011	Malaga
29012	Malaga
29013	Malaga
29014	Malaga
29015	Malaga
29016	Malaga
29017	Malaga
29018	Malaga
29070	Malaga
29071	Malaga
29080	Malaga
29100	Coin|El Rodeo|Miralmonte (Urbanizacion)|Miralvalles|Montecillo (Urbanizacion)
29108	Ardite|Guaro (Coin)
29109	Tolox|Umbria (Tolox)
29110	Monda
29120	Alhaurin El Grande|El Cigarral|El Zangano|Fuente Del Perro|La Chicharra
29130	Alamillo, El (Urbanizacion)|Alhaurin De La Torre|Alqueria (Alhaurin De La Torre)|El Peñon|El Romeral|La Fuensanta|Lagar De Las Pitas|Los Tomillares|Mestanza|Piamonte|Pinos De Alhaurin (Urbanizacion)|Santa Amalia|Torre Alqueria|Zapata
29140	Malaga
29150	Almogia|Arroyo De Los Olivos|Barranco De Zafra|Barranco Del Sol|Las Moras|Monterroso
29160	Arroyo Coche (Casabermeja)|Camino Real (Casabermeja)|Casabermeja|Chapera Madroñal|Portales
29170	Caravaca|Colmenar|Gonzalo|Majada Del Moro|Solano
29180	Riogordo
29190	Malaga
29193	Venta De La Nada|Venta Galwey
29194	Alfarnate|Alfarnatejo
29195	Alqueria (Comares)|Chamizas|Comares|El Gallego|El Olivar|El Romo|Gomez, Los (Comares)|Las Cuevas Romo|Los Dioses|Los Hijanos|Marines, Los (Comares)|Masmullar|Rio (Comares)
29196	Malaga
29197	Olias|Totalan
29200	Antequera
29210	Cuevas De San Marcos
29220	Cuevas Bajas
29230	Campo De Camara (Almogia)|Villanueva De Cauche|Villanueva De La Concepcion
29239	Arroyo Coche (Almogia)
29240	Valle De Abdalajis
29250	Cartaojal|Los Llanos De Antequera
29260	La Joya|Los Nogales
29300	Archidona
29310	Albaicin|Villanueva De Algaidas
29311	La Atalaya|La Parrilla
29312	Villanueva Del Rosario
29313	Villanueva Del Trabuco
29314	Archidona (Estacion)|Huertas Del Rio
29315	Salinas, De (Estacion)|Villanueva De Tapia
29320	Campillos
29327	Teba
29328	Sierra De Yeguas
29329	Navahermosa
29330	Almargen
29340	Cañete La Real
29350	Arriate
29360	Montejaque
29370	Benaojan
29380	Cortes De La Frontera|El Robledal
29391	La Cañada Del Real Tesoro
29392	Jimera De Libar|Jimera De Libar (Estacion)
29393	La Indiana
29394	La Cimada|Parchite
29395	Cañete La Real (Estacion)
29400	Ronda|Rosalejo
29410	Yunquera
29420	El Burgo
29430	Montecorto
29440	Igualeja
29450	Pujerra
29451	Parauta
29452	Cartajima
29460	Alpandeire
29461	Farajan
29462	Juzcar
29470	Cuevas Del Becerro
29471	Serrato
29480	Gaucin
29490	Benarraba|Colmenar, El (Estacion De Gaucin)
29491	Algatocin|Benalauria|Opayar|Sierra (Benalauria)|Vega (Benalauria)
29492	Genalguacil|Jubrique
29493	Benadalid|Genal|Sierra, La (Benadalid)
29494	Atajate
29500	Alora|Arroyo Ancon|Arroyo Jevar|Lomas, Las (Alora)|Sabinal
29510	Arroyo Corrales|Barriada Bellavista (Alora Estacion)|Casablanquilla
29520	Fuente Piedra
29530	Alameda
29531	Humilladero
29532	Mollina
29533	Carvajales
29540	Barriada Ortiz|Bobadilla (Estacion)|Bobadilla (Pueblo)|Colonia De Santa Ana
29550	Ardales
29551	Carratraca
29552	El Chorro
29560	Pizarra
29566	Casarabonela
29567	Alozaina|Jorox
29569	Cerralba|Gibralgalia|Los Lagares|Los Malagueños|Ribera (Pizarra)|Vega De Santa Maria (Pizarra)|Villalon|Zalea
29570	Cartama|Cartama, Ampliacion|Casapalma|Fahala|Villafranco Del Guadalhorce
29580	Comendador|El Sexmo|Estacion De Aljaima (Escaleras)|Estacion De Cartama (Escaleras)|Loma De Cuenca|Nueva Aljaima|Peral|Puerto Terron|Saucedilla|Tres Leguas
29590	Malaga
29591	Malaga
29593	Bermejo|Caracuel|Las Mellizas|Llanos, Los (Las Mellizas)|Paredones
29600	Marbella
29601	Marbella
29602	Marbella
29603	Marbella
29604	Marbella
29610	Ojen
29611	Istan
29612	Mairena, La-Vicario, El (Urbanizacion)
29620	Torremolinos
29630	Benalmadena Costa|La Capellania
29631	Arroyo De La Miel
29639	Benalmadena (Pueblo)
29640	Fuengirola
29649	Mijas
29650	Mijas
29651	Mijas
29660	Marbella
29670	Marbella
29678	Artola (Benahavis)|El Madroñal
29679	Benahavis|Cortes (Benahavis)|Montemayor
29680	Estepona|Loma Del Monte
29688	Atalaya Isdabe|Cancelada|El Paraiso|Saladillo Benamara
29689	El Padron|El Valerin
29690	Casares
29691	Manilva
29692	Alcorrin|Castillo De La Duquesa|Chullera|Honda Cavada|San Luis De Sabinillas|Secadero
29693	Bahia Dorada|Buenas Noches|La Gaspara|Saladavieja
29700	Cabrillas|Velez Malaga
29710	Periana
29711	Alcaucin|Espino|Pilarejo|Toril
29712	Gomez, Los (Canillas De Aceituno)|La Aldea|Los Millanes|Los Paulas|Portugalejo|Rio Bermuzas|Viñuela
29713	Casillas, Las (Los Romanes)|Los Castillejos|Los Romanes|Puente Salia|Venta Baja
29714	Salares
29715	Sedella|Valverde
29716	Canillas De Aceituno|Lomas Chozas|Los Capitos
29718	Almachar|Benamargosa|Cutar|El Borge|La Zubia|Las Rozas|Rio Almachar|Salto Del Negro|Santo Pitar|Triana|Zorrilla
29719	Benamocarra|Pasada De Granadillo|Rubite|Trapiche
29720	La Araña|La Cala Del Moral
29730	Rincon De La Victoria
29738	Benagalbon|Moclinejo|Torre De Benagalbon|Valdes
29740	Torre Del Mar
29749	Almayate Alto|Almayate Bajo
29750	Algarrobo|Algarrobo Costa
29751	Caleta De Velez|Trayamar
29752	Sayalonga
29753	Archez|Arenas De Velez|Corumbela|Daimalos Vados
29754	Competa
29755	Canillas De Albaida
29760	Lagos|Mezquitilla
29770	Torrox
29780	Nerja
29787	Maro
29788	Frigiliana
29789	Molineta, La (Frigiliana)
29790	Benajarafe|Chilches
29791	Benaque|Los Puerta|Los Vallejos|Macharaviaya
29792	Cajiz|Iznate
29793	Castillo Bajo-Conejito|El Morche|El Peñoncillo|Generacion Del 27 (Urbanizacion)|Huit|Llanos, Los (Torrox-Costa)|Torrox Park|Torrox-Costa
30001	Murcia
30002	Murcia
30003	Murcia
30004	Murcia
30005	Murcia
30006	Murcia
30007	Murcia
30008	Murcia
30009	Murcia
30010	Murcia
30011	Murcia
30012	Murcia
30070	Murcia
30071	Murcia
30080	Murcia
30100	Cementerio Nuestro Padre Jesus|Espinardo|Molinos Alfatego|Murcia|Puntal, El (Espinardo)
30107	Guadalupe
30108	Rincon De Beniscornia
30109	Jeronimos, Los (Los Jeronimos)
30110	Cabezo De Torres|Castellar, El (Cabezo De Torres)|Churra Cabezo De Torres|Murcia|Torre Alcayna
30120	Barrio La Victoria|Palmar, El (El Palmar)
30130	Beniel|Mojon, El (Beniel)|Raiguero, El (Beniel)
30139	El Raal
30140	Santomera
30148	Matanza, La (Santomera)
30149	El Siscar
30150	La Alberca
30151	Murcia|Santo Angel
30152	Aljucer|Maurillos, Los (Carril)
30153	Brianes|Corvera|Garcia, Los (Corvera)|La Murta
30154	Cabecico Del Rey|Los Bastidas|Valladolises
30155	Baños Y Mendigo
30156	Los Martinez Del Puerto|Ruices, Los (Los Martinez Del Puerto)
30157	Algezares|Teatinos, Los (Algezares)
30158	Los Garres|Los Lages
30160	La Cueva|Las Lumbreras|Monteagudo|Murcia
30161	Llano De Brujas
30162	Santa Cruz
30163	Azarbe (Parroquia)|Barrio De La Aurora|Cobatillas|Cobatillas Viejas|El Esparragal|Orilla Del Azarbe|Peñicas De Cobatica Las Viejas
30164	Cabezo De Plata|Cañada De San Pedro
30165	Rincon De Seca
30166	Nonduermas
30167	Raya, La (La Raya)
30168	Era Alta|Murcia
30169	San Gines
30170	Cagitan|Mula
30176	Pliego
30177	Casas Nuevas (Casas Nuevas)
30178	Fuente Librilla|Hoya Noguera|Los Ojos|Retamosa
30179	Barqueros
30180	Bullas
30189	Arroyo Hurtado|Chaparral|El Carrascalejo|La Copa
30190	Albudeite|La Cruz
30191	Campos Del Rio
30192	Rodeo De Enmedio|Rodeo De Los Tenderos
30193	Baños De Mula|Puebla De Mula|Yechar
30194	Niño De Mula
30195	Archivel|Noguericas
30196	Bajil
30200	Cartagena
30201	Cartagena
30202	Barriada Santiago|Cartagena
30203	Cartagena
30204	Cartagena
30205	Cartagena
30300	Cartagena
30310	Cartagena
30319	Cartagena|Las Casicas|Los Piñuelas|Miranda|Poligono Santa Ana|Santa Ana
30320	Fuente Alamo
30329	El Espinar
30330	El Albujon|Esparragueral|Hernandez, Los (Albujon)|Las Casas|Lomas, Las (Albujon)|Roses, Los (Albujon)
30331	Conesas, Los (Lobosillo)|Garcia, Los (Lobosillo)|Lobosillo|Los Romeras|Urreas, Los (Lobosillo)|Vidales, Los (Lobosillo)
30332	Balsapintada|Estrecho De Fuente Alamo
30333	Cuevas De Reyllo|Escobar, El (Reyllo)|Lo Jorge|Los Almagros|Los Morenos
30334	Las Palas|Loma, La (Las Palas)
30335	Campillo De Abajo (La Pinilla)|Campillo De Arriba (La Pinilla)|El Mingrano|La Pinilla|Los Vivancos
30338	Canovas
30350	Valle Escombreras
30351	Alumbres|Borricen (Alumbres)
30353	Poligono Industrial Cabezo Beaza
30360	La Union|Los Oliveras
30364	Portman
30365	Cruz Chiquita|El Gorguel
30366	El Algar
30367	Los Beatos|Los Castillejos|Los Miralles|Los Rizos|Ruices, Los (San Jose)
30368	Bahia Bella (Urbanizacion)|Carmoli, El (Urbanizacion)|Estrella Mar (Urbanizacion)|Los Urrutias
30369	Bolarin, Lo (Roche)|Huertas, Los (Roche)|La Esperanza|Los Camachos|Los Paredes|Los Topares|Roche|Roche Alto|Roche Bajo|Torre Blanca
30370	Cabo De Palos|Cala Flores|Cala Reona (Urbanizacion)
30380	La Manga Del Mar Menor
30381	El Llano Del Beal|Estrecho De San Gines
30382	Beal|San Gines De La Jara
30383	Lo Pollo|Nietos Viejos|Nietos, Los (Los Nietos)
30384	Islas Menores|Mar De Cristal
30385	Atamaria|Cobaticas|La Ribera|Las Barracas|Los Belones|Playa Honda (Urbanizacion)|Puntal, El (Los Belones)|Villa Caravaning
30389	Manga Club, La (Urbanizacion)
30390	La Aljorra|Los Carrascosas|Los Nicolases|Navarros, Los (La Aljorra)|Roses, Los (La Lajorra)
30391	La Guia|Pozo De Los Palos
30392	El Porche|Hondon, El (Media Legua)|Media Legua (Media Legua)|Roche (Vereda)|Torreciega
30393	Angeles, Los (Califa)|Barriada De San Jose Obrero (Galifa)|El Portus|Galifa|Los Patojos|Molino De Marfagones|Sanchez, Los (Galifa)
30394	Canteras (Canteras)|Cartagena|Diaz, Los (Canteras)|Majuelo|Palmero, El (Pozo Estrecho)|Roses, Los (Canteras)|Vaguada, La (Urbanizacion)
30395	Campo Bajo|La Aparecida|La Puebla|Los Rosiques
30396	Blases, Los (Cuesta Blanca)|Casas Del Pino (Cuesta Blanca)|Cuesta Blanca|La Corona|Los Puertos|Los Rojos|Marinas, Las (Cuesta Blanca)|Perin
30397	Carceles, Los (La Magdalena)|La Magdalena|Los Simonetes|Palmero, El (La Magdalena)|San Isidro
30398	Casas Altas|La Manchica|Los Arroyos|Los Faustinos|Los Mendez|Martinez, Los (Tallante)|Perez, Los (Tallante)|Rincon De Tallante|Valdelentiscos
30399	Abrevadero|Gibraltar|Los Jorqueras|Vista Alegre
30400	Caravaca De La Cruz
30410	Benablon|Campo Coy|Caneja|La Almudema|La Encarnacion|Los Prados|Navares|Pinilla|Singla
30411	Los Royos
30412	Barranda|Cabezuela|La Junquera|Moralejo, El (Caravaca De La Cruz)|Moralejo, El (Moratalla)
30413	El Hornico|El Moral|Inazares|La Rogativa|Tartamudo
30414	Cañada De La Cruz|Entredicho|Los Odres
30420	Baños De Gilico|Calasparra|El Macaneo|Madriles, Los (Calasparra)|Marines, Los (Calasparra)|Valentin (Calasparra)|Valentin (Cehegin)
30430	Cehegin
30438	Campillo Y Suertes
30439	Agua Salada|Burete|Campillo De Los Jimenez|Canara|Cañada Canara|Cañada Lentisco|El Ribazo|Escobar, El (Cehegin)|Pila Canara
30440	Moratalla
30441	Calar De La Santa|Casas De Aledo|Casas Del Puerto|El Sabinar|San Juan, Campo De
30442	Benizar|Casicas Del Portal|El Molino|El Villar|Mazuza|Otos|Rincon De Los Huertos
30500	Molina De Segura
30506	Molina De Segura
30507	Molina De Segura
30508	Molina De Segura
30509	El Romeral|La Hornera|Molina De Segura
30510	Yecla
30520	Jumilla
30528	Fuente Del Pino|La Alqueria|La Estacada
30529	Caña Del Trigo|El Carche|La Alberquilla|La Raja|La Zarza|Las Encebras|Roman|Torre Del Rico
30530	Barretera|Bolvax|Cieza|El Buho|El Ginete|Maripinar
30535	Ascoy
30540	Alto Palomo|Bayna|Blanca|Casas Alcantara|Tollos
30550	Abaran|Barranco De Molax
30558	Barriada De La Virgen De Oro|Candelon|Corona|Cuesta Egea
30559	Asomada, La (Abaran)|El Boqueron|Hoya Del Campo|Los Vergeles|San Jose Artesano
30560	Alguazas
30561	Alguazas (Estacion)|Las Pullas
30562	Ceuti
30563	Los Torraos
30564	Lorqui
30565	Florida, La (Las Torres De Cotillas)|Las Torres De Cotillas|Los Pulpites
30566	Huerta De Abajo (Torres De Cotillas)|Huerta De Arriba|La Condomina|Las Parcelas|Los Matias|Media Legua (Torres De Cotillas)|Parque Las Palmeras|Parque Los Romeros
30570	Beniajan|Canute|Casas Nuevas (Beniajan)|El Bojal|Murcia|San Jose De La Vega
30579	Torreaguera
30580	Alquerias
30588	Tabala|Zeneta
30589	Los Ramos
30590	Borrambla|Casas Blancas|Casas Del Cura|Cuevas De Marin|Gea Y Truyols|Lo Gea|Pino (Urbanizacion)|Sucina|Tercia, La (Sucina)
30591	Balsicas|Martinez, Los (Balsicas)
30592	Avileses|Camachos|Hondo, El (Avileses)|Saez De Tarquinales|San Cayetano Avileses
30593	Carriones, Los (La Palma)|Conesas, Los (La Palma)|Fuente Amarga|La Palma|Los Balanzas|Los Chorlitos|Los Medicos|Los Salazares|Vidales, Los (La Palma)
30594	Carriones, Los (Pozo Estrecho)|El Charco|Loma, La (Pozo Estrecho)|Pozo Estrecho|Rambla, La (Torraos)
30600	Archena|Hurtado|Las Arboledas
30609	La Algaida|Torre Del Junco
30610	La Bermeja|Ricote
30611	Ojos
30612	Ulea
30613	Fuente Morra|Villanueva Rio Segura
30620	Fortuna
30626	Baños|Capres De Abajo|Capres De Arriba|Capres De Enmedio
30627	Campotejar Alta|Campotejar Baja|Comala|El Rellano|Fenazar|Hurona|La Espada
30628	Ajauque|Matanza, La (Fortuna)|Salinas De Rambla Salada
30629	Casicas, Las (Peña Zafra)|Fuente Blanca|Hoya Hermosa|La Garapacha|Las Peñas|Peña Zafra De Abajo|Peña Zafra De Arriba
30640	Abanilla
30648	Barinas|Campules|Cañada De La Leña|Chicamo|Collado De Los Gabrieles|El Algarrobo|El Canton|La Zarza De Abanilla|Macisvenda|Ricabacica|Salado|Tolle|Umbria|Zarza, La (El Canton)
30649	Los Carrillos|Mahoya|Poligono Industrial El Semolilla
30700	Hoya Morena|Torre Pacheco
30708	El Gimenado
30709	Lo Ferro|Roldan
30710	Lomas De Rame|Los Alcazares|Los Narejos|Nietos, Los (Los Alcazares)|Santa Rosalia
30720	Calavera, La (Santiago De La Rivera)|Santiago De La Ribera
30729	Academia General Del Aire
30730	San Javier
30739	Casicas, Las (Dolores Pacheco)|Dolores De Pacheco|El Mirador|Granjuela|Pozo Aledo|Roda|Vidales, Los (Dolores Pacheco)
30740	Barrio Los Angeles|Beatas, Las (Los Saez)|Las Esperanzas|Lo Pagan|Loma De Abajo|Loma De Arriba|Los Antolinos|Los Cuarteros|Los Gomez|Los Imbernones|Los Peñascos|Los Plazas|Los Saez|Los Tarragas|Los Veras|Mojon, El (Cuarteros)|San Pedro Del Pinatar|Tacon, Lo (Los Saez)|Villa Nanitos
30800	Lorca|Sutullena
30810	Zarcilla De Ramos
30811	Fontanares|Jarales|La Tova|Ortillo|Parrilla
30812	Aviles|Coy|Don Gonzalo|Doña Ines|La Paca|Las Terreras
30813	Alcanara|Alto Bordo|Campillo (Lorca)|Escarihuela|La Campana|La Escucha|Pozo De La Higuera (Lorca)|Puente Botero|Puente De Pasico|Purias
30814	Barranco Hondo|Torralba|Torrealvilla|Zarzadilla De Totana|Zuñiga
30815	Aguaderas|Campo Lopez|Carrasquilla (Lorca)|Marchena|Santa Gertrudis|Tercia (Lorca)
30816	El Porvenir|Hinojar|Hoya, La (La Hoya)|San Julian
30817	Huerta Nublo|Las Canales|Torrecilla
30818	Cazalla|Pulgara|Tiata|Ventarique
30820	Alcantarilla
30830	La Ñora
30831	Javali Viejo
30832	Javali Nuevo
30833	Sangonera La Verde|Torreguil (Urbanizacion)
30834	Cuevas Del Norte|El Puntarron|Torreguil
30835	Los Pepitos|Sangonera La Seca
30836	Los Pujantes|Puebla De Soto
30837	Cañada Hermosa (Alcantarilla)|Cañada Hermosa (Murcia)
30840	Alhama De Murcia
30848	Azaraque|Collado, El (Espuña)|El Berro|El Ramblar|Flotas, Las (Alhama De Murcia)|Gebas|Moriana|Pavos
30849	Casas Del Algibe|Caserio De Los Muñoces|Costera|El Cañarico|Las Cañadas|Las Ramblillas|Mojon, El (Alhama De Murcia)|Molata|Ventorrillos, Los (El Mojon)
30850	Totana
30858	Cañada Del Romero|El Raiguero|Lopez, Los (Ventas Del Parejon)|Los Cantareros|Los Guardianes|Los Tudelas|Pareton|Pulios|Serranos, Los (Totana)
30859	Aledo|Canales, Las (Chichar)|Chichar|La Charca|Los Allozos|Montisol (Urbanizacion)|Morti
30860	Puerto De Mazarron
30868	Alamillo|Campillo De Adentro|Isla Plana|La Azohia|Las Balsicas|Los Lorentes|Madriles, Los (Campillo Adentro)|Mojon, El (Campillo De Adentro)
30870	Mazarron
30875	Camposol
30876	Barranco De Los Asensios|Cañada Del Gallego|Cuesta Cazadores (Ifre)|El Ramonete|Ermita Ramonete|Lebrillera|Los Curas|Pastrana|Puntas De Calnegre
30877	Bolnuevo|Gañuelas|Las Moreras
30878	Atalaya (Morata)|Fuente Meca|La Majada|Leiva|Morata|Puerto Mariel|Ujejar
30879	El Garrobo|El Saladillo|Rusticana
30880	Aguilas
30889	Calabardina|Calarreona (Urbanitzacio)|Collado Weiss|Collado Zieschang|Cope|Cuesta De Gos|El Charcon|El Cocon|El Garrobillo|Geraneos, Los (Urbanitzacio)|Lomas, Las (Cuesta De Gas)|Los Arejos|Majada Del Moro|Tebar|Todosol (Urbanitzacio)
30890	Casicas, Las (Puerto Lumbreras)|Henares|Nogalte (Pueblo)|Puerto Lumbreras|Zarzalico
30891	Esparragal De Puerto Lumbreras|Goñar|Puerto Adentro
30892	Librilla
30893	Almendricos
31001	Pamplona/Iruña
31002	Pamplona/Iruña
31003	Pamplona/Iruña
31004	Pamplona/Iruña
31005	Pamplona/Iruña
31006	Pamplona/Iruña
31007	Pamplona/Iruña
31008	Pamplona/Iruña
31009	Pamplona/Iruña
31010	Pamplona/Iruña
31011	Pamplona/Iruña
31012	Pamplona/Iruña
31013	Pamplona/Iruña
31014	Pamplona/Iruña
31015	Pamplona/Iruña
31016	Mendillorri|Pamplona/Iruña
31070	Pamplona/Iruña
31071	Pamplona/Iruña
31080	Pamplona/Iruña
31100	Gares|Puente La Reina/Gares|Señorio De Sarria
31109	Artazu
31110	Aeropuerto De Noain (Pamplona)|Noain
31119	Guerendiain (Elorz)|Imarcoain|Oriz|Torres De Elorz
31130	Mañeru
31131	Cirauqui/Zirauki
31132	Villatuerta
31133	Basongaiz|Legarda|Uterga
31140	Artajona
31150	Mendigorria|Muruzabal De Andion|Nuestra Señora De Andion
31151	Obanos
31152	Muruzabal
31153	Adios|Eneriz/Eneritz|Larrain
31154	Añorbe|Tirapu|Ucar
31160	Orkoien
31170	Arazuri|Iza/Itza
31171	Asiain|Lizasoain|Olza|Ororbia
31172	Aizpun|Anotz|Arteta|Azanza|Beasoain|Egillor (Ollo)|Goñi|Iltzarbe|Lete|Munarriz|Ollo|Saldise|Senosiain|Ultzurrun|Urdanoz
31173	Artazcoz|Ibero|Izcue|Izu
31174	Arguiñariz|Arraiza|Belascoain|Bidaurreta|Ciriza|Echarri (Echarri)|Elio|Eriete|Etxauri|Larraya|Otazu|Ubani|Zabalza/Zabaltza
31175	Izurzu|Muniain De Guesalaz|Salinas De Oro/Jaitz
31176	Arguiñano|Guembe|Irujo|Iturgoyen|Muez|Riezu/Errezu|Vidaurre|Villanueva De Yerri/Hiriberri Deierri
31177	Arizala/Aritzala|Arizaleta/Aritzaleta|Azcona/Aizkoa|Casetas De Ciriza/Ziritzako Etxeak|Ibiricu De Yerri/Ibiriku Deierri|Iruñela|Lezaun|Ugar
31178	Abarzuza|Anderaz|Iranzu (Monasterio)
31179	Bearin|Muru (Yerri)
31180	Zizur Mayor/Zizur Nagusia
31190	Astrain|Cizur Menor|Gazolaz|Guendulain (Astrain)|Muru-Astrain|Paternain|Sagües|Undiano/Undio|Zariquiegui
31191	Arlegui|Barbatain|Beriain|Cordovilla|Esparza De Galar|Esquiroz (Galar)|Galar|Olaz Subiza|Salinas De Pamplona|Subiza
31192	Aranguren|Ardanaz De Egues|Badostain|Gongora|Ilundain|Labiano|Laquidain/Lakidain|Mutilva/Mutiloa|Tajonar/Taxoare|Zolina
31193	Amalain|Belzunce|Beorburu|Eguaras|Garciriain|Larrayoz|Marcalain|Navaz|Nuin|Ollacarizqueta|Osacar|Usi
31194	Aderiz|Arre|Azoz|Cildoz|Eusa|Ezcaba|Garrues|La Trinidad De Arre|Maquirriain (Ezcabarte)|Oricain|Orrio|Sorauren|Unzu
31195	Aizoain|Añezcar|Ballariain|Berrioplano|Berriosuso|Elcarte|Larragueta|Loza|Oteiza De Berrioplano
31200	Estella/Lizarra|Lizarra
31208	Irache (Urbanizacion)
31210	Los Arcos
31219	Cabrega|Mirafuentes|Mues|Otiñano|Piedramillera|Sorlada|Ubago
31220	Sansol
31227	Cabredo|Genevilla|Lapoblacion|Marañon|Meano
31228	Aguilar De Codes|Armañanzas|Azuelo|Espronceda|Torralba Del Rio
31229	Bargota|Desojo|El Busto|Torres Del Rio
31230	Recajo|Viana
31239	Aras
31240	Ayegui/Aiegi
31241	Arbeiza|Arteaga|Azqueta|Ganuza|Iguzquiza|Labeaga|Metauten|Ollobarren|Ollogoyen|Zubielqui|Zufia
31242	Villamayor De Monjardin
31243	Arroniz|Barbarin|Luquin|Urbiola
31250	Oteiza
31251	Larraga
31252	Berbinzana
31253	Miranda De Arga
31254	Vergalijo
31260	Lerin
31261	Andosilla
31262	Allo
31263	Arellano|Dicastillo
31264	Aberin|Echavarri, De (Caserio)|Morentin|Muniain De La Solana
31270	Larraona
31271	Aranarache/Aranaratxe|Eulate
31272	Artaza|Baquedano|Barindano|Ecala|Gollano|San Martin De Amescoa|Urra|Zudaire
31280	Abaigar|Mendilibarri|Murieta
31281	Ancin/Antzin|Etayo|Learza|Legaria|Oco|Olejua
31282	Acedo|Asarta|Mendaza|Nazar
31283	Galbarra|Gastiain|Narcue|Ulibarri|Viloria
31284	Zuñiga
31290	Amillano|Aramendia|Artavia|Echavarri (Allin)|Eraul|Eulz|Galdeano|Larrion|Muneta
31291	Arzoz|Echarren (Guirguillano)|Estenoz|Garisoain|Guirguillano|Irurre|Lerate|Muzqui|Viguria
31292	Alloz/Allotz|Arandigoyen/Arandigoien|Arinzano|Eguiarte|Grocin/Gorozin|Lacar/Lakar|Legardeta|Lorca/Lorka|Murillo De Yerri/Murelu Deierri|Murugarren|Zabal|Zurucuain/Zurukuain
31293	Sesma
31300	Tafalla
31310	Carcastillo|Oliva, La (Monasterio)
31311	Figarol
31312	San Isidro Del Pinar
31313	Murillo El Fruto
31314	Santacara
31315	Traibuenas
31320	Milagro
31330	Villafranca
31340	Marcilla
31350	Peralta/Azkoien
31360	Funes
31370	Falces
31380	Caparroso
31382	Melida
31383	Rada
31390	Olite/Erriberri
31391	Murillo El Cuende
31392	Pitillas
31393	Beire
31394	Pueyo
31395	Amatriain|Amunarrizqueta|Artariain|Barasoain|Benegorri|Bezquiz|Eristain|Garinoain|Iracheta|Iriberri (Leoz)|Leoz/Leotz|Mendivil|Orisoain|Sansomain|Solchaga|Uzquita
31396	Bariain|Echagüe|Oloriz/Oloritz|Oricin|Unzue
31397	Campanas
31398	Biurrun|Muruarte De Reta|Olcoz|Tiebas
31400	Sangüesa/Zangoza
31409	Gabarderal|Rocaforte|Torre De Peña
31410	Leyre (Monasterio)|Urbanizacion Lasaitasuna|Urbanizacion Nautica De Leyre|Yesa
31411	Javier
31412	Burgui/Burgi
31413	Vidangoz/Bidankoze
31414	Garde
31415	Roncal/Erronkari
31416	Urzainqui/Urzainki
31417	Isaba/Izaba
31418	Uztarroz/Uztarroze
31420	Urroz
31421	Ardanaz De Izagaondoa|Beroiz|Guerguitiain|Idoate De Izagaondoa|Indurain|Iriso|Izanoz|Lizarraga (Izagaondoa)|Mendinueta|Reta|Turrillas|Urbicain|Zuazu (Izagaondoa)
31422	Artaiz|Cemborain|Muguetajarra|Najurieta|Unciti|Zabalceta|Zoroquiain
31430	Agoitz|Aoiz/Agoitz
31438	Arce/Artzi|Arizcuren/Arizkuren|Arrieta|Espoz/Espotz|Ezkai|Gorriz/Gorritz|Gurpegui/Gurpegi|Itoiz/Itoitz|Lusarreta|Nagore|Orbaiz/Orbaitz|Osa/Otsa|Saragüeta/Saragueta|Urdiroz/Urdirotz|Uriz/Uritz|Villanueva (Arce) Hiriberri-Artzibar|Zandueta
31439	Artozqui/Artozki|Azparren|Equiza/Ekiza|Gorraiz De Arce/Gorraitz-Artzibar|Imizcoz/Imizkotz|Lacabe/Lakabe|Muniain De Arce/Muniain-Artzibar|Olaldea|Oroz-Betelu/Orotz-Betelu|Rala/Errala|Usoz/ Usotz
31440	Lumbier
31448	Adoain|Aristu|Artanga|Ayechu|Elcoaz|Eparoz|Ezcaniz|Guindano|Imirizaldu|Irurozqui|Jacoisti|Larequi|Larraun (Urraul Alto)|Nardues Andurra|Ongoz|Ozcoidi|Ripodas|San Vicente|Sansoain (Urraul Bajo)|Santa Fe O Santafe|Zabalza (Urraul Alto)
31449	Aldunate|Nardues Aldunate|Tabar
31450	Navascues
31451	Gallues/Galoze|Ibilcieta/Ibiltzieta|Iciz/Izize|Izal/Itzalle|Oronz|Racas Alto|Sarries/Satze|Uscarres/Uskartze|Ustes
31452	Güesa/Gorza|Igal/Igari|Ripalda/Erripalda
31453	Esparza De Salazar
31454	Adansa|Arbonies|Arielz|Aspurz|Berroya (Pueblo)|Bigüezal|Castillonuevo|Domeño|Iso|Murillo Berroya|Napal|Orradre|Usun
31460	Aibar/Oibar|Leache
31470	Elorz/Elortz|Ezperun|Otano|Yarnoz|Zabalegui|Zulueta
31471	Monreal
31472	Alzorriz|Salinas De Ibargoiti/Getze Ibargoiti|Zabalza (Ibargoiti)
31473	Abinzano|Celigüeta|Idocin|Izco|Lecaun|Sengariz|Vesolla
31480	Artieda|Grez
31481	Akotain|Aos|Artajo/Artaxo|Ayanz/Aiantz|Ekai De Longuida/Ekai-Longida|Erdozain/Erdotzain|Javerri/Xaberri|Larrangoz/Larrangotz|Liberri|Meoz/Meotz|Mugueta/Mugeta|Murillo De Longuida/Murelu-Longida|Olaverri/Olaberri|Oleta|Uli-Alto/Uliberri|Uli-Bajo/Ulibeiti|Villanueva De Longuida/Hiriberri-Longida|Villaveta/Billabeta|Zarikieta|Zuasti (Longuida)|Zuza/Zutza
31482	Lerruz|Lizoain|Redin
31483	Beortegui|Janariz|Laboa|Leyun|Oscariz
31484	Iloz|Urricelqui|Zalba|Zaldaiz|Zunzarren
31485	Mendioroz|Uroz|Yelz
31486	Alzuza|Azpa|Echalaz|Egulbati|Egües|Elcano|Elia|Eransus|Galduroz|Ibiricu De Egües|Sagaseta|Ustarroz (Egues)
31487	Liedena
31490	Caseda
31491	Moriones|Sada
31492	Ayesa
31493	Gallipienzo|Gallipienzo Nuevo
31494	Eslava|Lerga|Maquirriain (Leoz)|Olleta (Leoz)|Sansoain (Leoz)
31495	San Martin De Unx
31496	Ujue
31500	Tudela
31510	Fustiñana
31511	Cabanillas
31512	El Bocal|Fontellas
31513	Arguedas
31514	Valtierra
31515	Cadreita
31520	Cascante
31521	Murchante
31522	Monteagudo|Tulebras
31523	Ablitas|Barillas
31530	Cortes
31540	Buñuel
31550	Ribaforada
31560	Azagra
31570	San Adrian
31579	Carcar
31580	Lodosa
31587	Imaz|Mendavia
31588	Lazagurria
31589	Sartaguda
31590	Castejon|Giraldelli
31591	Corella
31592	Cintruenigo
31593	Fitero
31600	Burlada/Burlata
31610	Atarrabia|Villava
31620	Gorraiz|Huarte/Uharte|Olaz De Egües
31621	Sarriguren
31630	Osteritz|Zubiri
31638	Eugi
31639	Agorreta|Iragi|Kintoa/Quinto Real|Leranotz|Olaberri|Quinto Real|Saigots|Urtasun|Usetxi|Zilbeti
31640	Auritz/Burguete
31650	Orreaga/Roncesvalles
31660	Luzaide/Valcarlos
31670	Larraun (Orbaitzeta)|Orbaizeta
31671	Aria|Aribe|Hiriberri/Villanueva De Aezkoa (Pueblo)|Orbara
31680	Ochagavia
31689	Izalzu/Itzaltzu
31690	Ezcaroz/Ezkaroze
31691	Jaurrieta
31692	Abaurregaina/Abaurrea Alta|Abaurrepea/Abaurrea Baja|Garaioa
31693	Garralda
31694	Aurizberri/Espinal
31695	Bizkarreta-Gerendiain|Mezkiritz|Sorogain-Lastur|Ureta
31696	Lintzoain
31697	Aintzioa|Ardaitz|Erro|Esnotz|Larraingoa|Loizu|Orondritz|Urniza
31698	Akerreta|Errea|Ezkirotz|Idoi|Ilarratz|Inbuluzketa|Irure|Larrasoaña|Sarasibar|Setoain|Urdaitz/Urdaniz
31699	Antxoritz|Arleta|Gendulain (Esteribar)|Ilurdotz|Irotz|Olloki|Zabaldika|Zuriain
31700	Antzanborda|Beartzun|Berro|Elbete|Elizondo|Etxaide (Baztan)
31710	Azkar|Etxartea|Madaria|Olazur|Zugarramurdi
31711	Alkerdi|Landibar|Leorlaz|Telleria|Urdazubi/Urdax
31712	Dantxarinea
31713	Aintzialde|Arizkun|Bozate|Ordoki|Pertalats
31714	Erratzu|Gorostapolo|Iñarbil
31715	Amaiur/Maya|Apaioa|Arribiltoa|Azpilkueta|Urrasun|Zuaztoi (Azpilikueta)
31720	Mugairi|Oieregi|Oronoz|Señorio De Bertiz|Zozaia (Oronoz) (Pueblo)
31730	Aitzano|Ariztegi|Etxerri|Gartzain|Irurita
31740	Doneztebe/Santesteban
31744	Elgorriaga
31745	Aurtitz|Ituren|Latsaga
31746	Aurkidi|Azkota|Mendrasa|Sarekoa|Zubieta
31747	Saldias
31748	Eratsun
31749	Ezkurra
31750	Donamaria|Gaztelu
31751	Oitz
31752	Urrotz (Pueblo)
31753	Beintza Labaien|Labaien
31754	Aitasemegi|Alkainzuriain|Alkasoaldea|Arano|Artikutza|Espidealdea|Goizueta|Latse|Suro|Tartazu|Urumea
31760	Etxalar|Gorosurreta|Lakain-Apezborro|Larrapil-Sarriku|Lurriztiederra|Orizki|Urritzokieta
31770	Auzoberri|Biurrana|Endara|Endarlatsa|Frain (Lesaka)|Izotzaldea|Katazpegi|Lesaka|Nabaz (Lesaka)|Otsango Auzoa|Zala|Zalain Zoko
31780	Bera
31789	Dornaku|Garaitarreta|Kaule|Suspela|Suspelttiki|Xantelerreka/Elzaurdia|Zalain
31790	Aientsa|Arantza|Azkilarrea|Berrizaun|Bordalarrea|Eguzkialdea|Elusta|Frain (Igantzi)|Igantzi|Irisarri|Piedadeko Gaina|Sarrola|Unanua
31791	Sunbilla
31792	Legasa|Santalokadia|Zeberi
31793	Narbarte|Tipulatze
31794	Aroztegia|Arraioz|Mardea|Oharriz|Uharte (Baztan)
31795	Lekaroz
31796	Almandoz|Aniz|Berroeta|Ziga|Zigaurre
31797	Alkotz|Arraitz-Orkin|Auza|Eltzaburu|Ilarregi|Iraizotz|Larraintzar|Lozen|Suarbe
31798	Aritzu|Burutain|Egozkue|Etsain|Etulain|Etxaide (Anue)|Lantz|Leazkue|Olague
31799	Anocibar|Anoz|Beraiz|Ciaurriz|Eltso|Enderiz|Gerendiain|Gorrontz-Olano|Guendulain (Odieta)|Latasa (Odieta)|Lizaso|Olaiz|Olave|Osacain|Osavide|Ostiz|Ripa|Urritzola-Galain|Zandio|Zenotz
31800	Altsasu/Alsasua
31809	Olazti/Olatzagutia|Ziordia
31810	Bakaiku|Iturmendi|Urdiain
31820	Etxarri-Aranatz|Lizarragabengoa
31829	Dorrao/Torrano|Lizarraga (Ergoiena)|Unanu
31830	Lakuntza
31839	Arbizu
31840	Amurgin|Arruazu|Uharte-Arakil|Zamartze
31849	Irañeta|Itsasperri|Murgindueta
31850	Hiriberri-Villanueva (Pueblo)|Ihabar|Satrustegi
31860	Irurtzun
31866	Aizarotz|Arrarats|Beruete|Erbiti|Gartzaron|Igoa|Jauntsarats|Ola|Orokieta
31867	Aguinaga De Iza|Aizkorbe|Arostegui|Berasain|Beunza|Beunza Larrea|Cia|Ciganda|Eguillor (Atez)|Erice (Atez)|Gascue|Guelbenzu|Gulina|Iriberri (Atez)|Labaso|Muskitz
31868	Atondo|Egiarreta|Ekai|Errotz|Etxarren|Etxeberri|Izurdiaga|Urritzola|Zuhatzu
31869	Beramendi|Eraso|Etxaleku|Goldaratz|Ihaben|Itsaso|Latasa (Imotz)|Oskotz|Udabe|Urritza|Zarrantz
31870	Lekunberri|San Migel
31876	Areso
31877	Albiasu|Gorriti|Uitzi
31878	Aldatz|Arruitz|Etxarri|Mugiro
31879	Alli|Astitz|Baraibar|Iribas|Madotz|Oderitz
31880	Arkiskil|Erasote|Erreka|Gorriztaran|Leitza (Pueblo)|Sakulu
31890	Betelu
31891	Arribe|Atallu|Azkarate|Azpirotz|Errazkin|Gaintza|Intza|Lezaeta|Uztegi
31892	Aldaba|Aldaz|Aristregui|Ariz|Erice (Iza)|Larumbe|Ochovi|Orderiz|Osinaga|Sarasa|Sarasate|Zuasti (Iza)
32001	Coiñas, Os|Eirexa, A (Quintela Canedo)|Ourense|Quintela Canedo|Val Do Regueiro
32002	Estrada De Reza (Reza-Ourense)|Ourense|Reza (Ourense)|Valenza, A (Barbadas)|Vilaescusa|Vistahermosa
32003	Ourense
32004	Ceboliño|Ourense
32005	Ourense
32070	Ourense
32071	Ourense
32080	Ourense
32100	Cambeo|Empalme|Gustei|Gustei (Santiago)|Sobral|Vilarnaz
32101	Agro Maior|Bainte|Baiuca, A (Vilamarin)|Barbantes (Vilamarin)|Barrio, O (Vilamarin)|Castiñeiras (Vilamarin)|Cazarrande|Cepedo, O|Chouzana, A (Vilamarin)|Cibran|Delvezon|Estrumil|Figueiredo, O (Vilamarin)|Fontao, O (Vilamarin)|Gosende|Leon|Parada (Vilamarin)|Pardiñeiros, Os|Pazos De Monte|Pica, A|Prado, O (Vilamarin)|Readegos (San Vicente)|Regueira Grande, A|Regueiros (Vilamarin)|Rio, O (Vilamarin)|San Martiño (Vilamarin)|Sestelos|Val, O (Vilamarin)|Vilamarin
32102	Tamallancos|Tamallancos (Santa Maria)
32103	Cudeiro|Cudeiro (San Pedro)
32111	Figueiroa (Paderne De Allariz)|San Salvador De Mourisco (Paderne De Allariz)|San Xes (Paderne De Allariz)
32112	Cantoña (Paderne De Allariz)|Concieiro (Paderne De Allariz)|Figueiredo (Paderne De Allariz)|Golpellas (Paderne De Allariz)|Paderne (Paderne De Allariz)|San Lourenzo De Siabal (Paderne De Allariz)|Siabal (Paderne De Allariz)|Solbeira (Paderne De Allariz)
32120	Ansariz|Armental|Cerdeiras, As (Peroxa)|Codosedo (Peroxa, A)|Couselo|Cuartas, As|Entrambosrios (Peroxa, A)|Ladredo|Marcelle (Vilamarin)|Montos|Orban (Vilamarin)|Outraldea, A|Palacio, O (Orban)|Pazos|Penela, A|Pereiro, O (Vilamarin)|Piton|Raña, A|Regolevado|Saa (Peroxa, A)|San Cibrao (Peroxa, A)|Toldavia|Vilar, O|Xagrade
32130	Cea|Cea (San Cristovo)
32135	Canda, A (San Mamede)|Freas Da Canda
32136	Oseira (San Cristovo De Cea)|Vales (San Cristovo De Cea)
32137	Albarona|Alen (Coiras)|Arenteiriño (San Cristovo De Cea)|Arenteiro|Barran (Piñor)|Cales (Piñor)|Carballediña|Casandulfe|Casmoniño|Coiras|Fontao (Piñor)|Fontelo (Piñor)|Loeda (San Paio)|Lousado (Piñor)|Outeiro (Loeda-Piñor)|Outeiro, O (Coiras)|Ovenza|Pallota, A (Piñor)|Pazo, O (Coiras)|Piñor Barran|Portela De Baixo (Piñor)|Portela De Riba (Piñor)|Senderiz (Piñor)|Senra (Piñor)|Sestos|Torguedo|Torre, A (Piñor)
32138	Alen (Torcela)|Cal, A (Piñor)|Canices|Carballeda (Piñor)|Casarellos|Corneas (Cea)|Derramada, A|Desterro (Piñor Cea)|Desterro (Santa Maria)|Eirexe, A (Piñor)|Grobas (Piñor)|Moire|Outeiro, O (Torcela)|Pereira (Piñor)|Ponte, A (Piñor)|Reino, O|Torcela|Vilar (Piñor)
32139	Ariz|Cazarrancas|Eirexa Vella, A|Fontaiñas, As (San Cristovo De Cea)|Gabian (San Cristovo De Cea)|Gavian|Lamas (San Cristovo De Cea)|Longos (Santa Baia)|San Fagundo (Cea)|San Martiño De Lamas
32140	Arbor|Boimorto (Santa Baia)|Borulfe|Bouzas (Vilamarin)|Crecedur|Fondo De Vila (Vilamarin)|Ouxeas, As|Oxen|Palacio, O (Vilamarin)|Rego, O (Vilamarin)|Reguengo, O (Vilamarin)|Sobreira (Vilamarin)
32141	Agra, A (San Cristovo De Cea)|Anllo (Cea)|Ardesende|Biduedo (San Cristovo De Cea)|Bustelo (Cea)|Casanova, A (Cea)|Castrelo (Cea)|Chao Real|Costa De Monte (San Cristovo De Cea)|Covas (Cea)|Ermida, A (San Cristovo De Cea)|Faramontaos (San Cristovo De Cea)|Faton|Ferreiros, Os (San Cristovo De Cea)|Fondo De Vila (San Cristovo De Cea)|Mandras (San Cristovo De Cea)|Mosteiron|Nogueira (Cea)|Paramios|Pazos (San Cristovo De Cea)|Peago|Pereda (San Cristovo De Cea)|Ponte Mandras|Pulledo|Regueira, A (San Cristovo De Cea)|Ricovelo|Rozadas|Souto (San Cristovo De Cea)|Tellado, O (San Cristovo De Cea)|Torre, A (Cea)|Toubes (San Cristovo De Cea)|Val, O (San Cristovo De Cea)|Vila, A (San Cristovo De Cea)|Vilaseco (San Cristovo De Cea)|Vilela (San Cristovo Cea)|Viña (San Cristovo De Cea)|Zarza
32150	Celaguantes (San Xulian)|Cinco Nogueiras|Peroxa, A (Peroxa, A)|Peroxa, A (Santiago)|Toubes (Peroxa, A)|Toubes (Santiago)|Vilarrubin (San Martiño)
32151	Berdelle|Besteiros|Bouza Longa|Bouzas Vedras|Bustos|Casarizas, As|Fontefria (Peroxa, A)|Graices (San Vicente)|Mirallos (Peroxa, A)|Moreda|Salceda (Peroxa, A)|San Nicolao|San Xes Da Peroxa (San Xes)|Senon|Turbisquedo|Turzavella|Vilasusa
32152	Alban (San Paio)|Barra, A|Barra, A (Santa Maria)|Bergaza|Cales (Coles)|Coles (San Xoan)|Fontefiz|Gueral (San Martiño)|Madalena, A|Moure|Ocelle (Santa Maria)|Outeiro (Ucelle)|Vilar Da Barra|Vilarchao (Coles)
32153	Alban (Santa Mariña)
32160	Alcouce, O|Baldomar|Cinseiro|Cortecadela|Espartedo|Fiscal|Fontefria (Nogueira De Ramuin)|Fontes (Nogueira De Ramuin)|Lama Forcada|Liñares (Nogueira De Ramuin)|Luintra|Monteverde|Moura (Nogueira De Ramuin)|Mundin (Nogueira De Ramuin)|Nogueira De Ramuin|Pacios (Nogueira De Ramuin)|Raposas, As|Requeixo (Loña-N. Ramuin)|Rubiacos|Santa Cruz (Nogueira De Ramuin)|Seara De Arriba, A|Sobrado (Nogueira De Ramuin)|Souto (Nogueira De Ramuin)|Vilasuxa|Vilouriz
32161	Armariz (Nogueira De Ramuin)|Armariz (San Cristovo)|Cachapraza|Cimadevila (Nogueira De Ramuin)|Costela, A (Nogueira De Ramuin)|Eiradela|Faramontaos (Nogueira De Ramuin)|Montecelo (Nogueira De Ramuin)|Saceda (Nogueira De Ramuin)|San Miguel Do Campo|Santa Seguiña|Toxedo, O|Val Do Pereiro
32164	Cerreda (Nogueira De Ramuin)|Santo Estevo De Ribas De Sil (Nogueira De Ramuin)|Vilar De Cerreda (Nogueira De Ramuin)|Vilar De Cerreda (Santa Baia)
32170	Amoeiro|Amoeiro (Santa Maria)|Bubeiras|Burguete, O|Codeseda|Cornoces|Garabatos, Os|Outeiro (Parada De Amoeiro)|Parada De Amoeiro|Sabariz (Amoeiro)
32172	Abruciños|Albeiros|Arcos, Os|Bergueira, A|Cerval|Fechos|Figueiras|Fontefria (Amoeiro)|Formigueiro, O|Loureiro (Amoeiro)|Monte Asnal|Rouzos (San Cibrao)|Soutomanco|Torre De Rouzos, A|Trasalba (San Pedro)
32200	Cortegada (Cortegada)
32211	Aldea De Souto (Cortegada)|Arnoia Seca|Casares Da Virxe|Casares De Refoxos|Cerdeiral|Cimadevila (Pao, O)|Cimadevila (Val, O)|Encoutada, A|Fondevila (Cortegada)|Freiria, A|Levada, A|Louredo (Cortegada)|Muradelle|Piñon|Poulo (Gomesende)|Pousa, A (Cortegada)|Pousadoiro, O|Refoxos (Cortegada)|Regueiro, O (Cortegada)|Torre, A (Cortegada)|Val, O (Gomesende)|Vergazas|Vilaverde (Cortegada)|Vilela (Cortegada)|Viso, O (Gomesende)|Zaparin
32212	Abelida, A|Abellas|Agrufeixe|Balteiro (Gomesende)|Barreiras, As (Gomesende)|Buiñas|Cachopos, Os|Carballeiras, As (Gomesende)|Casal, O (Gomesende)|Casaldrigo|Casanova, A (Gomesende)|Cerdal (Gomesende)|Chaos, Os (Gomesende)|Cimadevila (San Lourenzo De Fustans)|Cortiñal|Cortiñas, As|Couto (Gomesende)|Curro, O|Dornelas (Gomesende)|Dorno, O|Feardos|Folon, O|Fustans|Garabelos (Gomesende)|Granxa, A (Gomesende)|Guielas|Lamaboa|Legumieira, A|Louredo (Gomesende)|Mariz|Matama (Gomesende)|Meixueiro, O|Moreiras (Gomesende)|Noval, O|Ocella, A|Outeiriños, Os (Gomesende)|Outeiro Da Guia|Pao, O|Paredes (Gomesende)|Paredes Do Pao|Penama (Gomesende)|Pombiña, A|Redondallo|Regadas, As (Gomesende)|Regas, As (Gomesende)|Reguenga (Gomesende)|San Paio (Gomesende)|Sobrado (Gomesende)|Souto Do Bispo|Souto, O (Gomesende)|Tixosa (Gomesende)|Travesa, A|Trigueira, A (Gomesende)|Val De Feardos|Veiga, A (Gomesende)|Vilacova|Viñal (Gomesende)
32213	Abelenda De Balongo|Casal, O (Cortegada)|Casaldalvaro|Decolada, A|Leirado (Cortegada)|Merens|Outeiral|Pazo (Cortegada)|Peralba|Pereiro, O (Cortegada)|Ponte Trado, A|Rabiño (San Bieito)|Sa (Cortegada)|Seixomil|Valongo|Vilanova Da Barca (Cortegada)
32226	Amean|Carballal (Pradenda)|Casal De Veco|Crespos (Padrenda)|Freans (Padrenda)|Gresufe|Lamas, As (Padrenda)|Morgade (Padrenda)|San Amaro (Padrenda)|San Roque De Crespos
32227	Entrerrios|Esmoriz|Gorgua|Grixo (Padrenda)|San Pedro Da Torre|Vilar (Padrenda)
32228	Abeleira, A (Padrenda)|Alen (Monte Redondo)|Ancado|Cerdeiro (Padrenda)|Chan Do Crego|Escusalla, A (Padrenda)|Lapiñeiras|Ludeiro (Padrenda)|Monte Redondo|Monterredondo (Padrenda)|Outeiro, O (Padrenda)|Outon|Pardellas|Pereiro, O (Padrenda)|Quinta, A (Padrenda)|San Antonio (Padrenda)
32229	Lavandeira (Padrenda)|Padrenda (San Cibran)|Pontebarxas (Padrenda)
32235	Abelleira De Arriba, A|Abelleira, A (Pontedeva)|Escusalla, A (Pontedeva)|Freans De Deva|Pedrosa (Pontedeva)|Ponte, A (Pontedeva)|Pontedeva|Trado|Trigueira, A (Pontedeva)|Xinzo De Deva
32236	Agra De Desteriz|Condado, O (Padrenda)|Desteriz|Frieira, A (Padrenda)|Lordelo|Notaria, A|Sa (Padrenda)
32300	Barco, O|Barco, O (San Amaro)
32310	Rubia (Santa Mariña)
32311	Barrio De Cascalla, O|Barrio E Castelo|Biobra|Castelo, O (Rubia)|Covas (Rubia)|Veiga De Cascalla, A
32312	Oulego|Porto, O (Rubia)|Real, O|Robledo Da Lastra, O
32314	Alixo|Candis|Carreiras, As|Coedo (Barco)|Millarouso|Raxoa|San Martiño (Barco)|Santigoso (Barco De Valdeorras, O)|Santurxo|Soulecin|Vilariño (Barco De Valdeorras, O)
32315	Arcos (Vilamartin De Valdeorras)|Arnado (Vilamartin De Valdeorras)|Cesures|Fervenza (Barco De Valdeorras, O)|Meiral, O|Santa Mariña (Barco De Valdeorras, O)|Santa Mariña Do Monte (Barco, O)|Vales (Barco De Valdeorras, O)|Viloira (San Martiño)
32317	Ferradal (Barco De Valdeorras, O)|Pobra, A (Barco, O)|Proba, A (Santa Maria)|Veigamuiños|Xagoaza
32318	Castro De Valdeorras, O (Santa Maria)|Castro Vilariño|Forcadela E Nogaledo (Santiago)|Vilanova (Barco De Valdeorras, O)|Viloval
32320	Quereño (San Cristovo)
32329	Pardollan|Vilardesilva
32330	Sobradelo (Carballeda)|Sobradelo (Santa Maria)
32334	Viladequinta
32336	Bascois|Casoio|Entoma|Pusmazan|Ricosende|Riodolas|Robledo De Domiz|Santa Cruz (Carballeda)|Soutadoiro
32337	Casaio|Lardeira|Portela (Carballeda)|Portela Do Trigal, A|Trigal, O
32338	Candeda (Carballeda)|Domiz (Carballeda)|Pumares (Carballeda)|San Xusto (Carballeda)|Vila (Carballeda)
32340	Correxais (Vilamartin De Valdeorras)|Covas, As (Vilamartin De Valdeorras)|Penouta (Vilamartin De Valdeorras)|San Miguel Do Outeiro|Valdegodos|Valencia Do Sil|Vilamartin De Valdeorras
32348	Aldea, A (Vilamartin De Valdeorras)|Barxeles|Cernego|Chelos, Os (Vilamartin De Valdeorras)|Corgomo|Mazo, O|Robledo, O|San Vicente De Leira
32350	Fontei|Rua De Valdeorras, A (Rua, A)
32356	Petin
32357	Carballal (Petin)|Cima De Vila (Rua, A)|Mones|Outeiro (Petin)|Pacio (Rua, A)|Porto, O|Roblido (Rua, A)|Rua Vella, A|San Fiz (Veiga, A)|San Paio (Petin)|San Xulian (Rua, A)|Santa Maria (Petin)|Santoalla (Petin)|Seixo, O (Santo Anxo)|Somoza (Rua, A)|Vilela (Rua, A)
32358	Hermida Vella|Larouco|Poulo (Larouco)|Seadur
32360	Veiga, A (Santa Maria)
32365	Ponte, A (Veiga, A)|Requeixo (Veiga, A)|San Lourenzo (San Lourenzo)|Xares
32366	Casdenodres|Curra|Edreira (Santa Columba)|Espiño (Veiga, A)|Lamalonga (Veiga, A)|Meixide|Prado (Veiga, A)|Vilanova (Veiga, A)
32368	Candeda (Veiga, A)|Carracedo (Veiga, A)|Castromarigo|Corexido (Santo Estevo)|Meda|Prada (Veiga, A)|Pradolongo|Riomao|Santa Cristina (Veiga, A)|Vilaboa (Veiga, A)
32369	Baños (Veiga, A)|Castromao (Veiga, A)|Corzos (Veiga, A)|Seoane (Veiga, A)|Valdin
32370	Caseta, A (Petin)|Freixido (Sagrado Corazon De Xesus)|Freixido De Arriba
32371	Portela De Portomourisco, A|Portela, A (Larouco)|Portomourisco
32372	Aceveda|Barxa, A (Bolo, O)|Celavente|Chandoiro|Lentellais|San Martiño (Bolo, O)
32373	Bolo, O|Chao Das Donas|Fornelos (Bolo, O)|Orxais, Os|Paradela (Bolo, O)|San Pedro Dos Nabos|Teixido|Valdanta|Xava
32375	Buxan (Bolo, O)|Cambela (Bolo, O)|Casasola (Bolo, O)|Celeiros (Bolo, O)|Chao De Castro|Ermidas, As (Bolo, O)|Rigueira, A|Santa Cruz Do Bolo|Tuxe|Valbuxan|Vao, O (Bolo, O)|Vilaseco (Bolo, O)
32400	Foz, A (Ribadavia)|Ribadavia
32410	Melon|Melon (Santa Maria)
32411	Covelo (Melon)|Ibia, A|Quins|Quins (Santa Maria)
32412	Fermosas, As|Laceiras, As (Carballeda De Avia)|Novoa|Prados, Os|Vilar De Condes
32413	Carballeda (San Miguel)|Carballeda De Avia
32415	Campo Redondo|Chabolas, As (Ribadavia)|Esposende (Rivadavia)|Groba, A (Ribadavia)|Sanin|Seixo, O (Ribadavia)|Val De Pereira|Ventosela (Ribadavia)
32416	Franqueiran, A|Regodeigon|San Cristovo (Ribadavia)|San Estebo De Novoa
32417	Arnoia, A (San Salvador)|Outeiro Cruz|Remuiño|Reza, A
32418	Francelos|Prexigueiro (Ribadavia)|Quinza|San Paio (Ribadavia)|Santa Cristina (Ribadavia)
32419	Barzamedelle (Bieite)|Bieite
32420	Leiro
32425	Beran|Caldelas
32426	Orega|Outeiro, O (Orega)
32428	Lamas (Santa Maria)|Lebosende|Lebosende (San Miguel)|Paredes (Leiro)|Sa (Leiro)|San Clodio (Santa Maria)|Serantes|Suigrexa (Leiro)
32429	Cubilledo|Gomariz (Leiro)|Lalon|Vilerma, A
32430	Albin|Astariz|Barral (Castrelo De Miño)|Bouza, A (Castrelo De Miño)|Bouzas, As (Castrelo De Miño)|Casardeita (Castrelo De Miño)|Castrelo De Miño (Santa Maria)|Covelas (Castrelo De Miño)|Fondo De Vila (Castrelo De Miño)|Foxo|Freas (Castrelo De Miño)|Frieira, A (Castrelo De Miño)|Macendo (Santa Maria)|Meizo|Noallo (Castrelo De Miño)|Oleiros (Castrelo De Miño)|Parada (Castrelo De Miño)|Paradela (Castrelo De Miño)|Pousada (Castrelo De Miño)|Pousadoiro, O (Castrelo De Miño)|Prado De Miño (Santa Maria)|Ramiras (Castrelo De Miño)|San Pedro (Castrelo De Miño)|Santo Estevo (Castrelo De Miño)|Señorin (Castrelo De Miño)|Souto (Castrelo De Miño)|Souto (Macendo)|Tallon|Troncoso|Vide (Castrelo De Miño)|Vilela (Castrelo Miño)
32431	Beade (Beade)
32432	Regadas, As (Beade)
32433	Abelenda Das Penas|Balde|Beiro (Carbaleda De Avia)|Beiro De Abaixo|Beiro De Arriba|Casares (Carballeda De Avia)|Faramontaos (Carballeda De Avia)|Fornelos (Carballeda De Avia)|Muimenta (Carballeda De Avia)|Sariñas|Serra, A
32440	Peares, Os
32448	Almorfe|Barxela, A|Bertelo|Borraxos, Os|Buzaxe, A|Carballeira, A (Nogueira De Ramuin)|Casanova (Nogueira De Ramuin)|Casdecid|Celeiros (Nogueira De Ramuin)|Coitelo, O|Covelas (Nogueira De Ramuin)|Ferreirua, A|Forraqueira, A|Pena Do Chao|Pena, A (Nogueira De Ramuin)|Penalba, A (Nogueira De Ramuin)|Pereira, A (Nogueira De Ramuin)|Pousada (Nogueira De Ramuin)|Ramuin|San Vicente (Nogueira De Ramuin)|Santa Xusta|Seara Do Rio, A|Souto Do Chao|Val, O (Nogueira De Ramuin)|Varalonga|Vilanova (Nogueira De Ramuin)|Viñoas|Zumento
32449	Airoa De Beacan|Areas (Peroxa, A)|Barras, As|Barrio (Peroxa, A)|Beacan|Carracedo (Peroxa, A)|Cascallal|Casferreiro|Casgutierrez|Caspicon|Coto, O (Peroxa, A)|Fontao, O (Beacan)|Outeiro De Beacan, O|Outeiro De Carracedo|Pacio (Peroxa, A)|Pedreira (Peroxa, A)|Recheda, A|Reza (Peroxa, A)|Ribas (Peroxa, A)|San Paio (Peroxa, A)|Sandamiro|Vilaboa (Peroxa, A)|Vilamaior (Peroxa, A)|Vilar De Carracedo
32450	Barbantes (Cenlle) (Estacion)|Barca De Barbantes, A
32452	Ourantes|Rubias (Punxin)|Santome (Punxin)|Ventosela (Punxin)|Vilar (Punxin)
32453	Barrio (Salamonde)|Castro, O (San Amaro)|Eiras (San Amaro)|Ferradal, O|Gaime|Gontan (San Amaro)|Lamego|Las, San Cibrao (San Amaro)|Outeiro (Salamonde)|Pallota, A (San Amaro)|Quintas, As (San Amaro)|Reguenga, A (Eiras)|Sabariz (San Amaro)|Salamonde|San Roque (San Amaro)|Santa Eufemia (San Amaro)|Souto (Salamonde)|Touza, A (Eiras)|Tralorrio (San Amaro)|Veiga, A (San Amaro)|Xinzo (San Amaro)
32454	Cenlle|Chabolas, As (Cenlle)|Cima De Vila (Cenlle)|Esposende (Cenlle)|Lama, A (Cenlle)|Nazara|Osmo|Pena, A (Cenlle)|Pena, A (San Lorenzo)|Pereiro, O (Cenlle)|Piñeiro (Cenlle)|Riobo (Cenlle)|Saa (Cenlle)|Sadurnin|Torre, A (Cenlle)|Vilar De Rei
32455	Anllo|Barrio (Navio)|Beariz (San Amaro)|Brea, A|Calve|Campo Da Festa, O|Carballeira, A (San Amaro)|Casanova, A (Anllo)|Casas Novas, As (San Amaro)|Caseta, A (San Amaro)|Cruceiro, O|Cruz, A (San Amaro)|Figueiredo, O (San Amaro)|Grixoa (Santa Maria)|Hospicio, O (San Amaro)|Navio|Outeiro, O (Beariz)|Outeiro, O (Navio)|Pazos (San Amaro)|Piroño|Quinta, A (Cenlle)|Quinta, A (San Amaro)|Reguenga, A (Navio)|San Amaro (San Amaro)|San Sebastian|Sandulces|Sergude|Sobrado (San Amaro)|Touza, A (Navio)|Varon (San Fiz) (San Amaro)|Ventoselo (Beariz)|Ventoselo (Navio)|Vilar (San Amaro)|Viriña, A|Viñas, As
32456	Bacelo, O|Barbantes (Punxin)|Barxeles (Punxin)|Castiñeira, A|Chao, O (Punxin)|Conde De Arriba|Condes De Abaixo|Figueiroa (Punxin)|Fontedouro|Forxa, A|Moa, A|Outeiro, O (Punxin)|Pazos De Abaixo|Pazos De Arriba|Punxin (Capital)|Quintas, As (Punxin)|Rego, O (Punxin)|San Roque (Punxin)|Santo Estevo (Punxin)|Souto, O (Punxin)|Val, O (Punxin)|Vila, A (Punxin)|Vilamoure|Vilela (Punxin)|Vilerma, A (Punxin)|Viñao, O
32457	Freas (Punxin)|Pousa, A (Santa Maria Freas)
32459	Laias|Razamonde|Trasariz|Xubin
32500	Arcos (Santa Maria)|Carballiño, O
32510	Bagarelas|Baron, O (Seoane De Arcos)|Bertamil|Boedes|Carballeda (Carballiño, O)|Costoia|Dornela|Fontao (Carballiño, O)|Granxa, A (Carballino)|Lama, A (Carballino)|Larouce|Lobas (Carballiño, O)|Mosteiro (Carballiño, O)|Mouriz|Paradela (Carballiño, O)|Piteira, A|Pol (Carballiño, O)|Ponte Veiga (San Lourenzo)|Saa (Carballiño, O)|Seoane (Carballiño, O)|Sobrado (Carballiño, O)|Souto (Piteira)|Trigas (Lobas-Carballiño, O)|Valeiras|Valfrio|Xuio|Zafra
32512	Astureses|Batallas (Boboras)|Cibreiro|Eixan|Fondo De Vila (Boboras)|Igresario, O (Brues)|Xoane
32514	Albarellos (Boboras)|Almuzara, A|Boboras|Cameixa|Corneas (Boboras)|Costa, A (Boboras)|Distriz|Eiravedra (Boboras)|Franza|Gontelle|Granxa, A (Boboras)|Igresario, O (Albarellos-Boboras)|Igresario, O (Xuvencos)|Lamela (Boboras)|Laxas (Boboras)|Liñariños|Miandreiras|Moldes|Nonas|Parada (Boboras)|Paredes (Boboras)|Pazos De Arenteiro|Penedo De Xuvencos, O|Porto Do Carro, O|Quintas, As (Boboras)|Regueiro, O (Albarellos)(Babarellos)|Rodas|Sa (Boboras)|Salceda (Boboras)|Salon|San Bartolomeu|Sande (Boboras)|Sobredo (Boboras)|Valdesenda|Valiñas (Boboras)|Vilanova (Boboras)|Xesteira (Moldes-Boboras)|Xuvencos
32515	Aguisar|Bifos|Caldas, As|Campo Lamela|Campo, O (Baron, O)|Centeas|Covela (Carballiño)|Covelo, O (Carballino, O)|Elfe|Fonteantiga|Montegrande|Partovia|Penedo, O (Carballino, O)|Porto De Eguas|Refoxo (Carballiño)|Señorin (Carballiño)|Sona|Torron, O (Carballiño, O)|Varille|Veiga, A (Baron, O)
32516	Alboio, O|Banga|Bouteiro|Cabanelas (San Xoan)|Corval|Fraga, A|Mesego|Miomas|Pazo, O (Banga)|Reguenga, A (Carballino, O)|Sagra (San Martiño)|Seara, A (Carballino)|Souto (Banga)|Trigas (Sagra)
32520	Abelenda (Avion)|Amiudal (Avion)|Avion|Baiste (Avion)|Barroso (Avion)|Beresmo (Avion)|Corcores (Avion)|Cortegazas (Avion)|Couso (Avion)|Liñares, Os (Baiste, Avion)|Nieva (Avion)
32521	Brues|Regueiro (San Pedro)|Riande
32522	Xurenzas|Xurenzas (San Pedro)
32523	Cardelle|Feas (Boboras)|Feas (San Anton)|Moreiras (Boboras)|Moreiras (Santa Mariña)|Vecoña
32525	Beariz|Doade (Xirazga, Beariz)|Lebozan (Beariz)|Magros (Beariz)|Xirazga (Beariz)
32526	Xendive (Boboras)|Xendive (San Mamede)
32530	Barro (Cusanca)|Barrocal, O|Baxin|Campo (Irixo, O)|Cardedo, O|Casares (Campo)|Castro, O (Irixo, O)|Chelos (Irixo, O)|Condomiña, A (Campo)|Costa, A (Irixo, O)|Coto, O (Irixo, O)|Eirexa, A (Irixo, O)|Ermida, A (Irixo, O)|Esfarrapa, A|Fabeiros|Filgueira (Campo)|Filgueira (Cusanca)|Fraga, A (Irixo, O)|Irixo De Arriba, O|Lagorzos|Laiña|Lama, A (Irixo, O)|Marnotes (Irixo, O)|Menaz|Orosa (Irixo, O)|Pedrouzo (Irixo, O)|Porto Da Veiga|Reguega|Regueiro (Irixo, O)|Regueiro, O (San Pedro)|Rio, O (Irixo, O)|San Cosmede De Cusanca (San Cosmede)|Segade|Sueirexa (Cusanca)|Surribas (Cusanca)|Tellado Do Campo, O|Vila (Irixo, O)|Vixide|Zacarade
32534	Batallas (Carballiño, O)|Enfesta (Carballiño, O)|Esgueva|Godas|Longoseiros (Santa Mariña)|Madarnas (Carballiño, O)|Medela|Mudelos (Santiago)|Ponterriza|Ponteveiga (San Lourenzo)
32536	Bugalleira De Abaixo, A|Bugalleira De Arriba, A|Bugalleira, A|Condomiña, A (Dadin)|Dadin|Enfreado, O|Saavedra|Seara, A (Irixo, O)
32537	Barcia (Irixo, O)|Casar, O (Readigos)|Casares, Os (Cida, A)|Castiñeira (Irixo, O)|Cida, A|Fontes (Irixo, O)|Nabas (Irixo, O)|Orros|Outeiro, O (Readegos)|Parada De Laviote|Paredes (Irixo, O)|Prexigueiro (Irixo, O)|Readigos (Irixo, O)|Ribela (Irixo, O)|Santiso (Irixo, O)|Valdesoiro|Xirei
32539	Cangues (O Irixo)|Corneda (Irixo, O)|Espiñeira (O Irixo)|Froufe (O Irixo)|Loureiro (Irixo, O)
32540	Gudiña, A|Gudiña, A (San Martiño E San Pedro)
32545	Barxa (Gudiña, A)|Seixo, O (Gudiña, A)
32546	Parada Da Serra (San Lucas)
32547	Carracedo Da Serra|Pentes (San Mamede)|San Lourenzo De Pentes|Venda Do Bolaño, A
32548	Cadavos|Canizo, O|Castromil|Chaguazoso (Mezquita, A)|Manzalvos|Pereiro, O (Mezquita, A)|Tameiron, O
32549	Canda, A|Esculqueira, A|Mezquita, A|Santigoso (Mezquita, A)|Vilavella, A
32550	Viana Do Bolo
32551	Conso|Mormentelos|San Cristovo|Veiguiña, A (Vilariño De Conso)
32552	Entrecinsa|Hedrada|Invernadeiro, O|Pradoalbar|Sabuguido|San Mamede (San Mamede)|San Mamede (Vilariño Conso)|Soutelo (Vilariño De Conso)|Soutogrande
32554	Caldesiños|Mosexos|Pinza|Ponton (Viana Do Bolo)|San Cibrao (Viana Do Bolo)|Seoane De Abaixo
32555	Ermida, A (Viana)|Vilardemilo|Vilaseco Da Serra
32556	Covelo (San Lourenzo)|Mourisca (Viana Do Bolo)|San Mamede (Viana Do Bolo)|Tabazoa De Hedroso
32557	Ardexarxe|Castiñeira (Vilariño De Conso)|Chaguazoso (Vilariño De Conso)|Fradelo|Grixoa (San Pedro)|Quintela Do Pando|Santa Mariña Da Ponte|Vilariño De Conso|Vilarmeao (Viana)
32558	Castiñeira (Viana Do Bolo)|Cepedelo|Dradelo|Froxais|Hedroso|Louzaregos|Paradela (Viana Do Bolo)|Penouta (Viana De Bolo)|Pradoramisquedo|Punxeiro|Quintela De Hedroso|Quintela De Umoso|Ramilo|Rubiais|San Martiño (Viana Do Bolo)|Santa Mariña De Froxais|Santo Agostiño|Sever (Viana Do Bolo)|Tabazoa De Umoso|Umoso|Vilar De Goia
32560	Pradocabalos|Seoane De Arriba|Solbeira (Viana Do Bolo)
32562	Bembibre|Fornelos De Filloas
32563	Bouza (Viana Do Bolo)|Castro, O (Pexeiros)|Pexeiros (Viana Do Bolo)
32570	Maside (Casco Urbano)|Maside (Santo Tome)
32573	Amarante (Maside)|Dacon (Amarante, Maside)|Fontela, A (Amarante, Maside)|Santa Comba Do Trevoedo (Maside)
32574	Armeses (Maside)|Rañestres (Maside)
32575	Lago, O (Maside)
32577	Garabas (Maside)|Louredo (Maside)|Piñeiro (Maside)|Quintas, As (Maside)
32600	Cabreiroa|Verin
32610	Castrelo De Abaixo|Castrelo De Cima|Covelas (Rios)|Mente, O|Mourisco, O|Navallo, O (Rios)|Pena Do Souto|Rios (Santa Maria)|San Paio (Rios)|Silva, A (Rios)|Veiga Do Seixo, A|Vendas Da Barreira, As
32611	Feilas (Vilardevos)|Fumaces|Mañoas|Monteveloso|Piornedo, O|Pousada (Rios)|Progo|Rubios|San Cristovo (Rios)|San Pedro Pousada|Santa Baia (Rios)|Trasestrada (Santo Estevo)|Trepa, A|Vilariño Das Touzas
32612	Queirugas (Verin)
32613	Bouses|Casas Dos Montes, As|Chas, As (Oimbra)|Espiño (Oimbra)|Granxa, A (Oimbra)|Oimbra|Rosal, O|San Cibrao (Oimbra)|Videferre
32615	Abedes
32616	Arzadegos|Enxames|Florderrei Vello (Vilardevos)|Soutocovo|Terroso|Vilar De Cervos|Vilardevos|Vilarello (Vilardevos)
32617	Arzoa|Berrande|Lamasdeite|Moialde|Osoño (San Pedro)|Santa Comba (Verin)|Santa Comba De Baroncelle|Santa Maria De Traseirexa (Santa Maria)|Soutochao (Santa Maria)|Trabe, A
32618	Albarellos (Monterrei)|Caridade, A|Flariz|Guimarei|Infesta (Monterrey)|Madanela, A (Monterrei)|Medeiros|Paradiña (Monterrei)|Rebordondo (Monterrei)|Salgueira, A|San Cristovo (Monterrei)|Sandin (Monterrei)|Vilaza
32619	Monterrei (Santa Maria) (Verin)|Pazos (Verin)
32620	Cimadevila (Laza)|Laza (Verin)|Souteliño (Laza)
32621	Arcucelos|Camba (Laza)|Cerdedelo|Eiras (Laza)|Matama (Laza)|Pereiro, O (Laza)|Retorta (Laza)|Toro|Trez
32622	Albergueria, A (Laza)|Caldeliñas (Verin)|Carraxo|Castro De Laza, O (San Pedro)|Salgueiro, O (Verin)|Santo, O|Vilamaior Do Val (Santiago)
32624	Estevesiños|Mixos|Nocedo Do Val|Vences
32625	Castrelo Do Val|Pepin|Ribas (S Vicente Pepin)
32626	Campobecerros|Fontefria (Castrelo Do Val)|Gondulfes|Marban|Portocamba|San Paio (Castrelo Do Val)|Sanguñedo (Castrelo Do Val)|Servoi|Veiga De Nostre|Vilar (Castrelo Do Val)
32627	Rasela, A (Verin)|Tintores (Verin)|Vilela (Verin)
32630	Xinzo De Limia
32631	Boado|Couso (Sarreaus)|Freande|Freixo (Sarreaus)|Padroso (Sarreaus)|Paradiña (Sarreaus)|Perrelos|Pidre|Piñeira Seca|Porto Alto|Sarreaus|Sas (Sarreaus)|Solbeira (Xinzo De Limia)|Tarrazo
32632	Baltar|Fiestras, As|Garabelos (Baltar)|Gomariz (Baltar)|Laroa|Niñodaguia (Baltar)|Nocedo (Blancos, Os)|Noveas|San Pedro De Laroa|Texos
32633	Abades|Montecelo (Baltar)|Quinta, A (Baltar)|Sabucedo Dos Peros|San Martiño Dos Peros|San Paio (Baltar)|Santo Antoiño (Baltar)|Vilamaior Da Boullosa
32634	Aguis|Aguis (Blancos)|Aspra, A|Blancos, Os|Covas (Blancos, Os)|Covelas (Blancos, Os)|Cuquexos, Os|Fonte Arcada|Guntin|Loureses|Mosqueiro, O (Blancos, Os)|Outeiro, O (Blancos, Os)|Ouvigo|Penalonga|Pexeiros (Blancos, Os)|Rabea, A|Vilar (Blancos, Os)
32635	Cima De Ribeira (San Miguel)|Damil|Gudes|Guntimil (Xinzo De Limia)|Lamas (Santa Maria)|Mosteiro, O (Xinzo De Limia)|Parada De Ribeira
32636	Amea|Baronzas|Bresmaus|Codesedo (Sarreaus)|Cortegada (Sarreaus)|Folgoso (Sarreaus)|Meilas|Morgade (Xinzo De Limia)|Pazos (Sarreaus)|Pena, A (Xinzo De Limia)|Penedo, O (Sarreaus)|Portela Da Quinta, A|Soutelo (Xinzo De Limia)|Trandeiras (Xinzo De Limia)|Veredo, O
32637	Faramontaos (Xinzo De Limia)|Gudin|Moreiras (Xinzo De Limia)|Mosteiro Ribeira (Xinzo Limia)|Mosteiro, O|Novas (Xinzo De Limia)|Paredes (Xinzo De Limia)|Rebordecha|Seoane De Oleiros
32640	Ganade (San Bartolomeu)|San Vitoiro (Xinzo De Limia)
32641	Airavella (Porqueira)|Eido De Lamas|Eido De Ribeira|Filgueira, A|Gandara, A (Porqueira)|Lagoa, A (Porqueira)|Martices (Porqueira)|Penin Novo|Quintas, As (Porqueira)|Rial, O (Sabucedo)|Sabucedo (Porqueira)|Toxal, O
32643	Faramiñas|Faramontaos (Porqueira)|Fontemoura|Forxa, A (Porqueira)|Lobios|Paradela (Porqueira)|Paradela De Abeleda|Porqueira (Porqueira)|Reboredo (Porqueira)|Retorta, A (Porqueira)|San Lourenzo (Porqueira)|Sever (Porqueira)|Tellados (Porqueira)|Torre, A (Porqueira)|Xocin (Porqueira)
32644	Castelaus (Calvos De Randin)|San Mamede De Sobreganade (Porqueira)
32646	Paradela (Calvos De Randin)|Randin|Rubias (Calvos De Randin)|Rubias Dos Mixtos|Santiago De Rubias|Tosende (Baltar)|Vilar (Calvos De Randin)|Vilariño (Calvos De Randin)
32648	Calvos De Randin|Feas (Calvos De Randin)|Golpellas (Calvos De Randin)|Lobas (San Vicente)|Lomear|Padroso (Calvos De Randin)|Rioseco (Calvos De Randin)|Vila (Calvos De Randin)
32650	Casas Da Veiga, As (Vilar De Santos)|Vilar De Santos
32651	Breixomes|Laioso (Vilar De Santos)|Mosqueiro, O (Vilar De Santos)|Parada De Outeiro|Ponte, A (Vilar De Santos)|Toxediño|Venda, A (Vilar De Santos)|Vieiro, O
32652	Candas (San Martiño)|Lampaza (Santa Maria)|Rairiz De Veiga|Rairiz De Veiga (San Xoan)|Sabariz (San Pedro)|Sainza De Abaixo, A
32654	Amieiro Longo|Cancela, A|Carballal (Rairiz De Veiga)|Celme|Congostro (Rairiz De Veiga)|Eidobispo|Forxas (Rairiz De Veiga)|Martices (Rairiz De Veiga)|Maus, As (Rairiz De Veiga)|Ordes|Peaguda|Penelas (Rairiz De Veiga)|Raposeiras, As|Rañoa, A (Rairiz De Veiga)|Rial, O (Rairiz De Veiga)|San Miguel (Rairiz De Veiga)|Zapeaus
32655	Azoreiros|Barracel|Filgueiras (Rairiz De Veiga)|Guillamil|Nigueiroa (Rairiz De Veiga)|Quilmelas|Rosen
32660	Allariz
32664	Allariz (Santiago)|Bouzas, As|Casnadagaia|Castro, O (Allariz)|Coruxeira, A|Gundias (Allariz)|Outeiro De Orraca|Pedreira, A|Pousa, A (Allariz)|Pousada, A (Allariz)|Queiroas (San Breixo)|Queiroas Da Igrexa|Rial, O (Allariz)|San Mamede (Allariz)|San Vitoiro Da Mezquita (San Vitorio)|Santa Baia (Allariz)|Tain (Allariz)|Torre, A (Urros-Allariz)|Vilares (Allariz)
32665	San Martiño De Pazoo (San Martiño)|San Trocado|Seoane (Allariz)|Seoane (San Xoan)
32666	Coedo (Allariz)|Novas (Allariz)|Outeiro De Torneiros|Paradiñas (Allariz)|Penaflor|San Miguel (Allariz)|Torneiros (Allariz)
32667	Allariz (Santo Estevo)|Paciños (Allariz)|Requeixo De Valverde|Valverde (Allariz)
32668	Acea, A (Allariz)|Armea|Augas Santas|Casas Novas, As (Allariz)|Duci|Espiñeiros, Os (Allariz)|Laioso (Allariz)|Meire (Allariz)|Outeiro De Laxe|Rubias (Allariz)|Santa Mariña De Augas Santas|Santo Estevo (Allariz)|Souto, O (Allariz)|Tosende (Allariz)|Turzas|Vila, A (Allariz)|Vilar De Flores
32669	Cal, A (Allariz)|Coira, A|Enfestela, A|Folgoso (Allariz)|Guede (Allariz)|Roiriz
32670	Xunqueira De Ambia|Xunqueira De Ambia (Santa Maria A Real)
32678	Armariz (San Salvador)|Brandela, A|Casnaloba|Cerdeira (Xunqueira De Ambia)|Graña, A (Xunqueira De Ambia)|Pena, A (Xunqueira De Ambia)
32679	Abeleda, A (Xunqueira De Ambia)|Bobadela (Xunqueira De Ambia)|Busteliño|Bustelo (Xunqueira De Ambia)|Casasoa (Xunqueira De Ambia)|Cima De Vila (Xunqueira De Ambia)|Fondo De Vila (Xunqueira De Ambia)|Pazos Da Abeleda|San Roman|Sobradelo (Xunqueira De Ambia)|Tellada, A|Vilariño Da Veiga
32680	Atas (Santa Maria)|Baldriz|Mercedes, As
32688	Lamalonga (Cualedro)|Lucenza|Moimenta (Cualedro)|Pedrosa, A|Saceda, A|San Millao|Vilela (Cualedro)|Xironda, A
32689	Carzoa|Cualedro|Lamas (Cualedro)|Pena Verde|Rebordondo|San Martiño (Cualedro)
32690	Abeledo|Alto De Taboadela|Barrio, O (Taboadela)|Castro, O (Taboadela)|Covelo (Taboadela)|Eirexa, A (Taboadela)|Lavandeira (Taboadela)|Mezquita, A (Taboadela)|Mingarabeiza|Outeiro, O (Toran)|Palacio (Taboadela)|Pazos (Taboadela)|Pereiras (Taboadela)|Pumar (Taboadela)|Quintas, As (Taboadela)|Rectoral, A|Ribo|San Fiz (Taboadela)|Seara, A (Taboadela)|Silvosiño|Silvoso (Taboadela)|Soutomaior|Taboadela (Taboadela)|Telleira, A (Taboadela)|Toran|Venda Do Rio, A|Vilar (Taboadela)|Xociños
32691	Amendo, O|Espiñeiro (Taboadela)|Meson De Calvos, O|Outeiriño, O (Taboadela)|Pasadan|Petada, A|Pousa (Taboadela)|Reguenga, A (Taboadela)|San Xurxo Da Touza|Santa Locaia|Santas (Taboadela)|Touza (Taboadela)|Venda Nova, A|Veredo (Taboadela)
32692	Cardeita|Castro, O (Sandias)|Cerredelo|Coalloso|Couso De Limia|Couso De Limia (Sandias)|Pegas, As|Sandias|Santa Ana (Sandias)|Vilariño Das Poldras
32693	Arcos (Sandias)|Chousela, A|Corga, A|Fontela, A (Sandias)|Ladeira, A|Lavandeira, A|Piñeira De Abaixo|Piñeira De Arcos|Piñeira De Arriba|Zadagos
32695	Abavides|Casas (Trasmiras)|Chamosiños|Lobaces (Trasmiras)|Pardieiros, Os|Santa Baia De Chamosiños|Serralleira, A|Silvaescura|Soutelo (Trasmiras)|Trasmiras (Xinzo De Limia)|Vilar De Lebres|Zos
32696	Castelo, O (Trasmiras)|Escornabois|Lodoselo|Nocelo Da Pena|Rabal (Trasmiras)|Santo Andre (Trasmiras)|Seixas|Vila De Rei (San Salvador)|Vilaseca
32697	Mourazos|Tamagos|Tamaguelos
32698	Feces De Cima|Mandin|Queizas|Rabal (Oimbra)
32699	Feces De Abaixo
32700	Maceda
32701	Baños De Molgas|Baños De Molgas (San Salvador)|Calvelo (Baños De Molgas)|Guamil|Lama Ma|Poedo|Presqueira|Vide (Baños De Molgas)|Vide (San Xoan)|Vilariño (Baños De Molgas)|Xocin (Baños De Molgas)
32702	Boveda (Vilar De Barrio)|Padreda|Prado (Vilar De Barrio)|Rebordechao|Seiro|Vilar De Barrio|Vilar De Gomareite
32703	Maceda (San Pedro)|Piuca|Zorelle (Santiago)
32704	Almoite|Ambia|Betan|Cantoña (Baños De Molgas)|Coucieiro (Baños De Molgas)|Ponte Ambia|San Pedro De Ribeira|Sanguñedo (Baños De Molgas)
32705	Albergueria, A (Vilar De Barrio)|Arnuide|Arruas|Maus (San Pedro)|Porto (Vilar De Barrio)
32706	Castro De Escuadro|Foncuberta|Santiso|Vilar (Maceda)|Vixueses|Xinzo Da Costa
32707	Costa, A (Santiago) (Maceda)|Tioira
32708	Asadur|Ramil (Xunqueira De Espadañedo)
32710	Cachamuiña (Pereiro De Aguiar)|Castadon|Cortiñas (Pereiro De Aguiar)|Lamela, A (Pereiro De Aguiar)|Monterrei (Urbanizacion)|Murteira, A|Pereiro De Aguiar, O|Pereiro De Alen, O|Prexigueiro (Pereiro De Aguiar)|San Salvador (Prexigueiro)|San Salvador (Vilariño)|Tibias|Vilar (Prexigueiro)
32711	Agra (Pereiro De Aguiar)|Bouzas De Fondo|Casdemiro|Cimadevila (Melias-Pereiro De Aguiar)|Condado, O (Pereiro De Aguiar)|Espiñedo (Pereiro De Aguiar)|Frieira (Pereiro De Aguiar)|Lamagrande|Ouriz|Parada (Pereiro De Aguiar)|Sabadelle|San Benito Da Veiga|Ventosela (Pereiro De Aguiar)|Vilariño (Pereiro De Aguiar)|Xubande
32720	Esgos|Folgoso (Esgos)|Gomariz (Esgos)|Lobaces (Esgos)|Loña Do Monte (Esgos)|Pardeconde (Xunqueira De Espadanedo)|Pensos, Os|San Pedro De Rocas|Vilar De Ordelles
32730	Niñodaguia (Santa Maria)|Niñodaguia (Xunqueira De Espadanedo)|Xunqueira De Espada|Xunqueira De Espadanedo (Santa Maria)
32740	Barreiros (Maceda)|Bouzas (Maceda)|Caseta, A (Maceda)|Parada De Sil|Parada De Sil (Santa Mariña)|Rodicio, O (Maceda)
32747	Chandreixa (Parada De Sil)|Sacardebois (San Martiño)
32748	Barxacova|Forcas|Hedrada, A|Paradellas, As|Pradomao|San Lourenzo (Parada De Sil)
32749	Caxide|Coutiño, O
32750	Ferreiria, A (Montederramo)|Fontedoso|Gabin|Laza (Montederramo)|Mazaira (Montederramo)|Mogainza, A|Montederramo|Montederramo (Santa Maria)|Nogueira (Santa Maria)|Paredes (Montederramo)|Pereiras, As (Montederramo)|Sabin|Suspiazo|Teixedo, O|Touzal|Valdarias|Veredo (Montederramo)|Vilanova (Montederramo)
32751	Castiñeiras, As|Lamas, As (Montederramo)|Marrubio (Santo Andre)|Mioteira, A (Montederramo)|Montederramo (San Cosme)|Reguenga, A (Montederramo)|Sas Do Monte|Veiga, A (Montederramo)
32760	Castro Caldelas (San Sebastian)|Castro De Caldelas, O
32764	Abeleda (Teixeira)|Boga, A|Casa Da Dona|Castro, O (Castro Caldelas)|Cerdeiros, Os (Castro Caldelas)|Chaguacedo, O|Nogueira (Abeleda-Teixeira, A)|Pacio, O (Santa Tegra De Abeleda)|Paradela (Castro Caldelas)|Paradella|Pombar, O (Teixeira, A)|Regato, O|Ruxil|Sabugueiro, O|San Paio De Abeleda (San Paio)|Santa Tegra Abeleda (Castro Caldelas)|Santo (Castro Caldelas)|Sequeiros|Soutelo (Castro Caldelas)|Touza, A (Castro Caldelas)|Val, O (Castro Caldelas)
32765	Alende (Teixeira, A)|Barrio, O (Teixeira)|Boazo|Celeiros (Teixeira)|Cristosende|Eirexa, A (Teixeira, A)|Fontao (Teixeira, A)|Lumeares (San Salvador)|Montoedo|Nogueira (Boazo)|Pedra Do Sol|Pedrafita|Quintairos (Teixeira, A)|Quintela De Abaixo|Quintela De Arriba|Sistin|Teixeira, A (Teixeira, A)|Valilongo|Veiga, A (Teixeira, A)|Xiras
32766	Alais (San Pedro)|Alende (Castro Caldelas)|Carballeiras, As (Castro Caldelas)|Eirexa, A (Mazaira)|Espiñeiros, Os (Castro Caldelas)|Folgoso (Castro Caldelas)|Mazaira (Castro Caldelas)|Quintela (Castro Caldelas)|Ruidos|Santa Olaia (Castro Caldelas)|Susaus|Tronceda|Vilarellos (Castro Caldelas)
32767	Chavean|Drados|Fitoiro|Fonteita|Rabal (Santa Maria)|San Cristovo (Chandrexa De Queixa)
32768	Cadeliña|Candedo, O|Casteloais|Queixa
32769	Aguil|Airavedra|Alenza (Montederramo)|Barreiras, As (Castro Caldelas)|Burgo, O (Castro Caldelas)|Bustelos|Camba (Castro Caldelas)|Carabelos|Casguil|Castomas|Cimadevila (Castro Caldelas)|Medorra, A (Montederramo)|Outeiriño, O (Castr Caldelas)|Pedrouzos (Castro Caldelas)|Poboeiros|San Xulian (Castro Caldelas)|Santiago Da Medorra|Vilamaior (Castro Caldelas)|Vimieiro (Castro Caldelas)
32770	Campo, O (Rio)|San Xoan De Rio
32774	Campo, O (Castro Caldelas)
32778	Cabanas, As (San Paio)|San Xurxo (Rio)
32779	Acevido|Arboiro|Argas Vellas|Barreal, O (Rio)|Cambela (Rio)|Carballo, O (Rio)|Casdelope|Castiñeiro|Cortes, As (Rio)|Cruz, A (Rio)|Medos|Outeiro, O (Rio)|Pacios De San Xurxo (Rio)|Ribadas, As|San Silvestre (Rio)|Santa Cruz (Rio)|Senreiro|Seoane (Rio)|Toutelle|Vilarda
32780	Pobra De Trives, A|Trives
32781	Manzaneda|Manzaneda (San Martiño De Abaixo)
32782	Manzaneda (San Martiño De Arriba)|Paradela (Manzaneda)|Sobrado (Pobra De Trives, A)
32784	Requeixo (Manzaneda)|San Miguel De Vidueira
32785	Cernado|Cesuris (Santa Maria)|Placin|Reigada|Soutipedre
32786	Celeiros (Chandrexa De Queixa)|Chandrexa (Chandrexa De Queixa)|Cova (Santa Maria)|Forcadas (Chandrexa De Queixa)|Parada Seca (Chandrexa Dee Queixa)|Parafita (Chandrexa Queixa)|Queixa (Chandrexa De Queixa)|Requeixo De Chandrexa|Vilar (Chandrexa De Queixa)
32787	Casteligo (San Martiño)|Castro, O (Pobra De Trives, A)|Navea (San Miguel)|San Mamede De Trives
32788	Barrio (Pobra De Trives, A)|Pareisas|Pena Folenche|San Lourenzo (Pobra De Trives, A)|Sas De Xunqueira
32789	Cotaros|Encomenda, A (Santo Antonio)|Mendoia|Pena Petada|Piñeiro (Pobra De Trives, A)|Somoza (Pobra De Trives, A)|Vilanova (Pobra De Trives, A)
32790	Abeledos, Os|Alen (Montederramo)|Arnufe|Cacharrequille|Cadaval|Casar Do Mato (Montederrano)|Casardansola|Castiñeira, A (Montederramo)|Chas, As (Montederramo)|Cordelle De Abaixo|Covas (Montederramo)|Curras, Os (Montederramo)|Folgoso (Montederramo)|Gorgullon, O|Graña De Seoane, A|Laxe, A|Leboreiro|Medon, O|Penas, As (Montederramo)|Peredo, O|Praducelos|Ratoeiras, As|Seoane Vello (Montederramo)|Vidalen|Vigueira De Arriba|Vilariño Frio (Montederramo)|Vilariño Pequeno|Villeta, A
32791	Trios (Pereiro De Aguiar)
32792	Calvelle (San Miguel)|Casanova, A (Pereiro De Aguiar)|Derrasa, A|Medorra, A (Pereiro De Aguiar)|Parque Empresarial Pereiro De Aguiar|Penedo, O (Moreiras)|Reboredo (Pereiro De Aguiar)|Ribela (Pereiro De Aguiar)|Roupeiro, O|San Martiño (Pereiro De Aguiar)|San Martiño Moreiras (P.Aguiar)|San Miguel (Pereiro De Aguiar)|San Xoan De Moreiras|Santa Baia (Pereiro De Aguiar)|Santa Marta (Pereiro De Aguiar)|Santa Marta De Moreiras (Santa Marta)|Venda, A (Pereiro De Aguiar)
32793	Cebreiros (Covas-Pereiro De Aguiar)|Chaodarcas (Pereiro De Aguiar)|Covas (Pereiro De Aguiar)|Loñoa (Covas-Pereiro De Aguiar)|Urbanizacion Tapada De Bouzas (Covas-Pereiro De Aguiar)
32794	Castrelo (Rio)|Cerdeira (Rio)|Sas De Penelas
32800	Celanova
32810	Carreiriña, A|Casal De Cima|Costa, A (Ramiras)|Covelas (Ramiras)|Entreviñas|Freas De Eiras (Santa Maria)|Maceira|Margarideiros|Mosteiro (Ramiras)|Outeiro, O (Mosteiro)|Padrenda (Ramiras)|Partida, A|Penavegosa|Picouto, O (Ramiras)|Rozas (Ramiras)|Rubias (Ramiras)|Santa Maria Madre|Santa Marta (Ramiras)|Souto (Rubias-Ramiras)|Terrado, O (Ramiras9|Vilamea De Ramiras|Xocin (Ramiras)
32811	Aldea, A|Almariz|Calvos (Ramiras)|Carraguedo|Casardeita (Ramiras)|Corredoira, A (Ramiras)|Coveliñas (Casardeita)|Escudeiros|Fraguas (Ramiras)|Grixo (Ramiras)|Ludeiros (Ramiras)|Marnotos|Moreira, A|Outeiro, O (Paizas)|Paizas|Pambre|Pazo, O (Celanova)|Pazo, O (Ramiras)|Pazos (Ramiras)|Penosiños|Pereira (Ramiras)|Pereira De San Tome|Pereiras, As (Ramiras)|Proente (Ramiras)|Pumar Vello|Quinta (Ramiras)|Regas, As (Ramiras)|Reguengo, O (Ramiras)|Rial, O (Ramiras)|San Cristovo (Ramiras)|Silva, A (Ramiras)|Silvaescura (Ramiras)|Souto (Penosiños-Ramiras)|Tellado, O (Ramiras)|Turei (Ramiras)|Tuño|Veiga, A (Ramiras)|Ver|Vilaboa (Paizas)|Vilaboa (Rubias)|Vilaflor|Vilanova (Ramiras)|Vilariño (Ramiras)|Vilavidal|Viso, O (Ramiras)
32812	Aldea Ferreiro|Alvarin|Anxa|Barreal (Bola, A)|Barrio (Bola, A)|Berredo (Bola, A)|Bola, A (Capital)|Cabanas (Bola, A)|Cacabelos (Bola, A)|Campo, O (Sorga)|Campo, O (Soutomel)|Capelo, O|Casal De Feas|Casal De Morgade|Casal Do Rio|Casanova (Bola, A)|Castro, O (Bola, A)|Cerdal (Bola, A)|Ciros|Cortiña, A|Covas (Celanova)|Espiñal|Fechas (Bola, A)|Folgoso (Bola, A)|Fondo De Vila (Pardavedra)|Fondo De Vila (Sorga)|Fontes (Bola, A)|Forriolo, O|Froias|Igrexa|Mamoelas, As|Moreiriñas|Morgade (Bola, A)|Murzas|Outeiro, O (Berredo)|Outeiro, O (Sorga)|Outeiro, O (Veiga-Bola, A)|Oxen (Bola, A)|Pardavedra|Pazo, O (Berredo, Santa Baia)|Pazo, O (Pardavedra)|Pazo, O (Sorga)|Pegariña|Podentes|Podentiños|Pousa (Bola, A)|Prado, O (Bola, A)|Quintas, As (Bola, A)|Rairigo|Rañadoiro, O (Bola, A)|Requeixo (Bola, A)|Rozas (Bola, A)|San Fiz (Bola, A)|San Mamede (Bola, A)|San Martiño (Bola, A)|San Martiño De Berredo (San Martiño)|San Pedro (Bola, A)|San Simon|Seara, A (Bola, A)|Seixomil (Bola, A)|Sorga|Soutomel|Tixosa (Bola, A)|Tourille|Val De Boi|Veiga, A (Bola, A)|Vilar (Bola, A)|Vilaverde (Bola, A)
32813	Albos|Auguela, A|Balin|Bangueses|Barreiro (Verea)|Campo Real|Carballo (Verea)|Cardeo|Casal De Abade|Casal De Bispo|Casares, Os (Verea)|Castro, O (Verea)|Cernadela|Cexo|Chedas|Cigarrosa|Cobreiros|Fondodevila (Verea)|Fontechide|Gondesende|Gontan (Verea)|Laceiras, As (Verea)|Laioso (Verea)|Ledime|Mociños|Nigueiroa (Verea)|Nogueira (Verea)|Orille (Verea)|Outeiro (Domez)|Outeiro (Sanguñedo)|Paredes (Verea)|Pia, A|Pitelos|Portela (Verea)|Retortoiro|Sa (Verea)|Sabucedo (Verea)|San Martiño (Verea)|San Vicente (Verea)|Sanguñedo (Verea)|Verea (Celanova)|Vieiro (Verea)|Vilar (Verea)|Xacebas
32814	Agua Levada|Alcouce, O (Quintela De Leirado)|Atainde|Atrio (Quintela De Leirado)|Beade (Quintela De Leirado)|Cabanelas (Quintela De Leirado)|Cima De Vila (Quintela De Leirado)|Corredoira, A (Quintela De Leirado)|Costa (Quintela De Leirado)|Fondons|Forxan (Quintela De Leirado)|Fraguas (Quintela De Leirado)|Lavandeira (Quintela De Leirado)|Leirado (Quintela De Leirado)|Mourisca, A (Quintela De Leirado)|Outeiro (Quintela De Leirado)|Pereiras, As (Quintela De Leirado)|Pousa (Quintela De Leirado)|Quintela (Leirado)|Redemuiños (San Salvador)|Reguengo (Quintela De Leirado)|Rio De Abaixo|Rio De Arriba|Souto (Quintela De Leirado)|Tornadoiro|Val (Quintela De Leirado)
32815	Ademouran|Alcazar De Milmanda (Santa Maria)|Arrotea, A (Celanova)|Barreira, A|Canto|Carballo, O|Carracedo (Milmanda)|Casal, O (Acevedo)|Castromao (Santa Maria)|Cavadoiro|Chousas, As|Eiras (Milmanda)|Ermide|Fontebranca|Lamas, As (Celanova)|Miranzo|Moimenta, A (Celanova)|Orban (Celanova)|Outeiro (Acevedo)|Pazo Das Chousas|Pereiro, O (Celanova)|Prados, Os (Celanova)|San Cibrao (Celanova)|San Martiño De Abaixo|San Martiño De Arriba|Santa Eufemia (Celanova)|Seoane (Celanova)|Tellado, O (Celanova)|Terrado, O (Celanova)|Trasmiras (Celanova)|Vila (Celanova)|Vilaverde (Celanova)|Xamiras
32816	Abelleira, A (Celanova)|Amedo (Celanova)|Armada, A (Celanova)|Barrio (Bobadela)|Barxa (Santo Tome)|Bobadela (Celanova)|Campo (Bobadela)|Carfaxiño|Cristal, O|Fechas (Celanova)|Fechiñas|Orga (San Miguel)|Pereiras, As (Celanova)|Ponte Fechas|Pousa, A (Celanova)|Quintairos (Bobadela)|Rabal (Celanova)|Rabal Da Eirexa|Rabal De Arriba|Ramallosa, A|Roda De Abaixo, A|San Paio|Souto, O (Celanova)|Vilanova Dos Infantes
32817	Amoroce|Ansemil|Baraca, A (Celanova)|Barreiros, Os|Barrio (Ansemil)|Campo (Mourillos)|Campo De Veiga|Carballeira (Celanova)|Casal (Amoroce)|Casasoa (Celanova)|Caseta (Ansemil)|Cañon|Celanova (San Rosendo)|Einibo|Feal De Ansemil|Figueiredo (Celanova)|Goterre|Granxa, A (Celanova)|Mandras (Celanova)|Mato, O (Celanova)|Mourillos|Outeiro (Amoroce)|Outeiro, O (Cañon)|Outeiro, O (Veiga-Celanova)|Pazos (Celanova)|Penalta|Quintairos (Amoroce)|Regada, A (Celanova)|Rial (Celanova)|Sambades (Celanova)|Sampil|Sandin (Celanova)|Val, O (Celanova)|Veiga, A (S. Munio)
32820	Cartelle (Santa Maria)|Mato, O (Cartelle)|Peto, O|Peto, O (Cartelle)|Sanguñedo (Cartelle)|Vilar De Vacas
32821	Bagullo, O|Lamas De Outeiro|Sabucedo De Montes|San Tome (Cartelle)|Seara, A (Cartelle)|Seixadas, As|Seixadelas|Terzas|Xinzo Das Teixugueiras
32823	Bidueiro, O|Oleiros (Cartelle)|Prado, O (Cartelle)|Sande (Cartelle)
32824	Couxil|Couxiliño|Mundil (Santa Maria)|Nogueiro (Mundil)|Outomuro
32825	Anfeoz|Santa Baia De Anfeoz
32826	Espiñoso|Freixoso De Penela|Marabillas, As|Pazo, O (Cartelle)|Penela (Cartelle)
32828	Buzacos (Celanova)|Casanova (Celanova)|Correxas (Celanova)|Fontelo (Celanova)|Freixo (Celanova)|Gueral (Celanova)|Vilares, Os (Celanova)|Viveiro (Celanova)
32830	Manchica, A (Nosa Señora De Lourdes)|Matusiños|Merca, A|Nigueiroa (Merca, A)|Parderrubias|Pereira De Montes|Solbeira|Vilaboa (Merca, A)|Vilacha (Merca, A)|Vilar De Paio Muñiz
32838	Arcas|Campo, O (Merca, A)|Celeiros (Merca, A)|Compostela (Merca, A)|Fontefria (Merca, A)|Froxas Das Viñas|Mezquita, A (Merca, A)|Outeiro (Mezquita, A-Merca, A)|Proente (Merca, A)|Rubillos|Val, O (Merca, A)
32839	Cabanas De Abaixo|Cabanas De Ferro|Cabanas De Loureiro|Campelo (Merca, A)|Casal (Merca, A)|Corvillon|Covas Do Rio|Entrambosrios (Merca, A)|Faramontaos (Merca, A)|Fontao (Merca, A)|Forxas De Montes|Lameiro Quente|Medorra, A (Merca, A)|Olas|Pazos De Olas|Rebola|Salpurido|Vilariño (Merca, A)|Xen|Zarracos
32840	Bande|Bande (San Pedro)
32846	Carpazas|Chaos (Lobeira)|Fradalvite|Nigueiroa (Bande)|Outeiro, O (Bande)|Quinta (Bande)|Quintela (Santa Comba)|Santa Comba (Bande)|Santa Comba (San Trocado)|Trarigo|Viñal, O (Bande)
32847	Barrio (Bande)|Campinas, As (Bande)|Fervenza (Bande)|Garabelos (Bande)|Guin|Ponte Liñares, A (Feira Nova, A)|Quintela (Ribeiro)|Ribeiro, O (Bande)|San Fiz (Bande)
32848	Baños, Os|Maus, As (Bande)|Vilar (Bande)|Vilela (Bande)
32849	Aldea De Arriba (Bande)|Cados (Bande)|Cima De Vila (Bande)|Corvelle (Bande)|Igrexa, A (Bande)|Pazos (Bande)|Pereira (Bande)|Ponte Cados|Pumares (Bande)|Ribas (Bande)|Rubias (Bande)|Souto, O (Bande)|Vilamea (Calvos-Bande)
32850	Baldemir|Canle, A|Lobeira (San Vicente)|Quintas, As (Lobeira)|Sabariz (Lobeira)|Senderiz (Lobeira)|Torneiros (Lobeira)|Vilariño (San Xes)(Lobeira)
32858	Fraga, A (Lobeira)|Parada Do Monte|Taboazas (Lobeira)
32859	Monte Longo (Lobeira)|Nogueira (Lobeira)|Souto (Lobeira)|Vilariño (Montelongo)(Lobeira)
32860	Asperelo Y Olin|Entrimo (Santa Maria A Real)|Feira Vella, A|Galez|Terracha, A (Entrimo)
32868	Bouzadragro|Guxinde (Entrimo)|Pereira (Entrimo)|Queguas|Venceans|Vilar (Entrimo)
32869	Illa, A|Lantemil|Olelas|Quintela (Lobios)
32870	Aceredo|Compostela (Lobios)|Lobios (Lobios)|Lobios (San Miguel)|Ludeiros (Lobios)|Manin
32879	Arauxo (Lobios)|Bouzas (Lobios)|Briñidelo|Cela, A|Delas|Esperanzo|Guende|Gustomeao|Portaxe, A|Prancibe|Puxedo, O|Regada, A (Lobios)|Reguengo, O (Lobios)|Requeixo (Arauxo)|Sa (Lobios)|San Paio (Lobios)|Vila, A (Lobios)
32880	Agrelo, O|Couso De Salas (Santiago)|Guimil|Guntumil (Muiños)|Maus De Salas, As (Santa Baia)|Mugueimes|Muiños (Muiños)|Picos|Porqueiros|Rañadoiro, O|Requias|Souto De Limia (Muiños)|Vilar De Cas (Muiños)
32890	Alto Do Ponton, O|Barbadas|Bentraces|Cimadevila (Barbadas)|Fornos, Os|Lamas, As|Loiro|Muiños, Os (Barbadas)|Ponton, O (Barbadas)|Sobrado Do Bispo
32892	Carreira, A (Lobios)|Ganceiros|Grou (Lobios)|Grou, San Mamede (Lobios)|Herdadiña, A|Lama, A (Lobios)|Maras|Rasela, A (Grou)|Requeixo (Grou)|Torno|Valoiro, O|Xeas|Xendive (Lobios)
32895	Rio Caldo (Santa Maria)|Torneiros (Lobios)|Vilamea (Lobios)
32896	Parada De Ventosa|Pazo (Muiños)
32897	Barxes (Muiños)|Barxes (Santa Maria)|San Martiño De Grou (Lobeira)|Santa Cruz De Grou (Lobeira)|Santa Cruz De Grou (Lobios)
32898	Barrio (Cados)|Cados (Muiños)|Piñoi|Prado De Limia (San Salvador)|Reparada|San Miguel (Muiños)|Xermeade
32899	Barrio, O (Barxes)|Farnadeiros (San Pedro)
32900	Belmonte|Parque Tecnologico Poligono San Cibrao Das Viñas|Pazos De San Clodio|Picouto, O (San Cibrao Das Viñas)|Valiñas (San Cibrao Das Viñas)|Zamorana, A
32901	Calvos (San Cibrao Das Viñas)|Carballeira, A (San Cibrao Das Viñas)|Castellana, A|Castroverde|Eirexa, A (Rabeda)|Mioteira, A (San Cibrao Das Viñas)|Poligono Industrial (San Cibrao Das Viñas)|Reboredo (San Cibrao Das Viñas)|Santa Cruz Da Rabeda
32910	Condado (San Cibrao Das Viñas)|Cruz De Rante, A|Gargantos|Montelongo De Abaixo|Montelongo De Arriba|Outeiro Calvo|Outeiro, O (San Cibrao Das Viñas)|Pazos (San Cibrao Das Viñas)|Penedo (San Cibrao Das Viñas)|Prado, O (San Cibrao Das Viñas)|Rante|Souto Bravo|Soutopenedo|Torre, A (San Cibrao Das Viñas)|Vilanova (San Cibrao Das Viñas)
32911	Farixa (A)|Lagoa, A (San Cibrao Das Viñas)|Piñeiral (O)|San Cibrao Das Viñas (Capital)|San Cibrao Das Viñas (Santo Ildefonso)
32915	Aspera (San Cibrao Das Viñas)|Barreiros Zona Comercial|Cumial, O (Ourense)|Cumial, O (San Cibrao Das Viñas)|Noalla (San Cibrao Das Viñas)|Ponte Noalla, A|Santa Marta (San Cibrao Das Viñas)|Veiga (San Cibrao Das Viñas)
32920	Airas, As|Moreiras (Toen)|Trelle|Trellerma
32930	Fondon, O|Fonte Larelle|Gradeira, A|Larelle|Meaba|Moreiro, O|Mugares|Parada De Piñor|Piñeiro, O (Barbadas)|Piñor (San Lourenzo)|Requeixo (Barbadas)|Roma (Barbadas)|Toen|Xestosa
32940	Alongos|Castiñeiras (Toen)|Celeiron (Toen)|Fea|Freixendo|Paredes (Toen)|Puga|Quenlle|San Fiz (Puga)
32950	Barxelas (Ourense)|Belesar|Carballeda (Coles)|Carballeda (Rivela)|Casanova (Barra Miño)|Cerdedo (Coles)|Covas (Coles)|Figueiredo (Coles)|Fontao (Coles)|Levices|Malvedo, O|Outeiriños, Os (Coles)|Outeiro (Melias)(Coles)|Pacios (Coles)|Peroxa, A (San Eusebio)|Prados (Coles)|Reguenga, A|Ribela (Coles)|San Lourenzo (Coles)|Se, A|Sobrado (Coles)|Souto, O (Coles)|Vilanova De Rivela
32960	Cangos|Canivelos, Os (Mende)|Casixova|Cazaligo|Lagar, O (Velle)|Lonia De Arriba (Lugar)|Outeiro, O (Velle)|Pedra, A|Pousa, A (Ourense)|Quintela De Velle|Regoufe|Roxomilo|San Mamede (Velle)|Senra, A (Velle)|Velle
32970	Bemposta (Ourense)|Curuxeiras, As|Peneireira, A (As Curuxeiras-Seixalvo)|Seixalbo (Industrial)|Seixalbo (San Breixo)|Tenencia De Zain|Zain
32971	Granxa, A (Montealegre)|Monte (Ourense)|Rairo (Ourense)|Santa Mariña Do Monte (Monte-Ourense)
32980	Abeleda, A (Ourense)|Boveda (Amoeiro)|Castro De Beiro, O|Nogueira (Ourense)|Pazos (Ourense)|Vilariño (Ourense)
32981	Astres|Beiro (Ourense)|Bouza, A (Ourense)|Burata, A|Burgo, O (Ourense)|Caveanca, A|Conchada, A|Lagar, O (Vilar De Astres)|Ludeiros (Ourense)|Madrosende|Naves|Palmes (San Mamede)|Paradela (Ourense)|Pereiro, O (Ourense)|Pradobo|Regoalde|Saceda (Ourense)|Sartedigos|Valdolide|Vilar De Astres
32990	Arrabaldo (Santa Cruz)|Barrio (Untes)|Granxa, A (Arrabaldo)|Untes (Santo Estevo)
33001	Oviedo
33002	Oviedo
33003	Oviedo
33004	Oviedo
33005	Oviedo
33006	Campiello (La Manjoya)|Oviedo
33007	Oviedo
33008	Oviedo
33009	Oviedo
33010	Abuli|Colloto (Oviedo)|Colloto (Siero)|Nonin|Oviedo
33011	Corredoria (Oviedo)|Oviedo
33012	Oviedo
33013	Oviedo
33070	Oviedo
33071	Oviedo
33080	Oviedo
33100	Trubia
33111	Alesga|Barzana (Teverga)|Berrueño|Campiello (Teverga)|Campos (Teverga)|Cansinos|Carrea|Castro (Teverga)|Coañana (Teverga)|Cuarteles, Los (Teverga)|Cuña|Entrago (Teverga)|Focella|Fresnedo (Teverga)|Gradura|Hedrada|Infiesta (Teverga)|La Favorita|Las Garbas|Llamas (Teverga)|Medion|Monteciello|Murias (Teverga)|Obra, La (Teverga)|Paramo|Plaza, La (Teverga)|Prado (Teverga)|Quintanal (Teverga)|Redral|Riello|Riomayor (Teverga)|San Martin De Teverga|San Salvador (Teverga)|Santianes (Teverga)|Sobrevilla|Taja|Torce (Teverga)|Torre, La (Teverga)|Urria (Teverga)|Vegas, Las (Teverga)|Vigidel|Villa De Sub|Villabonel|Villamayor|Villanueva (Teverga)|Villar (Teverga)
33112	Bustiello (Proaza)|Fabar (Proaza)|Santa Maria De Traspeña|Toral, El (Proaza)|Ventas, Las (Proaza)
33114	Bandujo|Caranga|Folgueras (Proaza)|Linares (Proaza)|Proacina|Proaza|San Martin (Proaza)|Serandi|Sograndio (Proaza)|Vegas, Las (Proaza)|Villamejin
33115	Castañedo Del Monte|Cotomonteros|Dosango|La Casina|Lavares (Santo Adriano)|Pedroveya|Rebollada, La (Quiros)|Sabadille|Tenebredo|Tuñon|Villanueva De Santo Adriano
33116	Aguadina|Bueira|Cabaniellas|Cerezal (Quiros)|Cienfuegos|Corral|Cortes (Quiros)|Cuevas (Quiros)|Fresnedo (Lindes-Quiros)|Lindes|Llanas, Las (Quiros)|Nimbra|Ricabo (Quiros)|Rodiles (Quiros)|Ronderos|San Vicente (Quiros)|Santa Marina De Quiros|Villagime|Villamarcel|Villar De Cienfuegos|Villasante
33117	Arrojo (Quiros)|Barzana De Quiros|Casares (Quiros)|Castañero, El (Quiros)|Coañana (Quiros)|Fabrica, La (Quiros)|Faedo (Quiros)|Fresnedo (Casares-Quiros)|La Casa Vide|Llanuces|Murias (Quiros)|Muriellos (Quiros)|Pando (Quiros)|Rano|Salcedo (Quiros)|San Pedro (Quiros)|San Salvador (Quiros)|Toriezo|Vallin (Quiros)|Vega (Quiros)|Villagondu|Villar De Salcedo|Villarejo (Quiros)
33118	Aciera|Agueras De Quiros|Bermiego|Carrexa|Cortina (Quiros)|Llano, El (Quiros)|Perueño|Tene|Villaorille
33119	Barquera, La (Las Segadas)|Bercio|Buseco (Santo Adriano)|Camales|Carangas, Las (Santo Adriano)|Cuestas, Las (Trubia)|Feleches (Trubia)|Godos|Molina (Trubia)|Nora (Trubia)|Pando (Caces)|Pando, El (Trubia)|Perlavia|Perlin|Pintoria|Priañes|Quintana (Trubia)|San Andres De Trubia|San Pedro De Nora|Soto De Arriba|Udrion|Vallina, La (Caces - Oviedo)|Vega De Trubia
33120	Pravia
33125	San Juan De La Arena
33126	Cotollano|Foncubierta|Llago|Magadalena, La (Soto Del Barco)|Rubines|Soto Del Barco|Truebano (Soto Barco)|Ucedo
33127	Barrera, La (Soto Del Barco)|Bernadal|Carrocero|Castillo (Soto Del Barco)|Florida, La (Soto Del Barco)|La Bimera|La Marrona|Las Rabias|Llamera, La (Soto Del Barco)|Llana, La (Pravia)|Monterrey|Peñaullan|Riberas (Soto Del Barco)|Santa Eulalia (Soto Del Barco)|Uz, La (Soto Del Barco)|Veneros (Soto Del Barco)
33128	Ablanedo (Pravia)|Allence (Pravia)|Arango|Arborio|Caliero, El (Pravia)|Carceda (Pravia)|Castañal, La (Pravia)|Caunedo (Pravia)|Cordovero|Folgueras (Pravia)|Fondos De Villa (Pravia)|Inclan|La Fungal|Las Piñeras|Lomparte|Loro|Omedas|Palacion|Prada (Pravia)|Puentevega|Quintana (Pravia)|Rivero (Pravia)|San Bartolome|San Esteban (Villavaler)|San Pelayo (Pravia)|Sangreña|Selgas|Tablas, Las (Pravia)|Travesedo (Pravia)|Valdediello|Vegafriosa|Villamondriz|Villavaler
33129	Agones|Bances|Beifar|Cadarienzo|Campas, Las (Pravia)|Cañedo (Pravia)|Corias (Pravia)|Corralinos|Escoredo|Forcinas|Godina|Los Cabos|Luerces|Masfera|Ocea|Pandiella, La (Pravia)|Perzanas|Prahua (Pravia)|Pronga|Quinzanas|Recuevo|Repolles|Sandamias|Santianes (Pravia)|Vegañan|Villafria (Pravia)|Villagonzay|Villamejan|Villamuñin|Villanueva (Pravia)|Villarigan
33130	San Esteban De Pravia
33138	Era|Muros|Pumariega, La (Muros)|Reborio (Muros De Nalon)|Villar (Muros Nalon)
33139	Somado
33140	Arquera, La (Oviedo)|Caces|Cantayu|Pozoval|Puerto (Fuso)|Siones|Villar (Fuso-Puerto)
33150	Cudillero
33154	Aronces|Cuesta La Bana|El Pito|La Atalaya|La Paca
33155	Argaton|Artedo|Baos|Beiciella|Brañaseca|Busfrio|Castañedo (Cudillero)|Cipiello|Escalada, La (Cudillero)|Folguerua (Cudillero)|Gallinero (Cudillero)|Gayuelos|La Bordinga|La Puerca|La Sinjania|Lamuño (Cudillero)|Llendepin|Magdalena, La (Cudillero)|Mumayor|Rellayo|Ribao|Rondiella (Cudillero)|Salamir|San Cosme (Cudillero)|San Martin De Luiña|Teixidiello
33156	El Cepedo|Llanorrozo|Oviñana (Cudillero)|Pandiello (Cudillero)|Pramaro|Riego De Abajo|Riego De Arriba|San Pedro De La Ribera|Soto De Luiña|Troncedo (Cudillero)|Vivigo
33157	Albuerne|Castañeras|Novellana|Resiellas|Valdredo
33158	Ballota (Cudillero)|Cuesta Del Cesto|Resillinas|Santa Marina (Cudillero)
33159	Armayor|Arrojas|Belandres (Cudillero)|Bustiello (Cudillero)|Cerecedo (Cudillero)|Corollos|El Manto|El Peñedo|Faedo (Cudillero)|Fenosa, La (Cudillero)|Orderias (Cudillero)|Otero (Cudillero)|Pepin|Piñera (Cudillero)|San Cristobal (Cudillero)|San Juan De Piñera|Tabla, La (Cudillero)|Veiga|Villademar|Villazain|Villazones|Villeirin
33160	Ablanedo (Riosa)|Ablanosa|Aguera, Las (Riosa)|Cabornin|Cadabal (Riosa)|Caleyos, Los (Riosa)|Cantera, La (Riosa)|Canto De La Vara|Canto, El (Riosa)|Casillina, La (Riosa)|Cerecedo (Riosa)|Collado, El (Riosa)|Corujedo (Riosa)|Cuadros, Los (Riosa)|Doñajuandi|El Huesped|Envernaes|Felguera (Riosa)|Fresnedo (Riosa)|Grandiella (Riosa)|Granja, La (Riosa)|La Ara|La Castañar|La Cuba|La Juncar|La Rebolla|Las Gateras|Llamo|Llanas, Las (Riosa)|Llaneza, La (Riosa)|Marina, La (Riosa)|Muriellos (Riosa)|Nijeres|Panderraices|Piedrafita (Riosa)|Porcio|Prado Velorto|Prunadiella|Puente Alta|Rotellin (Riosa)|Rozacagil (Riosa)|San Adriano (Riosa)|Tejeras, Las (Riosa)|Teleno|Vara, La (Riosa)|Vega De Riosa|Villameri|Zorera De Las Llamas|Zorera De Porcio
33161	Busloñe|Calella, La (Morcin)|Calvin (Morcin)|Cardeo (Morcin)|Collada, La (Morcin)|Cuesta, La (Morcin)|El Pereo|Enseca De Arriba Y Abajo|Figar, La (Morcin)|Figares (Morcin)|Foz De Morcin|La Carbayosa|La Melandrera|Las Vegas De Cardeo|Lugar De Abajo (Morcin)|Lugar De Arriba (Morcin)|Mazas, Las (Morcin)|Mellampo|Molin De La Fuente|Molino De Figares (Caserio)|Otura (Morcin)|Panizales (Morcin)|Porriman|Pradiquin|Puente, La (Morcin)|Pumar, El (Morcin)|Roza, La (Morcin)|Vallin, El (Morcin)|Vara, La (Morcin)
33162	Ablanedo (Morcin)|Alfilorio De Abajo|Alfilorio De Arriba|Alfilorio Del Medio|Barrea|Bolias|Boza, La (Morcin)|Campo, El (Morcin)|Castandiello (Morcin)|Cogollo, El (Morcin)|Cortes (Morcin)|El Artoxu|El Brañueto|La Cotina|La Gantal|La Llorera|Lavandera (Morcin)|Los Duernos|Los Gonzalez|Malpica (Morcin)|Palacio, El (Morcin)|Parteayer|Peñanes|Peñerudes|Piñera De Morcin|Requejo (Morcin)|Rio, El (Morcin)|San Esteban (Morcin)|San Sebastian De Morcin|Santa Eulalia De Morcin|Vallinas, Las (Morcin)|Vegas De San Esteban|Villar (Morcin)
33163	Argame|Rectoria, La (Morcin)
33170	Caleyo, El (Oviedo)|El Llagu|Llamaoscura|Medio, El (Manjoya-Oviedo)
33171	Bueño (Ribera De Arriba)|Caleyo, El (Ribera De Arriba)|Casielles (Pereda-Oviedo)|Condado, El (Oviedo)|El Atrollo|Ferreros (Ribera De Arriba)|Pereda (Las Segadas)|Quintaniellas (Ribera De Arriba)|San Miguel De La Pereda|Santa Agueda|Segadas, Las (Oviedo)|Venta Del Aire (Oviedo)|Villar De Pereda
33172	Fuejos|La Carrera|Labarejos|Mortera De Palomar|Palomar (Ribera De Arriba)|Rebollar (Ribera De Arriba)|Soto De Ribera|Vixiel
33173	Entrepuentes|Mortera De Tellego|Sardin|Tellego|Vegalencia
33174	Casielles (Prioro-Oviedo)|Cuestayones|Las Caldas|Piñera (Oviedo)|Premaña|Priorio (San Juan De)
33180	Noreña
33186	Buenavista (Hevia-Siero)|Campones, Los (Hevia-Siero)|El Berron|Orial (Hevia-Siero)|San Pelayo (El Berron - Siero)|Vallina, La (Hevia-Siero)
33187	Campo, El (Berron-Siero)|Cuclillos (Santa Marina)|Cuesta, La (El Berron - Siero)|Fuentemelga|Gijun (Berron, El-Siero)|Pumarin, El (Hevia-Siero)|Ricabada|Solad
33188	Arguelles|Cabornia, La (Siero)|Cuesta, La (Arguelles-Siero)|El Cristo|Fuentespino|La Belga Baja|Pumares (Siero)|Revuelta Del Coche|San Miguel De La Barreda
33189	Anes (San Martin)|Arniella|Calabaza (Siero)|Carrizal, La (Noreña)|Casa De Anes|Coto, El (Anes-Siero)|El Meson De La Tabla|Espiniella (Siero)|Faedo (Siero)|Fombona|Grandarrasa|Huergo|La Carizal|La Figarona|La Madera|Llaneces (Siero)|Llantero (Siero)|Madera, La (Siero)|Orviz|Palmiano|Pañeda Nueva|Pañeda Vieja|Peral, La (Noreña)|Picaloredo|Poladura (Siero)|San Pedro (Anes - Siero)|San Tirso (Siero)|Vare|Vio|Yerbano
33190	Aguera (Las Regueras)|Alcedo (Las Regueras)|Andallon|Ania|Areces|Biedes (Las Regueras)|Bolgues|Braña (Las Regueras)|Cruces, Las (Regueras)|Cueto (Las Regueras)|Estaca, La (Las Regueras)|Fuente, La (Las Regueras)|Granda (Las Regueras)|Landrio|Las Marinas|Lazana|Meobra|Otero (Las Regueras)|Paladin|Parades|Pereda, Las (Regueras)|Pravia (Las Regueras)|Premio|Premoño|Puerma|Santullano De Las Regueras|Soto De Las Regueras|Trascañedo|Trasmonte (Las Reguera)|Valduno|Viado
33191	Areñes (Oviedo)|Barrosa, La (Oviedo)|Belovio|Cabaña, La (Oviedo)|Cabaña, La (Zona)|Cida|Cimadevilla (Oviedo)|Cruz, La (Oviedo)|Escamplero (Las Regueras)|Fabarin|Gallegos (Las Regueras)|Granja, La (San Claudio)|La Maja|Lampajua|Las Heras|Llama, La (San Claudio)|Llana, La (San Claudio)|Loriana|Lubrio|Malpica (San Claudio)|Navaliega (San Claudio)|Nievares (Oviedo)|Omedo (Oviedo)|Oteruelo|Peñanora|Ponteo (San Claudio)|Pumeda (Las Regueras)|Quejo|Rañeces (Las Regueras)|Rebollar (Loriana-Oviedo)|Requejo (San Claudio)|Rivero (San Claudio)|Rodiella|San Claudio|San Roque (San Claudio)|Tahoces|Tamargo|Torre, La (San Claudio)|Valle, El (San Claudio)|Valsera|Villamar|Villaverde (San Claudio)
33192	Barganiza|Espinera (Pruvia-Siero)|Llamedo (Siero)|Llomba (Llanera)|Lotero|Ordoño|Pruvia (Llanera)|Remoria|Santa Eulalia (Llanera)|Silvota (Llanera-Pol. Industrial)|Venta De La Puga
33193	Ayones (Oviedo)|Belonga|Carballinos|Escalones|Faedo (Latores)|La Carbayeda|La Martinez|Latores|Pedruño|Rotella, La (Latores)|Santa Marina Piedramuelle|Santo Medero|Sograndio (Oviedo)|Toriello (Oviedo)|Vega (Oviedo)|Venta, La (Oviedo)|Villarmil
33194	Ajuyan|Brañes (Oviedo)|Cabañas (Oviedo)|Campas, Las (Oviedo)|Carbayon|Carriles, Los (Oviedo)|Castiello (Oviedo)|Constante (Oviedo)|Cuyences|Escontiella|Fitoria|Folgueras (Oviedo)|Granja, La (Oviedo)|La Contriz|Ladines (Oviedo)|Lampaya|Laviada|Llano, El (Oviedo)|Lloral, La (San Claudio)|Lugarin (Oviedo)|Mazas, Las (Lugar)|Nora (Villaperez)|Oviedo|Pedrera, La (Oviedo)|Pevidal (Oviedo)|Quintana (Oviedo)|San Lazaro De Paniceres|Tresllamas (Lugar)|Ules|Venta, La (Brañes)|Villamorsen|Villanueva (Oviedo)|Villaperez|Violeo
33195	Arenales|Barraca, La (Oviedo)|Bendones|Carbajal (Oviedo)|Casas De La Carretera|Covadonga (Oviedo)|El Bosque|El Caldero|El Codejal|El Cruce|Faro De Abajo|Faro De Arriba|Fozalguera (Oviedo)|Friera (Oviedo)|Granda, La (La Manjoya-Oviedo)|Llovera (Oviedo)|Los Pintos|Lugido|Molinos, Los (Oviedo)|Morente|Novales (Oviedo)|Paderne (Oviedo)|Pando, El (Oviedo)|Polledo (Oviedo)|Rozavillar|San Cipriano De Pando|San Cristobal (Oviedo)|San Esteban De Las Cruces|San Rafael|Valdemora (Oviedo)|Vidayan
33196	Barredos, Los (Manjoya-Oviedo)|Cabornio (Oviedo)|Cagigal|Caseron|Fuente Del Forno|Los Corzos|Los Prietos|Rodada, La (Oviedo)|San Torcuato
33199	Barreros (Limanes)|Caravia (Oviedo)|Castañera (Siero)|Folgueras, Las (Colloto-Siero)|Fonciello (Meres-Siero)|Fozana|Fueyo (Meres - Siero)|Granda (Siero)|Granda- Siero (Poligono Industrial)|La Sierra|Limanes|Meres (Siero)|Mieres (Limanes-Siero)|Moreo|Peñas (Siero)|Rebollada (Limanes)|Roces (Oviedo)|San Juan Del Obispo|Tiñana|Vallin (Limanes-Siero)|Villamiana
33200	Gijon
33201	Gijon
33202	Gijon
33203	Gijon
33204	Gijon
33205	Gijon
33206	Gijon
33207	Gijon
33208	Gijon
33209	Gijon
33210	Gijon
33211	Gijon
33212	Gijon
33213	Gijon
33290	Gijon
33299	Gijon|Jove
33300	Arcenoyo|Casona, La (Villaviciosa)|Cobertoria, La (Villav)|Condarco|Villaviciosa
33310	Abeu (Fuentes-Villaviciosa)|Arboleya|Arriondo|Bospolin|Breceña|Buslad|Candones|Carabaño|Castiello (Cabranes)|Cayado|Cermuño|Cervera|Ceyanes|Coro|Cotariella (Cabranes)|El Coche|Encrucijada, La (Cabranes)|Fresnedo (Cabranes)|Fresno (Cabranes)|Fuentes (Villaviciosa)|Giranes|Gramedo (Cabranes)|Granda, La (Coro-Villaviciosa)|Güerdies|Heria|Infiesta (Villaviciosa)|La Madrera|Lavandero|Liñana|Los Caminos|Madiedo|Mases|Migoya|Miyangües (Cabranes)|Moratin (Villaviciosa)|Naveda|Niao|Novales (Breceña-Villaviciosa)|Pando (Breceña-Villaviciosa)|Parte, La (Cabranes)|Pentanes|Peral, El (Villaviciosa)|Peñella|Piedrafita (Villaviciosa)|Pino, El (Coro-Villaviciosa)|Piñera, La (Villaviciosa)|Puerta|Rebollada, La (Cabranes)|San Martin De Valles|San Vicente (Villaviciosa)|Santa Eulalia De Cabranes|Solares (Villaviciosa)|Ternin|Tisorio|Torazo|Tresvilla|Trias|Valbunena|Vallina (Breceña)|Venta, La (Pando-Villaviciosa)|Viñon|Viñones
33311	Algara|Amandi|Arpandi|Arrabal|Baragañas|Bozanes|Cajide|Campos, Los (Amandi-Villaviciosa)|Carcabada (Cazanes-Villaviciosa)|Casquita (Amandi-Villaviciosa)|Cazanes|Coruxeu|Felgueres (Villaviciosa)|Fontines|Gordinallo|Gotera|La Mesada|Lavares|Lavares (Villaviciosa)|Llera, La (Amandi)|Lugarin (Villaviciosa)|Lugas|Mieres (Villaviciosa)|Obaya|Palacio, El (Amandi - Villaviciosa)|Parra, La (Villaviciosa)|Pedrera (Villaviciosa)|Pelamantas|Poladura (Villaviciosa)|Pumarin (Villaviciosa)|Quinta, La (Villaviciosa)|Roza, La (Villaviciosa)|San Juan (Villaviciosa)|Sebrayo|Sietes|Sorribas (Villaviciosa)|Valbucar|Valle, El (Cazanes - Villaviciosa)|Vega, La (Cazanes-Villaviciosa)|Ximangues
33312	Ambas (Villaviciosa)|Arbazal|Camoca De Abajo|Camoca De Arriba|Campo, El (Villaviciosa)|Castañeu|Castiello (Villaviciosa)|Congares|Daja|Granda, La (Puebles-Villaviciosa)|Llaneces|Llano, El (Villaviciosa)|Lloses|Luaria|Piqera, La (Camoca-Villaviciosa)|Puelles|Riega, La (Camoca - Villaviciosa)|Ronzon (Villaviciosa)|San Saturnino|Santi|Torretejera|Toya|Travieso|Valdedios (Villaviciosa)|Valeri|Valle, El (Camoca - Villaviciosa)|Villabona (Villaviciosa)|Villarrica|Viña, La (Villaviciosa)|Xiana
33313	Arbellia|Argallada|Barraca (Villaviciosa)|Cabrafrio|Casares (Nievares-Villaviciosa)|Casquita (Grases-Villaviciosa)|Conceyero|Cortina, La (Villaviciosa)|Cuadros, Los (Villaviciosa)|Cueva, La (Villaviciosa)|El Respigo|El Sur|Fabares|Grases|Heros, Los (Villaviciosa)|Huelga, La (Villaviciosa)|La Pendiz|Las Cuartas|Llanas, Las (Villaviciosa)|Llosa, La (Villaviciosa)|Mayorazo|Molinos (Villaviciosa)|Nievares (Villaviciosa)|Piqera (Nievares-Villaviciosa)|Piqera, La (Rozadas-Villaviciosa)|Pueblo (Nievares-Villaviciosa)|Reboria, La (Villaviciosa)|Rozadas (Villaviciosa)|San Pedrin|Singla|Sopeñas|Terrero|Torre, La (Nievares-Villaviciosa)|Turbeño|Vallinas, Las (Villaviciosa)|Venta, La (Grases - Villaviciosa)|Villanueva (Rozadas-Villaviciosa)
33314	Argañoso|Arguero|Arriba|Arroes (Sta Marina)|Atilan|Barcena (Villaviciosa)|Bustiello (Villaviciosa)|Cadamancio|Caes|Camino Real|Candanal (Villaviciosa)|Carbayera (Castiello-Villaviciosa)|Careñes|Castiello De La Marina|Cerra (Villaviciosa)|Cimadevilla (Villaviciosa)|Collado (Villaviciosa)|Contriz (Villaviciosa)|Corolla (Villaviciosa)|Cruz, La (Villaviciosa)|Cuatro Caminos|Curbiello|El Calderon|Florida, La (Villaviciosa)|Fondujo|Fresno, El (Careñes - Villaviciosa)|Manzanedo|Marina, La (Villaviciosa)|Melendreras (Villaviciosa)|Monasterio|Nava, La (Villaviciosa)|Obra, La (Villaviciosa)|Pedroso, El (Villavicios)|Peon|Piñares|Piñole|Puente Arroes|Pumar De Abad|Quintana, La (Arguero - Villaviciosa)|Quintes|Quintueles|Roces (Villaviciosa)|Rodavigo|San Justo (Villaviciosa)|San Miguel (Arroes-Villaviciosa)|Santa Cecilia (Villaviciosa)|Sariego (Villaviciosa)|Silva (Careñes-Villaviciosa)|Valle, El (Peon-Villaviciosa)|Vallina, La (Villavic.)|Vega, La (Castiello-Villaviciosa)|Venta De La Esperanza|Venta De Las Ranas|Villanueva (Sariego-Villaviciosa)|Villaverde (Villavicio)
33315	Abayu|Arenas (Villaviciosa)|Atalaya, La (Villaviciosa)|Bedriñana|Cabañas (Villaviciosa)|Gobernador|La Ermita|Liñero|Llames (Villaviciosa)|Lloraza|Maseras|Mestas, Las (Villaviciosa)|Mienagos|Oles|Oriyes|Pola, La (Villaviciosa)|Requejo (Villaviciosa)|Retiro (Villaviciosa)|Riega, La (Bedriñana - Villaviciosa)|San Martin Del Mar|San Miguel (Tazones - Villaviciosa)|Santa Marina (Villaviciosa)|Seli|Tarandiellos|Tazones|Tuero|Villar (Tazones)
33316	Abeu De Arriba (Carda-Villaviciosa)|Ayones (Villaviciosa)|Cabañona, La (Villaviciosa)|Carda|Carda De Arriba|Casares, Los (Priesca-Villaviciosa)|Espina, La (Quintana)|Fresno, El (Tornon-Villaviciosa)|La Alegria|La Busta|Las Callejas|Llera, La (Quintana)|Los Faroles|Maniel|Montoto|Moreda (Villaviciosa)|Muslera|Muñones|Onon (Villaviciosa)|Otero, El (Villaviciosa)|Pando (Tornon - Villaviciosa)|Parada, La (Villaviciosa)|Peredal|Peredi|Peruyera (Villaviciosa)|Piquera, La (Villavicio)|Poreño|Porreo|Priesca (San Salvador)|Quintana (Priesca - Villaviciosa)|Rasa, La (Villaviciosa)|Rebollar (Villaviciosa)|Riera (Villaviciosa)|San Andres (Villaviciosa)|San Roque (Villaviciosa)|Santa Mera|Selorio|Sienra, La (Tornon - Villaviciosa)|Silva (Villaverde - Villaviciosa)|Soma La (Villaviciosa)|Soto (Villaviciosa)|Tornon|Toroyes|Torre, La (Carda-Villaviciosa)|Valles, Los (Villaviciosa)|Vega (Quintana)|Vega (Selorio-Villaviciosa)|Vega, La (Priesca-Villaviciosa)|Villar (Selorio-Villaviciosa)|Villar (Tornon-Villaviciosa)|Villar (Villaviciosa)|Villaverde (Quintana)
33317	Acevedo (Villaviciosa)|Aguelle|Balduera|Barrosa, La (Villaviciosa)|Baton|Bayones|Brañas, Las (Villaviciosa)|Busto, El (Villaviciosa)|Calamua|Caliellu (Busto-Villaviciosa)|Camatierra|Campos, Los (Miravalles-Villaviciosa)|Carbayera (Magdalena-Villaviciosa)|Casa Hevia|Casamayor (Villaviciosa)|Cueli|Gancedo|La Abadia|La Hera|La Sota|Las Felgueras|Lugaron|Magdalena, La (Villaviciosa)|Mallado|Miravalles (Villaviciosa)|Miyar, La (Villaviciosa)|Morillon|Novales (Oles-Villaviciosa)|Palomera|Paniceres (La Magdalena - Villaviciosa)|Paniceres (Pando - Villaviciosa)|Pico, El (Villaviciosa)|Pino, El (Cardo-Villaviciosa)|Polledo (Villaviciosa)|Puente (Villaviciosa)|Rionda (Villaviciosa)|Sabudiello|San Blas|San Martin De Miravalles|Santa Eugenia (Villaviciosa)|Santiago (Villaviciosa)|Sienra, La (La Magdalena - Villaviciosa)|Vallin, El (Villaviciosa)|Xin
33318	Carcabada (Celada-Villaviciosa)|Ceceñes|Celada|Charcon, El (Villaviciosa)|Conciella|Contina|Cuinya|Espina (Villaviciosa)|Fernandiz|Ferreria (Villaviciosa)|Fongabin|Fuentona|Fumerin|La Payariega|La Trocha|Llata|Llosanueva|Los Torales|Mahoxu|Miyares (Villaviciosa)|Miyeres (Villaviciosa)|Mogobio|Morvis|Mota|Peruyero (Villaviciosa)|Rali|Riaño (Villaviciosa)|Sello|Tejera, La (Villaviciosa)|Toral, El (Villaviciosa)|Valdaces|Valdebarcena|Valdemaria|Vallinaoscura|Vegas, Las (Villaviciosa)|Viesca, La (Villaviciosa)|Villar (Valdebarcena - Villaviciosa)|Vitienes
33320	Colunga
33324	Riera, La (Colunga)
33325	Carrandena|Eslabayo|Fano (Colunga)|Libardon|Raicedo (Colunga)
33326	Arnin|Cardegoda|Castañera (Rales-Villaviciosa)|El Cayo|El Llestro|Llineres|Pivierda|Rales (Villaviciosa)|San Feliz (Arguero-Villaviciosa)|San Feliz (Rales-Villaviciosa)|Ñabla
33327	Beldredo|Conlledo|Pernus|Pis|Sales|Villaescusa (Colunga)
33328	Huerres|Luces|San Juan De Duz|San Telmo
33329	Carrandi
33330	Lastres
33340	Castiello (Colunga)|Lue
33341	La Isla
33342	Coceña|Gobiendes|Loroñe
33343	Caravia Baja|Carrales|Duesos|Duyos|Espasa, La (Caravia B.)|Valle (Caravia)
33344	Bandalisque|Cerracin|La Cantiella|Prado (Caravia)|Pumarin (Caravia Alta)|Rotella (Caravia Alta)
33345	Alea|Barredo (Ribadesella)|Linares (Ribadesella)|Torre, La (Ribadesella)|Vega, La (Ribadesella)
33346	Berbes|Caravia Alta
33347	Abeo|Bones|Leces|San Esteban De Leces|San Pedro (Ribadesella)|Tereñes
33350	Aroles|Bobia, La (Gijon)|Cabuezo|Gijon|La Camocha|Lavandera (Gijon)|Linares (Camocha)|Monte|Monte, El (La Camocha)|San Martin De Huerces|Santa Cecilia (Gijon)|Tueya|Villaverde (La Camocha)
33390	Leorio|Llantones|Mareo De Abajo|Mareo De Arriba|Pedrera, La (Gijon)
33391	Baldornon|Baones|Caldones|Carcedo (Gijon)|Fano (Gijon)|Garvelles|Granda (Gijon)|La Granda De Abajo|La Granda De Arriba|Linares (Gijon)|Mata, La (Gijon)|Quintana (Gijon)|Rioseco (Baldornon-Gijon)|Rioseco (Caldones-Gijon)|Robledo (Gijon)|Salientes|San Pelayo (Gijon)|Santa Eulalia (Gijon)|Tarna (Gijon)|Vega (Gijon)|Villares (Gijon)|Zalca
33392	Aguda|Arroyo (Gijon)|Carbainos|Casares (Gijon)|Cerca De Abajo|Cerca De Arriba|Figar (Gijon)|Fontaciera|Peñaferruz|Piñera (Gijon)|Porceyo|Rebollada (Gijon)|Riera (Gijon)|Ruedes|Salcedo (Gijon)|Vega, La (Porceyo)|Venta De Veranes
33393	Batiao|Beloño|Caravedo|Cenero|Fresno (Gijon)|Picun|Sotiello (Gijon)|Trubia (Gijon)|Veranes|Villar (Gijon)
33394	Aldea, La (Gijon)|Bernueces|Cabueñes|Castañeda|Cefontes|Cimadevilla (Cabueñes)|Cuesta, La (Gijon)|Deva|Fondon (Gijon)|Gijon|Lloreda (Gijon)|Olla, La (Gijon)|Pedroso (Gijon)|Pontica|Reguera (Gijon)|Rioseco (Vega - Gijon)|San Antonio (Gijon)|San Miguel De Bernueces|Santurio|Serantes (Gijon)|Zarracina (Deva-Gijon)
33400	Aviles
33401	Aviles|Bastian (Aviles)|Cabianca, La (Aviles)|Campo Conde (Aviles)|Campo, El (Aviles)|Cuesta, La (Aviles)|Folleca, La (Aviles)|Fuente, La (Aviles)|Garita, La (Aviles)|Gaxin (Aviles)|Montan, El (Aviles)|Quintana Dionisio (Aviles)|Rey, El (Aviles)|Sablera, La (Aviles)|San Cristobal (Castrillon)|So La Iglesia (Aviles)|Valdredo (Aviles)|Valgranda (Aviles)
33402	Arabuya (Aviles)|Aviles|Ceba, La (Aviles)|Ceruyeda (Aviles)|Grandiella (Aviles)
33403	Aviles|Breton, El (Aviles)|Carrionina, La (Aviles)|Castañeda (Aviles)|Peña, La (Aviles)|Piqueros (Aviles)|Tabla, La (Aviles)
33404	Aviles|Estrada, La (Corvera)|Santa Cruz (Corvera)|Truyes (Corvera)
33405	Aviles|Caliero, El (Castrillon)|Raices Nuevo (Castrillon)
33410	Alfaraz|Bao (Aviles)|Caleyos, Los (Castrillon) (Viviendas)|Campo Santa Ana|Cruz De Illas|Cruz De La Hoguera|Curtia, La (Viviendas)|Forcon, El (Castrillon) (Viviendas)|Granda, La (Castrillon) (Viviendas)|Heros (Aviles)|La Lleda|Los Calvos|Miranda (Aviles)|Mondivisa|Pedreras, Las (Viviendas)|Pozo De La Granda|Santa Ana (Miranda - Aviles)|Santo Domingo|Vidoledo|Villanueva (La Carriona)
33411	Barrera, La (Illas)|Braña, La (Illas)|Callezuela|Fonte|Friera (Illas)|Joyana|Llascara, La (Illas)|Poli|Taborneda|Trejo
33412	Capiello (Corvera)|El Barriero|Fabar (Corvera)|Laguna, La (Castrillon)|Laguna, La (Corvera)|Laguna, La (Illas)|Las Huertas|Llamera, La (Corvera)|Llano (Corvera)|Lloreda (Corvera)|Pevidal, El (Castrillon) (Pueblo)|Piniella (Illas)|Ponton De Villa (Corvera)|Suco, El (Corvera)|Tras La Iglesia|Truebano (Corvera)|Vallin (Corvera)|Villa (Corvera)
33414	Calavero|Faedo (Illas)|Llanavao (Aviles-La Reigada)|Peral, La (Illas)|Reconco (Illas)|Reigada, La (Illas)|Rozaflor|Ventanueva (Illas)
33416	Ablaneda (Corbera)|Barrial (Corvera)|Cabaña, La (Corvera)|Candamo De Corvera|Carruebano|Castiello (Corvera)|Cogulla, La (Corvera)|Entrialgo|Escuela, La (Corvera)|Espinos, Los (Corvera)|Esquilera|Estebanina|Fuencaliente|Garcia|Grandellana|Juncedo|La Peluca|La Rozona|Lavandera (Corvera)|Llandones (Corvera)|Molleda|Monco (Corvera)|Monte, El (Cancienes)|Nubledo|Pedrera (Corvera)|Peruyal (Corvera)|Pino, El (Corvera)|Portazgo, El (Corvera)|Ralla|Reguera, La (Corvera)|Sabledal|Sierra, La (Corvera)|Trapa, La (Corvera)|Vega (Illas)|Villanueva (Corvera)
33417	San Juan De Nieva
33418	Campo De La Iglesia (Gozon)|Campo, El (Gozon)|Endasa (Gozon)|Genra|Granda, La (Gozon)|Laviana De Gozon|Llodero (San Martin De Podes)|Lloreda (Gozon)|Monteril|Nieva|Podes|Santiago De Ambiedes|Zeluan
33420	Lugones
33422	Albares (Llanera)|Castiello (Lugo Llanera)|Castiello (Villabona-Llanera)|La Cigoña|Miranda, La (Llanera)|Peña (Villabona-Llanera)|Piles (Llanera)|Ponton (Llanera)|Tabladiello (Llanera)|Vega, La (Llanera)|Veyo|Villabona (Llanera)|Villardeveyo
33423	Soto De Llanera (Urbanizacion)
33424	Abarrio|Ables|Andorcio|Lineres (Llanera)|Peruyeres|Portiella (Llanera)|Posada De Llanera|Regidorio|Rondiella (Llanera)|Severies
33425	Aguera (Llanera)|Bauro|Cañe|Guyame|Piñera (Llanera)|San Cucao|Tuernes El Grande|Tuernes El Pequeño|Villanueva (Llanera)
33426	Bonielles|Carbajal (Llanera)|Fresno, El (Llanera)|Granda, La (Llanera)|Panizales (Llanera)|Peña, La (Bonielles - Llanera)|Vidriera
33427	Anduerga|Arlos|Barredo (Llanera)|Carbayal (Llanera)|Cenizal (Llanera)|Fanes|Lavares (Llanera)|Santa Cruz De Llanera|Vendon|Verdera (Llanera)|Villayo
33428	Arroyo (Llanera)|Cadage|Campiello (Llanera)|Cayes|Coruño|Parque Tecnologico De Llanera|Poligono Industrial De Asipo|Ponte (Llanera)|Venta Del Gallo (Llanera)
33429	Balbona (Siero)|Belga, La (Bobes-Siero)|Belga, La (Viella-Siero)|Bobes|Castañera|Cogollu, El (Siero)|Conceyin|Conceyin (Siero)|Cuesta, La (Bobes-Siero)|Folgueras (Lugones)|Fresneda (Lugones)|Naon|Paredes (Lugones)|Viella
33430	Candas|Carbayo (Carreño)|Casas Molino|Forca, La (Carreño)|La Cruz De Arrabal|Piedra, La (Carreño)
33438	Ambas (Carreño)|Arena, La (Carredo)|Arquiella|Barcena (Carreño)|Cabo, El (Prendes-Carreño)|Cabovilla (Logrezana-Carreño)|Canto (Logrezana-Carreño)|Canto, El (Prendes-Carreño)|Cespedera|Cueto (El Valle-Carreño)|Falmuria (Carreño)|Fancornio|Fondo|Fuentefria|Fundial|Guimaran|Lacin|Lloral|Manzaneda (Guimaran - Carreño)|Maquila|Mata, La (Carreño)|Monte, El (Logrezana-Carreño)|Naves (Carreño)|Nozalin (Carreño)|Palacio, El (Carreño)|Pesgana|Polledo (Carreño)|Posada (Logrezana-Carreño)|Prendes|Rebollada (Carreño)|Riestro|San Pablo (Guimaran - Carreño)|San Pablo (Prendes - Carreño)|Santa Eulalia (Valle-Carreño)|Sierra, La (Candas - Carreño)|Sopeña|Torre (Carreño)|Valle De Carreño|Vega (Carreño)|Villar (Carreño)|Xianes
33439	Alto De La Iglesia|Barca, La (Piedeloro-Carreño)|Cabada, La (Logrezana-Carreño)|Calabrina|Caleros, Los (Carreño)|Campanal (Carreño)|Cardusu, El (Carreño)|Carnicera|Castiello (Carreño)|Cellero|Coyanca|Espasa (Carreño)|Espeñada|Estacion (Piedeloro-Carreño)|Granda, La (Logrezana-Carreño)|La Machina|La Menudina|Llaneces (Carreño)|Llano, El (Carreño)|Llantero (Carreño)|Matiella|Monte, El (Piedeloro-Carreño)|Pedregal (Carreño)|Peñeo|Piedeloro|Raitan|Regueral (Carreño)|Rendaliego|Sebades|Tejera, La (Carreño)|Xunca|Zanzabornin
33440	Luanco
33448	Balbin|Bañugues|Cabañas (Gozon)|Cabo Peñas|Camporriondo|Ferrero (Gozon)|Fiame|Gelaz|Heres|La Arena|Monte, El (Gozon)|Peroño|Pueblo, El (Gozon)|Quintana (Gozon)|Salines (Gozon)|San Jorge De Heres|Susacasa|Vallina, La (Gozon)|Verdicio|Villanueva (Gozon)|Viodo
33449	Alvare (Gozon)|Antromero|Aramar|Bocines|Busto (Gozon)|Cabrera|Cardo|Cerin|Condres|Eria (Gozon)|Ferrera (Gozon)|La Ren|Legua|Manzaneda (Gozon)|Mazorra|Moniello|Nembro|Ovies|Pedrera, La (Gozon)|Romadonga|Santa Ana (Luanco)|Vioño
33450	Alvare (Castrillon)|Arnao|Campas, Las (Castrillon)|Campiello (Castrillon)|Censo|Cuenza|Cueto, El (Laspra - Castrillon)|Ferralgo|Fondon (Castrillon)|Garabiza|La Castañalona|La Fabrica|Los Carbayos|Piedras Blancas|Ponton (Castrillon)|San Martin De Laspra|Valboniel|Vegarrozadas|Ventorrillo (Castrillon)
33456	Altamira|Berruga (Castrillon)|Braña, La (Castrillon)|Bujandi|Buria|Cascayo (Castrillon)|El Cuadro|La Cangueta|La Ramera|La Ramera De Abajo|La Salguera|Lago (Aviles)|Las Barzanas|Llodares|Llordal|Machuquera|Moire|Orbon|Peñarey|Pillarno|Pulide (Castrillon)|Rasa, La (Castrillon)|Rionda, La (Castrillon)|Romadoiro|Teboyas|Torre, La (Castrillon)
33457	Arances|Arrojo (Naveces-Castrillon)|Bayas|Cabornia, La (Castrillon)|Calamon|Chavolas, Las (Castrillon)|Cueto El (Bayas - Castrillon)|El Molino|El Muro|El Puerto|Infiesta (Castrillon)|La Envidia|La Llada|Las Lunas|Linares (Castrillon)|Llascaras|Navalon|Naveces|Parra, La (Castrillon)|Pedrera, La (Castrillon)|Pino, El (Castrillon)|Pipe (P. Blancas)|San Adriano (Castrillon)|Santa Maria Del Mar|Vallinas, Las (Castrillon)|Villar (Castrillon)
33458	Arenas (Soto Del Barco)|Carcabina|Corrada, La (Soto Del Barco)|Ferreria (Soto Del Barco)|Folgueras (Soto Del Barco)|Los Calbuetos|Ponte (Soto Del Barco)|Riocuevas|Sombredo|Tejera, La (Soto Del Barco)
33459	Cabaña, La (Castrillon)|Carcedo (Soto Barco)|Castro, El (Castrillon)|Cenizal (Castrillon)|Corredoria (Castrillon)|Cueplo|La Banda|La Lleñada|La Lloba|Las Cepas|Llantero (Castrillon)|Panizales (Castrillon)|Plata, La (Castrillon)|Quiloño|Quintana (Castrillon)|Ranon (Soto Del Barco)|Santiago Del Monte|Vallina, La (Castrillon)
33460	Aviles|Cueto, El (Trasona-Corvera)|Marzaniella, La (Trasona-Corvera)|Pedrero, El (Trasona-Corvera)|San Pelayo (Trasona - Corvera)|Tarin (Trasona-Corvera)
33468	Fafilan|Favila|Gudin|Los Gavitos|Mocin|Overo|Palacio (Corvera)|Robes|Silvota (Trasona)|Trasmonte (Corvera)|Trasona
33469	Admiracion De Iglesia|Barca, La (Logrezana-Carreño)|Bardiel|Cabañas (Carreño)|Calle De La Vega|Cascayo (Carreño)|Cotones|El Redal|Fontanina (Carreño)|Huelga, La (Carreño)|Huerno|Las Trancas|Maripollin|Monte Pando|Montegrande|Montico|Orilla Del Rio|Ribanceo|Rodil|San Martin (Carreño)|Tabaza|Tabla, La (Carreño)|Tamon|Vallina (Carreño)|Velilla, La (Tabaza)|Venta, La (Tabaza-Carreño)|Villar (Tabaza-Carreño)
33470	Acebo (Corvera)|Aguera (Corvera)|Aguilero|Alvares (Corvera)|Areñes, Les (Llanera)|Bango|Barredo (Corvera)|Cabañon|Calabaza (Corvera)|Camina|Campañones|Campo De La Vega|Campo La Vega|Cancienes|Cruzada, La (Corvera)|Ferroñes|La Cruzada|Llano, El (Corvera)|Martinete, El (Corvera)|Menudera|Monteagudo (Llanera)|Mora, La (Cancienes)|Moriana|Noval (Llanera)|Nuñez|Picosa|Ponton, El (Solis - Corvera)|Rebollada, La (Corvera)|Rodiles (Corvera)|Sama De Abajo|Sama De Arriba|Santa Marina (Corvera)|Solis|Sota (Corvera)|Taraño|Taujo
33490	Ambiedes (Pueblo)|Aviles|Bardasquera|Barredo (Gozon) (Pueblo)|Campo De La Iglesia (Aviles)|El Estrellin|Escucha, La (Aviles)|Ferrero (Viviendas)|Granda, La (Aviles)|Iboya (Pueblo)|La Cabian|Llantao|Los Guardados|Perdones (Pueblo)|Piedramenuda|Piñera, La (Gozon) (Pueblo)|Quintana Pedro|Refurao|Retumes|San Pedro De Navarro|San Sebastian|Tabiella|Tetuan (San Pedro Navarro)|Tuñes|Valle, El (Gozon) (Zona)|Villanueva (San Pedro Navarro)
33491	Arenas, Las (Carreño)|Braña, La (Carreño)|Canto Coyanca|Ciudad Residencial De Perlora|Corredor (Carreño)|Cueto (Perlora-Carreño)|Cuto (Carreño)|Dormon|Estacion (Perlora-Carreño)|Estaquera|Formiga|Friera (Carreño)|Iglesia, La (Perlora-Carreño)|La Bermeya|La Ferrian|Monte, El (Perlora-Carreño)|Noval (Carreño)|Nozaleda (Carreño)|Pedrera, La (Carreño)|Peran|Perecil|Perlora|Ponteo (Carreño)|Prado, El (Carreño)|Rodada, La (Carreño)|Rodiles (Perlora)|Rotella (Carreño)|Salguero|Sierra, La (Perlora - Carreño)|Yavio
33492	Aboño|Albandi|Bandin|Baragaña (Carreño)|Barquera, La (Carreño)|Barreres (Albandi_Carreño)|Barreres (Pervera-Carreño)|Caicorrida|Calera|Caleyo (Carreño)|Campo San Juan|Carrio (Carreño)|Convento, El (Carreño)|Cuesta Carrio|Cuesta, La (Carreño)|Empalme, El (Carreño)|Granda, La (Albandi-Carreño)|La Xana|Las Cruzadas|Llamera (Aboño)|Manzaneda (Aboño)|Monte Moris|Monte, El (Pervera-Carreño)|Montecalera|Muniello (Carreño)|Otero (Aboño)|Peruyera (Albandi-Carreño)|Peruyera (Carrio - Carreño)|Pervera|Reconco (Aboño)|Reguero (Carreño)|Rica|Riego (Aboño)|Sabarriona|Xivares
33500	Llanes
33507	Ardisana|Buda|Caldueñin|Caldueño|Cortines|Debodes|El Mazuco|Jareras|Llano De Amieva|Los Callejos|Mestas De Ardisana|Palacio De Ardisana|Puente Nuevo|Riocaliente (Llanes)|Villa (Llanes)
33508	Allende (Vibaño)|Malateria, La (Llanes)|Mere|Rioseco (Llanes)|Torrevega|Vibaño
33509	Cue|Pancar|Parres (Llanes)|Pereda, La (Llanes)|Poo De Llanes|Porrua|Portiella, La (Llanes)
33510	Pola De Siero
33518	Acebo (Sariego)|Aramanti|Aramil|Barbecho|Barrial (Siero)|Berros|Brañuca, La (Traspando-Siero)|Cabaña, La (Traspando-Siero)|Camino, El (Feleches-Siero)|Canal (Sariego)|Capilla, La (Siero)|Carcabada (Sariego)|Castañera (Sariego)|Cirigüeyo|Collado (Siero)|Cordon|Corros, Los (Siero)|Cuesta, La (Feleches-Siero)|Cuesta, La (Sariego)|El Molinon|Feleches (Siero)|Felguera, La (Siero)|Figares (Sariego)|Fuentemil|La Cigueta|La Masanti|La Recula|La Secada|Llamargon|Llorian|Mata, La (Feleches-Siero)|Matuca|Miyares (Sariego)|Moldano|Moral De Sariego|Narzana De Sariego|Nora (Sariego)|Novalin|Nuste|Pascual, El (Traspando-Siero)|Pedraces (Siero)|Pedrosa (Sariego)|Quintana (Siero)|Quintana, La (Siero)|Rebollada, La (Siero)|Rebollar, El (Sariego)|Rimada|Rincon|San Roman De Sariego|San Roque (Siero)|Sanriella|Santianes (Sariego)|Tabladiello (Siero)|Traspando|Valvidares|Vega De Sariego|Viesca, La (Siero)|Villar (Vega Sariego)
33519	Atras (Siero)|Aveno|Barbales|Barredo (Siero)|Belga (Celles-Siero)|Braña (Siero)|Braña, La (Noreña)|Cabaña, La (Vega De Poja-Siero)|Camino (Muño-Siero)|Carbayo, El (Lugones)|Careses|Carril, La (Noreña)|Castiello (Siero)|Celles|Ceñal|Collada, La (Siero)|Corujedo (Siero)|Cotariello (Siero)|Cuesta, La (Vega De Poja-Siero)|El Rayo|Escamplero (Siero)|Ferrera (Siero)|Forfontia|Fresno (Collada-Siero)|Granja, La (Siero)|Guaricio|Huergo (Siero)|Lavandera (Siero)|Llorianes (Valdesoto-Siero)|Lugarin (Siero)|Marcenado|Monte (Siero)|Mudarri|Munco|Muño|Negales (Valdesoto-Siero)|Ordiales (Pola De Siero)|Otero (Siero-Celles)|Otero (Siero-Muño)|Pando (Celles-Siero)|Parte, La (Siero)|Peral, La (Siero)|Plazuela|Posada (Siero)|Pueblo, El (Siero)|Rebollal, El (Pola De Siero)|Rioseco (Siero)|San Andres (Noreña)|Santa Eulalia De Vigil|Santianes (Siero)|Taraña|Vega De Poja|Vega Muñiz|Venta La Salve, La (Valdesoto-Siero)|Vigil|Villanueva (Siero)|Villar (Siero)
33520	Nava
33527	Acebal, La (Bimenes)|Canteli|Capellan|Carbayal|Casa Del Rio|Castañal (Bimenes)|Castiello (Bimenes)|Castro (Bimenes)|Colladas (Bimenes)|Corredoria (Bimenes)|Cueto, El (Bimenes)|Escobal (Bimenes)|Faedo (Bimenes)|Figar, La (Bimenes)|Fragua (Bimenes)|Granxu|La Brañuca|La Riba|Martimporra|Montiquin|Perezal|Pradon (Bimenes)|Rebollo (Bimenes)|Ricabo (Bimenes)|Riosuaria|Rubiera (Bimenes)|San Julian De Bimenes|San Miguel (Bimenes)|Texuca (Bimenes)|Tuenes|Valle, El (Bimenes)|Xugueros
33528	Argamoso|Baragaña (Bimenes)|Brizosa|Buruyosa|Cabañas, Las (Bimenes)|Caleyo|Campanal (Nava)|Canales (Bimenes)|Cantera, La (Nava)|Carbajal (Nava)|Carbayal (Nava)|Cardeli|Casa Del Monte|Caspio|Castañera (Rozadas-Bimenes)|Castañera (Suares-Bimenes)|Cañal|Cruz, La (Bimenes)|Cuestespines|Estacion (Bimenes)|Fadiello|Fayacaba|Fontanina (Nava)|Fontoria (Bimenes)|La Llantada|Llamedo (Nava)|Melendreros|Mesnada|Oñardi|Pedrero (Bimenes)|Priandi|Puente, La (Nava)|Pumar (Bimenes)|Quintana (Nava)|Rebollar (Bimenes)|Recimuro|Riega|Roiles (Nava)|Rozadas (Bimenes)|Santa Agadea|Santo Tomas De Priandi|Segredal|Sienra (Bimenes)|Suares|Tavalles|Vara, La (Bimenes)|Viñay
33529	Basoredo|Buyeres|Cabaña, La (Nava)|Camas|Castañera (Nava)|Cesa|Cezoso|Cuenya (Nava)|El Remedio|Emplalme, El (Nava)|Gamonedo (Nava)|Gradatila|Llames (Nava)|Madera, La (Nava)|Monga|Omedo (Nava)|Orizon|Ovin|Pandenes|Pando (Nava-Candones)|Pando (Piloñeta-Nava)|Paraes|Piloñeta|Pozo Cordero|Pruneda|Robledo (Nava)|Sierra, La (Nava)|Solano (Nava)|Travesedo (Nava)|Tresali|Vega (Nava)|Vega, La (Nava)|Vegadali|Verdera (Nava)|Villa (Nava)|Villabona (Nava)|Villamartin (Nava)|Villares (Cabranes)|Viobes
33530	Infiesto|Villanueva (Piloña)
33534	Anayo|Buslleria|Cadanes|Capareda|Cuenya, La (Infiesto)|Fresnosa (Piloña)|Las Pedrazas|Llares|Moruxones|Oscuredal|Pintueles|Robledo De Anayo|Viyao
33535	Bargaedo|Bustiello (Infiesto)|Canello (Piloña)|Coya|Gamonedo (Piloña)|Llana De Coya (Piloña)|Lodeña|Maza|Montecoya|Mures|Santa Leocadia|Serpiedo|Villabajo|Villarriba
33536	Artedosa|Beronda|Cabaña Derecha|Cadapereda|Comba, La (Infiesto)|Cuevas, Las (Piloña)|El Moro|El Tozo|Fresnedal (Infiesto)|La Marea|Los Cuetos|Melendreras (Piloña)|Obana|Peruyero (Infiesto)|Peñueco|Puente Miera|Raposo (Piloña)|Retorno|San Martin (Piloña)|Travesera|Vegarrionda
33537	Cuerrias De Espinaredo|Espinaredo (Infiesto)|Esteli|Ligueria|Lozana|Omedal (Piloña)|Otero (Piloña)|Pandiella (Piloña)|Pedroso (Espinaredo-Piloña)|Porciles (Piloña)|Raicedo (Infiesto)|Riofabar|Rozapanera|San Vicente (Piloña)|Santianes|Soto (Infiesto)
33538	Abedul (Piloña)|Arenas De Beloncio|Beloncio|Candanedo (Infiesto)|Cobayas|Cuerrias De Maza|Cueva, La (Infiesto)|Ferreros (Infiesto)|La Peridiella|Vallin (Infiesto)
33539	Argandenes|Biedes (Piloña)|Bierces|Cardes (Infiesto)|Carrazal|Castiello (Infiesto)|El Calzado|El Orrin|La Cobaya|Llana, La (San Roman-Piloña)|Mestas (Piloña)|Pandoto|Parte, La (Piloña)|Pascual (Piloña)|Pedrueco|Peleon|Ques|Robledal (Piloña)|Roces (Piloña)|San Miguel (Piloña)|San Roman Piloña|Tercias, Las (Piloña)|Valle (Piloña)|Valles (Piloña)
33540	Arriondas|Castañera (Parres)|Santianes Del Terron
33546	Arobes|Carrio (Arriondas)|Llerandi (San Cosme)|Ozanes|Romillin|Romillo|San Cosme De Llerandi|Tospe
33547	Aguera (Cangas De Onis)|Coviella (Cangas De Onis)|Cuenco|Granda, La (C.Onis)|Llano, El (Cangas Onis)|Llordon|Miyar (Cangas Onis)|Olicio|Parda|Peruyes (C. Onis)|Roza, La (Castrillon)|San Tirso (Cangas De Onis)|Triongo|Villa (C. Onis)|Viña (C. Onis)
33548	Bodes|Cofiño|Collado De Santo Tomas|Cuadroveña|Fios|Hueges|Nevares|Pandiello (Arriondas)|San Andres (Arriondas)|Santo Tomas De Collia|Villanueva De Fios|Villar De La Cuesta|Villar De La Peña
33549	Bode|Collia|La Vita|Las Coronas|Montealea|Pendas
33550	Cangas De Onis
33554	Arangas|Arenas De Cabrales|Bulnes|Camarmeña|Sotres|Tielve|Tresviso
33555	Asiego|Berodia|Canales (Cabrales)|Carreña De Cabrales|Escobal, El (Cabrales)|Inguanzo|Molina, La (Cabrales)|Ortiguero De Cabrales|Pandiello (Cabrales)|Poo De Cabrales|Puertas De Cabrales|Salce
33556	Abamia|Avin|Beceña|Benia|Bobia De Abajo|Bobia De Arriba|Bustovela|Castro, El (Cangas De Onis)|Con|Corain (Cangas De Onis)|Corao|Corao Castillo|Cuerres (Cangas De Onis)|Cuetoaleos|Demues|Estrada, La (Cangas De Onis)|Gamonedo De Cangas|Gamonedo De Onis|Grazanes|Igena|Intriago|La Cebia|La Robellada|Labra|Llano De Con|Llenin|Los Menores|Mestas De Con|Pandellevandes|Paroro|Pedroso, El (Cangas De Onis)|San Martin De Grazanes|Santianes De Ola|Santoveña (Amieva)|Sirviella|Soto De La Ensartal|Talavero|Tarano (Cangas De Onis)|Teleña|Villar De Onis|Villaverde (Cangas De Onis)|Zardon
33557	Abiegos|Ambingue|Beleño|Cadenaba|Carangas (Ponga)|Cazo|Caño (Cangas De Onis)|Cirieño|Corigos (Amieva)|Eno|Fresneda, La (Amieva)|La Prida|Los Laderos|Miyares (Amieva)|Mollera|Parcia (Amieva)|Pen|Pervis|Pontigo, El (Amieva)|Priesca|San Juan De Beleño|Santa Olaya|Santianes De Tornin|Sellaño|Sobrefoz|Tanda|Taranes|Tornin|Vega De Pervis|Vega De Sebarga|Ventaniella|Villaverde (Amieva)
33558	Amieva|Argolibio|Arnaño|Camporriondi|Carbes|Casielles De Ponga|Ceneya|Cien|El Molin De La Llastra|Gorgoyones|La Cetreda|La Fuente Del Sapu|Mata, La (Amieva)|Mian|Palombierga|Precendi|Sames|San Ignacio|San Juan De Amieva|San Roman De Amieva|Santillan|Vega De Cien|Viboli|Viego
33559	Aballe|Arenas De Parres|Bada|Caxidi|Celango|Collado De Andrin|Dego|Helgueras|Isongo|Lago (Parres)|Las Rozas De Villanueva|Llueves|Nieda|Prestin|Puente, El (Parres)|San Juan De Parres|San Martin De Bada|Seguenco|Sobrepiedra|Soto De Dego|Tribierto|Valle De Moro|Vallobil|Vega De Los Caseros|Villanueva (Cangas De Onis)|Vis
33560	Ribadesella
33566	Calabrez|Pando (Ribadesella)
33567	Carmen|Fresno (Ribadesella)|Moro (Ribadesella)|Sardedo|Sebreño|Soto (Ribadesella)
33568	Camango|Collera|Cuerres (Ribadesella)|Meluerda|Toriello (Ribadesella)
33569	Ardines|Fries|Granda (Ribadesella)|Junco|Llovio|Omedina|San Miguel De Ucio|Santianes Del Agua|Sardalla|Ucio
33570	Panes
33576	Caraves|Oceño|Rozagas|Ruenes|Trescares
33577	Mier
33578	Alles|Llonin
33579	Abandames|Alevia|Bores|Buelles (P. Baja)|Cavandi|Cerebanes|Cimiano|Colosia|Cuñaba|Mazo, El (P. Baja)|Merodio|Narganes|Para|Robriguero|Siejo|Suarias|Tobes (P. Baja)
33580	Acebal, La (Lieres)|Cabaña, La (Lieres-Siero)|Campiello (Lieres-Siero)|Corte (Lieres-Siero)|Corujedo (Lieres)|Cotaya|Cruz, La (Lieres-Siero)|Cuesta, La (Lieres-Siero)|Espinera, La (Lieres-Siero)|Faces, Las (Lieres)|Faya, La (Lieres)|Fresneda (Lieres)|La Cobiella|Las Cuadriellas|Lieres|Los Cañales|Monte, El (Lieres)|Pedrera, La (Lieres)|Pino, El (Lieres)|Piqule|Reanes|Rebollar, El (Lieres-Siero)|Reconco, El (Lieres-Siero)|Roza, La (Lieres)|Secadiella|Solvay|Sorrobin
33581	Campones (Nava)|Fuentesanta|La Corba|La Vilortera|Polanava|Vegalloba
33582	Carancos|Ceceda|Cuesta, La (Nava)|Faya, La (Ceceda)|Fresnadiello (Nava)|Grandiella (Nava)|Sienra (Ceceda)|Vega, La (Ceceda)
33583	Antrialgo|Barcena (Villamayor)|Borines|Brez|Cereceda (Villamayor)|Collados, Los (Piloña)|Goleta, La (Villamayor)|Infiesta, La (Villamayor)|Melarde|Miyares (Piloña)|Mones (Villamayor)|Moñio|Pando, El (Miyares-Piloña)|Pedroso (Piloña)|Pesquerin|Robledo De Cereceda|San Feliz (Piloña)|Sardeda|Sieres|Torin|Vallobal|Villamayor (Piloña)
33584	Caldevilla|Canal, La (Sevares)|Cua|Ferrera (Piloña)|Frecha, La (Sevares)|La Matosa|Pandavenes|Pico, El (Infiesto)|Piñera, La (Sevares)|Priede|Samalea|Sevares|Sorribas (Sevares)|Tejedal, El (Sevares)|Villar De Huergo|Villarcazo
33585	Castiello De Parres|Cividiello|Faeda, La (Parres)|Fresnidiello|Llames De Parres|Prunales|Soto De Dueñas|Viabaño
33586	Cayarga|Fuentes (Arriondas)|Gustarnales|Mesariegos|Sinariega|Tresmonte|Tresmonte De Parres
33587	Margolles|Toraño
33588	Cuevas De Agua|Nocedo (Cuevas Del Agua)|Tezangos
33589	Cabielles|Cardes (Cangas De Onis)|Celorio (Cangas De Onis)|Covadonga (Cangas De Onis)|La Riera De Covadonga|Llerices|Narciandi|Onao|Perlleces|Soto De Cangas|Torio|Tresano
33590	Andines|Bojes|Boquerizo|Borbolla, La (Llanes)|Bustio|Colombres|La Franca|Noriega|Pie De La Sierra|Pimiango|Santa Eulalia De Carranzo|Tresgrandas|Vilde|Villanueva De Colombres
33591	Belmonte De Pria|Garaña De Pria|Llames De Pria|Pesa De Pria|Piñeres De Pria|Pria|Silviella De Pria|Villanueva De Pria
33592	Carriles, Los (Llanes)|Llamigo|Nueva (Llanes)|Ovio|Picones|Riensena
33593	Cardoso (Llanes)|Hontoria|Villahormes
33594	Bricia|Lledias|Naves (Posada Llanes)|Piedra (Posada Llanes)|Posada De Llanes|Quintana (Posada Llanes)|Rales (Posada Llanes)|Turanzas
33595	Balmori|Barro (Llanes)|Celorio (Llanes)|Niembro
33596	Andrin|La Galguera|Puron|San Roque Del Acebal|Soberron
33597	Puertas De Vidiago|Riego (Vidiago)|Vidiago
33598	Buelna|Pendueles
33599	San Esteban (P. Baja)
33600	Aguain|Arriondo (Mieres)|Campeta, La (Mieres)|Cargadero Viejo|El Requintin|Mieres Del Camino
33610	Ablanedo (Turon)|Argaxo|Arniello|Arnizo (Turon)|Barcena (Turon)|Berruga, La (Turon)|Braña, La (Mieres)|Cabaña, La (Turon)|Caborno, El (Turon)|Cabritera|Campa La Estrecha|Campo La Tabla|Canabatan|Cantiquin|Canto, El (Turon)|Carcarosa|Casillina (Turon)|Castañir|Ceposa, La (Turon)|Collado, El (Turon)|Cotarente|Cuesta De Villabazal|Cuesta Del Lago|Dochal|El Artoso|El Cueto|El Gavito|El Pindal|Entrerrios (Mieres)|Entrerrios (Turon)|Enverniego (Turon)|Escobal (Turon)|Escosura|Folleron|Fortuna|Fuente, La (Turon)|Fuentona, La (Turon)|Fuexo|Granja, La (Turon)|La Caleyina|La Crucina|La Faya Verde|La Flecha|La Rabaldana|La Vegona|Lago (Turon)|Lago De Arriba|Las Matiellas|Las Porqueras|Linares (Turon)|Llama, La (Turon)|Llana Palacio|Llanacedo|Llano Peral|Llera, La (Turon)|Misiego (Turon)|Ordaliego (Turon)|Pandel De Berruga|Pandiello (Turon)|Pedrero (Turon)|Peruyal (Turon)|Pervaca|Piedrafita (Turon)|Pila, La (Turon)|Preximir|Prubiz|Pruvia, La (Turon)|Puente Villandio|Rasa, La (Turon)|Reconco (Turon)|Reguera, La (Turon)|Regueron (Turon)|Repedroso|Requejo (Turon)|Rozadiella (Turon)|San Andres (Turon)|San Benigno|San Francisco|San Justo (Turon)|San Pedro (Turon)|Santa Eulalia (Turon)|Santo Tomas (Turon)|Sesnendi|Soqueto|Tablado (Turon)|Tejera (Turon)|Trechorio (Turon)|Turon|Valles, Los (Turon)|Vera Del Camino|Viescas, Las (Turon)|Villabazal|Villafria (Turon)|Villandio|Villapendi
33611	Brañanocedo|Cantera, La (Mieres)|Corujas (Mieres)|Cuarteles De Doriga|Fabariega (Mieres)|Pedroso (Santa Cruz - Mieres)|Reguerona, La (Mieres)|San Bernardo|Santullano De Mieres|Sierra, La (Mieres)|Villarejo (Mieres)|Villasola (Mieres)
33612	Bustiello (Mieres)|Casona, La (Mieres)|Collada, La (Mieres)|Collanzo (Mieres)|Corraina|Cruz De Los Caminos|Figares (Mieres)|Forcada|Forniellos (Santa Cruz De Mieres)|Fresnedo (Santa Cruz De Mieres)|Gramedo (Mieres)|Grillero|La Alameda|La Llinar|Llama, La (Mieres)|Llanas, Las (Mieres)|Oriella|Pomar (Santa Cruz De Mieres)|Presamo|Puente Vieja|Revallinas|Santa Cruz De Mieres|Taruelo|Valdeciegos|Valdeoreyo|Valdesenche|Virgen De La Luz|Vistalegre (San Cruz De Mieres)
33613	Boyalvendi|Corral De Ujo|Granda, La (Turon)|Jamonda|La Faya La Verde|Las Argalladas|Llascara, La (Urbies)|Llomba La (Turon)|Palacio, El (Urbies)|Urbies|Valeriana|Vallicuerra
33614	Cabanin, El (Santa Rosa-Mieres)|Canto|Carraspientes|Casa Cima|El Sordan|Invernal (Mieres)|La Xagosa|Polio|Pradorredondo|Quintanales, Los (Mieres)|Redespines|Rioturbio|Santa Rosa (Mieres)|Vegadotos|Vescon, El (Santa Rosa-Mieres)
33615	Cangas De Abajo|Cangas De Arriba|Caseta, La (Valdecuna-Mieres)|Cenera|El Valleto|Forniellos (Gallegos-Mieres)|Foz (Mieres)|Fresnedo (Mieres)|Gallegos (Mieres)|Insierto|Llandebustio|Lleron, El (Mieres)|Pedroso, El (Valdecuna - Mieres)|Pradon, El (Valdecuna - Mieres)|Segada|Sobrobio|Tazada|Valdecuna|Viade|Viesca (Mieres)|Villaestremeri|Villamartin (Mieres)|Villar De Gallegos
33616	Acebedo (Mieres)|Acebo (Mieres)|Agradiellos|Baltasara|Barrio Solano|Belonga (Mieres)|Campo, El (Mieres)|Cantera, La (San Emiliano)|Cantoserron|Carba, La (Mieres)|Collado, El (Mieres)|Corion|Coto Peral|Cuestavil|El Peñon|El Someron|Fresnedal (Mieres)|La Caba|La Caseria|La Depata|La Insiesta|La Matinada|Llana, La (Mieres)|Longa, La (Mieres)|Mosquita|Murias (Mieres)|Nadales|Pedrova|Piedra, La (Mieres)|Piedrafita (Mieres)|Planta, La (Mieres)|Pontones, Los (Mieres)|Rebollo (Santa Rosa-Mieres)|Santo Emiliano|Torneros (Mieres)
33617	Barrio, El (Mieres)|Cabanin, El (La Peña-Mieres)|Carba De Arrojo|Caseta, La (La Peña-Mieres)|Casetas, Las (Mieres)|Cimiellos|Corraelcanto|Cruces, Las (Mieres)|Cutiellos (Mieres)|El Arzolar|El Bravo|El Terronal|Escalada (Mieres)|Escuelas, Las (Mieres)|La Canterona|La Fuentiquina|La Infestal|La Nozal|La Pria|La Rambla|Peña, La (Mieres)|Pradon, El (La Peña - Mieres)|Rozadas De La Peña|Rucio, El (Mieres)|San Tirso (Mieres)|Tejera, La (Mieres)|Vara, La (Mieres)|Venta, La (Mieres)
33618	Barrio Gonzalin|Carricacho|Disco|Espinedo (Mieres)|Estacion, La (Mieres)|Fonda, La (Mieres)|Llano La Tabla|Maricasina|Pajio|Panizales (Mieres)|Pares|Prado Reguero|Pradon (Seana - Mieres)|Puente La Luisa|Quinta, La (Mieres)|Reimeses|Requejado|Ribono|Seana|Seana (Carretera)|Sueros|Vescon El (Seana - Mieres)
33619	Aguilar|Brañanobeles|Camino De La Mariana|Camino De La Quinta|Carbonero|Carrilon (Mieres)|Caño De La Salud|Copian|Corredor, El (Mieres)|Cuarteles De Mariana|El Rollo|La Calleja|La Coca|La Malateria|La Piperona|Ladredo|Mariana|Padrun, El (Olloniego)|Peraleda|Piezas, Las (Mieres)|Plano, El (Mieres)|Prados De Copian|Quinta, De La (Camino)|Raiz, La (Mieres)|Rebollada, La (Mieres)|Repitaneo|Resenche|Rosamiana|Rozadas De Bazuelo|Santa Lucia (Mieres)|Tablado De Mieres|Tejera De Bazuelo|Tendejones|Valmurian|Vegalafonte
33620	Campomanes|Collado, El (Campomane)|Cornellana (Pola De Lena)|Corrada Vieja (Lena)|Cotorraso (Campomanes)|La Nozala|Montealegre
33627	Arnon|Cortina De Telledo|Pontones, Los (Campomanes)
33628	Campo, El (Campomanes)|Cruz, La (Campomanes)|Reconcos (Campomanes)|Riospasos|Telledo|Tras La Cruz|Tuiza
33629	Alcedo De Caballeros|Bendueños|Carraluz|El Moclin|El Redondo|Enverniega|Espinedo (Campomanes)|Ferreras (Campomanes)|Frecha, La (Campomanes)|Herias (Campomanes)|Heros (Campomanes)|Jomezana De Abajo|Jomezana De Arriba|Las Monas|Piñera (Campananes)|Renueva|Salas (Campomanes)|Sotiello (Campomanes)|Tios|Valle (Campomanes)|Zureda
33630	Pola De Lena
33637	Ablano (Lena)|Alcedo (Pola De Lena)|Campas, Las (P. Lena)|Caseta, La (P. Lena)|Cobertoria (P. Lena)|Columbiello|Consorios|Felgueras (Pola De Lena)|Mamorana|Otero (P.Lena)|Palacio (Pola De Lena)|Peridiello|Puente, La (Pola De Lena)|Ronzon (P. Lena)|Santa Cristina (Pola De Lena)|Sorribas (Pola De Lena)|Vega Del Ciego|Vega Del Rey
33638	Armada|Cabo|Carabanzo|Corraon|Fresnedo (Lena) (Villallana)|Mora|Piedraceda|Retrunal|San Feliz (Pola De Lena)|Tablado (P. Lena)|Valle, El (P. Lena)|Viña
33639	Barraca, La (Pola Lena)|Bayo, El (Pola Lena)|Brañalamosa|Campos, Los (P. Lena)|Castañera (P. Lena)|Figares (Pola De Lena)|Fueyos, Los (P.Lena)|Iglesia, La (Pola De Lena)|La Corroña|La Maderada|La Miera|Maramuñiz|Muela, La (P.Lena)|Muñon Cimero|Muñon Fondero|Palacios (P.Lena)|Reconcos (Pola De Lena)|Soterraña|Trechorio (Lena)|Venceyal
33640	Barredos (Ujo)|Barrio Nuevo De La Estacion (Ujo)|Casares (Ujo)|Cortina, La (Ujo)|Embaralado|Estacion (Ujo-Mieres)|La Reigosa|La Urdiera|Los Tapios|Pontarron|Rebollo, El (Ujo)|Ribayon|Ubriendes|Ujo|Viastalegre|Villar (Ujo)|Viñas, Las (Ujo)
33650	Ablaña|La Faidosa|Llamas (Ablaña)|Llanolacuba|Nicolasa|Peña Del Cuervo|Quintanas, Las (Mieres)
33660	Malpica (Olloniego)|Olloniego|Quintanal (Olloniego)|Santianes (Olloniego)|Sienra (Olloniego)
33669	Casares (Oviedo)|Escobadielles|Focara, La (Olloniego)|Llandellana|Manzaneda (Olloniego)|Monegro|Mortera, La (Olloniego)|Picola Viña|Portazgo, El (Olloniego)|San Frechoso (Olloniego)
33670	Moreda De Aller
33673	Nandiello
33675	Boo|Bustille|Canto De La Silla|Carrerallana|Cuarteles De Marianas|Labayos (Moreda)|Pena, La (Moreda)|Provia, La (Moreda)
33676	Murias (Aller)|Santibañez De Murias|Villar De Murias
33677	Arnizo (Moreda)|Cabanon|Cabo (Moreda)|Campueta|Carrera, La (Moreda)|Corralada|Enfistiella|Huertomuro|Las Fureras|Nembra|Omedal (Aller)|Perasente|Posadorio|Pumardongo (Moreda)|Rueda|San Miguel (Moreda)|Tornos, Los (Moreda)
33678	Agueria (Moreda)|Arriondo (Moreda)|Bustios|Cabanielles|Casanueva (Moreda)|Caseta, La (Moreda)|Castro (Aller)|Conforcada|Fontona|La Cascayera|La Maravilla|La Rumiada|Llanas, Las (Aller)|Llandemieres|Omeo (Moreda)|Polea|Santo Tomas (Aller)
33679	Collada (Moreda)|El Rason|Entrebu|Felguerosa, La (Moreda)|Florida, La (Moreda)|Los Heros|Oyanco|Primayor|Reyan|Torneros, Los (Moreda)|Valdedios (Moreda)|Valle, El (Moreda)|Villanueva (Moreda)|Xagual
33680	Collanzo (Aller)|Cuerigo|Fuente, La (Collanzo)|Santibañez De La Fuente|Valdevero
33681	Casomera|Conforcos (Aller)|Foz (Moreda)|La Paraya|Llamas (Aller)|Rio Aller|Riomañon|Villar De Casomera
33682	Baiña|Barraca, La (Mieres)|Barreros, Los (Mieres)|Barrial (Mieres)|Barrio De Pachon|Casa De Arriba (Mieres)|El Coston|El Tunelon|Escalabada|Fenosa (Mieres)|La Falcuedra|Laviades|Llaneces (Mieres)|Lleros De Abajo|Lleros De Arriba|Loredo (Mieres)|Navalin, El (Mieres)|Paraxa|Pereda, La (Mieres)|Perio|Puente De La Pereda|Pumardongo (La Pereda)|Rociella|Roza, La (Mieres)|Tablado (Loredo - Mieres)|Traspalacio|Vallin (Mieres)|Vega De San Pedro
33683	Agualestro|Aprocedorio|Arriondo (Figaredo)|Cabojal|Cortina De Figaredo|Cuesta, La (Figaredo)|Cutiellos|Felguerua|Figaredo|Formiguera (Figaredo)|Lavandera, La (Figaredo)|Pena, La (Figaredo)|Peñule|Pumarin (Figaredo)|Quemadero|Repipe|Riquela|Sarabia|Sobre Las Vegas|Vega De Los Piqueros|Villadominica
33684	Buciello|Caborana|Collados, Los (Aller)|Conveniencia|El Tarancon|Estrada, La (Moreda)|La Pinga|Llana La Mata|Sienra, La (Aller)|Sinariego|Tejera, La (Aller)
33685	Acebedo (Aller)|Arteos|Cambrosio|Carrocera (Moreda)|Casares, Los (Aller)|Castandiello (Moreda)|Castañedo (Aller)|Castiello (Moreda)|Corigos (Aller)|Cortina, La (Moreda)|Cubrenes|El Casar De Moreda|El Torno|Escobio (Moreda)|Estrullones|Fresnadiello (Aller)|Fresnaza|Lagar, El (Moreda)|Las Barrosas|Llameras|Misiegos|Orilles De Serrapio|Palacio, El (Aller)|Pedregal (Aller)|Pereda (Aller)|Pinedo|Piñeres De Aller|Provia, La (Piñeres)|Pueblo, El (Piñeres-Aller)|San Antonio (Piñeres - Aller)|Santa Ana (Aller)|Serrapio|Soto De Aller|Tercias, Las (Piñeres-Aller)|Vegalatorre|Veguellina|Venta, La (Piñeres-Aller)|Villar (Piñeres-Aller)
33686	Bello (Cabañaquinta-Aller)|Cabañaquinta|Casas De Abajo (Moreda)|Cuevas (Pelugano - Aller)|Entrepeñas (Cabañaquinta)|Escobio (Cabañaquinta)|Fornos (Aller)|Levinco|Palomar (Cabañaquinta)|Pelugano|Quintanas, Las (Aller)|Rio Cabo|Vega, La (Cabañaquinta)
33687	Llanos|Pino, El (Moreda)|Pola Del Pino|Rioseco (Aller)
33688	Cuevas (Felechosa - Aller)|Felechosa|Puerto San Isidro (Asturias)
33690	Bervola|Caravies|Castañera (Lugo Llanera)|Fonciello (Llanera)|Lugo De Llanera|Pando (Lugo De Llanera)|Pondal|Robledo (Lugo Llanera)|Santa Rosa (Lugo Llanera)|Truebano (Lugo Llanera)
33691	Gijon|Monteana|Muniello (Veriña)|Pavierna|Poago (Veriña)|Veriña|Zarracina (Veriña-Gijon)
33692	Cabezon|Las Puentes|Navidiello|San Andres (Puente Fierros)
33693	Brañillin (Pajares)|Castiello|Flor De Acebos|La Malveda|La Muela|Las Pedrosas|Navedo|Nocedo, El (Lena)|Pajares|Puente De Los Fierros|Romia De Abajo|Romia De Arriba|San Miguel Del Rio|Santa Marina (Pajares)|Villar (Pajares)
33694	Buelles|Casorvida|Congostinas|El Carril|Fresnedo (Lena)(Fuentes, Las)|Linares Del Puerto|Llanos De Someron|Malvedo|Pandiella (Linares-Lena)|Parana
33695	Castiello (Villallana)|Castro (Villallana)|Collada, La (Pola De Lena)|La Corraona|Padrun, El (Villallana)|Requejo (Lena)|Retrulles|San Martino|Vallinas (Villallana)|Vega Muro|Vega, La (Villallana)|Villallana|Viscarriona
33696	Candama, La (Ribera De Arriba)|Casuca (Ribera De Arriba)|Fresnedo (Soto Rey)|Lusiella|Pico De Lanza (Ribera De Arriba)|Soto De Rey
33697	Arroyo (Serin)|Campazon|Cruciada|Espin, El (Gijon)|Fontanielles|Gallinal|Liervado|Melendrera (Serin)|Naviella|Pasquin|Reboria (Serin)|San Andres De Tacones|Santianes (Serin)|Serin|Sisiello|Traveseo|Vega, La (Serin)|Vilarteo
33700	Almuña|Barcellina|Luarca
33707	Belen|Buseco (Luarca)|Carboniella|Cercenadas|Cereizal|Concernoso|Cunqueiros|Granda, La (Luarca)|Los Piñeros|Mazo, El (Luarca)|Menudeiro|Paladeperre|Piedrafita (Luarca)|Riopinoso|San Pelayo De Sexmo|Siñeriz|Valleancho
33708	Ablanedo (Luarca)|Busindre|Busmourisco|Cadollo|Candanin|Candanosa, La (Luarca)|Figal, La (Luarca)|Folgueron|Gallinero De Barcia|Herreria De Arriba|Leiriella|Modreros (Luarca)|Rioseco (Luarca)|Telares|Venta, La (Luarca)
33710	Aceñas|Espin, El (Coaña)|Navia
33716	Fojos|Medal|Mohias|Ortiguera (Coaña)|Rabeiron|Reguera (Coaña)|Vega De Pindolas|Villares Los (Coaña)|Villares, Los (Coaña)
33717	Abruñeiros|Berbeguera|Berrugas|Brañuas|Bullimeiro|Busmente|Candanosa De Parlero|Carcobas|Carrio (Villayon)|Castañera (Villayon)|Herias (Villayon)|La Granas-Riestra|Lantero (Boal)|Lendelforno|Linera, La (Villayon)|Los Lagos|Masenga|Mezana|Murias (Villayon)|Oneta|Parlero|Ribalagua|San Cristobal (Villayon)|Sellon (Villayon)|Valbona (Villayon)|Villayon|Zorerina
33718	Aguamaroza|Arbon|Argolellas|Barandon|Busmayor (Villayon)|Bustelfollado|Candanosa De Bustefollado|Candanosa De Solares|Castanedo|Couz, El (Villayon)|Folguerosa (Villayon)|Illaso|Lantero (Villayon)|Lendequintana|Loredo (Villayon)|Martintorin|Pojos|Ponticiella|Pumarin (Coaña)|Sabariz|San Juan De Trelles|San Pelayo (Villayon)|Sequeiro|Solares (Villayon)|Teijedo (Coaña) (Caserio)|Trabada (Villayon)|Valdedo (Villayon)|Valle (Villayon)|Vidural (Villayon)|Villartorey|Vivedro|Zorera, La (Villayon)
33719	Abranedo|Andes|Anleo|Ansilan|Armental|Balmeon|Barqueros|Braña Del Rio (Navia)|Busmargali|Cabanella|Caborno (Navia)|Cacabellos|Cartavio|Carvajal (Navia)|El Aspra|El Seijo|Esfreita|Esteler|Folgueras (Coaña)|Freal|Frejulfe|Fuentes (Navia)|Guardia|Jarrio|Jonte (Coaña)|La Colorada|La Mabona|La Villalonga|Las Cortinas|Las Escas|Loza|Lugarnuevo|Meiro|Monte, El (Navia)|Murias (Navia)|Paderne (Navia)|Piquera (Navia)|Piñera (Navia)|Polavieja|Salcedo (Navia)|San Cristobal (Coaña)|San Miguel De Eiros|Sante (Navia)|Silvarronda|Somorto|Talaren|Teifaros|Torce (Coaña)|Venta, La (Navia)|Villabona (Navia)|Villalocay|Villaoril (Navia)
33720	Boal|Llaviada|Pelame (Boal)|Penouta (Boal)
33721	Villur
33724	Los Navalios
33725	Armal|Cabanas, Las (Boal)|Caleyo, El (Boal)|Capareiro|Langrave|Rozas (Boal)|Villanueva (Boal)
33726	Cabanas Trabazas|Orbaelle|Serandinas|Villar De Serandinas
33727	Castrillon De Boal|Folgueira Mayor|Fuentes Cavadas|Lendiglesia|Merou|Mestas, Las (Boal)|Rebollal (Boal)|Reigoto (Boal)|Sampol|Sarceda (Boal)|Silvon
33728	Brañadesella|Brañavara|Carrugueiro|El Pato|Ferradal (Boal)|La Bajada|La Camara|Peirones|Prelo|Ronda, La (Boal)|San Luis|Silvarelle|Villar De San Pedro
33729	Brañalibel|Ouria (Boal)|Ransal|Rozadas (Boal)|Treve|Valleseco|Vega De Ouria
33730	Airela|Armilda|Arregaida|Brualla|Busmayor (Grandas De Salime)|Carballo Del Cuito|Castiadelo|Cereijeira|Escanlares|Fabal (Grandas De Salime)|Grandas De Salime|La Aviñola|La Farrapa|Llandecarballo|Los Vitos|Magadan|Nogueiron|Paradela (Villamayor)|Pelou|Pontiga (Grandas De Salime)|Robledo (Grandas De Salime)|San Mayor|Teijeira (Grandas De Salime)|Trasmonte (Grandas De Salime)|Valdedo (Grandas De Salime)|Villabolle|Villadefondo|Villarello (Grandas De Salime)|Villarmayor|Vista Alegre|Vistalegre
33731	Baboreira|Bullaso|Bustelo (Illano)|Cernias|Doiras|El Poceiro|Estela|Froseira|Herias (Illano)|Lantero (Illano)|Lombatin|Muñon|Navedo (Illano)|Piñeira (Boal)|Rio De Villar|Riodecoba|Sarzol|Tamagordas|Villar De Bullaso
33732	Cedemonio
33733	Gio
33734	Arruñada (San Martin De Oscos)|Cachafol|Carbayal (Illano)|Cimadevilla (Illano)|El Arne|Entrerrios (Illano)|Illano|La Montaña|Pastur|San Esteban (Illano)|San Pedro De Ahio|Villar De Pastur|Villaseca
33735	Argul|Brañavieja (Pesoz)|Cabanela (Pesoz)|Cela|Francos (Pesoz)|Lijou|Mazo De Mon|Pelorde|Pesoz|Sequeiros|Villabrille|Villarmarzo
33736	Santa Maria (Grandas De Salime)|Sanzo|Seran
33737	Castro (Grandas De Salime)|Malneira|Padraira|Pedre|San Julian (Grandas De Salime)
33738	Coba, La (Grandas Salime)|Trabada (G. Salime)
33739	Brañota|Bustelo Del Camino|Folgosa|Fornaza|Gestoselo|Gestoso (Grandas Salime)|Lieira|Llandepereira|Monteserin Grande|Monteserin Pequeño|Peñafuente|Peñafurada|Seoane|Silvallana (Grandas Salime)|Valabelleiro
33740	Tapia De Casariego
33746	Campos (Tapia)|Cortaficio|El Franco|Folgueiras (Tapia)|Mernies|Porcia|Rabote|Rebollada, La (Tapia)|San Pelayo (El Franco)|Valdepares
33747	Acevedo (Tapia)|Alfonsares|Barrosa, La (Tapia)|Bustelo (Tapia)|Jarias|La Paloma|La Veguiña|La Ventanova|Lantrapiñan|Mantaras|Matafoyada|Momean|Monte, El (Tapia)|Orgales|Pelogra|Pontraviza|Reiriz|Roda, La (Tapia)|San Antonio (Tapia)|San Julian (Tapia)|Valle De San Agustin|Ventosa, La (Tapia)|Villargomil|Villarin (Tapia)
33748	Casariego|Entreplayas|Lota|Muria, La (Tapia)|Ol|Viacoba|Viso, El (Tapia)
33749	Calambre|Cornallo|Pedralba|Penela|Roda (Tapia)|Santa Gadea|Serantes (Tapia)|Vilanova (Tapia)|Villamil
33750	La Caridad|Longara|Viavelez
33756	Arancedo|Boimouro|Brañamayor (El Franco)|Coba (Boal)|La Andina|Lebredo (Coaña)|Lebredo (El Franco)
33757	Arboces|Barganaz (La Caridad)|Braña, La (El Franco)|Carroceiro|Chao Das Trabas|Penadecabras (El Franco)|Romaelle De Abajo|Villarin De La Braña
33758	Castello (El Franco)|Godella|Grandamarina|Mendones|Mercadeiros|Miudeira|Miudes|Veiral|Villar De Miudes
33759	Carbeje|Cerredo (El Franco)|Hervedeiras|Louredal (El Franco)|Ludeiros|Nenin|Prendones|Rebollada (El Franco)|Ronda, La (El Franco)|San Juan De Prendones|San Julian (El Franco)|Sueiro|Villalmarzo
33760	Castropol
33768	Becharro|Berbesa|Berruga (Castropol)|Bouza (Castropol)|Campas, Las (Castropol)|Castro (Castropol)|Cotapos|El Esquilo|Ferradal (Castropol)|La Casia|Piñera (Castropol)|Riocaliente (Castropol)|Riofelle|Salias|San Cristobal (Castropol)|Santiago (Castropol)|Seijas|Soma (Castropol)
33769	Aldeanova|Areneira|Augueira|Barreira (Castropol)|Barreiras (Castropol)|Bruiteira|Cal|El Ferrol|Fabal (Castropol)|Granda (Castropol)|Huerta (Castropol)|Iramola|Lantoira|Liso|Moldes|Payoza|Poceira|Pruida|Quintalonga|Roda, La (Castropol)|Sabugo (Castropol)|Vale|Villarrasa
33770	Vegadeo
33774	Antigua (San Tirso De Abres)|Eilale|Espasande|Fojas|Goje|Llano, El (San Tirso De Abres)|Lombal|Louredal (San Tirso Abres)|Lourido (San Tirso Abres)|Matela|Mourela|Naraido|Prado (San Tirso De Abres)|Salcido|San Andres (San Tirso De Abres)|Sobrelavega|Solmayor|Trasdacorda|Valiñaseca|Vegas, Las (San Tirso De Abres)|Vilar (San Tirso De Abres)|Vilelas
33775	Abraido|Aguillon (Taramundi)|Almallos|Arredondas|Arrojo (Taramundi)|Arruñada (Taramundi)|Barredo (Taramundi)|Bres|Cabaniñas (Taramundi)|Cabaza|Calvin (Taramundi)|Cancelos|Castro, El (Taramundi)|Chao De Leiras|Couces|Couso (Taramundi)|Entorcisa|Esquios|Fabal (Taramundi)|Folgueirosa (Taramundi)|Freije|Galiñeiros|Garda|Las Tingas|Leiras|Les|Llan|Lourido (Taramundi)|Loutima|Mazo De Bres|Mousende (Taramundi)|Navallo|Nio|Nogueira|Ouria (Taramundi)|Pardiñas|Pereira|Pereiro (Taramundi)|Piñeiro|Santa Marina (Taramundi)|Silvallana (Taramundi)|Taramundi|Teijo|Teijois|Turia|Valin (Taramundi)|Vega De La Zarza|Vega De Llan|Veigas De Turia|Vilanova (Taramundi)|Villarede
33776	Amieiros|Barcia (Santa Eulalia De Oscos)|Barranca De Paramios|Barreiras (Santa Eulalia De Oscos)|Batriban|Brañavella|Busdemouros|Busqueimado|Bustapena|Caraduje|Castromouran|Espina (Vegadeo)|Ferreira (Santa Eulalia De Oscos)|Ferreirela|Folgueiras (Vegadeo)|Gestoso (Villanueva De Oscos)|La Garganta|La Valia|Lineras (Santa Eulalia De Oscos)|Mazonovo (Santa Eulalia De Oscos)|Millarado|Monticelo|Montouto|Murias (Santa Eulalia De Oscos)|Nonide|Paramios|Pasaron|Peizais|Perulleira|Puente, El (Santa Eulalia De Oscos)|Pumares (Santa Eulalia De Oscos)|Quinta (Santa Eulalia De Oscos)|Regodeseves|Restrepo|Salgueiras|San Cristobal (Villanueva De Oscos)|San Julian (Santa Eulalia De Oscos)|Santa Eulalia De Oscos|Sarceda (Santa Eulalia De Oscos)|Souto|Sualleiro|Talladas|Teijeira (Santa Eulalia De Oscos)|Toleiras|Trapa, La (Santa Eulalia De Oscos)|Vega De Villar|Vega Del Carro|Ventoso|Vijande|Villamartin (Santa Eulalia De Oscos)|Villar (Villanueva De Oscos)
33777	Arrojina|Ascuita|Baldedo (San Martin De Oscos)|Bobia, La (Villanueva De Oscos)|Bousoño|Cimadevilla (Villanueva De Oscos)|Cotarelo|Deilan|El Cortin|Folgueirarrubia|Labiaron|Liceira|Loujedo|Martul|Mon|Morlongo|Ovellariza|Pacios (Villanueva De Oscos)|Penacoba|Perdigueiros|Piorno|Revoqueira|Rio, El (Villanueva De Oscos)|Ron|Salcedo (Villanueva De Oscos)|San Mamed|San Martin De Oscos|San Pedro De Agueira|San Pelayo (San Martin De Oscos)|Santa Eufemia (Villanueva De Oscos)|Sarceda (San Martin De Oscos)|Soutelo|Teijeira (San Martin De Oscos)|Trasmonte (San Martin De Oscos)|Travadelo|Ventosa (San Martin De Oscos)|Vilarello (Villanueva De Oscos)|Villamañe|Villamea|Villanueva De Oscos|Villarin De Piorno|Villarin De Trasmonte|Villarpille|Villarquille
33778	Agelan|Aguillon (Castropol)|Arco (Castropol)|Arguiol|Armeirin|Azoreiras|Añides|Balmonte|Barreiras (Balmonte-Castropol)|Besedo|Brañatuille|Cabana (Castropol)|Cabanada|Caborcos|Candal|Candaosa|Canedo (Castropol)|Castañeirua|Castro (Castropol-Vegadeo)|Cerolleiro|Coba, La (Vegadeo)|Cruz De Vilar|Culmieiros|Grandallana|Grandela (Castropol)|Grilo|Jonte (Castropol)|Lagar (Castropol)|Lanteiro|Lavandal|Leirio|Mazo, El (Castropol)|Monteavaro|Murolas|Niseiros|Obanza|Penzol|Pereiral|Pianton|Porqueira|Porzun|Presa (Castropol)|Presno|Pusallana|Requejo (Castropol)|Rio De Seares|Rondeira|Samagan|Santa Colomba|Santalla|Seares|Tabes|Tomentosa|Trio|Valin (Castropol)|Vega De Los Molinos|Vega Del Torno|Vilar|Vilavedelle|Villameitide|Villar (Castropol)|Villarin (Castropol)|Vior
33779	Abres|Chao De Porzun|Couso (Castropol)|Estelo|Fuente Louteiro|Grandela (San Tirso De Abres)|Guiar|La Graña|La Pumarega|Lamisqueira|Louterio|Meredo|Miou|Molejon|Murias (Castropol)|Nafarea|Posadoiro (Santa Eulalia De Oscos)|Quintela|Refojos|Seladaloura|Soladaloura|Vinjoy
33780	Anguilero|Bahiñas|Balsera|Brañaverniza|Busmarzo|Enverniego (Trevias)|Gallinero De Arcallana|Gamones|Malata|Ribon|Tablizo|Trevias|Villanueva (Trevias)|Villar De Bahiñas
33782	Alienes|Ayones (Luarca)|Biescas (Luarca)|Castañedo (Luarca)|Castro (Castañedo-Luarca)|Colinas|Corros, Los (Luarca)|Faeo (Luarca)|Pereda|Turuelles|Villar De Ayones
33783	Adrado|Cortina|Lago|Llaneces (Luarca)|Llendecastiello|Ore|Pena (Luarca)|Pescaredo|Pontigon, El (Luarca)|San Pelayo De Tahona|Silvamayor|Valle|Villagermonde
33784	Argumosin|Arquillina|Brieves|Capiello, El (Luarca)|Carcedo (Brieves)|Espiniella (Brieves)|Faedal (Brieves)|Ferrera De Los Gavitos|La Cadorna|Muñas De Abajo|Muñas De Arriba|Villar De Carcedo
33785	Aguera|Arcallana|Brañarronda|Bustiello De Paredes|El Pueblo|Foyedo|Gamatosa|La Candanosa|La Longa|La Mortera|Las Cruces|Las Longas|Las Murias|Lendepeña|Longrey|Los Pontones|Los Rozos|Mafalla|Meras|Mones|Ocinera|Ovienes|Paredes|Quintana (Luarca)|San Feliz|San Pedro De Paredes|Villarin
33786	Cueva (Luarca)
33787	Aldin|Argumoso|Barcia (Luarca)|Canero|Carlangas|Caroyas|Casiellas|Chano De Canero|El Cabanin|Fijuecas|Fontoria|Mouruso|Ranon|Sapinas
33788	Cadavedo|Villademoros
33789	Busto (Luarca)|Queruas|San Cristobal (Luarca)
33790	Puerto De Vega|Santa Marina (Puerto Vega)|Soirana|Vega De Cima|Vigo
33791	Albarde|C'Alcabo|Caxos|Constancios|Corripia|El Vallin|Godon|Grandavil|Herreria De Abajo|La Ronda|Moanes|Otero|Pontigas|Ribadebajo|Ribadecima|San Justo (Villuir - Luarca)|San Martin|Santiago|Setienes|Taborcias|Valtravieso|Vistalegre (Villuir-Luarca)
33792	Arnizo (Otur)|Artosa (Otur)|Boronas|Busantianes|Caborno|Canedo (Otur)|Las Hervedosas|Otur|Sabugo (Otur)|Vidural (Navia)
33793	Bao Y Barayo|Tox|Villapedre
33794	Acebreiral|Acevedin|Barres|Barrionuevo|Boudois|Bourio|Brañela (Grandas Salime)|Brañuela, La (Tapia)|Brul|Buenavista (Tapia)|Cabaleiros (Castropol)|Campon (Barres)|Carretera (Barres)|Casa De La Granda|Donlebun|Figueras (Castropol)|Fuente (Barres)|Granda (Figueras)|Grandela (Tapia)|Lamelas|Linera, La (Castropol)|Lois|Magosteiras|Navalin (Castropol)|Oubias|Outeiro (Barres)|Pedras|Penadecabras (Tapia)|Penarronda|Reboledo|Riocabo|Rozadela|Rubieira|Salcedo (Barres)|San Roman (Castropol)|Texo De Lois|Tol|Tombin, El (Barres-Castropol)|Tombin, El (Tol-Castropol)|Villadun|Villarviejo (Barres)|Villasibil|Viña (Barres)
33795	Astas|Bustabernego|Carbon|Cerejedo|Coaña|Cruces, Las (Coaña)|Llosoiro|Mestas, Las (Coaña)|Nadou|San Esteban (Coaña)|Sarriou|Valentin (Coaña)|Villar (Coaña)|Villar (Trelles-Coaña)
33796	Busnovo|Estelleiro|Porto|Ronda, La (Coaña)|Tarrebarre|Villacondide|Villarda
33798	Miñagon
33799	Los Mazos|Riomayor (Boal)|Rodela|Viñas, Las (Boal)
33800	Cangas De Narcea|Pinar
33810	Alguerdo|Andeo|Arandojo|Barca (Ibias)|Boiro|Busante|Buso|Bustelin|Bustelo (Ibias)|Busto (San Antolin De Ibias)|Cadagayoso|Caldevilla De Ibias|Carbueiro|Castaosa|Cuantas|Dou|Ferreira (Ibias)|Folgoso|Folgueiras De Avioga|Folgueiras De Boiro|Folgueiras De Cotos|Fondodevilla|Fresno (Ibias)|La Lagua|Lagueiro|Linares (Ibias)|Luiña (Ibias)|Montillo|Morentan|Muria, La (Ibias)|Omente|Parada (Ibias)|Pelliceira|Peneda|Penedela|Piñeira (Ibias)|Pousadoiro (Ibias)|Pradias|Rellan (Ibias)|Salvador|San Antolin De Ibias|San Clemente (Ibias)|San Esteban (Ibias)|Santa Comba (Ibias)|Santiso|Sena|Seroiro|Sierra, La (Ibias)|Torga|Uria (Seroiro)|Valdeferreiros|Valvaler|Vilarello (Ibias)|Villamayor (Ibias)|Villarcebollin|Villardecendias|Villaselande|Viñal
33811	Caldevilla De Rengos|Cecos|Centenales|Eiros, Los (Cangas De Narcea)|Gedrez|Gillon|Jalon|La Cuitada|La Muriella|Marcellana|Marentes|Mergulleira|Moal|Monasterio De Hermo|Noceda De Rengos|Oballo|Piedrafita (Cangas De Narcea)|Posada De Rengos|Riodeporcos|Riotorno (Cangas De Narcea)|San Martin De Eiros|Valdebueyes|Vega Del Tallo|Ventanueva (Cangas De Narcea)|Vidal|Villajane|Villar De Posada
33812	Bao (Ibias)|Cerredo (Degaña)|Degaña|Llanelo|Prohida (Degaña)|Rebollar (Degaña)|Sisterna|Tablado (Degaña)|Taladrid|Tormaleo|Villaoril (Ibias)|Villares De Abajo|Villares De Arriba|Villarin (Ibias)|Villarmeirin
33813	Adrales|Aguera De Castañedo|Alto De Santarbas|Arayon|Arbolente|Berguño|Castañedo (Cangas De Narcea)|Cibuyo|Combarro|Cruces (Cangas De Narcea)|Cueras|Folguerua (Cangas De Narcea)|Fondos De Vega|Fraguas|Larna|Laron|Llano (Cangas De Narcea)|Monco (Cangas De Narcea)|Otas|Pandiello (Cangas De Narcea)|Pescal, La (Cangas Narcea)|Pladano|Pueblo De Rengos|Saburcio|San Esteban (Cangas De Narcea)|Santa Eulalia (Cangas De Narcea)|Sestorraso|Sierra De Castañedo|Soto De Cibuyo|Tarano (Cangas De Narcea)|Vega De Castro|Vega De Rengos|Viliella
33814	Abanceña|Acio|Aguera De Coto|Bergame|Cadaleito|Caldevilla De Acio|Casares (Cangas De Narcea)|Cerveriz|Ciella|Combo|Escrita, La (Cangas De Narcea)|La Artosa|Llanos, Los (Cangas De Narcea)|Luberio|Monasterio Del Coto|Penles|Perandones|Peñas (Cangas De Narcea)|Rato|Rebollas|Regla De Perandones|San Damias (Cangas De Narcea)|Santiago De Peñas|Sevil|Soto De Los Molinos|Trasmonte De Abajo|Trasmonte De Arriba|Tremado De Coto|Vega De Pope|Vegalagar|Vegaperpera|Villar De Bergame|Viso, El (Cangas De Narcea)|Yema
33815	Araniego|Besullo|Carcedo De Lomes|Cerecedo (Cangas De Narcea)|Comba (Allande)|Cubopuerto|Defradas De Las Montañas|Faedo (Cangas De Narcea)|Faidiel|Forniellas (Allande)|Fuentes De Besullo|Fuentes De Las Montañas|Iboyo|Irrondo De Besullo|Las Avelleras|Leiron|Lorante|Noceda (Allande)|Olgo|Otriello|Parajas (Cangas De Narcea)|Parajas (Pola De Allande)|Posada De Besullo|Pumar De Las Montañas|San Felix De Montañas|San Pedro De Montañas|San Romano|Sanabuega|Santa Ana (Cangas De Narcea)|Selce|Trones
33816	Anderve|Antrago|Barcena (Cangas De Narcea)|Becerrales|Braña De Ordial, La (Jarceley-Narcea)|Bruelles|Cadrijuela|Carballedo (Cangas De Narcea)|Castañal (Cangas De Narcea)|Cierades|Coliema (San Pedro)|Corias (Cangas De Narcea)|Dagueño|Fontaniella (Cangas De Narcea)|Jarceley|Javita|La Bubia|La Veguilla|Llamas De Mouro|Luarnes|Mendiello|Mieldes|Nando|Onon (Cangas De Narcea)|Ordial|Ordiales (Cangas De Narcea)|Ovilley|Pambley|Parrondo|Portiella (Cangas De Narcea)|Puente Del Infierno|Retuertas|Robledo De Biforco|San Martin De Sierra|San Pedro De Coliema|San Pedro De Corias|Santiago De Sierra|Sotiello (Cangas De Narcea)|Tabladiello (Cangas De Narcea)|Tandes|Tebongo|Valcabo|Valleciello|Villadestre|Villaoril De La Sierra|Villardelantero
33817	Ardaliz|Barzaniellas|Carballo|Castro De Limes|Cibea|Cobos|Corbero (Cangas De Narcea)|Cuadriellas De Villalaez|Fonceca|Fondos De Villa (Cangas De Narcea)|Fuentes Corbero|Genestoso|La Himera|Limes|Llamera (Cangas De Narcea)|Mestas, Las (Cangas De Narcea)|Moral (Cangas De Narcea)|Morzo|Pedrueño|Pejan|Piñera, La (Cangas De Narcea)|Ponton (Cangas De Narcea)|Puenticiella|Regla De Cibea|Reguera De Cabo|Siero (Cangas Del Narcea)|Sonande|Sorrodiles|Tiendas, Las (Cangas De Narcea)|Tremado De Carballo|Valmayor|Villalaez|Villar De Los Indianos|Villarin De Cibea|Villarino De Limes|Villarmental|Villategil
33818	Arbas (San Julian)|Arbas (San Pedro)|Bimeda|Brañas De Abajo|Brañas De Arriba|Bustiello (Cangas De Narcea)|Caldevilla De Arbas|Corros (Cangas De Narcea)|Folgueraju|Fonda, La (Cangas De Narcea)|Gelan|La Chabola De Vallado|La Farruquita|La Linde|La Pachalina|Labayos (Cangas De Narcea)|Ladredo (Cangas De Narcea)|Leitariegos|Lindota|Mata, La (Cangas De Narcea)|Miravalles (Cangas De Narcea)|Murias De Puntaras|Naviego|Otardeju|Otero, El (Cangas De Narcea)|Palacio De Naviego|Penellada|Puntaras|Regla De Naviego|Riomolin|Rubial (Cangas De Narcea)|San Juan Del Monte|San Julian De Arbas|San Martin De Bimeda|San Pedro De Arbas|Socarral|Tablado De Villacibran|Trascastro|Vallado|Valle De Los Humeros|Valle, El (Cangas De Narcea)|Vega De Horreo|Vega De Rey (Cangas De Narcea)|Vegameoro|Villacanes|Villacibran|Villager|Villajur|Villaoril De Bimeda|Villar De Bimeda|Villar De Naviego|Viña, La (Cangas De Narcea)
33819	Amago|Ambres|Barnedo|Biescas (Cangas De Narcea)|Bornazal|Borracan|Braña De San Cristobal, La (Cangas De Narcea)|Brañamena (Cangas De Narcea)|Carceda (Cangas De Narcea)|Castiello (Cangas De Narcea)|Castilmoure|Castro De La Sierra|Castrosin|Cerame|Cerezaliz|Cogolla, La (Cangas De Narcea)|Cuadriella De Ambres|Curriellos (Cangas De Narcea)|Defradas De Ambres|El Cabanal|Folgueras (Cangas De Narcea)|Irrondo De La Folguera|Las Escolinas|Linares De Acebo|Llamas De Ambasaguas|Llanos De Tainas|Los Tablados|Medeo|Nisal (Cangas De Narcea)|Obanca|Parada La Nueva|Parada La Vieja|Porciles (Cangas De Narcea)|Porley|Rañeces De San Cristobal|Rañeces De Sierra|Ridera|Robledo De San Cristobal|Robledo De Tainas|Rocabo|Santa Maria De Obanca|Santianes (Cangas De Narcea)|Sillaso|Soucedo|Tainas|Vallinas (Cangas De Narcea)|Vecil|Villajimada|Villalar|Villanueva (Cangas De Narcea)|Villar De Adrales
33820	Borbolla, La (Grado)|Grado
33825	Alcubiella|Ballongo|Bascones|Baselgas|Bayo (Grado)|Belandres (Grado)|Borondes|Caleya (Grado)|Campo Del Valle|Carbayin (Grado)|Casucas, Las (Grado)|Corradas, Las (Grado)|Corredoria, La (Grado)|Cueto (Grado)|Doro|El Merin De Abajo|El Merin De Arriba|Entre Los Rios|Entre, La Iglesia|Entrelafuente|Espina, La (Grado)|Espriella|Ferreras (La Mata)|Fuejo (Grado)|Javier|La Cay|La Zurraquera|Mata, La (Grado)|Medio, El (Grado)|Nalio|Nores|Palacio (Grado)|Pedrero|Picalgallo|Pozanco|Prioto|Rebollal (Grado)|Reguero, El (Grado)|Riviellas (Grado)|Rodaco|Sama De Grado|Santo Dolfo|Trsmuria|Vega, La (Grado)|Xorro
33826	Ambas (Grado)|Arellanes|Barzana (Grado)|Calea, La (Grado)|Cortes, Las (Grado)|Cubia|Fojo|Formiguera (Grado)|La Vega De Villaldin|Las Corujas|Llamas (Grado)|Llanon, El (Grado)|Momalo|Noceda (Grado)|Panicera|Regueral, El (Grado)|Retiro, El (Grado)|Robledo (Grado)|Rodiles (Grado)|Rubiano|San Miguel De Tejedo|San Pedro De Los Burros|Santianes De Molenes|Sorribas (Grado)|Tablado (Grado)|Tameza|Tejedo|Tolinas (Grado)|Trillapeña|Vendilles|Villabre|Villagarcia|Villaldin|Villamarin De Salcedo|Villaruiz (Tameza)|Villas, Las (Grado)|Yernes
33827	Aguera De Salcedo|Barreiros, Los (Grado)|Cabaña, La (Grado)|Cabañin, El (Grado)|Cañedo (Grado)|El Caliente|Hispanes|La Fueja|Lobio|Los Lodos|Moutas|Pereda (Grado)|Puente De Seaza|Restiello|Rozallana|Santa Cristina (Grado)|Santa Maria De Villandas|Seaza|Vega De Restiello|Vigaña|Villaizoy|Villandas|Villanueva (Grado)|Vio De Pedrouco|Vio Del Pico
33828	Aces De Candamo|Barrioazul|Bustiello (Grado)|Cadenado|Campo Del Cura|Casas De Abajo (Grado)|Castañedo (Grado)|El Bravuco|El Terrero|Espinosa|Fabariego (Grado)|Fenolleda|Ferreras (Candamo)|Fojaca|Fojaca, La (Grado)|Fontebona|Gorrion|Las Parrucas|Llavayos|Los Canales|Matiega|Molinos De Agosto|Morana|Mortera, La (Candamo)|Otero (Candamo)|Picaroso|Portiella, La (Grado)|Prahua (Candamo)|Quintana|Ricabo (Candamo)|San Roman De Candamo|San Tirso De Candamo|Sandiche|Santa Eulalia (Candamo)|Santoseso|Torno (Grado)|Valdemora (Candamo)|Valle De Candamo|Villa (Candamo)|Villamarin De Candamo|Villanueva De Candamo|Vistalegre (Grado)
33829	Acebedo (Grado)|Aguera De Candamo|Alvare (Grado)|Anzo (Grado)|Argañosa|Asniella|Barraca (Grado)|Bohiles|Bondeyo|Cabruñana|Caleyo, El (Candamo)|Campamojada|Campillin|Candamin|Caridad, La (Grado)|Casas Del Monte (Grado)|Coalla|Coallaju|Cuero|El Monte Llamero|Faces (Candamo)|Faedo (Candamo)|Ferreros (Candamo)|Figal, La (Grado)|Figaredo De Candamo|Fornos, Los (Grado)|Fresno, El (Grado)|Fuejo (Salas)|Grullos|Gurulles|La Garaba|La Linar|La Llamiella|La Roñada|La Tejera|La Tronca|Las Carquivas|Las Pandiellas|Llamero|Llanos, Los (El Fresno-Grado)|Llantrales|Loredo (Grado)|Macetes, Les|Mafalla (Candamo)|Murias De Candamo|Murias, Las (Grado)|Novales, Los (Grado)|Paciones|Pando (Grado)|Panizal|Peñaflor|Puente De Peñaflor|Pumarin (Grado)|Rañeces (Grado)|Rebollada (Salas)|Rebollada, La (Candamo)|Reconco (Grado)|Reigada, La (Candamo)|Rellan (Grado)|Reznera|Rozadas (Grado)|San Juan De Villapañada|San Martin De Gurulles|San Pelayo (Grado)|San Pelayo De Sienra|Sestiello|Somines|Tablado (Candamo)|Temia|Valles, Los (Candamo)|Vega De Peridiello|Ventosa (Candamo)|Villar (Grado)|Villar De Candamo
33830	Belmonte
33836	Abango|Alcedo (Belmonte)|Antoñana|Balbona (Belmonte)|Begega|Boinas|Carricedo|Estilleiro|Ferredal, El (Belmonte)|Las Estacas|Millara|Pontigo (Belmonte)|Quintana (Belmonte)|Santa Marina (Belmonte)|Valle De Begega|Vega De Quintana|Villar De Tejon|Villaverde (Belmonte)
33837	Alvariza|Cezana|Corias De Abajo|Corias De Arriba|Dorera|Fresnedo (Belmonte)|Pascual (Blamonte)|Posadoiro (Belmonte)
33838	Cruces, Las (Belmonte)|Dolia|Faedo (Belmonte)|Faidiello (Belmonte)|La Casa El Sol|Los Bazales|Meruja|Repenerencia|Tablado (Belmonte)|Tiblos|Vigaña De Arcello
33839	Llamoso|Montovo|Ondes|San Martin De Ondes
33840	Aguino|Arbellales (Somiedo)|Caunedo (Somiedo)|Coto, El (Somiedo)|Endriga|Falguera|Gua|Llamardal|Llamera, La (Somiedo)|Peral, La (Somiedo)|Perlunes|Pola De Somiedo|Puerto (Somiedo)|Saliencia|Urria (P. Somiedo)|Valle De Lago|Veigas|Villarin (Somiedo)
33841	Bustariega|Castro (Somiedo)|Clavillas|La Riera De Somiedo|Las Morteras|Orderias (Somiedo)|Pineda|Santiago De Hermo|Valcarcel|Villamor|Villaux|Viñas, Las (Somiedo)
33842	Aguasmestas|Cores|Pigueces|Pigueña|Rebollada (Somiedo)|Robledo (Somiedo)|Santullano (Somiedo)|Villar De Vildas
33843	Almurfe|Cuevas (Belmonte)
33844	Abedul (Belmonte)|Aguera (Belmonte)|Aguerina|Arena, La (Belmonte)|Castañera (Belmonte)|Ciguedres|Ferreiria (Belmonte)|Quintanal (Belmonte)|Rozos|San Esteban (Belmonte)|Villar De Zuepos
33845	Bello (Belmonte)|Leiguarda|Menes|Modreros (Belmonte)|Pando (Belmonte)|Selviella
33846	Barcena De Alava|Fontoria (Belmonte)|Oviñaña (Belmonte)|San Cristobal (Belmonte)|San Martin De Lodon|Villanueva (Belmonte)
33850	Candanonegro|Cornellana (Salas)|Fajas|Folguerinas|Fresnedo (Cornellana)|Las Nisales|Santueñina (Cornellana)|Verdugos
33857	Bulse|Castiello (Salas)|Cotariello (Cornellana)|Doriga (San Esteban-Salas)|Eiros (Cornellana)|La Rodriga|Reconco (Cornellana)|San Esteban (Cornellana)|San Justo De Doriga|Villar (Cornellana)
33858	Barrudo|Casas Del Puente|Doriga (San Antonio-Salas)|Doriga (Santa Eulalia - Salas)|Loreda|Marcelo|Moratin (Cornellana)|Rubial (Doriga - Salas)|San Antolin (Cornellana)|San Marcelo
33859	Ballota (Cornellana)|Borreras|Cermoño|Cortes (Cornellana)|La Planadera|Nava (Cornellana)|Ovanes|Quintoños|Rondero|Santa Eufemia (Cornellana)|Sobrerriba|Valbona (Cornellana)
33860	Salas
33865	Alava|Barcena (Salas)|Castañedo De Miranda|Cutiellos (Belmonte)|Hospital, El (Belmonte)|Laneo|Longoria|Lorero|Pumarada|Requejo (Salas)|Rubial (Santiago De La Barca-Salas)|San Bartolome De Miranda|Santiago De La Barca
33866	Acevedo (Salas)|Barraca (Salas)|Borducedo|Brañaivente|Candano, El (Salas)|Cerezal (Salas)|Curiscado|Folguerosa (Salas)|Gallinero (Salas)|Granja, La (Salas)|Lindemurias|Malleza|Montenuevo|Pumar, El (Salas)|Rubieros|San Andres (Salas)|San Cristobal (Salas)|Vegacebron|Villarin (Malleza)
33867	Arquera, La (Salas)|Barrio, El (Salas)|Caborno (Salas)|Caleyo, El (Salas)|Campas (Salas)|Camuño|Carbajal (Salas)|Cardus|Casamayor (Salas)|Casona, La (Salas)|Corradas, Las (Salas)|Daner|El Alba|El Pozo|Escobio (Salas)|Estrada, La (Salas)|Fenigonte|Folgueiro (Salas)|Las Centiniegas|Linares (Salas)|Mallecina|Mouruso (Salas)|Peral, La (Salas)|Peña, La (Salas)|Piniella (Salas)|Prada (Salas)|Priero|Puerta, La (Salas)|Santullano (Salas)|Tarano (Salas)|Toral (Salas)|Valderrodero|Viesca, La (Salas)|Villarin (Salas)
33868	Aciana|Allence (Salas)|Arrojo (Salas)|Casazorrina|Espinedo (Salas)|Festiella|Figares (Salas)|Fontanal|La Calzada|Llamas (Salas)|Loris|Monte, El (Salas)|Monteagudo (Salas)|Poles|Quintana (Salas)|Rabadiello|Sala, La (Salas)|San Martin (Salas)|San Vicente (Salas)|Villacarisme|Villamar De Abajo|Villamar De Arriba|Villampero|Villarraba|Villazon
33869	Ablaneda (Salas)|Arbodas|Barrosa, La (Salas)|Carles|Godan|Mallecin|Otero (Salas)|Pereras|Pevidal, El (Salas|Piñedo|Soto De Los Infantes|Vega De Los Peredos|Vega, La (Salas)|Venta, La (Salas)|Viescas (Salas)
33870	Braña, La (Tineo)|Buenavista (Tineo)|Ocio|Tineo
33873	Atalaya (Tineo)|Barreiro (Tineo)|Barzanallana|Bullacente|Burgazal|Bustellin|Calabazos|Calleras|Carrizal (Tineo)|Cerezal De Rellanos|Coldobredo|Conto|Ese De Calleras|Folgueras De Muñalen|Foyedo (Navelgas-Tineo)|Foz (Tineo)|Fresnedo (Tineo)|Fuentes (Tineo)|La Fanar|Leirosa|Llaneces De Rellanos|Morados|Muñalen|Navelgas|Parada (Tineo)|Paradiella|Peral, La (Tineo)|Rebollada (Navelgas-Tineo)|Rellanos|Relloso (Navelgas-Tineo)|Sabadell De Navelgas|Tejedal (Tineo)|Tejera, La (Navelgas-Tineo)|Vallinaferrera|Vega De Muñalen|Venta De Aquilino|Villar De Navelgas|Zardain
33874	Arcillero|Aristebano|Barcena Del Monasterio|Berrugoso|Busiñan|Bustellon|Cabuerna|Candanedo (Naraval)|Carbajal (Tineo)|Cebedal, La (Tineo)|Cerecedo De Cabuerna|Cerezal De Tablado|Collada (Tineo)|Cornas|Cuestalonga|Escarden|Ese De San Vicente|Fajera, La (Tineo)|Folgueras De Cornas|Folgueras Del Rio|Francos (Tineo)|Genestosa|Hervederas|La Fanosa|La Rebollosa|La Vinada|Lantero (Tineo)|Luciernas|Miño|Monterizo|Murias (Tineo)|Naraval|Nera|Noron|Obona|Olleros|Ordial De Miño|Paniceros|Piedrafita (Tineo)|Piedralonga|Piedratecha|Prado (Tineo)|Recorba|Rellon (Tineo)|Riocastiello|Riviella (Tineo)|San Andres (Tineo)|San Fructuoso|San Martin De Forcayado|San Pedro De Barcena|San Salvador (Tineo)|Santa Eulalia De Miño|Silvallana (Tineo)|Tablado De Riviella|Tablado Del Rio|Tarantiellos|Tiendas, Las (Tineo)|Tremado (Tineo)|Trespando|Valle De Tablado|Venta Arcadio|Venta Del Aire (Tineo)|Venta El Pagano|Venta Quildan|Villapro|Villarino Del Rio|Villatriz
33875	Ablaneda (Tineo)|Agoveda|Aguera De Carriles|Albar|Ansaras|Arganza|Armayan|Arroyo (Tineo)|Barzana (Tineo)|Barzanicas|Berdules|Cabañas (Tineo)|Cachorrero|Campo De Sobrado (Tineo)|Carcediel|Carriles (Tineo)|Cerviago|Cortina (Tineo)|Eiros, Los (Tineo)|El Peligro|Fenolledo|Gera|Lago (Tineo)|Llama, La (Tineo)|Magarin|Mallayo|Mirallo De Abajo|Mirallo De Arriba|Pena (Tineo)|Pendosen|Perluces|Piñera De San Felix|Pozon (Tineo)|Quintaniella (Tineo)|Rozadiella (Tineo)|San Antonio De Relamiego|San Esteban De Relamiego|San Facundo|San Felix (Tineo)|San Martin De Semproniana|Santa Marina (Tineo)|Santueña (Tineo)|Santullano (Tineo)|Semellon De Abajo|Semellon De Arriba|Sobrado|Socarrera|Tamallanes|Tejero|Valentin (Tineo)|Vallecueva|Valles De Teso|Villacin|Villafronte|Villameana (Tineo)|Villar De Sapos (Tineo)|Villarmou|Villarpadrid|Vivente
33876	Aguera De La Barca|Areñes (Tineo)|Argancinas (Tineo)|Azorera|Bebares|Berzana|Bombeao|Brañueta (Tineo)|Buseiro|Campas, Las (Tineo)|Casares (Tineo)|Castañedo (Tineo)|Castañera (Tineo)|Castiello (Tineo)|Castiello De La Barca|Cetrales|Combarcio|Corniella|El Rodical|Espinaredo (Tineo)|Florida, La (Tineo)|Forcon (Tineo)|Fresno De Genestaza|Genestaza|La Oteda|La Troncada|Merilles|Pilotuerto|Posada (Tineo)|Prohida, La (Tineo)|Puente Tuña|Puentecastro|Requejo (Tineo)|San Adriano (Tineo)|San Vicente (Tineo)|Santa Marta|Santianes (Tineo)|Silva (Tineo)|Solanos|Sorriba|Soto De La Barca|Torayo|Tornos, Los (Tineo)|Tueres|Tuña|Valserondo|Villanueva De Sorriba
33877	Bedures|Brañalonga|Busllon|Buspaulin|Cezures|Couto|El Crucero|Espin, El (Tineo)|Faedo (Tineo)|Millariega|Modreiros|Monteoscuro|Ondinas|Pedregal (Tineo)|Pereda, La (Tineo)|Pontigas, Las (Tineo)|Santa Eulalia De Tineo|Sebran|Tejera, La (El Crucero - Tineo)|Trapa, La (Tineo)|Truebano (Tineo)|Valdarieme|Valle, El (El Crucero - Tineo)|Valsoredo|Villanueva De Rañadoiro|Zarrazin
33878	Anzas|Besapie|Borres|Bustiello De Cabuerna|Campiello (Tineo)|Cerecedo Del Monte|Colinas De Abajo|Colinas De Arriba|Corcolina|Cueta, La (Tineo)|Curriellos (Tineo)|Espin De Sangonedo|Fayona, La (Tineo)|Fontalba|Fresno (Tineo)|Huergola|Laniello|Lavadoira|Lavandera (Tineo)|Mortera, La (Tineo)|Orderias (Tineo)|Orrea|Pelontre|Pereda De Sangoñedo|Porciles (Tineo)|Robledo De Obona|Sabadell De Troncedo|Samblismo|Sangoñedo|Troncedo (Tineo)|Valmorisco|Vega De Rey (Tineo)|Villajulian|Villaluz|Villerino Del Monte
33879	Baradal|Barredo (Tineo)|Busmartin|Busmeon|Bustellan|Bustoburniego|Campo Caldera|Casilla, La (Tineo)|Cruces, Las (Tineo)|Faedal (Tineo)|Fastias|Folguerua (Tineo)|Fondal (Tineo)|Fuejo (Tineo)|Grandamuelle|Las Colladas|Las Tabiernas|Llaneces De Calleras|Llaneces De La Barca|Llaneza La (Tineo)|Llanoriego|Los Cepones|Mañores|Montelloso|Nieres|Ordial De La Barca|Pandiello (Tineo)|Peñacabranes|Peñafolgueros|Piñera De Barredo|Ponte (Tineo)|Pontones, Los (Tineo)|Rio Villar|Rubiera, La (Tineo)|San Roque (Tineo)|Santiago De Cerredo|Trabazo|Uz, La (Tineo)|Vallamonte|Veneiro|Villabona (Tineo)|Villacabrera|Villatresmil|Yerbo
33880	Pola De Allande
33885	Buslabin|Ema|Fresnedo (San Emiliano)|Murias (Pola De Allande)|Quintana, La (Pola De Allande)|San Emiliano|Valle (Pola De Allande)|Vallinas (Pola De Allande)|Villadecabo
33886	Armenande|Carcedo De Lago|Lago (Allande)|Santa Maria De Lago|Villar De Castanedo|Villardejusto
33887	Aguanes|Baldedo (Pola Allande)|Barras|Berducedo|Buspol (Grandas De Salime)|Bustarel|Busvidal|Castello (Pola De Allande)|Castro, El (Allande)|Coba (P. Allande)|Collada (P. Allande)|Cornollo|Corondeño|El Engertal|El Provo|Fonteta|Grandera, La (Pola De Allende)|La Figuerina|La Furada|La Mesa|Los Toucedos|Paradas|Robledo (Pola De Allande)|Rubieiro|Salcedo (P. Allande)|San Martin De Valledor|San Salvador De Valledor|Teijedo (Pola De Allande)|Trabaces|Trapa (P. Allande)|Trellopico|Tremado (P. Allende)|Valia Mayor|Villalain|Villanueva (Pola De Allande)|Villar De Buspol|Villarpedre|Villasonte
33888	Arbeyales (Pola De Allande)|Bendon|Beveraso|Bojo|Bustantigo|Bustel|Caleyo, El (Santa Coloma)|Castanedo (Pola De Allande)|Is|La Folgueriza|La Porquera|Llaneces (Pola De Allande)|Meres (Pola De Allande)|Monon|Montefurado|Muriellos (Pola De Allande)|Penouta (Pola De Allande)|Plantao, El (Pola De Allande)|Puentenueva|Rebollo, El (Pola De Allande)|San Pedro (Pola De Allande)|Santa Coloma (Pola De Allande)|Sellon, El (Pola De Allande)
33889	Cabral|Caleyo (Pola De Allande)|Carballedo (Pola De Allande)|Celon|Cereceda (Pola De Allande)|Cimadevilla (Pola De Allande)|Colobredo|El Mazo|Ferroy|Figueras (Pola De Allande)|Fresnedo (Santa Coloma)|Penablanca|Peñaseita|Piniella (Pola De Allande)|Prada (Pola De Allande)|Pradiella|Reigada, La (Pola De Allande)|Riovena|Santa Eulalia (Pola De Allande)|Santullano (Pola De Allande)|Tamuño|Valbona (Pola De Allande)|Vallinadosa|Villafrontu|Villagrufe|Villavaser
33890	Abaniella|Almoño|Argancinas (Pola Allande)|Arganzua|Lantigo|Linares (P.Allande)|Lomes|Moure|Otero, El (P.Allende)|Peruyeda|Presnas (P.Allande)|Puente De Linares|Pumar (Pola De Allande)|Rozas (Cangas Del Narcea)|San Martin De Beduledo|Taralle|Vega De Truelles|Villar De Sapos (P. Allande)|Villaverde (Pola De Allande)
33891	Ablanedo (Salas)|Acebal, La (Espina)|Ardesaldo|Barracas|Bodenaya|Brañameana (Salas)|Brañasivil|Buscabrero|Buspol (La Espina)|Bustoto|Candano, El (La Espina)|Casandresin|Castro, El (Salas)|Cotariello (Las Rubias)|Couz, El (La Espina)|Cueva (La Espina)|Curriquera, La (Pueblo)|Espina, La (Salas)|Faedo (Salas)|Fontanos|Idarga|La Borra|La Bouga|La Colniella|La Cuerva|La Curriquera|Las Gallinas|Las Rubias|Lavio|Llanon, El (Caserio)|Oves|Pende|Peña, La (La Espina)|Peñallonga|Porciles (La Espina)|Posadoiro (La Espina)|Rañadoiro|Socolinas|Villarmor
33892	Barredo (Vega De Anzo)|Castaños|Cima De Grado|Corros (Vega De Anzo)|Fozante|La Caborna|Llera (Vega De Anzo)|Sobrevega|Vega De Anzo
33900	Ciaño|Llanu, El (Langreo)|Sama De Langreo|San Roque (Langreo)
33909	Artosa (Langreo)|Cabañin (Langreo)|Cabaños|Cabo, El (Mieres)|Cadavio|Caleya, La (Langreo)|Campa, La (Ciaño-Langreo)|Canga, La (Langreo)|Cantera, La (Langreo)|Cantu Trechuru|Carabin|Cardiñuezo|Carril, El (Langreo)|Casa Abajo|Casa Del Medio (Ciañ0-Langreo)|Casielles (Langreo)|Casona, La (Ciaño-Langreo)|Casuca, La (Langreo)|Cau, El (Langreso)|Caufel (Lada-Langreo)|Centenal (Langreo)|Ceposa, La (Langreo)|Corralon (Langreo)|Corros (Langreo)|Cuesta La Viña|Cuestadarcu|Cuestas, Las (Langreo)|Cuetos (Langreo)|El Maderal|El Tunel|Escobal, El (Langreo)|Felgueroso|Fresneal, El (Langreo)|Fresnosa (Langreo)|Güeria, La (Sama-Langreo)|L'Arma|La Inverniza|La Xuga|Las Casucas|Llanes, Les (Langreo)|Los Cuarteles De La Güeria|Los Tablones|Moquina|Mosquitera, La (Langreo)|Nadal|Navaliegu, El (Langreo)|Nueva, La (Langreo)|Omedines (Langreo)|Otones|Pampiedra|Paniciri|Payega (Langreo)|Perallonga|Pevidal, El (Ciaño-Langreo)|Peña, La (Langreo)|Peñaotiello|Peñas (Langreo)|Posadoiro (Langreo)|Poya|Pozobal|Pradon, El (Langreo)|Puente Humero|Pumaron|Raposa La (Sama-Langreo)|Rebollo, El (Langreo)|Roiles (Langreo)|Rondera|Ronderina|Roza, La (Langreo)|Sexto Piso De Carbones|Sienra (Langreo)|Tejera, La (Langreo)|Tendeyon|Texuca (Langreo)|Traba, La (Ciaño-Langreo)|Trechorio (Langreo)|Valle, El (Sama-Langreo)|Valles, Los (Langreo)|Vallina, La (Ciaño-Langreo)|Viesques (Ciaño-Langreo)|Zorera, La (Ciaño-Langreo)
33910	Alperi|Aviño|Braña (Tudela Veguin)|Cabornio (T.Veguin)|Cueva, La (T.Veguin)|Pandiella (T.Veguin)|Paranza, La (Siero)|Presa, La (T. Veguin)|Quintanas, Las (T. Veguin)|Rozas, Las (T. Veguin)|Tudela Veguin|Valle, El (T. Veguin)|Veguin
33912	Los Tableros
33919	Abedul (Oviedo)|Anieves|Argollanes|Argumal|Cabaña, La (T. Veguin)|Campo, El (T. Veguin)|Carcaba, La (Soto De Ribera)|Cortina (T.Veguin)|Entrepeñas (T. Veguin)|La Grandota|Llana, La (T.Veguin)|Llaneza (T.Veguin)|Llano Del Rio|Molino, El (T. Veguin)|Naves (T. Veguin)|Quintaniella (T.Veguin)|San Pedro De Naves|Santa Eulalia De Manzaneda|Sotiello (T. Veguin)|Tudela De Agueria
33920	Bobia, La (Langreo)|Cabaña, La (Riaño-Langreo)|Campones, Los (Langreo)|Cataldonce|Collado, El (Barros, Langreo)|L'Acebal (Langreo)|Llodero (Langreo)|Pedrazos (Barros - Langreo)|Pevidal (Barros-Langreo)|Piqera, La (Langreo)|Riaño (Langreo)|Riera, La (Langreo)|Rionda (Langreo)|Terronero|Viesques (Riaño-Langreo)|Villa (Langreo)|Zorera, La (Riaño-Langreo)
33929	Barripies|Bories, Les (Lada- Langreo)|Cabornio (La Venta-Langreo)|Camperones, Los (Langreo)|Candanedo (Langreo)|Cantera (La Venta-Langreo)|Carmen, El (Langreo)|Casa El Medio, La (La Venta-Langreo)|Cebosa, La (Langreo)|Cuesta El Viso|Cuturrasu (Lada-Langreo)|El Corro|Espina, La (Langreo)|Espinedo (Langreo)|Faedo (Langreo)|Felgueron, El (Langreo)|Frieres|Güeria Del Viso, La (La Venta - Langreo)|La Taberna|Llandosu|Llaneces (Langreo)|Llantamartin|Paerna|Pedrazos (Lada - Langreo)|Peña Rubia|Raposa, La (La Venta-Langreo)|Ruciu El (Langreo)|San Tirso (Langreo)|Santianes (Lada-Langreo)|Sierrallana|Sorribero|Trapa, La (Langreo)|Troncos|Vega, La (Venta-Langreo, La)|Veneros (Lada-Langreo)|Viso, El (Langreo)
33930	Barros|Felguera, La (Langreo)|Rexiella|Viesca, La (Langreo)
33934	Caliyu, El (Lada-Langreo)|Campurru, El (Lada-Langreo)|Casa Nueva, La (Lada-Langreo)|Conforcos (Lada-Langreo)|Cuesta Naval, La (Lada-Langreo)|Granda, La (Lada-Langreo)|Llindion, El (Lada-Langreo)|Manigua, La (Lada-Langreo)|Nisal, La (Lada-Langreo)|Pedrea (Lada-Langreo)|Pelabraga (Lada-Langreo)|Pertiga, La (Lada-Langreo)|Ponton, El (Lada - Langreo)|Rivero (Langreo)|Samiguel (Lada-Langreo)|Valle, El (Lada - Langreo)|Venta, La (Langreo)|Xusta, La (Lada-Langreo)
33935	Antuña|Baeres|Braña Del Rio (Langreo)|Braña, La (Langreo)|Camonal|Campanal (Tuilla-Langreo)|Caperal|Carbayu (Tuilla-Langreo)|Casa Nueva, La (Langreo)|Casanueva, La (Tuilla-Langreo)|Casona, La (Tuilla-Langreo)|Ceacal|Coroña|Cotariella (Langreo)|Coz|Cueto, El (Langreo)|El Valluco|Espinera (Langreo)|Güeria, La (Tuilla -Langreo)|Huelga, La (Langreo)|La Casa El Monte|La Gallina|La Mudrera|La Mudrerina|La Tornera|La Valdre|Molino De Coz|Molino De La Maña|Molino Rozado|Moral, La (Langreo)|Otero-Roiles|Refozones|Reguerin|Riega Miguel|Rozado|Tuilla|Vallina, La (Tuilla - Langreo)
33936	Areñes|Cabañona, La (Siero)|Candin|Cerezales|Corujona (Siero)|Coto, El (Arenas-Siero)|Cruz, La (Arenas-Siero)|Cuitu, El (Siero)|El Carpio|Escobal (Carbayin)|Estacion (Carbayin-Siero)|Freno, El (Arenas-Siero)|La Cueña|La Horrea|Lamuño (Siero)|Llosa, La (Siero)|Llovera, La (Siero)|Los Pozos|Magdalena, La (Siero)|Miracales|Mosquitera (Siero)|Paseres, Les|Porqueriza|Pumarabule|Puñide|Rasa, La (Siero)|Rosellon (Siero)|Saldaña|Santiago De Arenas|Saus|Tronquedal|Villaescusa (Siero)
33937	Bendicion (Valdesoto-Siero)|Corripos (Valdesoto-Siero)|Molleo (Hevia-Siero)|Moñeca, La (Hevia-Siero)|Nora (Siero)|Tablao (Valdesoto-Siero)|Venta De Soto|Vinadas, Las (Langreo)
33938	Castiello (Valdesoto-Siero)|Fayes (Valdesoto-Siero)|Landia (Valdesoto-Siero)|Lliceñes (Valdesoto-Siero)|Pando (Valdesoto-Siero)|Piñella, La (Valdesoto-Siero)|Rotella, La (Valdesoto-Siero)|Tiroco ( Valdesoto-Siero)
33939	Andarujo|Caballeros (Hevia-Siero)|Campa, La (Barros-Langreo)|Campanal (La Felguera-Langreo)|Campu La Carrera|Capilla, La (Felguera-Langreo)|Castandiello (Langreo)|Cuarteles De Peñarrubia, Los (Lada-Langreo)|El Ricarion|Fayes, Les (Lada-Langreo)|Formiguera (Langreo)|Frayoso, Lo (Lada-Langreo)|Garganta|Granda, La (La Felguera - Langreo)|Güeria, La (La Felguera - Langreo)|L'Atalaya (Langreo)|Llana, La (Langreo)|Llana¿L Pandu, La (Lada-Langreo)|Nava, La (Langreo)|Pajomal|Pandu, El (Lada-Langreo)|Rebollin, El (Lada-Langreo)|Reguerinas|Reguero Llerin|Respinedo|Respiño|Riparape|San Justo (Langreo)|Tejera De Pando|Torgados|Venta Del Aire (Langreo)
33940	El Entrego|Soton
33945	Cabaña, La (Cocañin) (El Entrego)|Carrocera (El Entrego)|Casanueva (El Entrego)|Corvero|El Cubo|El Pumarabin|Hueria De Carrocera|Huerta, La (El Entrego)|La Llave|Magdalena, La (Entrego)|Piñera, La (El Entrego)|Pontona (El Entrego)|Rotella, La (El Entrego)
33946	Aragustin|Baua|Braniella|Cabaña, La (Ciaño-Langreo)|Cabañina (El Entrego)|Cabañona, La (El Entrego)|Camperona, La (El Entrego)|Camperona, La (Siero)|Capilla, La (Ciaño-Langreo)|Casuca, La (El Entrego)|Ciriego Alto|Ciriego Bajo|Ciriego Medio|Cocañin|Cocaño|Comba, La (Siero)|Corredoria (El Entrego)|Cotariella-Cocañin|Edrado, El (El Entrego)|Fatorgada|Faya, La (El Entrego)|Felechosas|Gemenediz|Ifrera|La Encarnada|La Revenga|La Rina|Las Forniellas|Llaneces Del Rey Moro|Llaniella, La (Entrego)|Llanos Los Artos|Lloseta|Longa, La (El Entrego)|Los Artos|Noal|Ordiales (El Entrego)|Pelonegro|Perlada|Poladura (El Entrego)|Riolosbueyes|Roces, Las (El Entrego)|Roiles (El Entrego)|Rosellon, El (Entrego, El)|Rotella De Bedavo|Sagosa
33947	Abonion|Acebal, La (El Entrego)|Arbejil|Artosa (El Entrego)|Cabaña, La (El Entrego)|Castañera (El Entrego)|Ciñera|Collau, El (San Andres)|Cotariella-Escobio|Escobio (El Entrego)|Figar, La (El Entrego)|Lantero (El Entrego)|Llagos|Mayao|Otariz|Paniceres De San Andres|Pipe (El Entrego)|Rebollada, La (Entrego)|Rebollos, Los (Entrego)|San Vicente (El Entrego)|Sorriego|Trabanquin|Valleya|Vallina (Valle Lantero)|Vilorteras, Las (El Entrego)|Viña (El Entrego)
33948	Barredo (El Entrego)|Bedavo|Bornadina|Cantera, La (El Entrego)|Caseta, La (El Entrego)|El Lugarin De Arriba|El Meruxeo|Fayona, La (El Entrego)|Fresno, El (El Entrego)|Juliana|Llugarin De Abajo|Llugarin De Arriba|Nespral, La (Entrego)|Otariello|Pumarin|Rebollal, El (Entrego)|Rozada|Vistalegre (El Entrego)
33949	Barraca, La (Ciaño-Langreo)|Barraca, La (Langreo)|Candanal, El (El Entrego)|Carbayal (Langreo)|Carbayal, El (Langreo)|Casorra, La (El Entrego)|Cubes, Les (Ciaño-Langreo)|Felguera (Ciaño-Langreo)|Fornos (Ciaño-Langreo)|Foyeu (Ciaño-Langreo)|Granja (El Entrego)|La Central|Limosnera|Los Fornos|Picu Castiellu (Ciaño-Langreo)|Polledo,El (El Entrego)|Santa Ana (Ciaño-Langreo)|Solalonga|Traviesa, La (El Entrego)|Valles, Los (Entrego)|Vallina (El Entrego)|Vallina De La Longa|Villacedre
33950	Sotrondio|Venta, La (Sotrondio)
33957	Argayadas|Batan|Caleyos, Los (Sotrondio)|Canto Las Matas|Canto, El (Sotrondio)|Casacima|Casanueva (Sotrondio)|Casas De Abajo (Sotrondio)|Casuca, La (Sotrondio)|Collado Escobal|Corralon (Sotrondio)|Costaya|Cruz, La (Sotrondio)|Edrado (Sotrondio)|El Vericioso|Escobal, El (Sotrondio)|Estaca, La (Sotrondio)|La Espesura|La Pared|La Potaxa|La Seca Del Agua|La Zorea|Llanos, Los (Sotrondio)|Meruca, La (Sotrondio)|Miera De Arriba|Miera Del Medio|Nespral, La (Sotrondio)|Paniceres (Sotrondio)|Perabeles|Restinga|Rioceral|Riocerezaledo|Santa Barbara|Vallicalagua|Vero|Villar (Sotrondio)
33958	Baraosa|Cabaña Isidora|Cabañas Loredo|Cabañas Nuevas|Cabañina, La (Sotrondio)|Campeta, La (Sotrondio)|Carbonero, El (Sotrondio)|Cepedal|El Carbo|El Madreñero|Florida, La (Sotrondio)|Foxacos|Fuente Las Roces|La Gallega|La Peñona|La Rotura|Linares (El Entrego)|Llaneces De Pedriego|Llano, El (Sotrondio)|Parayes|Pedriego|Peruyera (Sotrondio)|Piquera, La (Sotrondio)|Pomarada (Sotrondio)|San Frechoso (Sotrondio)|San Martin (Sotrondio)|San Pedro (Sotrondio)|Socavon|Venta Del Aire (El Entrego)|Vilorteras (Sotrondio)
33959	Caleyo, El (Sotrondio)|Cavite|Invernal, La (Sotrondio)|La Invernite|Labayos (Sotrondio)|Llana El Pando|Peñatejera|Pradon, El (Sotrondio)|Sallosas|Tetuan (Sotrondio)
33960	Blimea|Caraveo
33969	Aparadas|Biomba|Bobia, La (Blimea)|Burganeo|Cabuernos|Canales, Las (Blimea)|Canto, El (Blimea)|Casilla, La (Blimea)|Cegontin|Collau, El (Blimea)|Cuello|El Chirente|El Mero|El Murio|El Nieto|El Portillo|Fariseo|Felguera (Blimea)|Felguerosa (Blimea)|Fuente Felguera|Hueria, La (Blimea)|La Cabezada|La Cabiella|La Milana|La Molatera|Ladesancho|Lay|Los Melchores|Moznera|Payega (Blimea)|Peruyal (Blimea)|Peña Corvera|Peña, La (Blimea)|Ponton (Blimea)|Quintana, La (Blimea)|Quintanas, Las (Blimea)|Raposera (Blimea)|Riegalatabla|Riolapiedra|Ronzon, El (Blimea)|San Mames|San Roque (Sotrondio)|Sienra (Blimea)|Sierra, La (Blimea)|Solascampas|Soto, El (Blimea)|Tercias, Las (Blimea)|Villalad
33970	Barredos (Laviana)|Recortina
33979	Abedul (Laviana)|Barrera, La (Laviana)|Bustio (Laviana)|Cabañas, Las (Laviana)|Cabuernia|Campo, El (Laviana)|Camporro, El (Barredos)|Carbajal (Barredos)|Casacabada|Casarriba|Casorra, La (Laviana)|Cerezal (Laviana)|Condueño|El Forno|El Pareu|Fabariego (Tiraña-Laviana)|Facuriella|Hueria Alta|Lloro|Los Cardos|Moral, La (Laviana)|Ordaliego (Laviana)|Paniceres (Laviana)|Patarin|Peruyal (Tiraña-Laviana)|Rebollal (Laviana)|San Pedro De Tiraña|Sayedo|Valliquin|Veneros (Laviana)|Villarin (Laviana)|Zoreda Alta|Zoreda Baja
33980	La Arbeya|Pola De Laviana
33986	Arbin|Bargana|Borias, Las (P. Laviana)|Braña De Arriba (Laviana)|Brañavieja (Laviana)|Cabo, El (Laviana)|Campomojado|Caucia|Cerezaleru|Corian|Cuadrazal|Cuesta Los Valles|Cuesta, La (Laviana)|Febrero|Fechaladrona|Fornos (Pola De Laviana)|Fresnedo (Laviana)|Grandon|Merujal De Villoria|Mestas, Las (P.Laviana)|Miguelperi|Navaliego (P.Laviana)|Paradina|Piedras Negras|Pumarada (Pola De Laviana)|Quintanas (P.Laviana)|Roxil|San Pedro De Villoria|Solano (Laviana)|Tolivia (P. Laviana)|Tornos (Pola De Laviana)|Valdelafaya|Viescabozadas|Villoria
33987	Acebal (Pola De Laviana)|Cabaña (Laviana)|Canzana|Entralgo|Fombermeja|Iguanzo|Pando (Laviana)|Peruyal (Entralgo-Laviana)|Puente Del Arco|Ribota
33988	Boza (Pola Laviana)|Brañueta (P. Laviana)|Carrio (P. Laviana)|Corcia|Cuarteles De Merujal|Linariegas|Mardana|Merujal|Perujal|Sarambiello
33989	Canto De Abajo|Canto De Arriba|Carba, La (Pola De Laviana)|Casapapio|Castañal (Laviana)|Constante (Laviana)|Corredoria (P. Laviana)|Fabariego (Villoria-Laviana)|Faya, La (P. Laviana)|Felgueron (Laviana)|Gamonal|Grandiella (Laviana)|Horron|La Ortigosa|La Sertera|Las Palomas|Llanas, Las (Laviana)|Lloreo|Omedines (P. Laviana)|Pielagos|Piniella (P.Laviana)|Pomarada (Pola De Laviana)|Portillas, Las (P.Laviana)|Rasa, La (P.Laviana)|Rebollada (Laviana)|Rebollada, La (Sotrondio)|Rebolloso|Redondina|Redondo (Pola De Laviana)|Sospelaya|Tablazo|Tendejon|Valdelasabejas
33990	Barrio (Caso)|Bueres (Caso)|Campo De Caso|Govezanes|Nieves|Orle|Veneros De Caso
33991	Celleruelo|Llera, La (P.Laviana)|Lorio|Muñera|Payandi
33992	Aldea (Pola De Laviana)|Boroñes|Condado, El (P. Laviana)|Ferrera, La (Laviana)|Sierra (P. Laviana)|Soto De Lorio
33993	Agues|Anzo (Sobrescobio)|Campiellos|La Polina|Ladines (Sobrescobio)|Rioseco De Sobrescobio|San Andres (Sobrescobio)|Soto De Agues|Villamorey
33994	Abantro|Prieres|Tanes|Valderrosa
33995	Buspriz|Caleao|Coballes|Felguerina|Linares (Caso)|Puente Piedra
33996	Belerda|Bezanes|Cortina (P.Laviana)|Foz De Caso|Sobrecastillo|Soto De Caso
33997	Pendones|Tarna (Caso)
34001	Palencia
34002	Palencia
34003	Palencia
34004	Palencia
34005	Palencia
34006	Palencia
34070	Palencia
34071	Palencia
34080	Palencia
34100	Saldaña
34110	Pino Del Rio
34111	Acera De La Vega|Barrios De La Vega|Celadilla Del Rio|Poza De La Vega|San Martin Del Obispo|Villaluenga De La Vega|Villosilla De La Vega
34112	San Andres De La Regla|Santa Olaja De La Vega|Santervas De La Vega|Villapun|Villarrobejo|Villota Del Paramo
34113	Bustocirio, De (Dehesa)|Quintanadiez De La Vega|San Llorente Del Paramo|Villambroz|Villarrabe|Villarrodrigo De La Vega
34114	Portillejo|Quintanilla De Onsoña|Velillas Del Duque|Villantodrigo|Villarmienzo
34115	Membrillar|Relea De La Loma|Renedo Del Monte|Valenoso|Valles De Valdavia|Vega De Doña Olimpa|Villaires|Villalafuente|Villanueva Del Monte|Villasur
34116	Bustillo De La Vega|Gañinas De La Vega|Lagunilla De La Vega|Lobera De La Vega|Pedrosa De La Vega|San Martin Del Valle
34117	Carbonera|Valcabadillo|Villafruel|Villorquite Del Paramo
34118	Villota Del Duque
34120	Carrion De Los Condes
34126	Albala De La Vega|Moslares De La Vega|Renedo De La Vega|Santa Maria De La Vega (Convento)|Santillan De La Vega|Villamoronta
34127	Bahillo|Miñanes|Robladillo De Ucieza|San Mames De Campos|Villamorco|Villasabariego De Ucieza
34128	Gozon De Ucieza|La Serna|Nogal De Las Huertas|Poblacion De Soto|Villaproviano
34129	Bustillo Del Paramo De Carrion|Calzada De Los Molinos|Villacuende|Villanueva De Los Nabos|Villaturde|Villotilla
34130	Monton De Trigo (Finca)
34131	Castrillejo De La Olma|Dehesa De Macintos|Torre De Los Molinos|Villanueva Del Rio|Villoldo
34132	Villasarracino
34133	Perales
34159	Monte La Torre|Rayaces|Valdebusto
34160	Esquileo De Abajo|Esquileo De Arriba|La Dehesilla
34170	Cascon De La Nava|Mazariegos|Pedraza De Campos|Revilla De Campos|Villamartin De Campos|Villarramiro
34190	Calabazanos|Ciudad Jardin 'Virgen Milagro'|Los Olmillos|Villamuriel De Cerrato
34191	Ampudia|Autilla Del Pino|Monte De Villalobon|Nuestra Señora De Alconada (Monasterio)|Paradilla Del Alcor|Paredes Del Monte|Santa Cecilia Del Alcor|Valoria Del Alcor
34192	Grijota|Villaumbrales
34200	Baños De Cerrato|Venta De Baños
34208	Cementos Hontoria|Monasterio De San Isidro Dueña|Reinoso De Cerrato|San Isidro De Dueñas
34209	Hontoria De Cerrato|Soto De Cerrato|Tariego De Cerrato|Valle De Cerrato
34210	Dueñas
34218	Cevico De La Torre
34219	Alba De Cerrato|Castrillo De Onielo|Cubillas De Cerrato|Poblacion De Cerrato|Vertavillo
34220	Castillo De Magaz|Magaz De Pisuerga
34230	Torquemada
34239	Valdeolmillos|Villamediana
34240	Baltanas
34246	Castrillo De Don Juan
34247	Cevico Navero|Hermedes De Cerrato|Villaconancio
34248	Antiguedad|Cobos De Cerrato|Espinosa De Cerrato
34249	Hornillos De Cerrato|Valdecañas De Cerrato|Villaviudas
34250	Quintana Del Puente
34257	Palenzuela|Tabanera De Cerrato|Villahan|Villodrigo
34259	Cordovilla La Real|Dehesa De Cordovilla|Dehesa De Matanza|Dehesa De Villandrando|Herrera De Valdecañas|San Salvador Del Moral
34260	Revilla Vallejera|Vallejera|Villamedianilla|Vizmalo
34261	Villalaco
34300	Paredes De Nava
34304	Belmonte De Campos|Castil De Vela
34305	Baquerin De Campos|Boada De Campos|Capillas|Castromocho|Meneses De Campos|Torremormojon|Villerias De Campos
34306	Frechilla|Guaza De Campos|Mazuecos De Valdeginate
34307	Abastas|Abastillas|Añoza|Villalumbroso|Villatoquite
34309	Calzadilla De La Cueza|Cardeñosa De Volpejera|Cervatos De La Cueza|Quintanilla De La Cueza|Riberos De La Cueza|Villamuera De La Cueza|Villanueva Del Rebollar|Villaverde De Volpejera
34310	Becerril De Campos|El Espinar|Monte Carrascal|Pinacho (Caserio)|Venta, La (Urbanizacion)|Villafruela|Villaldavin
34320	Cisneros
34337	Fuentes De Nava
34338	Abarca De Campos|Autillo De Campos
34340	Villada
34347	Arroyo|Lagartos|Ledigos|Poblacion De Arroyo|Pozo De Urama|San Roman De La Cuba|Villalcon|Villambran De Cea
34349	Boadilla De Rioseco|Moratinos|Pozuelos Del Rey|San Martin De La Fuente|San Nicolas Del Real Camino|Terradillos De Templarios|Villacidaler|Villatima (Finca)|Villelga|Villemar
34350	Villarramiel
34400	Herrera De Pisuerga
34405	Hijosa De Boedo|Naveros De Pisuerga|Olmos De Pisuerga|Ventosa De Pisuerga
34406	Bascones De Ojeda|Dehesa De Romanos|Oteros De Boedo|San Jorde De Ojeda|Villabermudo De Ojeda
34407	Calahorra De Boedo|Cembrero|Collazos De Boedo|Olea De Boedo|Paramo De Boedo|Revilla De Collazos|San Martin Del Monte|Sotillo De Boedo|Sotobañado Y Priorato|Villaneceriel|Zorita Del Paramo
34408	Villameriel
34409	Santa Cruz Del Monte|Villorquite De Herrera
34410	Monzon De Campos
34411	Ribas De Campos
34419	Fuentes De Valdepero|Husillos|Valdespina|Villajimena|Villalobon
34420	Amusco
34429	Amayuelas De Abajo|Amayuelas De Arriba|Manquillos|San Cebrian De Campos
34430	Piña De Campos
34439	Tamara De Campos
34440	Fromista
34447	Revenga De Campos|Villarmentero De Campos
34449	Arconada|Lomas|Poblacion De Campos|Villalcazar De Sirga|Villovieco
34450	Astudillo
34460	Osorno
34465	San Cebrian De Buena Madre (Finca)|Valbuena De Pisuerga
34466	Villodre
34467	Melgar De Yuso
34468	Boadilla Del Camino|Itero De La Vega|Lantadilla|Osornillo
34469	Fuenteandrino|Las Cabañas De Castilla|Marcilla De Campos|Requena De Campos|Santillana De Campos|Villadiezma|Villaherreros
34470	Barrio La Puebla|Barriosuso|Buenavista De Valdavia|La Puebla De Valdavia
34473	Arenillas De San Pelayo|Ayuela|Polvorosa De Valdavia|Renedo De Valdavia|Tabanera De Valdavia|Valderrabano
34475	Villabasta De Valdavia|Villaeles De Valdavia|Villamelendro|Villasila De Valdavia
34477	Arenillas De Nuño Perez|Barcena De Campos|Itero Seco|Villanuño De Valdavia
34478	Castrillo De Villavega|Villavega
34479	Abia De Las Torres
34480	Alar Del Rey
34483	Colmenares De Ojeda
34484	Dehesa De Montejo
34485	Amayuelas De Ojeda|Berzosa De Los Hidalgos|La Vid De Ojeda|Micieces De Ojeda|Payo De Ojeda|Pison De Ojeda|Quintanatello De Ojeda|Vega De Bur|Villavega De Ojeda
34486	Moarves De Ojeda|Pradanos De Ojeda|San Andres Del Arroyo|San Pedro De Moarves|Santibañez De Ecla|Villaescusa De Ecla
34487	Becerril Del Carpio
34488	Cozuelos De Ojeda|Cubillo De Ojeda|Montoto De Ojeda|Olmos De Ojeda|Perazancas De Ojeda
34490	Palacios Del Alcor|Santiago Del Val|Santoyo
34491	Espinosa De Villagonzalo|San Cristobal De Boedo|Santa Cruz De Boedo|Villaprovedo
34492	Albacastro|Barrio De San Quirce|Castrecias|La Rebolleda|Mave|Nogales De Pisuerga|Pozancos|Rebolledillo|Rebolledo De La Orden|Rebolledo De La Torre|San Quirce De Rio Pisuerga|Santa Maria De Mave|Valdegama|Valtierra De Albacastro|Villacibio|Villela
34800	Aguilar De Campoo
34810	Barrio De San Pedro|Barrio De Santa Maria|Cordovilla De Aguilar|Corvio|Foldada|Matalbaniega|Matamorisca|Menaza|Nestar De Aguilar|Vallespinoso De Aguilar|Villavega De Aguilar
34811	Cabria|Canduela|Navas De Sobremonte|Quintanas De Hormiguera|Quintanilla De Las Torres|Villanueva De Henares
34813	Bascones De Valdivia|Camesa De Valdivia|Cezura|Helecha De Valdivia|Pomar De Valdivia|Porquera De Los Infantes|Puentetoma|Rebolledo De La Inera|Respenda De Aguilar|Revilla De Pomar|Villaren De Valdivia
34815	Gama|Lomilla|Olleros De Pisuerga|Renedo De La Inera|Valoria De Aguilar|Villaescusa De Las Torres|Villallano
34820	Barruelo De Santullan
34828	Bustillo De Santullan|Monasterio|Nava De Santullan|Porquera De Santullan|Revilla De Santullan|Santa Maria De Nava|Valle De Santullan|Verbios|Villabellaco|Villanueva De La Torre
34829	Brañosera|Cillamayor|El Valle|Matabuena|Orbo|Salcedillo|Valberzoso|Vallejo De Orbo
34830	Renedo De Zalima|Salinas De Pisuerga|San Mames De Zalima
34839	Barcenilla De Pisuerga|Liguerzana|Matabustillo|Muda|Perapertu|Quintanaluengos|Rueda De Pisuerga|San Cebrian De Muda|San Martin De Perapertu|Vallespinoso De Cervera|Vergaño
34840	Cervera De Pisuerga
34844	Rebanal De Las Llantas|Resoba|Ruesga|San Martin De Los Herreros|Santibañez De Resoba|Vado Cervera, De (Estacion)|Vado-Cervera|Ventanilla
34846	Arbejal|Celada De Roblecedo|Estalaya|Gramedo|Herreruela De Castilleria|Polentinos|Rabanal De Los Caballeros|San Felices De Castilleria|Valsadornin|Vañes|Verdeña
34847	El Campo|Lebanza|San Salvador De Cantamuda
34848	Lores
34849	Areños|Camasobres|Casavegas|Los Llazos|Piedrasluengas|San Juan De Redondo|Santa Maria De Redondo|Tremaya
34850	Castrejon De La Peña
34858	Pison De Castrejon|Recueva De La Peña|Roscales De La Peña
34859	Boedo De Castrejon|Cantoral De La Peña|Cubillo De Castrejon|Loma De Castrejon|Traspeña|Villanueva De La Peña
34869	Aviñante De La Peña|Tarilonte De La Peña|Velilla De La Peña|Villafria De La Peña|Villalbeto De La Peña|Villaverde De La Peña
34870	Respenda De La Peña|Santibañez De La Peña
34878	Barajores De La Peña|Baños De La Peña|Cornoncillo|Fontecha De La Peña|Riosmenudos De La Peña|Santana De La Peña|Vega De Riacos|Viduerna De La Peña|Villanueva De Abajo
34879	Cornon De La Peña|Intorcisa De La Peña|Las Heras De La Peña|Muñeca De La Peña|Pino De Viduerna|Villa Oliva De La Peña|Villanueva De Arriba
34880	Guardo
34882	Congosto De Valdavia|Dehesa De Tablares
34886	Velilla Del Rio Carrion
34887	La Lastra|Triollo|Vidrieros
34888	Alba De Los Cardaños|Camporredondo De Alba|Cardaño De Abajo|Cardaño De Arriba|Otero De Guardo
34889	Fresno Del Rio|Mantinos|San Pedro De Cansoles|Villalba De Guardo
35001	Las Palmas De Gran Canaria
35002	Las Palmas De Gran Canaria
35003	Las Palmas De Gran Canaria
35004	Las Palmas De Gran Canaria
35005	Las Palmas De Gran Canaria
35006	Las Palmas De Gran Canaria
35007	Las Palmas De Gran Canaria
35008	Las Palmas De Gran Canaria
35009	Las Palmas De Gran Canaria
35010	Las Palmas De Gran Canaria
35011	Las Palmas De Gran Canaria
35012	Las Palmas De Gran Canaria
35013	Las Palmas De Gran Canaria
35014	Las Palmas De Gran Canaria
35015	La Matula|Las Palmas De Gran Canaria
35016	Las Palmas De Gran Canaria
35017	Dragonal Alto|Dragonal Bajo|El Sabinal|La Calzada|Las Palmas De Gran Canaria|Llanos De Maria Ribera|Lomo Blanco (Las Palmas)|Los Hoyos (Las Palmas De G.C.)|Montañeta, La (Las Palmas)|Monte Luz|Pico Viento|Siete Puertas|Tafira Baja
35018	Almatriche Alto|Almatriche Bajo|Cortijo, El (Tamaraceite)|El Pintor|El Sardo|Frailes, Lomo De Los|Hoya Andrea|La Galera|La Milagrosa|La Suerte|Las Mesas Altas|Las Mesas Bajas|Las Palmas De Gran Canaria|Las Perreras|Majadillas, Las (Las Palmas De G.C.)|Piletas|San Lorenzo|Tamaraceite
35019	Las Palmas De Gran Canaria
35070	Las Palmas De Gran Canaria
35071	Las Palmas De Gran Canaria
35080	Las Palmas De Gran Canaria
35100	Bahia Feliz (Urbanizacion)|Campo Internacional|Cañon Del Aguila|Costa Meloneras (Urbanizacion)|Las Meloneras|Maspalomas|Playa Del Aguila|Playa Del Ingles|San Agustin|San Fernando (Maspalomas)|Sonneland (Urbanizacion)
35106	Calderin|El Llanillo|El Salobre|Lomo De Pedro Afonso|Montaña Blanca (Maspalomas)|Montaña De La Arena|Pasito Blanco|Pedrazo Alto|Pedrazo Bajo
35107	Agadir|Berriel|Castillo Del Romeral|El Morrete|Florida, La (San Bartolome De Tirajana)|Juan Grande|Las Salinas Del Matorral|Lomo Del Moral|Matorral, El (San Bartolome De Tirajana)|Rodeos, Los (San Bartolome De Tirajana)|Tarajalillo (Juan Grande)
35108	Arteara|Cercados, Los (San Bartolome Tirajana)|Fataga|Los Caserones De Fataga|Los Hortigones
35109	Ayagaures|La Mimbre|Las Tederas|Lomo De Perera|Lomo Gordo|Media Fanega|Montaña La Data|Monte Leon (Urbanizacion)|Palmitos Park|Palmitos, Los (Maspalomas)|Tablero, El (Maspalomas)
35110	Balos|Barranquillo De Sardina|Camino La Madera|Canario, El (Vecindario)|Casa Pastores|Cruce De Sardina Del Sur|El Doctoral|Hoya Pavon|La Blanca|La Cerruda|La Paredilla|La Union|La Vereda|Llanos, Los (Santa Lucia De Tirajana)|Orilla Baja|San Pedro Martir|San Rafael|Sardina Del Sur (Vecindario)|Vecindario
35118	Arinaga|Cruce De Arinaga|Goleta, La (Aguimes)|Montaña De San Francisco|Pie De La Cuesta (Agüimes)|Poligono Industrial De Arinaga|Rosas, Las (Agüimes)
35119	Aldea Blanca|Barranquillo (Santa Lucia De Tirajana)|Casa Santa|Pozo Izquierdo
35120	Arguineguin|Charca, La (Arguineguin)|Cornisa Del Suroeste|Cornisa, La (Urbanizacion)
35128	Barranquillo Andres|Cercados De Espino|Chira|Crucitas, Las (San Bartolome De Tirajana)|El Caidero|El Horno|El Pajar|El Vento|Huesa Bermeja|Las Filipinas|Lomo Galeon|Peñones, Los (Mogan)|Santa Agueda|Soria
35129	Aquamarina|Balito|Barranco Balito|Barranco De La Verga|Caideros, Los (Urbanizacion)|Los Canarios|Patalavaca
35130	Chaparral, El (Puerto Rico)|Cortadores De Puerto Rico|El Motor Grande|Playa De Amadores|Puerto Rico
35138	Mogan, De (Playa)|Platero, El (Urbanizacion)|Playa De Tauro|Taurito
35139	Lomo Quiebre
35140	Los Navarros|Mogan (Capital Municipal)
35149	Casas Blancas (Mogan)|Casas De Veneguera|Casillas, Las (Mogan)|Cercado, El (Mogan)|Hornillo, El (Mogan)|Horno De Teja|La Humbridilla|La Rosilla|La Umbridilla|Las Burrillas|Llanos, Los (Mogan)|Los Almacigos|Molino De Viento (Mogan)|Pasitos, Los (Mogan)|Pie De La Cuesta (Mogan)|Playa De Veneguera|Tabaibales
35200	San Francisco|San Gregorio (Telde)|San Juan (Telde)|Telde
35210	Balcon De Telde|Lomo De La Herradura|Montaña De Las Palmas|San Jose De Las Longueras|Tara|Telde
35211	Arenales, Los (Telde)|Cazadores|La Colomba|Lomo-Bristol|Lomo-Magullo|Tecen (Telde)|Telde|Valle De Los Nueve
35212	La Estrella|La Garita|Marpequeña|San Borondon|Telde
35213	La Pardilla|La Primavera|Las Remudas|Majadilla, La (Telde)|San Antonio|San Isidro (Telde)|Telde
35214	Casas Nuevas|Melenara|Playa De Las Clavellinas|Playa De Melenara|Playa De Salinetas|Playa Del Hombre|Salinetas|Taliarte|Telde
35215	Cuatro Puertas|El Calero|El Caracol|Frailes, Lomo Los (Telde)|Jerez|Jerez (Telde)|La Viña|Las Huesas|Las Medianias|Lomo Cementerio|Lomo Sala|Piletillas|Telde
35216	Casas Blancas (Valsequillo)|Casillas, Las (Valsequillo)|Colmenar De Abajo|Colmenar De Arriba|El Almendrillo|El Helechal|El Montañon|El Troncon|La Era De La Mota|La Suertecilla|Pedregal, El (Valsequillo) (Urbanizacion)|Rincon, El (Tenteniguada)|Tenteniguada|Vegas, Las (Valsequillo)
35217	Almendros, Los (Urbanizacion)|Casas, Las (Valsequillo)|Cuevas Negras|La Barrera|La Cantera|Las Chozas|Llanos Del Conde|Lomitos De Correa|Los Juagarzos|Los Llanetes|Luis Verde|Majuelo|Mirabala|Pinos, Los (Valsequillo)|Roque, El (Valsequillo)|San Roque (Valsequillo)|Tecen De Valsequillo|Valle De San Roque|Valsequillo (Capital Municipal)
35218	Caserones Altos|Caserones Bajos|Cendro|Garcia Ruiz|Goteras, Las (Telde)|Hoya Aguedita|La Higuera Canaria|Palmital, El (Telde)|Solana, La (Telde)|Telde|Valle De Casares
35219	El Goro|Gando|Ojos De Garza|Playa De Tufia|Playa Ojos De Garza|Poligo Industrial El Goro|Poligono Salinetas|Telde
35220	Cruz De La Gallina|Hornos Del Rey|La Matanza|Las Palmas De Gran Canaria|Lomo Blanco (Jinamar)|Parque Empresarial Jinamar|Telde|Valle De Jinamar
35229	Las Palmas De Gran Canaria|Llanos De Cuatro Caminos|Marzagan|Mercalaspalmas|Santa Margarita (Urbanizacion)
35230	Aeropuerto De Gran Canaria|Base Aerea De Gando
35240	Carrizal, El (Ingenio)|El Burrero
35250	El Carrion|Ingenio (Capital Municipal)|Las Mejias|Lomo Del Hospital|Sequero, El (Ingenio)
35259	Aguatona El Nuevo|Aguatona El Viejo|La Pasadilla|Las Majoreras|Las Puntillas|Los Moriscos|Marfu|Mondragon|Roque, El (Ingenio)
35260	Aguimes (Capital Municipal)|Barranco De Guayadeque|Cueva Bermeja
35269	El Eden|La Banda|Las Rosas Viejas|Llano Blanco|Montaña De Los Velez|Oasis|Palmillas, Las (Aguimes)|Vargas
35270	Temisas
35280	Casas Blancas (San Bartolome De Tirajana)|Ciudad De Lima|El Morisco|El Mundillo|El Parralillo|El Sitio De Abajo|El Sitio De Arriba|Ingenio, El (Santa Lucia De Tirajana)|La Sorrueda|Las Lagunas|Lomito De Taidia|Los Sitios|Montaña De Rosiana|Montaña, La (San Bartolome De Tirajana)|Parral Grande|Risco Blanco|Rosiana|Santa Lucia De Tirajana (Capital Municipal)|Taidia|Trejo|Valle, El (Santa Lucia De Tirajana)
35290	San Bartolome De Tirajana (Capital Municipal)|Tunte
35299	Agualatente|Cercados De Araña|Culata, La (S.B.Tirajana)|El Canalizo|Hoya De Tunte|Hoya Garcia|Hoya Grande|La Plata|Lomo De La Palma|Perera|Sequero, El (San Bartolome Tirajana)
35300	Alternativa Uno|Cruce De La Atalaya (Santa Brigida)|Cuesta De La Grama|El Castaño Alto|El Castaño Bajo|Estanco, El (Santa Brigida)|Los Veroles|Montañeta, La (Santa Brigida)|Montebravo|Palmeral, El (Santa Brigida)|Plaza De Doña Luisa|San Jose De Las Vegas|Santa Brigida (Capital Municipal)|Satautejo
35307	Arco, El (Santa Brigida)|Atalaya, La (Santa Brigida)|Bandama (Urbanizacion)|Concepcion, La (Urbanizacion)|Cuesta La Gramma|El Raso|Estanco, El (Atalaya De Santa Brigida)|Goteras, Las (Santa Brigida)|Las Cordilleras|Vinculo, El (Santa Brigida)
35308	Casas, Las (Santa Brigida)|Casillas, Las (Santa Brigida)|El Paraiso|Gamonal Alto|Gamonal Bajo|Gargujo|Gran Parada|Hoya Bravo|Las Brisas|Lugarejo, El (Santa Brigida)|Madroñal|Molino, El (Santa Brigida)|Portada Verde|Silos, Los (Santa Brigida)
35309	Cuevas Del Guanche|El Palmarejo|El Santisimo|El Tejar|La Angostura|La Capellania|Las Cadenas|Las Haciendas|Las Meleguinas|Lomo Espino (Santa Brigida)|Lomo Los Ajos|Los Olivos|Pino Santo Alto|Pino Santo Bajo
35310	Bebedero, El (Monte Lentiscal)|Cuesta El Reventon|El Colegio|El Mocanal|Hoya Capa|Lentiscos, Los (Urbanizacion)|Los Alvarados|Los Toscones|Monte Lentiscal|Reventon, El (Urbanizacion)|Vinco, El (Santa Brigida)
35319	Bandama|Caldera De Bandama|Fuente De Los Berros|Las Arenillas|Montañeta, La (Monte Lentiscal)
35320	El Solis|San Mateo|Vega De San Mateo
35328	Ariñez|Casa Quemada|Corraletes|Corte, La (San Mateo)|Cruz De Tejeda|Cruz Del Herrero|El Gallego|El Lomito|El Piquillo|El Portillo|El Vincol|Estanco, El (San Mateo)|Galas|Hoya De Los Ajos|La Sequera|La Solana|La Yedra|Las Lagunetas|Las Pitas|Lomo Carbonero|Pajaritos|Risco Prieto (San Mateo)|San Francisco (San Mateo)|Solana, La (San Mateo)|Utiaca|Vegas, Las (San Mateo)
35329	Acequia Marrero|Asomada, La (San Mateo)|Calero, El (San Mateo)|Camaretas|Casa De La Cal|Chorrillo, El (San Mateo)|Cruz Del Saucillo|Cuatro Caminos|Cueva Grande|Cuevas, Las (San Mateo)|El Arenal|Hornillo, El (San Mateo)|Hoya Del Gamonal|Hoya Navarra|Hoya Viciosa|La Bodeguilla|La Higuera|La Lechuza|La Veguetilla|Lechucilla|Lomo Aljorradero|Lomo Caballo|Lomo Los Ingleses|Longueras, Las (San Mateo)|Los Chorros|Meson, El (San Mateo)
35330	Barrio Del Pino (Teror)|Buenavista (Teror)|El Chorrito|El Secuestro|Hornillo, El (Teror)|Hoyo, El (Teror)|Llanos De Arevalo|Lomo Cobo|Lomo, El (Teror)|Mujica|Muñigal|Rincon, El (Teror)|Teror (Capital Municipal)
35333	Arbejales
35338	Barranco Zapatero|Corrales Los (Teror)|El Faro|Espartero|Lo Blanco|Lomo Del Gallego|Lomo Pilon|Miraflor|Ojero|San Isidro (Teror)|Toscas, Las (Teror)
35339	Barranco Del Pino (Barranco)|Cuesta Falcon|El Alamo|El Escobonal|El Palmar|El Pedregal|Guanchia|Huertas Del Palmar|Las Paredes|Las Peñas|Las Rosadas|Los Llanos|Peña, La (Teror)|Quebradero|San Matias|Siete Puertas (Teror)
35340	Lanzarote (Valleseco)|Madrelagua|Valleseco (Capital Municipal)
35349	Barranco|Barranquillo (Valleseco)|Carpinteras|Caseron|Laguna, La (Valleseco)|Las Troyanas|Monagas|Valsendero|Zamora|Zumacal (Valleseco)
35350	Acusa Verde|Artenara|Candelaria|Coruña|Cuevas, Las (Artenara)|Lugarejos
35360	Tejeda (Capital Municipal)
35368	Carrizal De Tejeda|Casa Forestal Pajonales|Chorrillo, El (Tejeda)|Culata, La (Tejeda)|El Espinillo|El Juncal|Higuerilla|Pagos De Casas Juan Gomez|Roque, El (Tejeda)|Solana, La (Tejeda)|Toscon, El (Tejeda)
35369	Ayacata|Casas De Huertas|Casas Del Lomo|Crucitas, Las (Tejeda)|Cuevas Caidas|Degollada, La (Tejeda)|El Majuelo|La Candelilla|La Umbria|Lomo De Los Santos|Rincon, El (Tejeda)|Risco La Candelilla|Timagada
35400	Arucas (Capital Municipal)|Camino De La Cruz Alto|El Angostillo|El Cerrillo|El Hornillo Alto|El Matadero|Goleta, La (Arucas)|Hoya De San Juan|La Fula|Lomo De San Pedro (Arucas)|Montaña De Arucas|Montañeta, La (Arucas)|Terrero, El (Arucas)
35411	Barreto|Barriada De Juan Xxiii|El Puente De Arucas|Hoya De Ariñez|La Guitarrilla|Las Palmeras|Lomo De Arucas|Lomo Grande|Lomo, El (Santidad)|San Francisco Javier|San Francisco Javier (Urbanizacion)|San Gregorio (Arucas)|Santidad Alta|Santidad Baja
35412	Arco, El (Arucas)|Barrio Virgen Del Pino|Camino Del Arco|El Picacho|Fuente Del Laurel|La Pedrera|Los Altabacales|Los Castillos|Los Portales|Mirador De Los Portales|Peñones, Los (Arucas)|Santa Flora|Solana, La (Arucas)|Visvique
35413	Camino De La Cruz Bajo|Cardonal (Arucas)|Costa|Cruz De Pineda|El Carril|El Guincho|El Hornillo Bajo|Hinojal|Hoyas, Las (Arucas)|La Hondura|La Palmita|Las Chorreras|Las Hoyas Del Cardonal|Llano Blanco (Arucas)|Lomito, El (Arucas)|Lomo De Quintanilla (Arucas)|Lomo Ramirez|Los Castillejos|Los Palmitos|Tanasio|Tinocas (Arucas)|Trapiche (Arucas)|Trasmontaña|Tres Barrios
35414	Altillo|Bañaderos|El Peñon|El Puertillo|El Tarahal|Escaleritas (Arucas)|La Cuestilla|Pagador|Quintanilla|Risco, El (Arucas)|Roque, El (Arucas)|San Andres|San Felipe
35415	Cardones|Dehesa, La (Arucas)|El Perdigon|Lomo Espino (Arucas)|Montaña Cardones|Montaña, La (Cardones)
35420	Moya
35421	Barranco Del Laurel|Barranco Del Pinar (Moya)|Corvo|Fontanales|Hoyas Del Cavadero|Juarada, La (Moya)|Lomo Del Peñon|Los Tiles|San Bartolome De Fontanales|San Fernando (Moya)|Tablero, El (Moya)
35422	Cabo Verde|El Brecito|El Moreto|Fronton, El (Moya)|La Cordillera|Las Carreras|Los Toscales|Palmito, El (Moya)|Trujillo (Moya)
35423	Carreteria|Doramas (Moya)|Dragos, Los (Moya)|El Lance|El Palo|Lomo Blanco (Moya)
35430	Firgas (Capital Municipal)
35431	Barranco De Las Madres|Buenlugar|Casablanca|Itara|Las Pellas|Lomito, El (Firgas)|Palmilla, La (Firgas)|San Anton|Zumacal, El (Firgas)
35432	Caldera, La (Firgas)|Cambalud|Cruz, La (Firgas)|El Cortijo|Lomo Quintanilla (Firgas)|Los Barranquillos|Los Dolores|Los Menores|Los Rosales|Padilla|Risco, El (Firgas)|Trapiche (Firgas)
35450	Becerril De Guia|Calvario, El (Santa Maria De Guia)|Cercados De Merino|Guia|La Atalaya De Guia|Marente (Urbanizacion)|Santa Maria De Guia (Capital Municipal)
35457	Barranco Del Pinar (Santa Maria De Guia)|Barranquillo Frio|Bascamao|Caserio De Marente|Cuesta De Caraballo|Hoya Del Predegal (Santa Maria De Guia)|Ingenio Blanco|Junquillo|Lomo Betancor|Marente|Montaña Alta (Santa Maria De Guia)|Paso Maria De Los Santos|Santa Cristina|Tres Cruces (Santa Ma De Guia)|Verdejo
35458	Albercon De La Virgen|Barranco Hondo (Santa Maria De Guia)|Casas De Aguilar|Desaguaderos|Doñana|El Calabozo|Farailaga|La Dehesa|Lomo De Las Azucenas|Lomo Los Martines|Mondragones|Palmital, El (Carretera)|San Blas|San Juan (S.M.Guia)|Suerte, La (S.M. Guia)|Tres Palmas (Santa Maria De Guia)|Vergara
35459	Anzo|Cañada, La (Santa Maria De Guia)|Las Boticarias|Llanos De Parra|Montaña De Guia
35460	Galdar (Capital Municipal)
35468	Barranco Hondo De Abajo|Barranco Hondo De Arriba|Buenavista|Caideros De San Jose|Cardonal (Agaete)|Chirino|Degollada, La (Galdar)|Hornillo, El (Agaete)|Hoya De Pineda (Galdar)|Hoya De Pineda (Santa Maria De Guia)|Inciensal|Juncalillo (Galdar)|La Agazal|Las Calderas|Llanos, Los (Agaete)|Lomo Del Palo|Lucena|Molino, El (Galdar)|Montañeta, La (Galdar)|Piso Firme|Rosas, Las (Galdar)|Saucillo|Silos, Los (Galdar)|Tegueste (Galdar)|Troya|Trujillo (Galdar)|Valeron
35469	Barranquillo El Vino|Barrial|Barrio Negrin (Galdar)|Caleta De Arriba|Condenados, Los (Barrio)|Corralete|El Agujero|El Clavo|Faro De Sardina (Urbanizacion)|La Furnia|Las Cumbrecillas|Los Dos Roques|Nido Cuervo|Punta De Galdar|Sardina (Galdar)|Sobradillo, El (Galdar)
35470	Jerez (San Nicolas De Tolentino)|La Aldea De San Nicolas|Los Cardones|San Nicolas De Tolentino (Capital Municipal)
35478	Artejeves (Zona)|Casas Blancas (San Nicolas De Tolentino)|Cruz, La (San Nicolas De Tolentino)|El Canonigo|Hoyo, El (San Nicolas De Tolentino)|La Cardonera|Molino De Viento (Tasarte)|Palillo De Tasarte|Pasitos, Los (San Nicolas De Tolentino)|Playa De Tasarte (Playa)|Posteragua De Tasarte|Rosas, Las (San Nicolas De Tolentino)|Tasarte|Tasartico|Tocodoman
35479	Castañeta|Cercadillos|Cruce, El (San Nicolas De Tolentino)|Cuermeja|El Albercon|El Pinillo|El Ribanzo|La Hoyilla|La Ladera|La Rosa|Ladera Del Palomar|Las Marciegas|Las Tabladas|Lomo, El (San Nicolas De Tolentino)|Los Caserones|Los Espinos|Los Molinos|Mederos|Molino De Agua|Playa, La (San Nicolas De Tolentino)
35480	Agaete (Capital Municipal)|Palmeral, El (Agaete) (Urbanizacion)|Turman, El (Urbanizacion)
35488	Barranco Canario|Farragut|Juan Viejo|Las Quintanas|Lomo De Don Tomas|Lomo De San Anton|Majadilla, Las (Galdar)|Marmolejo|Rosetas|San Isidro (Galdar)|Taya
35489	Chapin|Cruz, La (Agaete)|Cuevecillas (Agaete)|Guayedra|La Calera|Lomo De San Pedro (Agaete)|Longueras, Las (Agaete)|Los Berrazales|Puerto De Las Nieves|Risco El (Agaete)|San Pedro|Sao, El (Agaete)|Suerte, La (Agaete)|Valle De Agaete|Vecindad De Enfrente
35500	Arrecife
35507	Las Cabreras|Tahiche|Vega De Tahiche|Volcan De Tahiche
35508	Costa Teguise|Las Caletas|Los Ancones
35509	Aeropuerto De Lanzarote|Las Puntas|Playa Del Cable (Playa)|Playa Honda
35510	Barranco Del Quiquere|Los Casalones|Los Mojones|Los Pocillos|Puerto Del Carmen
35520	Haria (Capital Municipal)
35530	Teguise (Capital Municipal)
35539	El Mojon|Los Valles|Montaña, La (Teguise)|Nazaret|Teseguite
35540	Caleta De Sebo (Isla Graciosa)|Caleta De Sebo (La Graciosa)|Pedro Barba (La Graciosa)
35541	Guinate|Maguez|Orzola|Ye
35542	Arrieta|Punta Mujeres|Tabayesco
35543	Mala
35544	Guatiza
35550	San Bartolome De Lanzarote (Capital Municipal)
35558	Caldereta (San Bartolome De Lanzarote)|Caleta De Famara|Laderas, Las (Teguise)|Muñique|Soo|Tiagua
35559	El Islote|Florida, La (San Bartolome De Lanzarote)|Guime|Montaña Blanca (San Bartolome De Lanzarote)
35560	Cañada, La (Tinajo)|Costa, La (Tinajo)|El Cuchillo|La Santa|La Vegueta|Mancha Blanca|Tajaste|Tinajo|Yuco
35561	Mozaga|Tao (Teguise)|Tomaren
35570	Breñas, Las (Yaiza)|Casitas, Las (Yaiza)|Degollada La (Yaiza)|Femes|Golfo, El (Yaiza)|La Geria|Maciot|Playa Quemada|Uga|Yaiza (Capital Municipal)
35571	Asomada, La (Tias)|Barranco De La Calera (Macher)|Barranco De La Pila|Barranco Del Agua|Cortijo Viejo (Yaiza)|Macher|Puerto Calero
35572	Conil|Masdache|Tegoyo|Tias (Capital Municipal)
35580	Castillo Del Aguila|Coloradas, Las (Yaiza)|Costa De Papagayo|Montaña Roja|Playa Blanca (Yaiza)|San Marcial De Rubicon
35600	Llanos De La Mareta|Matorral, El (Puerto Del Rosario)|Puerto Del Rosario (Capital Municipal)
35610	Aeropuerto De Fuerteventura|Barranco De La Torre|Barrio De Negrin (Puerto Del Rosario)|Caleta De Fuste|Castillo De Caleta Fuste|Castillo, El (Antigua)|Costa De Antigua|Golf Club Fuerteventura|Nuevo Horizonte (Urbanizacion)|Salinas Del Carmen
35611	Casillas Del Angel|Colonia De Garcia Escamez|Tao (Pto Del Rosario)|Tefia|Tesjuate
35612	Asomada, La (Puerto Del Rosario)|Guisguey|Llanos Pelados|Los Estancos|Puerto Lajas|Rosa De La Arena|Rosa De La Monja
35613	El Time|Herradura, La (Pto Rosario)|La Matilla|Tamariche|Tetir|Valhondo
35620	Gran Tarajal
35625	Las Gaviotas|Morro Jable|Solana Del Matorral
35626	Barranco Del Mal Nombre|Barranco Los Canarios|Esquinzo (Morro Jable)|Jandia
35627	Bahia Calma|Cañada Del Rio|Chilegua|Costa Calma|Huertas De Chilegua|La Lajita|La Pared|Los Albertos|Risco Del Gato
35628	Ajuy|Cardon, El (Pajara)|Mezquez|Pajara (Capital Municipal)|Toto
35629	Casa De Violante|Charco, El (Tuineje)|Diego Alonso|Juan Gopar|La Calabaza|La Fuentita|La Mata|Las Casitas|Las Playitas|Llano Florido|Marcos Sanchez|Mazacote|Montaña Hendida|Piedra Hincada|Puerto Azul (Urbanizacion)|Rosa De James|Rosa Grande|Tamaretilla|Tarajalejo|Tenicosquey|Tesejerague|Tuineje
35630	Antigua, La (Capital Municipal)
35637	Betancuria|La Ampuyenta|Llanos De La Concepcion|Valle De Santa Ines|Vega De Rio Palmas
35638	Agua De Bueyes|Casillas De Morales|Corte, La (Antigua)|Las Pocetas|Tiscamanita|Valles De Ortega
35639	Alares|Casas Del Hospinal|Majada Blanca|Pozo Negro|Rosa Del Taro|Triquivijate
35640	La Oliva|Villaverde
35649	Caldereta, La (La Oliva)|Esquinzo (La Oliva)|Parque Holandes|Taca|Tindaya|Vallebron
35650	El Cotillo|Lagos, Los (Urbanizacion)|Lajares (La Oliva)|Majanicho|Roque, El (Cotillo)
35660	Corralejo|Corralejo Playa|Geafond|Lobos, Isla De|Tres Islas
36001	Pontevedra
36002	Pontevedra
36003	Pontevedra
36004	Pontevedra
36005	Pontevedra
36070	Pontevedra
36071	Pontevedra
36080	Pontevedra
36100	Centro Militar Base General Morillo (Usba)
36110	Campo Lameiro (San Miguel)|Lagoa, A (Campo Lameiro)
36116	Castro (Cerdedo)|Quireza (Cerdedo)|Tomonde (Cerdedo)
36117	Montes (Campo Lameiro)
36118	Fragas (Santa Mariña)
36119	Couso (Campo Lameiro)|Moimenta (Campo Lameiro)|Morillas (Santiago)
36120	Tenorio (San Pedro)|Vilanova (Tenorio)
36121	Sacos (Santa Maria)|San Xurxo De Sacos (Cotobade)|Viascon (Santiago)
36139	Cerdedo|Cerdedo (San Xoan)|Figueroa (San Martiño)|Pedre (Santo Estevo)
36140	Balteiro (Figueirido)|Figueirido (Santo Andre)|Santa Comba De Bertola (Santa Comba)
36141	Acuña (Vilaboa)|Paredes (Vilaboa)|Vilaboa (San Martiño)
36142	Barciela (Cobres)|Cobres (Santo Adran)|Muiño, O (Cobres)|Nores (Cobres)|Pazos (Cobres)|Pousada (Cobres)|Santa Cristina De Cobres (Vilaboa)
36143	Cabanas (Salcedo)|Carramal, O (Salcedo)|Pontevedra|Salcedo (San Martiño)
36150	Couso, O (Santo Andre De Xeve)|Filgueira (Santo Andre De Xeve)|Fragoso (Santo Andre De Xeve)|Sobral (Santo Andre De Xeve)|Xeve (Santo Andre)
36151	Covadaspera (Verducido)|Fontans, Os (Santa Maria De Xeve)|Gatomorto (Santa Maria De Xeve)|Igrexa, A (Santa Maria De Xeve)|Santa Maria De Xeve (Santa Maria)|Verducido (San Martiño)
36152	Cerponzons (San Vicente)
36153	Lourizan
36154	Bora (Santa Mariña)
36156	Castelo, O (Lerez|Lerez (San Salvador)|Pontevedra
36157	Alba (Santa Maria)|Campaño (San Pedro)|Devesa, A (Alba)|Sabaris (Campaño)|Vao, O (Poligono Ndustrial)
36158	Barcia, A (Marcon)|Ermida, A (Marcon)|Lusquiños (Tomeza)|Marcon (San Miguel)|Pazos (Marcon)|Pintos (Marcon)|Tomeza (San Pedro)|Valadares (Marcon)
36160	Pontevedra
36161	Pontevedra
36162	Pontevedra
36163	Poio (San Salvador)|Pontevedra
36164	Areas (Mourente)|Areas (Parroquia Mourente)|Casas Novas (Mourente)|Mourente (Santa Maria)|Pazo, O (Mourente)|Pontevedra
36190	Agudelo (San Martiño )
36191	Barro (San Breixo)|Porrans (Barro)
36192	Armenteira (Santa Maria)
36193	Valiñas (Santo Andre)
36194	Perdecanai (Santa Maria)
36201	Vigo
36202	Vigo
36203	Vigo
36204	Vigo
36205	Vigo
36206	Vigo
36207	Vigo
36208	Vigo
36209	Vigo
36210	Vigo
36211	Vigo
36212	Vigo
36213	Vigo
36214	Vigo
36215	Vigo
36216	Vigo
36270	Vigo
36271	Vigo
36280	Vigo
36281	Vigo
36282	Vigo
36300	Baiona (Casco Urbano)|Baiona (Santa Maria)|Cova Terreña (Baiona)|Loureiral (Baiona)|Percebelleira (Baiona)
36307	Belesar (San Lourenzo)|Medialdea (Baiona)|Urgal (Baiona)
36308	Baiña (Santa Mariña)|Burgo, O (Baiña)|Laxes, As (Baiña)
36309	Baredo (Santa Maria)|Mougas (Santa Uxia)|Pedornes (San Mamede)|Viladesuso (San Miguel)
36310	Vigo
36312	Vigo
36313	Vigo
36314	Vigo
36315	Vigo
36316	Brandufe (Vincios)|Ervillas (Vincios)|Fraga, A (Vincios)|Rocha, A (Vincios)|Vincios (Santa Mariña)
36317	Vigo
36318	Vigo
36320	Chapela (Casco Urbano)|Chapela (San Fausto)
36330	Vigo
36331	Vigo
36339	Vigo
36340	Area Alta, A (Panxon)|Bouza Vella, A (Panxon)|Gaifar (Panxon)|Panxon (San Xoan)|Patos (Panxon)|Porqueira, A (Panxon)|San Xoan (Panxon)
36350	Angustia, A (Nigran)|Canido (Nigran)|Nigran (San Fiz)|Tarela, A (Nigran)|Telleiras, As (Nigran)|Vilamean (Nigran)
36360	Camos (Santa Baia)|Chandebrito (San Xose)|Tomadas, As (Chandebrito)
36370	Cabreira, A (Ramallosa)|Cotros, Os (Ramallosa)|Golada, A (Ramallosa)|Ramallosa, A (San Pedro)|Tomadas, As (Ramallosa)|Vilariño De Abaixo (Ramallosa)|Viso, O (Ramallosa)|Xesteira, A (Ramallosa)
36378	Borreiros (San Martiño)
36379	Con (Parada)|Mallon (Ramallosa)|Parada (Nigran)
36380	Gondomar (Casco Urbano)|Gondomar (San Bieito)|Vilaza (Santa Maria)
36388	Donas (Santa Baia)|Mañufe (San Vicente)
36389	Bastida, A (Couso)|Chain (Santa Maria)|Couso (Gondomar)|Morgadans (Santiago)|Peitieiros (San Miguel)|Prado (Morgadans)|Vilas (Morgadns)
36390	Canido (Oia)|Vigo
36391	Albores Grande (Priegue)|Prado (Priegue)|Priegue (San Mamede)
36392	Vigo
36393	Outeiro, O (Ramallosa, A)|Sabaris (Ramallosa, A)|Santa Cristina Da Ramallosa|Xuncal, O (Ramallosa, A)
36400	Porriño, O (Casco Urbano)|Porriño, O (Santa Maria)
36410	Noval, O (Torneiros)|Relva, A (Torneiros)|Ribeira, A (Torneiros)|Torneiros (San Salvador)
36411	Cans (Santo Estevo)
36412	Arrotea, A (Pontellas)|Pontellas (Santiago)
36413	Mosende (San Xurxo)
36414	Chenlo (San Xoan)
36415	Arrufana (Louredo)|Castro, O (Mos)|Gandara, A (Mos)|Louredo (San Salvador)|Mos (Santa Eulalia)
36416	Casal, O (Tameiga)|Estibada, A (Petelos)|Igrexa, A (Tameiga)|Pedraucha (Tameiga)|Petelos (San Mamed)|Portela, A (Tameiga)|Porteliña, A (Petelos)|Tameiga (San Martiño)|Veigadaña (Petelos)
36417	Castros, Os (Dornelas)|Cotiño, O (Dornelas)|Dornelas (Santa Maria)|Guizan (Santa Maria)|Sobrans, As (Guizan)|Torroso (San Mamede)
36418	Albarin (Atios)|Atios (Santa Eulalia)|Covelo, O (Atios)|Eidos, Os (Atios)|Rocha, A (Atios)
36419	Ameiro Longo (Sanguiñeda)|Campo De Eiro (Pereiras)|Cela (San Pedro)|Erville (Cela)|Pereiras (San Miguel)|Sanguiñeda (Santa Maria)
36420	Crecente (San Pedro)
36428	Angudes (San Xoan)|Freixo, O (San Roque)|Sendelle (Santa Cruz)
36429	Albeos (San Xoan)|Vilar (Crecente)
36430	Arbo (Casco Urbano)|Arbo (Santa Maria )|Consistorio (Arbo)|Estacion, A (Arbo)
36435	Barcela (San Xoan )
36436	Cabeiras (San Sebastian )
36437	Mourentan (San Cristovo )
36438	Cequelinos (San Miguel )
36440	Neves, As (Casco Urbano)|Neves, As (Santa Maria)
36446	San Cibran De Ribarteme (San Cibran)|Setados (Santa Euxenia)|Vide (Santa Maria)
36447	Cerdeira (San Xoan)|San Xose De Ribarteme (Neves, As)|Santiago De Ribarteme (Neves, As)
36448	Batallans (Santa Eulalia)|San Pedro De Batallans (Neves, As)|Taboexa (Santa Maria)
36449	Liñares (Santa Maria)|Rubios (San Xoan)|Tortoreos (Santiago)
36450	Castelo, O (Salvaterra)|Salvaterra De Miño (Casco Urbano)|Salvaterra De Miño (San Lourenzo)
36455	Fornelos (San Xoan)|Fraguiñas, As (Fornelos)|Lourido (Santo Andre)
36456	Chan Da Igrexa (Pesqueiras)|Pesqueiras (Santa Mariña)
36457	Corzans (San Miguel)|Fiolledo (San Paio)|Leirado (San Salvador)|Meder (Santo Adrian)|Nogueiro (Meder)|Oleiros (Santa Maria)|San Roque (Leirado)|Soutolobre (Santa Comba)
36458	Alxen (San Paio)|Arantei (San Pedro)|Cabreira (San Miguel)|Igrexa, A (Alxen)|Igrexa, A (Arantei)|Porto (San Paulo)
36459	Lira (San Simon)|Uma (Santo Andre)|Vilacoba (San Xoan)
36460	Soutelo (San Vicente)
36470	Esfarrapada, A (Salceda)|Salceda De Caselas (Nucleo)|San Xurxo De Salceda (San Xurxo)|Santa Maria De Salceda (Santa Maria)|Venda Nova, A (Salceda)
36471	Entenza (Santos Xusto E Pastor)
36472	Parderrubias (San Tome)|Revolta, A (Parderrubias)
36474	Picoña, A (San Martiño)
36475	Casal, O (Budiño)|Gandaras, As (Poligono Industrial)|San Salvador De Budiño (Porriño, O)|Santo Estevo De Budiño (Santo Estevo)
36490	Filgueira (San Pedro)
36491	Ameixeira, A (San Bernabeu)|Rebordechan (Santa Maria)
36492	Quintela (Creciente)
36493	Ribeira (Creciente)
36494	Sela (Santa Maria )
36500	Lalin (Casco Urbano)|Lalin De Arriba
36510	Bailas (Goias)|Goias (San Miguel)|Palmaz (Goias)|Pareizo (Goias)|Xaxan (Pª Santa Maria De Saleta)|Xaxan (Santa Maria Da Saleta)
36511	Alceme (Santa Maria)|Arnego (Santiago)|Carboentes (Santo Estevo)|Pedroso (San Xiao)|Riobo (Rodeiro)|San Martiño De Asperelo (Rodeiro)|San Paio De Senra (Rodeiro)
36512	Anzo (San Xoan)|Bendoiro (San Miguel)|Busto (San Facundo)|Filgueira (Santa Maria)|Loson (Santa Baia)|Madriñan (San Adrao)|Meixome (Santiago)|Noceda (Santa Maria)|Prado (Lalin)|Santiso (San Roman)
36514	Cadron (Santo Estevo)|Moimenta (Lalin)
36515	Donramiro (Santa Maria)|Moneixas (San Adrao)|Vilanova (San Xoan)|Xesta (Pª San Pedro Felix)|Xesta, A (San Fiz)
36516	Albarellos (Santa Maria)|Alemparte (Lalin)|Castro (Lalin)|Maceira (San Martiño)|Saa (Dozon)|Sisto, O (San Xoan)|Vilarello (Santo Andre)
36517	Bermes (Santa Maria)|Cangas (Lalin)|Cello (San Martiño)|Palmou (San Xoan)|Sello (Santiago)
36518	Bidueiros (Santa Maria)|Castro, O (Dozon)|Castro,O (San Salvador)|Catasos (Santiago)|Dozon (Santa Maria)|Maceiras, As (San Remixio)|Sanguiñedo (Santa Maria)
36519	Ansean (Santiago)|Barcia (Santo Estevo)|Botos (San Xoan)|Cristimil (San Xurxo)|Doade (San Pedro)|Donsion (Santa Baia)|Gresande (Santiago)|Lalin (Santa Maria Das Dores)|Lebozan (Santiago)|Lodeiro (San Paio)|Soutolongo (Santa Maria)|Vilatuxe (San Lourenzo)|Zobra (Santa Maria)
36520	Agolada|Esperante (San Cibrao)|Ferreiroa (San Pedro)
36524	Brantega (San Lourenzo)|Carmoega (San Pedro)|Feira Nova (Agolada)|Santa Comba (San Xoan)
36525	Borraxeiros (San Cristovo)
36526	Agra (San Miguel)|Brocos (San Miguel)|Sesto (San Cibrao)|Sexo, O (Santiago)|Val De Sangorza (Santa Maria)
36527	Basadre (Santa Maria)|Basadroa (Agolada)|Eidian (Santiago)|Ramil (Pª San Martiño)|Ramil (San Martiño)
36528	Albergue (Agolada)|Artoño (Santalla)|Baiña, A (San Pedro)|Berredo (Santa Maria)|Merlin (San Pedro)|Orrea (Santo Andre)|San Paio De Bais (Agolada)|Vilariño (Pª Santa Maria)
36529	Gurgueiro (San Miguel)|Laxe (Agolada)|Parada (Lalin)|Trabancas, As (San Mamede)|Ventosa (San Xulian)
36530	Rodeiro (San Vicente)
36537	Fafian (Santiago)|Rio (Pª Santa Maria)|Rio (Santa Maria)|Santa Baia De Camba (Rodeiro)|Vilela (Santa Maria)
36538	Guillar (Santa Maria)|Negrelos (San Cibrao)|San Cristovo De Az (San Cristovo)|Santa Mariña De Pescoso (Rodeiro)
36539	Camba (San Xoan)|Portela (Rodeiro)|Salto, O (San Estevo)|San Salvador De Camba (Rodeiro)
36540	Silleda (Casco Urbano)|Silleda (Santa Baia)
36542	Refoxos (San Paio)
36543	Ponte (San Miguel)|Taboada (Santiago)|Vilar (Silleda)
36544	Laro (San Salvador)|Parada (Silleda)
36545	Cortegada (Santa Maria)|Oleiros (San Miguel)
36546	Ansemil (San Pedro)|Breixa (Santiago)|Carboeiro (Santa Maria)|Castro, O (San Mamede)|Martixe (San Cristovo)|Negreiros (San Martiño)|Saidres (San Xoan)
36547	Escuadro (San Salvador)|Rellas (San Martiño)|Siador (San Miguel)
36548	Fiestras (San Martiño)|Graba (San Miguel)|Margaride (San Fiz)|Xestoso (Santa Maria)
36550	Forcarei (Casco Urbano)
36555	Aciveiro (Santa Maria)|Ventoxo (San Nicolao)
36556	Forcarei (San Martiño)|Millarada (San Amedio)
36557	Meavia (San Xoan)|Pereira (San Bartolomeu)|Quintillan (San Pedro)
36558	Castrelo (Santa Mariña)|Folgoso (Santa Maria)|Parada (Cerdedo)
36559	Duas Igrexas (Santa Maria)
36560	Soutelo De Montes
36567	Madanela De Montes, A (Santa Maria)
36568	Pardesoa (Santiago)
36569	San Miguel De Presqueiras (Forcarei)|Santa Mariña De Presqueiras (Forcarei)
36570	Bandeira, A|Chapa (San Cibrao)|Manduas (San Tirso)
36579	Cervaña (San Salvador)|Cervaña (Silleda)|Dornelas (San Martiño)|Lamela (San Miguel)|Moalde (San Mamede)|Piñeiro (Silleda)
36580	Bascuas (Santa Mariña)|Merza (Santa Maria)
36581	Sabrexo (Santa Maria)
36582	Carbia (San Xoan)
36583	Fontao (Santiago)
36584	Arnois (San Xiao)|San Miguel De Castro (Estrada, A)
36585	Añobre (San Pedro)|Brandariz (San Miguel)|Obra (San Tome)
36586	Ollares (Santa Maria)|Piloño (Santa Maria)|Salgueiros (San Pedro)
36587	Camanzo (San Salvador)|Cira (Santa Baia)|Gres (Santiago)
36588	Loimil (Santa Maria)|Orazo (San Pedro)
36589	Abades (Santa Maria)|Pazos (San Martiño)
36590	Cruces (Nosa Señora Da Piedade)|Vila De Cruces
36596	Camposancos (San Cristovo)|Cercio (Santiago)|Galegos (San Miguel)|Rodis (San Xiao)|Val Do Carrio (Santo Andre)
36597	Toiriz (San Xoan)
36598	Asorei (Santa Maria)|Besexos (San Fiz)|Bodaño (San Mamede)|Oiros (Santa Maria)|San Pedro De Loson (Vila De Cruces)
36599	Arnego (Vila De Cruces)|Cumeiro (San Pedro)|Duxame (San Miguel)|Ferreiros (San Xes)|Larazo (San Xoan)|Loño (San Mamede)|Portodemouros (San Salvador)|San Tome De Insua (Vila De Cruces)
36600	Fontecarmoa (San Pedro)|Vilagarcia (Parroquia Santa Eulalia)|Vilagarcia De Arousa
36610	Caldigüela (Pª Carril)|Carril (Pª Santiago De Afora)|Carril (Santiago)|Guillan (Pª Carril)
36611	Aralde (Sobran)|Faxilde (Sobran)|Lagoa, A (Sobran)|Rosaleda (Sobradelo)|Sobradelo (San Salvador)|Sobran (San Martiño)|Vilaboa (Sobradelo)|Vilaxoan (Vilagarcia)
36612	Abalo (San Mamede)|Catoira (San Miguel)|Coaxe (Dimo)|Cores (Abalo)|Corredoira, A (Catoira)|Dimo (San Pedro)|Menda, A (Dimo)|Oeste (Santa Baia)|Outeiriño, O (Catoira)|Ponte, A (Catoira)|Progreso, O (Oeste)|Tarrio (Dimo)
36613	Arealonga (Vilagarcia De Arousa)|Bocas (Pª Arealonga)|Laxe (Pª Arealonga)|Torre (Pª Arealonga)|Trabanca Badiña (Pª Arealonga)
36614	Baion (San Xoan)|Rabuñade
36615	Godos (Santa Maria)
36616	Paradela (Meis)
36617	Castrogudin (Cea)|Cea (San Pedro)|Vento, O (Cea)
36618	Bamio (San Xens)|Campanario, O (Bamio)|Casal, O (Bamio)|Trabanca Sardiñeira (Carril)|Vilar (Bamio)
36619	Cornazo (San Pedro)|Cruz, A (Cornazo)|Paradela De Arriba (Cornazo)|Rubians (Santa Maria)|Solobeira (San Felix)
36620	Sinas, As (Vilanova De Arousa)|Vilamaior (Caleiro)|Vilanova De Arousa|Vilanova De Arousa (Casco Urbano)
36626	Illa De Arousa, A (San Xulian)
36627	Cardalda (Deiro)|Deiro (San Miguel)|Igrexa, A (Deiro)|Monte, O (Deiro)|San Roque Do Monte (Deiro)|Viña Grande (Deiro)
36628	Andras (San Lourenzo)|Cruceiro, O (Andras)|Deiro (Tremoedo)|Tremoedo (Santo Estevo)
36629	Aduana De Coron, A (Caleiro)|Caleiro (Santa Maria)|Coron (Caleiro)|Curras (Caleiro)|Ousensa (Caleiro)|Pantrigueira, A (Caleiro)|Saradelo (Caleiro)
36630	Cambados (Santa Mariña)
36633	Covas De Lobos (Vilariño)|Cruceiro, O (Vilariño)|Modia, A (Vilariño)|Sameiro (Vilariño)|Sineiro, O (Vilariño)|Vilariño (Cambados)
36634	Cabana, A (Corvillon)|Corvillon (San Amedio)|Laxes, As (Corvillon)|Ribeiro, O (Corvillon)|Rio Da Ucha, O (Corvillon)|Tragove (Corvillon)
36635	Leiro (San Xoan)|Leiromean (Leiro)|Lois (San Fins)|Oubiña (San Vicenzo)
36636	Barrantes (Ribadumia)|Barroso (Sisan, Ribadumia)|Besomaño (Santa Maria)|Carrasqueira (Sisan, Ribadumia)|Couto De Arriba (Barrantes)|Escusa, A (Ribadumia)|Freixo, O (Ribadumia)|Mosqueiro (Sisan, Ribadumia)|Ribadumia (Santa Baia)|Sisan (San Clemente-Ribadumia)
36637	Meis (San Salvador)|Mosteiro, O (Meis)|Nogueira (San Vicente)|San Lourenzo De Nogueira (Meis)|San Martiño De Meis (San Martiño)|San Tome De Nogueira (Meis)
36638	Covas (Santa Cristina)|Padrenda (San Martiño)
36639	Bouza, A (Castrelo)|Castrelo (Santa Cruz)|Couto De Abaixo, O (Castrelo)|Couto De Arriba, O (Castrelo)|Facho, O (Castrelo)|Xesteira (Castrelo)
36640	Carreiras (Pontecesures)|Infesta (Pontecesures)|Pontecesures (Casco Urbano)|Pontecesures (San Xulian)|Portarraxoi (Pontecesures)|Porto De Arriba (Pontecesures)|San Luis (Pontecesures)|San Xulian (Pontecesures)
36645	Valga (San Miguel)
36646	Casal De Eirigo (Setecoros)|Setecoros (San Salvador)
36647	Campaña (Santa Cristina)|Cordeiro (Santa Comba)|Ferreiros (Cordeiro)|Forno, O (Cordeiro)|Vilar (Cordeiro)
36648	Torre, A (Campaña)|Xanza (Santa Maria)
36649	Devesa, A (Campaña)
36650	Caldas De Reis (Casco Urbano)
36652	Romai (San Xian)|Xagove-Vilavedra (Romai)
36653	Santo Andre De Cesar (Santo Andre)
36654	San Clemente De Cesar (San Clemente)
36655	Arcos Da Condesa (Santa Mariña)|Caldas De Reis (Santa Maria)
36656	Saiar (Santo Estevo)
36657	Lantaño (San Pedro)
36658	Briallos (San Cristovo)|Portas (Santa Maria)
36659	Bemil (Santa Maria)|Carracedo (Santa Mariña)|Follente (Bemil)|Gorgullon, O (Carracedo)|Outeiro (Bemil)|Paradela (Bemil)
36660	Santa Lucia De Moraña
36667	San Lourenzo De Moraña (San Lourenzo)
36668	Cosoirado (Santa Maria)|Gargantans (San Martiño)|Lamas (Santa Cruz)|Laxe (San Martiño)|Santa Xusta De Moraña (Santa Xusta)
36669	Amil (San Mamede)|Rebon (San Pedro)|Saians (San Salvador)
36670	Cuntis (Casco Urbano)
36675	Troans (Santa Maria)
36676	San Xiao De Vea (Estrada, A)|Santo Andre De Vea (Estrada, A)
36677	Arcos (Cuntis)|Couselo (San Miguel)|Portela (Cuntis)
36678	Cequeril (Santa Maria)|Cuntis (Santa Maria)
36679	Estacas (San Fiz)|Piñeiro (Cuntis)
36680	Estrada, A (Casco Urbano)
36681	Estrada, A (San Paio)|Guimarei (San Xiao)|Ouzande (San Lourenzo)
36682	Baloira (San Salvador)|Cora (San Miguel)|Couso (Estrada, A)|Santa Cristina De Vea (Estrada, A)|Toedo (San Pedro)
36683	Barcala (Santa Mariña)|Frades (Santa Maria)|San Miguel De Barcala (Estrada, A)|San Xurxo De Vea (Estrada, A)
36684	Arca (San Miguel)|Codeseda (San Xurxo)|Liripio (San Xoan)|Nigoi (Santa Maria)|Parada (Estrada, A)|Sabucedo (San Lourenzo)|Somoza (Santo Andre)|Souto (Santo Andre)|Tabeiros (Santiago)
36685	Agar (Santa Mariña)|Aguions (Santa Maria)|Barbude (San Martiño)|Oca (Santo Estevo)|Paradela (Estrada, A)|Remesar (San Cristovo)|Ribeira (Santa Mariña)|Riobo (Estrada, A)|San Pedro De Ancorados (Estrada, A)
36686	Curantes (San Miguel)|Lamas (San Breixo)|Olives (Santa Maria)|Pardemarin (Santa Baia)|Rubin (Santa Maria)|San Tome De Ancorados (Estrada, A)
36687	Cereixo (San Xurxo)|Lagartons (Santo Estevo)|Ribela (Santa Mariña)|Vinseiro (Santa Cristina)
36688	Berres (San Vicenzo)|Callobre (San Martiño)|Moreira (San Miguel)
36689	Matalobos (Santa Baia)|Santeles (San Xoan)
36690	Acevedo (Ponte Sampaio)|Arcade (Santiago)|Calle, A (Arcade)|Canicouva, A (Santo Estevo)|Conde, O (Arcade)|Devesa, A (Arcade)|Ponte Sampaio (Santa Maria)|Xesteira, A (Arcade)
36691	Aranza (Soutomaior)|Comboa (Soutomaior)|Lourido (Soutomaior)|Moreira (Soutomaior)|Rial, O (Soutomaior)|Romariz (Soutomaior)|Soutomaior (San Salvador)
36692	Bretoña (Curro)|Curro (Santa Maria)|Estacion De Portela (Portela)|Fonte Do Curro (Curro)|Portela (San Mamede)|San Amaro (Portela)
36693	Cesantes (San Pedro)
36700	Tui (Casco Urbano)|Tui (O Sagrario)
36710	Ribadelouro (Santa Comba)
36711	Areas (Santa Mariña)|Pexegueiro (San Miguel)
36712	Rebordans (San Bartolomeu)
36713	Estrada, A (Randufe)|Randufe (Santa Maria)
36714	Malvas (Santiago)
36715	Pazos De Reis ( O Sagrario)
36720	Albelos (Guillarei)|Cegoñeiras, As (Guillarei)|Gandara, A (Guillarei)|Guillarei (San Mamede)|Sobredo (Guillarei)
36721	Caldelas De Miño (San Martiño)
36729	Baldrans (Santiago)|Baños, Os (Caldelas)|Paramos (San Xoan)
36730	Aldea (Forcadela-Tomiño)|Estas (Tomiño)|Forcadela (Tomiño)|Solleiro (Forcadela-Tomiño)|Vilardematos (Forcadela-Tomiño)
36739	Achan (Taborda-Tomiño)|Aldea (Taborda-Tomiño)|Bouzada (Piñeiro-Tomiño)|Bouzon (Piñeiro-Tomiño)|Pazo (Taborda-Tomiño)|Piñeiro (Tomiño)|Taborda (Tomiño)|Tomada (Taborda-Tomiño)
36740	Barro (Tomiño)|Cotro (Tomiño)|Gandara (Tomiño)|Hospital (Tomiño)|Mosteiro (Tomiño)|Pedra (Tomiño)|San Benito (Tomiño)|Seijo (Zona Urbana Tomiño)|Solleiro (Tomiño)|Tomiño (Santa Maria)|Vilachan (Tomiño)|Vilar (Tomiño)
36746	Cimadevila (Santa Maria De Tebra-Tomiño)|Igrexa (Santa Maria De Tebra-Tomiño)|Outeiro (Santa Maria De Tebra-Tomiño)|Ponteciña (Santa Maria De Tebra-Tomiño)|Samuelle (Santa Maria De Tebra-Tomiño)|Santa Maria De Tebra (Tomiño)
36747	Ral (Vilamean-Tomiño)|Vilamean (Tomiño)
36748	Casal (San Salvador De Tebra-Tomiño)|Lubian (San Salvador De Tebra-Tomiño)|San Salvador De Tebra (Tomiño)
36749	Barrantes (Tomiño)|Cristelos (Barrantes-Tomiño)|Mosteiro (Barrantes-Tomiño)|Pazo (Barrantes-Tomiño)|Pinzas (Tomiño)|Solvado (Barrantes-Tomiño)
36750	Avenida Brasil (Goian-Tomiño)|Avenida Ordoñez (Goian-Tomiño)|Centinela (Goian-Tomiño)|Couto (Goian-Tomiño)|Fontenla (Goian-Tomiño)|Gandara (Goian-Tomiño)|Goian (Tomiño)|Soutelo (Goian-Tomiño)|Tollo (Goian-Tomiño)
36760	Carrascal (San Miguel De Tabagon-O Rosal)|Cotro (San Miguel De Tabagon-O Rosal)|Cruceiro (San Miguel De Tabagon-O Rosal)|Cumieira (San Miguel De Tabagon-O Rosal)|Eiras, As (O Rosal)|Igrexa (Eiras, O Rosal)|Paradela (San Xoan De Tabagon-O Rosal)|Pias (San Miguel De Tabagon-O Rosal)|Portela (San Xoan De Tabagon-O Rosal)|Rua Da Baixo (San Xoan De Tabagon-O Rosal)|Rua Da Cal (San Xoan De Tabagon-O Rosal)|San Miguel De Tabagon (O Rosal)|San Xoan De Tabagon (O Rosal)
36770	Calvario, O (Rosal,O)|Caselas (O Rosal)|Couselo (O Rosal)|Cruces, As (Rosal, O)|Cumieira De Abaixo (O Rosal)|Cumieira De Riba (O Rosal)|Cunchada ( O Rosal)|Fornelos ( O Rosal)|Lagos ( O Rosal)|Lomba (O Rosal)|Martin (O Rosal)|Marzan (Rosal, O)|Medas (O Rosal)|Miranxe (O Rosal)|Pancenteo (Rosal, O)|Portecelo (O Rosal)|Rosal, O (Santa Mariña)|Rotea (O Rosal)|Sandian (O Rosal)|Urgal (O Rosal)|Videira (O Rosal)|Viso Dos Eidos (Rosal, O)
36779	Burgueira (San Pedro)|Campo, O (Burgueira)|Loureza (San Mamede)
36780	Guarda, A (Casco Urbano)|Guarda, A (Santa Maria)
36788	Camposancos (Santa Isabel)|Outeiro, O (Camposancos
36789	Castro, O (Salcidos)|Coruto Vello, O (Salcidos)|Cruz, A (Salcidos)|Gandara, A (Salcidos)|Netos (Salcidos)|Salcidos (San Lourenzo)
36790	Aldea (Sobrada-Tomiño)|Gandara (Sobrada-Tomiño)|Gandariña (Sobrada-Tomiño)|Portela (Sobrada-Tomiño)|Sobrada (Tomiño)|Torron (Sobrada-Tomiño)
36791	Amorin (Tomiño)|Arrotea (Amorin-Tomiño)|Carregal De Abaixo (Amorin-Tomiño)|Carregal De Arriba (Amorin-Tomiño)|Curras (Tomiño)|Monte (Curras-Tomiño)|Outeiro (Amorin-Tomiño)
36792	Figueiro (Tomiño)|Lago (Figueiro-Tomiño)
36794	Arrabal, O (Oia)|Oia (Santa Maria)|Riña, A (Oia)
36800	Redondela (Casco Urbano)|Redondela (Santiago)
36810	Viso, O (Santa Maria)
36811	Trasmaño (San Vicente)
36812	Aldea, A (Cedeira)|Cedeira (Santo Andre)|Cruceiro, O (Cedeira)|Eira Pedriña, A (Cedera)|Formiga (Cedeira - Redondela)|Fortons (Cedeira)|Portela, A (Cedeira)|Rande (Cedeira)
36813	Cabeiro (San Xoan)
36814	Negros (Santo Estevo)|Pregal (Negros)
36815	Vilar De Infesta (San Martiño)
36816	Saxamonde (San Roman)|Valos, Os (Saxamonde)
36817	Cepeda (San Pedro)|Nespereira (San Martiño)|Quintela (San Mamede)
36818	Reboreda (Santa Maria)|Ventosela (San Martiño)
36820	Caldelas (Ponte Caldelas)|Cuñas (Ponte Caldelas)|Pazos (Ponte Caldelas)|Ponte Caldelas (Casco Urbano)|Ponte Caldelas (Santa Eulalia)
36826	Barbudo (Santa Maria)|Insua, A (Santa Mariña)|Silvoso (Insua)
36827	Chan Do Casal, O (Xustans)|Taboadelo (Santiago)|Xustans (San Martiño)
36828	Buchabade (Touron)|Touron (Santa Maria)|Vilarchan (Touron)
36829	Anceu (Santo Andre)|Caritel (Santa Maria)
36830	Lama, A (San Salvador)
36835	Seixido (San Bartolomeu)
36836	Xesta (San Bartolomeu)
36837	Barcia Do Seixo (Santa Ana)
36838	Escuadra (San Lourenzo)
36839	Covelo (San Sebastian)
36840	Amoedo (San Saturniño)|Igrexa, A (Amoedo)
36841	Ermida, A (Nosa Señora Da Anunciacion)|Pazos (Santa Maria)
36842	Borben (Santiago)
36843	Gorgoreiro, O (Moscoso)|Moscoso (San Paio)
36844	Xunqueiras (San Salvador)
36845	Calvos (Santo Adrian)
36846	Oitaven (San Vicente)
36847	Fornelos De Montes (San Lourenzo)|Igrexa, A (Fornelos De Montes)
36848	Ventin (San Miguel)
36849	Traspielas (Santa Maria)
36851	Estacas, As (Santa Maria)
36852	Laxe, A (Fornelos De Montes)
36853	Antas (Santiago)|Forzans (San Fiz)|Gaxate (San Pedro)|Verducido (Lama, A)|Xende (San Paulo)
36854	Aguasantas (Santa Maria)|Valongo (Santo Andre)
36855	Loureiro (Santiago)
36856	Carballedo (San Miguel)|Caroi (Santiago)|Corredoira (San Gregorio)
36857	Rebordelo (San Martiño)
36858	Borela (San Martiño)
36859	Almofrei (San Lourenzo)
36860	Canedo (Ponteareas)|Ponteareas (Casco Urbano)|Ponteareas (San Miguel)
36861	Areas (Ponteareas)|Gulans (San Xulian)
36862	Oliveira (Ponteareas)|Piñeiro (Oliveira)|Puzo (Oliveira)
36863	Cristiñade (San Salvador)|Moreira (San Martiño)|Nogueira (San Salvador)
36864	Oliveira (Santiago)|San Lourenzo De Oliveira (Ponteareas)
36865	Arcos (Ponteareas)|Celeiros (San Fins)|Correlo (Arcos)|Fontenla (San Mamede)|Serra (Arcos)
36866	Fozara (San Bartolomeu)|Padrons (San Salvador)|Paredes (Ponteareas)|Ribadetea (San Xurxo)
36867	Abelleira (Angoares)|Angoares (San Pedro)|Searas, As (Angoares)
36868	Guillade (San Miguel)
36869	Bugarin (Santa Cristina)
36870	Mondariz (Casco Urbano)|Mondariz (Santa Baia)
36872	Santiago De Covelo (Covelo, O)
36873	Campo (Covelo, O)|Fofe (San Miguel)|Godons (Santa Maria)|Graña, A (San Bernabeu)|Igrexa, A (Maceira)|Lamosa, A (San Bartolomeu)|Maceira (San Salvador)|Piñeiro, O (Covelo, O)|Prado (Covelo,O)|Prado De Canda (Santiago)
36874	Touton (San Mateo)|Vilar (Mondariz)
36875	Cernadela (Riofrio)|Frades (San Martiño)|Gargamala (Santa Maria)|Riofrio (San Miguel)
36876	Castelans (Santo Estevo)|Covelo (Santa Mariña)|Lougares (San Fiz)
36877	Meirol (Santo Andre)|Mouriscados (San Cibran)|Paraños (Santa Maria)|Queimadelos (Santa Maria)
36878	Barcia De Mera (San Martiño)|Sabaxans (San Mamede)|San Amaro, O (Barcia De Mera)
36879	Vilasobroso (San Martiño)
36880	Cañiza, A (Casco Urbano)
36883	Valeixe (Santa Cristina)
36884	Petan (San Xian)
36885	Oroso (Santa Maria)
36886	Couto, O (San Bartolomeu)
36887	Luneda (Santa Maria)|Parada Das Achas (Santiago)
36888	Achas, As (San Sebastian)|Cañiza, A (Santa Teresa)
36889	Franqueira, A (Santa Maria)
36890	Mondariz-Balneario
36891	Rocha, A (Xinzo)|Xinzo (Santa Mariña)
36892	Arnoso (San Lourenzo)
36893	Cumiar (Santo Estevo)
36895	Pias (Santa Mariña)|Prado (Ponteareas)
36900	Marin (Casco Urbano)|Marin (Parroquia Santa Maria Do Porto)
36910	Carballeira, A (Lourizan)|Estribela (Lourizan)|Praceres, Os (Lourizan)
36911	Barriada, A (Mogor)|Igrexario, O (Mogor)|Mogor (San Xurxo)
36912	Ardan (Santa Maria)|Casas (Ardan)|Moledo (Ardan)|Vilaseca (Ardan)
36913	Aguete (Seixo)|Montecelo (Seixo)|Seixo (Nosa Señora Do Carme)
36914	Cadrelo (Piñeiro)|Campo, O (Santa Maria)|San Tome De Piñeiro (Marin)
36915	Arealonga (Marin)|Carballal, O (Marin)|Igrexario, O (Marin)|Laxe, A (Marin)|Marin (Parroquia San Xulian De Afora)|Moreira, A (Marin)|Pardavila (Marin)
36920	Marin (Escuela Naval)
36930	Bueu (Casco Urbano)
36937	Achadiza, A (Beluso)|Beluso (Santa Maria)|Bon De Abaixo (Beluso)|Bon De Arriba (Beluso)|Cabalo, O (Beluso)|Montemogos (Beluso)|Roza, A (Beluso)|Rua Nova De Abaixo, A (Beluso)|Rua Nova De Arriba, A (Beluso)|Sar (Beluso)
36938	Castiñans, As (Cela)|Castrelo (Cela)|Cela (Santa Maria)|Ermelo (Santiago)|Sabarigo (Cela)|Torre, A (Cela)
36939	Bueu (S. Martiño)|Carrasqueira, A (Bueu)|Graña, A (Bueu)|Means, As (Bueu)|Meiro (Bueu)|Norte, O (Bueu)|Portela, A (Bueu)|Ramorta, A (Bueu)|Valado, O (Bueu)
36940	Cangas Do Morrazo
36945	Aldan (Cangas)|Donon (Hio-Cangas)|Espiñeira (Aldan - Cangas)|Herbello (Aldan - Cangas)|Hio (Cangas)|Iglesario (Hio - Cangas)|Limens (Hio - Cangas)|Menduiña (Aldan - Cangas)|Nerga (Hio - Cangas)|Pintens (Hio - Cangas)|Piñeiro (Aldan - Cangas)|San Cibran (Aldan - Cangas)|Vilanova (Hio - Cangas)|Vilariño (Hio - Cangas)
36946	Gandon (Aldan - Cangas)
36947	Coiro (San Salvador)|Espirito Santo, O (Coiro)|Forte, O (Coiro)|Gruncheiras, As (Coiro)|Pedreira, A (Coiro)|Reboredo (Coiro)|Retirosa, A (Coiro)|Romarigo (Coiro)|Rozada (Coiro)
36949	Balea (Darbo)|Cima De Vila (Darbo)|Cunchido (Darbo)|Darbo (Santa Maria)|Magdalena, A (Darbo)|San Pedro (Darbo)|San Roque Do Monte (Darbo)|Seixo, O (Darbo)|Serra De Poente, A (Darbo)|Ximeu (Darbo)
36950	Moaña (Casco Urbano)
36954	Abelendo (Moaña)|Ameixoada (Moaña)|Broullon (Moaña)|Casal, O (Moaña)|Cruceiro, O (Moaña)|Moaña (San Martiño)
36955	Couso (Meira)|Guia, A (Meira)|Isamil (Meira)|Laton, O (Meira)|Meira (Santa Eulalia)|Moureira, A (Meira)|Reibon (Meira)|Ribeira, A (Meira)
36957	Calvar, O (Domaio)|Costa, A (Domaio)|Domaio (San Pedro)|Palmas (Domaio)|Verdeal (Domaio)
36958	Fontes (Tiran)|Igrexario, O (Tiran)|Tiran (San Xoan)|Vilela (Tiran)
36959	Marrua, A (Moaña)|Moaña (Virxe Do Carme)|Paradela (Moaña)|Piñeiro, O (Moaña)|Quintela (Moaña)|Redondo (Moaña)|Sabaceda (Moaña)|Verducedo (Moaña)
36960	Sanxenxo (Casco Urbano)
36966	Bordons (San Pedro)|Costa, A (Dorron)|Dorron (San Xoan)|Granxa, A (Dorron)
36967	Coiron (Dena)|Dena (Santa Eulalia)|Eirexe, A (Dena)|Seixiños, Os (Dena)|Viliquin (Dena)
36968	Xil (Santa Eulalia)
36969	Carabuxeira, A (Padriñan)|Lores (San Miguel)|Nantes (Santa Baia)|Padriñan (San Xenxo)|Simes (Santa Maria)
36970	Portonovo (Adina)
36979	Adina (Santa Maria)|Arra (San Amaro)|Baltar (Adina)|Barbeito (Adina)|Vista Alegre (Adina)
36980	Grove, O (Casco Urbano)
36988	Balea (Grove, O)|Campos, Os (Grove, O)|Reboredo (Grove, O)|San Vicente Do Grove (San Vicente)
36989	Ardia (Grove, O)|Campos (Grove, O)|Con, O (Grove, O)|Grove, O (San Martiño)|Meloxo (Grove, O)|Porto De Meloxo, O (Grove, O)|Virxe Das Mareas (Grove, O)
36990	Aios (Noalla)|Fonte De Ons (Noalla)|Gondar (San Tome)|Mourelos (Noalla)|Noalla (Santo Estevo)|Rouxique (Vilalonga)|Salgueira, A (Vilalonga)|Soutullo (Noalla)|Vilalonga (San Pedro)|Vilar (Vilalonga)
36991	Toxa (Illa Da)
36992	Aren (Samieira)|Covelo, O (Samieira)|Raxo (San Gregorio)|Samieira (Santa Maria)
36993	Chancelas (Combarro)|Combarro (San Roque)
36995	Aris (Poio)|Campelo (Poio)|Casal, O (Poio)|Casalvito (Poio)|Liñares (Poio)|Muiño (Poio)|Poio (San Xoan)|Sartal, O (Poio)|Seara, A (Poio)
37001	Salamanca
37002	Salamanca
37003	Salamanca
37004	Salamanca
37005	Salamanca
37006	Salamanca
37007	Salamanca
37008	Salamanca
37009	Salamanca
37071	Salamanca
37080	Salamanca
37100	Ledesma
37110	Aldearrodrigo|El Arco|San Pelayo De La Guareña|Santiz|Torresmenudas|Zamayon
37111	Añover De Tormes|Espino Rapado|Palacino|Palacios Del Arzobispo
37114	Encina De San Silvestre|Espayos|Gejuelo Del Barro|La Huerfana|Muelledes|Valrubio|Villaseco De Los Gamitos
37115	Almenara De Tormes|Baños De Ledesma|Contiensa|Frades Nuevo|Frades Viejo|Juzbado|Valverdon
37116	Aldeagutierrez|Cuadrilleros|Cuadrilleros De Los Dieces|Estacas|Estanquillas|La Samasa|La Samasita|La Vadima|Pelilla|Sagrada, La (Ledesma)|Santo Domingo|Zorita
37120	Cabrasmalas|Calzadilla De La Valmuza|Doñinos De Salamanca|La Golpejera|Torre De La Valmuza
37129	Argentina|Carrascal De Barregas|Florida De Liebana|Palacio De Villalones|Parada De Arriba|Puerto De La Anunciacion|San Justo De La Valmuza|Santibañez Del Rio|Villaselva
37130	Carreros (Finca)|Cojos De Robliza (Finca)|Doñinos De Ledesma|Mata De Ledesma|Padierno (Finca)|Porqueriza (Finca)|Quejigal|Robliza De Cojos|San Roman (Finca)|Tabera De Abajo|Teso Del Corcho (Finca)|Valdefresno (Finca)|Villarmayor|Zafron
37139	El Barrero De Porqueriza|El Gejo
37140	El Campo De Ledesma
37147	Villar De Peralonso
37148	Becerril|Espadaña|Pedernal|Peñalvo|Sardon De Los Alamos|Tremedal De Tormes
37149	Cuadrillero De Los Gusanos|Trabadillo
37150	Gejo De Los Reyes|Villaseco De Los Reyes
37159	Berganciano|Cerezal De Puertas|El Groo|Manceras|Puertas
37160	Villarino De Los Aires
37170	Cabra, La (Finca)|Carrascal De Velambeles|Carrascalino|El Carmen|El Pino De Tormes|Espino De Los Doctores (Finca)|Golpejas|La Narra|Pozos De Mondar (Finca)|San Pedro Del Valle|Tirados De Vega|Torrecilla De Miranda|Vega De Tirados|Zarapicos|Zaratan
37171	El Manzano|Monleras
37172	Sardon De Los Frailes
37173	Ahigal De Villarino|Trabanca
37174	Cabeza De Framontanos
37175	Pereña De La Ribera
37176	Almendra|Salto De Almendra
37181	Amatos Del Rio|Calvarrasa De Abajo|Naharros Del Rio (Alqueria)|Nuevo Amatos|Nuevo Naharros (Urbanizacion)|Nuevos Naharros|Pelabravo|Valdecarretas (Urbanizacion)
37183	Aldealgordo De Abajo|Aldealgordo De Arriba|Bernoy|Cilleros El Hondo|Morille|Orejudos|Rozados|San Pedro De Rozados|Sanchoviejo|Santo Tome De Rozados|Torre De Juan Vazquez
37184	Bizarricas, Las (Urbanizacion)|Poligono Los Villares Reina|Villares De La Reina
37185	Mozodiel De Sanchiñigo|Villamayor|Zorita De Valverdon
37186	Carrascalino De La Valmuza|Continos|Otero De Vaciadores|Salvadorique|Terrubias|Turra
37187	Aldeagallega|Aldeanueva De Ariseos|Aldeatejada|Miranda De Azan|Porquerizos|Torrecilla|Vistahermosa (Sotomuñiz)
37188	Carbajosa De La Sagrada|La Pinilla
37189	Aldeaseca De La Armuña
37190	Cisnes, Los (Urbanizacion)|Encinar, El (Urbanizacion)
37191	Albahonda (Urbanizacion)|Calvarrasa De Arriba|Navahonda (Urbanizacion)
37192	Montalvo I|Montalvo Ii|Montalvo Iii|Montalvo Iv|Montalvo Rano|Peñasolana (Urbanizacion)|Sanatorio Martinez Anido
37193	Aldehuela De Los Guzmanes|Arenal Del Angel|Cabrerizos|Dunas, Las (Urbanizacion)|La Flecha
37197	Ariseos
37198	Carpihuelo
37200	La Fuente De San Esteban
37207	Fuente San Esteban, La (Estacion)
37208	Boadilla|San Muñoz
37209	Buenamadre|Campos De Buenamadre|Pelarrodriguez
37210	Vitigudino
37214	Cabeza De Caballo|Fuentes De Masueco|La Peña|La Vidola|Valsalabroso
37216	Ciperez|Escuernavacas|Gomeciego|La Moralita|Peralejos De Abajo|Peralejos De Arriba|Pozos De Hinojo|Traguntia (Finca)
37217	Barceino|Barceo|Brincones|Carrasca|Carrasco|Iruelos|Las Uces|Robledo Hermoso|Sanchon De La Ribera|Villar De Samaniego|Villargordo|Villarmuerto
37219	Casales, Los (Finca)|Gema|Guadramiro|Yecla De Yeltes
37220	Fregeneda (Pueblo)
37230	Hinojosa De Duero
37240	Lumbrales
37246	Sobradillo
37247	La Redonda
37248	Ahigal De Los Aceiteros
37250	Aldeadavila De La Ribera|Majuges
37251	Corporario|Masueco
37253	Cerezal De Peñahorcada|La Zarza De Pumareda|Salto De Aldeadavila La Ribera
37254	Mieza
37255	Barruecopardo
37256	Barreras|El Milano|Encinasola De Los Comendadores|Picones|Valderrodrigo|Villasbuenas
37257	Salto De Saucelle|Saucelle
37258	Moronta|Vilvestre
37259	Saldeana
37260	Villavieja De Yeltes
37267	Pedro Alvaro|Villares De Yeltes
37269	La Cañada
37270	San Felices De Los Gallegos
37271	Bañobarez
37281	El Cubo De Don Sancho|Ituerino|Ituero De Huebra
37290	Boada|Las Porciones
37291	Bermellar|Bogajo|Cerralbo|Fuenteliante
37292	Olmedo De Camaces
37300	Peñaranda De Bracamonte
37310	Macotera
37311	Santiago De La Puebla
37312	Alaraz
37313	Malpartida
37314	Salmoral
37315	Mancera De Abajo
37316	Boveda Del Rio Almar
37317	Aldeaseca De La Frontera|Aldeayuste|El Campo De Peñaranda
37318	Paradinas De San Juan|Ragama
37319	Cantaracillo
37320	Villar De Gallimazo
37329	Alconada|San Vicente De Alconada|Ventosa Del Rio Almar
37330	Babilafuente
37336	Huerta
37337	Cordovilla|Moriñigo
37338	Villoruela
37339	Villoria
37340	Aldearrubia|San Morales
37350	Aldealengua
37400	Cantalapiedra
37405	Cantalpino
37406	Palacios Rubios|Poveda De Las Cintas|Villaflores
37408	Zorita De La Frontera
37409	Tarazona De La Guareña
37410	El Pedroso De La Armuña
37418	Arabayona De Mogica
37419	Espino De La Orbada|Parada De Rubiales
37420	Gomecello
37426	Negrilla De Palencia|Palencia De Negrilla
37427	La Velles|Pedrosillo El Ralo
37428	La Orbada|La Orbadilla|Pajares De La Laguna|Villanueva De Los Pavones|Villaverde De Guareña
37429	Aldeanueva De Figueroa|Arcediano|Tardaguila
37430	Moriscos
37439	Almunia, La (Urbanizacion)|Castellanos De Moriscos|Poligono Industrial Moriscos|San Cristobal De La Cuesta
37440	Barbadillo|Carnero|Castrejon|El Tejado|El Vecino|Gejo De Da Mencia
37446	Villalba De Los Llanos
37447	Rollan
37448	Calzada De Don Diego|Canillas De Abajo|Canillejas|Sagos
37449	Albergueria De La Valmuza|Campo Charro (Urbanizacion)|Carrascal De Pericalvo|Encinar De La Rad, El (Urbanizacion)|Galindo Y Perahuy|La Rad|Los Escobos|Miranda De Pericalvo|Pericalvo|Rodillo|San Benito De La Balmuza|Santo Tome Del Collado
37450	Canillas De Torneros|Matilla De Los Caños
37451	Carrascal Del Obispo|Huelmos Y Casasolilla
37452	Casanueva|Casasola|Casasola Del Campo|Castroverde|Cortos De La Sierra|Garcigalindo|Sanchogomez
37453	Carneruelo|Carrascal De Sanchiricones|Gueribañez|La Torrita|Sanchiricones|Tordelalosa|Tornadizos
37454	Las Veguillas
37455	Arguijo (Finca)|Cabrera (Finca)|Carrascal Del Asno (Finca)|Esteban Isidro (Finca)|Pedro Llen (Finca)
37456	Corbacera|Galleguillos (Finca)|Llen (Finca)|Olmedilla (Finca)|Vecinos
37458	La Dueña De Abajo
37460	Alcornocal (Finca)|Aldehuela De La Boveda|Ardonsillero (Finca)|Berrocalejo (Finca)|Cabeza De Diego Gomez|Castro Enriquez (Finca)|Garcirrey|Moral De Castro, La (Finca)|Rodasviejas (Finca)|Tabera De Arriba|Tejadillo|Valdelama (Finca)|Villar De Los Alamos|Villarejo (Sando) (Finca)|Vilvis (Finca)
37465	Anaya De Huebra|Carrascalejo De Huebra|La Sagrada
37466	Cuarton Del Pilar|Sanchon De La Sagrada
37467	Villagarcia
37468	Fuentes De Sando|Grandez|Iruelo Del Camino|Sando De Santa Maria|Santa Maria De Sando|Villasdardo
37470	Sancti Spiritus
37478	Alba De Yeltes|Diosleguarde|El Mejorito
37479	Paradinas De Abajo
37480	Nuevo Poblado (Fuentes De Oñoro)
37481	Fuentes De Oñoro
37488	Aldea Del Obispo|Barquilla|Castillejo De Dos Casas|La Bouza|Puerto Seguro|Villar De La Yegua|Villar Del Ciervo
37490	Cabezabellosa De La Calzada|Pitiegua
37491	Encinasola De Las Minayas|Navas De Quejigal|Taberuela|Tellosancho|Valdechapero
37492	San Fernando
37493	Aldeavieja (Alaveria)|Aldeavila De Revilla|Muñoz|Peramato
37494	Campocerrado|Martin De Yeltes
37495	Baños De Retortillo (Balneario)|Retortillo
37496	Castillejo De Yeltes|Castraz|Collado De Yeltes|Pedraza De Yeltes|Sepulveda De Yeltes
37497	Carpio De Azaba|Espeja|Gallegos De Argañan|Hurtada (Finca)|La Alameda De Gardon|Martillan|Paradinas De Abajo (Aldea)|Serranillo|Sexmiro|Villar De Argañan
37500	Arrabal De San Sebastian|Ciudad Rodrigo|Ivanrey|Poligono Industrial Las Viñas
37510	Agallas|Cespedosa De Agadones|El Sahugo|Martiago|Pastores (Pueblo)|Vegas De Domingo Rey|Villarejo Agallas (Finca)
37515	La Encina
37516	Herguijuela De Ciudad Rodrigo
37520	El Bodon
37521	Robleda
37522	Villasrubias
37523	Peñaparda
37524	El Payo
37530	Serradilla Del Llano
37531	Serradilla Del Arroyo
37532	Monsagro
37540	Fuenteguinaldo
37541	Casillas De Flores
37542	Navasfrias
37550	Campillo De Azaba
37551	Ituero De Azaba
37552	Castillejo De Azaba
37553	Puebla De Azaba
37554	La Alamedilla
37555	La Albergueria De Argañan
37589	Tenebron
37590	Morasverdes
37591	El Soto|La Atalaya|San Juanejo|Zamarra
37592	Castillejo Martin Viejo|Saelices El Chico
37593	Bocacara
37594	Agueda Del Caudillo|Conejera (Poblado)
37595	Pedrotoro
37596	Guadapero
37600	Tamames
37606	Puebla De Yeltes
37607	Alcazaren (Finca)|Arevalos, Los (Finca)|Barbalos|Corral De Garciñigo (Finca)|Garciñigo (Finca)|Hondura|Monflorido (Finca)|Moraleja De Huebra (Finca)|Navarredonda De La Rinconada|Puerto De La Calderilla|Rinconada De La Sierra|San Miguel De Asperones (Finca)|Segoyuela De Los Cornejos (Finca)|Tejeda Y Segoyuela|Ventas De Garriel
37608	Pedraza De La Sierra
37609	Avililla De La Sierra|Berrocal De Huebra|Coca De Huebra|Coquilla De Huebra|Domingo Señor|Gallinero De Huebra|Herreros De Peña Cabra|Iñigo De Huebra (Finca)|Narros De Matalayegua|Pedro Martin (Finca)|Peralejos De Solis|Peña De Cabra|Terrones (Finca)|Torre De Velayos|Villar Del Profeta
37610	Mogarras
37617	Rebollosa
37618	Monforte De La Sierra
37619	Herguijuela De La Sierra|Madroñal
37621	Aldeanueva De La Sierra (Pueblo)|Cereceda De La Sierra|Cilleros De La Bastida|El Cabaco|El Maillo|El Zarzoso|La Bastida|Zarzosillo
37624	La Alberca
37630	Cabrillas
37638	Sepulcro-Hilario
37639	Aldehuela De Yeltes
37640	Abusejo
37650	Sequeros
37656	Cepeda
37657	Sotoserrano
37658	Garcibuey|Villanueva Del Conde
37659	El Casarito|Las Casas Del Conde|Nava De Francia|San Martin Del Castañar|San Miguel De Robledo
37660	Miranda Del Castañar
37670	Santibañez De La Sierra
37671	San Esteban De La Sierra
37680	Valdefuentes De Sangusin
37682	Santa Maria De Los Llanos
37683	Molinillo
37684	Cristobal
37690	Santa Olalla De Yeltes
37700	Bejar|Palomares Alto|Palomares De Bejar
37710	Candelario
37711	Colmenar De Montemayor
37712	Horcajo De Montemayor|Pinedas
37713	Valdehijaderos
37714	La Calzada De Bejar
37715	El Castañar
37716	Cantagallo|La Hoya|Navacarros|Vistahermosa (Bejar)
37717	Valdesangil|Vallejera De Riofrio
37718	Aldeacipreste|Valbuena
37720	El Cerro|Puerto De Bejar
37724	Lagunilla|Valdelageve|Valdelamatanza
37727	Montemayor Del Rio|Peñacaballera
37730	Ledrada
37740	Santibañez De Bejar
37748	Puente Del Congosto
37749	El Tejado De Bejar|La Magdalena|Las Casillas|Navamorales
37750	Bercimuelle (Pueblo)|Cespedosa De Tormes
37751	Gallegos De Solmiron
37752	La Tala
37753	Navahombela
37754	Iñigo Blasco
37755	Armenteros
37756	Revalbos
37759	Albergueria De Herguijuela|Herguijuela Del Campo|La Sierpe|Santo Domingo De Herguijuela
37760	Linares De Riofrio
37762	Escurial De La Sierra
37763	San Miguel De Valero
37764	Valero
37765	Casas De Monleon|El Tornadizo|Monleon
37766	Endrinal De La Sierra|Frades De La Sierra|Membribe De La Sierra|Navagallega (Finca)|Navarredonda De Salvatierra|Villar De Leche
37767	Aldeanueva De Campomojado|Casafranca
37768	Fuenterroble De Salvatierra|Los Santos
37770	Guijuelo
37773	La Cabeza De Bejar
37774	Guijo De Avila
37775	Fresnedoso
37776	Nava De Bejar
37777	Sorihuela
37778	Campillo De Salvatierra
37779	Aldeavieja De Tormes|Salvatierra De Tormes
37780	La Maya
37781	Monterrubio De La Sierra
37785	Galinduste
37786	Andarromero|Martin Perez
37787	Pelayos
37788	Dueña De Arriba|Pedrosillo De Los Aires
37789	Beleña|Buenavista|El Vaqueril|Fresno Alhandiga
37790	Fuentes De Bejar
37791	Peromingo|Puebla De San Medel|San Medel|Valdelacasa|Valverde De Valdelacasa
37792	Amatos De Salvatierra|Castillejo De Salvatierra|Valdejerrus
37793	Fuentebuena
37794	Navalmoral De Bejar|Sanchotello
37795	Berrocal De Salvatierra|Cabezuela De Salvatierra|Montejo|Palacios De Salvatierra|Pizarral
37796	Arapiles|Las Torres|Mozarbez
37797	Arroyo De La Encina (Urbanizacion)|Calzada De Valdunciel|Castellanas, Las (Urbanizacion)|Castellanos De Villiquera (Pueblo)
37798	Carbajosa De Armuña|Mata De Armuña|Mina, La (Urbanizacion)|Monterrubio De Armuña|Mozodiel Del Camino (Finca)|Naharros De Valdunciel|Valdunciel|Viso, El (Urbanizacion)
37799	Cardeñosa|Cañedo|Forfoleda (Pueblo)|Huelmos, De (Estacion)|Izcala|Jarales, Los (Finca)|San Cristobal Del Monte|Topas|Valdelosa|Villanueva De Cañedo
37800	Alba De Tormes
37810	Garcihernandez|Jemingomez|La Lurda
37820	Peñarandilla
37830	Coca De Alba
37840	Tordillos
37850	Nava De Sotrobal
37860	Horcajo Medianero|Valverde De Gonzaliañe
37861	Chagarcia-Medianero|Juarros
37863	Anaya De Alba
37864	Herrezuelo
37865	Larrodrigo
37870	Aldeaseca De Alba
37871	Pedrosillo De Alba|Turra De Alba
37873	Valeros
37874	Azud De Villagonzalo (Chalets)|Cilloruelo|Gajates|Pardo, El (Finca)
37881	Valdecarros
37882	Navales De Alba|Pedraza De Alba|Pinar De Alba, El (Urbanizacion)|Terradillos
37890	Amatos De Alba
37891	Cartala (Finca)|Cuatro Calzadas (Calzada)|Ejeme|Galisancho|Martinamor|Portillo De Ejeme|Santa Ines|Santa Teresa|Valdemierque
37892	Encinas De Arriba|Sieteiglesias De Tormes|Torrejon
37893	Carpio Bernardo|Encinas De Abajo|Francos Nuevo Y Viejo|Los Ventorros|Palomares De Alba|Villagonzalo De Tormes
37894	Castañeda (Finca)|Machacon|Matacan
37900	Santa Marta De Tormes
38001	Santa Cruz De Tenerife
38002	Santa Cruz De Tenerife
38003	Santa Cruz De Tenerife
38004	Santa Cruz De Tenerife
38005	Santa Cruz De Tenerife
38006	Santa Cruz De Tenerife
38007	Santa Cruz De Tenerife
38008	Santa Cruz De Tenerife
38009	Santa Cruz De Tenerife
38010	Santa Cruz De Tenerife
38070	Santa Cruz De Tenerife
38071	Santa Cruz De Tenerife
38080	Santa Cruz De Tenerife
38107	Barranco Grande|El Pilar|El Rosarito|El Sobradillo|El Tablero|La Gallega|Las Veredillas|Llano Del Moro (Santa Cruz) (Ver Callejero De Santa Cruz De Tenerife)|Santa Cruz De Tenerife|Tincer
38108	Las Chumberas|Los Andenes|San Cristobal De La Laguna|San Matias|Taco
38109	Bocacangrejo (El Rosario)|Campana, La (Poligono Industrial)|El Chorrillo|Radazul|San Isidro (El Rosario)
38110	Mayorazgo, El (Poligono Industrial)|Santa Cruz De Tenerife
38111	Acoran|Alisios|Añaza|Santa Cruz De Tenerife|Santa Maria Del Mar
38120	San Andres (Santa Cruz De Tenerife)
38129	Almaciga|Benijo|Chamorga|El Bailadero|El Draguillo|El Suculum|La Cumbrilla|Lomo De Las Bodegas|Roque Bermejo
38130	Taganana
38139	Afur|Casas De La Cumbre|Roque Negro|Valle De Los Catalanes
38140	Igueste De San Andres
38150	Cardonera|Las Cuevas|Valleseco
38160	Santa Cruz De Tenerife|Valle Tahodio
38170	Los Campitos|Santa Cruz De Tenerife
38180	Cueva Bermeja|Darsena Pesquera|Maria Jimenez|Valle Brosque|Valle Crispin
38190	Machado|Tabaiba (Urbanizacion)
38200	San Cristobal De La Laguna
38201	San Cristobal De La Laguna
38202	San Cristobal De La Laguna
38203	San Cristobal De La Laguna
38204	San Cristobal De La Laguna
38205	San Cristobal De La Laguna
38206	San Cristobal De La Laguna
38207	San Cristobal De La Laguna
38208	San Cristobal De La Laguna
38240	Punta Del Hidalgo
38250	Bajamar
38260	Tejina
38270	Valle Guerra
38280	Tegueste
38290	La Esperanza|Las Barreras|Llano Del Moro (El Rosario)|Lomo Pelado|Peñafiel|Preventorio|Rosas, Las (Esperanza, La)
38291	Los Baldios|Mina|San Cristobal De La Laguna
38292	El Infierno|Padilla Baja|Pedro Alvarez|Portezuelo|Socorro, El (Tegueste)
38293	Camino De Jardina|Mercedes, Las, De (Carretera)|San Cristobal De La Laguna
38294	Batan De Abajo|Batan De Arriba|Bejia|Chinamada|Cruz Del Carmen|Las Carboneras|Rio|Taborno
38296	San Cristobal De La Laguna|San Miguel De Geneto
38297	Aeropuerto De Los Rodeos (Santa Cruz De Tenerife)|Aeropuerto De Los Rodeos, Residencial (Zona)|Garimba|Hoya Del Camello|Ortigal
38300	La Orotava|Las Cañadas Del Teide|Parque Nacional Teide
38310	Aguamansa|Chasna|El Bebedero|El Montijo|El Sauce|Hacienda Perdida|La Sierra|Pinoleris|Posada De Montenegro|Tres Pinos (Aguamansa)
38311	Dehesa Alta|Florida Alta|Humboldt (Urbanizacion)|La Florida|La Hondura|Los Frontones|Los Gomez|Pino Alto
38312	Arenas, Las (La Orotava)|Cruz De Los Martillos|La Luz|Las Candias|San Jeronimo (La Orotava)
38313	Benijos
38314	Cuevas, Las (La Orotava) (Urbanizacion)|El Durazno|La Ratona|Los Rechazos|Rincon, El (La Orotava)|San Bartolome (La Orotava)
38315	La Aza|La Perdoma
38320	La Cuesta|San Cristobal De La Laguna|Santa Cruz De Tenerife
38329	Lomo De Las Casillas|San Cristobal De La Laguna|Valle Jimenez|Valle Tabares
38330	El Pulpito|Guamasa
38340	Campo De Golf (Tacoronte)|La Caridad|Los Naranjeros|Luz, La (Tacoronte)
38350	Cantiillo, El (Tacoronte)|El Torreon|Tacoronte
38355	Agua Garcia|Barranco De Las Lajas
38356	San Jeronimo (Tacoronte)|San Juan Perales
38357	El Adelantado|Las Casas Altas|Lomo Colorado
38358	El Pris|Guayonje|Juan Fernandez|Mesa Del Mar (Urbanizacion)|Puerto La Madera|Santa Catalina Las Toscas|Tagoro
38359	Ravelo|Valle Forestal (Urbanizacion)
38360	Angeles, Los (Urbanizacion)|El Puertito|El Sauzal
38370	La Matanza De Acentejo
38379	Chamiana|Jagre|Puntillo Del Sol|San Antonio|Toscas De Guia
38380	La Victoria De Acentejo
38389	La Vera-Carril|Los Altos-Arroyos|Resbala, La (La Victoria)
38390	Cuesta De La Villa|Lomo Roman|Quinta|Santa Ursula|Vera, La (Santa Ursula)
38398	Farrobillo|Tosca De Anamaria|Tosca De Barrio
38399	Cantillo|La Corujera|Tamaide (Santa Ursula)
38400	Puerto De La Cruz
38410	Los Realejos|Realejo Alto
38411	Horno, El (Los Realejos)|Mocan, El (Los Realejos)
38412	Realejo Bajo
38413	Cruz Santa|Ferruja, La (Realejos, Los)
38414	Icod El Alto
38415	Llanadas|Palo Blanco (Los Realejos)
38416	Tigaiga
38417	Toscal, El (Los Realejos)
38418	Longuera
38419	Grimona, La (Urbanizacion)|Jardin, El (Los Realejos)|La Carrera|La Montañeta|San Benito (Los Realejos)|Zamora Alta
38420	San Juan De La Rambla
38428	Los Quevedos|Rosas|San Jose
38429	Las Aguas
38430	Icod|San Felipe|San Marcos, De (Playa)
38434	Belmonte Bajo|Buen Paso|Florida, La (Icod)|La Mancha|Las Cañas|Llanito Perera|Peniche|Santa Barbara
38435	El Tanque|Erjos|La Tierra Del Trigo|Ruigomez|San Jose De Los Llanos
38438	Cueva Del Viento|El Amparo|La Patita|Pedregal
38439	Cruz Del Camino|Fuente La Vega|La Vega|La Vega Alta|Las Abiertas|Mirabal
38440	La Guancha|Lomo Blanco (Guancha, La)
38441	Convento, El (La Guancha)|Crucitas, Las (La Guancha)|Las Longueras|Montañetas, Las (La Guancha)|Santa Catalina (La Guancha)|Santo Domingo|Tierra De Costa
38449	El Pinalete|Hoya Pablos|La Sorriba|Llano Mendez
38450	Garachico
38458	Guincho, El (Garachico)
38459	Genoves|Montañeta, La (Garachico)|San Juan Del Reparo
38460	Caleta De Silos|Casa Amarilla|Cruces, Las (Garachico)|La Caleta De Interian|San Pedro De Daute
38470	El Casco|Los Silos
38479	Barrio De San Jose Bajo|Puertito De Los Silos|San Bernardo|Sibora
38480	Buenavista Del Norte
38489	El Palmar|Lagunetas (Buenavista)|Las Portelas|Los Carrizales|Masca|Teno
38500	Guimar
38508	El Puertito De Guimar|Socorro, El (Guimar)
38509	Aroba|Brillasol|Candelaria, Industrial (Paseo)|La Viuda
38510	Barranco Hondo
38520	Igueste De Candelaria
38530	Candelaria|Las Caletillas
38540	Araya|Las Cuevecitas|Malpais (Araya)
38550	Arafo|El Carreton|La Hidalga
38560	La Medida|Pajara (Guimar)|Punta Prieta
38570	Eras, Las (Fasnia)|Fasnia|Roque, Los (Fasnia)
38579	La Zarza|Sabina Alta (Fasnia)|Sombrera, La (Fasnia)
38580	Villa De Arico
38588	Casablanca (Poris)|Faro De Abona|La Jaca|Poris De Abona|Punta De Abona|San Miguel De Tajao
38589	Arico El Nuevo|Arico El Viejo|Degollada, La (Arico)|La Cisnera|La Sabinita|Los Gavilanes|Teguedite
38590	Lomo De Mena
38591	Aguerche|Chimaje|El Escobonal|El Tablado
38592	Eras, Las (Arico)|Icor
38593	El Rio De Arico
38594	Chimiche|Rosas, Las (Granadilla)|Vegas, Las (Granadilla)
38595	Charco Del Pino
38600	Granadilla
38610	Aeropuerto Reina Sofia (Santa Cruz De Tenerife)
38611	Atogo|Casablanca (Granadilla)|Castro|Chuchurumbache|Montaña De Yaco|San Isidro De Abona|Vistas De Yaco
38612	El Medano
38613	Vilaflor
38614	La Escalona
38615	Ifonche|Trevejos
38616	Chavez|Cruz De Las Animas|Cruz De Tea (Granadilla)|El Desierto|Higuera, La (Granadilla)|Los Barrancos|Los Blanquitos|Vicacaro
38617	El Draguito|El Salto|Las Palomas|Llanos, Los (Granadilla)|Vista Gorda|Yaco
38618	Los Abrigos
38619	Granadilla (Poligono Industrial)
38620	San Miguel De Abona
38626	Cruz De Guanche|Los Toscales|Valle De San Lorenzo
38627	Barranco Oscuro|Buzanada|Cabo Blanco|La Camella|Los Bebederos
38628	Aldea Blanca|Asomada|Las Zocas|Tamaide (San Miguel)
38629	Asomada Alta|El Fronton|El Roque|Jama
38630	Costa Del Silencio|Ten-Bel (Urbanizacion)
38631	Las Galletas|Rosas, Las (Las Galletas)
38632	Cho|Fraile|Guargacho|Guaza|Palm-Mar|Reina, La (Parque)
38639	Amarilla Golf|Chafiras, Las (San Miguel De Abona)|Golf Del Sur|Guincho, El (San Miguel)
38640	Arona
38649	Casas, Las (Arona)|Montaña Fria|Sabinita Alta|Tunez|Vento
38650	Playa De Los Cristianos
38652	Chayofa
38660	Costa Adeje|Costa Adeje-Playas De Fañabe|Costa Adeje-San Eugenio|La Caldera
38670	Adeje Casco|Las Nieves|Las Torres
38677	La Concepcion|Los Menores|Moraditas, Las (Adeje)|Quinta, La (Adeje)|Taucho|Tijoco Alto|Tijoco Bajo
38678	Armeñime|Callao Salvaje|El Puertito De Adeje|Las Cancelas|Marazul
38679	Fañabe
38680	Guia De Isora
38683	Acantilados De Los Gigantes|Puerto De Santiago
38684	Tamaimo (Santiago Del Teide)
38685	Tejina De Isora
38686	Alcala|Cueva Del Polvo|El Varadero
38687	Abama|Aguadulce|Aponte|Fonsalia|Piedra Hincada|Playa San Juan
38688	Acojeja|Aripe|Chiguergue|Chirche|El Jaral|La Gambueza|Lomo Del Balo (Guia I.)|Pozo, El (Guia De Isora)|Vera De Erques
38689	Chio
38690	Arguayo|Manchas, Las (Santiago Del Teide)|Molledo|Retamar, El (Santiago Del Teide)|Santiago Del Teide|Valle De Arriba
38700	Morro, El (Santa Cruz De La Palma)|Santa Cruz De La Palma
38710	Breña Alta
38711	La Polvacera|San Antonio De Breña
38712	El Fuerte|El Socorro|Las Ledas|Los Cancajos|Montaña La Breña|San Jose De Breña Baja
38713	Alamos, Los (Santa Cruz De La Palma)|Barranco Del Rio|Belhoco|Botazo|Buenavista De Abajo|Buenavista De Arriba|Cuesta, La (Breña Alta)|Las Tierritas|Nieves, Las (Santa Cruz De La Palma)
38714	Cercado Peñon (Puntallana)|El Granel|El Posito|Galga, La (Puntallana)|Llano Molino|Lomo El Corcho|Lomo Estrecho|Lomo Piñedo|San Bartolome (Puntallana)
38715	Candelaria (Santa Cruz De La Palma)|El Taboco|La Camacha|Lomadilla|Lomo De Los Gomeros|Puntallana|Toscas, Las (Santa Cruz De La Palma)
38720	San Andres Y Sauces
38726	Barlovento|Las Paredes|Lomo Machin|Lomo Machin Alto
38727	Cabezadas Bajas|Cuesta, La (Barlovento)|Gallegos|Lomo De Los Castros|Lomo Quinto|Lomo Romero|Marantes|Oropesa|Palmita, La (Barlovento)|Topaciegas|Tosca, La (Barlovento)
38728	Roque Faro
38729	Bermudez|La Fuente Nueva|Llano Del Pino|Quinta Zoca|Ramirez|Roque, El (San Andres Y Sauces)|San Andres De La Palma|San Juan (San Andres Y Sauces)|Verada De Bajamar|Verada De Lomadas
38730	Mazo
38738	Aeropuerto De La Palma|Callejones De Abajo|Lomo Oscuro|Malpaises|Monte De Luna|Sabina, La (Mazo)|San Simon|Tigalate Abajo|Tiguerorte
38739	El Poleal|Lodero|Monte Breñas|Monte Pueblo|Rosa, La (Mazo)
38740	Fuencaliente
38749	Caletas, Las (Fuencalite)|El Charco|Las Indias|Quemados, Los (Fuencaliente)
38750	El Paso
38758	Barrial De Abajo|Barrial De Arriba|Barrial De Enmedio|Rosa, La (El Paso)|Tacande De Arriba (El Paso)
38759	Cuatro Caminos (Llanos)|El Paraiso|Jedey (El Paso)|Malpais (El Paso)|Manchas De Abajo|Manchas, Las (El Paso)|Paso De Abajo|San Nicolas (El Paso)|Tacande Abajo (El Paso)
38760	Argual|Llanos De Aridane|Retamar (Los Llanos)
38767	Rosas, Las (Los Llanos)|Triana
38768	Barros, Los (Los Llanos De Aridane)|Hermosilla|Pedregales, Los (Los Llanos De Aridane)
38769	Casa De La Bombilla|Dos Pinos|El Pedregal|El Remo|La Condesa|Puerto De Naos|Tajuya|Todoque
38770	Tazacorte
38779	Costa, La (Tazacorte)|El Puerto De Tazacorte|Marina|San Borondon
38780	Aguatavar|Amagar|Arecida|Bellido|El Jesus|Pueblo, El (Tijarafe)|Punta, La (Tijarafe)|Tijarafe|Tinizara
38787	Garafia
38788	Castillo, El (Garafia)|Cueva Del Agua|Hoya Grande (Garafia)|Las Tricias|Llano Negro
38789	Fagundo|Pinar, El (Puntagorda)|Puntagorda|Roque, El (Puntagorda)
38800	San Sebastian Gomera
38801	Chejelipes|El Atajo|El Jorado|El Molinito|Inchereda|La Laja|Lomito Fragoso Y Honduras|San Antonio Y Pilar
38810	Santiago, De (Playa)
38811	Ayamosna|Barranco De Santiago|Benchijigua|Jerduñe|Laguna De Santiago|Las Toscas|Lo Del Gato|Pastrana|Tapahuga|Tecina|Tejiade|Vegaipala
38812	Alajero|Almacigos|Arguayoda|Guarimiar|Imada|Quise
38813	Antoncojo|Targa
38820	Callejon De Ordaiz|El Curato|El Tabaibal|Hermigua|Las Nuevitas|Llano Campos|Palmarejo|Piedra Romana
38829	Cabezadas, Las (Hermigua)|Casas, Las (Hermigua)|Corralete|Estanquillo|Hoyetas|Ibo Alfaro|Las Poyatas|Monteforte
38830	Agulo|Lepe
38840	Vallehermoso
38849	Banda De Las Rosas|La Quilla|Los Bellos|Los Chapines|Los Loros|Macayo|Rosa De Las Piedras
38850	Arguamul
38852	Alojera|Epina|Taguluche|Tazo
38860	La Rajita
38869	Cercado, El (Vallehermoso)|Chipude (Vallehermoso)|Erque|Erquito|Igualero|La Dama|Pavon|Temocoda
38870	Borbalan|La Calera|La Puntilla|Valle Gran Rey|Vueltas
38879	Casa De La Seda|Chele|El Guro|El Retamal|Hornillo, El (Valle Gran Rey)|Lomo Del Balo (Valle Gran Rey)|Lomo Del Moral|Los Descansaderos|Los Granados|Vizcaina, La (Valle Gran Rey)
38890	Cruz Del Tierno|Los Aceviños|Pajar De Bento|Palmita, La (Agulo)|Rosas, Las (Agulo)|Serpa|Vega, La (Agulo)
38891	Tamargada|Valle Abajo
38892	Acardece|Arure|Las Hayas
38900	Valverde Del Hierro
38910	Aeropuerto De Hierro|Caleta, De La (Playa)|Puerto De La Estaca|Tamaduste|Temijiraque
38911	Frontera|Los Mocanes|Luchon|Puntas, Las (V. Hierro)
38912	Sabinosa
38913	Tigaday
38914	Las Casas|Pinar, El (V. Hierro)|Taibique
38915	Isora|San Andres (V. Hierro)|Tiñor
38916	Erese|Guarazoca|Mocanal
38917	La Restinga
39001	Santander
39002	Santander
39003	Santander
39004	Santander
39005	Santander
39006	Santander
39007	Santander
39008	Santander
39009	Santander
39010	Santander
39011	Santander
39012	Santander
39070	Santander
39071	Santander
39080	Santander
39100	Santa Cruz De Bezana
39108	Azoños|Maoño|Mompia|Prezanes
39110	Sancibrian (Soto De La Marina)|Soto De La Marina
39120	Liencres|Mortera
39130	Elechas|Pedreña
39140	Somo
39150	Carriazo (Ribamontan Al Mar)|Castanedo|Suesa
39160	Galizano|Langre|Loredo
39170	Ajo|Bareyo
39180	Noja
39191	Guemes
39192	San Bartolome (Meruelo)|San Mames De Meruelo|San Miguel De Meruelo
39193	Castillo|El Alvareo|Rionegro|Soano
39195	Arnuero|Isla|Isla Playa
39197	Ancillo|Argoños|Cerecedas|Piedrahita|Santiuste
39200	Matamorosa|Reinosa
39210	Abiada|Barrio (Campoo De Suso)|Brañavieja|Celada De Los Calderones|Entrambasaguas (Campoo De Suso)|Espinilla|Hoz De Abiada|La Lomba|Mazandrero|Naveda|Ormas|Poblacion De Suso|Proaño|Soto (Campoo De Suso)|Villacantid|Villar
39212	Aradillos|Argüeso|Camino (Campoo De Suso)|Fontecha|Fontibre|Fresno Del Rio|Miña, La (Campoo De Suso)|Morancas|Nestares|Paracuelles|Salces|Serna, La (Campoo De Suso)
39213	Arroyo De Valdearroyo|Bimon|Bolmir|Celada Marlantes|Cervatos|Fombellida|Horna De Ebro|Izara|La Aguilera|Las Rozas De Valdearroyo|Llano (De Valdearroyo)|Quintanilla (Enmedio)|Renedo De Valdearroyo|Retortillo|San Pedro (Cervatos)|Sopeña (Cervatos)|Suano|Villaescusa (Enmedio)|Villafria (Enmedio)|Villanueva (Rozas Valdearroyo)
39220	Arantiones|Polientes|Salcedo (Valderredible)
39230	Poblacion De Abajo|Poblacion De Arriba|Ruijas|Serna, La (Valderredible)
39232	Allen Del Hoyo|Arenillas De Ebro|Arroyuelos|Cadalso (Valderredible)|Cejancas|Espinosa De Bricia|Linares De Bricia|Lomas De Villamediana|Quintanilla De Rucandio|Renedo De Bricia|Repudio|Riopanero|Ruanales|Rucandio (Valderredible)|Ruerrero|San Martin De Elines|Santa Maria De Hito|Soto De Rucandio|Valderias|Villaescusa De Ebro|Villamediana De La Loma|Villaverde De Hito|Villota De Elines
39250	Bascones De Ebro|Berzosilla|Campo De Ebro|Coroneles|Cubillo De Ebro|Cuillas Del Valle|La Puente Del Valle|Montecillo|Olleros De Paredes Rubias|Otero (Valderredible)|Quintanilla De An|Rebollar De Ebro|Revelillas|Rocamundo|Sobrepenilla|Sobrepeña|Villamoñico|Villanueva De La Nia
39292	Aldueso|Bustamante|La Costana|Monegro|Orzales|Quintana (Campoo De Yuso)|Quintanamanil|Requejo (Enmedio)|Servillas|Servillejas|Villapaderne|Villasuso (Campoo De Yuso)
39294	Corconte|La Poblacion|La Riva De Yuso|Lanchares
39300	Barreda (Torrelavega)|Campuzano|Dualez|Ganzo|La Montaña|Sierrapando|Tanos|Torrelavega|Torres
39310	Gornazo|Miengo|Mogro
39311	Bedico|Cartes|La Barquera|Mercadal|Mijarojos|Santiago De Cartes|Sierra Elsa
39312	Requejada|Rumoroso|Soña
39313	Barrio Obrero (Polanco)|Polanco|Posadillo|Rinconeda
39314	Mijares|Queveda|Viveda
39315	Viernoles
39318	Barcena De Cudon|Cuchia|Cudon|Mar
39320	Cobreces
39329	Toñanes
39330	Santillana Del Mar
39340	Suances
39350	Cortiguera|Hinojedo|Puente Avios
39360	Arroyo (Santillana Del Mar)|Camplengo|Herran|Ongayo|Tagle|Ubiarco|Vispieres|Yuso
39400	Lobado|Los Corrales De Buelna|Penias|San Andres (Los Corrales)|San Mateo|Somahoz
39407	Collado (Cieza)|Villasuso De Cieza|Villayuso De Cieza
39408	Barros|Coo|Las Caldas De Besaya
39409	Barcena, La (San Felices Buelna)|Jain|Mata|Posajo Penias|Rivero (San Felices)|Sopenilla|Sovilla|Tarriba (San Felices)
39410	Mataporquera
39417	Bustasur (Las Rozas)|Bustidoño|Laguillos|Malataja|Montesclaros
39418	Barriopalacio (Valdeolea)|Bercedo|Camesa|Castrillo Del Haya|Cuena|Haya, El (Valdeolea)|Hoyos|Las Henestrosas De Las Quintanillas|Las Quintanillas|Loma, La (Valdeolea)|Mata De Hoz|Matarrepudio|Olea|Quintana, La (Valdeolea)|Rebolledo|Reinosilla|San Martin De Hoyos|Santa Olalla (Valdeolea)
39419	Aldea De Ebro|Arcera|Arroyal De Los Carabeos|Barcena De Ebro|Barruelo (Valdeprado)|Bustillo Del Monte|Candenosa|Castrillo De Valdelomar|Hormiguera|Lastrilla|Loma Somera|Mediadoro|Navamuel|Rasgada|Reocin De Los Molinos|San Andres (Valdeprado)|San Andres De Valdelomar|San Martin De Valdelomar|San Vitores (Valdeprado)|Santa Maria De Valverde|Sotillo|Susilla (Valderredible)|Valdeprado Del Rio
39420	Barcena Pie De Concha|Cobejo|Montabliz|Pie De Concha|Pujayo
39430	Arca|Caceo|Helguera (Molledo)|Meson, El (Molledo)|Molledo|Mura|Santa Olalla (Molledo)
39438	Casares|Pando (Molledo)|Quevedo|San Martin De Quevedo|Santa Marina (Molledo)|Santian (Molledo)|Silio|Ulda|Vallejo (Molledo)
39450	Arenas De Iguña|Cohiño|Las Fraguas|Los Llares|Palacio (Arenas Iguña)|Pedredo|San Cristobal|San Vicente De Leon|Santa Agueda|Santa Cruz De Iguña|Serna, La (Iguña)
39451	Barriopalacio (Anievas)|Bostronizo|Calga|Cotillo De Anievas|San Juan De Raicedo|Villasuso De Anievas
39460	Corral|Llano (San Felices Buelna)|Riocorvo|San Miguel|Yermo
39470	Renedo De Pielagos
39477	Barcenilla De Pielagos|Oruña De Pielagos|Quijano De Pielagos
39478	Arce|Boo De Pielagos
39479	Carandia|Vioño|Zurita
39490	Lantueno|Santiurde De Reinosa|Somballe
39491	Cañeda|Pesquera|Rioseco (Santiurde-Reinosa)|San Miguel De Aguayo|Santa Maria De Aguayo|Santa Olalla De Aguayo|Ventorrillo
39500	Cabezon De La Sal|Ontoria|Vernejo
39507	Bustablado (Cabezon De La Sal)|Canales (Udias)|Cobijon (Udias)|Duña|Hayuela, La (Udias)|Llano, El (Udias)|Pumalverde (Udias)|Rodezas|Toporias|Valoria|Virgen La (Udias)
39509	Cabrojo (Cabezon De La Sal)|Herrera De Ibio|Ibio|Luzmela-Mazcuerras|Mazcuerras|Riaño De Ibio|Sierra De Ibio|Villanueva De La Peña|Virgen De La Peña
39510	Sopeña (Cabuerniga)|Teran (Valle Cabuerniga)|Valle De Cabuerniga
39511	Renedo De Cabuerniga|Selores (Cabuerniga)|Viaña (Cabuerniga)
39513	Barcenillas (Ruente)|Barrio De Abajo (Ruente)|Barrio De Arriba (Ruente)|Cuesta, La (Ruente)|Gismana (Ruente)|Lamiña (Ruente)|Monasterio|Ruente|Ucieda
39517	El Tojo|Saja
39518	Barcenamayor|Correpoco|Fresneda|Los Tojos
39520	Comillas|Seminario Pontificio
39525	Barcena (Alfoz)|Caborredondo (Alfoz De Lloredo)|Carrastrada (Alfoz De Lloredo)|Oreña|Padruno|Perelada|San Roque (Oreña)|Torriente|Viallan
39526	Cigüenza|Novales
39527	Casasola (Ruiloba)|Concha|Iglesia, La (Ruiloba)|Liandres|Pando (Ruiloba)|Ruiloba|Ruilobuca|Sierra (Ruiloba)|Trasierra
39528	Cara|Ceceño|El Tejo|La Rabia|Larteme|Rioturbio|Rubarcena|Ruiseñada|Santa Ana|Trasvia
39530	Puente San Miguel
39538	Helguera (Reocin)|La Veguilla|Reocin
39539	Cerrazo|Fresnedo (Alfoz De Lloredo)|Lloredo|Rudaguera|San Pedro (Rudaguera)|Villapresente
39540	San Vicente De La Barquera
39547	Los Llaos|Revilla, La (San Vicente De La Barquera)
39548	Los Tanagos|Pesues|Prellezo|Santillan
39549	Abanillas|Abaño|Acebosa, La (Abanillas)|El Barcenal|Estrada|Gandarilla|Hortigal|Portillo (Val De San Vicente)|Serdio
39550	Bielva|Burio|Cades|Cires|Lafuente De Lamason|Pumares, Los (Lamason)|Quintanilla (Lamason)|Rabago|Rio (Lamason)|Sobrelapeña|Venta, La (Lamason)
39551	Cabanzon|Casamaria
39553	Arenas (Rionansa)|Celis|Celucos|Cotera, La (Rionansa)|Herreria, La (Rionansa)|Las Barcenas|Riclones
39554	Los Picayos|Obeso|Pedreo|Puentenansa|Rioseco (Rionansa)|San Sebastian De Garabandal
39555	Lastra, La (Tudanca)|Santotis|Sarceda|Tudanca
39556	La Laguna|Puente Pumar|Uznayo
39557	Belmonte|Cotillos|Lombraña|Pejanda|Salceda|San Mames (Polaciones)|Santa Eulalia|Tresabuela
39558	Cabrojo (Rionansa)|Carmona
39559	Cosio|Rozadio
39560	Unquera
39569	Helgueras|Molleda|Prio|San Pedro De Las Baheras
39570	Potes|Rases|Santo Toribio
39571	Aniezo|Buyezo|Cabezon De Liebana|Cahecho|Cambarco|Luriezo|Perrozo|Torices
39572	Avellanedo|Barreda (Pesaguero)|Caloca|Lomeña-Basieda|Obargo|Pesaguero|Vendejo
39573	Lamedo|Piasca|Puente Asnil|San Andres (Cabezon Liebana)
39574	Cueva (Pesaguero)|Frama|Lerones|Valdeprado
39575	Barago|Cucayo|Dobres|Naroba|Señas|Soberado|Tollo|Tudes|Valcayo|Valmeo
39577	Barrio (Vega Liebana)|Bores|Campollo|Dobares|Dobarganes|El Arroyo|Enterrias|Ledantes|Maredes|Ongayo (Vega Liebana)|Pollayo|Toranzo (Vega Liebana)|Vada|Vega De Liebana|Vejo|Villaverde (Vega De Liebana)
39580	Bejes|Caldas (Peñarrubia)|Cicera|La Hermida|Linares|Navedo|Piñeres|Roza (Peñarrubia)
39582	Areños|Barcena (Camaleño)|Besoy|Cosgaya|Enterria|Llanos, Los (Camaleño)|Llaves|Mogrovejo|Pembes|Sebrango|Treviño
39583	Castro-Cillorigo|Lebeña|Pumareña|Salarzon|San Pedro (Bedoya)|Trillayo
39584	Aliezo|Armaño|Cabañes|Cobeña|Colio|Esanos|Llayo|Ojedo|Pendes|Tama|Viñon
39586	Arguebanes|Congarna|Mieses|Turieno
39587	Baro|Beares|Bodia|Brez|Camaleño|La Frecha|Lon|Molina, La (Camaleño)|Quintana (Camaleño)|Redo|San Pelayo (Camaleño)|Tanarrio|Vallejo (Camaleno)
39588	Espinama|Fuente De|Las Ilces|Pido
39590	Barcenaciones|Golbardo|La Busta|Quijas|Valles
39591	Caranceja|Casar De Periedo|Periedo|San Esteban (Casar De Periedo)|San Esteban (Reocin)
39592	Birruezas|Carrejo|Casas Nuevas, Las (Valdaliga)|Corrales, Los (Treceño)|Cos|El Ansar|El Turujal|Herreria, La (Valdaliga)|Hualle|La Plaza|La Ria|Molina, La (Valdaliga)|Requejo (Valdaliga)|San Vicente Del Monte|Santibañez (Cabezon De La Sal)|Sierra, La (Valdaliga)|Treceño
39593	Arguedes|Bustillo (Valdaliga)|Bustriguado|Caviedes|Concha, La (Valdaliga)|Cotera, La (Lamadrid-Valdaliga)|Cotera, La (Roiz-Valdaliga)|Cuevas, Las (Valdaliga)|El Vear|La Cantera|La Cocina|La Ganceda|La Hoya|La Peñia|Lamadrid|Las Arenas|Losbia|Mazo, El (Valdaliga)|Movellan|Puente, La (Valdaliga)|Radillo|Roiz|San Pedro (Valdaliga)|San Salvador (Valdaliga)|Sejo De Abajo|Vallines|Vega, La (Valdaliga)|Venta, La (Valdaliga)
39594	Camijanes|Luey|Muñorrodero|Pechon
39595	Caviña|La Mata|Labarces|Villanueva (Valdaliga)
39600	Maliaño|Muriedas|Revilla De Camargo
39608	Cacicedo|Herrera De Camargo|Igollo De Camargo
39609	Camargo|Escobedo De Camargo
39610	Astillero
39611	Guarnizo
39612	Cianca|Parbayon|Riosapero
39613	Boo De Guarnizo
39618	Pontejos
39619	San Salvador (Medio Cudeyo)|Santiago De Heras
39620	Saron
39626	Argomilla De Cayon|La Abadilla|San Roman De Cayon
39627	Cabarceno|El Arenal De Penagos|La Encina|Llanos, Los (Penagos)|Penagos|Sobarzo (Penagos)
39630	Penilla (Villafufre)|Vega (Villafufre)
39638	Escobedo De Villafufre|Rasillo De Villafufre|Villafufre
39639	Abionzo|Llerana|Saro
39640	Villacarriedo
39649	Aloños|Barcena De Carriedo|Pedroso|Santibañez De Carriedo|Soto (Villacarriedo)|Tezanos
39650	La Cueva|Penilla, La De Cayon
39660	Pomaluengo|Socobio|Villabañez
39670	Aes|Hijas|Puente Viesgo
39679	Las Presillas|Vargas
39680	Alceda|Ontaneda
39681	Bollacin|Penilla (Luena)|Resconorio|Sel Del Manzano
39682	Entrambasmestas|Guzparras|La Parada|Ocejo|Retuerta|Sel De La Peña|Sel Del Tojo (Toranzo)|Vega Escobosa
39683	Aldano
39685	Candolias|Pandillo (Vega Pas)|Vega De Pas|Viaña (Vega Pas)|Yera
39686	Bustaleguin|Bustiyerro|El Rosario|Hornedillo|La Gurueba|La Peredilla|San Pedro Del Romeral|Sota, La (San Pedro Romeral)|Vegaloscorrales|Vegalosvados
39687	Carrascal De Cocejon|Carrascal De San Miguel|El Cocejon|Llano (Luena)|Los Pandos|Pandoto|Puente, La (Luena)|San Andres (Luena)|San Miguel De Luena|Sel De La Carrera|Sel Del Hoyo|Selviejo
39688	Bustasur (Luena)|Cazpurrion|La Garma|La Ventona|Tablado (Luena)|Urdiales|Vozpornoche
39689	Barcena De Toranzo|San Martin De Toranzo|Vejoris
39690	Concha, La (Villaescu)|Obregon|Villanueva (Villaescusa)
39691	Iruz|Pando (Santiurde De Toranzo)|Penilla (Toranzo)
39692	Liaño
39694	Esles|Lloreda|Santa Maria De Cayon|Totero
39696	Bustantegua|Campillo|Pisueña|Selaya
39697	Corvera|Prases
39698	Acereda|Santiurde De Toranzo|Villasevil
39699	Borleña|Castillo Pedroso|Esponzues|Quintana (Toranzo)|San Vicente De Toranzo|Villegar
39700	Castro Urdiales
39706	Baltezana|Lusa|Onton|Santullan
39707	Otañes|Talledo
39709	Mioño|Samano
39710	Solares
39715	Entrambasaguas|Navajeda
39716	El Bosque|Hornedo|Hoznayo|Santa Marina (Entrambasaguas)
39718	Anaz|Bucarrero|Casa Del Monte|El Condado|La Herran|Pamanes|San Vitores (Medio Cudeyo)|Sobremazas|Somarriba|Tarriba (Lierganes)
39719	Agüero|Orejo|Puente Aguero|Rubayo|Setien
39720	Barrio De Arriba (Riotuerto)|La Cavada|Monte (Riotuerto)|Rucandio (Riotuerto)
39722	Lierganes
39723	Irias|La Cantolla|La Carcoba|Mirones|Mortesante|Pumares, Los (Miera)|Solana (Miera)|Vega, La (Miera)
39724	Ceceñas|Hermosa|Valdecilla
39727	Angustina (Riotuerto)|Calgar|El Rellano|Extremera|La Quieva|La Rañada|Las Porquerizas|Los Prados|Mercadillo|Rubalcaba|Vega, La (Lierganes)
39728	Ajanedo|Calseca|La Concha|La Pedrosa|La Toba|Linto|Morilla|San Roque De Riomiera|Valdicio
39730	Beranga|Praves
39738	Fresnedo (Solorzano)|Garzon (Solorzano)|Hazas De Cesto|La Collada|Regolfo|Riaño (Solorzano)|Solorzano
39740	Santoña
39749	Dueso
39750	Colindres
39760	Coz De Monte|La Maza|La Peña|Primosto|Sierra, La (Treto)|Treto
39761	Adal|Nates|Vidular
39762	Carasa|Padierniga
39764	Badames|Llanez|Rada|San Mames De Aras|Secadura
39766	Bueras|San Bartolome De Los Montes|San Miguel De Aras|San Pantaleon De Aras
39770	El Callejo|Laredo|Las Casillas|Pesquera, La (Laredo)|Villante
39776	Hazas (Liendo)|Iseca Nueva|Iseca Vieja|Isequilla|La Portilla|Liendo|Llatazos|Mendina|Mollaneda|Noval (Liendo)|Rocillo (Liendo)|Sopeña (Liendo)|Villanueva (Liendo)|Villaviad
39777	La Arenosa|Las Carcobas|Tarrueza
39778	Seña
39788	Adino|Angostina|Balbacienta|Carazon|El Pontarron|Francos|La Corra|La Magdalena|Landeral|Lendagua|Llano, El (Guriezo)|Lugarejos|Nocina|Pomar|Puente, El (Guriezo)|Ranero|Revilla (Guriezo)|Rioseco De Guriezo|Santa Cruz (Guriezo)|Torquiendo|Tresagua
39790	Barcena De Cicero|Carnerizas|Cicero|Cornocio (Cicero)|El Bao|Gama|La Ermita|La Fragua|La Via|Mazuecas|Paderne|Pomares|Rivaplumo|Rueda|San Pelayo (Cicero)|Sollagua
39791	Ambrosero|Casuso|Cuesta, La (Cicero)|El Cristo|El Manzanal|El Pico|Estian|Iglesia, La (Ambrosero)|Iglesia, La (Cicero)|La Bodega|La Escallada|La Madrid|La Tejera|Madama|Moncalian|Palacio (Cicero)|Pendon|Riolastras|San Andres (Ambrosero)|Tuebre
39792	Gajano|Heras
39793	Cubas|Las Pilas|Liermo|Omoño|Pontones|Villaverde De Pontones
39794	Anero|Hoz De Anero
39795	Baranda|Cornocio (Escalante)|Escalante|Montehano|Noval (Escalante)
39798	Allendelagua|Cerdigo|Islares|Oriñon|Sonabia
39800	Ramales De La Victoria|Salto Del Oso|Veares
39805	Calera, La (Vizcaya)|El Prado|Herada De Soba|La Pared
39806	Aja|Ason|Astrana|Bustancilles|Cañedo|Fresnedo De Soba|Hazas De Soba|Lavin|Pilas|Quintana (Soba)|Revilla De Soba|San Juan De Soba|San Martin De Soba|Valcaba|Villar De Soba|Villaverde De Soba
39808	Incedo De Soba|Regules|Rehoyos|Rozas De Soba|San Pedro (Soba)|Sangas|Santayana De Soba|Veguilla De Soba
39809	Barcena (Gibaja)|Entrepuentes|Estacion, La (Gibaja)|Gibaja|Guardamino|Helguero|Iseña|Los Valles|Mazo, El (Ramales)|Pondra|Quintana, La (Gibaja)|Riancho
39812	Matienzo|Mentera Barruelo|Ogarrio|Sierra Alcomba
39813	Alisas (Ramales)|Arredondo|Ason (Arredondo)|El Avellanal|Iglesia, La (Arredondo)|Rocias|Roza, La (Arredondo)|Socueva|Tabladillo|Val De Ason
39815	Riva De Ruesga|Valle De Ruesga
39820	Limpias
39840	Ampuero
39849	Ahedo (Ampuero)|Alisas (Ampuero)|Barcena, La (Ampuero)|Bernales|Cerbiago|Coterillo (Ampuero)|El Camino|Hoz De Marron|La Aparecida|Las Entradas|Las Garmillas|Marron|Perujo, El (Ampuero)|Pieragullano|Rascon|Regada|Rocillo (Ampuero)|Santisteban|Solamaza|Tabernilla
39850	Bulco|Udalla|Vear De Udalla
39860	Casavieja (Rasines)|Cereceda|El Cerro|Fresno|Helguera (Rasines)|La Edilla|Lombera|Ojebar|Rasines|Rocillo (Rasines)|Santa Cruz (Rasines)|Torcollano|Vega, La (Rasines)|Villaparte
39880	Aguera|Agüera De Trucios|Cabaña De La Sierra|El Campo|Iglesia, La (Valle De Villaverde)|La Altura|La Capitana|Laiseca (V. De Trucios)|Llaguno|Los Hoyos|Matanza, La (Valle De Villaverde)|Mollinedo|Palacio (Valle De Villaverde)|Trebuesto|Valle De Villaverde|Villanueva (Valle De Villaverde)
40001	Segovia
40002	Segovia
40003	Segovia
40004	Segovia
40005	Segovia
40006	Segovia
40070	Segovia
40071	Segovia
40080	Segovia
40100	San Ildefonso O La Granja
40109	Valsain
40120	Garcillan
40121	Anaya
40122	Pascuales|Pinilla Ambroz|Tabladillo
40123	Aragoneses|Paradinas
40130	Finca Allas De San Pedro|Juarros De Riomoros|Marazoleja|Martin Miguel
40133	Marazuela
40134	Etreros|Sangarcia
40135	Jemenuño|Santovenia
40136	Hoyuelos|Laguna Rodrigo|Ochando
40140	Valverde Del Majano
40141	Abades
40142	Lastras Del Pozo|Marugan|Monterrubio
40144	Bercial|Cobos De Segovia|Finca Caserio Parraces
40145	Muñopedro
40146	Labajos
40150	Villacastin
40151	Ituero Y Lama
40152	Zarzuela Del Monte
40153	Aldeallana (Finca)|Fuentemilanos
40154	Madrona|Perogordo|Torredondo
40160	Aldehuela (Torrecaballeros)|Cabanillas Del Monte|Torrecaballeros
40161	Navafria
40162	Aldealengua De Pedraza|Ceguilla|Cotanillo|Galindez|Gallegos|Martincano
40163	Cañicosa|Matabuena|Matamala
40164	Arconcillos|Arcones|Castillejo De Arcones|Colladillo|Huerta
40165	Casas Altas|Pradena|Pradenilla|Tejadilla (Ventosilla)|Ventosilla
40170	Collado Hermoso|Pelayos Del Arroyo|Sotosalbos
40171	Chavida|La Salceda|Mata De Santiuste|Santiuste De Pedraza|Torre Val De San Pedro|Valle De San Pedro
40172	Pedraza|Rades De Abajo
40173	Arahuetes|La Velilla|Requijada
40174	Berzal|Tejadilla (Valleruela Pedraza)|Valleruela De Pedraza
40175	La Matilla
40176	El Arenal|Orejana|Orejanilla|Revilla (Orejana)|Sanchopedro|Valleruela De Sepulveda
40180	Basardilla|Brieva|Santo Domingo De Piron|Tenzuela
40181	Aldeasaz De La Cuesta|Berrocal|Carrascal De La Cuesta|La Cuesta
40182	Caballar
40183	Muñoveros
40184	Pajares De Pedraza|Puebla De Pedraza|Rebollo
40185	Arevalillo De Cega|Cubillo|Guijar De Valdevacas|Valdevacas Y Guijar
40190	Bernuy De Porreros
40191	Espirdo|La Higuera|Tizneros
40192	Adrada De Piron|Losana De Piron|Torreiglesias
40193	Parque De Robledo
40194	Palazuelos De Eresma|Quitapesares|Sonsoto|Tabanera Del Monte|Trescasas
40195	Hontoria|Revenga
40196	La Lastrilla|Zamarramala
40197	San Cristobal De Segovia
40200	Cuellar
40210	Escarabajosa De Cuellar
40211	Torregutierrez
40212	San Cristobal De Cuellar
40213	Vallelado
40214	Mata De Cuellar
40215	Arroyo De Cuellar
40216	Chañe|Remondo
40217	Fresneda De Cuellar
40218	Fuente El Olmo De Iscar
40219	Villaverde De Iscar
40220	Olombrada|Vegafria
40230	Dehesa De Cuellar|Dehesa Mayor
40231	Lovingos
40232	Fuentes De Cuellar
40233	Moraleja De Cuellar
40234	Membibre De La Hoz
40235	Aldeasoña
40236	Laguna De Contreras|Vivar De Fuentidueña
40237	Sacramenia
40238	Pecharroman|San Jose De Valtiendas
40239	Cuevas De Provanco
40240	Gomezserracin
40241	Chatun
40242	Campo De Cuellar
40250	Mozoncillo
40260	Fuentepelayo
40270	Carbonero El Mayor
40280	Navalmanzano
40290	Roda De Eresma
40291	Escarabajosa De Cabezas|Tabanera La Luenga
40292	Aldea Real
40293	Zarzuela Del Pinar
40294	Pinarnegrillo
40295	Mudrian|San Martin Y Mudrian
40296	Pinarejos
40297	Sanchonuño
40298	Frumales
40299	El Henar
40300	Sepulveda
40310	Perorrubio|Santa Marta Del Cerro
40311	Alameda (Sotillo)|Fresneda De Sepulveda|Sotillo
40312	Corral De Duraton|Duraton|Duruelo|Los Cortos|Tanarro|Vellosillo
40313	Torreadrada
40314	Fuentesoto|Tejares De Fuentidueña|Valtiendas
40315	Castro De Fuentidueña|Castrojimeno|Castroserracin
40317	Aldehuelas De Sepulveda|Castrillo De Sepulveda|Hinojosas Del Cerro|Urueñas|Villar De Sobrepeña|Villaseca
40318	Castillo De Castilnovo|Castroserna De Abajo|Castroserna De Arriba|Condado De Castilnovo|Nava Del Condado|Torrecilla Del Condado|Valdesaz|Villafranca Del Condado
40320	Cantalejo
40330	Fuenterrebollo
40331	Burgomillodo|Carrascal Del Rio|Navalilla|Valle De Tabladillo
40332	Cobos De Fuentidueña|San Miguel De Bernuy
40340	Aguilafuente
40350	Escalona Del Prado
40351	Sauquillo De Cabezas
40352	Lastras De Cuellar
40353	Hontalbilla
40354	Adrados|Cozuelos De Fuentidueña|Perosillo
40355	Fuentesauco De Fuentidueña
40356	Calabazas De Fuentidueña
40357	Fuentidueña
40358	Fuentepiñel
40359	Fuente El Olmo De Fuentidueña|Torrecilla Del Pinar
40360	Cantimpalos
40370	Turegano
40380	Aldeonsancho|Sebulcor
40389	Aldealcorvo|Consuegra De Murera|Rebollar|San Pedro De Gaillos|Valdesimonte
40390	Valseca
40391	Encinillas
40392	Cabañas De Polendos|Mata De Quintanar
40393	Escobar De Polendos|Parral De Piron O De Villovela|Peñarrubias De Piron|Villovela De Piron
40394	Otones De Benjumea
40395	Veganzones
40396	Cabezuela
40397	Pinillos De Polendos|Venta De Pinillos
40400	El Espinar|Espinar, De El (Estacion)
40408	Navas De San Antonio
40410	San Rafael
40419	Alto De Los Leones|Gudillos
40420	La Losa|Navas De Riofrio|Riofrio, Real Bosque De
40421	Ortigosa Del Monte
40422	Otero De Herreros
40423	Guijasalbas|Valdeprados|Vegas De Matute
40424	Los Angeles De San Rafael
40430	Bernardos
40440	Santa Maria La Real De Nieva
40441	Miguelañez
40442	Samboal
40443	Narros De Cuellar
40444	Melque De Cercos
40445	Juarros De Voltoya
40446	Martin Muñoz De Las Posadas
40447	Nieva
40449	Balisa|Villoslada
40450	Nava De La Asuncion
40460	Bernuy De Coca|Santiuste De San Juan Bautista
40461	Moraleja De Coca
40462	Aldeanueva Del Codonal|Aldehuela Del Codonal
40463	Codorniz
40464	Montuenga
40465	San Cristobal De La Vega
40466	Martin Muñoz De La Dehesa|Rapariegos
40467	Tolocirio
40468	Montejo De Arevalo
40469	Donhierro
40470	Navas De Oro
40480	Coca
40490	Hontanares De Eresma|Los Huertos
40491	Carbonero De Ahusin
40492	Añe
40493	Yanguas De Eresma
40494	Armuña|Miguel Ibañez
40495	Domingo Garcia|Ortigosa Del Pestaño
40496	Ciruelos De Coca|Fuente De Santa Cruz|Villagonzalo De Coca|Villeguillo
40500	Riaza
40510	Alquite|Becerril|El Muyo|Madriguera|Martin Muñoz De Ayllon|Serracin
40512	El Negredo|Grado Del Pico|Santibañez De Ayllon|Villacorta
40513	Aldealazaro|Ribota
40514	Estebanvela|Francos|Saldaña De Ayllon|Valvieja
40515	Riofrio De Riaza
40516	Fresno De Cantespino
40517	Aldeanueva Del Monte|Barahona De Fresno|Sequera De Fresno
40518	Cascajares|Castiltierra|Cincovillas|Gomeznarro|Pajares De Fresno|Riahuelas
40520	Ayllon
40529	Alconada De Maderuelo|Alconadilla|Corral De Ayllon|Riaguas De San Bartolome
40530	Barbolla|El Olmillo|El Olmo
40531	Aldeonte|Encinas|Navares De Ayuso
40532	Aldeanueva De La Serrezuela|Navares De Enmedio|Navares De Las Cuevas
40533	Aldehorno
40540	Carabias|Ciruelos De Pradales|Fresno De La Fuente|Pradales
40541	Honrubia De La Cuesta|Villalbilla De Montejo
40542	Montejo De La Vega De La Serre|Moral De Hornuez|Valdevacas De Montejo|Villaverde De Montejo
40550	Bercimuel|Cedillo De La Torre
40551	Campo De San Pedro|Cilleruelo De San Mames
40552	Fuentemizarra
40553	Valdevarnes
40554	Embalse De Linares|Maderuelo
40555	Aldealengua De Santa Maria
40556	Languilla|Mazagatos
40560	Boceguillas|Turrubuelo
40567	Pajarejos
40568	Aldeanueva Del Campanario
40569	Grajera
40590	Casla|La Rades|Rosuero|Siguero|Sigueruelo|Villarejo
40591	Cerezo De Abajo|Mansilla
40592	Cerezo De Arriba
40593	Castillejo De Mesleon
40594	Santa Maria De Riaza
41001	Sevilla
41002	Sevilla
41003	Sevilla
41004	Sevilla
41005	Sevilla
41006	Sevilla
41007	Sevilla
41008	Sevilla
41009	Sevilla
41010	Sevilla
41011	Sevilla
41012	Sevilla
41013	Sevilla
41014	Sevilla
41015	Sevilla
41016	Sevilla
41017	Sevilla
41018	Sevilla
41019	Sevilla
41020	Sevilla
41070	Sevilla
41071	Sevilla
41080	Sevilla
41089	Dos Hermanas
41092	Sevilla
41100	Carchena|Coria Del Rio|La Vega
41110	Bollullos De La Mitacion
41111	Almensilla
41120	Gelves
41130	La Puebla Del Rio|Poblado De Colinas
41140	Isla Mayor
41150	Poblado De Alfonso Xiii
41200	Alcala Del Rio
41209	Esquivel|San Ignacio Del Viar
41210	Guillena|Lagos Del Serrano
41218	Torre De La Reina
41219	Las Pajanosas
41220	Burguillos
41230	Castilblanco De Los Arroyos
41240	Almaden De La Plata
41250	El Real De La Jara
41300	La Jarilla|Majaloba|Poligono Industrial El Gordillo|Poligono Industrial Majaravique|Poligono Industrial Nacoisa|San Jose De La Rinconada
41309	La Rinconada
41310	Brenes
41318	Villaverde Del Rio
41319	El Viar
41320	Cantillana|Los Pajares
41330	Los Rosales
41339	Guadajoz
41340	Tocina
41350	Villanueva Del Rio Y Minas
41359	Carbonal|Villanueva Del Rio
41360	Cañadas Del Romero|El Pedroso|Las Jarillas|Navahonda
41370	Cazalla De La Sierra|El Galeon|El Pintado|La Ganchosa|Solana Del Valle
41380	Alanis
41388	San Nicolas Del Puerto
41389	Cerro Del Hierro
41390	Guadalcanal
41400	Ecija
41409	Cerro Perea|Isla Del Vicario|Navalagrulla|Villanueva Del Rey|Villar Del Marco, El (Poblado)
41410	Carmona
41420	Fuentes De Andalucia
41429	La Campana
41430	Campillo, El (La Luisiana)|La Luisiana
41439	Cañada Rosal|La Monclova
41440	Acebuchal, El (Lora Del Rio)|El Priorato|El Rincon|La Rambla|Lora Del Rio|Setefilla
41449	Alcolea Del Rio
41450	Constantina|Fuente El Negro
41460	Las Navas De Las Concepcion
41470	Peñaflor|Vega De Almenara|Vereda
41479	La Puebla De Los Infantes
41500	Acebuchal, El (Alcala De Guadaira)|Alcala De Guadaira|Gandul-Marchenilla|San Rafael (Urbanizacion)|Santa Genoveva (Urbanizacion)|Soledad|Torrequinto (Urbanizacion)|Trujillo Cabeza Sordo
41510	Bencarron|Clavinque|Mairena Del Alcor
41520	El Viso Del Alcor
41530	La Ramira|Moron De La Frontera
41540	La Puebla De Cazalla
41550	Aguadulce|Cortijo Del Marques|Huerta Del Colegio
41560	Alamedilla|El Gallo|Estepa|La Salada|Pozo Del Villar
41563	Isla Redonda La Aceñuela
41564	Lora De Estepa
41565	Gilena
41566	Pedrera
41567	Herrera
41568	El Rubio
41569	Marinaleda|Matarredonda
41570	Badolatosa|Huertas De La Manga
41580	Casariche|Riguelo
41590	La Roda De Andalucia
41599	Corcoya|Los Perenos|Los Perez
41600	Arahal|La Gironda|Las Monjas
41610	El Calvario|El Palomar|Monte-Palacio|Paradas
41620	Marchena
41630	La Lantejuela
41640	Osuna|Puerto De La Encina
41650	El Saucejo
41657	Los Corrales
41658	Martin De La Jara|Rejano
41659	La Mezquitilla|Navarredonda
41660	Villanueva De San Juan
41661	Algamitas
41670	Pruna
41700	Dos Hermanas
41701	Dos Hermanas
41702	Dos Hermanas
41703	Dos Hermanas|Fuente Del Rey
41704	Dos Hermanas
41710	Bencarron (Utrera)|Don Rodrigo|Utrera
41719	El Palmar De Troya|Guadalema De Los Quintero
41720	Los Palacios Y Villafranca
41727	El Trobal|Maribañez|Trajano
41728	Adriano|Los Chapatales|Pinzon
41730	Las Cabezas De San Juan|Sacramento|Vetaherrado
41731	Marismillas
41740	Lebrija
41749	El Cuervo
41750	Los Molares
41760	El Coronil
41770	Montellano
41780	Coripe
41800	Sanlucar La Mayor
41804	Olivares
41805	Benacazon
41806	Umbrete
41807	Espartinas
41808	Villanueva Del Ariscal
41809	Albaida Del Aljarafe
41810	Castilleja Del Campo
41820	Carrion De Los Cespedes
41830	Huevar De Aljarafe
41840	Pilas
41849	Aznalcazar
41850	Villamanrique De La Condesa
41860	Gerena
41870	Aznalcollar
41880	El Hoyuelo|El Ronquillo|La Ratilla
41888	El Garrobo
41889	Arroyo De La Plata|El Alisar|El Cañuelo
41890	El Castillo De Las Guardas|Peroamigo
41897	El Madroño
41898	Alamo, El (El Madroño)|El Peralejo|Juan Anton|Juan Gallego|La Aulaga|Minas Del Castillo|Villargordo
41899	Archidona|La Alcornocosa|Valdeflores
41900	Camas
41907	Valencina De La Concepcion
41908	Castilleja De Guzman
41909	Salteras
41910	Coca De La Piñera|El Carambolo
41920	San Juan De Aznalfarache
41927	Mairena Del Aljarafe
41928	Palomares Del Rio
41930	Bormujos
41940	Tomares
41950	Castilleja De La Cuesta
41960	Gines
41970	Santiponce
41980	La Algaba
41989	El Aral
42001	Soria
42002	Soria
42003	Soria
42004	Soria
42005	Soria
42070	Soria
42071	Soria
42080	Soria
42100	Agreda
42107	Aldehuela De Agreda|Beraton|Borobia|Cueva De Agreda|Fuentes De Agreda|Vozmediano
42108	Añavieja|Devanos|Muro|Valverde De Agreda
42110	Olvega
42112	Aldealpozo|Calderuela|Hinojosa Del Campo|Nieva De Calderuela|Omeñaca|Pinilla Del Campo|Pozalmuro|Tajahuerce|Tozalmoro|Valdegeña|Villar Del Campo
42113	Castilruiz|Cigudosa|Fuentestrun|Matalebreras|Montenegro De Agreda|San Felices|Trevago|Valdelagua Del Cerro
42120	Gomara
42126	Almazul|Carabantes|Cihuela|Deza|La Alameda|Mazateron|Miñana|Quiñoneria|Reznos
42127	Abion|Ledesma De Soria|Seron De Nagima|Zarabes
42128	Bliecos|Castil De Tierra|Nomparedes|Tapiela|Tejado|Villanueva De Zamajon|Zamajon
42130	Almenar|Cabrejas Del Campo|Castejon Del Campo|Esteras De Lubia|Mazalvete|Ojuel|Peroniel Del Campo
42132	Albocabe|Aliud|Buberos|Jaray|Noviercas|Paredesroyas|Torralba De Arciel|Villaseca De Arciel
42134	Alconaba|Aldealafuente|Cadosa (Alconaba) (Urbanizacion)|Candilichera|Carazuelo|Cubo De Hogueras|Duañez|Fuensauco|Fuentetecha|Martialay|Ontalvilla De Valcorba|Ribarroya|Salma, La (Alconaba) (Granja)
42138	Cardejon|Ciria|Portillo De Soria|Sauquillo De Alcazar|Torrubia De Soria
42140	San Leonardo De Yague
42141	Arganza|Fuencaliente Del Burgo|Fuentearmegil|Guijosa|Nafria De Ucero|Quintanilla De Nuño Pedro|Rejas De Ucero|Santa Maria De Las Hoyas|Santervas Del Burgo|Valdealbin
42142	Espeja De San Marcelino|Espejon|La Hinojosa|Muñecas|Orillares
42145	Cidones|Herreros|Malluembre (Cidones) (Finca)|Ocenilla|Villaverde Del Monte
42146	Abejar|Cabrejas Del Pinar
42147	La Blanca
42148	Cantalucia|Casarejos|Cubilla|Cubillos|Herrera De Soria|Muriel Viejo|Talveila|Vadillo
42149	Navaleno
42150	Vinuesa
42153	Canredondo De La Sierra|Chavaler|Derroñadas|Dombellas|El Royo|Hinojosa De La Sierra|Santervas De La Sierra|Vilviestre De Los Nabos
42154	Cuerda Del Pozo, La (Royo El) (Pantano)
42156	Molinos De Duero|Quintanarejo O El Quintanar|Salduero|Santa Ines
42157	Covaleda
42158	Duruelo De La Sierra
42159	Langosto
42161	Arevalo De La Sierra|Gallinero|Torrearevalo|Ventosa De La Sierra
42162	Aylloncillo|Buitrago|Fuentecantos|Fuentelsaz De Soria|Garray|Garrejo|La Rubia|Pedraza|Pinilla De Caradueña|Portelrubio|Tardesillas
42164	Espejo De Tera|Tera
42165	Molinos De Razon|Rebollar|Rollamienta|Sotillo Del Rincon|Valdeavellano De Tera|Villar Del Ala
42166	Aldehuela Del Rincon
42167	Cubo De La Sierra|Matute De La Sierra|Portelarbol|San Gregorio|Segoviela|Sepulveda De La Sierra
42169	Almarza|Arguijo|Barriomartin|La Poveda De Soria|San Andres De Soria
42172	Ausejo De La Sierra|Cuellar De La Sierra|Diustes|El Collado|Fuentelfresno|Navabellida|Oncala|San Andres De San Pedro|Yanguas
42173	Bretun|La Laguna|Las Aldehuelas|Ledrado|Los Campos|Santa Cecilia|Santa Cruz De Yanguas|Valdecantos|Valduerteles|Valloria|Verguizas|Villar De Maya|Villar Del Rio|Villartoso|Vizmanos
42174	Huerteles|Las Fuentes De San Pedro|Montaves|Palacios De San Pedro|San Pedro Manrique|Taniñe|Valdelavilla|Ventosa De San Pedro|Villaseca Somera
42175	Las Fuesas|Matasejun
42180	Aldealices|Aldealseñor|Aldehuela De Periañez|Almajano|Arancon|Canos|Carrascosa De La Sierra|Castilfrio De La Sierra|Cirujales Del Rio|Cortos|Estepa De San Juan|Los Villares De Soria|Torretartajo
42181	Cerbon|Fuentes De Magaña|La Losilla|Magaña|Pobar|Valdeprado|Valtajeros|Villarraso
42189	El Espino|Narros|Renieblas|Santo Cristo De Los Olmedillos (Velilla De La Sierra) (Granja)|Suellacabras|Velilla De La Sierra|Ventosilla De San Juan
42190	Camaretas, Las (Urbanizacion)|Carbonera De Frentes|Frentes, De (Granja)|Fuentetoba|Golmayo|La Monjia|La Verguilla|Las Casas|Oteruelos|Pedrajas|Toledillo
42191	Almarail|Cubo De La Solana|Ituero|Los Rabanos|Miranda De Duero|Rabanera Del Campo|Riotuerto|Sinova|Tardajos De Duero
42192	La Cuenca|La Mallona|Las Fraguas|Villaciervitos|Villaciervos
42193	Abioncillo|Aldehuela De Calatañazor|Blacos|Boos|Calatañazor|Muriel De La Fuente|Nafria La Llana|Nodalo|Rioseco De Soria|Santiuste|Torralba Del Burgo|Torreblacos|Valdealvillo|Valdenarros|Venta Nueva La (Aldehuela De Catalañazor)
42200	Almazan
42210	Barca|Ciadueña|Rebollo De Duero|Velamazan
42211	Centenera De Andaluz|Fuentelcarro|Matamala De Almazan|Matute De Almazan|Santa Maria De Prado|Tejerizas
42212	Almantiga|Balluncar|Cobertelada|Covarrubias|Lodares Del Monte
42213	Alcubilla De Las Peñas|Alpanseque|Barahona|Marazovel|Mezquetillas|Radona|Romanillos De Medinaceli
42214	Fuentegelmes|Pinilla Del Olmo|Villasayas
42216	Adradas|Bordeje|Centenera Del Campo|Coscurita|Frechilla De Almazan|Jodra De Cardos|La Miñosa|Ontalvilla De Almazan|Sauquillo Del Campo|Señuela|Taroda|Torremediana
42218	Alparrache|Baniel|Borjabad|Boñices|La Milana|Moñux|Nepas|Perdices|Sauquillo De Boñices|Valdespina|Viana De Duero
42220	Cañamaque|Fuentelmonge|Torlengua|Valtueña
42222	Chercoles|Puebla De Eca
42223	Borchicayada|Bujarrapian (Borchicayada) (Granja)|Escobosa De Almazan|Moron De Almazan|Neguillas|Nolay|Soliedra|Villalba
42225	Alentisque|Cabanillas|Majan|Momblona|Velilla De Los Ajos
42230	Ambrona|Azcamellas|Benamira|Conquezuela|Esteras De Medinaceli|Fuencaliente De Medinaceli|Miño De Medinaceli|Torralba Del Moral O Medina|Ventosa Del Ducado|Yelo
42240	Arbujuelo|Layna|Medinaceli|Salinas De Medinaceli|Ures De Medina
42248	Beltejar|Blocona|Lodares De Medinaceli
42250	Arcos De Jalon
42257	Jubera|Rio Blanco|Somaen|Velilla De Medinaceli
42258	Aguaviva De La Vega|Almaluez|Utrilla
42259	Aguilar De Montuenga|Chaorna|Judes|Montuenga De Soria|Sagides
42260	Santa Maria De Huerta
42269	Alconchel De Ariza|Granja De San Pedro|Iruecha|Monteagudo De Las Vicarias|Pozuel De Ariza|Torrehermosa
42290	Camparañon|Lubia|Navalcaballo|Villabuena
42291	El Monasterio|Fuentelaldea|Izana|La Barbolla|La Seca|Las Cuevas De Soria|Los Llamosos|Osonilla|Quintana Redonda|Revilla De Calatañazor|Ventosa De Fuentepinilla
42294	Cascajosa|Fuentelarbol|Fuentepinilla|La Muela|Osona|Tardelcuende|Torreandaluz|Valderrodilla|Valderrueda
42300	El Burgo De Osma
42310	La Rasa
42311	Caracena|Carrascosa De Abajo|Fresno De Caracena|Navapalos|Vilde|Villanueva De Gormaz
42313	El Enebral|Gormaz|La Olmeda|Lodares De Osma|Quintanas De Gormaz|Recuerda|Valdenebro
42315	Castro|Cañicera|Galapagares|La Perera|Losana|Madruedano|Modamio|Mosarejos|Nograles|Peralejo De Los Escuderos|Retortillo De Soria|Sauquillo De Paredes|Tarancueña|Torrevicente|Valvenedizo
42317	Aylagas|Fuentecantales|Ucero|Valdeavellano De Ucero
42318	Barcebal|Barcebalejo|Osma|Sotos Del Burgo|Valdelinares|Valdelubiel|Valdemaluque
42320	Alcozar|Langa De Duero|Rejas De San Esteban|Velilla De San Esteban
42328	Castillejo De Robledo|Miño De San Esteban|Valdanzo|Valdanzuelo
42329	Bocigas De Perales|Zayas De Torre
42330	San Esteban De Gormaz
42340	Morcuera
42341	Hoz De Abajo|Hoz De Arriba|Liceras|Montejo De Tiermes|Noviales
42342	Cenegro|Cuevas De Ayllon|Fuentecambron|Ligos|Piquera De San Esteban|Torraño|Torremocha De Ayllon
42344	Carrascosa De Arriba|Pedro|Rebollosa De Pedro|Tiermes|Torresuso|Valderroman
42345	Aldea De San Esteban|Atauta|Ines|Olmillos|Peñalba De San Esteban|Quintanas Rubias De Abajo|Quintanas Rubias De Arriba|Soto De San Esteban
42350	Valdegrulla
42351	Alcoba De La Torre|Alcubilla De Avellaneda|Berzosa|Matanza De Soria|Quintanilla De Tres Barrios|Villalvaro|Zayas De Bascones|Zayuelas
42360	Berlanga De Duero
42365	Andaluz|Fuentetovar|Tajueco
42366	Aguilera|Bayubas De Abajo|Bayubas De Arriba|Hortezuela|Morales|Valverde De Los Ajos
42367	Bordecorex|Caltojar|Casillas De Berlanga|Ciruela
42368	Abanco|Alalo|Arenillas|Barcones|Brias|La Riba De Escalote|Lumias|Paones|Rello
42391	Alcubilla Del Marques|Pedraja De San Esteban
43001	Tarragona
43002	Tarragona
43003	Tarragona
43004	Tarragona
43005	Tarragona
43006	Tarragona
43007	Tarragona
43008	Tarragona
43070	Tarragona
43071	Tarragona
43080	Tarragona
43100	Bonavista
43110	La Canonja
43120	Basal|Constanti|Gavarres|Mas Magrinya|Mas Sanroma|Poligono Industrial De Constanti|Puntas
43130	Sant Salvador (Urbanitzacio)|Tarragona
43140	La Pobla De Mafumet
43141	Vilallonga Del Camp
43142	El Rourell
43143	El Mila|La Maso
43144	Vallmoll
43150	Medol, El (Urbanitzacio)
43151	Pallaresos, Els
43152	Perafort
43153	Garidells, Els
43154	Gunyoles, Les
43155	Puigdelfi
43178	La Papiola
43200	Reus
43201	Reus
43202	Reus
43203	Reus
43204	Reus
43205	Reus
43206	Parcelas Plana|Reus
43300	Club Mont-Roig (Urbanitzacio)|Monmont Terres Noves (Urbanitzacio)|Mont-Roig Del Camp
43310	Colldejou
43311	Vilanova D'Escornalbou
43312	Arbocet, L'
43320	Llaberia|Planes Del Rei, Les|Pratdip
43321	Santa Marina (Urbanitzacio)
43330	Riudoms
43340	Montbrio Del Camp
43350	Borges Del Camp, Les
43360	Albarca|Cornudella De Montsant
43361	La Morera De Montsant
43362	Siurana
43363	Ulldemolins
43364	Aixabiga, L'|Capafonts|El Bosquet|La Cadeneta|La Febro|Mont-Ral|Prades|Tossalets (Edificio)
43365	Alforja|Arboli
43370	La Palma D'Ebre
43371	Margalef
43372	La Bisbal De Falset
43373	Cabaces
43374	La Vilella Baixa
43375	La Vilella Alta
43376	Poboleda
43379	Escaladei
43380	Vilaplana
43381	Aleixar L'
43382	Maspujols
43390	Irles, Les|Riudecolls|Voltes, Les
43391	Vinyols I Els Arcs
43392	Castellvell Del Camp
43393	Almoster
43400	Montblanc
43410	La Guardia Dels Prats
43411	Blancafort
43412	Solivella
43413	Belltall
43414	Lilla
43415	Prenafeta|Rojals
43420	Santa Coloma De Queralt
43421	Bellprat|Montalegre|Pontils|Sant Magi De Rocamora|Santa Perpetua De Gaia|Valldeperes|Viladeperdius
43422	Barbera De La Conca
43423	Pira
43424	Sarral
43425	Fores|Montbrio De La Marca|Passanant|Pla De La Basa
43426	Rocafort De Queralt
43427	Albio|Barri De Segura|Conesa|La Cirera|Llorac|Montargull|Rauric|Savalla Del Comtat|Vallfogona De Riucorp
43428	Biure|Piles, Les|Vallespinosa|Vallverd
43429	Aguilo|Guialmons|La Pobla De Carivenys|Roques, Les
43430	Vimbodi
43439	Vallclara|Vilanova De Prades
43440	Espluga De Francoli, L'
43448	Poblet|Poblet (Monestir)
43449	Senan
43450	La Riba
43459	El Pinetell|Farena
43460	Alcover
43461	La Plana|Serradalt
43470	La Selva Del Camp
43479	Albiol, L'
43480	Vila-Seca
43481	La Pineda
43490	Vilaverd
43491	Picamoixons|Planes De Picamoixons, Les
43500	Simpatica (Carretera)|Tortosa
43510	Bitem
43511	Tivenys
43512	Benifallet
43513	Rasquera
43514	Mas De Barberans
43515	La Galera
43516	Godall
43517	Capuchinos (Barranc)|Coll De L'Alba|Cuesta Capellanes|Horta De Sant Vicenc|Mianes|Vinallop
43518	25 De Gener (Bloc)|El Raval De Falco|El Raval De La Llet|Horta De Pimpi|La Petja|Parque Del Mopu|Sant Llatzer|Santa Candida|Soldevilla
43519	El Perello
43520	Roquetes
43527	Reguers, Els
43528	Alfara De Carles
43529	Horta Baixa, L'|Horta De Dalt, L'|Observatorio Del Ebro|Raval De Cristo
43530	Alcanar
43540	Sant Carles De La Rapita
43548	Salines De La Trinitat, Les
43549	El Poble Nou Del Delta
43550	Ulldecona
43558	Freginals|Ventalles, Les
43559	El Castell|La Miliana|Sant Joan Del Pas|Valentins, Els
43560	La Cenia|La Senia
43569	Cases D'Alcanar, Les
43570	Santa Barbara
43580	Deltebre
43590	Jesus
43591	Aldover
43592	Xerta
43593	Pauls
43594	El Pinell De Brai
43595	Prat De Comte
43596	Horta De Sant Joan
43597	Arnes
43700	El Vendrell
43710	Pedreres, Les (Urbanitzacio)|Santa Oliva
43711	Banyeres Del Penedes|Saifores (Barri)|Sant Miquel De Banyeres (Urbanitzacio)
43712	Llorenç Del Penedes
43713	Cornudella Del Penedes|El Papiolet|Hostal, L'|La Carronya Alta|La Carronya Baixa|La Torregassa|Lleger|Sant Jaume Dels Domenys
43714	Aiguaviva (El Montmell)|El Pla De Manlleu
43715	Sabartes (Edificio)|Santa Oliva (Camping)|Valldossera
43716	Albinyana|Masies De Torrent, Les
43717	La Bisbal Del Penedes|Ortigos, L'
43718	Atalaya Mediterranea (El Montmell) (Urbanitzacio)|Juncosa De Montmell (El Montmell)|Mas Mateu (El Montmell)|Masarbones|Masllorenç|Mirador Del Penedes, El (El Montmell) (Urbanitzacio)|Moixeta, La (El Montmell) (Urbanitzacio)|Moli Blanquillo|Peces, Les|Pinedas Altas (El Montmell) (Urbanitzacio)
43719	Bellvei
43720	Arboç, L'|Casetes De Puigmolto, Les|La Llacuneta
43729	Valdemar (Urbanitzacio)
43730	Falset
43736	El Masroig|El Molar|La Figuera
43737	El Lloar|Gratallops|Torroja Del Priorat
43738	Bellmunt Del Priorat
43739	Porrera
43740	Mora D'Ebre
43746	Darmos|La Serra D'Almos|Tivissa
43747	Benissanet|Miravet
43748	Ginestar
43749	Garcia
43750	Flix
43760	El Morell
43761	La Pobla De Montornes
43762	Ardenya|Casas De Virgili|La Riera De Gaia
43763	La Nou De Gaia|Vespella De Gaia
43764	El Catllar
43765	La Secuita
43770	Mora La Nova
43771	Riudecanyes
43772	Botarell
43773	Argentera, L'|Duesaigues
43774	La Torre De Fontaubella|Pradell De La Teixeta
43775	Marça
43776	Capçanes
43777	Guiamets, Els
43780	Gandesa
43781	La Fatarella
43782	Vilalba Dels Arcs
43783	La Pobla De Massaluca
43784	Corbera D'Ebre
43785	Bot
43786	Batea
43787	Caseres
43790	Riba-Roja D'Ebre
43791	Asco
43792	La Torre De L'Espanyol|Vinebre
43800	Valls
43810	El Pla De Santa Maria
43811	Cabra Del Camp|Figuerola Del Camp
43812	Brafim|Canferre (El Montmell)|Montferri|Puigpelat|Rodonya
43813	Alio|Fontscaldes|Masmolets|Miramar
43814	Vila-Rodona
43815	Aiguamurcia|Alba, L'|Cal Canonge|Destres, Les|Masbarrat|Pobles, Les|Santes Creus|Urbanizacion De Els Manantials
43816	Esblada|Querol
43817	El Pont D'Armentera|La Planeta
43820	Calafell
43830	Torredembarra
43839	Alba, L' (Camping)|Clara Mar (Urbanitzacio)|Costelacion (Apartamentos)|Creixell|Creixell-Mar (Urbanitzacio)|Gavina, La (Camping)|Masso, La (Urbanitzacio)|Morisques, Les (Urbanitzacio)|Noria, La (Camping)|Raco Del Cesar|Relax (Camping)|Sirena Dorada, La (Camping)
43840	Reco De Salou|Salou
43850	Cambrils|Costa Blanca (Camping)
43860	Ametlla De Mar, L'|Atmella De Mar, L'|Nautic (Camping)
43870	Amposta
43877	Sant Jaume D'Enveja
43878	Masdenverge
43879	Balada (Amposta)|Muntells, Els
43880	Barri Maritim De Sant Salvador|Barri Maritim Del Francas|Coma-Ruga|Creu, La (Urbanitzacio)|Estacio De Sant Vicenç De Calders (Viviendas)|Francas (Camping)|Garrofers, Els|La Masia Blanca|Masos De Coma-Ruga, Els|Nirvana (Urbanitzacio)|Sant Vicenç De Calders
43881	Cal Cego|Can Toni|Cunit|Cunit-Diagonal (Urbanitzacio)|Diagonal|Eixample De Cunit|Mar De Cunit (Camping)|Valparaiso
43882	Segur De Calafell
43883	Bera (Urbanitzacio)|La Barquera|Mas Roig, De (Zona)|Roc De Sant Gaieta (Urbanitzacio)|Roda De Bara
43884	Bonastre
43885	Salomo
43886	Renau|Vilabella
43887	Nulles
43890	Hospitalet De L'Infant, L'
43891	Masboquera|Masriudoms|Vandellos
43892	Casalot, El (Urbanitzacio)|Costa Zefir (Urbanitzacio)|Etersa (Mont-Roig Del Camp)|Marinada (Camping)|Marius (Camping)|Masos D'En Blade (Urbanitzacio)|Maynou|Miami-Platja|Montroig (Camping)|Montroig-Bahia (Urbanitzacio)|Montroig-Mar|Oasis (Camping)|Paraiso, El (Urbanitzacio)|Parque Mont-Roig (Urbanitzacio)|Pinos De Miramar (Urbanitzacio)|Pla Parcial Sector 28 (Mont-Roig Del Camp)|Playa Y Fiesta (Camping)|Pueblo Nuevo Azahar|Riviera, La (Urbanitzacio)|Rustical Balnearis (Urbanitzacio)|Rustical Mont-Roig (Urbanitzacio)|Sant Miquel De Mont-Roig (Urbanitzacio)|Sudoest (Mont-Roig Del Camp)|Torre Del Sol (Camping)|Via Marina (Urbanitzacio)|Vila Romana - Solemio (Urbanitzacio)
43893	Altafulla|Altafulla (Camping)|Llum I Mar (Urbanitzacio)|Perla, La (Urbanitzacio)|Robert (Urbanitzacio)|Sant Antoni (Urbanitzacio)
43894	Camarles|El Lligallo Del Ganguill|El Lligallo Del Roig|La Granadella
43895	Ampolla, L'
43896	Aldea, L'|Hostal Dels Alls, L'
43897	Camp-Redo|La Font De Quinto|Poligono Industrial El Camp-Redo
44001	Teruel
44002	Teruel
44003	Teruel
44070	Teruel
44071	Teruel
44080	Teruel
44100	Albarracin
44110	Gea De Albarracin
44111	Torres De Albarracin
44112	Tramacastilla
44113	Noguera De Albarracin
44114	Griegos|Villar Del Cobo
44115	Guadalaviar
44120	Terriente|Villarejo De Terriente
44121	Bezas|El Campillo|Rubiales
44122	Jabaloyas|Saldon|Valdecuenca
44123	Arroyofrio|Collado De La Grulla|El Cañigral|El Vallecillo|Toril Y Masegoso
44124	Moscardon
44125	Royuela
44126	Calomarde|Frias De Albarracin
44130	Villastar
44131	Villel
44132	Libros|Mas De La Cabrera
44133	Riodeva|Tramacastiel
44134	Alobras|El Cuervo|Tormon|Veguilla De La Sierra
44140	Cantavieja|Cañada De Benatanduz
44141	La Cuba|Mirambel|Tronchon
44142	La Iglesuela Del Cid
44143	Fortanete
44144	Villarroya De Los Pinares
44145	Allepuz
44146	Monteagudo Del Castillo
44147	Cedrillas
44150	Aliaga
44155	Ababuj|Camarillas|El Pobo
44156	Aguilar De Alfambra|Jorcas
44157	Cobatillas|Hinojosa De Jarque
44158	Campos|Cirugeda|La Cañadilla
44159	Miravete De La Sierra
44160	Alfambra
44161	Escorihuela|Orrios|Villalba Alta
44162	Cuevas Labradas|Peralejos|Tortajada|Villalba Baja
44163	Perales De Alfambra
44164	Lidon|Visiedo
44165	Argente
44166	Rubielos De La Cerida
44167	Camañas
44168	Cañada Vellida|Galve
44169	Cuevas De Almuden|Jarque De La Val|Mezquita De Jarque
44190	Villaspesa
44191	Cascante Del Rio|Cubla|Valacloche
44192	Aldehuela|Castralvo
44193	Corbalan|Valdecebro
44194	Celadas
44195	Poligono Industrial La Paz|San Blas|Teruel
44200	Calamocha
44210	Cutanda
44211	Collados|Olalla|Valverde
44212	Anadon|Piedrahita|Rudilla
44213	Huesa Del Comun|Plou
44220	Barrachina|Nueros
44221	Godos
44222	Torrecilla Del Rebollar
44223	Villanueva Del Rebollar
44230	Tornos
44231	Castejon De Tornos
44232	Bello
44233	Odon
44300	Monreal Del Campo
44310	Rodenas
44311	Villar Del Salz
44313	Ojos Negros
44314	Blancas
44315	Pozuel Del Campo
44320	Baguena
44330	Burbaguena
44340	Fuentes Claras
44350	Caminreal
44357	Bañon|El Villarejo De Los Olmos
44358	Cosa|Torre Los Negros
44359	Torralba De Los Sisones|Villalba De Los Morales
44360	Santa Eulalia
44366	Orihuela Del Tremedal
44367	Bronchales
44368	Monterde De Albarracin|Pozondon
44369	Almohaja|Peracense
44370	Cella
44380	Villarquemado
44381	Torremocha De Jiloca
44382	Aguaton|Singra|Torrelacarcel
44390	San Martin Del Rio
44391	Luco De Jiloca
44392	El Poyo
44393	Torrijo Del Campo
44394	Bueña|Villafranca Del Campo
44395	Alba
44396	Caude
44397	Concud
44400	Mora De Rubielos
44409	Cabra De Mora|El Castellar
44410	Mosqueruela
44411	Puertomingalvo
44412	Castelvispal|Linares De Mora
44413	Valdelinares
44414	Nogueruelas
44415	Fuentes De Rubielos|Rubielos De Mora
44420	Manzanera
44421	Arcos De Las Salinas|Torrijas
44422	Abejuela|Alcotas De Manzanera|El Paul|Los Cerezos|Paraiso Bajo
44423	Las Alhambras|Los Olmos De Manzanera
44424	La Escaleruela|Mora De Rubielos (Estacion)
44430	Valbona
44431	Virgen De La Vega
44432	Alcala De La Selva
44433	Gudar
44440	Formiche Alto
44441	Formiche Bajo
44450	La Puebla De Valverde
44459	Camarena De La Sierra
44460	Sarrion
44470	Rubielos De Mora (Estacion)
44477	Albentosa
44478	Los Pertegaces
44479	Olba
44480	San Agustin
44490	Ferreruela De Huerva
44491	Badenas|Cucalon|Lanzuela
44492	Allueva|Bea|Fonfria|Lagueruela
44493	Loscos|Mezquita De Loscos|Monforte De Moyuela
44494	Villahermosa Del Campo
44495	Cuencabuena|Lechago
44496	Navarrete Del Rio
44497	Nogueras|Santa Cruz De Nogueras
44500	Andorra
44509	Alloza
44510	La Puebla De Hijar
44520	Samper De Calanda
44530	Hijar
44540	Albalate Del Arzobispo
44547	Ariño
44548	Oliete
44549	Alacon
44550	Alcorisa
44555	Pitarque
44556	Berge|Molinos
44557	Crivillen|La Mata De Los Olmos|Los Olmos
44558	Estercuel|Gargallo
44559	Ejulve|Montoro De Mezquita|Villarluengo
44560	Castellote
44561	Seno
44562	Cuevas De Cañart|Dos Torres De Mercader|Ladruñan
44563	Bordon|Las Planas De Castellote|Luco De Bordon
44564	Mas De Las Matas
44565	Abenfigo
44566	Aguaviva|Jaganta|Las Parras De Castellote
44570	Calanda
44579	Foz Calanda
44580	Valderrobres
44586	Peñarroya De Tastavins
44587	Fuentespalda
44588	Beceite
44589	La Portellada|Rafales
44590	Azaila
44591	Almochuel|Vinaceite
44592	Castelnou|Jatiel
44593	Urrea De Gaen
44594	Valdealgorfa
44595	Valjunquera
44596	La Fresneda
44597	Torre Del Compte
44600	Alcañiz
44610	Calaceite
44620	Valdeltormo
44621	Mazaleon
44622	Arens De Lledo
44623	Cretas
44624	Lledo
44630	Castelseras
44640	La Codoñera|Torrecilla De Alcañiz
44641	Torrevelilla
44642	Belmonte De San Jose
44643	La Cañada De Verich|La Ginebrosa
44650	Fornoles
44651	La Cerollera
44652	Monroyo
44653	Torre De Arcas
44660	Puigmoreno
44661	Valmuel
44700	Montalban
44706	Castel De Cabra
44707	Cañizar Del Olivar|La Zoma
44708	Palomar De Arroyos
44709	Peñarroyas|Torre De Las Arcas
44710	Rillo
44711	Fuentes Calientes
44712	Son Del Puerto
44720	Cervera Del Rincon|Pancrudo
44721	Alpeñes|Corbaton
44730	Cuevas De Portalrubio|Portalrubio|Rambla De Martin
44740	Vivel Del Rio
44741	Fuenferrada
44742	Armillas
44750	Martin Del Rio
44760	Utrillas
44769	Las Parras De Martin
44770	Escucha
44779	Valdeconejos
44780	Muniesa
44790	Blesa
44791	Cortes De Aragon|La Hoz De La Vieja|Maicas
44792	Alcaine|Josa|Obon
44793	Salcedillo|Segura De Baños
45001	Toledo
45002	Toledo
45003	Toledo
45004	Toledo
45005	Toledo
45006	Toledo
45007	Toledo
45008	Toledo
45070	Toledo
45071	Toledo
45080	Toledo
45100	Sonseca
45109	Arisgotas|Casalgordo
45110	Ajofrin
45111	Cobisa
45112	Burguillos De Toledo
45113	Chueca
45114	Mazarambroz
45120	San Pablo De Los Montes
45121	Las Navillas
45122	Arges|El Viso
45123	Layos
45124	Casasbuenas
45125	Pulgar
45126	Cuerva|El Castañar
45127	Las Ventas Con Peña Aguilera
45128	Menasalbas
45130	Los Navalucillos
45138	Alares|Robledo Del Buey
45139	Valdeazores
45140	Los Navalmorales
45150	Navahermosa
45159	Hontanar|Rio Cedena (Urbanizacion)
45160	Guadamur
45161	Polan
45162	Noez
45163	Totanes
45164	Galvez
45165	San Martin De Montalban
45170	San Martin De Pusa
45179	Villarejo De Montalban
45180	Camarena
45181	Camarenilla
45182	Arcicollar
45183	Las Ventas De Retamosa
45190	Nambroca
45191	Nieves, Las (Urbanizacion)
45200	Illescas
45210	Yuncos
45211	Recas
45212	Lominchar
45213	Palomeque
45214	Cedillo Del Condado
45215	El Viso De San Juan
45216	Carranque
45217	Ugena
45220	Pradillos, Los (Urbanizacion)|Yeles
45221	Esquivias
45222	Borox
45223	Seseña Viejo
45224	Seseña Nuevo
45230	Numancia De La Sagra
45240	Alameda De La Sagra
45250	Añover De Tajo
45260	Villaseca De La Sagra
45270	Mocejon
45280	Olias Del Rey
45290	Pantoja
45291	Cobeja
45292	Aceca
45300	Ocaña
45310	Villatobas
45311	Dos Barrios
45312	Cabañas De Yepes
45313	Yepes
45314	Ciruelos
45340	Ontigola
45350	Noblejas
45360	Villarrubia De Santiago
45370	Santa Cruz De La Zarza
45400	Mora
45410	Villanueva De Bogas
45420	Almonacid De Toledo
45430	Mascaraque
45440	Villaminaya
45450	Orgaz
45460	Manzaneque
45470	Los Yebenes
45479	Lituero De Abajo|Lituero De Arriba|Marjaliza
45480	Urda
45489	Casa Del Quinto|Dehesa De Las Labores|El Fresnedal|La Alberca|La Cabezuela|La Lora|La Pedrera|La Vega|Las Guadalerzas|Los Peleches|Quintos Del Pizarro|Valdesimon|Valle De Abajo|Ventas Del Castillo
45500	Torrijos
45510	Fuensalida
45511	Huecas
45512	El Portillo De Toledo
45513	Santa Cruz De Retamar
45514	Quismondo
45515	Maqueda
45516	La Puebla De Montalban|La Rinconada
45517	Escalonilla
45518	Gerindote
45519	Noves (Pueblo)
45520	Villaluenga De La Sagra
45521	Burujon (Pueblo)
45522	Albarreal De Tajo (Pueblo)|Azoverin (Pueblo)
45523	Alcabon (Pueblo)
45524	Rielves (Pueblo)
45525	Barcience (Pueblo)
45526	Santo Domingo-Caudilla
45529	Yuncler
45530	Santa Olalla
45531	Carmena
45532	Carriches
45533	El Carpio De Tajo
45534	La Mata
45540	Erustes
45541	Mesegar De Tajo
45542	El Casar De Escalona
45543	Otero
45544	Domingo Perez
45560	Oropesa
45567	Lagartera
45568	Las Ventas De San Julian
45569	Corchuela|Torralba De Oropesa
45570	El Puente Del Arzobispo
45571	Alcolea De Tajo|Azutan|Bercial De San Rafael|Bercial De Tajo
45572	Torrico|Valdeverdeja
45573	Navalmoralejo
45574	Fuentes De La Estrella|La Estrella
45575	Aldeanueva De San Bartolome
45576	Mohedas De La Jara
45577	Puerto De San Vicente
45578	El Campillo De La Jara
45580	Calzada De Oropesa
45588	Herreruela De Oropesa
45589	Caleruela
45590	Magan
45591	Yunclillos
45592	Cabañas De La Sagra
45593	Bargas|Perdices, Las (Urbanizacion)
45594	Villamiel De Toledo
45600	Talavera De La Reina
45610	Navalcan
45611	Parrillas
45612	Velada
45613	Gamonal
45614	Casar De Talavera
45620	Montesclaros
45621	Segurilla
45622	Mejorada
45630	Navamorcuende
45631	Almendral De La Cañada
45632	Sartajada
45633	La Iglesuela
45634	Buenaventura
45635	Sotillo De Las Palomas
45636	Marrupe
45637	Cervera De Los Montes
45638	Pepino
45640	El Real De San Vicent
45641	Castillo De Bayuela
45642	Cardiel De Los Montes
45643	Garciotun
45644	Nuño Gomez
45645	Hinojosa De San Vicente
45646	San Roman De Los Montes|Serranillos
45650	Espinoso Del Rey
45651	La Fresneda|Torrecilla De La Jara
45652	Retamoso De La Jara
45653	Santa Ana De Pusa
45654	San Bartolome De Las Abiertas
45660	Belvis De La Jara
45661	Aldeanueva De Barbarroya
45662	Alcaudete De La Jara
45663	El Membrillo
45664	Las Herencias
45670	La Nava De Ricomalillo
45671	Gargantilla|Sevilleja De La Jara
45672	Mina De Sta Quiteria|Puerto Rey
45673	Buenasbodas
45674	Robledo Del Mazo
45675	Las Hunfrias
45676	Robledillo
45677	Navaltoril
45678	Piedraescrita
45680	Cebolla (Pueblo)
45681	Illan De Vacas (Pueblo)
45682	Cerralbos, Los (Pueblo)
45683	Cazalegas (Pueblo)
45684	Lucillos (Pueblo)
45685	Montearagon (Pueblo)|Montearagon Estacion (Pueblo)
45686	Calera Y Chozas (Pueblo)
45687	Alcañizo (Pueblo)
45690	La Pueblanueva
45691	Las Vegas|San Antonio
45692	Malpica De Tajo
45693	Bernuy
45694	Talavera La Nueva
45695	Alberche Del Caudillo
45700	Consuegra
45710	Madridejos
45720	Camuñas
45730	Las Lagunas|Villafranca De Los Caballeros
45740	Villasequilla
45749	Villamuelas
45750	Huerta De Valdecarabanos
45760	La Guardia
45770	El Romeral
45780	Tembleque
45789	Turleque
45790	Quero
45800	Quintanar De La Orden
45810	Villanueva De Alcardete
45820	El Toboso
45830	Miguel Esteban
45840	La Puebla De Almoradiel
45850	La Villa De Don Fadrique
45860	Villacañas
45870	Lillo
45880	Corral De Almaguer
45890	Cabezamesada
45900	Almorox
45908	Aldea En Cabo|Paredes De Escalona
45909	Calalberche (Urbanizacion)
45910	Escalona
45917	Nombela
45918	Pelahustan
45919	Hormigos
45920	La Torre De Esteban Hambran
45930	Mentrida
45940	Valmojado
45950	Casarrubios Del Monte
45960	Chozas De Canales
46001	Valencia
46002	Valencia
46003	Valencia
46004	Valencia
46005	Valencia
46006	Valencia
46007	Valencia
46008	Valencia
46009	Valencia
46010	Valencia
46011	Valencia
46012	Valencia
46013	Valencia
46014	Valencia
46015	Valencia
46016	Valencia
46017	Valencia
46018	Valencia
46019	Valencia
46020	Valencia
46021	Valencia
46022	Valencia
46023	Valencia
46024	Valencia
46025	Valencia
46026	Valencia
46035	Benimamet|Valencia
46070	Valencia
46071	Valencia
46080	Valencia
46100	Burjassot
46110	Campo Olivar|Godella
46111	Rocafort|Santa Barbara (Urbanitzacio)
46112	Masarrochos
46113	Moncada
46114	Vinalesa
46115	Alfara Del Patriarca
46116	Masias|San Isidro De Benageber
46117	Benagolf (Betera) (Urbanizacion)|Benagolf (San Antonio) (Urbanizacion)|Betera|Vall De Flors (Urbanitzacio)
46118	Cartuja De Portaceli|Porta Coeli|Serra
46119	Naquera
46120	Alboraya
46127	Campamento Militar De Betera
46130	Massamagrell
46131	Bonrepos I Mirambell|Casas De Barcena
46132	Almassera
46133	Meliana
46134	Cuiper|Foios
46135	Albalat Dels Sorells|Emperador|Mahuella Tauladella Rafalell Y Vistabella
46136	Museros
46137	Puebla De Farnals (Playa)
46138	Rafelbuñol/Rafelbunyol
46139	La Pobla De Farnals
46140	Ademuz|Arroyo Cerezo|Mas Del Olmo|Puebla De San Miguel|Sesga|Val De La Sabina
46141	Castielfabib|Cuesta Del Rato
46142	Los Santos
46143	Torrebaja
46144	Mas De Jacinto|Torrealta
46145	Negron|Vallanca
46146	Casas Bajas
46147	Casas Altas
46148	Algimia De Alfara
46149	Gilet|Santo Espiritu Del Monte
46150	Campamento De Marines
46160	Lliria|Vanacloig
46162	Andilla|Artaj|Higueruelas|Oset De Andilla|Pobleta De Andilla
46163	Marines|Marines Viejo
46164	Pedralba
46165	Bugarra
46166	Gestalgar
46167	Chulilla
46168	Losa Del Obispo|Sot De Chera
46169	Gatova|Olocau
46170	Villar Del Arzobispo
46171	Casinos
46172	Alcublas
46173	Benageber
46174	Domeño
46175	Calles|Domeño Antiguo
46176	Ahillas|Chelva|Ermitorio Del Remedio|Torrecilla
46177	Tuejar
46178	Alpuente|Baldovar De Alpuente|Campo Abajo|Campo Arriba|Collado De Alpuente|Corcolilla|Cuevarruz, La (Alpuente)|Cuevarruz, La (La Yesa)|El Chopo|El Hontanar|La Almeza|La Canaleja|La Carrasca|La Hortichuela|La Yesa|Titaguas
46179	Aras De Los Olmos|Losilla De Aras
46180	Benaguasil
46181	Benisano
46182	La Cañada|Vallesa, La (Urbanizacion)
46183	Eliana, L'
46184	Cumbres De San Antonio (Betera) (Urbanizacion)|Cumbres De San Antonio (San Antonio) (Urbanizacion)|San Antonio De Benageber
46185	La Pobla De Vallbona|Montecolorado (Urbanizacion)
46190	Riba-Roja De Turia
46191	Vilamarxant
46192	Monserrat
46193	Montroy
46194	Real
46195	Llombai
46196	Catadau
46197	Alfarp
46198	Dos Aguas|Millares
46199	Casas De Herrero|Castilblanques|Cortes De Pallas|El Oro|La Cabezuela|Otonel|Viñuelas
46200	Paiporta
46210	Picanya
46220	Alter, L'|Picassent
46225	Centro Penitenciario Picassent
46229	Fuente Del Omet
46230	Alginet|Lagos, Los (Alfarp) (Urbanizacion)|Lagos, Los (Alginet) (Urbanizacion)|San Patricio (Urbanizacion)
46240	Ausias March (Urbanizacion)|Carlet
46249	Villarrubia De Carlet
46250	Alcudia, L'|Montortal
46260	Alberic
46266	Antella
46267	Gavarda
46268	La Garrofera De Alzira
46269	Tous
46270	Villanueva De Castellon
46290	Alcasser
46291	Benimodo
46292	Massalaves
46293	Alcantera De Xuquer|Beneixida
46294	Carcer|Cotes
46295	Sellent|Sumacarcer
46300	Aldea De Estenas|Utiel
46310	Casas De Moya|Casas De Pradas|Casas Del Rey|Las Monjas|Los Marcos|Venta Del Moro
46311	Jaraguas
46312	Casas De Medina
46313	Cuevas, Las (Utiel)|Las Casas|Los Corrales
46314	Fuenterrobles
46315	Caudete De Las Fuentes
46317	Villargordo Del Cabriel
46320	Sinarcas
46321	Torre, Aldea De La
46330	Camporrobles
46339	La Loberuela
46340	Requena
46350	Chera
46351	Cañada, La (Requena)|Las Nogueras|Villar De Olmos|Villar De Tejas
46352	Campo Arcis|Casas De Eufemia|Los Duques
46353	Los Ruices
46354	Los Cojos|Los Isidros|Penen De Albosa
46355	Casas De Juan Vich|Casas De Sotos|Los Pedrones
46356	Casas Del Rio
46357	Azagador|El Ponton|Hortunas|La Portera
46360	Buñol
46367	Yatova
46368	Macastre
46369	Alborache
46370	Chiva
46380	Cheste
46388	Godelleta
46389	Conde Cortichelles, Del (Masia)|Turis
46390	Barrio Arroyo|Calderon|Chicanos|Derramador|Roma|San Antonio De Requena|San Juan De Requena
46391	El Rebollar
46392	Siete Aguas
46393	Loriguilla
46394	Oliveral, Del (Masia)|Ventas De Poyo
46400	Cullera
46408	El Dosel|Faro De Cullera|Mareny De San Lorenzo
46409	El Brosquil|El Estany|El Marenyet
46410	Sueca
46417	Riola
46418	Fortaleny
46419	Mareny Blau|Mareny De Les Barraquetes|Mareny De Vilches|Palmeretes, Les
46420	El Perello
46430	Sollana
46439	Romani
46440	Almussafes
46450	Benifaio
46460	Silla
46469	Beniparrell
46470	Albal|Catarroja|Massanassa
46500	Sagunt/Sagunto
46501	Petres
46510	Quartell
46511	Benifairo De Les Valls
46512	Faura
46513	Estacion De Los Valles
46514	Benavites
46515	Quart De Les Valls
46520	Almarda, De (Playa)|Puerto De Sagunto
46529	Canet D'En Berenguer
46530	Puçol
46540	El Puig|Puig, Del (Playa)
46550	Albuixech
46560	Massalfassar
46590	Estivella
46591	Albalat Dels Taronchers
46592	Segart
46593	Algar De Palancia
46594	Alfara De La Baronia
46595	Torres-Torres
46600	Alzira
46610	Guadassuar
46611	Benimuslem
46612	Corbera
46613	Llauri
46614	Favara
46620	Ayora
46621	Casas De Madrona|San Benito|Zarra
46622	Teresa De Cofrentes
46623	Jarafuel
46624	Jalance
46625	Cofrentes|Hervideros De Cofrentes|Salto De Cofrentes
46630	La Font De La Figuera
46635	Casas De Vidal|Fontanars Dels Alforins|Las Pedradas|Poblet
46640	Mogente/Moixent
46650	Canals
46659	Ayacor|Torre De Cerda
46660	Manuel
46666	Berfull|Rafelguaraf|Riu Rau
46667	Barxeta
46668	Llocnou D'En Fenollet|Tosalnou
46669	Enova, L'|Sant Joanet|Senyera
46670	La Pobla Llarga
46680	Algemesi|Carrascalet
46687	Albalat De La Ribera
46688	Polinya De Xuquer
46689	Benicull De Xuquer
46690	Alcudia De Crespins, L'
46691	Vallada
46692	Montesa
46700	Gandia
46701	Gandia
46702	Gandia
46703	Gandia
46710	Daimus|Daimus, De (Playa)
46711	Guardamar De La Safor|Miramar|Miramar, De (Playa)
46712	Piles|Piles, De (Playa)
46713	Bellreguard Poble|Bellreguard, De (Playa)
46714	Palmera
46715	Alqueria De La Comtessa, L'/Alqueria De La Condesa
46716	Rafelcofer
46717	La Font D'En Carros
46720	Villalonga
46721	Potries
46722	Beniarjo|Benifla
46723	Almoines
46724	Palma De Gandia
46725	Alfauir|Rotova
46726	Almisera|Castellonet De La Conquesta|Llocnou De Sant Jeroni
46727	Real De Gandia
46728	Gandia|Marchuquera
46729	Ador|Montecorona (Urbanitzacio)
46730	Gandia|Moli Santa Maria|Puerto De Gandia
46740	Carcaixent
46749	Cogullada
46750	Simat De La Valldigna
46758	Barx|La Drova|La Puigmola
46759	Corrales De Valldigna
46760	Tavernes De La Valldigna|Tavernes De La Valldigna, De (Playa)
46770	Xeraco
46780	Oliva
46790	Xeresa
46791	Benifairo De La Valldigna
46792	Barraca D'Aigues Vives
46800	Anahuir|Sorio|Torre De Lloris|Xativa
46810	Enguera
46811	Navalon De Abajo|Navalon De Arriba
46812	Aielo De Malferit
46813	Cerda
46814	Llanera De Ranes|Torrella
46815	La Llosa De Ranes
46816	Rotgla I Corbera|Torrent De Fenollet
46817	Estubeny
46818	La Granja De La Costera|Valles
46819	Novele/Novetle
46820	Anna|Barrio Fuente Negra
46821	Chella
46822	Bolbaite
46823	Navarres
46824	Quesa
46825	Bicorp
46830	Beniganim
46837	Quatretonda
46838	Benicolet|Llutxent|Pinet
46839	Bellus|Benisuera|Guadasequies|Sempere
46840	La Pobla Del Duc
46841	Castello De Rugat
46842	Aielo De Rugat|Montitxelvo/Montichelvo|Rugat|Terrateig
46843	Rafol De Salem|Salem
46844	Beniatjar|Otos
46850	Olleria, L'
46860	Albaida
46868	Belgida
46869	Atzeneta D'Albaida|Benisoda|Carricola
46870	Ontinyent
46880	Bocairent
46890	Agullent
46891	Bufali|El Palomar
46892	Montaverner
46893	Alfarrasi
46894	Alboy|Genoves
46900	El Realon|Torrent
46901	El Vedat De Torrente
46909	Juez, Del (Masia)
46910	Alfafar|Benetusser|Lugar Nuevo De La Corona|Sedavi
46920	Mislata
46930	Barrio De Porta|Barrio Jose Artesano|Quart De Poblet
46940	Aeropuerto De Manises (Valencia)|Collado (Partida)|La Presa|Manises
46950	Xirivella
46960	Aldaia|Barrio Del Cristo
46970	Alaquas
46980	Cruz De Gracia|Paterna
46988	Poligono Fuente Del Jarro
46989	Terramelar
47001	Valladolid
47002	Valladolid
47003	Valladolid
47004	Valladolid
47005	Valladolid
47006	Valladolid
47007	Valladolid
47008	Valladolid
47009	Valladolid
47010	Valladolid
47011	Valladolid
47012	Valladolid
47013	Valladolid
47014	Valladolid
47015	Valladolid
47016	Valladolid
47017	Valladolid
47018	Valladolid
47070	Valladolid
47071	Valladolid
47080	Valladolid
47100	Tordesillas
47110	Casasola De Arion
47111	Villalar De Los Comuneros
47112	Pedrosa Del Rey
47113	Villalbarba|Villavieja Del Cerro
47114	Matilla De Los Caños|Torrecilla De La Abadesa|Velilla
47115	Bercero|Berceruelo
47116	Pollos
47120	Mota Del Marques
47129	Adalia|Barruelo Del Valle|San Cebrian De Mazote|San Pelayo|Torrecilla De La Torre
47130	Simancas
47131	Geria|Robladillo|Velliza|Ventas De Geria|Villan De Tordesillas
47132	Pedroso De La Abadesa|San Miguel Del Pino|Villamarciel
47133	Marzales|Vega De Valdetronco
47134	Gallegos De Hornija|San Salvador|Torrelobaton|Villasexmir
47140	Laguna De Duero
47150	Viana De Cega
47151	Boecillo
47152	Puente Duero|Valladolid
47153	El Pinar|El Pinar De Antequera|Valladolid
47155	Santovenia De Pisuerga
47160	Aldea De San Miguel|Arrabal De Portillo|Portillo
47161	Herrera De Duero
47162	Aldeamayor De San Martin
47164	San Miguel Del Arroyo|Santiago Del Arroyo
47165	Camporredondo
47166	Viloria
47169	La Corala|Otero, El (Urbanizacion)
47170	Renedo De Esgueva
47171	Castronuevo De Esgueva
47172	Villarmentero De Esgueva
47173	Olmos De Esgueva
47174	Villanueva De Los Infantes
47175	Piña De Esgueva
47176	Esguevillas De Esgueva
47177	Amusquillo
47180	Villafuerte
47181	Villaco
47182	Castroverde De Cerrato
47183	Torre De Esgueva
47184	Fombellida
47185	Canillas De Esgueva
47186	Encinas De Esgueva
47190	Wamba
47191	Ciguñuela
47192	Castrodeza
47193	La Cisterniga
47194	Fuensaldaña|Mucientes
47195	Arroyo De La Encomienda|La Flecha
47196	La Pedraja De Portillo
47197	Valladolid
47200	Valoria La Buena
47209	Muedra (Granja)|San Martin De Valveni
47210	Ataquines
47219	Honcalada|Muriel|Salvador De Zapardiel|San Pablo De La Moraleja
47220	Pozaldez
47230	Matapozuelos
47231	Serrada
47232	Ventosa De La Cuesta
47237	Villalba De Adaja
47238	Alcazaren|Hornillos De Eresma
47239	Aniago|Villanueva De Duero
47240	Valdestillas
47250	Mojados
47260	Cabezon De Pisuerga
47270	Cigales
47280	Corcos
47281	Aguilarejo
47282	Trigueros Del Valle
47283	Quintanilla De Trigueros
47290	Cubillas De Santa Marta
47300	Peñafiel
47310	Campaspero
47311	Canalejas De Peñafiel|Fompedraza
47312	Bahabon
47313	Aldealbar|Aldeyuso|Cogeces Del Monte|Molpeceres|Torrescarcela
47314	Langayo|Manzanillo|Padilla De Duero
47315	Pesquera De Duero
47316	Curiel De Duero|Piñel De Abajo|Piñel De Arriba|Roturas
47317	Bocos De Duero|Corrales De Duero|San Llorente|Valdearcos De La Vega
47318	Castrillo De Duero|Melida|Olmos De Peñafiel
47319	Rabano|Torre De Peñafiel
47320	Montemayor De Pililla|Tudela De Duero
47328	La Parrilla
47329	Castrillo-Tejeriego|Villabañez|Villavaquerin
47330	Traspinedo
47331	Santibañez De Valcorba
47340	Sardon De Duero
47350	Quintanilla De Onesimo
47359	Olivares De Duero|San Bernardo|Valbuena De Duero|Vega Sicilia
47360	Quintanilla De Arriba
47400	Medina Del Campo
47410	Olmedo
47418	Aguasal|Fuente-Olmedo|Llano De Olmedo
47419	Almenara De Adaja|Bocigas|Puras
47420	Iscar
47430	Pedrajas De San Esteban
47440	Cogeces De Iscar|Megeces
47450	Pozal De Gallinas
47451	Calabazas
47452	La Zarza
47453	Ramiro
47454	Moraleja De Las Panadera
47460	El Campillo
47461	Brahojos De Medina
47462	Bobadilla Del Campo
47463	Velascalvaro
47464	Nueva Villa De Las Torres
47465	Villaverde De Medina
47470	Carpio
47480	Fresno El Viejo
47490	Rueda
47491	La Seca
47492	Foncastin|Rodilana
47493	Gomeznarro|San Vicente Del Palacio
47494	Cervillego De La Cruz|Fuente El Sol|Lomoviejo|Rubi De Bracamonte
47500	Nava Del Rey
47509	Torrecilla Del Valle
47510	Alaejos
47511	Siete Iglesias De Trabancos
47512	Castrejon De Trabancos
47513	Torrecilla De La Orden
47520	Castronuño
47529	Villafranca De Duero
47530	San Roman De La Hornija
47600	Villalon De Campos
47606	Gaton De Campos|Villafrades De Campos
47607	Herrin De Campos|Villacid De Campos
47608	Bustillo De Chaves|Gordaliza De La Loma|Villagomez La Nueva|Villanueva De La Condesa
47609	Fontihoyuelo|Santervas De Campos|Vega De Ruiponce|Villacarralon|Villacreces|Zorita De La Loma
47610	Zaratan
47620	Villanubla
47630	La Mudarra
47639	Paramo De Matallana|Villalba De Los Alcores
47640	Peñaflor De Hornija|Torozos (Monte)
47641	Castromonte|La Santa Espina
47650	Cuenca De Campos
47664	Castroponce De Valderaduey
47670	Becilla De Valderaduey|La Union De Campos
47671	Urones De Castroponce
47672	Valdunquillo
47673	Quintanilla Del Molar|Roales De Campos
47674	Barcial De La Loma
47675	Bolaños De Campos|Villalan De Campos
47676	Villavicencio De Los Caballeros
47680	Mayorga
47686	Melgar De Arriba
47687	Melgar De Abajo
47688	Monasterio De Vega
47689	Cabezon De Valderaduey|Castrobol|Saelices De Mayorga|Villalba De La Loma
47690	Valverde De Campos
47691	Moral De La Reina
47692	Ceinos De Campos
47800	Medina De Rioseco
47810	Villafrechos
47811	Morales De Campos|Santa Eufemia Del Arroyo|Villaesper
47812	Palazuelo De Vedija
47813	Berrueces|Villanueva De San Mancio
47814	Aguilar De Campos|Villamuriel De Campos
47815	Tamariz De Campos|Villabaruz De Campos
47816	Montealegre De Campos|Palacios De Campos|Valdenebro De Los Valles
47820	Villabragima
47830	Tordehumos
47831	Pozuelo De La Orden
47832	Cabreros Del Monte
47840	Villagarcia De Campos
47850	Villanueva De Los Caballeros
47851	San Pedro De Latarce
47860	Villardefrades
47862	Urueña
47870	Tiedra
47880	Benafarces
47881	Pobladura De Sotiedra
47882	Castromembibre
47883	Villavellid
48001	Bilbao
48002	Bilbao
48003	Bilbao|La Peña|Ollargan|Santa Isabel
48004	Bilbao
48005	Bilbao
48006	Bilbao
48007	Bilbao
48008	Bilbao
48009	Bilbao
48010	Bilbao
48011	Bilbao
48012	Bilbao
48013	Bilbao
48014	Bilbao
48015	Bilbao
48070	Bilbao
48071	Bilbao
48080	Bilbao
48100	Atela|Atxuri|Basozabal|Belako|Berreagamendi|Billela|Elgezabal|Iturribaltzaga|Laukariz|Llona|Maurola|Mungia|Trobika|Zabalondo
48110	Butroe|Garai (Gatika)|Gatika|Gorordo|Igartua|Libaroa|Lubarrietaondo (Urbanizacion)|Sertutxa|Ugarte (Gatika)|Urresti|Zurbao
48111	Aurrekoetxea|Elexalde (Laukiz)|Jose Antonio Agirre|Laukiz|Mendiondo (Laukiz)|Mentxaketa|Unbe-Mendi
48112	Erbera (Maruri-Jatabe)|Ergoien (Maruri-Jatabe)|Maruri-Jatabe
48113	Elexalde (Gamiz-Fika)|Ergoien (Gamiz-Fika)|Gamiz-Fika|Ibarra (Gamiz-Fika)|Mendotza
48114	Agirre (Arrieta)|Arrieta|Jainko-Oleaga|Libao|Olatxua-Olabarri
48115	Andra Mari (Morga)|Eskerika|Ganbe|Meaka|Meakaur|Morga|Morgaondo|Oñarte
48116	Aldai|Andeko (Fruiz)|Botiola|Fruiz|Mandaluiz
48120	Ametzaga|Emerando (Meñaka)|Emerando (Mungia)|Larrauri-Markaida|Markaida|Mesterika|Meñaka|Meñakabarrena
48130	Artzalde|Bakio|Basigo|Goitisolo|San Pelaio|Urkizaur|Zubiaur (Bakio)
48140	Arantzazu|Arantzazugoiti|Basauntz|Elexalde (Igorre)|Garbe|Igorre|Olabarri|Olarra|Sabino Arana|San Juan (Igorre)|Santa Lutzia|Urkizu|Zelaia (Arantzazu)
48141	Aroztegieta|Bargondia|Bikarregi|Dima|Indusi|Intxaurbizkar|Lamindao|Oba|Olazabal (Dima)|Ugarana
48142	Artea|Bildosola|Elexabeitia|Esparta|Herriko Plaza|Sarasola|Ugarte (Artea)
48143	Areatza|Launtzain|Uparan
48144	Altzuaga|Altzusta|Asterria|Ibarguen|Ipiñaburu|Otzerinmendi|Plaza|Undurraga|Uribe|Zeanuri
48145	Magdalena (Ubide)|San Juan (Ubide)|Ubide
48150	Basozabal (Sondika)|Izartza|Julio Arteche (Poblado)|Landa (Sondika)|Sondika|Zangroiz (Sondika)
48160	Aldekona (San Isidro)|Aranoltza (San Antolin)|Arteaga (Derio)|Derio|Elexalde Derio|San Esteban (Derio)|Ugaldeguren (Santimami)
48170	Aranoltza-San Antolin|Arteaga-San Martin|Geldo|Parque Tecnologico (Zamudio)|Ugaldeguren (Santimami)
48180	Aeropuerto De Loiu|Elotxelerri|Lauroeta|Loiu|Zabaloetxe|Zangroiz (Loiu)
48190	El Castaño|Jarralta|La Baluga|Las Muñecas|Las Ribas|Mercadillo|San Martin De Carral|Sopuerta
48191	Aceña, La /Atxuriaga|El Arenao|El Ventorro|Galdames|Llano|Montellano|San Esteban (Galdames)|San Pedro (Galdames)|Txabarri
48192	Gordexola|Iratzagorria|Sandamendi
48194	Zaldu|Zubieta (Gordexola)
48195	Gaztelu|Goikoelexalde|Larrabetzu
48196	Aretxalde|Garaioltza|Goitioltza|Lezama
48200	Durango|Garai|Garai-San Migel|Goierri (Garai)|Momoitio
48210	Andaparaluzeta|Mekoleta|Otxandio
48211	Urkiola
48212	Mañaria
48213	Izurtza
48215	Aita San Miguel|Amatza|Arandia|Arriandi|Artatza (Iurreta)|Bakixa|Fauste|Garaizar|Gaztañatza|Goiuria|Iturburu|Iurreta|Mallabiena|Mañariku|Oromiño (Iurreta)|Orozketa|San Andres (Iurreta)|San Marko|Santa Apolonia|Santa Maña
48220	Abadiño|Abadiño-Zelaieta|Gaztelua|Gerediaga|Mendiola|Muntsaratz|Traña-Matiena
48230	Berrio-Aldape|Berriozabaleta-Aramiño|Elorrio|Gazeta|Gaztañeta|Iguria|Leiz-Miota|Lekeriketa|Mendraka|San Agustin
48240	Andikoa|Berriz|Okango|Olakueta|Sarria
48249	Eitua|Murgoitio|Sallobente
48250	Gazaga|Goierri (Zaldibar)|Zaldibar
48260	Eitzaga|Ermua
48269	Arandoño|Areitio|Berano Nagusia|Berano Txikia|Gerea|Goita|Goitondo (Poligono Industrial)|Mallabia|Osma|Urtia (Poligono Industrial)
48270	Markina-Xemein
48276	Larruskain-Amalloa|Ubilla-Urberuaga
48277	Altzaa|Aulesti (Etxebarria)|Erbera (Etxebarria)|Etxebarria|Galartza|San Andres (Etxebarria)|Unamuntzaga
48278	Arta|Barinaga|Bolibar|Iluntzar|Iturreta (Markina-Xemein)|Meabe|Zeinka-Zearregi|Ziortza-Goierria-
48280	Lekeitio
48287	Bedaroa|Ea
48288	Barainka|Gardata-Artika|Ispaster|Ispaster-Elexalde|Kutziaga-Arropain|Mendazoa|Solarte-Gallete|Soloaran
48289	Amoroto|Eguen|Eleizaldea (Gizaburuaga)|Elexalde (Amoroto)|Gizaburuaga|Iturreta (Mendexa)|Lariz|Laxier|Leagi|Likoa|Mendexa|Odiaga|Okamika|Ugaran|Urrutia|Zelaia (Mendexa)
48291	Apatamonasterio|Arrazola|Artia-Jauregi (Poligono Industrial)|Atxondo|Axpe (Atxondo)|Marzana|Olazabal (Atxondo)|San Juan (Atxondo)|Santiago
48300	Arana|Errenteria|Gernika-Lumo|Lumo|Zallo
48309	Atxika-Errekalde|Baldatika|Elexalde-Olabarri|Errigoiti|Metxika
48310	Elantxobe
48311	Akorda|Elexalde (Ibarrangelu)|Ibarrangelu|Natxitua
48312	Elexalde (Nabarniz)|Ikazurieta|Intxaurraga (Nabarniz)|Lekerika|Merika|Nabarniz|Uribarri-Zabaleta
48313	Akorda-Bollar|Basetxeta-Atxoste|Elexalde-Zeeta|Ereño|Gabika
48314	Basetxeta|Errekalde (Gautegiz Arteaga)|Gautegiz Arteaga|Isla|Kanala (Gautegiz Arteaga)|Kanala (Sukarrieta)|Zelaieta
48315	Basando|Elorriaga-Santa Ana|Kortezubi|Oma
48320	Ajangiz|Kanpantxu|Mendieta (Ajangiz)
48330	Agarre (Lemoa)|Arantxe|Arraibi|Arraño|Azurreka|Bolunburu|Bolunburu (Poligono Industrial)|Durandio|Elizondo|Elorriaga (Lemoa)|Errekalde (Lemoa)|Estaziñoa|Intzuntza (Lemoa)|Iturritxe|Larrabeiti|Lemoa|Lemorieta|Mendieta (Lemoa)|Mendieta (Poligono Industrial)|Pozueta|San Inazio|Tallerreta|Txiriboketa|Zubieta (Lemoa)
48340	Aldana|Amorebieta-Etxano|Astepe|Autzagana|Bernagoitia|Boroa|Etxano|Euba|Oromiño (Amotebieta-Etxano)|San Miguel (Amorebieta-Etxano)
48350	Altamira-San Kristobal|Axpe-San Bartolome|Busturia
48360	Arketa-Aranburu|Mundaka|Portuondo-Basaran
48370	Agirre (Bermeo)|Almika|Arane|Arranotegi|Artika|Baratz-Eder|Bermeo|Demiku|Landabaso (Poligono Industrial)|Mañu|Pelaio Deuna|San Andres|San Miguel
48380	Aulesti|Goiherri (Aulesti)|Ibarrola|Malats|Narea|San Anton|Urriola|Zubero
48381	Berreño|Gerrika|Gerrikaitz|Munitibar-Arbatzegi Gerrikaitz|Totorika
48382	Albiz|Elejalde (Mendata)|Marmiz|Mendata|Olabe
48383	Arratzu|Barroeta (Arratzu)|Barrutia|Elexalde (Arratzu)|Gorozika (Arratzu)|Loiola|Monte|Uarka|Zabala-Belendiz|Zubiate (Arratzu)
48390	Asteitza|Barroeta (Bedia)|Bedia|Bidekoetxea|Elexalde (Bedia)|Ereño (Bedia)|Eroso-Ugarte|Ibarra (Bedia)|Jauregi|Murtatza
48391	Aiuria|Gorozika (Muxika)|Ibarruri
48392	Muxika|San Roman (Muxika)|Ugartegoikoa (Muxika)|Usparitxa
48393	Armotxerria|Atxondoa|Elexalde (Forua)|Forua|Gaitoka|Landaberde|Urberuaga
48394	Murueta
48395	Abiña (Andoni Deuna)|Sukarrieta|Txatxarramendi
48410	Orozko|Zubiaur (Orozko)
48419	Albizuelexaga|Arbaitza|Bengoetxea|Gallartu|Ibarra (Orozko)|Murueta (Orozko)|Urigoiti
48450	Doneztebe|Etxebarri|Kukullaga|Legizamon|San Esteban (Etxebarri)
48460	Belandia|Lendoño De Abajo/Lendoñobeiti|Lendoño De Arriba/Lendoño Goikoa|Mendeika|Urduña/Orduña|Villaño (Cerca De)
48480	Agirre (Arrigorriaga)|Arkotxa|Arrigorriaga|Brisketa|Burbustu-Altamira|Cubo|Gurutzalde|Gutiolo|Lanbarketa|Markio|Martiartu|Moiordin-Barrondo|Salud E Higiene|Zaratamo
48490	Ugao-Miraballes
48498	Arakaldo|Arene (Arrankudiaga)|Arrankudiaga|Bakiola, Poligono Industrial|Uribarri|Zuloaga
48499	Ametzola|Arbildu|Areiltza-Olatzar|Aresandiaga|Argiñao|Arkulanda|Aspiuntza|Ermitabarri-Ibarra|Gezala|Saldarian|Solatxi|Uriondo|Zeberio|Zollo-Elexalde|Zubialde
48500	Abanto|Abanto Y Ciervana|Abanto-Zierbena|Casal, El (Poligono Industrial)|Cotorrio|El Campillo|Gallarta|La Balastera|La Florida|La Hera|Las Calizas|Las Carreras|Las Cortes|Los Castaños|Murrieta|Picon|Putxeta|San Pedro (Abanto-Zierbena)|Sanfuentes|Santa Juliana|Triano (Abanto-Zierbena)
48508	Cuesta, La (Aldapa)|El Puerto|Kardeo|La Arena|San Mames (Zierbena)|San Roman (Zierbena)|Valle|Virgen De El Puerto|Zierbena
48510	Durañona|Elguero|Galindo-Salcedillo|Trapaga-Causo|Trapagaran|Ugarte (Valle De Trapaga)|Valle De Trapaga
48520	La Arboleda|Matamoros-Burzaco|Parcocha-Barrionuevo|Reineta, La/Larreineta
48530	Cadegal|La Orconera|Nocedal|Ortuella|Triano (Ortuella)|Urioste
48550	Cobaron|La Rigada|Muskiz|Pobeña|San Juan (Muskiz)|San Julian De Muskiz|Santelices
48600	Larrabasterra|Moreaga|Sopelana|Ugeraga
48610	Dobaran|Elortza|Landa (Urduliz)|Mendiondo (Urduliz)|Urduliz|Zalbidea
48620	Andraka|Armintza|Gure Mendi|Guzurmendi|Isuzkitza|Lemoiz|Plentzia|Saratxaga|Txipio|Urizar
48630	Elexalde (Gorliz)|Gandia|Gorliz|Urezarantza
48640	Baserri-Santa Ana|Berango
48650	Barrika|Elexalde (Barrika)|Goierri (Barrika)
48700	Ondarroa
48710	Asterrika|Berriatua|Erribera|Gardotza (Poligono Industrial)|Magdalena (Berriatua)|Mereludi
48800	Balmaseda|Pandozales|Peñueco
48810	Alonsotegi|Arbuio|Cadagua-Elkartegi (Poligono Industrial)|Irauregi
48820	La Quadra|Zaramillo
48830	Sodupe
48840	Güeñes
48850	Aranguren
48860	Mimetiz|Sollano-Llantada|Zalla
48869	Avellaneda|La Herrera|Otxaran
48870	Alen|Barrieta, La/Olabarrieta|Bezi
48879	Artzentales|Gorgolas|San Miguel De Linares|Santa Cruz|Traslaviña|Traslosheros
48880	Cueto|Gordon|La Iglesia|Pando (Trucios)|Trucios/Turtzioz
48890	Ambasaguas|Biañez|Bollain|El Callejo|El Suceso|Herboso|La Cadena|La Cerca|Manzaneda De Biañez|Matienzo|Molinar|Paules|Ranero|Rioseco|Santecilla
48891	Ahedo|Aldeacueva|Bernales|Carranza|Concha|Karrantza Harana|La Tejera|Lanzas Agudas|Las Barcenas|Pando (Carranza)|Presa|San Cipriano|San Esteban (Carranza)|Sierra|Soscaño|Valle De Carranza
48895	La Calera Del Prado|Lanestosa|Sangrices
48900	Barakaldo
48901	Barakaldo
48902	Barakaldo|San Bizenti-Barakaldo
48903	Barakaldo|Regato, El/Errekatxo
48910	Sestao
48920	Portugalete
48930	Getxo
48940	Aketxe|Artatza (Leioa)|Artatzagane|Begoñako Ama|Centro Civico (Leioa)|Elexalde (Leioa)|Estartetxe|Iturribide|La Chopera|Lamiako|Landabarri|Leioa|Los Pinos|Mendibile|Monte Ikea|Negurigane|Ondiz|Peruri|Sakoneta|San Bartolome|San Juan (Leioa)|Santimami (Leioa)|Santsoena|Sarriena|Telleria|Txorierri (Leioa)|Udondo|Zarrageta
48950	Altzaga|Arriaga|Astrabudua|Asua|Erandio|Erandiogoikoa|Goierri (Erandio)|Lutxana-Enekuri
48960	Agirre-Aperribai|Bekea|Elexalde (Galdakao)|Galdakao|Gumuzio|La Cruz|Usansolo
48970	Arizgoiti|Basauri|Elexalde (Basauri)|Mercabilbao|Urbi
48980	Balparda|El Villar|Santurtzi
48990	Getxo
48991	Getxo
48992	Getxo
48993	Getxo
48998	Getxo
49001	Zamora
49002	Zamora
49003	Zamora
49004	Zamora
49005	Zamora
49006	Zamora
49007	Zamora
49008	Zamora
49009	Zamora
49010	Zamora
49011	Zamora
49012	Zamora
49013	Zamora
49014	Zamora
49015	Zamora
49016	Zamora
49017	Zamora
49018	Zamora
49019	Zamora
49020	Zamora
49021	Zamora
49022	Zamora
49023	Zamora
49024	Zamora
49025	Zamora
49026	Zamora
49027	Carrascal|Zamora
49028	Zamora
49029	Zamora
49030	Zamora
49031	Zamora
49032	Zamora
49070	Zamora
49071	Zamora
49080	Zamora
49100	Villanueva Del Campo
49110	Castroverde De Campos
49120	Molacillos
49121	Monfarracinos
49122	Torres Del Carrizal
49123	Benegiles
49124	Aspariegos
49125	Cerecinos Del Carrizal
49126	Arquillinos|Villalba De La Lampreana
49127	Castronuevo De Los Arcos|Pobladura De Valderaduey
49128	Cañizo
49129	San Martin De Valderaduey|Villardiga
49130	Manganeses De La Lampreana
49131	Villamayor De Campos
49132	Villar De Fallaves
49133	Vega De Villalobos
49134	Villalobos
49135	Revellinos|San Agustin Del Pozo|Vidayanes
49136	Otero De Sariegos|Villafafila
49137	Villarrin De Campos
49140	Tabara
49141	Faramontanos Tabara
49142	Pajares De La Lampreana
49143	Piedrahita De Castro
49144	San Cebrian De Castro
49145	Perilla De Castro|San Pedro De Las Cuevas
49146	Navianos De Alba
49147	Marquiz De Alba|Olmillos De Castro
49148	Moreruela De Tabara|Pozuelo De Tabara|Santa Eulalia De Tabara
49149	Montamarta
49150	Moraleja Del Vino
49151	Arcenillas|Casaseca De Las Chanas|Gema
49152	Sanzoles
49153	Venialbo
49154	El Pego
49155	La Boveda De Toro
49156	Guarrate
49157	Bamba|Madridanos
49158	Villalazan
49159	Villaralbo|Zamora
49160	Carbajales De Alba
49161	Losilla|Santa Eufemia
49162	Andavias|Palacios Del Pan
49163	Manzanal Del Barco
49164	Cerezal De Aliste|Videmala
49165	Ricobayo|Villaflor|Villanueva De Los Corchos
49166	Carbajosa|Salto De Villalcampo|Villalcampo
49167	Muelas Del Pan|Salto De Esla
49168	Bermillo De Alba
49170	Tardobispo
49171	La Pueblica De Campean
49172	Las Enillas
49173	La Tuda
49174	Mogatar|Sobradillo De Palomares
49176	Tamame
49177	Alfaraz De Sayago|Escuadro|Figueruela De Sayago|Moraleja De Sayago|Soguino (Finca)|Torremut (Dehesa)|Viñuela De Sayago
49178	Peñausende|Villardiegua Del Sierro
49180	Almaraz De Duero|Zamora
49181	Villaseco Del Pan
49182	Valdeperdices
49183	Almendra|El Campillo
49190	Morales Del Vino
49191	Cazurra|Jambrina|Peleas De Abajo|Pontejos
49192	La Hiniesta|Roales|Valcabado
49200	Bermillo De Sayago
49210	Almeida De Sayago
49211	Carbellino|Roelos De Sayago|Salce|Villamor De Cadozos
49212	Muga De Sayago
49213	Fariza|Mamoles|Palazuelo De Sayago
49214	Badilla|Cozcurrita|Tudera|Zafara
49215	Luelmo|Monumenta|Villamor De La Ladre
49216	Fresno De Sayago|Piñuel|Torrefrades
49220	Fermoselle
49230	Cibanal|Formariz
49231	Pinilla De Fermoselle
49232	Fornillos De Fermoselle
49240	Pasariegos|Villar Del Buey
49250	Villadepera|Villardiegua De La Ribera
49251	Argañin|Gamones
49252	Torregamones
49253	Moralina
49254	Abelon|Moral De Sayago
49255	Fresnadillo|Ganame
49260	Fadon
49270	Sogo De Sayago
49271	Cernecina
49272	Arcillo|Malillos
49280	Pereruela
49281	San Roman De Los Infantes
49290	Dehesa De Pelazas
49300	Puebla De Sanabria
49310	Mombuey
49317	Lanseros|Manzanal De Los Infantes|Sejas De Sanabria|Valdemerilla
49318	Fresno De La Carballeda|Peque|Santa Eulalia De Rionegro|Valparaiso
49319	Donadillo|Dornillas|Gramedo|Otero De Centenos
49320	Otero De Sanabria|Triufe
49321	Cervantes|Ferreros|Paramio|Remesal De Sanabria|Robleda|San Juan De La Cuesta
49322	Palacios De Sanabria|Rionegrito|Rosinos De La Requejada|Vime De Sanabria
49323	Doney De La Requejada|Escuredo|Santiago De La Requejada
49324	Carbajalinos|Gusandanos|Monterrubio|Villar De Los Pisones
49325	Asturianos|Cerezal De Sanabria|Cernadilla|Entrepeñas|Lagarejos De La Carballeda|San Salvador De Palazuelo
49326	Rionegro Del Puente|Valleluengo
49327	Cubo De Benavente|Molezuelas De La Carballeda|Uña De Quintana
49329	Calzada De Tera
49330	Junquera De Tera|Milla De Tera|Villar De Farfon
49331	Calzadilla De Tera|Olleros De Tera|Vega De Tera
49332	Camarzana
49333	Bercianos De Valverde|Santa Maria De Valverde|Villanueva De Las Peras
49334	Litos
49335	Ferreras De Abajo|Ferreras De Arriba
49336	Otero De Bodas
49337	Val De Santa Maria|Villanueva De Valrojo
49340	Justel|Quintanilla De Justel
49341	Muelas De Los Caballeros|Vega Del Castillo
49342	Espadañedo|Faramontanos De La Sierra|Villarejo De La Sierra
49343	Villalverde
49344	Donado
49345	Utrera De La Encomienda
49346	Letrillas
49347	Carbajales De La Encomienda
49348	Rioconejos
49349	Anta De Rioconejos
49350	El Puente De Sanabria
49352	Moncabril
49357	Rozas|Valdespino
49358	Barrio De Rabano|Coso|Rabano De Sanabria|San Justo De Sanabria|Villarino De Sanabria
49359	Cerdillo|Murias|San Ciprian De Sanabria|Trefacio
49360	Cubelo|Galende|Rabanillo
49361	Pedrazales|San Martin De Castañeda|Vigo De Sanabria
49362	Ribadelago De Franco|Robles, Los (Camping)
49390	Castellanos|Sampil
49391	Rihonor De Castilla
49392	Baños De Calabor|Calabor|Lobeznos|Pedralba De La Praderia|Santa Cruz De Abranes
49393	Robledo De Sanabria|Ungilde
49394	Requejo|San Martin De Terroso|Santa Colomba De Sanabria|Terroso|Ventas De Terroso
49395	Ilanes|Limianos De Sanabria|Quintana De Sanabria|San Roman De Sanabria|Sotillo De Sanabria
49396	Avedillo De Sanabria|Barrio De Lomba|Castro De Sanabria|Cobreros|Riego De Lomba|San Miguel De Lomba
49400	Fuentesauco
49410	Fuentelapeña
49419	Castrillo De La Guareña
49420	Vadillo De La Guareña
49430	Villaescusa
49440	Cañizal
49450	El Olmo De La Guareña|Vallesa De La Guareña
49500	Alcañices
49510	Fonfria
49511	Brandilanes|El Castro De Alcañices|Salto De Castro
49512	Ceadea|Lober|Mellanes|Tolilla
49513	Fornillos De Aliste|Samir De Los Caños
49514	Arcillera|Moveros De Aliste|Pino De Oro|Vivinera
49515	Rabano De Aliste|Ribas De Aliste|Sejas De Aliste
49516	Latedo|Nuez De Aliste|Trabazos
49517	Alcorcillo|San Martin De Pedroso|Viñas De Aliste
49518	San Mamed|Santa Ana|Villarino Tras La Sierra
49519	Fradellos|Grisuela|Matellanes|Rabanales|Ufones
49520	Figueruela De Abajo|Figueruela De Arriba|Flechas
49521	Gallegos Del Campo|Moldones|Riomanzanas|Villarino De Manzanos
49522	Las Torres De Aliste|Mahide|Pobladura De Aliste
49523	San Cristobal De Aliste|San Vitero|Villarino Del Cebal
49524	El Poyo|San Blas|Vega De Nuez
49525	San Juan Del Rebollar|Tola
49530	Coreses
49539	Algodre|Gallegos Del Pan|Villalube
49540	Escober|Losacio|San Martin De Tabara
49541	Losacino|Vide De Alba
49542	Domez|Vegalatrave
49543	Castillo De Alba|Muga De Alba
49550	Ferreruela|Sesnandez
49559	Flores|Gallegos Del Rio|Puercas|Valer
49560	San Pedro De Las Herrerias
49561	Boya
49562	Villardeciervos
49563	Cional
49570	Lubian
49571	Castrelos
49572	Castromil|Hermisende|La Tejera|San Ciprian De Hermisende
49573	Chanos|Las Hedradas
49574	Aciberos|Hedroso|Padornelo
49580	Pias|Villanueva De La Sierra
49582	Barjacoba
49583	Porto
49590	Fresno De La Rivera|Matilla La Seca
49591	Abejera|Riofrio De Aliste|Sarracin De Aliste
49592	Bercianos De Aliste|Cabañas De Aliste|Campogrande De Aliste|Palazuelo De Las Cuevas|San Vicente De La Cabeza
49593	Linarejos|Santa Cruz De Los Cuerragos
49594	Codesal|Folgoso De La Carballeda|Manzanal De Arriba|Pedroso De La Carballeda|Sagallos|Sandin
49600	Benavente
49610	Santibañez De Vidriales
49618	Bercianos De Vidriales|Fuente Encalada|Rosinos De Vidriales|Tardemezar|Villageriz De Vidriales|Villaobispo De Vidriales
49619	Ayoo De Vidriales|Carracedo De Vidriales|Congosta De Vidriales|San Pedro De La Viña
49620	Santa Cristina De La Polvorosa
49621	Granucillo|Grijalba De Vidriales|Pozuelo De Vidriales
49622	Brime De Urz|Cunquilla De Vidriales|Moratones De Vidriales|Quintanilla De Urz|Quiruelas De Vidriales
49623	Colinas De Transmonte|Vecilla De Transmonte
49624	Abraveses De Tera|Aguilar De Tera|Micereces De Tera|Sitrama De Tera
49625	Santibañez De Tera
49626	Melgar De Tera|Pumarejo De Tera|Santa Croya De Tera|Santa Marta De Tera
49627	Cabañas De Tera|San Juanico El Nuevo
49628	San Pedro De Ceque
49629	Brime De Sog
49630	Villalpando
49637	Cotanes Del Monte
49638	Prado|Quintanilla Del Olmo
49639	Quintanilla Del Monte|Tapioles
49640	Cerecinos De Campos
49650	San Esteban Del Molar
49660	Castrogonzalo|Castropepe
49670	Fuentes De Ropel
49680	San Miguel Del Valle|Valdescorriel
49690	San Cristobal De Entreviñas
49691	San Miguel Del Esla|Santa Colomba De Las Carabias
49692	Matilla De Arzon
49693	Fresno De La Polvorosa|Morales Del Rey|Vecilla De La Polvorosa
49694	Manganeses De La Polvorosa
49695	Villaferrueña
49696	Alcubilla De Nogales|Arrabalde|Santa Maria De La Vega
49697	Morales De Valverde|Navianos De Valverde|Pueblica De Valverde|San Pedro De Zamudia|Villanazar|Villaveza De Valverde
49698	Bretocino|Burganes De Valverde|Friera De Valverde|Mozar De Valverde|Olmillos De Valverde
49699	Arcos De La Polvorosa|Milles De La Polvorosa|Santa Colomba De Las Monjas|Villanueva De Azoague
49700	Corrales Del Vino
49706	Fuente El Carnero|Peleas De Arriba
49707	Santa Clara De Avedillo
49708	Casaseca De Campean|Villanueva De Campean
49709	Cabañas De Sayago
49710	El Cubo De Tierra Del Vino
49714	Fuentespreadas
49715	El Piñero
49716	Argujillo
49717	Cuelgamures|San Miguel De La Ribera
49718	Mayalde
49719	El Maderal|Villamor De Los Escuderos
49720	Amor, De (Dehesa)|El Perdigon
49721	Entrala
49722	San Marcial
49730	Cubillos
49731	Moreruela De Los Infanzones
49740	Granja De Moreruela
49741	La Tabla
49742	Riego Del Camino
49743	Fontanillas De Castro
49750	Santovenia
49751	Breto
49760	Barcial Del Barco|Villaveza Del Agua
49770	Villabrazaro
49780	Pobladura Del Valle
49781	La Torre Del Valle|Paladinos Del Valle
49782	San Roman Del Valle
49783	Coomonte|Maire De Castroponce
49800	Toro
49810	Morales De Toro
49820	Villabuena Del Puente
49830	Belver De Los Montes
49831	Bustillo Del Oro
49832	Malva
49833	Fuentesecas
49834	Abezames
49835	Pozoantiguo
49836	Tagarabuena
49840	Vezdemarban
49850	Pinilla De Toro
49860	Villalonso
49870	Villavendimio
49871	Villardondiego
49880	Peleagonzalo
49881	Monte La Reina
49882	Valdefinjas
50001	Zaragoza
50002	Zaragoza
50003	Zaragoza
50004	Zaragoza
50005	Zaragoza
50006	Zaragoza
50007	Zaragoza
50008	Zaragoza
50009	Zaragoza
50010	Zaragoza
50011	Zaragoza
50012	Zaragoza
50013	Zaragoza
50014	Zaragoza
50015	Zaragoza
50016	Zaragoza
50017	Zaragoza
50018	Zaragoza
50019	Zaragoza
50020	Urbanizacion El Zorongo (Nucleo)
50021	Zaragoza
50022	Zaragoza
50059	Barrio Montañana|Zaragoza
50070	Zaragoza
50071	Zaragoza
50080	Zaragoza
50090	Academia General Militar|Zaragoza
50100	La Almunia De Doña Godina
50108	Almonacid De La Sierra
50109	Alpartir
50110	Campamento San Gregorio
50120	Alfocea|Monzalbarba
50130	Belchite
50131	Lecera
50132	Codo
50133	Almonacid De La Cuba
50134	Lagata|Samper De Salz
50135	Mediana De Aragon
50136	Letux
50137	Puebla De Alborton
50138	Valmadrid
50139	Torrecilla De Valmadrid
50140	Azuara
50141	Jaulin
50142	Fuendetodos
50143	Moyuela|Plenas
50144	Moneva
50150	Herrera De Los Navarros
50151	Luesma
50152	Ailes|Mezalocha
50153	Villanueva Del Huerva
50154	Tosos
50155	Aguilon
50156	Villar De Los Navarros
50160	Leciñena
50161	Perdiguera
50162	Villamayor De Gallego
50163	Farlete
50164	Monegrillo
50170	Mequinenza
50171	La Puebla De Alfinden
50172	Alfajarin
50173	Nuez De Ebro
50174	Villafranca De Ebro
50175	Aguilar De Ebro|Osera
50176	Hostal El Ciervo
50177	Bujaraloz
50178	La Almolda
50180	Utebo
50190	Aeropuerto De Garrapinillos (Zaragoza)|Garrapinillos|Torre Balmez (Barrio De Garrapinillos)
50191	Barrio De Juslibol
50192	Aula-Dei (Cartuja De)
50193	Peñaflor De Gallego
50194	Movera
50195	La Alfranca|Lugarico De Cerdan|Pastriz
50196	La Muela
50197	Plataforma Logistica Plaza|Zaragoza
50198	Poligono Industrial Centrovia (La Muela)
50200	Ateca
50210	Monasterio De Piedra|Nuevalos
50211	Castejon De Las Armas
50212	Carenas
50213	Cimballa|Granja De Oro|Llumes (Nucleo)|Lugar Nuevo|Monterde
50214	Campillo De Aragon
50215	Moros
50216	Villalengua
50217	Torrijo De La Cañada
50219	La Vilueña|Munebrega|Valtorres
50220	Ariza
50227	Sisamon
50228	Cabolafuente
50229	Bordalba
50230	Alhama De Aragon
50236	Ibdes
50237	Jaraba
50238	Calmarza|Godojos|Jaraba (Baños De La Virgen)
50239	Bubierca|Casa De La Vega|Contamina|Embid De Ariza
50240	Mores
50246	Brea De Aragon
50247	Purroy De Jalon
50248	Sestrica
50249	Viver De La Sierra
50250	Illueca
50257	Gotor
50258	Jarque|Oseja
50259	Aranda De Moncayo|Pomer
50260	Morata De Jalon
50266	Arandiga
50267	Mesones De Isuela
50268	Calcena|Purujosa|Trasobares
50269	Chodes|Las Minas De Tierga|Niguella|Tierga
50270	Ricla
50280	Calatorao
50290	Epila
50291	Monreal De Ariza
50292	Cetina
50293	Terrer
50294	Berbedel|Lucena De Jalon|Salillas De Jalon
50295	Lumpiaque|Rueda De Jalon
50296	Bardallur|Plasencia De Jalon|Urrea De Jalon
50297	Barboles|Grisen|Oitura|Peraman|Pleitas
50298	Pinseque
50299	Campiel|Embid De La Ribera|Paracuellos De La Ribera|Sabiñan
50300	Calatayud
50310	Villarroya De La Sierra
50311	Torralba De Ribota
50312	Cervera De La Cañada
50313	Aniñon
50314	Clares De Ribota
50315	Malanquilla
50316	Berdejo|Bijuesca|Torrelapaja
50320	El Frasno
50322	Aluenda
50323	Inoges
50324	Aldehuela De Grio|Santa Cruz Del Grio|Viver De Vicort
50325	Tobed
50326	Codos
50330	Miedes De Aragon
50331	Mara|Orera|Ruesca
50332	Belmonte De Gracian
50333	Villalba De Perejiles
50334	Sediles
50335	Barrio Torres
50336	Huermeda
50340	Maluenda
50341	Olves
50342	Paracuellos De Jiloca
50343	Velilla De Jiloca
50344	Morata De Jiloca
50345	Alarba
50346	Castejon De Alarba
50347	Acered
50348	Atea
50360	Daroca
50366	Balconchan|Manchones|Murero|Orcajo
50367	Langa Del Castillo|Retascon
50368	Cerveruela|Mainar|Torralbilla|Villarroya Del Campo
50369	Anento|Lechon|Nombrevilla
50370	Villanueva De Jiloca
50371	Valdehorna
50372	Val De San Martin
50373	Berrueco|Gallocanta|Las Cuerlas|Santed
50374	Aldehuela De Liestos|Torralba De Los Frailes|Used
50375	Abanto
50376	Cubel
50390	Fuentes De Jiloca
50391	Monton|Villafeliche
50400	Cariñena
50408	Aguaron
50409	Cosuenda
50410	Cuarte De Huerva
50411	Santa Fe
50420	Cadrete
50430	Maria De Huerva
50440	Mozota
50441	Botorrita
50450	Muel
50460	Longares
50461	Alfamen
50470	Encinacorba
50480	Paniza
50481	Aladren
50482	Vistabella
50490	Villadoz|Villarreal De Huerva
50491	Badules|Fombuena|Romanos
50500	Tarazona
50510	Novallas
50511	Malon
50512	Torrellas
50513	Cunchillos|Grisel|Los Fayos|Santa Cruz De Moncayo|Vierlas
50514	Tortoles
50520	Magallon
50529	Alberite De San Juan|Fuendejalon|Pozuelo De Aragon
50530	Novillas
50540	Borja
50546	Ambel|Bulbuente|Talamantes
50547	Bureta|Tabuenca
50548	El Buste|Nuestra Señora Misericordia
50549	Albeta|Malejan
50550	Mallen
50560	Agon
50561	Bisimbre
50562	Frescano
50570	Ainzon
50580	Vera De Moncayo
50581	Lituenigo
50582	Litago
50583	Trasmoz
50584	San Martin De La Virgen De Moncayo
50590	Añon De Moncayo
50591	Alcala De Moncayo
50592	El Monasterio De Veruela|Veruela
50596	Barues|Mamillas|Novellaco
50600	Ejea De Los Caballeros
50610	El Frago|Luna
50611	Erla
50612	Castejon De Valdejasa|Las Pedrosas|Sierra De Luna
50614	Ardisa|Casas De Espes|Puendeluna
50615	Lacorvilla|Valpalmas
50616	Marracos|Piedratajada
50617	El Sabinar|Santa Anastasia|Valareña
50619	Asin|Biel|Farasdues|Fuencalderas|Luesia|Ores|Rivas
50620	Casetas
50629	Sobradiel
50630	Alagon
50637	Remolinos
50638	Cabañas De Ebro
50639	Figueruelas
50640	Luceni
50641	Boquiñeni
50650	Gallur
50660	Tauste
50668	Pradilla De Ebro
50669	Sancho Abarca|Santa Engracia
50670	Sadaba
50678	Uncastillo
50679	Alera|Layana
50680	Sos Del Rey Catolico
50682	Esco|Sigues|Tiermas
50683	Artieda|Asso Veral|Mianos
50684	Salvatierra De Esca
50685	Bagues|Gordues|Pintano|Undues Pintano|Urries
50686	Gondun|Navardun|Petilla De Aragon (Pueblo)
50687	Isuerre|Lobera De Onsella
50688	Longas
50689	Campo Real|Undues De Lerda
50690	Pedrola
50691	Alcala De Ebro
50692	Camino Real|La Joyosa|Marlofa|Villarrapa
50693	Torres De Berrellen
50694	Bardena Del Caudillo|El Bayo|Pinsoro
50695	Biota|Malpica De Arba
50696	Castiliscar|Sofuentes
50700	Caspe
50709	Miraflores, Huerta De|Vuelta De Rodan|Vuelta Del Cañar|Zaragoceta
50710	Maella
50720	Cartuja Baja
50730	El Burgo De Ebro
50740	Fuentes De Ebro
50741	Roden
50750	Pina De Ebro
50760	Velilla De Ebro
50770	Quinto
50780	Sastago
50781	Alborge
50782	Cinco Olivas
50783	Alforque
50784	La Zaida
50786	Gelsa
50790	Escatron
50792	Chiprana
50793	Fabara
50794	Nonaspe
50795	Fayon
50800	Zuera
50810	Ontinar De Salz
50820	San Juan Mozarrifar
50830	Lomas Del Gallego|Villanueva De Gallego
50840	San Mateo De Gallego
51001	Ceuta
51002	Ceuta
51003	Ceuta
51004	Ceuta
51005	Ceuta
51070	Ceuta
51071	Ceuta
51080	Ceuta
52001	Melilla
52002	Melilla
52003	Melilla
52004	Melilla
52005	Melilla
52006	Melilla
52070	Melilla
52071	Melilla
52080	Melilla
