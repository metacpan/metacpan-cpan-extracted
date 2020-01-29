
#line 1 "src/panda/date/parse-date.rl"
#include "Date.h" 
#include <string.h>
#include <stdlib.h>
#include <algorithm>


#line 161 "src/panda/date/parse-date.rl"


namespace panda { namespace date {


#line 16 "src/panda/date/parse-date.cc"
static const int date_parser_start = 1;
static const int date_parser_first_final = 273;
static const int date_parser_error = 0;

static const int date_parser_en_all = 1;


#line 166 "src/panda/date/parse-date.rl"

static constexpr const int32_t WEEK_1_OFFSETS[] = {0, -1, -2, -3, 4, 3, 2};
static constexpr const int32_t WEEK_2_OFFSETS[] = {8, 7, 6, 5, 9, 10, 9};

static const Timezone* gmt_zone;

#define NSAVE(dest) { dest = acc; acc = 0; }
        
#define TZRULE(str) do {                    \
    memcpy(tzi.rule, str, sizeof(str) - 1); \
    tzi.len = sizeof(str) - 1;              \
} while(0)

void Date::parse (string_view str, int allowed_formats) {
    memset(&_date, 0, sizeof(_date)); // reset all values
    _date.mday = 1;
    _error = errc::ok;
    _mksec = 0;

    enum class TZType { LOCAL, OFFSET };
    
    const char* p      = str.data();
    const char* pe     = p + str.length();
    const char* eof    = pe;
    int         cs     = date_parser_en_all;
    uint64_t    acc    = 0;
    const char* mksec_ptr;
    int         format = 0;
    
    struct {
        char rule[14];
        int  len = 0;
    } tzi;
    
    unsigned week = 0;

    
#line 62 "src/panda/date/parse-date.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 70: goto st113;
		case 77: goto st231;
		case 83: goto st237;
		case 84: goto st250;
		case 87: goto st264;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr0;
	goto st0;
st0:
cs = 0;
	goto _out;
tr0:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 93 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr7;
	goto st0;
tr7:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 108 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 32: goto tr8;
		case 46: goto tr9;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr10;
	goto st0;
tr8:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 124 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st5;
		case 68: goto st38;
		case 70: goto st41;
		case 74: goto st44;
		case 77: goto st50;
		case 78: goto st54;
		case 79: goto st57;
		case 83: goto st60;
	}
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	switch( (*p) ) {
		case 112: goto st6;
		case 117: goto st36;
	}
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == 114 )
		goto st7;
	goto st0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( (*p) == 32 )
		goto tr22;
	goto st0;
tr22:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st8;
tr62:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st8;
tr65:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st8;
tr68:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st8;
tr72:
#line 97 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st8;
tr75:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st8;
tr76:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st8;
tr80:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st8;
tr81:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st8;
tr84:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st8;
tr87:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st8;
tr90:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 211 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr23;
	goto st0;
tr23:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st9;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
#line 226 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
tr24:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 241 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr25;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr26;
	goto st0;
tr25:
#line 21 "src/panda/date/parse-date.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
	goto st11;
tr60:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 263 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr27;
	goto st0;
tr27:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 278 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr28;
	goto st0;
tr28:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 293 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr29;
	goto st0;
tr29:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 305 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr30;
	goto st0;
tr30:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 320 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr31;
	goto st0;
tr31:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 335 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 32: goto tr32;
		case 58: goto tr33;
	}
	goto st0;
tr32:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st17;
tr58:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 353 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr34;
		case 45: goto tr34;
		case 65: goto st274;
		case 67: goto st22;
		case 69: goto st24;
		case 71: goto st26;
		case 77: goto st278;
		case 78: goto st280;
		case 80: goto st29;
		case 85: goto st27;
		case 89: goto st282;
		case 90: goto st277;
	}
	goto st0;
tr34:
#line 48 "src/panda/date/parse-date.rl"
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
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 386 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr45;
	goto st0;
tr45:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 401 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr46;
	goto st0;
tr46:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 416 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr47;
	goto st0;
tr47:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 436 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr48;
	goto st0;
tr48:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st273;
st273:
	if ( ++p == pe )
		goto _test_eof273;
case 273:
#line 451 "src/panda/date/parse-date.cc"
	goto st0;
st274:
	if ( ++p == pe )
		goto _test_eof274;
case 274:
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	switch( (*p) ) {
		case 68: goto st23;
		case 83: goto st23;
	}
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( (*p) == 84 )
		goto st275;
	goto st0;
st275:
	if ( ++p == pe )
		goto _test_eof275;
case 275:
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	switch( (*p) ) {
		case 68: goto st25;
		case 83: goto st25;
	}
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	if ( (*p) == 84 )
		goto st276;
	goto st0;
st276:
	if ( ++p == pe )
		goto _test_eof276;
case 276:
	goto st0;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	if ( (*p) == 77 )
		goto st27;
	goto st0;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	if ( (*p) == 84 )
		goto st277;
	goto st0;
st277:
	if ( ++p == pe )
		goto _test_eof277;
case 277:
	goto st0;
st278:
	if ( ++p == pe )
		goto _test_eof278;
case 278:
	switch( (*p) ) {
		case 68: goto st28;
		case 83: goto st28;
	}
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	if ( (*p) == 84 )
		goto st279;
	goto st0;
st279:
	if ( ++p == pe )
		goto _test_eof279;
case 279:
	goto st0;
st280:
	if ( ++p == pe )
		goto _test_eof280;
case 280:
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	switch( (*p) ) {
		case 68: goto st30;
		case 83: goto st30;
	}
	goto st0;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	if ( (*p) == 84 )
		goto st281;
	goto st0;
st281:
	if ( ++p == pe )
		goto _test_eof281;
case 281:
	goto st0;
st282:
	if ( ++p == pe )
		goto _test_eof282;
case 282:
	goto st0;
tr33:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 579 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr56;
	goto st0;
tr56:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 594 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr57;
	goto st0;
tr57:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st33;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
#line 609 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr58;
	goto st0;
tr26:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st34;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
#line 624 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr59;
	goto st0;
tr59:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st35;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
#line 639 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr60;
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	if ( (*p) == 103 )
		goto st37;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	if ( (*p) == 32 )
		goto tr62;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( (*p) == 101 )
		goto st39;
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	if ( (*p) == 99 )
		goto st40;
	goto st0;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	if ( (*p) == 32 )
		goto tr65;
	goto st0;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	if ( (*p) == 101 )
		goto st42;
	goto st0;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
	if ( (*p) == 98 )
		goto st43;
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	if ( (*p) == 32 )
		goto tr68;
	goto st0;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	switch( (*p) ) {
		case 97: goto st45;
		case 117: goto st47;
	}
	goto st0;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	if ( (*p) == 110 )
		goto st46;
	goto st0;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	if ( (*p) == 32 )
		goto tr72;
	goto st0;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 108: goto st48;
		case 110: goto st49;
	}
	goto st0;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	if ( (*p) == 32 )
		goto tr75;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	if ( (*p) == 32 )
		goto tr76;
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	if ( (*p) == 97 )
		goto st51;
	goto st0;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	switch( (*p) ) {
		case 114: goto st52;
		case 121: goto st53;
	}
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	if ( (*p) == 32 )
		goto tr80;
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( (*p) == 32 )
		goto tr81;
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( (*p) == 111 )
		goto st55;
	goto st0;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	if ( (*p) == 118 )
		goto st56;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	if ( (*p) == 32 )
		goto tr84;
	goto st0;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	if ( (*p) == 99 )
		goto st58;
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( (*p) == 116 )
		goto st59;
	goto st0;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	if ( (*p) == 32 )
		goto tr87;
	goto st0;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	if ( (*p) == 101 )
		goto st61;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( (*p) == 112 )
		goto st62;
	goto st0;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	if ( (*p) == 32 )
		goto tr90;
	goto st0;
