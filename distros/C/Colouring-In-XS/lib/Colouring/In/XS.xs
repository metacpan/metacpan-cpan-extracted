#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

struct HS {
	double r;
	double g;
	double b;
	double max;
	double min;
	double d;
	double h;
	double s;
	double l;
	double v;
};

struct HSL {
	int h;
	double s;
	double l;
	double a;
};

static HV * MESSAGES;

static SV * new (SV * class, HV * hash) {
        dTHX;
        if (SvTYPE(class) != SVt_PV) {
                char * name = HvNAME(SvSTASH(SvRV(class)));
                class = newSVpv(name, strlen(name));
        }
        return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, 0));
}

static AV * colour_array (SV * self) {
	dTHX;
	AV * colour = (AV*)SvRV(*hv_fetch((HV*)SvRV(self), "colour", 6, 0));

	SV * r = *av_fetch(colour, 0, 0);
	SV * g = *av_fetch(colour, 1, 0);
	SV * b = *av_fetch(colour, 2, 0);

	if ( !SvOK(r) ) {
		av_store(colour, 0, newSVnv(255));
	}

	if ( !SvOK(g) ) {
		av_store(colour, 1, newSVnv(255));
	}

	if ( !SvOK(b) ) {
		av_store(colour, 2, newSVnv(255));
	}

	return colour;
}

void croak_message (char * key, char * fb) {
	dTHX;
	if (hv_exists(MESSAGES, key, strlen(key))) {
		SV * msg  = *hv_fetch(MESSAGES, key, strlen(key), 0);
		if (SvTRUE(msg)) {
			fb = SvPV_nolen(msg);
		}
	}
	croak("%s", fb);
}

static double min (double first, double second) {
	return first < second ? first : second;
}

static double max (double first, double second) {
	return first > second ? first : second;
}

static double clamp (double first, double second) {
	return min( max(first, 0), second);
}

static double rround (double val, int dp) {
	int charsNeeded = 1 + snprintf(NULL, 0, "%.*f", dp, val);
	char * buffer = malloc(charsNeeded);
	snprintf(buffer, charsNeeded, "%.*f", dp, val);
	double result = atof(buffer);
	free(buffer);
	return result;
}

static int numIs (SV * num) {
	dTHX;
	char * str = SvPV_nolen(num);
	char tmp[256];
	for(int i=0;str[i];i++) {
 	 	int j=0;
  		while(str[i]>='0' && str[i]<='9') {
     			tmp[j]=str[i];
     			i++;
     			j++;
  		}
		break;
	}
 	return strlen(tmp) >= 1 ? 1 : 0;
}

static char * percent (double num) {
	char * ret = malloc(sizeof(char)*5);
	sprintf(ret, "%.0f%s", (num * 100), "%");
	return ret;
}

static double depercent (char * num) {
	return atof(num) / 100.;
}

char* join(char* strings[], char* seperator, int count) {
	char* str = NULL;             /* Pointer to the joined strings  */
	size_t total_length = 0;      /* Total length of joined strings */
	int i = 0;                    /* Loop counter                   */

	/* Find total length of joined strings */
	for (i = 0; i < count; i++) total_length += strlen(strings[i]);
	total_length++;     /* For joined string terminator */
	total_length += strlen(seperator) * (count - 1); // for seperators

	str = (char*) malloc(total_length);  /* Allocate memory for joined strings */
	str[0] = '\0';                      /* Empty string we can append to      */

	/* Append all the strings */
	for (i = 0; i < count; i++) {
		strcat(str, strings[i]);
		if (i < (count - 1)) strcat(str, seperator);
	}

	return str;
}

static double hue (double h, double m1, double m2) {
	h = h < 0 ? h + 1 : h > 1 ? h - 1 : h;
	if ( h * 6. < 1 ) {
		return m1 + ( m2 - m1 ) * h * 6;
	} else if ( h * 2. < 1 ) {
		return m2;
	} else if ( h * 3. < 2 ) {
		return m1 + ( m2 - m1 ) * ( (2 / 3.) - h ) * 6;
	}
	return m1;
}

