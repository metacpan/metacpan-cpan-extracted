
#line 1 "src/panda/date/parse-date.rl"
#include "Date.h" 
#include <string.h>
#include <stdlib.h>
#include <algorithm>


#line 167 "src/panda/date/parse-date.rl"


namespace panda { namespace date {


#line 16 "src/panda/date/parse-date.cc"
static const int date_parser_start = 1;
static const int date_parser_first_final = 377;
static const int date_parser_error = 0;

static const int date_parser_en_all = 1;


#line 172 "src/panda/date/parse-date.rl"

static constexpr const int32_t WEEK_1_OFFSETS[] = {0, -1, -2, -3, 4, 3, 2};
static constexpr const int32_t WEEK_2_OFFSETS[] = {8, 7, 6, 5, 9, 10, 9};

static TimezoneSP gmt_zone;

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
		case 70: goto st163;
		case 77: goto st281;
		case 83: goto st287;
		case 84: goto st300;
		case 87: goto st314;
		case 91: goto st323;
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
#line 94 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr8;
	goto st0;
tr8:
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
#line 109 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 32: goto tr9;
		case 46: goto tr10;
		case 47: goto tr11;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr12;
	goto st0;
tr9:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 126 "src/panda/date/parse-date.cc"
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
		goto tr24;
	goto st0;
tr24:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st8;
tr64:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st8;
tr67:
#line 109 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st8;
tr70:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st8;
tr74:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st8;
tr77:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st8;
tr78:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st8;
tr82:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st8;
tr83:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st8;
tr86:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st8;
tr89:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st8;
tr92:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 213 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr25;
	goto st0;
tr25:
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
#line 228 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr26;
	goto st0;
tr26:
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
#line 243 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr27;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr28;
	goto st0;
tr27:
#line 21 "src/panda/date/parse-date.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
	goto st11;
tr62:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 265 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr29;
	goto st0;
tr29:
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
#line 280 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr30;
	goto st0;
tr30:
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
#line 295 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr31;
	goto st0;
tr31:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 307 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr32;
	goto st0;
tr32:
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
#line 322 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr33;
	goto st0;
tr33:
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
#line 337 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 32: goto tr34;
		case 58: goto tr35;
	}
	goto st0;
tr34:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st17;
tr60:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 355 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr36;
		case 45: goto tr36;
		case 65: goto st378;
		case 67: goto st22;
		case 69: goto st24;
		case 71: goto st26;
		case 77: goto st382;
		case 78: goto st384;
		case 80: goto st29;
		case 85: goto st27;
		case 89: goto st386;
		case 90: goto st381;
	}
	goto st0;
tr36:
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
#line 388 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr47;
	goto st0;
tr47:
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
#line 403 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr48;
	goto st0;
tr48:
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
#line 418 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr49;
	goto st0;
tr49:
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
#line 438 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr50;
	goto st0;
tr50:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st377;
st377:
	if ( ++p == pe )
		goto _test_eof377;
case 377:
#line 453 "src/panda/date/parse-date.cc"
	goto st0;
st378:
	if ( ++p == pe )
		goto _test_eof378;
case 378:
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
		goto st379;
	goto st0;
st379:
	if ( ++p == pe )
		goto _test_eof379;
case 379:
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
		goto st380;
	goto st0;
st380:
	if ( ++p == pe )
		goto _test_eof380;
case 380:
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
		goto st381;
	goto st0;
st381:
	if ( ++p == pe )
		goto _test_eof381;
case 381:
	goto st0;
st382:
	if ( ++p == pe )
		goto _test_eof382;
case 382:
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
		goto st383;
	goto st0;
st383:
	if ( ++p == pe )
		goto _test_eof383;
case 383:
	goto st0;
st384:
	if ( ++p == pe )
		goto _test_eof384;
case 384:
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
		goto st385;
	goto st0;
st385:
	if ( ++p == pe )
		goto _test_eof385;
case 385:
	goto st0;
st386:
	if ( ++p == pe )
		goto _test_eof386;
case 386:
	goto st0;
tr35:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 581 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr58;
	goto st0;
tr58:
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
#line 596 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr59;
	goto st0;
tr59:
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
#line 611 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr60;
	goto st0;
tr28:
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
#line 626 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr61;
	goto st0;
tr61:
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
#line 641 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr62;
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
		goto tr64;
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
		goto tr67;
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
		goto tr70;
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
		goto tr74;
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
		goto tr77;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	if ( (*p) == 32 )
		goto tr78;
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
		goto tr82;
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( (*p) == 32 )
		goto tr83;
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
		goto tr86;
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
		goto tr89;
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
		goto tr92;
	goto st0;
tr10:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st63;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
#line 848 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr93;
	goto st0;
tr93:
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
#line 863 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr94;
	goto st0;
tr94:
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
#line 878 "src/panda/date/parse-date.cc"
	if ( (*p) == 46 )
		goto tr95;
	goto st0;
tr95:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st66;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
#line 890 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr96;
	goto st0;
tr96:
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
#line 905 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr97;
	goto st0;
tr97:
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
#line 920 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr98;
	goto st0;
tr98:
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
#line 935 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr99;
	goto st0;
tr99:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st387;
st387:
	if ( ++p == pe )
		goto _test_eof387;
case 387:
#line 950 "src/panda/date/parse-date.cc"
	goto st0;
tr11:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st70;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
#line 960 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st71;
		case 68: goto st95;
		case 70: goto st98;
		case 74: goto st101;
		case 77: goto st107;
		case 78: goto st111;
		case 79: goto st114;
		case 83: goto st117;
	}
	goto st0;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	switch( (*p) ) {
		case 112: goto st72;
		case 117: goto st93;
	}
	goto st0;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	if ( (*p) == 114 )
		goto st73;
	goto st0;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	if ( (*p) == 47 )
		goto tr111;
	goto st0;
tr111:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st74;
tr132:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st74;
tr135:
#line 109 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st74;
tr138:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st74;
tr142:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st74;
tr145:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st74;
tr146:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st74;
tr150:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st74;
tr151:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st74;
tr154:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st74;
tr157:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st74;
tr160:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st74;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
#line 1047 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr112;
	goto st0;
tr112:
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
#line 1062 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr113;
	goto st0;
tr113:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st76;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
#line 1077 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr114;
	goto st0;
tr114:
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
#line 1092 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr115;
	goto st0;
tr115:
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
#line 1107 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr116;
	goto st0;
tr116:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st79;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
#line 1119 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr117;
	goto st0;
tr117:
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
#line 1134 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr118;
	goto st0;
tr118:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st81;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
#line 1149 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr119;
	goto st0;
tr119:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st82;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
#line 1161 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr120;
	goto st0;
tr120:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st83;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
#line 1176 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr121;
	goto st0;
tr121:
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
#line 1191 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr122;
	goto st0;
tr122:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st85;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
#line 1203 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr123;
	goto st0;
tr123:
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
#line 1218 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr124;
	goto st0;
tr124:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st87;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
#line 1233 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr125;
	goto st0;
tr125:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st88;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
#line 1245 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr126;
		case 45: goto tr126;
	}
	goto st0;
tr126:
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
	goto st89;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
#line 1268 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr127;
	goto st0;
tr127:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st90;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
#line 1283 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr128;
	goto st0;
tr128:
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
#line 1298 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr129;
	goto st0;
tr129:
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
#line 1318 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr130;
	goto st0;
tr130:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st388;
st388:
	if ( ++p == pe )
		goto _test_eof388;
case 388:
#line 1333 "src/panda/date/parse-date.cc"
	goto st0;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	if ( (*p) == 103 )
		goto st94;
	goto st0;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	if ( (*p) == 47 )
		goto tr132;
	goto st0;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	if ( (*p) == 101 )
		goto st96;
	goto st0;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
	if ( (*p) == 99 )
		goto st97;
	goto st0;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	if ( (*p) == 47 )
		goto tr135;
	goto st0;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
	if ( (*p) == 101 )
		goto st99;
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	if ( (*p) == 98 )
		goto st100;
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	if ( (*p) == 47 )
		goto tr138;
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	switch( (*p) ) {
		case 97: goto st102;
		case 117: goto st104;
	}
	goto st0;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	if ( (*p) == 110 )
		goto st103;
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	if ( (*p) == 47 )
		goto tr142;
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	switch( (*p) ) {
		case 108: goto st105;
		case 110: goto st106;
	}
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	if ( (*p) == 47 )
		goto tr145;
	goto st0;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	if ( (*p) == 47 )
		goto tr146;
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	if ( (*p) == 97 )
		goto st108;
	goto st0;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
	switch( (*p) ) {
		case 114: goto st109;
		case 121: goto st110;
	}
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	if ( (*p) == 47 )
		goto tr150;
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	if ( (*p) == 47 )
		goto tr151;
	goto st0;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	if ( (*p) == 111 )
		goto st112;
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	if ( (*p) == 118 )
		goto st113;
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	if ( (*p) == 47 )
		goto tr154;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	if ( (*p) == 99 )
		goto st115;
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	if ( (*p) == 116 )
		goto st116;
	goto st0;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	if ( (*p) == 47 )
		goto tr157;
	goto st0;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	if ( (*p) == 101 )
		goto st118;
	goto st0;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	if ( (*p) == 112 )
		goto st119;
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	if ( (*p) == 47 )
		goto tr160;
	goto st0;