tr9:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st63;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
#line 846 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr91;
	goto st0;
tr91:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st64;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
#line 861 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr92;
	goto st0;
tr92:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st65;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
#line 876 "src/panda/date/parse-date.cc"
	if ( (*p) == 46 )
		goto tr93;
	goto st0;
tr93:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st66;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
#line 888 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr94;
	goto st0;
tr94:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st67;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
#line 903 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr95;
	goto st0;
tr95:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st68;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
#line 918 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr96;
	goto st0;
tr96:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st69;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
#line 933 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr97;
	goto st0;
tr97:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st283;
st283:
	if ( ++p == pe )
		goto _test_eof283;
case 283:
#line 948 "src/panda/date/parse-date.cc"
	goto st0;
tr10:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st70;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
#line 961 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr98;
	goto st0;
tr98:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st71;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
#line 976 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 45: goto tr99;
		case 47: goto tr100;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr101;
	goto st0;
tr99:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st72;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
#line 992 "src/panda/date/parse-date.cc"
	if ( (*p) == 87 )
		goto st99;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr102;
	goto st0;
tr102:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st73;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
#line 1009 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr104;
	goto st0;
tr104:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st284;
st284:
	if ( ++p == pe )
		goto _test_eof284;
case 284:
#line 1024 "src/panda/date/parse-date.cc"
	if ( (*p) == 45 )
		goto tr351;
	goto st0;
tr351:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st74;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
#line 1036 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr105;
	goto st0;
tr105:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st75;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
#line 1051 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr106;
	goto st0;
tr106:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st285;
st285:
	if ( ++p == pe )
		goto _test_eof285;
case 285:
#line 1066 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 32: goto tr352;
		case 84: goto tr353;
	}
	goto st0;
tr352:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st76;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
#line 1080 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr107;
	goto st0;
tr107:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st77;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
#line 1095 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr108;
	goto st0;
tr108:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st78;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
#line 1110 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr109;
	goto st0;
tr109:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st79;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
#line 1122 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr110;
	goto st0;
tr110:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st80;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
#line 1137 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr111;
	goto st0;
tr111:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st286;
st286:
	if ( ++p == pe )
		goto _test_eof286;
case 286:
#line 1152 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr354;
		case 45: goto tr354;
		case 58: goto tr355;
		case 90: goto tr356;
	}
	goto st0;
