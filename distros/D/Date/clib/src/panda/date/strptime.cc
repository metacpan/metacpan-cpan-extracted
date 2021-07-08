
#line 1 "src/panda/date/strptime.rl"
#include "Date.h"
#include <string.h>

#define NSAVE(dest) { dest = acc; acc = 0; }

enum class WeekInterpretation { none = 2, iso = 1, monday = 0, sunday = -7 };

namespace panda { namespace date {

struct MetaConsume {
    int cs;
    int consumed;
};

struct TZInfo {
    char rule[14];
    int  len = 0;
};



#line 121 "src/panda/date/strptime.rl"



#line 29 "src/panda/date/strptime.cc"
static const int parser_start = 185;
static const int parser_first_final = 185;
static const int parser_error = 0;

static const int parser_en_p_AMPM = 1;
static const int parser_en_p_ampm = 4;
static const int parser_en_p_sec = 7;
static const int parser_en_p_min = 9;
static const int parser_en_p_hour = 11;
static const int parser_en_p_hour_s = 13;
static const int parser_en_p_hour_min = 15;
static const int parser_en_p_hms = 20;
static const int parser_en_p_hmsAMPM = 28;
static const int parser_en_p_mdy = 40;
static const int parser_en_p_ymd = 48;
static const int parser_en_p_mdyhms = 58;
static const int parser_en_p_day = 75;
static const int parser_en_p_day3 = 77;
static const int parser_en_p_day_s = 80;
static const int parser_en_p_wday = 82;
static const int parser_en_p_wday_s = 83;
static const int parser_en_p_wname = 84;
static const int parser_en_p_wnum = 119;
static const int parser_en_p_month = 121;
static const int parser_en_p_mname = 123;
static const int parser_en_p_year = 169;
static const int parser_en_p_yr = 173;
static const int parser_en_p_cent = 175;
static const int parser_en_p_epoch = 177;
static const int parser_en_p_tz_num = 178;
static const int parser_en_p_tz_name = 183;
static const int parser_en_p_perc = 184;
static const int parser_en_p_space = 185;


#line 124 "src/panda/date/strptime.rl"

static inline int _parse_str(int cs, const char* p, const char* pe, int& week, datetime& _date, ptime_t& epoch_, TZInfo& tzi, const char*& tz_b, const char*& tz_e)  {
    // printf("_parse_str cs=%d\n", cs);
    const char* pb  = p;
    const char* eof = pe;
    uint64_t    acc = 0;

    
#line 74 "src/panda/date/strptime.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
	if ( (*p) == 32 )
		goto st185;
	goto st0;
st0:
cs = 0;
	goto _out;
case 1:
	switch( (*p) ) {
		case 65: goto st2;
		case 80: goto st3;
	}
	goto st0;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) == 77 )
		goto tr3;
	goto st0;
tr3:
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 186; goto _out;} }
	goto st186;
tr4:
#line 34 "src/panda/date/strptime.rl"
	{ _date.hour += 12;         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 186; goto _out;} }
	goto st186;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
#line 117 "src/panda/date/strptime.cc"
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( (*p) == 77 )
		goto tr4;
	goto st0;
case 4:
	switch( (*p) ) {
		case 97: goto st5;
		case 112: goto st6;
	}
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == 109 )
		goto tr7;
	goto st0;
tr7:
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 187; goto _out;} }
	goto st187;
tr8:
#line 34 "src/panda/date/strptime.rl"
	{ _date.hour += 12;         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 187; goto _out;} }
	goto st187;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
#line 153 "src/panda/date/strptime.cc"
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == 109 )
		goto tr8;
	goto st0;
case 7:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr9;
	goto st0;
tr9:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 177 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr10;
	goto st0;
tr10:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 31 "src/panda/date/strptime.rl"
	{ NSAVE(_date.sec);         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 188; goto _out;} }
	goto st188;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
#line 196 "src/panda/date/strptime.cc"
	goto st0;
case 9:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr11;
	goto st0;
tr11:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 213 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr12;
	goto st0;
tr12:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 32 "src/panda/date/strptime.rl"
	{ NSAVE(_date.min);         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 189; goto _out;} }
	goto st189;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
#line 232 "src/panda/date/strptime.cc"
	goto st0;
case 11:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr13;
	goto st0;
tr13:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 249 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr14;
	goto st0;
tr14:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 33 "src/panda/date/strptime.rl"
	{ NSAVE(_date.hour);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 190; goto _out;} }
	goto st190;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
#line 268 "src/panda/date/strptime.cc"
	goto st0;
case 13:
	if ( (*p) == 32 )
		goto st14;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr16;
	goto st0;
tr16:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 287 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr17;
	goto st0;
tr17:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 33 "src/panda/date/strptime.rl"
	{ NSAVE(_date.hour);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 191; goto _out;} }
	goto st191;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
#line 306 "src/panda/date/strptime.cc"
	goto st0;
case 15:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr18;
	goto st0;
tr18:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 323 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr19;
	goto st0;
tr19:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 33 "src/panda/date/strptime.rl"
	{ NSAVE(_date.hour);        }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 340 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st18;
	goto st0;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr21:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 362 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr22;
	goto st0;
tr22:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 32 "src/panda/date/strptime.rl"
	{ NSAVE(_date.min);         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 192; goto _out;} }
	goto st192;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
#line 381 "src/panda/date/strptime.cc"
	goto st0;
case 20:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr23;
	goto st0;
tr23:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 398 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
tr24:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 33 "src/panda/date/strptime.rl"
	{ NSAVE(_date.hour);        }
	goto st22;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
#line 415 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st23;
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr26;
	goto st0;
tr26:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 437 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr27;
	goto st0;
tr27:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 32 "src/panda/date/strptime.rl"
	{ NSAVE(_date.min);         }
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
#line 454 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st26;
	goto st0;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr29;
	goto st0;
tr29:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 476 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr30;
	goto st0;
tr30:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 31 "src/panda/date/strptime.rl"
	{ NSAVE(_date.sec);         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 193; goto _out;} }
	goto st193;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