tr12:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st120;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
#line 1541 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr161;
	goto st0;
tr161:
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
#line 1556 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 45: goto tr162;
		case 47: goto tr163;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr164;
	goto st0;
tr162:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st122;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
#line 1572 "src/panda/date/parse-date.cc"
	if ( (*p) == 87 )
		goto st149;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr165;
	goto st0;
tr165:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st123;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
#line 1589 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr167;
	goto st0;
tr167:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st389;
st389:
	if ( ++p == pe )
		goto _test_eof389;
case 389:
#line 1604 "src/panda/date/parse-date.cc"
	if ( (*p) == 45 )
		goto tr479;
	goto st0;
tr479:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st124;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
#line 1616 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr168;
	goto st0;
tr168:
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
#line 1631 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr169;
	goto st0;
tr169:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st390;
st390:
	if ( ++p == pe )
		goto _test_eof390;
case 390:
#line 1646 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 32: goto tr480;
		case 84: goto tr481;
	}
	goto st0;
tr480:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st126;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
#line 1660 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr170;
	goto st0;
tr170:
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
#line 1675 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr171;
	goto st0;
tr171:
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
#line 1690 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr172;
	goto st0;
tr172:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st129;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
#line 1702 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr173;
	goto st0;
tr173:
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
#line 1717 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr174;
	goto st0;
tr174:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st391;
st391:
	if ( ++p == pe )
		goto _test_eof391;
case 391:
#line 1732 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr482;
		case 45: goto tr482;
		case 58: goto tr483;
		case 90: goto tr484;
	}
	goto st0;
tr482:
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
	goto st131;
tr486:
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
	goto st131;
tr489:
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
	goto st131;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
#line 1800 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr175;
	goto st0;
tr175:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st132;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
#line 1815 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr176;
	goto st0;
tr176:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st392;
st392:
	if ( ++p == pe )
		goto _test_eof392;
case 392:
#line 1830 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr485;
	goto st0;
tr485:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
	goto st133;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
#line 1845 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr177;
	goto st0;
tr177:
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
#line 1860 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr178;
	goto st0;
tr178:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st393;
st393:
	if ( ++p == pe )
		goto _test_eof393;
case 393:
#line 1875 "src/panda/date/parse-date.cc"
	goto st0;
tr483:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st135;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
#line 1885 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr179;
	goto st0;
tr179:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st136;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
#line 1900 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr180;
	goto st0;
tr180:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st394;
st394:
	if ( ++p == pe )
		goto _test_eof394;
case 394:
#line 1915 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 44: goto tr487;
		case 46: goto tr487;
		case 90: goto tr488;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr486;
	goto st0;
tr487:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st137;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
#line 1932 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr181;
	goto st0;
tr181:
#line 27 "src/panda/date/parse-date.rl"
	{
        mksec_ptr = p;
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st395;
st395:
	if ( ++p == pe )
		goto _test_eof395;
case 395:
#line 1951 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr489;
		case 45: goto tr489;
		case 90: goto tr491;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr490;
	goto st0;
tr490:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st396;
st396:
	if ( ++p == pe )
		goto _test_eof396;
case 396:
#line 1971 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr489;
		case 45: goto tr489;
		case 90: goto tr491;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr492;
	goto st0;
tr492:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st397;
st397:
	if ( ++p == pe )
		goto _test_eof397;
case 397:
#line 1991 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr489;
		case 45: goto tr489;
		case 90: goto tr491;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr493;
	goto st0;
tr493:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st398;
st398:
	if ( ++p == pe )
		goto _test_eof398;
case 398:
#line 2011 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr489;
		case 45: goto tr489;
		case 90: goto tr491;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr494;
	goto st0;
tr494:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st399;
st399:
	if ( ++p == pe )
		goto _test_eof399;
case 399:
#line 2031 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr489;
		case 45: goto tr489;
		case 90: goto tr491;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr495;
	goto st0;
tr495:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st400;
st400:
	if ( ++p == pe )
		goto _test_eof400;
case 400:
#line 2051 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr489;
		case 45: goto tr489;
		case 90: goto tr491;
	}
	goto st0;
tr484:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st401;
tr488:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st401;
tr491:
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
	goto st401;
st401:
	if ( ++p == pe )
		goto _test_eof401;
case 401:
#line 2085 "src/panda/date/parse-date.cc"
	goto st0;
tr481:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st138;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
#line 2095 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr182;
	goto st0;
tr182:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st139;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
#line 2110 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr183;
	goto st0;
tr183:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st402;
st402:
	if ( ++p == pe )
		goto _test_eof402;
case 402:
#line 2125 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr496;
		case 45: goto tr496;
		case 58: goto tr497;
		case 90: goto tr498;
	}
	goto st0;
tr501:
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
	goto st140;
tr504:
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
	goto st140;
tr507:
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
	goto st140;
tr496:
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
	goto st140;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
#line 2208 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr184;
	goto st0;
tr184:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st141;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
#line 2223 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr185;
	goto st0;
tr185:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st403;
st403:
	if ( ++p == pe )
		goto _test_eof403;
case 403:
#line 2238 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr500;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr499;
	goto st0;
tr187:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st142;
tr499:
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
	goto st142;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
#line 2267 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr186;
	goto st0;
tr186:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st404;
st404:
	if ( ++p == pe )
		goto _test_eof404;
case 404:
#line 2282 "src/panda/date/parse-date.cc"
	goto st0;
tr500:
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
	goto st143;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
#line 2295 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr187;
	goto st0;
tr497:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st144;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
#line 2307 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr188;
	goto st0;
tr188:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st145;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
#line 2322 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr189;
	goto st0;
tr189:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st405;
st405:
	if ( ++p == pe )
		goto _test_eof405;
case 405:
#line 2337 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr501;
		case 45: goto tr501;
		case 58: goto tr502;
		case 90: goto tr503;
	}
	goto st0;
tr502:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st146;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
#line 2353 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr190;
	goto st0;
tr190:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st147;
tr517:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st147;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
#line 2377 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr191;
	goto st0;
tr191:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st406;
st406:
	if ( ++p == pe )
		goto _test_eof406;
case 406:
#line 2392 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 44: goto tr505;
		case 46: goto tr505;
		case 90: goto tr506;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr504;
	goto st0;
tr505:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st148;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
#line 2409 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr192;
	goto st0;
tr192:
#line 27 "src/panda/date/parse-date.rl"
	{
        mksec_ptr = p;
    }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st407;
st407:
	if ( ++p == pe )
		goto _test_eof407;
case 407:
#line 2428 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr507;
		case 45: goto tr507;
		case 90: goto tr509;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr508;
	goto st0;
tr508:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st408;
st408:
	if ( ++p == pe )
		goto _test_eof408;
case 408:
#line 2448 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr507;
		case 45: goto tr507;
		case 90: goto tr509;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr510;
	goto st0;
tr510:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st409;
st409:
	if ( ++p == pe )
		goto _test_eof409;
case 409:
#line 2468 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr507;
		case 45: goto tr507;
		case 90: goto tr509;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr511;
	goto st0;
tr511:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st410;
st410:
	if ( ++p == pe )
		goto _test_eof410;
case 410:
#line 2488 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr507;
		case 45: goto tr507;
		case 90: goto tr509;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr512;
	goto st0;
tr512:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st411;
st411:
	if ( ++p == pe )
		goto _test_eof411;
case 411:
#line 2508 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr507;
		case 45: goto tr507;
		case 90: goto tr509;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr513;
	goto st0;
tr513:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st412;
st412:
	if ( ++p == pe )
		goto _test_eof412;
case 412:
#line 2528 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr507;
		case 45: goto tr507;
		case 90: goto tr509;
	}
	goto st0;
tr498:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st413;
tr503:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st413;
tr506:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st413;
tr509:
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
	goto st413;
st413:
	if ( ++p == pe )
		goto _test_eof413;
case 413:
#line 2566 "src/panda/date/parse-date.cc"
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr193;
	goto st0;
tr193:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st150;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
#line 2586 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr194;
	goto st0;
tr194:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st414;
st414:
	if ( ++p == pe )
		goto _test_eof414;
case 414:
#line 2601 "src/panda/date/parse-date.cc"
	if ( (*p) == 45 )
		goto tr514;
	goto st0;
tr514:
#line 74 "src/panda/date/parse-date.rl"
	{ NSAVE(week); }
	goto st151;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
#line 2613 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr195;
	goto st0;
tr195:
#line 75 "src/panda/date/parse-date.rl"
	{ _date.wday = *p - '0'; }
	goto st415;
st415:
	if ( ++p == pe )
		goto _test_eof415;
case 415:
#line 2625 "src/panda/date/parse-date.cc"
	goto st0;
tr163:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st152;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
#line 2635 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr196;
	goto st0;
tr196:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st153;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
#line 2650 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr197;
	goto st0;
tr197:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st154;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
#line 2665 "src/panda/date/parse-date.cc"
	if ( (*p) == 47 )
		goto tr198;
	goto st0;
tr198:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
	goto st155;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
#line 2677 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr199;
	goto st0;
tr199:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st156;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
#line 2692 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr200;
	goto st0;
