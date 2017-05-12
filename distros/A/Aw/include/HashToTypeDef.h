/* This is part of the Aw:: Perl module.  A Perl interface to the ActiveWorks(tm)
   libraries.  Copyright (C) 1999-2000 Daniel Yacob.

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

#ifndef HASHTOTYPEDEF_H
#define HASHTOTYPEDEF_H 1

BrokerError awxsSetFieldType ( BrokerAdminTypeDef type_def, char * field_name, SV* sv );
BrokerError awxsSetSequenceFieldType ( BrokerAdminTypeDef type_def, char * field_name, AV* av );
BrokerError awxsSetStructFieldType ( BrokerAdminTypeDef type_def, char * field_name, HV* hv );
BrokerError awxsSetEventTypeDefFromHash ( BrokerAdminTypeDef type_def, HV * hv );
BrokerError awxsNavigateHash ( BrokerAdminTypeDef type_def, char * root_field_name, HV * hv );
BrokerError awxsSetFieldDef ( BrokerAdminTypeDef type_def, char * field_name, SV* object );


#endif /* HASHTOTYPEDEF_H */