static double scaled (SV * num, int size) {
	dTHX;
	char * number = SvPV_nolen(num);
	double n = atof(number);
	if (number[strlen(number)] == '%') {
		return (n * size) / 100;
	} else {
		return n;
	}
}

int hex2int(char *hex) {
	int val = 0;
	while (*hex) {
		int byte = *hex++; 
		if (byte >= '0' && byte <= '9') byte = byte - '0';
		else if (byte >= 'a' && byte <='f') byte = byte - 'a' + 10;
		else if (byte >= 'A' && byte <='F') byte = byte - 'A' + 10;    
		else croak_message("INVALID_HEX", "Cannot convert hex colour format");
		val = (val << 4) | (byte & 0xF);
	}
	return val;
}

static SV * hex2rgb (char * colour) {
	dTHX;
	AV * color = newAV();
	int l = strlen(colour);
	if (l == 3) {
		for (int i = 0; i < 3; i++) {
			char * hex = malloc(sizeof(char)*22);
			sprintf(hex, "%c%c", colour[i], colour[i]);
			av_push(color, newSViv(hex2int(hex)));
		}
	} else if (l == 6) {
		for (int i = 0; i < 6; i += 2) {
			char * hex = malloc(sizeof(char)*22);;
			sprintf(hex, "%c%c", colour[i], colour[i + 1]);
			av_push(color, newSViv(hex2int(hex)));
		}
	} else {
		croak("hex length must be 3 or 6");
	}
	return newRV_noinc((SV*)color);
}

static AV * numbers (char * colour) {
	dTHX;
	AV * color = newAV();
	int len = strlen(colour);
	char temp[6] = "";
	for (int i = 0; i < len; i++) {
		if ((colour[i] >= '0' && colour[i] <= '9') || colour[i] == '.') {
			strncat(temp, &colour[i], 1);
		} else if (strlen(temp) >= 1 && atol(temp) >= 0) {
			av_push(color, newSVnv(atol(temp)));
			memset(temp,0,strlen(temp));
		}
	}

	if (av_len(color) <= 1) {
		croak_message("INVALID_RGB", "Cannot convert rgb colour format");
	}

	return color;
}

static SV * rgb2rgb (char * colour) {
	dTHX;
	return newRV_noinc((SV*)numbers(colour));
}

static SV * hsl2rgb (double h, double s, double l, double a) {
	dTHX;
	AV * color = newAV();
	int lame = (int)h;
	h = ( lame % 360 ) / 360.;
	if (s > 1 || l > 1) {
		s = s / 100.;
		l = l / 100.;
	}
	double m2 = l <= 0.5 ? l * ( s + 1 ) : l + s - l * s;
	double m1 = l * 2 - m2;
	av_push(color, newSViv(clamp(hue(h + (1 / 3.), m1, m2), 1) * 255));
	av_push(color, newSViv(clamp(hue(h, m1, m2), 1) * 255));
	av_push(color, newSViv(clamp(hue(h - (1 / 3.), m1, m2), 1) * 255));
	return newRV_noinc((SV*)color);
}

static SV * convertColour (char * colour) {
	dTHX;
	if (colour[0] == '#') {
		colour++;
		return hex2rgb(colour);
	} else if (colour[0] == 'r' && colour[1] == 'g' && colour[2] == 'b') {
		return rgb2rgb(colour);
	} else if (colour[0] == 'h' && colour[1] == 's' && colour[2] == 'l') {
		AV * nums = numbers(colour);
		int len = av_len(nums);
		double h = len >= 0 ? SvNV(*av_fetch(nums, 0, 0)) : 0;
		double s = len >= 1 ? SvNV(*av_fetch(nums, 1, 0)) : 0;
		double l = len >= 2 ? SvNV(*av_fetch(nums, 2, 0)) : 0;
		double a = len >= 3 ? SvNV(*av_fetch(nums, 3, 0)) : 1;
		return hsl2rgb(h, s, l, a);
	}
	croak_message("INVALID_COLOUR", "Cannot convert the colour format");
	return newSVpv("never", 5);
}