tr200:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st416;
st416:
	if ( ++p == pe )
		goto _test_eof416;
case 416:
#line 2707 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr480;
	goto st0;
tr164:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st157;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
#line 2724 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr201;
	goto st0;
tr201:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st158;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
#line 2739 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr202;
	goto st0;
tr202:
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st159;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
#line 2756 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr203;
	goto st0;
tr203:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st417;
st417:
	if ( ++p == pe )
		goto _test_eof417;
case 417:
#line 2771 "src/panda/date/parse-date.cc"
	if ( (*p) == 84 )
		goto tr515;
	goto st0;
tr515:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st160;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
#line 2783 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr204;
	goto st0;
tr204:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st161;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
#line 2798 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr205;
	goto st0;
tr205:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st418;
st418:
	if ( ++p == pe )
		goto _test_eof418;
case 418:
#line 2813 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr496;
		case 45: goto tr496;
		case 90: goto tr498;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr516;
	goto st0;
tr516:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st162;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
#line 2835 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr206;
	goto st0;
tr206:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st419;
st419:
	if ( ++p == pe )
		goto _test_eof419;
case 419:
#line 2850 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr501;
		case 45: goto tr501;
		case 90: goto tr503;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr517;
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	if ( (*p) == 114 )
		goto st164;
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	if ( (*p) == 105 )
		goto st165;
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	switch( (*p) ) {
		case 32: goto tr209;
		case 44: goto tr210;
		case 100: goto st217;
	}
	goto st0;
tr209:
#line 115 "src/panda/date/parse-date.rl"
	{ _date.wday = 5; }
	goto st166;
tr359:
#line 111 "src/panda/date/parse-date.rl"
	{ _date.wday = 1; }
	goto st166;
tr368:
#line 116 "src/panda/date/parse-date.rl"
	{ _date.wday = 6; }
	goto st166;
tr377:
#line 117 "src/panda/date/parse-date.rl"
	{ _date.wday = 0; }
	goto st166;
tr386:
#line 114 "src/panda/date/parse-date.rl"
	{ _date.wday = 4; }
	goto st166;
tr395:
#line 112 "src/panda/date/parse-date.rl"
	{ _date.wday = 2; }
	goto st166;
tr404:
#line 113 "src/panda/date/parse-date.rl"
	{ _date.wday = 3; }
	goto st166;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
#line 2915 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st167;
		case 68: goto st188;
		case 70: goto st191;
		case 74: goto st194;
		case 77: goto st200;
		case 78: goto st204;
		case 79: goto st207;
		case 83: goto st210;
	}
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	switch( (*p) ) {
		case 112: goto st168;
		case 117: goto st186;
	}
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	if ( (*p) == 114 )
		goto st169;
	goto st0;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
	if ( (*p) == 32 )
		goto tr223;
	goto st0;
tr223:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st170;
tr242:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st170;
tr245:
#line 109 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st170;
tr248:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st170;
tr252:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st170;
tr255:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st170;
tr256:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st170;
tr260:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st170;
tr261:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st170;
tr264:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st170;
tr267:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st170;
tr270:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st170;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
#line 3002 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto st171;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr225;
	goto st0;
tr225:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st171;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
#line 3019 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr226;
	goto st0;
tr226:
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
#line 3034 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr227;
	goto st0;
tr227:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st173;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
#line 3046 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr228;
	goto st0;
tr228:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st174;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
#line 3061 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr229;
	goto st0;
tr229:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st175;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
#line 3076 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr230;
	goto st0;
tr230:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st176;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
#line 3088 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr231;
	goto st0;
tr231:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st177;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
#line 3103 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr232;
	goto st0;
tr232:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st178;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
#line 3118 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr233;
	goto st0;
tr233:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st179;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
#line 3130 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr234;
	goto st0;
tr234:
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
#line 3145 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr235;
	goto st0;
tr235:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st181;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
#line 3160 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr236;
	goto st0;
tr236:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st182;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
#line 3172 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr237;
	goto st0;
tr237:
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
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr238;
	goto st0;
tr238:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st184;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
#line 3202 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr239;
	goto st0;
tr239:
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
#line 3217 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr240;
	goto st0;
tr240:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st420;
st420:
	if ( ++p == pe )
		goto _test_eof420;
case 420:
#line 3232 "src/panda/date/parse-date.cc"
	goto st0;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
	if ( (*p) == 103 )
		goto st187;
	goto st0;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
	if ( (*p) == 32 )
		goto tr242;
	goto st0;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
	if ( (*p) == 101 )
		goto st189;
	goto st0;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
	if ( (*p) == 99 )
		goto st190;
	goto st0;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
	if ( (*p) == 32 )
		goto tr245;
	goto st0;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
	if ( (*p) == 101 )
		goto st192;
	goto st0;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
	if ( (*p) == 98 )
		goto st193;
	goto st0;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
	if ( (*p) == 32 )
		goto tr248;
	goto st0;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
	switch( (*p) ) {
		case 97: goto st195;
		case 117: goto st197;
	}
	goto st0;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
	if ( (*p) == 110 )
		goto st196;
	goto st0;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
	if ( (*p) == 32 )
		goto tr252;
	goto st0;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
	switch( (*p) ) {
		case 108: goto st198;
		case 110: goto st199;
	}
	goto st0;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
	if ( (*p) == 32 )
		goto tr255;
	goto st0;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
	if ( (*p) == 32 )
		goto tr256;
	goto st0;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
	if ( (*p) == 97 )
		goto st201;
	goto st0;
st201:
	if ( ++p == pe )
		goto _test_eof201;
case 201:
	switch( (*p) ) {
		case 114: goto st202;
		case 121: goto st203;
	}
	goto st0;
st202:
	if ( ++p == pe )
		goto _test_eof202;
case 202:
	if ( (*p) == 32 )
		goto tr260;
	goto st0;
st203:
	if ( ++p == pe )
		goto _test_eof203;
case 203:
	if ( (*p) == 32 )
		goto tr261;
	goto st0;
st204:
	if ( ++p == pe )
		goto _test_eof204;
case 204:
	if ( (*p) == 111 )
		goto st205;
	goto st0;
st205:
	if ( ++p == pe )
		goto _test_eof205;
case 205:
	if ( (*p) == 118 )
		goto st206;
	goto st0;
st206:
	if ( ++p == pe )
		goto _test_eof206;
case 206:
	if ( (*p) == 32 )
		goto tr264;
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
	if ( (*p) == 116 )
		goto st209;
	goto st0;
st209:
	if ( ++p == pe )
		goto _test_eof209;
case 209:
	if ( (*p) == 32 )
		goto tr267;
	goto st0;
st210:
	if ( ++p == pe )
		goto _test_eof210;
case 210:
	if ( (*p) == 101 )
		goto st211;
	goto st0;
st211:
	if ( ++p == pe )
		goto _test_eof211;
case 211:
	if ( (*p) == 112 )
		goto st212;
	goto st0;
st212:
	if ( ++p == pe )
		goto _test_eof212;
case 212:
	if ( (*p) == 32 )
		goto tr270;
	goto st0;
tr210:
#line 115 "src/panda/date/parse-date.rl"
	{ _date.wday = 5; }
	goto st213;
tr360:
#line 111 "src/panda/date/parse-date.rl"
	{ _date.wday = 1; }
	goto st213;
tr369:
#line 116 "src/panda/date/parse-date.rl"
	{ _date.wday = 6; }
	goto st213;
tr378:
#line 117 "src/panda/date/parse-date.rl"
	{ _date.wday = 0; }
	goto st213;
tr387:
#line 114 "src/panda/date/parse-date.rl"
	{ _date.wday = 4; }
	goto st213;
tr396:
#line 112 "src/panda/date/parse-date.rl"
	{ _date.wday = 2; }
	goto st213;
tr405:
#line 113 "src/panda/date/parse-date.rl"
	{ _date.wday = 3; }
	goto st213;
st213:
	if ( ++p == pe )
		goto _test_eof213;
case 213:
#line 3461 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto st214;
	goto st0;
st214:
	if ( ++p == pe )
		goto _test_eof214;
case 214:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr272;
	goto st0;
tr272:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st215;
st215:
	if ( ++p == pe )
		goto _test_eof215;
case 215:
#line 3483 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr273;
	goto st0;
tr273:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st216;
st216:
	if ( ++p == pe )
		goto _test_eof216;
case 216:
#line 3498 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr9;
	goto st0;
st217:
	if ( ++p == pe )
		goto _test_eof217;
case 217:
	if ( (*p) == 97 )
		goto st218;
	goto st0;
st218:
	if ( ++p == pe )
		goto _test_eof218;
case 218:
	if ( (*p) == 121 )
		goto st219;
	goto st0;
st219:
	if ( ++p == pe )
		goto _test_eof219;
case 219:
	if ( (*p) == 44 )
		goto tr276;
	goto st0;
tr276:
#line 123 "src/panda/date/parse-date.rl"
	{ _date.wday = 5; }
	goto st220;
tr364:
#line 119 "src/panda/date/parse-date.rl"
	{ _date.wday = 1; }
	goto st220;
tr375:
#line 124 "src/panda/date/parse-date.rl"
	{ _date.wday = 6; }
	goto st220;