#line 495 "src/panda/date/strptime.cc"
	goto st0;
case 28:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr31;
	goto st0;
tr31:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 512 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr32;
	goto st0;
tr32:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 33 "src/panda/date/strptime.rl"
	{ NSAVE(_date.hour);        }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 529 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st31;
	goto st0;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr34;
	goto st0;
tr34:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 551 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr35;
	goto st0;
tr35:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 32 "src/panda/date/strptime.rl"
	{ NSAVE(_date.min);         }
	goto st33;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
#line 568 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st34;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr37;
	goto st0;
tr37:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st35;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
#line 590 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr38;
	goto st0;
tr38:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 31 "src/panda/date/strptime.rl"
	{ NSAVE(_date.sec);         }
	goto st36;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
#line 607 "src/panda/date/strptime.cc"
	if ( (*p) == 32 )
		goto st37;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	switch( (*p) ) {
		case 32: goto st37;
		case 65: goto st38;
		case 80: goto st39;
	}
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( (*p) == 77 )
		goto tr42;
	goto st0;
tr42:
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 194; goto _out;} }
	goto st194;
tr43:
#line 34 "src/panda/date/strptime.rl"
	{ _date.hour += 12;         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 194; goto _out;} }
	goto st194;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
#line 642 "src/panda/date/strptime.cc"
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	if ( (*p) == 77 )
		goto tr43;
	goto st0;
case 40:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr44;
	goto st0;
tr44:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st41;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
#line 666 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr45;
	goto st0;
tr45:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 41 "src/panda/date/strptime.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 683 "src/panda/date/strptime.cc"
	if ( (*p) == 47 )
		goto st43;
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr47;
	goto st0;
tr47:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st44;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
#line 705 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr48;
	goto st0;
tr48:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 35 "src/panda/date/strptime.rl"
	{ NSAVE(_date.mday);        }
	goto st45;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
#line 722 "src/panda/date/strptime.cc"
	if ( (*p) == 47 )
		goto st46;
	goto st0;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr50;
	goto st0;
tr50:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st47;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
#line 744 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr51;
	goto st0;
tr51:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 44 "src/panda/date/strptime.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 195; goto _out;} }
	goto st195;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
#line 767 "src/panda/date/strptime.cc"
	goto st0;
case 48:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr52;
	goto st0;
tr52:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st49;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
#line 784 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr53;
	goto st0;
tr53:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st50;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
#line 799 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr54;
	goto st0;
tr54:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st51;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
#line 814 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr55;
	goto st0;
tr55:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 30 "src/panda/date/strptime.rl"
	{ NSAVE(_date.year);        }
	goto st52;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
#line 831 "src/panda/date/strptime.cc"
	if ( (*p) == 45 )
		goto st53;
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr57;
	goto st0;
tr57:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st54;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
#line 853 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr58;
	goto st0;
tr58:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 41 "src/panda/date/strptime.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st55;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
#line 870 "src/panda/date/strptime.cc"
	if ( (*p) == 45 )
		goto st56;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr60;
	goto st0;
tr60:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st57;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
#line 892 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr61;
	goto st0;
tr61:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 35 "src/panda/date/strptime.rl"
	{ NSAVE(_date.mday);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 196; goto _out;} }
	goto st196;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
#line 911 "src/panda/date/strptime.cc"
	goto st0;
case 58:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr62;
	goto st0;
tr62:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st59;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
#line 928 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr63;
	goto st0;
tr63:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 41 "src/panda/date/strptime.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st60;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
#line 945 "src/panda/date/strptime.cc"
	if ( (*p) == 47 )
		goto st61;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr65;
	goto st0;
tr65:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st62;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
#line 967 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr66;
	goto st0;
tr66:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 35 "src/panda/date/strptime.rl"
	{ NSAVE(_date.mday);        }
	goto st63;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
#line 984 "src/panda/date/strptime.cc"
	if ( (*p) == 47 )
		goto st64;
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr68;
	goto st0;
tr68:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st65;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
#line 1006 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr69;
	goto st0;
tr69:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 44 "src/panda/date/strptime.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
	goto st66;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
#line 1027 "src/panda/date/strptime.cc"
	if ( (*p) == 32 )
		goto st67;
	goto st0;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	if ( (*p) == 32 )
		goto st67;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr71;
	goto st0;
tr71:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st68;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
#line 1051 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr72;
	goto st0;
tr72:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 33 "src/panda/date/strptime.rl"
	{ NSAVE(_date.hour);        }
	goto st69;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
#line 1068 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st70;
	goto st0;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr74;
	goto st0;
tr74:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st71;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
#line 1090 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr75;
	goto st0;
tr75:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 32 "src/panda/date/strptime.rl"
	{ NSAVE(_date.min);         }
	goto st72;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
#line 1107 "src/panda/date/strptime.cc"
	if ( (*p) == 58 )
		goto st73;
	goto st0;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr77;
	goto st0;
tr77:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st74;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
#line 1129 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr78;
	goto st0;
tr78:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 31 "src/panda/date/strptime.rl"
	{ NSAVE(_date.sec);         }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 197; goto _out;} }
	goto st197;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
#line 1148 "src/panda/date/strptime.cc"
	goto st0;
case 75:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr79;
	goto st0;
tr79:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st76;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
#line 1165 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr80;
	goto st0;
tr80:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 35 "src/panda/date/strptime.rl"
	{ NSAVE(_date.mday);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 198; goto _out;} }
	goto st198;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
#line 1184 "src/panda/date/strptime.cc"
	goto st0;
case 77:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr81;
	goto st0;
tr81:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st78;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
#line 1201 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr82;
	goto st0;
tr82:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st79;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
#line 1216 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr83;
	goto st0;
tr83:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 38 "src/panda/date/strptime.rl"
	{ NSAVE(_date.mday);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 199; goto _out;} }
	goto st199;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
#line 1235 "src/panda/date/strptime.cc"
	goto st0;
case 80:
	if ( (*p) == 32 )
		goto st81;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr85;
	goto st0;
