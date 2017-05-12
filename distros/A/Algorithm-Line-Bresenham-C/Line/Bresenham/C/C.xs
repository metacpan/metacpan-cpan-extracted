/* 
   it is a C version Algorithm::Line::Bresenham to speed up a bit. 
   LiloHuang @ 2008, kenwu@cpan.org
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Algorithm::Line::Bresenham::C		PACKAGE = Algorithm::Line::Bresenham::C		

void circle(int y, int x, int radius)
PPCODE:
	AV * point;
	int curr_x = 0;
	int curr_y = radius;
	int d = 3 - (radius << 1);
	
	while(1) {
		EXTEND(SP, 8);

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y + curr_y));
		av_push(point, newSViv(x + curr_x));	
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y + curr_y));
		av_push(point, newSViv(x - curr_x));	
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y - curr_y));
		av_push(point, newSViv(x + curr_x));	
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y - curr_y));
		av_push(point, newSViv(x - curr_x));	
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y + curr_x));
		av_push(point, newSViv(x + curr_y));	
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y + curr_x));
		av_push(point, newSViv(x - curr_y));	
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y - curr_x));
		av_push(point, newSViv(x + curr_y));	
		PUSHs(sv_2mortal(newRV((SV *)point)));			

		point = (AV *)sv_2mortal((SV *)newAV());	
		av_push(point, newSViv(y - curr_x));
		av_push(point, newSViv(x - curr_y));
		PUSHs(sv_2mortal(newRV((SV *)point)));	                

		if(curr_x >= curr_y) break;
		if (d < 0) {
			d += (curr_x << 2) + 6;
		}else{
			d += ((curr_x - curr_y) << 2) + 10;
			curr_y -= 1;
		}
		curr_x++;
	}

void line(int from_y, int from_x, int to_y, int to_x)
PPCODE:
	AV * point;
	int curr_maj, curr_min, to_maj, to_min, delta_maj, delta_min;
	int delta_y = to_y - from_y;
	int delta_x = to_x - from_x;
	int dir = 0;
	if(abs(delta_y) > abs(delta_x)) dir = 1;
	
	if(dir) {
		curr_maj = from_y;
		curr_min = from_x;
		to_maj = to_y;
		to_min = to_x;
		delta_maj = delta_y;
		delta_min = delta_x;
	}else{
		curr_maj = from_x;
		curr_min = from_y;
		to_maj = to_x;
		to_min = to_y;
		delta_maj = delta_x;
		delta_min = delta_y;	
	}
	int inc_maj, inc_min;
	if(!delta_maj) inc_maj = 0;
	else inc_maj = (abs(delta_maj)==delta_maj ? 1 : -1);
	
	if(!delta_min) inc_min = 0;
	else inc_min = (abs(delta_min)==delta_min ? 1 : -1);
	
	delta_maj = abs(delta_maj)+0;
	delta_min = abs(delta_min)+0;
	
	int d = (delta_min << 1) - delta_maj;
	int d_inc1 = (delta_min << 1);
	int d_inc2 = ((delta_min - delta_maj) << 1);	
	
	while(1) {     
		EXTEND(SP, 1);
		point = (AV *)sv_2mortal((SV *)newAV());	
		if(dir) {
			av_push(point, newSViv(curr_maj));
			av_push(point, newSViv(curr_min));	
		}else{
			av_push(point, newSViv(curr_min));	
			av_push(point, newSViv(curr_maj));
		}
		PUSHs(sv_2mortal(newRV((SV *)point)));	

		if(curr_maj == to_maj) break;
        curr_maj += inc_maj;
		if (d < 0) {
				d += d_inc1;
		}else{
				d += d_inc2;
				curr_min += inc_min;
		}
	}