tr382:
#line 125 "src/panda/date/parse-date.rl"
	{ _date.wday = 0; }
	goto st220;
tr393:
#line 122 "src/panda/date/parse-date.rl"
	{ _date.wday = 4; }
	goto st220;
tr401:
#line 120 "src/panda/date/parse-date.rl"
	{ _date.wday = 2; }
	goto st220;
tr412:
#line 121 "src/panda/date/parse-date.rl"
	{ _date.wday = 3; }
	goto st220;
st220:
	if ( ++p == pe )
		goto _test_eof220;
case 220:
#line 3555 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto st221;
	goto st0;
st221:
	if ( ++p == pe )
		goto _test_eof221;
case 221:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr278;
	goto st0;
tr278:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st222;
st222:
	if ( ++p == pe )
		goto _test_eof222;
case 222:
#line 3577 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr279;
	goto st0;
tr279:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st223;
st223:
	if ( ++p == pe )
		goto _test_eof223;
case 223:
#line 3592 "src/panda/date/parse-date.cc"
	if ( (*p) == 45 )
		goto tr280;
	goto st0;
tr280:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st224;
st224:
	if ( ++p == pe )
		goto _test_eof224;
case 224:
#line 3604 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st225;
		case 68: goto st256;
		case 70: goto st259;
		case 74: goto st262;
		case 77: goto st268;
		case 78: goto st272;
		case 79: goto st275;
		case 83: goto st278;
	}
	goto st0;
st225:
	if ( ++p == pe )
		goto _test_eof225;
case 225:
	switch( (*p) ) {
		case 112: goto st226;
		case 117: goto st254;
	}
	goto st0;
st226:
	if ( ++p == pe )
		goto _test_eof226;
case 226:
	if ( (*p) == 114 )
		goto st227;
	goto st0;
st227:
	if ( ++p == pe )
		goto _test_eof227;
case 227:
	if ( (*p) == 45 )
		goto tr292;
	goto st0;
tr292:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st228;
tr328:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st228;
tr331:
#line 109 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st228;
tr334:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st228;
tr338:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st228;
tr341:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st228;
tr342:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st228;
tr346:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st228;
tr347:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st228;
tr350:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st228;
tr353:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st228;
tr356:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st228;
st228:
	if ( ++p == pe )
		goto _test_eof228;
case 228:
#line 3691 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr293;
	goto st0;
tr293:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st229;
st229:
	if ( ++p == pe )
		goto _test_eof229;
case 229:
#line 3706 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
tr294:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st230;
st230:
	if ( ++p == pe )
		goto _test_eof230;
case 230:
#line 3721 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr295;
	goto st0;
tr295:
#line 21 "src/panda/date/parse-date.rl"
	{
        if (acc <= 50) _date.year = 2000 + acc;
        else           _date.year = 1900 + acc;
        acc = 0;
    }
	goto st231;
st231:
	if ( ++p == pe )
		goto _test_eof231;
case 231:
#line 3737 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr296;
	goto st0;
tr296:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st232;
st232:
	if ( ++p == pe )
		goto _test_eof232;
case 232:
#line 3752 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr297;
	goto st0;
tr297:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st233;
st233:
	if ( ++p == pe )
		goto _test_eof233;
case 233:
#line 3767 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr298;
	goto st0;
tr298:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st234;
st234:
	if ( ++p == pe )
		goto _test_eof234;
case 234:
#line 3779 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr299;
	goto st0;
tr299:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st235;
st235:
	if ( ++p == pe )
		goto _test_eof235;
case 235:
#line 3794 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr300;
	goto st0;
tr300:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st236;
st236:
	if ( ++p == pe )
		goto _test_eof236;
case 236:
#line 3809 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr301;
	goto st0;
tr301:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st237;
st237:
	if ( ++p == pe )
		goto _test_eof237;
case 237:
#line 3821 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr302;
	goto st0;
tr302:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st238;
st238:
	if ( ++p == pe )
		goto _test_eof238;
case 238:
#line 3836 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr303;
	goto st0;
tr303:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st239;
st239:
	if ( ++p == pe )
		goto _test_eof239;
case 239:
#line 3851 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr304;
	goto st0;
tr304:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st240;
st240:
	if ( ++p == pe )
		goto _test_eof240;
case 240:
#line 3863 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr305;
		case 45: goto tr305;
		case 65: goto st422;
		case 67: goto st245;
		case 69: goto st247;
		case 71: goto st249;
		case 77: goto st426;
		case 78: goto st428;
		case 80: goto st252;
		case 85: goto st250;
		case 89: goto st430;
		case 90: goto st425;
	}
	goto st0;
tr305:
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
	goto st241;
st241:
	if ( ++p == pe )
		goto _test_eof241;
case 241:
#line 3896 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr316;
	goto st0;
tr316:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st242;
st242:
	if ( ++p == pe )
		goto _test_eof242;
case 242:
#line 3911 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr317;
	goto st0;
tr317:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st243;
st243:
	if ( ++p == pe )
		goto _test_eof243;
case 243:
#line 3926 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr318;
	goto st0;
tr318:
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
	goto st244;
st244:
	if ( ++p == pe )
		goto _test_eof244;
case 244:
#line 3946 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr319;
	goto st0;
tr319:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st421;
st421:
	if ( ++p == pe )
		goto _test_eof421;
case 421:
#line 3961 "src/panda/date/parse-date.cc"
	goto st0;
st422:
	if ( ++p == pe )
		goto _test_eof422;
case 422:
	goto st0;
st245:
	if ( ++p == pe )
		goto _test_eof245;
case 245:
	switch( (*p) ) {
		case 68: goto st246;
		case 83: goto st246;
	}
	goto st0;
st246:
	if ( ++p == pe )
		goto _test_eof246;
case 246:
	if ( (*p) == 84 )
		goto st423;
	goto st0;
st423:
	if ( ++p == pe )
		goto _test_eof423;
case 423:
	goto st0;
st247:
	if ( ++p == pe )
		goto _test_eof247;
case 247:
	switch( (*p) ) {
		case 68: goto st248;
		case 83: goto st248;
	}
	goto st0;
st248:
	if ( ++p == pe )
		goto _test_eof248;
case 248:
	if ( (*p) == 84 )
		goto st424;
	goto st0;
st424:
	if ( ++p == pe )
		goto _test_eof424;
case 424:
	goto st0;
st249:
	if ( ++p == pe )
		goto _test_eof249;
case 249:
	if ( (*p) == 77 )
		goto st250;
	goto st0;
st250:
	if ( ++p == pe )
		goto _test_eof250;
case 250:
	if ( (*p) == 84 )
		goto st425;
	goto st0;
st425:
	if ( ++p == pe )
		goto _test_eof425;
case 425:
	goto st0;
st426:
	if ( ++p == pe )
		goto _test_eof426;
case 426:
	switch( (*p) ) {
		case 68: goto st251;
		case 83: goto st251;
	}
	goto st0;
st251:
	if ( ++p == pe )
		goto _test_eof251;
case 251:
	if ( (*p) == 84 )
		goto st427;
	goto st0;
st427:
	if ( ++p == pe )
		goto _test_eof427;
case 427:
	goto st0;
st428:
	if ( ++p == pe )
		goto _test_eof428;
case 428:
	goto st0;
st252:
	if ( ++p == pe )
		goto _test_eof252;
case 252:
	switch( (*p) ) {
		case 68: goto st253;
		case 83: goto st253;
	}
	goto st0;
st253:
	if ( ++p == pe )
		goto _test_eof253;
case 253:
	if ( (*p) == 84 )
		goto st429;
	goto st0;
st429:
	if ( ++p == pe )
		goto _test_eof429;
case 429:
	goto st0;
st430:
	if ( ++p == pe )
		goto _test_eof430;
case 430:
	goto st0;
st254:
	if ( ++p == pe )
		goto _test_eof254;
case 254:
	if ( (*p) == 103 )
		goto st255;
	goto st0;
st255:
	if ( ++p == pe )
		goto _test_eof255;
case 255:
	if ( (*p) == 45 )
		goto tr328;
	goto st0;
st256:
	if ( ++p == pe )
		goto _test_eof256;
case 256:
	if ( (*p) == 101 )
		goto st257;
	goto st0;
st257:
	if ( ++p == pe )
		goto _test_eof257;
case 257:
	if ( (*p) == 99 )
		goto st258;
	goto st0;
st258:
	if ( ++p == pe )
		goto _test_eof258;
case 258:
	if ( (*p) == 45 )
		goto tr331;
	goto st0;
st259:
	if ( ++p == pe )
		goto _test_eof259;
case 259:
	if ( (*p) == 101 )
		goto st260;
	goto st0;
st260:
	if ( ++p == pe )
		goto _test_eof260;
case 260:
	if ( (*p) == 98 )
		goto st261;
	goto st0;
st261:
	if ( ++p == pe )
		goto _test_eof261;
case 261:
	if ( (*p) == 45 )
		goto tr334;
	goto st0;
st262:
	if ( ++p == pe )
		goto _test_eof262;
case 262:
	switch( (*p) ) {
		case 97: goto st263;
		case 117: goto st265;
	}
	goto st0;
st263:
	if ( ++p == pe )
		goto _test_eof263;
case 263:
	if ( (*p) == 110 )
		goto st264;
	goto st0;