tr85:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st81;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
#line 1254 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr86;
	goto st0;
tr86:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 35 "src/panda/date/strptime.rl"
	{ NSAVE(_date.mday);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 200; goto _out;} }
	goto st200;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
#line 1273 "src/panda/date/strptime.cc"
	goto st0;
case 82:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr87;
	goto st0;
tr87:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 36 "src/panda/date/strptime.rl"
	{ NSAVE(_date.wday);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 201; goto _out;} }
	goto st201;
st201:
	if ( ++p == pe )
		goto _test_eof201;
case 201:
#line 1294 "src/panda/date/strptime.cc"
	goto st0;
case 83:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr88;
	goto st0;
tr88:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 37 "src/panda/date/strptime.rl"
	{ --acc; NSAVE(_date.wday); }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 202; goto _out;} }
	goto st202;
st202:
	if ( ++p == pe )
		goto _test_eof202;
case 202:
#line 1315 "src/panda/date/strptime.cc"
	goto st0;
case 84:
	switch( (*p) ) {
		case 70: goto st85;
		case 77: goto st89;
		case 83: goto st93;
		case 84: goto st102;
		case 87: goto st112;
	}
	goto st0;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	if ( (*p) == 114 )
		goto st86;
	goto st0;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	if ( (*p) == 105 )
		goto tr95;
	goto st0;
tr95:
#line 74 "src/panda/date/strptime.rl"
	{ _date.wday = 5; }
	goto st203;
st203:
	if ( ++p == pe )
		goto _test_eof203;
case 203:
#line 1348 "src/panda/date/strptime.cc"
	if ( (*p) == 100 )
		goto st87;
	goto st0;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
	if ( (*p) == 97 )
		goto st88;
	goto st0;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
	if ( (*p) == 121 )
		goto tr97;
	goto st0;
tr97:
#line 74 "src/panda/date/strptime.rl"
	{ _date.wday = 5; }
	goto st204;
tr101:
#line 70 "src/panda/date/strptime.rl"
	{ _date.wday = 1; }
	goto st204;
tr108:
#line 75 "src/panda/date/strptime.rl"
	{ _date.wday = 6; }
	goto st204;
tr111:
#line 76 "src/panda/date/strptime.rl"
	{ _date.wday = 0; }
	goto st204;
tr118:
#line 73 "src/panda/date/strptime.rl"
	{ _date.wday = 4; }
	goto st204;
tr122:
#line 71 "src/panda/date/strptime.rl"
	{ _date.wday = 2; }
	goto st204;
tr129:
#line 72 "src/panda/date/strptime.rl"
	{ _date.wday = 3; }
	goto st204;
st204:
	if ( ++p == pe )
		goto _test_eof204;
case 204:
#line 1398 "src/panda/date/strptime.cc"
	goto st0;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
	if ( (*p) == 111 )
		goto st90;
	goto st0;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	if ( (*p) == 110 )
		goto tr99;
	goto st0;
tr99:
#line 70 "src/panda/date/strptime.rl"
	{ _date.wday = 1; }
	goto st205;
st205:
	if ( ++p == pe )
		goto _test_eof205;
case 205:
#line 1422 "src/panda/date/strptime.cc"
	if ( (*p) == 100 )
		goto st91;
	goto st0;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	if ( (*p) == 97 )
		goto st92;
	goto st0;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	if ( (*p) == 121 )
		goto tr101;
	goto st0;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	switch( (*p) ) {
		case 97: goto st94;
		case 117: goto st99;
	}
	goto st0;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	if ( (*p) == 116 )
		goto tr104;
	goto st0;
tr104:
#line 75 "src/panda/date/strptime.rl"
	{ _date.wday = 6; }
	goto st206;
st206:
	if ( ++p == pe )
		goto _test_eof206;
case 206:
#line 1464 "src/panda/date/strptime.cc"
	if ( (*p) == 117 )
		goto st95;
	goto st0;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	if ( (*p) == 114 )
		goto st96;
	goto st0;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
	if ( (*p) == 100 )
		goto st97;
	goto st0;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	if ( (*p) == 97 )
		goto st98;
	goto st0;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
	if ( (*p) == 121 )
		goto tr108;
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	if ( (*p) == 110 )
		goto tr109;
	goto st0;
tr109:
#line 76 "src/panda/date/strptime.rl"
	{ _date.wday = 0; }
	goto st207;
st207:
	if ( ++p == pe )
		goto _test_eof207;
case 207:
#line 1511 "src/panda/date/strptime.cc"
	if ( (*p) == 100 )
		goto st100;
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	if ( (*p) == 97 )
		goto st101;
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	if ( (*p) == 121 )
		goto tr111;
	goto st0;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	switch( (*p) ) {
		case 104: goto st103;
		case 117: goto st108;
	}
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	if ( (*p) == 117 )
		goto tr114;
	goto st0;
tr114:
#line 73 "src/panda/date/strptime.rl"
	{ _date.wday = 4; }
	goto st208;
st208:
	if ( ++p == pe )
		goto _test_eof208;
case 208:
#line 1553 "src/panda/date/strptime.cc"
	if ( (*p) == 114 )
		goto st104;
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	if ( (*p) == 115 )
		goto st105;
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	if ( (*p) == 100 )
		goto st106;
	goto st0;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	if ( (*p) == 97 )
		goto st107;
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	if ( (*p) == 121 )
		goto tr118;
	goto st0;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
	if ( (*p) == 101 )
		goto tr119;
	goto st0;
tr119:
#line 71 "src/panda/date/strptime.rl"
	{ _date.wday = 2; }
	goto st209;
st209:
	if ( ++p == pe )
		goto _test_eof209;
case 209:
#line 1600 "src/panda/date/strptime.cc"
	if ( (*p) == 115 )
		goto st109;
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	if ( (*p) == 100 )
		goto st110;
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	if ( (*p) == 97 )
		goto st111;
	goto st0;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	if ( (*p) == 121 )
		goto tr122;
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	if ( (*p) == 101 )
		goto st113;
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	if ( (*p) == 100 )
		goto tr124;
	goto st0;