static void sprintf_colour (SV * self, char * css, char * pattern) {
	dTHX;
	int colour[3] = { 255, 255, 255 };
	AV * color = colour_array(self);
	int len = av_len(color);
	colour[0] = len >= 0 ? SvIV(*av_fetch(color, 0, 0)) : 255;
	colour[1] = len >= 1 ? SvIV(*av_fetch(color, 1, 0)) : 255;
	colour[2] = len >= 2 ? SvIV(*av_fetch(color, 2, 0)) : 255;
	sprintf(css, pattern, colour[0], colour[1], colour[2]);
}

static void sprintf_rgba (SV * self, char * css) {
	dTHX;
	int colour[3] = { 255, 255, 255 };
	AV * color = colour_array(self);
	double alpha = SvNV(*hv_fetch((HV*)SvRV(self), "alpha", 5, 0));
	int len = av_len(color);
	colour[0] = len >= 0 ? SvIV(*av_fetch(color, 0, 0)) : 255;
	colour[1] = len >= 1 ? SvIV(*av_fetch(color, 1, 0)) : 255;
	colour[2] = len >= 2 ? SvIV(*av_fetch(color, 2, 0)) : 255;
	sprintf(css, "rgba(%d,%d,%d,%.2g)", colour[0], colour[1], colour[2], alpha);
}

static struct HS rgb2hs (SV * self) {
	dTHX;
	struct HS hs;
	AV * color = colour_array(self);
	int len = av_len(color);
	hs.r = len >= 0 ? SvIV(*av_fetch(color, 0, 0)) / 255.00 : 1;
	hs.g = len >= 1 ? SvIV(*av_fetch(color, 1, 0)) / 255.00 : 1;
	hs.b = len >= 2 ? SvIV(*av_fetch(color, 2, 0)) / 255.00 : 1;
	hs.max = max(max(hs.r, hs.g), hs.b);
	hs.min = min(min(hs.r, hs.g), hs.b);
	hs.d = hs.max - hs.min;
	return hs;
}

static struct HSL asHSL (SV * self) {
	dTHX;
	struct HS hs = rgb2hs(self);

	hs.l = ( hs.max + hs.min ) / 2;

	if ( hs.max == hs.min ) {
		hs.h = hs.s = 0;
	} else {
		hs.s = hs.l > 0.5 ? (hs.d / (2 - hs.max - hs.min)) : (hs.d / (hs.max + hs.min));	
		hs.h = (hs.max == hs.r)
			? (hs.g - hs.b) / hs.d + ( hs.g < hs.b ? 6 : 0 )
			: (hs.max == hs.g)
				? (hs.b - hs.r) / hs.d + 2
				: (hs.r - hs.g) / hs.d + 4;
		hs.h = hs.h / 6;
	}

	struct HSL hsl;
	hsl.h = hs.h * 360;
	hsl.s = hs.s;
	hsl.l = hs.l;
	hsl.a = SvNV(*hv_fetch((HV*)SvRV(self), "alpha", 5, 0));
	return hsl;
}

static SV * new_color (SV * class, SV * colour, SV * a) {
        dTHX;
	HV * hash = newHV();
	if (SvTYPE(SvRV(colour)) == SVt_PVAV) {
		if (av_len((AV*)colour) == 3) {
			a = av_pop((AV*)colour);
		}
		hv_store(hash, "colour", 6, newSVsv(colour), 0);
	} else {
		colour = convertColour(SvPV_nolen(colour));
		if (av_len((AV*)SvRV(colour)) == 3) {
			a = av_pop((AV*)SvRV(colour));
		}
		hv_store(hash, "colour", 6, colour, 0);
	}
	hv_store(hash, "alpha", 5, numIs(a) ? newSVsv(a) : newSViv(1), 0);
	return new(class, hash);
}