st264:
	if ( ++p == pe )
		goto _test_eof264;
case 264:
	if ( (*p) == 45 )
		goto tr338;
	goto st0;
st265:
	if ( ++p == pe )
		goto _test_eof265;
case 265:
	switch( (*p) ) {
		case 108: goto st266;
		case 110: goto st267;
	}
	goto st0;
st266:
	if ( ++p == pe )
		goto _test_eof266;
case 266:
	if ( (*p) == 45 )
		goto tr341;
	goto st0;
st267:
	if ( ++p == pe )
		goto _test_eof267;
case 267:
	if ( (*p) == 45 )
		goto tr342;
	goto st0;
st268:
	if ( ++p == pe )
		goto _test_eof268;
case 268:
	if ( (*p) == 97 )
		goto st269;
	goto st0;
st269:
	if ( ++p == pe )
		goto _test_eof269;
case 269:
	switch( (*p) ) {
		case 114: goto st270;
		case 121: goto st271;
	}
	goto st0;
st270:
	if ( ++p == pe )
		goto _test_eof270;
case 270:
	if ( (*p) == 45 )
		goto tr346;
	goto st0;
st271:
	if ( ++p == pe )
		goto _test_eof271;
case 271:
	if ( (*p) == 45 )
		goto tr347;
	goto st0;
st272:
	if ( ++p == pe )
		goto _test_eof272;
case 272:
	if ( (*p) == 111 )
		goto st273;
	goto st0;
st273:
	if ( ++p == pe )
		goto _test_eof273;
case 273:
	if ( (*p) == 118 )
		goto st274;
	goto st0;
st274:
	if ( ++p == pe )
		goto _test_eof274;
case 274:
	if ( (*p) == 45 )
		goto tr350;
	goto st0;
st275:
	if ( ++p == pe )
		goto _test_eof275;
case 275:
	if ( (*p) == 99 )
		goto st276;
	goto st0;
st276:
	if ( ++p == pe )
		goto _test_eof276;
case 276:
	if ( (*p) == 116 )
		goto st277;
	goto st0;
st277:
	if ( ++p == pe )
		goto _test_eof277;
case 277:
	if ( (*p) == 45 )
		goto tr353;
	goto st0;
st278:
	if ( ++p == pe )
		goto _test_eof278;
case 278:
	if ( (*p) == 101 )
		goto st279;
	goto st0;
st279:
	if ( ++p == pe )
		goto _test_eof279;
case 279:
	if ( (*p) == 112 )
		goto st280;
	goto st0;
st280:
	if ( ++p == pe )
		goto _test_eof280;
case 280:
	if ( (*p) == 45 )
		goto tr356;
	goto st0;
st281:
	if ( ++p == pe )
		goto _test_eof281;
case 281:
	if ( (*p) == 111 )
		goto st282;
	goto st0;
st282:
	if ( ++p == pe )
		goto _test_eof282;
case 282:
	if ( (*p) == 110 )
		goto st283;
	goto st0;
st283:
	if ( ++p == pe )
		goto _test_eof283;
case 283:
	switch( (*p) ) {
		case 32: goto tr359;
		case 44: goto tr360;
		case 100: goto st284;
	}
	goto st0;
st284:
	if ( ++p == pe )
		goto _test_eof284;
case 284:
	if ( (*p) == 97 )
		goto st285;
	goto st0;
st285:
	if ( ++p == pe )
		goto _test_eof285;
case 285:
	if ( (*p) == 121 )
		goto st286;
	goto st0;
st286:
	if ( ++p == pe )
		goto _test_eof286;
case 286:
	if ( (*p) == 44 )
		goto tr364;
	goto st0;
st287:
	if ( ++p == pe )
		goto _test_eof287;
case 287:
	switch( (*p) ) {
		case 97: goto st288;
		case 117: goto st295;
	}
	goto st0;
st288:
	if ( ++p == pe )
		goto _test_eof288;
case 288:
	if ( (*p) == 116 )
		goto st289;
	goto st0;
st289:
	if ( ++p == pe )
		goto _test_eof289;
case 289:
	switch( (*p) ) {
		case 32: goto tr368;
		case 44: goto tr369;
		case 117: goto st290;
	}
	goto st0;
st290:
	if ( ++p == pe )
		goto _test_eof290;
case 290:
	if ( (*p) == 114 )
		goto st291;
	goto st0;
st291:
	if ( ++p == pe )
		goto _test_eof291;
case 291:
	if ( (*p) == 100 )
		goto st292;
	goto st0;
st292:
	if ( ++p == pe )
		goto _test_eof292;
case 292:
	if ( (*p) == 97 )
		goto st293;
	goto st0;
st293:
	if ( ++p == pe )
		goto _test_eof293;
case 293:
	if ( (*p) == 121 )
		goto st294;
	goto st0;
st294:
	if ( ++p == pe )
		goto _test_eof294;
case 294:
	if ( (*p) == 44 )
		goto tr375;
	goto st0;
st295:
	if ( ++p == pe )
		goto _test_eof295;
case 295:
	if ( (*p) == 110 )
		goto st296;
	goto st0;
st296:
	if ( ++p == pe )
		goto _test_eof296;
case 296:
	switch( (*p) ) {
		case 32: goto tr377;
		case 44: goto tr378;
		case 100: goto st297;
	}
	goto st0;
st297:
	if ( ++p == pe )
		goto _test_eof297;
case 297:
	if ( (*p) == 97 )
		goto st298;
	goto st0;
st298:
	if ( ++p == pe )
		goto _test_eof298;
case 298:
	if ( (*p) == 121 )
		goto st299;
	goto st0;
st299:
	if ( ++p == pe )
		goto _test_eof299;
case 299:
	if ( (*p) == 44 )
		goto tr382;
	goto st0;
st300:
	if ( ++p == pe )
		goto _test_eof300;
case 300:
	switch( (*p) ) {
		case 104: goto st301;
		case 117: goto st308;
	}
	goto st0;
st301:
	if ( ++p == pe )
		goto _test_eof301;
case 301:
	if ( (*p) == 117 )
		goto st302;
	goto st0;
st302:
	if ( ++p == pe )
		goto _test_eof302;
case 302:
	switch( (*p) ) {
		case 32: goto tr386;
		case 44: goto tr387;
		case 114: goto st303;
	}
	goto st0;
st303:
	if ( ++p == pe )
		goto _test_eof303;
case 303:
	if ( (*p) == 115 )
		goto st304;
	goto st0;
st304:
	if ( ++p == pe )
		goto _test_eof304;
case 304:
	if ( (*p) == 100 )
		goto st305;
	goto st0;
st305:
	if ( ++p == pe )
		goto _test_eof305;
case 305:
	if ( (*p) == 97 )
		goto st306;
	goto st0;
st306:
	if ( ++p == pe )
		goto _test_eof306;
case 306:
	if ( (*p) == 121 )
		goto st307;
	goto st0;
st307:
	if ( ++p == pe )
		goto _test_eof307;
case 307:
	if ( (*p) == 44 )
		goto tr393;
	goto st0;
st308:
	if ( ++p == pe )
		goto _test_eof308;
case 308:
	if ( (*p) == 101 )
		goto st309;
	goto st0;
st309:
	if ( ++p == pe )
		goto _test_eof309;
case 309:
	switch( (*p) ) {
		case 32: goto tr395;
		case 44: goto tr396;
		case 115: goto st310;
	}
	goto st0;
st310:
	if ( ++p == pe )
		goto _test_eof310;
case 310:
	if ( (*p) == 100 )
		goto st311;
	goto st0;
st311:
	if ( ++p == pe )
		goto _test_eof311;
case 311:
	if ( (*p) == 97 )
		goto st312;
	goto st0;
st312:
	if ( ++p == pe )
		goto _test_eof312;
case 312:
	if ( (*p) == 121 )
		goto st313;
	goto st0;
st313:
	if ( ++p == pe )
		goto _test_eof313;
case 313:
	if ( (*p) == 44 )
		goto tr401;
	goto st0;
st314:
	if ( ++p == pe )
		goto _test_eof314;
case 314:
	if ( (*p) == 101 )
		goto st315;
	goto st0;
st315:
	if ( ++p == pe )
		goto _test_eof315;
case 315:
	if ( (*p) == 100 )
		goto st316;
	goto st0;
st316:
	if ( ++p == pe )
		goto _test_eof316;
case 316:
	switch( (*p) ) {
		case 32: goto tr404;
		case 44: goto tr405;
		case 110: goto st317;
	}
	goto st0;
st317:
	if ( ++p == pe )
		goto _test_eof317;
case 317:
	if ( (*p) == 101 )
		goto st318;
	goto st0;
st318:
	if ( ++p == pe )
		goto _test_eof318;
case 318:
	if ( (*p) == 115 )
		goto st319;
	goto st0;
st319:
	if ( ++p == pe )
		goto _test_eof319;
case 319:
	if ( (*p) == 100 )
		goto st320;
	goto st0;
st320:
	if ( ++p == pe )
		goto _test_eof320;
case 320:
	if ( (*p) == 97 )
		goto st321;
	goto st0;
st321:
	if ( ++p == pe )
		goto _test_eof321;
case 321:
	if ( (*p) == 121 )
		goto st322;
	goto st0;
