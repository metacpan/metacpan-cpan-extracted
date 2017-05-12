void		_adjust(SV* self,NV l,NV sigma,AV* unit,AV* v);
void		_adjustn(SOM_GENERIC* som,NV l,NV sigma,NV* n,AV* v);
void		_bmu_guts(SOM_GENERIC *generic,AV *sample,IV *bx,IV *by,NV *bd);
SOM_Map*	_make_map(SOM_GENERIC *generic);
SOM_Array*	_make_array(SOM_Map* map);
SOM_Vector*	_make_vector(SOM_Array* array);
AV*		_neighbors(SV* self,NV sigma,IV X0,IV Y0,...);

void		_map_DESTROY(SV* self);
SV*		_map_FETCH(SV* self,I32 x);
IV		_map_FETCHSIZE(SV* self);

void		_array_DESTROY(SV* self);
SV*		_array_FETCH(SV* self,I32 y);
IV		_array_FETCHSIZE(SV* self);
void		_array_STORE(SV* self,IV y,SV* aref);

void		_vector_DESTROY(SV* self);
SV*		_vector_FETCH(SV* self,I32 z);
IV		_vector_FETCHSIZE(SV* self);
void		_vector_STORE(SV* self,I32 z,NV val);
NV		_vector_distance(AV* V1,AV* V2);

void		_som_bmu(SV* self,AV* sample);
SV*		_som_map(SV* self);
SV*		_som_output_dim(SV* self);
void		_som_train(SV* self,IV epochs);
SV*		_som_FETCH(SV* self,SV* key);
SV*		_som_STORE(SV* self,SV* key,SV* val);
SV*		_som_FIRSTKEY();
SV*		_som_NEXTKEY(SV* prev);
void		_som_FREEZE(SV* self,SV* cloning);
void		_som_THAW(SV* self,SV* cloning,SV* serialized);
void		_som_DESTROY(SV* self);

NV		_hexa_distance(NV x1,NV y1,NV x2,NV y2);
void		_hexa_neiguts(SOM_Hexa* som,NV sigma,IV X0,IV Y0,NV* n);
void		_hexa_new(const char* class);

void		_rect_neiguts(SOM_Rect* som,NV sigma,IV X0,IV Y0,NV* n);
void		_rect_new(const char* class,...);
SV*		_rect_radius(SV* self);

void		_torus_neiguts(SOM_Torus* som,NV sigma,IV X0,IV Y0,NV* n);