tr354:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st81;
tr358:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st81;
tr361:
#line 31 "src/panda/date/parse-date.rl"
	{
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st81;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
#line 1220 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr112;
	goto st0;
tr112:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st82;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
#line 1235 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr113;
	goto st0;
tr113:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st287;
st287:
	if ( ++p == pe )
		goto _test_eof287;
case 287:
#line 1250 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr357;
	goto st0;
tr357:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
	goto st83;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
#line 1265 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr114;
	goto st0;
tr114:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st84;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
#line 1280 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr115;
	goto st0;
tr115:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st288;
st288:
	if ( ++p == pe )
		goto _test_eof288;
case 288:
#line 1295 "src/panda/date/parse-date.cc"
	goto st0;
tr355:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st85;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
#line 1305 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr116;
	goto st0;
tr116:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st86;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
#line 1320 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr117;
	goto st0;
tr117:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st289;
st289:
	if ( ++p == pe )
		goto _test_eof289;
case 289:
#line 1335 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 44: goto tr359;
		case 46: goto tr359;
		case 90: goto tr360;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr358;
	goto st0;
tr359:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st87;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
#line 1352 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr118;
	goto st0;
tr118:
#line 27 "src/panda/date/parse-date.rl"
	{
        mksec_ptr = p;
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st290;
st290:
	if ( ++p == pe )
		goto _test_eof290;
case 290:
#line 1371 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr361;
		case 45: goto tr361;
		case 90: goto tr363;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr362;
	goto st0;
tr362:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st291;
st291:
	if ( ++p == pe )
		goto _test_eof291;
case 291:
#line 1391 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr361;
		case 45: goto tr361;
		case 90: goto tr363;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr364;
	goto st0;
tr364:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st292;
st292:
	if ( ++p == pe )
		goto _test_eof292;
case 292:
#line 1411 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr361;
		case 45: goto tr361;
		case 90: goto tr363;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr365;
	goto st0;
tr365:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st293;
st293:
	if ( ++p == pe )
		goto _test_eof293;
case 293:
#line 1431 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr361;
		case 45: goto tr361;
		case 90: goto tr363;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr366;
	goto st0;
tr366:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st294;
st294:
	if ( ++p == pe )
		goto _test_eof294;
case 294:
#line 1451 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr361;
		case 45: goto tr361;
		case 90: goto tr363;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr367;
	goto st0;
tr367:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st295;
st295:
	if ( ++p == pe )
		goto _test_eof295;
case 295:
#line 1471 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr361;
		case 45: goto tr361;
		case 90: goto tr363;
	}
	goto st0;
tr356:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st296;
tr360:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st296;
tr363:
#line 31 "src/panda/date/parse-date.rl"
	{
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
	goto st296;
st296:
	if ( ++p == pe )
		goto _test_eof296;
case 296:
#line 1505 "src/panda/date/parse-date.cc"
	goto st0;
tr353:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st88;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
#line 1515 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr119;
	goto st0;
tr119:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st89;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
#line 1530 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr120;
	goto st0;
tr120:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st297;
st297:
	if ( ++p == pe )
		goto _test_eof297;
case 297:
#line 1545 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr368;
		case 45: goto tr368;
		case 58: goto tr369;
		case 90: goto tr370;
	}
	goto st0;
tr373:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st90;
tr376:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st90;
tr379:
#line 31 "src/panda/date/parse-date.rl"
	{
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st90;
tr368:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
#line 48 "src/panda/date/parse-date.rl"
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
	goto st90;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
#line 1628 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr121;
	goto st0;
tr121:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st91;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
#line 1643 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr122;
	goto st0;
tr122:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st298;
st298:
	if ( ++p == pe )
		goto _test_eof298;
case 298:
#line 1658 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr372;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr371;
	goto st0;
tr124:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st92;
tr371:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st92;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
#line 1687 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr123;
	goto st0;
tr123:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st299;
st299:
	if ( ++p == pe )
		goto _test_eof299;
case 299:
#line 1702 "src/panda/date/parse-date.cc"
	goto st0;
tr372:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
	goto st93;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
#line 1715 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr124;
	goto st0;
tr369:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st94;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
#line 1727 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr125;
	goto st0;
tr125:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st95;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
#line 1742 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr126;
	goto st0;
tr126:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st300;
st300:
	if ( ++p == pe )
		goto _test_eof300;
case 300:
#line 1757 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr373;
		case 45: goto tr373;
		case 58: goto tr374;
		case 90: goto tr375;
	}
	goto st0;
tr374:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st96;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
#line 1773 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr127;
	goto st0;
tr127:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st97;
tr389:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st97;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
#line 1797 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr128;
	goto st0;
tr128:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st301;
st301:
	if ( ++p == pe )
		goto _test_eof301;
case 301:
#line 1812 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 44: goto tr377;
		case 46: goto tr377;
		case 90: goto tr378;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr376;
	goto st0;
tr377:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st98;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
#line 1829 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr129;
	goto st0;
tr129:
#line 27 "src/panda/date/parse-date.rl"
	{
        mksec_ptr = p;
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st302;
st302:
	if ( ++p == pe )
		goto _test_eof302;
case 302:
#line 1848 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr379;
		case 45: goto tr379;
		case 90: goto tr381;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr380;
	goto st0;
tr380:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st303;
st303:
	if ( ++p == pe )
		goto _test_eof303;
case 303:
#line 1868 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr379;
		case 45: goto tr379;
		case 90: goto tr381;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr382;
	goto st0;
tr382:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st304;
st304:
	if ( ++p == pe )
		goto _test_eof304;
case 304:
#line 1888 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr379;
		case 45: goto tr379;
		case 90: goto tr381;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr383;
	goto st0;
tr383:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st305;
st305:
	if ( ++p == pe )
		goto _test_eof305;
case 305:
#line 1908 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr379;
		case 45: goto tr379;
		case 90: goto tr381;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr384;
	goto st0;
tr384:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st306;
st306:
	if ( ++p == pe )
		goto _test_eof306;
case 306:
#line 1928 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr379;
		case 45: goto tr379;
		case 90: goto tr381;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr385;
	goto st0;
tr385:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st307;
st307:
	if ( ++p == pe )
		goto _test_eof307;
case 307:
#line 1948 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr379;
		case 45: goto tr379;
		case 90: goto tr381;
	}
	goto st0;
tr370:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st308;
tr375:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st308;
tr378:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st308;
tr381:
#line 31 "src/panda/date/parse-date.rl"
	{
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
	goto st308;
st308:
	if ( ++p == pe )
		goto _test_eof308;
case 308:
#line 1986 "src/panda/date/parse-date.cc"
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr130;
	goto st0;
tr130:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st100;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
#line 2006 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr131;
	goto st0;
tr131:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st309;
st309:
	if ( ++p == pe )
		goto _test_eof309;
case 309:
#line 2021 "src/panda/date/parse-date.cc"
	if ( (*p) == 45 )
		goto tr386;
	goto st0;
tr386:
#line 74 "src/panda/date/parse-date.rl"
	{ NSAVE(week); }
	goto st101;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
#line 2033 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr132;
	goto st0;
tr132:
#line 75 "src/panda/date/parse-date.rl"
	{ _date.wday = *p - '0'; }
	goto st310;
st310:
	if ( ++p == pe )
		goto _test_eof310;
case 310:
#line 2045 "src/panda/date/parse-date.cc"
	goto st0;
tr100:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st102;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
#line 2055 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr133;
	goto st0;
tr133:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st103;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
#line 2070 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr134;
	goto st0;
tr134:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st104;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
#line 2085 "src/panda/date/parse-date.cc"
	if ( (*p) == 47 )
		goto tr135;
	goto st0;
tr135:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st105;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
#line 2097 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr136;
	goto st0;
tr136:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st106;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
#line 2112 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr137;
	goto st0;
tr137:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st311;
st311:
	if ( ++p == pe )
		goto _test_eof311;
case 311:
#line 2127 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr352;
	goto st0;
tr101:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st107;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
#line 2144 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr138;
	goto st0;
tr138:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st108;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
#line 2159 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr139;
	goto st0;
tr139:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st109;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
#line 2176 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr140;
	goto st0;
tr140:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st312;
st312:
	if ( ++p == pe )
		goto _test_eof312;
case 312:
#line 2191 "src/panda/date/parse-date.cc"
	if ( (*p) == 84 )
		goto tr387;
	goto st0;
tr387:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st110;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
#line 2203 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr141;
	goto st0;
tr141:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st111;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
#line 2218 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr142;
	goto st0;
tr142:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st313;
st313:
	if ( ++p == pe )
		goto _test_eof313;
case 313:
#line 2233 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr368;
		case 45: goto tr368;
		case 90: goto tr370;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr388;
	goto st0;
tr388:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st112;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
#line 2255 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr143;
	goto st0;
tr143:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st314;
st314:
	if ( ++p == pe )
		goto _test_eof314;
case 314:
#line 2270 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr373;
		case 45: goto tr373;
		case 90: goto tr375;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr389;
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	if ( (*p) == 114 )
		goto st114;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	if ( (*p) == 105 )
		goto st115;
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	switch( (*p) ) {
		case 32: goto tr146;
		case 44: goto tr147;
		case 100: goto st167;
	}
	goto st0;
tr146:
#line 114 "src/panda/date/parse-date.rl"
	{ _date.wday = 5; }
	goto st116;
tr296:
#line 110 "src/panda/date/parse-date.rl"
	{ _date.wday = 1; }
	goto st116;
tr305:
#line 115 "src/panda/date/parse-date.rl"
	{ _date.wday = 6; }
	goto st116;
tr314:
#line 116 "src/panda/date/parse-date.rl"
	{ _date.wday = 0; }
	goto st116;
tr323:
#line 113 "src/panda/date/parse-date.rl"
	{ _date.wday = 4; }
	goto st116;
tr332:
#line 111 "src/panda/date/parse-date.rl"
	{ _date.wday = 2; }
	goto st116;
tr341:
#line 112 "src/panda/date/parse-date.rl"
	{ _date.wday = 3; }
	goto st116;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
#line 2335 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st117;
		case 68: goto st138;
		case 70: goto st141;
		case 74: goto st144;
		case 77: goto st150;
		case 78: goto st154;
		case 79: goto st157;
		case 83: goto st160;
	}
	goto st0;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	switch( (*p) ) {
		case 112: goto st118;
		case 117: goto st136;
	}
	goto st0;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	if ( (*p) == 114 )
		goto st119;
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	if ( (*p) == 32 )
		goto tr160;
	goto st0;
tr160:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st120;
tr179:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st120;
tr182:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st120;
tr185:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st120;
tr189:
#line 97 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st120;
tr192:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st120;
tr193:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st120;
tr197:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st120;
tr198:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st120;
tr201:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st120;
tr204:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st120;
tr207:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st120;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
#line 2422 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto st121;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr162;
	goto st0;
tr162:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st121;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
#line 2439 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr163;
	goto st0;
tr163:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st122;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
#line 2454 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr164;
	goto st0;
tr164:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st123;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
#line 2466 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr165;
	goto st0;
tr165:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st124;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
#line 2481 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr166;
	goto st0;
tr166:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st125;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
#line 2496 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr167;
	goto st0;
tr167:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st126;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
#line 2508 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr168;
	goto st0;
tr168:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st127;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
#line 2523 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr169;
	goto st0;
tr169:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st128;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
#line 2538 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr170;
	goto st0;
tr170:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st129;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
#line 2550 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr171;
	goto st0;
tr171:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st130;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
#line 2565 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr172;
	goto st0;
tr172:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st131;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
#line 2580 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr173;
	goto st0;
tr173:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st132;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
#line 2592 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr174;
	goto st0;
tr174:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st133;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
#line 2607 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr175;
	goto st0;
tr175:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st134;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
#line 2622 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr176;
	goto st0;
tr176:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st135;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
#line 2637 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr177;
	goto st0;
tr177:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st315;
st315:
	if ( ++p == pe )
		goto _test_eof315;
case 315:
#line 2652 "src/panda/date/parse-date.cc"
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	if ( (*p) == 103 )
		goto st137;
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	if ( (*p) == 32 )
		goto tr179;
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	if ( (*p) == 101 )
		goto st139;
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	if ( (*p) == 99 )
		goto st140;
	goto st0;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	if ( (*p) == 32 )
		goto tr182;
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	if ( (*p) == 101 )
		goto st142;
	goto st0;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	if ( (*p) == 98 )
		goto st143;
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	if ( (*p) == 32 )
		goto tr185;
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	switch( (*p) ) {
		case 97: goto st145;
		case 117: goto st147;
	}
	goto st0;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	if ( (*p) == 110 )
		goto st146;
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	if ( (*p) == 32 )
		goto tr189;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	switch( (*p) ) {
		case 108: goto st148;
		case 110: goto st149;
	}
	goto st0;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	if ( (*p) == 32 )
		goto tr192;
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	if ( (*p) == 32 )
		goto tr193;
	goto st0;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	if ( (*p) == 97 )
		goto st151;
	goto st0;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	switch( (*p) ) {
		case 114: goto st152;
		case 121: goto st153;
	}
	goto st0;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	if ( (*p) == 32 )
		goto tr197;
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	if ( (*p) == 32 )
		goto tr198;
	goto st0;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	if ( (*p) == 111 )
		goto st155;
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	if ( (*p) == 118 )
		goto st156;
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	if ( (*p) == 32 )
		goto tr201;
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
		goto st159;
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	if ( (*p) == 32 )
		goto tr204;
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
	if ( (*p) == 112 )
		goto st162;
	goto st0;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	if ( (*p) == 32 )
		goto tr207;
	goto st0;
tr147:
#line 114 "src/panda/date/parse-date.rl"
	{ _date.wday = 5; }
	goto st163;
tr297:
#line 110 "src/panda/date/parse-date.rl"
	{ _date.wday = 1; }
	goto st163;
tr306:
#line 115 "src/panda/date/parse-date.rl"
	{ _date.wday = 6; }
	goto st163;
tr315:
#line 116 "src/panda/date/parse-date.rl"
	{ _date.wday = 0; }
	goto st163;
tr324:
#line 113 "src/panda/date/parse-date.rl"
	{ _date.wday = 4; }
	goto st163;
tr333:
#line 111 "src/panda/date/parse-date.rl"
	{ _date.wday = 2; }
	goto st163;
tr342:
#line 112 "src/panda/date/parse-date.rl"
	{ _date.wday = 3; }
	goto st163;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
#line 2881 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto st164;
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr209;
	goto st0;
tr209:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st165;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
#line 2903 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr210;
	goto st0;
tr210:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st166;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
#line 2918 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr8;
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	if ( (*p) == 97 )
		goto st168;
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	if ( (*p) == 121 )
		goto st169;
	goto st0;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
	if ( (*p) == 44 )
		goto tr213;
	goto st0;
tr213:
#line 122 "src/panda/date/parse-date.rl"
	{ _date.wday = 5; }
	goto st170;
tr301:
#line 118 "src/panda/date/parse-date.rl"
	{ _date.wday = 1; }
	goto st170;
tr312:
#line 123 "src/panda/date/parse-date.rl"
	{ _date.wday = 6; }
	goto st170;
tr319:
#line 124 "src/panda/date/parse-date.rl"
	{ _date.wday = 0; }
	goto st170;
tr330:
#line 121 "src/panda/date/parse-date.rl"
	{ _date.wday = 4; }
	goto st170;
tr338:
#line 119 "src/panda/date/parse-date.rl"
	{ _date.wday = 2; }
	goto st170;
tr349:
#line 120 "src/panda/date/parse-date.rl"
	{ _date.wday = 3; }
	goto st170;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
#line 2975 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto st171;
	goto st0;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr215;
	goto st0;
tr215:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st172;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
#line 2997 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr216;
	goto st0;
tr216:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st173;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
#line 3012 "src/panda/date/parse-date.cc"
	if ( (*p) == 45 )
		goto tr217;
	goto st0;
tr217:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st174;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
#line 3024 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st175;
		case 68: goto st206;
		case 70: goto st209;
		case 74: goto st212;
		case 77: goto st218;
		case 78: goto st222;
		case 79: goto st225;
		case 83: goto st228;
	}
	goto st0;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
	switch( (*p) ) {
		case 112: goto st176;
		case 117: goto st204;
	}
	goto st0;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
	if ( (*p) == 114 )
		goto st177;
	goto st0;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
	if ( (*p) == 45 )
		goto tr229;
	goto st0;
