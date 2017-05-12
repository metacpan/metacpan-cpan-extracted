#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "bieH5.h"

//calculate data buffer size
long long sizeofH5D(hid_t data_id, hid_t dType_id, hid_t mType_id, hid_t space_id) {
long long data_size  = H5Sget_simple_extent_npoints(space_id) * H5Tget_size(mType_id);
return data_size;
}

//return unpack code
const char * getH5DCode(hid_t nativeType)
{
if(H5Tequal(nativeType, H5T_NATIVE_CHAR)) {
return "c*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_SCHAR)) {
return "c*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_UCHAR)) {
return "C*";
}   
else if(H5Tequal(nativeType, H5T_NATIVE_SHORT)) {
return "s!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_USHORT)) {
return "S!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_INT)) {
return "i!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_UINT)) {
return "I!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_LONG)) {
return "l!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_ULONG)) {
return "L!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_LLONG)) {
return "q*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_ULLONG)) {
return "Q*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_FLOAT)) {
return "f*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_DOUBLE)) {
return "d*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_LDOUBLE)) {
return "D*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_HSIZE)) {
return "i!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_HSSIZE)) {
return "i!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_HERR)) {
return "i!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_HBOOL)) {
return "i!*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_B8)) {
return "C*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_B16)) {
return "S*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_B32)) {
return "L*";
}
else if(H5Tequal(nativeType, H5T_NATIVE_B64)) {
return "Q*";
}   
else {
return "";
}
}
herr_t listKidsNames(hid_t id, const char* name, const H5L_info_t* info, void* res) {
res = (AV*) res;
I32 key = av_len(res) + 1;
av_extend(res, key);
av_store(res, key, newSVpv(name, 0));
return 0;
}

herr_t listKids(hid_t id, const char* name, const H5O_info_t* info, void* res) {
res = (HV*) res;
char* ptr;
switch(info->type) {
case H5O_TYPE_GROUP:
ptr = malloc(6);
ptr = strcpy(ptr, "group");
break;
case H5O_TYPE_DATASET:
ptr = malloc(8);
ptr = strcpy(ptr, "dataset");
break;
default:
ptr = malloc(4);
}
hv_store(res, name, strlen(name), newSVpv(ptr, 0), 0);
free(ptr);
return 0;
}



MODULE = BIE::Data::HDF5            PACKAGE = BIE::Data::HDF5

SV *
h5name(hid_t obj_id)
PREINIT:
ssize_t nameLen;
char * ptr;
CODE:
ptr = malloc(1);
nameLen = H5Iget_name(obj_id,ptr,0);
ptr = realloc(ptr, nameLen + 1);
H5Iget_name(obj_id, ptr, nameLen + 1);
RETVAL = newSVpvn(ptr, nameLen);
free(ptr);
OUTPUT:
RETVAL

HV *
h5ls(hid_t grp_id)
CODE:
RETVAL = newHV();
H5Ovisit(grp_id, H5_INDEX_NAME, H5_ITER_INC, &listKids, RETVAL);
sv_2mortal((SV*)RETVAL);
OUTPUT:
RETVAL


hid_t
H5Fcreate(const char * fileName, unsigned int flags=H5F_ACC_TRUNC, hid_t create_plist=H5P_DEFAULT, hid_t access_plist=H5P_DEFAULT)
PREINIT:
CODE:
RETVAL = H5Fcreate(fileName, flags, create_plist, access_plist);
OUTPUT:
RETVAL

hid_t
H5Fopen(const char * fileName, unsigned int flags=H5F_ACC_RDONLY, hid_t fapl_id=H5P_DEFAULT)
PREINIT:
CODE:
RETVAL = H5Fopen(fileName, flags, fapl_id);
OUTPUT:
RETVAL

herr_t
H5Fclose(hid_t fileID)
CODE:
RETVAL = H5Fclose(fileID);
OUTPUT:
RETVAL

hid_t
H5Gcreate(hid_t loc_id, const char * grpName, hid_t lcpl_id=H5P_DEFAULT, hid_t gcpl_id=H5P_DEFAULT, hid_t gapl_id=H5P_DEFAULT)
CODE:
RETVAL = H5Gcreate(loc_id, grpName, lcpl_id, gcpl_id, gapl_id);
OUTPUT:
RETVAL

hid_t
H5Gopen(hid_t loc_id, const char * grpName, hid_t gapl_id=H5P_DEFAULT)
CODE:
RETVAL = H5Gopen2(loc_id, grpName, gapl_id);
OUTPUT:
RETVAL

herr_t
H5Gclose(hid_t grpID)
CODE:
RETVAL = H5Gclose(grpID);

hid_t
H5Dcreate(hid_t loc_id, const char * name, hid_t dtype_id, hid_t space_id, hid_t lcpl_id=H5P_DEFAULT, hid_t dcpl_id=H5P_DEFAULT, hid_t dapl_id=H5P_DEFAULT)
PREINIT:
CODE:
RETVAL = H5Dcreate(loc_id, name, dtype_id, space_id, lcpl_id, dcpl_id, dapl_id);
OUTPUT:
RETVAL

hid_t
H5Dopen(hid_t loc_id, const char * name, hid_t dapl_id=H5P_DEFAULT)
PREINIT:
CODE:
RETVAL = H5Dopen(loc_id, name, dapl_id);
OUTPUT:
RETVAL

herr_t
H5Dclose(hid_t data_id)

hid_t
H5Dget_type(hid_t data_id)

hid_t
H5Dget_space(hid_t data_id)

herr_t
H5Sclose(hid_t space_id)

herr_t
H5Tclose(hid_t type_id)

size_t
H5Tget_size(hid_t data_id)

SV *
H5Dread(hid_t data_id, hid_t mem_space_id = H5S_ALL, hid_t file_space_id = H5S_ALL, hid_t xfer_plist_id = H5P_DEFAULT)
PREINIT:
hid_t data_type_id;
hid_t mem_type_id;
hid_t space_id;
long long size;
SV* data;
char * ptr;
CODE:
data_type_id = H5Dget_type(data_id);
mem_type_id = H5Tget_native_type(data_type_id, H5T_DIR_ASCEND);
space_id = H5Dget_space(data_id);
size = sizeofH5D(data_id, data_type_id, mem_type_id, space_id);
ptr = malloc(size+1);
H5Dread(data_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, ptr);
RETVAL = newSVpvn(ptr, size);
H5Sclose(space_id);
H5Tclose(data_type_id);
H5Tclose(mem_type_id);
free(ptr);
OUTPUT:
RETVAL

const char * 
getH5DCode(hid_t data_id)
PREINIT:
hid_t data_type_id;
hid_t mem_type_id;
CODE:
data_type_id = H5Dget_type(data_id);
mem_type_id = H5Tget_native_type(data_type_id, H5T_DIR_ASCEND);
RETVAL = getH5DCode(mem_type_id);
H5Tclose(data_type_id);
H5Tclose(mem_type_id);
OUTPUT:
RETVAL



