SYNOPSIS
========

        use DateTime::TimeZone;
        # After DateTime::TimeZone is loaded, let's extend it
        use DateTime::TimeZone::Catalog::Extend;
        # That's it; nothing more

        # This would normally trigger an exception, but not anymore
        my $tz = DateTime::TimeZone->new( name => 'JST' );

        # Get the list of all aliases
        my $aliases = DateTime::TimeZone::Catalog::Extend->aliases;

        my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
        my $fmt = DateTime::Format::Strptime->new(
            pattern => $pattern,
            zone_map => $map,
        );
        my $dt = $fmt->parse_datetime( $str );
        die( $fmt->errmsg ) if( !defined( $dt ) );

VERSION
=======

        v0.3.0

DESCRIPTION
===========

This is a very simple module based on the [list of time zone
aliases](https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations){.perl-module}
that are sometimes found in dates.

Upon using this module, it will add to the
[DateTime::TimeZone::Catalog](https://metacpan.org/pod/DateTime::TimeZone::Catalog){.perl-module}
those aliases with their corresponding time zone offset. When there is
more than one time zone offset in the list, only the first one is set.

Here is the list of those time zone aliases and their offset:

1\. `A` +0100 (Alpha Military Time Zone)

:   

2\. `ACDT` +10:30 (Australian Central Daylight Saving Time)

:   

3\. `ACST` +09:30 (Australian Central Standard Time)

:   

4\. `ACT` +08:00 (ASEAN Common Time)

:   

5\. `ACWST` +08:45 (Australian Central Western Standard Time)

:   

6\. `ADT` -03:00 (Atlantic Daylight Time)

:   

7\. `AEDT` +11:00 (Australian Eastern Daylight Saving Time)

:   

8\. `AES` +10:00 (Australian Eastern Standard Time)

:   

9\. `AEST` +10:00 (Australian Eastern Standard Time)

:   

10\. `AET` +10:00 (Australian Eastern Time)

:   

11\. `AFT` +04:30 (Afghanistan Time)

:   

12\. `AHDT` -0900 (Alaska-Hawaii Daylight Time)

:   

13\. `AHST` -1000 (Alaska-Hawaii Standard Time)

:   

14\. `AKDT` -08:00 (Alaska Daylight Time)

:   

15\. `AKST` -09:00 (Alaska Standard Time)

:   

16\. `ALMT` +06:00 (Alma-Ata Time)

:   

17\. `AMST` -03:00 (Amazon Summer Time (Brazil))

:   

18\. `AMT` +04:00 (Armenia Time)

:   

19\. `ANAST` +1300 (Anadyr Summer Time)

:   

20\. `ANAT` +12:00 (Anadyr Time)

:   

21\. `AQTT` +05:00 (Aqtobe Time)

:   

22\. `ART` -03:00 (Argentina Time)

:   

23\. `AST` -04:00 (Atlantic Standard Time)

:   

24\. `AT` -0100 (Azores Time)

:   

25\. `AWST` +08:00 (Australian Western Standard Time)

:   

26\. `AZOST` UTC (Azores Summer Time)

:   

27\. `AZOT` -01:00 (Azores Standard Time)

:   

28\. `AZST` +0500 (Azerbaijan Summer Time)

:   

29\. `AZT` +04:00 (Azerbaijan Time)

:   

30\. `B` +0200 (Bravo Military Time Zone)

:   

31\. `BADT` +0400 (Baghdad Daylight Time)

:   

32\. `BAT` +0600 (Baghdad Time)

:   

33\. `BDST` +0200 (British Double Summer Time)

:   

34\. `BDT` +0600 (Bangladesh Time)

:   

35\. `BET` -1100 (Bering Standard Time)

:   

36\. `BIOT` +06:00 (British Indian Ocean Time)

:   

37\. `BIT` -12:00 (Baker Island Time)

:   

38\. `BNT` +08:00 (Brunei Time)

:   

39\. `BORT` +0800 (Borneo Time (Indonesia))

:   

40\. `BOT` -04:00 (Bolivia Time)

:   

41\. `BRA` -0300 (Brazil Time)

:   

42\. `BRST` -02:00 (Brasília Summer Time)

:   

43\. `BRT` -03:00 (Brasília Time)

:   

44\. `BST` +01:00 (British Summer Time (British Standard Time from Feb 1968 to Oct 1971))

:   

45\. `BTT` +06:00 (Bhutan Time)

:   

46\. `C` +0300 (Charlie Military Time Zone)

:   

47\. `CAST` +0930 (Casey Time Zone)

:   

48\. `CAT` +02:00 (Central Africa Time)

:   

49\. `CCT` +06:30 (Cocos Islands Time)

:   

50\. `CDT` -04:00 (Cuba Daylight Time)

:   

51\. `CEST` +02:00 (Central European Summer Time)

:   

52\. `CET` +01:00 (Central European Time)

:   

53\. `CETDST` +0200 (Central Europe Summer Time)

:   

54\. `CHADT` +13:45 (Chatham Daylight Time)

:   

55\. `CHAST` +12:45 (Chatham Standard Time)

:   

56\. `CHOST` +09:00 (Choibalsan Summer Time)

:   

57\. `CHOT` +08:00 (Choibalsan Standard Time)

:   

58\. `CHST` +10:00 (Chamorro Standard Time)

:   

59\. `CHUT` +10:00 (Chuuk Time)

:   

60\. `CIST` -08:00 (Clipperton Island Standard Time)

:   

61\. `CKT` -10:00 (Cook Island Time)

:   

62\. `CLST` -03:00 (Chile Summer Time)

:   

63\. `CLT` -04:00 (Chile Standard Time)

:   

64\. `COST` -04:00 (Colombia Summer Time)

:   

65\. `COT` -05:00 (Colombia Time)

:   

66\. `CST` -05:00 (Cuba Standard Time)

:   

67\. `CSuT` +1030 (Australian Central Daylight)

:   

68\. `CT` -06:00 (Central Time)

:   

69\. `CUT` +0000 (Coordinated Universal Time)

:   

70\. `CVT` -01:00 (Cape Verde Time)

:   

71\. `CWST` +08:45 (Central Western Standard Time (Australia))

:   

72\. `CXT` +07:00 (Christmas Island Time)

:   

73\. `ChST` +1000 (Chamorro Standard Time)

:   

74\. `D` +0400 (Delta Military Time Zone)

:   

75\. `DAVT` +07:00 (Davis Time)

:   

76\. `DDUT` +10:00 (Dumont d\'Urville Time)

:   

77\. `DFT` +01:00 (AIX-specific equivalent of Central European Time)

:   

78\. `DNT` +0100 (Dansk Normal)

:   

79\. `DST` +0200 (Dansk Summer)

:   

80\. `E` +0500 (Echo Military Time Zone)

:   

81\. `EASST` -05:00 (Easter Island Summer Time)

:   

82\. `EAST` -06:00 (Easter Island Standard Time)

:   

83\. `EAT` +03:00 (East Africa Time)

:   

84\. `ECT` -05:00 (Ecuador Time)

:   

85\. `EDT` -04:00 (Eastern Daylight Time (North America))

:   

86\. `EEST` +03:00 (Eastern European Summer Time)

:   

87\. `EET` +02:00 (Eastern European Time)

:   

88\. `EETDST` +0300 (European Eastern Summer)

:   

89\. `EGST` UTC (Eastern Greenland Summer Time)

:   

90\. `EGT` -01:00 (Eastern Greenland Time)

:   

91\. `EMT` +0100 (Norway Time)

:   

92\. `EST` -05:00 (Eastern Standard Time (North America))

:   

93\. `ESuT` +1100 (Australian Eastern Daylight)

:   

94\. `ET` -04:00 (Eastern Time (North America))

:   

95\. `F` +0600 (Foxtrot Military Time Zone)

:   

96\. `FET` +03:00 (Further-eastern European Time)

:   

97\. `FJST` +1300 (Fiji Summer Time)

:   

98\. `FJT` +12:00 (Fiji Time)

:   

99\. `FKST` -03:00 (Falkland Islands Summer Time)

:   

100\. `FKT` -04:00 (Falkland Islands Time)

:   

101\. `FNT` -02:00 (Fernando de Noronha Time)

:   

102\. `FWT` +0100 (French Winter Time)

:   

103\. `G` +0700 (Golf Military Time Zone)

:   

104\. `GALT` -06:00 (Galapagos Time)

:   

105\. `GAMT` -09:00 (Gambier Islands Time)

:   

106\. `GEST` +0500 (Georgia Summer Time)

:   

107\. `GET` +04:00 (Georgia Standard Time)

:   

108\. `GFT` -03:00 (French Guiana Time)

:   

109\. `GILT` +12:00 (Gilbert Island Time)

:   

110\. `GIT` -09:00 (Gambier Island Time)

:   

111\. `GMT` UTC (Greenwich Mean Time)

:   

112\. `GST` +04:00 (Gulf Standard Time)

:   

113\. `GT` +0000 (Greenwich Time)

:   

114\. `GYT` -04:00 (Guyana Time)

:   

115\. `GZ` +0000 (Greenwichzeit)

:   

116\. `H` +0800 (Hotel Military Time Zone)

:   

117\. `HAA` -0300 (Heure Avancée de l\'Atlantique)

:   

118\. `HAC` -0500 (Heure Avancee du Centre)

:   

119\. `HAE` -0400 (Heure Avancee de l\'Est)

:   

120\. `HAEC` +02:00 (Heure Avancée d\'Europe Centrale)

:   

121\. `HAP` -0700 (Heure Avancee du Pacifique)

:   

122\. `HAR` -0600 (Heure Avancee des Rocheuses)

:   

123\. `HAT` -0230 (Heure Avancee de Terre-Neuve)

:   

124\. `HAY` -0800 (Heure Avancee du Yukon)

:   

125\. `HDT` -09:00 (Hawaii--Aleutian Daylight Time)

:   

126\. `HFE` +0200 (Heure Fancais d\'Ete)

:   

127\. `HFH` +0100 (Heure Fancais d\'Hiver)

:   

128\. `HG` +0000 (Heure de Greenwich)

:   

129\. `HKT` +08:00 (Hong Kong Time)

:   

130\. `HL` local (Heure locale)

:   

131\. `HMT` +05:00 (Heard and McDonald Islands Time)

:   

132\. `HNA` -0400 (Heure Normale de l\'Atlantique)

:   

133\. `HNC` -0600 (Heure Normale du Centre)

:   

134\. `HNE` -0500 (Heure Normale de l\'Est)

:   

135\. `HNP` -0800 (Heure Normale du Pacifique)

:   

136\. `HNR` -0700 (Heure Normale des Rocheuses)

:   

137\. `HNT` -0330 (Heure Normale de Terre-Neuve)

:   

138\. `HNY` -0900 (Heure Normale du Yukon)

:   

139\. `HOE` +0100 (Spain Time)

:   

140\. `HOVST` +08:00 (Hovd Summer Time (not used from 2017-present))

:   

141\. `HOVT` +07:00 (Hovd Time)

:   

142\. `HST` -10:00 (Hawaii--Aleutian Standard Time)

:   

143\. `I` +0900 (India Military Time Zone)

:   

144\. `ICT` +07:00 (Indochina Time)

:   

145\. `IDLE` +1200 (Internation Date Line East)

:   

146\. `IDLW` -12:00 (International Day Line West time zone)

:   

147\. `IDT` +03:00 (Israel Daylight Time)

:   

148\. `IOT` +03:00 (Indian Ocean Time)

:   

149\. `IRDT` +04:30 (Iran Daylight Time)

:   

150\. `IRKST` +0900 (Irkutsk Summer Time)

:   

151\. `IRKT` +08:00 (Irkutsk Time)

:   

152\. `IRST` +03:30 (Iran Standard Time)

:   

153\. `IRT` +0330 (Iran Time)

:   

154\. `IST` +02:00 (Israel Standard Time)

:   

155\. `IT` +0330 (Iran Time)

:   

156\. `ITA` +0100 (Italy Time)

:   

157\. `JAVT` +0700 (Java Time)

:   

158\. `JAYT` +0900 (Jayapura Time (Indonesia))

:   

159\. `JST` +09:00 (Japan Standard Time)

:   

160\. `JT` +0700 (Java Time)

:   

161\. `K` +1000 (Kilo Military Time Zone)

:   

162\. `KALT` +02:00 (Kaliningrad Time)

:   

163\. `KDT` +1000 (Korean Daylight Time)

:   

164\. `KGST` +0600 (Kyrgyzstan Summer Time)

:   

165\. `KGT` +06:00 (Kyrgyzstan Time)

:   

166\. `KOST` +11:00 (Kosrae Time)

:   

167\. `KRAST` +0800 (Krasnoyarsk Summer Time)

:   

168\. `KRAT` +07:00 (Krasnoyarsk Time)

:   

169\. `KST` +09:00 (Korea Standard Time)

:   

170\. `L` +1100 (Lima Military Time Zone)

:   

171\. `LHDT` +1100 (Lord Howe Daylight Time)

:   

172\. `LHST` +11:00 (Lord Howe Summer Time)

:   

173\. `LIGT` +1000 (Melbourne, Australia)

:   

174\. `LINT` +14:00 (Line Islands Time)

:   

175\. `LKT` +0600 (Lanka Time)

:   

176\. `LST` local (Local Sidereal Time)

:   

177\. `LT` local (Local Time)

:   

178\. `M` +1200 (Mike Military Time Zone)

:   

179\. `MAGST` +1200 (Magadan Summer Time)

:   

180\. `MAGT` +12:00 (Magadan Time)

:   

181\. `MAL` +0800 (Malaysia Time)

:   

182\. `MART` -09:30 (Marquesas Islands Time)

:   

183\. `MAT` +0300 (Turkish Standard Time)

:   

184\. `MAWT` +05:00 (Mawson Station Time)

:   

185\. `MDT` -06:00 (Mountain Daylight Time (North America))

:   

186\. `MED` +0200 (Middle European Daylight)

:   

187\. `MEDST` +0200 (Middle European Summer)

:   

188\. `MEST` +02:00 (Middle European Summer Time)

:   

189\. `MESZ` +0200 (Mitteieuropaische Sommerzeit)

:   

190\. `MET` +01:00 (Middle European Time)

:   

191\. `MEWT` +0100 (Middle European Winter Time)

:   

192\. `MEX` -0600 (Mexico Time)

:   

193\. `MEZ` +0100 (Mitteieuropaische Zeit)

:   

194\. `MHT` +12:00 (Marshall Islands Time)

:   

195\. `MIST` +11:00 (Macquarie Island Station Time)

:   

196\. `MIT` -09:30 (Marquesas Islands Time)

:   

197\. `MMT` +06:30 (Myanmar Standard Time)

:   

198\. `MPT` +1000 (North Mariana Islands Time)

:   

199\. `MSD` +0400 (Moscow Summer Time)

:   

200\. `MSK` +03:00 (Moscow Time)

:   

201\. `MSKS` +0400 (Moscow Summer Time)

:   

202\. `MST` -07:00 (Mountain Standard Time)

:   

203\. `MT` +0830 (Moluccas)

:   

204\. `MUT` +04:00 (Mauritius Time)

:   

205\. `MVT` +05:00 (Maldives Time)

:   

206\. `MYT` +08:00 (Malaysia Time)

:   

207\. `N` -0100 (November Military Time Zone)

:   

208\. `NCT` +11:00 (New Caledonia Time)

:   

209\. `NDT` -02:30 (Newfoundland Daylight Time)

:   

210\. `NFT` +11:00 (Norfolk Island Time)

:   

211\. `NOR` +0100 (Norway Time)

:   

212\. `NOVST` +0700 (Novosibirsk Summer Time (Russia))

:   

213\. `NOVT` +07:00 (Novosibirsk Time)

:   

214\. `NPT` +05:45 (Nepal Time)

:   

215\. `NRT` +1200 (Nauru Time)

:   

216\. `NST` -03:30 (Newfoundland Standard Time)

:   

217\. `NSUT` +0630 (North Sumatra Time)

:   

218\. `NT` -03:30 (Newfoundland Time)

:   

219\. `NUT` -11:00 (Niue Time)

:   

220\. `NZDT` +13:00 (New Zealand Daylight Time)

:   

221\. `NZST` +12:00 (New Zealand Standard Time)

:   

222\. `NZT` +1200 (New Zealand Standard Time)

:   

223\. `O` -0200 (Oscar Military Time Zone)

:   

224\. `OESZ` +0300 (Osteuropaeische Sommerzeit)

:   

225\. `OEZ` +0200 (Osteuropaische Zeit)

:   

226\. `OMSST` +0700 (Omsk Summer Time)

:   

227\. `OMST` +06:00 (Omsk Time)

:   

228\. `ORAT` +05:00 (Oral Time)

:   

229\. `OZ` local (Ortszeit)

:   

230\. `P` -0300 (Papa Military Time Zone)

:   

231\. `PDT` -07:00 (Pacific Daylight Time (North America))

:   

232\. `PET` -05:00 (Peru Time)

:   

233\. `PETST` +1300 (Kamchatka Summer Time)

:   

234\. `PETT` +12:00 (Kamchatka Time)

:   

235\. `PGT` +10:00 (Papua New Guinea Time)

:   

236\. `PHOT` +13:00 (Phoenix Island Time)

:   

237\. `PHST` +08:00 (Philippine Standard Time)

:   

238\. `PHT` +08:00 (Philippine Time)

:   

239\. `PKT` +05:00 (Pakistan Standard Time)

:   

240\. `PMDT` -02:00 (Saint Pierre and Miquelon Daylight Time)

:   

241\. `PMST` -03:00 (Saint Pierre and Miquelon Standard Time)

:   

242\. `PMT` -0300 (Pierre & Miquelon Standard Time)

:   

243\. `PNT` -0830 (Pitcairn Time)

:   

244\. `PONT` +11:00 (Pohnpei Standard Time)

:   

245\. `PST` -08:00 (Pacific Standard Time (North America))

:   

246\. `PWT` +09:00 (Palau Time)

:   

247\. `PYST` -03:00 (Paraguay Summer Time)

:   

248\. `PYT` -04:00 (Paraguay Time)

:   

249\. `Q` -0400 (Quebec Military Time Zone)

:   

250\. `R` -0500 (Romeo Military Time Zone)

:   

251\. `R1T` +0200 (Russia Zone 1)

:   

252\. `R2T` +0300 (Russia Zone 2)

:   

253\. `RET` +04:00 (Réunion Time)

:   

254\. `ROK` +0900 (Korean Standard Time)

:   

255\. `ROTT` -03:00 (Rothera Research Station Time)

:   

256\. `S` -0600 (Sierra Military Time Zone)

:   

257\. `SADT` +1030 (Australian South Daylight Time)

:   

258\. `SAKT` +11:00 (Sakhalin Island Time)

:   

259\. `SAMT` +04:00 (Samara Time)

:   

260\. `SAST` +02:00 (South African Standard Time)

:   

261\. `SBT` +11:00 (Solomon Islands Time)

:   

262\. `SCT` +04:00 (Seychelles Time)

:   

263\. `SDT` -10:00 (Samoa Daylight Time)

:   

264\. `SET` +0100 (Prague, Vienna Time)

:   

265\. `SGT` +08:00 (Singapore Time)

:   

266\. `SLST` +05:30 (Sri Lanka Standard Time)

:   

267\. `SRET` +11:00 (Srednekolymsk Time)

:   

268\. `SRT` -03:00 (Suriname Time)

:   

269\. `SST` +08:00 (Singapore Standard Time)

:   

270\. `SWT` +0100 (Swedish Winter)

:   

271\. `SYOT` +03:00 (Showa Station Time)

:   

272\. `T` -0700 (Tango Military Time Zone)

:   

273\. `TAHT` -10:00 (Tahiti Time)

:   

274\. `TFT` +05:00 (French Southern and Antarctic Time)

:   

275\. `THA` +07:00 (Thailand Standard Time)

:   

276\. `THAT` -1000 (Tahiti Time)

:   

277\. `TJT` +05:00 (Tajikistan Time)

:   

278\. `TKT` +13:00 (Tokelau Time)

:   

279\. `TLT` +09:00 (Timor Leste Time)

:   

280\. `TMT` +05:00 (Turkmenistan Time)

:   

281\. `TOT` +13:00 (Tonga Time)

:   

282\. `TRT` +03:00 (Turkey Time)

:   

283\. `TRUT` +1000 (Truk Time)

:   

284\. `TST` +0300 (Turkish Standard Time)

:   

285\. `TUC ` +0000 (Temps Universel Coordonné)

:   

286\. `TVT` +12:00 (Tuvalu Time)

:   

287\. `U` -0800 (Uniform Military Time Zone)

:   

288\. `ULAST` +09:00 (Ulaanbaatar Summer Time)

:   

289\. `ULAT` +08:00 (Ulaanbaatar Standard Time)

:   

290\. `USZ1` +0200 (Russia Zone 1)

:   

291\. `USZ1S` +0300 (Kaliningrad Summer Time (Russia))

:   

292\. `USZ3` +0400 (Volga Time (Russia))

:   

293\. `USZ3S` +0500 (Volga Summer Time (Russia))

:   

294\. `USZ4` +0500 (Ural Time (Russia))

:   

295\. `USZ4S` +0600 (Ural Summer Time (Russia))

:   

296\. `USZ5` +0600 (West-Siberian Time (Russia))

:   

297\. `USZ5S` +0700 (West-Siberian Summer Time)

:   

298\. `USZ6` +0700 (Yenisei Time (Russia))

:   

299\. `USZ6S` +0800 (Yenisei Summer Time (Russia))

:   

300\. `USZ7` +0800 (Irkutsk Time (Russia))

:   

301\. `USZ7S` +0900 (Irkutsk Summer Time)

:   

302\. `USZ8` +0900 (Amur Time (Russia))

:   

303\. `USZ8S` +1000 (Amur Summer Time (Russia))

:   

304\. `USZ9` +1000 (Vladivostok Time (Russia))

:   

305\. `USZ9S` +1100 (Vladivostok Summer Time (Russia))

:   

306\. `UTC` UTC (Coordinated Universal Time)

:   

307\. `UTZ` -0300 (Greenland Western Standard Time)

:   

308\. `UYST` -02:00 (Uruguay Summer Time)

:   

309\. `UYT` -03:00 (Uruguay Standard Time)

:   

310\. `UZ10` +1100 (Okhotsk Time (Russia))

:   

311\. `UZ10S` +1200 (Okhotsk Summer Time (Russia))

:   

312\. `UZ11` +1200 (Kamchatka Time (Russia))

:   

313\. `UZ11S` +1300 (Kamchatka Summer Time (Russia))

:   

314\. `UZ12` +1200 (Chukot Time (Russia))

:   

315\. `UZ12S` +1300 (Chukot Summer Time (Russia))

:   

316\. `UZT` +05:00 (Uzbekistan Time)

:   

317\. `V` -0900 (Victor Military Time Zone)

:   

318\. `VET` -04:00 (Venezuelan Standard Time)

:   

319\. `VLAST` +1100 (Vladivostok Summer Time)

:   

320\. `VLAT` +10:00 (Vladivostok Time)

:   

321\. `VOLT` +03:00 (Volgograd Time)

:   

322\. `VOST` +06:00 (Vostok Station Time)

:   

323\. `VTZ` -0200 (Greenland Eastern Standard Time)

:   

324\. `VUT` +11:00 (Vanuatu Time)

:   

325\. `W` -1000 (Whiskey Military Time Zone)

:   

326\. `WAKT` +12:00 (Wake Island Time)

:   

327\. `WAST` +02:00 (West Africa Summer Time)

:   

328\. `WAT` +01:00 (West Africa Time)

:   

329\. `WEST` +01:00 (Western European Summer Time)

:   

330\. `WESZ` +0100 (Westeuropaische Sommerzeit)

:   

331\. `WET` UTC (Western European Time)

:   

332\. `WETDST` +0100 (European Western Summer)

:   

333\. `WEZ` +0000 (Western Europe Time)

:   

334\. `WFT` +1200 (Wallis and Futuna Time)

:   

335\. `WGST` -02:00 (West Greenland Summer Time)

:   

336\. `WGT` -03:00 (West Greenland Time)

:   

337\. `WIB` +07:00 (Western Indonesian Time)

:   

338\. `WIT` +09:00 (Eastern Indonesian Time)

:   

339\. `WITA` +08:00 (Central Indonesia Time)

:   

340\. `WST` +08:00 (Western Standard Time)

:   

341\. `WTZ` -0100 (Greenland Eastern Daylight Time)

:   

342\. `WUT` +0100 (Austria Time)

:   

343\. `X` -1100 (X-ray Military Time Zone)

:   

344\. `Y` -1200 (Yankee Military Time Zone)

:   

345\. `YAKST` +1000 (Yakutsk Summer Time)

:   

346\. `YAKT` +09:00 (Yakutsk Time)

:   

347\. `YAPT` +1000 (Yap Time (Micronesia))

:   

348\. `YDT` -0800 (Yukon Daylight Time)

:   

349\. `YEKST` +0600 (Yekaterinburg Summer Time)

:   

350\. `YEKT` +05:00 (Yekaterinburg Time)

:   

351\. `YST` -0900 (Yukon Standard Time)

:   

352\. `Z` +0000 (Zulu)

:   

METHODS
=======

aliases
-------

Returns an array reference of the time zone aliases.

        my $aliases = DateTime::TimeZone::Catalog::Extend->aliases;

You can also achieve the same result by accessing directly the package
variable `$ALIAS_CATALOG`

        my $aliases = [sort( keys( %$DateTime::TimeZone::Catalog::Extend::ALIAS_CATALOG ) )];

zone\_map
---------

Returns an hash reference of time zone alias to their offset. This class
function caches the hash reference so the second time it returns the
cached value.

The returned hash reference is suitable to be passed to [\"new\" in
DateTime::Format::Strptime](https://metacpan.org/pod/DateTime::Format::Strptime#new){.perl-module}
with the argument `zone_map`

        my $str = 'Fri Mar 25 2011 12:16:25 ADT';
        my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
        my $fmt = DateTime::Format::Strptime->new(
            pattern => $pattern,
            zone_map => $map,
        );
        my $dt = $fmt->parse_datetime( $str );
        die( $fmt->errmsg ) if( !defined( $dt ) );

Without passing the `zone_map`,
[DateTime::Format::Strptime](https://metacpan.org/pod/DateTime::Format::Strptime){.perl-module}
would have returned the error c\<The time zone abbreviation that was
parsed is ambiguous\>

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x559ebf70ac70)"}\>

SEE ALSO
========

[DateTime::TimeZone::Catalog](https://metacpan.org/pod/DateTime::TimeZone::Catalog){.perl-module},
[DateTime::TimeZone::Alias](https://metacpan.org/pod/DateTime::TimeZone::Alias){.perl-module},
[DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