tr124:
#line 72 "src/panda/date/strptime.rl"
	{ _date.wday = 3; }
	goto st210;
st210:
	if ( ++p == pe )
		goto _test_eof210;
case 210:
#line 1647 "src/panda/date/strptime.cc"
	if ( (*p) == 110 )
		goto st114;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	if ( (*p) == 101 )
		goto st115;
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	if ( (*p) == 115 )
		goto st116;
	goto st0;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	if ( (*p) == 100 )
		goto st117;
	goto st0;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	if ( (*p) == 97 )
		goto st118;
	goto st0;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	if ( (*p) == 121 )
		goto tr129;
	goto st0;
case 119:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr130;
	goto st0;
tr130:
#line 110 "src/panda/date/strptime.rl"
	{ week = 0;}
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st120;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
#line 1703 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr131;
	goto st0;
tr131:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 39 "src/panda/date/strptime.rl"
	{ NSAVE(week);              }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 211; goto _out;} }
	goto st211;
st211:
	if ( ++p == pe )
		goto _test_eof211;
case 211:
#line 1722 "src/panda/date/strptime.cc"
	goto st0;
case 121:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr132;
	goto st0;
tr132:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st122;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
#line 1739 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr133;
	goto st0;
tr133:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 41 "src/panda/date/strptime.rl"
	{ _date.mon = acc - 1; acc = 0; }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 212; goto _out;} }
	goto st212;
st212:
	if ( ++p == pe )
		goto _test_eof212;
case 212:
#line 1758 "src/panda/date/strptime.cc"
	goto st0;
case 123:
	switch( (*p) ) {
		case 65: goto st124;
		case 68: goto st130;
		case 70: goto st136;
		case 74: goto st142;
		case 77: goto st148;
		case 78: goto st151;
		case 79: goto st157;
		case 83: goto st162;
	}
	goto st0;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
	switch( (*p) ) {
		case 112: goto st125;
		case 117: goto st127;
	}
	goto st0;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
	if ( (*p) == 114 )
		goto tr144;
	goto st0;
tr144:
#line 81 "src/panda/date/strptime.rl"
	{ _date.mon = 3; }
	goto st213;
st213:
	if ( ++p == pe )
		goto _test_eof213;
case 213:
#line 1796 "src/panda/date/strptime.cc"
	if ( (*p) == 105 )
		goto st126;
	goto st0;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
	if ( (*p) == 108 )
		goto tr145;
	goto st0;
tr145:
#line 81 "src/panda/date/strptime.rl"
	{ _date.mon = 3; }
	goto st214;
tr148:
#line 85 "src/panda/date/strptime.rl"
	{ _date.mon = 7; }
	goto st214;
tr154:
#line 89 "src/panda/date/strptime.rl"
	{ _date.mon = 11;}
	goto st214;
tr160:
#line 79 "src/panda/date/strptime.rl"
	{ _date.mon = 1; }
	goto st214;
tr166:
#line 78 "src/panda/date/strptime.rl"
	{ _date.mon = 0; }
	goto st214;
tr220:
#line 84 "src/panda/date/strptime.rl"
	{ _date.mon = 6; }
	goto st214;
tr221:
#line 83 "src/panda/date/strptime.rl"
	{ _date.mon = 5; }
	goto st214;
tr172:
#line 80 "src/panda/date/strptime.rl"
	{ _date.mon = 2; }
	goto st214;
tr171:
#line 82 "src/panda/date/strptime.rl"
	{ _date.mon = 4; }
	goto st214;
tr178:
#line 88 "src/panda/date/strptime.rl"
	{ _date.mon = 10;}
	goto st214;
tr183:
#line 87 "src/panda/date/strptime.rl"
	{ _date.mon = 9; }
	goto st214;
tr190:
#line 86 "src/panda/date/strptime.rl"
	{ _date.mon = 8; }
	goto st214;
st214:
	if ( ++p == pe )
		goto _test_eof214;
case 214:
#line 1859 "src/panda/date/strptime.cc"
	goto st0;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	if ( (*p) == 103 )
		goto tr146;
	goto st0;
tr146:
#line 85 "src/panda/date/strptime.rl"
	{ _date.mon = 7; }
	goto st215;
st215:
	if ( ++p == pe )
		goto _test_eof215;
case 215:
#line 1876 "src/panda/date/strptime.cc"
	if ( (*p) == 117 )
		goto st128;
	goto st0;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	if ( (*p) == 115 )
		goto st129;
	goto st0;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	if ( (*p) == 116 )
		goto tr148;
	goto st0;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	if ( (*p) == 101 )
		goto st131;
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	if ( (*p) == 99 )
		goto tr150;
	goto st0;
tr150:
#line 89 "src/panda/date/strptime.rl"
	{ _date.mon = 11;}
	goto st216;
st216:
	if ( ++p == pe )
		goto _test_eof216;
case 216:
#line 1916 "src/panda/date/strptime.cc"
	if ( (*p) == 101 )
		goto st132;
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	if ( (*p) == 109 )
		goto st133;
	goto st0;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
	if ( (*p) == 98 )
		goto st134;
	goto st0;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
	if ( (*p) == 101 )
		goto st135;
	goto st0;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
	if ( (*p) == 114 )
		goto tr154;
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	if ( (*p) == 101 )
		goto st137;
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	if ( (*p) == 98 )
		goto tr156;
	goto st0;
tr156:
#line 79 "src/panda/date/strptime.rl"
	{ _date.mon = 1; }
	goto st217;
st217:
	if ( ++p == pe )
		goto _test_eof217;
case 217:
#line 1970 "src/panda/date/strptime.cc"
	if ( (*p) == 114 )
		goto st138;
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	if ( (*p) == 117 )
		goto st139;
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	if ( (*p) == 97 )
		goto st140;
	goto st0;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	if ( (*p) == 114 )
		goto st141;
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	if ( (*p) == 121 )
		goto tr160;
	goto st0;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	switch( (*p) ) {
		case 97: goto st143;
		case 117: goto st147;
	}
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	if ( (*p) == 110 )
		goto tr163;
	goto st0;
