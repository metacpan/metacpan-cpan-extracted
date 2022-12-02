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

VERSION
=======

        v0.2.0

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

1\. `ACDT` +10:30 (Australian Central Daylight Saving Time)

:   

2\. `ACST` +09:30 (Australian Central Standard Time)

:   

3\. `ACT` +08:00 (ASEAN Common Time (proposed))

:   

4\. `ACWST` +08:45 (Australian Central Western Standard Time (unofficial))

:   

5\. `ADT` -03:00 (Atlantic Daylight Time)

:   

6\. `AEDT` +11:00 (Australian Eastern Daylight Saving Time)

:   

7\. `AEST` +10:00 (Australian Eastern Standard Time)

:   

8\. `AET` +10:00 (Australian Eastern Time)

:   

9\. `AFT` +04:30 (Afghanistan Time)

:   

10\. `AKDT` -08:00 (Alaska Daylight Time)

:   

11\. `AKST` -09:00 (Alaska Standard Time)

:   

12\. `ALMT` +06:00 (Alma-Ata Time\[1\])

:   

13\. `AMST` -03:00 (Amazon Summer Time (Brazil)\[2\])

:   

14\. `AMT` +04:00 (Armenia Time)

:   

15\. `ANAT` +12:00 (Anadyr Time\[4\])

:   

16\. `AQTT` +05:00 (Aqtobe Time\[5\])

:   

17\. `ART` -03:00 (Argentina Time)

:   

18\. `AST` -04:00 (Atlantic Standard Time)

:   

19\. `AWST` +08:00 (Australian Western Standard Time)

:   

20\. `AZOST` UTC (Azores Summer Time)

:   

21\. `AZOT` -01:00 (Azores Standard Time)

:   

22\. `AZT` +04:00 (Azerbaijan Time)

:   

23\. `BIOT` +06:00 (British Indian Ocean Time)

:   

24\. `BIT` -12:00 (Baker Island Time)

:   

25\. `BNT` +08:00 (Brunei Time)

:   

26\. `BOT` -04:00 (Bolivia Time)

:   

27\. `BRST` -02:00 (Brasília Summer Time)

:   

28\. `BRT` -03:00 (Brasília Time)

:   

29\. `BST` +01:00 (British Summer Time (British Standard Time from Feb 1968 to Oct 1971))

:   

30\. `BTT` +06:00 (Bhutan Time)

:   

31\. `CAT` +02:00 (Central Africa Time)

:   

32\. `CCT` +06:30 (Cocos Islands Time)

:   

33\. `CDT` -04:00 (Cuba Daylight Time\[7\])

:   

34\. `CEST` +02:00 (Central European Summer Time)

:   

35\. `CET` +01:00 (Central European Time)

:   

36\. `CHADT` +13:45 (Chatham Daylight Time)

:   

37\. `CHAST` +12:45 (Chatham Standard Time)

:   

38\. `CHOST` +09:00 (Choibalsan Summer Time)

:   

39\. `CHOT` +08:00 (Choibalsan Standard Time)

:   

40\. `CHST` +10:00 (Chamorro Standard Time)

:   

41\. `CHUT` +10:00 (Chuuk Time)

:   

42\. `CIST` -08:00 (Clipperton Island Standard Time)

:   

43\. `CKT` -10:00 (Cook Island Time)

:   

44\. `CLST` -03:00 (Chile Summer Time)

:   

45\. `CLT` -04:00 (Chile Standard Time)

:   

46\. `COST` -04:00 (Colombia Summer Time)

:   

47\. `COT` -05:00 (Colombia Time)

:   

48\. `CST` -05:00 (Cuba Standard Time)

:   

49\. `CT` -06:00 (Central Time)

:   

50\. `CVT` -01:00 (Cape Verde Time)

:   

51\. `CWST` +08:45 (Central Western Standard Time (Australia) unofficial)

:   

52\. `CXT` +07:00 (Christmas Island Time)

:   

53\. `DAVT` +07:00 (Davis Time)

:   