tr229:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st178;
tr265:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st178;
tr268:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st178;
tr271:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st178;
tr275:
#line 97 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st178;
tr278:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st178;
tr279:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st178;
tr283:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st178;
tr284:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st178;
tr287:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st178;
tr290:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st178;
tr293:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st178;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
#line 3111 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr230;
	goto st0;
tr230:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st179;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
#line 3126 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr231;
	goto st0;
tr231:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st180;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
#line 3141 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr232;
	goto st0;
tr232:
#line 21 "src/panda/date/parse-date.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
	goto st181;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
#line 3157 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr233;
	goto st0;
tr233:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st182;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
#line 3172 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr234;
	goto st0;
tr234:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st183;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
#line 3187 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr235;
	goto st0;
tr235:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st184;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
#line 3199 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr236;
	goto st0;
tr236:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st185;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
#line 3214 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr237;
	goto st0;
tr237:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st186;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
#line 3229 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr238;
	goto st0;
tr238:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st187;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
#line 3241 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr239;
	goto st0;
tr239:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st188;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
#line 3256 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr240;
	goto st0;
tr240:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st189;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
#line 3271 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr241;
	goto st0;
tr241:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st190;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
#line 3283 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr242;
		case 45: goto tr242;
		case 65: goto st317;
		case 67: goto st195;
		case 69: goto st197;
		case 71: goto st199;
		case 77: goto st321;
		case 78: goto st323;
		case 80: goto st202;
		case 85: goto st200;
		case 89: goto st325;
		case 90: goto st320;
	}
	goto st0;
tr242:
#line 48 "src/panda/date/parse-date.rl"
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
	goto st191;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
#line 3316 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr253;
	goto st0;
tr253:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st192;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
#line 3331 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr254;
	goto st0;
tr254:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st193;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
#line 3346 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr255;
	goto st0;
tr255:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st194;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
#line 3366 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr256;
	goto st0;
tr256:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st316;
st316:
	if ( ++p == pe )
		goto _test_eof316;
case 316:
#line 3381 "src/panda/date/parse-date.cc"
	goto st0;
st317:
	if ( ++p == pe )
		goto _test_eof317;
case 317:
	goto st0;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
	switch( (*p) ) {
		case 68: goto st196;
		case 83: goto st196;
	}
	goto st0;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
	if ( (*p) == 84 )
		goto st318;
	goto st0;
st318:
	if ( ++p == pe )
		goto _test_eof318;