st322:
	if ( ++p == pe )
		goto _test_eof322;
case 322:
	if ( (*p) == 44 )
		goto tr412;
	goto st0;
st323:
	if ( ++p == pe )
		goto _test_eof323;
case 323:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr413;
	goto st0;
tr413:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st324;
st324:
	if ( ++p == pe )
		goto _test_eof324;
case 324:
#line 4610 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr414;
	goto st0;
tr414:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st325;
st325:
	if ( ++p == pe )
		goto _test_eof325;
case 325:
#line 4625 "src/panda/date/parse-date.cc"
	if ( (*p) == 47 )
		goto tr415;
	goto st0;
tr415:
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
	goto st326;
st326:
	if ( ++p == pe )
		goto _test_eof326;
case 326:
#line 4637 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 65: goto st327;
		case 68: goto st352;
		case 70: goto st355;
		case 74: goto st358;
		case 77: goto st364;
		case 78: goto st368;
		case 79: goto st371;
		case 83: goto st374;
	}
	goto st0;
st327:
	if ( ++p == pe )
		goto _test_eof327;
case 327:
	switch( (*p) ) {
		case 112: goto st328;
		case 117: goto st350;
	}
	goto st0;
st328:
	if ( ++p == pe )
		goto _test_eof328;
case 328:
	if ( (*p) == 114 )
		goto st329;
	goto st0;
st329:
	if ( ++p == pe )
		goto _test_eof329;
case 329:
	if ( (*p) == 47 )
		goto tr427;
	goto st0;
tr427:
#line 101 "src/panda/date/parse-date.rl"
	{ _date.mon = 3; }
	goto st330;
tr449:
#line 105 "src/panda/date/parse-date.rl"
	{ _date.mon = 7; }
	goto st330;
tr452:
#line 109 "src/panda/date/parse-date.rl"
	{ _date.mon = 11;}
	goto st330;
tr455:
#line 99 "src/panda/date/parse-date.rl"
	{ _date.mon = 1; }
	goto st330;
tr459:
#line 98 "src/panda/date/parse-date.rl"
	{ _date.mon = 0; }
	goto st330;
tr462:
#line 104 "src/panda/date/parse-date.rl"
	{ _date.mon = 6; }
	goto st330;
tr463:
#line 103 "src/panda/date/parse-date.rl"
	{ _date.mon = 5; }
	goto st330;
tr467:
#line 100 "src/panda/date/parse-date.rl"
	{ _date.mon = 2; }
	goto st330;
tr468:
#line 102 "src/panda/date/parse-date.rl"
	{ _date.mon = 4; }
	goto st330;
tr471:
#line 108 "src/panda/date/parse-date.rl"
	{ _date.mon = 10;}
	goto st330;
tr474:
#line 107 "src/panda/date/parse-date.rl"
	{ _date.mon = 9; }
	goto st330;
tr477:
#line 106 "src/panda/date/parse-date.rl"
	{ _date.mon = 8; }
	goto st330;
st330:
	if ( ++p == pe )
		goto _test_eof330;
case 330:
#line 4724 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr428;
	goto st0;
tr428:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st331;
st331:
	if ( ++p == pe )
		goto _test_eof331;
case 331:
#line 4739 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr429;
	goto st0;
tr429:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st332;
st332:
	if ( ++p == pe )
		goto _test_eof332;
case 332:
#line 4754 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr430;
	goto st0;
tr430:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st333;
st333:
	if ( ++p == pe )
		goto _test_eof333;
case 333:
#line 4769 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr431;
	goto st0;
tr431:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st334;
st334:
	if ( ++p == pe )
		goto _test_eof334;
case 334:
#line 4784 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr432;
	goto st0;
tr432:
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
	goto st335;
st335:
	if ( ++p == pe )
		goto _test_eof335;
case 335:
#line 4796 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr433;
	goto st0;
tr433:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st336;
st336:
	if ( ++p == pe )
		goto _test_eof336;
case 336:
#line 4811 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr434;
	goto st0;
tr434:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st337;
st337:
	if ( ++p == pe )
		goto _test_eof337;
case 337:
#line 4826 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr435;
	goto st0;
tr435:
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
	goto st338;
st338:
	if ( ++p == pe )
		goto _test_eof338;
case 338:
#line 4838 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr436;
	goto st0;
tr436:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st339;
st339:
	if ( ++p == pe )
		goto _test_eof339;
case 339:
#line 4853 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr437;
	goto st0;
tr437:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st340;
st340:
	if ( ++p == pe )
		goto _test_eof340;
case 340:
#line 4868 "src/panda/date/parse-date.cc"
	if ( (*p) == 58 )
		goto tr438;
	goto st0;
tr438:
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
	goto st341;
st341:
	if ( ++p == pe )
		goto _test_eof341;
case 341:
#line 4880 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr439;
	goto st0;
tr439:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st342;
st342:
	if ( ++p == pe )
		goto _test_eof342;
case 342:
#line 4895 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr440;
	goto st0;
tr440:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st343;
st343:
	if ( ++p == pe )
		goto _test_eof343;
case 343:
#line 4910 "src/panda/date/parse-date.cc"
	if ( (*p) == 32 )
		goto tr441;
	goto st0;
tr441:
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
	goto st344;
st344:
	if ( ++p == pe )
		goto _test_eof344;
case 344:
#line 4922 "src/panda/date/parse-date.cc"
	switch( (*p) ) {
		case 43: goto tr442;
		case 45: goto tr442;
	}
	goto st0;
tr442:
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
	goto st345;
st345:
	if ( ++p == pe )
		goto _test_eof345;
case 345:
#line 4945 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr443;
	goto st0;
tr443:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st346;
st346:
	if ( ++p == pe )
		goto _test_eof346;
case 346:
#line 4960 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr444;
	goto st0;
tr444:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st347;
st347:
	if ( ++p == pe )
		goto _test_eof347;
case 347:
#line 4975 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr445;
	goto st0;
tr445:
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
	goto st348;
st348:
	if ( ++p == pe )
		goto _test_eof348;
case 348:
#line 4995 "src/panda/date/parse-date.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr446;
	goto st0;
tr446:
#line 9 "src/panda/date/parse-date.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st349;
st349:
	if ( ++p == pe )
		goto _test_eof349;
case 349:
#line 5010 "src/panda/date/parse-date.cc"
	if ( (*p) == 93 )
		goto tr447;
	goto st0;
tr447:
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
	goto st431;
st431:
	if ( ++p == pe )
		goto _test_eof431;
case 431:
#line 5025 "src/panda/date/parse-date.cc"
	goto st0;
st350:
	if ( ++p == pe )
		goto _test_eof350;
case 350:
	if ( (*p) == 103 )
		goto st351;
	goto st0;
st351:
	if ( ++p == pe )
		goto _test_eof351;
case 351:
	if ( (*p) == 47 )
		goto tr449;
	goto st0;
st352:
	if ( ++p == pe )
		goto _test_eof352;
case 352:
	if ( (*p) == 101 )
		goto st353;
	goto st0;
st353:
	if ( ++p == pe )
		goto _test_eof353;
case 353:
	if ( (*p) == 99 )
		goto st354;
	goto st0;
st354:
	if ( ++p == pe )
		goto _test_eof354;
case 354:
	if ( (*p) == 47 )
		goto tr452;
	goto st0;
st355:
	if ( ++p == pe )
		goto _test_eof355;
case 355:
	if ( (*p) == 101 )
		goto st356;
	goto st0;
st356:
	if ( ++p == pe )
		goto _test_eof356;
case 356:
	if ( (*p) == 98 )
		goto st357;
	goto st0;
st357:
	if ( ++p == pe )
		goto _test_eof357;
case 357:
	if ( (*p) == 47 )
		goto tr455;
	goto st0;
st358:
	if ( ++p == pe )
		goto _test_eof358;
case 358:
	switch( (*p) ) {
		case 97: goto st359;
		case 117: goto st361;
	}
	goto st0;
st359:
	if ( ++p == pe )
		goto _test_eof359;
case 359:
	if ( (*p) == 110 )
		goto st360;
	goto st0;
st360:
	if ( ++p == pe )
		goto _test_eof360;
case 360:
	if ( (*p) == 47 )
		goto tr459;
	goto st0;
st361:
	if ( ++p == pe )
		goto _test_eof361;
case 361:
	switch( (*p) ) {
		case 108: goto st362;
		case 110: goto st363;
	}
	goto st0;
st362:
	if ( ++p == pe )
		goto _test_eof362;
case 362:
	if ( (*p) == 47 )
		goto tr462;
	goto st0;
st363:
	if ( ++p == pe )
		goto _test_eof363;
case 363:
	if ( (*p) == 47 )
		goto tr463;
	goto st0;
st364:
	if ( ++p == pe )
		goto _test_eof364;
case 364:
	if ( (*p) == 97 )
		goto st365;
	goto st0;
st365:
	if ( ++p == pe )
		goto _test_eof365;
case 365:
	switch( (*p) ) {
		case 114: goto st366;
		case 121: goto st367;
	}
	goto st0;
st366:
	if ( ++p == pe )
		goto _test_eof366;
case 366:
	if ( (*p) == 47 )
		goto tr467;
	goto st0;