tr163:
#line 78 "src/panda/date/strptime.rl"
	{ _date.mon = 0; }
	goto st218;
st218:
	if ( ++p == pe )
		goto _test_eof218;
case 218:
#line 2026 "src/panda/date/strptime.cc"
	if ( (*p) == 117 )
		goto st144;
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	if ( (*p) == 97 )
		goto st145;
	goto st0;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	if ( (*p) == 114 )
		goto st146;
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	if ( (*p) == 121 )
		goto tr166;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	switch( (*p) ) {
		case 108: goto tr167;
		case 110: goto tr168;
	}
	goto st0;
tr167:
#line 84 "src/panda/date/strptime.rl"
	{ _date.mon = 6; }
	goto st219;
st219:
	if ( ++p == pe )
		goto _test_eof219;
case 219:
#line 2068 "src/panda/date/strptime.cc"
	if ( (*p) == 121 )
		goto tr220;
	goto st0;
tr168:
#line 83 "src/panda/date/strptime.rl"
	{ _date.mon = 5; }
	goto st220;
st220:
	if ( ++p == pe )
		goto _test_eof220;
case 220:
#line 2080 "src/panda/date/strptime.cc"
	if ( (*p) == 101 )
		goto tr221;
	goto st0;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	if ( (*p) == 97 )
		goto st149;
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	switch( (*p) ) {
		case 114: goto tr170;
		case 121: goto tr171;
	}
	goto st0;
tr170:
#line 80 "src/panda/date/strptime.rl"
	{ _date.mon = 2; }
	goto st221;
st221:
	if ( ++p == pe )
		goto _test_eof221;
case 221:
#line 2108 "src/panda/date/strptime.cc"
	if ( (*p) == 99 )
		goto st150;
	goto st0;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	if ( (*p) == 104 )
		goto tr172;
	goto st0;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	if ( (*p) == 111 )
		goto st152;
	goto st0;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	if ( (*p) == 118 )
		goto tr174;
	goto st0;
tr174:
#line 88 "src/panda/date/strptime.rl"
	{ _date.mon = 10;}
	goto st222;
st222:
	if ( ++p == pe )
		goto _test_eof222;
case 222:
#line 2141 "src/panda/date/strptime.cc"
	if ( (*p) == 101 )
		goto st153;
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	if ( (*p) == 109 )
		goto st154;
	goto st0;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	if ( (*p) == 98 )
		goto st155;
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	if ( (*p) == 101 )
		goto st156;
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	if ( (*p) == 114 )
		goto tr178;
	goto st0;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
	if ( (*p) == 99 )
		goto st158;
	goto st0;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	if ( (*p) == 116 )
		goto tr180;
	goto st0;
tr180:
#line 87 "src/panda/date/strptime.rl"
	{ _date.mon = 9; }
	goto st223;
st223:
	if ( ++p == pe )
		goto _test_eof223;
case 223:
#line 2195 "src/panda/date/strptime.cc"
	if ( (*p) == 111 )
		goto st159;
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	if ( (*p) == 98 )
		goto st160;
	goto st0;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
	if ( (*p) == 101 )
		goto st161;
	goto st0;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
	if ( (*p) == 114 )
		goto tr183;
	goto st0;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	if ( (*p) == 101 )
		goto st163;
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	if ( (*p) == 112 )
		goto tr185;
	goto st0;
tr185:
#line 86 "src/panda/date/strptime.rl"
	{ _date.mon = 8; }
	goto st224;
st224:
	if ( ++p == pe )
		goto _test_eof224;
case 224:
#line 2242 "src/panda/date/strptime.cc"
	if ( (*p) == 116 )
		goto st164;
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	if ( (*p) == 101 )
		goto st165;
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	if ( (*p) == 109 )
		goto st166;
	goto st0;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
	if ( (*p) == 98 )
		goto st167;
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	if ( (*p) == 101 )
		goto st168;
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	if ( (*p) == 114 )
		goto tr190;
	goto st0;
case 169:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr191;
	goto st0;
tr191:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st170;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
#line 2296 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr192;
	goto st0;
tr192:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st171;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
#line 2311 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr193;
	goto st0;
tr193:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st172;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
#line 2326 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr194;
	goto st0;
tr194:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 30 "src/panda/date/strptime.rl"
	{ NSAVE(_date.year);        }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 225; goto _out;} }
	goto st225;
st225:
	if ( ++p == pe )
		goto _test_eof225;
case 225:
#line 2345 "src/panda/date/strptime.cc"
	goto st0;
case 173:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr195;
	goto st0;
tr195:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st174;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
#line 2362 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr196;
	goto st0;
tr196:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 44 "src/panda/date/strptime.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 226; goto _out;} }
	goto st226;
st226:
	if ( ++p == pe )
		goto _test_eof226;
case 226:
#line 2385 "src/panda/date/strptime.cc"
	goto st0;
case 175:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr197;
	goto st0;
tr197:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st176;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
#line 2402 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr198;
	goto st0;
tr198:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
#line 29 "src/panda/date/strptime.rl"
	{ _date.year += acc * 100; acc = 0; }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 227; goto _out;} }
	goto st227;
st227:
	if ( ++p == pe )
		goto _test_eof227;
case 227:
#line 2421 "src/panda/date/strptime.cc"
	goto st0;
case 177:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr199;
	goto st0;
tr199:
#line 24 "src/panda/date/strptime.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st228;
st228:
	if ( ++p == pe )
		goto _test_eof228;
case 228:
#line 2438 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr199;
	goto st0;
case 178:
	switch( (*p) ) {
		case 43: goto tr200;
		case 45: goto tr200;
	}
	goto st0;
tr200:
#line 50 "src/panda/date/strptime.rl"
	{
        tzi.rule[0] = '<';
        tzi.rule[1] = *p;
        tzi.rule[4] = ':';
        tzi.rule[7] = '>';
        tzi.rule[8] = *p ^ 6; // swap '+'<->'-': yes, it is reversed
        tzi.rule[11] = ':';
        tzi.rule[5] = tzi.rule[6] = tzi.rule[12] = tzi.rule[13] = '0'; // in case there will be no minutes
        tzi.len = 14;
    }
	goto st179;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