case 318:
	goto st0;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
	switch( (*p) ) {
		case 68: goto st198;
		case 83: goto st198;
	}
	goto st0;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
	if ( (*p) == 84 )
		goto st319;
	goto st0;
st319:
	if ( ++p == pe )
		goto _test_eof319;
case 319:
	goto st0;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
	if ( (*p) == 77 )
		goto st200;
	goto st0;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
	if ( (*p) == 84 )
		goto st320;
	goto st0;
st320:
	if ( ++p == pe )
		goto _test_eof320;
case 320:
	goto st0;
st321:
	if ( ++p == pe )
		goto _test_eof321;
case 321:
	switch( (*p) ) {
		case 68: goto st201;
		case 83: goto st201;
	}
	goto st0;
st201:
	if ( ++p == pe )
		goto _test_eof201;
case 201:
	if ( (*p) == 84 )
		goto st322;
	goto st0;
st322:
	if ( ++p == pe )
		goto _test_eof322;
case 322:
	goto st0;
st323:
	if ( ++p == pe )
		goto _test_eof323;
case 323:
	goto st0;
st202:
	if ( ++p == pe )
		goto _test_eof202;
case 202:
	switch( (*p) ) {
		case 68: goto st203;
		case 83: goto st203;
	}
	goto st0;
st203:
	if ( ++p == pe )
		goto _test_eof203;
case 203:
	if ( (*p) == 84 )
		goto st324;
	goto st0;
st324:
	if ( ++p == pe )
		goto _test_eof324;
case 324:
	goto st0;
st325:
	if ( ++p == pe )
		goto _test_eof325;
case 325:
	goto st0;
st204:
	if ( ++p == pe )
		goto _test_eof204;
case 204:
	if ( (*p) == 103 )
		goto st205;
	goto st0;
st205:
	if ( ++p == pe )
		goto _test_eof205;
case 205:
	if ( (*p) == 45 )
		goto tr265;
	goto st0;
st206:
	if ( ++p == pe )
		goto _test_eof206;
case 206:
	if ( (*p) == 101 )
		goto st207;
	goto st0;
st207:
	if ( ++p == pe )
		goto _test_eof207;
case 207:
	if ( (*p) == 99 )
		goto st208;
	goto st0;
st208:
	if ( ++p == pe )
		goto _test_eof208;
case 208:
	if ( (*p) == 45 )
		goto tr268;
	goto st0;
st209:
	if ( ++p == pe )
		goto _test_eof209;
case 209:
	if ( (*p) == 101 )
		goto st210;
	goto st0;
st210:
	if ( ++p == pe )
		goto _test_eof210;
case 210:
	if ( (*p) == 98 )
		goto st211;
	goto st0;
st211:
	if ( ++p == pe )
		goto _test_eof211;
case 211:
	if ( (*p) == 45 )
		goto tr271;
	goto st0;
st212:
	if ( ++p == pe )
		goto _test_eof212;
case 212:
	switch( (*p) ) {
		case 97: goto st213;
		case 117: goto st215;
	}
	goto st0;
st213:
	if ( ++p == pe )
		goto _test_eof213;
case 213:
	if ( (*p) == 110 )
		goto st214;
	goto st0;
st214:
	if ( ++p == pe )
		goto _test_eof214;
case 214:
	if ( (*p) == 45 )
		goto tr275;
	goto st0;
st215:
	if ( ++p == pe )
		goto _test_eof215;
case 215:
	switch( (*p) ) {
		case 108: goto st216;
		case 110: goto st217;
	}
	goto st0;
st216:
	if ( ++p == pe )
		goto _test_eof216;
case 216:
	if ( (*p) == 45 )
		goto tr278;
	goto st0;
st217:
	if ( ++p == pe )
		goto _test_eof217;
case 217:
	if ( (*p) == 45 )
		goto tr279;
	goto st0;
st218:
	if ( ++p == pe )
		goto _test_eof218;
case 218:
	if ( (*p) == 97 )
		goto st219;
	goto st0;
st219:
	if ( ++p == pe )
		goto _test_eof219;
case 219:
	switch( (*p) ) {
		case 114: goto st220;
		case 121: goto st221;
	}
	goto st0;
st220:
	if ( ++p == pe )
		goto _test_eof220;
case 220:
	if ( (*p) == 45 )
		goto tr283;
	goto st0;
st221:
	if ( ++p == pe )
		goto _test_eof221;
case 221:
	if ( (*p) == 45 )
		goto tr284;
	goto st0;
st222:
	if ( ++p == pe )
		goto _test_eof222;
case 222:
	if ( (*p) == 111 )
		goto st223;
	goto st0;
st223:
	if ( ++p == pe )
		goto _test_eof223;
case 223:
	if ( (*p) == 118 )
		goto st224;
	goto st0;
st224:
	if ( ++p == pe )
		goto _test_eof224;
case 224:
	if ( (*p) == 45 )
		goto tr287;
	goto st0;
st225:
	if ( ++p == pe )
		goto _test_eof225;
case 225:
	if ( (*p) == 99 )
		goto st226;
	goto st0;
st226:
	if ( ++p == pe )
		goto _test_eof226;
case 226:
	if ( (*p) == 116 )
		goto st227;
	goto st0;
st227:
	if ( ++p == pe )
		goto _test_eof227;
case 227:
	if ( (*p) == 45 )
		goto tr290;
	goto st0;
st228:
	if ( ++p == pe )
		goto _test_eof228;
case 228:
	if ( (*p) == 101 )
		goto st229;
	goto st0;
st229:
	if ( ++p == pe )
		goto _test_eof229;
case 229:
	if ( (*p) == 112 )
		goto st230;
	goto st0;
st230:
	if ( ++p == pe )
		goto _test_eof230;
case 230:
	if ( (*p) == 45 )
		goto tr293;
	goto st0;
st231:
	if ( ++p == pe )
		goto _test_eof231;
case 231:
	if ( (*p) == 111 )
		goto st232;
	goto st0;
st232:
	if ( ++p == pe )
		goto _test_eof232;
case 232:
	if ( (*p) == 110 )
		goto st233;
	goto st0;
st233:
	if ( ++p == pe )
		goto _test_eof233;
case 233:
	switch( (*p) ) {
		case 32: goto tr296;
		case 44: goto tr297;
		case 100: goto st234;
	}
	goto st0;
st234:
	if ( ++p == pe )
		goto _test_eof234;
case 234:
	if ( (*p) == 97 )
		goto st235;
	goto st0;
st235:
	if ( ++p == pe )
		goto _test_eof235;
case 235:
	if ( (*p) == 121 )
		goto st236;
	goto st0;
st236:
	if ( ++p == pe )
		goto _test_eof236;
case 236:
	if ( (*p) == 44 )
		goto tr301;
	goto st0;
st237:
	if ( ++p == pe )
		goto _test_eof237;
case 237:
	switch( (*p) ) {
		case 97: goto st238;
		case 117: goto st245;
	}
	goto st0;
st238:
	if ( ++p == pe )
		goto _test_eof238;
case 238:
	if ( (*p) == 116 )
		goto st239;
	goto st0;
st239:
	if ( ++p == pe )
		goto _test_eof239;
case 239:
	switch( (*p) ) {
		case 32: goto tr305;
		case 44: goto tr306;
		case 117: goto st240;
	}
	goto st0;