static SV * mix (SV * colour1, SV * colour2, int weight) {
	dTHX;

	SV * class = newSVpv("Colouring::In::XS", 17);
	if (SvTYPE(colour1) == SVt_PV) {
		colour1 = new_color(class, colour1, newSVnv(1));
	}
	if (SvTYPE(colour2) == SVt_PV) {
		colour2 = new_color(class, colour2, newSVnv(1));
	}
	struct HSL hsl1 = asHSL(colour1);
	struct HSL hsl2 = asHSL(colour2);

	double w = weight / 100.;

	double a = hsl1.a - hsl2.a;

	w = (w * 2) - 1;
	double w1 = (((w * a == -1) ? w : (w + a) / ( 1 + w * a )) + 1 ) / 2;
	double w2 = 1 - w1;

	AV * c = newAV();

	AV * c1 = (AV*)SvRV(*hv_fetch((HV*)SvRV(colour1), "colour", 6, 0));
	AV * c2 = (AV*)SvRV(*hv_fetch((HV*)SvRV(colour2), "colour", 6, 0));

	double r1 = SvNV(*av_fetch(c1, 0, 0));
	double g1 = SvNV(*av_fetch(c1, 1, 0));
	double b1 = SvNV(*av_fetch(c1, 2, 0));
	double a1 = SvNV(*hv_fetch((HV*)SvRV(colour1), "alpha", 5, 0));

	double r2 = SvNV(*av_fetch(c2, 0, 0));
	double g2 = SvNV(*av_fetch(c2, 1, 0));
	double b2 = SvNV(*av_fetch(c2, 2, 0));
	double a2 = SvNV(*hv_fetch((HV*)SvRV(colour2), "alpha", 5, 0));

	
	av_push(c, newSVnv((r1 * w1) + (r2 * w2)));
	av_push(c, newSVnv((g1 * w1) + (g2 * w2)));
	av_push(c, newSVnv((b1 * w1) + (b2 * w2)));

	return new_color(class, newRV_noinc((SV*)c), newSVnv((a1 * w) + (a2 * 1 - w)));
}


MODULE = Colouring::In::XS  PACKAGE = Colouring::In::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

void
set_messages(...)
	CODE:
		AV * array = av_make(items, MARK+1);
		MESSAGES = (HV*)SvRV(av_pop(array));

SV *
new(...)
        CODE:
		SV * colour = ST(1);
		SV * a = (items > 2) && SvOK(ST(2)) ? ST(2) : newSViv(1);
		RETVAL = new_color(ST(0), colour, a);
        OUTPUT:
                RETVAL

SV *
rgb(self, red, green, blue, ...)
	SV * self
	SV * red
	SV * green
	SV * blue
	CODE:
		double r = scaled(red, 255);
		double g = scaled(green, 255);
		double b = scaled(blue, 255);		
		AV * colour = newAV();
		av_push(colour, newSVnv(r));
		av_push(colour, newSVnv(g));
		av_push(colour, newSVnv(b));
		double a = clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		RETVAL = new_color(self, newRV_noinc((SV*)colour), newSVnv(a)); 
	OUTPUT:
		RETVAL

SV *
rgba(self, red, green, blue, ...)
	SV * self
	SV * red
	SV * green
	SV * blue
	CODE:
		double r = scaled(red, 255);
		double g = scaled(green, 255);
		double b = scaled(blue, 255);
		AV * colour = newAV();
		av_push(colour, newSVnv(r));
		av_push(colour, newSVnv(g));
		av_push(colour, newSVnv(b));
		double a = clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		RETVAL = new_color(self, newRV_noinc((SV*)colour), newSVnv(a)); 
	OUTPUT:
		RETVAL

SV *
hsl(self, h, s, l, ...)
	SV * self
	SV * h
	SV * s
	SV * l
	CODE:
		double a = clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		SV * colour = hsl2rgb(SvNV(h), SvNV(s), SvNV(l), a);
		RETVAL = new_color(self, colour, newSVnv(a)); 
	OUTPUT:
		RETVAL