#line 2465 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr201;
	goto st0;
tr201:
#line 61 "src/panda/date/strptime.rl"
	{ tzi.rule[2] = tzi.rule[9]  = *p; }
	goto st180;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
#line 2477 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr202;
	goto st0;
tr202:
#line 62 "src/panda/date/strptime.rl"
	{ tzi.rule[3] = tzi.rule[10] = *p; }
	goto st181;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
#line 2489 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr203;
	goto st0;
tr203:
#line 63 "src/panda/date/strptime.rl"
	{ tzi.rule[5] = tzi.rule[12] = *p; }
	goto st182;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
#line 2501 "src/panda/date/strptime.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr204;
	goto st0;
tr204:
#line 64 "src/panda/date/strptime.rl"
	{ tzi.rule[6] = tzi.rule[13] = *p; }
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 229; goto _out;} }
	goto st229;
st229:
	if ( ++p == pe )
		goto _test_eof229;
case 229:
#line 2515 "src/panda/date/strptime.cc"
	goto st0;
case 183:
	if ( (*p) < 65 ) {
		if ( 43 <= (*p) && (*p) <= 47 )
			goto tr205;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr205;
	} else
		goto tr205;
	goto st0;
tr205:
#line 118 "src/panda/date/strptime.rl"
	{tz_b = p;}
	goto st230;
st230:
	if ( ++p == pe )
		goto _test_eof230;
case 230:
#line 2535 "src/panda/date/strptime.cc"
	if ( (*p) < 65 ) {
		if ( 43 <= (*p) && (*p) <= 47 )
			goto st230;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st230;
	} else
		goto st230;
	goto st0;
case 184:
	if ( (*p) == 37 )
		goto tr206;
	goto st0;
tr206:
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 231; goto _out;} }
	goto st231;
st231:
	if ( ++p == pe )
		goto _test_eof231;
case 231:
#line 2557 "src/panda/date/strptime.cc"
	goto st0;
	}
	_test_eof185: cs = 185; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof186: cs = 186; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof187: cs = 187; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof188: cs = 188; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof189: cs = 189; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof190: cs = 190; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof191: cs = 191; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof192: cs = 192; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof193: cs = 193; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof194: cs = 194; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof195: cs = 195; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof196: cs = 196; goto _test_eof; 
	_test_eof59: cs = 59; goto _test_eof; 
	_test_eof60: cs = 60; goto _test_eof; 
	_test_eof61: cs = 61; goto _test_eof; 
	_test_eof62: cs = 62; goto _test_eof; 
	_test_eof63: cs = 63; goto _test_eof; 
	_test_eof64: cs = 64; goto _test_eof; 
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof66: cs = 66; goto _test_eof; 
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof197: cs = 197; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof198: cs = 198; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof199: cs = 199; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof200: cs = 200; goto _test_eof; 
	_test_eof201: cs = 201; goto _test_eof; 
	_test_eof202: cs = 202; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
	_test_eof86: cs = 86; goto _test_eof; 
	_test_eof203: cs = 203; goto _test_eof; 
	_test_eof87: cs = 87; goto _test_eof; 
	_test_eof88: cs = 88; goto _test_eof; 
	_test_eof204: cs = 204; goto _test_eof; 
	_test_eof89: cs = 89; goto _test_eof; 
	_test_eof90: cs = 90; goto _test_eof; 
	_test_eof205: cs = 205; goto _test_eof; 
	_test_eof91: cs = 91; goto _test_eof; 
	_test_eof92: cs = 92; goto _test_eof; 
	_test_eof93: cs = 93; goto _test_eof; 
	_test_eof94: cs = 94; goto _test_eof; 
	_test_eof206: cs = 206; goto _test_eof; 
	_test_eof95: cs = 95; goto _test_eof; 
	_test_eof96: cs = 96; goto _test_eof; 
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof98: cs = 98; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof207: cs = 207; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof208: cs = 208; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof108: cs = 108; goto _test_eof; 
	_test_eof209: cs = 209; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
	_test_eof113: cs = 113; goto _test_eof; 
	_test_eof210: cs = 210; goto _test_eof; 
	_test_eof114: cs = 114; goto _test_eof; 
	_test_eof115: cs = 115; goto _test_eof; 
	_test_eof116: cs = 116; goto _test_eof; 
	_test_eof117: cs = 117; goto _test_eof; 
	_test_eof118: cs = 118; goto _test_eof; 
	_test_eof120: cs = 120; goto _test_eof; 
	_test_eof211: cs = 211; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
	_test_eof212: cs = 212; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
	_test_eof213: cs = 213; goto _test_eof; 
	_test_eof126: cs = 126; goto _test_eof; 
	_test_eof214: cs = 214; goto _test_eof; 
	_test_eof127: cs = 127; goto _test_eof; 
	_test_eof215: cs = 215; goto _test_eof; 
	_test_eof128: cs = 128; goto _test_eof; 
	_test_eof129: cs = 129; goto _test_eof; 
	_test_eof130: cs = 130; goto _test_eof; 
	_test_eof131: cs = 131; goto _test_eof; 
	_test_eof216: cs = 216; goto _test_eof; 
	_test_eof132: cs = 132; goto _test_eof; 
	_test_eof133: cs = 133; goto _test_eof; 
	_test_eof134: cs = 134; goto _test_eof; 
	_test_eof135: cs = 135; goto _test_eof; 
	_test_eof136: cs = 136; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 
	_test_eof217: cs = 217; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
	_test_eof218: cs = 218; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof219: cs = 219; goto _test_eof; 
	_test_eof220: cs = 220; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof149: cs = 149; goto _test_eof; 
	_test_eof221: cs = 221; goto _test_eof; 
	_test_eof150: cs = 150; goto _test_eof; 
	_test_eof151: cs = 151; goto _test_eof; 
	_test_eof152: cs = 152; goto _test_eof; 
	_test_eof222: cs = 222; goto _test_eof; 
	_test_eof153: cs = 153; goto _test_eof; 
	_test_eof154: cs = 154; goto _test_eof; 
	_test_eof155: cs = 155; goto _test_eof; 
	_test_eof156: cs = 156; goto _test_eof; 
	_test_eof157: cs = 157; goto _test_eof; 
	_test_eof158: cs = 158; goto _test_eof; 
	_test_eof223: cs = 223; goto _test_eof; 
	_test_eof159: cs = 159; goto _test_eof; 
	_test_eof160: cs = 160; goto _test_eof; 
	_test_eof161: cs = 161; goto _test_eof; 
	_test_eof162: cs = 162; goto _test_eof; 
	_test_eof163: cs = 163; goto _test_eof; 
	_test_eof224: cs = 224; goto _test_eof; 
	_test_eof164: cs = 164; goto _test_eof; 
	_test_eof165: cs = 165; goto _test_eof; 
	_test_eof166: cs = 166; goto _test_eof; 
	_test_eof167: cs = 167; goto _test_eof; 
	_test_eof168: cs = 168; goto _test_eof; 
	_test_eof170: cs = 170; goto _test_eof; 
	_test_eof171: cs = 171; goto _test_eof; 
	_test_eof172: cs = 172; goto _test_eof; 
	_test_eof225: cs = 225; goto _test_eof; 
	_test_eof174: cs = 174; goto _test_eof; 
	_test_eof226: cs = 226; goto _test_eof; 
	_test_eof176: cs = 176; goto _test_eof; 
	_test_eof227: cs = 227; goto _test_eof; 
	_test_eof228: cs = 228; goto _test_eof; 
	_test_eof179: cs = 179; goto _test_eof; 
	_test_eof180: cs = 180; goto _test_eof; 
	_test_eof181: cs = 181; goto _test_eof; 
	_test_eof182: cs = 182; goto _test_eof; 
	_test_eof229: cs = 229; goto _test_eof; 
	_test_eof230: cs = 230; goto _test_eof; 
	_test_eof231: cs = 231; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 228: 