st240:
	if ( ++p == pe )
		goto _test_eof240;
case 240:
	if ( (*p) == 114 )
		goto st241;
	goto st0;
st241:
	if ( ++p == pe )
		goto _test_eof241;
case 241:
	if ( (*p) == 100 )
		goto st242;
	goto st0;
st242:
	if ( ++p == pe )
		goto _test_eof242;
case 242:
	if ( (*p) == 97 )
		goto st243;
	goto st0;
st243:
	if ( ++p == pe )
		goto _test_eof243;
case 243:
	if ( (*p) == 121 )
		goto st244;
	goto st0;
st244:
	if ( ++p == pe )
		goto _test_eof244;
case 244:
	if ( (*p) == 44 )
		goto tr312;
	goto st0;
st245:
	if ( ++p == pe )
		goto _test_eof245;
case 245:
	if ( (*p) == 110 )
		goto st246;
	goto st0;
st246:
	if ( ++p == pe )
		goto _test_eof246;
case 246:
	switch( (*p) ) {
		case 32: goto tr314;
		case 44: goto tr315;
		case 100: goto st247;
	}
	goto st0;
st247:
	if ( ++p == pe )
		goto _test_eof247;
case 247:
	if ( (*p) == 97 )
		goto st248;
	goto st0;
st248:
	if ( ++p == pe )
		goto _test_eof248;
case 248:
	if ( (*p) == 121 )
		goto st249;
	goto st0;
st249:
	if ( ++p == pe )
		goto _test_eof249;
case 249:
	if ( (*p) == 44 )
		goto tr319;
	goto st0;
st250:
	if ( ++p == pe )
		goto _test_eof250;
case 250:
	switch( (*p) ) {
		case 104: goto st251;
		case 117: goto st258;
	}
	goto st0;
st251:
	if ( ++p == pe )
		goto _test_eof251;
case 251:
	if ( (*p) == 117 )
		goto st252;
	goto st0;
st252:
	if ( ++p == pe )
		goto _test_eof252;
case 252:
	switch( (*p) ) {
		case 32: goto tr323;
		case 44: goto tr324;
		case 114: goto st253;
	}
	goto st0;
st253:
	if ( ++p == pe )
		goto _test_eof253;
case 253:
	if ( (*p) == 115 )
		goto st254;
	goto st0;
st254:
	if ( ++p == pe )
		goto _test_eof254;
case 254:
	if ( (*p) == 100 )
		goto st255;
	goto st0;
st255:
	if ( ++p == pe )
		goto _test_eof255;
case 255:
	if ( (*p) == 97 )
		goto st256;
	goto st0;
st256:
	if ( ++p == pe )
		goto _test_eof256;
case 256:
	if ( (*p) == 121 )
		goto st257;
	goto st0;
st257:
	if ( ++p == pe )
		goto _test_eof257;
case 257:
	if ( (*p) == 44 )
		goto tr330;
	goto st0;
st258:
	if ( ++p == pe )
		goto _test_eof258;
case 258:
	if ( (*p) == 101 )
		goto st259;
	goto st0;
st259:
	if ( ++p == pe )
		goto _test_eof259;
case 259:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 115: goto st260;
	}
	goto st0;
st260:
	if ( ++p == pe )
		goto _test_eof260;
case 260:
	if ( (*p) == 100 )
		goto st261;
	goto st0;
st261:
	if ( ++p == pe )
		goto _test_eof261;
case 261:
	if ( (*p) == 97 )
		goto st262;
	goto st0;
st262:
	if ( ++p == pe )
		goto _test_eof262;
case 262:
	if ( (*p) == 121 )
		goto st263;
	goto st0;
st263:
	if ( ++p == pe )
		goto _test_eof263;
case 263:
	if ( (*p) == 44 )
		goto tr338;
	goto st0;
st264:
	if ( ++p == pe )
		goto _test_eof264;
case 264:
	if ( (*p) == 101 )
		goto st265;
	goto st0;
st265:
	if ( ++p == pe )
		goto _test_eof265;
case 265:
	if ( (*p) == 100 )
		goto st266;
	goto st0;
st266:
	if ( ++p == pe )
		goto _test_eof266;
case 266:
	switch( (*p) ) {
		case 32: goto tr341;
		case 44: goto tr342;
		case 110: goto st267;
	}
	goto st0;
st267:
	if ( ++p == pe )
		goto _test_eof267;
case 267:
	if ( (*p) == 101 )
		goto st268;
	goto st0;
st268:
	if ( ++p == pe )
		goto _test_eof268;
case 268:
	if ( (*p) == 115 )
		goto st269;
	goto st0;
st269:
	if ( ++p == pe )
		goto _test_eof269;
case 269:
	if ( (*p) == 100 )
		goto st270;
	goto st0;
st270:
	if ( ++p == pe )
		goto _test_eof270;
case 270:
	if ( (*p) == 97 )
		goto st271;
	goto st0;
st271:
	if ( ++p == pe )
		goto _test_eof271;
case 271:
	if ( (*p) == 121 )
		goto st272;
	goto st0;
st272:
	if ( ++p == pe )
		goto _test_eof272;
