
#line 1 "src/panda/date/parse-relative.rl"
#include "DateRel.h" 


#line 42 "src/panda/date/parse-relative.rl"


namespace panda { namespace date {


#line 13 "src/panda/date/parse-relative.cc"
static const int daterel_parser_start = 1;
static const int daterel_parser_first_final = 19;
static const int daterel_parser_error = 0;

static const int daterel_parser_en_main = 1;


#line 47 "src/panda/date/parse-relative.rl"

#define NSAVE(dest) { dest = acc; acc = 0; }
        
errc DateRel::parse (string_view str, int available_formats) {
    _year = _month = _day = _hour = _min = _sec = 0;
    int         cs     = daterel_parser_start;
    int64_t     acc    = 0;
    char        sign   = 0;
    const char* p      = str.data();
    const char* pe     = p + str.length();
    const char* eof    = pe;
    int         format = 0;
    
    
#line 36 "src/panda/date/parse-relative.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 45: goto tr0;
		case 80: goto st25;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr2;
	goto st0;
st0:
cs = 0;
	goto _out;
tr0:
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 61 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr2;
	goto st0;
tr2:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 76 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 68: goto tr4;
		case 77: goto tr5;
		case 89: goto tr6;
		case 100: goto tr4;
		case 104: goto tr7;
		case 109: goto tr8;
		case 115: goto tr9;
		case 121: goto tr6;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr2;
	goto st0;
tr4:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 103 "src/panda/date/parse-relative.cc"
	if ( (*p) == 32 )
		goto tr25;
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr25;
	goto st0;
tr25:
#line 23 "src/panda/date/parse-relative.rl"
	{ NSAVE(_day); }
	goto st4;
tr26:
#line 24 "src/panda/date/parse-relative.rl"
	{ NSAVE(_month); }
	goto st4;
tr27:
#line 25 "src/panda/date/parse-relative.rl"
	{ NSAVE(_year); }
	goto st4;
tr28:
#line 22 "src/panda/date/parse-relative.rl"
	{ NSAVE(_hour); }
	goto st4;
tr29:
#line 21 "src/panda/date/parse-relative.rl"
	{ NSAVE(_min); }
	goto st4;
tr30:
#line 20 "src/panda/date/parse-relative.rl"
	{ NSAVE(_sec); }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 137 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 32: goto st4;
		case 45: goto tr0;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr2;
	} else if ( (*p) >= 9 )
		goto st4;
	goto st0;
tr5:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 161 "src/panda/date/parse-relative.cc"
	if ( (*p) == 32 )
		goto tr26;
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr26;
	goto st0;
tr6:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 180 "src/panda/date/parse-relative.cc"
	if ( (*p) == 32 )
		goto tr27;
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr27;
	goto st0;
tr7:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st22;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
#line 199 "src/panda/date/parse-relative.cc"
	if ( (*p) == 32 )
		goto tr28;
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr28;
	goto st0;
tr8:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st23;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
#line 218 "src/panda/date/parse-relative.cc"
	if ( (*p) == 32 )
		goto tr29;
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr29;
	goto st0;
tr9:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 237 "src/panda/date/parse-relative.cc"
	if ( (*p) == 32 )
		goto tr30;
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr30;
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	switch( (*p) ) {
		case 45: goto tr31;
		case 84: goto st28;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr11;
	goto st0;
tr31:
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 262 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr11;
	goto st0;
tr11:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 277 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 68: goto tr12;
		case 77: goto tr13;
		case 87: goto tr14;
		case 89: goto tr15;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr11;
	goto st0;
tr12:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 300 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 45: goto tr33;
		case 84: goto tr35;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr34;
	goto st0;
tr33:
#line 23 "src/panda/date/parse-relative.rl"
	{ NSAVE(_day); }
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 318 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr16;
	goto st0;
tr16:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st8;
tr34:
#line 23 "src/panda/date/parse-relative.rl"
	{ NSAVE(_day); }
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 342 "src/panda/date/parse-relative.cc"
	if ( (*p) == 87 )
		goto tr14;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr16;
	goto st0;
tr14:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 361 "src/panda/date/parse-relative.cc"
	if ( (*p) == 84 )
		goto tr36;
	goto st0;
tr35:
#line 23 "src/panda/date/parse-relative.rl"
	{ NSAVE(_day); }
	goto st28;
tr44:
#line 24 "src/panda/date/parse-relative.rl"
	{ NSAVE(_month); }
	goto st28;
tr47:
#line 25 "src/panda/date/parse-relative.rl"
	{ NSAVE(_year); }
	goto st28;
tr36:
#line 27 "src/panda/date/parse-relative.rl"
	{
        _day += acc*7;
        acc = 0;
    }
	goto st28;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
#line 388 "src/panda/date/parse-relative.cc"
	if ( (*p) == 45 )
		goto tr37;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr17;
	goto st0;
tr37:
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st9;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
#line 402 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr17;
	goto st0;
tr17:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 417 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 72: goto tr18;
		case 77: goto tr19;
		case 83: goto tr20;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr17;
	goto st0;
tr18:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 439 "src/panda/date/parse-relative.cc"
	if ( (*p) == 45 )
		goto tr38;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr39;
	goto st0;
tr38:
#line 22 "src/panda/date/parse-relative.rl"
	{ NSAVE(_hour); }
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 455 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr21:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st12;
tr39:
#line 22 "src/panda/date/parse-relative.rl"
	{ NSAVE(_hour); }
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 479 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 77: goto tr19;
		case 83: goto tr20;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr19:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 500 "src/panda/date/parse-relative.cc"
	if ( (*p) == 45 )
		goto tr40;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr41;
	goto st0;
tr40:
#line 21 "src/panda/date/parse-relative.rl"
	{ NSAVE(_min); }
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 516 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr22;
	goto st0;
tr22:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st14;
tr41:
#line 21 "src/panda/date/parse-relative.rl"
	{ NSAVE(_min); }
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 540 "src/panda/date/parse-relative.cc"
	if ( (*p) == 83 )
		goto tr20;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr22;
	goto st0;
tr20:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 559 "src/panda/date/parse-relative.cc"
	goto st0;
tr13:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 574 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 45: goto tr42;
		case 84: goto tr44;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr43;
	goto st0;
tr42:
#line 24 "src/panda/date/parse-relative.rl"
	{ NSAVE(_month); }
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 592 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr23;
	goto st0;
tr23:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st16;
tr43:
#line 24 "src/panda/date/parse-relative.rl"
	{ NSAVE(_month); }
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 616 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 68: goto tr12;
		case 87: goto tr14;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr23;
	goto st0;
tr15:
#line 13 "src/panda/date/parse-relative.rl"
	{
        if (sign == '-') {
            acc = -acc;
            sign = 0;
        }
    }
	goto st33;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
#line 637 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 45: goto tr45;
		case 84: goto tr47;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr46;
	goto st0;
tr45:
#line 25 "src/panda/date/parse-relative.rl"
	{ NSAVE(_year); }
#line 6 "src/panda/date/parse-relative.rl"
	{ sign = *p; }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 655 "src/panda/date/parse-relative.cc"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
tr24:
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st18;
tr46:
#line 25 "src/panda/date/parse-relative.rl"
	{ NSAVE(_year); }
#line 8 "src/panda/date/parse-relative.rl"
	{
        acc *= 10;
        acc += (*p) - '0';
    }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 679 "src/panda/date/parse-relative.cc"
	switch( (*p) ) {
		case 68: goto tr12;
		case 77: goto tr13;
		case 87: goto tr14;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 25: 
	case 28: 
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 24: 
#line 20 "src/panda/date/parse-relative.rl"
	{ NSAVE(_sec); }
#line 35 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::simple; }
	break;
	case 31: 
#line 20 "src/panda/date/parse-relative.rl"
	{ NSAVE(_sec); }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 23: 
#line 21 "src/panda/date/parse-relative.rl"
	{ NSAVE(_min); }
#line 35 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::simple; }
	break;
	case 30: 
#line 21 "src/panda/date/parse-relative.rl"
	{ NSAVE(_min); }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 22: 
#line 22 "src/panda/date/parse-relative.rl"
	{ NSAVE(_hour); }
#line 35 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::simple; }
	break;
	case 29: 
#line 22 "src/panda/date/parse-relative.rl"
	{ NSAVE(_hour); }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 19: 
#line 23 "src/panda/date/parse-relative.rl"
	{ NSAVE(_day); }
#line 35 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::simple; }
	break;
	case 26: 
#line 23 "src/panda/date/parse-relative.rl"
	{ NSAVE(_day); }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 20: 
#line 24 "src/panda/date/parse-relative.rl"
	{ NSAVE(_month); }
#line 35 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::simple; }
	break;
	case 32: 
#line 24 "src/panda/date/parse-relative.rl"
	{ NSAVE(_month); }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 21: 
#line 25 "src/panda/date/parse-relative.rl"
	{ NSAVE(_year); }
#line 35 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::simple; }
	break;
	case 33: 
#line 25 "src/panda/date/parse-relative.rl"
	{ NSAVE(_year); }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
	case 27: 
#line 27 "src/panda/date/parse-relative.rl"
	{
        _day += acc*7;
        acc = 0;
    }
#line 39 "src/panda/date/parse-relative.rl"
	{ format |= InputFormat::iso8601; }
	break;
#line 812 "src/panda/date/parse-relative.cc"
	}
	}

	_out: {}
	}

#line 61 "src/panda/date/parse-relative.rl"
    
    if (cs < daterel_parser_first_final && (available_formats & InputFormat::iso8601i)) {
        _year = _month = _day = _hour = _min = _sec = 0;
        // ISO8601 interval format: "iso8601_date/iso8601_relative"
        auto pos = str.find('/');
        if (pos == string::npos) return errc::parser_error;
        format = InputFormat::iso8601i;
        
        _from = Date(str.substr(0, pos), {}, Date::InputFormat::iso8601);
        if (_from->error()) return errc::parser_error;

        return parse(str.substr(pos+1), InputFormat::iso8601d);
    }
    
    if (!(format & available_formats)) {
        _year = _month = _day = _hour = _min = _sec = 0;
        return errc::parser_error;
    }
    
    return errc::ok;
}

}}