#line 40 "src/panda/date/strptime.rl"
	{ NSAVE(epoch_);            }
	break;
	case 185: 
	case 203: 
	case 204: 
	case 205: 
	case 206: 
	case 207: 
	case 208: 
	case 209: 
	case 210: 
	case 213: 
	case 214: 
	case 215: 
	case 216: 
	case 217: 
	case 218: 
	case 219: 
	case 220: 
	case 221: 
	case 222: 
	case 223: 
	case 224: 
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 0; goto _out;} }
	break;
	case 230: 
#line 118 "src/panda/date/strptime.rl"
	{tz_e = p;}
#line 42 "src/panda/date/strptime.rl"
	{ {p++; cs = 0; goto _out;} }
	break;
#line 2802 "src/panda/date/strptime.cc"
	}
	}

	_out: {}
	}

#line 132 "src/panda/date/strptime.rl"


    // printf("_parse_str %s -> cs=%d, consumed=%d\n", pb, cs, p - pb);
    return p - pb;
}


#line 178 "src/panda/date/strptime.rl"



#line 2821 "src/panda/date/strptime.cc"
static const int meta_parser_start = 1;
static const int meta_parser_first_final = 3;
static const int meta_parser_error = 0;

static const int meta_parser_en_m_main = 1;


#line 181 "src/panda/date/strptime.rl"

static inline MetaConsume _parse_meta(const char* p, const char* pe, WeekInterpretation& week_interptetation)  {
    const char* pb     = p;
    int         cs     = meta_parser_en_m_main;
    int         p_cs   = 0;

    
#line 2837 "src/panda/date/strptime.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 9: goto tr0;
		case 32: goto tr0;
		case 37: goto st2;
	}
	goto st0;
st0:
cs = 0;
	goto _out;
tr0:
#line 171 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_space;                                        {p++; cs = 3; goto _out;} }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 2861 "src/panda/date/strptime.cc"
	switch( (*p) ) {
		case 9: goto tr0;
		case 32: goto tr0;
	}
	goto st0;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	switch( (*p) ) {
		case 37: goto tr3;
		case 65: goto tr4;
		case 66: goto tr5;
		case 67: goto tr6;
		case 68: goto tr7;
		case 70: goto tr8;
		case 77: goto tr10;
		case 80: goto tr11;
		case 82: goto tr12;
		case 83: goto tr13;
		case 85: goto tr15;
		case 86: goto tr16;
		case 87: goto tr17;
		case 89: goto tr18;
		case 90: goto tr19;
		case 97: goto tr4;
		case 98: goto tr5;
		case 99: goto tr20;
		case 100: goto tr21;
		case 101: goto tr22;
		case 104: goto tr5;
		case 106: goto tr23;
		case 109: goto tr25;
		case 110: goto tr26;
		case 112: goto tr27;
		case 114: goto tr28;
		case 115: goto tr29;
		case 116: goto tr26;
		case 117: goto tr30;
		case 119: goto tr31;
		case 120: goto tr7;
		case 121: goto tr32;
		case 122: goto tr33;
	}
	if ( (*p) < 84 ) {
		if ( 72 <= (*p) && (*p) <= 73 )
			goto tr9;
	} else if ( (*p) > 88 ) {
		if ( 107 <= (*p) && (*p) <= 108 )
			goto tr24;
	} else
		goto tr14;
	goto st0;
tr3:
#line 169 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_perc;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr4:
#line 150 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_wname;                                         {p++; cs = 4; goto _out;} }
	goto st4;
tr5:
#line 157 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_mname;                                 {p++; cs = 4; goto _out;} }
	goto st4;
tr6:
#line 144 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_cent;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr7:
#line 165 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_mdy;                                          {p++; cs = 4; goto _out;} }
	goto st4;
tr8:
#line 163 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_ymd;                                                    {p++; cs = 4; goto _out;} }
	goto st4;
tr9:
#line 154 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_hour;                                          {p++; cs = 4; goto _out;} }
	goto st4;