case 272:
	if ( (*p) == 44 )
		goto tr349;
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof273: cs = 273; goto _test_eof; 
	_test_eof274: cs = 274; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof275: cs = 275; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof276: cs = 276; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof277: cs = 277; goto _test_eof; 
	_test_eof278: cs = 278; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof279: cs = 279; goto _test_eof; 
	_test_eof280: cs = 280; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof281: cs = 281; goto _test_eof; 
	_test_eof282: cs = 282; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof48: cs = 48; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof58: cs = 58; goto _test_eof; 
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
	_test_eof283: cs = 283; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof284: cs = 284; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof75: cs = 75; goto _test_eof; 
	_test_eof285: cs = 285; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof77: cs = 77; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof80: cs = 80; goto _test_eof; 
	_test_eof286: cs = 286; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof82: cs = 82; goto _test_eof; 
	_test_eof287: cs = 287; goto _test_eof; 
	_test_eof83: cs = 83; goto _test_eof; 
	_test_eof84: cs = 84; goto _test_eof; 
	_test_eof288: cs = 288; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
	_test_eof86: cs = 86; goto _test_eof; 
	_test_eof289: cs = 289; goto _test_eof; 
	_test_eof87: cs = 87; goto _test_eof; 
	_test_eof290: cs = 290; goto _test_eof; 
	_test_eof291: cs = 291; goto _test_eof; 
	_test_eof292: cs = 292; goto _test_eof; 
	_test_eof293: cs = 293; goto _test_eof; 
	_test_eof294: cs = 294; goto _test_eof; 
	_test_eof295: cs = 295; goto _test_eof; 
	_test_eof296: cs = 296; goto _test_eof; 
	_test_eof88: cs = 88; goto _test_eof; 
	_test_eof89: cs = 89; goto _test_eof; 
	_test_eof297: cs = 297; goto _test_eof; 
	_test_eof90: cs = 90; goto _test_eof; 
	_test_eof91: cs = 91; goto _test_eof; 
	_test_eof298: cs = 298; goto _test_eof; 
	_test_eof92: cs = 92; goto _test_eof; 
	_test_eof299: cs = 299; goto _test_eof; 
	_test_eof93: cs = 93; goto _test_eof; 
	_test_eof94: cs = 94; goto _test_eof; 
	_test_eof95: cs = 95; goto _test_eof; 
	_test_eof300: cs = 300; goto _test_eof; 
	_test_eof96: cs = 96; goto _test_eof; 
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof301: cs = 301; goto _test_eof; 
	_test_eof98: cs = 98; goto _test_eof; 
	_test_eof302: cs = 302; goto _test_eof; 
	_test_eof303: cs = 303; goto _test_eof; 
	_test_eof304: cs = 304; goto _test_eof; 
	_test_eof305: cs = 305; goto _test_eof; 
	_test_eof306: cs = 306; goto _test_eof; 
	_test_eof307: cs = 307; goto _test_eof; 
	_test_eof308: cs = 308; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof309: cs = 309; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof310: cs = 310; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof311: cs = 311; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof108: cs = 108; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof312: cs = 312; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof313: cs = 313; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
	_test_eof314: cs = 314; goto _test_eof; 
	_test_eof113: cs = 113; goto _test_eof; 
	_test_eof114: cs = 114; goto _test_eof; 
	_test_eof115: cs = 115; goto _test_eof; 
	_test_eof116: cs = 116; goto _test_eof; 
	_test_eof117: cs = 117; goto _test_eof; 
	_test_eof118: cs = 118; goto _test_eof; 
	_test_eof119: cs = 119; goto _test_eof; 
	_test_eof120: cs = 120; goto _test_eof; 
	_test_eof121: cs = 121; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
	_test_eof123: cs = 123; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
	_test_eof126: cs = 126; goto _test_eof; 
	_test_eof127: cs = 127; goto _test_eof; 
	_test_eof128: cs = 128; goto _test_eof; 
	_test_eof129: cs = 129; goto _test_eof; 
	_test_eof130: cs = 130; goto _test_eof; 
	_test_eof131: cs = 131; goto _test_eof; 
	_test_eof132: cs = 132; goto _test_eof; 
	_test_eof133: cs = 133; goto _test_eof; 
	_test_eof134: cs = 134; goto _test_eof; 
	_test_eof135: cs = 135; goto _test_eof; 
	_test_eof315: cs = 315; goto _test_eof; 
	_test_eof136: cs = 136; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof149: cs = 149; goto _test_eof; 
	_test_eof150: cs = 150; goto _test_eof; 
	_test_eof151: cs = 151; goto _test_eof; 
	_test_eof152: cs = 152; goto _test_eof; 
	_test_eof153: cs = 153; goto _test_eof; 
	_test_eof154: cs = 154; goto _test_eof; 
	_test_eof155: cs = 155; goto _test_eof; 
	_test_eof156: cs = 156; goto _test_eof; 
	_test_eof157: cs = 157; goto _test_eof; 
	_test_eof158: cs = 158; goto _test_eof; 
	_test_eof159: cs = 159; goto _test_eof; 
	_test_eof160: cs = 160; goto _test_eof; 
	_test_eof161: cs = 161; goto _test_eof; 
	_test_eof162: cs = 162; goto _test_eof; 
	_test_eof163: cs = 163; goto _test_eof; 
	_test_eof164: cs = 164; goto _test_eof; 
	_test_eof165: cs = 165; goto _test_eof; 
	_test_eof166: cs = 166; goto _test_eof; 
	_test_eof167: cs = 167; goto _test_eof; 
	_test_eof168: cs = 168; goto _test_eof; 
	_test_eof169: cs = 169; goto _test_eof; 
	_test_eof170: cs = 170; goto _test_eof; 
	_test_eof171: cs = 171; goto _test_eof; 
	_test_eof172: cs = 172; goto _test_eof; 
	_test_eof173: cs = 173; goto _test_eof; 
	_test_eof174: cs = 174; goto _test_eof; 
	_test_eof175: cs = 175; goto _test_eof; 
	_test_eof176: cs = 176; goto _test_eof; 
	_test_eof177: cs = 177; goto _test_eof; 
	_test_eof178: cs = 178; goto _test_eof; 
	_test_eof179: cs = 179; goto _test_eof; 
	_test_eof180: cs = 180; goto _test_eof; 
	_test_eof181: cs = 181; goto _test_eof; 
	_test_eof182: cs = 182; goto _test_eof; 
	_test_eof183: cs = 183; goto _test_eof; 
	_test_eof184: cs = 184; goto _test_eof; 
	_test_eof185: cs = 185; goto _test_eof; 
	_test_eof186: cs = 186; goto _test_eof; 
	_test_eof187: cs = 187; goto _test_eof; 
	_test_eof188: cs = 188; goto _test_eof; 
	_test_eof189: cs = 189; goto _test_eof; 
	_test_eof190: cs = 190; goto _test_eof; 
	_test_eof191: cs = 191; goto _test_eof; 
	_test_eof192: cs = 192; goto _test_eof; 
	_test_eof193: cs = 193; goto _test_eof; 
	_test_eof194: cs = 194; goto _test_eof; 
	_test_eof316: cs = 316; goto _test_eof; 
	_test_eof317: cs = 317; goto _test_eof; 
	_test_eof195: cs = 195; goto _test_eof; 
	_test_eof196: cs = 196; goto _test_eof; 
	_test_eof318: cs = 318; goto _test_eof; 
	_test_eof197: cs = 197; goto _test_eof; 
	_test_eof198: cs = 198; goto _test_eof; 
	_test_eof319: cs = 319; goto _test_eof; 
	_test_eof199: cs = 199; goto _test_eof; 
	_test_eof200: cs = 200; goto _test_eof; 
	_test_eof320: cs = 320; goto _test_eof; 
	_test_eof321: cs = 321; goto _test_eof; 
	_test_eof201: cs = 201; goto _test_eof; 
	_test_eof322: cs = 322; goto _test_eof; 
	_test_eof323: cs = 323; goto _test_eof; 
	_test_eof202: cs = 202; goto _test_eof; 
	_test_eof203: cs = 203; goto _test_eof; 
	_test_eof324: cs = 324; goto _test_eof; 
	_test_eof325: cs = 325; goto _test_eof; 
	_test_eof204: cs = 204; goto _test_eof; 
	_test_eof205: cs = 205; goto _test_eof; 
	_test_eof206: cs = 206; goto _test_eof; 
	_test_eof207: cs = 207; goto _test_eof; 
	_test_eof208: cs = 208; goto _test_eof; 
	_test_eof209: cs = 209; goto _test_eof; 
	_test_eof210: cs = 210; goto _test_eof; 
	_test_eof211: cs = 211; goto _test_eof; 
	_test_eof212: cs = 212; goto _test_eof; 
	_test_eof213: cs = 213; goto _test_eof; 
	_test_eof214: cs = 214; goto _test_eof; 
	_test_eof215: cs = 215; goto _test_eof; 
	_test_eof216: cs = 216; goto _test_eof; 
	_test_eof217: cs = 217; goto _test_eof; 
	_test_eof218: cs = 218; goto _test_eof; 
	_test_eof219: cs = 219; goto _test_eof; 
	_test_eof220: cs = 220; goto _test_eof; 
	_test_eof221: cs = 221; goto _test_eof; 
	_test_eof222: cs = 222; goto _test_eof; 
	_test_eof223: cs = 223; goto _test_eof; 
	_test_eof224: cs = 224; goto _test_eof; 
	_test_eof225: cs = 225; goto _test_eof; 
	_test_eof226: cs = 226; goto _test_eof; 
	_test_eof227: cs = 227; goto _test_eof; 
	_test_eof228: cs = 228; goto _test_eof; 
	_test_eof229: cs = 229; goto _test_eof; 
	_test_eof230: cs = 230; goto _test_eof; 
	_test_eof231: cs = 231; goto _test_eof; 
	_test_eof232: cs = 232; goto _test_eof; 
	_test_eof233: cs = 233; goto _test_eof; 
	_test_eof234: cs = 234; goto _test_eof; 
	_test_eof235: cs = 235; goto _test_eof; 
	_test_eof236: cs = 236; goto _test_eof; 
	_test_eof237: cs = 237; goto _test_eof; 
	_test_eof238: cs = 238; goto _test_eof; 
	_test_eof239: cs = 239; goto _test_eof; 
	_test_eof240: cs = 240; goto _test_eof; 
	_test_eof241: cs = 241; goto _test_eof; 
	_test_eof242: cs = 242; goto _test_eof; 
	_test_eof243: cs = 243; goto _test_eof; 
	_test_eof244: cs = 244; goto _test_eof; 
	_test_eof245: cs = 245; goto _test_eof; 
	_test_eof246: cs = 246; goto _test_eof; 
	_test_eof247: cs = 247; goto _test_eof; 
	_test_eof248: cs = 248; goto _test_eof; 
	_test_eof249: cs = 249; goto _test_eof; 
	_test_eof250: cs = 250; goto _test_eof; 
	_test_eof251: cs = 251; goto _test_eof; 
	_test_eof252: cs = 252; goto _test_eof; 
	_test_eof253: cs = 253; goto _test_eof; 
	_test_eof254: cs = 254; goto _test_eof; 
	_test_eof255: cs = 255; goto _test_eof; 
	_test_eof256: cs = 256; goto _test_eof; 
	_test_eof257: cs = 257; goto _test_eof; 
	_test_eof258: cs = 258; goto _test_eof; 
	_test_eof259: cs = 259; goto _test_eof; 
	_test_eof260: cs = 260; goto _test_eof; 
	_test_eof261: cs = 261; goto _test_eof; 
	_test_eof262: cs = 262; goto _test_eof; 
	_test_eof263: cs = 263; goto _test_eof; 
	_test_eof264: cs = 264; goto _test_eof; 
	_test_eof265: cs = 265; goto _test_eof; 
	_test_eof266: cs = 266; goto _test_eof; 
	_test_eof267: cs = 267; goto _test_eof; 
	_test_eof268: cs = 268; goto _test_eof; 
	_test_eof269: cs = 269; goto _test_eof; 
	_test_eof270: cs = 270; goto _test_eof; 
	_test_eof271: cs = 271; goto _test_eof; 
	_test_eof272: cs = 272; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 310: 
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 289: 
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 301: 
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 286: 
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 300: 
	case 314: 
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 297: 
	case 313: 
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 311: 
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 312: 
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 284: 
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 315: 
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
#line 156 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::ansi_c; }
	break;
	case 283: 
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
#line 158 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::dot; }
	break;
	case 290: 
	case 291: 
	case 292: 
	case 293: 
	case 294: 
	case 295: 