SV *
hsla(self, h, s, l, ...)
	SV * self
	SV * h
	SV * s
	SV * l
	CODE:
		double a = clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		SV * colour = hsl2rgb(SvNV(h), SvNV(s), SvNV(l), a);
		RETVAL = new_color(self, colour, newSVnv(a)); 
	OUTPUT:
		RETVAL

SV *
toCSS(self, ...)
	SV * self
	CODE:
		int r = items > 1 ? SvIV(ST(1)) : 0;
		int s = items > 2 ? SvIV(ST(1)) : 0;
		double alpha = SvNV(*hv_fetch((HV*)SvRV(self), "alpha", 5, 0));
		alpha = rround(alpha, r);
		if (alpha == 1) {
			char css[8];
			sprintf_colour(self, css, "#%02lx%02lx%02lx");
			if (!s) {
				int min = 1;
				for (int i = 1; i < 7; i += 2) {
					if (css[i] != css[i+1]) {
						min = 0;
						break;
					}
				}
				if (min) {
					sprintf(css, "#%c%c%c", css[1], css[3], css[5]);
				}
			}
			RETVAL = newSVpvn(css, strlen(css));
		} else {
			char * css = malloc(sizeof(char)*22);
			sprintf_rgba(self, css);
			RETVAL = newSVpvn(css, strlen(css));
		}
	OVERLOAD: \"\"
	OUTPUT:
		RETVAL

SV *
toTerm(self)
	SV * self
	CODE:
		char * css = malloc(sizeof(char)*12);
		sprintf_colour(self, css, "r%dg%db%d");
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toOnTerm(self)
	SV * self
	CODE:
		char * css = malloc(sizeof(char)*15);
		sprintf_colour(self, css, "on_r%dg%db%d");
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toRGB(self, ...)
	SV * self
	CODE:
		SV * alpha = *hv_fetch((HV*)SvRV(self), "alpha", 5, 0);
		if (numIs(alpha) && SvIV(alpha) != 1) {
			char * css = malloc(sizeof(char)*22);
			sprintf_rgba(self, css);
			RETVAL = newSVpvn(css, strlen(css));
		} else {
			char * css = malloc(sizeof(char)*24);
			sprintf_colour(self, css, "rgb(%d,%d,%d)");
			RETVAL = newSVpvn(css, strlen(css));
		}
	OUTPUT:
		RETVAL

SV *
toRGBA(self, ...)
	SV * self
	CODE:
		char * css = malloc(sizeof(char)*22);
		sprintf_rgba(self, css);
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toHEX(self, ...)
	SV * self
	CODE:
		char css[8];
		sprintf_colour(self, css, "#%02lx%02lx%02lx");
		if (! SvTRUE(ST(1)) || (SvTRUE(ST(1)) && SvTYPE(ST(1)) != SVt_IV)) {
			int min = 1;
			for (int i = 1; i < 7; i += 2) {
				if (css[i] != css[i+1]) {
					min = 0;
					break;
				}
			}
			if (min) {
				sprintf(css, "#%c%c%c", css[1], css[3], css[5]);
			}
		}
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toHSL(self)
	SV * self
	CODE:
		struct HSL colour = asHSL(self); 
		char css[30];
		sprintf(css, "hsl(%d,%s,%s)", colour.h, percent(colour.s), percent(colour.l));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toHSV(self)
	SV * self
	CODE:
		struct HS colour = rgb2hs(self);
		
		colour.s = (colour.max == 0 ) ? colour.max : colour.d / colour.max;

		if (colour.max == colour.min) {
			colour.h = 0;
		} else {
			colour.h = (colour.max == colour.r)
				? (colour.g - colour.b) / colour.d + ( colour.g < colour.b ? 6 : 0 )
				: (colour.max == colour.g)
					? (colour.b - colour.r) / colour.d + 2
					: (colour.r - colour.g) / colour.d + 4;
			colour.h = colour.h / 6;
		}
		char css[30];
		sprintf(css, "hsv(%.0f,%s,%s)", colour.h * 360, percent(colour.s), percent(colour.max));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