st367:
	if ( ++p == pe )
		goto _test_eof367;
case 367:
	if ( (*p) == 47 )
		goto tr468;
	goto st0;
st368:
	if ( ++p == pe )
		goto _test_eof368;
case 368:
	if ( (*p) == 111 )
		goto st369;
	goto st0;
st369:
	if ( ++p == pe )
		goto _test_eof369;
case 369:
	if ( (*p) == 118 )
		goto st370;
	goto st0;
st370:
	if ( ++p == pe )
		goto _test_eof370;
case 370:
	if ( (*p) == 47 )
		goto tr471;
	goto st0;
st371:
	if ( ++p == pe )
		goto _test_eof371;
case 371:
	if ( (*p) == 99 )
		goto st372;
	goto st0;
st372:
	if ( ++p == pe )
		goto _test_eof372;
case 372:
	if ( (*p) == 116 )
		goto st373;
	goto st0;
st373:
	if ( ++p == pe )
		goto _test_eof373;
case 373:
	if ( (*p) == 47 )
		goto tr474;
	goto st0;
st374:
	if ( ++p == pe )
		goto _test_eof374;
case 374:
	if ( (*p) == 101 )
		goto st375;
	goto st0;
st375:
	if ( ++p == pe )
		goto _test_eof375;
case 375:
	if ( (*p) == 112 )
		goto st376;
	goto st0;
st376:
	if ( ++p == pe )
		goto _test_eof376;
case 376:
	if ( (*p) == 47 )
		goto tr477;
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
	_test_eof377: cs = 377; goto _test_eof; 
	_test_eof378: cs = 378; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof379: cs = 379; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof380: cs = 380; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof381: cs = 381; goto _test_eof; 
	_test_eof382: cs = 382; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof383: cs = 383; goto _test_eof; 
	_test_eof384: cs = 384; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof385: cs = 385; goto _test_eof; 
	_test_eof386: cs = 386; goto _test_eof; 
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
	_test_eof387: cs = 387; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof75: cs = 75; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof77: cs = 77; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof80: cs = 80; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof82: cs = 82; goto _test_eof; 
	_test_eof83: cs = 83; goto _test_eof; 
	_test_eof84: cs = 84; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
	_test_eof86: cs = 86; goto _test_eof; 
	_test_eof87: cs = 87; goto _test_eof; 
	_test_eof88: cs = 88; goto _test_eof; 
	_test_eof89: cs = 89; goto _test_eof; 
	_test_eof90: cs = 90; goto _test_eof; 
	_test_eof91: cs = 91; goto _test_eof; 
	_test_eof92: cs = 92; goto _test_eof; 
	_test_eof388: cs = 388; goto _test_eof; 
	_test_eof93: cs = 93; goto _test_eof; 
	_test_eof94: cs = 94; goto _test_eof; 
	_test_eof95: cs = 95; goto _test_eof; 
	_test_eof96: cs = 96; goto _test_eof; 
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof98: cs = 98; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof108: cs = 108; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
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
	_test_eof389: cs = 389; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
	_test_eof390: cs = 390; goto _test_eof; 
	_test_eof126: cs = 126; goto _test_eof; 
	_test_eof127: cs = 127; goto _test_eof; 
	_test_eof128: cs = 128; goto _test_eof; 
	_test_eof129: cs = 129; goto _test_eof; 
	_test_eof130: cs = 130; goto _test_eof; 
	_test_eof391: cs = 391; goto _test_eof; 
	_test_eof131: cs = 131; goto _test_eof; 
	_test_eof132: cs = 132; goto _test_eof; 
	_test_eof392: cs = 392; goto _test_eof; 
	_test_eof133: cs = 133; goto _test_eof; 
	_test_eof134: cs = 134; goto _test_eof; 
	_test_eof393: cs = 393; goto _test_eof; 
	_test_eof135: cs = 135; goto _test_eof; 
	_test_eof136: cs = 136; goto _test_eof; 
	_test_eof394: cs = 394; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 
	_test_eof395: cs = 395; goto _test_eof; 
	_test_eof396: cs = 396; goto _test_eof; 
	_test_eof397: cs = 397; goto _test_eof; 
	_test_eof398: cs = 398; goto _test_eof; 
	_test_eof399: cs = 399; goto _test_eof; 
	_test_eof400: cs = 400; goto _test_eof; 
	_test_eof401: cs = 401; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof402: cs = 402; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof403: cs = 403; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof404: cs = 404; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof405: cs = 405; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof406: cs = 406; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof407: cs = 407; goto _test_eof; 
	_test_eof408: cs = 408; goto _test_eof; 
	_test_eof409: cs = 409; goto _test_eof; 
	_test_eof410: cs = 410; goto _test_eof; 
	_test_eof411: cs = 411; goto _test_eof; 
	_test_eof412: cs = 412; goto _test_eof; 
	_test_eof413: cs = 413; goto _test_eof; 
	_test_eof149: cs = 149; goto _test_eof; 
	_test_eof150: cs = 150; goto _test_eof; 
	_test_eof414: cs = 414; goto _test_eof; 
	_test_eof151: cs = 151; goto _test_eof; 
	_test_eof415: cs = 415; goto _test_eof; 
	_test_eof152: cs = 152; goto _test_eof; 
	_test_eof153: cs = 153; goto _test_eof; 
	_test_eof154: cs = 154; goto _test_eof; 
	_test_eof155: cs = 155; goto _test_eof; 
	_test_eof156: cs = 156; goto _test_eof; 
	_test_eof416: cs = 416; goto _test_eof; 
	_test_eof157: cs = 157; goto _test_eof; 
	_test_eof158: cs = 158; goto _test_eof; 
	_test_eof159: cs = 159; goto _test_eof; 
	_test_eof417: cs = 417; goto _test_eof; 
	_test_eof160: cs = 160; goto _test_eof; 
	_test_eof161: cs = 161; goto _test_eof; 
	_test_eof418: cs = 418; goto _test_eof; 
	_test_eof162: cs = 162; goto _test_eof; 
	_test_eof419: cs = 419; goto _test_eof; 
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
	_test_eof420: cs = 420; goto _test_eof; 
	_test_eof186: cs = 186; goto _test_eof; 
	_test_eof187: cs = 187; goto _test_eof; 
	_test_eof188: cs = 188; goto _test_eof; 
	_test_eof189: cs = 189; goto _test_eof; 
	_test_eof190: cs = 190; goto _test_eof; 
	_test_eof191: cs = 191; goto _test_eof; 
	_test_eof192: cs = 192; goto _test_eof; 
	_test_eof193: cs = 193; goto _test_eof; 
	_test_eof194: cs = 194; goto _test_eof; 
	_test_eof195: cs = 195; goto _test_eof; 
	_test_eof196: cs = 196; goto _test_eof; 
	_test_eof197: cs = 197; goto _test_eof; 
	_test_eof198: cs = 198; goto _test_eof; 
	_test_eof199: cs = 199; goto _test_eof; 
	_test_eof200: cs = 200; goto _test_eof; 
	_test_eof201: cs = 201; goto _test_eof; 
	_test_eof202: cs = 202; goto _test_eof; 
	_test_eof203: cs = 203; goto _test_eof; 
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
	_test_eof421: cs = 421; goto _test_eof; 
	_test_eof422: cs = 422; goto _test_eof; 
	_test_eof245: cs = 245; goto _test_eof; 
	_test_eof246: cs = 246; goto _test_eof; 
	_test_eof423: cs = 423; goto _test_eof; 
	_test_eof247: cs = 247; goto _test_eof; 
	_test_eof248: cs = 248; goto _test_eof; 
	_test_eof424: cs = 424; goto _test_eof; 
	_test_eof249: cs = 249; goto _test_eof; 
	_test_eof250: cs = 250; goto _test_eof; 
	_test_eof425: cs = 425; goto _test_eof; 
	_test_eof426: cs = 426; goto _test_eof; 
	_test_eof251: cs = 251; goto _test_eof; 
	_test_eof427: cs = 427; goto _test_eof; 
	_test_eof428: cs = 428; goto _test_eof; 
	_test_eof252: cs = 252; goto _test_eof; 
	_test_eof253: cs = 253; goto _test_eof; 
	_test_eof429: cs = 429; goto _test_eof; 
	_test_eof430: cs = 430; goto _test_eof; 
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
	_test_eof273: cs = 273; goto _test_eof; 
	_test_eof274: cs = 274; goto _test_eof; 
	_test_eof275: cs = 275; goto _test_eof; 
	_test_eof276: cs = 276; goto _test_eof; 
	_test_eof277: cs = 277; goto _test_eof; 
	_test_eof278: cs = 278; goto _test_eof; 
	_test_eof279: cs = 279; goto _test_eof; 
	_test_eof280: cs = 280; goto _test_eof; 
	_test_eof281: cs = 281; goto _test_eof; 
	_test_eof282: cs = 282; goto _test_eof; 
	_test_eof283: cs = 283; goto _test_eof; 
	_test_eof284: cs = 284; goto _test_eof; 
	_test_eof285: cs = 285; goto _test_eof; 
	_test_eof286: cs = 286; goto _test_eof; 
	_test_eof287: cs = 287; goto _test_eof; 
	_test_eof288: cs = 288; goto _test_eof; 
	_test_eof289: cs = 289; goto _test_eof; 
	_test_eof290: cs = 290; goto _test_eof; 
	_test_eof291: cs = 291; goto _test_eof; 
	_test_eof292: cs = 292; goto _test_eof; 
	_test_eof293: cs = 293; goto _test_eof; 
	_test_eof294: cs = 294; goto _test_eof; 
	_test_eof295: cs = 295; goto _test_eof; 
	_test_eof296: cs = 296; goto _test_eof; 
	_test_eof297: cs = 297; goto _test_eof; 
	_test_eof298: cs = 298; goto _test_eof; 
	_test_eof299: cs = 299; goto _test_eof; 
	_test_eof300: cs = 300; goto _test_eof; 
	_test_eof301: cs = 301; goto _test_eof; 
	_test_eof302: cs = 302; goto _test_eof; 
	_test_eof303: cs = 303; goto _test_eof; 
	_test_eof304: cs = 304; goto _test_eof; 
	_test_eof305: cs = 305; goto _test_eof; 
	_test_eof306: cs = 306; goto _test_eof; 
	_test_eof307: cs = 307; goto _test_eof; 
	_test_eof308: cs = 308; goto _test_eof; 
	_test_eof309: cs = 309; goto _test_eof; 
	_test_eof310: cs = 310; goto _test_eof; 
	_test_eof311: cs = 311; goto _test_eof; 
	_test_eof312: cs = 312; goto _test_eof; 
	_test_eof313: cs = 313; goto _test_eof; 
	_test_eof314: cs = 314; goto _test_eof; 
	_test_eof315: cs = 315; goto _test_eof; 
	_test_eof316: cs = 316; goto _test_eof; 
	_test_eof317: cs = 317; goto _test_eof; 
	_test_eof318: cs = 318; goto _test_eof; 
	_test_eof319: cs = 319; goto _test_eof; 
	_test_eof320: cs = 320; goto _test_eof; 
	_test_eof321: cs = 321; goto _test_eof; 
	_test_eof322: cs = 322; goto _test_eof; 
	_test_eof323: cs = 323; goto _test_eof; 
	_test_eof324: cs = 324; goto _test_eof; 
	_test_eof325: cs = 325; goto _test_eof; 
	_test_eof326: cs = 326; goto _test_eof; 
	_test_eof327: cs = 327; goto _test_eof; 
	_test_eof328: cs = 328; goto _test_eof; 
	_test_eof329: cs = 329; goto _test_eof; 
	_test_eof330: cs = 330; goto _test_eof; 
	_test_eof331: cs = 331; goto _test_eof; 
	_test_eof332: cs = 332; goto _test_eof; 
	_test_eof333: cs = 333; goto _test_eof; 
	_test_eof334: cs = 334; goto _test_eof; 
	_test_eof335: cs = 335; goto _test_eof; 
	_test_eof336: cs = 336; goto _test_eof; 
	_test_eof337: cs = 337; goto _test_eof; 
	_test_eof338: cs = 338; goto _test_eof; 
	_test_eof339: cs = 339; goto _test_eof; 
	_test_eof340: cs = 340; goto _test_eof; 
	_test_eof341: cs = 341; goto _test_eof; 
	_test_eof342: cs = 342; goto _test_eof; 
	_test_eof343: cs = 343; goto _test_eof; 
	_test_eof344: cs = 344; goto _test_eof; 
	_test_eof345: cs = 345; goto _test_eof; 
	_test_eof346: cs = 346; goto _test_eof; 
	_test_eof347: cs = 347; goto _test_eof; 
	_test_eof348: cs = 348; goto _test_eof; 
	_test_eof349: cs = 349; goto _test_eof; 
	_test_eof431: cs = 431; goto _test_eof; 
	_test_eof350: cs = 350; goto _test_eof; 
	_test_eof351: cs = 351; goto _test_eof; 
	_test_eof352: cs = 352; goto _test_eof; 
	_test_eof353: cs = 353; goto _test_eof; 
	_test_eof354: cs = 354; goto _test_eof; 
	_test_eof355: cs = 355; goto _test_eof; 
	_test_eof356: cs = 356; goto _test_eof; 
	_test_eof357: cs = 357; goto _test_eof; 
	_test_eof358: cs = 358; goto _test_eof; 
	_test_eof359: cs = 359; goto _test_eof; 
	_test_eof360: cs = 360; goto _test_eof; 
	_test_eof361: cs = 361; goto _test_eof; 
	_test_eof362: cs = 362; goto _test_eof; 
	_test_eof363: cs = 363; goto _test_eof; 
	_test_eof364: cs = 364; goto _test_eof; 
	_test_eof365: cs = 365; goto _test_eof; 
	_test_eof366: cs = 366; goto _test_eof; 
	_test_eof367: cs = 367; goto _test_eof; 
	_test_eof368: cs = 368; goto _test_eof; 
	_test_eof369: cs = 369; goto _test_eof; 
	_test_eof370: cs = 370; goto _test_eof; 
	_test_eof371: cs = 371; goto _test_eof; 
	_test_eof372: cs = 372; goto _test_eof; 
	_test_eof373: cs = 373; goto _test_eof; 
	_test_eof374: cs = 374; goto _test_eof; 
	_test_eof375: cs = 375; goto _test_eof; 
	_test_eof376: cs = 376; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 415: 
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 431: 
#line 163 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::clf; }
	break;
	case 394: 
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 406: 
#line 14 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.sec); }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 391: 
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 405: 
	case 419: 