#line 31 "src/panda/date/parse-date.rl"
	{
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 302: 
	case 303: 
	case 304: 
	case 305: 
	case 306: 
	case 307: 
#line 31 "src/panda/date/parse-date.rl"
	{
        switch (p - mksec_ptr) {
            case 1:  _mksec = acc * 100000; break;
            case 2:  _mksec = acc *  10000; break;
            case 3:  _mksec = acc *   1000; break;
            case 4:  _mksec = acc *    100; break;
            case 5:  _mksec = acc *     10; break;
            case 6:  _mksec = acc;          break;
            default: abort();
        }
        acc = 0;
    }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 287: 
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 298: 
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 288: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 299: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 273: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 316: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 296: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 308: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 277: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 320: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 309: 
#line 74 "src/panda/date/parse-date.rl"
	{ NSAVE(week); }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 276: 
#line 137 "src/panda/date/parse-date.rl"
	{ TZRULE("EST5EDT"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 319: 
#line 137 "src/panda/date/parse-date.rl"
	{ TZRULE("EST5EDT"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 275: 
#line 138 "src/panda/date/parse-date.rl"
	{ TZRULE("CST6CDT"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 318: 
#line 138 "src/panda/date/parse-date.rl"
	{ TZRULE("CST6CDT"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 279: 
#line 139 "src/panda/date/parse-date.rl"
	{ TZRULE("MST7MDT"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 322: 
#line 139 "src/panda/date/parse-date.rl"
	{ TZRULE("MST7MDT"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 281: 
#line 140 "src/panda/date/parse-date.rl"
	{ TZRULE("PST8PDT"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 324: 
#line 140 "src/panda/date/parse-date.rl"
	{ TZRULE("PST8PDT"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 274: 
#line 141 "src/panda/date/parse-date.rl"
	{ TZRULE("<-01:00>+01:00"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 317: 
#line 141 "src/panda/date/parse-date.rl"
	{ TZRULE("<-01:00>+01:00"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 278: 
#line 142 "src/panda/date/parse-date.rl"
	{ TZRULE("<-12:00>+12:00"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 321: 
#line 142 "src/panda/date/parse-date.rl"
	{ TZRULE("<-12:00>+12:00"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 280: 
#line 143 "src/panda/date/parse-date.rl"
	{ TZRULE("<+01:00>-01:00"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 323: 
#line 143 "src/panda/date/parse-date.rl"
	{ TZRULE("<+01:00>-01:00"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 282: 
#line 144 "src/panda/date/parse-date.rl"
	{ TZRULE("<+12:00>-12:00"); }
#line 148 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 325: 
#line 144 "src/panda/date/parse-date.rl"
	{ TZRULE("<+12:00>-12:00"); }
#line 152 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 285: 
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
#line 128 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
#line 134 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
#line 4652 "src/panda/date/parse-date.cc"
	}
	}

	_out: {}
	}

#line 203 "src/panda/date/parse-date.rl"

    if (cs < date_parser_first_final || !(allowed_formats & format)) {
        _error = errc::parser_error;
        return;
    }
    
    if (tzi.len) _zone = panda::time::tzget(string_view(tzi.rule, tzi.len));

    // convert from week to mday for YYYY-Wnn[-nn] format
    if (week) {
        auto days_since_christ = panda::time::christ_days(_date.year);
        int32_t beginning_weekday = days_since_christ % 7;
        if (!_date.wday) _date.wday = 1;
        if (week == 1) {
            int mday = WEEK_1_OFFSETS[beginning_weekday] + (_date.wday - 1);
            if (mday <= 0) { // was no such weekday that year
                _error = errc::out_of_range;
                return;
            }
            _date.mday = mday;
        }
        else {
            _date.mday = WEEK_2_OFFSETS[beginning_weekday] + (_date.wday - 1) + 7 * (week - 2);
        }
    }
    else if (_date.wday) { // check wday number if included in date
        if (_date.wday != panda::time::wday(_date.year, _date.mon, _date.mday)) {
            _error = errc::out_of_range;
            return;
        }
    }
}

}}