lighten(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		double amount = depercent(SvPV_nolen(amt));

		if (SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0) {
			double l = hsl.l || 1.;	
			hsl.l = hsl.l + clamp(l * amount, 1);
		} else {
			hsl.l = hsl.l + clamp(amount, 1);
		}

		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL

SV *
darken(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		double amount = depercent(SvPV_nolen(amt));
	
		if (SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0) {
			hsl.l = hsl.l - clamp(hsl.l * amount, 1);
		} else {
			hsl.l = hsl.l - clamp(amount, 1);
		}

		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL


SV *
fade(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		hsl.a = depercent(SvPV_nolen(amt));
		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL


SV *
fadeout(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		double amount = depercent(SvPV_nolen(amt));
		hsl.a -= clamp((items > 2 && strcmp(SvPV_nolen(ST(2)), "relative") == 0) ? hsl.a * amount : amount, 1);
		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL

SV *
fadein(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		double amount = depercent(SvPV_nolen(amt));
		hsl.a += clamp((items > 2 && strcmp(SvPV_nolen(ST(2)), "relative") == 0) ? hsl.a * amount : amount, 1);
		hsl.a = clamp(hsl.a, 1);
		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL

SV *
mix (colour1, colour2, ...)
	SV * colour1
	SV * colour2
	CODE:
		int weight = 50;
		if (SvOK(ST(2)) && SvIV(ST(2)) != 0) {
			weight = SvIV(ST(2));
		}
		RETVAL = mix(colour1, colour2, weight);
	OUTPUT:
		RETVAL

SV *
tint (colour, ...)
	SV * colour
	CODE:
		int weight = 50;
		if (SvOK(ST(2)) && SvIV(ST(2)) != 0) {
			weight = SvIV(ST(2));
		}
		SV * white = newSVpv("rgb(255,255,255)", 16);
		RETVAL = mix(white, colour, weight);
	OUTPUT:
		RETVAL

SV *
shade (colour, ...)
	SV * colour
	CODE:
		int weight = 50;
		if (SvOK(ST(2)) && SvIV(ST(2)) != 0) {
			weight = SvIV(ST(2));
		}
		SV * black = newSVpv("rgb(0,0,0)", 10);
		RETVAL = mix(black, colour, weight);
	OUTPUT:
		RETVAL


SV * 
saturate (colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		double amount = depercent(SvPV_nolen(amt));
		hsl.s += clamp((items > 2 && strcmp(SvPV_nolen(ST(2)), "relative") == 0) ? hsl.s * amount : amount, 1);
		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL	

SV *
desaturate (colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		double amount = depercent(SvPV_nolen(amt));
		hsl.s -= clamp((items > 2 && strcmp(SvPV_nolen(ST(2)), "relative") == 0) ? hsl.s * amount : amount, 1);
		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL	


SV *
greyscale (colour)
	SV * colour
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		if (SvTYPE(colour) == SVt_PV) {
			colour = new_color(class, colour, newSVnv(1));
		}
		struct HSL hsl = asHSL(colour);
		hsl.s -= 1.;
		colour = hsl2rgb(hsl.h, hsl.s, hsl.l, hsl.a);
		RETVAL = new_color(class, colour, newSVnv(hsl.a)); 
	OUTPUT:
		RETVAL

	
void
colour(self)
        SV * self
        CODE:
                int i = 0;
		AV * colour = colour_array(self);
                int len = av_len(colour);
                for (i = 0; i <= len; i++) {
                        ST(i) = newSVsv(*av_fetch(colour, i, 0));
                }
                XSRETURN(i);

SV *
get_message(msg)
	SV * msg
	CODE:
		char * key = SvPV_nolen(msg);
		RETVAL = *hv_fetch(MESSAGES, key, strlen(key), 0);
	OUTPUT:
		RETVAL
