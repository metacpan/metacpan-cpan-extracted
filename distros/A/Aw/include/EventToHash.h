/* This is part of the Aw:: Perl module.  A Perl interface to the ActiveWorks(tm) 
   libraries.  Copyright (C) 1999-2001 Daniel Yacob.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef EVENTTOHASH_H
#define EVENTTOHASH_H 1


BrokerError awxsSetHashFromEvent ( BrokerEvent event, HV * hv );

SV* getSV ( BrokerEvent event, char * key );
SV* getHV ( BrokerEvent event, char * key );

SV* _getValue ( short type, void * value, int i, bool array );
#define getValue(type, value) _getValue(type, value, 0, 0)
#define getValueI(type, value, i) _getValue(type, value, i, 1)

SV* _getAV ( BrokerEvent event, char * key, int offset, int max_n );
#define getAV( event, key ) _getAV( event, key, 0, AW_ENTIRE_SEQUENCE )
#define getAVN( event, key, offset, max_n ) _getAV( event, key, offset, max_n )


#endif /* EVENTTOHASH_H */