#line 15 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.min); }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 402: 
	case 418: 
#line 16 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.hour); }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 416: 
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 417: 
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 389: 
#line 18 "src/panda/date/parse-date.rl"
	{ _date.mon = acc - 1; acc = 0; }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 420: 
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
#line 157 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::ansi_c; }
	break;
	case 387: 
#line 19 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.year); }
#line 159 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::dot; }
	break;
	case 395: 
	case 396: 
	case 397: 
	case 398: 
	case 399: 
	case 400: 
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
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 407: 
	case 408: 
	case 409: 
	case 410: 
	case 411: 
	case 412: 
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
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 392: 
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 403: 
#line 59 "src/panda/date/parse-date.rl"
	{
        tzi.rule[2] = tzi.rule[9]  = *(p-2);
        tzi.rule[3] = tzi.rule[10] = *(p-1);
    }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 393: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 404: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 377: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 421: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 388: 
#line 64 "src/panda/date/parse-date.rl"
	{
        tzi.rule[5] = tzi.rule[12] = *(p-2);
        tzi.rule[6] = tzi.rule[13] = *(p-1);
    }
#line 163 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::clf; }
	break;
	case 401: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
	break;
	case 413: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 381: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 425: 
#line 69 "src/panda/date/parse-date.rl"
	{
        if (!gmt_zone) gmt_zone = panda::time::tzget("GMT");
        _zone = gmt_zone;
    }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 414: 
#line 74 "src/panda/date/parse-date.rl"
	{ NSAVE(week); }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 380: 
#line 138 "src/panda/date/parse-date.rl"
	{ TZRULE("EST5EDT"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 424: 
#line 138 "src/panda/date/parse-date.rl"
	{ TZRULE("EST5EDT"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 379: 
#line 139 "src/panda/date/parse-date.rl"
	{ TZRULE("CST6CDT"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 423: 
#line 139 "src/panda/date/parse-date.rl"
	{ TZRULE("CST6CDT"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 383: 
#line 140 "src/panda/date/parse-date.rl"
	{ TZRULE("MST7MDT"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 427: 
#line 140 "src/panda/date/parse-date.rl"
	{ TZRULE("MST7MDT"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 385: 
#line 141 "src/panda/date/parse-date.rl"
	{ TZRULE("PST8PDT"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 429: 
#line 141 "src/panda/date/parse-date.rl"
	{ TZRULE("PST8PDT"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 378: 
#line 142 "src/panda/date/parse-date.rl"
	{ TZRULE("<-01:00>+01:00"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 422: 
#line 142 "src/panda/date/parse-date.rl"
	{ TZRULE("<-01:00>+01:00"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 382: 
#line 143 "src/panda/date/parse-date.rl"
	{ TZRULE("<-12:00>+12:00"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 426: 
#line 143 "src/panda/date/parse-date.rl"
	{ TZRULE("<-12:00>+12:00"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 384: 
#line 144 "src/panda/date/parse-date.rl"
	{ TZRULE("<+01:00>-01:00"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 428: 
#line 144 "src/panda/date/parse-date.rl"
	{ TZRULE("<+01:00>-01:00"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 386: 
#line 145 "src/panda/date/parse-date.rl"
	{ TZRULE("<+12:00>-12:00"); }
#line 149 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc1123; }
	break;
	case 430: 
#line 145 "src/panda/date/parse-date.rl"
	{ TZRULE("<+12:00>-12:00"); }
#line 153 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::rfc850; }
	break;
	case 390: 
#line 17 "src/panda/date/parse-date.rl"
	{ NSAVE(_date.mday); }
#line 129 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso; }
#line 135 "src/panda/date/parse-date.rl"
	{ format |= InputFormat::iso8601; }
	break;
#line 5981 "src/panda/date/parse-date.cc"
	}
	}

	_out: {}
	}

#line 209 "src/panda/date/parse-date.rl"

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