54\. `DDUT` +10:00 (Dumont d\'Urville Time)

:   

55\. `DFT` +01:00 (AIX-specific equivalent of Central European Time\[NB 1\])

:   

56\. `EASST` -05:00 (Easter Island Summer Time)

:   

57\. `EAST` -06:00 (Easter Island Standard Time)

:   

58\. `EAT` +03:00 (East Africa Time)

:   

59\. `ECT` -05:00 (Ecuador Time)

:   

60\. `EDT` -04:00 (Eastern Daylight Time (North America))

:   

61\. `EEST` +03:00 (Eastern European Summer Time)

:   

62\. `EET` +02:00 (Eastern European Time)

:   

63\. `EGST` UTC (Eastern Greenland Summer Time)

:   

64\. `EGT` -01:00 (Eastern Greenland Time)

:   

65\. `EST` -05:00 (Eastern Standard Time (North America))

:   

66\. `ET` -04:00 (Eastern Time (North America) UTC-05 /)

:   

67\. `FET` +03:00 (Further-eastern European Time)

:   

68\. `FJT` +12:00 (Fiji Time)

:   

69\. `FKST` -03:00 (Falkland Islands Summer Time)

:   

70\. `FKT` -04:00 (Falkland Islands Time)

:   

71\. `FNT` -02:00 (Fernando de Noronha Time)

:   

72\. `GALT` -06:00 (Galápagos Time)

:   

73\. `GAMT` -09:00 (Gambier Islands Time)

:   

74\. `GET` +04:00 (Georgia Standard Time)

:   

75\. `GFT` -03:00 (French Guiana Time)

:   

76\. `GILT` +12:00 (Gilbert Island Time)

:   

77\. `GIT` -09:00 (Gambier Island Time)

:   

78\. `GMT` UTC (Greenwich Mean Time)

:   

79\. `GST` +04:00 (Gulf Standard Time)

:   

80\. `GYT` -04:00 (Guyana Time)

:   

81\. `HAEC` +02:00 (Heure Avancée d\'Europe Centrale French-language name for CEST)

:   

82\. `HDT` -09:00 (Hawaii--Aleutian Daylight Time)

:   

83\. `HKT` +08:00 (Hong Kong Time)

:   

84\. `HMT` +05:00 (Heard and McDonald Islands Time)

:   

85\. `HOVST` +08:00 (Hovd Summer Time (not used from 2017-present))

:   

86\. `HOVT` +07:00 (Hovd Time)

:   

87\. `HST` -10:00 (Hawaii--Aleutian Standard Time)

:   

88\. `ICT` +07:00 (Indochina Time)

:   

89\. `IDLW` -12:00 (International Day Line West time zone)

:   

90\. `IDT` +03:00 (Israel Daylight Time)

:   

91\. `IOT` +03:00 (Indian Ocean Time)

:   

92\. `IRDT` +04:30 (Iran Daylight Time)

:   

93\. `IRKT` +08:00 (Irkutsk Time)

:   

94\. `IRST` +03:30 (Iran Standard Time)

:   

95\. `IST` +02:00 (Israel Standard Time)

:   

96\. `JST` +09:00 (Japan Standard Time)

:   

97\. `KALT` +02:00 (Kaliningrad Time)

:   

98\. `KGT` +06:00 (Kyrgyzstan Time)

:   

99\. `KOST` +11:00 (Kosrae Time)

:   

100\. `KRAT` +07:00 (Krasnoyarsk Time)

:   

101\. `KST` +09:00 (Korea Standard Time)

:   

102\. `LHST` +11:00 (Lord Howe Summer Time)

:   

103\. `LINT` +14:00 (Line Islands Time)

:   

104\. `MAGT` +12:00 (Magadan Time)

:   

105\. `MART` -09:30 (Marquesas Islands Time)

:   

106\. `MAWT` +05:00 (Mawson Station Time)

:   

107\. `MDT` -06:00 (Mountain Daylight Time (North America))

:   

108\. `MEST` +02:00 (Middle European Summer Time (same zone as CEST))

:   

109\. `MET` +01:00 (Middle European Time (same zone as CET))

:   

110\. `MHT` +12:00 (Marshall Islands Time)

:   

111\. `MIST` +11:00 (Macquarie Island Station Time)

:   

112\. `MIT` -09:30 (Marquesas Islands Time)

:   

113\. `MMT` +06:30 (Myanmar Standard Time)

:   

114\. `MSK` +03:00 (Moscow Time)

:   

115\. `MST` -07:00 (Mountain Standard Time (North America))

:   

116\. `MUT` +04:00 (Mauritius Time)

:   

117\. `MVT` +05:00 (Maldives Time)

:   

118\. `MYT` +08:00 (Malaysia Time)

:   

119\. `NCT` +11:00 (New Caledonia Time)

:   

120\. `NDT` -02:30 (Newfoundland Daylight Time)

:   

121\. `NFT` +11:00 (Norfolk Island Time)

:   

122\. `NOVT` +07:00 (Novosibirsk Time \[9\])

:   

123\. `NPT` +05:45 (Nepal Time)

:   

124\. `NST` -03:30 (Newfoundland Standard Time)

:   

125\. `NT` -03:30 (Newfoundland Time)

:   

126\. `NUT` -11:00 (Niue Time)

:   

127\. `NZDT` +13:00 (New Zealand Daylight Time)

:   

128\. `NZST` +12:00 (New Zealand Standard Time)

:   

129\. `OMST` +06:00 (Omsk Time)

:   

130\. `ORAT` +05:00 (Oral Time)

:   

131\. `PDT` -07:00 (Pacific Daylight Time (North America))

:   

132\. `PET` -05:00 (Peru Time)

:   

133\. `PETT` +12:00 (Kamchatka Time)

:   

134\. `PGT` +10:00 (Papua New Guinea Time)

:   

135\. `PHOT` +13:00 (Phoenix Island Time)

:   

136\. `PHST` +08:00 (Philippine Standard Time)

:   

137\. `PHT` +08:00 (Philippine Time)

:   

138\. `PKT` +05:00 (Pakistan Standard Time)

:   

139\. `PMDT` -02:00 (Saint Pierre and Miquelon Daylight Time)

:   

140\. `PMST` -03:00 (Saint Pierre and Miquelon Standard Time)

:   

141\. `PONT` +11:00 (Pohnpei Standard Time)

:   

142\. `PST` -08:00 (Pacific Standard Time (North America))

:   

143\. `PWT` +09:00 (Palau Time\[10\])

:   

144\. `PYST` -03:00 (Paraguay Summer Time\[11\])

:   

145\. `PYT` -04:00 (Paraguay Time\[12\])

:   

146\. `RET` +04:00 (Réunion Time)

:   

147\. `ROTT` -03:00 (Rothera Research Station Time)

:   

148\. `SAKT` +11:00 (Sakhalin Island Time)

:   

149\. `SAMT` +04:00 (Samara Time)

:   

150\. `SAST` +02:00 (South African Standard Time)

:   

151\. `SBT` +11:00 (Solomon Islands Time)

:   

152\. `SCT` +04:00 (Seychelles Time)

:   

153\. `SDT` -10:00 (Samoa Daylight Time)

:   

154\. `SGT` +08:00 (Singapore Time)

:   

155\. `SLST` +05:30 (Sri Lanka Standard Time)

:   

156\. `SRET` +11:00 (Srednekolymsk Time)

:   

157\. `SRT` -03:00 (Suriname Time)

:   

158\. `SST` +08:00 (Singapore Standard Time)

:   

159\. `SYOT` +03:00 (Showa Station Time)

:   

160\. `TAHT` -10:00 (Tahiti Time)

:   

161\. `TFT` +05:00 (French Southern and Antarctic Time\[13\])

:   

162\. `THA` +07:00 (Thailand Standard Time)

:   

163\. `TJT` +05:00 (Tajikistan Time)

:   

164\. `TKT` +13:00 (Tokelau Time)

:   

165\. `TLT` +09:00 (Timor Leste Time)

:   

166\. `TMT` +05:00 (Turkmenistan Time)

:   

167\. `TOT` +13:00 (Tonga Time)

:   

168\. `TRT` +03:00 (Turkey Time)

:   

169\. `TVT` +12:00 (Tuvalu Time)

:   

170\. `ULAST` +09:00 (Ulaanbaatar Summer Time)

:   

171\. `ULAT` +08:00 (Ulaanbaatar Standard Time)

:   

172\. `UTC` UTC (Coordinated Universal Time)

:   

173\. `UYST` -02:00 (Uruguay Summer Time)

:   

174\. `UYT` -03:00 (Uruguay Standard Time)

:   

175\. `UZT` +05:00 (Uzbekistan Time)

:   

176\. `VET` -04:00 (Venezuelan Standard Time)

:   

177\. `VLAT` +10:00 (Vladivostok Time)

:   

178\. `VOLT` +03:00 (Volgograd Time)

:   

179\. `VOST` +06:00 (Vostok Station Time)

:   

180\. `VUT` +11:00 (Vanuatu Time)

:   

181\. `WAKT` +12:00 (Wake Island Time)

:   

182\. `WAST` +02:00 (West Africa Summer Time)

:   

183\. `WAT` +01:00 (West Africa Time)

:   

184\. `WEST` +01:00 (Western European Summer Time)

:   

185\. `WET` UTC (Western European Time)

:   

186\. `WGST` -02:00 (West Greenland Summer Time\[14\])

:   

187\. `WGT` -03:00 (West Greenland Time\[15\])

:   

188\. `WIB` +07:00 (Western Indonesian Time)

:   

189\. `WIT` +09:00 (Eastern Indonesian Time)

:   

190\. `WITA` +08:00 (Central Indonesia Time)

:   

191\. `WST` +08:00 (Western Standard Time)

:   

192\. `YAKT` +09:00 (Yakutsk Time)

:   

193\. `YEKT` +05:00 (Yekaterinburg Time)

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

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55e09004be00)"}\>

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