tr10:
#line 158 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_min;                                                    {p++; cs = 4; goto _out;} }
	goto st4;
tr11:
#line 142 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_ampm;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr12:
#line 160 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_hour_min;                                               {p++; cs = 4; goto _out;} }
	goto st4;
tr13:
#line 159 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_sec;                                                    {p++; cs = 4; goto _out;} }
	goto st4;
tr14:
#line 164 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_hms;                                          {p++; cs = 4; goto _out;} }
	goto st4;
tr15:
#line 153 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_wnum; week_interptetation = WeekInterpretation::sunday; {p++; cs = 4; goto _out;} }
	goto st4;
tr16:
#line 151 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_wnum; week_interptetation = WeekInterpretation::iso;    {p++; cs = 4; goto _out;} }
	goto st4;
tr17:
#line 152 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_wnum; week_interptetation = WeekInterpretation::monday; {p++; cs = 4; goto _out;} }
	goto st4;
tr18:
#line 143 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_year;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr19:
#line 168 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_tz_name;                                               {p++; cs = 4; goto _out;} }
	goto st4;
tr20:
#line 161 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_mdyhms;                                                 {p++; cs = 4; goto _out;} }
	goto st4;
tr21:
#line 145 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_day;                                                    {p++; cs = 4; goto _out;} }
	goto st4;
tr22:
#line 147 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_day_s;                                                  {p++; cs = 4; goto _out;} }
	goto st4;
tr23:
#line 146 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_day3;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr24:
#line 155 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_hour_s;                                        {p++; cs = 4; goto _out;} }
	goto st4;
tr25:
#line 156 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_month;                                                  {p++; cs = 4; goto _out;} }
	goto st4;
tr26:
#line 170 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_space;                                         {p++; cs = 4; goto _out;} }
	goto st4;
tr27:
#line 141 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_AMPM;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr28:
#line 162 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_hmsAMPM;                                               {p++; cs = 4; goto _out;} }
	goto st4;
tr29:
#line 166 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_epoch;                                                 {p++; cs = 4; goto _out;} }
	goto st4;
tr30:
#line 149 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_wday_s;                                                 {p++; cs = 4; goto _out;} }
	goto st4;
tr31:
#line 148 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_wday;                                                   {p++; cs = 4; goto _out;} }
	goto st4;
tr32:
#line 140 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_yr;                                                     {p++; cs = 4; goto _out;} }
	goto st4;
tr33:
#line 167 "src/panda/date/strptime.rl"
	{ p_cs = parser_en_p_tz_num;                                                {p++; cs = 4; goto _out;} }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 3043 "src/panda/date/strptime.cc"
	goto st0;
	}
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 

	_test_eof: {}
	_out: {}
	}

#line 188 "src/panda/date/strptime.rl"

    auto consumed = p - pb;
    // printf("_parse_meta '%s' p_cs=%d, c=%d, cs=%d\n", pb, p_cs, consumed, cs);
    return MetaConsume { p_cs, (int)consumed };
}

void Date::_strptime (string_view str, string_view format) {
    memset(&_date, 0, sizeof(_date)); // reset all values
    _date.mday = 1;
    _error = errc::ok;
    _mksec = 0;
    _has_date = true;

    ptime_t epoch_ = 0;
    int week       = -1;
    WeekInterpretation week_interptetation = WeekInterpretation::none;
    TZInfo tzi;

    const char* m_p = format.data();
    const char* m_e = m_p + format.length();
    const char* s_p = str.data();
    const char* s_e = s_p + str.length();
    const char* tz_b = nullptr;
    const char* tz_e = nullptr;

    while((m_p != m_e) && (s_p != s_e)) {
        // printf("cycle, meta='%s', str='%s'\n", m_p, s_p);
        auto meta_result = _parse_meta(m_p, m_e, week_interptetation);
        if (meta_result.cs) {
            int consumed = _parse_str(meta_result.cs, s_p, s_e, week, _date, epoch_, tzi, tz_b, tz_e);
            if (consumed >= 0) {
                s_p += consumed;
            } else {
                _error = errc::parser_error;
                break;
            }
        } else {
            meta_result.consumed = 0;
            if (*m_p++ != *s_p++) {
                // printf("char mismatch\n");
                _error = errc::parser_error;
                break;
            }
        }
        m_p += meta_result.consumed;
    }

    if ((m_p < m_e) || (s_p < s_e)) {
        _error = errc::parser_error;
        return;
    }

    if (epoch_ != 0) {
        epoch(epoch_);
    } else {
        _has_date = true;
    }

    switch (week_interptetation) {
        case WeekInterpretation::none: break;
        case WeekInterpretation::iso: _post_parse_week((unsigned)week); break;
        case WeekInterpretation::monday: ; /* fallthrough */
        case WeekInterpretation::sunday:
        if (!_date.wday) _date.wday = 1;
            auto days_since_christ = panda::time::christ_days(_date.year);
            int32_t beginning_weekday = days_since_christ % 7;

            //static constexpr const int32_t WEEK_DELTA[] = {6, 0, 1, 2, 3, 4, 5};
            //static constexpr const int32_t WEEK_DELTA[] = {-1, 0, 1, 2, 3, 4, 5};
            //auto delta = WEEK_DELTA[beginning_weekday];
            if (!beginning_weekday) beginning_weekday = (int)week_interptetation;   // for %U
            auto delta = ((beginning_weekday - 1) + 7) % 7;

            //printf("y = %d, wday = %d, delta = %d, beg = %d\n", _date.year, _date.wday, delta, beginning_weekday);
            _date.mday = week * 7  + (_date.wday - 1) - delta;
    }

    if (tzi.len) _zone = panda::time::tzget(string_view(tzi.rule, tzi.len));
    if (tz_e) {
        auto zkey = string_view(tz_b, tz_e - tz_b);
        _zone = panda::time::tzget(zkey);
        if (_zone->name == panda::time::GMT_FALLBACK) {
            _zone = panda::time::tzget_abbr(zkey);
        }
    }
}

}}
